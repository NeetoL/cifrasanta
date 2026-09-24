<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require dirname(__DIR__).'/app/Core/Database.php';
$db=\CifraSanta\Core\Database::connection();
if ((int)$db->query("SELECT GET_LOCK('cifra_santa_migration',10)")->fetchColumn()!==1) throw new RuntimeException('Migração em andamento.');
try {
 $sql=file_get_contents(dirname(__DIR__).'/database/003_playlists.sql');$checksum=hash('sha256',$sql);
 $q=$db->prepare('SELECT checksum FROM cifra_santa_migracao WHERE versao=?');$q->execute(['003_playlists']);$saved=$q->fetchColumn();
 if($saved && $saved!==$checksum) throw new RuntimeException('Checksum incompatível.');
 if(!$saved) {
  foreach(explode(';',$sql) as $statement) if(trim($statement)!=='') $db->exec($statement);
  $db->prepare('INSERT INTO cifra_santa_migracao(versao,checksum) VALUES(?,?)')->execute(['003_playlists',$checksum]);
 }
 echo "Tabelas de listas pessoais prontas.\n";
} finally { $db->query("SELECT RELEASE_LOCK('cifra_santa_migration')"); }
