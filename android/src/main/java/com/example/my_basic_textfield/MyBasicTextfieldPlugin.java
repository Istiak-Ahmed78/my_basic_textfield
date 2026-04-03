package com.example.my_basic_textfield;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.systemchannels.ScribeChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.plugin.platform.PlatformViewsController2;
import com.example.my_basic_textfield.editing.TextInputPlugin;

public class MyBasicTextfieldPlugin implements FlutterPlugin, ActivityAware {
  private static final String TAG = "MyBasicTextfieldPlugin";

  @Nullable
  private MethodChannel channel;

  @Nullable
  private TextInputPlugin textInputPlugin;

  @Nullable
  private Activity activity;

  @Nullable
  private FlutterEngine flutterEngine;

  @Nullable
  private ActivityPluginBinding activityBinding;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    android.util.Log.d(TAG, "onAttachedToEngine");

    flutterEngine = binding.getFlutterEngine();

    channel =
        new MethodChannel(
            binding.getBinaryMessenger(),
            "com.example.my_basic_textfield/text_input");

    channel.setMethodCallHandler(
        (call, result) -> {
          switch (call.method) {
            case "getPlatformVersion":
              result.success("Android " + android.os.Build.VERSION.RELEASE);
              break;
            case "getTextInputState":
              if (textInputPlugin != null) {
                result.success(textInputPlugin.toString());
              } else {
                result.success("No text input plugin");
              }
              break;
            default:
              result.notImplemented();
          }
        });

    android.util.Log.d(TAG, "MethodChannel created: com.example.my_basic_textfield/text_input");
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    android.util.Log.d(TAG, "onAttachedToActivity");

    activity = binding.getActivity();
    activityBinding = binding;

    initializeTextInputPlugin();

    android.util.Log.d(TAG, "TextInputPlugin initialized");
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    android.util.Log.d(TAG, "onReattachedToActivityForConfigChanges");

    activity = binding.getActivity();
    activityBinding = binding;

    initializeTextInputPlugin();

    android.util.Log.d(TAG, "TextInputPlugin reinitialized after config change");
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    android.util.Log.d(TAG, "onDetachedFromActivityForConfigChanges");

    cleanupTextInputPlugin();

    activity = null;
    activityBinding = null;

    android.util.Log.d(TAG, "TextInputPlugin cleaned up after config change");
  }

  @Override
  public void onDetachedFromActivity() {
    android.util.Log.d(TAG, "onDetachedFromActivity");

    cleanupTextInputPlugin();

    activity = null;
    activityBinding = null;

    android.util.Log.d(TAG, "TextInputPlugin cleaned up");
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    android.util.Log.d(TAG, "onDetachedFromEngine");

    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }

    flutterEngine = null;

    android.util.Log.d(TAG, "MethodChannel destroyed");
  }

   private void initializeTextInputPlugin() {
     if (activity == null || flutterEngine == null) {
       android.util.Log.e(TAG, "❌ Cannot initialize TextInputPlugin: activity or engine is null");
       return;
     }

     android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
     android.util.Log.d(TAG, "🔧 INITIALIZING TEXTINPUTPLUGIN");
     android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");

     View rootView = activity.getWindow().getDecorView().getRootView();
     android.util.Log.d(TAG, "✅ Root view obtained: " + rootView.getClass().getSimpleName());

     // ✅ OFFICIAL PATTERN: Get system channels from the FlutterEngine via public API
     TextInputChannel textInputChannel = flutterEngine.getTextInputChannel();
     ScribeChannel scribeChannel = flutterEngine.getScribeChannel();
     
     if (textInputChannel != null) {
       android.util.Log.d(TAG, "✅ Flutter's TextInputChannel obtained via public API");
     } else {
       android.util.Log.e(TAG, "❌ TextInputChannel is null - engine not properly initialized");
       return;
     }
     
     if (scribeChannel != null) {
       android.util.Log.d(TAG, "✅ Flutter's ScribeChannel obtained via public API");
     } else {
       android.util.Log.e(TAG, "❌ ScribeChannel is null - engine not properly initialized");
       return;
     }

     android.util.Log.d(TAG, "📢 Getting PlatformViewsController...");
     PlatformViewsController platformViewsController =
         flutterEngine.getPlatformViewsController();
     android.util.Log.d(TAG, "✅ PlatformViewsController obtained: " + (platformViewsController != null ? "not null" : "null"));

     android.util.Log.d(TAG, "📢 Getting PlatformViewsController2...");
     PlatformViewsController2 platformViewsController2 =
         flutterEngine.getPlatformViewsController2();
     android.util.Log.d(TAG, "✅ PlatformViewsController2 obtained: " + (platformViewsController2 != null ? "not null" : "null"));

     // Create the TextInputPlugin
     android.util.Log.d(TAG, "📢 Creating TextInputPlugin instance...");
     android.util.Log.d(TAG, "  - rootView: " + rootView.getClass().getSimpleName());
     android.util.Log.d(TAG, "  - textInputChannel: initialized");
     android.util.Log.d(TAG, "  - scribeChannel: initialized");
     
     textInputPlugin =
         new TextInputPlugin(
             rootView,
             textInputChannel,
             scribeChannel,
             platformViewsController,
             platformViewsController2);

     // ✅ OFFICIAL PATTERN: Register TextInputMethodHandler with the channel
     // This wires our TextInputPlugin to receive text input events from the framework
     textInputChannel.setTextInputMethodHandler(
         new io.flutter.embedding.engine.systemchannels.TextInputChannel.TextInputMethodHandler() {
           @Override
           public void show() {
             android.util.Log.d(TAG, "🔊 show() called from framework");
             textInputPlugin.show();
           }

           @Override
           public void hide() {
             android.util.Log.d(TAG, "🔊 hide() called from framework");
             textInputPlugin.hide();
           }

           @Override
           public void requestAutofill() {
             android.util.Log.d(TAG, "🔊 requestAutofill() called from framework");
             textInputPlugin.requestAutofill();
           }

           @Override
           public void setClient(int textInputClientId, 
               io.flutter.embedding.engine.systemchannels.TextInputChannel.Configuration configuration) {
             android.util.Log.d(TAG, "🔊 setClient() called from framework with clientId=" + textInputClientId);
             textInputPlugin.setClient(textInputClientId, configuration);
           }

           @Override
           public void setPlatformViewClient(int id, boolean usesVirtualDisplay) {
             android.util.Log.d(TAG, "🔊 setPlatformViewClient() called from framework");
             textInputPlugin.setPlatformViewClient(id, usesVirtualDisplay);
           }

           @Override
           public void setEditableSizeAndTransform(double width, double height, double[] transform) {
             android.util.Log.d(TAG, "🔊 setEditableSizeAndTransform() called from framework");
             textInputPlugin.setEditableSizeAndTransform(width, height, transform);
           }

           @Override
           public void setEditingState(
               io.flutter.embedding.engine.systemchannels.TextInputChannel.TextEditState editingState) {
             android.util.Log.d(TAG, "🔊 setEditingState() called from framework");
             textInputPlugin.setEditingState(editingState);
           }

           @Override
           public void clearClient() {
             android.util.Log.d(TAG, "🔊 clearClient() called from framework");
             textInputPlugin.clearClient();
           }

           @Override
           public void sendAppPrivateCommand(String action, android.os.Bundle data) {
             android.util.Log.d(TAG, "🔊 sendAppPrivateCommand() called from framework");
             textInputPlugin.sendAppPrivateCommand(action, data);
           }

            @Override
            public void finishAutofillContext(boolean shouldSave) {
              android.util.Log.d(TAG, "🔊 finishAutofillContext() called from framework");
              textInputPlugin.finishAutofillContext(shouldSave);
            }
          });

      // ✅ OFFICIAL PATTERN: Request existing input state after handler registration
      textInputChannel.requestExistingInputState();

      android.util.Log.d(TAG, "✅ TextInputPlugin created and registered successfully!");
      android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
   }

  private void cleanupTextInputPlugin() {
    if (textInputPlugin != null) {
      textInputPlugin.destroy();
      textInputPlugin = null;
      android.util.Log.d(TAG, "TextInputPlugin destroyed");
    }
  }

  @Nullable
  public TextInputPlugin getTextInputPlugin() {
    return textInputPlugin;
  }

  @Nullable
  public MethodChannel getMethodChannel() {
    return channel;
  }

  @Nullable
  public Activity getActivity() {
    return activity;
  }

  @NonNull
  @Override
  public String toString() {
    return "MyBasicTextfieldPlugin{" +
        "channel=" + (channel != null ? "initialized" : "null") +
        ", textInputPlugin=" + (textInputPlugin != null ? "initialized" : "null") +
        ", activity=" + (activity != null ? "attached" : "null") +
        ", flutterEngine=" + (flutterEngine != null ? "attached" : "null") +
        '}';
  }
}