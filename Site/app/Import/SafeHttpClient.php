<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;
final class SafeHttpClient {
    public function get(string $url,UrlPolicy $policy):array {
        $deadline=microtime(true)+12;
        for($redirects=0;$redirects<=2;$redirects++) {
            $url=$policy->normalize($url);[$host,$ip]=$policy->resolve($url);
            $remaining=(int)(($deadline-microtime(true))*1000);
            if($remaining<=0)throw new RuntimeException('O provedor demorou para responder.',422);
            $body='';$headers=[];$tooLarge=false;$headerBytes=0;
            $ch=curl_init($url);
            curl_setopt_array($ch,[CURLOPT_FOLLOWLOCATION=>false,CURLOPT_PROTOCOLS=>CURLPROTO_HTTPS,CURLOPT_PROXY=>'',
                CURLOPT_RESOLVE=>[$host.':443:'.$ip],CURLOPT_IPRESOLVE=>CURL_IPRESOLVE_V4,CURLOPT_SSL_VERIFYPEER=>true,CURLOPT_SSL_VERIFYHOST=>2,
                CURLOPT_CONNECTTIMEOUT_MS=>min(4000,$remaining),CURLOPT_TIMEOUT_MS=>$remaining,CURLOPT_ENCODING=>'gzip, deflate',
                CURLOPT_HTTPHEADER=>['Accept: text/html, application/xhtml+xml'],CURLOPT_USERAGENT=>'CifraSanta-Import/1.0',
                CURLOPT_WRITEFUNCTION=>static function($ch,string $chunk)use(&$body,&$tooLarge):int{
                    if(strlen($body)+strlen($chunk)>2*1024*1024){$tooLarge=true;return 0;}$body.=$chunk;return strlen($chunk);
                },
                CURLOPT_HEADERFUNCTION=>static function($ch,string $line)use(&$headers,&$headerBytes):int{
                    $headerBytes+=strlen($line);if($headerBytes>32768)return 0;
                    if(str_contains($line,':')){[$k,$v]=explode(':',$line,2);$headers[strtolower(trim($k))]=trim($v);}return strlen($line);
                },
            ]);
            $ok=curl_exec($ch);$status=curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$error=curl_errno($ch);curl_close($ch);
            if($tooLarge)throw new RuntimeException('A página excede o limite de 2 MB.',422);
            if($ok===false){error_log('Cifra Santa import http code='.$error.' host='.$host);throw new RuntimeException('Não foi possível acessar a página informada.',422);}
            if(in_array($status,[301,302,303,307,308],true)){$url=$policy->redirect($url,$headers['location']??'');continue;}
            if($status!==200)throw new RuntimeException('O provedor recusou a solicitação ou está indisponível.',422);
            if(!preg_match('~^(text/html|application/xhtml\+xml)(?:;|$)~i',$headers['content-type']??''))throw new RuntimeException('O endereço não retornou uma página HTML.',422);
            if(preg_match('/charset=["\x27]?([a-z0-9-]+)/i',$headers['content-type'],$charset) && strtolower($charset[1])!=='utf-8') {
                if(!in_array(strtolower($charset[1]),['iso-8859-1','windows-1252','us-ascii'],true))throw new RuntimeException('Codificação não suportada.',422);
                $body=mb_convert_encoding($body,'UTF-8',$charset[1]);
            }
            if(!mb_check_encoding($body,'UTF-8'))throw new RuntimeException('A página não possui codificação reconhecida.',422);
            return ['html'=>$body,'url'=>$url];
        }
        throw new RuntimeException('A página excedeu o limite de redirecionamentos.',422);
    }
}
