/// 程簿端到端加密层（03 文档 §6）。
///
/// 密钥层级：
/// ```text
/// 用户主密码 ──Argon2id(m=64MiB,t=3,p=1)──► KEK（不出设备）
/// 恢复短语(12词 BIP39) ──PBKDF2──► 种子 ──HKDF──► 主密钥 MK
/// MK ──HKDF("db")─────► 数据密钥 DK：op 负载逐条 XChaCha20-Poly1305
/// MK ──HKDF("backup")─► 备份密钥
/// 每设备 Ed25519 DeviceKeyPair：设备身份，指纹 = SHA-256(公钥)前 16 字节
/// ```
///
/// 依赖 `package:cryptography`（纯 Dart Argon2id / XChaCha20-Poly1305 /
/// HKDF / PBKDF2 / Ed25519）。本包不含 UI、不含 flutter 依赖 —— 存储抽象
/// [KeyStore]（R1 §7，测试用 InMemoryKeyStore）与生产实现分离；信封
/// （[KekEnvelope]）的上送与设备注册由上层（客户端/服务端账号）负责。
library;

export 'src/aead.dart';
export 'src/device.dart';
export 'src/kdf.dart';
export 'src/keystore.dart';
export 'src/mnemonic.dart';
export 'src/op_cipher.dart';
export 'src/uid.dart';
export 'src/vault.dart';
