<?php
declare(strict_types=1);
require __DIR__.'/../app/Core/Database.php';
require __DIR__.'/../app/Core/Service.php';
require __DIR__.'/../app/Core/Playlists.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;
use CifraSanta\Core\Playlists;
$db=Database::connection();$service=new Service($db);$lists=new Playlists($db);$users=[];$checks=0;
function verify(bool $ok,string $label):void {global $checks;if(!$ok)throw new RuntimeException($label);$checks++;echo 'OK '.$label.PHP_EOL;}
function rejects(callable $operation,int $code):void {try{$operation();}catch(RuntimeException $e){verify($e->getCode()===$code,'rejeição '.$code);return;}throw new RuntimeException('Operação indevida permitida.');}
try {
 for($i=0;$i<2;$i++){
  $service->query('INSERT INTO cifra_santa_usuario(nome,email,senha_hash) VALUES(?,?,?)',['Teste listas serviço','cs-list-service-'.bin2hex(random_bytes(8)).'@example.invalid',password_hash(bin2hex(random_bytes(20)),PASSWORD_DEFAULT)]);
  $users[]=(int)$db->lastInsertId();
 }
 $songIds=array_slice(array_column($service->catalog()['songs'],'id'),0,2);verify(count($songIds)===2,'catálogo');
 $result=$lists->mutate($users[0],['action'=>'save','title'=>'Teste privado','songIds'=>array_reverse($songIds)]);$list=$result[0];
 verify($list['songIds']===array_reverse($songIds),'criar e ordenar');
 verify($lists->all($users[1])===[],'isolamento leitura');
 $edit=['action'=>'save','id'=>$list['id'],'version'=>1,'title'=>'Novo título','songIds'=>[$songIds[0]]];
 rejects(fn()=>$lists->mutate($users[1],$edit),404);
 rejects(fn()=>$lists->mutate($users[1],['action'=>'delete','id'=>$list['id'],'version'=>1]),404);
 rejects(fn()=>$lists->mutate($users[0],array_replace($edit,['songIds'=>[$songIds[0],$songIds[0]]])),422);
 rejects(fn()=>$lists->mutate($users[0],array_replace($edit,['songIds'=>['999999999']])),422);
 $result=$lists->mutate($users[0],$edit);verify($result[0]['version']===2 && $result[0]['title']==='Novo título','editar');
 rejects(fn()=>$lists->mutate($users[0],$edit),409);
 verify(!str_contains(json_encode($service->catalog()),'Novo título'),'catálogo público sem listas privadas');
 verify($lists->mutate($users[0],['action'=>'delete','id'=>$list['id'],'version'=>2])===[],'excluir');
 echo "$checks verificações concluídas.\n";
}finally{foreach($users as $id)$service->query('DELETE FROM cifra_santa_usuario WHERE id=?',[$id]);echo "Dados temporários removidos.\n";}
