<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;
/** Sem lista de domínios, aceita qualquer host público por nome (IPs privados continuam bloqueados em resolve()). */
final class UrlPolicy {
    private const HOST='/^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$/D';
    public function __construct(private array $domains=[]) {
        foreach($domains as $domain) if(!is_string($domain) || !preg_match(self::HOST,$domain)) throw new RuntimeException('Domínio do provedor inválido.',422);
    }
    public static function host(string $url):string {return (string)parse_url((new self())->normalize($url),PHP_URL_HOST);}
    public function normalize(string $url):string {
        $url=trim($url);
        if(strlen($url)>1000 || preg_match('/[^\x21-\x7e]/',$url) || preg_match('/[\x00-\x20\x7f\\\\]/',$url))throw new RuntimeException('URL inválida.',422);
        $p=parse_url($url);
        if(!$p || strtolower($p['scheme']??'')!=='https' || isset($p['user']) || isset($p['pass']) || isset($p['port']) && $p['port']!==443)throw new RuntimeException('Informe uma URL HTTPS sem credenciais ou porta alternativa.',422);
        $host=strtolower($p['host']??'');
        if(!preg_match(self::HOST,$host))throw new RuntimeException('Informe o endereço completo da página, como https://site.com.br/musica/.',422);
        if($this->domains && !in_array($host,$this->domains,true))throw new RuntimeException('Domínio não permitido por este provedor.',422);
        $path=$p['path']??'/';
        if(preg_match('/%(?:0[0-9a-f]|1[0-9a-f]|7f|5c)/i',$path.($p['query']??'')))throw new RuntimeException('URL inválida.',422);
        if(preg_match('/%(?![a-f0-9]{2})/i',$path.($p['query']??'')))throw new RuntimeException('URL inválida.',422);
        $path=preg_replace_callback('/%([a-f0-9]{2})/i',static function($m){$c=chr(hexdec($m[1]));return preg_match('/[A-Za-z0-9._~-]/',$c)?$c:strtoupper($m[0]);},$path);
        $segments=[];
        foreach(explode('/',$path) as $segment){if($segment==='.')continue;if($segment==='..'){array_pop($segments);continue;}$segments[]=$segment;}
        $path=implode('/',$segments);if(!str_starts_with($path,'/'))$path='/'.$path;
        return 'https://'.$host.($path===''?'/':$path).(isset($p['query'])?'?'.$p['query']:'');
    }
    public static function publicIpv4(string $ip):bool {
        if(!filter_var($ip,FILTER_VALIDATE_IP,FILTER_FLAG_IPV4|FILTER_FLAG_NO_PRIV_RANGE|FILTER_FLAG_NO_RES_RANGE))return false;
        $n=ip2long($ip);
        foreach([['0.0.0.0',8],['100.64.0.0',10],['127.0.0.0',8],['169.254.0.0',16],['192.0.0.0',24],['192.0.2.0',24],['192.88.99.0',24],['198.18.0.0',15],['198.51.100.0',24],['203.0.113.0',24],['224.0.0.0',4],['240.0.0.0',4]] as [$network,$bits]) {
            $mask=(-1 << (32-$bits));if(($n & $mask)===(ip2long($network)&$mask))return false;
        }
        return true;
    }
    public function resolve(string $url):array {
        $url=$this->normalize($url);$host=parse_url($url,PHP_URL_HOST);
        $ips=gethostbynamel($host);
        if(!$ips)throw new RuntimeException('Falha de DNS: não foi possível resolver '.$host.'.',422);
        foreach($ips as $ip)if(!self::publicIpv4($ip))throw new RuntimeException('O domínio '.$host.' aponta para um endereço não permitido ('.$ip.').',422);
        return [$host,$ips[0]];
    }
    public function redirect(string $base,string $location):string {
        if(preg_match('~^https?://~i',$location))return $this->normalize($location);
        if(str_starts_with($location,'//'))return $this->normalize('https:'.$location);
        if($location==='' || preg_match('/^[a-z][a-z0-9+.-]*:/i',$location))throw new RuntimeException('Redirecionamento inválido.',422);
        $p=parse_url($base);$path=$p['path']??'/';
        if(str_starts_with($location,'?'))$path.=$location;
        else $path=str_starts_with($location,'/')?$location:substr($path,0,strrpos($path,'/')+1).$location;
        return $this->normalize('https://'.$p['host'].$path);
    }
}
