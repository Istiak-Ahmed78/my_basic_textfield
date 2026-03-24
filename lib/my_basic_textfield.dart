
import 'my_basic_textfield_platform_interface.dart';

class MyBasicTextfield {
  Future<String?> getPlatformVersion() {
    return MyBasicTextfieldPlatform.instance.getPlatformVersion();
  }
}
