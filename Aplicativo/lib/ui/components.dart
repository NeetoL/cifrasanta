import 'package:flutter/material.dart';

import '../core/catalog.dart';
import 'identity.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SacredGlyph(SacredSymbol.mark, size: 31),
      const SizedBox(width: 9),
      RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: SaintColors.text),
          children: [TextSpan(text: 'cifra'), TextSpan(text: 'santa', style: TextStyle(color: SaintColors.blue))],
        ),
      ),
    ],
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: SaintColors.gold),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.kicker, required this.title, this.action, this.onAction});
  final String kicker;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(kicker),
          const SizedBox(height: 7),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.6)),
        ])),
        if (action != null && onAction != null)
          TextButton.icon(onPressed: onAction, iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward, size: 16), label: Text(action!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
      ],
    ),
  );
}

class SongRow extends StatelessWidget {
  const SongRow({super.key, required this.song, required this.index, required this.favorite, required this.onTap, required this.onFavorite});
  final Song song;
  final int index;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF293439)))),
    child: Row(children: [
      SizedBox(width: 30, child: Text('${index + 1}'.padLeft(2, '0'), style: const TextStyle(color: Color(0xFF78909A), fontSize: 11, fontWeight: FontWeight.w700))),
      Expanded(child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text('${song.artist}  ·  ${song.category}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SaintColors.muted, fontSize: 11)),
          ]),
        ),
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: SaintColors.line), borderRadius: BorderRadius.circular(5)),
        child: Text(song.originalKey, style: const TextStyle(color: SaintColors.blue, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
      IconButton(
        tooltip: favorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
        onPressed: onFavorite,
        icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 21, color: favorite ? SaintColors.gold : const Color(0xFF879BA3)),
      ),
    ]),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.kicker, required this.title, required this.subtitle});
  final String kicker;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 21),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Eyebrow(kicker),
      const SizedBox(height: 11),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 33, letterSpacing: -1.5)),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: SaintColors.muted, fontSize: 13, height: 1.4)),
    ]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.action, this.onAction});
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
    child: Column(children: [
      const SacredGlyph(SacredSymbol.mark, size: 44),
      const SizedBox(height: 18),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: SaintColors.muted, fontSize: 13, height: 1.5)),
      if (action != null && onAction != null) ...[const SizedBox(height: 17), TextButton(onPressed: onAction, child: Text(action!))],
    ]),
  );
}
