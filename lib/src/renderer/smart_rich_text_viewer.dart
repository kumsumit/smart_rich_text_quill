import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/smart_content_config.dart';
import '../models/file_link_model.dart';
import '../parser/content_normalizer.dart';
import '../handlers/image_handler.dart';
import '../handlers/pdf_handler.dart';
import '../handlers/file_download_handler.dart';

/// The main read-only viewer widget.
///
/// Renders a Markdown (or mixed Markdown+HTML) string with:
///   - Proper heading, bold, italic, strikethrough, blockquote styles
///   - Ordered/unordered/task lists
///   - Inline code & code blocks
///   - Network images with headers + full-screen viewer
///   - PDF links → viewer
///   - DOCX / XLS / ZIP / other links → download card
///
/// ```dart
/// SmartRichTextViewer(
///   content: backendMarkdownString,
///   config: SmartContentConfig(headers: myHeaders),
/// )
/// ```
class SmartRichTextViewer extends StatelessWidget {
  final String content;
  final SmartContentConfig config;

  const SmartRichTextViewer({
    super.key,
    required this.content,
    this.config = const SmartContentConfig(),
  });

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    final normalized = ContentNormalizer.normalize(content);

    return MarkdownBody(
      data: normalized,
      selectable: true,
      shrinkWrap: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        <md.InlineSyntax>[
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      styleSheet: _buildStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href == null || href.isEmpty) return;
        _handleLinkTap(context, href, text);
      },
      imageBuilder: (uri, title, alt) {
        return SrqImageWidget(
          url: uri.toString(),
          alt: alt ?? title ?? 'image',
          config: config,
        );
      },
      checkboxBuilder: (checked) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Icon(
          checked
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 18,
          color: checked ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
        ),
      ),
      blockSyntaxes: const [],
    );
  }

  void _handleLinkTap(BuildContext context, String href, String text) {
    final type = classifyUrl(href, text);
    switch (type) {
      case ContentType.image:
        SrqImageHandler.openFullScreen(
          context: context,
          url: href,
          headers: config.headers,
          viewerBuilder: config.imageViewerBuilder,
        );
        break;
      case ContentType.pdf:
        SrqPdfHandler.open(
          context: context,
          url: href,
          headers: config.headers,
          viewerBuilder: config.pdfViewerBuilder,
        );
        break;
      case ContentType.web:
      case ContentType.unwanted:
        // Do nothing for standard links (like tags/chips) as requested
        break;
      // case ContentType.word || ContentType.zip || ContentType.excel
      default:
        // XLS, DOCX, ZIP, generic — show download bottom sheet
        final filename = _extractFilename(href, text);
        SrqFileDownloadHandler.showDownloadSheet(
          context: context,
          url: href,
          filename: filename,
          type: type,
          config: config,
        );
        break;
    }
  }

  String _extractFilename(String url, String linkText) {
    if (linkText.trim().isNotEmpty && linkText != url) return linkText.trim();
    // Try from download param
    final dlMatch = RegExp(r'download="([^"]+)"').firstMatch(url);
    if (dlMatch != null) return dlMatch.group(1)!;
    // Try from url path
    final pathParts = url.split('/');
    final last = pathParts.last.split('?').first;
    if (last.isNotEmpty) return last;
    return 'file';
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      // ── Body ──────────────────────────────────────────────────────────────
      p: const TextStyle(
        fontSize: 14,
        height: 1.65,
        color: Color(0xFF1F2937),
      ),
      // ── Headings ──────────────────────────────────────────────────────────
      h1: const TextStyle(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
      h2: const TextStyle(
        fontSize: 20,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
      h3: const TextStyle(
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
      h2Padding: const EdgeInsets.only(top: 14, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 4),
      // ── Inline ────────────────────────────────────────────────────────────
      strong: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      em: const TextStyle(
        fontStyle: FontStyle.italic,
        color: Color(0xFF374151),
      ),
      del: const TextStyle(
        decoration: TextDecoration.lineThrough,
        color: Color(0xFF9CA3AF),
      ),
      // ── Code ──────────────────────────────────────────────────────────────
      code: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: Color(0xFFF3F4F6),
        color: Color(0xFFD63B3B),
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      // ── Blockquote ────────────────────────────────────────────────────────
      blockquote: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Color(0xFF4B5563),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 4),
        ),
        color: Color(0xFFF0F6FF),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      // ── Lists ─────────────────────────────────────────────────────────────
      listBullet: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2563EB),
      ),
      listIndent: 20,
      // ── Horizontal rule ───────────────────────────────────────────────────
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
      ),
      // ── Links ─────────────────────────────────────────────────────────────
      a: const TextStyle(
        color: Color(0xFF2563EB),
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFF2563EB),
      ),
      // ── Tables ────────────────────────────────────────────────────────────
      tableHead: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      tableBody: const TextStyle(fontSize: 13),
      tableBorder: TableBorder.all(color: const Color(0xFFE5E7EB)),
      tableHeadAlign: TextAlign.left,
    );
  }
}
