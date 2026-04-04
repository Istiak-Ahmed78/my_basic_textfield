import 'package:flutter/material.dart' hide TextEditingValue, TextSelection;

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

  final dynamic value;
  final BuildContext context;
  final dynamic debugRequiredFor;
  final LayerLink toolbarLayerLink;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final dynamic renderObject;
  final dynamic selectionControls;
  final dynamic selectionDelegate;
  final double textFieldMaxWidth;
  final EdgeInsets? textFieldPadding;
  final TextStyle? textStyle;
  final ValueChanged<dynamic> onSelectionHandleUpdate;

  bool _isVisible = false;

  void show() => _isVisible = true;
  void hide() => _isVisible = false;
  void showToolbar() {}
  void showHandles() {}
  void hideToolbar() {}
  void hideHandles() {}
  void update(dynamic newValue) {}
  void dispose() {}
}

class TextSelectionPoint {
  final Offset point;
  final TextDirection direction;
  TextSelectionPoint(this.point, this.direction);
}
