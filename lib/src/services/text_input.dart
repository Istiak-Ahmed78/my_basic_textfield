import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show SelectionChangedCause, TextSelection;

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
  dynamic get textEditingValue;
  void hideToolbar([bool hideHandles = true]);
  bool get cutEnabled => true;
  bool get copyEnabled => true;
  bool get pasteEnabled => true;
  bool get selectAllEnabled => true;
  void cutSelection(SelectionChangedCause cause);
  Future<void> pasteText(SelectionChangedCause cause);
  void selectAll(SelectionChangedCause cause);
  void copySelection(SelectionChangedCause cause);
}

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

  @override
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
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.unspecified,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
}

mixin TextInputClient {
  dynamic get currentTextEditingValue;
  void updateEditingValue(dynamic value);
  void performAction(TextInputAction action);
  void closeConnection();
  void insertContent(dynamic content);
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TextEditingValue) return false;
    return text == other.text && selection == other.selection;
  }

  @override
  int get hashCode => Object.hash(text, selection);
}

class KeyboardInsertedContent {
  final String mimeType;
  final Uint8List data;
  final String uri;

  KeyboardInsertedContent({
    required this.mimeType,
    required this.data,
    required this.uri,
  });
}
