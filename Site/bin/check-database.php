<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require dirname(__DIR__) . '/app/Core/Database.php';

try {
    $connection = \CifraSanta\Core\Database::connection();
    $connection->query('SELECT 1')->fetchColumn();
    fwrite(STDOUT, "Conexão com MySQL verificada. Nenhum dado foi alterado.\n");
} catch (Throwable $error) {
    // Não imprime mensagens do driver que possam revelar dados da conexão.
    fwrite(STDERR, "Não foi possível conectar. Confira o nome do banco, as credenciais, o driver pdo_mysql e a liberação de acesso no servidor.\n");
    exit(1);
}
