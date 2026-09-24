<?php
declare(strict_types=1);
namespace CifraSanta\Import;
use RuntimeException;

/**
 * Escolhe o provedor pela URL, sem nenhuma configuração do administrador:
 * 1. sites com leitura dedicada em config/import-providers.php (opcional, mantido pelo desenvolvedor);
 * 2. sites com provedor próprio no código (Cifra Club: CifraClubProvider + CifraClubParser);
 * 3. catálogos de cifras de terceiros: só os dados da música, sem letra/cifra;
 * 4. qualquer outro site: detecção automática completa.
 */
final class ProviderResolver {
    /** Catálogos de cifras mantidos por terceiros. A letra e a cifra têm direitos autorais e não são copiadas. */
    public const REFERENCE_ONLY=[
        'cifras.com.br'=>'Cifras.com.br','letras.mus.br'=>'Letras.mus.br',
        'ultimate-guitar.com'=>'Ultimate Guitar','e-chords.com'=>'E-Chords','cifra.com.br'=>'Cifra.com.br',
    ];
    private ?array $configured;
    /** @param ICifraProvider[]|null $configured provedores dedicados; null lê config/import-providers.php. */
    public function __construct(?array $configured=null){$this->configured=$configured;}

    public function resolve(string $url):ICifraProvider {
        $host=UrlPolicy::host($url);
        foreach($this->configured() as $provider)if(in_array($host,$provider->domains(),true))return $provider;
        if(in_array($host,CifraClubProvider::DOMAINS,true))return new CifraClubProvider();
        foreach(self::REFERENCE_ONLY as $domain=>$name){
            if($host===$domain || str_ends_with($host,'.'.$domain)){
                return new AutoDetectProvider('referencia',$name,false,$name.' é um catálogo de terceiros: a letra e a cifra têm direitos autorais e não são copiadas. Trouxemos só os dados da música. Cole a cifra de uma fonte própria ou autorizada em "Editar".');
            }
        }
        return new AutoDetectProvider('automatico',$host);
    }

    /** @return ICifraProvider[] */
    private function configured():array {
        if($this->configured!==null)return $this->configured;
        $file=getenv('CIFRA_IMPORT_PROVIDER_CONFIG') ?: dirname(__DIR__,2).'/config/import-providers.php';
        $config=is_file($file)?require $file:[];
        if(!is_array($config))throw new RuntimeException('Configuração de importação inválida.',422);
        $this->configured=[];
        foreach($config as $id=>$entry){
            if(!preg_match('/^[a-z0-9_-]{1,40}$/D',(string)$id))throw new RuntimeException('Identificador de provedor inválido.',422);
            // Autorização de conteúdo do Cifra Club: só a referência; o provedor e o parser são fixos no código.
            if($id==='cifraclub'){if(is_string($entry['authorization']??null) && trim($entry['authorization'])!=='')$this->configured[]=new CifraClubProvider($entry['authorization']);continue;}
            if(($entry['enabled']??false)===true)$this->configured[]=new ConfiguredHtmlProvider((string)$id,$entry);
        }
        return $this->configured;
    }
}
