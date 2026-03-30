import 'dart:async';
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
  final bool readOnly;
  final bool obscureText;
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

    if (_selectionOverlay == null) {
      _selectionOverlay = _createSelectionOverlay();
    }
    _selectionOverlay?.update(_value);
  }

  void _showKeyboard() {
    if (_hasInputConnection) {
      _textInputConnection!.show();
    } else {
      _openInputConnection();
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
  void performAction(TextInputAction action) {}

  @override
  void closeConnection() {
    _closeInputConnectionIfNeeded();
  }

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
