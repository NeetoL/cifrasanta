import 'package:flutter/material.dart';

import '../../core/library_store.dart';
import '../../core/theme_store.dart';
import '../components.dart';
import '../identity.dart';
import '../widgets/cards.dart';
import 'account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.library, required this.theme});

  final LibraryStore library;
  final ThemeStore theme;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([library, theme]),
    builder: (context, _) => ContentPage(
      children: [
        const PageHeading(
          kicker: 'CIFRA SANTA',
          title: 'Configurações.',
          subtitle: 'Preferências do aplicativo.',
        ),
        const Eyebrow('TEMA'),
        const SizedBox(height: 8),
        SaintCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Aparência',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(switch (theme.mode) {
                ThemeMode.system => 'Segue o tema do celular.',
                ThemeMode.light =>
                  'Fundo claro, bom para ambientes iluminados.',
                ThemeMode.dark => 'Fundo escuro, confortável à noite.',
              }, style: TextStyle(color: SaintColors.muted, fontSize: 12.5)),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Automático'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                ],
                selected: {theme.mode},
                onSelectionChanged: (selection) =>
                    theme.setMode(selection.single),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Eyebrow('TAMANHO DA CIFRA'),
        const SizedBox(height: 8),
        SaintCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tamanho atual: ${library.fontSize.round()}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: library.fontSize,
                min: 8,
                max: 28,
                divisions: 20,
                label: '${library.fontSize.round()}',
                onChanged: library.setFontSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Eyebrow('CONTA'),
        const SizedBox(height: 8),
        SaintCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AccountScreen(library: library),
            ),
          ),
          child: Row(
            children: [
              const IconBadge(Icons.account_circle_outlined, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  library.signedIn
                      ? 'Conectado como ${library.userName}'
                      : 'Entrar ou criar conta',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: SaintColors.muted),
            ],
          ),
        ),
      ],
    ),
  );
}
