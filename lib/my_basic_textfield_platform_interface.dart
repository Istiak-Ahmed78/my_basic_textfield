import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'my_basic_textfield_method_channel.dart';

abstract class MyBasicTextfieldPlatform extends PlatformInterface {
  /// Constructs a MyBasicTextfieldPlatform.
  MyBasicTextfieldPlatform() : super(token: _token);

  static final Object _token = Object();

  static MyBasicTextfieldPlatform _instance = MethodChannelMyBasicTextfield();

  /// The default instance of [MyBasicTextfieldPlatform] to use.
  ///
  /// Defaults to [MethodChannelMyBasicTextfield].
  static MyBasicTextfieldPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MyBasicTextfieldPlatform] when
  /// they register themselves.
  static set instance(MyBasicTextfieldPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
