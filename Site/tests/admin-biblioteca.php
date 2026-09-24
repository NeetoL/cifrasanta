<?php
declare(strict_types=1);
// Biblioteca do painel: busca/filtro no servidor, no máximo 100 músicas (as mais recentes) e 10 por página.
// Grava dados temporários no banco configurado (use DATABASE_DSN_PROD para um banco local) e remove ao final.
// Uso: TEST_BASE_URL=http://127.0.0.1:8105 php Site/tests/admin-biblioteca.php --allow-configured-database
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if (!in_array('--allow-configured-database', $argv, true)) exit("Use --allow-configured-database para permitir registros temporários de teste, removidos ao final.\n");
require dirname(__DIR__).'/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;
$db=Database::connection();$service=new Service($db);$checks=0;$adminId=0;
$base=getenv('TEST_BASE_URL')?:'http://127.0.0.1:8097';$cookie=tempnam(sys_get_temp_dir(),'cs-lib-');$password=bin2hex(random_bytes(16));
$tag='bib'.bin2hex(random_bytes(4));
function libGet(string $path,?array $post=null):array{global $base,$cookie;$c=curl_init($base.$path);curl_setopt_array($c,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_COOKIEJAR=>$cookie,CURLOPT_COOKIEFILE=>$cookie,CURLOPT_TIMEOUT=>20]);if($post!==null)curl_setopt($c,CURLOPT_POSTFIELDS,http_build_query($post));$body=curl_exec($c);$code=curl_getinfo($c,CURLINFO_RESPONSE_CODE);curl_close($c);return [$code,(string)$body];}
function libOk(bool $ok,string $label):void{global $checks;if(!$ok)throw new RuntimeException('Falhou: '.$label);$checks++;}
/** IDs das linhas da biblioteca, na ordem exibida. */
function libRows(string $body):array{preg_match_all('/<li class="song[^"]*" data-id="(\d+)"/',$body,$m);return array_map('intval',$m[1]);}
function libPick(string $body):array{return preg_match('~<script type="application/json" id="pick-data">(.*?)</script>~s',$body,$m)?json_decode($m[1],true):[];}
try{
 $email=$tag.'@example.invalid';
 $service->query('INSERT INTO cifra_santa_usuario(nome,email,senha_hash,papel) VALUES(?,?,?,?)',['Teste biblioteca',$email,password_hash($password,PASSWORD_DEFAULT),'admin']);$adminId=(int)$db->lastInsertId();
 // 125 músicas: pares publicadas, ímpares rascunho. A 1ª tem título com HTML para conferir o escape.
 $ids=[];
 for($i=1;$i<=125;$i++){
  $title=$i===1?'<script>alert(1)</script> '.$tag:"Canção $tag ".str_pad((string)$i,3,'0',STR_PAD_LEFT);
  $service->query('INSERT INTO cifra_santa_musica(titulo,artista,categoria,criado_por) VALUES(?,?,?,?)',[$title,$i===7?'Artista Único Ção':'Autor '.$tag,$i%10===0?'Comunhão':'Entrada',$adminId]);
  $id=(int)$db->lastInsertId();$ids[$i]=$id;
  $service->query('INSERT INTO cifra_santa_cifra(musica_id,tom,conteudo,publicada) VALUES(?,?,?,?)',[$id,'C','[C]Teste',$i%2===0?1:0]);
 }
 $total=(int)$service->query('SELECT COUNT(*) FROM cifra_santa_musica')->fetchColumn();
 [,$body]=libGet('/admin.php');preg_match('/name="csrf" value="([a-f0-9]+)"/',$body,$m);
 [$status]=libGet('/admin.php',['action'=>'login','csrf'=>$m[1]??'','email'=>$email,'senha'=>$password]);libOk($status===303,'login admin de teste');

 // Padrão: 10 por página, as mais recentes primeiro, no máximo 100.
 [$status,$body]=libGet('/admin.php');
 $rows=libRows($body);
 libOk($status===200 && count($rows)===10,'10 músicas na primeira página');
 libOk($rows[0]===$ids[125] && $rows[9]===$ids[116],'mais recentes primeiro');
 libOk(str_contains($body,'1–10 de 100') && str_contains($body,"$total no total"),'contagem limitada a 100 com aviso do total');
 libOk(preg_match_all('/class="pager-num/',$body)===10 && str_contains($body,'rel="next"') && !str_contains($body,'rel="prev"'),'10 páginas, sem "Anterior" na primeira');
 libOk(str_contains($body,'<strong>'.$total.'</strong><span class="label">Músicas no acervo'),'contador usa o total do acervo');
 [,$last]=libGet('/admin.php?p=10');$rows=libRows($last);
 libOk(count($rows)===10 && $rows[0]===$ids[35] && $rows[9]===$ids[26] && str_contains($last,'91–100 de 100') && !str_contains($last,'rel="next"'),'página 10 = itens 91 a 100');
 [,$beyond]=libGet('/admin.php?p=999');libOk(libRows($beyond)===$rows,'página inexistente vai para a última');
 [,$weird]=libGet('/admin.php?p=abc&status=xyz');libOk(count(libRows($weird))===10 && str_contains($weird,'1–10 de 100'),'parâmetros inválidos ignorados');

 // Busca no banco: encontra músicas fora das 100 mais recentes.
 [,$old]=libGet('/admin.php?q='.urlencode("Canção $tag 003"));
 libOk(libRows($old)===[$ids[3]] && str_contains($old,'1–1 de 1'),'busca encontra música antiga (fora das 100)');
 [,$accent]=libGet('/admin.php?q='.urlencode('artista unico cao'));libOk(libRows($accent)===[$ids[7]],'busca ignora acentos e maiúsculas');
 [,$cat]=libGet('/admin.php?q='.urlencode('comunhao').'&status=pub');
 libOk(count(libRows($cat))>=10 && !array_diff(array_slice(libRows($cat),0,10),array_map(fn($i)=>$ids[$i],[120,110,100,90,80,70,60,50,40,30])),'busca por momento + filtro publicadas');
 [,$all]=libGet('/admin.php?q='.urlencode($tag));
 libOk(str_contains($all,'1–10 de 100') && str_contains($all,'125 no total'),'busca ampla também limitada a 100');
 [,$page2]=libGet('/admin.php?q='.urlencode($tag).'&p=2');libOk(libRows($page2)[0]===$ids[115],'paginação preserva a busca');
 libOk(str_contains($page2,'href="admin.php?q='.$tag.'&amp;p=3#musicas"') && str_contains($page2,'href="admin.php?q='.$tag.'#musicas" rel="prev"'),'links de página mantêm a busca');
 [,$none]=libGet('/admin.php?q='.urlencode('nada-'.$tag.'-xyz'));
 libOk(libRows($none)===[] && str_contains($none,'Nenhuma música encontrada para') && !str_contains($none,'Ainda não há músicas'),'busca sem resultado');
 [,$like]=libGet('/admin.php?q='.urlencode('%'));libOk(libRows($like)===[],'curinga % tratado como texto');

 // Filtro de situação no servidor.
 [,$drafts]=libGet('/admin.php?status=draft');[,$pubs]=libGet('/admin.php?status=pub');
 libOk(libRows($drafts)[0]===$ids[125] && libRows($pubs)[0]===$ids[124],'filtros Rascunhos e Publicadas');
 libOk(str_contains($drafts,'name="status" value="draft" class="is-on" aria-pressed="true"'),'botão do filtro ativo marcado');

 // Editar mantém a lista; o editor carrega a música mesmo fora da página.
 libOk(str_contains($page2,'href="admin.php?q='.$tag.'&amp;p=2&amp;song='.$ids[115].'#editor"'),'Editar mantém busca e página');
 [,$edit]=libGet('/admin.php?song='.$ids[2]);libOk(str_contains($edit,'value="Canção '.$tag.' 002"'),'editor abre música fora da página atual');

 // Montador de repertório recebe todas as músicas, sem cifras, com escape seguro.
 $pick=libPick($body);
 libOk(count($pick)===$total && $pick[0][0]===(string)$ids[125] && count($pick[0])===4,'montador com todas as músicas (id, título, artista, rascunho)');
 libOk(!str_contains($body,'<script>alert(1)</script>'),'título com HTML não aparece cru na página');
 libOk(str_contains($body,trim(json_encode('<script>',JSON_HEX_TAG),'"')),'título com HTML escapado no JSON do montador');
 [,$xss]=libGet('/admin.php?q='.urlencode('alert(1)'));
 libOk(libRows($xss)===[$ids[1]] && str_contains($xss,'&lt;script&gt;alert(1)&lt;/script&gt;') && !str_contains($xss,'<script>alert(1)</script>'),'título com HTML escapado na lista');
 libOk(!str_contains(substr($body,strpos($body,'id="pick-data"'),20000),'[C]Teste'),'JSON do montador sem o conteúdo das cifras');
 echo "$checks verificações da biblioteca passaram.\n";
}finally{
 if($adminId){$service->query('DELETE FROM cifra_santa_musica WHERE criado_por=?',[$adminId]);$service->query('DELETE FROM cifra_santa_usuario WHERE id=?',[$adminId]);}
 @unlink($cookie);
}
