<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use DOMDocument;
use DOMElement;
use DOMNode;
use DOMXPath;
use RuntimeException;
final class HtmlChartParser {
    private const BLOCKS=['div','p','section','h1','h2','h3','h4'];
    private const UNSAFE='.//script|.//style|.//iframe|.//object|.//embed|.//noscript|.//template|.//form|.//button|.//svg';
    private const INLINE='~\[[A-G](?:#|b)?[^\]\n]{0,8}\]~u';

    private function load(string $html):DOMDocument {
        if(strlen($html)>2*1024*1024 || preg_match('/<!ENTITY/i',$html))throw new RuntimeException('HTML não permitido ou muito grande.',422);
        $document=new DOMDocument();$previous=libxml_use_internal_errors(true);
        try{$loaded=$document->loadHTML('<?xml encoding="UTF-8">'.$html,LIBXML_NONET|LIBXML_NOERROR|LIBXML_NOWARNING|LIBXML_COMPACT);}finally{libxml_clear_errors();libxml_use_internal_errors($previous);}
        if(!$loaded)throw new RuntimeException('Não foi possível interpretar a página.',422);
        return $document;
    }

    /**
     * Detecção automática, sem seletores: metadados estruturados (JSON-LD, Open Graph, <title>, <h1>),
     * rótulos visíveis ("Tom:", "Capotraste:", "Afinação:") e o bloco com mais linhas de acordes.
     * Com $withContent=false devolve só os metadados, com conteudo vazio.
     */
    public function detect(string $html,bool $withContent=true):array {
        $document=$this->load($html);$xpath=new DOMXPath($document);
        [$titulo,$artista]=$this->names($xpath);
        $text='';
        if(($body=$xpath->query('//body')->item(0)) instanceof DOMElement){
            $copy=$body->cloneNode(true);
            foreach(iterator_to_array($xpath->query('.//script|.//style|.//noscript|.//template',$copy)) as $node)$node->parentNode?->removeChild($node);
            $text=preg_replace('/[ \t\x{00A0}]+/u',' ',$copy->textContent)??'';
        }
        $values=['titulo'=>$titulo,'artista'=>$artista,'tom'=>'','afinacao'=>'','capotraste'=>''];
        // Sem \b: o texto do DOM junta elementos vizinhos sem espaço ("...PrincipalTom:").
        if(preg_match('/Tom\s*:\s*([A-G](?:#|b)?m?)(?![\pL\pN#])/u',$text,$m))$values['tom']=$m[1];
        if(preg_match('/Capotraste\s*(?::|na)\s*(\d{1,2})\s*(?:ª|º|a)?\s*(casa|traste)?/iu',$text,$m))$values['capotraste']=$m[1].'ª '.(strtolower($m[2]??'')==='traste'?'traste':'casa');
        if(preg_match('/Afina(?:ção|cao)\s*:\s*([A-G](?:#|b)?(?:\s+[A-G](?:#|b)?){3,7})(?![\pL#])/u',$text,$m))$values['afinacao']=$m[1];
        foreach($values as $key=>$value)$values[$key]=mb_substr(trim(preg_replace('/\s+/u',' ',$value)??''),0,in_array($key,['titulo','artista'],true)?200:80);
        if($values['titulo']==='')throw new RuntimeException('Não foi possível identificar o título da música nesta página.',422);
        $values+=['conteudo'=>'','formato'=>'inline','categoria'=>'','publicada'=>''];
        if(!$withContent)return $values;
        $root=$this->chartNode($xpath);
        if(!$root)throw new RuntimeException('Não encontramos uma cifra nesta página (acordes acima da letra ou no formato [C]palavra).',422);
        foreach(iterator_to_array($xpath->query(self::UNSAFE,$root)) as $node)$node->parentNode?->removeChild($node);
        $content=$this->text($root,self::BLOCKS);
        $values['conteudo']=ChartParser::normalize($content,$this->chordLines($content)>0?'aligned':'inline',false);
        return $values;
    }

    /** Título e artista: JSON-LD de música → og:title/<title> ("Música - Artista - Site") → <h1>. */
    private function names(DOMXPath $xpath):array {
        $titulo='';$artista='';$recording='';
        foreach($xpath->query('//script[@type="application/ld+json"]') as $script){
            $data=json_decode(trim($script->textContent),true);
            if(!is_array($data))continue;
            $items=is_array($data['@graph']??null)?$data['@graph']:(array_is_list($data)?$data:[$data]);
            foreach($items as $item){
                if(!is_array($item))continue;
                $types=(array)($item['@type']??[]);$name=is_string($item['name']??null)?trim($item['name']):'';
                if(!array_intersect($types,['MusicComposition','MusicRecording']))continue;
                if(in_array('MusicComposition',$types,true) && $name!=='')$titulo=$name;elseif($name!=='')$recording=$name;
                $by=$item['byArtist']??null;if(is_array($by) && array_is_list($by))$by=$by[0]??null;
                if($artista==='' && is_array($by) && is_string($by['name']??null))$artista=trim($by['name']);
            }
        }
        $meta=static fn(string $q):string=>trim((string)($xpath->query($q)->item(0)?->nodeValue??''));
        $site=$meta('//meta[@property="og:site_name"]/@content');
        $parts=array_values(array_filter(array_map('trim',preg_split('/\s+[-–|]\s+/u',$meta('//meta[@property="og:title"]/@content')?:$meta('//title'))?:[]),'strlen'));
        if(count($parts)>2 || count($parts)===2 && $site!=='' && strcasecmp($parts[1],$site)===0)array_pop($parts);
        if($titulo==='' && $recording!==''){$titulo=$artista!==''?trim(str_replace($artista,'',$recording),' -–|'):$recording;}
        if($titulo==='')$titulo=$parts[0]??'';
        if($artista==='' && count($parts)===2)$artista=$parts[1];
        if($titulo==='')$titulo=trim((string)($xpath->query('//h1')->item(0)?->textContent??''));
        return [html_entity_decode($titulo,ENT_QUOTES|ENT_HTML5,'UTF-8'),html_entity_decode($artista,ENT_QUOTES|ENT_HTML5,'UTF-8')];
    }

    /** O bloco com mais linhas de acordes (ou marcações [C]) entre <pre> e contêineres de cifra; o mais interno vence empates. */
    private function chartNode(DOMXPath $xpath):?DOMElement {
        $best=null;$bestScore=1;$bestLength=PHP_INT_MAX;
        $query='//pre|//*[@data-chord-content]|//*[contains(@class,"cifra") or contains(@id,"cifra") or contains(@class,"chord") or contains(@id,"chord") or contains(@class,"chart")]';
        foreach($xpath->query($query) as $node){
            if(!$node instanceof DOMElement)continue;
            $text=$this->text($node,self::BLOCKS);
            $score=$this->chordLines($text)+intdiv(preg_match_all(self::INLINE,$text),2);
            if($score>$bestScore || $score===$bestScore && strlen($text)<$bestLength){$best=$node;$bestScore=$score;$bestLength=strlen($text);}
        }
        return $best;
    }
    private function chordLines(string $text):int {
        $count=0;foreach(explode("\n",$text) as $line)if(ChartParser::isChordLine($line))$count++;return $count;
    }

    public function parse(string $html,array $config):array {
        $document=$this->load($html);
        $xpath=new DOMXPath($document);$selectors=$config['selectors'];$values=[];
        foreach(['titulo','artista','tom','afinacao','capotraste'] as $key){
            $selector=$selectors[$key]??null;$value='';
            if($selector){$nodes=$this->select($xpath,$selector);if($nodes->length>1)throw new RuntimeException('O seletor de '.$key.' encontrou mais de um elemento.',422);$value=$nodes->item(0)?->textContent??'';}
            $value=trim(preg_replace('/\s+/u',' ',$value));
            foreach($config['strip_prefixes'][$key]??[] as $prefix)if(str_starts_with($value,$prefix))$value=trim(substr($value,strlen($prefix)));
            if(mb_strlen($value)>200)throw new RuntimeException('Metadado importado muito longo.',422);
            $values[$key]=$value;
        }
        $roots=$this->select($xpath,$selectors['conteudo']);
        if($roots->length!==1 || !($roots->item(0) instanceof DOMElement))throw new RuntimeException('Não foi possível identificar corretamente a estrutura desta cifra. Revise os seletores do provedor.',422);
        $root=$roots->item(0);
        foreach([self::UNSAFE,...($config['remove']??[])] as $selector){
            if(!str_starts_with($selector,'.'))throw new RuntimeException('Seletores de limpeza precisam ser relativos ao conteúdo.',422);
            foreach(iterator_to_array($this->select($xpath,$selector,$root)) as $node)$node->parentNode?->removeChild($node);
        }
        if(!empty($config['section_selector'])) {
            $selector=$config['section_selector'];
            if(!str_starts_with($selector,'.'))throw new RuntimeException('O seletor de seções precisa ser relativo.',422);
            foreach(iterator_to_array($this->select($xpath,$selector,$root)) as $section){
                $label=trim($section->textContent);
                if($label==='' || mb_strlen($label)>80)throw new RuntimeException('Seção inválida. Revise o seletor de seções.',422);
                while($section->firstChild)$section->removeChild($section->firstChild);
                $section->appendChild($document->createTextNode('['.trim($label,'[]').']'));
            }
        }
        $content=$this->text($root,$config['block_tags']??self::BLOCKS);
        if(trim($content)==='' || $values['titulo']==='' || $values['artista']==='')throw new RuntimeException('Título, artista ou conteúdo não encontrados. A página pode ter mudado.',422);
        $values['conteudo']=ChartParser::normalize($content,$config['format']??'aligned',false);
        if(!preg_match('~\[[A-G](?:#|b)?[^\]\n]*\]~u',$values['conteudo']))throw new RuntimeException('Não foram identificados acordes no conteúdo. Revise o seletor e o formato.',422);
        $values['categoria']='';$values['formato']='inline';$values['publicada']='';
        return $values;
    }
    private function select(DOMXPath $xpath,string $selector,?DOMNode $context=null):\DOMNodeList {
        $nodes=@$xpath->query($selector,$context);if($nodes===false)throw new RuntimeException('Um seletor XPath do provedor é inválido.',422);return $nodes;
    }
    private function text(DOMNode $node,array $blocks,int $depth=0):string {
        if($depth>128)throw new RuntimeException('A estrutura da página é muito complexa.',422);
        if($node->nodeType===XML_TEXT_NODE || $node->nodeType===XML_CDATA_SECTION_NODE)return $node->nodeValue??'';
        $output='';foreach($node->childNodes as $child){
            if($child instanceof DOMElement && strtolower($child->tagName)==='br'){$output.="\n";continue;}
            $block=$child instanceof DOMElement && in_array(strtolower($child->tagName),$blocks,true);
            if($block && $output!=='' && !str_ends_with($output,"\n"))$output.="\n";
            $output.=$this->text($child,$blocks,$depth+1);
            if($block && !str_ends_with($output,"\n"))$output.="\n";
        }return $output;
    }
}
