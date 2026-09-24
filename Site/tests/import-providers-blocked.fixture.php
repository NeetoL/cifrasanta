<?php
// Somente para tests/import-http.php com TEST_BLOCKED_URL: um endpoint público que responde HTTP 403 de verdade.
return ['bloqueado'=>['enabled'=>true,'name'=>'Fonte bloqueada de teste','authorization'=>'Fixture de teste','domains'=>['httpbin.org'],'selectors'=>['titulo'=>'//h1','artista'=>'//h2','conteudo'=>'//pre'],'format'=>'aligned']];
