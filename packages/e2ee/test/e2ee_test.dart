/// E2EE 层单测：AEAD、BIP39（官方向量）、信封、op 编解码。
/// Argon2id(m=64MiB,t=3) 全参数用例较慢，集中在一个组里跑。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_protocol/agendum_protocol.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:test/test.dart';

void main() {
  group('XchachaAead', () {
    final key = List.filled(32, 7);

    test('seal/open 往返；密文与明文无关长度一致', () async {
      const message = '任务标题：给司机发合同';
      final sealed = await XchachaAead.seal(
        key: key,
        plaintext: utf8.encode(message),
        aad: utf8.encode('aad'),
      );
      expect(sealed.length, greaterThan(message.length));
      final opened = await XchachaAead.open(
        key: key,
        sealed: sealed,
        aad: utf8.encode('aad'),
      );
      expect(utf8.decode(opened), message);
    });

    test('nonce 随机：同明文两次加密密文不同', () async {
      final a = await XchachaAead.seal(key: key, plaintext: [1, 2, 3]);
      final b = await XchachaAead.seal(key: key, plaintext: [1, 2, 3]);
      expect(a, isNot(equals(b)));
    });

    test('篡改任一字节/错 AAD/错密钥 → AeadAuthError', () async {
      final sealed = await XchachaAead.seal(key: key, plaintext: [9, 9]);
      final tampered = [...sealed]..[5] ^= 0xFF;
      await expectLater(
        XchachaAead.open(key: key, sealed: tampered),
        throwsA(isA<AeadAuthError>()),
      );
      await expectLater(
        XchachaAead.open(key: key, sealed: sealed, aad: utf8.encode('wrong')),
        throwsA(isA<AeadAuthError>()),
      );
      await expectLater(
        XchachaAead.open(key: List.filled(32, 8), sealed: sealed),
        throwsA(isA<AeadAuthError>()),
      );
    });

    test('密钥长度校验', () async {
      expect(
        () => XchachaAead.seal(key: [1, 2], plaintext: const []),
        throwsArgumentError,
      );
    });
  });

  group('Bip39（BIP39 官方测试向量）', () {
    test('全零熵 → 全 abandon … about', () {
      final mnemonic = Bip39.fromEntropy(List.filled(16, 0));
      expect(
        mnemonic,
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon about',
      );
      expect(Bip39.validate(mnemonic), isTrue);
    });

    test('种子向量（passphrase TREZOR）', () async {
      final seed = await bip39Seed(
        'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon about',
        passphrase: 'TREZOR',
      );
      expect(
        seed.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e5349553'
        '1f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
      );
    });

    test('熵往返：fromEntropy → toEntropy 恒等', () {
      final entropy = List.generate(16, (i) => (i * 17 + 3) & 0xFF);
      final mnemonic = Bip39.fromEntropy(entropy);
      expect(Bip39.toEntropy(mnemonic), entropy);
    });

    test('校验和被改 → validate 假 / toEntropy 抛', () {
      final words = Bip39.fromEntropy(List.filled(16, 0)).split(' ');
      final broken = [...words]..[11] = 'zoo'; // 换最后一个词破坏校验和
      final brokenPhrase = broken.join(' ');
      expect(Bip39.validate(brokenPhrase), isFalse);
      expect(
        () => Bip39.toEntropy(brokenPhrase),
        throwsA(isA<Bip39FormatError>()),
      );
    });

    test('非法词/词数拒绝;normalize 容忍大小写与多余空白', () {
      expect(Bip39.validate('notaword in list at all'), isFalse);
      expect(Bip39.validate('abandon'), isFalse);
      const phrase =
          'abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon about';
      expect(Bip39.validate(phrase.toUpperCase()), isTrue);
      expect(Bip39.validate('  $phrase  '), isTrue);
    });

    test('generate 默认 12 词且可校验', () {
      final phrase = Bip39.generate();
      expect(phrase.split(' '), hasLength(12));
      expect(Bip39.validate(phrase), isTrue);
    });
  });

  group('VaultKeys + KekEnvelope（Argon2id 全参数,较慢）', () {
    test('setup → unlock 往返;错口令拒绝;信封 JSON 往返', () async {
      final vault = await VaultKeys.setup(password: '正确的口袋密码');
      expect(vault.mnemonic.split(' '), hasLength(12));
      expect(vault.mk, hasLength(32));

      final restored = KekEnvelope.decode(vault.envelope.encode());
      final unlocked = await VaultKeys.unwrap(
        password: '正确的口袋密码',
        envelope: restored,
      );
      expect(unlocked, vault.mk);

      await expectLater(
        VaultKeys.unwrap(password: '错误口令', envelope: restored),
        throwsA(isA<AeadAuthError>()),
      );

      expect(restored.alg, 'argon2id');
      expect(restored.memoryKib, argon2MemoryKib);
      expect(restored.verifier, hasLength(16));
      expect(
        DeviceKeys.looksLikeFingerprint(
          'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-0000-1111',
        ),
        isTrue,
      );
    });

    test('恢复短语找回同一 MK → 同一 DK/备份密钥', () async {
      final vault = await VaultKeys.setup(password: 'p');
      final recovered = await VaultKeys.masterKey(mnemonic: vault.mnemonic);
      expect(recovered, vault.mk);
      expect(
        await VaultKeys.dataKey(recovered),
        await VaultKeys.dataKey(vault.mk),
      );
      expect(
        await VaultKeys.backupKey(recovered),
        await VaultKeys.backupKey(vault.mk),
      );
    });

    test('同密码不同信封(新盐)派生不同 KEK 但都能解包 MK', () async {
      final vault = await VaultKeys.setup(password: 'p');
      final envelope2 = await VaultKeys.wrapWithPassword('p', vault.mk);
      expect(envelope2.saltB64, isNot(vault.envelope.saltB64));
      expect(
        await VaultKeys.unwrap(password: 'p', envelope: envelope2),
        vault.mk,
      );
    });

    test('换密码:新信封可解,MK 不变', () async {
      final vault = await VaultKeys.setup(password: '旧密码');
      final changed = await VaultKeys.changePassword(
        mk: vault.mk,
        newPassword: '新密码',
      );
      expect(
        await VaultKeys.unwrap(password: '新密码', envelope: changed),
        vault.mk,
      );
      await expectLater(
        VaultKeys.unwrap(password: '旧密码', envelope: changed),
        throwsA(isA<AeadAuthError>()),
      );
    });

    test('DK/备份密钥分离', () async {
      final mk = List.generate(32, (i) => i);
      expect(await VaultKeys.dataKey(mk), isNot(await VaultKeys.backupKey(mk)));
    });
  });

  group('DeviceKeys', () {
    test('指纹格式与确定性(同种子同指纹)', () async {
      final a = await DeviceKeys.fromSeed(List.filled(32, 1));
      final b = await DeviceKeys.fromSeed(List.filled(32, 1));
      expect(a.fingerprint, b.fingerprint);
      expect(DeviceKeys.looksLikeFingerprint(a.fingerprint), isTrue);
      final c = await DeviceKeys.fromSeed(List.filled(32, 2));
      expect(a.fingerprint, isNot(c.fingerprint));
      expect(a.publicKeyB64.length, base64Encode(List.filled(32, 0)).length);
    });

    test('签名/验签;指纹派生与公钥一致', () async {
      final keys = await DeviceKeys.generate();
      final sig = await keys.sign(utf8.encode('hello'));
      expect(
        await DeviceKeys.verify(message: utf8.encode('hello'), signature: sig),
        isTrue,
      );
      expect(
        await DeviceKeys.verify(message: utf8.encode('hellO'), signature: sig),
        isFalse,
      );
      expect(await fingerprintOf(keys.publicKey), keys.fingerprint);
    });
  });

  group('E2eeOpCodec', () {
    SyncOp plainOp() => const SyncOp(
      deviceId: 'dvc_x',
      lamport: 42,
      entity: 'task',
      entityId: 'tsk_1',
      field: 'title',
      type: SyncOpType.set,
      value: OpValue(OpValueTypes.str, '给司机发合同'),
    );

    test('seal:线上 value 为 enc 且不含明文;open 还原', () async {
      final codec = E2eeOpCodec(Uint8List.fromList(List.filled(32, 9)));
      final wire = await codec.encodeForWire(plainOp());
      expect(wire.value!.type, OpValueTypes.enc);
      final encoded = jsonEncode(wire.toJson());
      expect(encoded.contains('给司机发合同'), isFalse);

      final back = await codec.decodeFromWire(wire);
      expect(back.value, plainOp().value);
      expect(back.toJson(), plainOp().toJson());
    });

    test('del op 与非 enc value 原样通过(前向兼容)', () async {
      final codec = E2eeOpCodec(Uint8List.fromList(List.filled(32, 9)));
      const del = SyncOp(
        deviceId: 'dvc_x',
        lamport: 43,
        entity: 'task',
        entityId: 'tsk_1',
        field: '__row',
        type: SyncOpType.del,
      );
      expect(await codec.encodeForWire(del), same(del));
      expect(await codec.decodeFromWire(del), same(del));

      final plainWire = await const IdentityOpCodec().encodeForWire(plainOp());
      final back = await codec.decodeFromWire(plainWire);
      expect(back.value, plainOp().value);
    });

    test('AAD 绑定:元数据被改 → 认证失败', () async {
      final codec = E2eeOpCodec(Uint8List.fromList(List.filled(32, 9)));
      final wire = await codec.encodeForWire(plainOp());
      final tampered = SyncOp(
        deviceId: wire.deviceId,
        lamport: wire.lamport + 1, // 改 lamport
        entity: wire.entity,
        entityId: wire.entityId,
        field: wire.field,
        type: wire.type,
        value: wire.value,
      );
      await expectLater(
        codec.decodeFromWire(tampered),
        throwsA(isA<AeadAuthError>()),
      );
    });

    test('无 DK(错密钥)的服务端/对端看不到明文', () async {
      final codec = E2eeOpCodec(Uint8List.fromList(List.filled(32, 9)));
      final wire = await codec.encodeForWire(plainOp());
      final stranger = E2eeOpCodec(Uint8List.fromList(List.filled(32, 10)));
      await expectLater(
        stranger.decodeFromWire(wire),
        throwsA(isA<AeadAuthError>()),
      );
    });
  });
}
