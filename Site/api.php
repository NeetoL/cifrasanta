<?php
declare(strict_types=1);
require __DIR__ . '/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;

header('Content-Type: application/json; charset=utf-8');
function respond(array $data, int $status = 200): never {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    exit;
}

try {
    if (!secure_transport()) respond(['error' => 'Use uma conexão HTTPS.'], 403);
    $method = $_SERVER['REQUEST_METHOD'];
    $route = $_GET['route'] ?? 'catalog';
    if (!is_string($route)) respond(['error' => 'Rota inválida.'], 400);
    $allowed = ['catalog' => 'GET', 'register' => 'POST', 'login' => 'POST', 'me' => 'GET', 'logout' => 'POST', 'favorites' => ['GET', 'PUT'], 'bible' => 'GET', 'playlists' => ['GET', 'POST']];
    if (!isset($allowed[$route])) respond(['error' => 'Rota não encontrada.'], 404);
    if (!in_array($method, (array) $allowed[$route], true)) {
        header('Allow: ' . implode(', ', (array) $allowed[$route]));
        respond(['error' => 'Método não permitido.'], 405);
    }
    $data = [];
    if (in_array($method, ['POST', 'PUT'], true)) {
        if (!str_starts_with(strtolower($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')) respond(['error' => 'Envie JSON.'], 415);
        $raw = file_get_contents('php://input', false, null, 0, 16385);
        if (strlen($raw) > 16384) respond(['error' => 'Requisição muito grande.'], 413);
        try { $data = json_decode($raw, true, 16, JSON_THROW_ON_ERROR); }
        catch (JsonException) { respond(['error' => 'JSON inválido.'], 400); }
        if (!is_array($data) || array_is_list($data) && $data !== []) respond(['error' => 'Envie um objeto JSON.'], 400);
    }
    $service = new Service(Database::connection());
    if ($route === 'catalog') respond($service->catalog());
    if ($route === 'register') respond($service->issueToken($service->register($data)), 201);
    if ($route === 'login') respond($service->issueToken($service->login($data)));

    $authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer ([a-f0-9]{64})$/D', $authorization, $match)) respond(['error' => 'Entre na sua conta para continuar.'], 401);
    $token = $match[1];
    $user = $service->authenticate($token);
    if ($route === 'playlists') {
        $lists = new \CifraSanta\Core\Playlists(Database::connection());
        respond(['playlists' => $method === 'GET' ? $lists->all((int)$user['id']) : $lists->mutate((int)$user['id'], $data)]);
    }
    if ($route === 'me') respond(['usuario' => $user]);
    if ($route === 'logout') {
        $service->query('DELETE FROM cifra_santa_token WHERE token_hash = ?', [hash('sha256', $token)]);
        respond(['ok' => true]);
    }
    if ($route === 'bible') {
        // Texto sem licença de distribuição: leitura restrita às contas de administrador.
        if ($user['papel'] !== 'admin') respond(['error' => 'A Bíblia está disponível apenas para contas autorizadas.'], 403);
        $book = Service::bibleBook($_GET['livro'] ?? null);
        if (!isset($_GET['capitulo'])) respond($service->bibleChapters($book));
        respond($service->bibleVerses($book, Service::id($_GET['capitulo'])));
    }
    if ($method === 'GET') respond(['favorites' => $service->favorites((int) $user['id'])]);
    if (!isset($data['favorite']) || !is_bool($data['favorite'])) respond(['error' => 'favorite deve ser verdadeiro ou falso.'], 422);
    respond(['favorites' => $service->setFavorite((int) $user['id'], Service::id($data['songId'] ?? null), $data['favorite'])]);
} catch (Throwable $error) {
    $status = (int) $error->getCode();
    if (!$error instanceof PDOException && in_array($status, [401, 403, 404, 409, 422, 429], true)) {
        if ($status === 429) header('Retry-After: 900');
        respond(['error' => $error->getMessage()], $status);
    }
    error_log('Cifra Santa API: ' . get_class($error) . ' code=' . $error->getCode());
    respond(['error' => 'Serviço indisponível. Tente novamente em instantes.'], 503);
}
