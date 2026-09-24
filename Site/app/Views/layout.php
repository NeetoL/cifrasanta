<!doctype html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#0b1927">
    <meta name="csrf-token" content="<?= e(csrf_token()) ?>">
    <meta name="app-base" content="<?= e(base_path()) ?>">
    <title><?= e($title ?? 'Cifra Santa') ?></title>
    <link rel="icon" type="image/png" href="<?= e(asset('favicon.png')) ?>">
    <link rel="stylesheet" href="<?= e(asset('app.css')) ?>">
</head>
<body>
<?php if ($reader): ?>
    <?= $content ?>
<?php else: ?>
<div class="app-shell">
    <aside class="sidebar">
        <a class="brand" href="<?= e(url('/')) ?>" aria-label="Cifra Santa, início"><span class="brand-mark"><?= lit_icon('mark',28) ?></span><span class="brand-word">cifra<span>santa</span><small>MÚSICA PARA SERVIR</small></span></a>
        <div class="nav-caption">BIBLIOTECA</div>
        <nav class="side-nav" aria-label="Navegação principal">
            <a class="<?= $nav === '/' ? 'active' : '' ?>" href="<?= e(url('/')) ?>"><?= icon('home') ?> <span>Início</span></a>
            <a class="<?= $nav === '/buscar' ? 'active' : '' ?>" href="<?= e(url('/buscar')) ?>"><?= icon('search') ?> <span>Explorar cifras</span></a>
            <a class="<?= $nav === '/favoritos' ? 'active' : '' ?>" href="<?= e(url('/favoritos')) ?>"><?= icon('heart') ?> <span>Favoritos</span></a>
            <a class="<?= $nav === '/repertorios' ? 'active' : '' ?>" href="<?= e(url('/repertorios')) ?>"><?= icon('list') ?> <span>Repertórios</span></a>
        </nav>
        <div class="sidebar-divider"></div><div class="nav-caption smaller">ACESSO RÁPIDO</div>
        <nav class="quick-nav" aria-label="Repertórios rápidos">
            <a href="<?= e(url('/repertorios/missa-domingo')) ?>"><span class="quick-dot blue"></span>Missa de domingo</a>
            <a href="<?= e(url('/repertorios/grupo-oracao')) ?>"><span class="quick-dot gold"></span>Grupo de oração</a>
            <a href="<?= e(url('/repertorios/adoracao')) ?>"><span class="quick-dot violet"></span>Noite de adoração</a>
        </nav>
        <div class="sidebar-bottom"><div class="sidebar-symbol" aria-hidden="true"><?= lit_icon('mark',46) ?></div><div class="sidebar-caption">FEITO PARA QUEM<br>TOCA COM PROPÓSITO.</div><div class="profile"><span class="avatar">CS</span><span><strong>Comunidade</strong><small>Versão de demonstração</small></span><span class="profile-status"></span></div></div>
    </aside>
    <div class="main-area">
        <header class="topbar">
            <a class="mobile-brand" href="<?= e(url('/')) ?>" aria-label="Cifra Santa, início"><span class="brand-mark"><?= lit_icon('mark',25) ?></span><span>cifra<strong>santa</strong></span></a>
            <form class="global-search" action="<?= e(url('/buscar')) ?>" method="get"><?= icon('search',19) ?><input name="q" aria-label="Buscar música ou artista" placeholder="Encontre uma cifra, artista ou momento" value="<?= e($_GET['q'] ?? '') ?>"><button type="submit">Buscar <span class="search-shortcut">↵</span></button></form>
            <div class="topbar-actions"><span class="demo-indicator"><i></i> ACERVO DEMO</span><a class="top-favorite" href="<?= e(url('/favoritos')) ?>" aria-label="Abrir favoritos"><?= icon('heart',19) ?></a></div>
        </header>
        <main class="page-content"><?= $content ?></main>
    </div>
</div>
<nav class="mobile-nav" aria-label="Navegação móvel">
    <a class="<?= $nav === '/' ? 'active' : '' ?>" href="<?= e(url('/')) ?>"><?= icon('home') ?><span>Início</span></a>
    <a class="<?= $nav === '/buscar' ? 'active' : '' ?>" href="<?= e(url('/buscar')) ?>"><?= icon('search') ?><span>Buscar</span></a>
    <a class="<?= $nav === '/favoritos' ? 'active' : '' ?>" href="<?= e(url('/favoritos')) ?>"><?= icon('heart') ?><span>Favoritos</span></a>
    <a class="<?= $nav === '/repertorios' ? 'active' : '' ?>" href="<?= e(url('/repertorios')) ?>"><?= icon('list') ?><span>Repertórios</span></a>
</nav>
<?php endif; ?>
<script defer src="<?= e(asset('reader.js')) ?>"></script>
<script defer src="<?= e(asset('app.js')) ?>"></script>
</body>
</html>
