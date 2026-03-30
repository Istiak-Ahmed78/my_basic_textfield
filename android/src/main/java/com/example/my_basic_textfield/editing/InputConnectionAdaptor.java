package com.example.my_basic_textfield.editing;

import android.os.Build;
import android.text.Editable;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.embedding.engine.systemchannels.ScribeChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;

/**
 * Adaptor between Android IME (Input Method Editor) and Flutter text input.
 * 
 * This class extends BaseInputConnection and acts as a bridge between:
 * - Android's keyboard (IME)
 * - Flutter's text input system
 * 
 * When user types on keyboard:
 * 1. IME calls methods on InputConnectionAdaptor (commitText, deleteSurroundingText, etc.)
 * 2. InputConnectionAdaptor updates the text in ListenableEditingState
 * 3. ListenableEditingState notifies listeners
 * 4. TextInputPlugin sends updates to Flutter
 * 
 * Key responsibilities:
 * - Receive text input from IME
 * - Manage cursor position and selection
 * - Handle composing region (for IME composition)
 * - Send updates back to Flutter
 * 
 * Example flow when user types "H":
 * 1. User presses "H" on keyboard
 * 2. IME calls: commitText("H", 1)
 * 3. We update text and cursor position
 * 4. ListenableEditingState notifies listeners
 * 5. TextInputPlugin sends update to Flutter
 * 6. Flutter receives: text="H", cursor at position 1
 */
public class InputConnectionAdaptor extends BaseInputConnection {
  private static final String TAG = "InputConnectionAdaptor";

  /**
   * The view that owns this input connection
   * Used to get context and other view-related info
   */
  @NonNull
  private final View mView;

  /**
   * The client ID from Flutter
   * Used to identify which text field this connection belongs to
   */
  private final int mClientId;

  /**
   * Channel to communicate with Flutter
   * Used to send text updates back to Flutter
   */
  @NonNull
  private final TextInputChannel textInputChannel;

  /**
   * Scribe channel for additional text input events
   * Used for advanced text input features
   */
  @NonNull
  private final ScribeChannel scribeChannel;

  /**
   * The editable text state
   * This is where we store and modify the text content
   */
  @NonNull
  private final ListenableEditingState mEditable;

  /**
   * Editor info for the input field
   * Contains information about the input field configuration
   */
  @NonNull
  private final EditorInfo outAttrs;

  /**
   * Creates a new InputConnectionAdaptor
   *
   * @param view              The view that owns this connection
   * @param clientId          The client ID from Flutter
   * @param textInputChannel  Channel to communicate with Flutter
   * @param scribeChannel     Scribe channel for text input events
   * @param editable          The editable text state
   * @param outAttrs          Editor info for the input field
   */
  public InputConnectionAdaptor(
      @NonNull View view,
      int clientId,
      @NonNull TextInputChannel textInputChannel,
      @NonNull ScribeChannel scribeChannel,
      @NonNull ListenableEditingState editable,
      @NonNull EditorInfo outAttrs) {
    super(view, true);
    mView = view;
    mClientId = clientId;
    this.textInputChannel = textInputChannel;
    this.scribeChannel = scribeChannel;
    mEditable = editable;
    this.outAttrs = outAttrs;
  }

  /**
   * Gets the editable text
   * 
   * This is called by the IME to get the current text content.
   * The IME uses this to display the text and manage cursor position.
   *
   * @return The editable text
   */
  @Override
  public Editable getEditable() {
    return mEditable;
  }

  /**
   * Commits text to the text field.
   * 
   * This is called by the IME when user types characters.
   * 
   * Flow:
   * 1. Delete any existing composing region
   * 2. Replace text at cursor position with new text
   * 3. Update cursor position
   * 4. Clear composing region
   * 
   * Example:
   * - Current text: "Hello|" (cursor at |)
   * - User types: "World"
   * - Call: commitText("World", 1)
   * - Result: "HelloWorld|"
   * 
   * The newCursorPosition parameter:
   * - Positive: move cursor forward
   * - Negative: move cursor backward
   * - 0: cursor stays at insertion point
   *
   * @param text              The text to commit
   * @param newCursorPosition The new cursor position relative to insertion point
   * @return true if successful
   */
  @Override
  public boolean commitText(CharSequence text, int newCursorPosition) {
    android.util.Log.d(TAG, "commitText: text='" + text + "', newCursorPosition=" + newCursorPosition);

    // If there's a composing region, delete it first
    // (composing region is used by IME for composition like Chinese input)
    if (mEditable.isComposingRangeValid()) {
      mEditable.delete(mEditable.getComposingStart(), mEditable.getComposingEnd());
    }

    // Get current cursor position
    int cursorPos = mEditable.getSelectionStart();

    // Calculate new cursor position
    // newCursorPosition is relative to the end of inserted text
    // Example: if we insert "Hi" and newCursorPosition=1, cursor goes to position+1
    int selectionStart = Math.max(0, cursorPos + newCursorPosition - 1);
    int selectionEnd = Math.max(0, cursorPos + newCursorPosition);

    // Insert the text at cursor position
    mEditable.replace(cursorPos, cursorPos, text);

    // Update selection (cursor position)
    mEditable.setSelection(selectionStart, selectionEnd);

    // Clear composing region since we committed the text
    mEditable.clearComposingRegion();

    android.util.Log.d(TAG, "commitText result: text='" + mEditable.toString() + 
        "', selection=" + selectionStart + "-" + selectionEnd);

    return true;
  }

  /**
   * Deletes text around the cursor.
   * 
   * This is called by the IME for backspace/delete operations.
   * 
   * Flow:
   * 1. Calculate delete range (beforeLength before cursor, afterLength after cursor)
   * 2. Clamp to valid range (0 to text length)
   * 3. Delete the range
   * 4. Update cursor position
   * 
   * Example:
   * - Current text: "Hello|World" (cursor at |)
   * - Call: deleteSurroundingText(2, 3)
   * - Delete: "lo" before and "Wor" after
   * - Result: "He|ld"
   *
   * @param beforeLength Number of characters to delete before cursor
   * @param afterLength  Number of characters to delete after cursor
   * @return true if successful
   */
  @Override
  public boolean deleteSurroundingText(int beforeLength, int afterLength) {
    android.util.Log.d(TAG, "deleteSurroundingText: beforeLength=" + beforeLength + 
        ", afterLength=" + afterLength);

    // Get current cursor position
    int cursorPos = mEditable.getSelectionStart();

    // Calculate delete range
    int deleteStart = Math.max(0, cursorPos - beforeLength);
    int deleteEnd = Math.min(mEditable.length(), cursorPos + afterLength);

    // Delete the range if valid
    if (deleteStart < deleteEnd) {
      mEditable.delete(deleteStart, deleteEnd);
      // Move cursor to start of deleted region
      mEditable.setSelection(deleteStart, deleteStart);
    }

    android.util.Log.d(TAG, "deleteSurroundingText result: text='" + mEditable.toString() + 
        "', cursor=" + deleteStart);

    return true;
  }

  /**
   * Sets the selection (cursor position).
   * 
   * This is called by the IME to change the cursor position or select text.
   * 
   * Flow:
   * 1. Clamp start and end to valid range (0 to text length)
   * 2. Update selection
   * 
   * Example:
   * - Current text: "Hello World" with cursor at 0
   * - Call: setSelection(0, 5)
   * - Result: "Hello" is selected
   * 
   * If start == end, it's a collapsed selection (just cursor):
   * - Call: setSelection(5, 5)
   * - Result: cursor at position 5
   *
   * @param start The start of selection
   * @param end   The end of selection
   * @return true if successful
   */
  @Override
  public boolean setSelection(int start, int end) {
    android.util.Log.d(TAG, "setSelection: start=" + start + ", end=" + end);

    // Clamp to valid range
    int length = mEditable.length();
    int clampedStart = Math.max(0, Math.min(start, length));
    int clampedEnd = Math.max(0, Math.min(end, length));

    // Update selection
    mEditable.setSelection(clampedStart, clampedEnd);

    android.util.Log.d(TAG, "setSelection result: selection=" + clampedStart + "-" + clampedEnd);

    return true;
  }

  /**
   * Sets the composing region.
   * 
   * The composing region is used by IME for text composition.
   * This is important for languages like Chinese, Japanese, Korean where
   * multiple keystrokes combine to form a single character.
   * 
   * Flow:
   * 1. Clamp start and end to valid range
   * 2. Update composing region
   * 
   * Example (Chinese input):
   * - User types: "ni" (拼音 for 你)
   * - IME calls: setComposingRegion(0, 2)
   * - User selects: "你" (you)
   * - IME calls: commitText("你", 1)
   * - Result: "你" is committed
   *
   * @param start The start of composing region
   * @param end   The end of composing region
   * @return true if successful
   */
  @Override
  public boolean setComposingRegion(int start, int end) {
    android.util.Log.d(TAG, "setComposingRegion: start=" + start + ", end=" + end);

    // Clamp to valid range
    int length = mEditable.length();
    int clampedStart = Math.max(0, Math.min(start, length));
    int clampedEnd = Math.max(0, Math.min(end, length));

    // Update composing region
    mEditable.setComposingRegion(clampedStart, clampedEnd);

    android.util.Log.d(TAG, "setComposingRegion result: composing=" + clampedStart + "-" + clampedEnd);

    return true;
  }

  /**
   * Sets composing text.
   * 
   * This is called by the IME when composing text (before final commit).
   * This is used for IME composition in languages like Chinese, Japanese, Korean.
   * 
   * Flow:
   * 1. Delete existing composing region
   * 2. Insert composing text at cursor position
   * 3. Set selection to after inserted text
   * 4. Mark the inserted text as composing region
   * 
   * Example (Chinese input):
   * - User types: "n" (拼音)
   * - IME calls: setComposingText("n", 1)
   * - User sees: "n" displayed (not yet committed)
   * - User types: "i"
   * - IME calls: setComposingText("ni", 1)
   * - User sees: "ni" displayed
   * - User selects: "你" (you)
   * - IME calls: commitText("你", 1)
   * - Result: "你" is committed
   *
   * @param text              The composing text
   * @param newCursorPosition The new cursor position relative to end of text
   * @return true if successful
   */
  @Override
  public boolean setComposingText(CharSequence text, int newCursorPosition) {
    android.util.Log.d(TAG, "setComposingText: text='" + text + "', newCursorPosition=" + newCursorPosition);

    // Delete existing composing region if any
    if (mEditable.isComposingRangeValid()) {
      mEditable.delete(mEditable.getComposingStart(), mEditable.getComposingEnd());
    }

    // Get current cursor position
    int cursorPos = mEditable.getSelectionStart();

    // Insert composing text at cursor position
    mEditable.replace(cursorPos, cursorPos, text);

    // Calculate new cursor position
    int selectionStart = Math.max(0, cursorPos + newCursorPosition - 1);
    int selectionEnd = Math.max(0, cursorPos + newCursorPosition);

    // Update selection
    mEditable.setSelection(selectionStart, selectionEnd);

    // Mark the inserted text as composing region
    mEditable.setComposingRegion(cursorPos, cursorPos + text.length());

    android.util.Log.d(TAG, "setComposingText result: text='" + mEditable.toString() + 
        "', composing=" + cursorPos + "-" + (cursorPos + text.length()));

    return true;
  }

  /**
   * Finishes composing text.
   * 
   * This is called by the IME when composing is finished.
   * This clears the composing region, indicating that the text is now final.
   * 
   * Example:
   * - User was composing: "ni" (拼音)
   * - User selects: "你" (you)
   * - IME calls: finishComposingText()
   * - Composing region is cleared
   * - Text "你" is now final
   *
   * @return true if successful
   */
  @Override
  public boolean finishComposingText() {
    android.util.Log.d(TAG, "finishComposingText");

    // Clear composing region
    mEditable.clearComposingRegion();

    android.util.Log.d(TAG, "finishComposingText result: composing cleared");

    return true;
  }

  /**
   * Sends a key event.
   * 
   * This is called by the IME for special key events like backspace, delete, etc.
   * 
   * We handle:
   * - KEYCODE_DEL: Backspace (delete before cursor)
   * - KEYCODE_FORWARD_DEL: Delete (delete after cursor)
   * 
   * Flow for backspace:
   * 1. Get cursor position
   * 2. If there's selection, delete selected text
   * 3. If no selection, delete one character before cursor
   * 4. Update cursor position
   * 
   * Example:
   * - Current text: "Hello|" (cursor at |)
   * - User presses backspace
   * - IME calls: sendKeyEvent(KEYCODE_DEL)
   * - We delete "o"
   * - Result: "Hell|"
   *
   * @param event The key event
   * @return true if handled, false otherwise
   */
  @Override
  public boolean sendKeyEvent(KeyEvent event) {
    android.util.Log.d(TAG, "sendKeyEvent: keyCode=" + event.getKeyCode() + 
        ", action=" + event.getAction());

    // Only handle key down events
    if (event.getAction() == KeyEvent.ACTION_DOWN) {
      // Handle backspace
      if (event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
        int selectionStart = mEditable.getSelectionStart();
        int selectionEnd = mEditable.getSelectionEnd();

        // If there's no selection (just cursor)
        if (selectionStart == selectionEnd && selectionStart > 0) {
          // Delete one character before cursor
          mEditable.delete(selectionStart - 1, selectionStart);
          // Move cursor back one position
          mEditable.setSelection(selectionStart - 1, selectionStart - 1);
        } 
        // If there's a selection
        else if (selectionStart != selectionEnd) {
          // Delete selected text
          mEditable.delete(selectionStart, selectionEnd);
          // Move cursor to start of deleted region
          mEditable.setSelection(selectionStart, selectionStart);
        }

        android.util.Log.d(TAG, "sendKeyEvent DEL result: text='" + mEditable.toString() + 
            "', cursor=" + mEditable.getSelectionStart());

        return true;
      } 
      // Handle forward delete
      else if (event.getKeyCode() == KeyEvent.KEYCODE_FORWARD_DEL) {
        int selectionStart = mEditable.getSelectionStart();
        int selectionEnd = mEditable.getSelectionEnd();

        // If there's no selection (just cursor)
        if (selectionStart == selectionEnd && selectionStart < mEditable.length()) {
          // Delete one character after cursor
          mEditable.delete(selectionStart, selectionStart + 1);
        } 
        // If there's a selection
        else if (selectionStart != selectionEnd) {
          // Delete selected text
          mEditable.delete(selectionStart, selectionEnd);
          // Move cursor to start of deleted region
          mEditable.setSelection(selectionStart, selectionStart);
        }

        android.util.Log.d(TAG, "sendKeyEvent FORWARD_DEL result: text='" + mEditable.toString() + 
            "', cursor=" + mEditable.getSelectionStart());

        return true;
      }
    }

    return false;
  }

  /**
   * Handles a key event.
   * 
   * This is a wrapper around sendKeyEvent for easier testing.
   *
   * @param keyEvent The key event to handle
   * @return true if handled, false otherwise
   */
  public boolean handleKeyEvent(KeyEvent keyEvent) {
    return sendKeyEvent(keyEvent);
  }

  /**
   * Performs an editor action.
   * 
   * This is called when user presses the action button on the keyboard
   * (like Done, Send, Next, etc.).
   * 
   * For now, we just return true (accept the action).
   * In a full implementation, you might send this to Flutter.
   *
   * @param actionCode The action code (IME_ACTION_DONE, IME_ACTION_SEND, etc.)
   * @return true if handled
   */
  @Override
  public boolean performEditorAction(int actionCode) {
    android.util.Log.d(TAG, "performEditorAction: actionCode=" + actionCode);
    return true;
  }

  /**
   * Clears meta key states.
   * 
   * This is called to clear any meta key states (Shift, Ctrl, Alt, etc.).
   * For now, we just return true.
   *
   * @param states The meta key states to clear
   * @return true if handled
   */
  @Override
  public boolean clearMetaKeyStates(int states) {
    android.util.Log.d(TAG, "clearMetaKeyStates: states=" + states);
    return true;
  }

  /**
   * Deletes surrounding text in code points.
   * 
   * This is similar to deleteSurroundingText but works with code points
   * instead of characters (important for emoji and other multi-byte characters).
   * 
   * For now, we just delegate to deleteSurroundingText.
   *
   * @param beforeLength Number of code points to delete before cursor
   * @param afterLength  Number of code points to delete after cursor
   * @return true if successful
   */
  @Override
  public boolean deleteSurroundingTextInCodePoints(int beforeLength, int afterLength) {
    android.util.Log.d(TAG, "deleteSurroundingTextInCodePoints: beforeLength=" + beforeLength + 
        ", afterLength=" + afterLength);
    return deleteSurroundingText(beforeLength, afterLength);
  }

  /**
   * Gets debug information about this connection.
   * 
   * @return Debug string
   */
  @NonNull
  @Override
  public String toString() {
    return "InputConnectionAdaptor{" +
        "clientId=" + mClientId +
        ", text='" + mEditable.toString() + '\'' +
        ", selection=" + mEditable.getSelectionStart() + "-" + mEditable.getSelectionEnd() +
        ", composing=" + mEditable.getComposingStart() + "-" + mEditable.getComposingEnd() +
        '}';
  }
}

