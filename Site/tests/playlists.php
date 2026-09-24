<?php
declare(strict_types=1);
// Testa a API local contra o banco configurado, removendo apenas contas temporárias.
require __DIR__.'/../app/Core/Database.php';
$db=\CifraSanta\Core\Database::connection();
$emails=[];$checks=0;
function requestApi(string $route,?array $data=null,?string $token=null): array {
 $ch=curl_init((getenv('CIFRA_TEST_API') ?: 'http://127.0.0.1:8101/api.php').'?route='.$route);
 $headers=['Accept: application/json'];
 if($data!==null){$headers[]='Content-Type: application/json';curl_setopt($ch,CURLOPT_POSTFIELDS,json_encode($data));}
 if($token)$headers[]='Authorization: Bearer '.$token;
 curl_setopt_array($ch,[CURLOPT_HTTPHEADER=>$headers,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>90]);
 $raw=curl_exec($ch);$status=curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);
 if($raw===false) throw new RuntimeException('A API não respondeu no prazo.');
 return [$status,json_decode($raw,true,512,JSON_THROW_ON_ERROR)];
}
function check(bool $condition,string $label):void {global $checks;if(!$condition)throw new RuntimeException($label);$checks++;echo 'OK: '.$label.PHP_EOL;}
try {
 $tokens=[];
 for($i=0;$i<2;$i++){
  $emails[]=$email='cs-list-test-'.bin2hex(random_bytes(8)).'@example.invalid';
  [$status,$account]=requestApi('register',['nome'=>'Teste temporário','email'=>$email,'senha'=>bin2hex(random_bytes(18))]);
  check($status===201,'cadastro');$tokens[]=$account['token'];
 }
 [$status]=requestApi('playlists');check($status===401,'exige autenticação');
 [$status,$catalog]=requestApi('catalog');$songs=array_column($catalog['songs'],'id');check(count($songs)>=2,'catálogo de teste');
 [$status,$result]=requestApi('playlists',['action'=>'save','title'=>'Lista privada de teste','songIds'=>[$songs[1],$songs[0]]],$tokens[0]);
 check($status===200,'criar lista');$list=$result['playlists'][0];
 check($list['songIds']===[$songs[1],$songs[0]],'ordem preservada');
 [$status,$other]=requestApi('playlists',null,$tokens[1]);check($status===200 && $other['playlists']===[],'isolamento leitura');
 $edit=['action'=>'save','id'=>$list['id'],'version'=>1,'title'=>'Renomeada','songIds'=>[$songs[0]]];
 [$status]=requestApi('playlists',$edit,$tokens[1]);check($status===404,'isolamento edição');
 [$status]=requestApi('playlists',['action'=>'delete','id'=>$list['id'],'version'=>1],$tokens[1]);check($status===404,'isolamento exclusão');
 [$status]=requestApi('playlists',array_replace($edit,['songIds'=>[$songs[0],$songs[0]]]),$tokens[0]);check($status===422,'sem duplicatas');
 [$status]=requestApi('playlists',array_replace($edit,['songIds'=>['999999999']]),$tokens[0]);check($status===422,'música inexistente');
 [$status,$result]=requestApi('playlists',$edit,$tokens[0]);check($status===200 && $result['playlists'][0]['version']===2,'renomear e remover');
 [$status]=requestApi('playlists',$edit,$tokens[0]);check($status===409,'edição obsoleta rejeitada');
 [$status,$public]=requestApi('catalog');check(!str_contains(json_encode($public),'Renomeada'),'lista privada ausente catálogo');
 [$status,$result]=requestApi('playlists',['action'=>'delete','id'=>$list['id'],'version'=>2],$tokens[0]);check($status===200 && $result['playlists']===[],'excluir lista');
 echo "$checks verificações de listas passaram.\n";
} finally {
 foreach($emails as $email){$q=$db->prepare('DELETE FROM cifra_santa_usuario WHERE email=?');$q->execute([$email]);}
 echo "Contas e listas temporárias removidas.\n";
}
