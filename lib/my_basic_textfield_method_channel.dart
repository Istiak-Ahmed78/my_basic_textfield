import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'my_basic_textfield_platform_interface.dart';

/// An implementation of [MyBasicTextfieldPlatform] that uses method channels.
class MethodChannelMyBasicTextfield extends MyBasicTextfieldPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'com.example.my_basic_textfield/text_input',
  );

  @override
  Future<String?> getPlatformVersion() async {
    try {
      final version = await methodChannel.invokeMethod<String>(
        'getPlatformVersion',
      );
      return version;
    } on PlatformException catch (e) {
      debugPrint('Failed to get platform version: ${e.message}');
      return null;
    }
  }
}
