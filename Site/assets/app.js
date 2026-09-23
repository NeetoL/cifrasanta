(() => {
    const base = document.querySelector('meta[name="app-base"]')?.content || '';
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content || '';
    const notes = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
    const path = value => base + value;

    document.addEventListener('click', async event => {
        const button = event.target.closest('[data-favorite-id]');
        if (!button) return;
        const id = button.dataset.favoriteId;
        button.disabled = true;
        try {
            const response = await fetch(path('/favoritos/alternar'), {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
                body: new URLSearchParams({ id, csrf })
            });
            const result = await response.json();
            if (!response.ok) throw new Error(result.error || 'Não foi possível alterar o favorito.');
            document.querySelectorAll('[data-favorite-id]').forEach(item => {
                if (item.dataset.favoriteId !== id) return;
                item.classList.toggle('is-favorite', result.favorite);
                item.classList.toggle('is-active', result.favorite && item.closest('.sr-top-actions') !== null);
                item.setAttribute('aria-label', result.favorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos');
                item.title = result.favorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos';
            });
            if (location.pathname.endsWith('/favoritos')) location.reload();
        } catch (error) { alert(error.message); }
        finally { button.disabled = false; }
    });

    const searchForm = document.querySelector('[data-search-form]');
    if (searchForm) {
        const queryInput = searchForm.querySelector('[data-search-query]');
        const categoryInput = searchForm.querySelector('[data-search-category]');
        const keyInput = searchForm.querySelector('[data-search-key]');
        const normalize = value => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('pt-BR');
        const filter = () => {
            const query = normalize(queryInput.value.trim());
            const category = categoryInput.value;
            const key = keyInput.value;
            let count = 0;
            document.querySelectorAll('[data-song-card]').forEach(card => {
                const matches = (!query || [card.dataset.title, card.dataset.artist, card.dataset.category].some(value => normalize(value).includes(query))) && (!category || card.dataset.category === category) && (!key || card.dataset.key === key);
                card.hidden = !matches;
                if (matches) count++;
            });
            document.querySelector('[data-result-count]').textContent = `${count} ${count === 1 ? 'música' : 'músicas'}`;
            document.querySelector('[data-result-caption]').textContent = `${count} ${count === 1 ? 'encontrada' : 'encontradas'}`;
            document.querySelector('[data-search-empty]').hidden = count !== 0;
            const params = new URLSearchParams();
            if (queryInput.value.trim()) params.set('q', queryInput.value.trim());
            if (category) params.set('momento', category);
            if (key) params.set('tom', key);
            history.replaceState(null, '', path('/buscar') + (params.size ? `?${params}` : ''));
        };
        queryInput.addEventListener('input', filter);
        categoryInput.addEventListener('change', filter);
        keyInput.addEventListener('change', filter);
    }

    const reader = document.querySelector('[data-reader]');
    if (reader) {
        const originalChords = [...reader.querySelectorAll('[data-chords]')].map(node => node.textContent);
        const chart = reader.querySelector('[data-chart]');
        const diagramStrip = reader.querySelector('[data-diagram-strip]');
        const diagramNote = reader.querySelector('[data-diagram-note]');
        const panel = reader.querySelector('.sr-panel');
        const state = { shift: 0, font: 100, capo: 0, bpm: 80, diagrams: true, columns: false, scrolling: false, metronome: false, panel: false };
        const currentKey = () => notes[(2 + state.shift) % 12];
        const transpose = line => line.replace(/[A-G](?:#|b)?/g, note => {
            const index = notes.indexOf(note);
            return index < 0 ? note : notes[(index + state.shift) % 12];
        });
        const setPressed = (action, active) => reader.querySelectorAll(`[data-action="${action}"]`).forEach(button => {
            button.classList.toggle('is-active', active);
            button.setAttribute('aria-pressed', String(active));
        });
        const update = () => {
            reader.querySelectorAll('[data-key-display]').forEach(node => node.textContent = currentKey());
            reader.querySelectorAll('[data-capo-display]').forEach(node => node.textContent = String(state.capo));
            reader.querySelectorAll('[data-bpm-display]').forEach(node => node.textContent = String(state.bpm));
            reader.querySelectorAll('[data-font-display]').forEach(node => node.textContent = `${state.font}%`);
            reader.querySelectorAll('[data-chords]').forEach((node, index) => node.textContent = transpose(originalChords[index]));
            chart.style.fontSize = `${Math.round(15 * state.font / 100)}px`;
            chart.classList.toggle('two-columns', state.columns);
            diagramStrip.hidden = !state.diagrams || state.shift !== 0;
            diagramNote.hidden = !state.diagrams || state.shift === 0;
            panel.classList.toggle('open', state.panel);
            panel.querySelector('.sr-panel-head').setAttribute('aria-expanded', String(state.panel));
            setPressed('scroll', state.scrolling);
            setPressed('metronome', state.metronome);
            setPressed('diagrams', state.diagrams);
            setPressed('columns', state.columns);
            reader.querySelector('[data-scroll-label]').textContent = state.scrolling ? 'Em andamento' : 'Automática';
            reader.querySelector('[data-metronome-label]').textContent = state.metronome ? 'Batida ativa' : 'Marcar tempo';
            const diagramLabel = reader.querySelector('[data-diagram-label]');
            diagramLabel.textContent = state.diagrams ? 'Exibir' : 'Ocultar';
            diagramLabel.classList.toggle('on', state.diagrams);
            const columnsLabel = reader.querySelector('[data-columns-label]');
            columnsLabel.textContent = state.columns ? 'Ligado' : 'Desligado';
            columnsLabel.classList.toggle('on', state.columns);
        };
        reader.addEventListener('click', event => {
            const button = event.target.closest('[data-action]');
            if (!button) return;
            switch (button.dataset.action) {
                case 'panel': state.panel = !state.panel; break;
                case 'key-down': state.shift = (state.shift + 11) % 12; break;
                case 'key-up': state.shift = (state.shift + 1) % 12; break;
                case 'capo-down': state.capo = Math.max(0, state.capo - 1); break;
                case 'capo-up': state.capo = Math.min(12, state.capo + 1); break;
                case 'bpm-down': state.bpm = Math.max(40, state.bpm - 5); if (state.metronome) window.CifraSantaReader.startMetronome(state.bpm); break;
                case 'bpm-up': state.bpm = Math.min(220, state.bpm + 5); if (state.metronome) window.CifraSantaReader.startMetronome(state.bpm); break;
                case 'font-down': state.font = Math.max(80, state.font - 10); break;
                case 'font-up': state.font = Math.min(150, state.font + 10); break;
                case 'diagrams': state.diagrams = !state.diagrams; break;
                case 'columns': state.columns = !state.columns; break;
                case 'scroll': state.scrolling = !state.scrolling; window.CifraSantaReader[state.scrolling ? 'start' : 'stop'](); break;
                case 'metronome': state.metronome = !state.metronome; state.metronome ? window.CifraSantaReader.startMetronome(state.bpm) : window.CifraSantaReader.stopMetronome(); break;
                case 'print': window.CifraSantaReader.print(); return;
                case 'download': {
                    const lines = [...reader.querySelectorAll('.chart-pair')].map(pair => `${pair.querySelector('[data-chords]').textContent}\n${pair.querySelector('.chart-lyrics').textContent}`).join('\n\n');
                    window.CifraSantaReader.download('sacramento-da-comunhao.txt', `Sacramento da Comunhão — Nelsinho Corrêa\nTom: ${currentKey()}\n\n${lines}\n`);
                    return;
                }
            }
            update();
        });
        window.addEventListener('beforeunload', () => { window.CifraSantaReader.stop(); window.CifraSantaReader.stopMetronome(); });
        update();
    }

    const demo = document.querySelector('[data-song-reader]');
    if (demo) {
        let fontSize = 19;
        const keySelect = demo.querySelector('[data-demo-key]');
        const draw = () => {
            const index = notes.indexOf(keySelect.value);
            demo.querySelectorAll('[data-demo-chord]').forEach(node => {
                const step = Number(node.dataset.demoChord);
                const offset = { 3: 5, 4: 7, 5: 9 }[step] || 0;
                node.textContent = notes[(index + offset + 12) % 12] + (step === 5 ? 'm' : '');
            });
            demo.querySelector('[data-demo-sheet]').style.fontSize = `${fontSize}px`;
            demo.querySelector('[data-demo-action="font-down"]').disabled = fontSize <= 16;
            demo.querySelector('[data-demo-action="font-up"]').disabled = fontSize >= 28;
        };
        keySelect.addEventListener('change', draw);
        demo.addEventListener('click', event => {
            const action = event.target.closest('[data-demo-action]')?.dataset.demoAction;
            if (action === 'font-down') fontSize = Math.max(16, fontSize - 2);
            if (action === 'font-up') fontSize = Math.min(28, fontSize + 2);
            if (action === 'focus') {
                const focused = demo.classList.toggle('reader-focus');
                const button = demo.querySelector('[data-demo-action="focus"]');
                button.classList.toggle('is-on', focused);
                button.setAttribute('aria-pressed', String(focused));
                button.querySelector('span').textContent = focused ? 'Sair do palco' : 'Modo palco';
            }
            draw();
        });
        draw();
    }
})();
