/// Normalizes backend content (mixed Markdown + HTML) into clean Markdown.
///
/// The backend sends a hybrid format:
///   - Standard Markdown for headings, bold, italic, images, etc.
///   - Raw HTML <a href> tags for file links, often with <strong> inside
///   - Escaped characters that need unescaping
///
/// This pre-processor runs before any Markdown rendering.
class ContentNormalizer {
  ContentNormalizer._();

  /// Normalizes [input] content from backend into clean Markdown.
  static String normalize(String input) {
    if (input.trim().isEmpty) return input;

    String result = input;

    // 1. Unescape common escaped sequences the editor may produce
    result = _unescape(result);

    // 2. Convert <a href="URL" ...>text</a> → [text](URL)
    //    Must strip any inner HTML tags from the link text (e.g. <strong>)
    result = _convertHtmlAnchors(result);

    // 3. Normalize excess blank lines (max 2 consecutive)
    result = _normalizeBlankLines(result);

    return result;
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static String _unescape(String s) {
    return s
        .replaceAll(r'\<', '<')
        .replaceAll(r'\>', '>')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\_', '_')
        .replaceAll(r'\-', '-')
        .replaceAll(r'\.', '.');
  }

  static final _anchorRegex = RegExp(
    r'<a\s[^>]*href="([^"]+)"[^>]*>(.*?)<\/a>',
    caseSensitive: false,
    dotAll: true,
  );

  static final _innerHtmlRegex = RegExp(r'<[^>]+>');

  static String _convertHtmlAnchors(String s) {
    return s.replaceAllMapped(_anchorRegex, (match) {
      final url = match.group(1) ?? '';
      final rawText = match.group(2) ?? '';
      // Strip inner HTML tags (e.g. <strong>filename</strong> → filename)
      final text = rawText.replaceAll(_innerHtmlRegex, '').trim();
      if (url.isEmpty) return text;
      return '[$text]($url)';
    });
  }

  static String _normalizeBlankLines(String s) {
    // Collapse 3+ consecutive blank lines into 2
    return s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
