import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart' hide TextEditingValue;
import 'package:my_basic_textfield/src/services/text_input.dart'
    show TextEditingValue, TextSelection;

class TextSelectionOverlay {
  TextSelectionOverlay({
    required this.value,
    required this.context,
    required this.debugRequiredFor,
    required this.toolbarLayerLink,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    this.renderObject,
    this.selectionControls,
    this.selectionDelegate,
  });

  final TextEditingValue value;
  final BuildContext context;
  final Widget debugRequiredFor;
  final LayerLink toolbarLayerLink;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final dynamic renderObject;
  final dynamic selectionControls;
  final dynamic selectionDelegate;

  bool _isVisible = false;
  OverlayEntry? _toolbarEntry;
  OverlayEntry? _startHandleEntry;
  OverlayEntry? _endHandleEntry;

  bool get isVisible => _isVisible;

  void show() {
    if (_isVisible) return;
    _isVisible = true;
    _buildAndShowToolbar();
    _buildAndShowHandles();
  }

  void hide() {
    if (!_isVisible) return;
    _isVisible = false;
    _toolbarEntry?.remove();
    _startHandleEntry?.remove();
    _endHandleEntry?.remove();
    _toolbarEntry = null;
    _startHandleEntry = null;
    _endHandleEntry = null;
  }

  void update(TextEditingValue newValue) {
    if (!_isVisible) return;
    hide();
    show();
  }

  void _buildAndShowToolbar() {
    final overlay = Overlay.of(context);
    _toolbarEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        child: CompositedTransformFollower(
          link: toolbarLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Container(
            color: Colors.grey[300],
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 8),
                Text('Copy'),
                SizedBox(width: 8),
                Text('Paste'),
                SizedBox(width: 8),
                Text('Select All'),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toolbarEntry!);
  }

  void _buildAndShowHandles() {
    if (!value.selection.isValid || value.selection.isCollapsed) return;

    final overlay = Overlay.of(context);

    _startHandleEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        child: CompositedTransformFollower(
          link: startHandleLayerLink,
          showWhenUnlinked: false,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );

    _endHandleEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        child: CompositedTransformFollower(
          link: endHandleLayerLink,
          showWhenUnlinked: false,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_startHandleEntry!);
    overlay.insert(_endHandleEntry!);
  }

  void dispose() {
    hide();
  }
}
