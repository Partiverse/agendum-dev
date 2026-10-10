/// 生产密钥存储:flutter_secure_storage 封装(macOS Keychain / Linux
/// libsecret / Windows DPAPI / Android Keystore)。
///
/// R1 §7:生产路径唯一 KeyStore 实现;测试一律走 agendum_e2ee 的
/// InMemoryKeyStore(避免平台通道依赖)。值为明文字符串,机密性由
/// 系统安全存储保证 —— 与 KeyStore 抽象的约定一致(见 keystore.dart)。
library;

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageKeyStore implements KeyStore {
  SecureStorageKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}
