import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/smart_content_config.dart';
import '../widgets/image_viewer_widget.dart';
import '../widgets/loading_placeholder.dart';

/// Handles rendering and tapping of network images in the viewer.
class SrqImageHandler {
  SrqImageHandler._();

  /// Open the full-screen image viewer.
  static void openFullScreen({
    required BuildContext context,
    required String url,
    required Map<String, String> headers,
    Widget Function(Object context, String url, Map<String, String> headers)?
        viewerBuilder,
  }) {
    if (viewerBuilder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              viewerBuilder(context, url, headers),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => SrqImageViewerPage(
          url: url,
          headers: headers,
        ),
      ),
    );
  }
}

/// The image widget rendered inline inside [SmartRichTextViewer].
class SrqImageWidget extends StatelessWidget {
  final String url;
  final String alt;
  final SmartContentConfig config;

  const SrqImageWidget({
    super.key,
    required this.url,
    required this.alt,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = url.startsWith('http');

    if (!isNetwork) {
      return _localImage(url, alt);
    }

    return GestureDetector(
      onTap: config.enableImageViewer
          ? () => SrqImageHandler.openFullScreen(
                context: context,
                url: url,
                headers: config.headers,
                viewerBuilder: config.imageViewerBuilder,
              )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          httpHeaders: config.headers,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (_, __) => const SrqLoadingPlaceholder(height: 200),
          errorBuilder: (_, __, ___) => _errorWidget(alt),
        ),
      ),
    );
  }

  Widget _localImage(String path, String alt) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorWidget(alt),
      ),
    );
  }

  Widget _errorWidget(String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined,
              color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load: $name',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
