// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'my_basic_textfield_platform_interface.dart';

/// A web implementation of the MyBasicTextfieldPlatform of the MyBasicTextfield plugin.
class MyBasicTextfieldWeb extends MyBasicTextfieldPlatform {
  /// Constructs a MyBasicTextfieldWeb
  MyBasicTextfieldWeb();

  static void registerWith(Registrar registrar) {
    MyBasicTextfieldPlatform.instance = MyBasicTextfieldWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }
}
