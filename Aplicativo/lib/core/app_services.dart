import 'bible.dart';
import 'churches.dart';
import 'liturgia_store.dart';
import 'local_favorites.dart';
import 'prayers.dart';
import 'rosary.dart';
import 'saints.dart';
import 'theme_store.dart';

/// Serviços compartilhados pelas áreas do aplicativo. Cada área depende apenas
/// da interface de que precisa, o que permite trocar a origem dos dados.
class AppServices {
  AppServices({
    LiturgiaStore? liturgia,
    PrayerRepository? prayers,
    RosaryRepository? rosary,
    BibleCanonRepository? bibleCanon,
    BibleTextSource? bibleText,
    SaintRepository? saints,
    ChurchRepository? churches,
    LocalFavoritesStore? favorites,
    ThemeStore? theme,
  }) : theme = theme ?? ThemeStore(),
       liturgia = liturgia ?? LiturgiaStore(),
       prayers = prayers ?? PrayerRepository(),
       rosary = rosary ?? RosaryRepository(),
       bibleCanon = bibleCanon ?? BibleCanonRepository(),
       bibleText = bibleText ?? UnavailableBibleTextSource(),
       saints = saints ?? const UnavailableSaintRepository(),
       churches = churches ?? const EmptyChurchRepository(),
       favorites = favorites ?? LocalFavoritesStore();

  final LiturgiaStore liturgia;
  final PrayerRepository prayers;
  final RosaryRepository rosary;
  final BibleCanonRepository bibleCanon;
  final BibleTextSource bibleText;
  final SaintRepository saints;
  final ChurchRepository churches;
  final LocalFavoritesStore favorites;
  final ThemeStore theme;
}
