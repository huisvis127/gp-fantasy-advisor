import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Estados vacíos y de error (sección 6: "sin datos, sin conexión, login
/// caducado, API caída -> mensaje claro + reintentar"), reutilizado en
/// todas las pantallas.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  const EmptyState.noConnection({super.key, this.onRetry})
      : icon = Icons.wifi_off_rounded,
        title = 'Sin conexión',
        message = 'No se pudo actualizar. Mostrando los últimos datos guardados.';

  const EmptyState.noData({super.key, this.onRetry})
      : icon = Icons.inbox_rounded,
        title = 'Todavía no hay datos',
        message = 'Sincroniza para descargar calendario, resultados y precios.';

  const EmptyState.loginExpired({super.key, this.onRetry})
      : icon = Icons.lock_clock_rounded,
        title = 'Sesión caducada',
        message = 'Vuelve a iniciar sesión en F1 Fantasy para importar tu equipo.';

  const EmptyState.apiDown({super.key, this.onRetry})
      : icon = Icons.cloud_off_rounded,
        title = 'Servicio no disponible',
        message = 'La fuente de datos no responde ahora mismo. Inténtalo más tarde.';

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
