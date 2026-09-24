<?php
declare(strict_types=1);
namespace CifraSanta\Import;

/**
 * Provedor padrão: baixa a página e detecta título, artista, tom, afinação, capotraste e cifra sozinho.
 * Com $importsContent=false (catálogos de terceiros) traz só os dados da música; a cifra fica a cargo do admin.
 */
final class AutoDetectProvider implements ICifraProvider {
    private UrlPolicy $policy;
    public function __construct(private string $key,private string $label,private bool $importsContent=true,private string $notice='',private SafeHttpClient $http=new SafeHttpClient(),private HtmlChartParser $parser=new HtmlChartParser()) {
        $this->policy=new UrlPolicy();
    }
    public function id():string{return $this->key;}
    public function name():string{return $this->label;}
    public function domains():array{return [];}
    public function normalizeUrl(string $url):string{return $this->policy->normalize($url);}
    public function extract(string $url):array {
        $response=$this->http->get($this->normalizeUrl($url),$this->policy);
        return ['url_origem'=>$response['url'],'provider'=>$this->id(),'provider_nome'=>$this->name(),'diagnostico'=>$response['diagnostico'],'aviso'=>$this->notice,...$this->parser->detect($response['html'],$this->importsContent)];
    }
}
