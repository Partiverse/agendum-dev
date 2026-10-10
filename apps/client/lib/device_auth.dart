/// 客户端侧设备鉴权组装(R1 §2/§3/§4/§9):
///
/// - 注册:扩展后的 `POST /v1/devices/register`,body 携带 uid、uid_proof
///   (uid 归属证明,ADR-016 §6)、pubkey_b64 与 sig_b64(设备私钥对
///   `agendum/register:` + fingerprint 的签名);
/// - 鉴权头:每个 push/pull 请求先 `GET /v1/auth/challenge?device_id=X`
///   取一次性 nonce,再以设备私钥签名 `agendum/auth:` + device_id + ':' +
///   nonce_b64,组装 `X-Agendum-Auth: v1 <device_id> <nonce_b64> <sig_b64>`。
///
/// nonce 缓存:只缓存「已取未用」的一条([prefetch] 预取),消费即清除;
/// 过期挑战不使用。并发请求各自取新挑战 —— nonce 单次有效,复用必 401。
/// 组装在本包(apps/client)完成:sync 包不得反向依赖 e2ee(R1 §9)。
library;

import 'dart:convert';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:http/http.dart' as http;

/// 挑战相对过期余量(ms):本地时钟可能略快于服务端,到期前 2s 即视为不可用。
const int _challengeSkewMs = 2000;

class DeviceAuthService {
  DeviceAuthService({
    required this.base,
    required this.deviceId,
    required this.keys,
    required this.uid,
    this.uidProofB64,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 同步服务端基址(挑战与注册走同一 base,R1 §9)。
  final String base;

  /// 本设备 ID(与 push 的 op.device_id 同源,注册时与公钥绑定)。
  final String deviceId;

  /// 设备 Ed25519 密钥对(签名与注册验签公钥)。
  final DeviceKeys keys;

  /// 租户 uid(注册时绑 device→uid;服务端校验请求 uid 与之一致)。
  final String uid;

  /// uid 归属证明(ADR-016 §6,base64):非明文租户必带,服务端验证
  /// uid = HKDF(uid_proof)。明文开发租户(dev-plain)为 null。
  final String? uidProofB64;

  final http.Client _client;

  /// 已取未用的挑战(至多一条);被一次鉴权头消费后即清除。
  AuthChallenge? _cachedNonce;

  /// 本进程内已确认注册成功(服务端幂等,重复注册不换绑公钥)。
  bool _registered = false;

  @override
  String toString() => 'DeviceAuthService($deviceId)'; // 不含密钥材料

  /// 预取一条挑战入缓存(可选优化:下一请求免一次往返)。
  /// 已有未用挑战时不重复请求。
  Future<void> prefetch() async {
    if (_cachedNonce != null) return;
    _cachedNonce = await _fetchChallenge();
  }

  /// 鉴权头钩子(RestSyncTransport.authHeaders):每请求先确保已注册,
  /// 再取新 nonce 并签名。
  ///
  /// 注册走懒确认而非启动时阻塞:首个签名请求前完成注册,天然消除
  /// 「注册与首推赛跑」;服务端暂不可达时,注册失败随请求上抛,下一轮
  /// 重试(once 缓存只在成功后置位)。
  Future<Map<String, String>> authHeaders() async {
    if (!_registered) {
      await register();
      _registered = true;
    }
    final nonce = _takeCachedNonce() ?? await _fetchChallenge();
    final sig = await keys.sign(
      utf8.encode(authSignatureMessage(deviceId, nonce.nonceB64)),
    );
    return {
      authHeaderName: buildAuthHeader(
        deviceId: deviceId,
        nonceB64: nonce.nonceB64,
        sigB64: base64Encode(sig.bytes),
      ),
    };
  }

  /// 设备注册(R1 §3 + ADR-016 §6):上送公钥、uid 归属证明与注册签名,
  /// 服务端验签并绑 device→uid。
  /// 「同 fingerprint 重复注册不换绑公钥」的幂等语义由服务端保证。
  Future<void> register() async {
    final sig = await keys.sign(
      utf8.encode(registerSignatureMessage(keys.fingerprint)),
    );
    final req = DeviceRegistrationRequest(
      deviceId: deviceId,
      algorithm: deviceKeyAlgorithm,
      publicKeyB64: keys.publicKeyB64,
      fingerprint: keys.fingerprint,
      uid: uid,
      uidProofB64: uidProofB64,
      pubkeyB64: keys.publicKeyB64,
      sigB64: base64Encode(sig.bytes),
    );
    final resp = await _client.post(
      Uri.parse('$base/v1/devices/register'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (resp.statusCode != 200) {
      throw SyncTransportException(
        '设备注册失败 HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    // 响应最小校验:协议层 DeviceRegistrationResponse 尚无 fromJson,
    // 这里只认「ok == true」—— 缺字段/拒绝即抛,不让坏响应静默通过。
    final body = (jsonDecode(resp.body) as Map).cast<String, Object?>();
    if (body['ok'] != true) {
      throw SyncTransportException(
        '设备注册被拒: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
  }

  AuthChallenge? _takeCachedNonce() {
    final nonce = _cachedNonce;
    if (nonce == null) return null;
    _cachedNonce = null; // 缓存只消费一次
    if (!_isUsable(nonce)) return null; // 过期即弃,走新挑战
    return nonce;
  }

  bool _isUsable(AuthChallenge nonce) =>
      nonce.expiresAtMs >
      DateTime.now().millisecondsSinceEpoch + _challengeSkewMs;

  Future<AuthChallenge> _fetchChallenge() async {
    final resp = await _client.get(
      Uri.parse(
        '$base/v1/auth/challenge',
      ).replace(queryParameters: {'device_id': deviceId}),
    );
    if (resp.statusCode != 200) {
      throw SyncTransportException(
        '挑战获取失败 HTTP ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    return AuthChallenge.fromJson(
      (jsonDecode(resp.body) as Map).cast<String, Object?>(),
    );
  }
}
