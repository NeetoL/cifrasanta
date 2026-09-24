import 'package:flutter/material.dart';

import '../components.dart';
import '../identity.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _paragraphs = [
    'O Cifra Santa nasceu para servir à Igreja através da música, da Palavra e da oração.',
    'Reunimos em um só lugar cifras para o canto litúrgico, a liturgia diária, orações tradicionais e o Santo Terço, para acompanhar o dia a dia de músicos, equipes de canto e fiéis.',
    'Nosso compromisso é apresentar conteúdo fiel à tradição católica e usar apenas fontes cujo uso seja devidamente autorizado. Quando ainda não temos uma fonte confiável para algum conteúdo, preferimos dizer isso com clareza a apresentar algo incerto.',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                kicker: 'CIFRA SANTA',
                title: 'Sobre.',
                subtitle: 'Música  •  Palavra  •  Fé',
              ),
              for (final text in _paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 15.5, height: 1.65),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Sugestões e correções são bem-vindas e ajudam a servir melhor à comunidade.',
                style: TextStyle(color: SaintColors.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
