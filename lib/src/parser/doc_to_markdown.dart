/// Converts an SrqDocument back to a Markdown string.
/// Since the document model IS Markdown, this is trivial.
/// This layer exists so the consuming app always calls docToMarkdown()
/// rather than accessing .markdown directly — keeping the API stable
/// if the document model ever evolves to a richer representation.
import '../models/srq_document.dart';

class DocToMarkdown {
  DocToMarkdown._();

  static String convert(SrqDocument doc) => doc.markdown;
}
