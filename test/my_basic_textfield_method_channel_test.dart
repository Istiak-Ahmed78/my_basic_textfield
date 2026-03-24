import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_basic_textfield/my_basic_textfield_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMyBasicTextfield platform = MethodChannelMyBasicTextfield();
  const MethodChannel channel = MethodChannel('my_basic_textfield');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
