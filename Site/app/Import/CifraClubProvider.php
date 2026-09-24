<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;

/**
 * Cifra Club: obtém a página (HTTP GET, sem executar JavaScript) e entrega o HTML ao CifraClubParser.
 * Só aceita os hosts do site, inclusive em redirects.
 *
 * A letra e a cifra do Cifra Club têm direitos autorais. Sem $authorization o provedor traz só os
 * dados da música (título, artista, tom, capotraste, afinação); o parser ainda confirma que a estrutura
 * da cifra foi reconhecida, mas o conteúdo não é copiado. Com uma autorização registrada pelo
 * desenvolvedor em config/import-providers.php ('cifraclub' => ['authorization' => '...']), o conteúdo
 * é importado com a formatação preservada.
 */
final class CifraClubProvider implements ICifraProvider {
    public const DOMAINS=['www.cifraclub.com.br','cifraclub.com.br','m.cifraclub.com.br'];
    private UrlPolicy $policy;
    public function __construct(private string $authorization='',private SafeHttpClient $http=new SafeHttpClient(),private CifraClubParser $parser=new CifraClubParser()) {
        $this->policy=new UrlPolicy(self::DOMAINS);
    }
    public function id():string{return 'cifraclub';}
    public function name():string{return 'Cifra Club';}
    public function domains():array{return self::DOMAINS;}
    public function importsContent():bool{return trim($this->authorization)!=='';}
    public function normalizeUrl(string $url):string{return $this->policy->normalize($url);}

    public function extract(string $url):array {
        $response=$this->http->get($this->normalizeUrl($url),$this->policy);
        $diagnostic=$response['diagnostico'];
        try{
            $parsed=$this->parser->parse($response['html']);
        }catch(RuntimeException $e){
            $diagnostic['erro']=['etapa'=>'parser','detalhe'=>$e->getMessage()];
            error_log('Cifra Santa import parser '.json_encode($diagnostic,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE));
            throw new ImportDiagnosticException($e->getMessage(),422,$diagnostic,$e);
        }
        $diagnostic['parser']=['deteccao'=>$parsed['deteccao'],'estrutura'=>$parsed['estrutura'],'conteudo_importado'=>$this->importsContent()];
        $draft=['url_origem'=>$response['url'],'provider'=>$this->id(),'provider_nome'=>$this->name(),'diagnostico'=>$diagnostic,
            'categoria'=>'','publicada'=>'','formato'=>'inline',
            ...array_intersect_key($parsed,array_flip(['titulo','artista','tom','capotraste','afinacao']))];
        if($this->importsContent())return [...$draft,'conteudo'=>$parsed['conteudo'],'aviso'=>''];
        return [...$draft,'conteudo'=>'','aviso'=>'Cifra Club é um catálogo de terceiros: a letra e a cifra têm direitos autorais e não são copiadas. Trouxemos só os dados da música. Cole a cifra de uma fonte própria ou autorizada em "Editar".'];
    }
}
