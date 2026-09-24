<?php
declare(strict_types=1);

namespace CifraSanta\Core;

use PDO;
use RuntimeException;

final class Database
{
    private static ?PDO $connection = null;

    public static function connection(): PDO
    {
        if (self::$connection !== null) return self::$connection;

        $file = dirname(__DIR__, 2) . '/config/database.php';
        $config = is_file($file) ? require $file : [];
        if (!is_array($config)) throw new RuntimeException('Configuração de banco inválida.');

        $dsn = getenv('DATABASE_DSN_PROD');
        if ($dsn === false || $dsn === '') {
            $name = (string) ($config['name'] ?? '');
            $host = (string) ($config['host'] ?? '');
            $port = filter_var($config['port'] ?? 3306, FILTER_VALIDATE_INT);
            if ($name === '' || $host === '') {
                throw new RuntimeException('Informe o host e o nome do banco do Cifra Santa em config/database.php.');
            }
            if (preg_match('/[;\x00-\x20]/', $host . $name) || $port === false || $port < 1 || $port > 65535) {
                throw new RuntimeException('Host, nome ou porta do banco inválidos.');
            }
            $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";
        }
        if (!str_starts_with($dsn, 'mysql:')) throw new RuntimeException('A conexão deve usar MySQL.');

        $user = getenv('DATABASE_USER_PROD');
        $password = getenv('DATABASE_PASS_PROD');
        self::$connection = new PDO(
            $dsn,
            $user !== false ? $user : (string) ($config['user'] ?? ''),
            $password !== false ? $password : (string) ($config['password'] ?? ''),
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_TIMEOUT => 5,
            ]
        );
        return self::$connection;
    }
}
