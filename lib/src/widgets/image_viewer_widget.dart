import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen image viewer with pinch-to-zoom and Hero animation.
///
/// Push this page via [Navigator.push] or via [SrqImageHandler.openFullScreen].
class SrqImageViewerPage extends StatelessWidget {
  final String url;
  final Map<String, String> headers;
  final String? heroTag;

  const SrqImageViewerPage({
    super.key,
    required this.url,
    this.headers = const {},
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Zoomable image ───────────────────────────────────────────────
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      child: _NetworkImg(url: url, headers: headers),
                    )
                  : _NetworkImg(url: url, headers: headers),
            ),
          ),

          // ── Close button ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _CloseButton(),
          ),

          // ── Download / share button ──────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: _BottomBar(url: url, headers: headers),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImg extends StatelessWidget {
  final String url;
  final Map<String, String> headers;

  const _NetworkImg({required this.url, required this.headers});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: headers,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
      ),
      errorBuilder: (_, __, ___) => Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          SizedBox(height: 8),
          Text(
            'Could not load image',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String url;
  final Map<String, String> headers;

  const _BottomBar({required this.url, required this.headers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          const Text(
            'Pinch to zoom',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
