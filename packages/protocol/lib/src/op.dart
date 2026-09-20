/// oplog 字段级变更记录（03 文档 §4.1）。
///
/// E2EE 模式下 [SyncOp.toJson] 的 `value` 整体加密为 `value_blob`，明文元数据
/// （lamport/origin/field/entity）供服务端裁决（03 文档 §6.2）。
library;

/// 同步实体类型（与 DDL 表名一致）。
abstract final class SyncEntities {
  static const task = 'task';
  static const project = 'project';
  static const area = 'area';
  static const tag = 'tag';
  static const tagGroup = 'tag_group';
  static const taskTag = 'task_tag';
  static const timeBlock = 'time_block';
  static const timeEntry = 'time_entry';
  static const review = 'review';
  static const aiMemory = 'ai_memory';
  static const perspective = 'perspective';
}

/// 整行创建时使用的伪字段名（03 文档 DDL 注释）。
const String rowCreateField = '__row';

enum SyncOpType { set, del }

String syncOpTypeToJson(SyncOpType t) => t.name;

SyncOpType syncOpTypeFromJson(String v) => switch (v) {
  'set' => SyncOpType.set,
  'del' => SyncOpType.del,
  _ => throw FormatException('未知 op 类型: $v'),
};

/// 字段值的类型标签 `t`（密文模式下加密方自行编码，此处为明文模式约定）。
abstract final class OpValueTypes {
  static const str = 'str';
  static const intT = 'int';
  static const boolT = 'bool';
  static const doubleT = 'double';
  static const date = 'date'; // epoch days
  static const ms = 'ms'; // epoch ms
  static const json = 'json';

  /// E2EE 密文（S07）：v = {n: nonce, c: ciphertext, m: mac}（base64）。
  /// 服务端不解读，按不透明负载转发（03 文档 §6.2）。
  static const enc = 'enc';
}

/// 带类型标签的字段值：`{"t": "date", "v": 20650}`。
class OpValue {
  const OpValue(this.type, this.value);

  final String type;
  final Object? value;

  Map<String, Object?> toJson() => {'t': type, 'v': value};

  factory OpValue.fromJson(Map<String, Object?> json) {
    final t = json['t'];
    if (t is! String || t.isEmpty) {
      throw const FormatException('OpValue 缺少类型标签 t');
    }
    return OpValue(t, json['v']);
  }

  @override
  bool operator ==(Object other) =>
      other is OpValue && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'OpValue($type, $value)';
}

/// 一条字段级变更。
class SyncOp {
  const SyncOp({
    required this.deviceId,
    required this.lamport,
    required this.entity,
    required this.entityId,
    required this.field,
    required this.type,
    this.value,
    this.baseSeq,
  }) : assert(type != SyncOpType.set || value != null, 'set 操作必须携带 value');

  final String deviceId;
  final int lamport;
  final String entity;
  final String entityId;
  final String field; // '__row' 表示整行创建
  final SyncOpType type;
  final OpValue? value; // del 时为 null
  final int? baseSeq; // 客户端最后同步位点，可选

  Map<String, Object?> toJson() => {
    'device_id': deviceId,
    'lamport': lamport,
    'entity': entity,
    'entity_id': entityId,
    'field': field,
    'op': syncOpTypeToJson(type),
    if (value != null) 'value': value!.toJson(),
    if (baseSeq != null) 'base_seq': baseSeq,
  };

  factory SyncOp.fromJson(Map<String, Object?> json) {
    final deviceId = json['device_id'];
    final lamport = json['lamport'];
    final entity = json['entity'];
    final entityId = json['entity_id'];
    final field = json['field'];
    final op = json['op'];
    if (deviceId is! String || deviceId.isEmpty) {
      throw const FormatException('op.device_id 缺失或非法');
    }
    if (lamport is! int || lamport < 0) {
      throw const FormatException('op.lamport 缺失或非法');
    }
    if (entity is! String || entityId is! String || field is! String) {
      throw const FormatException('op.entity/entity_id/field 缺失或非法');
    }
    if (op is! String) throw const FormatException('op.op 缺失');
    final type = syncOpTypeFromJson(op);
    final rawValue = json['value'];
    if (type == SyncOpType.set) {
      if (rawValue is! Map<String, Object?>) {
        throw const FormatException('set 操作缺少 value 对象');
      }
      return SyncOp(
        deviceId: deviceId,
        lamport: lamport,
        entity: entity,
        entityId: entityId,
        field: field,
        type: type,
        value: OpValue.fromJson(rawValue),
        baseSeq: json['base_seq'] as int?,
      );
    }
    return SyncOp(
      deviceId: deviceId,
      lamport: lamport,
      entity: entity,
      entityId: entityId,
      field: field,
      type: type,
      baseSeq: json['base_seq'] as int?,
    );
  }

  @override
  String toString() => 'SyncOp(${toJson()})';
}
