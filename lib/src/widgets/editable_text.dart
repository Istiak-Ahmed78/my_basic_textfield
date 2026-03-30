import 'dart:async';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart'
    hide TextInputType, TextEditingValue, TextSelectionOverlay;
import 'package:my_basic_textfield/src/widgets/text_selection_overlay.dart';
import 'package:my_basic_textfield/src/services/text_input.dart'
    show
        TextInputClient,
        TextInputType,
        TextInputConnection,
        TextInputAction,
        TextEditingValue,
        TextInput,
        TextInputConfiguration;

class TextEdittingController extends ValueNotifier<TextEditingValue> {
  TextEdittingController(String? text)
    : super(
        text == null ? TextEditingValue.empty : TextEditingValue(text: text),
      );

  TextEditingValue get editingValue => value;
  String get text => value.text;
  set text(String valueText) {
    value = value.copyWith(text: valueText);
  }

  TextSelection get selection => value.selection;
  set selection(TextSelection selection) {
    value = value.copyWith(selection: selection);
  }

  void clear() {
    value = TextEditingValue.empty;
  }
}

class EditableText extends StatefulWidget {
  const EditableText({
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.style,
    this.textAlign = TextAlign.start,
    this.cursorColor,
    this.showCursor = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardAppearance,
    this.cursorWidth = 2.0,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.isMultiline = false,
    super.key,
  });

  final TextEdittingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final TextAlign textAlign;
  final Color? cursorColor;
  final bool showCursor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onEditingComplete;
  final bool readOnly;
  final bool obscureText;
  final bool isMultiline;
  final Brightness? keyboardAppearance;
  final double cursorWidth;
  final TextInputAction? textInputAction;

  @override
  State<EditableText> createState() => _EditableTextState();
}

class _EditableTextState extends State<EditableText>
    with TickerProviderStateMixin<EditableText>, TextInputClient {
  late TextEdittingController _controller;
  late FocusNode _focusNode;

  TextInputConnection? _textInputConnection;
  TextSelectionOverlay? _selectionOverlay;
  TextEditingValue _lastKnownRemoteTextEditingValue = TextEditingValue.empty;

  late AnimationController _cursorBlinkOpacityController;
  Timer? _cursorTimer;

  TextEditingValue get _value => _controller.value;

  set _value(TextEditingValue newValue) {
    _controller.value = newValue;
  }

  bool get _hasFocus => _focusNode.hasFocus;
  bool get _shouldCreateInputConnection => !widget.readOnly;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  bool get _showBlinkingCursor =>
      _hasFocus && _value.selection.isCollapsed && widget.showCursor;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEdittingController(null);
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_didChangeTextEditingValue);
    _focusNode.addListener(_handleFocusChanged);

    _cursorBlinkOpacityController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_didChangeTextEditingValue);
    _focusNode.removeListener(_handleFocusChanged);
    _closeInputConnectionIfNeeded();
    _selectionOverlay?.dispose();
    _cursorTimer?.cancel();
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    _cursorBlinkOpacityController.dispose();
    super.dispose();
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    setState(() {});
  }

  void _handleFocusChanged() {
    if (_hasFocus) {
      _openInputConnection();
      _startCursorBlink();
    } else {
      _closeInputConnectionIfNeeded();
      _stopCursorBlink();
    }
  }

  void _onCursorColorTick() {
    setState(() {});
  }

  TextInputConfiguration _getTextInputConfiguration() {
    return TextInputConfiguration(
      viewID: View.of(context).viewId,
      inputType: widget.keyboardType ?? TextInputType.text,
      inputAction: widget.textInputAction ?? TextInputAction.done,
      keyboardAppearance: widget.keyboardAppearance ?? Brightness.light,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
      enableInteractiveSelection: true,
    );
  }

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) return;

    if (!_hasInputConnection) {
      final TextInputConfiguration config = _getTextInputConfiguration();
      _textInputConnection = TextInput.attach(this, config);
      _textInputConnection!.show();
      _lastKnownRemoteTextEditingValue = _value;
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection?.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = TextEditingValue.empty;
    }
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (!_hasInputConnection) return;

    if (_value == _lastKnownRemoteTextEditingValue) return;

    _textInputConnection!.setEditingState(_value);
    _lastKnownRemoteTextEditingValue = _value;
  }

  void _startCursorBlink() {
    if (!widget.showCursor || !_showBlinkingCursor) return;

    _cursorTimer?.cancel();
    _cursorBlinkOpacityController.value = 1.0;

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _cursorBlinkOpacityController.value =
          _cursorBlinkOpacityController.value == 0 ? 1 : 0;
    });
  }

  void _stopCursorBlink({bool resetCharTicks = true}) {
    _cursorBlinkOpacityController.value = 0.0;
    _cursorTimer?.cancel();
    _cursorTimer = null;
  }

  void _hideToolbar() {
    _selectionOverlay?.hide();
    _selectionOverlay = null;
  }

  TextSelectionOverlay _createSelectionOverlay() {
    return TextSelectionOverlay(
      value: _value,
      context: context,
      debugRequiredFor: widget,
      toolbarLayerLink: LayerLink(),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      renderObject: null,
      selectionControls: null,
      selectionDelegate: this,
    );
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final String text = _controller.text;

    if (text.length < selection.start || text.length < selection.end) {
      return;
    }

    _controller.selection = selection;

    if ([
      SelectionChangedCause.longPress,
      SelectionChangedCause.drag,
    ].contains(cause)) {
      _showKeyboard();
    }

    _selectionOverlay ??= _createSelectionOverlay();
    _selectionOverlay?.update(_value);
  }

  void _showKeyboard() {
    if (_hasInputConnection) {
      _textInputConnection!.show();
    } else {
      _openInputConnection();
    }
  }

  void _insertNewLine() {
    if (!widget.isMultiline) {
      _finalizeEditting(true);
      widget.onEditingComplete?.call(_controller.text);
      return;
    }
    final currentCursorPosition = _controller.selection.baseOffset;
    final newText = _controller.text.replaceRange(
      currentCursorPosition,
      currentCursorPosition,
      '\n',
    );
    _value = _value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: currentCursorPosition + 1),
    );
    widget.onChanged?.call(newText);
  }

  void _finalizeEditting(bool shouldUnfocus) {
    _hideToolbar();
    _stopCursorBlink();
    if (shouldUnfocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    if (widget.readOnly) {
      value = _value.copyWith(selection: value.selection);
    }

    _lastKnownRemoteTextEditingValue = value;

    if (value.text == _value.text &&
        value.selection.baseOffset == _value.selection.baseOffset &&
        value.selection.extentOffset == _value.selection.extentOffset) {
      return;
    }

    if (value.text == _value.text) {
      _handleSelectionChanged(value.selection, SelectionChangedCause.keyboard);
    } else {
      _hideToolbar();
      _value = value;
      widget.onChanged?.call(value.text);
      _handleSelectionChanged(value.selection, SelectionChangedCause.keyboard);

      if (_showBlinkingCursor && _cursorTimer != null) {
        _stopCursorBlink(resetCharTicks: false);
        _startCursorBlink();
      }
    }
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.search:
      case TextInputAction.send:
      case TextInputAction.next:
      case TextInputAction.previous:
        _finalizeEditting(true);
        widget.onEditingComplete?.call(_controller.text);
        break;
      case TextInputAction.none:
      case TextInputAction.unspecified:
        break;
      case TextInputAction.newline:
        _insertNewLine();
    }
  }

  @override
  void closeConnection() {
    _closeInputConnectionIfNeeded();
  }

  @override
  void insertContent(KeyboardInsertedContent content) {}
  double get cursorOpacity =>
      _showBlinkingCursor ? _cursorBlinkOpacityController.value : 0.0;

  void _handleTap(TapDownDetails details) {
    if (widget.readOnly) {
      return;
    }
    _focusNode.requestFocus();
    final textPainter = TextPainter(
      text: TextSpan(
        text: _value.text,
        style: widget.style ?? const TextStyle(color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
      textAlign: widget.textAlign,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 16);

    final tapPosition = textPainter.getPositionForOffset(
      Offset(details.localPosition.dx - 8, details.localPosition.dy - 12),
    );

    _handleSelectionChanged(
      TextSelection.collapsed(offset: tapPosition.offset),
      SelectionChangedCause.tap,
    );
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (widget.readOnly) return;

    _focusNode.requestFocus();

    final textPainter = TextPainter(
      text: TextSpan(
        text: _value.text,
        style: widget.style ?? const TextStyle(color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
      textAlign: widget.textAlign,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 16);

    final tapPosition = textPainter.getPositionForOffset(
      Offset(details.localPosition.dx - 8, details.localPosition.dy - 12),
    );

    // Select the word at tap position
    final text = _value.text;
    int start = tapPosition.offset;
    int end = tapPosition.offset;

    // Find word boundaries
    while (start > 0 && text[start - 1] != ' ') {
      start--;
    }
    while (end < text.length && text[end] != ' ') {
      end++;
    }

    _handleSelectionChanged(
      TextSelection(baseOffset: start, extentOffset: end),
      SelectionChangedCause.longPress,
    );
  }

  Offset _getCursorOffset(Size size, TextPainter textPainter) {
    final cursorPosition = _value.selection.baseOffset;
    final text = _value.text;

    if (cursorPosition < 0 || cursorPosition > text.length) {
      return Offset.zero;
    }

    // Get the offset for the cursor position
    final caretOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: cursorPosition),
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    return caretOffset;
  }

  // /// Paints the blinking cursor
  // void _paintCursor(Canvas canvas, Size size, TextPainter textPainter) {
  //   final cursorOffset = _getCursorOffset(size, textPainter);
  //   final cursorHeight = textPainter.preferredLineHeight;

  //   final paint = Paint()
  //     ..color = (widget.cursorColor ?? Colors.blue).withOpacity(
  //       _cursorBlinkOpacityController.value,
  //     )
  //     ..strokeWidth = widget.cursorWidth
  //     ..strokeCap = StrokeCap.round;

  //   canvas.drawLine(
  //     cursorOffset,
  //     cursorOffset.translate(0, cursorHeight),
  //     paint,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        onTapDown: _handleTap,
        onLongPressStart: _handleLongPress,
        child: CustomPaint(
          painter: _TextFieldPainter(
            text: _value.text,
            cursorPosition: _value.selection.baseOffset,
            style: widget.style,
            selectionStart: _value.selection.start,
            selectionEnd: _value.selection.end,
            cursorOpacity: cursorOpacity,
            obscureText: widget.obscureText,
          ),
          size: Size.infinite,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextFieldPainter extends CustomPainter {
  final TextStyle? style;
  final String text;
  final int selectionStart;
  final int selectionEnd;
  final int cursorPosition;
  final double cursorOpacity;
  final bool obscureText;

  static const double PADDING_LEFT = 8;
  static const double PADDING_TOP = 12;

  _TextFieldPainter({
    this.style,
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
    required this.cursorPosition,
    required this.obscureText,
    this.cursorOpacity = 1.0,
  });

  void _drawBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
  }

  TextSpan _buildTextSpan() {
    final text = obscureText ? '•' * this.text.length : this.text;

    if (selectionStart == selectionEnd) {
      return TextSpan(
        text: text,
        style: style ?? const TextStyle(color: Colors.black),
      );
    }
    final beforeSelection = text.substring(0, selectionStart);
    final selectedText = text.substring(selectionStart, selectionEnd);
    final afterSelection = text.substring(selectionEnd);
    return TextSpan(
      style: style ?? const TextStyle(color: Colors.black),
      children: [
        TextSpan(text: beforeSelection),
        TextSpan(
          text: selectedText,
          style:
              style?.copyWith(
                color: Colors.white,
                backgroundColor: Colors.blue,
              ) ??
              const TextStyle(
                color: Colors.white,
                backgroundColor: Colors.blue,
              ),
        ),
        TextSpan(text: afterSelection),
      ],
    );
  }

  TextPainter _getTextPainter({required double maxWidth}) {
    return TextPainter(text: _buildTextSpan(), textDirection: TextDirection.ltr)
      ..layout(maxWidth: maxWidth);
  }

  void _paintText(Canvas canvas, Size size) {
    final textPainter = _getTextPainter(maxWidth: size.width - 16);
    textPainter.paint(canvas, Offset(PADDING_LEFT, PADDING_TOP));
  }

  // void _paintSelection(Canvas canvas, Size size) {
  //   if (selectionStart == selectionEnd) return;
  //   final textPainter = _getTextPainter(maxWidth: size.width - 16);
  //   final selectionHeight = textPainter.preferredLineHeight;
  //   final startOffset = textPainter.getOffsetForCaret(
  //     TextPosition(offset: selectionStart),
  //     Rect.fromLTWH(0, 0, size.width - 20, size.height),
  //   );
  //   final endOffset = textPainter.getOffsetForCaret(
  //     TextPosition(offset: selectionEnd),
  //     Rect.fromLTWH(0, 0, size.width - 20, size.height),
  //   );
  //   final selectionPaint = Paint()
  //     ..color = Colors.blue.withOpacity(0.5)
  //     ..style = PaintingStyle.fill;
  //   final selectionRect = Rect.fromLTRB(
  //     PADDING_LEFT + startOffset.dx,
  //     PADDING_TOP + startOffset.dy,
  //     PADDING_LEFT + endOffset.dx,
  //     PADDING_TOP + startOffset.dy + selectionHeight,
  //   );
  //   canvas.drawRect(selectionRect, selectionPaint);
  // }

  void _paintCursor(Canvas canvas, Size size) {
    final textPainter = _getTextPainter(maxWidth: size.width - 16);

    final selectionHeight = textPainter.preferredLineHeight;

    final cursorOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: cursorPosition),
      Rect.fromLTWH(0, 0, size.width - 20, size.height),
    );
    final cursorPaint = Paint()
      ..color = Colors.blue.withOpacity(cursorOpacity)
      ..strokeWidth = 2.0;
    final cursorX = PADDING_LEFT + cursorOffset.dx;
    final cursorStartY = PADDING_TOP + cursorOffset.dy;
    final cursorEndY = PADDING_TOP + cursorOffset.dy + selectionHeight;

    // Draw cursor line
    canvas.drawLine(
      Offset(cursorX, cursorStartY),
      Offset(cursorX, cursorEndY),
      cursorPaint,
    );
  }

  void _drawBorder(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _paintText(canvas, size);
    // _paintSelection(canvas, size);
    _paintCursor(canvas, size);
    _drawBorder(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _TextFieldPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.selectionStart != selectionStart ||
        oldDelegate.selectionEnd != selectionEnd ||
        oldDelegate.cursorPosition != cursorPosition ||
        oldDelegate.cursorOpacity != cursorOpacity;
  }
}
