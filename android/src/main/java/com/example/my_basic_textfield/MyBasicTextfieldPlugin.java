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

    android.util.Log.d(TAG, "🔧 Initializing TextInputPlugin...");

    View rootView = activity.getWindow().getDecorView().getRootView();
    android.util.Log.d(TAG, "✅ Root view obtained: " + rootView.getClass().getSimpleName());

    // ✅ FIXED: Access channels via reflection or use the engine's dart executor
    // Try to get TextInputChannel from the engine
    TextInputChannel textInputChannel = null;
    ScribeChannel scribeChannel = null;

    try {
      // Method 1: Try using getDartExecutor() to get the channels
      // This is the more reliable way in newer Flutter versions
      Object dartExecutor = flutterEngine.getDartExecutor();
      android.util.Log.d(TAG, "✅ DartExecutor obtained: " + dartExecutor.getClass().getSimpleName());

      // Create new channels if they don't exist
      textInputChannel = new TextInputChannel(flutterEngine.getDartExecutor());
      scribeChannel = new ScribeChannel(flutterEngine.getDartExecutor());

      android.util.Log.d(TAG, "✅ Channels created successfully");
    } catch (Exception e) {
      android.util.Log.e(TAG, "❌ Error creating channels: " + e.getMessage());
      e.printStackTrace();

      // Fallback: Create with null - Flutter will initialize them
      android.util.Log.d(TAG, "⚠️ Using fallback: channels will be initialized by Flutter");
    }

    PlatformViewsController platformViewsController =
        flutterEngine.getPlatformViewsController();
    android.util.Log.d(TAG, "✅ PlatformViewsController obtained");

    PlatformViewsController2 platformViewsController2 =
        flutterEngine.getPlatformViewsController2();
    android.util.Log.d(TAG, "✅ PlatformViewsController2 obtained");

    // Create the TextInputPlugin
    textInputPlugin =
        new TextInputPlugin(
            rootView,
            textInputChannel,
            scribeChannel,
            platformViewsController,
            platformViewsController2);

    android.util.Log.d(TAG, "✅ TextInputPlugin created and initialized successfully!");
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