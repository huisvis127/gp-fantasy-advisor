import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../widgets/ref_widgets.dart';
import '../ideal/ideal_screen.dart';
import '../my_team/my_team_screen.dart';

/// Reúne las dos herramientas de juego en la pestaña Fantasy, igual que la
/// aplicación de referencia: propuesta óptima y equipo real del usuario.
class FantasyScreen extends StatefulWidget {
  const FantasyScreen({super.key});

  @override
  State<FantasyScreen> createState() => _FantasyScreenState();
}

class _FantasyScreenState extends State<FantasyScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHead(
                kicker: 'Estrategia',
                title: 'Tu juego',
              ),
              const SizedBox(height: 5),
              Text(
                'Construye el equipo ideal o analiza el que ya tienes.',
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: const ['Equipo ideal', 'Mi equipo'],
                selectedIndex: _tab,
                onSelected: (value) => setState(() => _tab = value),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [IdealScreen(), MyTeamScreen()],
          ),
        ),
      ],
    );
  }
}
