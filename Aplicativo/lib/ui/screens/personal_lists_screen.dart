import 'package:flutter/material.dart';
import '../../core/catalog.dart';
import '../../core/personal_lists.dart';
import '../components.dart';
import '../../core/moments.dart';

class PersonalListsScreen extends StatelessWidget {
  const PersonalListsScreen({
    super.key,
    required this.store,
    required this.onSong,
    required this.onRepertoire,
  });
  final PersonalLists store;
  final ValueChanged<Song> onSong;
  final ValueChanged<Repertoire> onRepertoire;
  void edit(BuildContext context, [PersonalList? list]) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              EditPersonalListScreen(store: store, list: list, onSong: onSong),
        ),
      );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          kicker: 'SUAS MÚSICAS',
          title: 'Minhas listas',
          subtitle: 'Escolha o nome, as músicas e a ordem para tocar.',
        ),
        Text(
          store.library.signedIn
              ? 'Novas listas ficam salvas na sua conta. As listas do celular continuam disponíveis abaixo.'
              : 'Sem conta, suas listas ficam salvas somente neste celular.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Criar lista'),
        ),
        if (store.loading) const LinearProgressIndicator(),
        if (store.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(store.error!),
          ),
        if (store.items.isEmpty && !store.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Crie sua primeira lista para organizar as cifras.'),
          ),
        for (final list in store.items)
          ListTile(
            leading: Icon(
              list.local ? Icons.phone_android : Icons.cloud_outlined,
            ),
            title: Text(list.title),
            subtitle: Text(
              '${list.songIds.length} músicas · ${list.local ? "Neste celular" : "Na sua conta"}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => edit(context, list),
          ),
        const SizedBox(height: 24),
        const Text(
          'Repertórios da comunidade',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        if (Catalog.repertoires.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum repertório publicado'),
          ),
        for (final list in Catalog.repertoires)
          ListTile(
            title: Text(list.title),
            subtitle: Text('${list.songIds.length} músicas'),
            onTap: () => onRepertoire(list),
          ),
      ],
    ),
  );
}

class EditPersonalListScreen extends StatefulWidget {
  const EditPersonalListScreen({
    super.key,
    required this.store,
    this.list,
    required this.onSong,
  });
  final PersonalLists store;
  final PersonalList? list;
  final ValueChanged<Song> onSong;
  @override
  State<EditPersonalListScreen> createState() => _EditPersonalListScreenState();
}

class _EditPersonalListScreenState extends State<EditPersonalListScreen> {
  late final name = TextEditingController(text: widget.list?.title ?? '');
  late final ids = List<String>.of(widget.list?.songIds ?? []);
  late final local = widget.list?.local ?? !widget.store.library.signedIn;
  late final String? session;
  bool busy = false;
  bool dirty = false;
  String? error;
  @override
  void initState() {
    super.initState();
    session = widget.store.library.api.token;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void finish() {
    setState(() {
      dirty = false;
      busy = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> save() async {
    setState(() => busy = true);
    final result = await widget.store.save(
      original: widget.list,
      title: name.text,
      songIds: List.of(ids),
      local: local,
      session: session,
    );
    if (!mounted) return;
    if (result == null) {
      finish();
    } else {
      setState(() {
        busy = false;
        error = result;
      });
    }
  }

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir esta lista?'),
        content: const Text('As músicas continuam no catálogo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    final result = await widget.store.delete(widget.list!, session);
    if (!mounted) return;
    if (result == null) {
      finish();
    } else {
      setState(() {
        busy = false;
        error = result;
      });
    }
  }

  Future<void> addSongs() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => _SongPicker(selected: ids)),
    );
    if (selected != null && mounted) {
      setState(() {
        ids
          ..clear()
          ..addAll(selected);
        dirty = true;
      });
    }
  }

  Future<void> leave() async {
    if (busy) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair sem salvar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.list == null ? 'Criar lista' : 'Minha lista'),
        actions: [
          if (widget.list != null)
            IconButton(
              tooltip: 'Excluir lista',
              onPressed: busy ? null : remove,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ReorderableListView.builder(
        header: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                enabled: !busy,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Nome da lista'),
                onChanged: (_) => setState(() => dirty = true),
              ),
              Text(
                local ? 'Salva somente neste celular' : 'Salva na sua conta',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : addSongs,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Escolher músicas'),
              ),
              const Text(
                'Toque para abrir a cifra. Arraste pela alça para mudar a ordem.',
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        footer: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'Salvando...' : 'Salvar lista'),
              ),
            ),
          ),
        ),
        buildDefaultDragHandles: false,
        itemCount: ids.length,
        onReorderItem: (oldIndex, newIndex) {
          if (busy) return;
          setState(() {
            ids.insert(newIndex, ids.removeAt(oldIndex));
            dirty = true;
          });
        },
        itemBuilder: (context, index) {
          final song = Catalog.song(ids[index]);
          return ListTile(
            key: ValueKey(ids[index]),
            leading: Text('${index + 1}'),
            title: Text(song?.title ?? 'Música indisponível'),
            subtitle: song == null ? null : Text(song.artist),
            onTap: song == null || busy ? null : () => widget.onSong(song),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Remover da lista',
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          ids.removeAt(index);
                          dirty = true;
                        }),
                  icon: const Icon(Icons.close),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: !busy,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _SongPicker extends StatefulWidget {
  const _SongPicker({required this.selected});
  final List<String> selected;
  @override
  State<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends State<_SongPicker> {
  late final selected = List<String>.of(widget.selected);
  String query = '';
  @override
  Widget build(BuildContext context) {
    final term = Moments.normalize(query);
    final songs = Catalog.songs
        .where((s) => s.searchKey.contains(term))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher músicas'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Concluir'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar música ou artista',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Text('${selected.length} de 100 músicas'),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return CheckboxListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  value: selected.contains(song.id),
                  onChanged: (value) {
                    if (value == true && selected.length >= 100) return;
                    setState(() {
                      if (value == true) {
                        selected.add(song.id);
                      } else {
                        selected.remove(song.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
