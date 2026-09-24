import 'package:flutter/foundation.dart';
import 'liturgia.dart';
import 'liturgia_repository.dart';

class LiturgiaStore extends ChangeNotifier {
  LiturgiaStore({LiturgiaRepository? repository})
    : repository = repository ?? LiturgiaRepository();

  final LiturgiaRepository repository;

  DateTime _selectedDate = DateTime.now();
  Liturgia? _liturgia;
  bool _loading = false;
  String? _error;

  // Liturgia de hoje, independente da data escolhida na tela de Liturgia.
  Liturgia? _today;
  bool _todayLoading = false;
  DateTime? _todayDate;
  String? _todayError;

  DateTime get selectedDate => _selectedDate;
  Liturgia? get liturgia => _liturgia;
  bool get loading => _loading;
  String? get error => _error;

  Liturgia? get today => _today;
  bool get todayLoading => _todayLoading;
  String? get todayError => _todayError;

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> loadDate(DateTime date, {bool forceRefresh = false}) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _liturgia = await repository.getLiturgia(_selectedDate);
    } catch (e) {
      _liturgia = null;
      _error = e.toString().isNotEmpty
          ? e.toString()
          : 'Não foi possível carregar a liturgia. Verifique sua conexão e tente novamente.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Carrega a liturgia de hoje usando o mesmo repositório (e cache) da tela
  /// de Liturgia, sem uma nova chamada quando o dia já estiver em cache.
  Future<void> ensureToday({bool force = false}) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final stale = _todayDate != null && _todayDate != day;
    if (_todayLoading || (_today != null && !force && !stale)) return;
    _todayLoading = true;
    _todayError = null;
    notifyListeners();
    try {
      _today = await repository.getLiturgia(day);
      _todayDate = day;
    } catch (e) {
      _today = null;
      _todayError = e.toString().isNotEmpty
          ? e.toString()
          : 'Não foi possível carregar a liturgia de hoje.';
    } finally {
      _todayLoading = false;
      notifyListeners();
    }
  }

  void nextDay() {
    loadDate(_selectedDate.add(const Duration(days: 1)));
  }

  void previousDay() {
    loadDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void goToToday() {
    loadDate(DateTime.now());
  }
}
