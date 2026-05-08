import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_link_model.dart';
import '../models/smart_content_config.dart';
import '../widgets/file_preview_card.dart';

/// Handles non-image, non-PDF file links (DOCX, XLS, ZIP, etc.).
/// Shows a bottom sheet with a [FilePreviewCard] and live download progress.
class SrqFileDownloadHandler {
  SrqFileDownloadHandler._();

  static void showDownloadSheet({
    required BuildContext context,
    required String url,
    required String filename,
    required ContentType type,
    required SmartContentConfig config,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FileDownloadSheet(
        url: url,
        filename: filename,
        type: type,
        config: config,
      ),
    );
  }
}

// ─── Bottom-sheet widget ──────────────────────────────────────────────────────

class _FileDownloadSheet extends StatefulWidget {
  final String url;
  final String filename;
  final ContentType type;
  final SmartContentConfig config;

  const _FileDownloadSheet({
    required this.url,
    required this.filename,
    required this.type,
    required this.config,
  });

  @override
  State<_FileDownloadSheet> createState() => _FileDownloadSheetState();
}

class _FileDownloadSheetState extends State<_FileDownloadSheet> {
  SrqFileState _state = SrqFileState.idle;
  double _progress = 0;
  String? _savedPath;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _state = SrqFileState.downloading;
      _progress = 0;
      _error = null;
    });

    widget.config.onDownloadStart?.call(widget.url);

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/${widget.filename}';

      final dio = Dio();
      await dio.download(
        widget.url,
        savePath,
        options: Options(headers: widget.config.headers),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _state = SrqFileState.done;
        _savedPath = savePath;
      });
      widget.config.onDownloadComplete?.call(savePath);
    } catch (e) {
      widget.config.onDownloadError?.call(e);
      if (mounted) {
        setState(() {
          _state = SrqFileState.error;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _open() async {
    if (_savedPath == null) return;
    await OpenFilex.open(_savedPath!);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle bar ──────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'File Attachment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilePreviewCard(
                    filename: widget.filename,
                    type: widget.type,
                    downloadState: _state,
                    progress: _progress,
                    error: _error,
                    onDownload: _state == SrqFileState.idle ? _download : null,
                    onOpen: _state == SrqFileState.done ? _open : null,
                    onRetry: _state == SrqFileState.error ? _download : null,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
