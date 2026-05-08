import 'package:flutter/material.dart';
import 'srq_controller.dart';

/// The formatting toolbar for the SrqEditor.
///
/// Provides buttons for:
///   Bold, Italic, Strikethrough, Inline code,
///   H1 / H2 / H3,
///   Bullet list, Ordered list, Task list, Blockquote,
///   Divider, Undo, Redo,
///   Image insert (triggers [onImageInsert]),
///   File upload (triggers [onFileUpload]).
class SrqToolbar extends StatefulWidget {
  final SrqController controller;

  /// Called when user taps the image insert button.
  /// The handler should pick/upload the image and call
  /// [controller.insertImage(url)] on success.
  final VoidCallback? onImageInsert;

  /// Called when user taps the file upload button.
  final VoidCallback? onFileUpload;

  final bool showMediaButtons;

  /// Whether the datepicker should also select time.
  final bool isNeedTimeCl;

  /// Scroll direction of the toolbar.
  final Axis axis;

  const SrqToolbar({
    super.key,
    required this.controller,
    this.onImageInsert,
    this.onFileUpload,
    this.showMediaButtons = true,
    this.isNeedTimeCl = false,
    this.axis = Axis.horizontal,
  });

  @override
  State<SrqToolbar> createState() => _SrqToolbarState();
}

class _SrqToolbarState extends State<SrqToolbar> {
  SrqController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    ctrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fmt = ctrl.activeFormat;
    final block = ctrl.activeBlock;

    final buttons = <Widget>[
      // ── Undo / Redo ──────────────────────────────────────────────────────
      _ToolbarIconBtn(
        icon: Icons.undo_rounded,
        tooltip: 'Undo',
        enabled: ctrl.canUndo,
        onTap: ctrl.undo,
      ),
      _ToolbarIconBtn(
        icon: Icons.redo_rounded,
        tooltip: 'Redo',
        enabled: ctrl.canRedo,
        onTap: ctrl.redo,
      ),
      _divider(),

      // ── Block type ───────────────────────────────────────────────────────
      _ToolbarLabelBtn(
        label: 'H1',
        tooltip: 'Heading 1',
        active: block == SrqBlockFormat.heading1,
        onTap: () => ctrl.setHeading(1),
      ),
      _ToolbarLabelBtn(
        label: 'H2',
        tooltip: 'Heading 2',
        active: block == SrqBlockFormat.heading2,
        onTap: () => ctrl.setHeading(2),
      ),
      _ToolbarLabelBtn(
        label: 'H3',
        tooltip: 'Heading 3',
        active: block == SrqBlockFormat.heading3,
        onTap: () => ctrl.setHeading(3),
      ),
      _divider(),

      // ── Inline formats ───────────────────────────────────────────────────
      _ToolbarIconBtn(
        icon: Icons.format_bold_rounded,
        tooltip: 'Bold',
        active: fmt.bold,
        onTap: ctrl.toggleBold,
      ),
      _ToolbarIconBtn(
        icon: Icons.format_italic_rounded,
        tooltip: 'Italic',
        active: fmt.italic,
        onTap: ctrl.toggleItalic,
      ),
      _ToolbarIconBtn(
        icon: Icons.format_strikethrough_rounded,
        tooltip: 'Strikethrough',
        active: fmt.strikethrough,
        onTap: ctrl.toggleStrikethrough,
      ),
      _ToolbarIconBtn(
        icon: Icons.code_rounded,
        tooltip: 'Inline Code',
        active: fmt.code,
        onTap: ctrl.toggleInlineCode,
      ),
      _divider(),

      // ── Lists ────────────────────────────────────────────────────────────
      _ToolbarIconBtn(
        icon: Icons.format_list_bulleted_rounded,
        tooltip: 'Bullet List',
        active: block == SrqBlockFormat.bulletList,
        onTap: ctrl.toggleBulletList,
      ),
      _ToolbarIconBtn(
        icon: Icons.format_list_numbered_rounded,
        tooltip: 'Ordered List',
        active: block == SrqBlockFormat.orderedList,
        onTap: ctrl.toggleOrderedList,
      ),
      _ToolbarIconBtn(
        icon: Icons.checklist_rounded,
        tooltip: 'Task List',
        active: block == SrqBlockFormat.taskList,
        onTap: ctrl.toggleTaskList,
      ),
      _ToolbarIconBtn(
        icon: Icons.format_quote_rounded,
        tooltip: 'Blockquote',
        active: block == SrqBlockFormat.blockquote,
        onTap: ctrl.toggleBlockquote,
      ),
      _ToolbarIconBtn(
        icon: Icons.data_array_rounded,
        tooltip: 'Code Block',
        active: block == SrqBlockFormat.codeBlock,
        onTap: ctrl.toggleCodeBlock,
      ),
      _ToolbarIconBtn(
        icon: Icons.horizontal_rule_rounded,
        tooltip: 'Divider',
        onTap: ctrl.insertDivider,
      ),
      _divider(),

      // ── Date Picker ──────────────────────────────────────────────────────
      _ToolbarIconBtn(
        icon: Icons.calendar_month_rounded,
        tooltip: 'Insert Date',
        onTap: () => _pickDate(context),
      ),
      _divider(),

      // ── Link ─────────────────────────────────────────────────────────────
      _ToolbarIconBtn(
        icon: Icons.link_rounded,
        tooltip: 'Insert Link',
        onTap: () => _showLinkDialog(context),
      ),

      // ── Media ────────────────────────────────────────────────────────────
      if (widget.showMediaButtons) ...[
        _ToolbarIconBtn(
          icon: Icons.image_outlined,
          tooltip: 'Insert Image',
          onTap: widget.onImageInsert,
        ),
        _ToolbarIconBtn(
          icon: Icons.attach_file_rounded,
          tooltip: 'Upload File',
          onTap: widget.onFileUpload,
        ),
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: widget.axis,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: widget.axis == Axis.horizontal
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: buttons,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: buttons,
              ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFDDDDDD),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    DateTime finalDateTime = date;
    
    // Check if context is still mounted before showing the time picker
    if (!context.mounted) return;

    if (widget.isNeedTimeCl) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        finalDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }

    final d = finalDateTime.day.toString().padLeft(2, '0');
    final m = finalDateTime.month.toString().padLeft(2, '0');
    final y = finalDateTime.year;

    String formatted = '$d-$m-$y';
    if (widget.isNeedTimeCl) {
      final hh = finalDateTime.hour % 12 == 0 ? 12 : finalDateTime.hour % 12;
      final mm = finalDateTime.minute.toString().padLeft(2, '0');
      final ampm = finalDateTime.hour < 12 ? 'am' : 'pm';
      formatted += ', $hh:$mm $ampm';
    }

    // Insert as a dummy link so it appears blue, but doesn't trigger a download.
    ctrl.insertLink('#date', text: formatted);
  }

  void _showLinkDialog(BuildContext context) {
    final urlCtrl = TextEditingController();
    final textCtrl = TextEditingController();

    // Pre-fill with selection
    final sel = ctrl.textController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      textCtrl.text = sel.textInside(ctrl.textController.text);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(urlCtrl, 'URL', 'https://example.com'),
            const SizedBox(height: 12),
            _dialogField(textCtrl, 'Display text (optional)', 'Link text'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              ctrl.insertLink(url,
                  text: textCtrl.text.trim().isNotEmpty
                      ? textCtrl.text.trim()
                      : null);
              Navigator.pop(ctx);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
      TextEditingController c, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Internal button widgets ─────────────────────────────────────────────────

class _ToolbarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const _ToolbarIconBtn({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? const Color(0xFFBDBDBD)
        : active
            ? const Color(0xFF2563EB)
            : const Color(0xFF374151);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFEFF6FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _ToolbarLabelBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  const _ToolbarLabelBtn({
    required this.label,
    required this.tooltip,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
