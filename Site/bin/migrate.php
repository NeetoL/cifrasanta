<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require dirname(__DIR__) . '/app/Core/Database.php';

try {
    $db = \CifraSanta\Core\Database::connection();
    $sql = file_get_contents(dirname(__DIR__) . '/database/001_initial.sql');
    $checksum = hash('sha256', $sql);
    $lock = $db->query("SELECT GET_LOCK('cifra_santa_migration', 10)")->fetchColumn();
    if ((int) $lock !== 1) throw new RuntimeException('Outra migração está em execução.');
    try {
        $tables = $db->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
        if (in_array('cifra_santa_migracao', $tables, true)) {
            $saved = $db->query("SELECT checksum FROM cifra_santa_migracao WHERE versao = '001_initial'")->fetchColumn();
            if ($saved === $checksum) { echo "Migração já aplicada.\n"; exit(0); }
            throw new RuntimeException('Histórico incompatível. Verifique a migração antes de continuar.');
        }
        foreach ($tables as $table) {
            if (str_starts_with($table, 'cifra_santa_')) {
                throw new RuntimeException('Já existem tabelas do Cifra Santa sem histórico. Revise antes de continuar.');
            }
        }
        // DDL MySQL não é transacional. Interrompa e revise se houver falha parcial.
        foreach (explode(';', $sql) as $statement) {
            if (trim($statement) !== '') $db->exec($statement);
        }
        $db->prepare('INSERT INTO cifra_santa_migracao (versao, checksum) VALUES (?, ?)')->execute(['001_initial', $checksum]);
        echo "Nove tabelas cifra_santa_ criadas. Nenhuma tabela anterior foi alterada.\n";
    } finally {
        $db->query("SELECT RELEASE_LOCK('cifra_santa_migration')");
    }
} catch (Throwable $error) {
    fwrite(STDERR, "Migração interrompida. Código: " . $error->getCode() . ". Verifique conexão, permissões e tabelas existentes.\n");
    exit(1);
}
