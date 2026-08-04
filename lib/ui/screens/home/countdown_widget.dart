import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Cuenta atrás hasta el próximo GP, con los números en Syne y las
/// etiquetas en mono uppercase (lenguaje visual de la referencia).
class CountdownWidget extends StatefulWidget {
  const CountdownWidget({super.key, required this.targetDate});

  final DateTime targetDate;

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _update());
  }

  void _update() {
    setState(() {
      _remaining = widget.targetDate.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return Text('¡EN MARCHA O FINALIZADO!',
          style: AppText.mono(11, color: AppColors.ok));
    }
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _timeBlock('$days', 'DÍAS'),
          _separator(),
          _timeBlock('$hours', 'HORAS'),
          _separator(),
          _timeBlock('$minutes', 'MIN'),
        ],
      ),
    );
  }

  Widget _separator() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child:
            Text(':', style: AppText.syne(22, color: AppColors.textTertiary)),
      );

  Widget _timeBlock(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.syne(22, color: AppColors.cyan)),
          const SizedBox(height: 2),
          Text(label, style: AppText.mono(8)),
        ],
      ),
    );
  }
}
