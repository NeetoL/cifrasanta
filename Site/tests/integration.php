<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if (!in_array('--allow-configured-database', $argv, true)) exit("Use --allow-configured-database para permitir registros temporários de teste, removidos ao final.\n");
require dirname(__DIR__) . '/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;

$base = getenv('TEST_BASE_URL') ?: 'http://127.0.0.1:8097';
$db = Database::connection();
$service = new Service($db);
$suffix = bin2hex(random_bytes(8));
$password = bin2hex(random_bytes(12));
$emails = ["admin-$suffix@example.invalid", "reader-$suffix@example.invalid", "other-$suffix@example.invalid"];
$cookie = tempnam(sys_get_temp_dir(), 'cs-test-');
$checks = 0;

function check(bool $condition, string $label): void {
    global $checks;
    if (!$condition) throw new RuntimeException('Falhou: ' . $label);
    $checks++;
}
function request(string $path, string $method = 'GET', ?array $data = null, ?string $token = null, bool $form = false): array {
    global $base, $cookie;
    $curl = curl_init($base . $path);
    $headers = [];
    if ($token !== null) $headers[] = 'Authorization: Bearer ' . $token;
    if ($data !== null) $headers[] = $form ? 'Content-Type: application/x-www-form-urlencoded' : 'Content-Type: application/json';
    curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_CUSTOMREQUEST => $method, CURLOPT_HTTPHEADER => $headers, CURLOPT_TIMEOUT => 20, CURLOPT_COOKIEJAR => $cookie, CURLOPT_COOKIEFILE => $cookie]);
    if ($data !== null) curl_setopt($curl, CURLOPT_POSTFIELDS, $form ? http_build_query($data) : json_encode($data));
    $body = curl_exec($curl);
    $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    curl_close($curl);
    return [$status, is_string($body) ? $body : ''];
}
function csrfFrom(string $body): string {
    preg_match('/name="csrf" value="([a-f0-9]+)"/', $body, $match);
    return $match[1] ?? '';
}

try {
    [$status, $body] = request('/api.php?route=catalog');
    check($status === 200 && is_array(json_decode($body, true)['songs'] ?? null), 'catálogo público');
    check(request('/api.php?route=favorites')[0] === 401, 'favoritos exigem autenticação');
    check(request('/api.php?route=catalog', 'POST', [])[0] === 405, 'método inválido');
    check(request('/api.php?route=missing')[0] === 404, 'rota inexistente');
    check(request('/api.php?route=register', 'POST', ['nome' => 'Teste', 'email' => $emails[1], 'senha' => 'curta'])[0] === 422, 'validação de senha');

    $keyFile = dirname(__DIR__, 2) . '/admin-install-key.txt';
    if (!$service->query("SELECT id FROM cifra_santa_usuario WHERE papel = 'admin' LIMIT 1")->fetchColumn() && is_file($keyFile)) {
        [$status, $body] = request('/admin.php');
        $csrf = csrfFrom($body);
        check($status === 200 && str_contains($body, 'Chave de instalação'), 'primeiro acesso administrativo');
        $setup = ['action' => 'setup', 'csrf' => $csrf, 'nome' => 'Admin teste', 'email' => $emails[0], 'senha' => $password, 'install_key' => 'incorreta'];
        check(request('/admin.php', 'POST', $setup, null, true)[0] === 403, 'instalação exige chave');
        preg_match('/[a-f0-9]{48}/', file_get_contents($keyFile), $keyMatch);
        $setup['install_key'] = $keyMatch[0];
        check(request('/admin.php', 'POST', $setup, null, true)[0] === 303, 'primeiro administrador criado pelo painel');
        $admin = ['id' => $service->query('SELECT id FROM cifra_santa_usuario WHERE email = ?', [$emails[0]])->fetchColumn()];
        [$status, $body] = request('/admin.php');
        $csrf = csrfFrom($body);
        check(!str_contains($body, 'Chave de instalação'), 'formulário inicial desativado após instalação');
        request('/admin.php', 'POST', ['action' => 'logout', 'csrf' => $csrf], null, true);
    } else {
        $admin = $service->register(['nome' => 'Admin teste', 'email' => $emails[0], 'senha' => $password]);
        $service->query("UPDATE cifra_santa_usuario SET papel = 'admin' WHERE id = ?", [$admin['id']]);
    }
    [$status, $body] = request('/api.php?route=register', 'POST', ['nome' => 'Leitor teste', 'email' => $emails[1], 'senha' => $password, 'papel' => 'admin']);
    check($status === 201, 'cadastro pela API');
    $reader = json_decode($body, true);
    check($service->query('SELECT papel FROM cifra_santa_usuario WHERE id = ?', [$reader['usuario']['id']])->fetchColumn() === 'usuario', 'cadastro não permite elevar privilégios');
    [$status, $body] = request('/api.php?route=register', 'POST', ['nome' => 'Outro teste', 'email' => $emails[2], 'senha' => $password]);
    check($status === 201, 'segunda conta');
    $other = json_decode($body, true);
    check(request('/api.php?route=register', 'POST', ['nome' => 'Duplicado', 'email' => $emails[1], 'senha' => $password])[0] === 409, 'e-mail duplicado');
    check(request('/api.php?route=login', 'POST', ['email' => $emails[1], 'senha' => 'senha-incorreta'])[0] === 401, 'senha incorreta');
    check(request('/api.php?route=login', 'POST', ['email' => $emails[1], 'senha' => $password])[0] === 200, 'login válido');

    [$status, $body] = request('/admin.php');
    check($status === 200 && !str_contains($body, 'Adicionar música e cifra'), 'painel exige login');
    $csrf = csrfFrom($body);
    check(request('/admin.php', 'POST', ['action' => 'login', 'csrf' => $csrf, 'email' => $emails[1], 'senha' => $password], null, true)[0] === 401, 'usuário comum não entra no painel');
    check(request('/admin.php', 'POST', ['action' => 'login', 'csrf' => $csrf, 'email' => $emails[0], 'senha' => $password], null, true)[0] === 303, 'login administrador');
    [$status, $body] = request('/admin.php');
    $csrf = csrfFrom($body);
    check(request('/admin.php', 'POST', ['action' => 'song', 'titulo' => 'Sem CSRF'], null, true)[0] === 419, 'proteção CSRF');

    $songData = ['csrf' => $csrf, 'action' => 'song', 'titulo' => 'Integração ' . $suffix, 'artista' => 'Teste', 'categoria' => 'Entrada', 'tom' => 'C', 'conteudo' => "[C]Texto de teste [G]ação\n[Am]Outra linha", 'publicada' => '1'];
    check(request('/admin.php', 'POST', $songData, null, true)[0] === 303, 'publicação pelo painel');
    $songId = (int) $service->query('SELECT id FROM cifra_santa_musica WHERE criado_por = ?', [$admin['id']])->fetchColumn();
    $draftId = $service->saveSong(['titulo' => 'Rascunho ' . $suffix, 'artista' => 'Teste', 'categoria' => 'Louvor', 'tom' => 'Bm', 'conteudo' => '[Bm]Rascunho'], (int) $admin['id']);
    $repertoireId = $service->saveRepertoire(['titulo' => 'Repertório ' . $suffix, 'descricao' => 'Teste', 'musicas' => "$songId, $draftId", 'publicado' => '1'], (int) $admin['id']);
    $catalog = json_decode(request('/api.php?route=catalog')[1], true);
    $byId = array_column($catalog['songs'], null, 'id');
    check(isset($byId[$songId]) && !isset($byId[$draftId]), 'publicados visíveis e rascunhos ocultos');
    check($byId[$songId]['chart'] === $songData['conteudo'], 'conteúdo e UTF-8 preservados');
    $repertoire = array_column($catalog['repertoires'], null, 'id')[$repertoireId];
    check($repertoire['songIds'] === [(string) $songId], 'repertório oculta rascunhos');
    [$status, $body] = request('/api.php?route=favorites', 'PUT', ['songId' => (string) $songId, 'favorite' => true], $reader['token']);
    check($status === 200 && json_decode($body, true)['favorites'] === [(string) $songId], 'salva favorito');
    check(json_decode(request('/api.php?route=favorites', 'GET', null, $other['token'])[1], true)['favorites'] === [], 'favoritos isolados por usuário');
    check(request('/api.php?route=favorites', 'PUT', ['songId' => $draftId, 'favorite' => true], $reader['token'])[0] === 404, 'não favorita rascunho');
    check(request('/api.php?route=favorites', 'PUT', ['songId' => '1 OR 1=1', 'favorite' => true], $reader['token'])[0] === 422, 'valida identificador');
    check(request('/api.php?route=favorites', 'PUT', ['songId' => $songId, 'favorite' => 'true'], $reader['token'])[0] === 422, 'valida booleano');
    check(json_decode(request('/api.php?route=favorites', 'PUT', ['songId' => $songId, 'favorite' => false], $reader['token'])[1], true)['favorites'] === [], 'remove favorito');
    $songData['id'] = (string) $songId;
    unset($songData['publicada']);
    check(request('/admin.php', 'POST', $songData, null, true)[0] === 303, 'despublica pelo painel');
    check(!in_array((string) $songId, array_column(json_decode(request('/api.php?route=catalog')[1], true)['songs'], 'id'), true), 'despublicação refletida na API');
    check(request('/api.php?route=logout', 'POST', [], $reader['token'])[0] === 200, 'logout');
    check(request('/api.php?route=me', 'GET', null, $reader['token'])[0] === 401, 'token revogado');
    $service->query('UPDATE cifra_santa_usuario SET ativo = 0 WHERE id = ?', [$other['usuario']['id']]);
    check(request('/api.php?route=me', 'GET', null, $other['token'])[0] === 401, 'conta desativada perde acesso');
    echo "$checks verificações de integração passaram.\n";
} finally {
    foreach ($emails as $email) {
        $id = $service->query('SELECT id FROM cifra_santa_usuario WHERE email = ?', [$email])->fetchColumn();
        if (!$id) continue;
        $service->query('DELETE FROM cifra_santa_repertorio WHERE criado_por = ?', [$id]);
        $service->query('DELETE FROM cifra_santa_musica WHERE criado_por = ?', [$id]);
        $service->query('DELETE FROM cifra_santa_usuario WHERE id = ?', [$id]);
        $service->query('DELETE FROM cifra_santa_limite_acesso WHERE chave = ?', [hash('sha256', 'login-email:' . $email)]);
    }
    @unlink($cookie);
    echo "Registros temporários removidos.\n";
}
