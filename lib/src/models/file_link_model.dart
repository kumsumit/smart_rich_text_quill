/// Represents a detected file/media link extracted from the content.
class FileLinkModel {
  final String url;
  final String displayName;
  final ContentType type;
  final String emoji;

  const FileLinkModel({
    required this.url,
    required this.displayName,
    required this.type,
    this.emoji = '📎',
  });

  String get fileExtension {
    final lower = url.toLowerCase();
    final extMatch = RegExp(r'ext=([a-z0-9]+)').firstMatch(lower);
    if (extMatch != null) return extMatch.group(1)!;
    final parts = lower.split('.');
    if (parts.length > 1) return parts.last.split('?').first;
    return '';
  }

  String get typeLabelLong {
    switch (type) {
      case ContentType.pdf:
        return 'PDF Document';
      case ContentType.excel:
        return 'Excel Spreadsheet';
      case ContentType.word:
        return 'Word Document';
      case ContentType.zip:
        return 'ZIP Archive';
      case ContentType.image:
        return 'Image';
      default:
        return 'File';
    }
  }
}

enum ContentType { image, pdf, excel, word, zip, web, generic, unwanted }

/// Classify a URL into a ContentType.
ContentType classifyUrl(String url, [String? linkText]) {
  final lower = url.toLowerCase();
  final lText = linkText?.toLowerCase() ?? '';

  bool check(String ext) {
    return lower.contains('.$ext') ||
        lower.contains('ext=$ext') ||
        lText.contains('.$ext');
  }

  // 1. High priority: Specific file extensions (from URL or filename in text)
  if (check('pdf')) return ContentType.pdf;
  if (check('xlsx') || check('xls')) return ContentType.excel;
  if (check('docx') || check('doc')) return ContentType.word;
  if (check('zip')) return ContentType.zip;
  if (check('jpg') ||
      check('jpeg') ||
      check('png') ||
      check('gif') ||
      check('webp')) {
    return ContentType.image;
  }

  // 2. Medium priority: Chips, Mentions, Tags (Internal organizational links)
  // These should NOT have an action.
  if (lower.startsWith('/') ||
      lower.contains('goto') ||
      lower.startsWith('#') ||
      lower.startsWith('date:')) {
    return ContentType.web;
  }

  // 3. Regular Web Links (Standard http/https pages)
  if (lower.startsWith('http')) {
    // If the user wants standard web links to "open" (e.g. browser), 
    // we can classify them as generic or handle web specially.
    // For now, if it's http and not caught as a file above, we'll let it 
    // fall to generic so it can be handled or kept as web.
    // However, user said "chips" (mentions) shouldn't have action.
    // Usually mentions in this app use the /goto/ pattern (handled above).
    return ContentType.generic;
  }

  return ContentType.generic;
}

String emojiForType(ContentType type) {
  switch (type) {
    case ContentType.pdf:
      return '📕';
    case ContentType.excel:
      return '📊';
    case ContentType.word:
      return '📃';
    case ContentType.zip:
      return '🗜';
    case ContentType.image:
      return '🖼';
    default:
      return '📎';
  }
}
