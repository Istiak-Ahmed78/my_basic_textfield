import 'package:flutter_test/flutter_test.dart';
import 'package:my_basic_textfield/my_basic_textfield.dart';
import 'package:my_basic_textfield/my_basic_textfield_platform_interface.dart';
import 'package:my_basic_textfield/my_basic_textfield_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMyBasicTextfieldPlatform
    with MockPlatformInterfaceMixin
    implements MyBasicTextfieldPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MyBasicTextfieldPlatform initialPlatform = MyBasicTextfieldPlatform.instance;

  test('$MethodChannelMyBasicTextfield is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMyBasicTextfield>());
  });

  test('getPlatformVersion', () async {
    MyBasicTextfield myBasicTextfieldPlugin = MyBasicTextfield();
    MockMyBasicTextfieldPlatform fakePlatform = MockMyBasicTextfieldPlatform();
    MyBasicTextfieldPlatform.instance = fakePlatform;

    expect(await myBasicTextfieldPlugin.getPlatformVersion(), '42');
  });
}
