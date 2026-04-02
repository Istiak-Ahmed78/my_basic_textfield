package com.example.my_basic_textfield.editing;

import static io.flutter.Build.API_LEVELS;
import java.util.ArrayList;
import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Rect;
import android.os.Build;
import android.text.Editable;
import android.text.InputType;
import android.util.SparseArray;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.systemchannels.ScribeChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel.TextEditState;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.plugin.platform.PlatformViewsController2;
import com.example.my_basic_textfield.editing.models.InputTarget;
import com.example.my_basic_textfield.editing.models.InputConfiguration;

public class TextInputPlugin implements ListenableEditingState.EditingStateWatcher {
  private static final String TAG = "TextInputPlugin";

  @NonNull
  private final View mView;

  @NonNull
  private final InputMethodManager mImm;

  @NonNull
  private final ScribeChannel scribeChannel;

  @NonNull
  private final TextInputChannel textInputChannel;

  @NonNull
  private InputTarget inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);

  @Nullable
  private InputConfiguration configuration;  // ✅ FIXED: Use custom InputConfiguration

  @NonNull
  private ListenableEditingState mEditable;

  private boolean mRestartInputPending;

  @Nullable
  private InputConnection lastInputConnection;

  @NonNull
  private PlatformViewsController platformViewsController;

  @NonNull
  private PlatformViewsController2 platformViewsController2;

  @Nullable
  private TextEditState mLastKnownFrameworkTextEditingState;

  private boolean isInputConnectionLocked;

  @Nullable
  private Rect lastClientRect;

  @SuppressLint("NewApi")
  public TextInputPlugin(
      @NonNull View view,
      @NonNull TextInputChannel textInputChannel,
      @NonNull ScribeChannel scribeChannel,
      @NonNull PlatformViewsController platformViewsController,
      @NonNull PlatformViewsController2 platformViewsController2) {
    
    mView = view;
    mEditable = new ListenableEditingState(null, mView);
    
    mImm = (InputMethodManager) view.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);

    this.textInputChannel = textInputChannel;
    
    textInputChannel.setTextInputMethodHandler(
        new TextInputChannel.TextInputMethodHandler() {
          @Override
          public void show() {
            android.util.Log.d(TAG, "🔊 TextInputMethodHandler.show() called");
            showTextInput(mView);
          }

          @Override
          public void hide() {
            android.util.Log.d(TAG, "🔊 TextInputMethodHandler.hide() called");
            hideTextInput(mView);
          }

          @Override
          public void requestAutofill() {
          }

          @Override
          public void finishAutofillContext(boolean shouldSave) {
          }

          @Override
          public void setClient(
              int textInputClientId, TextInputChannel.Configuration flutterConfig) {
            android.util.Log.d(TAG, "🔊 TextInputMethodHandler.setClient() called with clientId=" + textInputClientId);
            
            // ✅ CONVERT Flutter's Configuration to our InputConfiguration
            InputConfiguration config = convertFlutterConfiguration(flutterConfig);
            setTextInputClient(textInputClientId, config);
          }

          @Override
          public void setPlatformViewClient(int platformViewId, boolean usesVirtualDisplay) {
            setPlatformViewTextInputClient(platformViewId, usesVirtualDisplay);
          }

          @Override
          public void setEditingState(TextInputChannel.TextEditState editingState) {
            android.util.Log.d(TAG, "🔊 TextInputMethodHandler.setEditingState() called");
            setTextInputEditingState(mView, editingState);
          }

          @Override
          public void setEditableSizeAndTransform(double width, double height, double[] transform) {
            saveEditableSizeAndTransform(width, height, transform);
          }

          @Override
          public void clearClient() {
            android.util.Log.d(TAG, "🔊 TextInputMethodHandler.clearClient() called");
            clearTextInputClient();
          }

          @Override
          public void sendAppPrivateCommand(String action, android.os.Bundle data) {
            sendTextInputAppPrivateCommand(action, data);
          }
        });

    textInputChannel.requestExistingInputState();

    this.scribeChannel = scribeChannel;
    this.platformViewsController = platformViewsController;
    android.util.Log.d(TAG, "Platform views controllers initialized");
    this.platformViewsController2 = platformViewsController2;

    android.util.Log.d(TAG, "TextInputPlugin created");
  }

  // ✅ NEW METHOD: Convert Flutter's Configuration to our InputConfiguration
  @NonNull
  private InputConfiguration convertFlutterConfiguration(
      @NonNull TextInputChannel.Configuration flutterConfig) {
    
    android.util.Log.d(TAG, "convertFlutterConfiguration: " + flutterConfig);

    InputConfiguration.InputType inputType = InputConfiguration.InputType.TEXT;
    
    if (flutterConfig.inputType != null) {
      String type = flutterConfig.inputType.type.name().toLowerCase();
      android.util.Log.d(TAG, "convertFlutterConfiguration: Flutter inputType=" + type);
      
      try {
        inputType = InputConfiguration.InputType.valueOf(type.toUpperCase());
      } catch (IllegalArgumentException e) {
        android.util.Log.w(TAG, "Unknown input type: " + type + ", using TEXT");
        inputType = InputConfiguration.InputType.TEXT;
      }
    }

    InputConfiguration.TextCapitalization textCap = InputConfiguration.TextCapitalization.NONE;
    if (flutterConfig.textCapitalization != null) {
      try {
        textCap = InputConfiguration.TextCapitalization.valueOf(
            flutterConfig.textCapitalization.name().toUpperCase());
      } catch (IllegalArgumentException e) {
        android.util.Log.w(TAG, "Unknown text capitalization");
      }
    }

    InputConfiguration config = new InputConfiguration(
        inputType,
        flutterConfig.inputAction,
        flutterConfig.obscureText,
        flutterConfig.autocorrect,
        flutterConfig.enableSuggestions,
        flutterConfig.enableIMEPersonalizedLearning,
        textCap,
        flutterConfig.actionLabel
    );

    android.util.Log.d(TAG, "convertFlutterConfiguration result: " + config);
    return config;
  }

  @NonNull
  public InputMethodManager getInputMethodManager() {
    return mImm;
  }

  @VisibleForTesting
  Editable getEditable() {
    return mEditable;
  }

  public void lockPlatformViewInputConnection() {
    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      isInputConnectionLocked = true;
    }
  }

  public void unlockPlatformViewInputConnection() {
    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      isInputConnectionLocked = false;
    }
  }

  @SuppressLint("NewApi")
  public void destroy() {
    android.util.Log.d(TAG, "TextInputPlugin destroyed");
    platformViewsController.detachTextInputPlugin();
    platformViewsController2.detachTextInputPlugin();
    textInputChannel.setTextInputMethodHandler(null);
    mEditable.removeEditingStateListener(this);
  }

  private static int inputTypeFromTextInputType(
      @NonNull String type,
      boolean obscureText,
      boolean autocorrect,
      boolean enableSuggestions,
      boolean enableIMEPersonalizedLearning,
      @Nullable String textCapitalization) {
    
    android.util.Log.d(TAG, "inputTypeFromTextInputType: type=" + type + 
        ", obscureText=" + obscureText);

    switch (type) {
      case "datetime":
        return InputType.TYPE_CLASS_DATETIME;
      case "number":
        int textType = InputType.TYPE_CLASS_NUMBER;
        return textType;
      case "phone":
        return InputType.TYPE_CLASS_PHONE;
      case "none":
        return InputType.TYPE_NULL;
      default:
        break;
    }

    int textType = InputType.TYPE_CLASS_TEXT;
    
    if (type.equals("multiline")) {
      textType |= InputType.TYPE_TEXT_FLAG_MULTI_LINE;
    } else if (type.equals("email_address")) {
      textType |= InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
    } else if (type.equals("url")) {
      textType |= InputType.TYPE_TEXT_VARIATION_URI;
    } else if (type.equals("visible_password")) {
      textType |= InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD;
    } else if (type.equals("name")) {
      textType |= InputType.TYPE_TEXT_VARIATION_PERSON_NAME;
    } else if (type.equals("postal_address")) {
      textType |= InputType.TYPE_TEXT_VARIATION_POSTAL_ADDRESS;
    }

    if (obscureText) {
      textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
      textType |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
    } else {
      if (autocorrect) {
        textType |= InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;
      }
      if (!enableSuggestions) {
        textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
        textType |= InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD;
      }
    }

    if ("characters".equals(textCapitalization)) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS;
    } else if ("words".equals(textCapitalization)) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_WORDS;
    } else if ("sentences".equals(textCapitalization)) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
    }

    return textType;
  }

  @Nullable
  public InputConnection createInputConnection(
      @NonNull View view, @NonNull EditorInfo outAttrs) {
    
    android.util.Log.d(TAG, "createInputConnection: inputTarget=" + inputTarget);

    if (inputTarget.type == InputTarget.Type.NO_TARGET) {
      lastInputConnection = null;
      android.util.Log.w(TAG, "createInputConnection: NO_TARGET, returning null");
      return null;
    }

    if (inputTarget.type == InputTarget.Type.PHYSICAL_DISPLAY_PLATFORM_VIEW) {
      android.util.Log.d(TAG, "createInputConnection: PHYSICAL_DISPLAY_PLATFORM_VIEW");
      return null;
    }

    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      if (isInputConnectionLocked) {
        return lastInputConnection;
      }
      lastInputConnection =
          platformViewsController
              .getPlatformViewById(inputTarget.id)
              .onCreateInputConnection(outAttrs);
      return lastInputConnection;
    }

    if (configuration == null) {
      android.util.Log.e(TAG, "createInputConnection: configuration is null!");
      return null;
    }

    // ✅ FIXED: Use configuration.inputType.name() directly
    String inputType = configuration.inputType != null 
        ? configuration.inputType.name().toLowerCase() 
        : "text";
    
    android.util.Log.d(TAG, "createInputConnection: inputType=" + inputType);

    outAttrs.inputType =
        inputTypeFromTextInputType(
            inputType,
            configuration.obscureText,
            configuration.autocorrect,
            configuration.enableSuggestions,
            configuration.enableIMEPersonalizedLearning,
            configuration.textCapitalization.name().toLowerCase());
    
    outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN;

    if (Build.VERSION.SDK_INT >= API_LEVELS.API_26
        && !configuration.enableIMEPersonalizedLearning) {
      outAttrs.imeOptions |= EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING;
    }

    int enterAction;
    if (configuration.inputAction == null) {
      enterAction =
          (InputType.TYPE_TEXT_FLAG_MULTI_LINE & outAttrs.inputType) != 0
              ? EditorInfo.IME_ACTION_NONE
              : EditorInfo.IME_ACTION_DONE;
    } else {
      enterAction = configuration.inputAction;
    }
    
    if (configuration.actionLabel != null) {
      outAttrs.actionLabel = configuration.actionLabel;
      outAttrs.actionId = enterAction;
    }
    outAttrs.imeOptions |= enterAction;

    InputConnectionAdaptor connection =
        new InputConnectionAdaptor(
            view,
            inputTarget.id,
            textInputChannel,
            scribeChannel,
            mEditable,
            outAttrs);
    
    outAttrs.initialSelStart = mEditable.getSelectionStart();
    outAttrs.initialSelEnd = mEditable.getSelectionEnd();

    lastInputConnection = connection;
    
    android.util.Log.d(TAG, "createInputConnection: created connection for client " + inputTarget.id);

    return lastInputConnection;
  }

  @Nullable
  public InputConnection getLastInputConnection() {
    return lastInputConnection;
  }

  public void clearPlatformViewClient(int platformViewId) {
    if ((inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW
            || inputTarget.type == InputTarget.Type.PHYSICAL_DISPLAY_PLATFORM_VIEW)
        && inputTarget.id == platformViewId) {
      inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
      mImm.hideSoftInputFromWindow(mView.getApplicationWindowToken(), 0);
      mImm.restartInput(mView);
      mRestartInputPending = false;
    }
  }

  public void sendTextInputAppPrivateCommand(@NonNull String action, @NonNull android.os.Bundle data) {
    mImm.sendAppPrivateCommand(mView, action, data);
  }

  @VisibleForTesting
  void showTextInput(View view) {
    android.util.Log.d(TAG, "showTextInput called");

    // ✅ FIXED: Correct logic - Show keyboard for valid input types
    if (configuration == null
        || configuration.inputType == null) {
      android.util.Log.w(TAG, "showTextInput: configuration is null, cannot show keyboard");
      return;
    }

    // Don't show keyboard for "none" type
    if (configuration.inputType == InputConfiguration.InputType.NONE) {
      android.util.Log.d(TAG, "showTextInput: input type is NONE, skipping");
      return;
    }

    android.util.Log.d(TAG, "showTextInput: requesting focus and showing keyboard");
    view.requestFocus();
    mImm.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT);
  }

  private void hideTextInput(View view) {
    android.util.Log.d(TAG, "hideTextInput");
    mImm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
  }

  @VisibleForTesting
  void setTextInputClient(int client, InputConfiguration configuration) {
    android.util.Log.d(TAG, "setTextInputClient: client=" + client + 
        ", config=" + configuration);

    this.configuration = configuration;
    
    inputTarget = new InputTarget(InputTarget.Type.FRAMEWORK_CLIENT, client);

    mEditable.removeEditingStateListener(this);
    
    mEditable = new ListenableEditingState(null, mView);

    mRestartInputPending = true;
    
    unlockPlatformViewInputConnection();
    
    lastClientRect = null;
    
    mEditable.addEditingStateListener(this);

    // ✅ FIXED: Immediately restart input to initialize keyboard
    android.util.Log.d(TAG, "setTextInputClient: calling restartInput immediately");
    mImm.restartInput(mView);
    mRestartInputPending = false;

    android.util.Log.d(TAG, "setTextInputClient: client set and input restarted");
  }

  private void setPlatformViewTextInputClient(int platformViewId, boolean usesVirtualDisplay) {
    android.util.Log.d(TAG, "setPlatformViewTextInputClient: platformViewId=" + platformViewId + 
        ", usesVirtualDisplay=" + usesVirtualDisplay);

    if (usesVirtualDisplay) {
      mView.requestFocus();
      inputTarget = new InputTarget(InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW, platformViewId);
      mImm.restartInput(mView);
      mRestartInputPending = false;
    } else {
      inputTarget =
          new InputTarget(InputTarget.Type.PHYSICAL_DISPLAY_PLATFORM_VIEW, platformViewId);
      lastInputConnection = null;
    }
  }

  private static boolean composingChanged(
      TextInputChannel.TextEditState before, TextInputChannel.TextEditState after) {
    
    final int composingRegionLength = before.composingEnd - before.composingStart;
    
    if (composingRegionLength != after.composingEnd - after.composingStart) {
      return true;
    }
    
    for (int index = 0; index < composingRegionLength; index++) {
      if (before.text.charAt(index + before.composingStart)
          != after.text.charAt(index + after.composingStart)) {
        return true;
      }
    }
    
    return false;
  }

  @VisibleForTesting
  void setTextInputEditingState(View view, TextInputChannel.TextEditState state) {
    android.util.Log.d(TAG, "setTextInputEditingState: text='" + state.text + 
        "', selection=" + state.selectionStart + "-" + state.selectionEnd +
        ", composing=" + state.composingStart + "-" + state.composingEnd);

    if (!mRestartInputPending
        && mLastKnownFrameworkTextEditingState != null
        && mLastKnownFrameworkTextEditingState.hasComposing()) {
      mRestartInputPending = composingChanged(mLastKnownFrameworkTextEditingState, state);
      if (mRestartInputPending) {
        android.util.Log.i(TAG, "Composing region changed by the framework. Restarting the input method.");
      }
    }

    mLastKnownFrameworkTextEditingState = state;
    
    mEditable.setEditingState(state);

    if (mRestartInputPending) {
      mImm.restartInput(view);
      mRestartInputPending = false;
    }
  }

  private void saveEditableSizeAndTransform(double width, double height, double[] matrix) {
    android.util.Log.d(TAG, "saveEditableSizeAndTransform: width=" + width + ", height=" + height);

    final double[] minMax = new double[4];
    final boolean isAffine = matrix[3] == 0 && matrix[7] == 0 && matrix[15] == 1;
    minMax[0] = minMax[1] = matrix[12] / matrix[15];
    minMax[2] = minMax[3] = matrix[13] / matrix[15];

    final MinMax finder =
        new MinMax() {
          @Override
          public void inspect(double x, double y) {
            final double w = isAffine ? 1 : 1 / (matrix[3] * x + matrix[7] * y + matrix[15]);
            final double tx = (matrix[0] * x + matrix[4] * y + matrix[12]) * w;
            final double ty = (matrix[1] * x + matrix[5] * y + matrix[13]) * w;

            if (tx < minMax[0]) {
              minMax[0] = tx;
            } else if (tx > minMax[1]) {
              minMax[1] = tx;
            }

            if (ty < minMax[2]) {
              minMax[2] = ty;
            } else if (ty > minMax[3]) {
              minMax[3] = ty;
            }
          }
        };

    finder.inspect(width, 0);
    finder.inspect(width, height);
    finder.inspect(0, height);
    
    final Float density = mView.getContext().getResources().getDisplayMetrics().density;
    lastClientRect =
        new Rect(
            (int) (minMax[0] * density),
            (int) (minMax[2] * density),
            (int) Math.ceil(minMax[1] * density),
            (int) Math.ceil(minMax[3] * density));
  }

  private interface MinMax {
    void inspect(double x, double y);
  }

  @VisibleForTesting
  void clearTextInputClient() {
    android.util.Log.d(TAG, "clearTextInputClient");

    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      return;
    }
    
    mEditable.removeEditingStateListener(this);
    
    // FIX: Don't clear configuration - keep it for reuse on second tap
    // When keyboard is hidden and user taps field again, show() is called without setClient()
    // If configuration is null, showTextInput() returns early and keyboard won't appear
    // configuration = null;
    
    inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
    
    unlockPlatformViewInputConnection();
    
    lastClientRect = null;
  }

  public boolean handleKeyEvent(@NonNull KeyEvent keyEvent) {
    if (!getInputMethodManager().isAcceptingText() || lastInputConnection == null) {
      return false;
    }

    return (lastInputConnection instanceof InputConnectionAdaptor)
        ? ((InputConnectionAdaptor) lastInputConnection).handleKeyEvent(keyEvent)
        : lastInputConnection.sendKeyEvent(keyEvent);
  }

  @Override
  public void didChangeEditingState(
      boolean textChanged, boolean selectionChanged, boolean composingRegionChanged) {
    
    android.util.Log.d(TAG, "didChangeEditingState: textChanged=" + textChanged + 
        ", selectionChanged=" + selectionChanged + 
        ", composingRegionChanged=" + composingRegionChanged);

    final int selectionStart = mEditable.getSelectionStart();
    final int selectionEnd = mEditable.getSelectionEnd();
    final int composingStart = mEditable.getComposingStart();
    final int composingEnd = mEditable.getComposingEnd();

    final ArrayList<TextEditingDelta> batchTextEditingDeltas =
        mEditable.extractBatchTextEditingDeltas();
    
    final boolean skipFrameworkUpdate =
        mLastKnownFrameworkTextEditingState == null
            || (mEditable.toString().equals(mLastKnownFrameworkTextEditingState.text)
                && selectionStart == mLastKnownFrameworkTextEditingState.selectionStart
                && selectionEnd == mLastKnownFrameworkTextEditingState.selectionEnd
                && composingStart == mLastKnownFrameworkTextEditingState.composingStart
                && composingEnd == mLastKnownFrameworkTextEditingState.composingEnd);
    
    if (!skipFrameworkUpdate) {
      android.util.Log.v(TAG, "send EditingState to flutter: " + mEditable.toString());

      textInputChannel.updateEditingState(
          inputTarget.id,
          mEditable.toString(),
          selectionStart,
          selectionEnd,
          composingStart,
          composingEnd);
      
      mLastKnownFrameworkTextEditingState =
          new TextEditState(
              mEditable.toString(), selectionStart, selectionEnd, composingStart, composingEnd);
    } else {
      mEditable.clearBatchDeltas();
    }
  }

  @NonNull
  @Override
  public String toString() {
    return "TextInputPlugin{" +
        "inputTarget=" + inputTarget +
        ", configuration=" + configuration +
        ", editable='" + mEditable.toString() + '\'' +
        ", selectionStart=" + mEditable.getSelectionStart() +
        ", selectionEnd=" + mEditable.getSelectionEnd() +
        ", composingStart=" + mEditable.getComposingStart() +
        ", composingEnd=" + mEditable.getComposingEnd() +
        '}';
  }
}