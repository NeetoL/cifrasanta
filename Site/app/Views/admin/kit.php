<?php
declare(strict_types=1);
/**
 * Componentes visuais do painel administrativo. Somente apresentação:
 * nenhuma regra de negócio, autenticação ou acesso a dados fica aqui.
 * Tudo que vem de fora passa por escape().
 */

/** Ícones de traço (24x24). Conteúdo estático, seguro para saída direta. */
function adm_icon(string $name, int $size = 18): string {
    static $paths = [
        'music' => '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
        'download' => '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>',
        'list' => '<line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>',
        'plus' => '<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>',
        'search' => '<circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
        'edit' => '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
        'logout' => '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>',
        'sun' => '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
        'moon' => '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>',
        'check' => '<polyline points="20 6 9 17 4 12"/>',
        'x' => '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
        'external' => '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>',
        'book' => '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>',
        'eye' => '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/>',
        'up' => '<polyline points="18 15 12 9 6 15"/>',
        'down' => '<polyline points="6 9 12 15 18 9"/>',
        'alert' => '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>',
        'shield' => '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/>',
        'link' => '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
        'file' => '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>',
        'grid' => '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/>',
    ];
    $body = $paths[$name] ?? '';
    return '<svg class="ico" width="' . $size . '" height="' . $size . '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">' . $body . '</svg>';
}

/** Marca do aplicativo (mesmo desenho do ícone: arco, cruz e nota em dourado). */
function adm_mark(int $size = 40): string {
    return '<svg class="mark" width="' . $size . '" height="' . $size . '" viewBox="0 0 108 108" aria-hidden="true" focusable="false"><defs><linearGradient id="cs-bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#245256"/><stop offset="1" stop-color="#0D252A"/></linearGradient></defs><rect width="108" height="108" rx="26" fill="url(#cs-bg)"/><g transform="translate(54 54) scale(1.22) translate(-54 -54)"><path d="M54,24 A30,30 0 1,1 53.99,24" fill="none" stroke="#9BD5DF" stroke-opacity=".5" stroke-width="1.6"/><path d="M58,61 C52,57 41,60 38,66 C35,73 42,78 49,75 C55,73 60,68 58,61 Z" fill="#F1C76D"/><path d="M58 34 V64 M44 46 H72" fill="none" stroke="#F1C76D" stroke-width="5.4" stroke-linecap="round"/></g></svg>';
}

function adm_initials(string $name): string {
    $parts = preg_split('/\s+/u', trim($name), -1, PREG_SPLIT_NO_EMPTY) ?: [];
    $letters = '';
    foreach (array_slice($parts, 0, 2) as $part) $letters .= mb_strtoupper(mb_substr($part, 0, 1));
    return $letters !== '' ? $letters : 'A';
}

/**
 * Abre a página. Opções:
 *  title   título da aba
 *  user    ['id','nome'] do administrador logado, ou null (layout de acesso)
 *  active  item do menu: 'biblioteca' | 'importar' | 'repertorios'
 *  crumb   texto do topo
 *  counts  ['musicas'=>int,'repertorios'=>int] para os selos do menu
 *  csrf    token para o formulário de saída
 */
function adm_page_start(array $o): void {
    $user = $o['user'] ?? null;
    $active = $o['active'] ?? '';
    $counts = $o['counts'] ?? [];
    $item = static function (string $key, string $href, string $icon, string $label, ?int $count = null) use ($active): string {
        $badge = $count !== null ? '<em class="count">' . (int) $count . '</em>' : '';
        return '<a class="nav-item' . ($active === $key ? ' is-active' : '') . '" href="' . escape($href) . '" data-nav="' . escape($key) . '"' . ($active === $key ? ' aria-current="page"' : '') . '>' . adm_icon($icon, 18) . '<span>' . escape($label) . '</span>' . $badge . '</a>';
    };
    ?>
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark light">
<meta name="theme-color" content="#111619">
<title><?= escape($o['title'] ?? 'Cifra Santa · Painel') ?></title>
<link rel="stylesheet" href="assets/admin.css">
<script src="assets/admin.js" defer></script>
</head>
<body class="<?= $user ? 'is-app' : 'is-auth' ?>">
<a class="skip" href="#conteudo">Ir para o conteúdo</a>
<?php if ($user): ?>
<div class="shell">
  <aside class="side" aria-label="Menu do painel">
    <a class="brand" href="admin.php"><?= adm_mark(40) ?><span class="brand-text"><strong>Cifra Santa</strong><small>PAINEL</small></span></a>
    <nav class="side-nav" aria-label="Navegação principal">
      <span class="cap">CATÁLOGO</span>
      <?= $item('biblioteca', 'admin.php#musicas', 'music', 'Biblioteca', isset($counts['musicas']) ? (int) $counts['musicas'] : null) ?>
      <?= $item('importar', 'admin-import.php', 'download', 'Importar cifra') ?>
      <?= $item('repertorios', 'admin.php#repertorios', 'book', 'Repertórios', isset($counts['repertorios']) ? (int) $counts['repertorios'] : null) ?>
    </nav>
    <div class="side-foot">
      <div class="profile">
        <span class="avatar" aria-hidden="true"><?= escape(adm_initials((string) $user['nome'])) ?></span>
        <span class="who"><strong><?= escape($user['nome']) ?></strong><small>Administrador</small></span>
      </div>
      <form method="post" action="admin.php" class="logout"><input type="hidden" name="csrf" value="<?= escape($_SESSION['csrf'] ?? '') ?>"><input type="hidden" name="action" value="logout"><button class="btn btn-ghost btn-block" type="submit"><?= adm_icon('logout', 16) ?><span>Sair</span></button></form>
    </div>
  </aside>
  <div class="main">
    <header class="topbar">
      <span class="crumb"><span class="crumb-root">Painel</span><span class="crumb-sep" aria-hidden="true">/</span><strong><?= escape($o['crumb'] ?? '') ?></strong></span>
      <button class="icon-btn" type="button" data-theme-toggle aria-label="Alternar tema claro/escuro" title="Alternar tema"><span class="i-moon"><?= adm_icon('moon', 18) ?></span><span class="i-sun"><?= adm_icon('sun', 18) ?></span></button>
    </header>
    <main class="page" id="conteudo">
<?php else: ?>
<div class="auth-wrap">
  <button class="icon-btn auth-theme" type="button" data-theme-toggle aria-label="Alternar tema claro/escuro" title="Alternar tema"><span class="i-moon"><?= adm_icon('moon', 18) ?></span><span class="i-sun"><?= adm_icon('sun', 18) ?></span></button>
  <main class="auth" id="conteudo">
<?php endif;
}

function adm_page_end(bool $app = true): void {
    if ($app): ?>
    </main>
    <footer class="foot">Cifra Santa · Administração do catálogo</footer>
  </div>
</div>
<?php else: ?>
  </main>
  <p class="foot foot-auth">Cifra Santa · Administração do catálogo</p>
</div>
<?php endif; ?>
</body>
</html>
<?php
}

/** Faixa de mensagem (sucesso ou erro). */
function adm_notice(string $message, bool $isError): void {
    if ($message === '') return;
    ?>
<div class="notice <?= $isError ? 'is-error' : 'is-ok' ?>" role="<?= $isError ? 'alert' : 'status' ?>" data-notice>
  <span class="notice-ico"><?= adm_icon($isError ? 'alert' : 'check', 18) ?></span>
  <p><?= escape($message) ?></p>
  <button class="notice-x" type="button" data-notice-close aria-label="Fechar aviso"><?= adm_icon('x', 16) ?></button>
</div>
<?php
}

/** Cabeçalho de seção no padrão do app: kicker dourado + título. */
function adm_section_head(string $kicker, string $title, string $lead = '', string $actions = ''): void {
    ?>
<div class="section-head">
  <div>
    <span class="eyebrow"><?= escape($kicker) ?></span>
    <h2><?= escape($title) ?></h2>
    <?php if ($lead !== ''): ?><p class="lead"><?= escape($lead) ?></p><?php endif; ?>
  </div>
  <?php if ($actions !== ''): ?><div class="section-actions"><?= $actions ?></div><?php endif; ?>
</div>
<?php
}
