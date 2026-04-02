import 'dart:async';
import 'package:flutter/material.dart' show Colors, Material, InkWell;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:my_basic_textfield/src/services/text_editing.dart'
    show TextSelection;
import 'package:flutter/widgets.dart'
    hide
        TextInputType,
        TextEditingValue,
        TextSelectionOverlay,
        TextSelectionDelegate,
        TextSelectionPoint,
        TextSelection;
import 'package:my_basic_textfield/src/widgets/text_selection_overlay.dart';
import 'package:my_basic_textfield/src/services/text_input.dart'
    show
        TextInputClient,
        TextInputType,
        TextInputConnection,
        TextInputAction,
        TextEditingValue,
        TextInput,
        TextInputConfiguration,
        TextSelectionDelegate;

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
    with
        TickerProviderStateMixin<EditableText>,
        TextInputClient,
        TextSelectionDelegate {
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
  TextEditingValue get currentTextEditingValue {
    return _value;
  }

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

    setState(() {
      // Rebuild UI with new text
    });
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
    setState(() {
      // Rebuild to update cursor opacity
    });
  }

  TextInputConfiguration _getTextInputConfiguration() {
    try {
      final viewId = View.of(context).viewId;

      final config = TextInputConfiguration(
        viewID: viewId,
        inputType: widget.keyboardType ?? TextInputType.text,
        inputAction: widget.textInputAction ?? TextInputAction.done,
        keyboardAppearance: widget.keyboardAppearance ?? Brightness.light,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        autocorrect: !widget.obscureText,
        enableSuggestions: !widget.obscureText,
        enableInteractiveSelection: true,
      );

      return config;
    } catch (e) {
      rethrow;
    }
  }

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) {
      return;
    }

    if (!_hasInputConnection) {
      final TextInputConfiguration config = _getTextInputConfiguration();

      _textInputConnection = TextInput.attach(this, config);

      if (_textInputConnection != null) {
        _textInputConnection!.show();
      }

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
    if (!_hasInputConnection) {
      return;
    }

    if (_value == _lastKnownRemoteTextEditingValue) {
      return;
    }

    _textInputConnection!.setEditingState(_value);
    _lastKnownRemoteTextEditingValue = _value;
  }

  void _startCursorBlink() {
    if (!widget.showCursor || !_showBlinkingCursor) {
      return;
    }

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
      selectionControls: _SelectionOverlayControls(),
      selectionDelegate: this,
      onSelectionHandleUpdate: (newPosition) {
        _handleSelectionChanged(newPosition, SelectionChangedCause.drag);
      },
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
      SelectionChangedCause.tap,
    ].contains(cause)) {
      _showKeyboard();
    }

    _selectionOverlay ??= _createSelectionOverlay();
    _selectionOverlay?.update(_value);

    if (selection.isCollapsed) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;
    } else {
      _selectionOverlay?.showToolbar();
    }
  }

  void _showKeyboard() {
    // ✅ FLUTTER FRAMEWORK PATTERN: Check if connection exists AND is attached
    // When platform calls clearClient(), the connection object may still exist
    // but won't be attached to the platform anymore
    // attached getter checks: TextInput._instance._currentConnection == this
    if (_hasInputConnection && _textInputConnection!.attached) {
      _textInputConnection!.show();
    } else {
      // Clear the stale connection reference if it exists
      if (_textInputConnection != null) {
        _textInputConnection = null;
      }
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
    // TEXT INPUT ISSUE DEBUG: Track when platform sends text
    if (value.text != _value.text) {
      debugPrint(
        '📝 updateEditingValue: Text changed from "${_value.text}" to "${value.text}"',
      );
    }

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
      // TEXT INPUT ISSUE DEBUG: Confirm text was set to controller
      debugPrint(
        '📝 updateEditingValue: Text set to controller: "${_value.text}"',
      );

      widget.onChanged?.call(value.text);
      // TEXT INPUT ISSUE DEBUG: Confirm callback was called
      debugPrint('📝 updateEditingValue: onChanged callback called');

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
  void insertContent(KeyboardInsertedContent content) {
    // Handle content insertion from platform
  }

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

    final caretOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: cursorPosition),
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    return caretOffset;
  }

  @override
  Widget build(BuildContext context) {
    // TEXT INPUT ISSUE DEBUG: Log what text is being painted
    if (_value.text.isNotEmpty) {
      debugPrint('🎨 build: Rendering text: "${_value.text}"');
    }

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
            cursorColor: widget.cursorColor ?? Colors.blue,
            cursorWidth: widget.cursorWidth,
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

  @override
  void bringIntoView(TextPosition position) {
    // Bring position into view
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    _hideToolbar();
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    if (_value.selection.isCollapsed) {
      return;
    }

    final _selectedText = _value.text.substring(
      _value.selection.start,
      _value.selection.end,
    );

    Clipboard.setData(ClipboardData(text: _selectedText));
    _hideToolbar();
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    if (_value.selection.isCollapsed) {
      return;
    }

    final selectedText = _value.text.substring(
      _value.selection.start,
      _value.selection.end,
    );

    Clipboard.setData(ClipboardData(text: selectedText));

    final newText = _value.text.replaceRange(
      _value.selection.start,
      _value.selection.end,
      '',
    );

    _value = _value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: _value.selection.start),
    );
    widget.onChanged?.call(newText);
    _hideToolbar();
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final clibBoardData = await Clipboard.getData('text/plain');

    if (clibBoardData == null || clibBoardData.text == null) {
      return;
    }

    final currentTextEdittingValue = _value;
    int currentCursorPosition = currentTextEdittingValue.selection.baseOffset;
    TextEditingValue newTextEdittingValue;

    if (currentTextEdittingValue.selection.isCollapsed) {
      newTextEdittingValue = currentTextEdittingValue.replaced(
        TextRange(
          start: currentCursorPosition,
          end: currentCursorPosition + clibBoardData.text!.length,
        ),
        clibBoardData.text!,
      );
      newTextEdittingValue = newTextEdittingValue.copyWith(
        selection: TextSelection.collapsed(
          offset: currentCursorPosition + clibBoardData.text!.length,
        ),
      );
    } else {
      newTextEdittingValue = currentTextEdittingValue.replaced(
        TextRange(
          start: currentTextEdittingValue.selection.start,
          end: currentTextEdittingValue.selection.end,
        ),
        clibBoardData.text!,
      );
      newTextEdittingValue = newTextEdittingValue.copyWith(
        selection: TextSelection.collapsed(
          offset:
              currentTextEdittingValue.selection.start +
              clibBoardData.text!.length,
        ),
      );
    }

    _value = newTextEdittingValue;
    widget.onChanged?.call(newTextEdittingValue.text);
    _hideToolbar();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    _handleSelectionChanged(
      TextSelection(baseOffset: 0, extentOffset: _value.text.length),
      cause,
    );
  }

  @override
  TextEditingValue get textEditingValue => _value;
}

class _TextFieldPainter extends CustomPainter {
  final TextStyle? style;
  final String text;
  final int selectionStart;
  final int selectionEnd;
  final int cursorPosition;
  final double cursorOpacity;
  final bool obscureText;
  final Color cursorColor;
  final double cursorWidth;

  static const double PADDING_LEFT = 8;
  static const double PADDING_TOP = 12;

  _TextFieldPainter({
    this.style,
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
    required this.cursorPosition,
    required this.obscureText,
    required this.cursorColor,
    required this.cursorWidth,
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

  void _paintCursor(Canvas canvas, Size size) {
    final textPainter = _getTextPainter(maxWidth: size.width - 16);

    final selectionHeight = textPainter.preferredLineHeight;

    final cursorOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: cursorPosition),
      Rect.fromLTWH(0, 0, size.width - 20, size.height),
    );
    final cursorPaint = Paint()
      ..color = cursorColor.withOpacity(cursorOpacity)
      ..strokeWidth = cursorWidth;
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
    _paintCursor(canvas, size);
    _drawBorder(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _TextFieldPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.selectionStart != selectionStart ||
        oldDelegate.selectionEnd != selectionEnd ||
        oldDelegate.cursorPosition != cursorPosition ||
        oldDelegate.cursorColor != cursorColor ||
        oldDelegate.cursorWidth != cursorWidth ||
        oldDelegate.obscureText != obscureText ||
        oldDelegate.cursorOpacity != cursorOpacity;
  }
}

// =============== Selection Overlay Code (unchanged) ===============

class _SelectionOverlayControls {
  Widget buildToolbar(
    BuildContext context,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    return _SelectionToolBar(
      position: _toolBarPositionOffset(endpoints),
      endpoints: endpoints,
      delegate: delegate,
    );
  }

  Offset _toolBarPositionOffset(List<TextSelectionPoint> textSelectionPoints) {
    if (textSelectionPoints.isEmpty) return Offset.zero;
    final _firstOffest = textSelectionPoints.first;
    return Offset(_firstOffest.point.dx, _firstOffest.point.dy - 50);
  }
}

class _SelectionToolBar extends StatelessWidget {
  final List<TextSelectionPoint> endpoints;
  final TextSelectionDelegate delegate;
  final Offset position;
  const _SelectionToolBar({
    super.key,
    required this.endpoints,
    required this.delegate,
    required this.position,
  });

  void _handleCopy() {
    delegate.copySelection(SelectionChangedCause.toolbar);
  }

  void _handleCut() {
    delegate.cutSelection(SelectionChangedCause.toolbar);
  }

  void _handlePaste() {
    delegate.pasteText(SelectionChangedCause.toolbar);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: position.dy,
          left: position.dx,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _ToolBarButton(label: 'Copy', onPressed: _handleCopy),
                const _Devider(),
                _ToolBarButton(label: 'Cut', onPressed: _handleCut),
                const _Devider(),
                _ToolBarButton(label: 'Paste', onPressed: _handlePaste),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Devider extends StatelessWidget {
  const _Devider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: Colors.grey,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ToolBarButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ToolBarButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}

class SelectionHandler extends StatefulWidget {
  final SelectionHandleType type;
  final Offset position;
  final GestureDragStartCallback onPanStart;
  final GestureDragEndCallback onPanEnd;
  final ValueChanged<Offset> onPanUpdate;
  const SelectionHandler({
    super.key,
    required this.type,
    required this.onPanEnd,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.position,
  });

  @override
  State<SelectionHandler> createState() => _SelectionHandlerState();
}

class _SelectionHandlerState extends State<SelectionHandler> {
  late Offset _draggPosition;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (currentPosition) {
        _draggPosition = currentPosition.globalPosition;
        widget.onPanStart.call(currentPosition);
      },
      onPanEnd: (d) => widget.onPanEnd.call(d),
      onPanUpdate: (currentPosition) {
        final delta = currentPosition.globalPosition - _draggPosition;
        _draggPosition = currentPosition.globalPosition;
        widget.onPanUpdate.call(delta);
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
