<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;
final class ConfiguredHtmlProvider implements ICifraProvider {
    private UrlPolicy $policy;
    public function __construct(private string $key,private array $config,private SafeHttpClient $http=new SafeHttpClient(),private HtmlChartParser $parser=new HtmlChartParser()) {
        if(($config['enabled']??false)!==true || trim($config['authorization']??'')==='')throw new RuntimeException('Provedor desabilitado ou sem autorização configurada.',422);
        foreach(['titulo','artista','conteudo'] as $key)if(empty($config['selectors'][$key]))throw new RuntimeException('Configure os seletores obrigatórios do provedor.',422);
        $this->policy=new UrlPolicy($config['domains']??[]);
    }
    public function id():string{return $this->key;}
    public function name():string{return $this->config['name']??$this->key;}
    public function normalizeUrl(string $url):string{return $this->policy->normalize($url);}
    public function domains():array{return $this->config['domains'];}
    public function extract(string $url):array {
        $response=$this->http->get($this->normalizeUrl($url),$this->policy);
        return ['url_origem'=>$response['url'],'provider'=>$this->id(),'provider_nome'=>$this->name(),'aviso'=>'',...$this->parser->parse($response['html'],$this->config)];
    }
}
