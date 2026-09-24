<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
$target = dirname(__DIR__) . '/config/install.php';
if (file_exists($target)) { fwrite(STDERR, "A chave já está configurada. Não foi substituída.\n"); exit(1); }
$key = bin2hex(random_bytes(24));
file_put_contents($target, "<?php\ndeclare(strict_types=1);\nreturn '" . hash('sha256', $key) . "';\n", LOCK_EX);
$privatePath = dirname(__DIR__, 2) . '/admin-install-key.txt';
file_put_contents($privatePath, "Chave para o primeiro administrador do Cifra Santa:\n" . $key . "\n\nUse em /cifrasanta/admin.php. Não publique este arquivo.\n", LOCK_EX);
echo "Chave criada em admin-install-key.txt (fora da pasta Site).\n";
