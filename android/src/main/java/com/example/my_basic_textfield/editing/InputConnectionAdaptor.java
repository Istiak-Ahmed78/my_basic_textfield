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

public class InputConnectionAdaptor extends BaseInputConnection {
  private static final String TAG = "InputConnectionAdaptor";

  @NonNull
  private final View mView;

  private final int mClientId;

  @NonNull
  private final TextInputChannel textInputChannel;

  @NonNull
  private final ScribeChannel scribeChannel;

  @NonNull
  private final ListenableEditingState mEditable;

  @NonNull
  private final EditorInfo outAttrs;

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

  @Override
  public Editable getEditable() {
    return mEditable;
  }

  @Override
  public boolean commitText(CharSequence text, int newCursorPosition) {
    android.util.Log.d(TAG, "commitText: text='" + text + "', newCursorPosition=" + newCursorPosition);

    if (mEditable.isComposingRangeValid()) {
      mEditable.delete(mEditable.getComposingStart(), mEditable.getComposingEnd());
    }

    int cursorPos = mEditable.getSelectionStart();

    int selectionStart = Math.max(0, cursorPos + newCursorPosition - 1);
    int selectionEnd = Math.max(0, cursorPos + newCursorPosition);

    mEditable.replace(cursorPos, cursorPos, text);

    mEditable.setSelection(selectionStart, selectionEnd);

    mEditable.clearComposingRegion();

    android.util.Log.d(TAG, "commitText result: text='" + mEditable.toString() + 
        "', selection=" + selectionStart + "-" + selectionEnd);

    return true;
  }

  @Override
  public boolean deleteSurroundingText(int beforeLength, int afterLength) {
    android.util.Log.d(TAG, "deleteSurroundingText: beforeLength=" + beforeLength + 
        ", afterLength=" + afterLength);

    int cursorPos = mEditable.getSelectionStart();

    int deleteStart = Math.max(0, cursorPos - beforeLength);
    int deleteEnd = Math.min(mEditable.length(), cursorPos + afterLength);

    if (deleteStart < deleteEnd) {
      mEditable.delete(deleteStart, deleteEnd);
      mEditable.setSelection(deleteStart, deleteStart);
    }

    android.util.Log.d(TAG, "deleteSurroundingText result: text='" + mEditable.toString() + 
        "', cursor=" + deleteStart);

    return true;
  }

  @Override
  public boolean setSelection(int start, int end) {
    android.util.Log.d(TAG, "setSelection: start=" + start + ", end=" + end);

    int length = mEditable.length();
    int clampedStart = Math.max(0, Math.min(start, length));
    int clampedEnd = Math.max(0, Math.min(end, length));

    mEditable.setSelection(clampedStart, clampedEnd);

    android.util.Log.d(TAG, "setSelection result: selection=" + clampedStart + "-" + clampedEnd);

    return true;
  }

  @Override
  public boolean setComposingRegion(int start, int end) {
    android.util.Log.d(TAG, "setComposingRegion: start=" + start + ", end=" + end);

    int length = mEditable.length();
    int clampedStart = Math.max(0, Math.min(start, length));
    int clampedEnd = Math.max(0, Math.min(end, length));

    mEditable.setComposingRegion(clampedStart, clampedEnd);

    android.util.Log.d(TAG, "setComposingRegion result: composing=" + clampedStart + "-" + clampedEnd);

    return true;
  }

  @Override
  public boolean setComposingText(CharSequence text, int newCursorPosition) {
    android.util.Log.d(TAG, "setComposingText: text='" + text + "', newCursorPosition=" + newCursorPosition);

    if (mEditable.isComposingRangeValid()) {
      mEditable.delete(mEditable.getComposingStart(), mEditable.getComposingEnd());
    }

    int cursorPos = mEditable.getSelectionStart();

    mEditable.replace(cursorPos, cursorPos, text);

    int selectionStart = Math.max(0, cursorPos + newCursorPosition - 1);
    int selectionEnd = Math.max(0, cursorPos + newCursorPosition);

    mEditable.setSelection(selectionStart, selectionEnd);

    mEditable.setComposingRegion(cursorPos, cursorPos + text.length());

    android.util.Log.d(TAG, "setComposingText result: text='" + mEditable.toString() + 
        "', composing=" + cursorPos + "-" + (cursorPos + text.length()));

    return true;
  }

  @Override
  public boolean finishComposingText() {
    android.util.Log.d(TAG, "finishComposingText");

    mEditable.clearComposingRegion();

    android.util.Log.d(TAG, "finishComposingText result: composing cleared");

    return true;
  }

  @Override
  public boolean sendKeyEvent(KeyEvent event) {
    android.util.Log.d(TAG, "sendKeyEvent: keyCode=" + event.getKeyCode() + 
        ", action=" + event.getAction());

    if (event.getAction() == KeyEvent.ACTION_DOWN) {
      if (event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
        int selectionStart = mEditable.getSelectionStart();
        int selectionEnd = mEditable.getSelectionEnd();

        if (selectionStart == selectionEnd && selectionStart > 0) {
          mEditable.delete(selectionStart - 1, selectionStart);
          mEditable.setSelection(selectionStart - 1, selectionStart - 1);
        } 
        else if (selectionStart != selectionEnd) {
          mEditable.delete(selectionStart, selectionEnd);
          mEditable.setSelection(selectionStart, selectionStart);
        }

        android.util.Log.d(TAG, "sendKeyEvent DEL result: text='" + mEditable.toString() + 
            "', cursor=" + mEditable.getSelectionStart());

        return true;
      } 
      else if (event.getKeyCode() == KeyEvent.KEYCODE_FORWARD_DEL) {
        int selectionStart = mEditable.getSelectionStart();
        int selectionEnd = mEditable.getSelectionEnd();

        if (selectionStart == selectionEnd && selectionStart < mEditable.length()) {
          mEditable.delete(selectionStart, selectionStart + 1);
        } 
        else if (selectionStart != selectionEnd) {
          mEditable.delete(selectionStart, selectionEnd);
          mEditable.setSelection(selectionStart, selectionStart);
        }

        android.util.Log.d(TAG, "sendKeyEvent FORWARD_DEL result: text='" + mEditable.toString() + 
            "', cursor=" + mEditable.getSelectionStart());

        return true;
      }
    }

    return false;
  }

  public boolean handleKeyEvent(KeyEvent keyEvent) {
    return sendKeyEvent(keyEvent);
  }

  @Override
  public boolean performEditorAction(int actionCode) {
    android.util.Log.d(TAG, "performEditorAction: actionCode=" + actionCode);
    return true;
  }

  @Override
  public boolean clearMetaKeyStates(int states) {
    android.util.Log.d(TAG, "clearMetaKeyStates: states=" + states);
    return true;
  }

  @Override
  public boolean deleteSurroundingTextInCodePoints(int beforeLength, int afterLength) {
    android.util.Log.d(TAG, "deleteSurroundingTextInCodePoints: beforeLength=" + beforeLength + 
        ", afterLength=" + afterLength);
    return deleteSurroundingText(beforeLength, afterLength);
  }

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