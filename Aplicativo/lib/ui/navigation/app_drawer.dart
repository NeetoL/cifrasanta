import 'package:flutter/material.dart';

import '../components.dart';
import '../identity.dart';
import 'app_destination.dart';

/// Menu lateral do Cifra Santa. Fecha ao escolher e apenas informa o destino.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.current, required this.onSelect});

  final AppDestination current;
  final ValueChanged<AppDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    MenuGroup? lastGroup;
    final entries = <Widget>[];
    for (final destination in AppDestination.values) {
      if (destination.group != lastGroup) {
        if (lastGroup != null) {
          entries.add(const SizedBox(height: 6));
        }
        if (destination.group.title.isNotEmpty) {
          entries.add(_GroupTitle(destination.group.title));
        }
        lastGroup = destination.group;
      }
      entries.add(
        _DrawerItem(
          destination: destination,
          selected: destination == current,
          onTap: () {
            Navigator.of(context).pop();
            onSelect(destination);
          },
        ),
      );
    }
    return Drawer(
      backgroundColor: SaintColors.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DrawerHeader(),
            Divider(height: 1, thickness: 1, color: SaintColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppBrand(),
        const SizedBox(height: 14),
        const Eyebrow('MÚSICA  •  PALAVRA  •  FÉ'),
        const SizedBox(height: 6),
        Container(width: 34, height: 2, color: SaintColors.gold),
      ],
    ),
  );
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
    child: Text(
      title,
      style: TextStyle(
        color: SaintColors.muted,
        fontSize: 10,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? SaintColors.gold : SaintColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Material(
          color: selected
              ? SaintColors.gold.withValues(alpha: .09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 3,
                    height: selected ? 24 : 0,
                    margin: const EdgeInsets.only(right: 13),
                    decoration: BoxDecoration(
                      color: SaintColors.gold,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(width: selected ? 0 : 3),
                  Icon(
                    selected ? destination.activeIcon : destination.icon,
                    size: 22,
                    color: color,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? SaintColors.text
                            : SaintColors.drawerText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
