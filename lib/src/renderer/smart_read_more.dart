import 'package:flutter/material.dart';
import '../models/smart_content_config.dart';
import 'smart_rich_text_viewer.dart';

/// A read-only viewer with optional "Read more / Read less" truncation.
///
/// When [limit] > 0 and content exceeds [limit] characters, the widget shows
/// a truncated version with a "Read more" button.
class SmartReadMore extends StatefulWidget {
  final String content;
  final SmartContentConfig config;

  /// Character limit. 0 = no truncation.
  final int limit;

  const SmartReadMore({
    super.key,
    required this.content,
    this.config = const SmartContentConfig(),
    this.limit = 200,
  });

  @override
  State<SmartReadMore> createState() => _SmartReadMoreState();
}

class _SmartReadMoreState extends State<SmartReadMore> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.content;
    final limit = widget.limit;
    final isLong = limit > 0 && text.length > limit;

    final displayText =
        (!_expanded && isLong) ? _truncate(text, limit) : text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SmartRichTextViewer(
          content: displayText,
          config: widget.config,
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _expanded ? 'Read less' : 'Read more',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _truncate(String text, int limit) {
    final cut = text.substring(0, limit);
    final lastSpace = cut.lastIndexOf(' ');
    final safe = lastSpace > 0 ? cut.substring(0, lastSpace) : cut;
    return '$safe…';
  }
}
