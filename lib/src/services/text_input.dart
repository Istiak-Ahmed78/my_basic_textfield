import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    hide TextInputType, TextInputAction, TextEditingValue, TextSelection;
import 'package:my_basic_textfield/src/services/text_editing.dart'
    show TextSelection;

final Map<int, TextInputClient> _textInputClients = {};

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

mixin TextSelectionDelegate {
  TextEditingValue get textEditingValue;
  void hideToolbar([bool hideHandles = true]);

  /// Whether cut is enabled.
  bool get cutEnabled => true;

  /// Whether copy is enabled.
  bool get copyEnabled => true;

  /// Whether paste is enabled.
  bool get pasteEnabled => true;

  /// Whether select all is enabled.
  bool get selectAllEnabled => true;
  void cutSelection(SelectionChangedCause cause);
  Future<void> pasteText(SelectionChangedCause cause);
  void selectAll(SelectionChangedCause cause);
  void copySelection(SelectionChangedCause cause);
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

    // ✅ FIX #1: REGISTER THE METHOD CALL HANDLER!
    _channel.setMethodCallHandler(_loudlyHandleTextInputMethodCall);
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
    try {
      final connection = TextInputConnection._(client);

      _instance._attach(connection, configuration);
      return connection;
    } catch (e) {
      rethrow;
    }
  }

  void _attach(
    TextInputConnection connection,
    TextInputConfiguration configuration,
  ) {
    try {
      _currentConfiguration = configuration;
      _currentConnection = connection;

      _setClient(connection.client, configuration);
    } catch (e) {
      rethrow;
    }
  }

  void _setClient(
    TextInputClient client,
    TextInputConfiguration configuration,
  ) {
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint('║ 📞 _setClient called from platform                       ║');
    debugPrint('├─ client: ${client.runtimeType}');
    debugPrint('├─ configuration: ${configuration.inputType}');
    debugPrint('├─ controls count: ${_textInputControls.length}');

    try {
      for (final control in _textInputControls) {
        debugPrint('├─ Attaching to control: ${control.runtimeType}');
        control.attach(client, configuration);
      }
      debugPrint('├─ ✅ All controls attached successfully');
    } catch (e) {
      debugPrint('├─ ❌ Error attaching controls: $e');
      rethrow;
    }
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );
  }

  void _setEditingState(TextEditingValue value) {
    try {
      for (final control in _textInputControls) {
        control.setEditingState(value);
      }
    } catch (e) {
      rethrow;
    }
  }

  void _show() {
    try {
      for (final control in _textInputControls) {
        control.show();
      }
    } catch (e) {
      rethrow;
    }
  }

  void _hide() {
    try {
      for (final control in _textInputControls) {
        control.hide();
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✅ FIX #2: ADD DEBUG LOGGING TO METHOD CALL HANDLER
  Future<dynamic> _loudlyHandleTextInputMethodCall(MethodCall call) async {
    try {
      await _handleTextInputMethodCall(call);
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

  Future<dynamic> _handleTextInputMethodCall(MethodCall call) async {
    if (call.method == "TextInputClient.updateEditingState") {
      final int id = call.arguments["id"];
      final String text = call.arguments["text"];
      final int selectionBase = call.arguments["selectionBase"];
      final int selectionExtent = call.arguments["selectionExtent"];
      final TextAffinity selectionAffinity =
          TextAffinity.values[call.arguments["selectionAffinity"]];
      final bool selectionIsDirectional =
          call.arguments["selectionIsDirectional"];

      // TEXT INPUT ISSUE DEBUG: Log platform event
      debugPrint(
        '╔════════════════════════════════════════════════════════════╗',
      );
      debugPrint(
        '║ 📱 updateEditingState METHOD CALL received from platform ║',
      );
      debugPrint('├─ clientId: $id');
      debugPrint('├─ text: "$text"');
      debugPrint('├─ selection: $selectionBase-$selectionExtent');

      final TextEditingValue value = TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: selectionBase,
          extentOffset: selectionExtent,
          affinity: selectionAffinity,
          isDirectional: selectionIsDirectional,
        ),
      );

      final client = _textInputClients[id];
      if (client != null) {
        debugPrint('├─ Client found, calling updateEditingValue()');
        client.updateEditingValue(value);
        debugPrint('├─ ✅ updateEditingValue() returned successfully');
      } else {
        debugPrint('├─ ❌ Client not found for ID: $id');
        debugPrint('├─ Available clients: ${_textInputClients.keys.toList()}');
      }
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
    } else if (call.method == "TextInputClient.performAction") {
      final int id = call.arguments["id"];
      final TextInputAction action =
          TextInputAction.values[call.arguments["action"]];

      final client = _textInputClients[id];
      if (client != null) {
        client.performAction(action);
      }
    } else if (call.method == "TextInputClient.closeConnection") {
      final int id = call.arguments["id"];

      final client = _textInputClients[id];
      if (client != null) {
        client.closeConnection();
      }
    } else if (call.method == "TextInputClient.insertContent") {
      final int id = call.arguments["id"];
      final String mimeType = call.arguments["mimeType"];
      final Uint8List data = call.arguments["data"];

      final client = _textInputClients[id];
      if (client != null) {
        client.insertContent(
          KeyboardInsertedContent(mimeType: mimeType, data: data, uri: ""),
        );
      }
    } else {
      throw MissingPluginException();
    }
  }
}

class TextInputConnection {
  TextInputConnection._(this.client) : id = _nextID++ {
    _textInputClients[id] = client;
  }

  TextInputClient client;
  int id;

  static int _nextID = 1;
  bool _closed = false;

  bool get attached {
    final isAttached = TextInput._instance._currentConnection == this;

    return isAttached;
  }

  void close() {
    if (_closed) {
      return;
    }

    _closed = true;

    _textInputClients.remove(id);

    client.closeConnection();
  }

  void show() {
    if (_closed) {
      return;
    }

    assert(attached, "Cannot show a TextInputConnection that is not attached.");
    try {
      TextInput._instance._show();
    } catch (e) {
      rethrow;
    }
  }

  void hide() {
    assert(attached, "Cannot hide a TextInputConnection that is not attached.");
    TextInput._instance._hide();
  }

  void setEditingState(TextEditingValue value) {
    if (_closed) {
      return;
    }

    assert(
      attached,
      "Cannot set editing state on a TextInputConnection that is not attached.",
    );

    try {
      TextInput._instance._setEditingState(value);
    } catch (e) {
      rethrow;
    }
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
    if (_channel == null) {
      return;
    }

    try {
      _channel!.invokeMethod("TextInput.attach", {
        "id": TextInput.instance._currentConnection?.id,
        "configuration": configuration.toJson(),
      });
    } catch (e) {
      rethrow;
    }
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
    if (_channel == null) {
      return;
    }

    try {
      _channel!.invokeMethod("TextInput.show");
    } catch (e) {
      rethrow;
    }
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

  @override
  String toString() {
    return 'TextEditingValue(text: "$text", selection: $selection)';
  }
}
