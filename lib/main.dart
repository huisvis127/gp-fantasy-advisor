import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_providers.dart';
import 'core/providers.dart' show remoteConfigProvider;
import 'core/remote_config.dart';
import 'core/theme.dart';
import 'ui/screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final remoteConfig = await RemoteConfig.load();

  runApp(
    ProviderScope(
      overrides: [
        remoteConfigProvider.overrideWithValue(remoteConfig),
      ],
      child: const GpFantasyAdvisorApp(),
    ),
  );
}

class GpFantasyAdvisorApp extends ConsumerStatefulWidget {
  const GpFantasyAdvisorApp({super.key});

  @override
  ConsumerState<GpFantasyAdvisorApp> createState() => _GpFantasyAdvisorAppState();
}

class _GpFantasyAdvisorAppState extends ConsumerState<GpFantasyAdvisorApp> {
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
    return MaterialApp(
      title: 'GP Fantasy Advisor',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootShell(),
    );
  }
}
