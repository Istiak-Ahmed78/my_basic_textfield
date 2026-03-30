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

/**
 * Main plugin class for basic text field input.
 * 
 * This is the entry point for the Flutter plugin. It:
 * 1. Connects to Flutter via MethodChannel
 * 2. Initializes the text input system
 * 3. Manages the plugin lifecycle
 * 4. Provides InputConnection for text fields
 * 
 * Architecture:
 * ```
 * Flutter App (Dart)
 *     ↓
 * MethodChannel ("com.example.my_basic_textfield/text_input")
 *     ↓
 * MyBasicTextfieldPlugin (this class)
 *     ↓
 * TextInputPlugin
 *     ↓
 * ListenableEditingState + InputConnectionAdaptor
 *     ↓
 * Android IME (Keyboard)
 * ```
 * 
 * Lifecycle:
 * 1. onAttachedToEngine() - Plugin is attached to Flutter engine
 * 2. onAttachedToActivity() - Activity is available
 * 3. Plugin is ready to use
 * 4. onDetachedFromActivity() - Activity is detached
 * 5. onDetachedFromEngine() - Plugin is detached from engine
 * 
 * Key responsibilities:
 * - Create TextInputPlugin instance
 * - Set up MethodChannel for communication with Flutter
 * - Manage plugin lifecycle
 * - Provide InputConnection for text input
 * 
 * Example usage in Flutter:
 * ```dart
 * // In your Flutter app, use EditableText widget
 * // The text input is handled automatically by this plugin
 * 
 * EditableText(
 *   controller: controller,
 *   focusNode: focusNode,
 *   style: TextStyle(),
 *   cursorColor: Colors.blue,
 *   backgroundCursorColor: Colors.grey,
 *   onChanged: (value) {},
 * )
 * ```
 */
public class MyBasicTextfieldPlugin implements FlutterPlugin, ActivityAware {
  private static final String TAG = "MyBasicTextfieldPlugin";

  /**
   * The MethodChannel for communication with Flutter
   * 
   * This channel is used to send messages from native to Flutter
   * and receive messages from Flutter to native.
   * 
   * Channel name: "com.example.my_basic_textfield/text_input"
   */
  @Nullable
  private MethodChannel channel;

  /**
   * The TextInputPlugin instance
   * 
   * This is the core text input handler that manages:
   * - Text state
   * - Keyboard visibility
   * - IME communication
   * - Updates to Flutter
   */
  @Nullable
  private TextInputPlugin textInputPlugin;

  /**
   * The current activity
   * 
   * Used to get context and manage keyboard visibility
   */
  @Nullable
  private Activity activity;

  /**
   * The Flutter engine
   * 
   * Used to access system channels and other engine features
   */
  @Nullable
  private FlutterEngine flutterEngine;

  /**
   * The binding to the activity
   * 
   * Used to manage activity lifecycle
   */
  @Nullable
  private ActivityPluginBinding activityBinding;

  /**
   * Called when the plugin is attached to the Flutter engine
   * 
   * This is the first lifecycle method called.
   * We set up the MethodChannel here.
   * 
   * @param binding The plugin binding
   */
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    android.util.Log.d(TAG, "onAttachedToEngine");

    // Store the Flutter engine
    flutterEngine = binding.getFlutterEngine();

    // Create the MethodChannel
    // This is used for communication with Flutter
    channel =
        new MethodChannel(
            binding.getBinaryMessenger(),
            "com.example.my_basic_textfield/text_input");

    // Set up the method call handler
    channel.setMethodCallHandler(
        (call, result) -> {
          // Handle method calls from Flutter
          switch (call.method) {
            case "getPlatformVersion":
              // Return Android version
              result.success("Android " + android.os.Build.VERSION.RELEASE);
              break;
            case "getTextInputState":
              // Return current text input state
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

  /**
   * Called when the plugin is attached to an activity
   * 
   * This is called after onAttachedToEngine().
   * We initialize the TextInputPlugin here.
   * 
   * @param binding The activity plugin binding
   */
  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    android.util.Log.d(TAG, "onAttachedToActivity");

    // Store the activity and binding
    activity = binding.getActivity();
    activityBinding = binding;

    // Initialize TextInputPlugin
    initializeTextInputPlugin();

    android.util.Log.d(TAG, "TextInputPlugin initialized");
  }

  /**
   * Called when the activity is recreated
   * 
   * This can happen when the device is rotated or other configuration changes occur.
   * We reinitialize the TextInputPlugin.
   * 
   * @param binding The activity plugin binding
   */
  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    android.util.Log.d(TAG, "onReattachedToActivityForConfigChanges");

    // Update the activity and binding
    activity = binding.getActivity();
    activityBinding = binding;

    // Reinitialize TextInputPlugin
    initializeTextInputPlugin();

    android.util.Log.d(TAG, "TextInputPlugin reinitialized after config change");
  }

  /**
   * Called when the activity is detached
   * 
   * This happens when the activity is destroyed or paused.
   * We clean up the TextInputPlugin.
   */
  @Override
  public void onDetachedFromActivityForConfigChanges() {
    android.util.Log.d(TAG, "onDetachedFromActivityForConfigChanges");

    // Clean up
    cleanupTextInputPlugin();

    activity = null;
    activityBinding = null;

    android.util.Log.d(TAG, "TextInputPlugin cleaned up after config change");
  }

  /**
   * Called when the plugin is detached from the activity
   * 
   * This is called when the activity is destroyed.
   * We clean up resources here.
   */
  @Override
  public void onDetachedFromActivity() {
    android.util.Log.d(TAG, "onDetachedFromActivity");

    // Clean up
    cleanupTextInputPlugin();

    activity = null;
    activityBinding = null;

    android.util.Log.d(TAG, "TextInputPlugin cleaned up");
  }

  /**
   * Called when the plugin is detached from the Flutter engine
   * 
   * This is the last lifecycle method called.
   * We clean up the MethodChannel here.
   */
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    android.util.Log.d(TAG, "onDetachedFromEngine");

    // Clean up the MethodChannel
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }

    // Clean up the Flutter engine
    flutterEngine = null;

    android.util.Log.d(TAG, "MethodChannel destroyed");
  }

  /**
   * Initializes the TextInputPlugin
   * 
   * This creates the TextInputPlugin instance and sets it up.
   * The TextInputPlugin is the core of the text input system.
   */
  private void initializeTextInputPlugin() {
    // Check if we have the required dependencies
    if (activity == null || flutterEngine == null) {
      android.util.Log.e(TAG, "Cannot initialize TextInputPlugin: activity or engine is null");
      return;
    }

    // Get the root view of the activity
    View rootView = activity.getWindow().getDecorView().getRootView();

    // Get the text input channel from the engine
    TextInputChannel textInputChannel = flutterEngine.getSystemChannel(TextInputChannel.class);

    // Get the scribe channel from the engine
    ScribeChannel scribeChannel = flutterEngine.getSystemChannel(ScribeChannel.class);

    // Get platform views controllers
    // These are used for platform view text input
    PlatformViewsController platformViewsController =
        flutterEngine.getPlatformViewsController();
    PlatformViewsController2 platformViewsController2 =
        flutterEngine.getPlatformViewsController2();

    // Create TextInputPlugin
    textInputPlugin =
        new TextInputPlugin(
            rootView,
            textInputChannel,
            scribeChannel,
            platformViewsController,
            platformViewsController2);

    android.util.Log.d(TAG, "TextInputPlugin created and initialized");
  }

  /**
   * Cleans up the TextInputPlugin
   * 
   * This destroys the TextInputPlugin and releases resources.
   */
  private void cleanupTextInputPlugin() {
    if (textInputPlugin != null) {
      textInputPlugin.destroy();
      textInputPlugin = null;
      android.util.Log.d(TAG, "TextInputPlugin destroyed");
    }
  }

  /**
   * Gets the TextInputPlugin instance
   * 
   * This is used for testing and debugging.
   * 
   * @return The TextInputPlugin, or null if not initialized
   */
  @Nullable
  public TextInputPlugin getTextInputPlugin() {
    return textInputPlugin;
  }

  /**
   * Gets the MethodChannel
   * 
   * This is used for testing and debugging.
   * 
   * @return The MethodChannel, or null if not initialized
   */
  @Nullable
  public MethodChannel getMethodChannel() {
    return channel;
  }

  /**
   * Gets the current activity
   * 
   * This is used for testing and debugging.
   * 
   * @return The Activity, or null if not attached
   */
  @Nullable
  public Activity getActivity() {
    return activity;
  }

  /**
   * Gets debug information about the plugin
   * 
   * @return Debug string
   */
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
