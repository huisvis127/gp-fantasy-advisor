/// Extrae los chips usados del historial privado de F1 Fantasy.
///
/// El servicio 2026 mantiene nombres antiguos y algunas erratas
/// (`extraDrs`, `noNigative`, `...takenGD`). El parser acepta esas variantes
/// y también la forma normalizada que genera nuestro WebView:
/// `chipsUsed: [{name, round}]`.
Map<String, int?> parseFantasyChipUsage(dynamic root) {
  final output = <String, int?>{};

  const definitions = <String, ({List<String> used, List<String> rounds})>{
    'wildcard': (
      used: ['iswildcardtaken'],
      rounds: ['wildcardtakengd'],
    ),
    'limitless': (
      used: ['islimitlesstaken'],
      rounds: ['limitlesstakengd'],
    ),
    'final_fix': (
      used: ['isfinalfixtaken'],
      rounds: ['finalfixtakengd'],
    ),
    'triple_boost': (
      used: ['isextradrstaken', 'istripleboosttaken'],
      rounds: ['extradrstakengd', 'tripleboosttakengd'],
    ),
    'no_negative': (
      used: ['isnonigativetaken', 'isnonegativetaken'],
      rounds: ['nonigativetakengd', 'nonegativetakengd'],
    ),
    'autopilot': (
      used: ['isautopilottaken'],
      rounds: ['isautopilottakengd', 'autopilottakengd'],
    ),
  };

  void add(String rawName, [int? round]) {
    final chip = canonicalFantasyChip(rawName);
    if (!_knownChips.contains(chip)) return;
    final normalizedRound = round != null && round > 0 ? round : null;
    final previous = output[chip];
    output[chip] = normalizedRound ?? previous;
  }

  int? readRound(Map<String, dynamic> map, Iterable<String> keys) {
    final normalized = {
      for (final entry in map.entries) _key(entry.key): entry.value,
    };
    for (final key in keys) {
      final parsed = int.tryParse(normalized[_key(key)]?.toString() ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  void parseUsedContainer(dynamic value) {
    if (value is String) {
      for (final item in value.split(',')) {
        add(item);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final normalized = {
            for (final entry in map.entries) _key(entry.key): entry.value,
          };
          final name = [
            'name',
            'chip',
            'booster',
            'type',
            'boostername',
          ]
              .map(_key)
              .map((key) => normalized[key])
              .whereType<Object?>()
              .firstOrNull;
          if (name != null) {
            add(
              name.toString(),
              readRound(map, const [
                'round',
                'gameDay',
                'gameDayId',
                'gd',
                'usedRound',
              ]),
            );
          }
        } else {
          add(item.toString());
        }
      }
      return;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final entry in map.entries) {
        if (_truthy(entry.value)) add(entry.key.toString());
      }
    }
  }

  void walk(dynamic node) {
    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      final normalized = {
        for (final entry in map.entries) _key(entry.key): entry.value,
      };
      for (final definition in definitions.entries) {
        final used = definition.value.used
            .map(_key)
            .any((key) => _truthy(normalized[key]));
        if (!used) continue;
        add(
          definition.key,
          readRound(map, definition.value.rounds),
        );
      }
      for (final entry in map.entries) {
        final key = _key(entry.key);
        if (key == 'chipsused' ||
            key == 'usedchips' ||
            key == 'boostersused' ||
            key == 'usedboosters') {
          parseUsedContainer(entry.value);
        }
        walk(entry.value);
      }
    } else if (node is List) {
      for (final value in node) {
        walk(value);
      }
    }
  }

  walk(root);
  return output;
}

const _knownChips = {
  'limitless',
  'wildcard',
  'triple_boost',
  'no_negative',
  'final_fix',
  'autopilot',
};

String canonicalFantasyChip(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return switch (slug) {
    'extra_drs' || '3x_boost' || 'triple_boost' || 'extradrs' => 'triple_boost',
    'auto_pilot' => 'autopilot',
    'no_negative' || 'no_nigative' => 'no_negative',
    'finalfix' => 'final_fix',
    final chip => chip,
  };
}

String _key(Object value) =>
    value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _truthy(dynamic value) =>
    value == true ||
    value == 1 ||
    value?.toString().toLowerCase() == 'true' ||
    value?.toString() == '1';

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
