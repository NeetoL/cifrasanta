class Leitura {
  const Leitura({
    required this.referencia,
    required this.titulo,
    required this.texto,
  });

  final String referencia;
  final String titulo;
  final String texto;

  factory Leitura.fromJson(Map<String, dynamic> json) => Leitura(
    referencia: (json['referencia'] as String?)?.trim() ?? '',
    titulo: (json['titulo'] as String?)?.trim() ?? '',
    texto: (json['texto'] as String?)?.trim() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'referencia': referencia,
    'titulo': titulo,
    'texto': texto,
  };

  bool get isValid => texto.isNotEmpty || referencia.isNotEmpty;
}

class Salmo {
  const Salmo({
    required this.referencia,
    required this.refrao,
    required this.texto,
  });

  final String referencia;
  final String refrao;
  final String texto;

  factory Salmo.fromJson(Map<String, dynamic> json) => Salmo(
    referencia: (json['referencia'] as String?)?.trim() ?? '',
    refrao: (json['refrao'] as String?)?.trim() ?? '',
    texto: (json['texto'] as String?)?.trim() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'referencia': referencia,
    'refrao': refrao,
    'texto': texto,
  };

  bool get isValid => texto.isNotEmpty || refrao.isNotEmpty;
}

class Aclamacao {
  const Aclamacao({
    required this.referencia,
    required this.refrao,
    required this.texto,
  });

  final String referencia;
  final String refrao;
  final String texto;

  factory Aclamacao.fromJson(Map<String, dynamic> json) => Aclamacao(
    referencia: (json['referencia'] as String?)?.trim() ?? '',
    refrao:
        (json['refrao'] as String?)?.trim() ??
        (json['titulo'] as String?)?.trim() ??
        '',
    texto: (json['texto'] as String?)?.trim() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'referencia': referencia,
    'refrao': refrao,
    'texto': texto,
  };

  bool get isValid => texto.isNotEmpty || refrao.isNotEmpty;
}

class Liturgia {
  const Liturgia({
    required this.data,
    required this.diaSemana,
    required this.celebracao,
    required this.tempoLiturgico,
    required this.corLiturgica,
    required this.primeiraLeitura,
    required this.salmo,
    this.segundaLeitura,
    this.aclamacao,
    required this.evangelho,
  });

  final String data;
  final String diaSemana;
  final String celebracao;
  final String tempoLiturgico;
  final String corLiturgica;
  final Leitura primeiraLeitura;
  final Salmo salmo;
  final Leitura? segundaLeitura;
  final Aclamacao? aclamacao;
  final Leitura evangelho;

  bool get hasSegundaLeitura =>
      segundaLeitura != null && segundaLeitura!.isValid;

  bool get hasAclamacao => aclamacao != null && aclamacao!.isValid;

  factory Liturgia.fromJson(Map<String, dynamic> json) {
    // Trata primeira leitura
    final primeiraRaw = json['primeiraLeitura'];
    final primeira = primeiraRaw is Map
        ? Leitura.fromJson(Map<String, dynamic>.from(primeiraRaw))
        : const Leitura(referencia: '', titulo: '', texto: '');

    // Trata salmo
    final salmoRaw = json['salmo'];
    final salmoObj = salmoRaw is Map
        ? Salmo.fromJson(Map<String, dynamic>.from(salmoRaw))
        : const Salmo(referencia: '', refrao: '', texto: '');

    // Trata segunda leitura (opcional)
    final segundaRaw = json['segundaLeitura'];
    Leitura? segundaObj;
    if (segundaRaw is Map) {
      final parsed = Leitura.fromJson(Map<String, dynamic>.from(segundaRaw));
      if (parsed.isValid) segundaObj = parsed;
    }

    // Trata aclamação ao evangelho (opcional)
    final aclamacaoRaw = json['aclamacao'] ?? json['aclamação'];
    Aclamacao? aclamacaoObj;
    if (aclamacaoRaw is Map) {
      final parsed = Aclamacao.fromJson(
        Map<String, dynamic>.from(aclamacaoRaw),
      );
      if (parsed.isValid) aclamacaoObj = parsed;
    } else if (aclamacaoRaw is String && aclamacaoRaw.trim().isNotEmpty) {
      aclamacaoObj = Aclamacao(
        referencia: '',
        refrao: '',
        texto: aclamacaoRaw.trim(),
      );
    }

    // Trata evangelho
    final evangelhoRaw = json['evangelho'];
    final evangelhoObj = evangelhoRaw is Map
        ? Leitura.fromJson(Map<String, dynamic>.from(evangelhoRaw))
        : const Leitura(referencia: '', titulo: '', texto: '');

    return Liturgia(
      data: (json['data'] as String?)?.trim() ?? '',
      diaSemana: (json['diaSemana'] as String?)?.trim() ?? '',
      celebracao:
          (json['liturgia'] as String?)?.trim() ??
          (json['celebracao'] as String?)?.trim() ??
          '',
      tempoLiturgico:
          (json['tempoLiturgico'] as String?)?.trim() ??
          (json['tempo'] as String?)?.trim() ??
          'Tempo Comum',
      corLiturgica:
          (json['cor'] as String?)?.trim() ??
          (json['corLiturgica'] as String?)?.trim() ??
          'Verde',
      primeiraLeitura: primeira,
      salmo: salmoObj,
      segundaLeitura: segundaObj,
      aclamacao: aclamacaoObj,
      evangelho: evangelhoObj,
    );
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'diaSemana': diaSemana,
    'liturgia': celebracao,
    'tempoLiturgico': tempoLiturgico,
    'cor': corLiturgica,
    'primeiraLeitura': primeiraLeitura.toJson(),
    'salmo': salmo.toJson(),
    if (segundaLeitura != null) 'segundaLeitura': segundaLeitura!.toJson(),
    if (aclamacao != null) 'aclamacao': aclamacao!.toJson(),
    'evangelho': evangelho.toJson(),
  };
}
