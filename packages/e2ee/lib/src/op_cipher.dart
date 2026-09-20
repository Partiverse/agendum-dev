/// op 负载加密（03 文档 §6.2）：实现 packages/sync 的 [OpCodec]。
///
/// - `set` op 的 value 整体加密为 `OpValue('enc', {n, c, m})`
///   （nonce/ciphertext/mac 各自 base64）；`del` op 无负载原样通过。
/// - AAD 绑定裁决元数据（device/lamport/entity/entityId/field）——
///   字段名按设计保持明文（服务端裁决需要），值不可见（§6.2 表）。
/// - 解密时 AAD 不符即认证失败：跨字段/跨实体搬运密文会被拒。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';

import 'aead.dart';

class E2eeOpCodec implements OpCodec {
  E2eeOpCodec(List<int> dataKey) : _dataKey = Uint8List.fromList(dataKey) {
    if (_dataKey.length != 32) {
      throw ArgumentError.value(_dataKey.length, 'dataKey', 'DK 须为 32 字节');
    }
  }

  static const _aadPrefix = 'agendum/op-v1';

  final Uint8List _dataKey;

  String _aad(SyncOp op) =>
      '$_aadPrefix|${op.deviceId}|${op.lamport}|${op.entity}|'
      '${op.entityId}|${op.field}';

  @override
  Future<SyncOp> encodeForWire(SyncOp op) async {
    if (op.type != SyncOpType.set || op.value == null) return op;
    final plain = utf8.encode(jsonEncode(op.value!.toJson()));
    final sealed = await XchachaAead.seal(
      key: _dataKey,
      plaintext: plain,
      aad: utf8.encode(_aad(op)),
    );
    final payload = <String, String>{
      'n': base64Encode(sealed.sublist(0, 24)),
      'c': base64Encode(sealed.sublist(24, sealed.length - 16)),
      'm': base64Encode(sealed.sublist(sealed.length - 16)),
    };
    return _withValue(op, OpValue(OpValueTypes.enc, payload));
  }

  @override
  Future<SyncOp> decodeFromWire(SyncOp op) async {
    final value = op.value;
    if (op.type != SyncOpType.set || value == null) return op;
    if (value.type != OpValueTypes.enc) return op; // 明文模式/前向兼容
    final payload = (value.value as Map? ?? const {}).cast<String, Object?>();
    final sealed = <int>[
      ...base64Decode(payload['n']! as String),
      ...base64Decode(payload['c']! as String),
      ...base64Decode(payload['m']! as String),
    ];
    final plain = await XchachaAead.open(
      key: _dataKey,
      sealed: sealed,
      aad: utf8.encode(_aad(op)),
    );
    return _withValue(
      op,
      OpValue.fromJson(
        (jsonDecode(utf8.decode(plain)) as Map).cast<String, Object?>(),
      ),
    );
  }

  SyncOp _withValue(SyncOp op, OpValue value) => SyncOp(
    deviceId: op.deviceId,
    lamport: op.lamport,
    entity: op.entity,
    entityId: op.entityId,
    field: op.field,
    type: op.type,
    value: value,
    baseSeq: op.baseSeq,
  );
}
