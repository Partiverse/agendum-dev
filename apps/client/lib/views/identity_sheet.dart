/// 身份与恢复(R1 实机验收配套):展示本机 Vault 身份(uid/加密模式)与
/// 恢复短语,供用户抄录到第二台设备「凭短语接入」。
///
/// 短语经 [TaskStore.recoveryPhrase] 只读 getter 取得,仅在用户主动点击
/// 「显示恢复短语」后渲染;不打印、不落日志。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';

Future<void> showIdentitySheet(BuildContext context, TaskStore store) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _IdentitySheet(store: store),
    );

class _IdentitySheet extends StatefulWidget {
  const _IdentitySheet({required this.store});

  final TaskStore store;

  @override
  State<_IdentitySheet> createState() => _IdentitySheetState();
}

class _IdentitySheetState extends State<_IdentitySheet> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final phrase = store.recoveryPhrase;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '身份与恢复',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _row(context, '租户 uid', store.uid),
            const SizedBox(height: 8),
            _row(
              context,
              '加密模式',
              store.isPlaintextMode ? '明文开发模式(AGENDUM_PLAINTEXT)' : '端到端加密',
            ),
            const SizedBox(height: 16),
            if (store.isPlaintextMode)
              const Text('明文模式下无恢复短语。')
            else ...[
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    icon: Icon(
                      _revealed ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(_revealed ? '隐藏恢复短语' : '显示恢复短语'),
                  ),
                  if (_revealed && phrase != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phrase));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('恢复短语已复制到剪贴板')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                    ),
                  ],
                ],
              ),
              if (_revealed) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    phrase ?? '(不可用)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '恢复短语是数据的唯一恢复凭证:第二台设备凭它接入本租户。'
                  '请离线抄写保存,不要截图或上传。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 72,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Expanded(child: SelectableText(value)),
    ],
  );
}
