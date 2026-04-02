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
    debugPrint('🔧 ========== TextInput._() CONSTRUCTOR ==========');
    _channel = SystemChannels.textInput;
    debugPrint('✅ MethodChannel created: $_channel');

    // ✅ FIX #1: REGISTER THE METHOD CALL HANDLER!
    debugPrint('📞 Setting up method call handler...');
    _channel.setMethodCallHandler(_loudlyHandleTextInputMethodCall);
    debugPrint('✅ Method call handler registered!');
    debugPrint('🔧 ========== TextInput._() CONSTRUCTOR END ==========\n');
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
    debugPrint('\n📞 ========== TextInput.attach() STATIC METHOD ==========');
    debugPrint('📊 Client type: ${client.runtimeType}');
    debugPrint(
      '📊 Client implements TextInputClient: ${client is TextInputClient}',
    );
    debugPrint('📊 Configuration: $configuration');

    try {
      final connection = TextInputConnection._(client);
      debugPrint('✅ TextInputConnection created with ID: ${connection.id}');
      debugPrint(
        '   - Client registered in _textInputClients: ${_textInputClients.containsKey(connection.id)}',
      );

      _instance._attach(connection, configuration);
      debugPrint('✅ _attach() completed successfully');
      debugPrint('📞 ========== TextInput.attach() END ==========\n');
      return connection;
    } catch (e) {
      debugPrint('❌ ERROR in TextInput.attach(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '📞 ========== TextInput.attach() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  void _attach(
    TextInputConnection connection,
    TextInputConfiguration configuration,
  ) {
    debugPrint('\n🔌 ========== TextInput._attach() ==========');
    debugPrint('📊 Connection ID: ${connection.id}');
    debugPrint('📊 Configuration: $configuration');

    try {
      _currentConfiguration = configuration;
      _currentConnection = connection;
      debugPrint('✅ Current connection set');
      debugPrint('   - _currentConnection.id: ${_currentConnection?.id}');
      debugPrint('   - _currentConfiguration: $_currentConfiguration');

      _setClient(connection.client, configuration);
      debugPrint('✅ _setClient() completed');
      debugPrint('🔌 ========== TextInput._attach() END ==========\n');
    } catch (e) {
      debugPrint('❌ ERROR in TextInput._attach(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '🔌 ========== TextInput._attach() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  void _setClient(
    TextInputClient client,
    TextInputConfiguration configuration,
  ) {
    debugPrint('\n🎯 ========== TextInput._setClient() ==========');
    debugPrint('📊 Client type: ${client.runtimeType}');
    debugPrint('📊 Client: $client');
    debugPrint('📊 Configuration: $configuration');
    debugPrint('📊 Number of controls: ${_textInputControls.length}');

    try {
      for (final control in _textInputControls) {
        debugPrint('📞 Calling control.attach() for ${control.runtimeType}');
        debugPrint('   - Control: $control');
        control.attach(client, configuration);
        debugPrint('✅ control.attach() completed for ${control.runtimeType}');
      }
      debugPrint('✅ All controls attached successfully');
      debugPrint('🎯 ========== TextInput._setClient() END ==========\n');
    } catch (e) {
      debugPrint('❌ ERROR in TextInput._setClient(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '🎯 ========== TextInput._setClient() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  void _setEditingState(TextEditingValue value) {
    debugPrint('\n📝 ========== TextInput._setEditingState() ==========');
    debugPrint('📊 Value: $value');
    debugPrint('📊 Number of controls: ${_textInputControls.length}');

    try {
      for (final control in _textInputControls) {
        debugPrint(
          '📞 Calling control.setEditingState() for ${control.runtimeType}',
        );
        control.setEditingState(value);
        debugPrint('✅ control.setEditingState() completed');
      }
      debugPrint('📝 ========== TextInput._setEditingState() END ==========\n');
    } catch (e) {
      debugPrint('❌ ERROR in _setEditingState(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '📝 ========== TextInput._setEditingState() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  void _show() {
    debugPrint('\n⌨️ ========== TextInput._show() ==========');
    debugPrint('📊 Number of controls: ${_textInputControls.length}');

    try {
      for (final control in _textInputControls) {
        debugPrint('📞 Calling control.show() for ${control.runtimeType}');
        debugPrint('   - Control: $control');
        control.show();
        debugPrint('✅ control.show() completed for ${control.runtimeType}');
      }
      debugPrint('✅ All controls shown successfully');
      debugPrint('⌨️ ========== TextInput._show() END ==========\n');
    } catch (e) {
      debugPrint('❌ ERROR in _show(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '⌨️ ========== TextInput._show() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  void _hide() {
    debugPrint('\n⌨️ ========== TextInput._hide() ==========');
    debugPrint('📊 Number of controls: ${_textInputControls.length}');

    try {
      for (final control in _textInputControls) {
        debugPrint('📞 Calling control.hide() for ${control.runtimeType}');
        debugPrint('   - Control: $control');
        control.hide();
        debugPrint('✅ control.hide() completed for ${control.runtimeType}');
      }
      debugPrint('✅ All controls hidden successfully');
      debugPrint('⌨️ ========== TextInput._hide() END ==========\n');
    } catch (e) {
      debugPrint('❌ ERROR in _hide(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '⌨️ ========== TextInput._hide() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  // ✅ FIX #2: ADD DEBUG LOGGING TO METHOD CALL HANDLER
  Future<dynamic> _loudlyHandleTextInputMethodCall(MethodCall call) async {
    debugPrint('\n📞 ========== PLATFORM METHOD CALL RECEIVED ==========');
    debugPrint('📞 Method: ${call.method}');
    debugPrint('📞 Arguments: ${call.arguments}');

    try {
      await _handleTextInputMethodCall(call);
      debugPrint('✅ Method call handled successfully');
    } catch (e) {
      debugPrint('❌ ERROR handling method call: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
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
    debugPrint('📞 ========== PLATFORM METHOD CALL END ==========\n');
  }

  Future<dynamic> _handleTextInputMethodCall(MethodCall call) async {
    debugPrint('\n🎯 ========== _handleTextInputMethodCall() ==========');
    debugPrint('📞 Method: ${call.method}');

    if (call.method == "TextInputClient.updateEditingState") {
      debugPrint('📝 Handling: TextInputClient.updateEditingState');

      final int id = call.arguments["id"];
      final String text = call.arguments["text"];
      final int selectionBase = call.arguments["selectionBase"];
      final int selectionExtent = call.arguments["selectionExtent"];
      final TextAffinity selectionAffinity =
          TextAffinity.values[call.arguments["selectionAffinity"]];
      final bool selectionIsDirectional =
          call.arguments["selectionIsDirectional"];

      debugPrint('📊 Parsed arguments:');
      debugPrint('   - id: $id');
      debugPrint('   - text: "$text"');
      debugPrint('   - selectionBase: $selectionBase');
      debugPrint('   - selectionExtent: $selectionExtent');

      final TextEditingValue value = TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: selectionBase,
          extentOffset: selectionExtent,
          affinity: selectionAffinity,
          isDirectional: selectionIsDirectional,
        ),
      );

      debugPrint('✅ TextEditingValue created: $value');
      debugPrint('📊 Looking up client with ID: $id');
      debugPrint('📊 Available clients: ${_textInputClients.keys.toList()}');

      final client = _textInputClients[id];
      if (client != null) {
        debugPrint('✅ Client found: ${client.runtimeType}');
        debugPrint('📞 Calling client.updateEditingValue()...');
        client.updateEditingValue(value);
        debugPrint('✅ client.updateEditingValue() completed');
      } else {
        debugPrint('❌ ERROR: Client not found for ID: $id');
        debugPrint('❌ Available IDs: ${_textInputClients.keys.toList()}');
      }
    } else if (call.method == "TextInputClient.performAction") {
      debugPrint('🎬 Handling: TextInputClient.performAction');

      final int id = call.arguments["id"];
      final TextInputAction action =
          TextInputAction.values[call.arguments["action"]];

      debugPrint('📊 Action: $action for client ID: $id');

      final client = _textInputClients[id];
      if (client != null) {
        debugPrint('✅ Client found: ${client.runtimeType}');
        debugPrint('📞 Calling client.performAction()...');
        client.performAction(action);
        debugPrint('✅ client.performAction() completed');
      } else {
        debugPrint('❌ ERROR: Client not found for ID: $id');
      }
    } else if (call.method == "TextInputClient.closeConnection") {
      debugPrint('🔌 Handling: TextInputClient.closeConnection');

      final int id = call.arguments["id"];
      debugPrint('📊 Closing connection for client ID: $id');

      final client = _textInputClients[id];
      if (client != null) {
        debugPrint('✅ Client found: ${client.runtimeType}');
        debugPrint('📞 Calling client.closeConnection()...');
        client.closeConnection();
        debugPrint('✅ client.closeConnection() completed');
      } else {
        debugPrint('❌ ERROR: Client not found for ID: $id');
      }
    } else if (call.method == "TextInputClient.insertContent") {
      debugPrint('📎 Handling: TextInputClient.insertContent');

      final int id = call.arguments["id"];
      final String mimeType = call.arguments["mimeType"];
      final Uint8List data = call.arguments["data"];

      debugPrint('📊 Inserting content for client ID: $id');
      debugPrint('   - mimeType: $mimeType');
      debugPrint('   - data length: ${data.length}');

      final client = _textInputClients[id];
      if (client != null) {
        debugPrint('✅ Client found: ${client.runtimeType}');
        debugPrint('📞 Calling client.insertContent()...');
        client.insertContent(
          KeyboardInsertedContent(mimeType: mimeType, data: data, uri: ""),
        );
        debugPrint('✅ client.insertContent() completed');
      } else {
        debugPrint('❌ ERROR: Client not found for ID: $id');
      }
    } else {
      debugPrint('⚠️ Unknown method: ${call.method}');
      debugPrint('🎯 ========== _handleTextInputMethodCall() END ==========\n');
      throw MissingPluginException();
    }
    debugPrint('🎯 ========== _handleTextInputMethodCall() END ==========\n');
  }
}

class TextInputConnection {
  TextInputConnection._(this.client) : id = _nextID++ {
    debugPrint('\n🔗 ========== TextInputConnection CREATED ==========');
    debugPrint('📊 ID: $id');
    debugPrint('📊 Client type: ${client.runtimeType}');

    _textInputClients[id] = client;
    debugPrint('✅ Client registered in _textInputClients map');
    debugPrint('📊 Total clients: ${_textInputClients.length}');
    debugPrint('🔗 ========== TextInputConnection CREATED END ==========\n');
  }

  TextInputClient client;
  int id;

  static int _nextID = 1;
  bool _closed = false;

  bool get attached {
    final isAttached = TextInput._instance._currentConnection == this;
    debugPrint('🔍 TextInputConnection.attached getter: $isAttached');
    return isAttached;
  }

  void close() {
    debugPrint('\n🔌 ========== TextInputConnection.close() ==========');
    debugPrint('📊 ID: $id');
    debugPrint('📊 Already closed: $_closed');

    if (_closed) {
      debugPrint('⚠️ Already closed - returning');
      debugPrint('🔌 ========== TextInputConnection.close() END ==========\n');
      return;
    }

    _closed = true;
    debugPrint('✅ Marked as closed');

    _textInputClients.remove(id);
    debugPrint('✅ Removed from _textInputClients map');
    debugPrint('📊 Remaining clients: ${_textInputClients.length}');

    debugPrint('📞 Calling client.closeConnection()...');
    client.closeConnection();
    debugPrint('✅ client.closeConnection() completed');
    debugPrint('🔌 ========== TextInputConnection.close() END ==========\n');
  }

  void show() {
    debugPrint('\n⌨️ ========== TextInputConnection.show() ==========');
    debugPrint('📊 ID: $id');
    debugPrint('📊 Attached: $attached');
    debugPrint('📊 _closed: $_closed');

    if (_closed) {
      debugPrint('⚠️ Connection is closed - cannot show');
      debugPrint('⌨️ ========== TextInputConnection.show() END ==========\n');
      return;
    }

    assert(attached, "Cannot show a TextInputConnection that is not attached.");
    try {
      debugPrint('📞 Calling TextInput._instance._show()...');
      TextInput._instance._show();
      debugPrint('✅ TextInput._instance._show() completed');
      debugPrint('⌨️ ========== TextInputConnection.show() END ==========\n');
    } catch (e) {
      debugPrint('❌ ERROR in show(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '⌨️ ========== TextInputConnection.show() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  void hide() {
    debugPrint('\n⌨️ ========== TextInputConnection.hide() ==========');
    debugPrint('📊 ID: $id');
    debugPrint('📊 Attached: $attached');

    assert(attached, "Cannot hide a TextInputConnection that is not attached.");
    TextInput._instance._hide();
    debugPrint('⌨️ ========== TextInputConnection.hide() END ==========\n');
  }

  void setEditingState(TextEditingValue value) {
    debugPrint(
      '\n📝 ========== TextInputConnection.setEditingState() ==========',
    );
    debugPrint('📊 ID: $id');
    debugPrint('📊 Value: $value');
    debugPrint('📊 Attached: $attached');
    debugPrint('📊 _closed: $_closed');

    if (_closed) {
      debugPrint('⚠️ Connection is closed - cannot set editing state');
      debugPrint(
        '📝 ========== TextInputConnection.setEditingState() END ==========\n',
      );
      return;
    }

    assert(
      attached,
      "Cannot set editing state on a TextInputConnection that is not attached.",
    );

    try {
      debugPrint('📞 Calling TextInput._instance._setEditingState()...');
      TextInput._instance._setEditingState(value);
      debugPrint('✅ TextInput._instance._setEditingState() completed');
      debugPrint(
        '📝 ========== TextInputConnection.setEditingState() END ==========\n',
      );
    } catch (e) {
      debugPrint('❌ ERROR in setEditingState(): $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '📝 ========== TextInputConnection.setEditingState() END (WITH ERROR) ==========\n',
      );
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
    debugPrint('\n🔌 ========== _PlatformTextInputControl.attach() ==========');
    debugPrint('📊 Client type: ${client.runtimeType}');
    debugPrint('📊 Client ID: ${TextInput.instance._currentConnection?.id}');
    debugPrint('📊 Configuration: $configuration');
    debugPrint('📊 MethodChannel: $_channel');

    if (_channel == null) {
      debugPrint('❌ ERROR: MethodChannel is null!');
      debugPrint(
        '🔌 ========== _PlatformTextInputControl.attach() END (WITH ERROR) ==========\n',
      );
      return;
    }

    try {
      debugPrint('📞 Invoking method: TextInput.attach');
      debugPrint('   - With ID: ${TextInput.instance._currentConnection?.id}');
      debugPrint('   - With configuration: ${configuration.toJson()}');
      _channel!.invokeMethod("TextInput.attach", {
        "id": TextInput.instance._currentConnection?.id,
        "configuration": configuration.toJson(),
      });
      debugPrint('✅ Method invoked successfully');
      debugPrint(
        '🔌 ========== _PlatformTextInputControl.attach() END ==========\n',
      );
    } catch (e) {
      debugPrint('❌ ERROR invoking TextInput.attach: $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '🔌 ========== _PlatformTextInputControl.attach() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  @override
  void detach() {
    debugPrint('\n🔌 ========== _PlatformTextInputControl.detach() ==========');
    debugPrint('📞 Invoking method: TextInput.detach');
    _channel?.invokeMethod("TextInput.detach");
    debugPrint('✅ Method invoked');
    debugPrint(
      '🔌 ========== _PlatformTextInputControl.detach() END ==========\n',
    );
  }

  @override
  void updateConfig(TextInputConfiguration config) {
    debugPrint(
      '\n⚙️ ========== _PlatformTextInputControl.updateConfig() ==========',
    );
    debugPrint('📊 Configuration: $config');
    debugPrint('📞 Invoking method: TextInput.updateConfig');
    _channel?.invokeMethod("TextInput.updateConfig", {
      "configuration": config.toJson(),
    });
    debugPrint('✅ Method invoked');
    debugPrint(
      '⚙️ ========== _PlatformTextInputControl.updateConfig() END ==========\n',
    );
  }

  @override
  void handleSizeAndTransform(Size size, Matrix4 transform) {
    debugPrint(
      '\n📐 ========== _PlatformTextInputControl.handleSizeAndTransform() ==========',
    );
    debugPrint('📊 Size: $size');
    debugPrint('📞 Invoking method: TextInput.handleSizeAndTransform');
    _channel?.invokeMethod("TextInput.handleSizeAndTransform", {
      "width": size.width,
      "height": size.height,
      "transform": transform.storage,
    });
    debugPrint('✅ Method invoked');
    debugPrint(
      '📐 ========== _PlatformTextInputControl.handleSizeAndTransform() END ==========\n',
    );
  }

  @override
  void hide() {
    debugPrint('\n⌨️ ========== _PlatformTextInputControl.hide() ==========');
    debugPrint('📞 Invoking method: TextInput.hide');
    _channel?.invokeMethod("TextInput.hide");
    debugPrint('✅ Method invoked');
    debugPrint(
      '⌨️ ========== _PlatformTextInputControl.hide() END ==========\n',
    );
  }

  @override
  void show() {
    debugPrint('\n⌨️ ========== _PlatformTextInputControl.show() ==========');
    debugPrint('📊 MethodChannel: $_channel');

    if (_channel == null) {
      debugPrint('❌ ERROR: MethodChannel is null!');
      debugPrint(
        '⌨️ ========== _PlatformTextInputControl.show() END (WITH ERROR) ==========\n',
      );
      return;
    }

    try {
      debugPrint('📞 Invoking method: TextInput.show');
      _channel!.invokeMethod("TextInput.show");
      debugPrint('✅ Method invoked successfully');
      debugPrint(
        '⌨️ ========== _PlatformTextInputControl.show() END ==========\n',
      );
    } catch (e) {
      debugPrint('❌ ERROR invoking TextInput.show: $e');
      debugPrint('   - Stack trace: ${StackTrace.current}');
      debugPrint(
        '⌨️ ========== _PlatformTextInputControl.show() END (WITH ERROR) ==========\n',
      );
      rethrow;
    }
  }

  @override
  void setEditingState(TextEditingValue value) {
    debugPrint(
      '\n📝 ========== _PlatformTextInputControl.setEditingState() ==========',
    );
    debugPrint('📊 Value: $value');
    debugPrint('📞 Invoking method: TextInput.setEditingState');
    _channel?.invokeMethod("TextInput.setEditingState", {
      "text": value.text,
      "selectionBase": value.selection.baseOffset,
      "selectionExtent": value.selection.extentOffset,
      "selectionAffinity": value.selection.affinity.index,
      "selectionIsDirectional": value.selection.isDirectional,
    });
    debugPrint('✅ Method invoked');
    debugPrint(
      '📝 ========== _PlatformTextInputControl.setEditingState() END ==========\n',
    );
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
