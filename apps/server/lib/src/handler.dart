/// 路由与处理器。
///
/// 同步契约（03 文档 §4.2）已在 PoC 中实现：push 分配全局序号并维护
/// 字段裁决表，pull 按 cursor 增量续传。AI 网关（04 文档 §5.2）提供
/// `/v1/ai/parse` 云端回落端点：分级强制 + 额度账本 + 可插拔适配器。
/// 存储经 [SyncStore] 抽象——默认内存实现，设 DATABASE_URL 时用
/// Postgres（bin/server.dart 装配）。S07 起提供 `/v1/devices/register`
/// 设备注册（E2EE 密钥指纹绑定,03 文档 §6.1）。错误响应统一 JSON。
///
/// R1 信任革命（蓝图 §2）：服务端退为不可信中继——只做签名验证、
/// 租户隔离与密文中继，永不接触明文任务数据：
/// - `GET /v1/auth/challenge`：单次 nonce 挑战（挑战表随部署：内存/PG
///   共享表，≤5 分钟 TTL，ADR-016 §1）；
/// - 注册验签（Ed25519,不过 400）+ uid 归属证明（ADR-016 §6 注册准入）
///   + device→uid 绑定；
/// - push/pull/envelope 一律要求 `X-Agendum-Auth`（无签名 401）；
/// - oplog 按 owner=uid 隔离；`/v1/vault/envelope` 不透明信封存取。
library;

import 'dart:convert';

import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai/adapter.dart';
import 'ai/quota.dart';
import 'ai/routes.dart';
import 'auth.dart';
import 'middleware.dart';
import 'store/devices.dart';
import 'store/envelopes.dart';
import 'store/memory_store.dart';
import 'store/sync_store.dart';

Response _json(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Handler buildHandler({
  SyncStore? store,
  DeviceDirectory? devices,
  VaultEnvelopeStore? envelopes,
  NonceStore? nonces,
  CaptureModelAdapter? aiAdapter,
  QuotaLedger? quotaLedger,
  int aiMonthlyLimit = 30,
  String version = '0.0.1',
}) {
  final sync = store ?? MemorySyncStore();
  final deviceDir = devices ?? MemoryDeviceDirectory();
  final envelopeStore = envelopes ?? MemoryVaultEnvelopeStore();
  final nonceTab = nonces ?? NonceTable();
  final adapter = aiAdapter ?? ServerRulesAdapter();
  final ai = aiRoutes(
    adapter: adapter,
    quota: quotaLedger ?? MemoryQuotaLedger(monthlyLimit: aiMonthlyLimit),
  );

  // push/pull/envelope 的鉴权守卫（R1 §4）；挑战/注册/健康/AI 不要求。
  Handler guarded(Handler inner) => Pipeline()
      .addMiddleware(deviceAuthMiddleware(devices: deviceDir, nonces: nonceTab))
      .addHandler(inner);

  final router = Router()
    ..get(
      '/v1/health',
      (Request req) => _json({
        'ok': true,
        'service': 'agendum-server',
        'version': version,
        'protocol': protocolVersion,
        'store': sync.runtimeType.toString(),
        'ai_adapter': adapter.name,
      }),
    )
    // R1 §2：单次 nonce 挑战。未注册设备也可取（nonce 本身无权,鉴权时
    // 仍要过注册公钥验签）。
    ..get('/v1/auth/challenge', (Request req) async {
      final deviceId = req.url.queryParameters['device_id'];
      if (deviceId == null || deviceId.isEmpty) {
        return _json({
          'error': 'bad_request',
          'message': 'device_id 必填',
        }, status: 400);
      }
      return _json((await nonceTab.issue()).toJson());
    })
    ..post(
      '/v1/sync/push',
      guarded((Request req) async {
        final authed = authedDeviceOf(req.context);
        if (authed == null) return unauthorized('未鉴权');
        final Map<String, Object?> body;
        try {
          body = (jsonDecode(await req.readAsString()) as Map)
              .cast<String, Object?>();
        } on FormatException {
          return _json({
            'error': 'bad_request',
            'message': 'body 不是合法 JSON',
          }, status: 400);
        }
        final PushRequest pushReq;
        try {
          pushReq = PushRequest.fromJson(body);
        } on FormatException catch (e) {
          return _json({
            'error': 'bad_request',
            'message': e.message,
          }, status: 400);
        }
        // R1 §4/§5：请求 uid 必须与注册 uid 一致，否则 401。
        if (pushReq.uid != authed.uid) {
          return unauthorized('push.uid 与注册租户不符');
        }
        final resp = await sync.push(pushReq);
        return _json(resp.toJson());
      }),
    )
    ..get(
      '/v1/sync/pull',
      guarded((Request req) async {
        final authed = authedDeviceOf(req.context);
        if (authed == null) return unauthorized('未鉴权');
        final since = int.tryParse(req.url.queryParameters['since'] ?? '');
        if (since == null || since < 0) {
          return _json({
            'error': 'bad_request',
            'message': 'since 必填且 ≥0',
          }, status: 400);
        }
        final uid = req.url.queryParameters['uid'];
        if (uid == null || uid.isEmpty) {
          return _json({
            'error': 'bad_request',
            'message': 'uid 必填（R1 §5 租户隔离）',
          }, status: 400);
        }
        if (uid != authed.uid) {
          return unauthorized('pull.uid 与注册租户不符');
        }
        final limit =
            int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 2000;
        final resp = await sync.pull(since: since, limit: limit, owner: uid);
        return _json(resp.toJson());
      }),
    )
    ..post('/v1/devices/register', (Request req) async {
      final Map<String, Object?> body;
      try {
        body = (jsonDecode(await req.readAsString()) as Map)
            .cast<String, Object?>();
      } on FormatException {
        return _json({
          'error': 'bad_request',
          'message': 'body 不是合法 JSON',
        }, status: 400);
      }
      final DeviceRegistrationRequest regReq;
      try {
        regReq = DeviceRegistrationRequest.fromJson(body);
      } on FormatException catch (e) {
        return _json({
          'error': 'bad_request',
          'message': e.message,
        }, status: 400);
      }
      // R1 §3：注册验签——sig_b64 必须是设备私钥对
      // `agendum/register:<fingerprint>` 的签名，用上传公钥验证,不过 400。
      // 校验顺序:先指纹自洽（签名原文的锚点,S07 语义）,再验签。
      if (regReq.algorithm != deviceKeyAlgorithm) {
        return _json({
          'error': 'bad_request',
          'message': 'algorithm 仅支持 $deviceKeyAlgorithm',
        }, status: 400);
      }
      if (regReq.pubkeyB64 != regReq.publicKeyB64) {
        return _json({
          'error': 'bad_request',
          'message': 'pubkey_b64 必须与 public_key 一致（指纹锚定的验签公钥）',
        }, status: 400);
      }
      final computedFingerprint = fingerprintFromKeyBytes(
        base64Decode(regReq.publicKeyB64),
      );
      if (computedFingerprint != regReq.fingerprint) {
        return _json({
          'error': 'fingerprint_mismatch',
          'message': FingerprintMismatch(
            regReq.fingerprint,
            computedFingerprint,
          ).toString(),
        }, status: 400);
      }
      // 注册准入（ADR-016 §6）：uid 归属证明——uid 必须等于
      // hex(HKDF(uid_proof))，证明注册者持有派生出该 uid 的 MK。
      // 只知 uid（如从服务端 DB 读到）无 proof 即被拒，防「知悉 uid 即
      // 可把设备注册进任意租户」。明文开发租户豁免（无 Vault，共用租户）。
      if (regReq.uid != devPlaintextUid) {
        final proofB64 = regReq.uidProofB64;
        if (proofB64 == null) {
          return _json({
            'error': 'uid_proof_missing',
            'message': 'uid_proof 缺失：注册须携带 uid 归属证明（ADR-016 §6）',
          }, status: 400);
        }
        final proofOk = await verifyUidOwnership(
          uid: regReq.uid,
          uidProof: base64Decode(proofB64),
        );
        if (!proofOk) {
          return _json({
            'error': 'uid_proof_mismatch',
            'message': 'uid 归属证明不符：uid ≠ hex(HKDF(uid_proof))',
          }, status: 400);
        }
      }
      final sigOk = await verifyEd25519(
        message: utf8.encode(registerSignatureMessage(regReq.fingerprint)),
        publicKeyB64: regReq.pubkeyB64,
        sigB64: regReq.sigB64,
      );
      if (!sigOk) {
        return _json({
          'error': 'signature_mismatch',
          'message': '注册签名验证失败',
        }, status: 400);
      }
      try {
        final resp = await deviceDir.register(regReq);
        return _json(resp.toJson());
      } on FingerprintMismatch catch (e) {
        return _json({
          'error': 'fingerprint_mismatch',
          'message': e.toString(),
        }, status: 400);
      } on ArgumentError catch (e) {
        return _json({
          'error': 'bad_request',
          'message': e.message ?? '非法参数',
        }, status: 400);
      }
    })
    // R1 §6：多设备信封（服务端不透明存储,仅限本 uid 设备读写）。
    ..post(
      '/v1/vault/envelope',
      guarded((Request req) async {
        final authed = authedDeviceOf(req.context);
        if (authed == null) return unauthorized('未鉴权');
        final Map<String, Object?> body;
        try {
          body = (jsonDecode(await req.readAsString()) as Map)
              .cast<String, Object?>();
        } on FormatException {
          return _json({
            'error': 'bad_request',
            'message': 'body 不是合法 JSON',
          }, status: 400);
        }
        final VaultEnvelope envelope;
        try {
          envelope = VaultEnvelope.fromJson(body);
        } on FormatException catch (e) {
          return _json({
            'error': 'bad_request',
            'message': e.message,
          }, status: 400);
        }
        if (envelope.uid != authed.uid) {
          return unauthorized('envelope.uid 与注册租户不符');
        }
        await envelopeStore.put(envelope);
        return _json({'ok': true});
      }),
    )
    ..get(
      '/v1/vault/envelope',
      guarded((Request req) async {
        final authed = authedDeviceOf(req.context);
        if (authed == null) return unauthorized('未鉴权');
        final uid = req.url.queryParameters['uid'];
        if (uid == null || uid.isEmpty) {
          return _json({
            'error': 'bad_request',
            'message': 'uid 必填',
          }, status: 400);
        }
        if (uid != authed.uid) {
          return unauthorized('envelope.uid 与注册租户不符');
        }
        final latest = await envelopeStore.latest(uid);
        if (latest == null) {
          return _json({
            'error': 'not_found',
            'message': '该 uid 无信封',
          }, status: 404);
        }
        return _json(latest.toJson());
      }),
    )
    // catch-all 路由须最后注册，AI 网关内部自带 404 兜底。
    ..mount('/', ai.call);

  return Pipeline().addMiddleware(corsMiddleware()).addHandler(router.call);
}
