#include "include/my_basic_textfield/my_basic_textfield_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "my_basic_textfield_plugin.h"

void MyBasicTextfieldPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  my_basic_textfield::MyBasicTextfieldPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
