import 'package:flutter/material.dart';
import '../models/smart_content_config.dart';
import '../renderer/smart_rich_text_viewer.dart';
import 'srq_controller.dart';
import 'srq_editor.dart';

/// A tabbed editor widget with **Edit** and **Preview** tabs.
///
/// Drop-in replacement for the Edit/Preview toggle in AppQuillEditor.
///
/// ```dart
/// SrqTabEditor(
///   controller: myController,
///   config: SmartContentConfig(headers: myHeaders),
/// )
/// ```
class SrqTabEditor extends StatefulWidget {
  final SrqController controller;
  final SmartContentConfig config;
  final String placeholder;
  final double? minHeight;
  final double? maxHeight;
  final bool autofocus;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final List<SrqChipTag>? chipTags;

  /// Whether the toolbar date picker should prompt for time selection.
  final bool isNeedTimeCl;

  /// Called when switching between Edit (false) and Preview (true).
  final ValueChanged<bool>? onModeChanged;

  /// Start in preview mode.
  final bool initiallyPreview;

  const SrqTabEditor({
    super.key,
    required this.controller,
    this.config = const SmartContentConfig(),
    this.placeholder = 'Write something…',
    this.minHeight,
    this.maxHeight,
    this.autofocus = false,
    this.focusNode,
    this.scrollController,
    this.chipTags,
    this.isNeedTimeCl = false,
    this.onModeChanged,
    this.initiallyPreview = false,
  });

  @override
  State<SrqTabEditor> createState() => _SrqTabEditorState();
}

class _SrqTabEditorState extends State<SrqTabEditor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initiallyPreview ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final isPreview = _tabController.index == 1;
    if (isPreview) {
      FocusScope.of(context).unfocus();
    }
    if (_tabController.indexIsChanging) return;
    widget.onModeChanged?.call(isPreview);
  }

  @override
  Widget build(BuildContext context) {
    final minH = widget.minHeight ?? 220.0;
    final maxH = widget.maxHeight ?? 480.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tab bar ─────────────────────────────────────────────────────────
        _buildTabBar(),
        const SizedBox(height: 8),

        // ── Tab content ──────────────────────────────────────────────────────
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH, maxHeight: maxH),
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // ── Edit tab ─────────────────────────────────────────────────
                SrqEditor(
                  controller: widget.controller,
                  config: widget.config,
                  placeholder: widget.placeholder,
                  minHeight: minH,
                  maxHeight: maxH,
                  autofocus: widget.autofocus,
                  focusNode: widget.focusNode,
                  scrollController: widget.scrollController,
                  chipTags: widget.chipTags,
                  isNeedTimeCl: widget.isNeedTimeCl,
                ),

                // ── Preview tab ───────────────────────────────────────────────
                AnimatedBuilder(
                  animation: widget.controller,
                  builder: (_, __) {
                    final md = widget.controller.markdown;
                    return Container(
                      constraints:
                          BoxConstraints(minHeight: minH, maxHeight: maxH),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: md.trim().isEmpty
                          ? Center(
                              child: Text(
                                'Nothing to preview',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(14),
                              child: SmartRichTextViewer(
                                content: md,
                                config: widget.config,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF1F2937),
        unselectedLabelColor: const Color(0xFF9CA3AF),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Edit'),
          Tab(text: 'Preview'),
        ],
      ),
    );
  }
}
