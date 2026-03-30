
import 'package:flutter/services.dart';

class TextSelection extends TextRange {
  final int baseOffset;
  final int extentOffset;

  final TextAffinity affinity;

  final bool isDirectional;
  TextSelection({
    required this.baseOffset,
    required this.extentOffset,
    this.affinity = TextAffinity.downstream,
    this.isDirectional = false,
  }) : super(start: baseOffset, end: extentOffset);

  TextSelection.collapsed({
    required int offset,
    this.affinity = TextAffinity.downstream,
  }) : baseOffset = offset,
       extentOffset = offset,
       isDirectional = false,
       super(start: offset, end: offset);

  TextSelection.fromPosition(TextPosition position)
    : baseOffset = position.offset,
      extentOffset = position.offset,
      affinity = position.affinity,
      isDirectional = false,
      super(start: position.offset, end: position.offset);
  TextSelection copyWith({
    int? baseOffset,
    int? extentOffset,
    TextAffinity? affinity,
    bool? isDirectional,
  }) {
    return TextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      affinity: affinity ?? this.affinity,
      isDirectional: isDirectional ?? this.isDirectional,
    );
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TextSelection &&
        other.baseOffset == baseOffset &&
        other.extentOffset == extentOffset &&
        other.affinity == affinity &&
        other.isDirectional == isDirectional;
  }

  TextPosition get base {
    final TextAffinity textAffinity;
    if (!isValid || baseOffset == extentOffset) {
      textAffinity = affinity;
    } else if (baseOffset < extentOffset) {
      textAffinity = TextAffinity.downstream;
    } else {
      textAffinity = TextAffinity.upstream;
    }
    return TextPosition(offset: baseOffset, affinity: textAffinity);
  }

  TextPosition get extent {
    final TextAffinity textAffinity;
    if (!isValid || baseOffset == extentOffset) {
      textAffinity = affinity;
    } else if (baseOffset < extentOffset) {
      textAffinity = TextAffinity.upstream;
    } else {
      textAffinity = TextAffinity.downstream;
    }
    return TextPosition(offset: extentOffset, affinity: textAffinity);
  }
}
