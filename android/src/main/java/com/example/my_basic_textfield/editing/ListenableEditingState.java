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

  /**
   * Interface for listening to editing state changes
   */
  public interface EditingStateWatcher {
    /**
     * Called when editing state changes
     *
     * @param textChanged           true if text content changed
     * @param selectionChanged      true if cursor/selection changed
     * @param composingRegionChanged true if composing region changed
     */
    void didChangeEditingState(
        boolean textChanged, boolean selectionChanged, boolean composingRegionChanged);
  }

  /**
   * The start position of the selection (cursor)
   * 
   * For a collapsed selection (just cursor): mSelectionStart == mSelectionEnd
   * For a range selection: mSelectionStart < mSelectionEnd
   * 
   * Example:
   * - Text: "Hello World"
   * - Cursor at position 5: mSelectionStart=5, mSelectionEnd=5
   * - "Hello" selected: mSelectionStart=0, mSelectionEnd=5
   */
  private int mSelectionStart = 0;

  /**
   * The end position of the selection (cursor)
   * 
   * For a collapsed selection (just cursor): mSelectionStart == mSelectionEnd
   * For a range selection: mSelectionStart < mSelectionEnd
   */
  private int mSelectionEnd = 0;

  /**
   * The start position of the composing region
   * 
   * The composing region is used by IME (Input Method Editor) for
   * languages that require composition (like Chinese, Japanese, Korean).
   * 
   * -1 means no composing region is active.
   * 
   * Example:
   * - User types "ni" in Chinese IME
   * - IME shows candidates like "你", "呢"
   * - mComposingStart=0, mComposingEnd=2 (the "ni" is composing)
   * - User selects "你"
   * - IME commits the text and clears composing region
   * - mComposingStart=-1, mComposingEnd=-1
   */
  private int mComposingStart = -1;

  /**
   * The end position of the composing region
   * 
   * -1 means no composing region is active.
   */
  private int mComposingEnd = -1;

  /**
   * List of listeners that watch for editing state changes
   */
  @NonNull
  private final ArrayList<EditingStateWatcher> mWatchers = new ArrayList<>();

  /**
   * List of text editing deltas (changes)
   * 
   * A delta represents a change to the text:
   * - oldStart: where the change started
   * - oldEnd: where the change ended
   * - replacementText: what replaced the old text
   * 
   * Example:
   * - Original text: "Hello"
   * - User types "World" at position 5
   * - Delta: oldStart=5, oldEnd=5, replacementText="World"
   * 
   * These deltas are used for efficient updates instead of sending
   * the entire text each time.
   */
  @NonNull
  private final ArrayList<TextEditingDelta> mBatchDeltas = new ArrayList<>();

  /**
   * Whether we're currently in a batch edit
   * 
   * When true, we don't notify listeners until endBatchEdit() is called.
   * This is for efficiency when making multiple changes at once.
   * 
   * Example:
   * - beginBatchEdit()
   * - replace(0, 5, "new text")
   * - setSelection(8, 8)
   * - endBatchEdit()  ← listeners notified once, not twice
   */
  private boolean mIsInBatchEdit = false;

  /**
   * The previous text length
   * 
   * Used to track text changes in onTextChanged()
   */
  private int mPreviousLength = 0;

  /**
   * Creates a new ListenableEditingState
   *
   * @param text The initial text content (can be null)
   * @param view The view that owns this editable state (for context)
   */
  public ListenableEditingState(@Nullable String text, @NonNull View view) {
    // Initialize SpannableStringBuilder with text
    super(text != null ? text : "");
    
    // Register ourselves as a TextWatcher to receive text change notifications
    addTextChangedListener(this);
    
    android.util.Log.d(TAG, "ListenableEditingState created with text: '" + getText() + "'");
  }

  /**
   * Adds a listener that will be notified of editing state changes
   *
   * @param watcher The listener to add
   */
  public void addEditingStateListener(@NonNull EditingStateWatcher watcher) {
    mWatchers.add(watcher);
    android.util.Log.d(TAG, "Listener added. Total listeners: " + mWatchers.size());
  }

  /**
   * Removes a listener
   *
   * @param watcher The listener to remove
   */
  public void removeEditingStateListener(@NonNull EditingStateWatcher watcher) {
    mWatchers.remove(watcher);
    android.util.Log.d(TAG, "Listener removed. Total listeners: " + mWatchers.size());
  }

  /**
   * Gets the start position of the selection
   *
   * @return The selection start position
   */
  public int getSelectionStart() {
    return mSelectionStart;
  }

  /**
   * Gets the end position of the selection
   *
   * @return The selection end position
   */
  public int getSelectionEnd() {
    return mSelectionEnd;
  }

  /**
   * Gets the start position of the composing region
   *
   * @return The composing start position (-1 if no composing)
   */
  public int getComposingStart() {
    return mComposingStart;
  }

  /**
   * Gets the end position of the composing region
   *
   * @return The composing end position (-1 if no composing)
   */
  public int getComposingEnd() {
    return mComposingEnd;
  }

  /**
   * Checks if the composing region is valid
   * 
   * A composing region is valid if:
   * - Both start and end are >= 0
   * - start <= end
   *
   * @return true if composing region is valid
   */
  public boolean isComposingRangeValid() {
    return mComposingStart >= 0 && mComposingEnd >= 0 && mComposingStart <= mComposingEnd;
  }

  /**
   * Sets the selection (cursor position)
   * 
   * This is called by InputConnectionAdaptor when:
   * - User taps to move cursor
   * - User selects text
   * - Cursor needs to be updated after text changes
   * 
   * Example:
   * - setSelection(5, 5) - cursor at position 5
   * - setSelection(0, 5) - "Hello" is selected (positions 0-5)
   *
   * @param start The start of selection
   * @param end   The end of selection
   */
  public void setSelection(int start, int end) {
    // Check if selection actually changed
    boolean changed = mSelectionStart != start || mSelectionEnd != end;
    
    // Update selection
    mSelectionStart = start;
    mSelectionEnd = end;

    // Notify listeners if selection changed
    if (changed) {
      android.util.Log.d(TAG, "Selection changed: " + start + "-" + end);
      notifyListeners(false, true, false);
    }
  }

  /**
   * Sets the composing region
   * 
   * This is called by InputConnectionAdaptor when:
   * - IME starts composing text
   * - IME updates composing region
   * - Composing is finished
   * 
   * Example:
   * - setComposingRegion(0, 2) - positions 0-2 are composing
   * - setComposingRegion(-1, -1) - no composing
   *
   * @param start The start of composing region
   * @param end   The end of composing region
   */
  public void setComposingRegion(int start, int end) {
    // Check if composing region actually changed
    boolean changed = mComposingStart != start || mComposingEnd != end;
    
    // Update composing region
    mComposingStart = start;
    mComposingEnd = end;

    // Notify listeners if composing region changed
    if (changed) {
      android.util.Log.d(TAG, "Composing region changed: " + start + "-" + end);
      notifyListeners(false, false, true);
    }
  }

  /**
   * Clears the composing region
   * 
   * This is called when composing is finished or cancelled.
   * Sets composing region to (-1, -1) which means no composing.
   */
  public void clearComposingRegion() {
    setComposingRegion(-1, -1);
  }

  /**
   * Sets the entire editing state from a TextEditState object
   * 
   * This is called when Flutter sends the complete text state to native.
   * We update:
   * - Text content
   * - Selection
   * - Composing region
   *
   * @param state The TextEditState from Flutter
   */
  public void setEditingState(
      @NonNull io.flutter.embedding.engine.systemchannels.TextInputChannel.TextEditState state) {
    android.util.Log.d(TAG, "setEditingState: text='" + state.text + 
        "', selection=" + state.selectionStart + "-" + state.selectionEnd +
        ", composing=" + state.composingStart + "-" + state.composingEnd);

    // Replace entire text
    replace(0, length(), state.text);
    
    // Update selection
    setSelection(state.selectionStart, state.selectionEnd);
    
    // Update composing region
    setComposingRegion(state.composingStart, state.composingEnd);
  }

  /**
   * Extracts all accumulated text editing deltas
   * 
   * Deltas represent the changes made to the text. Instead of sending
   * the entire text each time, we can send just the deltas for efficiency.
   * 
   * This method returns all accumulated deltas and clears the list.
   *
   * @return List of TextEditingDelta objects
   */
  public ArrayList<TextEditingDelta> extractBatchTextEditingDeltas() {
    ArrayList<TextEditingDelta> deltas = new ArrayList<>(mBatchDeltas);
    mBatchDeltas.clear();
    return deltas;
  }

  /**
   * Clears all accumulated text editing deltas
   * 
   * This is called when we skip sending an update to Flutter
   * (because nothing actually changed).
   */
  public void clearBatchDeltas() {
    mBatchDeltas.clear();
  }

  /**
   * Notifies all listeners of editing state changes
   * 
   * This is called whenever text, selection, or composing region changes.
   * We only notify if not in batch edit mode.
   *
   * @param textChanged           true if text content changed
   * @param selectionChanged      true if cursor/selection changed
   * @param composingChanged      true if composing region changed
   */
  private void notifyListeners(boolean textChanged, boolean selectionChanged, boolean composingChanged) {
    // Don't notify during batch edit - wait until endBatchEdit()
    if (mIsInBatchEdit) {
      return;
    }

    // Notify all listeners
    for (EditingStateWatcher watcher : mWatchers) {
      watcher.didChangeEditingState(textChanged, selectionChanged, composingChanged);
    }
  }

  /**
   * Called before text is changed
   * 
   * This is part of TextWatcher interface.
   * We use this to record the previous text length.
   *
   * @param s     The text before change
   * @param start Where the change starts
   * @param count How many characters are being replaced
   * @param after How many characters are replacing them
   */
  @Override
  public void beforeTextChanged(CharSequence s, int start, int count, int after) {
    // Record previous length for tracking changes
    mPreviousLength = s.length();
    
    android.util.Log.d(TAG, "beforeTextChanged: start=" + start + ", count=" + count + 
        ", after=" + after + ", length=" + mPreviousLength);
  }

  /**
   * Called when text is changed
   * 
   * This is part of TextWatcher interface.
   * We use this to create TextEditingDelta objects for efficient updates.
   * 
   * A delta represents what changed:
   * - oldStart: where the change started
   * - oldEnd: where the change ended (oldStart + count)
   * - replacementText: what replaced the old text
   *
   * @param s     The text after change
   * @param start Where the change starts
   * @param before How many characters were replaced
   * @param count How many characters are replacing them
   */
  @Override
  public void onTextChanged(CharSequence s, int start, int before, int count) {
    // Track changes for deltas
    if (count > 0) {
      // Text was inserted
      // Extract the inserted text
      String insertedText = s.subSequence(start, start + count).toString();
      
      // Create delta: deleted from start to start+before, inserted insertedText
      TextEditingDelta delta = new TextEditingDelta(start, start + before, insertedText);
      mBatchDeltas.add(delta);
      
      android.util.Log.d(TAG, "onTextChanged INSERT: delta=" + delta);
    } else if (before > 0) {
      // Text was deleted
      TextEditingDelta delta = new TextEditingDelta(start, start + before, "");
      mBatchDeltas.add(delta);
      
      android.util.Log.d(TAG, "onTextChanged DELETE: delta=" + delta);
    }
  }

  /**
   * Called after text is changed
   * 
   * This is part of TextWatcher interface.
   * We use this to notify listeners after text change is complete.
   *
   * @param s The text after change
   */
  @Override
  public void afterTextChanged(Editable s) {
    // Only notify if not in batch edit mode
    if (!mIsInBatchEdit) {
      android.util.Log.d(TAG, "afterTextChanged: text='" + s.toString() + "'");
      notifyListeners(true, false, false);
    }
  }

  /**
   * Begins a batch edit
   * 
   * Call this before making multiple changes to avoid notifying listeners
   * multiple times. Listeners will be notified once when endBatchEdit() is called.
   * 
   * Example:
   * ```
   * beginBatchEdit();
   * replace(0, 5, "new text");
   * setSelection(8, 8);
   * endBatchEdit();  // listeners notified once
   * ```
   */
  public void beginBatchEdit() {
    mIsInBatchEdit = true;
    android.util.Log.d(TAG, "beginBatchEdit");
  }

  /**
   * Ends a batch edit
   * 
   * Call this after making multiple changes. This will notify all listeners
   * once for all the changes made since beginBatchEdit() was called.
   */
  public void endBatchEdit() {
    mIsInBatchEdit = false;
    android.util.Log.d(TAG, "endBatchEdit: notifying listeners");
    notifyListeners(true, false, false);
  }

  /**
   * Gets the current text as a string
   *
   * @return The text content
   */
  @NonNull
  @Override
  public String toString() {
    return super.toString();
  }

  /**
   * Gets detailed debug information
   *
   * @return Debug string
   */
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