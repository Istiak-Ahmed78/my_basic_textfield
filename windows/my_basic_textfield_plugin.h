#ifndef FLUTTER_PLUGIN_MY_BASIC_TEXTFIELD_PLUGIN_H_
#define FLUTTER_PLUGIN_MY_BASIC_TEXTFIELD_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace my_basic_textfield {

class MyBasicTextfieldPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MyBasicTextfieldPlugin();

  virtual ~MyBasicTextfieldPlugin();

  // Disallow copy and assign.
  MyBasicTextfieldPlugin(const MyBasicTextfieldPlugin&) = delete;
  MyBasicTextfieldPlugin& operator=(const MyBasicTextfieldPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace my_basic_textfield

#endif  // FLUTTER_PLUGIN_MY_BASIC_TEXTFIELD_PLUGIN_H_
