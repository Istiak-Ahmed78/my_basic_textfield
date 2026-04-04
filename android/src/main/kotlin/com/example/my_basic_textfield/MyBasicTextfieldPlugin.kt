package com.example.my_basic_textfield

import io.flutter.embedding.engine.plugins.FlutterPlugin

class MyBasicTextfieldPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // This plugin is now empty - we use Flutter's built-in native text input
        // Our custom Dart widgets connect to it via TextInput.attach()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Cleanup if needed
    }
}
