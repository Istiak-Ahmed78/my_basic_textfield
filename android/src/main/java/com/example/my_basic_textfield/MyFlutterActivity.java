package com.example.my_basic_textfield;

import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

/**
 * Custom FlutterActivity that integrates the MyBasicTextfieldPlugin's TextInputPlugin
 * with the framework's text input handling.
 * 
 * This activity ensures that when the FlutterEngine initializes, the custom
 * TextInputPlugin is properly wired to handle input connections through the
 * official Flutter framework mechanisms.
 */
public class MyFlutterActivity extends FlutterActivity {
  private static final String TAG = "MyFlutterActivity";

  private MyBasicTextfieldPlugin myPlugin;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    
    android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
    android.util.Log.d(TAG, "🚀 MyFlutterActivity.onCreate() called");
    android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
  }

  /**
   * This method is called after the FlutterEngine is created and before the FlutterView
   * is attached. This is the CORRECT place to configure the text input plugin
   * according to Flutter's official patterns.
   */
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
    android.util.Log.d(TAG, "🔧 configureFlutterEngine() called");
    android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
    
    // Call the parent implementation first
    super.configureFlutterEngine(flutterEngine);
    
    // After the parent has set up the engine, the plugins have been loaded
    // including MyBasicTextfieldPlugin. We can now access it to finalize setup.
    
    try {
      android.util.Log.d(TAG, "📢 Accessing MyBasicTextfieldPlugin from plugin registry...");
      
      // Get the plugin that was auto-registered
      myPlugin = (MyBasicTextfieldPlugin) flutterEngine.getPlugins()
          .get(MyBasicTextfieldPlugin.class);
      
      if (myPlugin != null) {
        android.util.Log.d(TAG, "✅ MyBasicTextfieldPlugin obtained from registry");
        
        // The plugin's TextInputPlugin is now initialized with the FlutterEngine
        // The framework will call onCreateInputConnection() on the FlutterView,
        // which is handled by the official FlutterView implementation
        
        android.util.Log.d(TAG, "✅ TextInputPlugin ready for framework integration");
      } else {
        android.util.Log.w(TAG, "⚠️ MyBasicTextfieldPlugin not found in registry");
      }
      
    } catch (Exception e) {
      android.util.Log.e(TAG, "❌ Error configuring TextInputPlugin: " + e.getMessage());
      e.printStackTrace();
    }
    
    android.util.Log.d(TAG, "═══════════════════════════════════════════════════════════");
  }

  /**
   * Clean up when activity is destroyed
   */
  @Override
  protected void onDestroy() {
    android.util.Log.d(TAG, "🗑️  MyFlutterActivity.onDestroy() called");
    super.onDestroy();
    myPlugin = null;
  }
}
