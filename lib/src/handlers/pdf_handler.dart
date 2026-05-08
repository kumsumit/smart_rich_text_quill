
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Handles opening PDF links — either via a custom builder or by downloading
/// and opening with the system viewer.
class SrqPdfHandler {
  SrqPdfHandler._();

  static void open({
    required BuildContext context,
    required String url,
    required Map<String, String> headers,
    Widget Function(Object context, String url, Map<String, String> headers)?
        viewerBuilder,
  }) {
    if (viewerBuilder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => viewerBuilder(context, url, headers),
        ),
      );
      return;
    }

    // Default: download to temp dir and open with system viewer
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PdfOpenSheet(url: url, headers: headers),
    );
  }
}

class _PdfOpenSheet extends StatefulWidget {
  final String url;
  final Map<String, String> headers;

  const _PdfOpenSheet({required this.url, required this.headers});

  @override
  State<_PdfOpenSheet> createState() => _PdfOpenSheetState();
}

class _PdfOpenSheetState extends State<_PdfOpenSheet> {
  double _progress = 0;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final filename = _extractFilename(widget.url);
      final savePath = '${dir.path}/$filename';

      final dio = Dio();
      await dio.download(
        widget.url,
        savePath,
        options: Options(headers: widget.headers),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() => _downloading = false);
      await OpenFilex.open(savePath);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Failed to open PDF: $e';
        });
      }
    }
  }

  String _extractFilename(String url) {
    final parts = url.split('/');
    final raw = parts.last.split('?').first;
    return raw.isNotEmpty ? raw : 'document.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_rounded,
              size: 40, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          Text(
            _downloading ? 'Opening PDF…' : _error ?? 'Opening…',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? '${(_progress * 100).toStringAsFixed(0)}%'
                  : 'Connecting…',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _download,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
