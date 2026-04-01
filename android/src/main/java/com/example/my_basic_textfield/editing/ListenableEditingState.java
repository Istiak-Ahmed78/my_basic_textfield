package com.example.my_basic_textfield.editing;

import android.text.Editable;
import android.text.SpannableStringBuilder;
import android.text.TextWatcher;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.ArrayList;

public class ListenableEditingState extends SpannableStringBuilder implements TextWatcher {
  private static final String TAG = "ListenableEditingState";

  public interface EditingStateWatcher {
    void didChangeEditingState(
        boolean textChanged, boolean selectionChanged, boolean composingRegionChanged);
  }

  private int mSelectionStart = 0;

  private int mSelectionEnd = 0;

  private int mComposingStart = -1;

  private int mComposingEnd = -1;

  @NonNull
  private final ArrayList<EditingStateWatcher> mWatchers = new ArrayList<>();

  @NonNull
  private final ArrayList<TextEditingDelta> mBatchDeltas = new ArrayList<>();

  private boolean mIsInBatchEdit = false;

  private int mPreviousLength = 0;

  public ListenableEditingState(@Nullable String text, @NonNull View view) {
    super(text != null ? text : "");
    
    addTextChangedListener(this);
    
    android.util.Log.d(TAG, "ListenableEditingState created with text: '" + getText() + "'");
  }

  public void addEditingStateListener(@NonNull EditingStateWatcher watcher) {
    mWatchers.add(watcher);
    android.util.Log.d(TAG, "Listener added. Total listeners: " + mWatchers.size());
  }

  public void removeEditingStateListener(@NonNull EditingStateWatcher watcher) {
    mWatchers.remove(watcher);
    android.util.Log.d(TAG, "Listener removed. Total listeners: " + mWatchers.size());
  }

  public int getSelectionStart() {
    return mSelectionStart;
  }

  public int getSelectionEnd() {
    return mSelectionEnd;
  }

  public int getComposingStart() {
    return mComposingStart;
  }

  public int getComposingEnd() {
    return mComposingEnd;
  }

  public boolean isComposingRangeValid() {
    return mComposingStart >= 0 && mComposingEnd >= 0 && mComposingStart <= mComposingEnd;
  }

  public void setSelection(int start, int end) {
    boolean changed = mSelectionStart != start || mSelectionEnd != end;
    
    mSelectionStart = start;
    mSelectionEnd = end;

    if (changed) {
      android.util.Log.d(TAG, "Selection changed: " + start + "-" + end);
      notifyListeners(false, true, false);
    }
  }

  public void setComposingRegion(int start, int end) {
    boolean changed = mComposingStart != start || mComposingEnd != end;
    
    mComposingStart = start;
    mComposingEnd = end;

    if (changed) {
      android.util.Log.d(TAG, "Composing region changed: " + start + "-" + end);
      notifyListeners(false, false, true);
    }
  }

  public void clearComposingRegion() {
    setComposingRegion(-1, -1);
  }

  public void setEditingState(
      @NonNull io.flutter.embedding.engine.systemchannels.TextInputChannel.TextEditState state) {
    android.util.Log.d(TAG, "setEditingState: text='" + state.text + 
        "', selection=" + state.selectionStart + "-" + state.selectionEnd +
        ", composing=" + state.composingStart + "-" + state.composingEnd);

    replace(0, length(), state.text);
    
    setSelection(state.selectionStart, state.selectionEnd);
    
    setComposingRegion(state.composingStart, state.composingEnd);
  }

  public ArrayList<TextEditingDelta> extractBatchTextEditingDeltas() {
    ArrayList<TextEditingDelta> deltas = new ArrayList<>(mBatchDeltas);
    mBatchDeltas.clear();
    return deltas;
  }

  public void clearBatchDeltas() {
    mBatchDeltas.clear();
  }

  private void notifyListeners(boolean textChanged, boolean selectionChanged, boolean composingChanged) {
    if (mIsInBatchEdit) {
      return;
    }

    for (EditingStateWatcher watcher : mWatchers) {
      watcher.didChangeEditingState(textChanged, selectionChanged, composingChanged);
    }
  }

  @Override
  public void beforeTextChanged(CharSequence s, int start, int count, int after) {
    mPreviousLength = s.length();
    
    android.util.Log.d(TAG, "beforeTextChanged: start=" + start + ", count=" + count + 
        ", after=" + after + ", length=" + mPreviousLength);
  }

  @Override
  public void onTextChanged(CharSequence s, int start, int before, int count) {
    if (count > 0) {
      String insertedText = s.subSequence(start, start + count).toString();
      
      TextEditingDelta delta = new TextEditingDelta(start, start + before, insertedText);
      mBatchDeltas.add(delta);
      
      android.util.Log.d(TAG, "onTextChanged INSERT: delta=" + delta);
    } else if (before > 0) {
      TextEditingDelta delta = new TextEditingDelta(start, start + before, "");
      mBatchDeltas.add(delta);
      
      android.util.Log.d(TAG, "onTextChanged DELETE: delta=" + delta);
    }
  }

  @Override
  public void afterTextChanged(Editable s) {
    if (!mIsInBatchEdit) {
      android.util.Log.d(TAG, "afterTextChanged: text='" + s.toString() + "'");
      notifyListeners(true, false, false);
    }
  }

  public void beginBatchEdit() {
    mIsInBatchEdit = true;
    android.util.Log.d(TAG, "beginBatchEdit");
  }

  public void endBatchEdit() {
    mIsInBatchEdit = false;
    android.util.Log.d(TAG, "endBatchEdit: notifying listeners");
    notifyListeners(true, false, false);
  }

  @NonNull
  @Override
  public String toString() {
    return super.toString();
  }

  @NonNull
  public String toDebugString() {
    return "ListenableEditingState{" +
        "text='" + toString() + '\'' +
        ", selectionStart=" + mSelectionStart +
        ", selectionEnd=" + mSelectionEnd +
        ", composingStart=" + mComposingStart +
        ", composingEnd=" + mComposingEnd +
        ", isComposingValid=" + isComposingRangeValid() +
        ", listeners=" + mWatchers.size() +
        ", inBatchEdit=" + mIsInBatchEdit +
        '}';
  }
}