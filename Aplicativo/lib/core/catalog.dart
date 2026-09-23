class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.category,
    required this.originalKey,
    this.knownWork = false,
  });

  final String id;
  final String title;
  final String artist;
  final String category;
  final String originalKey;
  final bool knownWork;
}

class Repertoire {
  const Repertoire({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.songIds,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> songIds;
}

abstract final class Catalog {
  static const songs = <Song>[
    Song(id: 'sacramento-comunhao', title: 'Sacramento da Comunhão', artist: 'Nelsinho Corrêa', category: 'Comunhão', originalKey: 'D', knownWork: true),
    Song(id: 'hoje-tempo-louvar', title: 'Hoje é Tempo de Louvar a Deus', artist: 'Catálogo da comunidade', category: 'Louvor', originalKey: 'G', knownWork: true),
    Song(id: 'luz-do-caminho', title: 'Luz do Caminho', artist: 'Composição demonstrativa', category: 'Entrada', originalKey: 'C'),
    Song(id: 'pao-da-partilha', title: 'Pão da Partilha', artist: 'Composição demonstrativa', category: 'Comunhão', originalKey: 'G'),
    Song(id: 'voz-de-esperanca', title: 'Voz de Esperança', artist: 'Composição demonstrativa', category: 'Louvor', originalKey: 'F'),
    Song(id: 'ao-teu-encontro', title: 'Ao Teu Encontro', artist: 'Composição demonstrativa', category: 'Envio', originalKey: 'A'),
  ];

  static const repertoires = <Repertoire>[
    Repertoire(id: 'missa-domingo', title: 'Missa de domingo', subtitle: 'Celebração dominical', songIds: ['luz-do-caminho', 'sacramento-comunhao', 'pao-da-partilha', 'ao-teu-encontro']),
    Repertoire(id: 'grupo-oracao', title: 'Grupo de oração', subtitle: 'Encontro semanal', songIds: ['hoje-tempo-louvar', 'voz-de-esperanca', 'luz-do-caminho']),
    Repertoire(id: 'adoracao', title: 'Noite de adoração', subtitle: 'Momento de oração', songIds: ['voz-de-esperanca', 'pao-da-partilha']),
  ];

  static Song? song(String id) {
    for (final item in songs) {
      if (item.id == id) return item;
    }
    return null;
  }
}
