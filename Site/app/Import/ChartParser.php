<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;

final class ChartParser {
    private const CHORD = '[A-G](?:\#|b)?(?:(?:maj|min|dim|aug|sus|add|m|M)|[0-9\#b()+°º-])*(?:/[A-G](?:\#|b)?)?';
    public static function normalize(string $text, string $format, bool $decodeEntities = true): string {
        if (strlen($text)>150000 || !mb_check_encoding($text,'UTF-8')) throw new RuntimeException('A cifra deve ter até 100 mil caracteres e usar UTF-8.',422);
        $text = str_replace(["\r\n","\r","\xc2\xa0"],["\n","\n",' '],($format === 'aligned' && $decodeEntities ? html_entity_decode($text,ENT_QUOTES|ENT_HTML5,'UTF-8') : $text));
        if ($format === 'aligned') $text = str_replace('**','',$text);
        if (preg_match('/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/',$text)) throw new RuntimeException('A cifra contém caracteres de controle inválidos.',422);
        $lines = explode("\n",trim($text,"\n"));
        foreach ($lines as &$line) {
            $expanded='';
            foreach(mb_str_split($line) as $char) $expanded .= $char === "\t" ? str_repeat(' ',8-mb_strlen($expanded)%8) : $char;
            $line=$expanded;
        }
        unset($line);
        if ($format === 'inline') return self::bounded(implode("\n",$lines));
        if ($format !== 'aligned') throw new RuntimeException('Formato de cifra inválido.',422);
        $output=[];
        for($i=0;$i<count($lines);$i++) {
            $line=$lines[$i];
            if(preg_match('/^\s*Tom:\s*[A-G](?:#|b)?m?\s*$/ui',$line)) continue;
            if(preg_match('/^\s*\[([^\]]+)\]\s+(.+)$/u',$line,$section) && self::chords($section[2]) !== null) {
                $output[]='['.$section[1].']';$line=$section[2];
            }
            $chords=self::chords($line);
            if($chords===null){$output[]=$line;continue;}
            $next=$lines[$i+1]??'';
            $hasLyric=trim($next)!=='' && self::chords($next)===null && !preg_match('/^\s*\[[^\]]+\]/u',$next);
            if($hasLyric){$lyric=$next;$i++;} else {
                $lyric=$line;
                foreach(array_reverse($chords) as [$chord,$offset]) $lyric=substr_replace($lyric,str_repeat(' ',mb_strlen($chord)), $offset,strlen($chord));
            }
            $converted=$lyric;
            foreach(array_reverse($chords) as [$chord,$offset]) {
                $position=mb_strlen(substr($line,0,$offset));
                if($position>mb_strlen($converted))$converted.=str_repeat(' ',$position-mb_strlen($converted));
                $converted=mb_substr($converted,0,$position).'['.$chord.']'.mb_substr($converted,$position);
            }
            $output[]=rtrim($converted);
        }
        return self::bounded(implode("\n",$output));
    }
    private static function bounded(string $text):string {
        if(trim($text)==='' || mb_strlen($text)>100000)throw new RuntimeException('Informe uma cifra de até 100 mil caracteres.',422);
        return $text;
    }
    /** Linha composta só de acordes (formato de acordes acima da letra). */
    public static function isChordLine(string $line):bool {return trim($line)!=='' && self::chords($line)!==null;}
    private static function chords(string $line):?array {
        $pattern='~(?<![\pL\pN/#])('.self::CHORD.')(?![\pL\pN/#])~u';
        preg_match_all($pattern,$line,$matches,PREG_OFFSET_CAPTURE);
        if(!$matches[0])return null;
        $rest=preg_replace($pattern,'',$line);
        $rest=preg_replace('/\b[0-9]+x\b/ui','',$rest);
        return trim($rest," \t()|-:") === '' ? $matches[0] : null;
    }
    /** Pares alinhados para uma prévia escapada, sem HTML remoto. */
    public static function preview(string $content):array {
        $rows=[];
        foreach(explode("\n",$content) as $line){
            preg_match_all('~\[('.self::CHORD.')\]~u',$line,$matches,PREG_OFFSET_CAPTURE);
            $lyric='';$chords='';$cursor=0;
            foreach($matches[0] as $i=>[$tag,$offset]){
                $lyric.=substr($line,$cursor,$offset-$cursor);
                $position=mb_strlen($lyric);
                if(mb_strlen($chords)<$position)$chords.=str_repeat(' ',$position-mb_strlen($chords));
                elseif($chords!=='' && !str_ends_with($chords,' '))$chords.=' ';
                $chords.=$matches[1][$i][0];$cursor=$offset+strlen($tag);
            }
            $lyric.=substr($line,$cursor);$rows[]=[$chords,$lyric];
        }
        return $rows;
    }
}
