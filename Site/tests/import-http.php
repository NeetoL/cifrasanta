<?php
declare(strict_types=1);
require dirname(__DIR__).'/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;
$db=Database::connection();$service=new Service($db);$users=[];$cookies=[];$checks=0;
$base=getenv('TEST_BASE_URL')?:'http://127.0.0.1:8104';$password=bin2hex(random_bytes(16));
function httpImport(string $path,string $cookie,?array $data=null):array{global $base;$c=curl_init($base.$path);curl_setopt_array($c,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_COOKIEJAR=>$cookie,CURLOPT_COOKIEFILE=>$cookie,CURLOPT_TIMEOUT=>20]);if($data!==null)curl_setopt($c,CURLOPT_POSTFIELDS,http_build_query($data));$body=curl_exec($c);$code=curl_getinfo($c,CURLINFO_RESPONSE_CODE);curl_close($c);return [$code,$body?:''];}
function csrfImport(string $body):string{preg_match('/name="csrf" value="([a-f0-9]+)"/',$body,$m);return $m[1]??'';}
function okImport(bool $ok,string $label):void{global $checks;if(!$ok)throw new RuntimeException($label);$checks++;}
try{
 foreach(['admin','usuario'] as $role){$email='import-http-'.bin2hex(random_bytes(8)).'@example.invalid';$service->query('INSERT INTO cifra_santa_usuario(nome,email,senha_hash,papel) VALUES(?,?,?,?)',['Teste import HTTP',$email,password_hash($password,PASSWORD_DEFAULT),$role]);$users[]=['id'=>(int)$db->lastInsertId(),'email'=>$email];$cookies[]=tempnam(sys_get_temp_dir(),'cs-import-');}
 [$status,$body]=httpImport('/admin-import.php',$cookies[1]);okImport($status===401&&!str_contains($body,'name="url"'),'anônimo bloqueado');
 [$status,$body]=httpImport('/admin.php',$cookies[1]);$csrf=csrfImport($body);
 [$status]=httpImport('/admin.php',$cookies[1],['action'=>'login','csrf'=>$csrf,'email'=>$users[1]['email'],'senha'=>$password]);okImport($status===401,'login comum recusado');
 [$status,$body]=httpImport('/admin.php',$cookies[0]);$csrf=csrfImport($body);
 [$status]=httpImport('/admin.php',$cookies[0],['action'=>'login','csrf'=>$csrf,'email'=>$users[0]['email'],'senha'=>$password]);okImport($status===303,'login admin');
 [$status,$body]=httpImport('/admin-import.php',$cookies[0]);okImport($status===200&&str_contains($body,'name="url"')&&str_contains($body,'Importar cifra'),'tela admin: só a URL');$csrf=csrfImport($body);
 foreach(['name="slug"','name="provider"','Fontes autorizadas','admin-fontes.php','XPath'] as $legacy)okImport(!str_contains($body,$legacy),'sem campo técnico: '.$legacy);
 [$status]=httpImport('/admin-fontes.php',$cookies[0]);okImport($status===301,'rota antiga redireciona');
 [$status]=httpImport('/admin-import.php',$cookies[0],['action'=>'extract','url'=>'https://owned.example.org/test/']);okImport($status===419,'CSRF obrigatório');
 [$status,$body]=httpImport('/admin-import.php',$cookies[0],['action'=>'extract','url'=>'https://127.0.0.1/','csrf'=>$csrf]);okImport($status===422&&str_contains($body,'endereço completo'),'URL privada bloqueada');
 [$status,$body]=httpImport('/admin-import.php',$cookies[0],['action'=>'extract','url'=>'https://www.cifraclub.com.br/comunidade-gerados-pela-imaculada/odres-novos/','csrf'=>$csrf]);
 okImport($status===200&&!str_contains($body,'slug'),'URL real importada sem erro de slug');
 // Com config/import-providers.php autorizando o Cifra Club (uso pessoal), a cifra vem completa; sem ela, só os dados.
 $withContent=str_contains($body,'CIFRA ENCONTRADA');
 okImport(str_contains($body,'Odres Novos')&&str_contains($body,'Cifra Club')&&str_contains($body,'Salvar cifra')&&str_contains($body,'Editar')&&str_contains($body,'Cancelar')&&($withContent?str_contains($body,'class="chords"')&&!str_contains($body,'catálogo de terceiros'):str_contains($body,'MÚSICA IDENTIFICADA')&&str_contains($body,'catálogo de terceiros')),'prévia do caso real');
 file_put_contents(dirname(__DIR__,2).'/.work/import-real-preview.html',str_replace('href="assets/admin.css"','href="../Site/assets/admin.css"',$body));
 preg_match('/name="token" value="([a-f0-9]+)"/',$body,$real);
 if(!$withContent){[$status,$body]=httpImport('/admin-import.php',$cookies[0],['action'=>'save','token'=>$real[1]??'','csrf'=>$csrf,'categoria'=>'Entrada','autorizado'=>'1']);okImport($status===422&&str_contains($body,'Cole a cifra'),'catálogo de terceiros não salva sem cifra própria');}
 [$status]=httpImport('/admin-import.php',$cookies[0],['action'=>'cancel','token'=>$real[1]??'','csrf'=>$csrf]);okImport($status===303,'cancelar descarta a importação');
 // Fonte que responde 403 (servidor iniciado com CIFRA_IMPORT_PROVIDER_CONFIG=tests/import-providers-blocked.fixture.php).
 if($blocked=getenv('TEST_BLOCKED_URL')){
  [$status,$body]=httpImport('/admin-import.php',$cookies[0],['action'=>'extract','url'=>$blocked,'csrf'=>$csrf]);
  okImport(str_contains($body,'HTTP 403')&&str_contains($body,'Diagnóstico técnico')&&str_contains($body,'Status HTTP</dt><dd>403'),'403 real exibido no diagnóstico');
  okImport(str_contains($body,'name="conteudo"')&&str_contains($body,'Salvar cifra')&&str_contains($body,'não pôde ser lida automaticamente'),'403 abre o cadastro manual da mesma URL');
  okImport(substr_count($body,'name="url"')===0,'sem campos técnicos novos');
  file_put_contents(dirname(__DIR__,2).'/.work/import-blocked-preview.html',str_replace('href="assets/admin.css"','href="../Site/assets/admin.css"',$body));
  preg_match('/name="token" value="([a-f0-9]+)"/',$body,$blockedToken);
  [$status]=httpImport('/admin-import.php',$cookies[0],['action'=>'cancel','token'=>$blockedToken[1]??'','csrf'=>$csrf]);okImport($status===303,'cancelar o cadastro manual');
 }
 // Fixture de sessão somente neste teste, para conferir revisão/salvamento HTTP sem fonte externa.
 $cookieText=file_get_contents($cookies[0]);preg_match('/cifra_santa_admin\s+([^\s]+)/',$cookieText,$m);
 session_name('cifra_santa_admin');session_id($m[1]);session_start();
 $token=bin2hex(random_bytes(24));$draft=['provider'=>'owned','url_origem'=>'https://owned.example.org/test-'.bin2hex(random_bytes(6)).'/','titulo'=>'Cifra HTTP teste','artista'=>'Autor teste','tom'=>'C','categoria'=>'Entrada','afinacao'=>'','capotraste'=>'','formato'=>'inline','conteudo'=>'[C]Letra original de teste','publicada'=>''];
 $_SESSION['imports'][$token]=['draft'=>$draft,'expires'=>time()+1200];session_write_close();
 unset($draft['publicada'],$draft['provider'],$draft['url_origem']);$form=[...$draft,'token'=>$token,'csrf'=>$csrf,'action'=>'preview','titulo'=>'Cifra HTTP editada'];
 [$status,$body]=httpImport('/admin-import.php',$cookies[0],$form);okImport($status===200&&str_contains($body,'Cifra HTTP editada')&&str_contains($body,'Salvar cifra'),'editar e atualizar prévia');
 file_put_contents(dirname(__DIR__,2).'/.work/import-preview.html',str_replace('href="assets/admin.css"','href="../Site/assets/admin.css"',$body));
 $form['action']='save';[$status,$body]=httpImport('/admin-import.php',$cookies[0],$form);okImport($status===422&&str_contains($body,'autorização'),'salvar exige confirmação de autorização');
 $form['autorizado']='1';[$status]=httpImport('/admin-import.php',$cookies[0],$form);okImport($status===303,'salvar confirmado');
 $saved=$service->query('SELECT m.titulo,c.publicada FROM cifra_santa_musica m JOIN cifra_santa_cifra c ON c.musica_id=m.id WHERE m.criado_por=?',[$users[0]['id']])->fetch();okImport(($saved['titulo']??'')==='Cifra HTTP editada'&&(int)$saved['publicada']===0,'cifra editada gravada como rascunho');
 [$status]=httpImport('/admin-import.php',$cookies[0],$form);okImport($status===419,'replay impedido');
 $service->query("UPDATE cifra_santa_usuario SET papel='usuario' WHERE id=?",[$users[0]['id']]);
 [$status,$body]=httpImport('/admin-import.php',$cookies[0]);okImport($status===403&&!str_contains($body,'name="url"'),'permissão revogada bloqueia rota');
 echo "$checks verificações HTTP do painel passaram.\n";
}finally{foreach($users as $u){$service->query('DELETE FROM cifra_santa_musica WHERE criado_por=?',[$u['id']]);$service->query('DELETE FROM cifra_santa_usuario WHERE id=?',[$u['id']]);}foreach($cookies as $cookie)@unlink($cookie);}
