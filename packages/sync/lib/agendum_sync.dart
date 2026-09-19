/// 同步客户端引擎。服务端只做序号分配与转发;合并全部在端上(03 文档 §4.3)。
library;

export 'src/entity_state.dart';
export 'src/lww.dart';
export 'src/rest_transport.dart';
export 'src/sync_engine.dart';
