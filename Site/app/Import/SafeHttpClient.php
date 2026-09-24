<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;

/**
 * GET HTTPS com proteção SSRF (IP resolvido e fixado a cada salto), limite de tempo, tamanho, redirects e Content-Type.
 * Sempre devolve/anexa o diagnóstico real: status, URL final, redirects, Content-Type, bytes, tempo e erro de rede.
 */
final class SafeHttpClient {
    public const MAX_BYTES=2*1024*1024;
    public const MAX_REDIRECTS=3;
    private const TIMEOUT_SECONDS=12;
    /** Códigos do cURL agrupados pela etapa em que a rede falhou. */
    private const CURL_STAGES=[6=>'dns',7=>'conexao',28=>'timeout',35=>'tls',51=>'tls',53=>'tls',54=>'tls',58=>'tls',59=>'tls',60=>'tls',77=>'tls',80=>'tls',83=>'tls',90=>'tls',91=>'tls',52=>'resposta-vazia',56=>'conexao'];

    /** @return array{html:string,url:string,diagnostico:array} */
    public function get(string $url,UrlPolicy $policy):array {
        $start=microtime(true);$deadline=$start+self::TIMEOUT_SECONDS;
        $diag=['url_solicitada'=>$url,'url_final'=>'','redirects'=>[],'ip'=>'','status'=>null,'content_type'=>'','servidor'=>'','bytes'=>0,'tempo_ms'=>0,'erro'=>null];
        $fail=static function(string $stage,string $detail,int $code,?\Throwable $previous=null)use(&$diag,$start):never{
            $diag['erro']=['etapa'=>$stage,'detalhe'=>$detail];$diag['tempo_ms']=(int)round((microtime(true)-$start)*1000);
            error_log('Cifra Santa import http '.json_encode($diag,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE));
            throw new ImportDiagnosticException($detail,$code,$diag,$previous);
        };
        for($hop=0;;$hop++) {
            try{$url=$policy->normalize($url);}catch(RuntimeException $e){$fail('url',$e->getMessage(),422,$e);}
            $diag['url_final']=$url;
            try{[$host,$ip]=$policy->resolve($url);}catch(RuntimeException $e){$fail('dns',$e->getMessage(),502,$e);}
            $diag['ip']=$ip;
            $remaining=(int)(($deadline-microtime(true))*1000);
            if($remaining<=0)$fail('timeout','Tempo limite de '.self::TIMEOUT_SECONDS.' s esgotado antes de '.$host.' responder.',504);
            $body='';$headers=[];$tooLarge=false;$headerBytes=0;
            $ch=curl_init($url);
            curl_setopt_array($ch,[CURLOPT_FOLLOWLOCATION=>false,CURLOPT_PROTOCOLS=>CURLPROTO_HTTPS,CURLOPT_PROXY=>'',
                CURLOPT_RESOLVE=>[$host.':443:'.$ip],CURLOPT_IPRESOLVE=>CURL_IPRESOLVE_V4,CURLOPT_SSL_VERIFYPEER=>true,CURLOPT_SSL_VERIFYHOST=>2,
                CURLOPT_CONNECTTIMEOUT_MS=>min(4000,$remaining),CURLOPT_TIMEOUT_MS=>$remaining,CURLOPT_ENCODING=>'gzip, deflate',
                CURLOPT_HTTPHEADER=>['Accept: text/html, application/xhtml+xml','Accept-Language: pt-BR,pt;q=0.9'],CURLOPT_USERAGENT=>'CifraSanta-Import/1.0',
                CURLOPT_WRITEFUNCTION=>static function($ch,string $chunk)use(&$body,&$tooLarge):int{
                    if(strlen($body)+strlen($chunk)>self::MAX_BYTES){$tooLarge=true;return 0;}$body.=$chunk;return strlen($chunk);
                },
                CURLOPT_HEADERFUNCTION=>static function($ch,string $line)use(&$headers,&$headerBytes):int{
                    $headerBytes+=strlen($line);if($headerBytes>32768)return 0;
                    if(preg_match('~^HTTP/~',$line))$headers=[];// cabeçalhos só da resposta final deste salto
                    elseif(str_contains($line,':')){[$k,$v]=explode(':',$line,2);$headers[strtolower(trim($k))]=trim($v);}
                    return strlen($line);
                },
            ]);
            $ok=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$errno=curl_errno($ch);$error=curl_error($ch);curl_close($ch);
            $diag['status']=$status?:null;$diag['content_type']=$headers['content-type']??'';$diag['servidor']=$headers['server']??'';$diag['bytes']=strlen($body);
            if($tooLarge)$fail('limite','A resposta de '.$host.' passou do limite de '.intdiv(self::MAX_BYTES,1024*1024).' MB.',422);
            if($ok===false)$fail(self::CURL_STAGES[$errno]??'rede','Falha de rede ao acessar '.$host.' (cURL '.$errno.': '.$error.').',$errno===28?504:502);
            if(in_array($status,[301,302,303,307,308],true)){
                if($hop>=self::MAX_REDIRECTS)$fail('redirect','Mais de '.self::MAX_REDIRECTS.' redirecionamentos a partir de '.$diag['url_solicitada'].'.',502);
                $location=$headers['location']??'';
                try{$next=$policy->redirect($url,$location);}catch(RuntimeException $e){$fail('redirect','HTTP '.$status.' redirecionou para "'.$location.'", destino recusado: '.$e->getMessage(),502,$e);}
                $diag['redirects'][]=['status'=>$status,'de'=>$url,'para'=>$next];$url=$next;continue;
            }
            if($status!==200){
                $diag['resposta']=self::bodySnippet($body);
                $hint=match(true){$status===403=>' (acesso negado pelo servidor remoto)',$status===429=>' (limite de requisições do servidor remoto'.(isset($headers['retry-after'])?'; Retry-After: '.$headers['retry-after']:'').')',$status>=500=>' (erro no servidor remoto)',default=>''};
                $fail('http','O servidor '.$host.' respondeu HTTP '.$status.$hint.'.',502);
            }
            if(!preg_match('~^(text/html|application/xhtml\+xml)(?:;|$)~i',$diag['content_type']))$fail('content-type','Content-Type inesperado: "'.$diag['content_type'].'" (esperado text/html).',422);
            if(preg_match('/charset=["\x27]?([a-z0-9-]+)/i',$diag['content_type'],$charset) && strtolower($charset[1])!=='utf-8') {
                if(!in_array(strtolower($charset[1]),['iso-8859-1','windows-1252','us-ascii'],true))$fail('codificacao','Codificação não suportada: '.$charset[1].'.',422);
                $body=mb_convert_encoding($body,'UTF-8',$charset[1]);
            }
            if(!mb_check_encoding($body,'UTF-8'))$fail('codificacao','A página não está em UTF-8 válido.',422);
            $diag['tempo_ms']=(int)round((microtime(true)-$start)*1000);
            return ['html'=>$body,'url'=>$url,'diagnostico'=>$diag];
        }
    }

    /** Texto visível de uma resposta de erro (ex.: "Access Denied ... Reference #..."), sem HTML, até 300 caracteres. */
    public static function bodySnippet(string $body):string {
        $text=preg_replace('~<(script|style)\b[^>]*>.*?</\1>~is',' ',substr($body,0,20000))??'';
        $text=html_entity_decode(preg_replace('/<[^>]*>/',' ',$text)??'',ENT_QUOTES|ENT_HTML5,'UTF-8');
        $text=trim(preg_replace('/\s+/u',' ',mb_scrub($text,'UTF-8'))??'');
        return mb_strlen($text)>300?mb_substr($text,0,300).'…':$text;
    }
}
