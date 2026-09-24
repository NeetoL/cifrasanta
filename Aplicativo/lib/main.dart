import 'package:flutter/material.dart';

import 'core/app_services.dart';
import 'core/bible.dart';
import 'core/library_store.dart';
import 'core/theme_store.dart';
import 'ui/app_shell.dart';
import 'ui/identity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Só o tema é lido antes da primeira tela, para ela não piscar na cor
  // errada; o histórico e o tamanho da cifra são carregados pelo AppShell.
  final library = LibraryStore();
  final theme = ThemeStore();
  await theme.initialize();
  runApp(
    CifraSantaApp(
      library: library,
      services: AppServices(
        bibleText: RemoteBibleTextSource(library),
        theme: theme,
      ),
    ),
  );
}

class CifraSantaApp extends StatefulWidget {
  const CifraSantaApp({super.key, required this.library, this.services});
  final LibraryStore library;
  final AppServices? services;

  @override
  State<CifraSantaApp> createState() => _CifraSantaAppState();
}

class _CifraSantaAppState extends State<CifraSantaApp> {
  late final AppServices services =
      widget.services ??
      AppServices(bibleText: RemoteBibleTextSource(widget.library));
  final ThemeData light = cifraTheme(SaintPalette.light);
  final ThemeData dark = cifraTheme(SaintPalette.dark);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: services.theme,
    builder: (context, _) => MaterialApp(
      title: 'Cifra Santa',
      theme: light,
      darkTheme: dark,
      themeMode: services.theme.mode,
      // Sem animação: as cores do SaintColors trocam de uma vez.
      themeAnimationDuration: Duration.zero,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _PaletteScope(
        brightness: Theme.of(context).brightness,
        child: child!,
      ),
      home: AppShell(library: widget.library, services: services),
    ),
  );
}

/// Aplica a paleta do tema em uso ao [SaintColors] e, quando ela muda,
/// reconstrói todas as telas abertas para que peguem as novas cores.
class _PaletteScope extends StatefulWidget {
  const _PaletteScope({required this.brightness, required this.child});
  final Brightness brightness;
  final Widget child;

  @override
  State<_PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<_PaletteScope> {
  bool _built = false;

  static void _rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.brightness == Brightness.dark
        ? SaintPalette.dark
        : SaintPalette.light;
    if (!identical(SaintColors.palette, palette)) {
      SaintColors.use(palette);
      // No primeiro build as telas ainda vão ser criadas já com a paleta nova.
      if (_built) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) (context as Element).visitChildren(_rebuild);
        });
      }
    }
    _built = true;
    return widget.child;
  }
}
