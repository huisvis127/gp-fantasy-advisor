import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_providers.dart';
import 'core/constants.dart';
import 'core/localization.dart';
import 'core/providers.dart' show remoteConfigProvider;
import 'core/remote_config.dart';
import 'core/theme.dart';
import 'ui/screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  await Future.wait([
    for (final locale in ['es', 'en', 'de', 'it', 'fr', 'pt', 'nl'])
      initializeDateFormatting(locale),
  ]);
  final remoteConfig = await RemoteConfig.load();

  runApp(
    ProviderScope(
      overrides: [
        remoteConfigProvider.overrideWithValue(remoteConfig),
      ],
      child: const PolewiseApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp();
  } on FirebaseException {
    // La app sigue funcionando mientras no exista una configuración válida.
  }
}

class PolewiseApp extends ConsumerStatefulWidget {
  const PolewiseApp({super.key});

  @override
  ConsumerState<PolewiseApp> createState() => _PolewiseAppState();
}

class _PolewiseAppState extends ConsumerState<PolewiseApp> {
  @override
  void initState() {
    super.initState();
    // Sincronización inicial en segundo plano (Fase 1, sección 3): la UI se
    // muestra al instante con lo que haya en caché (o vacío la primera vez)
    // y se refresca sola en cuanto llega la respuesta de red. El estado y
    // los errores de la sync son visibles en la UI (syncControllerProvider).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider.notifier).syncNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: AppMeta.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: language.locale,
      supportedLocales: [
        for (final supported in AppLanguage.values) supported.locale,
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const RootShell(),
    );
  }
}
