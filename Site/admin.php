<?php
declare(strict_types=1);
require __DIR__ . '/app/server.php';
use CifraSanta\Core\Database;
use CifraSanta\Core\Service;
require __DIR__ . '/app/Views/admin/kit.php';

header("Content-Security-Policy: default-src 'none'; img-src 'self'; style-src 'self'; script-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'");
if (!secure_transport()) { http_response_code(403); exit('Acesse o painel por HTTPS.'); }
start_admin_session();
$message = '';
$isError = false;
$user = null;
$needsSetup = false;
$songs = $repertoires = [];
const SONG_LIST_LIMIT = 100;
const SONG_PAGE_SIZE = 10;
$songQuery = is_string($_GET['q'] ?? null) ? mb_substr(trim($_GET['q']), 0, 100) : '';
$songStatus = in_array($_GET['status'] ?? '', ['pub', 'draft'], true) ? $_GET['status'] : 'all';
$songPage = ctype_digit((string) ($_GET['p'] ?? '')) ? max(1, (int) $_GET['p']) : 1;
$songMatches = $songShown = 0;
$songPages = 1;
$totals = ['total' => 0, 'publicadas' => 0];
$pickSongs = [];
$edit = $editRepertoire = [];
try {
    $db = Database::connection();
    $service = new Service($db);
    $needsSetup = !(bool) $service->query("SELECT id FROM cifra_santa_usuario WHERE papel = 'admin' LIMIT 1")->fetchColumn();
    if (isset($_SESSION['admin_id'])) {
        $user = $service->query("SELECT id, nome FROM cifra_santa_usuario WHERE id = ? AND papel = 'admin' AND ativo = 1", [$_SESSION['admin_id']])->fetch() ?: null;
        if ((int) ($_SESSION['expires'] ?? 0) < time()) $user = null;
        if (!$user) unset($_SESSION['admin_id']);
    }
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!is_string($_POST['csrf'] ?? null) || !hash_equals($_SESSION['csrf'], $_POST['csrf'])) throw new RuntimeException('Sessão expirada. Atualize a página.', 419);
        $action = $_POST['action'] ?? '';
        if ($action === 'setup' && $needsSetup) {
            $service->throttle('setup:' . ($_SERVER['REMOTE_ADDR'] ?? ''), 10);
            $file = __DIR__ . '/config/install.php';
            $expected = is_file($file) ? require $file : '';
            $key = is_string($_POST['install_key'] ?? null) ? $_POST['install_key'] : '';
            if (!is_string($expected) || $expected === '' || !hash_equals($expected, hash('sha256', $key))) throw new RuntimeException('Chave de instalação inválida.', 403);
            if ((int) $db->query("SELECT GET_LOCK('cifra_santa_setup', 10)")->fetchColumn() !== 1) throw new RuntimeException('Tente novamente.', 409);
            try {
                if ($service->query("SELECT id FROM cifra_santa_usuario WHERE papel = 'admin' LIMIT 1")->fetchColumn()) throw new RuntimeException('Administrador já configurado.', 409);
                $db->beginTransaction();
                try {
                    $newUser = $service->register($_POST);
                    $service->query("UPDATE cifra_santa_usuario SET papel = 'admin' WHERE id = ?", [$newUser['id']]);
                    $db->commit();
                } catch (Throwable $error) { $db->rollBack(); throw $error; }
            } finally { $db->query("SELECT RELEASE_LOCK('cifra_santa_setup')"); }
            session_regenerate_id(true);
            $_SESSION['admin_id'] = $newUser['id'];
            $_SESSION['expires'] = time() + 7200;
            $_SESSION['csrf'] = bin2hex(random_bytes(32));
        } elseif ($action === 'login') {
            $authenticated = $service->login($_POST, true);
            session_regenerate_id(true);
            $_SESSION['admin_id'] = $authenticated['id'];
            $_SESSION['expires'] = time() + 7200;
            $_SESSION['csrf'] = bin2hex(random_bytes(32));
        } elseif ($action === 'logout') {
            $_SESSION = [];
            session_destroy();
        } else {
            if (!$user) throw new RuntimeException('Entre como administrador.', 401);
            if ($action === 'song') $service->saveSong($_POST, (int) $user['id']);
            elseif ($action === 'repertoire') $service->saveRepertoire($_POST, (int) $user['id']);
            else throw new RuntimeException('Ação inválida.', 400);
            $_SESSION['notice'] = 'Conteúdo salvo. As publicações já estão disponíveis para o aplicativo.';
        }
        header('Location: admin.php', true, 303);
        exit;
    }
    if ($user) {
        $totals = $service->query('SELECT COUNT(*) total, COALESCE(SUM(c.publicada = 1), 0) publicadas FROM cifra_santa_musica m JOIN cifra_santa_cifra c ON c.musica_id = m.id')->fetch();
        // Biblioteca: busca e filtro no banco; no máximo as 100 mais recentes (ou 100 resultados), 10 por página.
        $where = [];
        $params = [];
        if ($songQuery !== '') {
            $like = '%' . addcslashes($songQuery, '\\%_') . '%';
            $where[] = '(m.titulo LIKE ? OR m.artista LIKE ? OR m.categoria LIKE ?)';
            array_push($params, $like, $like, $like);
        }
        if ($songStatus !== 'all') $where[] = 'c.publicada = ' . ($songStatus === 'pub' ? '1' : '0');
        $from = 'FROM cifra_santa_musica m JOIN cifra_santa_cifra c ON c.musica_id = m.id' . ($where ? ' WHERE ' . implode(' AND ', $where) : '');
        $songMatches = (int) $service->query("SELECT COUNT(*) $from", $params)->fetchColumn();
        $songShown = min($songMatches, SONG_LIST_LIMIT);
        $songPages = max(1, (int) ceil($songShown / SONG_PAGE_SIZE));
        $songPage = min($songPage, $songPages);
        $songs = $service->query('SELECT m.id, m.titulo, m.artista, m.categoria, c.tom, c.publicada ' . $from . ' ORDER BY m.id DESC LIMIT ' . SONG_PAGE_SIZE . ' OFFSET ' . (($songPage - 1) * SONG_PAGE_SIZE), $params)->fetchAll();
        // Montador de repertório: só id/título/artista/situação (sem cifras), para resolver qualquer música da sequência.
        $pickSongs = $service->query('SELECT m.id, m.titulo, m.artista, c.publicada FROM cifra_santa_musica m JOIN cifra_santa_cifra c ON c.musica_id = m.id ORDER BY m.id DESC')->fetchAll();
        $repertoires = $service->query('SELECT * FROM cifra_santa_repertorio ORDER BY id DESC')->fetchAll();
        if (ctype_digit((string) ($_GET['song'] ?? ''))) $edit = $service->query('SELECT m.*, c.tom, c.conteudo, c.publicada FROM cifra_santa_musica m JOIN cifra_santa_cifra c ON c.musica_id = m.id WHERE m.id = ?', [(int) $_GET['song']])->fetch() ?: [];
        foreach ($repertoires as $item) if ((string) $item['id'] === ($_GET['repertoire'] ?? '')) {
            $editRepertoire = $item;
            $editRepertoire['musicas'] = implode(', ', $service->query('SELECT musica_id FROM cifra_santa_repertorio_musica WHERE repertorio_id = ? ORDER BY posicao', [$item['id']])->fetchAll(PDO::FETCH_COLUMN));
        }
    }
    $message = $_SESSION['notice'] ?? '';
    unset($_SESSION['notice']);
} catch (Throwable $error) {
    $status = (int) $error->getCode();
    $expected = !$error instanceof PDOException && in_array($status, [400, 401, 403, 404, 409, 419, 422, 429], true);
    http_response_code($expected ? $status : 503);
    $isError = true;
    $message = $expected ? $error->getMessage() : 'Não foi possível concluir. Verifique a configuração do servidor ou tente novamente.';
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && $user) {
        if (($_POST['action'] ?? '') === 'song') $edit = array_filter($_POST, 'is_string');
        if (($_POST['action'] ?? '') === 'repertoire') $editRepertoire = array_filter($_POST, 'is_string');
    }
}
function csrf(): void { echo '<input type="hidden" name="csrf" value="' . escape($_SESSION['csrf'] ?? '') . '">'; }

if (!$user):
    adm_page_start(['title' => 'Cifra Santa · Painel administrativo', 'user' => null]);
    ?>
<div class="auth-brand">
  <h1 class="auth-logo"><?= adm_logo(200) ?></h1>
  <p><?= $needsSetup ? 'Vamos preparar o seu painel.' : 'Seu acervo, em harmonia.' ?></p>
</div>
<?php adm_notice($message, $isError); ?>
<div class="card">
  <span class="eyebrow"><?= $needsSetup ? 'PRIMEIRO ACESSO' : 'PAINEL ADMINISTRATIVO' ?></span>
  <h2><?= $needsSetup ? 'Crie sua conta de administrador' : 'Entre na sua conta' ?></h2>
  <form method="post"><?php csrf(); ?><input type="hidden" name="action" value="<?= $needsSetup ? 'setup' : 'login' ?>">
    <?php if ($needsSetup): ?>
    <label class="field"><span class="lbl">Chave de instalação</span><input name="install_key" type="password" required autocomplete="off"></label>
    <label class="field"><span class="lbl">Seu nome</span><input name="nome" required maxlength="120" autocomplete="name"></label>
    <p class="hint">Use a chave entregue com a instalação. Após a primeira conta, este cadastro é encerrado.</p>
    <?php endif; ?>
    <label class="field"><span class="lbl">E-mail</span><input name="email" type="email" required maxlength="190" autocomplete="username"></label>
    <label class="field"><span class="lbl">Senha</span><input name="senha" type="password" required minlength="10" maxlength="72" autocomplete="<?= $needsSetup ? 'new-password' : 'current-password' ?>"></label>
    <button class="btn btn-primary btn-block" type="submit"><?= $needsSetup ? 'Criar administrador' : 'Entrar' ?></button>
  </form>
</div>
<?php
    adm_page_end(false);
    return;
endif;

$totalSongs = (int) $totals['total'];
$published = (int) $totals['publicadas'];
$drafts = $totalSongs - $published;
/** Link da biblioteca mantendo busca, filtro e página. */
$songLink = static function (array $change = []) use ($songQuery, $songStatus, $songPage): string {
    $params = array_filter(['q' => $songQuery, 'status' => $songStatus === 'all' ? '' : $songStatus, 'p' => $songPage > 1 ? $songPage : '', ...$change], static fn($v) => $v !== '' && $v !== null);
    return 'admin.php' . ($params ? '?' . http_build_query($params) : '');
};
$publishedRepertoires = count(array_filter($repertoires, static fn(array $item): bool => !empty($item['publicado'])));
$firstName = explode(' ', trim((string) $user['nome']))[0] ?: 'administrador';
$editingSong = !empty($edit['id']);
$editingRepertoire = !empty($editRepertoire['id']);

adm_page_start([
    'title' => 'Cifra Santa · Administração',
    'user' => $user,
    'active' => 'biblioteca',
    'crumb' => 'Biblioteca',
    'counts' => ['musicas' => $totalSongs, 'repertorios' => count($repertoires)],
]);
?>
<div class="page-head">
  <div>
    <span class="eyebrow">CIFRA SANTA · ADMINISTRAÇÃO</span>
    <h1>Olá, <?= escape($firstName) ?>. Seu acervo, em harmonia.</h1>
    <p>Publique as músicas que vão acompanhar a comunidade.</p>
  </div>
  <div class="actions">
    <a class="btn btn-secondary" href="admin-import.php"><?= adm_icon('download', 17) ?><span>Importar por URL</span></a>
    <a class="btn btn-primary" href="admin.php#editor"><?= adm_icon('plus', 17) ?><span>Nova música</span></a>
  </div>
</div>

<?php adm_notice($message, $isError); ?>

<div class="stats" aria-label="Resumo do acervo">
  <div class="card stat"><span class="stat-ico"><?= adm_icon('music', 20) ?></span><div><strong><?= $totalSongs ?></strong><span class="label">Músicas no acervo</span></div></div>
  <div class="card stat is-gold"><span class="stat-ico"><?= adm_icon('check', 20) ?></span><div><strong><?= $published ?></strong><span class="label">Publicadas no app</span></div></div>
  <div class="card stat"><span class="stat-ico"><?= adm_icon('file', 20) ?></span><div><strong><?= $drafts ?></strong><span class="label">Rascunhos</span></div></div>
  <div class="card stat"><span class="stat-ico"><?= adm_icon('book', 20) ?></span><div><strong><?= count($repertoires) ?></strong><span class="label">Repertórios (<?= $publishedRepertoires ?> publicados)</span></div></div>
</div>

<section class="block" id="musicas">
  <?php adm_section_head('BIBLIOTECA', 'Músicas e cifras', $songQuery === '' ? 'As ' . SONG_LIST_LIMIT . ' músicas adicionadas mais recentemente. Busque para encontrar qualquer outra do acervo. Rascunhos ficam ocultos no aplicativo.' : 'Resultados da busca em todo o acervo (até ' . SONG_LIST_LIMIT . ', das mais recentes para as mais antigas).'); ?>
  <div class="card">
    <form method="get" action="admin.php#musicas" class="toolbar" role="search">
      <label class="search"><?= adm_icon('search', 17) ?><input id="song-search" name="q" type="search" maxlength="100" value="<?= escape($songQuery) ?>" placeholder="Buscar por música, artista ou momento… (Enter)" autocomplete="off" aria-label="Buscar músicas"><?php if ($songQuery !== ''): ?><a class="search-clear" href="<?= escape($songLink(['q' => '', 'p' => ''])) ?>#musicas" aria-label="Limpar busca">×</a><?php endif; ?></label>
      <div class="seg" role="group" aria-label="Filtrar por situação">
        <?php foreach (['all' => 'Todas', 'pub' => 'Publicadas', 'draft' => 'Rascunhos'] as $value => $label): ?>
        <button type="submit" name="status" value="<?= $value ?>" class="<?= $songStatus === $value ? 'is-on' : '' ?>" aria-pressed="<?= $songStatus === $value ? 'true' : 'false' ?>"><?= $label ?></button>
        <?php endforeach; ?>
      </div>
    </form>
    <?php if ($songs): ?>
    <ul class="songs">
      <?php foreach ($songs as $song): $isPub = !empty($song['publicada']); ?>
      <li class="song<?= (string) $song['id'] === (string) ($edit['id'] ?? '') ? ' is-editing' : '' ?>" data-id="<?= escape($song['id']) ?>">
        <span class="idx"><?= escape($song['id']) ?></span>
        <div class="t"><strong><?= escape($song['titulo']) ?></strong><span><?= escape($song['artista'] !== '' ? $song['artista'] : 'Artista não informado') ?></span></div>
        <?php if (!empty($song['categoria'])): ?><span class="tag"><?= escape($song['categoria']) ?></span><?php else: ?><span></span><?php endif; ?>
        <?php if (!empty($song['tom'])): ?><span class="tag tom" title="Tom original"><?= escape($song['tom']) ?></span><?php else: ?><span></span><?php endif; ?>
        <span class="pill <?= $isPub ? 'is-pub' : 'is-draft' ?>"><?= $isPub ? 'Publicada' : 'Rascunho' ?></span>
        <a class="btn btn-ghost btn-sm edit" href="<?= escape($songLink(['song' => $song['id']])) ?>#editor"><?= adm_icon('edit', 15) ?><span>Editar</span></a>
      </li>
      <?php endforeach; ?>
    </ul>
    <nav class="pager" aria-label="Páginas da biblioteca">
      <span class="pager-info">
        <?= ($songPage - 1) * SONG_PAGE_SIZE + 1 ?>–<?= ($songPage - 1) * SONG_PAGE_SIZE + count($songs) ?> de <?= $songShown ?>
        <?php if ($songMatches > $songShown): ?> <em>· <?= $songMatches ?> no total; refine a busca para ver as demais</em><?php endif; ?>
      </span>
      <?php if ($songPages > 1): ?>
      <span class="pager-links">
        <?php if ($songPage > 1): ?><a class="btn btn-ghost btn-sm" href="<?= escape($songLink(['p' => $songPage - 1 > 1 ? $songPage - 1 : ''])) ?>#musicas" rel="prev">‹ Anterior</a><?php endif; ?>
        <?php for ($page = 1; $page <= $songPages; $page++): ?>
        <?php if ($page === $songPage): ?><span class="pager-num is-on" aria-current="page"><?= $page ?></span><?php else: ?><a class="pager-num" href="<?= escape($songLink(['p' => $page > 1 ? $page : ''])) ?>#musicas"><?= $page ?></a><?php endif; ?>
        <?php endfor; ?>
        <?php if ($songPage < $songPages): ?><a class="btn btn-ghost btn-sm" href="<?= escape($songLink(['p' => $songPage + 1])) ?>#musicas" rel="next">Próxima ›</a><?php endif; ?>
      </span>
      <?php endif; ?>
    </nav>
    <?php elseif ($totalSongs > 0): ?>
    <p class="list-empty is-shown">Nenhuma música encontrada<?= $songQuery !== '' ? ' para “' . escape($songQuery) . '”' : '' ?><?= $songStatus !== 'all' ? ' com esse filtro' : '' ?>.</p>
    <?php else: ?>
    <div class="empty-state">
      <span class="stat-ico"><?= adm_icon('music', 26) ?></span>
      <h3>Ainda não há músicas cadastradas</h3>
      <p>Cadastre a primeira cifra no editor abaixo ou importe de uma fonte autorizada pelo endereço da página.</p>
      <div class="actions"><a class="btn btn-primary" href="admin.php#editor"><?= adm_icon('plus', 17) ?><span>Nova música</span></a><a class="btn btn-secondary" href="admin-import.php"><?= adm_icon('download', 17) ?><span>Importar por URL</span></a></div>
    </div>
    <?php endif; ?>
  </div>
</section>

<section class="block" id="editor">
  <?php adm_section_head('EDITOR', $editingSong ? 'Editar música e cifra' : 'Adicionar música e cifra', 'Salve como rascunho ou publique para aparecer no aplicativo.', $editingSong ? '<a class="btn btn-ghost btn-sm" href="admin.php#editor">' . adm_icon('plus', 15) . '<span>Nova música</span></a>' : ''); ?>
  <form method="post" class="editor" data-editor><?php csrf(); ?><input type="hidden" name="action" value="song"><input type="hidden" name="id" value="<?= escape($edit['id'] ?? '') ?>">
    <div class="card card-pad stack">
      <div class="form-grid">
        <label class="field"><span class="lbl">Título</span><input name="titulo" required maxlength="200" value="<?= escape($edit['titulo'] ?? '') ?>"></label>
        <label class="field"><span class="lbl">Artista / compositor</span><input name="artista" required maxlength="200" value="<?= escape($edit['artista'] ?? '') ?>"></label>
        <div class="field"><label><span class="lbl">Momento / categoria</span><input name="categoria" required maxlength="80" list="categorias" value="<?= escape($edit['categoria'] ?? '') ?>"></label>
          <datalist id="categorias"><option>Entrada</option><option>Comunhão</option><option>Louvor</option><option>Envio</option></datalist>
          <div class="chips js-only" aria-label="Sugestões de momento"><?php foreach (['Entrada', 'Comunhão', 'Louvor', 'Envio'] as $moment): ?><button class="chip<?= ($edit['categoria'] ?? '') === $moment ? ' is-on' : '' ?>" type="button" data-fill="categoria"><?= $moment ?></button><?php endforeach; ?></div>
        </div>
        <div class="field"><label><span class="lbl">Tom original</span><input name="tom" required maxlength="12" placeholder="C, G, F#, Bm..." value="<?= escape($edit['tom'] ?? '') ?>"></label>
          <div class="chips js-only" aria-label="Tons frequentes"><?php foreach (['C', 'D', 'E', 'F', 'G', 'A', 'Am', 'Em'] as $key): ?><button class="chip<?= ($edit['tom'] ?? '') === $key ? ' is-on' : '' ?>" type="button" data-fill="tom"><?= $key ?></button><?php endforeach; ?></div>
        </div>
      </div>
      <div class="field"><label><span class="lbl">Letra com acordes <em>· acordes entre colchetes, antes da sílaba</em></span><textarea name="conteudo" required maxlength="100000" rows="15" spellcheck="false" placeholder="[C]Sua letra aqui [G]continua&#10;[Am]Uma nova linha [F]para cantar"><?= escape($edit['conteudo'] ?? '') ?></textarea></label>
        <div class="counter js-only" id="chart-counter"></div>
        <p class="hint">Exemplo: [C]Sua letra [G]continua. O aplicativo monta as linhas de acordes e permite mudar o tom. Use linhas em branco para separar as estrofes e [Refrão] para marcar seções.</p>
      </div>
      <div class="form-foot">
        <label class="switch"><input type="checkbox" name="publicada" value="1" <?= !empty($edit['publicada']) ? 'checked' : '' ?>><span class="track"></span><span>Publicar no aplicativo<small>Desmarcado, a música fica como rascunho.</small></span></label>
        <div class="actions"><a class="btn btn-ghost" href="admin.php#editor">Nova música</a><button class="btn btn-primary" type="submit"><?= adm_icon('check', 17) ?><span>Salvar música e cifra</span></button></div>
      </div>
    </div>
    <aside class="preview js-only" aria-label="Prévia da cifra">
      <div class="preview-head"><span class="eyebrow">PRÉVIA AO VIVO</span><span class="muted">Como aparece no aplicativo</span></div>
      <div class="preview-meta"><h3 id="pv-title">Título da música</h3><p id="pv-artist">Artista / compositor</p><span class="tom-badge" id="pv-tom">Sem tom</span></div>
      <div class="chart" id="pv-chart"></div>
    </aside>
  </form>
</section>

<section class="block" id="repertorios">
  <?php adm_section_head('CELEBRAÇÕES', $editingRepertoire ? 'Editar repertório' : 'Criar repertório', 'Monte a sequência de execução de uma celebração com as músicas do acervo.', $editingRepertoire ? '<a class="btn btn-ghost btn-sm" href="admin.php#repertorios">' . adm_icon('plus', 15) . '<span>Novo repertório</span></a>' : ''); ?>
  <div class="editor">
    <form method="post" class="card card-pad stack"><?php csrf(); ?><input type="hidden" name="action" value="repertoire"><input type="hidden" name="id" value="<?= escape($editRepertoire['id'] ?? '') ?>">
      <div class="form-grid">
        <label class="field"><span class="lbl">Título</span><input name="titulo" required maxlength="200" value="<?= escape($editRepertoire['titulo'] ?? '') ?>"></label>
        <label class="field"><span class="lbl">Descrição <em>· opcional</em></span><input name="descricao" maxlength="255" value="<?= escape($editRepertoire['descricao'] ?? '') ?>"></label>
      </div>
      <div class="field"><label><span class="lbl">Músicas na ordem desejada <em>· IDs separados por vírgula</em></span><input id="rep-ids" name="musicas" maxlength="10000" placeholder="Ex.: 12, 7, 9" value="<?= escape($editRepertoire['musicas'] ?? '') ?>"></label>
        <p class="hint">Informe os IDs na sequência de execução. Músicas em rascunho ficam ocultas no aplicativo.</p>
      </div>
      <div class="field js-only">
        <span class="lbl">Ou monte pela lista <em>· <span id="pick-total">0</span> selecionadas</em></span>
        <label class="search"><?= adm_icon('search', 16) ?><input id="pick-search" type="text" placeholder="Buscar música para adicionar…" autocomplete="off" aria-label="Buscar músicas para o repertório"></label>
        <script type="application/json" id="pick-data"><?= json_encode(array_map(static fn(array $s): array => [(string) $s['id'], $s['titulo'], $s['artista'], empty($s['publicada'])], $pickSongs), JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?></script>
        <div class="picker">
          <div class="picker-col"><header><span>DISPONÍVEIS</span></header><ul id="pick-avail"></ul></div>
          <div class="picker-col"><header><span>SEQUÊNCIA</span></header><ol id="pick-sel"></ol></div>
        </div>
      </div>
      <div class="form-foot">
        <label class="switch"><input type="checkbox" name="publicado" value="1" <?= !empty($editRepertoire['publicado']) ? 'checked' : '' ?>><span class="track"></span><span>Publicar repertório<small>Só aparece no aplicativo se estiver publicado.</small></span></label>
        <div class="actions"><a class="btn btn-ghost" href="admin.php#repertorios">Novo repertório</a><button class="btn btn-primary" type="submit"><?= adm_icon('check', 17) ?><span>Salvar repertório</span></button></div>
      </div>
    </form>
    <div class="rep-list" aria-label="Repertórios cadastrados">
      <?php foreach ($repertoires as $item): ?>
      <div class="card rep<?= (string) $item['id'] === (string) ($editRepertoire['id'] ?? '') ? ' is-editing' : '' ?>">
        <span class="rep-ico"><?= adm_icon('book', 20) ?></span>
        <div class="t"><strong><?= escape($item['titulo']) ?></strong><span><?= escape(($item['descricao'] ?? '') !== '' ? $item['descricao'] : 'Sem descrição') ?></span></div>
        <span class="pill <?= !empty($item['publicado']) ? 'is-pub' : 'is-draft' ?>"><?= !empty($item['publicado']) ? 'Publicado' : 'Rascunho' ?></span>
        <a class="btn btn-ghost btn-sm" href="?repertoire=<?= escape($item['id']) ?>#repertorios"><?= adm_icon('edit', 15) ?><span>Editar</span></a>
      </div>
      <?php endforeach; ?>
      <?php if (!$repertoires): ?><div class="card empty-state"><span class="stat-ico"><?= adm_icon('book', 26) ?></span><h3>Nenhum repertório ainda</h3><p>Crie o primeiro para organizar as músicas de uma celebração.</p></div><?php endif; ?>
    </div>
  </div>
</section>
<?php adm_page_end(true);
