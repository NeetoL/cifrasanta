import 'package:flutter/material.dart';

import '../../core/liturgia.dart';
import '../../core/liturgia_store.dart';
import '../components.dart';
import '../identity.dart';

class LiturgiaScreen extends StatefulWidget {
  const LiturgiaScreen({super.key, this.store, this.embedded = false});

  final LiturgiaStore? store;

  /// Quando verdadeiro, exibe apenas o conteúdo (o menu lateral fornece a barra).
  final bool embedded;

  @override
  State<LiturgiaScreen> createState() => _LiturgiaScreenState();
}

class _LiturgiaScreenState extends State<LiturgiaScreen> {
  late final LiturgiaStore store;

  @override
  void initState() {
    super.initState();
    store = widget.store ?? LiturgiaStore();
    if (store.liturgia == null && !store.loading) {
      store.loadDate(store.selectedDate);
    }
  }

  @override
  void dispose() {
    if (widget.store == null) {
      store.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: store.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: SaintColors.gold,
              onPrimary: SaintColors.background,
              surface: SaintColors.surface,
              onSurface: SaintColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      store.loadDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => widget.embedded
        ? _body(context)
        : Scaffold(
            appBar: AppBar(
              title: const AppBrand(),
              actions: [
                IconButton(
                  tooltip: 'Selecionar data',
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: SaintColors.gold,
                  ),
                  onPressed: () => _selectDate(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _body(context),
          ),
  );

  Widget _body(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: RefreshIndicator(
        onRefresh: () => store.loadDate(store.selectedDate, forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Eyebrow('LITURGIA DIÁRIA'),
              const SizedBox(height: 12),

              // Navegação de Datas
              _DateNavigation(
                store: store,
                onPickCalendar: () => _selectDate(context),
              ),
              const SizedBox(height: 20),

              if (store.loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: SaintColors.gold),
                  ),
                )
              else if (store.error != null)
                EmptyState(
                  title: 'Não foi possível carregar a liturgia',
                  message: store.error!,
                  action: 'Tentar novamente',
                  onAction: () => store.loadDate(store.selectedDate),
                )
              else if (store.liturgia != null)
                _buildLiturgiaContent(store.liturgia!),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildLiturgiaContent(Liturgia liturgia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Liturgia (Data, Celebração, Tempo, Cor)
        _LiturgiaHeader(liturgia: liturgia),
        const SizedBox(height: 24),

        // 1. PRIMEIRA LEITURA
        _LeituraCard(
          kicker: 'PRIMEIRA LEITURA',
          referencia: liturgia.primeiraLeitura.referencia,
          titulo: liturgia.primeiraLeitura.titulo,
          texto: liturgia.primeiraLeitura.texto,
        ),
        const SizedBox(height: 18),

        // 2. SALMO RESPONSORIAL
        _SalmoCard(salmo: liturgia.salmo),
        const SizedBox(height: 18),

        // 3. SEGUNDA LEITURA (Apenas quando houver)
        if (liturgia.hasSegundaLeitura) ...[
          _LeituraCard(
            kicker: 'SEGUNDA LEITURA',
            referencia: liturgia.segundaLeitura!.referencia,
            titulo: liturgia.segundaLeitura!.titulo,
            texto: liturgia.segundaLeitura!.texto,
          ),
          const SizedBox(height: 18),
        ],

        // 4. ACLAMAÇÃO AO EVANGELHO (Apenas when present)
        if (liturgia.hasAclamacao) ...[
          _AclamacaoCard(aclamacao: liturgia.aclamacao!),
          const SizedBox(height: 18),
        ],

        // 5. EVANGELHO
        _LeituraCard(
          kicker: 'EVANGELHO',
          referencia: liturgia.evangelho.referencia,
          titulo: liturgia.evangelho.titulo,
          texto: liturgia.evangelho.texto,
          isEvangelho: true,
        ),
        const SizedBox(height: 24),

        Text(
          'Textos da Liturgia Diária Oficial da Igreja Católica.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SaintColors.subtle, fontSize: 11),
        ),
      ],
    );
  }
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({required this.store, required this.onPickCalendar});

  final LiturgiaStore store;
  final VoidCallback onPickCalendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: SaintColors.surface,
        border: Border.all(color: SaintColors.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: store.loading ? null : store.previousDay,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
            label: const Text('Anterior', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: SaintColors.muted),
          ),
          InkWell(
            onTap: onPickCalendar,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: SaintColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    store.isToday
                        ? 'HOJE'
                        : '${store.selectedDate.day.toString().padLeft(2, '0')}/${store.selectedDate.month.toString().padLeft(2, '0')}/${store.selectedDate.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: SaintColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: store.loading ? null : store.nextDay,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text('Próximo', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: SaintColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LiturgiaHeader extends StatelessWidget {
  const _LiturgiaHeader({required this.liturgia});

  final Liturgia liturgia;

  Color _parseLiturgicalColor(String cor) {
    final lower = cor.toLowerCase().trim();
    if (lower.contains('verd')) return const Color(0xFF4CAF50);
    if (lower.contains('branc')) return const Color(0xFFE0E0E0);
    if (lower.contains('vermelh')) return const Color(0xFFE53935);
    if (lower.contains('rox')) return const Color(0xFFAB47BC);
    if (lower.contains('ros')) return const Color(0xFFEC407A);
    return SaintColors.gold;
  }

  @override
  Widget build(BuildContext context) {
    final colorVal = _parseLiturgicalColor(liturgia.corLiturgica);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: SaintColors.surface,
        border: Border.all(color: SaintColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  liturgia.diaSemana.isNotEmpty
                      ? liturgia.diaSemana
                      : liturgia.data,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorVal.withValues(alpha: 0.18),
                  border: Border.all(color: colorVal.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      liturgia.corLiturgica.toUpperCase(),
                      style: TextStyle(
                        color: colorVal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (liturgia.celebracao.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              liturgia.celebracao,
              style: TextStyle(
                color: SaintColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (liturgia.tempoLiturgico.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              liturgia.tempoLiturgico,
              style: TextStyle(color: SaintColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeituraCard extends StatelessWidget {
  const _LeituraCard({
    required this.kicker,
    required this.referencia,
    required this.titulo,
    required this.texto,
    this.isEvangelho = false,
  });

  final String kicker;
  final String referencia;
  final String titulo;
  final String texto;
  final bool isEvangelho;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: SaintColors.panel,
        border: Border.all(
          color: isEvangelho ? SaintColors.goldBorder : SaintColors.line,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SacredGlyph(
                isEvangelho ? SacredSymbol.chalice : SacredSymbol.book,
                size: 20,
              ),
              const SizedBox(width: 8),
              Eyebrow(kicker),
              const Spacer(),
              if (referencia.isNotEmpty)
                Text(
                  referencia,
                  style: TextStyle(
                    color: SaintColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (titulo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: SaintColors.gold,
              ),
            ),
          ],
          if (texto.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: SaintColors.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalmoCard extends StatelessWidget {
  const _SalmoCard({required this.salmo});

  final Salmo salmo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: SaintColors.panel,
        border: Border.all(color: SaintColors.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SacredGlyph(SacredSymbol.path, size: 20),
              const SizedBox(width: 8),
              const Eyebrow('SALMO RESPONSORIAL'),
              const Spacer(),
              if (salmo.referencia.isNotEmpty)
                Text(
                  salmo.referencia,
                  style: TextStyle(
                    color: SaintColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (salmo.refrao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SaintColors.chip,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: SaintColors.chipBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R. ',
                    style: TextStyle(
                      color: SaintColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      salmo.refrao,
                      style: TextStyle(
                        color: SaintColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (salmo.texto.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              salmo.texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: SaintColors.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AclamacaoCard extends StatelessWidget {
  const _AclamacaoCard({required this.aclamacao});

  final Aclamacao aclamacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: SaintColors.panel,
        border: Border.all(color: SaintColors.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SacredGlyph(SacredSymbol.dove, size: 20),
              const SizedBox(width: 8),
              const Eyebrow('ACLAMAÇÃO AO EVANGELHO'),
              const Spacer(),
              if (aclamacao.referencia.isNotEmpty)
                Text(
                  aclamacao.referencia,
                  style: TextStyle(
                    color: SaintColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (aclamacao.refrao.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              aclamacao.refrao,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: SaintColors.gold,
              ),
            ),
          ],
          if (aclamacao.texto.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              aclamacao.texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: SaintColors.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
