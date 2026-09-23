<?php
declare(strict_types=1);

spl_autoload_register(static function (string $class): void {
    $prefix = 'CifraSanta\\';
    if (!str_starts_with($class, $prefix)) return;
    $path = __DIR__ . '/' . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
    if (is_file($path)) require $path;
});

if (session_status() !== PHP_SESSION_ACTIVE) session_start();
if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(24));

function e(mixed $value): string { return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
function base_path(): string {
    $directory = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/index.php'));
    return $directory === '/' || $directory === '.' ? '' : rtrim($directory, '/');
}
function url(string $path = '/'): string { return base_path() . ($path === '/' ? '/' : '/' . ltrim($path, '/')); }
function asset(string $path): string { return url('/assets/' . ltrim($path, '/')); }
function partial(string $partialName, array $data = []): void { extract($data, EXTR_SKIP); require __DIR__ . '/Views/partials/' . $partialName . '.php'; }
function render(string $page, array $data = [], bool $reader = false): void {
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $base = base_path();
    if ($base !== '' && str_starts_with($path, $base . '/')) $path = substr($path, strlen($base));
    $nav = str_starts_with($path, '/repertorios') ? '/repertorios' : (str_starts_with($path, '/cifra') ? '/buscar' : $path);
    extract($data, EXTR_SKIP);
    ob_start();
    require __DIR__ . '/Views/pages/' . $page . '.php';
    $content = ob_get_clean();
    require __DIR__ . '/Views/layout.php';
}
function favorites(): array { return $_SESSION['favorites'] ?? ['sacramento-comunhao', 'luz-do-caminho', 'pao-da-partilha']; }
function is_favorite(string $id): bool { return in_array($id, favorites(), true); }
function csrf_token(): string { return (string) $_SESSION['csrf']; }
function icon(string $name, int $size = 20): string {
    $paths = [
        'home'=>'<path d="m3 10 9-7 9 7v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/><path d="M9 21v-7h6v7"/>',
        'search'=>'<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
        'heart'=>'<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8z"/>',
        'list'=>'<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h5"/>',
        'music'=>'<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
        'spark'=>'<path d="M12 2 9.8 9.8 2 12l7.8 2.2L12 22l2.2-7.8L22 12l-7.8-2.2z"/>',
        'arrow'=>'<path d="M4 12h16m-7-7 7 7-7 7"/>',
        'chevron'=>'<path d="m7 10 5 5 5-5"/>',
        'play'=>'<path d="m8 5 11 7-11 7z"/>',
        'sliders'=>'<path d="M4 7h16M4 17h16"/><circle cx="9" cy="7" r="2" fill="currentColor"/><circle cx="15" cy="17" r="2" fill="currentColor"/>',
        'book'=>'<path d="M4 4.5C7 3 10 3.5 12 5c2-1.5 5-2 8-.5V20c-3-1.5-6-1-8-.5z"/><path d="M12 5v15"/>',
        'clock'=>'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
        'expand'=>'<path d="M8 3H4a1 1 0 0 0-1 1v4m13-5h4a1 1 0 0 1 1 1v4M3 16v4a1 1 0 0 0 1 1h4m13-5v4a1 1 0 0 1-1 1h-4"/>',
        'check'=>'<path d="m5 12 4 4L19 6"/>',
        'print'=>'<path d="M7 8V3h10v5M7 17H5a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><path d="M7 14h10v7H7zM17 11h.01"/>',
        'download'=>'<path d="M12 3v12m-4-4 4 4 4-4M4 18v3h16v-3"/>',
    ];
    $path = $paths[$name] ?? '<circle cx="12" cy="12" r="8"/>';
    return '<svg width="'.$size.'" height="'.$size.'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'.$path.'</svg>';
}
function lit_icon(string $name, int $size = 32): string {
    $paths = [
        'mark'=>'<circle cx="24" cy="24" r="19"/><path d="M24 11v25M15 20h18M14 37c3 2 6 3 10 3s7-1 10-3"/>',
        'church'=>'<path d="M8 40V19l16-11 16 11v21H8Z"/><path d="M17 40V28a7 7 0 0 1 14 0v12M24 12v11M18.5 17.5h11"/>',
        'chalice'=>'<circle cx="24" cy="9" r="4"/><path d="M24 5v8M20 9h8M11 18h26l-3 11a10 10 0 0 1-20 0l-3-11ZM24 39v5M17 44h14"/>',
        'dove'=>'<path d="M7 30c7-1 11-6 14-13l4 7 12-4-7 9 8 6-14-1c-4 7-12 8-18 5 6-1 9-4 10-7-4 0-7 0-9-2Z"/><circle cx="30" cy="23" r="1"/>',
        'send'=>'<path d="M23 7v22M14 16h18M10 41c8-7 18-8 29-7M33 28l6 6-6 6"/>',
        'book'=>'<path d="M24 12c-6-4-12-4-18-2v28c6-2 12-2 18 2 6-4 12-4 18-2V10c-6-2-12-2-18 2ZM24 12v28M24 4v13M18 10h12"/>',
    ];
    $path = $paths[$name] ?? $paths['mark'];
    return '<svg width="'.$size.'" height="'.$size.'" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'.$path.'</svg>';
}
