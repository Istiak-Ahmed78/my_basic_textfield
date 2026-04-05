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
      android.util.Log.e(TAG, "Cannot initialize TextInputPlugin: activity or engine is null");
      return;
    }

    View rootView = activity.getWindow().getDecorView().getRootView();

    // ✅ FIXED: Pass null for channels - they'll be initialized by Flutter
    TextInputChannel textInputChannel = null;
    ScribeChannel scribeChannel = null;

    PlatformViewsController platformViewsController =
        flutterEngine.getPlatformViewsController();
    PlatformViewsController2 platformViewsController2 =
        flutterEngine.getPlatformViewsController2();

    textInputPlugin =
        new TextInputPlugin(
            rootView,
            textInputChannel,
            scribeChannel,
            platformViewsController,
            platformViewsController2);

    android.util.Log.d(TAG, "TextInputPlugin created and initialized");
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