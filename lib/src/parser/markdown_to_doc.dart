/// Converts a Markdown string into an SrqDocument (trivial for now,
/// since the document model stores raw Markdown).
///
/// This layer exists as an extension point for future delta-style parsing.
import '../models/srq_document.dart';
import 'content_normalizer.dart';

class MarkdownToDoc {
  MarkdownToDoc._();

  /// Parse [markdown] into an [SrqDocument], normalizing HTML anchors first.
  static SrqDocument parse(String markdown) {
    final normalized = ContentNormalizer.normalize(markdown);
    return SrqDocument(markdown: normalized);
  }
}
