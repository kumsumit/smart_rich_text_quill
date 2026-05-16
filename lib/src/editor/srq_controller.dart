import 'package:flutter/widgets.dart';
import '../models/srq_document.dart';
import '../parser/content_normalizer.dart';

/// Formatting attributes that can be applied to selected text.
class SrqTextFormat {
  final bool bold;
  final bool italic;
  final bool strikethrough;
  final bool underline;
  final bool code;

  const SrqTextFormat({
    this.bold = false,
    this.italic = false,
    this.strikethrough = false,
    this.underline = false,
    this.code = false,
  });

  SrqTextFormat copyWith({
    bool? bold,
    bool? italic,
    bool? strikethrough,
    bool? underline,
    bool? code,
  }) {
    return SrqTextFormat(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      strikethrough: strikethrough ?? this.strikethrough,
      underline: underline ?? this.underline,
      code: code ?? this.code,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SrqTextFormat &&
      bold == other.bold &&
      italic == other.italic &&
      strikethrough == other.strikethrough &&
      underline == other.underline &&
      code == other.code;

  @override
  int get hashCode =>
      Object.hash(bold, italic, strikethrough, underline, code);
}

/// Block-level format for the current line/paragraph.
enum SrqBlockFormat {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  orderedList,
  taskList,
  blockquote,
  codeBlock,
}

/// The controller that manages the editor's state.
///
/// Works similarly to [TextEditingController] but also tracks:
/// - Active inline formatting (bold, italic, etc.)
/// - Current block type (heading, list, blockquote, etc.)
/// - Undo/redo history
class SrqController extends ChangeNotifier {
  SrqController({String initialMarkdown = ''})
      : _markdown = ContentNormalizer.normalize(initialMarkdown),
        _textController = _buildTextController(
            ContentNormalizer.normalize(initialMarkdown));

  // ─── Internal state ─────────────────────────────────────────────────────────

  String _markdown;
  final TextEditingController _textController;

  SrqTextFormat _activeFormat = const SrqTextFormat();
  SrqBlockFormat _activeBlock = SrqBlockFormat.paragraph;

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  bool _disposed = false;

  // ─── Public getters ──────────────────────────────────────────────────────────

  String get markdown => _markdown;

  SrqDocument get document => SrqDocument(markdown: _markdown);

  TextEditingController get textController => _textController;

  SrqTextFormat get activeFormat => _activeFormat;

  SrqBlockFormat get activeBlock => _activeBlock;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ─── Selection-aware format detection ────────────────────────────────────────

  /// Returns true if the cursor or selection is inside **bold** text.
  bool get selectionBoldActive {
    final cursor = _textController.selection.baseOffset;
    if (cursor < 0) return false;
    return _cursorInsideMarker(_textController.text, cursor, r'\*\*([^*]+)\*\*');
  }

  /// Returns true if the cursor or selection is inside *italic* text.
  bool get selectionItalicActive {
    final cursor = _textController.selection.baseOffset;
    if (cursor < 0) return false;
    // Use negative lookahead-equivalent by matching single * not preceded/followed by *
    return _cursorInsideMarker(_textController.text, cursor, r'(?<!\*)\*(?!\*)([^*]+)(?<!\*)\*(?!\*)');
  }

  /// Returns true if the cursor is inside ~~strikethrough~~ text.
  bool get selectionStrikethroughActive {
    final cursor = _textController.selection.baseOffset;
    if (cursor < 0) return false;
    return _cursorInsideMarker(_textController.text, cursor, r'~~([^~]+)~~');
  }

  /// Returns true if the cursor is inside <u>underline</u> text.
  bool get selectionUnderlineActive {
    final cursor = _textController.selection.baseOffset;
    if (cursor < 0) return false;
    return _cursorInsideMarker(_textController.text, cursor, r'<u>(.*?)</u>');
  }

  /// Returns the block format of the line where the cursor is.
  SrqBlockFormat get selectionBlockFormat {
    final sel = _textController.selection;
    final text = _textController.text;
    if (!sel.isValid) return SrqBlockFormat.paragraph;
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final line = text.substring(lineStart, lineEnd == -1 ? text.length : lineEnd);
    return _blockFormatOf(line);
  }

  bool _cursorInsideMarker(String text, int cursor, String pattern) {
    for (final match in RegExp(pattern, dotAll: true).allMatches(text)) {
      if (cursor > match.start && cursor < match.end) return true;
    }
    return false;
  }

  SrqBlockFormat _blockFormatOf(String line) {
    if (line.startsWith('# ')) return SrqBlockFormat.heading1;
    if (line.startsWith('## ')) return SrqBlockFormat.heading2;
    if (line.startsWith('### ')) return SrqBlockFormat.heading3;
    if (line.startsWith('* [ ] ') || line.startsWith('- [ ] ')) return SrqBlockFormat.taskList;
    if (line.startsWith('* ') || line.startsWith('- ')) return SrqBlockFormat.bulletList;
    if (RegExp(r'^\d+\.\s').hasMatch(line)) return SrqBlockFormat.orderedList;
    if (line.startsWith('> ')) return SrqBlockFormat.blockquote;
    return SrqBlockFormat.paragraph;
  }

  // ─── Load & set content ──────────────────────────────────────────────────────

  /// Replace the entire document content (with undo snapshot).
  void setMarkdown(String markdown) {
    final normalized = ContentNormalizer.normalize(markdown);
    _pushUndoSnapshot();
    _markdown = normalized;
    _syncTextController();
    notifyListeners();
  }

  /// Replace content without adding an undo snapshot (use for imports).
  void setMarkdownSilently(String markdown) {
    final normalized = ContentNormalizer.normalize(markdown);
    _markdown = normalized;
    _syncTextController();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Inserts raw text exactly at the current cursor position.
  void insertAtCursor(String text) {
    if (text.isEmpty) return;
    final selection = _textController.selection;
    if (!selection.isValid) return;

    _pushUndoSnapshot();
    final start = selection.start;
    final end = selection.end;

    final newText = _markdown.replaceRange(start, end, text);
    _markdown = newText;

    final newCursorPos = start + text.length;
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    notifyListeners();
  }

  /// Clear content.
  void clear() {
    _pushUndoSnapshot();
    _markdown = '';
    _textController.clear();
    notifyListeners();
  }

  // ─── Format actions ──────────────────────────────────────────────────────────

  /// Toggle bold on the selected text (or set cursor format).
  void toggleBold() => _toggleInline('**', '**');

  /// Toggle italic on the selected text.
  void toggleItalic() => _toggleInline('*', '*');

  /// Toggle strikethrough on the selected text.
  void toggleStrikethrough() => _toggleInline('~~', '~~');

  /// Toggle underline on the selected text (using HTML <u> tags).
  void toggleUnderline() => _toggleInline('<u>', '</u>');

  /// Toggle inline code on the selected text.
  void toggleInlineCode() => _toggleInline('`', '`');

  /// Set heading level (1-3) on the current line.
  void setHeading(int level) {
    assert(level >= 1 && level <= 3);
    final prefix = '${'#' * level} ';
    _toggleLinePrefix(prefix, clearOtherPrefixes: true);
    _activeBlock = [
      SrqBlockFormat.heading1,
      SrqBlockFormat.heading2,
      SrqBlockFormat.heading3,
    ][level - 1];
    notifyListeners();
  }

  /// Remove all block formatting from current line (back to paragraph).
  void clearBlockFormat() {
    _pushUndoSnapshot();
    final text = _textController.text;
    final sel = _textController.selection;
    if (!sel.isValid) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final end = lineEnd == -1 ? text.length : lineEnd;
    final line = text.substring(lineStart, end);

    final cleaned = _clearBlockPrefixes(line);
    if (cleaned == line) return;

    final newText = '${text.substring(0, lineStart)}$cleaned${end < text.length ? text.substring(end) : ''}';
    final newCursor = (lineStart + cleaned.length).clamp(0, newText.length);
    _activeBlock = SrqBlockFormat.paragraph;
    _updateText(newText, newCursor);
  }

  /// Toggle bullet list on current line.
  void toggleBulletList() {
    _toggleLinePrefix('* ', clearOtherPrefixes: true);
    _activeBlock = SrqBlockFormat.bulletList;
    notifyListeners();
  }

  /// Toggle ordered list on current line.
  void toggleOrderedList() {
    _toggleLinePrefix('1. ', clearOtherPrefixes: true);
    _activeBlock = SrqBlockFormat.orderedList;
    notifyListeners();
  }

  /// Toggle blockquote on current line.
  void toggleBlockquote() {
    _toggleLinePrefix('> ', clearOtherPrefixes: true);
    _activeBlock = SrqBlockFormat.blockquote;
    notifyListeners();
  }

  /// Toggle task list on current line.
  void toggleTaskList() {
    _toggleLinePrefix('* [ ] ', clearOtherPrefixes: true);
    _activeBlock = SrqBlockFormat.taskList;
    notifyListeners();
  }

  /// Toggle code block — wraps selection in triple backticks.
  void toggleCodeBlock() {
    _pushUndoSnapshot();
    final sel = _textController.selection;
    final text = _textController.text;

    if (!sel.isValid || sel.isCollapsed) {
      final idx = sel.isValid ? sel.start : text.length;
      const inserted = '\n```\ncode here\n```\n';
      final newText = text.substring(0, idx) + inserted + text.substring(idx);
      _updateText(newText, idx + inserted.length);
    } else {
      final selected = sel.textInside(text);
      final before = text.substring(0, sel.start);
      final after = text.substring(sel.end);
      _updateText(
        '$before\n```\n$selected\n```\n$after',
        sel.start + selected.length + 10,
      );
    }
  }

  /// Insert a horizontal rule at cursor.
  void insertDivider() {
    _insertAtCursor('\n\n---\n\n');
  }

  /// Insert a link at cursor or wrap selection.
  void insertLink(String url, {String? text}) {
    final sel = _textController.selection;
    final rawText = _textController.text;
    final label = text ??
        (sel.isValid && !sel.isCollapsed
            ? sel.textInside(rawText)
            : 'link text');
    final md = '[$label]($url)';

    _pushUndoSnapshot();
    if (sel.isValid && !sel.isCollapsed) {
      final before = rawText.substring(0, sel.start);
      final after = rawText.substring(sel.end);
      _updateText('$before$md$after', sel.start + md.length);
    } else {
      _insertAtCursor(md);
    }
  }

  /// Insert a Markdown image at cursor.
  void insertImage(String url, {String alt = 'image'}) {
    _insertAtCursor('\n![${alt.isEmpty ? 'image' : alt}]($url)\n');
  }

  /// Insert a Markdown file link at cursor.
  void insertFileLink(String url, String filename) {
    _insertAtCursor('\n[$filename]($url)\n');
  }

  // ─── Undo / Redo ─────────────────────────────────────────────────────────────

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_markdown);
    final prev = _undoStack.removeLast();
    _markdown = prev;
    _syncTextController();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_markdown);
    final next = _redoStack.removeLast();
    _markdown = next;
    _syncTextController();
    notifyListeners();
  }

  // ─── Sync text controller → markdown ────────────────────────────────────────

  void _onTextChanged() {
    if (_disposed) return;
    String newText = _textController.text;

    // Auto-list formatting on Enter
    if (newText.length == _markdown.length + 1) {
      final sel = _textController.selection;
      if (sel.isCollapsed && sel.start > 0 && newText[sel.start - 1] == '\n') {
        final prevLineStart = newText.lastIndexOf('\n', sel.start - 2) + 1;
        final prevLine = newText.substring(prevLineStart, sel.start - 1);

        String? prefixToInsert;
        if (prevLine.startsWith('* [ ] ') || prevLine.startsWith('- [ ] ')) {
          prefixToInsert = prevLine.substring(0, 6);
        } else if (prevLine.startsWith('* ') || prevLine.startsWith('- ')) {
          prefixToInsert = prevLine.substring(0, 2);
        } else {
          final olMatch = RegExp(r'^(\d+)\.\s').firstMatch(prevLine);
          if (olMatch != null) {
            int num = int.parse(olMatch.group(1)!);
            prefixToInsert = '${num + 1}. ';
          } else if (prevLine.startsWith('> ')) {
            prefixToInsert = '> ';
          }
        }

        if (prefixToInsert != null) {
          if (prevLine.trim() == prefixToInsert.trim()) {
            newText = newText.substring(0, prevLineStart) + '\n' + newText.substring(sel.start);
            final cursor = prevLineStart + 1;
            _textController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursor),
            );
          } else {
            newText = newText.substring(0, sel.start) + prefixToInsert + newText.substring(sel.start);
            final cursor = sel.start + prefixToInsert.length;
            _textController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursor),
            );
          }
        }
      }
    }

    if (newText != _markdown) {
      _markdown = newText;
      _updateActiveFormats();
      notifyListeners();
    }
  }

  void _updateActiveFormats() {
    final sel = _textController.selection;
    final text = _textController.text;
    if (!sel.isValid) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final line = text.substring(lineStart, lineEnd == -1 ? text.length : lineEnd);

    final block = _blockFormatOf(line);
    if (block != _activeBlock) {
      _activeBlock = block;
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  static TextEditingController _buildTextController(String text) {
    return _SrqTextEditingController(text: text);
  }

  void _init() {
    _textController.addListener(_onTextChanged);
  }

  void _pushUndoSnapshot() {
    if (_undoStack.isEmpty || _undoStack.last != _markdown) {
      _undoStack.add(_markdown);
      if (_undoStack.length > 100) _undoStack.removeAt(0);
      _redoStack.clear();
    }
  }

  void _syncTextController() {
    final offset = _textController.selection.isValid
        ? _textController.selection.start.clamp(0, _markdown.length)
        : _markdown.length;
    _textController.value = TextEditingValue(
      text: _markdown,
      selection: TextSelection.collapsed(
          offset: offset.clamp(0, _markdown.length)),
    );
  }

  void _insertAtCursor(String text) {
    _pushUndoSnapshot();
    final controller = _textController;
    final sel = controller.selection;
    final current = controller.text;

    final idx = sel.isValid ? sel.start : current.length;
    final newText = current.substring(0, idx) + text + current.substring(idx);
    _updateText(newText, idx + text.length);
  }

  void _updateText(String newText, int cursorPos) {
    _markdown = newText;
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: cursorPos.clamp(0, newText.length)),
    );
    notifyListeners();
  }

  void _toggleInline(String prefix, String suffix) {
    _pushUndoSnapshot();
    final controller = _textController;
    final sel = controller.selection;
    final text = controller.text;

    if (!sel.isValid || sel.isCollapsed) {
      _insertAtCursor('$prefix$suffix');
      final newOffset = (sel.isValid ? sel.start : text.length) + prefix.length;
      _textController.selection =
          TextSelection.collapsed(offset: newOffset.clamp(0, _markdown.length));
      return;
    }

    final selected = sel.textInside(text);
    final before = text.substring(0, sel.start);
    final after = text.substring(sel.end);

    if (selected.startsWith(prefix) && selected.endsWith(suffix)) {
      final inner =
          selected.substring(prefix.length, selected.length - suffix.length);
      _updateText('$before$inner$after', sel.start + inner.length);
    } else {
      final wrapped = '$prefix$selected$suffix';
      _updateText('$before$wrapped$after', sel.start + wrapped.length);
    }
  }

  void _toggleLinePrefix(String prefix, {bool clearOtherPrefixes = false}) {
    _pushUndoSnapshot();
    final text = _textController.text;
    final sel = _textController.selection;
    if (!sel.isValid) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final lineEnd = text.indexOf('\n', sel.start);
    final end = lineEnd == -1 ? text.length : lineEnd;
    final line = text.substring(lineStart, end);

    String newLine;
    final before = text.substring(0, lineStart);
    final after = end < text.length ? text.substring(end) : '';

    if (line.startsWith(prefix)) {
      newLine = line.substring(prefix.length);
    } else {
      String cleaned = line;
      if (clearOtherPrefixes) {
        cleaned = _clearBlockPrefixes(line);
      }
      newLine = '$prefix$cleaned';
    }

    final newText = '$before$newLine$after';
    final newCursor = (lineStart + newLine.length).clamp(0, newText.length);
    _updateText(newText, newCursor);
  }

  String _clearBlockPrefixes(String line) {
    final prefixes = [
      RegExp(r'^#{1,3}\s'),
      RegExp(r'^\*\s\[\s\]\s'),
      RegExp(r'^\*\s'),
      RegExp(r'^-\s'),
      RegExp(r'^\d+\.\s'),
      RegExp(r'^>\s'),
    ];
    for (final p in prefixes) {
      if (p.hasMatch(line)) {
        return line.replaceFirst(p, '');
      }
    }
    return line;
  }

  @override
  void dispose() {
    _disposed = true;
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }
}

/// Factory to create a pre-configured controller and attach listeners.
extension SrqControllerFactory on SrqController {
  static SrqController create({String initialMarkdown = ''}) {
    final c = SrqController(initialMarkdown: initialMarkdown);
    c._init();
    return c;
  }
}

class _SrqTextEditingController extends TextEditingController {
  _SrqTextEditingController({String? text}) : super(text: text);

  static const _prefixColor = Color(0xFF94A3B8);
  static const _h1Size = 26.0;
  static const _h2Size = 21.0;
  static const _h3Size = 17.0;
  static const _codeBackground = Color(0xFFF3F4F6);
  static const _codeColor = Color(0xFFD63B3B);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) return TextSpan(style: style, text: '');

    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final nl = i < lines.length - 1 ? '\n' : '';

      final headingMatch = RegExp(r'^(#{1,3}) (.*)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final content = headingMatch.group(2) ?? '';
        final size = level == 1 ? _h1Size : level == 2 ? _h2Size : _h3Size;

        final prefixStyle = (style ?? const TextStyle()).copyWith(
          color: _prefixColor,
          fontSize: size,
          fontWeight: FontWeight.w800,
        );
        final contentStyle = (style ?? const TextStyle()).copyWith(
          fontSize: size,
          fontWeight: FontWeight.w800,
        );

        spans.add(TextSpan(text: '${'#' * level} ', style: prefixStyle));
        spans.addAll(_inlineSpans(content, contentStyle));
        if (nl.isNotEmpty) spans.add(TextSpan(text: nl, style: style));
      } else {
        spans.addAll(_inlineSpans(line, style));
        if (nl.isNotEmpty) spans.add(TextSpan(text: nl, style: style));
      }
    }

    return TextSpan(children: spans, style: style);
  }

  List<InlineSpan> _inlineSpans(String text, TextStyle? style) {
    if (text.isEmpty) return [];

    final spans = <InlineSpan>[];
    // Order matters: ** before * to avoid mis-matching single *
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|\*[^*]+\*|~~[^~]+~~|`[^`]+`|<u>[^<]+</u>)',
      dotAll: true,
    );
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: style));
      }

      final matched = match.group(0)!;
      TextStyle current = style ?? const TextStyle();

      if (matched.startsWith('**') && matched.endsWith('**')) {
        current = current.copyWith(fontWeight: FontWeight.bold);
      } else if (matched.startsWith('*') && matched.endsWith('*')) {
        current = current.copyWith(fontStyle: FontStyle.italic);
      } else if (matched.startsWith('~~') && matched.endsWith('~~')) {
        current = current.copyWith(decoration: TextDecoration.lineThrough);
      } else if (matched.startsWith('`') && matched.endsWith('`')) {
        current = current.copyWith(
          backgroundColor: _codeBackground,
          color: _codeColor,
          fontFamily: 'monospace',
        );
      } else if (matched.startsWith('<u>') && matched.endsWith('</u>')) {
        current = current.copyWith(decoration: TextDecoration.underline);
      }

      spans.add(TextSpan(text: matched, style: current));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    return spans;
  }
}
