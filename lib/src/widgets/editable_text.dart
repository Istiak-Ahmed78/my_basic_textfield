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
    debugPrint('🎮 TextEdittingController.text setter called');
    debugPrint('   - Old text: "${value.text}"');
    debugPrint('   - New text: "$valueText"');
    value = value.copyWith(text: valueText);
    debugPrint('   - Value updated');
  }

  TextSelection get selection => value.selection;
  set selection(TextSelection selection) {
    debugPrint('🎮 TextEdittingController.selection setter called');
    debugPrint('   - Old selection: ${value.selection}');
    debugPrint('   - New selection: $selection');
    value = value.copyWith(selection: selection);
    debugPrint('   - Selection updated');
  }

  void clear() {
    debugPrint('🧹 TextEdittingController.clear() called');
    debugPrint('   - Old text: "${value.text}"');
    value = TextEditingValue.empty;
    debugPrint('   - Text cleared');
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
    debugPrint('🎯 _value setter called');
    debugPrint('   - Old value: ${_controller.value}');
    debugPrint('   - New value: $newValue');
    _controller.value = newValue;
    debugPrint('   - Value set in controller');
  }

  bool get _hasFocus => _focusNode.hasFocus;
  bool get _shouldCreateInputConnection => !widget.readOnly;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  bool get _showBlinkingCursor =>
      _hasFocus && _value.selection.isCollapsed && widget.showCursor;

  @override
  TextEditingValue get currentTextEditingValue {
    debugPrint('📖 currentTextEditingValue getter called');
    debugPrint('   - Returning: $_value');
    return _value;
  }

  @override
  void initState() {
    debugPrint('\n🎯 ========== EditableText.initState() ==========');
    super.initState();

    _controller = widget.controller ?? TextEdittingController(null);
    debugPrint('✅ Controller initialized: $_controller');

    _focusNode = widget.focusNode ?? FocusNode();
    debugPrint('✅ FocusNode initialized: $_focusNode');

    _controller.addListener(_didChangeTextEditingValue);
    debugPrint('✅ Text listener attached');

    _focusNode.addListener(_handleFocusChanged);
    debugPrint('✅ Focus listener attached');

    _cursorBlinkOpacityController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
    debugPrint('✅ Cursor blink animation controller initialized');
    debugPrint('🎯 ========== EditableText.initState() END ==========\n');
  }

  @override
  void dispose() {
    debugPrint('\n🗑️ ========== EditableText.dispose() ==========');
    _controller.removeListener(_didChangeTextEditingValue);
    _focusNode.removeListener(_handleFocusChanged);
    _closeInputConnectionIfNeeded();
    _selectionOverlay?.dispose();
    _cursorTimer?.cancel();
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    _cursorBlinkOpacityController.dispose();
    debugPrint('✅ All listeners and connections cleaned up');
    debugPrint('🗑️ ========== EditableText.dispose() END ==========\n');
    super.dispose();
  }

  void _didChangeTextEditingValue() {
    debugPrint('\n📝 ========== _didChangeTextEditingValue() ==========');
    debugPrint('📄 Current text: "${_controller.text}"');
    debugPrint('📏 Text length: ${_controller.text.length}');
    debugPrint('🎯 Selection: ${_controller.selection}');

    _updateRemoteEditingValueIfNeeded();
    debugPrint('✅ Remote editing value updated');

    setState(() {
      debugPrint('🎨 setState() called');
    });
    debugPrint('📝 ========== _didChangeTextEditingValue() END ==========\n');
  }

  void _handleFocusChanged() {
    debugPrint('\n📍 ========== _handleFocusChanged() ==========');
    debugPrint('🎯 Has focus: $_hasFocus');
    debugPrint('📊 Focus node details:');
    debugPrint('   - _focusNode: $_focusNode');
    debugPrint('   - _focusNode.hasFocus: ${_focusNode.hasFocus}');
    debugPrint(
      '   - _shouldCreateInputConnection: $_shouldCreateInputConnection',
    );
    debugPrint('   - _hasInputConnection: $_hasInputConnection');

    if (_hasFocus) {
      debugPrint('✅ Focus gained - Opening input connection');
      _openInputConnection();
      debugPrint('   - _hasInputConnection after open: $_hasInputConnection');
      _startCursorBlink();
      debugPrint('✅ Cursor blink started');
    } else {
      debugPrint('❌ Focus lost - Closing input connection');
      _closeInputConnectionIfNeeded();
      debugPrint('   - _hasInputConnection after close: $_hasInputConnection');
      _stopCursorBlink();
      debugPrint('✅ Cursor blink stopped');
    }
    debugPrint('📍 ========== _handleFocusChanged() END ==========\n');
  }

  void _onCursorColorTick() {
    setState(() {
      // Rebuild to update cursor opacity
    });
  }

  TextInputConfiguration _getTextInputConfiguration() {
    debugPrint('\n⚙️ ========== _getTextInputConfiguration() ==========');

    try {
      final viewId = View.of(context).viewId;
      debugPrint('📊 View ID obtained: $viewId');

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

      debugPrint('✅ Configuration created:');
      debugPrint('   - viewID: ${config.viewID}');
      debugPrint('   - inputType: ${config.inputType}');
      debugPrint('   - inputAction: ${config.inputAction}');
      debugPrint('   - readOnly: ${config.readOnly}');
      debugPrint('   - obscureText: ${config.obscureText}');
      debugPrint('⚙️ ========== _getTextInputConfiguration() END ==========\n');

      return config;
    } catch (e) {
      debugPrint('❌ ERROR in _getTextInputConfiguration(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  void _openInputConnection() {
    debugPrint('\n🔌 ========== _openInputConnection() ==========');
    debugPrint('📊 Status check:');
    debugPrint(
      '   - _shouldCreateInputConnection: $_shouldCreateInputConnection',
    );
    debugPrint('   - _hasInputConnection: $_hasInputConnection');
    debugPrint('   - _textInputConnection: $_textInputConnection');
    debugPrint('   - widget.readOnly: ${widget.readOnly}');

    if (!_shouldCreateInputConnection) {
      debugPrint(
        '❌ Should not create input connection (readOnly or other reason)',
      );
      debugPrint('🔌 ========== _openInputConnection() END ==========\n');
      return;
    }

    if (!_hasInputConnection) {
      debugPrint('📞 Creating new input connection...');
      final TextInputConfiguration config = _getTextInputConfiguration();

      debugPrint('📞 Calling TextInput.attach()...');
      debugPrint('   - this: $this');
      debugPrint('   - config: $config');
      _textInputConnection = TextInput.attach(this, config);
      debugPrint('✅ TextInput.attach() completed');
      debugPrint('   - Connection: $_textInputConnection');
      debugPrint('   - Connection ID: ${_textInputConnection?.id}');
      debugPrint('   - Connection.attached: ${_textInputConnection?.attached}');

      if (_textInputConnection != null) {
        debugPrint('📞 Calling _textInputConnection.show()...');
        _textInputConnection!.show();
        debugPrint('✅ Keyboard shown');
      } else {
        debugPrint('❌ ERROR: _textInputConnection is null after attach()!');
      }

      _lastKnownRemoteTextEditingValue = _value;
      debugPrint(
        '✅ Last known remote value updated: $_lastKnownRemoteTextEditingValue',
      );
    } else {
      debugPrint('⚠️ Input connection already exists');
    }
    debugPrint('🔌 ========== _openInputConnection() END ==========\n');
  }

  void _closeInputConnectionIfNeeded() {
    debugPrint('\n🔌 ========== _closeInputConnectionIfNeeded() ==========');
    debugPrint('📊 Status check:');
    debugPrint('   - _hasInputConnection: $_hasInputConnection');
    debugPrint('   - _textInputConnection: $_textInputConnection');

    if (_hasInputConnection) {
      debugPrint('📞 Closing input connection...');
      debugPrint('   - Connection ID: ${_textInputConnection?.id}');
      debugPrint('   - Connection.attached: ${_textInputConnection?.attached}');
      _textInputConnection?.close();
      debugPrint('✅ Input connection closed');
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = TextEditingValue.empty;
      debugPrint('   - _textInputConnection set to null');
    } else {
      debugPrint('⚠️ No input connection to close');
    }
    debugPrint(
      '🔌 ========== _closeInputConnectionIfNeeded() END ==========\n',
    );
  }

  void _updateRemoteEditingValueIfNeeded() {
    debugPrint(
      '\n🔄 ========== _updateRemoteEditingValueIfNeeded() ==========',
    );
    debugPrint('📊 Status: _hasInputConnection = $_hasInputConnection');

    if (!_hasInputConnection) {
      debugPrint('⚠️ No input connection - skipping update');
      debugPrint(
        '🔄 ========== _updateRemoteEditingValueIfNeeded() END ==========\n',
      );
      return;
    }

    debugPrint('📊 Comparing values:');
    debugPrint('   - Current: $_value');
    debugPrint('   - Last known: $_lastKnownRemoteTextEditingValue');

    if (_value == _lastKnownRemoteTextEditingValue) {
      debugPrint('✅ Values are equal - no update needed');
      debugPrint(
        '🔄 ========== _updateRemoteEditingValueIfNeeded() END ==========\n',
      );
      return;
    }

    debugPrint('📞 Calling setEditingState()...');
    _textInputConnection!.setEditingState(_value);
    debugPrint('✅ setEditingState() completed');

    _lastKnownRemoteTextEditingValue = _value;
    debugPrint('✅ Last known remote value updated');
    debugPrint(
      '🔄 ========== _updateRemoteEditingValueIfNeeded() END ==========\n',
    );
  }

  void _startCursorBlink() {
    debugPrint('\n⏱️ ========== _startCursorBlink() ==========');
    debugPrint('📊 Conditions:');
    debugPrint('   - widget.showCursor: ${widget.showCursor}');
    debugPrint('   - _showBlinkingCursor: $_showBlinkingCursor');

    if (!widget.showCursor || !_showBlinkingCursor) {
      debugPrint('⚠️ Cursor should not blink');
      debugPrint('⏱️ ========== _startCursorBlink() END ==========\n');
      return;
    }

    _cursorTimer?.cancel();
    _cursorBlinkOpacityController.value = 1.0;

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _cursorBlinkOpacityController.value =
          _cursorBlinkOpacityController.value == 0 ? 1 : 0;
    });
    debugPrint('✅ Cursor blink timer started');
    debugPrint('⏱️ ========== _startCursorBlink() END ==========\n');
  }

  void _stopCursorBlink({bool resetCharTicks = true}) {
    debugPrint('\n⏱️ ========== _stopCursorBlink() ==========');
    _cursorBlinkOpacityController.value = 0.0;
    _cursorTimer?.cancel();
    _cursorTimer = null;
    debugPrint('✅ Cursor blink stopped');
    debugPrint('⏱️ ========== _stopCursorBlink() END ==========\n');
  }

  void _hideToolbar() {
    debugPrint('\n🔧 ========== _hideToolbar() ==========');
    _selectionOverlay?.hide();
    _selectionOverlay = null;
    debugPrint('✅ Toolbar hidden');
    debugPrint('🔧 ========== _hideToolbar() END ==========\n');
  }

  TextSelectionOverlay _createSelectionOverlay() {
    debugPrint('\n🎨 ========== _createSelectionOverlay() ==========');
    debugPrint('✅ Creating selection overlay');

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
        debugPrint('🎯 Selection handle updated: $newPosition');
        _handleSelectionChanged(newPosition, SelectionChangedCause.drag);
      },
    );
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    debugPrint('\n🎯 ========== _handleSelectionChanged() ==========');
    debugPrint('📊 New selection: $selection');
    debugPrint('📊 Cause: $cause');

    final String text = _controller.text;

    if (text.length < selection.start || text.length < selection.end) {
      debugPrint('❌ Selection out of bounds - ignoring');
      debugPrint('🎯 ========== _handleSelectionChanged() END ==========\n');
      return;
    }

    _controller.selection = selection;
    debugPrint('✅ Controller selection updated');

    if ([
      SelectionChangedCause.longPress,
      SelectionChangedCause.drag,
      SelectionChangedCause.tap,
    ].contains(cause)) {
      debugPrint('📞 Showing keyboard due to selection change');
      _showKeyboard();
    }

    _selectionOverlay ??= _createSelectionOverlay();
    _selectionOverlay?.update(_value);

    if (selection.isCollapsed) {
      debugPrint('📊 Selection is collapsed - hiding toolbar');
      _selectionOverlay?.hide();
      _selectionOverlay = null;
    } else {
      debugPrint('📊 Selection has content - showing toolbar');
      _selectionOverlay?.showToolbar();
    }
    debugPrint('🎯 ========== _handleSelectionChanged() END ==========\n');
  }

  void _showKeyboard() {
    debugPrint('\n⌨️ ========== _showKeyboard() ==========');
    debugPrint('📊 _hasInputConnection: $_hasInputConnection');
    debugPrint('📊 _textInputConnection: $_textInputConnection');

    // ✅ FLUTTER FRAMEWORK PATTERN: Check if connection exists AND is attached
    // When platform calls clearClient(), the connection object may still exist
    // but won't be attached to the platform anymore
    // attached getter checks: TextInput._instance._currentConnection == this
    if (_hasInputConnection && _textInputConnection!.attached) {
      debugPrint('📞 Showing keyboard via existing attached connection');
      _textInputConnection!.show();
    } else {
      debugPrint(
        '📞 Connection not attached to platform - Opening new connection',
      );
      // Clear the stale connection reference if it exists
      if (_textInputConnection != null) {
        debugPrint(
          '   - Clearing stale connection: ${_textInputConnection!.id}',
        );
        _textInputConnection = null;
      }
      _openInputConnection();
    }
    debugPrint('⌨️ ========== _showKeyboard() END ==========\n');
  }

  void _insertNewLine() {
    debugPrint('\n📝 ========== _insertNewLine() ==========');

    if (!widget.isMultiline) {
      debugPrint('⚠️ Not multiline - finalizing editing');
      _finalizeEditting(true);
      widget.onEditingComplete?.call(_controller.text);
      debugPrint('📝 ========== _insertNewLine() END ==========\n');
      return;
    }

    final currentCursorPosition = _controller.selection.baseOffset;
    debugPrint('📊 Current cursor position: $currentCursorPosition');

    final newText = _controller.text.replaceRange(
      currentCursorPosition,
      currentCursorPosition,
      '\n',
    );
    debugPrint('📝 New text with newline: "$newText"');

    _value = _value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: currentCursorPosition + 1),
    );
    widget.onChanged?.call(newText);
    debugPrint('✅ Newline inserted');
    debugPrint('📝 ========== _insertNewLine() END ==========\n');
  }

  void _finalizeEditting(bool shouldUnfocus) {
    debugPrint('\n🏁 ========== _finalizeEditting() ==========');
    debugPrint('📊 shouldUnfocus: $shouldUnfocus');

    _hideToolbar();
    _stopCursorBlink();

    if (shouldUnfocus) {
      debugPrint('📍 Unfocusing field');
      _focusNode.unfocus();
    }
    debugPrint('🏁 ========== _finalizeEditting() END ==========\n');
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    debugPrint('\n⌨️ ========== updateEditingValue() CALLED ==========');
    debugPrint('📝 Received value: $value');
    debugPrint('📝 Current value: $_value');

    if (widget.readOnly) {
      debugPrint('⚠️ Read-only mode - only updating selection');
      value = _value.copyWith(selection: value.selection);
    }

    _lastKnownRemoteTextEditingValue = value;

    if (value.text == _value.text &&
        value.selection.baseOffset == _value.selection.baseOffset &&
        value.selection.extentOffset == _value.selection.extentOffset) {
      debugPrint('✅ Value unchanged - skipping update');
      debugPrint('⌨️ ========== updateEditingValue() END ==========\n');
      return;
    }

    if (value.text == _value.text) {
      debugPrint('📊 Text unchanged - only selection changed');
      _handleSelectionChanged(value.selection, SelectionChangedCause.keyboard);
    } else {
      debugPrint('📝 Text changed!');
      debugPrint('   - Old text: "${_value.text}"');
      debugPrint('   - New text: "${value.text}"');

      _hideToolbar();
      _value = value;

      debugPrint('📢 Calling onChanged callback...');
      widget.onChanged?.call(value.text);
      debugPrint('✅ onChanged callback completed');

      _handleSelectionChanged(value.selection, SelectionChangedCause.keyboard);

      if (_showBlinkingCursor && _cursorTimer != null) {
        debugPrint('🔄 Restarting cursor blink');
        _stopCursorBlink(resetCharTicks: false);
        _startCursorBlink();
      }
    }
    debugPrint('⌨️ ========== updateEditingValue() END ==========\n');
  }

  @override
  void performAction(TextInputAction action) {
    debugPrint('\n🎬 ========== performAction() ==========');
    debugPrint('🎯 Action: $action');

    switch (action) {
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.search:
      case TextInputAction.send:
      case TextInputAction.next:
      case TextInputAction.previous:
        debugPrint('✅ Finalizing editing');
        _finalizeEditting(true);
        widget.onEditingComplete?.call(_controller.text);
        break;
      case TextInputAction.none:
      case TextInputAction.unspecified:
        debugPrint('⚠️ No action');
        break;
      case TextInputAction.newline:
        debugPrint('📝 Inserting newline');
        _insertNewLine();
    }
    debugPrint('🎬 ========== performAction() END ==========\n');
  }

  @override
  void closeConnection() {
    debugPrint('\n🔌 ========== closeConnection() ==========');
    _closeInputConnectionIfNeeded();
    debugPrint('🔌 ========== closeConnection() END ==========\n');
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    debugPrint('\n📎 ========== insertContent() ==========');
    debugPrint('📎 Content: $content');
    debugPrint('📎 ========== insertContent() END ==========\n');
  }

  double get cursorOpacity =>
      _showBlinkingCursor ? _cursorBlinkOpacityController.value : 0.0;

  void _handleTap(TapDownDetails details) {
    debugPrint('\n👆 ========== _handleTap() ==========');
    debugPrint('📍 Tap position: ${details.localPosition}');
    debugPrint('📊 Current focus state: $_hasFocus');

    if (widget.readOnly) {
      debugPrint('⚠️ Read-only mode - ignoring tap');
      debugPrint('👆 ========== _handleTap() END ==========\n');
      return;
    }

    debugPrint('📍 Requesting focus...');
    debugPrint('   - FocusNode: $_focusNode');
    debugPrint('   - FocusNode.hasFocus before: $_hasFocus');
    _focusNode.requestFocus();
    debugPrint('✅ Focus requested');
    debugPrint('   - FocusNode.hasFocus after: $_hasFocus');

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

    debugPrint('🎯 Tap position offset: ${tapPosition.offset}');

    _handleSelectionChanged(
      TextSelection.collapsed(offset: tapPosition.offset),
      SelectionChangedCause.tap,
    );
    debugPrint('👆 ========== _handleTap() END ==========\n');
  }

  void _handleLongPress(LongPressStartDetails details) {
    debugPrint('\n👆 ========== _handleLongPress() ==========');
    debugPrint('📍 Long press position: ${details.localPosition}');

    if (widget.readOnly) {
      debugPrint('⚠️ Read-only mode - ignoring long press');
      debugPrint('👆 ========== _handleLongPress() END ==========\n');
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

    debugPrint('📝 Selected word: "${text.substring(start, end)}"');

    _handleSelectionChanged(
      TextSelection(baseOffset: start, extentOffset: end),
      SelectionChangedCause.longPress,
    );
    debugPrint('👆 ========== _handleLongPress() END ==========\n');
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
    debugPrint('🎨 EditableText.build() called');

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
    debugPrint('🔍 bringIntoView() called: $position');
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    debugPrint('🔧 hideToolbar() called');
    _hideToolbar();
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    debugPrint('\n📋 ========== copySelection() ==========');
    debugPrint('📊 Cause: $cause');

    if (_value.selection.isCollapsed) {
      debugPrint('⚠️ Selection is collapsed - nothing to copy');
      debugPrint('📋 ========== copySelection() END ==========\n');
      return;
    }

    final _selectedText = _value.text.substring(
      _value.selection.start,
      _value.selection.end,
    );
    debugPrint('📋 Copied text: "$_selectedText"');

    Clipboard.setData(ClipboardData(text: _selectedText));
    _hideToolbar();
    debugPrint('✅ Text copied to clipboard');
    debugPrint('📋 ========== copySelection() END ==========\n');
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    debugPrint('\n✂️ ========== cutSelection() ==========');
    debugPrint('📊 Cause: $cause');

    if (_value.selection.isCollapsed) {
      debugPrint('⚠️ Selection is collapsed - nothing to cut');
      debugPrint('✂️ ========== cutSelection() END ==========\n');
      return;
    }

    final selectedText = _value.text.substring(
      _value.selection.start,
      _value.selection.end,
    );
    debugPrint('✂️ Cut text: "$selectedText"');

    Clipboard.setData(ClipboardData(text: selectedText));

    final newText = _value.text.replaceRange(
      _value.selection.start,
      _value.selection.end,
      '',
    );
    debugPrint('📝 New text after cut: "$newText"');

    _value = _value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: _value.selection.start),
    );
    widget.onChanged?.call(newText);
    _hideToolbar();
    debugPrint('✅ Text cut successfully');
    debugPrint('✂️ ========== cutSelection() END ==========\n');
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    debugPrint('\n📌 ========== pasteText() ==========');
    debugPrint('📊 Cause: $cause');

    final clibBoardData = await Clipboard.getData('text/plain');

    if (clibBoardData == null || clibBoardData.text == null) {
      debugPrint('⚠️ Clipboard is empty');
      debugPrint('📌 ========== pasteText() END ==========\n');
      return;
    }

    debugPrint('📌 Pasted text: "${clibBoardData.text}"');

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

    debugPrint('📝 New text after paste: "${newTextEdittingValue.text}"');

    _value = newTextEdittingValue;
    widget.onChanged?.call(newTextEdittingValue.text);
    _hideToolbar();
    debugPrint('✅ Text pasted successfully');
    debugPrint('📌 ========== pasteText() END ==========\n');
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    debugPrint('\n📋 ========== selectAll() ==========');
    debugPrint('📊 Cause: $cause');
    debugPrint('📝 Text: "${_value.text}"');
    debugPrint('📏 Text length: ${_value.text.length}');

    _handleSelectionChanged(
      TextSelection(baseOffset: 0, extentOffset: _value.text.length),
      cause,
    );
    debugPrint('✅ All text selected');
    debugPrint('📋 ========== selectAll() END ==========\n');
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
