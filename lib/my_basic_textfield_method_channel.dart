import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'my_basic_textfield_platform_interface.dart';

/// An implementation of [MyBasicTextfieldPlatform] that uses method channels.
class MethodChannelMyBasicTextfield extends MyBasicTextfieldPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('my_basic_textfield');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
