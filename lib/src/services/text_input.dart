import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    hide TextInputType, TextInputAction, TextEditingValue;

enum TextInputAction {
  none,
  unspecified,
  done,
  go,
  search,
  send,
  next,
  previous,
  newline,
}

@immutable
class TextInputType {
  final int index;
  final bool? signed;
  final bool? decimal;
  const TextInputType._(this.index) : decimal = null, signed = null;
  const TextInputType.numberWithOption({
    this.signed = false,
    this.decimal = false,
  }) : index = 2;

  static const TextInputType text = TextInputType._(0);
  static const TextInputType multiline = TextInputType._(1);
  static const TextInputType number = TextInputType.numberWithOption();
  static const TextInputType phoneNumber = TextInputType._(3);
  static const TextInputType datetime = TextInputType._(4);
  static const TextInputType emailAddress = TextInputType._(5);
  static const TextInputType url = TextInputType._(6);

  static const List<TextInputType> values = [
    text,
    multiline,
    number,
    phoneNumber,
    datetime,
    emailAddress,
    url,
  ];

  static const List<String> _names = [
    'text',
    'multiline',
    'number',
    'phoneNumber',
    'datetime',
    'emailAddress',
    'url',
  ];
  String get name => "TextInputType.${_names[index]}";

  String toString() {
    return "name: $name, signed: $signed, decimal: $decimal, index: $index";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextInputType) return false;
    return index == other.index &&
        signed == other.signed &&
        decimal == other.decimal;
  }

  @override
  int get hashCode => Object.hash(index, signed, decimal);
}

class TextInputConfiguration {
  TextInputConfiguration({
    this.viewID,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.unspecified,
    this.keyboardAppearance = Brightness.light,
    this.readOnly = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection = true,
  });

  final int? viewID;

  final TextInputType inputType;

  final TextInputAction inputAction;

  final Brightness? keyboardAppearance;

  final bool readOnly;

  final bool obscureText;

  final bool autocorrect;

  final bool enableSuggestions;

  final bool enableInteractiveSelection;

  TextInputConfiguration copyWith({
    int? viewID,
    TextInputType? inputType,
    TextInputAction? inputAction,
    Brightness? keyboardAppearance,
    bool? readOnly,
    bool? obscureText,
    bool? autocorrect,
    bool? enableSuggestions,
    TextCapitalization? textCapitalization,
    bool? enableInteractiveSelection,
  }) {
    return TextInputConfiguration(
      viewID: viewID ?? this.viewID,
      inputType: inputType ?? this.inputType,
      inputAction: inputAction ?? this.inputAction,
      keyboardAppearance: keyboardAppearance ?? this.keyboardAppearance,
      readOnly: readOnly ?? this.readOnly,
      obscureText: obscureText ?? this.obscureText,
      autocorrect: autocorrect ?? this.autocorrect,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
    );
  }

  /// Converts this configuration to a JSON map for sending to the platform
  Map<String, Object?> toJson() {
    return {
      "viewID": viewID,
      "inputType": inputType.toString(),
      "inputAction": inputAction.toString(),
      "keyboardAppearance": keyboardAppearance.toString(),
      "readOnly": readOnly,
      "obscureText": obscureText,
      "autocorrect": autocorrect,
      "enableSuggestions": enableSuggestions,
      "enableInteractiveSelection": enableInteractiveSelection,
    };
  }

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextInputConfiguration) return false;
    return viewID == other.viewID &&
        inputType == other.inputType &&
        inputAction == other.inputAction &&
        keyboardAppearance == other.keyboardAppearance &&
        readOnly == other.readOnly &&
        obscureText == other.obscureText &&
        autocorrect == other.autocorrect &&
        enableSuggestions == other.enableSuggestions &&
        enableInteractiveSelection == other.enableInteractiveSelection;
  }

  @override
  int get hashCode => Object.hash(
    viewID,
    inputType,
    inputAction,
    keyboardAppearance,
    readOnly,
    obscureText,
    autocorrect,
    enableSuggestions,
    enableInteractiveSelection,
  );

  @override
  String toString() {
    return 'TextInputConfiguration('
        'viewID: $viewID, '
        'inputType: $inputType, '
        'inputAction: $inputAction, '
        'keyboardAppearance: $keyboardAppearance, '
        'readOnly: $readOnly, '
        'obscureText: $obscureText, '
        'autocorrect: $autocorrect, '
        'enableSuggestions: $enableSuggestions, '
        'enableInteractiveSelection: $enableInteractiveSelection'
        ')';
  }
}

mixin TextInputClient {
  TextEditingValue? get currentTextEditingValue;
  void updateEditingValue(TextEditingValue value);
  void performAction(TextInputAction action);
  void closeConnection();
  void insertContent(KeyboardInsertedContent content);
}

class TextInput {
  TextInput._() {
    _channel = SystemChannels.textInput;
  }
  static final TextInput _instance = TextInput._();

  late final MethodChannel _channel;

  static TextInput get instance => _instance;
  TextInputConnection? _currentConnection;
  TextInputConfiguration? _currentConfiguration;

  Set<TextInputControl> _textInputControls = {
    _PlatformTextInputControl.instance,
  };

  static TextInputConnection attach(
    TextInputClient client,
    TextInputConfiguration configuration,
  ) {
    final connection = TextInputConnection._(client);
    _instance._attach(connection, configuration);
    return connection;
  }

  void _attach(
    TextInputConnection connection,
    TextInputConfiguration configuration,
  ) {
    _currentConfiguration = configuration;
    _currentConnection = connection;
    _setClient(connection.client, configuration);
  }

  void _setClient(
    TextInputClient client,
    TextInputConfiguration configuration,
  ) {
    for (final control in _textInputControls) {
      control.attach(client, configuration);
    }
  }

  void _setEditingState(TextEditingValue value) {
    for (final control in _textInputControls) {
      control.setEditingState(value);
    }
  }

  void _show() {
    for (final control in _textInputControls) {
      control.show();
    }
  }

  void _hide() {
    for (final control in _textInputControls) {
      control.hide();
    }
  }

  void _loudlyHandleTextInputMethodCall(MethodCall call) {
    try {
      _handleTextInputMethodCall(call);
    } catch (e) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: StackTrace.current,
          library: "TextInput",
          context: ErrorDescription(
            "while handling a method call from the platform",
          ),
        ),
      );
    }
  }

  void _handleTextInputMethodCall(MethodCall call) {
    if (call.method == "TextInputClient.updateEditingState") {
      final int id = call.arguments["id"];
      final String text = call.arguments["text"];
      final int selectionBase = call.arguments["selectionBase"];
      final int selectionExtent = call.arguments["selectionExtent"];
      final TextAffinity selectionAffinity =
          TextAffinity.values[call.arguments["selectionAffinity"]];
      final bool selectionIsDirectional =
          call.arguments["selectionIsDirectional"];
      final TextEditingValue value = TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: selectionBase,
          extentOffset: selectionExtent,
          affinity: selectionAffinity,
          isDirectional: selectionIsDirectional,
        ),
      );
      _textInputClients[id]?.updateEditingValue(value);
    } else if (call.method == "TextInputClient.performAction") {
      final int id = call.arguments["id"];
      final TextInputAction action =
          TextInputAction.values[call.arguments["action"]];
      _textInputClients[id]?.performAction(action);
    } else if (call.method == "TextInputClient.closeConnection") {
      final int id = call.arguments["id"];
      _textInputClients[id]?.closeConnection();
    } else if (call.method == "TextInputClient.insertContent") {
      final int id = call.arguments["id"];
      final String mimeType = call.arguments["mimeType"];
      final Uint8List data = call.arguments["data"];
      _textInputClients[id]?.insertContent(
        KeyboardInsertedContent(mimeType: mimeType, data: data),
      );
    } else {
      _loudlyHandleTextInputMethodCall(call);
    }
  }
}

class TextInputConnection {
  TextInputConnection._(this.client) : id = _nextID++;
  TextInputClient client;
  int id;

  static int _nextID = 1;
  bool _closed = false;

  bool get attached => TextInput._instance._currentConnection == this;

  void close() {
    if (_closed) return;
    _closed = true;
    client.closeConnection();
  }

  void show() {
    assert(attached, "Cannot show a TextInputConnection that is not attached.");
    TextInput._instance._show();
  }

  void hide() {
    assert(attached, "Cannot hide a TextInputConnection that is not attached.");
    TextInput._instance._hide();
  }

  void setEditingState(TextEditingValue value) {
    assert(
      attached,
      "Cannot set editing state on a TextInputConnection that is not attached.",
    );
    TextInput._instance._setEditingState(value);
  }
}

mixin TextInputControl {
  void attach(TextInputClient client, TextInputConfiguration configuration);
  void show();
  void hide();
  void handleSizeAndTransform(Size size, Matrix4 transform);
  void updateConfig(TextInputConfiguration config);
  void setEditingState(TextEditingValue value);
  void detach();
}

class _PlatformTextInputControl with TextInputControl {
  _PlatformTextInputControl._();
  static final _PlatformTextInputControl instance =
      _PlatformTextInputControl._();
  MethodChannel? get _channel => TextInput.instance._channel;
  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    _channel?.invokeMethod("TextInput.attach", {
      "id": TextInput.instance._currentConnection?.id,
      "configuration": configuration.toJson(),
    });
  }

  @override
  void detach() {
    _channel?.invokeMethod("TextInput.detach");
  }

  @override
  void updateConfig(TextInputConfiguration config) {
    _channel?.invokeMethod("TextInput.updateConfig", {
      "configuration": config.toJson(),
    });
  }

  @override
  void handleSizeAndTransform(Size size, Matrix4 transform) {
    _channel?.invokeMethod("TextInput.handleSizeAndTransform", {
      "width": size.width,
      "height": size.height,
      "transform": transform.storage,
    });
  }

  @override
  void hide() {
    _channel?.invokeMethod("TextInput.hide");
  }

  @override
  void show() {
    _channel?.invokeMethod("TextInput.show");
  }

  @override
  void setEditingState(TextEditingValue value) {
    _channel?.invokeMethod("TextInput.setEditingState", {
      "text": value.text,
      "selectionBase": value.selection.baseOffset,
      "selectionExtent": value.selection.extentOffset,
      "selectionAffinity": value.selection.affinity.index,
      "selectionIsDirectional": value.selection.isDirectional,
    });
  }
}

class TextEditingValue {
  TextEditingValue({
    this.text = "",
    this.selection = const TextSelection.collapsed(offset: -1),
  });
  final String text;
  final TextSelection selection;

  static final TextEditingValue empty = TextEditingValue();

  TextEditingValue copyWith({String? text, TextSelection? selection}) {
    return TextEditingValue(
      text: text ?? this.text,
      selection: selection ?? this.selection,
    );
  }

  TextEditingValue replaced(TextRange range, String replacement) {
    final String newText = text.replaceRange(
      range.start,
      range.end,
      replacement,
    );
    final int newSelectionBase = selection.baseOffset > range.end
        ? selection.baseOffset - range.end + range.start + replacement.length
        : selection.baseOffset;
    final int newSelectionExtent = selection.extentOffset > range.end
        ? selection.extentOffset - range.end + range.start + replacement.length
        : selection.extentOffset;
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: newSelectionBase,
        extentOffset: newSelectionExtent,
        affinity: selection.affinity,
        isDirectional: selection.isDirectional,
      ),
    );
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextEditingValue) return false;
    return text == other.text && selection == other.selection;
  }

  int get hashCode => Object.hash(text, selection);
  TextEditingValue.fromJSON(Map<String, Object?> json)
    : text = json["text"] as String,
      selection = TextSelection(
        baseOffset: json["selectionBase"] as int,
        extentOffset: json["selectionExtent"] as int,
        affinity: TextAffinity.values[json["selectionAffinity"] as int],
        isDirectional: json["selectionIsDirectional"] as bool,
      );
  Map<String, Object?> toJson() {
    return {
      "text": text,
      "selectionBase": selection.baseOffset,
      "selectionExtent": selection.extentOffset,
      "selectionAffinity": selection.affinity.index,
      "selectionIsDirectional": selection.isDirectional,
    };
  }
}
