<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use DOMDocument;
use DOMElement;
use DOMNode;
use DOMXPath;
use RuntimeException;

/**
 * Interpreta o HTML de uma página de cifra do Cifra Club. Não acessa a rede: HTML → DTO.
 *
 * As classes CSS do site são hashes gerados no build (ex.: "_5QAC", "kvMV") e não são usadas.
 * Cada campo tem estratégias em ordem, das mais estáveis para as mais genéricas:
 *   título   JSON-LD MusicComposition → og:title → <h1>
 *   artista  JSON-LD MusicRecording.byArtist → BreadcrumbList → og:title
 *   tom      [data-anchor=--chord-tone] → cartão #key → rótulo "Tom" → texto "Tom: X"
 *   capo     [data-anchor=--chord-capo] → cartão #capo → rótulo "Capotraste" → texto
 *   afinação cartão #tuning → rótulo "Afinação" → atributo data-tuning dos diagramas
 *   cifra    <pre data-chord-content> → <pre> com mais <b data-chord-name> → <pre> com mais linhas
 * O campo "deteccao" informa qual estratégia encontrou cada valor.
 */
final class CifraClubParser {
    private const UNSAFE='.//script|.//style|.//iframe|.//object|.//embed|.//noscript|.//template|.//form|.//button|.//svg|.//img|.//video|.//audio';
    private const BLOCKS=['div','p','section','article','li','ul','ol','h1','h2','h3','h4','h5','h6','table','tr'];
    private const STANDARD_TUNING='E A D G B E';

    /**
     * @return array{titulo:string,artista:string,tom:string,capotraste:string,afinacao:string,conteudo:string,formato:string,deteccao:array<string,string>,estrutura:array<string,int>}
     */
    public function parse(string $html):array {
        $xpath=new DOMXPath($this->load($html));$found=[];
        $ld=$this->jsonLd($xpath);
        $og=$this->ogParts($xpath);
        $found['titulo']=$this->first([
            'json-ld MusicComposition'=>fn()=>$ld['composition'],
            'og:title'=>fn()=>$og[0]??'',
            'h1'=>fn()=>$this->clean($xpath->query('//h1')->item(0)?->textContent??''),
        ]);
        $found['artista']=$this->first([
            'json-ld byArtist'=>fn()=>$ld['artist'],
            'json-ld BreadcrumbList'=>fn()=>$ld['breadcrumbArtist'],
            'og:title'=>fn()=>$og[1]??'',
        ]);
        $found['tom']=$this->first([
            'data-anchor --chord-tone'=>fn()=>$this->key($this->attrText($xpath,'--chord-tone')),
            'cartão #key'=>fn()=>$this->key($this->card($xpath,'key','Tom')),
            'rótulo "Tom"'=>fn()=>$this->key($this->labelled($xpath,'Tom')),
            'texto "Tom:"'=>fn()=>preg_match('/Tom\s*:\s*([A-G](?:#|b)?m?)(?![\pL\pN#])/u',$this->bodyText($xpath),$m)?$m[1]:'',
        ]);
        $found['capotraste']=$this->first([
            'data-anchor --chord-capo'=>fn()=>$this->capo($this->attrText($xpath,'--chord-capo')),
            'cartão #capo'=>fn()=>$this->capo($this->card($xpath,'capo','Capotraste')),
            'rótulo "Capotraste"'=>fn()=>$this->capo($this->labelled($xpath,'Capotraste')),
            'texto "Capotraste:"'=>fn()=>preg_match('/Capotraste\s*(?::|na)\s*(\d{1,2}\s*(?:ª|º|a)?\s*(?:casa|traste)?)/iu',$this->bodyText($xpath),$m)?$this->capo($m[1]):'',
        ]);
        $found['afinacao']=$this->first([
            'cartão #tuning'=>fn()=>$this->card($xpath,'tuning','Afinação'),
            'rótulo "Afinação"'=>fn()=>$this->labelled($xpath,'Afinação'),
            'data-tuning'=>fn()=>$this->tuningAttribute($xpath),
        ]);
        $values=[];$detection=[];
        foreach($found as $field=>[$value,$strategy]){
            $values[$field]=mb_substr($value,0,in_array($field,['titulo','artista'],true)?200:80);
            $detection[$field]=$strategy;
        }
        if($values['titulo']==='')throw new RuntimeException('Parser Cifra Club: título não encontrado (JSON-LD, og:title e <h1> ausentes).',422);
        [$pre,$detection['conteudo']]=$this->chartNode($xpath);
        if(!$pre)throw new RuntimeException('Parser Cifra Club: bloco da cifra não encontrado (<pre data-chord-content> ausente e nenhum <pre> com acordes).',422);
        [$content,$structure]=$this->chart($xpath,$pre);
        if($structure['acordes']===0)throw new RuntimeException('Parser Cifra Club: o bloco da cifra não contém acordes marcados.',422);
        return [...$values,'conteudo'=>ChartParser::normalize($content,'inline',false),'formato'=>'inline','deteccao'=>$detection,'estrutura'=>$structure];
    }

    private function load(string $html):DOMDocument {
        if(strlen($html)>SafeHttpClient::MAX_BYTES || preg_match('/<!ENTITY/i',$html))throw new RuntimeException('HTML não permitido ou muito grande.',422);
        $document=new DOMDocument();$previous=libxml_use_internal_errors(true);
        try{$loaded=$document->loadHTML('<?xml encoding="UTF-8">'.$html,LIBXML_NONET|LIBXML_NOERROR|LIBXML_NOWARNING|LIBXML_COMPACT);}finally{libxml_clear_errors();libxml_use_internal_errors($previous);}
        if(!$loaded)throw new RuntimeException('Não foi possível interpretar a página.',422);
        return $document;
    }

    /** @param array<string,callable():string> $strategies @return array{string,string} valor e estratégia que o encontrou */
    private function first(array $strategies):array {
        foreach($strategies as $name=>$strategy){$value=$this->clean($strategy());if($value!=='')return [$value,$name];}
        return ['','não encontrado'];
    }
    private function clean(string $value):string {
        return trim(preg_replace('/\s+/u',' ',html_entity_decode($value,ENT_QUOTES|ENT_HTML5,'UTF-8'))??'');
    }

    // ---- metadados ----

    private function jsonLd(DOMXPath $xpath):array {
        $out=['composition'=>'','artist'=>'','breadcrumbArtist'=>''];
        foreach($xpath->query('//script[@type="application/ld+json"]') as $script){
            $data=json_decode(trim($script->textContent),true);
            if(!is_array($data))continue;
            $items=is_array($data['@graph']??null)?$data['@graph']:(array_is_list($data)?$data:[$data]);
            foreach($items as $item){
                if(!is_array($item))continue;
                $types=(array)($item['@type']??[]);
                if(in_array('MusicComposition',$types,true) && $out['composition']==='' && is_string($item['name']??null))$out['composition']=$item['name'];
                if(array_intersect($types,['MusicRecording','MusicComposition']) && $out['artist']===''){
                    $by=$item['byArtist']??null;if(is_array($by) && array_is_list($by))$by=$by[0]??null;
                    if(is_array($by) && is_string($by['name']??null))$out['artist']=$by['name'];
                }
                // Início › Estilo › Artista › Música: o artista é o penúltimo item.
                if(in_array('BreadcrumbList',$types,true) && is_array($item['itemListElement']??null)){
                    $list=array_values(array_filter($item['itemListElement'],'is_array'));
                    usort($list,fn($a,$b)=>(int)($a['position']??0)<=>(int)($b['position']??0));
                    if(count($list)>=3 && is_string($list[count($list)-2]['name']??null))$out['breadcrumbArtist']=$list[count($list)-2]['name'];
                }
            }
        }
        return $out;
    }
    /** "Música - Artista - Cifra Club" sem o nome do site. */
    private function ogParts(DOMXPath $xpath):array {
        $title=(string)($xpath->query('//meta[@property="og:title"]/@content')->item(0)?->nodeValue??$xpath->query('//title')->item(0)?->textContent??'');
        $site=trim((string)($xpath->query('//meta[@property="og:site_name"]/@content')->item(0)?->nodeValue??'Cifra Club'));
        $parts=array_values(array_filter(array_map('trim',preg_split('/\s+[-–|]\s+/u',$title)?:[]),'strlen'));
        if(count($parts)>1 && strcasecmp(end($parts),$site)===0)array_pop($parts);
        return $parts;
    }
    private function attrText(DOMXPath $xpath,string $anchor):string {
        return (string)($xpath->query('//*[@data-anchor="'.$anchor.'"]')->item(0)?->textContent??'');
    }
    /** Cartão identificado por id: primeiro texto-folha que não seja o próprio rótulo. */
    private function card(DOMXPath $xpath,string $id,string $label):string {
        $card=$xpath->query('//*[@id="'.$id.'"]')->item(0);
        return $card?$this->valueAfterLabel($xpath,$card,$label):'';
    }
    /** Elemento cujo texto é só o rótulo ("Tom", "Tom:"); o valor é o texto seguinte no mesmo contêiner. */
    private function labelled(DOMXPath $xpath,string $label):string {
        foreach($xpath->query('//body//*[not(*)]') as $node){
            if(!$this->isLabel($node->textContent,$label))continue;
            for($container=$node->parentNode;$container instanceof DOMElement && $container->nodeName!=='body';$container=$container->parentNode){
                $value=$this->valueAfterLabel($xpath,$container,$label);
                if($value!=='')return $value;
                if(mb_strlen($container->textContent)>200)break;
            }
        }
        return '';
    }
    private function valueAfterLabel(DOMXPath $xpath,DOMNode $container,string $label):string {
        $seen=false;
        foreach($xpath->query('.//text()',$container) as $text){
            $value=$this->clean($text->nodeValue??'');
            if($value==='' || $value===':')continue;
            if($this->isLabel($value,$label)){$seen=true;continue;}
            if($seen)return $value;
        }
        return '';
    }
    private function isLabel(string $text,string $label):bool {
        return (bool)preg_match('/^\s*'.preg_quote($label,'/').'\s*:?\s*$/iu',$text);
    }
    private function key(string $text):string {
        return preg_match('/^\s*([A-G](?:#|b)?m?)(?![\pL\pN#])/u',$text,$m)?$m[1]:'';
    }
    private function capo(string $text):string {
        if(!preg_match('/(\d{1,2})\s*(?:ª|º|a)?\s*(casa|traste)?/iu',$text,$m) || (int)$m[1]<1 || (int)$m[1]>24)return '';
        return $m[1].'ª '.(strtolower($m[2]??'')==='traste'?'traste':'casa');
    }
    private function tuningAttribute(DOMXPath $xpath):string {
        $tuning=$this->clean((string)($xpath->query('//*[@data-tuning]/@data-tuning')->item(0)?->nodeValue??''));
        if(!preg_match('/^[A-G](?:#|b)?(?:\s[A-G](?:#|b)?){3,7}$/D',$tuning))return '';
        return $tuning===self::STANDARD_TUNING?'Padrão':$tuning;
    }
    private function bodyText(DOMXPath $xpath):string {
        $body=$xpath->query('//body')->item(0);
        return $body?preg_replace('/[ \t\x{00A0}]+/u',' ',$body->textContent)??'':'';
    }

    // ---- cifra ----

    /** @return array{?DOMElement,string} */
    private function chartNode(DOMXPath $xpath):array {
        $marked=$xpath->query('//pre[@data-chord-content]');
        if($marked->length===1 && $marked->item(0) instanceof DOMElement)return [$marked->item(0),'pre[data-chord-content]'];
        $best=null;$bestScore=0;
        foreach($xpath->query('//pre') as $pre){
            $score=$xpath->query('.//*[@data-chord-name]',$pre)->length;
            if($score>$bestScore){$best=$pre;$bestScore=$score;}
        }
        if($best instanceof DOMElement)return [$best,'pre com mais [data-chord-name]'];
        foreach($xpath->query('//pre') as $pre){
            $score=0;foreach(explode("\n",$pre->textContent) as $line)if(ChartParser::isChordLine($line))$score++;
            if($score>$bestScore){$best=$pre;$bestScore=$score;}
        }
        return $best instanceof DOMElement?[$best,'pre com mais linhas de acordes']:[null,'não encontrado'];
    }

    /**
     * Percorre o <pre> preservando quebras e colunas e converte acordes-sobre-a-letra para o formato [C]palavra.
     * Acordes vêm do DOM (<b data-chord-name>), não de regex; linhas de tablatura são mantidas intactas.
     * @return array{string,array<string,int>}
     */
    private function chart(DOMXPath $xpath,DOMElement $pre):array {
        foreach(iterator_to_array($xpath->query(self::UNSAFE,$pre)) as $node)$node->parentNode?->removeChild($node);
        $lines=[[]];
        $this->walk($pre,$lines);
        $rows=array_map(fn(array $tokens)=>$this->row($tokens),$lines);
        $output=[];$stats=['linhas'=>0,'acordes'=>0,'linhas_de_acordes'=>0,'secoes'=>0,'tablaturas'=>0];
        for($i=0;$i<count($rows);$i++){
            $row=$rows[$i];
            $stats['acordes']+=count($row['chords']);
            if($row['section']!==null){$output[]=$row['section'];$stats['secoes']++;if(!$row['chords'])continue;}
            if($row['tab'])$stats['tablaturas']++;
            if(!$row['chords'] || !$row['chordOnly']){$output[]=$this->inlineMixed($row);continue;}
            $stats['linhas_de_acordes']++;
            $next=$rows[$i+1]??null;
            $isLyric=$next && trim($next['text'])!=='' && !$next['chords'] && !$next['tab'] && $next['section']===null;
            if($isLyric){$output[]=$this->place($row['chords'],$next['text']);$i++;}
            else $output[]=$this->place($row['chords'],str_repeat(' ',mb_strlen($row['text'])));
        }
        while($output && trim(end($output))==='')array_pop($output);
        while($output && trim($output[0])==='')array_shift($output);
        $stats['linhas']=count($output);
        return [implode("\n",$output),$stats];
    }
    /** @param list<list<array{string,string}>> $lines tokens [tipo, texto] por linha */
    private function walk(DOMNode $node,array &$lines,int $depth=0):void {
        if($depth>64)throw new RuntimeException('A estrutura da cifra é muito profunda.',422);
        foreach($node->childNodes as $child){
            if($child->nodeType===XML_TEXT_NODE || $child->nodeType===XML_CDATA_SECTION_NODE){
                $parts=explode("\n",str_replace(["\r\n","\r"],"\n",$child->nodeValue??''));
                foreach($parts as $k=>$part){if($k>0)$lines[]=[];if($part!=='')$lines[array_key_last($lines)][]=['text',$part];}
                continue;
            }
            if(!$child instanceof DOMElement)continue;
            $tag=strtolower($child->tagName);
            if($tag==='br'){$lines[]=[];continue;}
            if($child->hasAttribute('data-chord-name')){$lines[array_key_last($lines)][]=['chord',$child->textContent];continue;}
            $block=in_array($tag,self::BLOCKS,true);
            if($block && $lines[array_key_last($lines)])$lines[]=[];
            $this->walk($child,$lines,$depth+1);
            if($block && $lines[array_key_last($lines)])$lines[]=[];
        }
    }
    /** Linha com colunas calculadas após expandir tabs (8 colunas), como no ChartParser. */
    private function row(array $tokens):array {
        $text='';$chords=[];$other='';
        foreach($tokens as [$type,$value]){
            $expanded='';foreach(mb_str_split(str_replace("\xc2\xa0",' ',$value)) as $char)$expanded.=$char==="\t"?str_repeat(' ',8-(mb_strlen($text.$expanded)%8)):$char;
            if($type==='chord'){$name=trim($expanded);$chords[]=[$name,mb_strlen($text)+mb_strlen($expanded)-mb_strlen(ltrim($expanded))];}
            else $other.=$expanded;
            $text.=$expanded;
        }
        $section=null;$rest=$other;
        // "[Refrão]" sozinho, ou "[Intro] D  E": a seção vai para linha própria e os acordes ficam na mesma coluna.
        if(preg_match('/^\s*(\[[^\]\n]{1,80}\])/u',$other,$m) && trim(substr($other,strlen($m[0])))==='' && str_starts_with($text,$m[0])){
            $section=$m[1];$rest='';
            $text=str_repeat(' ',mb_strlen($m[0])).mb_substr($text,mb_strlen($m[0]));
        }
        return ['text'=>$text,'chords'=>$chords,'chordOnly'=>trim($rest)==='','section'=>$section,
            'tab'=>(bool)preg_match('/^\s*[A-Ga-g](?:#|b)?\s*\|.*[-|]/u',$text)];
    }
    /** Insere [acorde] na coluna original sobre o texto (letra ou espaços), completando com espaços se preciso. */
    private function place(array $chords,string $lyric):string {
        foreach(array_reverse($chords) as [$name,$column]){
            if(mb_strlen($lyric)<$column)$lyric.=str_repeat(' ',$column-mb_strlen($lyric));
            $lyric=mb_substr($lyric,0,$column).'['.$name.']'.mb_substr($lyric,$column);
        }
        return rtrim($lyric);
    }
    /** Acordes no meio do texto (raro): o acorde vira [X] no ponto onde aparece. */
    private function inlineMixed(array $row):string {
        if(!$row['chords'])return rtrim($row['text']);
        $text=$row['text'];
        foreach(array_reverse($row['chords']) as [$name,$column])$text=mb_substr($text,0,$column).'['.$name.']'.mb_substr($text,$column+mb_strlen($name));
        return rtrim($text);
    }
}
