abstract final class Moments {
  static const all = [
    'Adoração',
    'Entrada',
    'Ato penitencial',
    'Glória',
    'Salmo',
    'Evangelho',
    'Profissão de fé',
    'Oração dos fiéis',
    'Ofertório',
    'Santo',
    'Aclamação memorial',
    'Grande amém',
    'Pai Nosso',
    'Abraço da paz',
    'Cordeiro',
    'Comunhão',
    'Pós-comunhão',
    'Final',
    'Louvor',
  ];

  static String normalize(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    return value.toLowerCase().trim().split('').map((c) {
      final index = from.indexOf(c);
      return index < 0 ? c : to[index];
    }).join();
  }

  static String canonical(String value) => switch (normalize(value)) {
    'oferta' || 'ofertorio' || 'apresentacao das oferendas' => 'ofertorio',
    'envio' || 'final' || 'canto final' => 'final',
    'aclamacao' || 'aclamacao ao evangelho' || 'evangelho' => 'evangelho',
    'cordeiro de deus' || 'cordeiro' => 'cordeiro',
    'salmo responsorial' || 'salmo' => 'salmo',
    'acao de gracas' || 'pos-comunhao' => 'pos-comunhao',
    final value => value,
  };

  static bool matches(String stored, String selected) =>
      canonical(stored) == canonical(selected);
}
