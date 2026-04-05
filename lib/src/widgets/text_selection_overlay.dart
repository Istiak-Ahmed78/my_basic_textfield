import 'package:flutter/widgets.dart' hide TextEditingValue, TextSelection;
import 'package:my_basic_textfield/src/services/text_input.dart'
    show TextEditingValue;
import 'package:my_basic_textfield/src/services/text_editing.dart'
    show TextSelection;
import 'package:my_basic_textfield/src/widgets/editable_text.dart'
    show SelectionHandler;

class TextSelectionOverlay {
  TextSelectionOverlay({
    required this.value,
    required this.context,
    required this.debugRequiredFor,
    required this.toolbarLayerLink,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.onSelectionHandleUpdate,
    this.textFieldPadding,
    this.textStyle,
    this.textFieldMaxWidth = 400,
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
  final double textFieldMaxWidth;
  final EdgeInsets? textFieldPadding;
  final TextStyle? textStyle;
  final ValueChanged<TextSelection> onSelectionHandleUpdate;

  bool _isVisible = false;
  bool _toolbarVisible = false;
  bool _handlesVisible = false;

  OverlayEntry? _toolbarEntry;
  OverlayEntry? _startHandleEntry;
  OverlayEntry? _endHandleEntry;

  bool get isVisible => _isVisible;

  void showToolbar() {
    if (_toolbarVisible) return;
    _isVisible = true;
    _toolbarVisible = true;
    _buildAndShowToolbar();
  }

  void showHandles() {
    if (_handlesVisible) return;
    _isVisible = true;
    _handlesVisible = true;
    _buildAndShowHandles();
  }

  void show() {
    if (_isVisible) return;
    _isVisible = true;
    _toolbarVisible = true;
    _handlesVisible = true;
    _buildAndShowToolbar();
    _buildAndShowHandles();
  }

  void hide() {
    if (!_isVisible) return;
    _isVisible = false;
    _toolbarVisible = false;
    _handlesVisible = false;

    _toolbarEntry?.remove();
    _startHandleEntry?.remove();
    _endHandleEntry?.remove();

    _toolbarEntry = null;
    _startHandleEntry = null;
    _endHandleEntry = null;
  }

  void hideToolbar() {
    if (!_toolbarVisible) return;
    _toolbarVisible = false;
    _toolbarEntry?.remove();
    _toolbarEntry = null;

    if (!_handlesVisible) {
      _isVisible = false;
    }
  }

  void hideHandles() {
    if (!_handlesVisible) return;
    _handlesVisible = false;
    _startHandleEntry?.remove();
    _endHandleEntry?.remove();
    _startHandleEntry = null;
    _endHandleEntry = null;

    if (!_toolbarVisible) {
      _isVisible = false;
    }
  }

  void update(TextEditingValue newValue) {
    if (!_isVisible) return;

    if (newValue.selection != value.selection) {
      hide();
      show();
    }
  }

  void _buildAndShowToolbar() {
    if (selectionControls == null || selectionDelegate == null) return;

    final overlay = Overlay.of(context);

    final toolbarOffset = _calculateToolbarPosition();
    final textSelectionPoints = _getTextSelectionPoints();

    _toolbarEntry = OverlayEntry(
      builder: (context) {
        return selectionControls.buildToolbar(
          context,
          toolbarOffset,
          textSelectionPoints,
          selectionDelegate,
        );
      },
    );

    overlay.insert(_toolbarEntry!);
  }

  Map<String, Offset> _getHandlePositions() {
    final points = _getTextSelectionPoints();

    if (points.length < 2) {
      return {'start': Offset.zero, 'end': Offset.zero};
    }

    return {'start': points[0].point, 'end': points[1].point};
  }

  void _buildAndShowHandles() {
    if (value.selection.isCollapsed || !value.selection.isValid) {
      return;
    }

    if (selectionControls == null) return;

    final overlay = Overlay.of(context);
    final handlePosition = _getHandlePositions();
    // Start handle
    _startHandleEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: handlePosition['start']?.dy,
          left: handlePosition['start']?.dx,
          child: (handlePosition['start'] != null)
              ? SelectionHandler(
                  type: SelectionHandleType.left,
                  onPanUpdate: (delta) {
                    if (handlePosition['start'] != null) {
                      _handleDragUpdate(
                        handlePosition['start']!,
                        delta,
                        SelectionHandleType.left,
                      );
                    }
                  },
                  onPanStart: (_) {},
                  onPanEnd: (_) {},
                  position: handlePosition['end']!,
                )
              : const SizedBox(),
        );
      },
    );

    _endHandleEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: handlePosition['end']?.dy,
          left: handlePosition['end']?.dx,
          child: (handlePosition['end'] != null)
              ? SelectionHandler(
                  type: SelectionHandleType.right,
                  onPanUpdate: (delta) {
                    if (handlePosition['end'] != null) {
                      _handleDragUpdate(
                        handlePosition['end']!,
                        delta,
                        SelectionHandleType.right,
                      );
                    }
                  },
                  onPanStart: (_) {},
                  onPanEnd: (_) {},
                  position: handlePosition['end']!,
                )
              : const SizedBox(),
        );
      },
    );

    overlay.insert(_startHandleEntry!);
    overlay.insert(_endHandleEntry!);
  }

  Offset _calculateToolbarPosition() {
    final points = _getTextSelectionPoints();

    if (points.isEmpty) {
      return const Offset(0, 0);
    }

    final firstPoint = points.first;
    return Offset(firstPoint.point.dx, firstPoint.point.dy - 60);
  }

  List<TextSelectionPoint> _getTextSelectionPoints() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.text,
        style:
            textStyle ??
            const TextStyle(color: Color(0xFF000000), fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: textFieldMaxWidth);
    final textSelection = value.selection;
    final startPosition = textPainter.getOffsetForCaret(
      TextPosition(offset: textSelection.start),
      Rect.fromLTWH(0, 0, 400, 100),
    );
    final endPosition = textPainter.getOffsetForCaret(
      TextPosition(offset: textSelection.end),
      Rect.fromLTWH(0, 0, 400, 100),
    );
    final lineHeight = textPainter.preferredLineHeight;
    final startingPoint = TextSelectionPoint(
      Offset(
        startPosition.dx + (textFieldPadding?.left ?? 0),
        startPosition.dy + lineHeight + (textFieldPadding?.top ?? 0),
      ),
      TextDirection.ltr,
    );
    final endingPoint = TextSelectionPoint(
      Offset(
        endPosition.dx + (textFieldPadding?.left ?? 0),
        endPosition.dy + lineHeight + (textFieldPadding?.top ?? 0),
      ),
      TextDirection.ltr,
    );
    return [startingPoint, endingPoint];
  }

  int _getTextOffestFromPosition(Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.text,
        style:
            textStyle ??
            const TextStyle(color: Color(0xFF000000), fontSize: 16),
      ),
    );
    textPainter.layout(maxWidth: textFieldMaxWidth);
    final adjustedPosition = Offset(
      position.dx - (textFieldPadding?.left ?? 0),
      position.dy - (textFieldPadding?.top ?? 0),
    );
    TextPosition textOffest = textPainter.getPositionForOffset(
      adjustedPosition,
    );
    return textOffest.offset.clamp(0, value.text.length);
  }

  void _handleDragUpdate(
    Offset initialTextOffset,
    Offset delta,
    SelectionHandleType type,
  ) {
    final newTextPosition = initialTextOffset + delta;
    final newTextOffset = _getTextOffestFromPosition(newTextPosition);
    final currentTextSelection = value.selection;
    TextSelection updatedPosition;
    if (type == SelectionHandleType.left) {
      updatedPosition = TextSelection(
        baseOffset: newTextOffset,
        extentOffset: currentTextSelection.extentOffset,
      );
    } else {
      updatedPosition = TextSelection(
        baseOffset: currentTextSelection.baseOffset,
        extentOffset: newTextOffset,
      );
    }
    if (updatedPosition.baseOffset > updatedPosition.extentOffset) {
      updatedPosition = TextSelection(
        baseOffset: updatedPosition.extentOffset,
        extentOffset: updatedPosition.baseOffset,
      );
    }
    onSelectionHandleUpdate.call(updatedPosition);
  }

  /// Dispose overlay
  void dispose() {
    hide();
  }
}

class TextSelectionPoint {
  final Offset point;
  final TextDirection direction;

  TextSelectionPoint(this.point, this.direction);
}

enum SelectionHandleType { left, right, collapsed }
