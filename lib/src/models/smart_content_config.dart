import 'package:flutter/widgets.dart';

/// Configuration for network headers, image/file upload, PDF viewer hook.
class SmartContentConfig {
  /// Auth headers forwarded to all network image loads and file downloads.
  final Map<String, String> headers;

  /// Called when an image needs to be uploaded (e.g. user picks from gallery).
  /// Receives the local file path; must return the remote URL (or null on cancel).
  final Future<String?> Function(String localFilePath)? onImageUpload;

  /// Called when a generic file needs to be uploaded.
  /// Receives the local file path; must return the remote URL (or null on cancel).
  final Future<String?> Function(String localFilePath)? onFileUpload;

  /// Optional custom PDF viewer. If null, dio-downloads and opens via open_filex.
  /// Signature: (context, url, headers) → Widget
  final Widget Function(Object context, String url, Map<String, String> headers)?
      pdfViewerBuilder;

  /// Optional image viewer override. Default: built-in full-screen hero viewer.
  final Widget Function(Object context, String url, Map<String, String> headers)?
      imageViewerBuilder;

  /// Read-more character limit. 0 = disabled.
  final int readMoreLimit;

  /// Whether tapping an image opens the full-screen viewer.
  final bool enableImageViewer;

  /// Called when a file download starts.
  final void Function(String url)? onDownloadStart;

  /// Called when a file download completes.
  final void Function(String savedPath)? onDownloadComplete;

  /// Called on download error.
  final void Function(Object error)? onDownloadError;

  const SmartContentConfig({
    this.headers = const {},
    this.onImageUpload,
    this.onFileUpload,
    this.pdfViewerBuilder,
    this.imageViewerBuilder,
    this.readMoreLimit = 0,
    this.enableImageViewer = true,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.onDownloadError,
  });

  SmartContentConfig copyWith({
    Map<String, String>? headers,
    Future<String?> Function(String)? onImageUpload,
    Future<String?> Function(String)? onFileUpload,
    int? readMoreLimit,
    bool? enableImageViewer,
  }) {
    return SmartContentConfig(
      headers: headers ?? this.headers,
      onImageUpload: onImageUpload ?? this.onImageUpload,
      onFileUpload: onFileUpload ?? this.onFileUpload,
      pdfViewerBuilder: pdfViewerBuilder,
      imageViewerBuilder: imageViewerBuilder,
      readMoreLimit: readMoreLimit ?? this.readMoreLimit,
      enableImageViewer: enableImageViewer ?? this.enableImageViewer,
      onDownloadStart: onDownloadStart,
      onDownloadComplete: onDownloadComplete,
      onDownloadError: onDownloadError,
    );
  }
}
