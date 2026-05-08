import 'package:flutter/material.dart';
import '../models/file_link_model.dart';

/// State of a file download in [FilePreviewCard].
enum SrqFileState { idle, downloading, done, error }

/// Visual card for a file attachment — shown in the download bottom sheet.
/// Shows icon, filename, type, progress bar, and action buttons.
class FilePreviewCard extends StatelessWidget {
  final String filename;
  final ContentType type;
  final SrqFileState downloadState;
  final double progress;
  final VoidCallback? onDownload;
  final VoidCallback? onOpen;
  final VoidCallback? onRetry;
  final String? error;

  const FilePreviewCard({
    super.key,
    required this.filename,
    required this.type,
    this.downloadState = SrqFileState.idle,
    this.progress = 0,
    this.onDownload,
    this.onOpen,
    this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _FileIcon(type: type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _typeLabel,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAction(),
            ],
          ),
          if (downloadState == SrqFileState.downloading) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              progress > 0
                  ? 'Downloading… ${(progress * 100).toStringAsFixed(0)}%'
                  : 'Connecting…',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
          if (downloadState == SrqFileState.error) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Download failed. Tap Retry to try again.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAction() {
    switch (downloadState) {
      case SrqFileState.idle:
        return _ActionChip(
          icon: Icons.download_rounded,
          label: 'Download',
          color: const Color(0xFF2563EB),
          onTap: onDownload,
        );
      case SrqFileState.downloading:
        return const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF2563EB)),
        );
      case SrqFileState.done:
        return _ActionChip(
          icon: Icons.open_in_new_rounded,
          label: 'Open',
          color: const Color(0xFF059669),
          onTap: onOpen,
        );
      case SrqFileState.error:
        return _ActionChip(
          icon: Icons.refresh_rounded,
          label: 'Retry',
          color: const Color(0xFFEF4444),
          onTap: onRetry,
        );
    }
  }

  String get _typeLabel {
    switch (type) {
      case ContentType.pdf:    return 'PDF Document';
      case ContentType.excel:  return 'Excel Spreadsheet';
      case ContentType.word:   return 'Word Document';
      case ContentType.zip:    return 'ZIP Archive';
      case ContentType.image:  return 'Image File';
      default:                 return 'File';
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FileIcon extends StatelessWidget {
  final ContentType type;
  const _FileIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Icon(_icon, color: _color, size: 26)),
    );
  }

  IconData get _icon {
    switch (type) {
      case ContentType.pdf:   return Icons.picture_as_pdf_rounded;
      case ContentType.excel: return Icons.table_chart_rounded;
      case ContentType.word:  return Icons.description_rounded;
      case ContentType.zip:   return Icons.folder_zip_rounded;
      case ContentType.image: return Icons.image_rounded;
      default:                return Icons.insert_drive_file_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case ContentType.pdf:   return const Color(0xFFDC2626);
      case ContentType.excel: return const Color(0xFF16A34A);
      case ContentType.word:  return const Color(0xFF2563EB);
      case ContentType.zip:   return const Color(0xFFD97706);
      default:                return const Color(0xFF6B7280);
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
