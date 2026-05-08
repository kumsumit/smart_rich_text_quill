import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/smart_content_config.dart';
import 'srq_controller.dart';
import 'srq_toolbar.dart';

/// The main rich-text editor widget.
///
/// Pure edit mode only — no preview tab. Use [SrqTabEditor] for tabbed UI.
///
/// ```dart
/// SrqEditor(
///   controller: myController,
///   config: SmartContentConfig(
///     headers: myHeaders,
///     onImageUpload: (path) async => uploadAndGetUrl(path),
///   ),
/// )
/// ```
class SrqEditor extends StatefulWidget {
  final SrqController controller;
  final SmartContentConfig config;
  final String placeholder;
  final double? minHeight;
  final double? maxHeight;
  final bool showToolbar;
  final bool autofocus;
  final FocusNode? focusNode;
  final ScrollController? scrollController;

  /// Whether the toolbar date picker should prompt for time selection.
  final bool isNeedTimeCl;

  /// Extra chips shown above the keyboard for quick-insert shortcuts.
  /// Each chip has a [label] and an [onTap] returning the Markdown to insert.
  final List<SrqChipTag>? chipTags;

  const SrqEditor({
    super.key,
    required this.controller,
    this.config = const SmartContentConfig(),
    this.placeholder = 'Write something…',
    this.minHeight,
    this.maxHeight,
    this.showToolbar = true,
    this.autofocus = false,
    this.focusNode,
    this.scrollController,
    this.isNeedTimeCl = false,
    this.chipTags,
  });

  @override
  State<SrqEditor> createState() => _SrqEditorState();
}

class _SrqEditorState extends State<SrqEditor> {
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  bool _isUploading = false;

  SrqController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showToolbar)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SrqToolbar(
              controller: ctrl,
              onImageInsert: _handleImageInsert,
              onFileUpload: _handleFileUpload,
              isNeedTimeCl: widget.isNeedTimeCl,
            ),
          ),
        Flexible(
          child: _buildEditorField(),
        ),
        if (widget.chipTags != null && widget.chipTags!.isNotEmpty)
          _buildChipBar(keyboardHeight),
      ],
    );
  }

  Widget _buildEditorField() {
    return LayoutBuilder(builder: (context, constraints) {
      final minH = widget.minHeight ?? 180.0;
      final maxH = widget.maxHeight ?? 420.0;

      return Container(
        constraints: BoxConstraints(minHeight: minH, maxHeight: maxH),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Scrollbar(
              controller: _scrollController,
              child: TextField(
                controller: ctrl.textController,
                focusNode: _focusNode,
                scrollController: _scrollController,
                autofocus: widget.autofocus,
                maxLines: null,
                expands: constraints.hasBoundedHeight ? false : false,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF1F2937),
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                          strokeWidth: 2.5,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Uploading…',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildChipBar(double keyboardHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        top: 8,
        bottom: keyboardHeight > 0 ? 16 : 0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.chipTags!.map((tag) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  tag.label,
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: tag.icon != null
                    ? Icon(tag.icon, size: 14, color: const Color(0xFF2563EB))
                    : CircleAvatar(
                        backgroundColor:
                            const Color(0xFF2563EB).withValues(alpha: 0.1),
                        child: Text(
                          tag.label.isNotEmpty
                              ? tag.label[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                onPressed: () async {
                  final text = await tag.onTap?.call();
                  if (text != null && text.isNotEmpty) {
                    ctrl.insertAtCursor(text);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Image insert (mirrors AppQuillEditor._handleImageInsert) ────────────────

  Future<void> _handleImageInsert() async {
    if (widget.config.onImageUpload == null) {
      _showSnack('No image upload handler configured.');
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      setState(() => _isUploading = true);

      final url = await widget.config.onImageUpload!(file.path);

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (url == null || url.isEmpty) {
        _showSnack('Image upload cancelled.');
        return;
      }

      final alt = file.name.isNotEmpty ? file.name : 'image';
      ctrl.insertImage(url, alt: alt);
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnack('Error inserting image: $e');
      }
    }
  }

  // ─── File upload ─────────────────────────────────────────────────────────────

  Future<void> _handleFileUpload() async {
    if (widget.config.onFileUpload == null) {
      _showSnack('No file upload handler configured.');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );
      
      if (result == null || result.files.single.path == null || !mounted) return;
      final file = result.files.single;

      setState(() => _isUploading = true);
      final url = await widget.config.onFileUpload!(file.path!);

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (url == null || url.isEmpty) {
        _showSnack('File upload cancelled.');
        return;
      }

      ctrl.insertFileLink(url, file.name);
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnack('Error uploading file: $e');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// A quick-insert chip tag shown above the keyboard in the editor.
class SrqChipTag {
  final String label;
  final IconData? icon;

  /// Called when tapped; return the Markdown fragment to insert, or null.
  final Future<String?> Function()? onTap;

  const SrqChipTag({
    required this.label,
    this.icon,
    this.onTap,
  });
}
