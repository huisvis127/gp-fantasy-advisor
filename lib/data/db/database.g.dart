// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DriversTable extends Drivers with TableInfo<$DriversTable, DriverRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _givenNameMeta =
      const VerificationMeta('givenName');
  @override
  late final GeneratedColumn<String> givenName = GeneratedColumn<String>(
      'given_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _familyNameMeta =
      const VerificationMeta('familyName');
  @override
  late final GeneratedColumn<String> familyName = GeneratedColumn<String>(
      'family_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _constructorIdMeta =
      const VerificationMeta('constructorId');
  @override
  late final GeneratedColumn<String> constructorId = GeneratedColumn<String>(
      'constructor_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, givenName, familyName, constructorId, number];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drivers';
  @override
  VerificationContext validateIntegrity(Insertable<DriverRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('given_name')) {
      context.handle(_givenNameMeta,
          givenName.isAcceptableOrUnknown(data['given_name']!, _givenNameMeta));
    } else if (isInserting) {
      context.missing(_givenNameMeta);
    }
    if (data.containsKey('family_name')) {
      context.handle(
          _familyNameMeta,
          familyName.isAcceptableOrUnknown(
              data['family_name']!, _familyNameMeta));
    } else if (isInserting) {
      context.missing(_familyNameMeta);
    }
    if (data.containsKey('constructor_id')) {
      context.handle(
          _constructorIdMeta,
          constructorId.isAcceptableOrUnknown(
              data['constructor_id']!, _constructorIdMeta));
    } else if (isInserting) {
      context.missing(_constructorIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriverRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriverRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      givenName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}given_name'])!,
      familyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}family_name'])!,
      constructorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}constructor_id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number']),
    );
  }

  @override
  $DriversTable createAlias(String alias) {
    return $DriversTable(attachedDatabase, alias);
  }
}

class DriverRow extends DataClass implements Insertable<DriverRow> {
  final String id;
  final String code;
  final String givenName;
  final String familyName;
  final String constructorId;
  final int? number;
  const DriverRow(
      {required this.id,
      required this.code,
      required this.givenName,
      required this.familyName,
      required this.constructorId,
      this.number});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['given_name'] = Variable<String>(givenName);
    map['family_name'] = Variable<String>(familyName);
    map['constructor_id'] = Variable<String>(constructorId);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    return map;
  }

  DriversCompanion toCompanion(bool nullToAbsent) {
    return DriversCompanion(
      id: Value(id),
      code: Value(code),
      givenName: Value(givenName),
      familyName: Value(familyName),
      constructorId: Value(constructorId),
      number:
          number == null && nullToAbsent ? const Value.absent() : Value(number),
    );
  }

  factory DriverRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriverRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      givenName: serializer.fromJson<String>(json['givenName']),
      familyName: serializer.fromJson<String>(json['familyName']),
      constructorId: serializer.fromJson<String>(json['constructorId']),
      number: serializer.fromJson<int?>(json['number']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'givenName': serializer.toJson<String>(givenName),
      'familyName': serializer.toJson<String>(familyName),
      'constructorId': serializer.toJson<String>(constructorId),
      'number': serializer.toJson<int?>(number),
    };
  }

  DriverRow copyWith(
          {String? id,
          String? code,
          String? givenName,
          String? familyName,
          String? constructorId,
          Value<int?> number = const Value.absent()}) =>
      DriverRow(
        id: id ?? this.id,
        code: code ?? this.code,
        givenName: givenName ?? this.givenName,
        familyName: familyName ?? this.familyName,
        constructorId: constructorId ?? this.constructorId,
        number: number.present ? number.value : this.number,
      );
  DriverRow copyWithCompanion(DriversCompanion data) {
    return DriverRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      givenName: data.givenName.present ? data.givenName.value : this.givenName,
      familyName:
          data.familyName.present ? data.familyName.value : this.familyName,
      constructorId: data.constructorId.present
          ? data.constructorId.value
          : this.constructorId,
      number: data.number.present ? data.number.value : this.number,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriverRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('givenName: $givenName, ')
          ..write('familyName: $familyName, ')
          ..write('constructorId: $constructorId, ')
          ..write('number: $number')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, givenName, familyName, constructorId, number);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriverRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.givenName == this.givenName &&
          other.familyName == this.familyName &&
          other.constructorId == this.constructorId &&
          other.number == this.number);
}

class DriversCompanion extends UpdateCompanion<DriverRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> givenName;
  final Value<String> familyName;
  final Value<String> constructorId;
  final Value<int?> number;
  final Value<int> rowid;
  const DriversCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.givenName = const Value.absent(),
    this.familyName = const Value.absent(),
    this.constructorId = const Value.absent(),
    this.number = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriversCompanion.insert({
    required String id,
    required String code,
    required String givenName,
    required String familyName,
    required String constructorId,
    this.number = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        code = Value(code),
        givenName = Value(givenName),
        familyName = Value(familyName),
        constructorId = Value(constructorId);
  static Insertable<DriverRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? givenName,
    Expression<String>? familyName,
    Expression<String>? constructorId,
    Expression<int>? number,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (givenName != null) 'given_name': givenName,
      if (familyName != null) 'family_name': familyName,
      if (constructorId != null) 'constructor_id': constructorId,
      if (number != null) 'number': number,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriversCompanion copyWith(
      {Value<String>? id,
      Value<String>? code,
      Value<String>? givenName,
      Value<String>? familyName,
      Value<String>? constructorId,
      Value<int?>? number,
      Value<int>? rowid}) {
    return DriversCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      givenName: givenName ?? this.givenName,
      familyName: familyName ?? this.familyName,
      constructorId: constructorId ?? this.constructorId,
      number: number ?? this.number,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (givenName.present) {
      map['given_name'] = Variable<String>(givenName.value);
    }
    if (familyName.present) {
      map['family_name'] = Variable<String>(familyName.value);
    }
    if (constructorId.present) {
      map['constructor_id'] = Variable<String>(constructorId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriversCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('givenName: $givenName, ')
          ..write('familyName: $familyName, ')
          ..write('constructorId: $constructorId, ')
          ..write('number: $number, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConstructorsTable extends Constructors
    with TableInfo<$ConstructorsTable, ConstructorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConstructorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nationalityMeta =
      const VerificationMeta('nationality');
  @override
  late final GeneratedColumn<String> nationality = GeneratedColumn<String>(
      'nationality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, nationality];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'constructors';
  @override
  VerificationContext validateIntegrity(Insertable<ConstructorRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('nationality')) {
      context.handle(
          _nationalityMeta,
          nationality.isAcceptableOrUnknown(
              data['nationality']!, _nationalityMeta));
    } else if (isInserting) {
      context.missing(_nationalityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConstructorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConstructorRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      nationality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nationality'])!,
    );
  }

  @override
  $ConstructorsTable createAlias(String alias) {
    return $ConstructorsTable(attachedDatabase, alias);
  }
}

class ConstructorRow extends DataClass implements Insertable<ConstructorRow> {
  final String id;
  final String name;
  final String nationality;
  const ConstructorRow(
      {required this.id, required this.name, required this.nationality});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['nationality'] = Variable<String>(nationality);
    return map;
  }

  ConstructorsCompanion toCompanion(bool nullToAbsent) {
    return ConstructorsCompanion(
      id: Value(id),
      name: Value(name),
      nationality: Value(nationality),
    );
  }

  factory ConstructorRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConstructorRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nationality: serializer.fromJson<String>(json['nationality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'nationality': serializer.toJson<String>(nationality),
    };
  }

  ConstructorRow copyWith({String? id, String? name, String? nationality}) =>
      ConstructorRow(
        id: id ?? this.id,
        name: name ?? this.name,
        nationality: nationality ?? this.nationality,
      );
  ConstructorRow copyWithCompanion(ConstructorsCompanion data) {
    return ConstructorRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nationality:
          data.nationality.present ? data.nationality.value : this.nationality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConstructorRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nationality: $nationality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nationality);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConstructorRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.nationality == this.nationality);
}

class ConstructorsCompanion extends UpdateCompanion<ConstructorRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> nationality;
  final Value<int> rowid;
  const ConstructorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nationality = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConstructorsCompanion.insert({
    required String id,
    required String name,
    required String nationality,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        nationality = Value(nationality);
  static Insertable<ConstructorRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? nationality,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nationality != null) 'nationality': nationality,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConstructorsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? nationality,
      Value<int>? rowid}) {
    return ConstructorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nationality.present) {
      map['nationality'] = Variable<String>(nationality.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConstructorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nationality: $nationality, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RacesTable extends Races with TableInfo<$RacesTable, RaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _raceNameMeta =
      const VerificationMeta('raceName');
  @override
  late final GeneratedColumn<String> raceName = GeneratedColumn<String>(
      'race_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _circuitIdMeta =
      const VerificationMeta('circuitId');
  @override
  late final GeneratedColumn<String> circuitId = GeneratedColumn<String>(
      'circuit_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _circuitNameMeta =
      const VerificationMeta('circuitName');
  @override
  late final GeneratedColumn<String> circuitName = GeneratedColumn<String>(
      'circuit_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _countryMeta =
      const VerificationMeta('country');
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
      'country', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _hasSprintMeta =
      const VerificationMeta('hasSprint');
  @override
  late final GeneratedColumn<bool> hasSprint = GeneratedColumn<bool>(
      'has_sprint', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_sprint" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        season,
        round,
        raceName,
        circuitId,
        circuitName,
        country,
        date,
        hasSprint
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'races';
  @override
  VerificationContext validateIntegrity(Insertable<RaceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('race_name')) {
      context.handle(_raceNameMeta,
          raceName.isAcceptableOrUnknown(data['race_name']!, _raceNameMeta));
    } else if (isInserting) {
      context.missing(_raceNameMeta);
    }
    if (data.containsKey('circuit_id')) {
      context.handle(_circuitIdMeta,
          circuitId.isAcceptableOrUnknown(data['circuit_id']!, _circuitIdMeta));
    } else if (isInserting) {
      context.missing(_circuitIdMeta);
    }
    if (data.containsKey('circuit_name')) {
      context.handle(
          _circuitNameMeta,
          circuitName.isAcceptableOrUnknown(
              data['circuit_name']!, _circuitNameMeta));
    } else if (isInserting) {
      context.missing(_circuitNameMeta);
    }
    if (data.containsKey('country')) {
      context.handle(_countryMeta,
          country.isAcceptableOrUnknown(data['country']!, _countryMeta));
    } else if (isInserting) {
      context.missing(_countryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('has_sprint')) {
      context.handle(_hasSprintMeta,
          hasSprint.isAcceptableOrUnknown(data['has_sprint']!, _hasSprintMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {season, round};
  @override
  RaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaceRow(
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      raceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}race_name'])!,
      circuitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}circuit_id'])!,
      circuitName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}circuit_name'])!,
      country: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      hasSprint: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_sprint'])!,
    );
  }

  @override
  $RacesTable createAlias(String alias) {
    return $RacesTable(attachedDatabase, alias);
  }
}

class RaceRow extends DataClass implements Insertable<RaceRow> {
  final int season;
  final int round;
  final String raceName;
  final String circuitId;
  final String circuitName;
  final String country;
  final DateTime date;
  final bool hasSprint;
  const RaceRow(
      {required this.season,
      required this.round,
      required this.raceName,
      required this.circuitId,
      required this.circuitName,
      required this.country,
      required this.date,
      required this.hasSprint});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['race_name'] = Variable<String>(raceName);
    map['circuit_id'] = Variable<String>(circuitId);
    map['circuit_name'] = Variable<String>(circuitName);
    map['country'] = Variable<String>(country);
    map['date'] = Variable<DateTime>(date);
    map['has_sprint'] = Variable<bool>(hasSprint);
    return map;
  }

  RacesCompanion toCompanion(bool nullToAbsent) {
    return RacesCompanion(
      season: Value(season),
      round: Value(round),
      raceName: Value(raceName),
      circuitId: Value(circuitId),
      circuitName: Value(circuitName),
      country: Value(country),
      date: Value(date),
      hasSprint: Value(hasSprint),
    );
  }

  factory RaceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaceRow(
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      raceName: serializer.fromJson<String>(json['raceName']),
      circuitId: serializer.fromJson<String>(json['circuitId']),
      circuitName: serializer.fromJson<String>(json['circuitName']),
      country: serializer.fromJson<String>(json['country']),
      date: serializer.fromJson<DateTime>(json['date']),
      hasSprint: serializer.fromJson<bool>(json['hasSprint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'raceName': serializer.toJson<String>(raceName),
      'circuitId': serializer.toJson<String>(circuitId),
      'circuitName': serializer.toJson<String>(circuitName),
      'country': serializer.toJson<String>(country),
      'date': serializer.toJson<DateTime>(date),
      'hasSprint': serializer.toJson<bool>(hasSprint),
    };
  }

  RaceRow copyWith(
          {int? season,
          int? round,
          String? raceName,
          String? circuitId,
          String? circuitName,
          String? country,
          DateTime? date,
          bool? hasSprint}) =>
      RaceRow(
        season: season ?? this.season,
        round: round ?? this.round,
        raceName: raceName ?? this.raceName,
        circuitId: circuitId ?? this.circuitId,
        circuitName: circuitName ?? this.circuitName,
        country: country ?? this.country,
        date: date ?? this.date,
        hasSprint: hasSprint ?? this.hasSprint,
      );
  RaceRow copyWithCompanion(RacesCompanion data) {
    return RaceRow(
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      raceName: data.raceName.present ? data.raceName.value : this.raceName,
      circuitId: data.circuitId.present ? data.circuitId.value : this.circuitId,
      circuitName:
          data.circuitName.present ? data.circuitName.value : this.circuitName,
      country: data.country.present ? data.country.value : this.country,
      date: data.date.present ? data.date.value : this.date,
      hasSprint: data.hasSprint.present ? data.hasSprint.value : this.hasSprint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaceRow(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('raceName: $raceName, ')
          ..write('circuitId: $circuitId, ')
          ..write('circuitName: $circuitName, ')
          ..write('country: $country, ')
          ..write('date: $date, ')
          ..write('hasSprint: $hasSprint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(season, round, raceName, circuitId,
      circuitName, country, date, hasSprint);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaceRow &&
          other.season == this.season &&
          other.round == this.round &&
          other.raceName == this.raceName &&
          other.circuitId == this.circuitId &&
          other.circuitName == this.circuitName &&
          other.country == this.country &&
          other.date == this.date &&
          other.hasSprint == this.hasSprint);
}

class RacesCompanion extends UpdateCompanion<RaceRow> {
  final Value<int> season;
  final Value<int> round;
  final Value<String> raceName;
  final Value<String> circuitId;
  final Value<String> circuitName;
  final Value<String> country;
  final Value<DateTime> date;
  final Value<bool> hasSprint;
  final Value<int> rowid;
  const RacesCompanion({
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.raceName = const Value.absent(),
    this.circuitId = const Value.absent(),
    this.circuitName = const Value.absent(),
    this.country = const Value.absent(),
    this.date = const Value.absent(),
    this.hasSprint = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RacesCompanion.insert({
    required int season,
    required int round,
    required String raceName,
    required String circuitId,
    required String circuitName,
    required String country,
    required DateTime date,
    this.hasSprint = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : season = Value(season),
        round = Value(round),
        raceName = Value(raceName),
        circuitId = Value(circuitId),
        circuitName = Value(circuitName),
        country = Value(country),
        date = Value(date);
  static Insertable<RaceRow> custom({
    Expression<int>? season,
    Expression<int>? round,
    Expression<String>? raceName,
    Expression<String>? circuitId,
    Expression<String>? circuitName,
    Expression<String>? country,
    Expression<DateTime>? date,
    Expression<bool>? hasSprint,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (raceName != null) 'race_name': raceName,
      if (circuitId != null) 'circuit_id': circuitId,
      if (circuitName != null) 'circuit_name': circuitName,
      if (country != null) 'country': country,
      if (date != null) 'date': date,
      if (hasSprint != null) 'has_sprint': hasSprint,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RacesCompanion copyWith(
      {Value<int>? season,
      Value<int>? round,
      Value<String>? raceName,
      Value<String>? circuitId,
      Value<String>? circuitName,
      Value<String>? country,
      Value<DateTime>? date,
      Value<bool>? hasSprint,
      Value<int>? rowid}) {
    return RacesCompanion(
      season: season ?? this.season,
      round: round ?? this.round,
      raceName: raceName ?? this.raceName,
      circuitId: circuitId ?? this.circuitId,
      circuitName: circuitName ?? this.circuitName,
      country: country ?? this.country,
      date: date ?? this.date,
      hasSprint: hasSprint ?? this.hasSprint,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (raceName.present) {
      map['race_name'] = Variable<String>(raceName.value);
    }
    if (circuitId.present) {
      map['circuit_id'] = Variable<String>(circuitId.value);
    }
    if (circuitName.present) {
      map['circuit_name'] = Variable<String>(circuitName.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (hasSprint.present) {
      map['has_sprint'] = Variable<bool>(hasSprint.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RacesCompanion(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('raceName: $raceName, ')
          ..write('circuitId: $circuitId, ')
          ..write('circuitName: $circuitName, ')
          ..write('country: $country, ')
          ..write('date: $date, ')
          ..write('hasSprint: $hasSprint, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResultsTable extends Results with TableInfo<$ResultsTable, ResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _driverIdMeta =
      const VerificationMeta('driverId');
  @override
  late final GeneratedColumn<String> driverId = GeneratedColumn<String>(
      'driver_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _constructorIdMeta =
      const VerificationMeta('constructorId');
  @override
  late final GeneratedColumn<String> constructorId = GeneratedColumn<String>(
      'constructor_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gridPositionMeta =
      const VerificationMeta('gridPosition');
  @override
  late final GeneratedColumn<int> gridPosition = GeneratedColumn<int>(
      'grid_position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _finishPositionMeta =
      const VerificationMeta('finishPosition');
  @override
  late final GeneratedColumn<int> finishPosition = GeneratedColumn<int>(
      'finish_position', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fastestLapMeta =
      const VerificationMeta('fastestLap');
  @override
  late final GeneratedColumn<bool> fastestLap = GeneratedColumn<bool>(
      'fastest_lap', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("fastest_lap" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        season,
        round,
        driverId,
        constructorId,
        gridPosition,
        finishPosition,
        status,
        fastestLap
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'results';
  @override
  VerificationContext validateIntegrity(Insertable<ResultRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('driver_id')) {
      context.handle(_driverIdMeta,
          driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta));
    } else if (isInserting) {
      context.missing(_driverIdMeta);
    }
    if (data.containsKey('constructor_id')) {
      context.handle(
          _constructorIdMeta,
          constructorId.isAcceptableOrUnknown(
              data['constructor_id']!, _constructorIdMeta));
    } else if (isInserting) {
      context.missing(_constructorIdMeta);
    }
    if (data.containsKey('grid_position')) {
      context.handle(
          _gridPositionMeta,
          gridPosition.isAcceptableOrUnknown(
              data['grid_position']!, _gridPositionMeta));
    } else if (isInserting) {
      context.missing(_gridPositionMeta);
    }
    if (data.containsKey('finish_position')) {
      context.handle(
          _finishPositionMeta,
          finishPosition.isAcceptableOrUnknown(
              data['finish_position']!, _finishPositionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('fastest_lap')) {
      context.handle(
          _fastestLapMeta,
          fastestLap.isAcceptableOrUnknown(
              data['fastest_lap']!, _fastestLapMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {season, round, driverId};
  @override
  ResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResultRow(
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      driverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}driver_id'])!,
      constructorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}constructor_id'])!,
      gridPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grid_position'])!,
      finishPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}finish_position']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      fastestLap: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}fastest_lap'])!,
    );
  }

  @override
  $ResultsTable createAlias(String alias) {
    return $ResultsTable(attachedDatabase, alias);
  }
}

class ResultRow extends DataClass implements Insertable<ResultRow> {
  final int season;
  final int round;
  final String driverId;
  final String constructorId;
  final int gridPosition;
  final int? finishPosition;
  final String status;
  final bool fastestLap;
  const ResultRow(
      {required this.season,
      required this.round,
      required this.driverId,
      required this.constructorId,
      required this.gridPosition,
      this.finishPosition,
      required this.status,
      required this.fastestLap});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['driver_id'] = Variable<String>(driverId);
    map['constructor_id'] = Variable<String>(constructorId);
    map['grid_position'] = Variable<int>(gridPosition);
    if (!nullToAbsent || finishPosition != null) {
      map['finish_position'] = Variable<int>(finishPosition);
    }
    map['status'] = Variable<String>(status);
    map['fastest_lap'] = Variable<bool>(fastestLap);
    return map;
  }

  ResultsCompanion toCompanion(bool nullToAbsent) {
    return ResultsCompanion(
      season: Value(season),
      round: Value(round),
      driverId: Value(driverId),
      constructorId: Value(constructorId),
      gridPosition: Value(gridPosition),
      finishPosition: finishPosition == null && nullToAbsent
          ? const Value.absent()
          : Value(finishPosition),
      status: Value(status),
      fastestLap: Value(fastestLap),
    );
  }

  factory ResultRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResultRow(
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      driverId: serializer.fromJson<String>(json['driverId']),
      constructorId: serializer.fromJson<String>(json['constructorId']),
      gridPosition: serializer.fromJson<int>(json['gridPosition']),
      finishPosition: serializer.fromJson<int?>(json['finishPosition']),
      status: serializer.fromJson<String>(json['status']),
      fastestLap: serializer.fromJson<bool>(json['fastestLap']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'driverId': serializer.toJson<String>(driverId),
      'constructorId': serializer.toJson<String>(constructorId),
      'gridPosition': serializer.toJson<int>(gridPosition),
      'finishPosition': serializer.toJson<int?>(finishPosition),
      'status': serializer.toJson<String>(status),
      'fastestLap': serializer.toJson<bool>(fastestLap),
    };
  }

  ResultRow copyWith(
          {int? season,
          int? round,
          String? driverId,
          String? constructorId,
          int? gridPosition,
          Value<int?> finishPosition = const Value.absent(),
          String? status,
          bool? fastestLap}) =>
      ResultRow(
        season: season ?? this.season,
        round: round ?? this.round,
        driverId: driverId ?? this.driverId,
        constructorId: constructorId ?? this.constructorId,
        gridPosition: gridPosition ?? this.gridPosition,
        finishPosition:
            finishPosition.present ? finishPosition.value : this.finishPosition,
        status: status ?? this.status,
        fastestLap: fastestLap ?? this.fastestLap,
      );
  ResultRow copyWithCompanion(ResultsCompanion data) {
    return ResultRow(
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      constructorId: data.constructorId.present
          ? data.constructorId.value
          : this.constructorId,
      gridPosition: data.gridPosition.present
          ? data.gridPosition.value
          : this.gridPosition,
      finishPosition: data.finishPosition.present
          ? data.finishPosition.value
          : this.finishPosition,
      status: data.status.present ? data.status.value : this.status,
      fastestLap:
          data.fastestLap.present ? data.fastestLap.value : this.fastestLap,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResultRow(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('driverId: $driverId, ')
          ..write('constructorId: $constructorId, ')
          ..write('gridPosition: $gridPosition, ')
          ..write('finishPosition: $finishPosition, ')
          ..write('status: $status, ')
          ..write('fastestLap: $fastestLap')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(season, round, driverId, constructorId,
      gridPosition, finishPosition, status, fastestLap);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResultRow &&
          other.season == this.season &&
          other.round == this.round &&
          other.driverId == this.driverId &&
          other.constructorId == this.constructorId &&
          other.gridPosition == this.gridPosition &&
          other.finishPosition == this.finishPosition &&
          other.status == this.status &&
          other.fastestLap == this.fastestLap);
}

class ResultsCompanion extends UpdateCompanion<ResultRow> {
  final Value<int> season;
  final Value<int> round;
  final Value<String> driverId;
  final Value<String> constructorId;
  final Value<int> gridPosition;
  final Value<int?> finishPosition;
  final Value<String> status;
  final Value<bool> fastestLap;
  final Value<int> rowid;
  const ResultsCompanion({
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.driverId = const Value.absent(),
    this.constructorId = const Value.absent(),
    this.gridPosition = const Value.absent(),
    this.finishPosition = const Value.absent(),
    this.status = const Value.absent(),
    this.fastestLap = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResultsCompanion.insert({
    required int season,
    required int round,
    required String driverId,
    required String constructorId,
    required int gridPosition,
    this.finishPosition = const Value.absent(),
    required String status,
    this.fastestLap = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : season = Value(season),
        round = Value(round),
        driverId = Value(driverId),
        constructorId = Value(constructorId),
        gridPosition = Value(gridPosition),
        status = Value(status);
  static Insertable<ResultRow> custom({
    Expression<int>? season,
    Expression<int>? round,
    Expression<String>? driverId,
    Expression<String>? constructorId,
    Expression<int>? gridPosition,
    Expression<int>? finishPosition,
    Expression<String>? status,
    Expression<bool>? fastestLap,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (driverId != null) 'driver_id': driverId,
      if (constructorId != null) 'constructor_id': constructorId,
      if (gridPosition != null) 'grid_position': gridPosition,
      if (finishPosition != null) 'finish_position': finishPosition,
      if (status != null) 'status': status,
      if (fastestLap != null) 'fastest_lap': fastestLap,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResultsCompanion copyWith(
      {Value<int>? season,
      Value<int>? round,
      Value<String>? driverId,
      Value<String>? constructorId,
      Value<int>? gridPosition,
      Value<int?>? finishPosition,
      Value<String>? status,
      Value<bool>? fastestLap,
      Value<int>? rowid}) {
    return ResultsCompanion(
      season: season ?? this.season,
      round: round ?? this.round,
      driverId: driverId ?? this.driverId,
      constructorId: constructorId ?? this.constructorId,
      gridPosition: gridPosition ?? this.gridPosition,
      finishPosition: finishPosition ?? this.finishPosition,
      status: status ?? this.status,
      fastestLap: fastestLap ?? this.fastestLap,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (driverId.present) {
      map['driver_id'] = Variable<String>(driverId.value);
    }
    if (constructorId.present) {
      map['constructor_id'] = Variable<String>(constructorId.value);
    }
    if (gridPosition.present) {
      map['grid_position'] = Variable<int>(gridPosition.value);
    }
    if (finishPosition.present) {
      map['finish_position'] = Variable<int>(finishPosition.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fastestLap.present) {
      map['fastest_lap'] = Variable<bool>(fastestLap.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResultsCompanion(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('driverId: $driverId, ')
          ..write('constructorId: $constructorId, ')
          ..write('gridPosition: $gridPosition, ')
          ..write('finishPosition: $finishPosition, ')
          ..write('status: $status, ')
          ..write('fastestLap: $fastestLap, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QualifyingResultsTable extends QualifyingResults
    with TableInfo<$QualifyingResultsTable, QualifyingResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QualifyingResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _driverIdMeta =
      const VerificationMeta('driverId');
  @override
  late final GeneratedColumn<String> driverId = GeneratedColumn<String>(
      'driver_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _q1MillisMeta =
      const VerificationMeta('q1Millis');
  @override
  late final GeneratedColumn<int> q1Millis = GeneratedColumn<int>(
      'q1_millis', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _q2MillisMeta =
      const VerificationMeta('q2Millis');
  @override
  late final GeneratedColumn<int> q2Millis = GeneratedColumn<int>(
      'q2_millis', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _q3MillisMeta =
      const VerificationMeta('q3Millis');
  @override
  late final GeneratedColumn<int> q3Millis = GeneratedColumn<int>(
      'q3_millis', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [season, round, driverId, position, q1Millis, q2Millis, q3Millis];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qualifying_results';
  @override
  VerificationContext validateIntegrity(
      Insertable<QualifyingResultRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('driver_id')) {
      context.handle(_driverIdMeta,
          driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta));
    } else if (isInserting) {
      context.missing(_driverIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('q1_millis')) {
      context.handle(_q1MillisMeta,
          q1Millis.isAcceptableOrUnknown(data['q1_millis']!, _q1MillisMeta));
    }
    if (data.containsKey('q2_millis')) {
      context.handle(_q2MillisMeta,
          q2Millis.isAcceptableOrUnknown(data['q2_millis']!, _q2MillisMeta));
    }
    if (data.containsKey('q3_millis')) {
      context.handle(_q3MillisMeta,
          q3Millis.isAcceptableOrUnknown(data['q3_millis']!, _q3MillisMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {season, round, driverId};
  @override
  QualifyingResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QualifyingResultRow(
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      driverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}driver_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      q1Millis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}q1_millis']),
      q2Millis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}q2_millis']),
      q3Millis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}q3_millis']),
    );
  }

  @override
  $QualifyingResultsTable createAlias(String alias) {
    return $QualifyingResultsTable(attachedDatabase, alias);
  }
}

class QualifyingResultRow extends DataClass
    implements Insertable<QualifyingResultRow> {
  final int season;
  final int round;
  final String driverId;
  final int position;
  final int? q1Millis;
  final int? q2Millis;
  final int? q3Millis;
  const QualifyingResultRow(
      {required this.season,
      required this.round,
      required this.driverId,
      required this.position,
      this.q1Millis,
      this.q2Millis,
      this.q3Millis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['driver_id'] = Variable<String>(driverId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || q1Millis != null) {
      map['q1_millis'] = Variable<int>(q1Millis);
    }
    if (!nullToAbsent || q2Millis != null) {
      map['q2_millis'] = Variable<int>(q2Millis);
    }
    if (!nullToAbsent || q3Millis != null) {
      map['q3_millis'] = Variable<int>(q3Millis);
    }
    return map;
  }

  QualifyingResultsCompanion toCompanion(bool nullToAbsent) {
    return QualifyingResultsCompanion(
      season: Value(season),
      round: Value(round),
      driverId: Value(driverId),
      position: Value(position),
      q1Millis: q1Millis == null && nullToAbsent
          ? const Value.absent()
          : Value(q1Millis),
      q2Millis: q2Millis == null && nullToAbsent
          ? const Value.absent()
          : Value(q2Millis),
      q3Millis: q3Millis == null && nullToAbsent
          ? const Value.absent()
          : Value(q3Millis),
    );
  }

  factory QualifyingResultRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QualifyingResultRow(
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      driverId: serializer.fromJson<String>(json['driverId']),
      position: serializer.fromJson<int>(json['position']),
      q1Millis: serializer.fromJson<int?>(json['q1Millis']),
      q2Millis: serializer.fromJson<int?>(json['q2Millis']),
      q3Millis: serializer.fromJson<int?>(json['q3Millis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'driverId': serializer.toJson<String>(driverId),
      'position': serializer.toJson<int>(position),
      'q1Millis': serializer.toJson<int?>(q1Millis),
      'q2Millis': serializer.toJson<int?>(q2Millis),
      'q3Millis': serializer.toJson<int?>(q3Millis),
    };
  }

  QualifyingResultRow copyWith(
          {int? season,
          int? round,
          String? driverId,
          int? position,
          Value<int?> q1Millis = const Value.absent(),
          Value<int?> q2Millis = const Value.absent(),
          Value<int?> q3Millis = const Value.absent()}) =>
      QualifyingResultRow(
        season: season ?? this.season,
        round: round ?? this.round,
        driverId: driverId ?? this.driverId,
        position: position ?? this.position,
        q1Millis: q1Millis.present ? q1Millis.value : this.q1Millis,
        q2Millis: q2Millis.present ? q2Millis.value : this.q2Millis,
        q3Millis: q3Millis.present ? q3Millis.value : this.q3Millis,
      );
  QualifyingResultRow copyWithCompanion(QualifyingResultsCompanion data) {
    return QualifyingResultRow(
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      position: data.position.present ? data.position.value : this.position,
      q1Millis: data.q1Millis.present ? data.q1Millis.value : this.q1Millis,
      q2Millis: data.q2Millis.present ? data.q2Millis.value : this.q2Millis,
      q3Millis: data.q3Millis.present ? data.q3Millis.value : this.q3Millis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QualifyingResultRow(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('driverId: $driverId, ')
          ..write('position: $position, ')
          ..write('q1Millis: $q1Millis, ')
          ..write('q2Millis: $q2Millis, ')
          ..write('q3Millis: $q3Millis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      season, round, driverId, position, q1Millis, q2Millis, q3Millis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QualifyingResultRow &&
          other.season == this.season &&
          other.round == this.round &&
          other.driverId == this.driverId &&
          other.position == this.position &&
          other.q1Millis == this.q1Millis &&
          other.q2Millis == this.q2Millis &&
          other.q3Millis == this.q3Millis);
}

class QualifyingResultsCompanion extends UpdateCompanion<QualifyingResultRow> {
  final Value<int> season;
  final Value<int> round;
  final Value<String> driverId;
  final Value<int> position;
  final Value<int?> q1Millis;
  final Value<int?> q2Millis;
  final Value<int?> q3Millis;
  final Value<int> rowid;
  const QualifyingResultsCompanion({
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.driverId = const Value.absent(),
    this.position = const Value.absent(),
    this.q1Millis = const Value.absent(),
    this.q2Millis = const Value.absent(),
    this.q3Millis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QualifyingResultsCompanion.insert({
    required int season,
    required int round,
    required String driverId,
    required int position,
    this.q1Millis = const Value.absent(),
    this.q2Millis = const Value.absent(),
    this.q3Millis = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : season = Value(season),
        round = Value(round),
        driverId = Value(driverId),
        position = Value(position);
  static Insertable<QualifyingResultRow> custom({
    Expression<int>? season,
    Expression<int>? round,
    Expression<String>? driverId,
    Expression<int>? position,
    Expression<int>? q1Millis,
    Expression<int>? q2Millis,
    Expression<int>? q3Millis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (driverId != null) 'driver_id': driverId,
      if (position != null) 'position': position,
      if (q1Millis != null) 'q1_millis': q1Millis,
      if (q2Millis != null) 'q2_millis': q2Millis,
      if (q3Millis != null) 'q3_millis': q3Millis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QualifyingResultsCompanion copyWith(
      {Value<int>? season,
      Value<int>? round,
      Value<String>? driverId,
      Value<int>? position,
      Value<int?>? q1Millis,
      Value<int?>? q2Millis,
      Value<int?>? q3Millis,
      Value<int>? rowid}) {
    return QualifyingResultsCompanion(
      season: season ?? this.season,
      round: round ?? this.round,
      driverId: driverId ?? this.driverId,
      position: position ?? this.position,
      q1Millis: q1Millis ?? this.q1Millis,
      q2Millis: q2Millis ?? this.q2Millis,
      q3Millis: q3Millis ?? this.q3Millis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (driverId.present) {
      map['driver_id'] = Variable<String>(driverId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (q1Millis.present) {
      map['q1_millis'] = Variable<int>(q1Millis.value);
    }
    if (q2Millis.present) {
      map['q2_millis'] = Variable<int>(q2Millis.value);
    }
    if (q3Millis.present) {
      map['q3_millis'] = Variable<int>(q3Millis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QualifyingResultsCompanion(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('driverId: $driverId, ')
          ..write('position: $position, ')
          ..write('q1Millis: $q1Millis, ')
          ..write('q2Millis: $q2Millis, ')
          ..write('q3Millis: $q3Millis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionLapsTable extends SessionLaps
    with TableInfo<$SessionLapsTable, SessionLapRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionLapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sessionKeyMeta =
      const VerificationMeta('sessionKey');
  @override
  late final GeneratedColumn<String> sessionKey = GeneratedColumn<String>(
      'session_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _driverIdMeta =
      const VerificationMeta('driverId');
  @override
  late final GeneratedColumn<String> driverId = GeneratedColumn<String>(
      'driver_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bestStintAvgMsMeta =
      const VerificationMeta('bestStintAvgMs');
  @override
  late final GeneratedColumn<double> bestStintAvgMs = GeneratedColumn<double>(
      'best_stint_avg_ms', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _top2StintsAvgMsMeta =
      const VerificationMeta('top2StintsAvgMs');
  @override
  late final GeneratedColumn<double> top2StintsAvgMs = GeneratedColumn<double>(
      'top2_stints_avg_ms', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bestLapMsMeta =
      const VerificationMeta('bestLapMs');
  @override
  late final GeneratedColumn<double> bestLapMs = GeneratedColumn<double>(
      'best_lap_ms', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lapCountMeta =
      const VerificationMeta('lapCount');
  @override
  late final GeneratedColumn<int> lapCount = GeneratedColumn<int>(
      'lap_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        season,
        round,
        sessionKey,
        driverId,
        bestStintAvgMs,
        top2StintsAvgMs,
        bestLapMs,
        lapCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_laps';
  @override
  VerificationContext validateIntegrity(Insertable<SessionLapRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('session_key')) {
      context.handle(
          _sessionKeyMeta,
          sessionKey.isAcceptableOrUnknown(
              data['session_key']!, _sessionKeyMeta));
    } else if (isInserting) {
      context.missing(_sessionKeyMeta);
    }
    if (data.containsKey('driver_id')) {
      context.handle(_driverIdMeta,
          driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta));
    } else if (isInserting) {
      context.missing(_driverIdMeta);
    }
    if (data.containsKey('best_stint_avg_ms')) {
      context.handle(
          _bestStintAvgMsMeta,
          bestStintAvgMs.isAcceptableOrUnknown(
              data['best_stint_avg_ms']!, _bestStintAvgMsMeta));
    } else if (isInserting) {
      context.missing(_bestStintAvgMsMeta);
    }
    if (data.containsKey('top2_stints_avg_ms')) {
      context.handle(
          _top2StintsAvgMsMeta,
          top2StintsAvgMs.isAcceptableOrUnknown(
              data['top2_stints_avg_ms']!, _top2StintsAvgMsMeta));
    } else if (isInserting) {
      context.missing(_top2StintsAvgMsMeta);
    }
    if (data.containsKey('best_lap_ms')) {
      context.handle(
          _bestLapMsMeta,
          bestLapMs.isAcceptableOrUnknown(
              data['best_lap_ms']!, _bestLapMsMeta));
    } else if (isInserting) {
      context.missing(_bestLapMsMeta);
    }
    if (data.containsKey('lap_count')) {
      context.handle(_lapCountMeta,
          lapCount.isAcceptableOrUnknown(data['lap_count']!, _lapCountMeta));
    } else if (isInserting) {
      context.missing(_lapCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {season, round, sessionKey, driverId};
  @override
  SessionLapRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionLapRow(
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      sessionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_key'])!,
      driverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}driver_id'])!,
      bestStintAvgMs: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}best_stint_avg_ms'])!,
      top2StintsAvgMs: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}top2_stints_avg_ms'])!,
      bestLapMs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}best_lap_ms'])!,
      lapCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lap_count'])!,
    );
  }

  @override
  $SessionLapsTable createAlias(String alias) {
    return $SessionLapsTable(attachedDatabase, alias);
  }
}

class SessionLapRow extends DataClass implements Insertable<SessionLapRow> {
  final int season;
  final int round;
  final String sessionKey;
  final String driverId;
  final double bestStintAvgMs;
  final double top2StintsAvgMs;
  final double bestLapMs;
  final int lapCount;
  const SessionLapRow(
      {required this.season,
      required this.round,
      required this.sessionKey,
      required this.driverId,
      required this.bestStintAvgMs,
      required this.top2StintsAvgMs,
      required this.bestLapMs,
      required this.lapCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['session_key'] = Variable<String>(sessionKey);
    map['driver_id'] = Variable<String>(driverId);
    map['best_stint_avg_ms'] = Variable<double>(bestStintAvgMs);
    map['top2_stints_avg_ms'] = Variable<double>(top2StintsAvgMs);
    map['best_lap_ms'] = Variable<double>(bestLapMs);
    map['lap_count'] = Variable<int>(lapCount);
    return map;
  }

  SessionLapsCompanion toCompanion(bool nullToAbsent) {
    return SessionLapsCompanion(
      season: Value(season),
      round: Value(round),
      sessionKey: Value(sessionKey),
      driverId: Value(driverId),
      bestStintAvgMs: Value(bestStintAvgMs),
      top2StintsAvgMs: Value(top2StintsAvgMs),
      bestLapMs: Value(bestLapMs),
      lapCount: Value(lapCount),
    );
  }

  factory SessionLapRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionLapRow(
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      sessionKey: serializer.fromJson<String>(json['sessionKey']),
      driverId: serializer.fromJson<String>(json['driverId']),
      bestStintAvgMs: serializer.fromJson<double>(json['bestStintAvgMs']),
      top2StintsAvgMs: serializer.fromJson<double>(json['top2StintsAvgMs']),
      bestLapMs: serializer.fromJson<double>(json['bestLapMs']),
      lapCount: serializer.fromJson<int>(json['lapCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'sessionKey': serializer.toJson<String>(sessionKey),
      'driverId': serializer.toJson<String>(driverId),
      'bestStintAvgMs': serializer.toJson<double>(bestStintAvgMs),
      'top2StintsAvgMs': serializer.toJson<double>(top2StintsAvgMs),
      'bestLapMs': serializer.toJson<double>(bestLapMs),
      'lapCount': serializer.toJson<int>(lapCount),
    };
  }

  SessionLapRow copyWith(
          {int? season,
          int? round,
          String? sessionKey,
          String? driverId,
          double? bestStintAvgMs,
          double? top2StintsAvgMs,
          double? bestLapMs,
          int? lapCount}) =>
      SessionLapRow(
        season: season ?? this.season,
        round: round ?? this.round,
        sessionKey: sessionKey ?? this.sessionKey,
        driverId: driverId ?? this.driverId,
        bestStintAvgMs: bestStintAvgMs ?? this.bestStintAvgMs,
        top2StintsAvgMs: top2StintsAvgMs ?? this.top2StintsAvgMs,
        bestLapMs: bestLapMs ?? this.bestLapMs,
        lapCount: lapCount ?? this.lapCount,
      );
  SessionLapRow copyWithCompanion(SessionLapsCompanion data) {
    return SessionLapRow(
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      sessionKey:
          data.sessionKey.present ? data.sessionKey.value : this.sessionKey,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      bestStintAvgMs: data.bestStintAvgMs.present
          ? data.bestStintAvgMs.value
          : this.bestStintAvgMs,
      top2StintsAvgMs: data.top2StintsAvgMs.present
          ? data.top2StintsAvgMs.value
          : this.top2StintsAvgMs,
      bestLapMs: data.bestLapMs.present ? data.bestLapMs.value : this.bestLapMs,
      lapCount: data.lapCount.present ? data.lapCount.value : this.lapCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionLapRow(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('sessionKey: $sessionKey, ')
          ..write('driverId: $driverId, ')
          ..write('bestStintAvgMs: $bestStintAvgMs, ')
          ..write('top2StintsAvgMs: $top2StintsAvgMs, ')
          ..write('bestLapMs: $bestLapMs, ')
          ..write('lapCount: $lapCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(season, round, sessionKey, driverId,
      bestStintAvgMs, top2StintsAvgMs, bestLapMs, lapCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionLapRow &&
          other.season == this.season &&
          other.round == this.round &&
          other.sessionKey == this.sessionKey &&
          other.driverId == this.driverId &&
          other.bestStintAvgMs == this.bestStintAvgMs &&
          other.top2StintsAvgMs == this.top2StintsAvgMs &&
          other.bestLapMs == this.bestLapMs &&
          other.lapCount == this.lapCount);
}

class SessionLapsCompanion extends UpdateCompanion<SessionLapRow> {
  final Value<int> season;
  final Value<int> round;
  final Value<String> sessionKey;
  final Value<String> driverId;
  final Value<double> bestStintAvgMs;
  final Value<double> top2StintsAvgMs;
  final Value<double> bestLapMs;
  final Value<int> lapCount;
  final Value<int> rowid;
  const SessionLapsCompanion({
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.sessionKey = const Value.absent(),
    this.driverId = const Value.absent(),
    this.bestStintAvgMs = const Value.absent(),
    this.top2StintsAvgMs = const Value.absent(),
    this.bestLapMs = const Value.absent(),
    this.lapCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionLapsCompanion.insert({
    required int season,
    required int round,
    required String sessionKey,
    required String driverId,
    required double bestStintAvgMs,
    required double top2StintsAvgMs,
    required double bestLapMs,
    required int lapCount,
    this.rowid = const Value.absent(),
  })  : season = Value(season),
        round = Value(round),
        sessionKey = Value(sessionKey),
        driverId = Value(driverId),
        bestStintAvgMs = Value(bestStintAvgMs),
        top2StintsAvgMs = Value(top2StintsAvgMs),
        bestLapMs = Value(bestLapMs),
        lapCount = Value(lapCount);
  static Insertable<SessionLapRow> custom({
    Expression<int>? season,
    Expression<int>? round,
    Expression<String>? sessionKey,
    Expression<String>? driverId,
    Expression<double>? bestStintAvgMs,
    Expression<double>? top2StintsAvgMs,
    Expression<double>? bestLapMs,
    Expression<int>? lapCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (sessionKey != null) 'session_key': sessionKey,
      if (driverId != null) 'driver_id': driverId,
      if (bestStintAvgMs != null) 'best_stint_avg_ms': bestStintAvgMs,
      if (top2StintsAvgMs != null) 'top2_stints_avg_ms': top2StintsAvgMs,
      if (bestLapMs != null) 'best_lap_ms': bestLapMs,
      if (lapCount != null) 'lap_count': lapCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionLapsCompanion copyWith(
      {Value<int>? season,
      Value<int>? round,
      Value<String>? sessionKey,
      Value<String>? driverId,
      Value<double>? bestStintAvgMs,
      Value<double>? top2StintsAvgMs,
      Value<double>? bestLapMs,
      Value<int>? lapCount,
      Value<int>? rowid}) {
    return SessionLapsCompanion(
      season: season ?? this.season,
      round: round ?? this.round,
      sessionKey: sessionKey ?? this.sessionKey,
      driverId: driverId ?? this.driverId,
      bestStintAvgMs: bestStintAvgMs ?? this.bestStintAvgMs,
      top2StintsAvgMs: top2StintsAvgMs ?? this.top2StintsAvgMs,
      bestLapMs: bestLapMs ?? this.bestLapMs,
      lapCount: lapCount ?? this.lapCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (sessionKey.present) {
      map['session_key'] = Variable<String>(sessionKey.value);
    }
    if (driverId.present) {
      map['driver_id'] = Variable<String>(driverId.value);
    }
    if (bestStintAvgMs.present) {
      map['best_stint_avg_ms'] = Variable<double>(bestStintAvgMs.value);
    }
    if (top2StintsAvgMs.present) {
      map['top2_stints_avg_ms'] = Variable<double>(top2StintsAvgMs.value);
    }
    if (bestLapMs.present) {
      map['best_lap_ms'] = Variable<double>(bestLapMs.value);
    }
    if (lapCount.present) {
      map['lap_count'] = Variable<int>(lapCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionLapsCompanion(')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('sessionKey: $sessionKey, ')
          ..write('driverId: $driverId, ')
          ..write('bestStintAvgMs: $bestStintAvgMs, ')
          ..write('top2StintsAvgMs: $top2StintsAvgMs, ')
          ..write('bestLapMs: $bestLapMs, ')
          ..write('lapCount: $lapCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FantasyPricesTable extends FantasyPrices
    with TableInfo<$FantasyPricesTable, FantasyPriceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FantasyPricesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetTypeMeta =
      const VerificationMeta('assetType');
  @override
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
      'asset_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _priceMillionsMeta =
      const VerificationMeta('priceMillions');
  @override
  late final GeneratedColumn<double> priceMillions = GeneratedColumn<double>(
      'price_millions', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [assetId, assetType, season, round, priceMillions];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fantasy_prices';
  @override
  VerificationContext validateIntegrity(Insertable<FantasyPriceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('asset_type')) {
      context.handle(_assetTypeMeta,
          assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta));
    } else if (isInserting) {
      context.missing(_assetTypeMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('price_millions')) {
      context.handle(
          _priceMillionsMeta,
          priceMillions.isAcceptableOrUnknown(
              data['price_millions']!, _priceMillionsMeta));
    } else if (isInserting) {
      context.missing(_priceMillionsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId, assetType, season, round};
  @override
  FantasyPriceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FantasyPriceRow(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      assetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_type'])!,
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      priceMillions: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_millions'])!,
    );
  }

  @override
  $FantasyPricesTable createAlias(String alias) {
    return $FantasyPricesTable(attachedDatabase, alias);
  }
}

class FantasyPriceRow extends DataClass implements Insertable<FantasyPriceRow> {
  final String assetId;
  final String assetType;
  final int season;
  final int round;
  final double priceMillions;
  const FantasyPriceRow(
      {required this.assetId,
      required this.assetType,
      required this.season,
      required this.round,
      required this.priceMillions});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['asset_type'] = Variable<String>(assetType);
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['price_millions'] = Variable<double>(priceMillions);
    return map;
  }

  FantasyPricesCompanion toCompanion(bool nullToAbsent) {
    return FantasyPricesCompanion(
      assetId: Value(assetId),
      assetType: Value(assetType),
      season: Value(season),
      round: Value(round),
      priceMillions: Value(priceMillions),
    );
  }

  factory FantasyPriceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FantasyPriceRow(
      assetId: serializer.fromJson<String>(json['assetId']),
      assetType: serializer.fromJson<String>(json['assetType']),
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      priceMillions: serializer.fromJson<double>(json['priceMillions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'assetType': serializer.toJson<String>(assetType),
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'priceMillions': serializer.toJson<double>(priceMillions),
    };
  }

  FantasyPriceRow copyWith(
          {String? assetId,
          String? assetType,
          int? season,
          int? round,
          double? priceMillions}) =>
      FantasyPriceRow(
        assetId: assetId ?? this.assetId,
        assetType: assetType ?? this.assetType,
        season: season ?? this.season,
        round: round ?? this.round,
        priceMillions: priceMillions ?? this.priceMillions,
      );
  FantasyPriceRow copyWithCompanion(FantasyPricesCompanion data) {
    return FantasyPriceRow(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      priceMillions: data.priceMillions.present
          ? data.priceMillions.value
          : this.priceMillions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FantasyPriceRow(')
          ..write('assetId: $assetId, ')
          ..write('assetType: $assetType, ')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('priceMillions: $priceMillions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(assetId, assetType, season, round, priceMillions);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FantasyPriceRow &&
          other.assetId == this.assetId &&
          other.assetType == this.assetType &&
          other.season == this.season &&
          other.round == this.round &&
          other.priceMillions == this.priceMillions);
}

class FantasyPricesCompanion extends UpdateCompanion<FantasyPriceRow> {
  final Value<String> assetId;
  final Value<String> assetType;
  final Value<int> season;
  final Value<int> round;
  final Value<double> priceMillions;
  final Value<int> rowid;
  const FantasyPricesCompanion({
    this.assetId = const Value.absent(),
    this.assetType = const Value.absent(),
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.priceMillions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FantasyPricesCompanion.insert({
    required String assetId,
    required String assetType,
    required int season,
    required int round,
    required double priceMillions,
    this.rowid = const Value.absent(),
  })  : assetId = Value(assetId),
        assetType = Value(assetType),
        season = Value(season),
        round = Value(round),
        priceMillions = Value(priceMillions);
  static Insertable<FantasyPriceRow> custom({
    Expression<String>? assetId,
    Expression<String>? assetType,
    Expression<int>? season,
    Expression<int>? round,
    Expression<double>? priceMillions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (assetType != null) 'asset_type': assetType,
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (priceMillions != null) 'price_millions': priceMillions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FantasyPricesCompanion copyWith(
      {Value<String>? assetId,
      Value<String>? assetType,
      Value<int>? season,
      Value<int>? round,
      Value<double>? priceMillions,
      Value<int>? rowid}) {
    return FantasyPricesCompanion(
      assetId: assetId ?? this.assetId,
      assetType: assetType ?? this.assetType,
      season: season ?? this.season,
      round: round ?? this.round,
      priceMillions: priceMillions ?? this.priceMillions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (priceMillions.present) {
      map['price_millions'] = Variable<double>(priceMillions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FantasyPricesCompanion(')
          ..write('assetId: $assetId, ')
          ..write('assetType: $assetType, ')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('priceMillions: $priceMillions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FantasyPointsTableTable extends FantasyPointsTable
    with TableInfo<$FantasyPointsTableTable, FantasyPointsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FantasyPointsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetTypeMeta =
      const VerificationMeta('assetType');
  @override
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
      'asset_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
      'points', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [assetId, assetType, season, round, points];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fantasy_points_table';
  @override
  VerificationContext validateIntegrity(Insertable<FantasyPointsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('asset_type')) {
      context.handle(_assetTypeMeta,
          assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta));
    } else if (isInserting) {
      context.missing(_assetTypeMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta,
          points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId, assetType, season, round};
  @override
  FantasyPointsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FantasyPointsRow(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      assetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_type'])!,
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      points: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}points'])!,
    );
  }

  @override
  $FantasyPointsTableTable createAlias(String alias) {
    return $FantasyPointsTableTable(attachedDatabase, alias);
  }
}

class FantasyPointsRow extends DataClass
    implements Insertable<FantasyPointsRow> {
  final String assetId;
  final String assetType;
  final int season;
  final int round;
  final int points;
  const FantasyPointsRow(
      {required this.assetId,
      required this.assetType,
      required this.season,
      required this.round,
      required this.points});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['asset_type'] = Variable<String>(assetType);
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['points'] = Variable<int>(points);
    return map;
  }

  FantasyPointsTableCompanion toCompanion(bool nullToAbsent) {
    return FantasyPointsTableCompanion(
      assetId: Value(assetId),
      assetType: Value(assetType),
      season: Value(season),
      round: Value(round),
      points: Value(points),
    );
  }

  factory FantasyPointsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FantasyPointsRow(
      assetId: serializer.fromJson<String>(json['assetId']),
      assetType: serializer.fromJson<String>(json['assetType']),
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      points: serializer.fromJson<int>(json['points']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'assetType': serializer.toJson<String>(assetType),
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'points': serializer.toJson<int>(points),
    };
  }

  FantasyPointsRow copyWith(
          {String? assetId,
          String? assetType,
          int? season,
          int? round,
          int? points}) =>
      FantasyPointsRow(
        assetId: assetId ?? this.assetId,
        assetType: assetType ?? this.assetType,
        season: season ?? this.season,
        round: round ?? this.round,
        points: points ?? this.points,
      );
  FantasyPointsRow copyWithCompanion(FantasyPointsTableCompanion data) {
    return FantasyPointsRow(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      points: data.points.present ? data.points.value : this.points,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FantasyPointsRow(')
          ..write('assetId: $assetId, ')
          ..write('assetType: $assetType, ')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('points: $points')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(assetId, assetType, season, round, points);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FantasyPointsRow &&
          other.assetId == this.assetId &&
          other.assetType == this.assetType &&
          other.season == this.season &&
          other.round == this.round &&
          other.points == this.points);
}

class FantasyPointsTableCompanion extends UpdateCompanion<FantasyPointsRow> {
  final Value<String> assetId;
  final Value<String> assetType;
  final Value<int> season;
  final Value<int> round;
  final Value<int> points;
  final Value<int> rowid;
  const FantasyPointsTableCompanion({
    this.assetId = const Value.absent(),
    this.assetType = const Value.absent(),
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.points = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FantasyPointsTableCompanion.insert({
    required String assetId,
    required String assetType,
    required int season,
    required int round,
    required int points,
    this.rowid = const Value.absent(),
  })  : assetId = Value(assetId),
        assetType = Value(assetType),
        season = Value(season),
        round = Value(round),
        points = Value(points);
  static Insertable<FantasyPointsRow> custom({
    Expression<String>? assetId,
    Expression<String>? assetType,
    Expression<int>? season,
    Expression<int>? round,
    Expression<int>? points,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (assetType != null) 'asset_type': assetType,
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (points != null) 'points': points,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FantasyPointsTableCompanion copyWith(
      {Value<String>? assetId,
      Value<String>? assetType,
      Value<int>? season,
      Value<int>? round,
      Value<int>? points,
      Value<int>? rowid}) {
    return FantasyPointsTableCompanion(
      assetId: assetId ?? this.assetId,
      assetType: assetType ?? this.assetType,
      season: season ?? this.season,
      round: round ?? this.round,
      points: points ?? this.points,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FantasyPointsTableCompanion(')
          ..write('assetId: $assetId, ')
          ..write('assetType: $assetType, ')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('points: $points, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MyTeamTableTable extends MyTeamTable
    with TableInfo<$MyTeamTableTable, MyTeamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MyTeamTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _driverIdsCsvMeta =
      const VerificationMeta('driverIdsCsv');
  @override
  late final GeneratedColumn<String> driverIdsCsv = GeneratedColumn<String>(
      'driver_ids_csv', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _constructorIdsCsvMeta =
      const VerificationMeta('constructorIdsCsv');
  @override
  late final GeneratedColumn<String> constructorIdsCsv =
      GeneratedColumn<String>('constructor_ids_csv', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remainingBudgetMillionsMeta =
      const VerificationMeta('remainingBudgetMillions');
  @override
  late final GeneratedColumn<double> remainingBudgetMillions =
      GeneratedColumn<double>('remaining_budget_millions', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _boostedDriverIdMeta =
      const VerificationMeta('boostedDriverId');
  @override
  late final GeneratedColumn<String> boostedDriverId = GeneratedColumn<String>(
      'boosted_driver_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chipsUsedCsvMeta =
      const VerificationMeta('chipsUsedCsv');
  @override
  late final GeneratedColumn<String> chipsUsedCsv = GeneratedColumn<String>(
      'chips_used_csv', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        driverIdsCsv,
        constructorIdsCsv,
        remainingBudgetMillions,
        boostedDriverId,
        source,
        chipsUsedCsv
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'my_team_table';
  @override
  VerificationContext validateIntegrity(Insertable<MyTeamRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('driver_ids_csv')) {
      context.handle(
          _driverIdsCsvMeta,
          driverIdsCsv.isAcceptableOrUnknown(
              data['driver_ids_csv']!, _driverIdsCsvMeta));
    } else if (isInserting) {
      context.missing(_driverIdsCsvMeta);
    }
    if (data.containsKey('constructor_ids_csv')) {
      context.handle(
          _constructorIdsCsvMeta,
          constructorIdsCsv.isAcceptableOrUnknown(
              data['constructor_ids_csv']!, _constructorIdsCsvMeta));
    } else if (isInserting) {
      context.missing(_constructorIdsCsvMeta);
    }
    if (data.containsKey('remaining_budget_millions')) {
      context.handle(
          _remainingBudgetMillionsMeta,
          remainingBudgetMillions.isAcceptableOrUnknown(
              data['remaining_budget_millions']!,
              _remainingBudgetMillionsMeta));
    } else if (isInserting) {
      context.missing(_remainingBudgetMillionsMeta);
    }
    if (data.containsKey('boosted_driver_id')) {
      context.handle(
          _boostedDriverIdMeta,
          boostedDriverId.isAcceptableOrUnknown(
              data['boosted_driver_id']!, _boostedDriverIdMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('chips_used_csv')) {
      context.handle(
          _chipsUsedCsvMeta,
          chipsUsedCsv.isAcceptableOrUnknown(
              data['chips_used_csv']!, _chipsUsedCsvMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MyTeamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MyTeamRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      driverIdsCsv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}driver_ids_csv'])!,
      constructorIdsCsv: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}constructor_ids_csv'])!,
      remainingBudgetMillions: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}remaining_budget_millions'])!,
      boostedDriverId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}boosted_driver_id']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      chipsUsedCsv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chips_used_csv'])!,
    );
  }

  @override
  $MyTeamTableTable createAlias(String alias) {
    return $MyTeamTableTable(attachedDatabase, alias);
  }
}

class MyTeamRow extends DataClass implements Insertable<MyTeamRow> {
  final int id;
  final String driverIdsCsv;
  final String constructorIdsCsv;
  final double remainingBudgetMillions;
  final String? boostedDriverId;
  final String source;
  final String chipsUsedCsv;
  const MyTeamRow(
      {required this.id,
      required this.driverIdsCsv,
      required this.constructorIdsCsv,
      required this.remainingBudgetMillions,
      this.boostedDriverId,
      required this.source,
      required this.chipsUsedCsv});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['driver_ids_csv'] = Variable<String>(driverIdsCsv);
    map['constructor_ids_csv'] = Variable<String>(constructorIdsCsv);
    map['remaining_budget_millions'] =
        Variable<double>(remainingBudgetMillions);
    if (!nullToAbsent || boostedDriverId != null) {
      map['boosted_driver_id'] = Variable<String>(boostedDriverId);
    }
    map['source'] = Variable<String>(source);
    map['chips_used_csv'] = Variable<String>(chipsUsedCsv);
    return map;
  }

  MyTeamTableCompanion toCompanion(bool nullToAbsent) {
    return MyTeamTableCompanion(
      id: Value(id),
      driverIdsCsv: Value(driverIdsCsv),
      constructorIdsCsv: Value(constructorIdsCsv),
      remainingBudgetMillions: Value(remainingBudgetMillions),
      boostedDriverId: boostedDriverId == null && nullToAbsent
          ? const Value.absent()
          : Value(boostedDriverId),
      source: Value(source),
      chipsUsedCsv: Value(chipsUsedCsv),
    );
  }

  factory MyTeamRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyTeamRow(
      id: serializer.fromJson<int>(json['id']),
      driverIdsCsv: serializer.fromJson<String>(json['driverIdsCsv']),
      constructorIdsCsv: serializer.fromJson<String>(json['constructorIdsCsv']),
      remainingBudgetMillions:
          serializer.fromJson<double>(json['remainingBudgetMillions']),
      boostedDriverId: serializer.fromJson<String?>(json['boostedDriverId']),
      source: serializer.fromJson<String>(json['source']),
      chipsUsedCsv: serializer.fromJson<String>(json['chipsUsedCsv']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'driverIdsCsv': serializer.toJson<String>(driverIdsCsv),
      'constructorIdsCsv': serializer.toJson<String>(constructorIdsCsv),
      'remainingBudgetMillions':
          serializer.toJson<double>(remainingBudgetMillions),
      'boostedDriverId': serializer.toJson<String?>(boostedDriverId),
      'source': serializer.toJson<String>(source),
      'chipsUsedCsv': serializer.toJson<String>(chipsUsedCsv),
    };
  }

  MyTeamRow copyWith(
          {int? id,
          String? driverIdsCsv,
          String? constructorIdsCsv,
          double? remainingBudgetMillions,
          Value<String?> boostedDriverId = const Value.absent(),
          String? source,
          String? chipsUsedCsv}) =>
      MyTeamRow(
        id: id ?? this.id,
        driverIdsCsv: driverIdsCsv ?? this.driverIdsCsv,
        constructorIdsCsv: constructorIdsCsv ?? this.constructorIdsCsv,
        remainingBudgetMillions:
            remainingBudgetMillions ?? this.remainingBudgetMillions,
        boostedDriverId: boostedDriverId.present
            ? boostedDriverId.value
            : this.boostedDriverId,
        source: source ?? this.source,
        chipsUsedCsv: chipsUsedCsv ?? this.chipsUsedCsv,
      );
  MyTeamRow copyWithCompanion(MyTeamTableCompanion data) {
    return MyTeamRow(
      id: data.id.present ? data.id.value : this.id,
      driverIdsCsv: data.driverIdsCsv.present
          ? data.driverIdsCsv.value
          : this.driverIdsCsv,
      constructorIdsCsv: data.constructorIdsCsv.present
          ? data.constructorIdsCsv.value
          : this.constructorIdsCsv,
      remainingBudgetMillions: data.remainingBudgetMillions.present
          ? data.remainingBudgetMillions.value
          : this.remainingBudgetMillions,
      boostedDriverId: data.boostedDriverId.present
          ? data.boostedDriverId.value
          : this.boostedDriverId,
      source: data.source.present ? data.source.value : this.source,
      chipsUsedCsv: data.chipsUsedCsv.present
          ? data.chipsUsedCsv.value
          : this.chipsUsedCsv,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MyTeamRow(')
          ..write('id: $id, ')
          ..write('driverIdsCsv: $driverIdsCsv, ')
          ..write('constructorIdsCsv: $constructorIdsCsv, ')
          ..write('remainingBudgetMillions: $remainingBudgetMillions, ')
          ..write('boostedDriverId: $boostedDriverId, ')
          ..write('source: $source, ')
          ..write('chipsUsedCsv: $chipsUsedCsv')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, driverIdsCsv, constructorIdsCsv,
      remainingBudgetMillions, boostedDriverId, source, chipsUsedCsv);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyTeamRow &&
          other.id == this.id &&
          other.driverIdsCsv == this.driverIdsCsv &&
          other.constructorIdsCsv == this.constructorIdsCsv &&
          other.remainingBudgetMillions == this.remainingBudgetMillions &&
          other.boostedDriverId == this.boostedDriverId &&
          other.source == this.source &&
          other.chipsUsedCsv == this.chipsUsedCsv);
}

class MyTeamTableCompanion extends UpdateCompanion<MyTeamRow> {
  final Value<int> id;
  final Value<String> driverIdsCsv;
  final Value<String> constructorIdsCsv;
  final Value<double> remainingBudgetMillions;
  final Value<String?> boostedDriverId;
  final Value<String> source;
  final Value<String> chipsUsedCsv;
  const MyTeamTableCompanion({
    this.id = const Value.absent(),
    this.driverIdsCsv = const Value.absent(),
    this.constructorIdsCsv = const Value.absent(),
    this.remainingBudgetMillions = const Value.absent(),
    this.boostedDriverId = const Value.absent(),
    this.source = const Value.absent(),
    this.chipsUsedCsv = const Value.absent(),
  });
  MyTeamTableCompanion.insert({
    this.id = const Value.absent(),
    required String driverIdsCsv,
    required String constructorIdsCsv,
    required double remainingBudgetMillions,
    this.boostedDriverId = const Value.absent(),
    required String source,
    this.chipsUsedCsv = const Value.absent(),
  })  : driverIdsCsv = Value(driverIdsCsv),
        constructorIdsCsv = Value(constructorIdsCsv),
        remainingBudgetMillions = Value(remainingBudgetMillions),
        source = Value(source);
  static Insertable<MyTeamRow> custom({
    Expression<int>? id,
    Expression<String>? driverIdsCsv,
    Expression<String>? constructorIdsCsv,
    Expression<double>? remainingBudgetMillions,
    Expression<String>? boostedDriverId,
    Expression<String>? source,
    Expression<String>? chipsUsedCsv,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (driverIdsCsv != null) 'driver_ids_csv': driverIdsCsv,
      if (constructorIdsCsv != null) 'constructor_ids_csv': constructorIdsCsv,
      if (remainingBudgetMillions != null)
        'remaining_budget_millions': remainingBudgetMillions,
      if (boostedDriverId != null) 'boosted_driver_id': boostedDriverId,
      if (source != null) 'source': source,
      if (chipsUsedCsv != null) 'chips_used_csv': chipsUsedCsv,
    });
  }

  MyTeamTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? driverIdsCsv,
      Value<String>? constructorIdsCsv,
      Value<double>? remainingBudgetMillions,
      Value<String?>? boostedDriverId,
      Value<String>? source,
      Value<String>? chipsUsedCsv}) {
    return MyTeamTableCompanion(
      id: id ?? this.id,
      driverIdsCsv: driverIdsCsv ?? this.driverIdsCsv,
      constructorIdsCsv: constructorIdsCsv ?? this.constructorIdsCsv,
      remainingBudgetMillions:
          remainingBudgetMillions ?? this.remainingBudgetMillions,
      boostedDriverId: boostedDriverId ?? this.boostedDriverId,
      source: source ?? this.source,
      chipsUsedCsv: chipsUsedCsv ?? this.chipsUsedCsv,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (driverIdsCsv.present) {
      map['driver_ids_csv'] = Variable<String>(driverIdsCsv.value);
    }
    if (constructorIdsCsv.present) {
      map['constructor_ids_csv'] = Variable<String>(constructorIdsCsv.value);
    }
    if (remainingBudgetMillions.present) {
      map['remaining_budget_millions'] =
          Variable<double>(remainingBudgetMillions.value);
    }
    if (boostedDriverId.present) {
      map['boosted_driver_id'] = Variable<String>(boostedDriverId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (chipsUsedCsv.present) {
      map['chips_used_csv'] = Variable<String>(chipsUsedCsv.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MyTeamTableCompanion(')
          ..write('id: $id, ')
          ..write('driverIdsCsv: $driverIdsCsv, ')
          ..write('constructorIdsCsv: $constructorIdsCsv, ')
          ..write('remainingBudgetMillions: $remainingBudgetMillions, ')
          ..write('boostedDriverId: $boostedDriverId, ')
          ..write('source: $source, ')
          ..write('chipsUsedCsv: $chipsUsedCsv')
          ..write(')'))
        .toString();
  }
}

class $PredictionsCacheTable extends PredictionsCache
    with TableInfo<$PredictionsCacheTable, PredictionCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PredictionsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetTypeMeta =
      const VerificationMeta('assetType');
  @override
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
      'asset_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
      'season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
      'round', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expectedPointsMeta =
      const VerificationMeta('expectedPoints');
  @override
  late final GeneratedColumn<double> expectedPoints = GeneratedColumn<double>(
      'expected_points', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _winProbabilityMeta =
      const VerificationMeta('winProbability');
  @override
  late final GeneratedColumn<double> winProbability = GeneratedColumn<double>(
      'win_probability', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _podiumProbabilityMeta =
      const VerificationMeta('podiumProbability');
  @override
  late final GeneratedColumn<double> podiumProbability =
      GeneratedColumn<double>('podium_probability', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _top10ProbabilityMeta =
      const VerificationMeta('top10Probability');
  @override
  late final GeneratedColumn<double> top10Probability = GeneratedColumn<double>(
      'top10_probability', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _priceMillionsMeta =
      const VerificationMeta('priceMillions');
  @override
  late final GeneratedColumn<double> priceMillions = GeneratedColumn<double>(
      'price_millions', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _breakdownJsonMeta =
      const VerificationMeta('breakdownJson');
  @override
  late final GeneratedColumn<String> breakdownJson = GeneratedColumn<String>(
      'breakdown_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _computedAtMeta =
      const VerificationMeta('computedAt');
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
      'computed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        assetId,
        assetType,
        season,
        round,
        expectedPoints,
        winProbability,
        podiumProbability,
        top10Probability,
        priceMillions,
        breakdownJson,
        computedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'predictions_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PredictionCacheRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('asset_type')) {
      context.handle(_assetTypeMeta,
          assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta));
    } else if (isInserting) {
      context.missing(_assetTypeMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
          _roundMeta, round.isAcceptableOrUnknown(data['round']!, _roundMeta));
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('expected_points')) {
      context.handle(
          _expectedPointsMeta,
          expectedPoints.isAcceptableOrUnknown(
              data['expected_points']!, _expectedPointsMeta));
    } else if (isInserting) {
      context.missing(_expectedPointsMeta);
    }
    if (data.containsKey('win_probability')) {
      context.handle(
          _winProbabilityMeta,
          winProbability.isAcceptableOrUnknown(
              data['win_probability']!, _winProbabilityMeta));
    } else if (isInserting) {
      context.missing(_winProbabilityMeta);
    }
    if (data.containsKey('podium_probability')) {
      context.handle(
          _podiumProbabilityMeta,
          podiumProbability.isAcceptableOrUnknown(
              data['podium_probability']!, _podiumProbabilityMeta));
    } else if (isInserting) {
      context.missing(_podiumProbabilityMeta);
    }
    if (data.containsKey('top10_probability')) {
      context.handle(
          _top10ProbabilityMeta,
          top10Probability.isAcceptableOrUnknown(
              data['top10_probability']!, _top10ProbabilityMeta));
    } else if (isInserting) {
      context.missing(_top10ProbabilityMeta);
    }
    if (data.containsKey('price_millions')) {
      context.handle(
          _priceMillionsMeta,
          priceMillions.isAcceptableOrUnknown(
              data['price_millions']!, _priceMillionsMeta));
    } else if (isInserting) {
      context.missing(_priceMillionsMeta);
    }
    if (data.containsKey('breakdown_json')) {
      context.handle(
          _breakdownJsonMeta,
          breakdownJson.isAcceptableOrUnknown(
              data['breakdown_json']!, _breakdownJsonMeta));
    } else if (isInserting) {
      context.missing(_breakdownJsonMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
          _computedAtMeta,
          computedAt.isAcceptableOrUnknown(
              data['computed_at']!, _computedAtMeta));
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId, assetType, season, round};
  @override
  PredictionCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PredictionCacheRow(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      assetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_type'])!,
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season'])!,
      round: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round'])!,
      expectedPoints: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}expected_points'])!,
      winProbability: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}win_probability'])!,
      podiumProbability: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}podium_probability'])!,
      top10Probability: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}top10_probability'])!,
      priceMillions: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_millions'])!,
      breakdownJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}breakdown_json'])!,
      computedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}computed_at'])!,
    );
  }

  @override
  $PredictionsCacheTable createAlias(String alias) {
    return $PredictionsCacheTable(attachedDatabase, alias);
  }
}

class PredictionCacheRow extends DataClass
    implements Insertable<PredictionCacheRow> {
  final String assetId;
  final String assetType;
  final int season;
  final int round;
  final double expectedPoints;
  final double winProbability;
  final double podiumProbability;
  final double top10Probability;
  final double priceMillions;
  final String breakdownJson;
  final DateTime computedAt;
  const PredictionCacheRow(
      {required this.assetId,
      required this.assetType,
      required this.season,
      required this.round,
      required this.expectedPoints,
      required this.winProbability,
      required this.podiumProbability,
      required this.top10Probability,
      required this.priceMillions,
      required this.breakdownJson,
      required this.computedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['asset_type'] = Variable<String>(assetType);
    map['season'] = Variable<int>(season);
    map['round'] = Variable<int>(round);
    map['expected_points'] = Variable<double>(expectedPoints);
    map['win_probability'] = Variable<double>(winProbability);
    map['podium_probability'] = Variable<double>(podiumProbability);
    map['top10_probability'] = Variable<double>(top10Probability);
    map['price_millions'] = Variable<double>(priceMillions);
    map['breakdown_json'] = Variable<String>(breakdownJson);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  PredictionsCacheCompanion toCompanion(bool nullToAbsent) {
    return PredictionsCacheCompanion(
      assetId: Value(assetId),
      assetType: Value(assetType),
      season: Value(season),
      round: Value(round),
      expectedPoints: Value(expectedPoints),
      winProbability: Value(winProbability),
      podiumProbability: Value(podiumProbability),
      top10Probability: Value(top10Probability),
      priceMillions: Value(priceMillions),
      breakdownJson: Value(breakdownJson),
      computedAt: Value(computedAt),
    );
  }

  factory PredictionCacheRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PredictionCacheRow(
      assetId: serializer.fromJson<String>(json['assetId']),
      assetType: serializer.fromJson<String>(json['assetType']),
      season: serializer.fromJson<int>(json['season']),
      round: serializer.fromJson<int>(json['round']),
      expectedPoints: serializer.fromJson<double>(json['expectedPoints']),
      winProbability: serializer.fromJson<double>(json['winProbability']),
      podiumProbability: serializer.fromJson<double>(json['podiumProbability']),
      top10Probability: serializer.fromJson<double>(json['top10Probability']),
      priceMillions: serializer.fromJson<double>(json['priceMillions']),
      breakdownJson: serializer.fromJson<String>(json['breakdownJson']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'assetType': serializer.toJson<String>(assetType),
      'season': serializer.toJson<int>(season),
      'round': serializer.toJson<int>(round),
      'expectedPoints': serializer.toJson<double>(expectedPoints),
      'winProbability': serializer.toJson<double>(winProbability),
      'podiumProbability': serializer.toJson<double>(podiumProbability),
      'top10Probability': serializer.toJson<double>(top10Probability),
      'priceMillions': serializer.toJson<double>(priceMillions),
      'breakdownJson': serializer.toJson<String>(breakdownJson),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  PredictionCacheRow copyWith(
          {String? assetId,
          String? assetType,
          int? season,
          int? round,
          double? expectedPoints,
          double? winProbability,
          double? podiumProbability,
          double? top10Probability,
          double? priceMillions,
          String? breakdownJson,
          DateTime? computedAt}) =>
      PredictionCacheRow(
        assetId: assetId ?? this.assetId,
        assetType: assetType ?? this.assetType,
        season: season ?? this.season,
        round: round ?? this.round,
        expectedPoints: expectedPoints ?? this.expectedPoints,
        winProbability: winProbability ?? this.winProbability,
        podiumProbability: podiumProbability ?? this.podiumProbability,
        top10Probability: top10Probability ?? this.top10Probability,
        priceMillions: priceMillions ?? this.priceMillions,
        breakdownJson: breakdownJson ?? this.breakdownJson,
        computedAt: computedAt ?? this.computedAt,
      );
  PredictionCacheRow copyWithCompanion(PredictionsCacheCompanion data) {
    return PredictionCacheRow(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      season: data.season.present ? data.season.value : this.season,
      round: data.round.present ? data.round.value : this.round,
      expectedPoints: data.expectedPoints.present
          ? data.expectedPoints.value
          : this.expectedPoints,
      winProbability: data.winProbability.present
          ? data.winProbability.value
          : this.winProbability,
      podiumProbability: data.podiumProbability.present
          ? data.podiumProbability.value
          : this.podiumProbability,
      top10Probability: data.top10Probability.present
          ? data.top10Probability.value
          : this.top10Probability,
      priceMillions: data.priceMillions.present
          ? data.priceMillions.value
          : this.priceMillions,
      breakdownJson: data.breakdownJson.present
          ? data.breakdownJson.value
          : this.breakdownJson,
      computedAt:
          data.computedAt.present ? data.computedAt.value : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PredictionCacheRow(')
          ..write('assetId: $assetId, ')
          ..write('assetType: $assetType, ')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('expectedPoints: $expectedPoints, ')
          ..write('winProbability: $winProbability, ')
          ..write('podiumProbability: $podiumProbability, ')
          ..write('top10Probability: $top10Probability, ')
          ..write('priceMillions: $priceMillions, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      assetId,
      assetType,
      season,
      round,
      expectedPoints,
      winProbability,
      podiumProbability,
      top10Probability,
      priceMillions,
      breakdownJson,
      computedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PredictionCacheRow &&
          other.assetId == this.assetId &&
          other.assetType == this.assetType &&
          other.season == this.season &&
          other.round == this.round &&
          other.expectedPoints == this.expectedPoints &&
          other.winProbability == this.winProbability &&
          other.podiumProbability == this.podiumProbability &&
          other.top10Probability == this.top10Probability &&
          other.priceMillions == this.priceMillions &&
          other.breakdownJson == this.breakdownJson &&
          other.computedAt == this.computedAt);
}

class PredictionsCacheCompanion extends UpdateCompanion<PredictionCacheRow> {
  final Value<String> assetId;
  final Value<String> assetType;
  final Value<int> season;
  final Value<int> round;
  final Value<double> expectedPoints;
  final Value<double> winProbability;
  final Value<double> podiumProbability;
  final Value<double> top10Probability;
  final Value<double> priceMillions;
  final Value<String> breakdownJson;
  final Value<DateTime> computedAt;
  final Value<int> rowid;
  const PredictionsCacheCompanion({
    this.assetId = const Value.absent(),
    this.assetType = const Value.absent(),
    this.season = const Value.absent(),
    this.round = const Value.absent(),
    this.expectedPoints = const Value.absent(),
    this.winProbability = const Value.absent(),
    this.podiumProbability = const Value.absent(),
    this.top10Probability = const Value.absent(),
    this.priceMillions = const Value.absent(),
    this.breakdownJson = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PredictionsCacheCompanion.insert({
    required String assetId,
    required String assetType,
    required int season,
    required int round,
    required double expectedPoints,
    required double winProbability,
    required double podiumProbability,
    required double top10Probability,
    required double priceMillions,
    required String breakdownJson,
    required DateTime computedAt,
    this.rowid = const Value.absent(),
  })  : assetId = Value(assetId),
        assetType = Value(assetType),
        season = Value(season),
        round = Value(round),
        expectedPoints = Value(expectedPoints),
        winProbability = Value(winProbability),
        podiumProbability = Value(podiumProbability),
        top10Probability = Value(top10Probability),
        priceMillions = Value(priceMillions),
        breakdownJson = Value(breakdownJson),
        computedAt = Value(computedAt);
  static Insertable<PredictionCacheRow> custom({
    Expression<String>? assetId,
    Expression<String>? assetType,
    Expression<int>? season,
    Expression<int>? round,
    Expression<double>? expectedPoints,
    Expression<double>? winProbability,
    Expression<double>? podiumProbability,
    Expression<double>? top10Probability,
    Expression<double>? priceMillions,
    Expression<String>? breakdownJson,
    Expression<DateTime>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (assetType != null) 'asset_type': assetType,
      if (season != null) 'season': season,
      if (round != null) 'round': round,
      if (expectedPoints != null) 'expected_points': expectedPoints,
      if (winProbability != null) 'win_probability': winProbability,
      if (podiumProbability != null) 'podium_probability': podiumProbability,
      if (top10Probability != null) 'top10_probability': top10Probability,
      if (priceMillions != null) 'price_millions': priceMillions,
      if (breakdownJson != null) 'breakdown_json': breakdownJson,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PredictionsCacheCompanion copyWith(
      {Value<String>? assetId,
      Value<String>? assetType,
      Value<int>? season,
      Value<int>? round,
      Value<double>? expectedPoints,
      Value<double>? winProbability,
      Value<double>? podiumProbability,
      Value<double>? top10Probability,
      Value<double>? priceMillions,
      Value<String>? breakdownJson,
      Value<DateTime>? computedAt,
      Value<int>? rowid}) {
    return PredictionsCacheCompanion(
      assetId: assetId ?? this.assetId,
      assetType: assetType ?? this.assetType,
      season: season ?? this.season,
      round: round ?? this.round,
      expectedPoints: expectedPoints ?? this.expectedPoints,
      winProbability: winProbability ?? this.winProbability,
      podiumProbability: podiumProbability ?? this.podiumProbability,
      top10Probability: top10Probability ?? this.top10Probability,
      priceMillions: priceMillions ?? this.priceMillions,
      breakdownJson: breakdownJson ?? this.breakdownJson,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (expectedPoints.present) {
      map['expected_points'] = Variable<double>(expectedPoints.value);
    }
    if (winProbability.present) {
      map['win_probability'] = Variable<double>(winProbability.value);
    }
    if (podiumProbability.present) {
      map['podium_probability'] = Variable<double>(podiumProbability.value);
    }
    if (top10Probability.present) {
      map['top10_probability'] = Variable<double>(top10Probability.value);
    }
    if (priceMillions.present) {
      map['price_millions'] = Variable<double>(priceMillions.value);
    }
    if (breakdownJson.present) {
      map['breakdown_json'] = Variable<String>(breakdownJson.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PredictionsCacheCompanion(')
          ..write('assetId: $assetId, ')
          ..write('assetType: $assetType, ')
          ..write('season: $season, ')
          ..write('round: $round, ')
          ..write('expectedPoints: $expectedPoints, ')
          ..write('winProbability: $winProbability, ')
          ..write('podiumProbability: $podiumProbability, ')
          ..write('top10Probability: $top10Probability, ')
          ..write('priceMillions: $priceMillions, ')
          ..write('breakdownJson: $breakdownJson, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DriversTable drivers = $DriversTable(this);
  late final $ConstructorsTable constructors = $ConstructorsTable(this);
  late final $RacesTable races = $RacesTable(this);
  late final $ResultsTable results = $ResultsTable(this);
  late final $QualifyingResultsTable qualifyingResults =
      $QualifyingResultsTable(this);
  late final $SessionLapsTable sessionLaps = $SessionLapsTable(this);
  late final $FantasyPricesTable fantasyPrices = $FantasyPricesTable(this);
  late final $FantasyPointsTableTable fantasyPointsTable =
      $FantasyPointsTableTable(this);
  late final $MyTeamTableTable myTeamTable = $MyTeamTableTable(this);
  late final $PredictionsCacheTable predictionsCache =
      $PredictionsCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        drivers,
        constructors,
        races,
        results,
        qualifyingResults,
        sessionLaps,
        fantasyPrices,
        fantasyPointsTable,
        myTeamTable,
        predictionsCache
      ];
}

typedef $$DriversTableCreateCompanionBuilder = DriversCompanion Function({
  required String id,
  required String code,
  required String givenName,
  required String familyName,
  required String constructorId,
  Value<int?> number,
  Value<int> rowid,
});
typedef $$DriversTableUpdateCompanionBuilder = DriversCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> givenName,
  Value<String> familyName,
  Value<String> constructorId,
  Value<int?> number,
  Value<int> rowid,
});

class $$DriversTableFilterComposer
    extends Composer<_$AppDatabase, $DriversTable> {
  $$DriversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get givenName => $composableBuilder(
      column: $table.givenName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get familyName => $composableBuilder(
      column: $table.familyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get constructorId => $composableBuilder(
      column: $table.constructorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));
}

class $$DriversTableOrderingComposer
    extends Composer<_$AppDatabase, $DriversTable> {
  $$DriversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get givenName => $composableBuilder(
      column: $table.givenName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get familyName => $composableBuilder(
      column: $table.familyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get constructorId => $composableBuilder(
      column: $table.constructorId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));
}

class $$DriversTableAnnotationComposer
    extends Composer<_$AppDatabase, $DriversTable> {
  $$DriversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get givenName =>
      $composableBuilder(column: $table.givenName, builder: (column) => column);

  GeneratedColumn<String> get familyName => $composableBuilder(
      column: $table.familyName, builder: (column) => column);

  GeneratedColumn<String> get constructorId => $composableBuilder(
      column: $table.constructorId, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);
}

class $$DriversTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DriversTable,
    DriverRow,
    $$DriversTableFilterComposer,
    $$DriversTableOrderingComposer,
    $$DriversTableAnnotationComposer,
    $$DriversTableCreateCompanionBuilder,
    $$DriversTableUpdateCompanionBuilder,
    (DriverRow, BaseReferences<_$AppDatabase, $DriversTable, DriverRow>),
    DriverRow,
    PrefetchHooks Function()> {
  $$DriversTableTableManager(_$AppDatabase db, $DriversTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> givenName = const Value.absent(),
            Value<String> familyName = const Value.absent(),
            Value<String> constructorId = const Value.absent(),
            Value<int?> number = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriversCompanion(
            id: id,
            code: code,
            givenName: givenName,
            familyName: familyName,
            constructorId: constructorId,
            number: number,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String code,
            required String givenName,
            required String familyName,
            required String constructorId,
            Value<int?> number = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriversCompanion.insert(
            id: id,
            code: code,
            givenName: givenName,
            familyName: familyName,
            constructorId: constructorId,
            number: number,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DriversTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DriversTable,
    DriverRow,
    $$DriversTableFilterComposer,
    $$DriversTableOrderingComposer,
    $$DriversTableAnnotationComposer,
    $$DriversTableCreateCompanionBuilder,
    $$DriversTableUpdateCompanionBuilder,
    (DriverRow, BaseReferences<_$AppDatabase, $DriversTable, DriverRow>),
    DriverRow,
    PrefetchHooks Function()>;
typedef $$ConstructorsTableCreateCompanionBuilder = ConstructorsCompanion
    Function({
  required String id,
  required String name,
  required String nationality,
  Value<int> rowid,
});
typedef $$ConstructorsTableUpdateCompanionBuilder = ConstructorsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> nationality,
  Value<int> rowid,
});

class $$ConstructorsTableFilterComposer
    extends Composer<_$AppDatabase, $ConstructorsTable> {
  $$ConstructorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nationality => $composableBuilder(
      column: $table.nationality, builder: (column) => ColumnFilters(column));
}

class $$ConstructorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConstructorsTable> {
  $$ConstructorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nationality => $composableBuilder(
      column: $table.nationality, builder: (column) => ColumnOrderings(column));
}

class $$ConstructorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConstructorsTable> {
  $$ConstructorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nationality => $composableBuilder(
      column: $table.nationality, builder: (column) => column);
}

class $$ConstructorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConstructorsTable,
    ConstructorRow,
    $$ConstructorsTableFilterComposer,
    $$ConstructorsTableOrderingComposer,
    $$ConstructorsTableAnnotationComposer,
    $$ConstructorsTableCreateCompanionBuilder,
    $$ConstructorsTableUpdateCompanionBuilder,
    (
      ConstructorRow,
      BaseReferences<_$AppDatabase, $ConstructorsTable, ConstructorRow>
    ),
    ConstructorRow,
    PrefetchHooks Function()> {
  $$ConstructorsTableTableManager(_$AppDatabase db, $ConstructorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConstructorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConstructorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConstructorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> nationality = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConstructorsCompanion(
            id: id,
            name: name,
            nationality: nationality,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String nationality,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConstructorsCompanion.insert(
            id: id,
            name: name,
            nationality: nationality,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConstructorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConstructorsTable,
    ConstructorRow,
    $$ConstructorsTableFilterComposer,
    $$ConstructorsTableOrderingComposer,
    $$ConstructorsTableAnnotationComposer,
    $$ConstructorsTableCreateCompanionBuilder,
    $$ConstructorsTableUpdateCompanionBuilder,
    (
      ConstructorRow,
      BaseReferences<_$AppDatabase, $ConstructorsTable, ConstructorRow>
    ),
    ConstructorRow,
    PrefetchHooks Function()>;
typedef $$RacesTableCreateCompanionBuilder = RacesCompanion Function({
  required int season,
  required int round,
  required String raceName,
  required String circuitId,
  required String circuitName,
  required String country,
  required DateTime date,
  Value<bool> hasSprint,
  Value<int> rowid,
});
typedef $$RacesTableUpdateCompanionBuilder = RacesCompanion Function({
  Value<int> season,
  Value<int> round,
  Value<String> raceName,
  Value<String> circuitId,
  Value<String> circuitName,
  Value<String> country,
  Value<DateTime> date,
  Value<bool> hasSprint,
  Value<int> rowid,
});

class $$RacesTableFilterComposer extends Composer<_$AppDatabase, $RacesTable> {
  $$RacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get raceName => $composableBuilder(
      column: $table.raceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get circuitId => $composableBuilder(
      column: $table.circuitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get circuitName => $composableBuilder(
      column: $table.circuitName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasSprint => $composableBuilder(
      column: $table.hasSprint, builder: (column) => ColumnFilters(column));
}

class $$RacesTableOrderingComposer
    extends Composer<_$AppDatabase, $RacesTable> {
  $$RacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get raceName => $composableBuilder(
      column: $table.raceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get circuitId => $composableBuilder(
      column: $table.circuitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get circuitName => $composableBuilder(
      column: $table.circuitName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasSprint => $composableBuilder(
      column: $table.hasSprint, builder: (column) => ColumnOrderings(column));
}

class $$RacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RacesTable> {
  $$RacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<String> get raceName =>
      $composableBuilder(column: $table.raceName, builder: (column) => column);

  GeneratedColumn<String> get circuitId =>
      $composableBuilder(column: $table.circuitId, builder: (column) => column);

  GeneratedColumn<String> get circuitName => $composableBuilder(
      column: $table.circuitName, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get hasSprint =>
      $composableBuilder(column: $table.hasSprint, builder: (column) => column);
}

class $$RacesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RacesTable,
    RaceRow,
    $$RacesTableFilterComposer,
    $$RacesTableOrderingComposer,
    $$RacesTableAnnotationComposer,
    $$RacesTableCreateCompanionBuilder,
    $$RacesTableUpdateCompanionBuilder,
    (RaceRow, BaseReferences<_$AppDatabase, $RacesTable, RaceRow>),
    RaceRow,
    PrefetchHooks Function()> {
  $$RacesTableTableManager(_$AppDatabase db, $RacesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<String> raceName = const Value.absent(),
            Value<String> circuitId = const Value.absent(),
            Value<String> circuitName = const Value.absent(),
            Value<String> country = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<bool> hasSprint = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RacesCompanion(
            season: season,
            round: round,
            raceName: raceName,
            circuitId: circuitId,
            circuitName: circuitName,
            country: country,
            date: date,
            hasSprint: hasSprint,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int season,
            required int round,
            required String raceName,
            required String circuitId,
            required String circuitName,
            required String country,
            required DateTime date,
            Value<bool> hasSprint = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RacesCompanion.insert(
            season: season,
            round: round,
            raceName: raceName,
            circuitId: circuitId,
            circuitName: circuitName,
            country: country,
            date: date,
            hasSprint: hasSprint,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RacesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RacesTable,
    RaceRow,
    $$RacesTableFilterComposer,
    $$RacesTableOrderingComposer,
    $$RacesTableAnnotationComposer,
    $$RacesTableCreateCompanionBuilder,
    $$RacesTableUpdateCompanionBuilder,
    (RaceRow, BaseReferences<_$AppDatabase, $RacesTable, RaceRow>),
    RaceRow,
    PrefetchHooks Function()>;
typedef $$ResultsTableCreateCompanionBuilder = ResultsCompanion Function({
  required int season,
  required int round,
  required String driverId,
  required String constructorId,
  required int gridPosition,
  Value<int?> finishPosition,
  required String status,
  Value<bool> fastestLap,
  Value<int> rowid,
});
typedef $$ResultsTableUpdateCompanionBuilder = ResultsCompanion Function({
  Value<int> season,
  Value<int> round,
  Value<String> driverId,
  Value<String> constructorId,
  Value<int> gridPosition,
  Value<int?> finishPosition,
  Value<String> status,
  Value<bool> fastestLap,
  Value<int> rowid,
});

class $$ResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ResultsTable> {
  $$ResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driverId => $composableBuilder(
      column: $table.driverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get constructorId => $composableBuilder(
      column: $table.constructorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gridPosition => $composableBuilder(
      column: $table.gridPosition, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get finishPosition => $composableBuilder(
      column: $table.finishPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get fastestLap => $composableBuilder(
      column: $table.fastestLap, builder: (column) => ColumnFilters(column));
}

class $$ResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ResultsTable> {
  $$ResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driverId => $composableBuilder(
      column: $table.driverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get constructorId => $composableBuilder(
      column: $table.constructorId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gridPosition => $composableBuilder(
      column: $table.gridPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get finishPosition => $composableBuilder(
      column: $table.finishPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get fastestLap => $composableBuilder(
      column: $table.fastestLap, builder: (column) => ColumnOrderings(column));
}

class $$ResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResultsTable> {
  $$ResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<String> get driverId =>
      $composableBuilder(column: $table.driverId, builder: (column) => column);

  GeneratedColumn<String> get constructorId => $composableBuilder(
      column: $table.constructorId, builder: (column) => column);

  GeneratedColumn<int> get gridPosition => $composableBuilder(
      column: $table.gridPosition, builder: (column) => column);

  GeneratedColumn<int> get finishPosition => $composableBuilder(
      column: $table.finishPosition, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get fastestLap => $composableBuilder(
      column: $table.fastestLap, builder: (column) => column);
}

class $$ResultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ResultsTable,
    ResultRow,
    $$ResultsTableFilterComposer,
    $$ResultsTableOrderingComposer,
    $$ResultsTableAnnotationComposer,
    $$ResultsTableCreateCompanionBuilder,
    $$ResultsTableUpdateCompanionBuilder,
    (ResultRow, BaseReferences<_$AppDatabase, $ResultsTable, ResultRow>),
    ResultRow,
    PrefetchHooks Function()> {
  $$ResultsTableTableManager(_$AppDatabase db, $ResultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<String> driverId = const Value.absent(),
            Value<String> constructorId = const Value.absent(),
            Value<int> gridPosition = const Value.absent(),
            Value<int?> finishPosition = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> fastestLap = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResultsCompanion(
            season: season,
            round: round,
            driverId: driverId,
            constructorId: constructorId,
            gridPosition: gridPosition,
            finishPosition: finishPosition,
            status: status,
            fastestLap: fastestLap,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int season,
            required int round,
            required String driverId,
            required String constructorId,
            required int gridPosition,
            Value<int?> finishPosition = const Value.absent(),
            required String status,
            Value<bool> fastestLap = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResultsCompanion.insert(
            season: season,
            round: round,
            driverId: driverId,
            constructorId: constructorId,
            gridPosition: gridPosition,
            finishPosition: finishPosition,
            status: status,
            fastestLap: fastestLap,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ResultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ResultsTable,
    ResultRow,
    $$ResultsTableFilterComposer,
    $$ResultsTableOrderingComposer,
    $$ResultsTableAnnotationComposer,
    $$ResultsTableCreateCompanionBuilder,
    $$ResultsTableUpdateCompanionBuilder,
    (ResultRow, BaseReferences<_$AppDatabase, $ResultsTable, ResultRow>),
    ResultRow,
    PrefetchHooks Function()>;
typedef $$QualifyingResultsTableCreateCompanionBuilder
    = QualifyingResultsCompanion Function({
  required int season,
  required int round,
  required String driverId,
  required int position,
  Value<int?> q1Millis,
  Value<int?> q2Millis,
  Value<int?> q3Millis,
  Value<int> rowid,
});
typedef $$QualifyingResultsTableUpdateCompanionBuilder
    = QualifyingResultsCompanion Function({
  Value<int> season,
  Value<int> round,
  Value<String> driverId,
  Value<int> position,
  Value<int?> q1Millis,
  Value<int?> q2Millis,
  Value<int?> q3Millis,
  Value<int> rowid,
});

class $$QualifyingResultsTableFilterComposer
    extends Composer<_$AppDatabase, $QualifyingResultsTable> {
  $$QualifyingResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driverId => $composableBuilder(
      column: $table.driverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get q1Millis => $composableBuilder(
      column: $table.q1Millis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get q2Millis => $composableBuilder(
      column: $table.q2Millis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get q3Millis => $composableBuilder(
      column: $table.q3Millis, builder: (column) => ColumnFilters(column));
}

class $$QualifyingResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $QualifyingResultsTable> {
  $$QualifyingResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driverId => $composableBuilder(
      column: $table.driverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get q1Millis => $composableBuilder(
      column: $table.q1Millis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get q2Millis => $composableBuilder(
      column: $table.q2Millis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get q3Millis => $composableBuilder(
      column: $table.q3Millis, builder: (column) => ColumnOrderings(column));
}

class $$QualifyingResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QualifyingResultsTable> {
  $$QualifyingResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<String> get driverId =>
      $composableBuilder(column: $table.driverId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get q1Millis =>
      $composableBuilder(column: $table.q1Millis, builder: (column) => column);

  GeneratedColumn<int> get q2Millis =>
      $composableBuilder(column: $table.q2Millis, builder: (column) => column);

  GeneratedColumn<int> get q3Millis =>
      $composableBuilder(column: $table.q3Millis, builder: (column) => column);
}

class $$QualifyingResultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QualifyingResultsTable,
    QualifyingResultRow,
    $$QualifyingResultsTableFilterComposer,
    $$QualifyingResultsTableOrderingComposer,
    $$QualifyingResultsTableAnnotationComposer,
    $$QualifyingResultsTableCreateCompanionBuilder,
    $$QualifyingResultsTableUpdateCompanionBuilder,
    (
      QualifyingResultRow,
      BaseReferences<_$AppDatabase, $QualifyingResultsTable,
          QualifyingResultRow>
    ),
    QualifyingResultRow,
    PrefetchHooks Function()> {
  $$QualifyingResultsTableTableManager(
      _$AppDatabase db, $QualifyingResultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QualifyingResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QualifyingResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QualifyingResultsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<String> driverId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int?> q1Millis = const Value.absent(),
            Value<int?> q2Millis = const Value.absent(),
            Value<int?> q3Millis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QualifyingResultsCompanion(
            season: season,
            round: round,
            driverId: driverId,
            position: position,
            q1Millis: q1Millis,
            q2Millis: q2Millis,
            q3Millis: q3Millis,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int season,
            required int round,
            required String driverId,
            required int position,
            Value<int?> q1Millis = const Value.absent(),
            Value<int?> q2Millis = const Value.absent(),
            Value<int?> q3Millis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QualifyingResultsCompanion.insert(
            season: season,
            round: round,
            driverId: driverId,
            position: position,
            q1Millis: q1Millis,
            q2Millis: q2Millis,
            q3Millis: q3Millis,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QualifyingResultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QualifyingResultsTable,
    QualifyingResultRow,
    $$QualifyingResultsTableFilterComposer,
    $$QualifyingResultsTableOrderingComposer,
    $$QualifyingResultsTableAnnotationComposer,
    $$QualifyingResultsTableCreateCompanionBuilder,
    $$QualifyingResultsTableUpdateCompanionBuilder,
    (
      QualifyingResultRow,
      BaseReferences<_$AppDatabase, $QualifyingResultsTable,
          QualifyingResultRow>
    ),
    QualifyingResultRow,
    PrefetchHooks Function()>;
typedef $$SessionLapsTableCreateCompanionBuilder = SessionLapsCompanion
    Function({
  required int season,
  required int round,
  required String sessionKey,
  required String driverId,
  required double bestStintAvgMs,
  required double top2StintsAvgMs,
  required double bestLapMs,
  required int lapCount,
  Value<int> rowid,
});
typedef $$SessionLapsTableUpdateCompanionBuilder = SessionLapsCompanion
    Function({
  Value<int> season,
  Value<int> round,
  Value<String> sessionKey,
  Value<String> driverId,
  Value<double> bestStintAvgMs,
  Value<double> top2StintsAvgMs,
  Value<double> bestLapMs,
  Value<int> lapCount,
  Value<int> rowid,
});

class $$SessionLapsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionLapsTable> {
  $$SessionLapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionKey => $composableBuilder(
      column: $table.sessionKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driverId => $composableBuilder(
      column: $table.driverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bestStintAvgMs => $composableBuilder(
      column: $table.bestStintAvgMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get top2StintsAvgMs => $composableBuilder(
      column: $table.top2StintsAvgMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bestLapMs => $composableBuilder(
      column: $table.bestLapMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapCount => $composableBuilder(
      column: $table.lapCount, builder: (column) => ColumnFilters(column));
}

class $$SessionLapsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionLapsTable> {
  $$SessionLapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionKey => $composableBuilder(
      column: $table.sessionKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driverId => $composableBuilder(
      column: $table.driverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bestStintAvgMs => $composableBuilder(
      column: $table.bestStintAvgMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get top2StintsAvgMs => $composableBuilder(
      column: $table.top2StintsAvgMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bestLapMs => $composableBuilder(
      column: $table.bestLapMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapCount => $composableBuilder(
      column: $table.lapCount, builder: (column) => ColumnOrderings(column));
}

class $$SessionLapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionLapsTable> {
  $$SessionLapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<String> get sessionKey => $composableBuilder(
      column: $table.sessionKey, builder: (column) => column);

  GeneratedColumn<String> get driverId =>
      $composableBuilder(column: $table.driverId, builder: (column) => column);

  GeneratedColumn<double> get bestStintAvgMs => $composableBuilder(
      column: $table.bestStintAvgMs, builder: (column) => column);

  GeneratedColumn<double> get top2StintsAvgMs => $composableBuilder(
      column: $table.top2StintsAvgMs, builder: (column) => column);

  GeneratedColumn<double> get bestLapMs =>
      $composableBuilder(column: $table.bestLapMs, builder: (column) => column);

  GeneratedColumn<int> get lapCount =>
      $composableBuilder(column: $table.lapCount, builder: (column) => column);
}

class $$SessionLapsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionLapsTable,
    SessionLapRow,
    $$SessionLapsTableFilterComposer,
    $$SessionLapsTableOrderingComposer,
    $$SessionLapsTableAnnotationComposer,
    $$SessionLapsTableCreateCompanionBuilder,
    $$SessionLapsTableUpdateCompanionBuilder,
    (
      SessionLapRow,
      BaseReferences<_$AppDatabase, $SessionLapsTable, SessionLapRow>
    ),
    SessionLapRow,
    PrefetchHooks Function()> {
  $$SessionLapsTableTableManager(_$AppDatabase db, $SessionLapsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionLapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionLapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionLapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<String> sessionKey = const Value.absent(),
            Value<String> driverId = const Value.absent(),
            Value<double> bestStintAvgMs = const Value.absent(),
            Value<double> top2StintsAvgMs = const Value.absent(),
            Value<double> bestLapMs = const Value.absent(),
            Value<int> lapCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionLapsCompanion(
            season: season,
            round: round,
            sessionKey: sessionKey,
            driverId: driverId,
            bestStintAvgMs: bestStintAvgMs,
            top2StintsAvgMs: top2StintsAvgMs,
            bestLapMs: bestLapMs,
            lapCount: lapCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int season,
            required int round,
            required String sessionKey,
            required String driverId,
            required double bestStintAvgMs,
            required double top2StintsAvgMs,
            required double bestLapMs,
            required int lapCount,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionLapsCompanion.insert(
            season: season,
            round: round,
            sessionKey: sessionKey,
            driverId: driverId,
            bestStintAvgMs: bestStintAvgMs,
            top2StintsAvgMs: top2StintsAvgMs,
            bestLapMs: bestLapMs,
            lapCount: lapCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionLapsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionLapsTable,
    SessionLapRow,
    $$SessionLapsTableFilterComposer,
    $$SessionLapsTableOrderingComposer,
    $$SessionLapsTableAnnotationComposer,
    $$SessionLapsTableCreateCompanionBuilder,
    $$SessionLapsTableUpdateCompanionBuilder,
    (
      SessionLapRow,
      BaseReferences<_$AppDatabase, $SessionLapsTable, SessionLapRow>
    ),
    SessionLapRow,
    PrefetchHooks Function()>;
typedef $$FantasyPricesTableCreateCompanionBuilder = FantasyPricesCompanion
    Function({
  required String assetId,
  required String assetType,
  required int season,
  required int round,
  required double priceMillions,
  Value<int> rowid,
});
typedef $$FantasyPricesTableUpdateCompanionBuilder = FantasyPricesCompanion
    Function({
  Value<String> assetId,
  Value<String> assetType,
  Value<int> season,
  Value<int> round,
  Value<double> priceMillions,
  Value<int> rowid,
});

class $$FantasyPricesTableFilterComposer
    extends Composer<_$AppDatabase, $FantasyPricesTable> {
  $$FantasyPricesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetType => $composableBuilder(
      column: $table.assetType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceMillions => $composableBuilder(
      column: $table.priceMillions, builder: (column) => ColumnFilters(column));
}

class $$FantasyPricesTableOrderingComposer
    extends Composer<_$AppDatabase, $FantasyPricesTable> {
  $$FantasyPricesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetType => $composableBuilder(
      column: $table.assetType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceMillions => $composableBuilder(
      column: $table.priceMillions,
      builder: (column) => ColumnOrderings(column));
}

class $$FantasyPricesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FantasyPricesTable> {
  $$FantasyPricesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetType =>
      $composableBuilder(column: $table.assetType, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<double> get priceMillions => $composableBuilder(
      column: $table.priceMillions, builder: (column) => column);
}

class $$FantasyPricesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FantasyPricesTable,
    FantasyPriceRow,
    $$FantasyPricesTableFilterComposer,
    $$FantasyPricesTableOrderingComposer,
    $$FantasyPricesTableAnnotationComposer,
    $$FantasyPricesTableCreateCompanionBuilder,
    $$FantasyPricesTableUpdateCompanionBuilder,
    (
      FantasyPriceRow,
      BaseReferences<_$AppDatabase, $FantasyPricesTable, FantasyPriceRow>
    ),
    FantasyPriceRow,
    PrefetchHooks Function()> {
  $$FantasyPricesTableTableManager(_$AppDatabase db, $FantasyPricesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FantasyPricesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FantasyPricesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FantasyPricesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> assetId = const Value.absent(),
            Value<String> assetType = const Value.absent(),
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<double> priceMillions = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FantasyPricesCompanion(
            assetId: assetId,
            assetType: assetType,
            season: season,
            round: round,
            priceMillions: priceMillions,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String assetId,
            required String assetType,
            required int season,
            required int round,
            required double priceMillions,
            Value<int> rowid = const Value.absent(),
          }) =>
              FantasyPricesCompanion.insert(
            assetId: assetId,
            assetType: assetType,
            season: season,
            round: round,
            priceMillions: priceMillions,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FantasyPricesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FantasyPricesTable,
    FantasyPriceRow,
    $$FantasyPricesTableFilterComposer,
    $$FantasyPricesTableOrderingComposer,
    $$FantasyPricesTableAnnotationComposer,
    $$FantasyPricesTableCreateCompanionBuilder,
    $$FantasyPricesTableUpdateCompanionBuilder,
    (
      FantasyPriceRow,
      BaseReferences<_$AppDatabase, $FantasyPricesTable, FantasyPriceRow>
    ),
    FantasyPriceRow,
    PrefetchHooks Function()>;
typedef $$FantasyPointsTableTableCreateCompanionBuilder
    = FantasyPointsTableCompanion Function({
  required String assetId,
  required String assetType,
  required int season,
  required int round,
  required int points,
  Value<int> rowid,
});
typedef $$FantasyPointsTableTableUpdateCompanionBuilder
    = FantasyPointsTableCompanion Function({
  Value<String> assetId,
  Value<String> assetType,
  Value<int> season,
  Value<int> round,
  Value<int> points,
  Value<int> rowid,
});

class $$FantasyPointsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FantasyPointsTableTable> {
  $$FantasyPointsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetType => $composableBuilder(
      column: $table.assetType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get points => $composableBuilder(
      column: $table.points, builder: (column) => ColumnFilters(column));
}

class $$FantasyPointsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FantasyPointsTableTable> {
  $$FantasyPointsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetType => $composableBuilder(
      column: $table.assetType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get points => $composableBuilder(
      column: $table.points, builder: (column) => ColumnOrderings(column));
}

class $$FantasyPointsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FantasyPointsTableTable> {
  $$FantasyPointsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetType =>
      $composableBuilder(column: $table.assetType, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);
}

class $$FantasyPointsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FantasyPointsTableTable,
    FantasyPointsRow,
    $$FantasyPointsTableTableFilterComposer,
    $$FantasyPointsTableTableOrderingComposer,
    $$FantasyPointsTableTableAnnotationComposer,
    $$FantasyPointsTableTableCreateCompanionBuilder,
    $$FantasyPointsTableTableUpdateCompanionBuilder,
    (
      FantasyPointsRow,
      BaseReferences<_$AppDatabase, $FantasyPointsTableTable, FantasyPointsRow>
    ),
    FantasyPointsRow,
    PrefetchHooks Function()> {
  $$FantasyPointsTableTableTableManager(
      _$AppDatabase db, $FantasyPointsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FantasyPointsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FantasyPointsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FantasyPointsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> assetId = const Value.absent(),
            Value<String> assetType = const Value.absent(),
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<int> points = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FantasyPointsTableCompanion(
            assetId: assetId,
            assetType: assetType,
            season: season,
            round: round,
            points: points,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String assetId,
            required String assetType,
            required int season,
            required int round,
            required int points,
            Value<int> rowid = const Value.absent(),
          }) =>
              FantasyPointsTableCompanion.insert(
            assetId: assetId,
            assetType: assetType,
            season: season,
            round: round,
            points: points,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FantasyPointsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FantasyPointsTableTable,
    FantasyPointsRow,
    $$FantasyPointsTableTableFilterComposer,
    $$FantasyPointsTableTableOrderingComposer,
    $$FantasyPointsTableTableAnnotationComposer,
    $$FantasyPointsTableTableCreateCompanionBuilder,
    $$FantasyPointsTableTableUpdateCompanionBuilder,
    (
      FantasyPointsRow,
      BaseReferences<_$AppDatabase, $FantasyPointsTableTable, FantasyPointsRow>
    ),
    FantasyPointsRow,
    PrefetchHooks Function()>;
typedef $$MyTeamTableTableCreateCompanionBuilder = MyTeamTableCompanion
    Function({
  Value<int> id,
  required String driverIdsCsv,
  required String constructorIdsCsv,
  required double remainingBudgetMillions,
  Value<String?> boostedDriverId,
  required String source,
  Value<String> chipsUsedCsv,
});
typedef $$MyTeamTableTableUpdateCompanionBuilder = MyTeamTableCompanion
    Function({
  Value<int> id,
  Value<String> driverIdsCsv,
  Value<String> constructorIdsCsv,
  Value<double> remainingBudgetMillions,
  Value<String?> boostedDriverId,
  Value<String> source,
  Value<String> chipsUsedCsv,
});

class $$MyTeamTableTableFilterComposer
    extends Composer<_$AppDatabase, $MyTeamTableTable> {
  $$MyTeamTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driverIdsCsv => $composableBuilder(
      column: $table.driverIdsCsv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get constructorIdsCsv => $composableBuilder(
      column: $table.constructorIdsCsv,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get remainingBudgetMillions => $composableBuilder(
      column: $table.remainingBudgetMillions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get boostedDriverId => $composableBuilder(
      column: $table.boostedDriverId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chipsUsedCsv => $composableBuilder(
      column: $table.chipsUsedCsv, builder: (column) => ColumnFilters(column));
}

class $$MyTeamTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MyTeamTableTable> {
  $$MyTeamTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driverIdsCsv => $composableBuilder(
      column: $table.driverIdsCsv,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get constructorIdsCsv => $composableBuilder(
      column: $table.constructorIdsCsv,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get remainingBudgetMillions => $composableBuilder(
      column: $table.remainingBudgetMillions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get boostedDriverId => $composableBuilder(
      column: $table.boostedDriverId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chipsUsedCsv => $composableBuilder(
      column: $table.chipsUsedCsv,
      builder: (column) => ColumnOrderings(column));
}

class $$MyTeamTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MyTeamTableTable> {
  $$MyTeamTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get driverIdsCsv => $composableBuilder(
      column: $table.driverIdsCsv, builder: (column) => column);

  GeneratedColumn<String> get constructorIdsCsv => $composableBuilder(
      column: $table.constructorIdsCsv, builder: (column) => column);

  GeneratedColumn<double> get remainingBudgetMillions => $composableBuilder(
      column: $table.remainingBudgetMillions, builder: (column) => column);

  GeneratedColumn<String> get boostedDriverId => $composableBuilder(
      column: $table.boostedDriverId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get chipsUsedCsv => $composableBuilder(
      column: $table.chipsUsedCsv, builder: (column) => column);
}

class $$MyTeamTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MyTeamTableTable,
    MyTeamRow,
    $$MyTeamTableTableFilterComposer,
    $$MyTeamTableTableOrderingComposer,
    $$MyTeamTableTableAnnotationComposer,
    $$MyTeamTableTableCreateCompanionBuilder,
    $$MyTeamTableTableUpdateCompanionBuilder,
    (MyTeamRow, BaseReferences<_$AppDatabase, $MyTeamTableTable, MyTeamRow>),
    MyTeamRow,
    PrefetchHooks Function()> {
  $$MyTeamTableTableTableManager(_$AppDatabase db, $MyTeamTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MyTeamTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MyTeamTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MyTeamTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> driverIdsCsv = const Value.absent(),
            Value<String> constructorIdsCsv = const Value.absent(),
            Value<double> remainingBudgetMillions = const Value.absent(),
            Value<String?> boostedDriverId = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> chipsUsedCsv = const Value.absent(),
          }) =>
              MyTeamTableCompanion(
            id: id,
            driverIdsCsv: driverIdsCsv,
            constructorIdsCsv: constructorIdsCsv,
            remainingBudgetMillions: remainingBudgetMillions,
            boostedDriverId: boostedDriverId,
            source: source,
            chipsUsedCsv: chipsUsedCsv,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String driverIdsCsv,
            required String constructorIdsCsv,
            required double remainingBudgetMillions,
            Value<String?> boostedDriverId = const Value.absent(),
            required String source,
            Value<String> chipsUsedCsv = const Value.absent(),
          }) =>
              MyTeamTableCompanion.insert(
            id: id,
            driverIdsCsv: driverIdsCsv,
            constructorIdsCsv: constructorIdsCsv,
            remainingBudgetMillions: remainingBudgetMillions,
            boostedDriverId: boostedDriverId,
            source: source,
            chipsUsedCsv: chipsUsedCsv,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MyTeamTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MyTeamTableTable,
    MyTeamRow,
    $$MyTeamTableTableFilterComposer,
    $$MyTeamTableTableOrderingComposer,
    $$MyTeamTableTableAnnotationComposer,
    $$MyTeamTableTableCreateCompanionBuilder,
    $$MyTeamTableTableUpdateCompanionBuilder,
    (MyTeamRow, BaseReferences<_$AppDatabase, $MyTeamTableTable, MyTeamRow>),
    MyTeamRow,
    PrefetchHooks Function()>;
typedef $$PredictionsCacheTableCreateCompanionBuilder
    = PredictionsCacheCompanion Function({
  required String assetId,
  required String assetType,
  required int season,
  required int round,
  required double expectedPoints,
  required double winProbability,
  required double podiumProbability,
  required double top10Probability,
  required double priceMillions,
  required String breakdownJson,
  required DateTime computedAt,
  Value<int> rowid,
});
typedef $$PredictionsCacheTableUpdateCompanionBuilder
    = PredictionsCacheCompanion Function({
  Value<String> assetId,
  Value<String> assetType,
  Value<int> season,
  Value<int> round,
  Value<double> expectedPoints,
  Value<double> winProbability,
  Value<double> podiumProbability,
  Value<double> top10Probability,
  Value<double> priceMillions,
  Value<String> breakdownJson,
  Value<DateTime> computedAt,
  Value<int> rowid,
});

class $$PredictionsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PredictionsCacheTable> {
  $$PredictionsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetType => $composableBuilder(
      column: $table.assetType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedPoints => $composableBuilder(
      column: $table.expectedPoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get winProbability => $composableBuilder(
      column: $table.winProbability,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get podiumProbability => $composableBuilder(
      column: $table.podiumProbability,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get top10Probability => $composableBuilder(
      column: $table.top10Probability,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceMillions => $composableBuilder(
      column: $table.priceMillions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get breakdownJson => $composableBuilder(
      column: $table.breakdownJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnFilters(column));
}

class $$PredictionsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PredictionsCacheTable> {
  $$PredictionsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetType => $composableBuilder(
      column: $table.assetType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get round => $composableBuilder(
      column: $table.round, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get expectedPoints => $composableBuilder(
      column: $table.expectedPoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get winProbability => $composableBuilder(
      column: $table.winProbability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get podiumProbability => $composableBuilder(
      column: $table.podiumProbability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get top10Probability => $composableBuilder(
      column: $table.top10Probability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceMillions => $composableBuilder(
      column: $table.priceMillions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get breakdownJson => $composableBuilder(
      column: $table.breakdownJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnOrderings(column));
}

class $$PredictionsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PredictionsCacheTable> {
  $$PredictionsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetType =>
      $composableBuilder(column: $table.assetType, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<double> get expectedPoints => $composableBuilder(
      column: $table.expectedPoints, builder: (column) => column);

  GeneratedColumn<double> get winProbability => $composableBuilder(
      column: $table.winProbability, builder: (column) => column);

  GeneratedColumn<double> get podiumProbability => $composableBuilder(
      column: $table.podiumProbability, builder: (column) => column);

  GeneratedColumn<double> get top10Probability => $composableBuilder(
      column: $table.top10Probability, builder: (column) => column);

  GeneratedColumn<double> get priceMillions => $composableBuilder(
      column: $table.priceMillions, builder: (column) => column);

  GeneratedColumn<String> get breakdownJson => $composableBuilder(
      column: $table.breakdownJson, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => column);
}

class $$PredictionsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PredictionsCacheTable,
    PredictionCacheRow,
    $$PredictionsCacheTableFilterComposer,
    $$PredictionsCacheTableOrderingComposer,
    $$PredictionsCacheTableAnnotationComposer,
    $$PredictionsCacheTableCreateCompanionBuilder,
    $$PredictionsCacheTableUpdateCompanionBuilder,
    (
      PredictionCacheRow,
      BaseReferences<_$AppDatabase, $PredictionsCacheTable, PredictionCacheRow>
    ),
    PredictionCacheRow,
    PrefetchHooks Function()> {
  $$PredictionsCacheTableTableManager(
      _$AppDatabase db, $PredictionsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PredictionsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PredictionsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PredictionsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> assetId = const Value.absent(),
            Value<String> assetType = const Value.absent(),
            Value<int> season = const Value.absent(),
            Value<int> round = const Value.absent(),
            Value<double> expectedPoints = const Value.absent(),
            Value<double> winProbability = const Value.absent(),
            Value<double> podiumProbability = const Value.absent(),
            Value<double> top10Probability = const Value.absent(),
            Value<double> priceMillions = const Value.absent(),
            Value<String> breakdownJson = const Value.absent(),
            Value<DateTime> computedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PredictionsCacheCompanion(
            assetId: assetId,
            assetType: assetType,
            season: season,
            round: round,
            expectedPoints: expectedPoints,
            winProbability: winProbability,
            podiumProbability: podiumProbability,
            top10Probability: top10Probability,
            priceMillions: priceMillions,
            breakdownJson: breakdownJson,
            computedAt: computedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String assetId,
            required String assetType,
            required int season,
            required int round,
            required double expectedPoints,
            required double winProbability,
            required double podiumProbability,
            required double top10Probability,
            required double priceMillions,
            required String breakdownJson,
            required DateTime computedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PredictionsCacheCompanion.insert(
            assetId: assetId,
            assetType: assetType,
            season: season,
            round: round,
            expectedPoints: expectedPoints,
            winProbability: winProbability,
            podiumProbability: podiumProbability,
            top10Probability: top10Probability,
            priceMillions: priceMillions,
            breakdownJson: breakdownJson,
            computedAt: computedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PredictionsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PredictionsCacheTable,
    PredictionCacheRow,
    $$PredictionsCacheTableFilterComposer,
    $$PredictionsCacheTableOrderingComposer,
    $$PredictionsCacheTableAnnotationComposer,
    $$PredictionsCacheTableCreateCompanionBuilder,
    $$PredictionsCacheTableUpdateCompanionBuilder,
    (
      PredictionCacheRow,
      BaseReferences<_$AppDatabase, $PredictionsCacheTable, PredictionCacheRow>
    ),
    PredictionCacheRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DriversTableTableManager get drivers =>
      $$DriversTableTableManager(_db, _db.drivers);
  $$ConstructorsTableTableManager get constructors =>
      $$ConstructorsTableTableManager(_db, _db.constructors);
  $$RacesTableTableManager get races =>
      $$RacesTableTableManager(_db, _db.races);
  $$ResultsTableTableManager get results =>
      $$ResultsTableTableManager(_db, _db.results);
  $$QualifyingResultsTableTableManager get qualifyingResults =>
      $$QualifyingResultsTableTableManager(_db, _db.qualifyingResults);
  $$SessionLapsTableTableManager get sessionLaps =>
      $$SessionLapsTableTableManager(_db, _db.sessionLaps);
  $$FantasyPricesTableTableManager get fantasyPrices =>
      $$FantasyPricesTableTableManager(_db, _db.fantasyPrices);
  $$FantasyPointsTableTableTableManager get fantasyPointsTable =>
      $$FantasyPointsTableTableTableManager(_db, _db.fantasyPointsTable);
  $$MyTeamTableTableTableManager get myTeamTable =>
      $$MyTeamTableTableTableManager(_db, _db.myTeamTable);
  $$PredictionsCacheTableTableManager get predictionsCache =>
      $$PredictionsCacheTableTableManager(_db, _db.predictionsCache);
}
