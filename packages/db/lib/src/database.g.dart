// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inbox'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedDateMeta = const VerificationMeta(
    'plannedDate',
  );
  @override
  late final GeneratedColumn<int> plannedDate = GeneratedColumn<int>(
    'planned_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deferDateMeta = const VerificationMeta(
    'deferDate',
  );
  @override
  late final GeneratedColumn<int> deferDate = GeneratedColumn<int>(
    'defer_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<int> reminderAt = GeneratedColumn<int>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimateMinutesMeta = const VerificationMeta(
    'estimateMinutes',
  );
  @override
  late final GeneratedColumn<int> estimateMinutes = GeneratedColumn<int>(
    'estimate_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinutesMeta = const VerificationMeta(
    'actualMinutes',
  );
  @override
  late final GeneratedColumn<int> actualMinutes = GeneratedColumn<int>(
    'actual_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<String> energy = GeneratedColumn<String>(
    'energy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waitingForMeta = const VerificationMeta(
    'waitingFor',
  );
  @override
  late final GeneratedColumn<String> waitingFor = GeneratedColumn<String>(
    'waiting_for',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<String> sortKey = GeneratedColumn<String>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    projectId,
    title,
    note,
    status,
    startDate,
    dueDate,
    plannedDate,
    deferDate,
    completedAt,
    reminderAt,
    recurrence,
    estimateMinutes,
    actualMinutes,
    energy,
    waitingFor,
    sortKey,
    createdAt,
    updatedAt,
    lamport,
    origin,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('planned_date')) {
      context.handle(
        _plannedDateMeta,
        plannedDate.isAcceptableOrUnknown(
          data['planned_date']!,
          _plannedDateMeta,
        ),
      );
    }
    if (data.containsKey('defer_date')) {
      context.handle(
        _deferDateMeta,
        deferDate.isAcceptableOrUnknown(data['defer_date']!, _deferDateMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('estimate_minutes')) {
      context.handle(
        _estimateMinutesMeta,
        estimateMinutes.isAcceptableOrUnknown(
          data['estimate_minutes']!,
          _estimateMinutesMeta,
        ),
      );
    }
    if (data.containsKey('actual_minutes')) {
      context.handle(
        _actualMinutesMeta,
        actualMinutes.isAcceptableOrUnknown(
          data['actual_minutes']!,
          _actualMinutesMeta,
        ),
      );
    }
    if (data.containsKey('energy')) {
      context.handle(
        _energyMeta,
        energy.isAcceptableOrUnknown(data['energy']!, _energyMeta),
      );
    }
    if (data.containsKey('waiting_for')) {
      context.handle(
        _waitingForMeta,
        waitingFor.isAcceptableOrUnknown(data['waiting_for']!, _waitingForMeta),
      );
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sortKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      ),
      plannedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_date'],
      ),
      deferDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}defer_date'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_at'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      ),
      estimateMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_minutes'],
      ),
      actualMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minutes'],
      ),
      energy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}energy'],
      ),
      waitingFor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waiting_for'],
      ),
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String? parentId;
  final String? projectId;
  final String title;
  final String? note;
  final String status;
  final int? startDate;
  final int? dueDate;
  final int? plannedDate;
  final int? deferDate;
  final int? completedAt;
  final int? reminderAt;
  final String? recurrence;
  final int? estimateMinutes;
  final int? actualMinutes;
  final String? energy;
  final String? waitingFor;
  final String sortKey;
  final int createdAt;
  final int updatedAt;
  final int lamport;
  final String origin;
  final int? deletedAt;
  const Task({
    required this.id,
    this.parentId,
    this.projectId,
    required this.title,
    this.note,
    required this.status,
    this.startDate,
    this.dueDate,
    this.plannedDate,
    this.deferDate,
    this.completedAt,
    this.reminderAt,
    this.recurrence,
    this.estimateMinutes,
    this.actualMinutes,
    this.energy,
    this.waitingFor,
    required this.sortKey,
    required this.createdAt,
    required this.updatedAt,
    required this.lamport,
    required this.origin,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<int>(startDate);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    if (!nullToAbsent || plannedDate != null) {
      map['planned_date'] = Variable<int>(plannedDate);
    }
    if (!nullToAbsent || deferDate != null) {
      map['defer_date'] = Variable<int>(deferDate);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<int>(reminderAt);
    }
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(recurrence);
    }
    if (!nullToAbsent || estimateMinutes != null) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes);
    }
    if (!nullToAbsent || actualMinutes != null) {
      map['actual_minutes'] = Variable<int>(actualMinutes);
    }
    if (!nullToAbsent || energy != null) {
      map['energy'] = Variable<String>(energy);
    }
    if (!nullToAbsent || waitingFor != null) {
      map['waiting_for'] = Variable<String>(waitingFor);
    }
    map['sort_key'] = Variable<String>(sortKey);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['lamport'] = Variable<int>(lamport);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      plannedDate: plannedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedDate),
      deferDate: deferDate == null && nullToAbsent
          ? const Value.absent()
          : Value(deferDate),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      recurrence: recurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrence),
      estimateMinutes: estimateMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMinutes),
      actualMinutes: actualMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(actualMinutes),
      energy: energy == null && nullToAbsent
          ? const Value.absent()
          : Value(energy),
      waitingFor: waitingFor == null && nullToAbsent
          ? const Value.absent()
          : Value(waitingFor),
      sortKey: Value(sortKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lamport: Value(lamport),
      origin: Value(origin),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<int?>(json['startDate']),
      dueDate: serializer.fromJson<int?>(json['dueDate']),
      plannedDate: serializer.fromJson<int?>(json['plannedDate']),
      deferDate: serializer.fromJson<int?>(json['deferDate']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      reminderAt: serializer.fromJson<int?>(json['reminderAt']),
      recurrence: serializer.fromJson<String?>(json['recurrence']),
      estimateMinutes: serializer.fromJson<int?>(json['estimateMinutes']),
      actualMinutes: serializer.fromJson<int?>(json['actualMinutes']),
      energy: serializer.fromJson<String?>(json['energy']),
      waitingFor: serializer.fromJson<String?>(json['waitingFor']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lamport: serializer.fromJson<int>(json['lamport']),
      origin: serializer.fromJson<String>(json['origin']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'projectId': serializer.toJson<String?>(projectId),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'startDate': serializer.toJson<int?>(startDate),
      'dueDate': serializer.toJson<int?>(dueDate),
      'plannedDate': serializer.toJson<int?>(plannedDate),
      'deferDate': serializer.toJson<int?>(deferDate),
      'completedAt': serializer.toJson<int?>(completedAt),
      'reminderAt': serializer.toJson<int?>(reminderAt),
      'recurrence': serializer.toJson<String?>(recurrence),
      'estimateMinutes': serializer.toJson<int?>(estimateMinutes),
      'actualMinutes': serializer.toJson<int?>(actualMinutes),
      'energy': serializer.toJson<String?>(energy),
      'waitingFor': serializer.toJson<String?>(waitingFor),
      'sortKey': serializer.toJson<String>(sortKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lamport': serializer.toJson<int>(lamport),
      'origin': serializer.toJson<String>(origin),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Task copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    String? title,
    Value<String?> note = const Value.absent(),
    String? status,
    Value<int?> startDate = const Value.absent(),
    Value<int?> dueDate = const Value.absent(),
    Value<int?> plannedDate = const Value.absent(),
    Value<int?> deferDate = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    Value<int?> reminderAt = const Value.absent(),
    Value<String?> recurrence = const Value.absent(),
    Value<int?> estimateMinutes = const Value.absent(),
    Value<int?> actualMinutes = const Value.absent(),
    Value<String?> energy = const Value.absent(),
    Value<String?> waitingFor = const Value.absent(),
    String? sortKey,
    int? createdAt,
    int? updatedAt,
    int? lamport,
    String? origin,
    Value<int?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    projectId: projectId.present ? projectId.value : this.projectId,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    status: status ?? this.status,
    startDate: startDate.present ? startDate.value : this.startDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    plannedDate: plannedDate.present ? plannedDate.value : this.plannedDate,
    deferDate: deferDate.present ? deferDate.value : this.deferDate,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    estimateMinutes: estimateMinutes.present
        ? estimateMinutes.value
        : this.estimateMinutes,
    actualMinutes: actualMinutes.present
        ? actualMinutes.value
        : this.actualMinutes,
    energy: energy.present ? energy.value : this.energy,
    waitingFor: waitingFor.present ? waitingFor.value : this.waitingFor,
    sortKey: sortKey ?? this.sortKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lamport: lamport ?? this.lamport,
    origin: origin ?? this.origin,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      plannedDate: data.plannedDate.present
          ? data.plannedDate.value
          : this.plannedDate,
      deferDate: data.deferDate.present ? data.deferDate.value : this.deferDate,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      estimateMinutes: data.estimateMinutes.present
          ? data.estimateMinutes.value
          : this.estimateMinutes,
      actualMinutes: data.actualMinutes.present
          ? data.actualMinutes.value
          : this.actualMinutes,
      energy: data.energy.present ? data.energy.value : this.energy,
      waitingFor: data.waitingFor.present
          ? data.waitingFor.value
          : this.waitingFor,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      origin: data.origin.present ? data.origin.value : this.origin,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('deferDate: $deferDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('recurrence: $recurrence, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('energy: $energy, ')
          ..write('waitingFor: $waitingFor, ')
          ..write('sortKey: $sortKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    parentId,
    projectId,
    title,
    note,
    status,
    startDate,
    dueDate,
    plannedDate,
    deferDate,
    completedAt,
    reminderAt,
    recurrence,
    estimateMinutes,
    actualMinutes,
    energy,
    waitingFor,
    sortKey,
    createdAt,
    updatedAt,
    lamport,
    origin,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.note == this.note &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.dueDate == this.dueDate &&
          other.plannedDate == this.plannedDate &&
          other.deferDate == this.deferDate &&
          other.completedAt == this.completedAt &&
          other.reminderAt == this.reminderAt &&
          other.recurrence == this.recurrence &&
          other.estimateMinutes == this.estimateMinutes &&
          other.actualMinutes == this.actualMinutes &&
          other.energy == this.energy &&
          other.waitingFor == this.waitingFor &&
          other.sortKey == this.sortKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lamport == this.lamport &&
          other.origin == this.origin &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String?> projectId;
  final Value<String> title;
  final Value<String?> note;
  final Value<String> status;
  final Value<int?> startDate;
  final Value<int?> dueDate;
  final Value<int?> plannedDate;
  final Value<int?> deferDate;
  final Value<int?> completedAt;
  final Value<int?> reminderAt;
  final Value<String?> recurrence;
  final Value<int?> estimateMinutes;
  final Value<int?> actualMinutes;
  final Value<String?> energy;
  final Value<String?> waitingFor;
  final Value<String> sortKey;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> lamport;
  final Value<String> origin;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.plannedDate = const Value.absent(),
    this.deferDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.energy = const Value.absent(),
    this.waitingFor = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lamport = const Value.absent(),
    this.origin = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    this.projectId = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.plannedDate = const Value.absent(),
    this.deferDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.energy = const Value.absent(),
    this.waitingFor = const Value.absent(),
    required String sortKey,
    required int createdAt,
    required int updatedAt,
    required int lamport,
    required String origin,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sortKey = Value(sortKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       lamport = Value(lamport),
       origin = Value(origin);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? status,
    Expression<int>? startDate,
    Expression<int>? dueDate,
    Expression<int>? plannedDate,
    Expression<int>? deferDate,
    Expression<int>? completedAt,
    Expression<int>? reminderAt,
    Expression<String>? recurrence,
    Expression<int>? estimateMinutes,
    Expression<int>? actualMinutes,
    Expression<String>? energy,
    Expression<String>? waitingFor,
    Expression<String>? sortKey,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lamport,
    Expression<String>? origin,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (dueDate != null) 'due_date': dueDate,
      if (plannedDate != null) 'planned_date': plannedDate,
      if (deferDate != null) 'defer_date': deferDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (recurrence != null) 'recurrence': recurrence,
      if (estimateMinutes != null) 'estimate_minutes': estimateMinutes,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (energy != null) 'energy': energy,
      if (waitingFor != null) 'waiting_for': waitingFor,
      if (sortKey != null) 'sort_key': sortKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lamport != null) 'lamport': lamport,
      if (origin != null) 'origin': origin,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String?>? projectId,
    Value<String>? title,
    Value<String?>? note,
    Value<String>? status,
    Value<int?>? startDate,
    Value<int?>? dueDate,
    Value<int?>? plannedDate,
    Value<int?>? deferDate,
    Value<int?>? completedAt,
    Value<int?>? reminderAt,
    Value<String?>? recurrence,
    Value<int?>? estimateMinutes,
    Value<int?>? actualMinutes,
    Value<String?>? energy,
    Value<String?>? waitingFor,
    Value<String>? sortKey,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? lamport,
    Value<String>? origin,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      note: note ?? this.note,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      plannedDate: plannedDate ?? this.plannedDate,
      deferDate: deferDate ?? this.deferDate,
      completedAt: completedAt ?? this.completedAt,
      reminderAt: reminderAt ?? this.reminderAt,
      recurrence: recurrence ?? this.recurrence,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      energy: energy ?? this.energy,
      waitingFor: waitingFor ?? this.waitingFor,
      sortKey: sortKey ?? this.sortKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lamport: lamport ?? this.lamport,
      origin: origin ?? this.origin,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (plannedDate.present) {
      map['planned_date'] = Variable<int>(plannedDate.value);
    }
    if (deferDate.present) {
      map['defer_date'] = Variable<int>(deferDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<int>(reminderAt.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (estimateMinutes.present) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes.value);
    }
    if (actualMinutes.present) {
      map['actual_minutes'] = Variable<int>(actualMinutes.value);
    }
    if (energy.present) {
      map['energy'] = Variable<String>(energy.value);
    }
    if (waitingFor.present) {
      map['waiting_for'] = Variable<String>(waitingFor.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<String>(sortKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('deferDate: $deferDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('recurrence: $recurrence, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('energy: $energy, ')
          ..write('waitingFor: $waitingFor, ')
          ..write('sortKey: $sortKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AreasTable extends Areas with TableInfo<$AreasTable, Area> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<String> sortKey = GeneratedColumn<String>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    sortKey,
    createdAt,
    updatedAt,
    lamport,
    origin,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Area> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sortKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Area map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Area(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AreasTable createAlias(String alias) {
    return $AreasTable(attachedDatabase, alias);
  }
}

class Area extends DataClass implements Insertable<Area> {
  final String id;
  final String name;
  final String? color;
  final String sortKey;
  final int createdAt;
  final int updatedAt;
  final int lamport;
  final String origin;
  final int? deletedAt;
  const Area({
    required this.id,
    required this.name,
    this.color,
    required this.sortKey,
    required this.createdAt,
    required this.updatedAt,
    required this.lamport,
    required this.origin,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_key'] = Variable<String>(sortKey);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['lamport'] = Variable<int>(lamport);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  AreasCompanion toCompanion(bool nullToAbsent) {
    return AreasCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortKey: Value(sortKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lamport: Value(lamport),
      origin: Value(origin),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Area.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Area(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lamport: serializer.fromJson<int>(json['lamport']),
      origin: serializer.fromJson<String>(json['origin']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'sortKey': serializer.toJson<String>(sortKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lamport': serializer.toJson<int>(lamport),
      'origin': serializer.toJson<String>(origin),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Area copyWith({
    String? id,
    String? name,
    Value<String?> color = const Value.absent(),
    String? sortKey,
    int? createdAt,
    int? updatedAt,
    int? lamport,
    String? origin,
    Value<int?> deletedAt = const Value.absent(),
  }) => Area(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    sortKey: sortKey ?? this.sortKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lamport: lamport ?? this.lamport,
    origin: origin ?? this.origin,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Area copyWithCompanion(AreasCompanion data) {
    return Area(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      origin: data.origin.present ? data.origin.value : this.origin,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Area(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortKey: $sortKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    color,
    sortKey,
    createdAt,
    updatedAt,
    lamport,
    origin,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Area &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortKey == this.sortKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lamport == this.lamport &&
          other.origin == this.origin &&
          other.deletedAt == this.deletedAt);
}

class AreasCompanion extends UpdateCompanion<Area> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<String> sortKey;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> lamport;
  final Value<String> origin;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const AreasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lamport = const Value.absent(),
    this.origin = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AreasCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    required String sortKey,
    required int createdAt,
    required int updatedAt,
    required int lamport,
    required String origin,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortKey = Value(sortKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       lamport = Value(lamport),
       origin = Value(origin);
  static Insertable<Area> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? sortKey,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lamport,
    Expression<String>? origin,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortKey != null) 'sort_key': sortKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lamport != null) 'lamport': lamport,
      if (origin != null) 'origin': origin,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AreasCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? color,
    Value<String>? sortKey,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? lamport,
    Value<String>? origin,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AreasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortKey: sortKey ?? this.sortKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lamport: lamport ?? this.lamport,
      origin: origin ?? this.origin,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<String>(sortKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AreasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortKey: $sortKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _reviewCadenceDaysMeta = const VerificationMeta(
    'reviewCadenceDays',
  );
  @override
  late final GeneratedColumn<int> reviewCadenceDays = GeneratedColumn<int>(
    'review_cadence_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextActionIdMeta = const VerificationMeta(
    'nextActionId',
  );
  @override
  late final GeneratedColumn<String> nextActionId = GeneratedColumn<String>(
    'next_action_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<String> sortKey = GeneratedColumn<String>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    areaId,
    name,
    note,
    status,
    reviewCadenceDays,
    nextActionId,
    sortKey,
    createdAt,
    updatedAt,
    lamport,
    origin,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('review_cadence_days')) {
      context.handle(
        _reviewCadenceDaysMeta,
        reviewCadenceDays.isAcceptableOrUnknown(
          data['review_cadence_days']!,
          _reviewCadenceDaysMeta,
        ),
      );
    }
    if (data.containsKey('next_action_id')) {
      context.handle(
        _nextActionIdMeta,
        nextActionId.isAcceptableOrUnknown(
          data['next_action_id']!,
          _nextActionIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sortKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reviewCadenceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_cadence_days'],
      ),
      nextActionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_action_id'],
      ),
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String? parentId;
  final String? areaId;
  final String name;
  final String? note;
  final String status;
  final int? reviewCadenceDays;
  final String? nextActionId;
  final String sortKey;
  final int createdAt;
  final int updatedAt;
  final int lamport;
  final String origin;
  final int? deletedAt;
  const Project({
    required this.id,
    this.parentId,
    this.areaId,
    required this.name,
    this.note,
    required this.status,
    this.reviewCadenceDays,
    this.nextActionId,
    required this.sortKey,
    required this.createdAt,
    required this.updatedAt,
    required this.lamport,
    required this.origin,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || areaId != null) {
      map['area_id'] = Variable<String>(areaId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || reviewCadenceDays != null) {
      map['review_cadence_days'] = Variable<int>(reviewCadenceDays);
    }
    if (!nullToAbsent || nextActionId != null) {
      map['next_action_id'] = Variable<String>(nextActionId);
    }
    map['sort_key'] = Variable<String>(sortKey);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['lamport'] = Variable<int>(lamport);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      areaId: areaId == null && nullToAbsent
          ? const Value.absent()
          : Value(areaId),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      reviewCadenceDays: reviewCadenceDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewCadenceDays),
      nextActionId: nextActionId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextActionId),
      sortKey: Value(sortKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lamport: Value(lamport),
      origin: Value(origin),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      areaId: serializer.fromJson<String?>(json['areaId']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      reviewCadenceDays: serializer.fromJson<int?>(json['reviewCadenceDays']),
      nextActionId: serializer.fromJson<String?>(json['nextActionId']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lamport: serializer.fromJson<int>(json['lamport']),
      origin: serializer.fromJson<String>(json['origin']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'areaId': serializer.toJson<String?>(areaId),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'reviewCadenceDays': serializer.toJson<int?>(reviewCadenceDays),
      'nextActionId': serializer.toJson<String?>(nextActionId),
      'sortKey': serializer.toJson<String>(sortKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lamport': serializer.toJson<int>(lamport),
      'origin': serializer.toJson<String>(origin),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Project copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    Value<String?> areaId = const Value.absent(),
    String? name,
    Value<String?> note = const Value.absent(),
    String? status,
    Value<int?> reviewCadenceDays = const Value.absent(),
    Value<String?> nextActionId = const Value.absent(),
    String? sortKey,
    int? createdAt,
    int? updatedAt,
    int? lamport,
    String? origin,
    Value<int?> deletedAt = const Value.absent(),
  }) => Project(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    areaId: areaId.present ? areaId.value : this.areaId,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    status: status ?? this.status,
    reviewCadenceDays: reviewCadenceDays.present
        ? reviewCadenceDays.value
        : this.reviewCadenceDays,
    nextActionId: nextActionId.present ? nextActionId.value : this.nextActionId,
    sortKey: sortKey ?? this.sortKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lamport: lamport ?? this.lamport,
    origin: origin ?? this.origin,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      reviewCadenceDays: data.reviewCadenceDays.present
          ? data.reviewCadenceDays.value
          : this.reviewCadenceDays,
      nextActionId: data.nextActionId.present
          ? data.nextActionId.value
          : this.nextActionId,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      origin: data.origin.present ? data.origin.value : this.origin,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('areaId: $areaId, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('reviewCadenceDays: $reviewCadenceDays, ')
          ..write('nextActionId: $nextActionId, ')
          ..write('sortKey: $sortKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    areaId,
    name,
    note,
    status,
    reviewCadenceDays,
    nextActionId,
    sortKey,
    createdAt,
    updatedAt,
    lamport,
    origin,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.areaId == this.areaId &&
          other.name == this.name &&
          other.note == this.note &&
          other.status == this.status &&
          other.reviewCadenceDays == this.reviewCadenceDays &&
          other.nextActionId == this.nextActionId &&
          other.sortKey == this.sortKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lamport == this.lamport &&
          other.origin == this.origin &&
          other.deletedAt == this.deletedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String?> areaId;
  final Value<String> name;
  final Value<String?> note;
  final Value<String> status;
  final Value<int?> reviewCadenceDays;
  final Value<String?> nextActionId;
  final Value<String> sortKey;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> lamport;
  final Value<String> origin;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.areaId = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.reviewCadenceDays = const Value.absent(),
    this.nextActionId = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lamport = const Value.absent(),
    this.origin = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    this.areaId = const Value.absent(),
    required String name,
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.reviewCadenceDays = const Value.absent(),
    this.nextActionId = const Value.absent(),
    required String sortKey,
    required int createdAt,
    required int updatedAt,
    required int lamport,
    required String origin,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortKey = Value(sortKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       lamport = Value(lamport),
       origin = Value(origin);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? areaId,
    Expression<String>? name,
    Expression<String>? note,
    Expression<String>? status,
    Expression<int>? reviewCadenceDays,
    Expression<String>? nextActionId,
    Expression<String>? sortKey,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lamport,
    Expression<String>? origin,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (areaId != null) 'area_id': areaId,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (reviewCadenceDays != null) 'review_cadence_days': reviewCadenceDays,
      if (nextActionId != null) 'next_action_id': nextActionId,
      if (sortKey != null) 'sort_key': sortKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lamport != null) 'lamport': lamport,
      if (origin != null) 'origin': origin,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String?>? areaId,
    Value<String>? name,
    Value<String?>? note,
    Value<String>? status,
    Value<int?>? reviewCadenceDays,
    Value<String?>? nextActionId,
    Value<String>? sortKey,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? lamport,
    Value<String>? origin,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      areaId: areaId ?? this.areaId,
      name: name ?? this.name,
      note: note ?? this.note,
      status: status ?? this.status,
      reviewCadenceDays: reviewCadenceDays ?? this.reviewCadenceDays,
      nextActionId: nextActionId ?? this.nextActionId,
      sortKey: sortKey ?? this.sortKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lamport: lamport ?? this.lamport,
      origin: origin ?? this.origin,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reviewCadenceDays.present) {
      map['review_cadence_days'] = Variable<int>(reviewCadenceDays.value);
    }
    if (nextActionId.present) {
      map['next_action_id'] = Variable<String>(nextActionId.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<String>(sortKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('areaId: $areaId, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('reviewCadenceDays: $reviewCadenceDays, ')
          ..write('nextActionId: $nextActionId, ')
          ..write('sortKey: $sortKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OplogTable extends Oplog with TableInfo<$OplogTable, OplogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OplogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localSeqMeta = const VerificationMeta(
    'localSeq',
  );
  @override
  late final GeneratedColumn<int> localSeq = GeneratedColumn<int>(
    'local_seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueBlobMeta = const VerificationMeta(
    'valueBlob',
  );
  @override
  late final GeneratedColumn<String> valueBlob = GeneratedColumn<String>(
    'value_blob',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMetaMeta = const VerificationMeta(
    'valueMeta',
  );
  @override
  late final GeneratedColumn<String> valueMeta = GeneratedColumn<String>(
    'value_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pushedAtMeta = const VerificationMeta(
    'pushedAt',
  );
  @override
  late final GeneratedColumn<int> pushedAt = GeneratedColumn<int>(
    'pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localSeq,
    serverSeq,
    deviceId,
    lamport,
    entity,
    entityId,
    field,
    op,
    valueBlob,
    valueMeta,
    pushedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oplog';
  @override
  VerificationContext validateIntegrity(
    Insertable<OplogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_seq')) {
      context.handle(
        _localSeqMeta,
        localSeq.isAcceptableOrUnknown(data['local_seq']!, _localSeqMeta),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('value_blob')) {
      context.handle(
        _valueBlobMeta,
        valueBlob.isAcceptableOrUnknown(data['value_blob']!, _valueBlobMeta),
      );
    }
    if (data.containsKey('value_meta')) {
      context.handle(
        _valueMetaMeta,
        valueMeta.isAcceptableOrUnknown(data['value_meta']!, _valueMetaMeta),
      );
    }
    if (data.containsKey('pushed_at')) {
      context.handle(
        _pushedAtMeta,
        pushedAt.isAcceptableOrUnknown(data['pushed_at']!, _pushedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localSeq};
  @override
  OplogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OplogRow(
      localSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_seq'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      valueBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_blob'],
      ),
      valueMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_meta'],
      ),
      pushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pushed_at'],
      ),
    );
  }

  @override
  $OplogTable createAlias(String alias) {
    return $OplogTable(attachedDatabase, alias);
  }
}

class OplogRow extends DataClass implements Insertable<OplogRow> {
  final int localSeq;
  final int? serverSeq;
  final String deviceId;
  final int lamport;
  final String entity;
  final String entityId;
  final String field;
  final String op;
  final String? valueBlob;
  final String? valueMeta;
  final int? pushedAt;
  const OplogRow({
    required this.localSeq,
    this.serverSeq,
    required this.deviceId,
    required this.lamport,
    required this.entity,
    required this.entityId,
    required this.field,
    required this.op,
    this.valueBlob,
    this.valueMeta,
    this.pushedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_seq'] = Variable<int>(localSeq);
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['lamport'] = Variable<int>(lamport);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['field'] = Variable<String>(field);
    map['op'] = Variable<String>(op);
    if (!nullToAbsent || valueBlob != null) {
      map['value_blob'] = Variable<String>(valueBlob);
    }
    if (!nullToAbsent || valueMeta != null) {
      map['value_meta'] = Variable<String>(valueMeta);
    }
    if (!nullToAbsent || pushedAt != null) {
      map['pushed_at'] = Variable<int>(pushedAt);
    }
    return map;
  }

  OplogCompanion toCompanion(bool nullToAbsent) {
    return OplogCompanion(
      localSeq: Value(localSeq),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      deviceId: Value(deviceId),
      lamport: Value(lamport),
      entity: Value(entity),
      entityId: Value(entityId),
      field: Value(field),
      op: Value(op),
      valueBlob: valueBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(valueBlob),
      valueMeta: valueMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(valueMeta),
      pushedAt: pushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pushedAt),
    );
  }

  factory OplogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OplogRow(
      localSeq: serializer.fromJson<int>(json['localSeq']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      lamport: serializer.fromJson<int>(json['lamport']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      field: serializer.fromJson<String>(json['field']),
      op: serializer.fromJson<String>(json['op']),
      valueBlob: serializer.fromJson<String?>(json['valueBlob']),
      valueMeta: serializer.fromJson<String?>(json['valueMeta']),
      pushedAt: serializer.fromJson<int?>(json['pushedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localSeq': serializer.toJson<int>(localSeq),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'deviceId': serializer.toJson<String>(deviceId),
      'lamport': serializer.toJson<int>(lamport),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'field': serializer.toJson<String>(field),
      'op': serializer.toJson<String>(op),
      'valueBlob': serializer.toJson<String?>(valueBlob),
      'valueMeta': serializer.toJson<String?>(valueMeta),
      'pushedAt': serializer.toJson<int?>(pushedAt),
    };
  }

  OplogRow copyWith({
    int? localSeq,
    Value<int?> serverSeq = const Value.absent(),
    String? deviceId,
    int? lamport,
    String? entity,
    String? entityId,
    String? field,
    String? op,
    Value<String?> valueBlob = const Value.absent(),
    Value<String?> valueMeta = const Value.absent(),
    Value<int?> pushedAt = const Value.absent(),
  }) => OplogRow(
    localSeq: localSeq ?? this.localSeq,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    deviceId: deviceId ?? this.deviceId,
    lamport: lamport ?? this.lamport,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    field: field ?? this.field,
    op: op ?? this.op,
    valueBlob: valueBlob.present ? valueBlob.value : this.valueBlob,
    valueMeta: valueMeta.present ? valueMeta.value : this.valueMeta,
    pushedAt: pushedAt.present ? pushedAt.value : this.pushedAt,
  );
  OplogRow copyWithCompanion(OplogCompanion data) {
    return OplogRow(
      localSeq: data.localSeq.present ? data.localSeq.value : this.localSeq,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      field: data.field.present ? data.field.value : this.field,
      op: data.op.present ? data.op.value : this.op,
      valueBlob: data.valueBlob.present ? data.valueBlob.value : this.valueBlob,
      valueMeta: data.valueMeta.present ? data.valueMeta.value : this.valueMeta,
      pushedAt: data.pushedAt.present ? data.pushedAt.value : this.pushedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OplogRow(')
          ..write('localSeq: $localSeq, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('deviceId: $deviceId, ')
          ..write('lamport: $lamport, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('op: $op, ')
          ..write('valueBlob: $valueBlob, ')
          ..write('valueMeta: $valueMeta, ')
          ..write('pushedAt: $pushedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localSeq,
    serverSeq,
    deviceId,
    lamport,
    entity,
    entityId,
    field,
    op,
    valueBlob,
    valueMeta,
    pushedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OplogRow &&
          other.localSeq == this.localSeq &&
          other.serverSeq == this.serverSeq &&
          other.deviceId == this.deviceId &&
          other.lamport == this.lamport &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.field == this.field &&
          other.op == this.op &&
          other.valueBlob == this.valueBlob &&
          other.valueMeta == this.valueMeta &&
          other.pushedAt == this.pushedAt);
}

class OplogCompanion extends UpdateCompanion<OplogRow> {
  final Value<int> localSeq;
  final Value<int?> serverSeq;
  final Value<String> deviceId;
  final Value<int> lamport;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> field;
  final Value<String> op;
  final Value<String?> valueBlob;
  final Value<String?> valueMeta;
  final Value<int?> pushedAt;
  const OplogCompanion({
    this.localSeq = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.lamport = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.field = const Value.absent(),
    this.op = const Value.absent(),
    this.valueBlob = const Value.absent(),
    this.valueMeta = const Value.absent(),
    this.pushedAt = const Value.absent(),
  });
  OplogCompanion.insert({
    this.localSeq = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String deviceId,
    required int lamport,
    required String entity,
    required String entityId,
    required String field,
    required String op,
    this.valueBlob = const Value.absent(),
    this.valueMeta = const Value.absent(),
    this.pushedAt = const Value.absent(),
  }) : deviceId = Value(deviceId),
       lamport = Value(lamport),
       entity = Value(entity),
       entityId = Value(entityId),
       field = Value(field),
       op = Value(op);
  static Insertable<OplogRow> custom({
    Expression<int>? localSeq,
    Expression<int>? serverSeq,
    Expression<String>? deviceId,
    Expression<int>? lamport,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? field,
    Expression<String>? op,
    Expression<String>? valueBlob,
    Expression<String>? valueMeta,
    Expression<int>? pushedAt,
  }) {
    return RawValuesInsertable({
      if (localSeq != null) 'local_seq': localSeq,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (deviceId != null) 'device_id': deviceId,
      if (lamport != null) 'lamport': lamport,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (field != null) 'field': field,
      if (op != null) 'op': op,
      if (valueBlob != null) 'value_blob': valueBlob,
      if (valueMeta != null) 'value_meta': valueMeta,
      if (pushedAt != null) 'pushed_at': pushedAt,
    });
  }

  OplogCompanion copyWith({
    Value<int>? localSeq,
    Value<int?>? serverSeq,
    Value<String>? deviceId,
    Value<int>? lamport,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? field,
    Value<String>? op,
    Value<String?>? valueBlob,
    Value<String?>? valueMeta,
    Value<int?>? pushedAt,
  }) {
    return OplogCompanion(
      localSeq: localSeq ?? this.localSeq,
      serverSeq: serverSeq ?? this.serverSeq,
      deviceId: deviceId ?? this.deviceId,
      lamport: lamport ?? this.lamport,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      field: field ?? this.field,
      op: op ?? this.op,
      valueBlob: valueBlob ?? this.valueBlob,
      valueMeta: valueMeta ?? this.valueMeta,
      pushedAt: pushedAt ?? this.pushedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localSeq.present) {
      map['local_seq'] = Variable<int>(localSeq.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (valueBlob.present) {
      map['value_blob'] = Variable<String>(valueBlob.value);
    }
    if (valueMeta.present) {
      map['value_meta'] = Variable<String>(valueMeta.value);
    }
    if (pushedAt.present) {
      map['pushed_at'] = Variable<int>(pushedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OplogCompanion(')
          ..write('localSeq: $localSeq, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('deviceId: $deviceId, ')
          ..write('lamport: $lamport, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('op: $op, ')
          ..write('valueBlob: $valueBlob, ')
          ..write('valueMeta: $valueMeta, ')
          ..write('pushedAt: $pushedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPullSeqMeta = const VerificationMeta(
    'lastPullSeq',
  );
  @override
  late final GeneratedColumn<int> lastPullSeq = GeneratedColumn<int>(
    'last_pull_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPushAtMeta = const VerificationMeta(
    'lastPushAt',
  );
  @override
  late final GeneratedColumn<int> lastPushAt = GeneratedColumn<int>(
    'last_push_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    lamport,
    lastPullSeq,
    lastPushAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('last_pull_seq')) {
      context.handle(
        _lastPullSeqMeta,
        lastPullSeq.isAcceptableOrUnknown(
          data['last_pull_seq']!,
          _lastPullSeqMeta,
        ),
      );
    }
    if (data.containsKey('last_push_at')) {
      context.handle(
        _lastPushAtMeta,
        lastPushAt.isAcceptableOrUnknown(
          data['last_push_at']!,
          _lastPushAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      lastPullSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_pull_seq'],
      )!,
      lastPushAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_push_at'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String deviceId;
  final int lamport;
  final int lastPullSeq;
  final int? lastPushAt;
  const SyncStateRow({
    required this.deviceId,
    required this.lamport,
    required this.lastPullSeq,
    this.lastPushAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['lamport'] = Variable<int>(lamport);
    map['last_pull_seq'] = Variable<int>(lastPullSeq);
    if (!nullToAbsent || lastPushAt != null) {
      map['last_push_at'] = Variable<int>(lastPushAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      deviceId: Value(deviceId),
      lamport: Value(lamport),
      lastPullSeq: Value(lastPullSeq),
      lastPushAt: lastPushAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      lamport: serializer.fromJson<int>(json['lamport']),
      lastPullSeq: serializer.fromJson<int>(json['lastPullSeq']),
      lastPushAt: serializer.fromJson<int?>(json['lastPushAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'lamport': serializer.toJson<int>(lamport),
      'lastPullSeq': serializer.toJson<int>(lastPullSeq),
      'lastPushAt': serializer.toJson<int?>(lastPushAt),
    };
  }

  SyncStateRow copyWith({
    String? deviceId,
    int? lamport,
    int? lastPullSeq,
    Value<int?> lastPushAt = const Value.absent(),
  }) => SyncStateRow(
    deviceId: deviceId ?? this.deviceId,
    lamport: lamport ?? this.lamport,
    lastPullSeq: lastPullSeq ?? this.lastPullSeq,
    lastPushAt: lastPushAt.present ? lastPushAt.value : this.lastPushAt,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      lastPullSeq: data.lastPullSeq.present
          ? data.lastPullSeq.value
          : this.lastPullSeq,
      lastPushAt: data.lastPushAt.present
          ? data.lastPushAt.value
          : this.lastPushAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('deviceId: $deviceId, ')
          ..write('lamport: $lamport, ')
          ..write('lastPullSeq: $lastPullSeq, ')
          ..write('lastPushAt: $lastPushAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, lamport, lastPullSeq, lastPushAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.deviceId == this.deviceId &&
          other.lamport == this.lamport &&
          other.lastPullSeq == this.lastPullSeq &&
          other.lastPushAt == this.lastPushAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> deviceId;
  final Value<int> lamport;
  final Value<int> lastPullSeq;
  final Value<int?> lastPushAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.deviceId = const Value.absent(),
    this.lamport = const Value.absent(),
    this.lastPullSeq = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String deviceId,
    required int lamport,
    this.lastPullSeq = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       lamport = Value(lamport);
  static Insertable<SyncStateRow> custom({
    Expression<String>? deviceId,
    Expression<int>? lamport,
    Expression<int>? lastPullSeq,
    Expression<int>? lastPushAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (lamport != null) 'lamport': lamport,
      if (lastPullSeq != null) 'last_pull_seq': lastPullSeq,
      if (lastPushAt != null) 'last_push_at': lastPushAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? lamport,
    Value<int>? lastPullSeq,
    Value<int?>? lastPushAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      deviceId: deviceId ?? this.deviceId,
      lamport: lamport ?? this.lamport,
      lastPullSeq: lastPullSeq ?? this.lastPullSeq,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (lastPullSeq.present) {
      map['last_pull_seq'] = Variable<int>(lastPullSeq.value);
    }
    if (lastPushAt.present) {
      map['last_push_at'] = Variable<int>(lastPushAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('lamport: $lamport, ')
          ..write('lastPullSeq: $lastPullSeq, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldLamportTable extends FieldLamport
    with TableInfo<$FieldLamportTable, FieldLamportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldLamportTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportMeta = const VerificationMeta(
    'lamport',
  );
  @override
  late final GeneratedColumn<int> lamport = GeneratedColumn<int>(
    'lamport',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entity,
    entityId,
    field,
    lamport,
    origin,
    opType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_lamport';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldLamportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('lamport')) {
      context.handle(
        _lamportMeta,
        lamport.isAcceptableOrUnknown(data['lamport']!, _lamportMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, entityId, field};
  @override
  FieldLamportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldLamportRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      lamport: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
    );
  }

  @override
  $FieldLamportTable createAlias(String alias) {
    return $FieldLamportTable(attachedDatabase, alias);
  }
}

class FieldLamportRow extends DataClass implements Insertable<FieldLamportRow> {
  final String entity;
  final String entityId;
  final String field;
  final int lamport;
  final String origin;
  final String opType;
  const FieldLamportRow({
    required this.entity,
    required this.entityId,
    required this.field,
    required this.lamport,
    required this.origin,
    required this.opType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['field'] = Variable<String>(field);
    map['lamport'] = Variable<int>(lamport);
    map['origin'] = Variable<String>(origin);
    map['op_type'] = Variable<String>(opType);
    return map;
  }

  FieldLamportCompanion toCompanion(bool nullToAbsent) {
    return FieldLamportCompanion(
      entity: Value(entity),
      entityId: Value(entityId),
      field: Value(field),
      lamport: Value(lamport),
      origin: Value(origin),
      opType: Value(opType),
    );
  }

  factory FieldLamportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldLamportRow(
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      field: serializer.fromJson<String>(json['field']),
      lamport: serializer.fromJson<int>(json['lamport']),
      origin: serializer.fromJson<String>(json['origin']),
      opType: serializer.fromJson<String>(json['opType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'field': serializer.toJson<String>(field),
      'lamport': serializer.toJson<int>(lamport),
      'origin': serializer.toJson<String>(origin),
      'opType': serializer.toJson<String>(opType),
    };
  }

  FieldLamportRow copyWith({
    String? entity,
    String? entityId,
    String? field,
    int? lamport,
    String? origin,
    String? opType,
  }) => FieldLamportRow(
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    field: field ?? this.field,
    lamport: lamport ?? this.lamport,
    origin: origin ?? this.origin,
    opType: opType ?? this.opType,
  );
  FieldLamportRow copyWithCompanion(FieldLamportCompanion data) {
    return FieldLamportRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      field: data.field.present ? data.field.value : this.field,
      lamport: data.lamport.present ? data.lamport.value : this.lamport,
      origin: data.origin.present ? data.origin.value : this.origin,
      opType: data.opType.present ? data.opType.value : this.opType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldLamportRow(')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('opType: $opType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entity, entityId, field, lamport, origin, opType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldLamportRow &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.field == this.field &&
          other.lamport == this.lamport &&
          other.origin == this.origin &&
          other.opType == this.opType);
}

class FieldLamportCompanion extends UpdateCompanion<FieldLamportRow> {
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> field;
  final Value<int> lamport;
  final Value<String> origin;
  final Value<String> opType;
  final Value<int> rowid;
  const FieldLamportCompanion({
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.field = const Value.absent(),
    this.lamport = const Value.absent(),
    this.origin = const Value.absent(),
    this.opType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldLamportCompanion.insert({
    required String entity,
    required String entityId,
    required String field,
    required int lamport,
    required String origin,
    required String opType,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       entityId = Value(entityId),
       field = Value(field),
       lamport = Value(lamport),
       origin = Value(origin),
       opType = Value(opType);
  static Insertable<FieldLamportRow> custom({
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? field,
    Expression<int>? lamport,
    Expression<String>? origin,
    Expression<String>? opType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (field != null) 'field': field,
      if (lamport != null) 'lamport': lamport,
      if (origin != null) 'origin': origin,
      if (opType != null) 'op_type': opType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldLamportCompanion copyWith({
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? field,
    Value<int>? lamport,
    Value<String>? origin,
    Value<String>? opType,
    Value<int>? rowid,
  }) {
    return FieldLamportCompanion(
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      field: field ?? this.field,
      lamport: lamport ?? this.lamport,
      origin: origin ?? this.origin,
      opType: opType ?? this.opType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (lamport.present) {
      map['lamport'] = Variable<int>(lamport.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldLamportCompanion(')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('lamport: $lamport, ')
          ..write('origin: $origin, ')
          ..write('opType: $opType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AgendumDatabase extends GeneratedDatabase {
  _$AgendumDatabase(QueryExecutor e) : super(e);
  $AgendumDatabaseManager get managers => $AgendumDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $AreasTable areas = $AreasTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $OplogTable oplog = $OplogTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $FieldLamportTable fieldLamport = $FieldLamportTable(this);
  late final Index idxTasksStatus = Index(
    'idx_tasks_status',
    'CREATE INDEX idx_tasks_status ON tasks (status, deleted_at)',
  );
  late final Index idxTasksDates = Index(
    'idx_tasks_dates',
    'CREATE INDEX idx_tasks_dates ON tasks (due_date, planned_date)',
  );
  late final Index idxProjectsStatus = Index(
    'idx_projects_status',
    'CREATE INDEX idx_projects_status ON projects (status, deleted_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    areas,
    projects,
    oplog,
    syncState,
    fieldLamport,
    idxTasksStatus,
    idxTasksDates,
    idxProjectsStatus,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      Value<String?> parentId,
      Value<String?> projectId,
      required String title,
      Value<String?> note,
      Value<String> status,
      Value<int?> startDate,
      Value<int?> dueDate,
      Value<int?> plannedDate,
      Value<int?> deferDate,
      Value<int?> completedAt,
      Value<int?> reminderAt,
      Value<String?> recurrence,
      Value<int?> estimateMinutes,
      Value<int?> actualMinutes,
      Value<String?> energy,
      Value<String?> waitingFor,
      required String sortKey,
      required int createdAt,
      required int updatedAt,
      required int lamport,
      required String origin,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String?> projectId,
      Value<String> title,
      Value<String?> note,
      Value<String> status,
      Value<int?> startDate,
      Value<int?> dueDate,
      Value<int?> plannedDate,
      Value<int?> deferDate,
      Value<int?> completedAt,
      Value<int?> reminderAt,
      Value<String?> recurrence,
      Value<int?> estimateMinutes,
      Value<int?> actualMinutes,
      Value<String?> energy,
      Value<String?> waitingFor,
      Value<String> sortKey,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lamport,
      Value<String> origin,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer
    extends Composer<_$AgendumDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deferDate => $composableBuilder(
    column: $table.deferDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waitingFor => $composableBuilder(
    column: $table.waitingFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AgendumDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deferDate => $composableBuilder(
    column: $table.deferDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waitingFor => $composableBuilder(
    column: $table.waitingFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AgendumDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deferDate =>
      $composableBuilder(column: $table.deferDate, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<String> get waitingFor => $composableBuilder(
    column: $table.waitingFor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AgendumDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AgendumDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AgendumDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> startDate = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<int?> plannedDate = const Value.absent(),
                Value<int?> deferDate = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> reminderAt = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<int?> actualMinutes = const Value.absent(),
                Value<String?> energy = const Value.absent(),
                Value<String?> waitingFor = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                parentId: parentId,
                projectId: projectId,
                title: title,
                note: note,
                status: status,
                startDate: startDate,
                dueDate: dueDate,
                plannedDate: plannedDate,
                deferDate: deferDate,
                completedAt: completedAt,
                reminderAt: reminderAt,
                recurrence: recurrence,
                estimateMinutes: estimateMinutes,
                actualMinutes: actualMinutes,
                energy: energy,
                waitingFor: waitingFor,
                sortKey: sortKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lamport: lamport,
                origin: origin,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> startDate = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<int?> plannedDate = const Value.absent(),
                Value<int?> deferDate = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> reminderAt = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<int?> actualMinutes = const Value.absent(),
                Value<String?> energy = const Value.absent(),
                Value<String?> waitingFor = const Value.absent(),
                required String sortKey,
                required int createdAt,
                required int updatedAt,
                required int lamport,
                required String origin,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                parentId: parentId,
                projectId: projectId,
                title: title,
                note: note,
                status: status,
                startDate: startDate,
                dueDate: dueDate,
                plannedDate: plannedDate,
                deferDate: deferDate,
                completedAt: completedAt,
                reminderAt: reminderAt,
                recurrence: recurrence,
                estimateMinutes: estimateMinutes,
                actualMinutes: actualMinutes,
                energy: energy,
                waitingFor: waitingFor,
                sortKey: sortKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lamport: lamport,
                origin: origin,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AgendumDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AgendumDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$AreasTableCreateCompanionBuilder =
    AreasCompanion Function({
      required String id,
      required String name,
      Value<String?> color,
      required String sortKey,
      required int createdAt,
      required int updatedAt,
      required int lamport,
      required String origin,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$AreasTableUpdateCompanionBuilder =
    AreasCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> color,
      Value<String> sortKey,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lamport,
      Value<String> origin,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$AreasTableFilterComposer
    extends Composer<_$AgendumDatabase, $AreasTable> {
  $$AreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AreasTableOrderingComposer
    extends Composer<_$AgendumDatabase, $AreasTable> {
  $$AreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AreasTableAnnotationComposer
    extends Composer<_$AgendumDatabase, $AreasTable> {
  $$AreasTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$AreasTableTableManager
    extends
        RootTableManager<
          _$AgendumDatabase,
          $AreasTable,
          Area,
          $$AreasTableFilterComposer,
          $$AreasTableOrderingComposer,
          $$AreasTableAnnotationComposer,
          $$AreasTableCreateCompanionBuilder,
          $$AreasTableUpdateCompanionBuilder,
          (Area, BaseReferences<_$AgendumDatabase, $AreasTable, Area>),
          Area,
          PrefetchHooks Function()
        > {
  $$AreasTableTableManager(_$AgendumDatabase db, $AreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion(
                id: id,
                name: name,
                color: color,
                sortKey: sortKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lamport: lamport,
                origin: origin,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> color = const Value.absent(),
                required String sortKey,
                required int createdAt,
                required int updatedAt,
                required int lamport,
                required String origin,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion.insert(
                id: id,
                name: name,
                color: color,
                sortKey: sortKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lamport: lamport,
                origin: origin,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AgendumDatabase,
      $AreasTable,
      Area,
      $$AreasTableFilterComposer,
      $$AreasTableOrderingComposer,
      $$AreasTableAnnotationComposer,
      $$AreasTableCreateCompanionBuilder,
      $$AreasTableUpdateCompanionBuilder,
      (Area, BaseReferences<_$AgendumDatabase, $AreasTable, Area>),
      Area,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      Value<String?> parentId,
      Value<String?> areaId,
      required String name,
      Value<String?> note,
      Value<String> status,
      Value<int?> reviewCadenceDays,
      Value<String?> nextActionId,
      required String sortKey,
      required int createdAt,
      required int updatedAt,
      required int lamport,
      required String origin,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String?> areaId,
      Value<String> name,
      Value<String?> note,
      Value<String> status,
      Value<int?> reviewCadenceDays,
      Value<String?> nextActionId,
      Value<String> sortKey,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lamport,
      Value<String> origin,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AgendumDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCadenceDays => $composableBuilder(
    column: $table.reviewCadenceDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextActionId => $composableBuilder(
    column: $table.nextActionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AgendumDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCadenceDays => $composableBuilder(
    column: $table.reviewCadenceDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextActionId => $composableBuilder(
    column: $table.nextActionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AgendumDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get reviewCadenceDays => $composableBuilder(
    column: $table.reviewCadenceDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextActionId => $composableBuilder(
    column: $table.nextActionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AgendumDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AgendumDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AgendumDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> areaId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> reviewCadenceDays = const Value.absent(),
                Value<String?> nextActionId = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                parentId: parentId,
                areaId: areaId,
                name: name,
                note: note,
                status: status,
                reviewCadenceDays: reviewCadenceDays,
                nextActionId: nextActionId,
                sortKey: sortKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lamport: lamport,
                origin: origin,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                Value<String?> areaId = const Value.absent(),
                required String name,
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> reviewCadenceDays = const Value.absent(),
                Value<String?> nextActionId = const Value.absent(),
                required String sortKey,
                required int createdAt,
                required int updatedAt,
                required int lamport,
                required String origin,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                parentId: parentId,
                areaId: areaId,
                name: name,
                note: note,
                status: status,
                reviewCadenceDays: reviewCadenceDays,
                nextActionId: nextActionId,
                sortKey: sortKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lamport: lamport,
                origin: origin,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgendumDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AgendumDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$OplogTableCreateCompanionBuilder =
    OplogCompanion Function({
      Value<int> localSeq,
      Value<int?> serverSeq,
      required String deviceId,
      required int lamport,
      required String entity,
      required String entityId,
      required String field,
      required String op,
      Value<String?> valueBlob,
      Value<String?> valueMeta,
      Value<int?> pushedAt,
    });
typedef $$OplogTableUpdateCompanionBuilder =
    OplogCompanion Function({
      Value<int> localSeq,
      Value<int?> serverSeq,
      Value<String> deviceId,
      Value<int> lamport,
      Value<String> entity,
      Value<String> entityId,
      Value<String> field,
      Value<String> op,
      Value<String?> valueBlob,
      Value<String?> valueMeta,
      Value<int?> pushedAt,
    });

class $$OplogTableFilterComposer
    extends Composer<_$AgendumDatabase, $OplogTable> {
  $$OplogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localSeq => $composableBuilder(
    column: $table.localSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueBlob => $composableBuilder(
    column: $table.valueBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueMeta => $composableBuilder(
    column: $table.valueMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OplogTableOrderingComposer
    extends Composer<_$AgendumDatabase, $OplogTable> {
  $$OplogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localSeq => $composableBuilder(
    column: $table.localSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueBlob => $composableBuilder(
    column: $table.valueBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueMeta => $composableBuilder(
    column: $table.valueMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pushedAt => $composableBuilder(
    column: $table.pushedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OplogTableAnnotationComposer
    extends Composer<_$AgendumDatabase, $OplogTable> {
  $$OplogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localSeq =>
      $composableBuilder(column: $table.localSeq, builder: (column) => column);

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get valueBlob =>
      $composableBuilder(column: $table.valueBlob, builder: (column) => column);

  GeneratedColumn<String> get valueMeta =>
      $composableBuilder(column: $table.valueMeta, builder: (column) => column);

  GeneratedColumn<int> get pushedAt =>
      $composableBuilder(column: $table.pushedAt, builder: (column) => column);
}

class $$OplogTableTableManager
    extends
        RootTableManager<
          _$AgendumDatabase,
          $OplogTable,
          OplogRow,
          $$OplogTableFilterComposer,
          $$OplogTableOrderingComposer,
          $$OplogTableAnnotationComposer,
          $$OplogTableCreateCompanionBuilder,
          $$OplogTableUpdateCompanionBuilder,
          (OplogRow, BaseReferences<_$AgendumDatabase, $OplogTable, OplogRow>),
          OplogRow,
          PrefetchHooks Function()
        > {
  $$OplogTableTableManager(_$AgendumDatabase db, $OplogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OplogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OplogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OplogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localSeq = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String?> valueBlob = const Value.absent(),
                Value<String?> valueMeta = const Value.absent(),
                Value<int?> pushedAt = const Value.absent(),
              }) => OplogCompanion(
                localSeq: localSeq,
                serverSeq: serverSeq,
                deviceId: deviceId,
                lamport: lamport,
                entity: entity,
                entityId: entityId,
                field: field,
                op: op,
                valueBlob: valueBlob,
                valueMeta: valueMeta,
                pushedAt: pushedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> localSeq = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                required String deviceId,
                required int lamport,
                required String entity,
                required String entityId,
                required String field,
                required String op,
                Value<String?> valueBlob = const Value.absent(),
                Value<String?> valueMeta = const Value.absent(),
                Value<int?> pushedAt = const Value.absent(),
              }) => OplogCompanion.insert(
                localSeq: localSeq,
                serverSeq: serverSeq,
                deviceId: deviceId,
                lamport: lamport,
                entity: entity,
                entityId: entityId,
                field: field,
                op: op,
                valueBlob: valueBlob,
                valueMeta: valueMeta,
                pushedAt: pushedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OplogTableProcessedTableManager =
    ProcessedTableManager<
      _$AgendumDatabase,
      $OplogTable,
      OplogRow,
      $$OplogTableFilterComposer,
      $$OplogTableOrderingComposer,
      $$OplogTableAnnotationComposer,
      $$OplogTableCreateCompanionBuilder,
      $$OplogTableUpdateCompanionBuilder,
      (OplogRow, BaseReferences<_$AgendumDatabase, $OplogTable, OplogRow>),
      OplogRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String deviceId,
      required int lamport,
      Value<int> lastPullSeq,
      Value<int?> lastPushAt,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> deviceId,
      Value<int> lamport,
      Value<int> lastPullSeq,
      Value<int?> lastPushAt,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AgendumDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPullSeq => $composableBuilder(
    column: $table.lastPullSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AgendumDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPullSeq => $composableBuilder(
    column: $table.lastPullSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AgendumDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<int> get lastPullSeq => $composableBuilder(
    column: $table.lastPullSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AgendumDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AgendumDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AgendumDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<int> lastPullSeq = const Value.absent(),
                Value<int?> lastPushAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                deviceId: deviceId,
                lamport: lamport,
                lastPullSeq: lastPullSeq,
                lastPushAt: lastPushAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int lamport,
                Value<int> lastPullSeq = const Value.absent(),
                Value<int?> lastPushAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                deviceId: deviceId,
                lamport: lamport,
                lastPullSeq: lastPullSeq,
                lastPushAt: lastPushAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AgendumDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AgendumDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$FieldLamportTableCreateCompanionBuilder =
    FieldLamportCompanion Function({
      required String entity,
      required String entityId,
      required String field,
      required int lamport,
      required String origin,
      required String opType,
      Value<int> rowid,
    });
typedef $$FieldLamportTableUpdateCompanionBuilder =
    FieldLamportCompanion Function({
      Value<String> entity,
      Value<String> entityId,
      Value<String> field,
      Value<int> lamport,
      Value<String> origin,
      Value<String> opType,
      Value<int> rowid,
    });

class $$FieldLamportTableFilterComposer
    extends Composer<_$AgendumDatabase, $FieldLamportTable> {
  $$FieldLamportTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FieldLamportTableOrderingComposer
    extends Composer<_$AgendumDatabase, $FieldLamportTable> {
  $$FieldLamportTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamport => $composableBuilder(
    column: $table.lamport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FieldLamportTableAnnotationComposer
    extends Composer<_$AgendumDatabase, $FieldLamportTable> {
  $$FieldLamportTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<int> get lamport =>
      $composableBuilder(column: $table.lamport, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);
}

class $$FieldLamportTableTableManager
    extends
        RootTableManager<
          _$AgendumDatabase,
          $FieldLamportTable,
          FieldLamportRow,
          $$FieldLamportTableFilterComposer,
          $$FieldLamportTableOrderingComposer,
          $$FieldLamportTableAnnotationComposer,
          $$FieldLamportTableCreateCompanionBuilder,
          $$FieldLamportTableUpdateCompanionBuilder,
          (
            FieldLamportRow,
            BaseReferences<
              _$AgendumDatabase,
              $FieldLamportTable,
              FieldLamportRow
            >,
          ),
          FieldLamportRow,
          PrefetchHooks Function()
        > {
  $$FieldLamportTableTableManager(
    _$AgendumDatabase db,
    $FieldLamportTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldLamportTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldLamportTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldLamportTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<int> lamport = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FieldLamportCompanion(
                entity: entity,
                entityId: entityId,
                field: field,
                lamport: lamport,
                origin: origin,
                opType: opType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String entityId,
                required String field,
                required int lamport,
                required String origin,
                required String opType,
                Value<int> rowid = const Value.absent(),
              }) => FieldLamportCompanion.insert(
                entity: entity,
                entityId: entityId,
                field: field,
                lamport: lamport,
                origin: origin,
                opType: opType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FieldLamportTableProcessedTableManager =
    ProcessedTableManager<
      _$AgendumDatabase,
      $FieldLamportTable,
      FieldLamportRow,
      $$FieldLamportTableFilterComposer,
      $$FieldLamportTableOrderingComposer,
      $$FieldLamportTableAnnotationComposer,
      $$FieldLamportTableCreateCompanionBuilder,
      $$FieldLamportTableUpdateCompanionBuilder,
      (
        FieldLamportRow,
        BaseReferences<_$AgendumDatabase, $FieldLamportTable, FieldLamportRow>,
      ),
      FieldLamportRow,
      PrefetchHooks Function()
    >;

class $AgendumDatabaseManager {
  final _$AgendumDatabase _db;
  $AgendumDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$AreasTableTableManager get areas =>
      $$AreasTableTableManager(_db, _db.areas);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$OplogTableTableManager get oplog =>
      $$OplogTableTableManager(_db, _db.oplog);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$FieldLamportTableTableManager get fieldLamport =>
      $$FieldLamportTableTableManager(_db, _db.fieldLamport);
}
