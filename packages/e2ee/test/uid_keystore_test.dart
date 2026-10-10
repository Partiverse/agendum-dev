/// R1 §1/§7:租户 uid 同种子确定性、格式约束,与 KeyStore 抽象的读写往返。
library;

import 'package:agendum_e2ee/agendum_e2ee.dart';
import 'package:test/test.dart';

void main() {
  group('tenantUid(R1 §1)', () {
    test('同一种子派生同一 uid(多端一致性)', () async {
      final mk = await VaultKeys.masterKey(mnemonic: Bip39.generate());
      final a = await tenantUid(mk);
      final b = await tenantUid(mk);
      expect(a, b);
    });

    test('同恢复短语(同种子)必得同一 uid;重派生 MK 也不变', () async {
      final phrase = Bip39.generate();
      final uid1 = await tenantUid(await VaultKeys.masterKey(mnemonic: phrase));
      // 模拟另一台设备:独立从短语重建 MK(短语 ──KDF──► MK 是确定性函数)。
      final uid2 = await tenantUid(await VaultKeys.masterKey(mnemonic: phrase));
      expect(uid1, uid2);
    });

    test('不同种子 uid 不同(租户隔离前提)', () async {
      final uid1 = await tenantUid(
        await VaultKeys.masterKey(mnemonic: Bip39.generate()),
      );
      final uid2 = await tenantUid(
        await VaultKeys.masterKey(mnemonic: Bip39.generate()),
      );
      expect(uid1, isNot(uid2));
    });

    test('格式:16 字节 → 32 位十六进制小写', () async {
      final uid = await tenantUid(List.filled(32, 7));
      expect(uid, hasLength(uidHexLength));
      expect(uid, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('uid 不泄露 MK 输入字节(十六进制输出 ≠ 输入截断)', () async {
      final mk = List.filled(32, 9);
      final uid = await tenantUid(mk);
      final mkHex = hexEncode(mk);
      expect(uid, isNot(mkHex.substring(0, 32)));
      expect(uid, isNot(mkHex.substring(16)));
    });
  });

  group('uidProof(ADR-016 §6 注册准入)', () {
    test('proof 32 字节;uid = hex(HKDF(proof))(服务端准入的派生关系)', () async {
      final mk = await VaultKeys.masterKey(mnemonic: Bip39.generate());
      final proof = await uidProof(mk);
      expect(proof, hasLength(32));
      final uid = hexEncode(
        await hkdfSha256(proof, info: uidInfo, outputLength: 16),
      );
      expect(uid, await tenantUid(mk), reason: 'tenantUid 走 proof 两跳派生');
    });

    test('同 MK 必得同一 proof(多端注册都过得了准入);异 MK proof 不同', () async {
      final phrase = Bip39.generate();
      final mk1 = await VaultKeys.masterKey(mnemonic: phrase);
      final mk2 = await VaultKeys.masterKey(mnemonic: phrase);
      expect(await uidProof(mk1), await uidProof(mk2));
      final other = await uidProof(
        await VaultKeys.masterKey(mnemonic: Bip39.generate()),
      );
      expect(other, isNot(await uidProof(mk1)));
    });

    test('只知 uid 无法反推 proof:任意 32 字节派生不出该 uid(准入单向性)', () async {
      final mk = await VaultKeys.masterKey(mnemonic: Bip39.generate());
      final uid = await tenantUid(mk);
      // 穷举不出 proof 的一般性由 HKDF 单向性保证;这里锁死具体机制:
      // 错误 proof 派生的 uid 与真 uid 不同(非空概率 1-2^-128)。
      final wrongUid = hexEncode(
        await hkdfSha256(List.filled(32, 3), info: uidInfo, outputLength: 16),
      );
      expect(wrongUid, isNot(uid));
    });
  });

  group('KeyStore(R1 §7)', () {
    test('InMemoryKeyStore 读写往返:写后读回原值', () async {
      final ks = InMemoryKeyStore();
      expect(await ks.read('k'), isNull, reason: '未写键读出 null');
      await ks.write('k', 'v1');
      expect(await ks.read('k'), 'v1');
      await ks.write('k', 'v2');
      expect(await ks.read('k'), 'v2', reason: '覆盖写生效');
    });

    test('两个 InMemoryKeyStore 互不可见(设备边界模拟)', () async {
      final a = InMemoryKeyStore();
      final b = InMemoryKeyStore();
      await a.write(KeyStoreKeys.vaultMnemonic, 'word word …');
      expect(await b.read(KeyStoreKeys.vaultMnemonic), isNull);
    });

    test('短语存取往返:KeyStore 恢复路径重建同一 uid', () async {
      // 模拟 TaskStore.open 的创建→重启恢复闭环:
      // 首启生成短语并经 KeyStore 持久化;重启后读短语重建 MK/uid。
      final ks = InMemoryKeyStore();
      final phrase = Bip39.generate();
      await ks.write(KeyStoreKeys.vaultMnemonic, phrase);

      final restored = (await ks.read(KeyStoreKeys.vaultMnemonic))!;
      expect(Bip39.validate(restored), isTrue, reason: '存取不破坏短语');
      final uidA = await tenantUid(await VaultKeys.masterKey(mnemonic: phrase));
      final uidB = await tenantUid(
        await VaultKeys.masterKey(mnemonic: restored),
      );
      expect(uidA, uidB);
    });
  });
}
