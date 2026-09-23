<?php
$moments = [
    ['name'=>'Entrada','line'=>'O primeiro acorde da celebração','tone'=>'azure','symbol'=>'church'],
    ['name'=>'Comunhão','line'=>'Canções para esse encontro','tone'=>'gold','symbol'=>'chalice'],
    ['name'=>'Louvor','line'=>'Uma voz que se eleva','tone'=>'violet','symbol'=>'dove'],
    ['name'=>'Envio','line'=>'A música continua lá fora','tone'=>'mint','symbol'=>'send'],
];
?>
<div class="home-v2">
    <section class="hv-hero" aria-labelledby="hv-title">
        <div class="hv-hero-art" aria-hidden="true"><span class="hv-orbit one"></span><span class="hv-orbit two"></span><span class="hv-orbit three"></span><span class="hv-art-star"><?= lit_icon('mark',140) ?></span></div>
        <div class="hv-hero-copy"><span class="hv-kicker"><i></i> MÚSICA PARA SERVIR</span><h1 id="hv-title">Cada celebração<br>tem sua <em>canção.</em></h1><p>Encontre a cifra certa, organize seu repertório e toque com tranquilidade em cada momento.</p>
            <form class="hv-search" action="<?= e(url('/buscar')) ?>" method="get" role="search"><?= icon('search',20) ?><input name="q" aria-label="Buscar cifra, artista ou momento" placeholder="Qual música você quer tocar?"><button type="submit">Encontrar cifra <?= icon('arrow',17) ?></button></form>
            <div class="hv-hero-foot"><span><?= str_pad((string)count($songs),2,'0',STR_PAD_LEFT) ?> músicas no catálogo</span><span>·</span><span><?= count($repertoires) ?> repertórios prontos</span></div>
        </div>
        <a class="hv-feature" href="<?= e(url('/cifra/sacramento-comunhao')) ?>"><span class="hv-feature-top"><span class="hv-feature-pulse"></span> CIFRA EM DESTAQUE</span><span class="hv-feature-symbol" aria-hidden="true"><?= lit_icon('chalice',68) ?></span><strong>Sacramento da<br>Comunhão</strong><small>Nelsinho Corrêa · Tom D</small><span class="hv-feature-link">Abrir cifra <?= icon('arrow',17) ?></span></a>
    </section>

    <section class="hv-moments" aria-labelledby="hv-moments-title"><div class="hv-section-heading"><div><span class="hv-eyebrow">ENCONTRE SEU MOMENTO</span><h2 id="hv-moments-title">Por onde vamos começar?</h2></div><p>Uma forma simples de chegar à música certa.</p></div>
        <div class="hv-moment-grid"><?php foreach ($moments as $index=>$moment): $count=count(array_filter($songs, static fn(array $song): bool => $song['category']===$moment['name'])); ?><a class="hv-moment <?= e($moment['tone']) ?>" href="<?= e(url('/buscar?momento='.rawurlencode($moment['name']))) ?>"><span class="hv-moment-top"><span><?= str_pad((string)($index+1),2,'0',STR_PAD_LEFT) ?></span><span aria-hidden="true"><?= lit_icon($moment['symbol'],34) ?></span></span><strong><?= e($moment['name']) ?></strong><small><?= e($moment['line']) ?></small><span class="hv-moment-bottom"><?= $count ?> <?= $count===1 ? 'música' : 'músicas' ?> <?= icon('arrow',16) ?></span></a><?php endforeach; ?></div>
    </section>

    <div class="hv-content-grid"><section class="hv-library" aria-labelledby="hv-library-title"><div class="hv-section-heading"><div><span class="hv-eyebrow">ACERVO DA COMUNIDADE</span><h2 id="hv-library-title">Prontas para tocar <span class="hv-count"><?= str_pad((string)count($songs),2,'0',STR_PAD_LEFT) ?></span></h2></div><a href="<?= e(url('/buscar')) ?>">Ver todas <?= icon('arrow',17) ?></a></div><div class="song-grid"><?php foreach ($songs as $song) partial('song-card', compact('song')); ?></div><a class="hv-library-more" href="<?= e(url('/buscar')) ?>">Explorar biblioteca completa <?= icon('arrow',18) ?></a></section>
        <aside class="hv-aside" aria-label="Repertórios"><div class="hv-section-heading"><div><span class="hv-eyebrow">PLANEJE O PRÓXIMO ENCONTRO</span><h2>Repertórios</h2></div></div><a class="hv-rep-feature" href="<?= e(url('/repertorios/missa-domingo')) ?>"><span class="hv-rep-kicker"><i></i> EM DESTAQUE</span><span class="hv-rep-art" aria-hidden="true"><?= lit_icon('book',125) ?></span><strong>Missa de domingo</strong><small>Da entrada ao envio, tudo no mesmo lugar.</small><span class="hv-rep-footer"><span>04 músicas</span><span>Abrir repertório <?= icon('arrow',17) ?></span></span></a><div class="hv-rep-list"><?php foreach (array_slice($repertoires,1) as $item): ?><a href="<?= e(url('/repertorios/'.$item['id'])) ?>"><span class="hv-rep-dot <?= e($item['color']) ?>"></span><span><strong><?= e($item['title']) ?></strong><small><?= count($item['songs']) ?> músicas · <?= e($item['context']) ?></small></span><?= icon('arrow',16) ?></a><?php endforeach; ?></div><div class="hv-aside-note"><?= lit_icon('mark',18) ?><span>Uma biblioteca feita para acompanhar quem toca com propósito.</span></div></aside>
    </div>
</div>
