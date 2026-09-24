<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require dirname(__DIR__) . '/app/Core/Database.php';

// Uso: php bin/import-biblia.php caminho/biblia.json
// O JSON ({livros: [...], versiculos: [[livro, capitulo, versiculo, texto], ...]}) fica fora do repositório.
$file = $argv[1] ?? '';
if ($file === '' || !is_file($file)) { fwrite(STDERR, "Informe o caminho do JSON da Bíblia.\n"); exit(1); }
$data = json_decode((string) file_get_contents($file), true, 512, JSON_THROW_ON_ERROR);

try {
    $db = \CifraSanta\Core\Database::connection();
    $sql = file_get_contents(dirname(__DIR__) . '/database/002_biblia.sql');
    $checksum = hash('sha256', $sql);
    $lock = $db->query("SELECT GET_LOCK('cifra_santa_migration', 10)")->fetchColumn();
    if ((int) $lock !== 1) throw new RuntimeException('Outra migração está em execução.');
    try {
        $saved = $db->query("SELECT checksum FROM cifra_santa_migracao WHERE versao = '002_biblia'")->fetchColumn();
        if ($saved === false) {
            $tables = $db->query("SHOW TABLES LIKE 'cifra\\_santa\\_biblia\\_%'")->fetchAll(PDO::FETCH_COLUMN);
            if ($tables) throw new RuntimeException('Tabelas da Bíblia já existem sem histórico. Revise antes de continuar.');
            foreach (explode(';', $sql) as $statement) {
                if (trim($statement) !== '') $db->exec($statement);
            }
            $db->prepare('INSERT INTO cifra_santa_migracao (versao, checksum) VALUES (?, ?)')->execute(['002_biblia', $checksum]);
            echo "Tabelas cifra_santa_biblia_ criadas.\n";
        } elseif ($saved !== $checksum) {
            throw new RuntimeException('Histórico incompatível da migração 002_biblia.');
        }

        $db->beginTransaction();
        $db->exec('DELETE FROM cifra_santa_biblia_versiculo');
        $db->exec('DELETE FROM cifra_santa_biblia_livro');
        $book = $db->prepare('INSERT INTO cifra_santa_biblia_livro (id, ordem, nome, abreviacao, testamento) VALUES (?, ?, ?, ?, ?)');
        foreach ($data['livros'] as $row) {
            $book->execute([$row['id'], $row['ordem'], $row['nome'], $row['abreviacao'], $row['testamento']]);
        }
        foreach (array_chunk($data['versiculos'], 500) as $chunk) {
            $values = implode(',', array_fill(0, count($chunk), '(?, ?, ?, ?)'));
            $db->prepare("INSERT INTO cifra_santa_biblia_versiculo (livro_id, capitulo, versiculo, texto) VALUES $values")
                ->execute(array_merge(...$chunk));
        }
        $db->commit();
        $total = $db->query('SELECT COUNT(*) FROM cifra_santa_biblia_versiculo')->fetchColumn();
        echo count($data['livros']) . " livros e {$total} versículos importados.\n";
    } finally {
        if ($db->inTransaction()) $db->rollBack();
        $db->query("SELECT RELEASE_LOCK('cifra_santa_migration')");
    }
} catch (Throwable $error) {
    fwrite(STDERR, 'Importação interrompida: ' . $error->getMessage() . "\n");
    exit(1);
}
