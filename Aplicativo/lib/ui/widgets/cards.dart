import 'package:flutter/material.dart';

import '../identity.dart';

/// Cartão discreto do aplicativo: superfície do tema, borda fina e toque opcional.
class SaintCard extends StatelessWidget {
  const SaintCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: Material(
        color: color ?? SaintColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor ?? SaintColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Ícone dentro de um quadrado suave, usado em cartões e listas.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 44, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: SaintColors.accentSurface,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: SaintColors.accentBorder),
    ),
    child: Icon(icon, size: size * .5, color: color ?? SaintColors.gold),
  );
}

/// Tela de conteúdo padrão: centralizada, com largura máxima e rolagem.
class ContentPage extends StatelessWidget {
  const ContentPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 35),
    this.onRefresh,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: children,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: onRefresh == null
            ? list
            : RefreshIndicator(onRefresh: onRefresh!, child: list),
      ),
    );
  }
}

/// Aviso institucional discreto, por exemplo quando uma fonte ainda não existe.
class InfoNotice extends StatelessWidget {
  const InfoNotice({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SaintCard(
    borderColor: SaintColors.goldBorder,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SaintColors.gold, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                style: TextStyle(
                  color: SaintColors.muted,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// FutureBuilder que cria o Future uma única vez, para não recarregar a cada
/// reconstrução da tela pai.
class CachedFutureBuilder<T> extends StatefulWidget {
  const CachedFutureBuilder({
    super.key,
    required this.load,
    required this.builder,
  });

  final Future<T> Function() load;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<CachedFutureBuilder<T>> createState() => _CachedFutureBuilderState<T>();
}

class _CachedFutureBuilderState<T> extends State<CachedFutureBuilder<T>> {
  late final Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<T>(future: _future, builder: widget.builder);
}
