/* Cifra Santa · Painel administrativo — melhorias progressivas.
   O painel continua funcionando sem JavaScript; aqui ficam apenas conveniências:
   tema, filtro da biblioteca, prévia ao vivo da cifra e montador de repertório.
   Nada é avaliado como código e todo texto entra no DOM via textContent. */
(function () {
  'use strict';
  var doc = document;
  var root = doc.documentElement;
  root.classList.add('has-js');

  function $(sel, ctx) { return (ctx || doc).querySelector(sel); }
  function $all(sel, ctx) { return Array.prototype.slice.call((ctx || doc).querySelectorAll(sel)); }
  function el(tag, cls, text) {
    var node = doc.createElement(tag);
    if (cls) node.className = cls;
    if (text != null) node.textContent = text;
    return node;
  }
  function plain(text) {
    return String(text || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  }

  /* ---------- Tema (claro/escuro) ---------- */
  var KEY = 'cifrasanta-admin-theme';
  try {
    var saved = localStorage.getItem(KEY);
    if (saved === 'light' || saved === 'dark') root.setAttribute('data-theme', saved);
  } catch (e) { /* armazenamento indisponível: segue o tema do sistema */ }
  $all('[data-theme-toggle]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var current = root.getAttribute('data-theme');
      if (!current) current = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
      var next = current === 'light' ? 'dark' : 'light';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem(KEY, next); } catch (e) { /* ignora */ }
    });
  });

  /* ---------- Avisos ---------- */
  $all('[data-notice]').forEach(function (box) {
    var close = $('[data-notice-close]', box);
    if (close) close.addEventListener('click', function () { box.classList.add('is-gone'); });
    if (box.classList.contains('is-ok')) setTimeout(function () { box.classList.add('is-gone'); }, 9000);
  });

  /* Biblioteca: busca, filtro e paginação são feitos no servidor (admin.php, GET q/status/p). */

  /* ---------- Cifra: interpretação e prévia ---------- */
  var CHORD = /^[A-G](?:#|b)?(?:(?:maj|min|dim|aug|sus|add|m|M)|[0-9#b()+°º-])*(?:\/[A-G](?:#|b)?)?$/;

  function splitLine(line) {
    var re = /\[([^\]]+)\]/g, m, lyric = '', chords = '', cursor = 0, found = false;
    while ((m = re.exec(line)) !== null) {
      if (!CHORD.test(m[1])) continue; // [Refrão] e afins seguem como texto
      lyric += line.slice(cursor, m.index);
      var position = Array.from(lyric).length;
      if (chords.length < position) chords += new Array(position - chords.length + 1).join(' ');
      else if (chords !== '' && chords.charAt(chords.length - 1) !== ' ') chords += ' ';
      chords += m[1];
      cursor = m.index + m[0].length;
      found = true;
    }
    lyric += line.slice(cursor);
    return { chords: chords, lyric: lyric, found: found };
  }

  function renderChart(target, text) {
    while (target.firstChild) target.removeChild(target.firstChild);
    var lines = String(text || '').replace(/\r\n?/g, '\n').split('\n');
    var any = false;
    lines.forEach(function (line) {
      var trimmed = line.trim();
      if (trimmed === '') { if (any) target.appendChild(el('div', 'gap')); return; }
      var section = /^\[([^\]]{1,80})\]$/.exec(trimmed);
      if (section && !CHORD.test(section[1])) { target.appendChild(el('span', 'sec', section[1])); any = true; return; }
      var parts = splitLine(line);
      var row = el('div', 'row');
      if (parts.found) row.appendChild(el('pre', 'chords', parts.chords));
      row.appendChild(el('pre', '', parts.lyric === '' ? ' ' : parts.lyric));
      target.appendChild(row);
      any = true;
    });
    if (!any) target.appendChild(el('div', 'empty-note', 'Digite a cifra ao lado para ver a prévia.'));
  }

  var editor = $('[data-editor]');
  if (editor) {
    var f = function (name) { return editor.elements[name]; };
    var pTitle = $('#pv-title'), pArtist = $('#pv-artist'), pTom = $('#pv-tom'), pChart = $('#pv-chart');
    var counter = $('#chart-counter');
    var refresh = function () {
      if (pTitle) pTitle.textContent = (f('titulo') && f('titulo').value.trim()) || 'Título da música';
      if (pArtist) pArtist.textContent = (f('artista') && f('artista').value.trim()) || 'Artista / compositor';
      if (pTom) {
        var tom = f('tom') ? f('tom').value.trim() : '';
        pTom.textContent = tom ? 'Tom ' + tom : 'Sem tom';
      }
      if (pChart && f('conteudo')) renderChart(pChart, f('conteudo').value);
      if (counter && f('conteudo')) counter.textContent = f('conteudo').value.length.toLocaleString('pt-BR') + ' / 100.000 caracteres';
    };
    ['titulo', 'artista', 'tom', 'conteudo'].forEach(function (name) {
      if (f(name)) f(name).addEventListener('input', refresh);
    });
    refresh();
  }

  /* Atalhos de preenchimento (categoria e tom) */
  $all('[data-fill]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var form = btn.closest('form');
      var field = form && form.elements[btn.getAttribute('data-fill')];
      if (!field) return;
      field.value = btn.getAttribute('data-value') || btn.textContent.trim();
      field.dispatchEvent(new Event('input', { bubbles: true }));
      $all('[data-fill="' + btn.getAttribute('data-fill') + '"]', form).forEach(function (b) { b.classList.toggle('is-on', b === btn); });
    });
  });

  /* ---------- Importação: estado "Analisando página..." ---------- */
  $all('[data-import-url]').forEach(function (form) {
    form.addEventListener('submit', function () {
      var btn = $('[data-busy]', form);
      if (!btn) return;
      var label = $('span', btn);
      if (label) label.textContent = btn.getAttribute('data-busy');
      btn.setAttribute('aria-busy', 'true');
      // Desabilita depois do envio para não cancelar o próprio submit.
      setTimeout(function () { btn.disabled = true; }, 0);
    });
  });

  /* ---------- Repertório: montador visual ---------- */
  var ids = $('#rep-ids');
  var availBox = $('#pick-avail');
  var selBox = $('#pick-sel');
  if (ids && availBox && selBox) {
    // Todas as músicas (só id/título/artista/rascunho) vêm de #pick-data, da mais recente para a mais antiga,
    // para que a sequência de um repertório nunca perca músicas que não estão na página atual da biblioteca.
    var songs = {};
    var recent = [];
    var order = [];
    var PICK_LIMIT = 100;
    var data = [];
    try { data = JSON.parse(($('#pick-data') || {}).textContent || '[]'); } catch (e) { data = []; }
    data.forEach(function (item) {
      songs[item[0]] = { id: item[0], title: item[1], artist: item[2], draft: item[3] };
      recent.push(item[0]);
    });
    (ids.value || '').split(',').forEach(function (part) {
      var id = part.trim();
      if (/^\d+$/.test(id) && songs[id] && order.indexOf(id) === -1) order.push(id);
    });
    var pickFilter = $('#pick-search');

    var iconBtn = function (label, glyph, handler, disabled) {
      var b = el('button', '', glyph);
      b.type = 'button';
      b.setAttribute('aria-label', label);
      b.title = label;
      b.disabled = !!disabled;
      b.addEventListener('click', handler);
      return b;
    };
    var sync = function () {
      ids.value = order.join(', ');
      draw();
    };
    var draw = function () {
      var q = plain(pickFilter ? pickFilter.value : '');
      while (availBox.firstChild) availBox.removeChild(availBox.firstChild);
      while (selBox.firstChild) selBox.removeChild(selBox.firstChild);
      var count = 0;
      // Sem busca: as 100 mais recentes; com busca: até 100 resultados.
      recent.forEach(function (id) {
        var s = songs[id];
        if (count >= PICK_LIMIT) return;
        if (order.indexOf(id) !== -1) return;
        if (q && plain(s.title + ' ' + s.artist).indexOf(q) === -1) return;
        var li = el('li', 'pick');
        li.appendChild(el('span', 'name', s.title + (s.artist ? ' · ' + s.artist : '') + (s.draft ? ' (rascunho)' : '')));
        li.appendChild(iconBtn('Adicionar ao repertório', '+', function () { order.push(id); sync(); }));
        availBox.appendChild(li);
        count++;
      });
      if (!count) availBox.appendChild(el('li', 'picker-empty', q ? 'Nenhuma música encontrada.' : 'Todas as músicas já estão no repertório.'));
      if (!order.length) selBox.appendChild(el('li', 'picker-empty', 'Clique em + para montar a sequência de execução.'));
      order.forEach(function (id, index) {
        var s = songs[id];
        var li = el('li', 'pick');
        li.appendChild(el('span', 'n', String(index + 1)));
        li.appendChild(el('span', 'name', s.title));
        li.appendChild(iconBtn('Subir', '↑', function () { order.splice(index - 1, 0, order.splice(index, 1)[0]); sync(); }, index === 0));
        li.appendChild(iconBtn('Descer', '↓', function () { order.splice(index + 1, 0, order.splice(index, 1)[0]); sync(); }, index === order.length - 1));
        li.appendChild(iconBtn('Remover', '×', function () { order.splice(index, 1); sync(); }));
        selBox.appendChild(li);
      });
      var total = $('#pick-total');
      if (total) total.textContent = String(order.length);
    };
    if (pickFilter) pickFilter.addEventListener('input', draw);
    // Edição manual do campo de IDs mantém o montador sincronizado.
    ids.addEventListener('change', function () {
      order = [];
      (ids.value || '').split(',').forEach(function (part) {
        var id = part.trim();
        if (/^\d+$/.test(id) && songs[id] && order.indexOf(id) === -1) order.push(id);
      });
      draw();
    });
    draw();
  }

  /* ---------- Menu: destaque da seção visível (Biblioteca/Repertórios) ---------- */
  var navLib = $('[data-nav="biblioteca"]');
  var navRep = $('[data-nav="repertorios"]');
  var secLib = $('#musicas');
  var secRep = $('#repertorios');
  if (navLib && navRep && secLib && secRep && 'IntersectionObserver' in window) {
    var visible = { musicas: true, repertorios: false };
    var paint = function () {
      var repActive = visible.repertorios && !visible.musicas;
      navLib.classList.toggle('is-active', !repActive);
      navRep.classList.toggle('is-active', repActive);
    };
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) { visible[entry.target.id] = entry.isIntersecting; });
      paint();
    }, { rootMargin: '-30% 0px -45% 0px' });
    io.observe(secLib);
    io.observe(secRep);
  }

  /* ---------- Importação: contador do conteúdo ---------- */
  var importArea = $('[data-import-content]');
  var importCounter = $('#import-counter');
  if (importArea && importCounter) {
    var updateImport = function () { importCounter.textContent = importArea.value.length.toLocaleString('pt-BR') + ' / 100.000 caracteres'; };
    importArea.addEventListener('input', updateImport);
    updateImport();
  }
})();
