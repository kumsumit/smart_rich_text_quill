/// Lightweight document model — the source of truth for the editor.
/// Stores content as a Markdown string; formatting is applied via spans.
class SrqDocument {
  final String markdown;

  const SrqDocument({this.markdown = ''});

  SrqDocument copyWith({String? markdown}) {
    return SrqDocument(markdown: markdown ?? this.markdown);
  }

  bool get isEmpty => markdown.trim().isEmpty;

  int get length => markdown.length;

  @override
  String toString() => markdown;
}
