import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        Clipboard,
        ClipboardData,
        TextInput,
        TextInputClient,
        TextInputConfiguration,
        TextInputConnection,
        TextInputAction,
        TextInputType,
        TextEditingValue,
        TextSelectionDelegate,
        TextAffinity,
        TextPosition,
        Brightness,
        SelectionChangedCause,
        KeyboardInsertedContent,
        RawFloatingCursorPoint,
        AutofillScope;

class TextEdittingController extends ValueNotifier<TextEditingValue> {
  TextEdittingController(String? text)
    : super(
        text == null ? TextEditingValue.empty : TextEditingValue(text: text),
      );

  TextEditingValue get editingValue => value;
  String get text => value.text;
  set text(String newText) => value = value.copyWith(text: newText);

  TextSelection get selection => value.selection;
  set selection(TextSelection newSelection) =>
      value = value.copyWith(selection: newSelection);

  void clear() => value = TextEditingValue.empty;
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
  State<EditableText> createState() => EditableTextState();
}

class EditableTextState extends State<EditableText>
    with
        TickerProviderStateMixin<EditableText>,
        TextInputClient,
        TextSelectionDelegate {
  late TextEdittingController _controller;
  late FocusNode _focusNode;

  @override
  AutofillScope? get currentAutofillScope => null;

  TextInputConnection? _textInputConnection;
  TextEditingValue _lastKnownRemoteTextEditingValue = TextEditingValue.empty;

  late AnimationController _cursorBlinkOpacityController;
  Timer? _cursorTimer;

  TextEditingValue get _value => _controller.value;

  set _value(TextEditingValue newValue) => _controller.value = newValue;

  bool get _hasFocus => _focusNode.hasFocus;
  bool get _shouldCreateInputConnection => !widget.readOnly;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  bool get _showBlinkingCursor =>
      _hasFocus && _value.selection.isCollapsed && widget.showCursor;

  TextEdittingController get controller => _controller;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  TextEditingValue get textEditingValue => _value;

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
    _cursorTimer?.cancel();
    _cursorBlinkOpacityController.dispose();
    super.dispose();
  }

  void _didChangeTextEditingValue() {
    debugPrint(
      '🔄 _didChangeTextEditingValue: _value.text="${_value.text}", length=${_value.text.length}',
    );
    _updateRemoteEditingValueIfNeeded();
    setState(() {});
    debugPrint(
      '🔄 _didChangeTextEditingValue: setState called, _value now="${_value.text}"',
    );
  }

  void _handleFocusChanged() {
    debugPrint(
      '🔑 _handleFocusChanged: _hasFocus=$_hasFocus, _hasInputConnection=$_hasInputConnection',
    );
    debugPrint('🔑 _handleFocusChanged: widget hashCode=${this.hashCode}');

    if (_hasFocus) {
      debugPrint('🔑 _handleFocusChanged: Gaining focus, opening connection');
      debugPrint(
        '🔑 _handleFocusChanged: this is TextInputClient=${this is TextInputClient}',
      );
      _openInputConnection();
      _startCursorBlink();
    } else {
      debugPrint('🔑 _handleFocusChanged: Losing focus, closing connection');
      _closeInputConnectionIfNeeded();
      _stopCursorBlink();
    }
  }

  void _onCursorColorTick() => setState(() {});

  TextInputConfiguration _getTextInputConfiguration() {
    return TextInputConfiguration(
      inputType: widget.keyboardType ?? TextInputType.text,
      inputAction: widget.textInputAction ?? TextInputAction.done,
      obscureText: widget.obscureText,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
    );
  }

  void _openInputConnection() {
    if (!_shouldCreateInputConnection || _hasInputConnection) return;

    debugPrint('🔑 _openInputConnection: Creating connection');
    final config = _getTextInputConfiguration();
    debugPrint(
      '🔑 _openInputConnection: Attaching with config inputType=${config.inputType}',
    );

    _textInputConnection = TextInput.attach(this, config);

    debugPrint('🔑 _openInputConnection: Connection object created');
    debugPrint(
      '🔑 _openInputConnection: Connection attached=${_textInputConnection?.attached}',
    );
    debugPrint('🔑 _openInputConnection: Calling show()');
    _textInputConnection!.show();

    debugPrint(
      '🔑 _openInputConnection: After show() - attached=${_textInputConnection?.attached}',
    );
    _lastKnownRemoteTextEditingValue = _value;

    // Send initial state to native
    debugPrint('🔑 _openInputConnection: Sending initial editing state');
    _textInputConnection!.setEditingState(_value);
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

  void _stopCursorBlink() {
    _cursorBlinkOpacityController.value = 0.0;
    _cursorTimer?.cancel();
    _cursorTimer = null;
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    _controller.selection = selection;
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    debugPrint(
      '🔑 updateEditingValue: RECEIVED text="${value.text}" (${value.text.length} chars), selection=${value.selection.baseOffset}',
    );
    debugPrint(
      '🔑 updateEditingValue: CURRENT _value="${_value.text}" (${_value.text.length} chars)',
    );

    if (widget.readOnly) {
      value = _value.copyWith(selection: value.selection);
    }

    _lastKnownRemoteTextEditingValue = value;

    if (value.text == _value.text &&
        value.selection.baseOffset == _value.selection.baseOffset &&
        value.selection.extentOffset == _value.selection.extentOffset) {
      debugPrint('🔑 updateEditingValue: early return (no change detected)');
      return;
    }

    debugPrint(
      '🔑 updateEditingValue: APPLYING - changing _value from "${_value.text}" to "${value.text}"',
    );
    _value = value;
    widget.onChanged?.call(value.text);
  }

  @override
  void performAction(TextInputAction action) {
    debugPrint('🎯🎯🎯 performAction CALLED: action=$action');
    switch (action) {
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.search:
      case TextInputAction.send:
      case TextInputAction.next:
      case TextInputAction.previous:
        _focusNode.unfocus();
        widget.onEditingComplete?.call(_controller.text);
        break;
      case TextInputAction.newline:
        if (widget.isMultiline) {
          final newText = _controller.text + '\n';
          _value = _value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
          widget.onChanged?.call(newText);
        }
        break;
      default:
        break;
    }
  }

  @override
  void connectionClosed() => _closeInputConnectionIfNeeded();

  @override
  void closeConnection() => _closeInputConnectionIfNeeded();

  @override
  void insertContent(KeyboardInsertedContent content) {}

  double get cursorOpacity =>
      _showBlinkingCursor ? _cursorBlinkOpacityController.value : 0.0;

  void _handleTap(TapDownDetails details) {
    debugPrint('🔑 _handleTap called, readOnly=${widget.readOnly}');
    if (widget.readOnly) return;
    debugPrint(
      '🔑 _handleTap: requesting focus, current hasFocus=${_focusNode.hasFocus}',
    );
    _focusNode.requestFocus();
    debugPrint(
      '🔑 _handleTap: after requestFocus, hasFocus=${_focusNode.hasFocus}',
    );
    debugPrint(
      '🔑 _handleTap: _hasInputConnection=$_hasInputConnection, _textInputConnection=${_textInputConnection?.attached}',
    );

    if (!_hasInputConnection && !widget.readOnly && _hasFocus) {
      debugPrint(
        '🔑 _handleTap: No input connection but has focus, opening connection',
      );
      _openInputConnection();
    } else if (_hasInputConnection) {
      debugPrint('🔑 _handleTap: has input connection, showing keyboard');
      _textInputConnection?.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? const TextStyle();
    final lineHeight = textStyle.fontSize ?? 16.0 * 1.5;
    final height = widget.isMultiline ? lineHeight * 3 : lineHeight + 24;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        debugPrint('🔑 Focus widget onFocusChange: $hasFocus');
      },
      child: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _TextFieldPainter(
              text: _value.text,
              cursorPosition: _value.selection.baseOffset,
              style: widget.style,
              selection: _value.selection,
              cursorOpacity: cursorOpacity,
              obscureText: widget.obscureText,
              cursorColor: widget.cursorColor ?? Colors.blue,
              cursorWidth: widget.cursorWidth,
            ),
            size: Size(double.infinity, height),
          ),
        ),
      ),
    );
  }

  @override
  void bringIntoView(TextPosition position) {}

  @override
  void hideToolbar([bool hideHandles = true]) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause cause,
  ) {
    _value = value;
    setState(() {});
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    if (_value.selection.isCollapsed) return;
    final selectedText = _value.text.substring(
      _value.selection.start,
      _value.selection.end,
    );
    Clipboard.setData(ClipboardData(text: selectedText));
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    if (_value.selection.isCollapsed) return;
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
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text == null) return;

    final currentCursorPosition = _value.selection.baseOffset;
    final newText = _value.text.replaceRange(
      currentCursorPosition,
      currentCursorPosition,
      clipboardData.text!,
    );

    _value = _value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: currentCursorPosition + clipboardData.text!.length,
      ),
    );
    widget.onChanged?.call(newText);
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    _handleSelectionChanged(
      TextSelection(baseOffset: 0, extentOffset: _value.text.length),
      cause,
    );
  }
}

class _TextFieldPainter extends CustomPainter {
  final TextStyle? style;
  final String text;
  final TextSelection selection;
  final int cursorPosition;
  final double cursorOpacity;
  final bool obscureText;
  final Color cursorColor;
  final double cursorWidth;

  static const double paddingLeft = 8.0;
  static const double paddingTop = 12.0;

  _TextFieldPainter({
    this.style,
    required this.text,
    required this.selection,
    required this.cursorPosition,
    required this.obscureText,
    required this.cursorColor,
    required this.cursorWidth,
    this.cursorOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final displayText = obscureText ? '•' * text.length : text;
    final effectiveStyle = style ?? const TextStyle(color: Colors.black);

    final textPainter = TextPainter(
      text: TextSpan(text: displayText, style: effectiveStyle),
      textDirection: TextDirection.ltr,
    );

    final maxWidth = (size.width - (paddingLeft * 2)).clamp(
      1.0,
      double.infinity,
    );
    textPainter.layout(maxWidth: maxWidth);

    textPainter.paint(
      canvas,
      Offset(paddingLeft, (size.height - textPainter.height) / 2),
    );

    if (cursorOpacity > 0 && cursorPosition >= 0) {
      final cursorPaint = Paint()
        ..color = cursorColor.withValues(alpha: cursorOpacity)
        ..strokeWidth = cursorWidth;

      final clampedPosition = cursorPosition.clamp(0, displayText.length);
      final cursorOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: clampedPosition),
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

      final cursorX = paddingLeft + cursorOffset.dx;
      final textHeight = textPainter.height;
      final cursorY = (size.height - textHeight) / 2;

      canvas.drawLine(
        Offset(cursorX, cursorY),
        Offset(cursorX, cursorY + textHeight),
        cursorPaint,
      );
    }

    final borderPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TextFieldPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.selection != selection ||
        oldDelegate.cursorPosition != cursorPosition ||
        oldDelegate.cursorColor != cursorColor ||
        oldDelegate.cursorWidth != cursorWidth ||
        oldDelegate.obscureText != obscureText ||
        oldDelegate.cursorOpacity != cursorOpacity;
  }
}
