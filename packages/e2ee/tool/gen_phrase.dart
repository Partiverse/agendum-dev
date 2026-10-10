// 开发工具:生成一条 BIP39 12 词恢复短语并打印(实机验收/测试夹具用)。
// 短语即租户身份 —— 仅用于本地验收,生成后即焚,不要入库。
import 'package:agendum_e2ee/agendum_e2ee.dart';

void main() {
  // ignore: avoid_print
  print(Bip39.generate());
}
