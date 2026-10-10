/// 密钥存储抽象(R1 §7):密钥只进系统安全存储(macOS Keychain /
/// Linux libsecret / Windows DPAPI),不落 SQLite、不进日志。
///
/// 本包保持零 flutter 依赖:[KeyStore] 是纯 Dart 接口,InMemory 实现
/// 供测试与无安全存储环境;生产实现(flutter_secure_storage 封装)由
/// apps/client 提供。Keychain 本身即静态加密,故此处只存字符串值,
/// 不再做二次加密;R3 的本地库透明加密另议(蓝图 §2)。
library;

/// 键名常量:KeyStore 内的条目命名,客户端与实现共用,避免散落魔法串。
abstract final class KeyStoreKeys {
  /// Vault 恢复短语(BIP39 12 词,规范化后空格连字)。
  ///
  /// 短语即 MK 的等价持有(短语 ──PBKDF2──► 种子 ──HKDF──► MK,
  /// 见 vault.dart 的 VaultKeys.masterKey),且短语找回 UI 需要原文,
  /// 故持久化短语而非裸 MK —— 单一事实来源,避免两份密钥材料漂移。
  static const vaultMnemonic = 'agendum/vault/mnemonic';

  /// 设备 Ed25519 私钥种子(32 字节 base64,经 DeviceKeys.fromSeed 重建)。
  static const deviceSeed = 'agendum/device/seed';
}

/// 密钥存储抽象:按键读写字符串值;读不存在键返回 null。
abstract interface class KeyStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

/// 内存实现:测试与无安全存储环境的兜底(如 CI)。进程退出即失忆 ——
/// 每次启动重新生成 Vault,符合「测试走 InMemoryKeyStore」的约定。
class InMemoryKeyStore implements KeyStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
