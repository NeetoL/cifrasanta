<?php
declare(strict_types=1);
require dirname(__DIR__).'/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;
use CifraSanta\Import\CifraImportService;
use CifraSanta\Import\CifraClubParser;
use CifraSanta\Import\ICifraProvider;
use CifraSanta\Import\UrlPolicy;
use CifraSanta\Import\ProviderResolver;
$db=Database::connection();$service=new Service($db);$users=[];$checks=0;
function expectImport(bool $ok,string $message):void{global $checks;if(!$ok)throw new RuntimeException($message);$checks++;}
function deniedImport(callable $fn,int $code):void{try{$fn();}catch(RuntimeException $e){expectImport($e->getCode()===$code,'código de rejeição');return;}throw new RuntimeException('Operação indevida permitida.');}
$provider=new class implements ICifraProvider {
 public int $calls=0;
 public function id():string{return 'integration';}
 public function name():string{return 'Fixture de teste';}
 public function domains():array{return ['owned.example.org'];}
 public function normalizeUrl(string $url):string{return (new UrlPolicy(['owned.example.org']))->normalize($url);}
 public function extract(string $url):array{$this->calls++;return ['provider'=>$this->id(),'url_origem'=>$this->normalizeUrl($url),'titulo'=>'Importação teste '.bin2hex(random_bytes(5)),'artista'=>'Autor teste','categoria'=>'Entrada','tom'=>'C','capotraste'=>'2','afinacao'=>'E A D G B E','formato'=>'inline','conteudo'=>"[C]Linha original de teste\n\n[G/B]Outra linha de teste",'publicada'=>''];}
};
try {
 foreach(['admin','usuario'] as $role){$service->query('INSERT INTO cifra_santa_usuario(nome,email,senha_hash,papel) VALUES(?,?,?,?)',['Importação teste','cs-import-'.bin2hex(random_bytes(8)).'@example.invalid',password_hash(bin2hex(random_bytes(20)),PASSWORD_DEFAULT),$role]);$users[]=(int)$db->lastInsertId();}
 $import=new CifraImportService($db,new ProviderResolver([$provider]));
 deniedImport(fn()=>$import->identify('https://owned.example.org/song/',$users[1]),403);
 expectImport($provider->calls===0,'usuário comum não executa provider');
 $draft=$import->identify('https://owned.example.org/test-'.bin2hex(random_bytes(8)).'/',$users[0]);
 expectImport((int)$service->query('SELECT COUNT(*) FROM cifra_santa_musica WHERE criado_por=?',[$users[0]])->fetchColumn()===0,'extração não grava música');
 unset($draft['publicada']);$prepared=$import->prepare($draft,$draft,$users[0]);
 expectImport($prepared['publicada']==='','rascunho por padrão');
 deniedImport(fn()=>$import->prepare($draft,[...$draft,'conteudo'=>' '],$users[0]),422);
 deniedImport(fn()=>$import->prepare($draft,[...$draft,'tom'=>''],$users[0]),422);
 deniedImport(fn()=>$import->identify('https://127.0.0.1/',$users[0]),422);
 $id=$import->save($prepared,$users[0]);
 $saved=$service->query('SELECT c.conteudo,c.publicada,i.capotraste,i.afinacao,i.url_origem FROM cifra_santa_cifra c JOIN cifra_santa_importacao i ON i.musica_id=c.musica_id WHERE c.musica_id=?',[$id])->fetch();
 expectImport($saved['conteudo']===$prepared['conteudo'] && (int)$saved['publicada']===0,'cifra e rascunho persistidos');
 expectImport($saved['capotraste']==='2' && $saved['afinacao']==='E A D G B E','metadados persistidos');
 deniedImport(fn()=>$import->save($prepared,$users[1]),403);
 deniedImport(fn()=>$import->save($prepared,$users[0]),409);
 $prepared['url_origem']='https://owned.example.org/another/';deniedImport(fn()=>$import->save($prepared,$users[0]),409);
 expectImport((int)$service->query('SELECT COUNT(*) FROM cifra_santa_musica WHERE criado_por=?',[$users[0]])->fetchColumn()===1,'duplicatas não criam registros');
 // Fonte bloqueada (HTTP 403): rascunho manual da mesma URL, com sugestões do endereço e sem conteúdo.
 $manualUrl='https://owned.example.org/comunidade-gerados-pela-imaculada/odres-novos-'.bin2hex(random_bytes(3)).'/';
 $manual=$import->manualDraft($manualUrl,$users[0],'O servidor respondeu HTTP 403.');
 expectImport($manual['url_origem']===$manualUrl && $manual['provider']===$provider->id() && $manual['conteudo']==='' && $manual['tom']==='','rascunho manual sem conteúdo');
 expectImport(str_starts_with($manual['titulo'],'Odres Novos ') && $manual['artista']==='Comunidade Gerados pela Imaculada','sugestão de título e artista pelo endereço');
 expectImport(str_contains($manual['aviso'],'HTTP 403') && $provider->calls===1,'motivo real no aviso e nenhum download extra');
 deniedImport(fn()=>$import->manualDraft($manualUrl,$users[1],'x'),403);
 deniedImport(fn()=>$import->manualDraft('https://127.0.0.1/a/',$users[0],'x'),422);
 deniedImport(fn()=>$import->prepare($manual,$manual,$users[0]),422);
 $filled=$import->prepare($manual,[...$manual,'categoria'=>'Entrada','tom'=>'Bm','conteudo'=>"[Bm]Letra própria de [G]teste"],$users[0]);
 $manualId=$import->save($filled,$users[0]);
 expectImport((string)$service->query('SELECT i.url_origem FROM cifra_santa_importacao i WHERE i.musica_id=?',[$manualId])->fetchColumn()===$manualUrl,'cadastro manual salvo com a URL de origem');
 deniedImport(fn()=>$import->manualDraft($manualUrl,$users[0],'x'),409);
 // Saída do CifraClubParser (fixture com letra inventada) → prévia → gravação, sem perder alinhamento.
 $parsed=(new CifraClubParser())->parse(file_get_contents(__DIR__.'/fixtures/cifraclub-estrutura.html'));
 $chartDraft=['provider'=>$provider->id(),'url_origem'=>'https://owned.example.org/cc-'.bin2hex(random_bytes(6)).'/','categoria'=>'Louvor',...array_intersect_key($parsed,array_flip(['titulo','artista','tom','capotraste','afinacao','conteudo','formato']))];
 $chartDraft['titulo'].=' '.bin2hex(random_bytes(4));
 $chartData=$import->prepare($chartDraft,$chartDraft,$users[0]);
 expectImport($chartData['conteudo']===$parsed['conteudo'] && $chartData['tom']==='Bm' && $chartData['capotraste']==='5ª casa' && $chartData['afinacao']==='Padrão','prévia mantém cifra e metadados do parser');
 $chartId=$import->save($chartData,$users[0]);
 $stored=$service->query('SELECT c.conteudo,c.tom,i.capotraste,i.afinacao FROM cifra_santa_cifra c JOIN cifra_santa_importacao i ON i.musica_id=c.musica_id WHERE c.musica_id=?',[$chartId])->fetch();
 expectImport($stored['conteudo']===$parsed['conteudo'] && $stored['tom']==='Bm' && $stored['capotraste']==='5ª casa' && $stored['afinacao']==='Padrão','cifra do parser persistida byte a byte');
 expectImport(str_contains($stored['conteudo'],'E|-----0--0---2') && str_contains($stored['conteudo'],'[Refrão]'),'tablatura e seções persistidas');
 echo "$checks verificações de autorização, prévia e persistência passaram.\n";
}finally{
 foreach($users as $id){$service->query('DELETE FROM cifra_santa_musica WHERE criado_por=?',[$id]);$service->query('DELETE FROM cifra_santa_usuario WHERE id=?',[$id]);foreach(['import-identify:','import-save:'] as $scope)$service->query('DELETE FROM cifra_santa_limite_acesso WHERE chave=?',[hash('sha256',$scope.$id)]);}
 echo "Dados temporários removidos.\n";
}
