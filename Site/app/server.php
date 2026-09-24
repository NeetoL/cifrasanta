<?php
declare(strict_types=1);

ini_set('display_errors', '0');
spl_autoload_register(static function (string $class): void {
    if (!str_starts_with($class, 'CifraSanta\\')) return;
    $file = __DIR__ . '/' . str_replace('\\', '/', substr($class, 11)) . '.php';
    if (is_file($file)) require $file;
});

header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: same-origin');
header('Cache-Control: no-store');

function secure_transport(): bool {
    return (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (in_array($_SERVER['REMOTE_ADDR'] ?? '', ['127.0.0.1', '::1'], true) && in_array($_SERVER['SERVER_NAME'] ?? '', ['localhost', '127.0.0.1', '::1'], true));
}

function start_admin_session(): void {
    ini_set('session.use_strict_mode', '1');
    session_name('cifra_santa_admin');
    session_set_cookie_params(['httponly' => true, 'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off', 'samesite' => 'Strict', 'path' => '/']);
    session_start();
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
}

function escape(mixed $value): string {
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
