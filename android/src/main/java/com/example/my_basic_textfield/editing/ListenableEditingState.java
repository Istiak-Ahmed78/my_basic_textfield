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
    
    // ✅ CRITICAL FIX: We override replace() and delete() methods to trigger text change notifications
    // SpannableStringBuilder doesn't have built-in TextWatcher support, so we handle it manually
    
    android.util.Log.d(TAG, "ListenableEditingState created with text: '" + toString() + "'");
  }

  // ✅ CRITICAL OVERRIDE: Intercept text changes to notify listeners
  @Override
  public SpannableStringBuilder replace(int start, int end, CharSequence tb, int tbstart, int tbend) {
    String newText = tb.subSequence(tbstart, tbend).toString();
    android.util.Log.d(TAG, "╔═════════════════════════════════════════════════════════════╗");
    android.util.Log.d(TAG, "│ 📝 replace() OVERRIDE called                              │");
    android.util.Log.d(TAG, "├─ start=" + start + ", end=" + end);
    android.util.Log.d(TAG, "├─ currentText='" + super.toString() + "'");
    android.util.Log.d(TAG, "├─ newText='" + newText + "'");
    
    // Call beforeTextChanged
    android.util.Log.d(TAG, "├─ Calling beforeTextChanged...");
    beforeTextChanged(this, start, end - start, tbend - tbstart);
    
    // Do the actual replacement
    android.util.Log.d(TAG, "├─ Calling super.replace()...");
    SpannableStringBuilder result = super.replace(start, end, tb, tbstart, tbend);
    android.util.Log.d(TAG, "├─ After replace, text='" + super.toString() + "'");
    
    // Call onTextChanged  
    android.util.Log.d(TAG, "├─ Calling onTextChanged...");
    onTextChanged(this, start, end - start, tbend - tbstart);
    
    // Call afterTextChanged
    android.util.Log.d(TAG, "├─ Calling afterTextChanged...");
    afterTextChanged(this);
    android.util.Log.d(TAG, "╚═════════════════════════════════════════════════════════════╝");
    
    return result;
  }

  // ✅ CRITICAL OVERRIDE: Intercept deletes to notify listeners
  @Override
  public SpannableStringBuilder delete(int start, int end) {
    android.util.Log.d(TAG, "delete() called: start=" + start + ", end=" + end);
    
    // Call beforeTextChanged
    beforeTextChanged(this, start, end - start, 0);
    
    // Do the actual deletion
    SpannableStringBuilder result = super.delete(start, end);
    
    // Call onTextChanged
    onTextChanged(this, start, end - start, 0);
    
    // Call afterTextChanged
    afterTextChanged(this);
    
    return result;
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
    android.util.Log.d(TAG, "notifyListeners: textChanged=" + textChanged + 
        ", selectionChanged=" + selectionChanged + 
        ", composingChanged=" + composingChanged +
        ", mIsInBatchEdit=" + mIsInBatchEdit +
        ", watchers.size=" + mWatchers.size());
    
    if (mIsInBatchEdit) {
      android.util.Log.d(TAG, "notifyListeners: SKIPPED because batch edit in progress");
      return;
    }

    if (mWatchers.isEmpty()) {
      android.util.Log.w(TAG, "notifyListeners: WARNING - No listeners registered!");
      return;
    }

    android.util.Log.d(TAG, "notifyListeners: Calling didChangeEditingState on " + mWatchers.size() + " watchers");
    for (EditingStateWatcher watcher : mWatchers) {
      android.util.Log.d(TAG, "notifyListeners: Calling watcher=" + watcher.getClass().getSimpleName());
      watcher.didChangeEditingState(textChanged, selectionChanged, composingChanged);
      android.util.Log.d(TAG, "notifyListeners: Watcher callback completed");
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
    android.util.Log.d(TAG, "╔═══════════════════════════════════════════════════════════╗");
    android.util.Log.d(TAG, "│ afterTextChanged called                                 │");
    android.util.Log.d(TAG, "├─ text='" + s.toString() + "'");
    android.util.Log.d(TAG, "├─ mIsInBatchEdit=" + mIsInBatchEdit);
    
    if (!mIsInBatchEdit) {
      android.util.Log.d(TAG, "├─ Not in batch edit, calling notifyListeners...");
      notifyListeners(true, false, false);
      android.util.Log.d(TAG, "├─ notifyListeners completed");
    } else {
      android.util.Log.d(TAG, "├─ SKIPPED because in batch edit");
    }
    android.util.Log.d(TAG, "╚═══════════════════════════════════════════════════════════╝");
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