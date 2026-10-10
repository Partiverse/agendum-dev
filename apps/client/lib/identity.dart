/// 信任身份装配(R1 §1/§7):明文门禁、Vault(短语→MK→uid→codec)与
/// 设备密钥的装载/创建。
///
/// 密钥只进 [KeyStore](生产 SecureStorageKeyStore,测试 InMemoryKeyStore),
/// 不落 SQLite、不进日志;恢复短语仅经只读 getter 暴露(供未来 onboarding
/// UI 展示/确认),任何路径不得打印。
library;

import 'dart:convert';
import 'dart:math';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_sync/agendum_sync.dart';

/// 构建期明文声明(R1 §7):只有 `-DAGENDUM_PLAINTEXT=true` 构建才允许
/// IdentityOpCodec 上线。运行时不可翻转(常量,编译期固定)。
const bool kPlaintextDeclared =
    String.fromEnvironment('AGENDUM_PLAINTEXT') == 'true';

/// 明文门禁(R1 §7):明文模式仅当构建期声明为 true 时放行。
///
/// [requested] 为调用方显式请求;null 表示跟随构建期声明。显式请求 true
/// 而构建未声明 → ArgumentError(生产误入明文在启动即炸,而非静默降级)。
/// [declared] 仅供测试注入真值表;生产代码一律用默认的构建期常量。
bool resolvePlaintextMode({
  bool? requested,
  bool declared = kPlaintextDeclared,
}) {
  if (requested == null) return declared;
  if (requested && !declared) {
    throw ArgumentError('明文模式需要构建期声明:--dart-define=AGENDUM_PLAINTEXT=true');
  }
  return requested;
}

/// Vault 身份:租户 uid、注册归属证明、op 编解码器与恢复短语的运行时持有者。
class IdentityVault {
  /// 租户 uid(R1 §1):push/pull 一律携带,服务端按 owner=uid 隔离。
  final String uid;

  /// 注册归属证明(ADR-016 §6):proof = HKDF(MK,'agendum/uid-proof') 的
  /// base64。设备注册时随 `uid_proof` 上送,服务端验证 uid = HKDF(proof)
  /// ——只知 uid 而无 proof 无法把设备注册进本租户。明文模式为 null。
  final String? uidProofB64;

  /// op 编解码:E2EE 模式为 E2eeOpCodec(DK 由 MK 派生);明文模式为恒等。
  final OpCodec codec;

  /// 是否明文开发模式(恒等编解码,固定租户 dev-plain)。
  final bool isPlaintext;

  /// 恢复短语(BIP39 12 词,规范化)。只读暴露供未来 onboarding UI;
  /// 明文模式为 null。不打印、不落日志。
  final String? mnemonic;

  IdentityVault._({
    required this.uid,
    required this.codec,
    required this.isPlaintext,
    this.uidProofB64,
    this.mnemonic,
  });

  /// 装载或创建:KeyStore 已有短语 → 恢复;无 → 生成 BIP39 12 词并经
  /// KeyStore 持久化(R1 §7)。[recoveryPhrase] 为恢复/测试路径的显式
  /// 短语,优先于已存值(第二设备「凭短语接入」即走此入口)并回写。
  /// [plaintext] 须经 [resolvePlaintextMode] 解析后传入。
  static Future<IdentityVault> load({
    required KeyStore keyStore,
    required bool plaintext,
    String? recoveryPhrase,
  }) async {
    if (plaintext) {
      return IdentityVault._(
        uid: devPlaintextUid,
        codec: const IdentityOpCodec(),
        isPlaintext: true,
      );
    }
    final stored =
        recoveryPhrase ?? await keyStore.read(KeyStoreKeys.vaultMnemonic);
    final phrase = Bip39.normalize(stored ?? Bip39.generate());
    // 首次创建或恢复短语接入:持久化(重复写同值幂等)。
    await keyStore.write(KeyStoreKeys.vaultMnemonic, phrase);
    final mk = await VaultKeys.masterKey(mnemonic: phrase);
    return IdentityVault._(
      uid: await tenantUid(mk),
      uidProofB64: base64Encode(await uidProof(mk)),
      codec: E2eeOpCodec(await VaultKeys.dataKey(mk)),
      isPlaintext: false,
      mnemonic: phrase,
    );
  }
}

/// 设备身份:Ed25519 密钥对的装载/创建(种子持久化在 KeyStore)。
/// 设备 ID 本体由本地库生成(DriftLocalSyncStore,dvc_* 持久于 sync_state),
/// 此处只负责签名密钥 —— 注册时二者绑定(R1 §3)。
class DeviceIdentity {
  DeviceIdentity._(this.keys);

  final DeviceKeys keys;

  static Future<DeviceIdentity> load({required KeyStore keyStore}) async {
    final stored = await keyStore.read(KeyStoreKeys.deviceSeed);
    if (stored != null) {
      return DeviceIdentity._(await DeviceKeys.fromSeed(base64Decode(stored)));
    }
    final seed = List<int>.generate(32, (_) => _random.nextInt(256));
    await keyStore.write(KeyStoreKeys.deviceSeed, base64Encode(seed));
    return DeviceIdentity._(await DeviceKeys.fromSeed(seed));
  }
}

final Random _random = Random.secure();
