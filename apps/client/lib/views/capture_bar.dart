import 'dart:async';

import 'package:flutter/material.dart';

import 'package:agendum_nlp/agendum_nlp.dart';

import '../utils.dart';
import 'store.dart';

/// 捕获条（设计公理 1 的载体）：单行输入、回车即入收件箱、
/// 输入过程中实时显示端上解析预览（packages/nlp 真实引擎）。
class CaptureBar extends StatefulWidget {
  const CaptureBar({super.key, required this.store});

  final TaskStore store;

  @override
  State<CaptureBar> createState() => _CaptureBarState();
}

class _CaptureBarState extends State<CaptureBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  ParsedCapture _parsed = const ParsedCapture(title: '', confidence: 0);

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) => setState(() => _parsed = parseCapture(v));

  void _submit() {
    if (_controller.value.text.trim().isEmpty) return;
    unawaited(widget.store.addFromCapture(_parsed));
    _controller.clear();
    _onChanged('');
    _focus.requestFocus(); // 连续捕获不打断
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(14),
          color: scheme.surfaceContainerLowest,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onChanged,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: '想到什么就记下：下周三下午3点前给司机发合同 30min !高精力',
              prefixIcon: const Icon(Icons.bolt_outlined),
              suffixIcon: _controller.value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.send_outlined),
                      onPressed: _submit,
                      tooltip: '加入收件箱',
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_controller.value.text.trim().isNotEmpty)
          _ParsePreview(parsed: _parsed),
      ],
    );
  }
}

class _ParsePreview extends StatelessWidget {
  const _ParsePreview({required this.parsed});

  final ParsedCapture parsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = <String>[
      if (parsed.dueDay != null) '📅 ${formatDueDay(parsed.dueDay!)}',
      if (parsed.estimateMinutes != null) '⏱ ${parsed.estimateMinutes} 分钟',
      if (parsed.energy == 'high') '🔥 高精力',
      if (parsed.energy == 'low') '🌙 低精力',
      for (final t in parsed.tags) '#$t',
      if (parsed.projectHint != null) '@${parsed.projectHint}',
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in chips)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Text(
              '→ ${parsed.title}',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: .75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
