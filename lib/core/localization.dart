import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  spanish('es', 'Español'),
  english('en', 'English'),
  german('de', 'Deutsch'),
  italian('it', 'Italiano'),
  french('fr', 'Français'),
  portugueseBrazil('pt-BR', 'Português (Brasil)'),
  dutch('nl', 'Nederlands');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale {
    final parts = code.split('-');
    return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(code);
  }

  static AppLanguage fromCode(String? code) {
    if (code == 'pt') return AppLanguage.portugueseBrazil;
    return AppLanguage.values.firstWhere(
      (language) => language.code.toLowerCase() == code?.toLowerCase(),
      orElse: () => AppLanguage.spanish,
    );
  }

  static AppLanguage fromDevice() {
    final locale = PlatformDispatcher.instance.locale;
    if (locale.languageCode == 'pt') return AppLanguage.portugueseBrazil;
    return fromCode(locale.languageCode);
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>(
  (ref) => AppLanguageNotifier(),
);

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.fromDevice()) {
    _load();
  }

  static const _preferenceKey = 'app_language';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_preferenceKey);
    if (saved != null) state = AppLanguage.fromCode(saved);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, language.code);
  }
}

/// Small, dependency-free translation catalog for the app's product copy.
/// The Spanish source text is intentionally used as the key so untranslated
/// dynamic/API data continues to display safely while the UI is migrated.
class AppTranslations {
  AppTranslations._();

  static String text(
    BuildContext context,
    String source, {
    Map<String, Object?> values = const {},
  }) {
    final language = Localizations.localeOf(context).languageCode;
    final translated = _catalog[language]?[source] ??
        _supplementalCatalog[language]?[source] ??
        _longCopyCatalog[language]?[source] ??
        _directLabelsCatalog[language]?[source] ??
        _statusCatalog[language]?[source] ??
        _screenStatusCatalog[language]?[source] ??
        _legalCatalog[language]?[source] ??
        _privacyCatalog[language]?[source] ??
        source;
    return values.entries.fold(
      translated,
      (result, entry) => result.replaceAll('{${entry.key}}', '${entry.value}'),
    );
  }

  static String plain(String source, String languageCode) =>
      _catalog[languageCode]?[source] ?? source;

  static const Map<String, Map<String, String>> _catalog = {
    'en': {
      'RESUMEN': 'SUMMARY',
      'ANÁLISIS': 'ANALYSIS',
      'MUNDIAL': 'WORLD',
      'CIRCUITO': 'CIRCUIT',
      'LIGA': 'LEAGUE',
      'FANTASY ADVISOR': 'FANTASY ADVISOR',
      'Ajustes': 'Settings',
      'Ayuda a mejorar Polewise': 'Help improve Polewise',
      '¿Quieres compartir estadísticas de uso con Polewise y Google Analytics? Solo enviamos eventos generales; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Would you like to share usage statistics with Polewise and Google Analytics? We only send general events, never your account, session, team, league, or content.',
      'Ver privacidad': 'View privacy',
      'No, gracias': 'No, thanks',
      'Permitir': 'Allow',
      'Resumen': 'Summary',
      'Temporada': 'Season',
      'Gran Premio': 'Grand Prix',
      'Recomendacion': 'Recommendation',
      'Picks del GP': 'Grand Prix picks',
      'ÚLTIMO GRAN PREMIO': 'LAST GRAND PRIX',
      'Sincronizando calendario, resultados y precios...':
          'Syncing calendar, results, and prices...',
      'No se pudieron calcular las predicciones.':
          'Predictions could not be calculated.',
      'Sin calendario. Sincroniza desde Resumen.':
          'No calendar. Sync from Summary.',
      'No se pudo cargar el circuito seleccionado.':
          'The selected circuit could not be loaded.',
      'Historial reciente': 'Recent history',
      'Ganadores de los últimos 5 años': 'Winners from the last 5 years',
      'No se pudo cargar el historial de ganadores.':
          'Winner history could not be loaded.',
      'Afinidad': 'Affinity',
      'Especialistas del circuito': 'Circuit specialists',
      'No se pudo calcular la afinidad del circuito.':
          'Circuit affinity could not be calculated.',
      'Temporada completa': 'Full season',
      'Calendario 2026': '2026 calendar',
      'El calendario aparecerá después de sincronizar.':
          'The calendar will appear after syncing.',
      'No se pudo cargar el calendario completo.':
          'The full calendar could not be loaded.',
      'Fin de semana': 'Weekend',
      'Horarios del GP': 'Grand Prix schedule',
      'Estrategia': 'Strategy',
      'Tu juego': 'Your game',
      'Desde el inicio de la liga': 'Since the start of the league',
      'Fantasy de la app': 'App fantasy',
      'CARRERA A CARRERA': 'RACE BY RACE',
      'PILOTOS': 'DRIVERS',
      'CONSTRUCTORES': 'CONSTRUCTORS',
      'PILOTOS ELEGIDOS': 'SELECTED DRIVERS',
      'CONSTRUCTORES ELEGIDOS': 'SELECTED CONSTRUCTORS',
      'Usar última disponible automáticamente':
          'Automatically use the latest available',
      'Modelo': 'Model',
      'Pesos de la predicción': 'Prediction weights',
      'Restaurar calibrados': 'Restore calibrated values',
      'Sin datos todavía. Sincroniza desde la pestaña Resumen.':
          'No data yet. Sync from the Summary tab.',
      'Error calculando el ranking: {error}':
          'Error calculating the ranking: {error}',
      'POR QUÉ': 'WHY',
      'PUNTOS FANTASY ESPERADOS': 'EXPECTED FANTASY POINTS',
      'POR QUÉ (0–100 POR FACETA)': 'WHY (0–100 BY FACTOR)',
      'Manual o importado': 'Manual or imported',
      'Mi equipo': 'My team',
      'pts esperados este GP': 'expected points this Grand Prix',
      'GUARDAR MI EQUIPO': 'SAVE MY TEAM',
      'Vaciar': 'Clear',
      'Cuenta sincronizada': 'Synced account',
      'Chips de la temporada': 'Season chips',
      'Optimizador': 'Optimizer',
      'Planes de cambios': 'Transfer plans',
      'Equipo guardado': 'Team saved',
      'Introducir mi equipo': 'Enter my team',
      'Guardar mi equipo': 'Save my team',
      'Pilotos': 'Drivers',
      'Constructores': 'Constructors',
      'Competición privada': 'Private competition',
      'Liga': 'League',
      'INICIAR SESIÓN': 'SIGN IN',
      'ACTUALIZAR DATOS DE LIGA': 'UPDATE LEAGUE DATA',
      'Clasificación y evolución': 'Standings and progress',
      'No se pudo abrir la clasificación.':
          'The standings could not be opened.',
      'Sin participantes disponibles. Actualiza la liga.':
          'No participants available. Update the league.',
      'MEDALLERO · POSICIÓN POR CARRERA': 'MEDALS · POSITION BY RACE',
      'EQUIPO': 'TEAM',
      'EVOLUCIÓN DE POSICIONES': 'POSITION PROGRESS',
      'Todo': 'All',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Race points will appear after updating the league.',
      'PUNTOS ACUMULADOS': 'ACCUMULATED POINTS',
      'Cuenta F1 Fantasy': 'F1 Fantasy account',
      'Acceso seguro': 'Secure access',
      'ABRIR WEB OFICIAL': 'OPEN OFFICIAL WEBSITE',
      'Introducir equipo manualmente': 'Enter team manually',
      'Iniciar sesión (navegador)': 'Sign in (browser)',
      'CAPTURAR SESIÓN': 'CAPTURE SESSION',
      'Datos': 'Data',
      'Sincronización': 'Sync',
      'Todavía no se ha sincronizado en esta sesión.':
          'Nothing has been synced in this session yet.',
      'Última sincronización: {date}.': 'Last sync: {date}.',
      'SINCRONIZANDO…': 'SYNCING…',
      'SINCRONIZAR AHORA': 'SYNC NOW',
      'Pesos de predicción': 'Prediction weights',
      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.':
          'The sliders are in the Analysis tab. From here you can restore the model\'s calibrated values.',
      'Restaurar pesos calibrados': 'Restore calibrated weights',
      'Tu cuenta': 'Your account',
      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.':
          'Sign in to import your real team and view your leagues. Public analysis and the manual editor remain available if the official service does not respond.',
      'Gestionar sesión': 'Manage session',
      'Privacidad': 'Privacy',
      'Estadísticas de uso': 'Usage statistics',
      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Help us understand which screens are useful. With permission, Polewise sends general events to its service and Google Analytics, never your account, session, team, league, or content.',
      'Compartir estadísticas anónimas': 'Share anonymous statistics',
      'Activadas': 'Enabled',
      'Desactivadas': 'Disabled',
      'Estadísticas pendientes eliminadas.': 'Pending statistics deleted.',
      'Borrar estadísticas pendientes': 'Delete pending statistics',
      'Tus datos': 'Your data',
      'Borrado local': 'Local deletion',
      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.':
          'Delete the session, team, and imported leagues from this device. This does not delete your account from the official service.',
      '¿Borrar datos locales?': 'Delete local data?',
      'Se cerrará la sesión y se eliminarán el equipo y las ligas guardadas en Polewise.':
          'You will be signed out, and the team and leagues saved in Polewise will be deleted.',
      'Cancelar': 'Cancel',
      'Borrar': 'Delete',
      'Sesión y datos locales eliminados.': 'Session and local data deleted.',
      'Borrar sesión y datos locales': 'Delete session and local data',
      'Legal': 'Legal',
      'Información': 'Information',
      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.':
          'Polewise is an unofficial application. Learn how data is handled and who develops the app.',
      'Acerca de Polewise': 'About Polewise',
      'Versión': 'Version',
      'Desarrollo': 'Development',
      'Soporte': 'Support',
      'Transparencia': 'Transparency',
      'Aplicación no oficial': 'Unofficial application',
      'Fuentes utilizadas': 'Sources used',
      'Responsable': 'Controller',
      'Datos de la cuenta de fantasy': 'Fantasy account data',
      'Estadísticas de uso opcionales': 'Optional usage statistics',
      'Servicios externos': 'External services',
      'Control y eliminación': 'Control and deletion',
      'Seguridad y menores': 'Security and children',
      'Reintentar': 'Retry',
      'Constructor': 'Constructor',
      'victorias': 'wins',
      'PUNTOS': 'POINTS',
      'pts esperados': 'expected points',
      'Presupuesto 100 M\$': 'Budget 100 M\$',
      'Error optimizando: {error}': 'Optimization error: {error}',
      'Clasificacion {season}': 'Standings {season}',
      'Campeonato del mundo': 'World championship',
      'Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.':
          'Official driver and constructor points. Pull down to refresh.',
      'No se pudo cargar la clasificacion general.':
          'The overall standings could not be loaded.',
      'Todavia no hay clasificacion disponible.':
          'No standings are available yet.',
      'Ayuda a saber qué pantallas son útiles.':
          'Help us understand which screens are useful.',
      'Idioma': 'Language',
      'Idioma de la aplicación': 'App language',
      'Elige el idioma de todos los textos de Polewise.':
          'Choose the language for all Polewise text.',
      'Elige temporada y Gran Premio para analizar.':
          'Choose a season and Grand Prix to analyze.',
      'Sin calendario todavia. Desliza para sincronizar.':
          'No calendar yet. Pull down to sync.',
      'No se pudo cargar el calendario guardado.':
          'The saved calendar could not be loaded.',
      'Precios estimados a partir de la tabla del Mundial. Se actualizarán cuando responda F1 Fantasy.':
          'Prices estimated from the World Championship standings. They will update when F1 Fantasy responds.',
      'Aun no hay datos suficientes para predecir.':
          'There is not enough data to predict yet.',
      'Pick principal': 'Main pick',
      'Capitan x2 alternativo': 'Alternative x2 captain',
      'Mejor valor': 'Best value',
      'Evitar por valor': 'Avoid for value',
      'Marca top': 'Top constructor',
      'Fin de semana sprint': 'Sprint weekend',
      'GP ya disputado · modo analisis': 'Grand Prix completed · analysis mode',
      'Actualiza una liga privada para ver aquí la clasificación del último GP.':
          'Update a private league to see the latest Grand Prix standings here.',
      'No se pudo actualizar ahora. Se muestran los datos guardados y estimaciones.':
          'Could not update now. Showing saved data and estimates.',
      'Sin sincronizar todavia. Desliza hacia abajo para descargar datos.':
          'Not synced yet. Pull down to download data.',
      'Datos disponibles. Algunas fuentes externas no respondieron y se usan estimaciones.':
          'Data available. Some external sources did not respond; estimates are being used.',
      'Ronda {round}': 'Round {round}',
      '¡EN MARCHA O FINALIZADO!': 'UNDERWAY OR FINISHED!',
      'DÍAS': 'DAYS',
      'HORAS': 'HOURS',
      'MIN': 'MIN',
      'Construye el equipo ideal o analiza el que ya tienes.':
          'Build the ideal team or analyze the one you already have.',
      'Equipo ideal': 'Ideal team',
      'Equilibrado': 'Balanced',
      'No hay datos suficientes para optimizar. Sincroniza en Resumen.':
          'There is not enough data to optimize. Sync from Summary.',
      'Coste total ': 'Total cost ',
      ' · te sobran {remaining} M\$.': ' · {remaining} M\$ remaining.',
      'Aficionado': 'Fan',
      'Profi': 'Pro',
      'Clasificación': 'Qualifying',
      'Carrera': 'Race',
      'Sprint': 'Sprint',
      'VICTORIA': 'WIN',
      'PODIO': 'PODIUM',
      'TOP 10': 'TOP 10',
      'Pick': 'Pick',
      'Capitán': 'Captain',
      'Valor': 'Value',
      'Riesgo DNF': 'DNF risk',
      'No se pudo cargar la clasificación general.':
          'The overall standings could not be loaded.',
      'No se pudo reconstruir la temporada: {error}':
          'The season could not be reconstructed: {error}',
      'Tu liga': 'Your league',
      'Clasificación privada': 'Private standings',
      'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.':
          'Sign in to see your leagues, positions, and gaps to the leader.',
      'USADO': 'USED',
      'DISP.': 'AVAILABLE',
      'Equipo conservado': 'Team retained',
      '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.':
          '{races} calendar races · {results} new results · {prices} prices.',
      'Las predicciones son estimaciones estadísticas y no garantizan resultados.':
          'Predictions are statistical estimates and do not guarantee results.',
      'Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.':
          'You can sign out and delete all imported data from Settings at any time.',
      'Asistente de análisis y estrategia para fantasy de automovilismo.':
          'Analysis and strategy assistant for motorsport fantasy.',
      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.':
          'Calendar and results: Jolpica-F1. Session data: OpenF1. The optional fantasy account connection is made through the relevant service website.',
      'Libres 1': 'Practice 1',
      'Libres 2': 'Practice 2',
      'Libres 3': 'Practice 3',
      'Clasificación sprint': 'Sprint qualifying',
      'Equipo': 'Team',
      'Alineación simulada actual': 'Current simulated lineup',
      'Importando…': 'Importing…',
      'Traer equipo del Fantasy (requiere sesión)':
          'Import team from Fantasy (sign-in required)',
      'Toca para elegir': 'Tap to choose',
      'Boost ×2 recomendado': 'Recommended x2 boost',
      'Duplicaría {points} pts esperados':
          'Would double {points} expected points',
      '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).':
          '2 free transfers per round; the 3rd costs -10 points (already deducted from net gain).',
      'La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.':
          'The strategy keeps the team or uses up to two free transfers. The budget evolves with the real value of drivers and constructors at each Grand Prix. Points are the complete official points; chips are not simulated.',
    },
    'de': {
      'RESUMEN': 'ÜBERSICHT',
      'ANÁLISIS': 'ANALYSE',
      'MUNDIAL': 'WELTMEISTERSCHAFT',
      'CIRCUITO': 'STRECKE',
      'LIGA': 'LIGA',
      'FANTASY ADVISOR': 'FANTASY-ASSISTENT',
      'Ajustes': 'Einstellungen',
      'Idioma': 'Sprache',
      'Idioma de la aplicación': 'App-Sprache',
      'Resumen': 'Übersicht',
      'Temporada': 'Saison',
      'Gran Premio': 'Grand Prix',
      'Pilotos': 'Fahrer',
      'Constructores': 'Konstrukteure',
      'PILOTOS': 'FAHRER',
      'CONSTRUCTORES': 'KONSTRUKTEURE',
      'PUNTOS': 'PUNKTE',
      'Reintentar': 'Erneut versuchen',
      'Cancelar': 'Abbrechen',
      'Borrar': 'Löschen',
      'Privacidad': 'Datenschutz',
      'Información': 'Informationen',
      'Legal': 'Rechtliches',
      'Acerca de Polewise': 'Über Polewise',
      'Cuenta F1 Fantasy': 'F1-Fantasy-Konto',
      'Acceso seguro': 'Sicherer Zugang',
      'INICIAR SESIÓN': 'ANMELDEN',
      'ABRIR WEB OFICIAL': 'OFFIZIELLE WEBSITE ÖFFNEN',
      'Introducir equipo manualmente': 'Team manuell eingeben',
      'Sincronización': 'Synchronisierung',
      'SINCRONIZAR AHORA': 'JETZT SYNCHRONISIEREN',
      'SINCRONIZANDO…': 'SYNCHRONISIERE…',
      'Restaurar pesos calibrados': 'Kalibrierte Gewichte wiederherstellen',
      'Gestionar sesión': 'Sitzung verwalten',
      'Compartir estadísticas anónimas': 'Anonyme Statistiken teilen',
      'Activadas': 'Aktiviert',
      'Desactivadas': 'Deaktiviert',
      'Borrar estadísticas pendientes': 'Ausstehende Statistiken löschen',
      'Borrar sesión y datos locales': 'Sitzung und lokale Daten löschen',
      'Campeonato del mundo': 'Weltmeisterschaft',
      'Clasificacion {season}': 'Meisterschaft {season}',
      'Tu liga': 'Deine Liga',
      'Tu juego': 'Dein Spiel',
      'Mi equipo': 'Mein Team',
      'Equipo ideal': 'Ideales Team',
      'Historial': 'Verlauf',
      'Sprint': 'Sprint',
      'Carrera': 'Rennen',
      'Clasificación': 'Qualifying',
      'Todo': 'Alle',
      'Constructor': 'Konstrukteur',
      'victorias': 'Siege',
      'pts esperados': 'erwartete Punkte',
      'pts esperados este GP': 'erwartete Punkte für diesen Grand Prix',
      'Guardar mi equipo': 'Mein Team speichern',
      'GUARDAR MI EQUIPO': 'MEIN TEAM SPEICHERN',
      'Vaciar': 'Leeren',
      'Estrategia': 'Strategie',
      'Optimizador': 'Optimierer',
      'Planes de cambios': 'Transferpläne',
      'Fin de semana': 'Wochenende',
      'Horarios del GP': 'Grand-Prix-Zeitplan',
      'Historial reciente': 'Letzte Ergebnisse',
      'Afinidad': 'Affinität',
      'Especialistas del circuito': 'Streckenspezialisten',
      'Temporada completa': 'Gesamte Saison',
      'Calendario 2026': 'Kalender 2026',
      'Modelo': 'Modell',
      'Pesos de la predicción': 'Vorhersagegewichtung',
      'Restaurar calibrados': 'Kalibrierte Werte wiederherstellen',
      'POR QUÉ': 'WARUM',
      'PUNTOS FANTASY ESPERADOS': 'ERWARTETE FANTASY-PUNKTE',
      'PODIO': 'PODIUM',
      'TOP 10': 'TOP 10',
      'VICTORIA': 'SIEG',
      'Pick': 'Tipp',
      'Capitán': 'Kapitän',
      'Valor': 'Wert',
      'Riesgo DNF': 'DNF-Risiko',
      'Recomendacion': 'Empfehlung',
      'Picks del GP': 'Grand-Prix-Tipps',
      'ÚLTIMO GRAN PREMIO': 'LETZTER GRAND PRIX',
      'CARRERA A CARRERA': 'RENNEN FÜR RENNEN',
      'PILOTOS ELEGIDOS': 'AUSGEWÄHLTE FAHRER',
      'CONSTRUCTORES ELEGIDOS': 'AUSGEWÄHLTE KONSTRUKTEURE',
      'CAPTURAR SESIÓN': 'SITZUNG ERFASSEN',
      'Iniciar sesión (navegador)': 'Anmelden (Browser)',
      'DÍAS': 'TAGE',
      'HORAS': 'STUNDEN',
      'MIN': 'MIN',
      'Ronda {round}': 'Runde {round}',
      'USADO': 'VERWENDET',
      'DISP.': 'VERFÜGBAR',
      'Equipo conservado': 'Team beibehalten',
      'Datos': 'Daten',
      'ACTUALIZAR DATOS DE LIGA': 'LIGADATEN AKTUALISIEREN',
      'Competición privada': 'Privater Wettbewerb',
      'Liga': 'Liga',
      'Última sincronización: {date}.': 'Letzte Synchronisierung: {date}.',
      'Estadísticas de uso': 'Nutzungsstatistiken',
      'Tus datos': 'Deine Daten',
      'Borrado local': 'Lokales Löschen',
      'No se pudo abrir la clasificación.':
          'Die Rangliste konnte nicht geöffnet werden.',
      'Sin participantes disponibles. Actualiza la liga.':
          'Keine Teilnehmer verfügbar. Aktualisiere die Liga.',
    },
    'it': {
      'RESUMEN': 'RIEPILOGO',
      'ANÁLISIS': 'ANALISI',
      'MUNDIAL': 'MONDIALE',
      'CIRCUITO': 'CIRCUITO',
      'LIGA': 'LEGA',
      'FANTASY ADVISOR': 'ASSISTENTE FANTASY',
      'Ajustes': 'Impostazioni',
      'Idioma': 'Lingua',
      'Idioma de la aplicación': 'Lingua dell’app',
      'Resumen': 'Riepilogo',
      'Temporada': 'Stagione',
      'Gran Premio': 'Gran Premio',
      'Pilotos': 'Piloti',
      'Constructores': 'Costruttori',
      'PILOTOS': 'PILOTI',
      'CONSTRUCTORES': 'COSTRUTTORI',
      'PUNTOS': 'PUNTI',
      'Reintentar': 'Riprova',
      'Cancelar': 'Annulla',
      'Borrar': 'Elimina',
      'Privacidad': 'Privacy',
      'Información': 'Informazioni',
      'Legal': 'Note legali',
      'Acerca de Polewise': 'Informazioni su Polewise',
      'Cuenta F1 Fantasy': 'Account F1 Fantasy',
      'Acceso seguro': 'Accesso sicuro',
      'INICIAR SESIÓN': 'ACCEDI',
      'ABRIR WEB OFICIAL': 'APRI SITO UFFICIALE',
      'Introducir equipo manualmente': 'Inserisci squadra manualmente',
      'Sincronización': 'Sincronizzazione',
      'SINCRONIZAR AHORA': 'SINCRONIZZA ORA',
      'SINCRONIZANDO…': 'SINCRONIZZAZIONE…',
      'Restaurar pesos calibrados': 'Ripristina pesi calibrati',
      'Gestionar sesión': 'Gestisci sessione',
      'Compartir estadísticas anónimas': 'Condividi statistiche anonime',
      'Activadas': 'Attivate',
      'Desactivadas': 'Disattivate',
      'Borrar estadísticas pendientes': 'Elimina statistiche in attesa',
      'Borrar sesión y datos locales': 'Elimina sessione e dati locali',
      'Campeonato del mundo': 'Campionato del mondo',
      'Clasificacion {season}': 'Classifica {season}',
      'Tu liga': 'La tua lega',
      'Tu juego': 'Il tuo gioco',
      'Mi equipo': 'La mia squadra',
      'Equipo ideal': 'Squadra ideale',
      'Historial': 'Cronologia',
      'Sprint': 'Sprint',
      'Carrera': 'Gara',
      'Clasificación': 'Qualifiche',
      'Todo': 'Tutto',
      'Constructor': 'Costruttore',
      'victorias': 'vittorie',
      'pts esperados': 'punti previsti',
      'pts esperados este GP': 'punti previsti per questo Gran Premio',
      'Guardar mi equipo': 'Salva la mia squadra',
      'GUARDAR MI EQUIPO': 'SALVA LA MIA SQUADRA',
      'Vaciar': 'Svuota',
      'Estrategia': 'Strategia',
      'Optimizador': 'Ottimizzatore',
      'Planes de cambios': 'Piani di trasferimento',
      'Fin de semana': 'Weekend',
      'Horarios del GP': 'Orari del Gran Premio',
      'Historial reciente': 'Cronologia recente',
      'Afinidad': 'Affinità',
      'Especialistas del circuito': 'Specialisti del circuito',
      'Temporada completa': 'Intera stagione',
      'Calendario 2026': 'Calendario 2026',
      'Modelo': 'Modello',
      'Pesos de la predicción': 'Pesi della previsione',
      'Restaurar calibrados': 'Ripristina calibrati',
      'POR QUÉ': 'PERCHÉ',
      'PUNTOS FANTASY ESPERADOS': 'PUNTI FANTASY PREVISTI',
      'PODIO': 'PODIO',
      'TOP 10': 'TOP 10',
      'VICTORIA': 'VITTORIA',
      'Pick': 'Scelta',
      'Capitán': 'Capitano',
      'Valor': 'Valore',
      'Riesgo DNF': 'Rischio DNF',
      'Recomendacion': 'Raccomandazione',
      'Picks del GP': 'Scelte del Gran Premio',
      'ÚLTIMO GRAN PREMIO': 'ULTIMO GRAN PREMIO',
      'CARRERA A CARRERA': 'GARA PER GARA',
      'PILOTOS ELEGIDOS': 'PILOTI SCELTI',
      'CONSTRUCTORES ELEGIDOS': 'COSTRUTTORI SCELTI',
      'CAPTURAR SESIÓN': 'ACQUISISCI SESSIONE',
      'Iniciar sesión (navegador)': 'Accedi (browser)',
      'DÍAS': 'GIORNI',
      'HORAS': 'ORE',
      'MIN': 'MIN',
      'Ronda {round}': 'Round {round}',
      'USADO': 'USATO',
      'DISP.': 'DISPONIBILE',
      'Equipo conservado': 'Squadra mantenuta',
      'Datos': 'Dati',
      'ACTUALIZAR DATOS DE LIGA': 'AGGIORNA DATI DELLA LEGA',
      'Competición privada': 'Competizione privata',
      'Liga': 'Lega',
      'Última sincronización: {date}.': 'Ultima sincronizzazione: {date}.',
      'Estadísticas de uso': 'Statistiche di utilizzo',
      'Tus datos': 'I tuoi dati',
      'Borrado local': 'Eliminazione locale',
      'No se pudo abrir la clasificación.': 'Impossibile aprire la classifica.',
      'Sin participantes disponibles. Actualiza la liga.':
          'Nessun partecipante disponibile. Aggiorna la lega.',
    },
    'fr': {
      'RESUMEN': 'RÉSUMÉ',
      'ANÁLISIS': 'ANALYSE',
      'MUNDIAL': 'MONDIAL',
      'CIRCUITO': 'CIRCUIT',
      'LIGA': 'LIGUE',
      'FANTASY ADVISOR': 'ASSISTANT FANTASY',
      'Ajustes': 'Réglages',
      'Idioma': 'Langue',
      'Idioma de la aplicación': 'Langue de l’application',
      'Resumen': 'Résumé',
      'Temporada': 'Saison',
      'Gran Premio': 'Grand Prix',
      'Pilotos': 'Pilotes',
      'Constructores': 'Constructeurs',
      'PILOTOS': 'PILOTES',
      'CONSTRUCTORES': 'CONSTRUCTEURS',
      'PUNTOS': 'POINTS',
      'Reintentar': 'Réessayer',
      'Cancelar': 'Annuler',
      'Borrar': 'Supprimer',
      'Privacidad': 'Confidentialité',
      'Información': 'Informations',
      'Legal': 'Mentions légales',
      'Acerca de Polewise': 'À propos de Polewise',
      'Cuenta F1 Fantasy': 'Compte F1 Fantasy',
      'Acceso seguro': 'Accès sécurisé',
      'INICIAR SESIÓN': 'SE CONNECTER',
      'ABRIR WEB OFICIAL': 'OUVRIR LE SITE OFFICIEL',
      'Introducir equipo manualmente': 'Saisir l’équipe manuellement',
      'Sincronización': 'Synchronisation',
      'SINCRONIZAR AHORA': 'SYNCHRONISER',
      'SINCRONIZANDO…': 'SYNCHRONISATION…',
      'Restaurar pesos calibrados': 'Restaurer les poids calibrés',
      'Gestionar sesión': 'Gérer la session',
      'Compartir estadísticas anónimas': 'Partager des statistiques anonymes',
      'Activadas': 'Activées',
      'Desactivadas': 'Désactivées',
      'Borrar estadísticas pendientes': 'Supprimer les statistiques en attente',
      'Borrar sesión y datos locales':
          'Supprimer la session et les données locales',
      'Campeonato del mundo': 'Championnat du monde',
      'Clasificacion {season}': 'Classement {season}',
      'Tu liga': 'Votre ligue',
      'Tu juego': 'Votre jeu',
      'Mi equipo': 'Mon équipe',
      'Equipo ideal': 'Équipe idéale',
      'Historial': 'Historique',
      'Sprint': 'Sprint',
      'Carrera': 'Course',
      'Clasificación': 'Qualifications',
      'Todo': 'Tout',
      'Constructor': 'Constructeur',
      'victorias': 'victoires',
      'pts esperados': 'points attendus',
      'pts esperados este GP': 'points attendus pour ce Grand Prix',
      'Guardar mi equipo': 'Enregistrer mon équipe',
      'GUARDAR MI EQUIPO': 'ENREGISTRER MON ÉQUIPE',
      'Vaciar': 'Vider',
      'Estrategia': 'Stratégie',
      'Optimizador': 'Optimiseur',
      'Planes de cambios': 'Plans de transferts',
      'Fin de semana': 'Week-end',
      'Horarios del GP': 'Horaires du Grand Prix',
      'Historial reciente': 'Historique récent',
      'Afinidad': 'Affinité',
      'Especialistas del circuito': 'Spécialistes du circuit',
      'Temporada completa': 'Saison complète',
      'Calendario 2026': 'Calendrier 2026',
      'Modelo': 'Modèle',
      'Pesos de la predicción': 'Poids de la prédiction',
      'Restaurar calibrados': 'Restaurer les valeurs calibrées',
      'POR QUÉ': 'POURQUOI',
      'PUNTOS FANTASY ESPERADOS': 'POINTS FANTASY ATTENDUS',
      'PODIO': 'PODIUM',
      'TOP 10': 'TOP 10',
      'VICTORIA': 'VICTOIRE',
      'Pick': 'Choix',
      'Capitán': 'Capitaine',
      'Valor': 'Valeur',
      'Riesgo DNF': 'Risque DNF',
      'Recomendacion': 'Recommandation',
      'Picks del GP': 'Choix du Grand Prix',
      'ÚLTIMO GRAN PREMIO': 'DERNIER GRAND PRIX',
      'CARRERA A CARRERA': 'COURSE PAR COURSE',
      'PILOTOS ELEGIDOS': 'PILOTES CHOISIS',
      'CONSTRUCTORES ELEGIDOS': 'CONSTRUCTEURS CHOISIS',
      'CAPTURAR SESIÓN': 'CAPTURER LA SESSION',
      'Iniciar sesión (navegador)': 'Se connecter (navigateur)',
      'DÍAS': 'JOURS',
      'HORAS': 'HEURES',
      'MIN': 'MIN',
      'Ronda {round}': 'Manche {round}',
      'USADO': 'UTILISÉ',
      'DISP.': 'DISPONIBLE',
      'Equipo conservado': 'Équipe conservée',
      'Datos': 'Données',
      'ACTUALIZAR DATOS DE LIGA': 'METTRE À JOUR LES DONNÉES DE LA LIGUE',
      'Competición privada': 'Compétition privée',
      'Liga': 'Ligue',
      'Última sincronización: {date}.': 'Dernière synchronisation : {date}.',
      'Estadísticas de uso': 'Statistiques d’utilisation',
      'Tus datos': 'Vos données',
      'Borrado local': 'Suppression locale',
      'No se pudo abrir la clasificación.':
          'Impossible d’ouvrir le classement.',
      'Sin participantes disponibles. Actualiza la liga.':
          'Aucun participant disponible. Mettez la ligue à jour.',
    },
    'pt': {
      'RESUMEN': 'RESUMO',
      'ANÁLISIS': 'ANÁLISE',
      'MUNDIAL': 'MUNDIAL',
      'CIRCUITO': 'CIRCUITO',
      'LIGA': 'LIGA',
      'FANTASY ADVISOR': 'ASSISTENTE FANTASY',
      'Ajustes': 'Configurações',
      'Ayuda a mejorar Polewise': 'Ajude a melhorar o Polewise',
      'Ver privacidad': 'Ver privacidade',
      'No, gracias': 'Não, obrigado',
      'Permitir': 'Permitir',
      'Resumen': 'Resumo',
      'Temporada': 'Temporada',
      'Gran Premio': 'Grande Prêmio',
      'Recomendacion': 'Recomendação',
      'Picks del GP': 'Escolhas do Grande Prêmio',
      'ÚLTIMO GRAN PREMIO': 'ÚLTIMO GRANDE PRÊMIO',
      'Sincronizando calendario, resultados y precios...':
          'Sincronizando calendário, resultados e preços...',
      'No se pudieron calcular las predicciones.':
          'Não foi possível calcular as previsões.',
      'Sin calendario. Sincroniza desde Resumen.':
          'Sem calendário. Sincronize pelo Resumo.',
      'No se pudo cargar el circuito seleccionado.':
          'Não foi possível carregar o circuito selecionado.',
      'Historial reciente': 'Histórico recente',
      'Ganadores de los últimos 5 años': 'Vencedores dos últimos 5 anos',
      'No se pudo cargar el historial de ganadores.':
          'Não foi possível carregar o histórico de vencedores.',
      'Afinidad': 'Afinidade',
      'Especialistas del circuito': 'Especialistas do circuito',
      'No se pudo calcular la afinidad del circuito.':
          'Não foi possível calcular a afinidade do circuito.',
      'Temporada completa': 'Temporada completa',
      'Calendario 2026': 'Calendário de 2026',
      'El calendario aparecerá después de sincronizar.':
          'O calendário aparecerá após a sincronização.',
      'No se pudo cargar el calendario completo.':
          'Não foi possível carregar o calendário completo.',
      'Fin de semana': 'Fim de semana',
      'Horarios del GP': 'Horários do Grande Prêmio',
      'Estrategia': 'Estratégia',
      'Tu juego': 'Seu jogo',
      'Desde el inicio de la liga': 'Desde o início da liga',
      'Fantasy de la app': 'Fantasy do app',
      'CARRERA A CARRERA': 'CORRIDA A CORRIDA',
      'PILOTOS': 'PILOTOS',
      'CONSTRUCTORES': 'CONSTRUTORES',
      'PILOTOS ELEGIDOS': 'PILOTOS ESCOLHIDOS',
      'CONSTRUCTORES ELEGIDOS': 'CONSTRUTORES ESCOLHIDOS',
      'Usar última disponible automáticamente':
          'Usar automaticamente a última disponível',
      'Modelo': 'Modelo',
      'Pesos de la predicción': 'Pesos da previsão',
      'Restaurar calibrados': 'Restaurar calibrados',
      'Sin datos todavía. Sincroniza desde la pestaña Resumen.':
          'Ainda não há dados. Sincronize pela aba Resumo.',
      'Error calculando el ranking: {error}':
          'Erro ao calcular o ranking: {error}',
      'POR QUÉ': 'POR QUÊ',
      'PUNTOS FANTASY ESPERADOS': 'PONTOS FANTASY ESPERADOS',
      'POR QUÉ (0–100 POR FACETA)': 'POR QUÊ (0–100 POR FATOR)',
      'Manual o importado': 'Manual ou importado',
      'Mi equipo': 'Minha equipe',
      'pts esperados este GP': 'pontos esperados neste Grande Prêmio',
      'GUARDAR MI EQUIPO': 'SALVAR MINHA EQUIPE',
      'Vaciar': 'Limpar',
      'Cuenta sincronizada': 'Conta sincronizada',
      'Chips de la temporada': 'Chips da temporada',
      'Optimizador': 'Otimizador',
      'Planes de cambios': 'Planos de transferências',
      'Equipo guardado': 'Equipe salva',
      'Introducir equipo manualmente': 'Inserir equipe manualmente',
      'Guardar mi equipo': 'Salvar minha equipe',
      'Pilotos': 'Pilotos',
      'Constructores': 'Construtores',
      'Competición privada': 'Competição privada',
      'Liga': 'Liga',
      'INICIAR SESIÓN': 'ENTRAR',
      'ACTUALIZAR DATOS DE LIGA': 'ATUALIZAR DADOS DA LIGA',
      'Clasificación y evolución': 'Classificação e evolução',
      'No se pudo abrir la clasificación.':
          'Não foi possível abrir a classificação.',
      'Sin participantes disponibles. Actualiza la liga.':
          'Nenhum participante disponível. Atualize a liga.',
      'MEDALLERO · POSICIÓN POR CARRERA': 'MEDALHEIRO · POSIÇÃO POR CORRIDA',
      'EQUIPO': 'EQUIPE',
      'EVOLUCIÓN DE POSICIONES': 'EVOLUÇÃO DAS POSIÇÕES',
      'Todo': 'Tudo',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Os pontos por corrida aparecerão após atualizar a liga.',
      'PUNTOS ACUMULADOS': 'PONTOS ACUMULADOS',
      'Cuenta F1 Fantasy': 'Conta F1 Fantasy',
      'Acceso seguro': 'Acesso seguro',
      'ABRIR WEB OFICIAL': 'ABRIR SITE OFICIAL',
      'Iniciar sesión (navegador)': 'Entrar (navegador)',
      'CAPTURAR SESIÓN': 'CAPTURAR SESSÃO',
      'Datos': 'Dados',
      'Sincronización': 'Sincronização',
      'Todavía no se ha sincronizado en esta sesión.':
          'Nada foi sincronizado nesta sessão ainda.',
      'Última sincronización: {date}.': 'Última sincronização: {date}.',
      'SINCRONIZANDO…': 'SINCRONIZANDO…',
      'SINCRONIZAR AHORA': 'SINCRONIZAR AGORA',
      'Restaurar pesos calibrados': 'Restaurar pesos calibrados',
      'Tu cuenta': 'Sua conta',
      'Gestionar sesión': 'Gerenciar sessão',
      'Privacidad': 'Privacidade',
      'Estadísticas de uso': 'Estatísticas de uso',
      'Compartir estadísticas anónimas': 'Compartilhar estatísticas anônimas',
      'Activadas': 'Ativadas',
      'Desactivadas': 'Desativadas',
      'Estadísticas pendientes eliminadas.':
          'Estatísticas pendentes excluídas.',
      'Borrar estadísticas pendientes': 'Excluir estatísticas pendentes',
      'Tus datos': 'Seus dados',
      'Borrado local': 'Exclusão local',
      '¿Borrar datos locales?': 'Excluir dados locais?',
      'Cancelar': 'Cancelar',
      'Borrar': 'Excluir',
      'Sesión y datos locales eliminados.': 'Sessão e dados locais excluídos.',
      'Borrar sesión y datos locales': 'Excluir sessão e dados locais',
      'Legal': 'Informações legais',
      'Información': 'Informações',
      'Acerca de Polewise': 'Sobre o Polewise',
      'Versión': 'Versão',
      'Desarrollo': 'Desenvolvimento',
      'Soporte': 'Suporte',
      'Transparencia': 'Transparência',
      'Aplicación no oficial': 'Aplicativo não oficial',
      'Fuentes utilizadas': 'Fontes utilizadas',
      'Responsable': 'Responsável',
      'Datos de la cuenta de fantasy': 'Dados da conta de fantasy',
      'Estadísticas de uso opcionales': 'Estatísticas de uso opcionais',
      'Servicios externos': 'Serviços externos',
      'Control y eliminación': 'Controle e exclusão',
      'Seguridad y menores': 'Segurança e menores',
      'Reintentar': 'Tentar novamente',
      'Constructor': 'Construtor',
      'victorias': 'vitórias',
      'PUNTOS': 'PONTOS',
      'pts esperados': 'pontos esperados',
      'Presupuesto 100 M\$': 'Orçamento de 100 M\$',
      'Clasificacion {season}': 'Classificação {season}',
      'Campeonato del mundo': 'Campeonato mundial',
      'Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.':
          'Pontos oficiais de pilotos e construtores. Deslize para baixo para atualizar.',
      'No se pudo cargar la clasificacion general.':
          'Não foi possível carregar a classificação geral.',
      'Todavia no hay clasificacion disponible.':
          'Ainda não há classificação disponível.',
      'Idioma': 'Idioma',
      'Idioma de la aplicación': 'Idioma do aplicativo',
      'Elige el idioma de todos los textos de Polewise.':
          'Escolha o idioma de todos os textos do Polewise.',
      'Elige temporada y Gran Premio para analizar.':
          'Escolha uma temporada e um Grande Prêmio para analisar.',
      'Sin calendario todavia. Desliza para sincronizar.':
          'Ainda não há calendário. Deslize para sincronizar.',
      'No se pudo cargar el calendario guardado.':
          'Não foi possível carregar o calendário salvo.',
      'Aun no hay datos suficientes para predecir.':
          'Ainda não há dados suficientes para prever.',
      'Pick principal': 'Escolha principal',
      'Capitan x2 alternativo': 'Capitão x2 alternativo',
      'Mejor valor': 'Melhor custo-benefício',
      'Evitar por valor': 'Evitar pelo valor',
      'Marca top': 'Construtor de destaque',
      'Fin de semana sprint': 'Fim de semana de sprint',
      'GP ya disputado · modo analisis':
          'Grande Prêmio concluído · modo de análise',
      'Ronda {round}': 'Rodada {round}',
      '¡EN MARCHA O FINALIZADO!': 'EM ANDAMENTO OU FINALIZADO!',
      'DÍAS': 'DIAS',
      'HORAS': 'HORAS',
      'MIN': 'MIN',
      'Construye el equipo ideal o analiza el que ya tienes.':
          'Monte a equipe ideal ou analise a que você já tem.',
      'Equipo ideal': 'Equipe ideal',
      'Equilibrado': 'Equilibrado',
      'No hay datos suficientes para optimizar. Sincroniza en Resumen.':
          'Não há dados suficientes para otimizar. Sincronize pelo Resumo.',
      'Coste total ': 'Custo total ',
      ' · te sobran {remaining} M\$.': ' · restam {remaining} M\$.',
      'Aficionado': 'Fã',
      'Profi': 'Pro',
      'Clasificación': 'Classificação',
      'Carrera': 'Corrida',
      'Sprint': 'Sprint',
      'VICTORIA': 'VITÓRIA',
      'PODIO': 'PÓDIO',
      'TOP 10': 'TOP 10',
      'Pick': 'Escolha',
      'Capitán': 'Capitão',
      'Valor': 'Valor',
      'Riesgo DNF': 'Risco de abandono',
      'USADO': 'USADO',
      'DISP.': 'DISP.',
      'Equipo conservado': 'Equipe mantida',
      'Importando…': 'Importando…',
      'Traer equipo del Fantasy (requiere sesión)':
          'Importar equipe do Fantasy (requer login)',
      'Toca para elegir': 'Toque para escolher',
      'Boost ×2 recomendado': 'Boost x2 recomendado',
      'Equipo': 'Equipe',
      'Alineación simulada actual': 'Escalação simulada atual',
      'Libres 1': 'Treino 1',
      'Libres 2': 'Treino 2',
      'Libres 3': 'Treino 3',
      'Clasificación sprint': 'Classificação do sprint',
    },
    'nl': {
      'RESUMEN': 'OVERZICHT',
      'ANÁLISIS': 'ANALYSE',
      'MUNDIAL': 'WERELD',
      'CIRCUITO': 'CIRCUIT',
      'LIGA': 'COMPETITIE',
      'FANTASY ADVISOR': 'FANTASY-ASSISTENT',
      'Ajustes': 'Instellingen',
      'Ayuda a mejorar Polewise': 'Help Polewise verbeteren',
      'Ver privacidad': 'Privacy bekijken',
      'No, gracias': 'Nee, bedankt',
      'Permitir': 'Toestaan',
      'Resumen': 'Overzicht',
      'Temporada': 'Seizoen',
      'Gran Premio': 'Grand Prix',
      'Recomendacion': 'Aanbeveling',
      'Picks del GP': 'Grand Prix-keuzes',
      'ÚLTIMO GRAN PREMIO': 'LAATSTE GRAND PRIX',
      'Sincronizando calendario, resultados y precios...':
          'Kalender, resultaten en prijzen synchroniseren...',
      'No se pudieron calcular las predicciones.':
          'Voorspellingen konden niet worden berekend.',
      'Sin calendario. Sincroniza desde Resumen.':
          'Geen kalender. Synchroniseer vanuit Overzicht.',
      'No se pudo cargar el circuito seleccionado.':
          'Het geselecteerde circuit kon niet worden geladen.',
      'Historial reciente': 'Recente geschiedenis',
      'Ganadores de los últimos 5 años': 'Winnaars van de afgelopen 5 jaar',
      'No se pudo cargar el historial de ganadores.':
          'Winnaarsgeschiedenis kon niet worden geladen.',
      'Afinidad': 'Affiniteit',
      'Especialistas del circuito': 'Circuitexperts',
      'No se pudo calcular la afinidad del circuito.':
          'Circuitaffiniteit kon niet worden berekend.',
      'Temporada completa': 'Volledig seizoen',
      'Calendario 2026': 'Kalender 2026',
      'El calendario aparecerá después de sincronizar.':
          'De kalender verschijnt na synchronisatie.',
      'No se pudo cargar el calendario completo.':
          'De volledige kalender kon niet worden geladen.',
      'Fin de semana': 'Weekend',
      'Horarios del GP': 'Grand Prix-schema',
      'Estrategia': 'Strategie',
      'Tu juego': 'Jouw spel',
      'Desde el inicio de la liga': 'Sinds het begin van de competitie',
      'Fantasy de la app': 'App-fantasy',
      'CARRERA A CARRERA': 'RACE VOOR RACE',
      'PILOTOS': 'COUREURS',
      'CONSTRUCTORES': 'CONSTRUCTEURS',
      'PILOTOS ELEGIDOS': 'GESELECTEERDE COUREURS',
      'CONSTRUCTORES ELEGIDOS': 'GESELECTEERDE CONSTRUCTEURS',
      'Usar última disponible automáticamente':
          'Automatisch de nieuwste beschikbare gebruiken',
      'Modelo': 'Model',
      'Pesos de la predicción': 'Voorspellingsgewichten',
      'Restaurar calibrados': 'Gekalibreerde waarden herstellen',
      'Sin datos todavía. Sincroniza desde la pestaña Resumen.':
          'Nog geen gegevens. Synchroniseer vanuit Overzicht.',
      'Error calculando el ranking: {error}':
          'Fout bij het berekenen van de ranglijst: {error}',
      'POR QUÉ': 'WAAROM',
      'PUNTOS FANTASY ESPERADOS': 'VERWACHTE FANTASY-PUNTEN',
      'POR QUÉ (0–100 POR FACETA)': 'WAAROM (0–100 PER FACTOR)',
      'Manual o importado': 'Handmatig of geïmporteerd',
      'Mi equipo': 'Mijn team',
      'pts esperados este GP': 'verwachte punten voor deze Grand Prix',
      'GUARDAR MI EQUIPO': 'MIJN TEAM OPSLAAN',
      'Vaciar': 'Wissen',
      'Cuenta sincronizada': 'Gesynchroniseerd account',
      'Chips de la temporada': 'Seizoenschips',
      'Optimizador': 'Optimizer',
      'Planes de cambios': 'Transferplannen',
      'Equipo guardado': 'Team opgeslagen',
      'Introducir equipo manualmente': 'Team handmatig invoeren',
      'Guardar mi equipo': 'Mijn team opslaan',
      'Pilotos': 'Coureurs',
      'Constructores': 'Constructeurs',
      'Competición privada': 'Privécompetitie',
      'Liga': 'Competitie',
      'INICIAR SESIÓN': 'INLOGGEN',
      'ACTUALIZAR DATOS DE LIGA': 'COMPETITIEGEGEVENS BIJWERKEN',
      'Clasificación y evolución': 'Ranglijst en ontwikkeling',
      'No se pudo abrir la clasificación.':
          'De ranglijst kon niet worden geopend.',
      'Sin participantes disponibles. Actualiza la liga.':
          'Geen deelnemers beschikbaar. Werk de competitie bij.',
      'MEDALLERO · POSICIÓN POR CARRERA':
          'MEDAILLEKLASSEMENT · POSITIE PER RACE',
      'EQUIPO': 'TEAM',
      'EVOLUCIÓN DE POSICIONES': 'POSITIEONTWIKKELING',
      'Todo': 'Alles',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Racepunten verschijnen na het bijwerken van de competitie.',
      'PUNTOS ACUMULADOS': 'OPGETELDE PUNTEN',
      'Cuenta F1 Fantasy': 'F1 Fantasy-account',
      'Acceso seguro': 'Veilige toegang',
      'ABRIR WEB OFICIAL': 'OFFICIËLE WEBSITE OPENEN',
      'Iniciar sesión (navegador)': 'Inloggen (browser)',
      'CAPTURAR SESIÓN': 'SESSIE VASTLEGGEN',
      'Datos': 'Gegevens',
      'Sincronización': 'Synchronisatie',
      'Todavía no se ha sincronizado en esta sesión.':
          'Er is in deze sessie nog niets gesynchroniseerd.',
      'Última sincronización: {date}.': 'Laatste synchronisatie: {date}.',
      'SINCRONIZANDO…': 'SYNCHRONISEREN…',
      'SINCRONIZAR AHORA': 'NU SYNCHRONISEREN',
      'Restaurar pesos calibrados': 'Gekalibreerde gewichten herstellen',
      'Tu cuenta': 'Jouw account',
      'Gestionar sesión': 'Sessie beheren',
      'Privacidad': 'Privacy',
      'Estadísticas de uso': 'Gebruiksstatistieken',
      'Compartir estadísticas anónimas': 'Anonieme statistieken delen',
      'Activadas': 'Ingeschakeld',
      'Desactivadas': 'Uitgeschakeld',
      'Estadísticas pendientes eliminadas.':
          'Wachtende statistieken verwijderd.',
      'Borrar estadísticas pendientes': 'Wachtende statistieken verwijderen',
      'Tus datos': 'Jouw gegevens',
      'Borrado local': 'Lokaal verwijderen',
      '¿Borrar datos locales?': 'Lokale gegevens verwijderen?',
      'Cancelar': 'Annuleren',
      'Borrar': 'Verwijderen',
      'Sesión y datos locales eliminados.':
          'Sessie en lokale gegevens verwijderd.',
      'Borrar sesión y datos locales': 'Sessie en lokale gegevens verwijderen',
      'Legal': 'Juridisch',
      'Información': 'Informatie',
      'Acerca de Polewise': 'Over Polewise',
      'Versión': 'Versie',
      'Desarrollo': 'Ontwikkeling',
      'Soporte': 'Ondersteuning',
      'Transparencia': 'Transparantie',
      'Aplicación no oficial': 'Onofficiële applicatie',
      'Fuentes utilizadas': 'Gebruikte bronnen',
      'Responsable': 'Verantwoordelijke',
      'Datos de la cuenta de fantasy': 'Fantasy-accountgegevens',
      'Estadísticas de uso opcionales': 'Optionele gebruiksstatistieken',
      'Servicios externos': 'Externe diensten',
      'Control y eliminación': 'Beheer en verwijdering',
      'Seguridad y menores': 'Veiligheid en minderjarigen',
      'Reintentar': 'Opnieuw proberen',
      'Constructor': 'Constructeur',
      'victorias': 'overwinningen',
      'PUNTOS': 'PUNTEN',
      'pts esperados': 'verwachte punten',
      'Presupuesto 100 M\$': 'Budget 100 M\$',
      'Clasificacion {season}': 'Stand {season}',
      'Campeonato del mundo': 'Wereldkampioenschap',
      'Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.':
          'Officiële punten van coureurs en constructeurs. Veeg omlaag om te vernieuwen.',
      'No se pudo cargar la clasificacion general.':
          'De algemene stand kon niet worden geladen.',
      'Todavia no hay clasificacion disponible.':
          'Er is nog geen stand beschikbaar.',
      'Idioma': 'Taal',
      'Idioma de la aplicación': 'App-taal',
      'Elige el idioma de todos los textos de Polewise.':
          'Kies de taal voor alle tekst in Polewise.',
      'Elige temporada y Gran Premio para analizar.':
          'Kies een seizoen en Grand Prix om te analyseren.',
      'Sin calendario todavia. Desliza para sincronizar.':
          'Nog geen kalender. Veeg om te synchroniseren.',
      'No se pudo cargar el calendario guardado.':
          'De opgeslagen kalender kon niet worden geladen.',
      'Aun no hay datos suficientes para predecir.':
          'Er zijn nog niet genoeg gegevens om te voorspellen.',
      'Pick principal': 'Belangrijkste keuze',
      'Capitan x2 alternativo': 'Alternatieve x2-kapitein',
      'Mejor valor': 'Beste waarde',
      'Evitar por valor': 'Vermijden op waarde',
      'Marca top': 'Topconstructeur',
      'Fin de semana sprint': 'Sprintweekend',
      'GP ya disputado · modo analisis': 'Grand Prix voltooid · analysemode',
      'Ronda {round}': 'Ronde {round}',
      '¡EN MARCHA O FINALIZADO!': 'BEZIG OF AFGELOPEN!',
      'DÍAS': 'DAGEN',
      'HORAS': 'UREN',
      'MIN': 'MIN',
      'Construye el equipo ideal o analiza el que ya tienes.':
          'Bouw het ideale team of analyseer je huidige team.',
      'Equipo ideal': 'Ideaal team',
      'Equilibrado': 'Gebalanceerd',
      'No hay datos suficientes para optimizar. Sincroniza en Resumen.':
          'Niet genoeg gegevens om te optimaliseren. Synchroniseer vanuit Overzicht.',
      'Coste total ': 'Totale kosten ',
      ' · te sobran {remaining} M\$.': ' · {remaining} M\$ over.',
      'Aficionado': 'Fan',
      'Profi': 'Pro',
      'Clasificación': 'Kwalificatie',
      'Carrera': 'Race',
      'Sprint': 'Sprint',
      'VICTORIA': 'ZEGE',
      'PODIO': 'PODIUM',
      'TOP 10': 'TOP 10',
      'Pick': 'Keuze',
      'Capitán': 'Kapitein',
      'Valor': 'Waarde',
      'Riesgo DNF': 'DNF-risico',
      'USADO': 'GEBRUIKT',
      'DISP.': 'BESCHIKBAAR',
      'Equipo conservado': 'Team behouden',
      'Importando…': 'Importeren…',
      'Traer equipo del Fantasy (requiere sesión)':
          'Team uit Fantasy importeren (inloggen vereist)',
      'Toca para elegir': 'Tik om te kiezen',
      'Boost ×2 recomendado': 'Aanbevolen x2-boost',
      'Equipo': 'Team',
      'Alineación simulada actual': 'Huidige gesimuleerde opstelling',
      'Libres 1': 'Vrije training 1',
      'Libres 2': 'Vrije training 2',
      'Libres 3': 'Vrije training 3',
      'Clasificación sprint': 'Sprintkwalificatie',
    },
  };

  /// Copy added after the initial catalog. Keeping it separate makes the
  /// fallback explicit and lets the coverage check ensure no screen returns
  /// Spanish copy when another language is selected.
  static const Map<String, Map<String, String>> _supplementalCatalog = {
    'en': {
      '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.':
          '5 drivers + 2 constructors maximizing expected points using your weights. Recalculated when you change the Grand Prix or sliders.',
      'La nota combina historial, forma y rendimiento del equipo.':
          'The score combines history, form, and team performance.',
      'PTS ESP.': 'EXP. PTS.',
      'pts sin chips': 'pts without chips',
      'Inicia sesión en la web oficial. Polewise no recibe ni guarda tu contraseña.':
          'Sign in on the official website. Polewise never receives or stores your password.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Los porcentajes muestran la probabilidad estimada de acabar en cada posición.':
          'The large figure is the expected Fantasy score for the weekend. Percentages show the estimated probability of finishing in each position.',
    },
    'de': {
      '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.':
          '{races} Kalenderrennen · {results} neue Ergebnisse · {prices} Preise.',
      '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).':
          '2 kostenlose Wechsel pro Runde; der 3. kostet -10 Punkte (bereits vom Nettogewinn abgezogen).',
      '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.':
          '5 Fahrer + 2 Konstrukteure maximieren mit deinen Gewichtungen die erwarteten Punkte. Bei Änderungen am Grand Prix oder an Reglern wird neu berechnet.',
      '¡EN MARCHA O FINALIZADO!': 'LÄUFT ODER BEENDET!',
      '¿Borrar datos locales?': 'Lokale Daten löschen?',
      'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.':
          'Melde dich mit deinem Konto an, um deine Ligen, Positionen und Abstände zur Spitze zu sehen.',
      'Asistente de análisis y estrategia para fantasy de automovilismo.':
          'Analyse- und Strategieassistent für Motorsport-Fantasy.',
      'Ayuda a mejorar Polewise': 'Hilf, Polewise zu verbessern',
      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Hilft uns zu verstehen, welche Bereiche nützlich sind. Mit Zustimmung sendet Polewise allgemeine Ereignisse an seinen Dienst und Google Analytics, niemals dein Konto, deine Sitzung, dein Team, deine Liga oder Inhalte.',
      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.':
          'Kalender und Ergebnisse: Jolpica-F1. Sitzungsdaten: OpenF1. Die optionale Verbindung mit einem Fantasy-Konto erfolgt über die Website des jeweiligen Dienstes.',
      'Construye el equipo ideal o analiza el que ya tienes.':
          'Stelle das ideale Team zusammen oder analysiere dein bestehendes Team.',
      'Coste total ': 'Gesamtkosten ',
      ' · te sobran {remaining} M\$.': ' · {remaining} Mio. \$ übrig.',
      'Elige el idioma de todos los textos de Polewise.':
          'Wähle die Sprache für alle Texte in Polewise.',
      'Elige temporada y Gran Premio para analizar.':
          'Wähle Saison und Grand Prix für die Analyse.',
      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.':
          'Löscht Sitzung, Team und importierte Ligen von diesem Gerät. Dein Konto beim offiziellen Dienst wird nicht gelöscht.',
      'EQUIPO': 'TEAM',
      'Estadísticas pendientes eliminadas.':
          'Ausstehende Statistiken gelöscht.',
      'EVOLUCIÓN DE POSICIONES': 'POSITIONSENTWICKLUNG',
      'Importando…': 'Importiere…',
      'Inicia sesión en la web oficial. Polewise no recibe ni guarda tu contraseña.':
          'Melde dich auf der offiziellen Website an. Polewise erhält oder speichert dein Passwort nie.',
      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.':
          'Melde dich an, um dein echtes Team zu importieren und deine Ligen anzusehen. Die öffentliche Analyse und der manuelle Editor bleiben verfügbar, falls der offizielle Dienst nicht antwortet.',
      'Introducir mi equipo': 'Mein Team eingeben',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Los porcentajes muestran la probabilidad estimada de acabar en cada posición.':
          'Die große Zahl sind die erwarteten Fantasy-Punkte des Wochenendes. Die Prozentwerte zeigen die geschätzte Wahrscheinlichkeit für jede Platzierung.',
      'La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.':
          'Die Strategie behält das Team oder nutzt bis zu zwei kostenlose Wechsel. Das Budget entwickelt sich mit den echten Werten von Fahrern und Konstrukteuren bei jedem Grand Prix. Es werden die vollständigen offiziellen Punkte verwendet; Chips werden nicht simuliert.',
      'La nota combina historial, forma y rendimiento del equipo.':
          'Die Bewertung kombiniert Historie, Form und Teamleistung.',
      'Las predicciones son estimaciones estadísticas y no garantizan resultados.':
          'Vorhersagen sind statistische Schätzungen und garantieren keine Ergebnisse.',
      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.':
          'Die Regler befinden sich im Tab Analyse. Hier kannst du die kalibrierten Modellwerte wiederherstellen.',
      'MEDALLERO · POSICIÓN POR CARRERA':
          'MEDAILLENSPIEGEL · POSITION PRO RENNEN',
      'No se pudo cargar el calendario guardado.':
          'Der gespeicherte Kalender konnte nicht geladen werden.',
      'No, gracias': 'Nein, danke',
      'Permitir': 'Erlauben',
      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.':
          'Polewise ist eine inoffizielle Anwendung. Erfahre, wie Daten verarbeitet werden und wer die App entwickelt.',
      'POR QUÉ (0–100 POR FACETA)': 'WARUM (0–100 PRO FAKTOR)',
      'PTS ESP.': 'ERW. PKT.',
      'pts sin chips': 'Punkte ohne Chips',
      'Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.':
          'Du kannst dich jederzeit abmelden und alle importierten Daten in den Einstellungen löschen.',
      'Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.':
          'Offizielle Punkte von Fahrern und Konstrukteuren. Zum Aktualisieren nach unten ziehen.',
      'Sesión y datos locales eliminados.':
          'Sitzung und lokale Daten gelöscht.',
      'Sin calendario todavia. Desliza para sincronizar.':
          'Noch kein Kalender. Zum Synchronisieren wischen.',
      'Sin datos todavía. Sincroniza desde la pestaña Resumen.':
          'Noch keine Daten. Synchronisiere über den Tab Übersicht.',
      'Todavía no se ha sincronizado en esta sesión.':
          'In dieser Sitzung wurde noch nicht synchronisiert.',
      'Traer equipo del Fantasy (requiere sesión)':
          'Team aus Fantasy importieren (Anmeldung erforderlich)',
      'Usar última disponible automáticamente':
          'Automatisch die neueste verfügbare verwenden',
      'Ver privacidad': 'Datenschutz ansehen',
    },
    'it': {
      '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.':
          '{races} gare in calendario · {results} nuovi risultati · {prices} prezzi.',
      '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).':
          '2 cambi gratuiti per turno; il 3° costa -10 punti (già detratti dal guadagno netto).',
      '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.':
          '5 piloti + 2 costruttori massimizzano i punti previsti con i tuoi pesi. Il calcolo si aggiorna cambiando Gran Premio o cursori.',
      '¡EN MARCHA O FINALIZADO!': 'IN CORSO O TERMINATO!',
      '¿Borrar datos locales?': 'Eliminare i dati locali?',
      'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.':
          'Accedi con il tuo account per vedere leghe, posizioni e distacco dal leader.',
      'Asistente de análisis y estrategia para fantasy de automovilismo.':
          'Assistente di analisi e strategia per fantasy motoristici.',
      'Ayuda a mejorar Polewise': 'Aiuta a migliorare Polewise',
      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Ci aiuta a capire quali schermate sono utili. Con il consenso, Polewise invia eventi generali al proprio servizio e a Google Analytics, mai account, sessione, squadra, lega o contenuti.',
      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.':
          'Calendario e risultati: Jolpica-F1. Dati delle sessioni: OpenF1. Il collegamento facoltativo a un account fantasy avviene tramite il sito del servizio corrispondente.',
      'Construye el equipo ideal o analiza el que ya tienes.':
          'Crea la squadra ideale o analizza quella che hai già.',
      'Coste total ': 'Costo totale ',
      ' · te sobran {remaining} M\$.': ' · ti restano {remaining} M\$.',
      'Elige el idioma de todos los textos de Polewise.':
          'Scegli la lingua di tutti i testi di Polewise.',
      'Elige temporada y Gran Premio para analizar.':
          'Scegli stagione e Gran Premio da analizzare.',
      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.':
          'Elimina da questo dispositivo sessione, squadra e leghe importate. Non elimina il tuo account dal servizio ufficiale.',
      'EQUIPO': 'SQUADRA',
      'Estadísticas pendientes eliminadas.': 'Statistiche in attesa eliminate.',
      'EVOLUCIÓN DE POSICIONES': 'EVOLUZIONE DELLE POSIZIONI',
      'Importando…': 'Importazione…',
      'Inicia sesión en la web oficial. Polewise no recibe ni guarda tu contraseña.':
          'Accedi sul sito ufficiale. Polewise non riceve né salva mai la tua password.',
      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.':
          'Accedi per importare la tua squadra reale e consultare le tue leghe. L’analisi pubblica e l’editor manuale restano disponibili se il servizio ufficiale non risponde.',
      'Introducir mi equipo': 'Inserisci la mia squadra',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Los porcentajes muestran la probabilidad estimada de acabar en cada posición.':
          'Il numero grande indica i punti Fantasy previsti per il weekend. Le percentuali mostrano la probabilità stimata di finire in ogni posizione.',
      'La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.':
          'La strategia conserva la squadra o usa fino a due cambi gratuiti. Il budget evolve con il valore reale di piloti e costruttori a ogni Gran Premio. I punti sono quelli ufficiali completi; i chip non vengono simulati.',
      'La nota combina historial, forma y rendimiento del equipo.':
          'Il punteggio combina storico, forma e rendimento della squadra.',
      'Las predicciones son estimaciones estadísticas y no garantizan resultados.':
          'Le previsioni sono stime statistiche e non garantiscono risultati.',
      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.':
          'I cursori sono nella scheda Analisi. Da qui puoi ripristinare i valori calibrati del modello.',
      'MEDALLERO · POSICIÓN POR CARRERA': 'MEDAGLIERE · POSIZIONE PER GARA',
      'No se pudo cargar el calendario guardado.':
          'Impossibile caricare il calendario salvato.',
      'No, gracias': 'No, grazie',
      'Permitir': 'Consenti',
      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.':
          'Polewise è un’applicazione non ufficiale. Scopri come vengono trattati i dati e chi sviluppa l’app.',
      'POR QUÉ (0–100 POR FACETA)': 'PERCHÉ (0–100 PER FATTORE)',
      'PTS ESP.': 'PUNTI PREV.',
      'pts sin chips': 'punti senza chip',
      'Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.':
          'Puoi chiudere la sessione ed eliminare tutti i dati importati dalle Impostazioni in qualsiasi momento.',
      'Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.':
          'Punti ufficiali di piloti e costruttori. Scorri verso il basso per aggiornare.',
      'Sesión y datos locales eliminados.': 'Sessione e dati locali eliminati.',
      'Sin calendario todavia. Desliza para sincronizar.':
          'Ancora nessun calendario. Scorri per sincronizzare.',
      'Sin datos todavía. Sincroniza desde la pestaña Resumen.':
          'Ancora nessun dato. Sincronizza dalla scheda Riepilogo.',
      'Todavía no se ha sincronizado en esta sesión.':
          'In questa sessione non è stato ancora sincronizzato nulla.',
      'Traer equipo del Fantasy (requiere sesión)':
          'Importa squadra da Fantasy (accesso richiesto)',
      'Usar última disponible automáticamente':
          'Usa automaticamente l’ultima disponibile',
      'Ver privacidad': 'Visualizza privacy',
    },
    'fr': {
      '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.':
          '{races} courses au calendrier · {results} nouveaux résultats · {prices} prix.',
      '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).':
          '2 transferts gratuits par manche ; le 3e coûte -10 points (déjà déduits du gain net).',
      '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.':
          '5 pilotes + 2 constructeurs maximisent les points attendus avec vos pondérations. Le calcul est mis à jour en changeant de Grand Prix ou les curseurs.',
      '¡EN MARCHA O FINALIZADO!': 'EN COURS OU TERMINÉ !',
      '¿Borrar datos locales?': 'Supprimer les données locales ?',
      'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.':
          'Connectez-vous avec votre compte pour voir vos ligues, positions et écarts avec le leader.',
      'Asistente de análisis y estrategia para fantasy de automovilismo.':
          'Assistant d’analyse et de stratégie pour fantasy de sport automobile.',
      'Ayuda a mejorar Polewise': 'Aidez à améliorer Polewise',
      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Cela nous aide à savoir quelles pages sont utiles. Avec votre accord, Polewise envoie des événements généraux à son service et à Google Analytics, jamais votre compte, session, équipe, ligue ou contenu.',
      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.':
          'Calendrier et résultats : Jolpica-F1. Données des sessions : OpenF1. La connexion facultative à un compte fantasy se fait via le site du service concerné.',
      'Construye el equipo ideal o analiza el que ya tienes.':
          'Construisez l’équipe idéale ou analysez celle que vous avez déjà.',
      'Coste total ': 'Coût total ',
      ' · te sobran {remaining} M\$.': ' · il vous reste {remaining} M\$.',
      'Elige el idioma de todos los textos de Polewise.':
          'Choisissez la langue de tous les textes de Polewise.',
      'Elige temporada y Gran Premio para analizar.':
          'Choisissez la saison et le Grand Prix à analyser.',
      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.':
          'Supprime de cet appareil la session, l’équipe et les ligues importées. Cela ne supprime pas votre compte du service officiel.',
      'EQUIPO': 'ÉQUIPE',
      'Estadísticas pendientes eliminadas.':
          'Statistiques en attente supprimées.',
      'EVOLUCIÓN DE POSICIONES': 'ÉVOLUTION DES POSITIONS',
      'Importando…': 'Importation…',
      'Inicia sesión en la web oficial. Polewise no recibe ni guarda tu contraseña.':
          'Connectez-vous sur le site officiel. Polewise ne reçoit ni ne conserve jamais votre mot de passe.',
      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.':
          'Connectez-vous pour importer votre équipe réelle et consulter vos ligues. L’analyse publique et l’éditeur manuel restent disponibles si le service officiel ne répond pas.',
      'Introducir mi equipo': 'Saisir mon équipe',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Los porcentajes muestran la probabilidad estimada de acabar en cada posición.':
          'Le grand chiffre correspond aux points Fantasy attendus du week-end. Les pourcentages montrent la probabilité estimée de finir à chaque position.',
      'La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.':
          'La stratégie conserve l’équipe ou utilise jusqu’à deux transferts gratuits. Le budget évolue avec la valeur réelle des pilotes et constructeurs à chaque Grand Prix. Les points sont les points officiels complets ; les puces ne sont pas simulées.',
      'La nota combina historial, forma y rendimiento del equipo.':
          'La note combine historique, forme et performance de l’équipe.',
      'Las predicciones son estimaciones estadísticas y no garantizan resultados.':
          'Les prédictions sont des estimations statistiques et ne garantissent pas les résultats.',
      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.':
          'Les curseurs se trouvent dans l’onglet Analyse. Vous pouvez y restaurer les valeurs calibrées du modèle.',
      'MEDALLERO · POSICIÓN POR CARRERA':
          'TABLEAU DES MÉDAILLES · POSITION PAR COURSE',
      'No se pudo cargar el calendario guardado.':
          'Impossible de charger le calendrier enregistré.',
      'No, gracias': 'Non, merci',
      'Permitir': 'Autoriser',
      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.':
          'Polewise est une application non officielle. Découvrez comment les données sont traitées et qui développe l’application.',
      'POR QUÉ (0–100 POR FACETA)': 'POURQUOI (0–100 PAR FACTEUR)',
      'PTS ESP.': 'PTS ATT.',
      'pts sin chips': 'pts sans puces',
      'Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.':
          'Vous pouvez fermer la session et supprimer toutes les données importées depuis les Réglages à tout moment.',
      'Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.':
          'Points officiels des pilotes et constructeurs. Faites glisser vers le bas pour actualiser.',
      'Sesión y datos locales eliminados.':
          'Session et données locales supprimées.',
      'Sin calendario todavia. Desliza para sincronizar.':
          'Pas encore de calendrier. Faites glisser pour synchroniser.',
      'Sin datos todavía. Sincroniza desde la pestaña Resumen.':
          'Pas encore de données. Synchronisez depuis l’onglet Résumé.',
      'Todavía no se ha sincronizado en esta sesión.':
          'Aucune synchronisation n’a encore été effectuée dans cette session.',
      'Traer equipo del Fantasy (requiere sesión)':
          'Importer l’équipe Fantasy (connexion requise)',
      'Usar última disponible automáticamente':
          'Utiliser automatiquement la dernière disponible',
      'Ver privacidad': 'Voir la confidentialité',
    },
    'pt': {
      '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.':
          '{races} corridas do calendário · {results} novos resultados · {prices} preços.',
      '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).':
          '2 transferências grátis por rodada; a 3ª custa -10 pontos (já descontados do ganho líquido).',
      '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.':
          '5 pilotos + 2 construtores maximizam os pontos esperados com seus pesos. O cálculo é refeito ao mudar o Grande Prêmio ou os controles.',
      'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.':
          'Entre com sua conta para ver suas ligas, posições e diferenças para o líder.',
      'Asistente de análisis y estrategia para fantasy de automovilismo.':
          'Assistente de análise e estratégia para fantasy de automobilismo.',
      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Ajuda a entender quais telas são úteis. Com permissão, o Polewise envia eventos gerais ao próprio serviço e ao Google Analytics, nunca sua conta, sessão, equipe, liga ou conteúdo.',
      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.':
          'Calendário e resultados: Jolpica-F1. Dados das sessões: OpenF1. A conexão opcional com uma conta de fantasy é feita pelo site do serviço correspondente.',
      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.':
          'Remove deste dispositivo a sessão, a equipe e as ligas importadas. Não remove sua conta do serviço oficial.',
      'Inicia sesión en la web oficial. Polewise no recibe ni guarda tu contraseña.':
          'Entre no site oficial. O Polewise nunca recebe nem guarda sua senha.',
      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.':
          'Entre para importar sua equipe real e consultar suas ligas. A análise pública e o editor manual continuam disponíveis se o serviço oficial não responder.',
      'Introducir mi equipo': 'Inserir minha equipe',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Los porcentajes muestran la probabilidad estimada de acabar en cada posición.':
          'O número grande mostra os pontos Fantasy esperados para o fim de semana. As porcentagens mostram a probabilidade estimada de terminar em cada posição.',
      'La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.':
          'A estratégia mantém a equipe ou usa até duas transferências grátis. O orçamento evolui com o valor real de pilotos e construtores em cada Grande Prêmio. Os pontos são os oficiais completos; os chips não são simulados.',
      'La nota combina historial, forma y rendimiento del equipo.':
          'A nota combina histórico, forma e desempenho da equipe.',
      'Las predicciones son estimaciones estadísticas y no garantizan resultados.':
          'As previsões são estimativas estatísticas e não garantem resultados.',
      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.':
          'Os controles estão na aba Análise. Daqui você pode restaurar os valores calibrados do modelo.',
      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.':
          'Polewise é um aplicativo não oficial. Veja como os dados são tratados e quem desenvolve o aplicativo.',
      'PTS ESP.': 'PTS ESP.',
      'pts sin chips': 'pts sem chips',
      'Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.':
          'Você pode encerrar a sessão e excluir todos os dados importados nas Configurações a qualquer momento.',
      'Tu liga': 'Sua liga',
    },
    'nl': {
      '{races} carreras de calendario · {results} resultados nuevos · {prices} precios.':
          '{races} kalenderraces · {results} nieuwe uitslagen · {prices} prijzen.',
      '2 cambios gratis por jornada; el 3º cuesta -10 pts (ya descontados en la ganancia neta).':
          '2 gratis transfers per ronde; de 3e kost -10 punten (al afgetrokken van de nettowinst).',
      '5 pilotos + 2 constructores maximizando los puntos esperados con tus pesos. Se recalcula al cambiar GP o sliders.':
          '5 coureurs + 2 constructeurs maximaliseren de verwachte punten met jouw wegingen. De berekening wordt opnieuw uitgevoerd bij een andere Grand Prix of schuifregelaar.',
      'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.':
          'Log in met je account om je competities, posities en achterstand op de leider te zien.',
      'Asistente de análisis y estrategia para fantasy de automovilismo.':
          'Analyse- en strategieassistent voor autosportfantasy.',
      'Ayuda a saber qué pantallas son útiles. Con permiso, Polewise envía eventos generales a su servicio y a Google Analytics; nunca tu cuenta, sesión, equipo, liga ni contenido.':
          'Helpt te begrijpen welke schermen nuttig zijn. Met toestemming stuurt Polewise algemene gebeurtenissen naar de eigen dienst en Google Analytics, nooit je account, sessie, team, competitie of inhoud.',
      'Calendario y resultados: Jolpica-F1. Datos de sesiones: OpenF1. La conexión opcional con una cuenta de fantasy se realiza mediante la web del servicio correspondiente.':
          'Kalender en uitslagen: Jolpica-F1. Sessiegegevens: OpenF1. De optionele koppeling met een fantasyaccount gebeurt via de website van de betreffende dienst.',
      'Elimina de este dispositivo la sesión, el equipo y las ligas importadas. No elimina tu cuenta del servicio oficial.':
          'Verwijdert de sessie, het team en geïmporteerde competities van dit apparaat. Je account bij de officiële dienst wordt niet verwijderd.',
      'Inicia sesión en la web oficial. Polewise no recibe ni guarda tu contraseña.':
          'Log in op de officiële website. Polewise ontvangt of bewaart je wachtwoord nooit.',
      'Inicia sesión para importar tu equipo real y consultar tus ligas. El análisis público y el editor manual siguen disponibles si el servicio oficial no responde.':
          'Log in om je echte team te importeren en je competities te bekijken. De openbare analyse en handmatige editor blijven beschikbaar als de officiële dienst niet reageert.',
      'Introducir mi equipo': 'Mijn team invoeren',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Los porcentajes muestran la probabilidad estimada de acabar en cada posición.':
          'Het grote getal is de verwachte Fantasy-score van het weekend. De percentages tonen de geschatte kans om op elke positie te eindigen.',
      'La estrategia conserva el equipo o usa hasta dos cambios gratuitos. El presupuesto evoluciona con el valor real de pilotos y constructores de cada GP. Los puntos son los oficiales completos; los chips no se simulan.':
          'De strategie behoudt het team of gebruikt maximaal twee gratis transfers. Het budget ontwikkelt zich met de werkelijke waarde van coureurs en constructeurs per Grand Prix. De punten zijn de volledige officiële punten; chips worden niet gesimuleerd.',
      'La nota combina historial, forma y rendimiento del equipo.':
          'De score combineert historie, vorm en teamprestatie.',
      'Las predicciones son estimaciones estadísticas y no garantizan resultados.':
          'Voorspellingen zijn statistische schattingen en garanderen geen resultaten.',
      'Los sliders están en la pestaña Análisis. Desde aquí puedes volver a los valores calibrados del modelo.':
          'De schuifregelaars staan op het tabblad Analyse. Hier kun je de gekalibreerde modelwaarden herstellen.',
      'Polewise es una aplicación no oficial. Consulta cómo se tratan los datos y quién desarrolla la app.':
          'Polewise is een niet-officiële toepassing. Lees hoe gegevens worden verwerkt en wie de app ontwikkelt.',
      'PTS ESP.': 'VERW. PTS.',
      'pts sin chips': 'pts zonder chips',
      'Puedes cerrar la sesión y borrar todos los datos importados desde Ajustes en cualquier momento.':
          'Je kunt je altijd afmelden en alle geïmporteerde gegevens vanuit Instellingen verwijderen.',
      'Tu liga': 'Jouw competitie',
    },
  };

  static const Map<String, Map<String, String>> _longCopyCatalog = {
    'en': {
      'Inicia sesión en la web oficial. Polewise no recibe ni almacena tu contraseña; únicamente copia de forma cifrada la sesión, tu equipo y tus ligas en este dispositivo.':
          'Sign in on the official website. Polewise never receives or stores your password; it only keeps an encrypted copy of your session, team, and leagues on this device.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Toca una fila para ver clasificación, carrera y Sprint. pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).':
          'The large figure is the expected Fantasy score for the weekend. Tap a row to view qualifying, race, and Sprint. pts/M = expected points per million (the key metric with a 100 M\$ cap).',
    },
    'de': {
      'Inicia sesión en la web oficial. Polewise no recibe ni almacena tu contraseña; únicamente copia de forma cifrada la sesión, tu equipo y tus ligas en este dispositivo.':
          'Melde dich auf der offiziellen Website an. Polewise erhält oder speichert dein Passwort nie; es speichert nur eine verschlüsselte Kopie deiner Sitzung, deines Teams und deiner Ligen auf diesem Gerät.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Toca una fila para ver clasificación, carrera y Sprint. pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).':
          'Die große Zahl sind die erwarteten Fantasy-Punkte des Wochenendes. Tippe auf eine Zeile für Qualifying, Rennen und Sprint. Pkt./M = erwartete Punkte pro Million (die wichtigste Kennzahl bei einem Limit von 100 Mio. \$).',
    },
    'it': {
      'Inicia sesión en la web oficial. Polewise no recibe ni almacena tu contraseña; únicamente copia de forma cifrada la sesión, tu equipo y tus ligas en este dispositivo.':
          'Accedi sul sito ufficiale. Polewise non riceve né conserva la tua password; salva solo una copia cifrata della sessione, della squadra e delle leghe su questo dispositivo.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Toca una fila para ver clasificación, carrera y Sprint. pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).':
          'Il numero grande indica i punti Fantasy previsti per il weekend. Tocca una riga per vedere qualifiche, gara e Sprint. punti/M = punti previsti per milione (il dato chiave con un limite di 100 M\$).',
    },
    'fr': {
      'Inicia sesión en la web oficial. Polewise no recibe ni almacena tu contraseña; únicamente copia de forma cifrada la sesión, tu equipo y tus ligas en este dispositivo.':
          'Connectez-vous sur le site officiel. Polewise ne reçoit ni ne stocke votre mot de passe ; il conserve uniquement une copie chiffrée de votre session, équipe et ligues sur cet appareil.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Toca una fila para ver clasificación, carrera y Sprint. pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).':
          'Le grand chiffre correspond aux points Fantasy attendus du week-end. Touchez une ligne pour voir qualifications, course et Sprint. pts/M = points attendus par million (la donnée clé avec un plafond de 100 M\$).',
    },
    'pt': {
      'Inicia sesión en la web oficial. Polewise no recibe ni almacena tu contraseña; únicamente copia de forma cifrada la sesión, tu equipo y tus ligas en este dispositivo.':
          'Entre no site oficial. O Polewise não recebe nem armazena sua senha; ele mantém apenas uma cópia criptografada da sua sessão, equipe e ligas neste dispositivo.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Toca una fila para ver clasificación, carrera y Sprint. pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).':
          'O número grande mostra os pontos Fantasy esperados para o fim de semana. Toque em uma linha para ver classificação, corrida e Sprint. pts/M = pontos esperados por milhão (o dado principal com limite de 100 M\$).',
    },
    'nl': {
      'Inicia sesión en la web oficial. Polewise no recibe ni almacena tu contraseña; únicamente copia de forma cifrada la sesión, tu equipo y tus ligas en este dispositivo.':
          'Log in op de officiële website. Polewise ontvangt of bewaart je wachtwoord niet; alleen een versleutelde kopie van je sessie, team en competities wordt op dit apparaat bewaard.',
      'La cifra grande son los puntos Fantasy esperados del fin de semana. Toca una fila para ver clasificación, carrera y Sprint. pts/M = puntos esperados por millón (el dato clave con 100 M\$ de tope).':
          'Het grote getal is de verwachte Fantasy-score van het weekend. Tik op een rij voor kwalificatie, race en Sprint. pts/M = verwachte punten per miljoen (de belangrijkste waarde bij een limiet van 100 M\$).',
    },
  };

  static const Map<String, Map<String, String>> _directLabelsCatalog = {
    'en': {
      'Error: {error}': 'Error: {error}',
      'CHIPS DE LA TEMPORADA': 'SEASON CHIPS',
      'PUNTOS ACUMULADOS': 'TOTAL POINTS',
      'Equipo guardado': 'Team saved',
      'Piloto {number}': 'Driver {number}',
      'Constructor {number}': 'Constructor {number}',
      'Introduce y guarda un equipo completo para usar su presupuesto.':
          'Enter and save a complete team to use its budget.',
      'Valor del equipo más dinero libre: {budget} M\$':
          'Team value plus available cash: {budget} M\$',
    },
    'de': {
      'Error: {error}': 'Fehler: {error}',
      'CHIPS DE LA TEMPORADA': 'SAISON-CHIPS',
      'PUNTOS ACUMULADOS': 'GESAMTPUNKTE',
      'Equipo guardado': 'Team gespeichert',
      'Piloto {number}': 'Fahrer {number}',
      'Constructor {number}': 'Konstrukteur {number}',
      'Introduce y guarda un equipo completo para usar su presupuesto.':
          'Gib ein vollständiges Team ein und speichere es, um sein Budget zu verwenden.',
      'Valor del equipo más dinero libre: {budget} M\$':
          'Teamwert plus verfügbares Guthaben: {budget} M\$',
    },
    'it': {
      'Error: {error}': 'Errore: {error}',
      'CHIPS DE LA TEMPORADA': 'CHIP DELLA STAGIONE',
      'PUNTOS ACUMULADOS': 'PUNTI TOTALI',
      'Equipo guardado': 'Squadra salvata',
      'Piloto {number}': 'Pilota {number}',
      'Constructor {number}': 'Costruttore {number}',
      'Introduce y guarda un equipo completo para usar su presupuesto.':
          'Inserisci e salva una squadra completa per usarne il budget.',
      'Valor del equipo más dinero libre: {budget} M\$':
          'Valore della squadra più denaro disponibile: {budget} M\$',
    },
    'fr': {
      'Error: {error}': 'Erreur : {error}',
      'CHIPS DE LA TEMPORADA': 'PUCES DE LA SAISON',
      'PUNTOS ACUMULADOS': 'POINTS CUMULÉS',
      'Equipo guardado': 'Équipe enregistrée',
      'Piloto {number}': 'Pilote {number}',
      'Constructor {number}': 'Constructeur {number}',
      'Introduce y guarda un equipo completo para usar su presupuesto.':
          'Saisissez et enregistrez une équipe complète pour utiliser son budget.',
      'Valor del equipo más dinero libre: {budget} M\$':
          'Valeur de l’équipe plus argent disponible : {budget} M\$',
    },
    'pt': {
      'Error: {error}': 'Erro: {error}',
      'CHIPS DE LA TEMPORADA': 'CHIPS DA TEMPORADA',
      'PUNTOS ACUMULADOS': 'PONTOS ACUMULADOS',
      'Equipo guardado': 'Equipe salva',
      'Piloto {number}': 'Piloto {number}',
      'Constructor {number}': 'Construtor {number}',
      'Introduce y guarda un equipo completo para usar su presupuesto.':
          'Insira e salve uma equipe completa para usar o orçamento dela.',
      'Valor del equipo más dinero libre: {budget} M\$':
          'Valor da equipe mais saldo disponível: {budget} M\$',
    },
    'nl': {
      'Error: {error}': 'Fout: {error}',
      'CHIPS DE LA TEMPORADA': 'SEIZOENSCHIPS',
      'PUNTOS ACUMULADOS': 'TOTALE PUNTEN',
      'Equipo guardado': 'Team opgeslagen',
      'Piloto {number}': 'Coureur {number}',
      'Constructor {number}': 'Constructeur {number}',
      'Introduce y guarda un equipo completo para usar su presupuesto.':
          'Voer een volledig team in en sla het op om het budget te gebruiken.',
      'Valor del equipo más dinero libre: {budget} M\$':
          'Teamwaarde plus beschikbaar geld: {budget} M\$',
    },
  };

  static const Map<String, Map<String, String>> _statusCatalog = {
    'en': {
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.':
          'Sign in with your account. The app will detect the session automatically.',
      'Sesión detectada. Descargando equipo y ligas…':
          'Session detected. Downloading team and leagues…',
      'Comprobando la sesión con la web oficial. Si acabas de entrar, espera unos segundos y vuelve a pulsar "Capturar sesión".':
          'Checking the session with the official website. If you just signed in, wait a few seconds and press “Capture session” again.',
      'La sesión todavía no está lista. Esperando a la web oficial…':
          'The session is not ready yet. Waiting for the official website…',
      'Equipo y ligas sincronizados correctamente.':
          'Team and leagues synchronized successfully.',
    },
    'de': {
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.':
          'Melde dich mit deinem Konto an. Die App erkennt die Sitzung automatisch.',
      'Sesión detectada. Descargando equipo y ligas…':
          'Sitzung erkannt. Team und Ligen werden heruntergeladen…',
      'Comprobando la sesión con la web oficial. Si acabas de entrar, espera unos segundos y vuelve a pulsar "Capturar sesión".':
          'Sitzung wird auf der offiziellen Website geprüft. Wenn du dich gerade angemeldet hast, warte einige Sekunden und tippe erneut auf „Sitzung erfassen“.',
      'La sesión todavía no está lista. Esperando a la web oficial…':
          'Die Sitzung ist noch nicht bereit. Warte auf die offizielle Website…',
      'Equipo y ligas sincronizados correctamente.':
          'Team und Ligen erfolgreich synchronisiert.',
    },
    'it': {
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.':
          'Accedi con il tuo account. L’app rileverà automaticamente la sessione.',
      'Sesión detectada. Descargando equipo y ligas…':
          'Sessione rilevata. Download di squadra e leghe…',
      'Comprobando la sesión con la web oficial. Si acabas de entrar, espera unos segundos y vuelve a pulsar "Capturar sesión".':
          'Controllo della sessione sul sito ufficiale. Se hai appena effettuato l’accesso, attendi alcuni secondi e premi di nuovo “Cattura sessione”.',
      'La sesión todavía no está lista. Esperando a la web oficial…':
          'La sessione non è ancora pronta. In attesa del sito ufficiale…',
      'Equipo y ligas sincronizados correctamente.':
          'Squadra e leghe sincronizzate correttamente.',
    },
    'fr': {
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.':
          'Connectez-vous avec votre compte. L’application détectera la session automatiquement.',
      'Sesión detectada. Descargando equipo y ligas…':
          'Session détectée. Téléchargement de l’équipe et des ligues…',
      'Comprobando la sesión con la web oficial. Si acabas de entrar, espera unos segundos y vuelve a pulsar "Capturar sesión".':
          'Vérification de la session avec le site officiel. Si vous venez de vous connecter, attendez quelques secondes puis appuyez à nouveau sur « Capturer la session ».',
      'La sesión todavía no está lista. Esperando a la web oficial…':
          'La session n’est pas encore prête. En attente du site officiel…',
      'Equipo y ligas sincronizados correctamente.':
          'Équipe et ligues synchronisées correctement.',
    },
    'pt': {
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.':
          'Entre com sua conta. O aplicativo detectará a sessão automaticamente.',
      'Sesión detectada. Descargando equipo y ligas…':
          'Sessão detectada. Baixando equipe e ligas…',
      'Comprobando la sesión con la web oficial. Si acabas de entrar, espera unos segundos y vuelve a pulsar "Capturar sesión".':
          'Verificando a sessão no site oficial. Se você acabou de entrar, espere alguns segundos e toque novamente em “Capturar sessão”.',
      'La sesión todavía no está lista. Esperando a la web oficial…':
          'A sessão ainda não está pronta. Aguardando o site oficial…',
      'Equipo y ligas sincronizados correctamente.':
          'Equipe e ligas sincronizadas corretamente.',
    },
    'nl': {
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.':
          'Log in met je account. De app detecteert de sessie automatisch.',
      'Sesión detectada. Descargando equipo y ligas…':
          'Sessie gedetecteerd. Team en competities worden gedownload…',
      'Comprobando la sesión con la web oficial. Si acabas de entrar, espera unos segundos y vuelve a pulsar "Capturar sesión".':
          'De sessie wordt gecontroleerd op de officiële website. Heb je net ingelogd, wacht dan enkele seconden en druk opnieuw op “Sessie vastleggen”.',
      'La sesión todavía no está lista. Esperando a la web oficial…':
          'De sessie is nog niet klaar. Wachten op de officiële website…',
      'Equipo y ligas sincronizados correctamente.':
          'Team en competities zijn succesvol gesynchroniseerd.',
    },
  };

  static const Map<String, Map<String, String>> _screenStatusCatalog = {
    'en': {
      'El calendario aparecerá después de sincronizar.':
          'The calendar will appear after synchronization.',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Points per race will appear after updating the league.',
      'No se pudo abrir la clasificación.':
          'The standings could not be opened.',
    },
    'de': {
      'El calendario aparecerá después de sincronizar.':
          'Der Kalender erscheint nach der Synchronisierung.',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Die Punkte pro Rennen erscheinen nach der Aktualisierung der Liga.',
      'No se pudieron calcular las predicciones.':
          'Die Vorhersagen konnten nicht berechnet werden.',
      'No se pudo abrir la clasificación.':
          'Die Rangliste konnte nicht geöffnet werden.',
      'No se pudo calcular la afinidad del circuito.':
          'Die Streckenaffinität konnte nicht berechnet werden.',
      'No se pudo cargar el calendario completo.':
          'Der vollständige Kalender konnte nicht geladen werden.',
      'No se pudo cargar el circuito seleccionado.':
          'Die ausgewählte Strecke konnte nicht geladen werden.',
      'No se pudo cargar el historial de ganadores.':
          'Die Gewinnerhistorie konnte nicht geladen werden.',
      'No se pudo cargar la clasificacion general.':
          'Die Gesamtwertung konnte nicht geladen werden.',
      'Sin calendario. Sincroniza desde Resumen.':
          'Kein Kalender. Synchronisiere über Übersicht.',
      'Sincronizando calendario, resultados y precios...':
          'Kalender, Ergebnisse und Preise werden synchronisiert…',
      'Todavia no hay clasificacion disponible.':
          'Es ist noch keine Wertung verfügbar.',
    },
    'it': {
      'El calendario aparecerá después de sincronizar.':
          'Il calendario apparirà dopo la sincronizzazione.',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'I punti per gara appariranno dopo l’aggiornamento della lega.',
      'No se pudieron calcular las predicciones.':
          'Impossibile calcolare le previsioni.',
      'No se pudo abrir la clasificación.': 'Impossibile aprire la classifica.',
      'No se pudo calcular la afinidad del circuito.':
          'Impossibile calcolare l’affinità del circuito.',
      'No se pudo cargar el calendario completo.':
          'Impossibile caricare il calendario completo.',
      'No se pudo cargar el circuito seleccionado.':
          'Impossibile caricare il circuito selezionato.',
      'No se pudo cargar el historial de ganadores.':
          'Impossibile caricare lo storico dei vincitori.',
      'No se pudo cargar la clasificacion general.':
          'Impossibile caricare la classifica generale.',
      'Sin calendario. Sincroniza desde Resumen.':
          'Nessun calendario. Sincronizza dal Riepilogo.',
      'Sincronizando calendario, resultados y precios...':
          'Sincronizzazione di calendario, risultati e prezzi…',
      'Todavia no hay clasificacion disponible.':
          'Non è ancora disponibile alcuna classifica.',
    },
    'fr': {
      'El calendario aparecerá después de sincronizar.':
          'Le calendrier apparaîtra après la synchronisation.',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Les points par course apparaîtront après la mise à jour de la ligue.',
      'No se pudieron calcular las predicciones.':
          'Impossible de calculer les prédictions.',
      'No se pudo abrir la clasificación.':
          'Impossible d’ouvrir le classement.',
      'No se pudo calcular la afinidad del circuito.':
          'Impossible de calculer l’affinité du circuit.',
      'No se pudo cargar el calendario completo.':
          'Impossible de charger le calendrier complet.',
      'No se pudo cargar el circuito seleccionado.':
          'Impossible de charger le circuit sélectionné.',
      'No se pudo cargar el historial de ganadores.':
          'Impossible de charger l’historique des vainqueurs.',
      'No se pudo cargar la clasificacion general.':
          'Impossible de charger le classement général.',
      'Sin calendario. Sincroniza desde Resumen.':
          'Aucun calendrier. Synchronisez depuis le Résumé.',
      'Sincronizando calendario, resultados y precios...':
          'Synchronisation du calendrier, des résultats et des prix…',
      'Todavia no hay clasificacion disponible.':
          'Aucun classement n’est encore disponible.',
    },
    'pt': {
      'El calendario aparecerá después de sincronizar.':
          'O calendário aparecerá após a sincronização.',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Os pontos por corrida aparecerão após atualizar a liga.',
      'No se pudo abrir la clasificación.':
          'Não foi possível abrir a classificação.',
    },
    'nl': {
      'El calendario aparecerá después de sincronizar.':
          'De kalender verschijnt na synchronisatie.',
      'Los puntos por carrera aparecerán tras actualizar la liga.':
          'Racepunten verschijnen na het bijwerken van de competitie.',
      'No se pudo abrir la clasificación.':
          'De ranglijst kon niet worden geopend.',
    },
  };

  static const Map<String, Map<String, String>> _legalCatalog = {
    'en': {
      'Polewise es una aplicación no oficial y no está asociada de ninguna manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de Formula One Licensing B.V.':
          'Polewise is an unofficial application and is not affiliated in any way with Formula 1 companies. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX, and related marks are trademarks of Formula One Licensing B.V.',
    },
    'de': {
      'Polewise es una aplicación no oficial y no está asociada de ninguna manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de Formula One Licensing B.V.':
          'Polewise ist eine inoffizielle Anwendung und steht in keiner Verbindung zu den Unternehmen der Formel 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX und zugehörige Marken sind Marken von Formula One Licensing B.V.',
    },
    'it': {
      'Polewise es una aplicación no oficial y no está asociada de ninguna manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de Formula One Licensing B.V.':
          'Polewise è un’applicazione non ufficiale e non è in alcun modo affiliata alle società di Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX e i marchi correlati sono marchi di Formula One Licensing B.V.',
    },
    'fr': {
      'Polewise es una aplicación no oficial y no está asociada de ninguna manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de Formula One Licensing B.V.':
          'Polewise est une application non officielle et n’est affiliée d’aucune manière aux sociétés de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX et les marques associées sont des marques de Formula One Licensing B.V.',
    },
    'pt': {
      'Polewise es una aplicación no oficial y no está asociada de ninguna manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de Formula One Licensing B.V.':
          'Polewise é um aplicativo não oficial e não possui qualquer associação com as empresas de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX e as marcas relacionadas são marcas registradas da Formula One Licensing B.V.',
    },
    'nl': {
      'Polewise es una aplicación no oficial y no está asociada de ninguna manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas relacionadas son marcas comerciales de Formula One Licensing B.V.':
          'Polewise is een niet-officiële toepassing en is op geen enkele wijze verbonden aan Formula 1-bedrijven. F1, FORMULA ONE, FORMULA 1, FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX en verwante merken zijn handelsmerken van Formula One Licensing B.V.',
    },
  };

  static const Map<String, Map<String, String>> _privacyCatalog = {
    'en': {
      'El acceso es opcional y se realiza en la web oficial dentro de un navegador integrado. Polewise puede copiar el token de sesión, el identificador de usuario, el equipo y las ligas para mostrarlos en la app. Esta información se cifra y se guarda únicamente en el dispositivo. Polewise no almacena la contraseña.':
          'Access is optional and takes place on the official website in an integrated browser. Polewise may copy the session token, user identifier, team, and leagues to display them in the app. This information is encrypted and stored only on the device. Polewise does not store the password.',
      'Solo se activan con permiso. Polewise envía recuentos agrupados a su servicio y eventos generales a Google Analytics. Google puede procesar un identificador de instalación, datos técnicos del dispositivo y una región aproximada. No enviamos correo, cuenta, sesión, equipo, liga ni contenido. La recopilación del identificador publicitario y la personalización de anuncios están desactivadas.':
          'They are enabled only with permission. Polewise sends aggregated counts to its service and general events to Google Analytics. Google may process an installation identifier, technical device data, and an approximate region. We do not send email, account, session, team, league, or content. Advertising ID collection and ad personalization are disabled.',
      'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de fantasy para obtener datos deportivos. Esos servicios pueden recibir la dirección IP y los datos técnicos imprescindibles para responder a la conexión, conforme a sus propias políticas.':
          'Polewise consults Jolpica-F1, OpenF1, and fantasy web services for sporting data. Those services may receive the IP address and technical data required to respond to the connection, under their own policies.',
      'Puedes desactivar las estadísticas en cualquier momento para detener recopilaciones futuras y borrar la cola local pendiente. Los datos ya procesados por Google se conservan según su política. También puedes eliminar desde Ajustes la sesión, el equipo y las ligas guardadas localmente. Esta acción no elimina la cuenta del servicio oficial.':
          'You can disable statistics at any time to stop future collection and delete the pending local queue. Data already processed by Google is retained under its policy. From Settings, you can also remove the locally saved session, team, and leagues. This does not delete your official service account.',
      'Los secretos de sesión se guardan mediante el almacenamiento seguro del sistema. Polewise no está dirigida específicamente a menores y no solicita edad, ubicación ni datos de pago.':
          'Session secrets are stored using secure system storage. Polewise is not specifically aimed at minors and does not request age, location, or payment details.',
    },
    'de': {
      'El acceso es opcional y se realiza en la web oficial dentro de un navegador integrado. Polewise puede copiar el token de sesión, el identificador de usuario, el equipo y las ligas para mostrarlos en la app. Esta información se cifra y se guarda únicamente en el dispositivo. Polewise no almacena la contraseña.':
          'Der Zugriff ist optional und erfolgt auf der offiziellen Website in einem integrierten Browser. Polewise kann Sitzungstoken, Benutzerkennung, Team und Ligen kopieren, um sie in der App anzuzeigen. Diese Informationen werden verschlüsselt und nur auf dem Gerät gespeichert. Polewise speichert kein Passwort.',
      'Solo se activan con permiso. Polewise envía recuentos agrupados a su servicio y eventos generales a Google Analytics. Google puede procesar un identificador de instalación, datos técnicos del dispositivo y una región aproximada. No enviamos correo, cuenta, sesión, equipo, liga ni contenido. La recopilación del identificador publicitario y la personalización de anuncios están desactivadas.':
          'Sie werden nur mit Zustimmung aktiviert. Polewise sendet zusammengefasste Zählwerte an seinen Dienst und allgemeine Ereignisse an Google Analytics. Google kann eine Installationskennung, technische Gerätedaten und eine ungefähre Region verarbeiten. E-Mail, Konto, Sitzung, Team, Liga und Inhalte werden nicht gesendet. Werbe-ID-Erfassung und Anzeigenpersonalisierung sind deaktiviert.',
      'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de fantasy para obtener datos deportivos. Esos servicios pueden recibir la dirección IP y los datos técnicos imprescindibles para responder a la conexión, conforme a sus propias políticas.':
          'Polewise nutzt Jolpica-F1, OpenF1 und Fantasy-Webdienste für Sportdaten. Diese Dienste können die IP-Adresse und notwendige technische Daten erhalten, um die Verbindung gemäß ihren eigenen Richtlinien zu beantworten.',
      'Puedes desactivar las estadísticas en cualquier momento para detener recopilaciones futuras y borrar la cola local pendiente. Los datos ya procesados por Google se conservan según su política. También puedes eliminar desde Ajustes la sesión, el equipo y las ligas guardadas localmente. Esta acción no elimina la cuenta del servicio oficial.':
          'Du kannst Statistiken jederzeit deaktivieren, um die künftige Erfassung zu stoppen und die lokale Warteschlange zu löschen. Bereits von Google verarbeitete Daten werden gemäß dessen Richtlinie aufbewahrt. Sitzung, Team und lokal gespeicherte Ligen kannst du ebenfalls entfernen. Dein Konto beim offiziellen Dienst wird dadurch nicht gelöscht.',
      'Los secretos de sesión se guardan mediante el almacenamiento seguro del sistema. Polewise no está dirigida específicamente a menores y no solicita edad, ubicación ni datos de pago.':
          'Sitzungsgeheimnisse werden über den sicheren Systemspeicher gespeichert. Polewise richtet sich nicht speziell an Minderjährige und fragt weder Alter, Standort noch Zahlungsdaten ab.',
    },
    'it': {
      'El acceso es opcional y se realiza en la web oficial dentro de un navegador integrado. Polewise puede copiar el token de sesión, el identificador de usuario, el equipo y las ligas para mostrarlos en la app. Esta información se cifra y se guarda únicamente en el dispositivo. Polewise no almacena la contraseña.':
          'L’accesso è facoltativo e avviene sul sito ufficiale in un browser integrato. Polewise può copiare token di sessione, identificativo utente, squadra e leghe per mostrarli nell’app. Queste informazioni sono cifrate e conservate solo sul dispositivo. Polewise non conserva la password.',
      'Solo se activan con permiso. Polewise envía recuentos agrupados a su servicio y eventos generales a Google Analytics. Google puede procesar un identificador de instalación, datos técnicos del dispositivo y una región aproximada. No enviamos correo, cuenta, sesión, equipo, liga ni contenido. La recopilación del identificador publicitario y la personalización de anuncios están desactivadas.':
          'Sono attivate solo con consenso. Polewise invia conteggi aggregati al proprio servizio ed eventi generali a Google Analytics. Google può elaborare un identificativo di installazione, dati tecnici del dispositivo e una regione approssimativa. Non inviamo email, account, sessione, squadra, lega o contenuti. La raccolta dell’ID pubblicitario e la personalizzazione degli annunci sono disattivate.',
      'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de fantasy para obtener datos deportivos. Esos servicios pueden recibir la dirección IP y los datos técnicos imprescindibles para responder a la conexión, conforme a sus propias políticas.':
          'Polewise consulta Jolpica-F1, OpenF1 e servizi web fantasy per ottenere dati sportivi. Tali servizi possono ricevere indirizzo IP e dati tecnici necessari per rispondere alla connessione, secondo le proprie politiche.',
      'Puedes desactivar las estadísticas en cualquier momento para detener recopilaciones futuras y borrar la cola local pendiente. Los datos ya procesados por Google se conservan según su política. También puedes eliminar desde Ajustes la sesión, el equipo y las ligas guardadas localmente. Esta acción no elimina la cuenta del servicio oficial.':
          'Puoi disattivare le statistiche in qualsiasi momento per interrompere la raccolta futura ed eliminare la coda locale. I dati già elaborati da Google sono conservati secondo la sua politica. Puoi anche rimuovere sessione, squadra e leghe salvate localmente. Questa azione non elimina l’account del servizio ufficiale.',
      'Los secretos de sesión se guardan mediante el almacenamiento seguro del sistema. Polewise no está dirigida específicamente a menores y no solicita edad, ubicación ni datos de pago.':
          'I segreti di sessione sono salvati nell’archiviazione sicura del sistema. Polewise non è rivolta specificamente ai minori e non richiede età, posizione o dati di pagamento.',
    },
    'fr': {
      'El acceso es opcional y se realiza en la web oficial dentro de un navegador integrado. Polewise puede copiar el token de sesión, el identificador de usuario, el equipo y las ligas para mostrarlos en la app. Esta información se cifra y se guarda únicamente en el dispositivo. Polewise no almacena la contraseña.':
          'L’accès est facultatif et s’effectue sur le site officiel dans un navigateur intégré. Polewise peut copier le jeton de session, l’identifiant utilisateur, l’équipe et les ligues afin de les afficher dans l’application. Ces informations sont chiffrées et stockées uniquement sur l’appareil. Polewise ne conserve pas le mot de passe.',
      'Solo se activan con permiso. Polewise envía recuentos agrupados a su servicio y eventos generales a Google Analytics. Google puede procesar un identificador de instalación, datos técnicos del dispositivo y una región aproximada. No enviamos correo, cuenta, sesión, equipo, liga ni contenido. La recopilación del identificador publicitario y la personalización de anuncios están desactivadas.':
          'Elles sont activées uniquement avec autorisation. Polewise envoie des décomptes regroupés à son service et des événements généraux à Google Analytics. Google peut traiter un identifiant d’installation, des données techniques de l’appareil et une région approximative. Nous n’envoyons ni e-mail, compte, session, équipe, ligue ou contenu. La collecte de l’identifiant publicitaire et la personnalisation des annonces sont désactivées.',
      'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de fantasy para obtener datos deportivos. Esos servicios pueden recibir la dirección IP y los datos técnicos imprescindibles para responder a la conexión, conforme a sus propias políticas.':
          'Polewise consulte Jolpica-F1, OpenF1 et des services web fantasy pour obtenir des données sportives. Ces services peuvent recevoir l’adresse IP et les données techniques nécessaires pour répondre à la connexion, selon leurs propres politiques.',
      'Puedes desactivar las estadísticas en cualquier momento para detener recopilaciones futuras y borrar la cola local pendiente. Los datos ya procesados por Google se conservan según su política. También puedes eliminar desde Ajustes la sesión, el equipo y las ligas guardadas localmente. Esta acción no elimina la cuenta del servicio oficial.':
          'Vous pouvez désactiver les statistiques à tout moment pour arrêter les collectes futures et supprimer la file locale. Les données déjà traitées par Google sont conservées selon sa politique. Vous pouvez aussi supprimer la session, l’équipe et les ligues enregistrées localement. Cette action ne supprime pas le compte du service officiel.',
      'Los secretos de sesión se guardan mediante el almacenamiento seguro del sistema. Polewise no está dirigida específicamente a menores y no solicita edad, ubicación ni datos de pago.':
          'Les secrets de session sont enregistrés dans le stockage sécurisé du système. Polewise ne cible pas spécifiquement les mineurs et ne demande ni âge, ni position, ni données de paiement.',
    },
    'pt': {
      'El acceso es opcional y se realiza en la web oficial dentro de un navegador integrado. Polewise puede copiar el token de sesión, el identificador de usuario, el equipo y las ligas para mostrarlos en la app. Esta información se cifra y se guarda únicamente en el dispositivo. Polewise no almacena la contraseña.':
          'O acesso é opcional e ocorre no site oficial dentro de um navegador integrado. O Polewise pode copiar o token de sessão, o identificador do usuário, a equipe e as ligas para exibi-los no aplicativo. Essas informações são criptografadas e guardadas somente no dispositivo. O Polewise não armazena a senha.',
      'Solo se activan con permiso. Polewise envía recuentos agrupados a su servicio y eventos generales a Google Analytics. Google puede procesar un identificador de instalación, datos técnicos del dispositivo y una región aproximada. No enviamos correo, cuenta, sesión, equipo, liga ni contenido. La recopilación del identificador publicitario y la personalización de anuncios están desactivadas.':
          'São ativadas apenas com permissão. O Polewise envia totais agrupados ao próprio serviço e eventos gerais ao Google Analytics. O Google pode processar um identificador de instalação, dados técnicos do dispositivo e uma região aproximada. Não enviamos e-mail, conta, sessão, equipe, liga ou conteúdo. A coleta do identificador de publicidade e a personalização de anúncios estão desativadas.',
      'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de fantasy para obtener datos deportivos. Esos servicios pueden recibir la dirección IP y los datos técnicos imprescindibles para responder a la conexión, conforme a sus propias políticas.':
          'O Polewise consulta Jolpica-F1, OpenF1 e serviços web de fantasy para obter dados esportivos. Esses serviços podem receber o endereço IP e dados técnicos necessários para responder à conexão, conforme suas próprias políticas.',
      'Puedes desactivar las estadísticas en cualquier momento para detener recopilaciones futuras y borrar la cola local pendiente. Los datos ya procesados por Google se conservan según su política. También puedes eliminar desde Ajustes la sesión, el equipo y las ligas guardadas localmente. Esta acción no elimina la cuenta del servicio oficial.':
          'Você pode desativar as estatísticas a qualquer momento para interromper coletas futuras e excluir a fila local. Dados já processados pelo Google são mantidos conforme sua política. Também pode remover a sessão, a equipe e as ligas salvas localmente. Esta ação não exclui sua conta do serviço oficial.',
      'Los secretos de sesión se guardan mediante el almacenamiento seguro del sistema. Polewise no está dirigida específicamente a menores y no solicita edad, ubicación ni datos de pago.':
          'Os segredos de sessão são guardados no armazenamento seguro do sistema. O Polewise não é direcionado especificamente a menores e não solicita idade, localização nem dados de pagamento.',
    },
    'nl': {
      'El acceso es opcional y se realiza en la web oficial dentro de un navegador integrado. Polewise puede copiar el token de sesión, el identificador de usuario, el equipo y las ligas para mostrarlos en la app. Esta información se cifra y se guarda únicamente en el dispositivo. Polewise no almacena la contraseña.':
          'Toegang is optioneel en vindt plaats op de officiële website in een geïntegreerde browser. Polewise kan het sessietoken, gebruikers-ID, team en competities kopiëren om ze in de app te tonen. Deze informatie wordt versleuteld en alleen op het apparaat opgeslagen. Polewise bewaart het wachtwoord niet.',
      'Solo se activan con permiso. Polewise envía recuentos agrupados a su servicio y eventos generales a Google Analytics. Google puede procesar un identificador de instalación, datos técnicos del dispositivo y una región aproximada. No enviamos correo, cuenta, sesión, equipo, liga ni contenido. La recopilación del identificador publicitario y la personalización de anuncios están desactivadas.':
          'Ze worden alleen met toestemming geactiveerd. Polewise stuurt samengevoegde tellingen naar de eigen dienst en algemene gebeurtenissen naar Google Analytics. Google kan een installatie-ID, technische apparaatgegevens en een globale regio verwerken. We sturen geen e-mail, account, sessie, team, competitie of inhoud. Verzameling van de advertentie-ID en advertentiepersonalisatie zijn uitgeschakeld.',
      'Polewise consulta Jolpica-F1, OpenF1 y los servicios web de fantasy para obtener datos deportivos. Esos servicios pueden recibir la dirección IP y los datos técnicos imprescindibles para responder a la conexión, conforme a sus propias políticas.':
          'Polewise raadpleegt Jolpica-F1, OpenF1 en fantasywebdiensten voor sportgegevens. Deze diensten kunnen het IP-adres en noodzakelijke technische gegevens ontvangen om op de verbinding te reageren, volgens hun eigen beleid.',
      'Puedes desactivar las estadísticas en cualquier momento para detener recopilaciones futuras y borrar la cola local pendiente. Los datos ya procesados por Google se conservan según su política. También puedes eliminar desde Ajustes la sesión, el equipo y las ligas guardadas localmente. Esta acción no elimina la cuenta del servicio oficial.':
          'Je kunt statistieken altijd uitschakelen om toekomstige verzameling te stoppen en de lokale wachtrij te verwijderen. Gegevens die Google al heeft verwerkt, worden volgens het beleid bewaard. Je kunt ook de sessie, het team en lokaal opgeslagen competities verwijderen. Hiermee wordt je account bij de officiële dienst niet verwijderd.',
      'Los secretos de sesión se guardan mediante el almacenamiento seguro del sistema. Polewise no está dirigida específicamente a menores y no solicita edad, ubicación ni datos de pago.':
          'Sessiegeheimen worden opgeslagen met de beveiligde opslag van het systeem. Polewise is niet specifiek gericht op minderjarigen en vraagt niet om leeftijd, locatie of betaalgegevens.',
    },
  };
}

extension AppLocalization on BuildContext {
  String tr(String source, {Map<String, Object?> values = const {}}) =>
      AppTranslations.text(this, source, values: values);
}
