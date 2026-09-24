import 'package:flutter/material.dart';

enum MenuGroup {
  main(''),
  prayerLife('VIDA DE ORAÇÃO'),
  library('MINHA BIBLIOTECA'),
  community('COMUNIDADE'),
  app('CIFRA SANTA');

  const MenuGroup(this.title);
  final String title;
}

/// Áreas principais do aplicativo. É a única lista de destinos do menu lateral.
enum AppDestination {
  inicio(
    'Início',
    Icons.home_outlined,
    Icons.home_rounded,
    MenuGroup.main,
    'Central do Cifra Santa',
  ),
  cifras(
    'Cifras',
    Icons.queue_music_outlined,
    Icons.queue_music_rounded,
    MenuGroup.main,
    'Cantos para celebrar',
  ),
  liturgia(
    'Liturgia Diária',
    Icons.auto_stories_outlined,
    Icons.auto_stories_rounded,
    MenuGroup.main,
    'Palavra do dia',
  ),
  biblia(
    'Bíblia Católica',
    Icons.menu_book_outlined,
    Icons.menu_book_rounded,
    MenuGroup.main,
    'Sagrada Escritura',
  ),
  oracoes(
    'Orações',
    Icons.volunteer_activism_outlined,
    Icons.volunteer_activism_rounded,
    MenuGroup.prayerLife,
    'Reze conosco',
  ),
  santoDoDia(
    'Santo do Dia',
    Icons.wb_twilight_outlined,
    Icons.wb_twilight_rounded,
    MenuGroup.prayerLife,
    'Vida dos santos',
  ),
  terco(
    'Santo Terço',
    Icons.blur_circular_outlined,
    Icons.blur_circular_rounded,
    MenuGroup.prayerLife,
    'Rezar passo a passo',
  ),
  calendario(
    'Calendário Litúrgico',
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
    MenuGroup.prayerLife,
    'Liturgia por data',
  ),
  favoritos(
    'Favoritos',
    Icons.favorite_border_rounded,
    Icons.favorite_rounded,
    MenuGroup.library,
    'Seus itens salvos',
  ),
  igrejas(
    'Igrejas Apoiadoras',
    Icons.church_outlined,
    Icons.church_rounded,
    MenuGroup.community,
    'Quem caminha conosco',
  ),
  sobre(
    'Sobre o Cifra Santa',
    Icons.info_outline_rounded,
    Icons.info_rounded,
    MenuGroup.app,
    'Nossa proposta',
  ),
  configuracoes(
    'Configurações',
    Icons.settings_outlined,
    Icons.settings_rounded,
    MenuGroup.app,
    'Preferências do aplicativo',
  );

  const AppDestination(
    this.label,
    this.icon,
    this.activeIcon,
    this.group,
    this.description,
  );

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final MenuGroup group;
  final String description;
}
