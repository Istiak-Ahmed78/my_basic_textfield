// import 'package:flutter/widgets.dart' hide TextInputType;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide TextInputType, TextEditingValue;
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
    super.key,
  });

  final TextEdittingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final TextAlign textAlign;
  final Color? cursorColor;
  final bool showCursor;

  final bool readOnly;
  final bool obscureText;
  final Brightness? keyboardAppearance;
  final double cursorWidth;

  final TextInputAction? textInputAction;

  @override
  State<EditableText> createState() => _EditableTextState();
}

class _EditableTextState extends State<EditableText> with TextInputClient {
  TextEditingValue get _value =>
      widget.controller?.value ?? TextEditingValue.empty;

  set _value(TextEditingValue newValue) {
    if (widget.controller != null) {
      widget.controller!.value = newValue;
    }
  }

  TextInputConnection? _textInputConnection;
  bool get _hasConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  bool get _hasFocus => widget.focusNode?.hasFocus ?? false;
  bool get _shouldCreateInputConnection => !widget.readOnly || !kIsWeb;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

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
      enableInteractiveSelection: true, // For copy/paste
    );
  }

  TextEditingValue _lastKnownRemoteTextEditingValue = TextEditingValue.empty;

  TextSelectionOverlay? _selectionOverlay;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  @override
  void closeConnection() {
    // TODO: implement closeConnection
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    // TODO: implement insertContent
  }

  @override
  void performAction(TextInputAction action) {
    // TODO: implement performAction
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    if (widget.readOnly) {
      value = _value.copyWith(selection: value.selection);
    }
    _lastKnownRemoteTextEditingValue = value;
    if (_value.text == value.text) {}
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final String text = widget.controller?.text ?? '';
    if (text.length < selection.start || text.length < selection.end) return;

    if ([
      SelectionChangedCause.longPress,
      SelectionChangedCause.drag,
      SelectionChangedCause.scribble,
    ].contains(cause)) {
      _showKeyboard();
    }
  }

  void _showKeyboard() {
    if (_hasFocus) {}
  }

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) return;

    if (!_hasInputConnection) {
      final TextInputConfiguration config = _getTextInputConfiguration();

      _textInputConnection = TextInput.attach(this, config);
      _textInputConnection!.show();
    } else {
      _textInputConnection!.show();
    }
  }
}
