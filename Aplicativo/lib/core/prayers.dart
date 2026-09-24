import 'dart:convert';

import 'package:flutter/services.dart';

class Prayer {
  const Prayer({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.text,
    this.subtitle = '',
    this.reference = '',
  });

  final String id;
  final String categoryId;
  final String title;
  final String subtitle;
  final String reference;
  final String text;

  factory Prayer.fromJson(String categoryId, Map<String, dynamic> json) =>
      Prayer(
        id: json['id'] as String,
        categoryId: categoryId,
        title: json['title'] as String,
        subtitle: (json['subtitle'] as String?) ?? '',
        reference: (json['reference'] as String?) ?? '',
        text: json['text'] as String,
      );
}

class PrayerCategory {
  const PrayerCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.prayers,
  });

  final String id;
  final String title;
  final String description;
  final List<Prayer> prayers;

  factory PrayerCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return PrayerCategory(
      id: id,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      prayers: List.unmodifiable(
        (json['prayers'] as List).map(
          (item) => Prayer.fromJson(id, item as Map<String, dynamic>),
        ),
      ),
    );
  }
}

/// Lê as orações do arquivo de dados. Novas orações entram apenas no JSON.
class PrayerRepository {
  PrayerRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/oracoes.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  List<PrayerCategory>? _categories;

  Future<List<PrayerCategory>> categories() async {
    final cached = _categories;
    if (cached != null) return cached;
    final decoded =
        jsonDecode(await _bundle.loadString(assetPath)) as Map<String, dynamic>;
    return _categories = List.unmodifiable(
      (decoded['categories'] as List).map(
        (item) => PrayerCategory.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<Prayer?> byId(String id) async {
    for (final category in await categories()) {
      for (final prayer in category.prayers) {
        if (prayer.id == id) return prayer;
      }
    }
    return null;
  }

  /// Sugestão para o card da Home: oração da manhã até o meio-dia, da noite depois.
  Future<Prayer?> prayerOfTheMoment(DateTime now) =>
      byId(now.hour < 12 ? 'oracao-da-manha' : 'oracao-da-noite');
}
