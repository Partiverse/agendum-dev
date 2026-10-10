/// R1 §7 信任装配:明文门禁、Vault 创建/恢复(uid 同种子确定性)、
/// TaskStore.open 默认 E2EE。
library;

import 'dart:convert';

import 'package:agendum_client/identity.dart';
import 'package:agendum_client/views/store.dart';
import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:agendum_sync/agendum_sync.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('明文门禁(resolvePlaintextMode)', () {
    test('本测试构建未声明 AGENDUM_PLAINTEXT(前提自检)', () {
      // 以下断言都依赖这一前提;若 CI 加了 dart-define,须改写本组测试。
      expect(kPlaintextDeclared, isFalse);
    });

    test('默认跟随构建期声明:未声明 → 明文关闭', () {
      expect(resolvePlaintextMode(), isFalse);
      expect(resolvePlaintextMode(requested: null), isFalse);
    });

    test('显式请求 true 而构建未声明 → ArgumentError(启动即炸,不静默降级)', () {
      expect(() => resolvePlaintextMode(requested: true), throwsArgumentError);
      // 穿透真实入口同样被拒。
      expect(
        () => TaskStore.open(
          executor: NativeDatabase.memory(),
          keyStore: InMemoryKeyStore(),
          plaintext: true,
        ),
        throwsArgumentError,
      );
    });

    test('显式请求 false 恒为关闭(声明了也可显式退出)', () {
      expect(resolvePlaintextMode(requested: false), isFalse);
    });

    test('构建声明 true 时:默认与显式请求 true 均放行(真值表补全)', () {
      // 测试构建无法定义编译期常量,以 declared 注入覆盖该分支;
      // 生产代码走默认(kPlaintextDeclared),不经此注入。
      expect(resolvePlaintextMode(declared: true), isTrue);
      expect(resolvePlaintextMode(requested: true, declared: true), isTrue);
      expect(resolvePlaintextMode(requested: false, declared: true), isFalse);
    });
  });

  group('IdentityVault(R1 §1/§7)', () {
    test('首启创建:12 词短语 + 32 位十六进制小写 uid + E2EE codec', () async {
      final vault = await IdentityVault.load(
        keyStore: InMemoryKeyStore(),
        plaintext: false,
      );
      expect(vault.mnemonic!.split(' '), hasLength(12));
      expect(Bip39.validate(vault.mnemonic!), isTrue);
      expect(vault.uid, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(vault.codec, isA<E2eeOpCodec>());
      expect(vault.isPlaintext, isFalse);
    });

    test(
      '注册归属证明(ADR-016 §6):E2EE 必有 32B proof 且 uid=HKDF(proof);明文为 null',
      () async {
        final vault = await IdentityVault.load(
          keyStore: InMemoryKeyStore(),
          plaintext: false,
        );
        expect(vault.uidProofB64, isNotNull);
        final proof = base64Decode(vault.uidProofB64!);
        expect(proof, hasLength(32));
        // 派生关系与客户端注册体、服务端准入共用一条链。
        final derived = [
          for (final b in await hkdfSha256(
            proof,
            info: uidInfo,
            outputLength: 16,
          ))
            b.toRadixString(16).padLeft(2, '0'),
        ].join();
        expect(derived, vault.uid);

        final plain = await IdentityVault.load(
          keyStore: InMemoryKeyStore(),
          plaintext: true,
        );
        expect(plain.uidProofB64, isNull, reason: 'dev-plain 豁免,无 Vault');
      },
    );

    test('重启恢复:同一 KeyStore 重开 → 同短语同 uid', () async {
      final keyStore = InMemoryKeyStore();
      final first = await IdentityVault.load(
        keyStore: keyStore,
        plaintext: false,
      );
      final second = await IdentityVault.load(
        keyStore: keyStore,
        plaintext: false,
      );
      expect(second.mnemonic, first.mnemonic);
      expect(second.uid, first.uid, reason: 'KeyStore round-trip:恢复不换身份');
    });

    test('显式恢复短语:异机同短语 → 同 uid(多端一致性)', () async {
      final phrase = Bip39.generate();
      final a = await IdentityVault.load(
        keyStore: InMemoryKeyStore(),
        plaintext: false,
        recoveryPhrase: phrase,
      );
      final b = await IdentityVault.load(
        keyStore: InMemoryKeyStore(),
        plaintext: false,
        recoveryPhrase: phrase,
      );
      expect(a.uid, b.uid);
      expect(a.mnemonic, phrase);
    });

    test('不同 KeyStore(不同用户/设备)→ 不同 uid', () async {
      final a = await IdentityVault.load(
        keyStore: InMemoryKeyStore(),
        plaintext: false,
      );
      final b = await IdentityVault.load(
        keyStore: InMemoryKeyStore(),
        plaintext: false,
      );
      expect(a.uid, isNot(b.uid));
      expect(a.mnemonic, isNot(b.mnemonic));
    });

    test('非法恢复短语 → 拒绝(Bip39FormatError),不静默换新', () async {
      await expectLater(
        IdentityVault.load(
          keyStore: InMemoryKeyStore(),
          plaintext: false,
          recoveryPhrase: 'not a valid phrase',
        ),
        throwsA(isA<Bip39FormatError>()),
      );
    });

    test('明文模式:固定 uid dev-plain + 恒等 codec + 无短语', () async {
      final vault = await IdentityVault.load(
        keyStore: InMemoryKeyStore(),
        plaintext: true,
      );
      expect(vault.uid, devPlaintextUid);
      expect(vault.codec, isA<IdentityOpCodec>());
      expect(vault.isPlaintext, isTrue);
      expect(vault.mnemonic, isNull);
    });
  });

  group('TaskStore.open 默认 E2EE(R1 §7)', () {
    test('默认路径:E2EE + 派生 uid;同 KeyStore 重开恢复同一身份', () async {
      final keyStore = InMemoryKeyStore();
      final s1 = await TaskStore.open(
        executor: NativeDatabase.memory(),
        keyStore: keyStore,
      );
      addTearDown(s1.close);
      expect(s1.isPlaintextMode, isFalse);
      expect(s1.uid, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(s1.recoveryPhrase, isNotNull);

      final s2 = await TaskStore.open(
        executor: NativeDatabase.memory(),
        keyStore: keyStore,
      );
      addTearDown(s2.close);
      expect(s2.uid, s1.uid);
      expect(s2.recoveryPhrase, s1.recoveryPhrase);
    });

    test('不同 KeyStore 的两台设备 uid 不同(租户隔离前提)', () async {
      final a = await TaskStore.open(
        executor: NativeDatabase.memory(),
        keyStore: InMemoryKeyStore(),
      );
      final b = await TaskStore.open(
        executor: NativeDatabase.memory(),
        keyStore: InMemoryKeyStore(),
      );
      addTearDown(a.close);
      addTearDown(b.close);
      expect(a.uid, isNot(b.uid));
    });
  });
}
