import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../data/sources/fantasy_auth_service.dart';
import '../../widgets/glass_card.dart';
import '../my_team/manual_team_entry_screen.dart';
import 'fantasy_login_webview_screen.dart';

class FantasyLoginScreen extends ConsumerStatefulWidget {
  const FantasyLoginScreen({super.key});

  @override
  ConsumerState<FantasyLoginScreen> createState() => _FantasyLoginScreenState();
}

class _FantasyLoginScreenState extends ConsumerState<FantasyLoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _showDirectForm = false;
  String? _error;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _openBrowser() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FantasyLoginWebViewScreen()),
    );
    if (result == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _submitDirect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(fantasyAuthServiceProvider)
          .loginWithPassword(
            username: _userController.text.trim(),
            password: _passController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on FantasyAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta F1 Fantasy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acceso seguro',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Inicia sesión en la web oficial. La app copiará únicamente '
                  'tu equipo y tus ligas; la contraseña nunca pasa por esta app.',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openBrowser,
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('ABRIR WEB OFICIAL'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualTeamEntryScreen(),
                      ),
                    ),
                    child: const Text('Introducir equipo manualmente'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() => _showDirectForm = !_showDirectForm),
            child: Text(
              _showDirectForm
                  ? 'Ocultar acceso directo experimental'
                  : 'Mostrar acceso directo experimental',
            ),
          ),
          if (_showDirectForm) ...[
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Correo o usuario',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitDirect,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('PROBAR ACCESO DIRECTO'),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
          ],
        ],
      ),
    );
  }
}
