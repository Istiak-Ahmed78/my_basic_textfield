package com.example.my_basic_textfield.editing;

import static io.flutter.Build.API_LEVELS;

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

/**
 * Main plugin for handling text input on Android.
 * 
 * This class is the core of the text input system. It:
 * 1. Receives configuration from Flutter via MethodChannel
 * 2. Manages the IME (Input Method Editor - keyboard)
 * 3. Creates InputConnection for IME communication
 * 4. Tracks text state changes
 * 5. Sends updates back to Flutter
 * 
 * Architecture:
 * ```
 * Flutter (Dart)
 *     ↓
 * TextInputChannel (MethodChannel)
 *     ↓
 * TextInputPlugin (this class)
 *     ↓
 * ListenableEditingState (text storage)
 *     ↓
 * InputConnectionAdaptor (IME connection)
 *     ↓
 * Android IME (Keyboard)
 * ```
 * 
 * Key responsibilities:
 * - Show/hide keyboard
 * - Set text input client (which text field is focused)
 * - Create InputConnection for IME
 * - Convert between Flutter and Android input types
 * - Track text state changes
 * - Send updates to Flutter
 * 
 * Example flow:
 * 1. Flutter: "Show keyboard for text input"
 * 2. TextInputPlugin: Creates InputConnection, shows keyboard
 * 3. User types "H"
 * 4. IME: Calls InputConnectionAdaptor.commitText("H", 1)
 * 5. InputConnectionAdaptor: Updates ListenableEditingState
 * 6. ListenableEditingState: Notifies TextInputPlugin
 * 7. TextInputPlugin: Sends to Flutter: "text='H', cursor=1"
 * 8. Flutter: Updates EditableText widget
 */
public class TextInputPlugin implements ListenableEditingState.EditingStateWatcher {
  private static final String TAG = "TextInputPlugin";

  /**
   * The view that owns this plugin
   * Used to get context and manage keyboard visibility
   */
  @NonNull
  private final View mView;

  /**
   * Input Method Manager from Android
   * Used to show/hide keyboard
   */
  @NonNull
  private final InputMethodManager mImm;

  /**
   * Scribe channel for additional text input events
   */
  @NonNull
  private final ScribeChannel scribeChannel;

  /**
   * Text input channel to communicate with Flutter
   * Used to receive configuration and send updates
   */
  @NonNull
  private final TextInputChannel textInputChannel;

  /**
   * Current input target (which widget is focused)
   * Initially NO_TARGET (no widget focused)
   */
  @NonNull
  private InputTarget inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);

  /**
   * Current input configuration from Flutter
   * Contains keyboard type, input action, etc.
   */
  @Nullable
  private InputConfiguration configuration;

  /**
   * The editable text state
   * Stores text, selection, and composing region
   */
  @NonNull
  private ListenableEditingState mEditable;

  /**
   * Whether we need to restart input
   * Set to true when composing region changes
   * We restart input to notify IME of changes
   */
  private boolean mRestartInputPending;

  /**
   * The last InputConnection we created
   * Used to send key events and get input state
   */
  @Nullable
  private InputConnection lastInputConnection;

  /**
   * Platform views controller
   * Used for platform view text input
   */
  @NonNull
  private PlatformViewsController platformViewsController;

  /**
   * Platform views controller 2
   * Used for platform view text input (newer API)
   */
  @NonNull
  private PlatformViewsController2 platformViewsController2;

  /**
   * The last known text editing state from Flutter
   * Used to detect when composing region changes
   */
  @Nullable
  private TextEditState mLastKnownFrameworkTextEditingState;

  /**
   * Whether input connection is locked
   * Used to prevent concurrent access to input connection
   */
  private boolean isInputConnectionLocked;

  /**
   * The last client rect (size and position of text field)
   * Used for IME positioning
   */
  @Nullable
  private Rect lastClientRect;

  /**
   * Creates a new TextInputPlugin
   * 
   * This is called when the plugin is initialized.
   * We set up the MethodChannel handler and register listeners.
   *
   * @param view                      The view that owns this plugin
   * @param textInputChannel          The text input channel from Flutter
   * @param scribeChannel             The scribe channel
   * @param platformViewsController   The platform views controller
   * @param platformViewsController2  The platform views controller 2
   */
  @SuppressLint("NewApi")
  public TextInputPlugin(
      @NonNull View view,
      @NonNull TextInputChannel textInputChannel,
      @NonNull ScribeChannel scribeChannel,
      @NonNull PlatformViewsController platformViewsController,
      @NonNull PlatformViewsController2 platformViewsController2) {
    
    mView = view;
    // Initialize editable state with empty text
    mEditable = new ListenableEditingState(null, mView);
    
    // Get InputMethodManager from Android
    mImm = (InputMethodManager) view.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);

    this.textInputChannel = textInputChannel;
    
    // Set up the MethodChannel handler
    // This receives messages from Flutter
    textInputChannel.setTextInputMethodHandler(
        new TextInputChannel.TextInputMethodHandler() {
          @Override
          public void show() {
            // Flutter: "Show the keyboard"
            showTextInput(mView);
          }

          @Override
          public void hide() {
            // Flutter: "Hide the keyboard"
            hideTextInput(mView);
          }

          @Override
          public void requestAutofill() {
            // Not implemented for basic version
          }

          @Override
          public void finishAutofillContext(boolean shouldSave) {
            // Not implemented for basic version
          }

          @Override
          public void setClient(
              int textInputClientId, TextInputChannel.Configuration configuration) {
            // Flutter: "Focus text field with this configuration"
            setTextInputClient(textInputClientId, configuration);
          }

          @Override
          public void setPlatformViewClient(int platformViewId, boolean usesVirtualDisplay) {
            // Flutter: "Focus platform view"
            setPlatformViewTextInputClient(platformViewId, usesVirtualDisplay);
          }

          @Override
          public void setEditingState(TextInputChannel.TextEditState editingState) {
            // Flutter: "Update text state"
            setTextInputEditingState(mView, editingState);
          }

          @Override
          public void setEditableSizeAndTransform(double width, double height, double[] transform) {
            // Flutter: "Text field size/position changed"
            saveEditableSizeAndTransform(width, height, transform);
          }

          @Override
          public void clearClient() {
            // Flutter: "Unfocus text field"
            clearTextInputClient();
          }

          @Override
          public void sendAppPrivateCommand(String action, android.os.Bundle data) {
            // Flutter: "Send private command to IME"
            sendTextInputAppPrivateCommand(action, data);
          }
        });

    // Request existing input state from Flutter
    textInputChannel.requestExistingInputState();

    this.scribeChannel = scribeChannel;
    this.platformViewsController = platformViewsController;
    this.platformViewsController.attachTextInputPlugin(this);
    this.platformViewsController2 = platformViewsController2;
    this.platformViewsController2.attachTextInputPlugin(this);

    android.util.Log.d(TAG, "TextInputPlugin created");
  }

  /**
   * Gets the InputMethodManager
   *
   * @return The InputMethodManager
   */
  @NonNull
  public InputMethodManager getInputMethodManager() {
    return mImm;
  }

  /**
   * Gets the editable text
   * Used for testing
   *
   * @return The editable text
   */
  @VisibleForTesting
  Editable getEditable() {
    return mEditable;
  }

  /**
   * Locks the platform view input connection
   * Prevents concurrent access to input connection
   */
  public void lockPlatformViewInputConnection() {
    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      isInputConnectionLocked = true;
    }
  }

  /**
   * Unlocks the platform view input connection
   * Allows access to input connection
   */
  public void unlockPlatformViewInputConnection() {
    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      isInputConnectionLocked = false;
    }
  }

  /**
   * Destroys the plugin
   * Called when the plugin is being destroyed
   */
  @SuppressLint("NewApi")
  public void destroy() {
    android.util.Log.d(TAG, "TextInputPlugin destroyed");
    platformViewsController.detachTextInputPlugin();
    platformViewsController2.detachTextInputPlugin();
    textInputChannel.setTextInputMethodHandler(null);
    mEditable.removeEditingStateListener(this);
  }

  /**
   * Converts Flutter input type to Android InputType
   * 
   * Flutter has different input types (text, number, email, etc.)
   * Android also has different input types (TYPE_CLASS_TEXT, TYPE_CLASS_NUMBER, etc.)
   * This method converts between them.
   * 
   * Example:
   * - Flutter: TextInputType.EMAIL_ADDRESS
   * - Android: InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS
   *
   * @param type                          The Flutter input type
   * @param obscureText                   Whether text should be obscured (password)
   * @param autocorrect                   Whether autocorrect is enabled
   * @param enableSuggestions             Whether suggestions are enabled
   * @param enableIMEPersonalizedLearning Whether IME can learn
   * @param textCapitalization            How to capitalize text
   * @return The Android InputType
   */
  private static int inputTypeFromTextInputType(
      TextInputChannel.InputType type,
      boolean obscureText,
      boolean autocorrect,
      boolean enableSuggestions,
      boolean enableIMEPersonalizedLearning,
      TextInputChannel.TextCapitalization textCapitalization) {
    
    android.util.Log.d(TAG, "inputTypeFromTextInputType: type=" + type.type + 
        ", obscureText=" + obscureText);

    // Handle special input types first
    if (type.type == TextInputChannel.TextInputType.DATETIME) {
      return InputType.TYPE_CLASS_DATETIME;
    } else if (type.type == TextInputChannel.TextInputType.NUMBER) {
      int textType = InputType.TYPE_CLASS_NUMBER;
      if (type.isSigned) {
        textType |= InputType.TYPE_NUMBER_FLAG_SIGNED;
      }
      if (type.isDecimal) {
        textType |= InputType.TYPE_NUMBER_FLAG_DECIMAL;
      }
      return textType;
    } else if (type.type == TextInputChannel.TextInputType.PHONE) {
      return InputType.TYPE_CLASS_PHONE;
    } else if (type.type == TextInputChannel.TextInputType.NONE) {
      return InputType.TYPE_NULL;
    }

    // Handle text-based input types
    int textType = InputType.TYPE_CLASS_TEXT;
    
    if (type.type == TextInputChannel.TextInputType.MULTILINE) {
      textType |= InputType.TYPE_TEXT_FLAG_MULTI_LINE;
    } else if (type.type == TextInputChannel.TextInputType.EMAIL_ADDRESS
        || type.type == TextInputChannel.TextInputType.TWITTER) {
      textType |= InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
    } else if (type.type == TextInputChannel.TextInputType.URL
        || type.type == TextInputChannel.TextInputType.WEB_SEARCH) {
      textType |= InputType.TYPE_TEXT_VARIATION_URI;
    } else if (type.type == TextInputChannel.TextInputType.VISIBLE_PASSWORD) {
      textType |= InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD;
    } else if (type.type == TextInputChannel.TextInputType.NAME) {
      textType |= InputType.TYPE_TEXT_VARIATION_PERSON_NAME;
    } else if (type.type == TextInputChannel.TextInputType.POSTAL_ADDRESS) {
      textType |= InputType.TYPE_TEXT_VARIATION_POSTAL_ADDRESS;
    }

    // Handle password field (obscure text)
    if (obscureText) {
      textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
      textType |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
    } else {
      // Handle autocorrect and suggestions
      if (autocorrect) {
        textType |= InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;
      }
      if (!enableSuggestions) {
        textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
        textType |= InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD;
      }
    }

    // Handle text capitalization
    if (textCapitalization == TextInputChannel.TextCapitalization.CHARACTERS) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS;
    } else if (textCapitalization == TextInputChannel.TextCapitalization.WORDS) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_WORDS;
    } else if (textCapitalization == TextInputChannel.TextCapitalization.SENTENCES) {
      textType |= InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
    }

    return textType;
  }

  /**
   * Creates an InputConnection for the IME
   * 
   * This is called by Android when the IME needs to communicate with the text field.
   * We return an InputConnectionAdaptor that handles IME calls.
   * 
   * The InputConnection is the bridge between:
   * - Android IME (keyboard)
   * - Our text field
   * 
   * When user types, the IME calls methods on InputConnection like:
   * - commitText("H", 1)
   * - deleteSurroundingText(1, 0)
   * - setSelection(5, 5)
   * etc.
   *
   * @param view     The view requesting the connection
   * @param outAttrs Output attributes for the IME
   * @return The InputConnection, or null if no text field is focused
   */
  @Nullable
  public InputConnection createInputConnection(
      @NonNull View view, @NonNull EditorInfo outAttrs) {
    
    android.util.Log.d(TAG, "createInputConnection: inputTarget=" + inputTarget);

    // If no target is focused, return null
    if (inputTarget.type == InputTarget.Type.NO_TARGET) {
      lastInputConnection = null;
      return null;
    }

    // If target is a physical display platform view, return null
    if (inputTarget.type == InputTarget.Type.PHYSICAL_DISPLAY_PLATFORM_VIEW) {
      return null;
    }

    // If target is a virtual display platform view, delegate to platform view
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

    // Set up EditorInfo for the IME
    // This tells the IME what kind of input we expect
    outAttrs.inputType =
        inputTypeFromTextInputType(
            configuration.inputType,
            configuration.obscureText,
            configuration.autocorrect,
            configuration.enableSuggestions,
            configuration.enableIMEPersonalizedLearning,
            configuration.textCapitalization);
    
    // Don't use fullscreen IME
    outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN;

    // Disable personalized learning if requested (Android 8.0+)
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_26
        && !configuration.enableIMEPersonalizedLearning) {
      outAttrs.imeOptions |= EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING;
    }

    // Set up the action button (Done, Send, Next, etc.)
    int enterAction;
    if (configuration.inputAction == null) {
      // Default: Done for single line, None for multiline
      enterAction =
          (InputType.TYPE_TEXT_FLAG_MULTI_LINE & outAttrs.inputType) != 0
              ? EditorInfo.IME_ACTION_NONE
              : EditorInfo.IME_ACTION_DONE;
    } else {
      enterAction = configuration.inputAction;
    }
    
    // Set custom action label if provided
    if (configuration.actionLabel != null) {
      outAttrs.actionLabel = configuration.actionLabel;
      outAttrs.actionId = enterAction;
    }
    outAttrs.imeOptions |= enterAction;

    // Create InputConnectionAdaptor
    InputConnectionAdaptor connection =
        new InputConnectionAdaptor(
            view,
            inputTarget.id,
            textInputChannel,
            scribeChannel,
            mEditable,
            outAttrs);
    
    // Set initial selection in EditorInfo
    outAttrs.initialSelStart = mEditable.getSelectionStart();
    outAttrs.initialSelEnd = mEditable.getSelectionEnd();

    lastInputConnection = connection;
    
    android.util.Log.d(TAG, "createInputConnection: created connection for client " + inputTarget.id);

    return lastInputConnection;
  }

  /**
   * Gets the last InputConnection we created
   *
   * @return The last InputConnection, or null
   */
  @Nullable
  public InputConnection getLastInputConnection() {
    return lastInputConnection;
  }

  /**
   * Clears the text input client for a platform view
   * Called when a platform view loses focus
   *
   * @param platformViewId The platform view ID
   */
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

  /**
   * Sends a private command to the IME
   *
   * @param action The action
   * @param data   The data
   */
  public void sendTextInputAppPrivateCommand(@NonNull String action, @NonNull android.os.Bundle data) {
    mImm.sendAppPrivateCommand(mView, action, data);
  }

  /**
   * Shows the text input (keyboard)
   * 
   * This is called when Flutter requests to show the keyboard.
   * We check if the input type is NONE (hidden keyboard).
   * If not NONE, we show the keyboard.
   *
   * @param view The view
   */
  @VisibleForTesting
  void showTextInput(View view) {
    android.util.Log.d(TAG, "showTextInput");

    if (configuration == null
        || configuration.inputType == null
        || configuration.inputType.type != TextInputChannel.TextInputType.NONE) {
      // Request focus and show keyboard
      view.requestFocus();
      mImm.showSoftInput(view, 0);
    } else {
      // Input type is NONE, hide keyboard
      hideTextInput(view);
    }
  }

  /**
   * Hides the text input (keyboard)
   * 
   * This is called when Flutter requests to hide the keyboard.
   * We hide the keyboard using InputMethodManager.
   *
   * @param view The view
   */
  private void hideTextInput(View view) {
    android.util.Log.d(TAG, "hideTextInput");
    mImm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
  }

  /**
   * Sets the text input client
   * 
   * This is called when Flutter focuses a text field.
   * We:
   * 1. Store the configuration
   * 2. Set the input target
   * 3. Create a new editable state
   * 4. Mark input as needing restart
   * 
   * The input restart will cause Android to call createInputConnection()
   * which will create a new InputConnectionAdaptor.
   *
   * @param client        The client ID from Flutter
   * @param configuration The input configuration
   */
  @VisibleForTesting
  void setTextInputClient(int client, TextInputChannel.Configuration configuration) {
    android.util.Log.d(TAG, "setTextInputClient: client=" + client + 
        ", config=" + configuration);

    // Store configuration
    this.configuration = configuration;
    
    // Set input target to this client
    inputTarget = new InputTarget(InputTarget.Type.FRAMEWORK_CLIENT, client);

    // Remove listener from old editable state
    mEditable.removeEditingStateListener(this);
    
    // Create new editable state
    mEditable = new ListenableEditingState(null, mView);

    // Mark input as needing restart
    // This will cause Android to call createInputConnection()
    mRestartInputPending = true;
    
    // Unlock platform view input connection
    unlockPlatformViewInputConnection();
    
    // Clear client rect
    lastClientRect = null;
    
    // Add listener to new editable state
    mEditable.addEditingStateListener(this);

    android.util.Log.d(TAG, "setTextInputClient: client set, input restart pending");
  }

  /**
   * Sets the platform view text input client
   * Called when a platform view gains focus
   *
   * @param platformViewId     The platform view ID
   * @param usesVirtualDisplay Whether the platform view uses virtual display
   */
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

  /**
   * Checks if composing region changed
   * 
   * This is used to detect when the composing region changes.
   * If it changes, we need to restart input to notify the IME.
   *
   * @param before The previous text edit state
   * @param after  The current text edit state
   * @return true if composing region changed
   */
  private static boolean composingChanged(
      TextInputChannel.TextEditState before, TextInputChannel.TextEditState after) {
    
    // Get composing region lengths
    final int composingRegionLength = before.composingEnd - before.composingStart;
    
    // If lengths differ, composing changed
    if (composingRegionLength != after.composingEnd - after.composingStart) {
      return true;
    }
    
    // If lengths are same, check if text in composing region changed
    for (int index = 0; index < composingRegionLength; index++) {
      if (before.text.charAt(index + before.composingStart)
          != after.text.charAt(index + after.composingStart)) {
        return true;
      }
    }
    
    return false;
  }

  /**
   * Sets the text input editing state
   * 
   * This is called when Flutter sends the complete text state to native.
   * We:
   * 1. Check if composing region changed
   * 2. Update the editable state
   * 3. Restart input if needed
   *
   * @param view  The view
   * @param state The text edit state from Flutter
   */
  @VisibleForTesting
  void setTextInputEditingState(View view, TextInputChannel.TextEditState state) {
    android.util.Log.d(TAG, "setTextInputEditingState: text='" + state.text + 
        "', selection=" + state.selectionStart + "-" + state.selectionEnd +
        ", composing=" + state.composingStart + "-" + state.composingEnd);

    // Check if composing region changed
    if (!mRestartInputPending
        && mLastKnownFrameworkTextEditingState != null
        && mLastKnownFrameworkTextEditingState.hasComposing()) {
      mRestartInputPending = composingChanged(mLastKnownFrameworkTextEditingState, state);
      if (mRestartInputPending) {
        android.util.Log.i(TAG, "Composing region changed by the framework. Restarting the input method.");
      }
    }

    // Store the state
    mLastKnownFrameworkTextEditingState = state;
    
    // Update editable state
    mEditable.setEditingState(state);

    // Restart input if needed
    if (mRestartInputPending) {
      mImm.restartInput(view);
      mRestartInputPending = false;
    }
  }

  /**
   * Saves the editable size and transform
   * Used for IME positioning
   *
   * @param width     The width of the text field
   * @param height    The height of the text field
   * @param matrix    The transformation matrix
   */
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

  /**
   * Interface for finding min/max coordinates
   */
  private interface MinMax {
    void inspect(double x, double y);
  }

  /**
   * Clears the text input client
   * Called when Flutter unfocuses the text field
   */
  @VisibleForTesting
  void clearTextInputClient() {
    android.util.Log.d(TAG, "clearTextInputClient");

    // Don't clear if platform view is focused
    if (inputTarget.type == InputTarget.Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      return;
    }
    
    // Remove listener
    mEditable.removeEditingStateListener(this);
    
    // Clear configuration
    configuration = null;
    
    // Clear input target
    inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
    
    // Unlock platform view input connection
    unlockPlatformViewInputConnection();
    
    // Clear client rect
    lastClientRect = null;
  }

  /**
   * Handles a key event
   * 
   * This is called when a key event is received.
   * We delegate to the last input connection.
   *
   * @param keyEvent The key event
   * @return true if handled
   */
  public boolean handleKeyEvent(@NonNull KeyEvent keyEvent) {
    if (!getInputMethodManager().isAcceptingText() || lastInputConnection == null) {
      return false;
    }

    return (lastInputConnection instanceof InputConnectionAdaptor)
        ? ((InputConnectionAdaptor) lastInputConnection).handleKeyEvent(keyEvent)
        : lastInputConnection.sendKeyEvent(keyEvent);
  }

  /**
   * Called when editing state changes
   * 
   * This is called by ListenableEditingState when text, selection, or composing changes.
   * We send the updated state to Flutter.
   *
   * @param textChanged           true if text content changed
   * @param selectionChanged      true if cursor/selection changed
   * @param composingRegionChanged true if composing region changed
   */
  @Override
  public void didChangeEditingState(
      boolean textChanged, boolean selectionChanged, boolean composingRegionChanged) {
    
    android.util.Log.d(TAG, "didChangeEditingState: textChanged=" + textChanged + 
        ", selectionChanged=" + selectionChanged + 
        ", composingRegionChanged=" + composingRegionChanged);

    // Get current state
    final int selectionStart = mEditable.getSelectionStart();
    final int selectionEnd = mEditable.getSelectionEnd();
    final int composingStart = mEditable.getComposingStart();
    final int composingEnd = mEditable.getComposingEnd();

    // Extract batch deltas
    final ArrayList<TextEditingDelta> batchTextEditingDeltas =
        mEditable.extractBatchTextEditingDeltas();
    
    // Check if we should skip updating Flutter
    // Skip if nothing actually changed
    final boolean skipFrameworkUpdate =
        mLastKnownFrameworkTextEditingState == null
            || (mEditable.toString().equals(mLastKnownFrameworkTextEditingState.text)
                && selectionStart == mLastKnownFrameworkTextEditingState.selectionStart
                && selectionEnd == mLastKnownFrameworkTextEditingState.selectionEnd
                && composingStart == mLastKnownFrameworkTextEditingState.composingStart
                && composingEnd == mLastKnownFrameworkTextEditingState.composingEnd);
    
    if (!skipFrameworkUpdate) {
      // Send update to Flutter
      android.util.Log.v(TAG, "send EditingState to flutter: " + mEditable.toString());

      textInputChannel.updateEditingState(
          inputTarget.id,
          mEditable.toString(),
          selectionStart,
          selectionEnd,
          composingStart,
          composingEnd);
      
      // Store the state we sent
      mLastKnownFrameworkTextEditingState =
          new TextEditState(
              mEditable.toString(), selectionStart, selectionEnd, composingStart, composingEnd);
    } else {
      // Nothing changed, clear deltas
      mEditable.clearBatchDeltas();
    }
  }

  /**
   * Gets debug information
   *
   * @return Debug string
   */
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
