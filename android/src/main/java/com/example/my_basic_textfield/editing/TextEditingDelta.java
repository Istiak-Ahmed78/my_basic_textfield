package com.example.my_basic_textfield.editing;

import androidx.annotation.NonNull;

/**
 * Represents a single change (delta) to the text.
 * 
 * Instead of sending the entire text content each time it changes,
 * we can send just the deltas (changes) for efficiency.
 * 
 * A delta represents:
 * - What was deleted: from oldStart to oldEnd
 * - What was inserted: replacementText
 * 
 * Examples:
 * 
 * Example 1: User types "H" at position 0
 * - Original text: ""
 * - After: "H"
 * - Delta: oldStart=0, oldEnd=0, replacementText="H"
 * - Meaning: Delete nothing (0 to 0), insert "H"
 * 
 * Example 2: User types "ello" at position 1
 * - Original text: "H"
 * - After: "Hello"
 * - Delta: oldStart=1, oldEnd=1, replacementText="ello"
 * - Meaning: Delete nothing (1 to 1), insert "ello"
 * 
 * Example 3: User deletes "llo" (positions 2-5)
 * - Original text: "Hello"
 * - After: "He"
 * - Delta: oldStart=2, oldEnd=5, replacementText=""
 * - Meaning: Delete "llo" (2 to 5), insert nothing
 * 
 * Example 4: User replaces "ell" with "i" (positions 1-4)
 * - Original text: "Hello"
 * - After: "Hio"
 * - Delta: oldStart=1, oldEnd=4, replacementText="i"
 * - Meaning: Delete "ell" (1 to 4), insert "i"
 * 
 * Why use deltas?
 * - More efficient: Send only changes, not entire text
 * - Useful for advanced features: Undo/redo, collaborative editing, etc.
 * - Matches Flutter's TextEditingDelta API
 * 
 * Architecture:
 * ```
 * User types "H"
 *     ↓
 * IME calls: InputConnectionAdaptor.commitText("H", 1)
 *     ↓
 * InputConnectionAdaptor calls: mEditable.replace(0, 0, "H")
 *     ↓
 * ListenableEditingState.onTextChanged() is called
 *     ↓
 * Create TextEditingDelta: oldStart=0, oldEnd=0, replacementText="H"
 *     ↓
 * Add to mBatchDeltas
 *     ↓
 * Later, TextInputPlugin.didChangeEditingState() is called
 *     ↓
 * Extract deltas: [TextEditingDelta(0, 0, "H")]
 *     ↓
 * Send to Flutter (along with complete text state)
 *     ↓
 * Flutter can use deltas for efficient updates
 * ```
 */
public class TextEditingDelta {
  private static final String TAG = "TextEditingDelta";

  /**
   * The start position of the deleted region
   * 
   * This is where the change starts in the original text.
   * 
   * Example:
   * - Original text: "Hello"
   * - Delete "ell" (positions 1-4)
   * - oldStart = 1
   */
  private final int oldStart;

  /**
   * The end position of the deleted region
   * 
   * This is where the change ends in the original text.
   * The deleted region is from oldStart to oldEnd (exclusive).
   * 
   * Example:
   * - Original text: "Hello"
   * - Delete "ell" (positions 1-4)
   * - oldEnd = 4
   * - Deleted text: "Hello".substring(1, 4) = "ell"
   */
  private final int oldEnd;

  /**
   * The text that replaces the deleted region
   * 
   * This is the new text that replaces the deleted region.
   * If empty string, it means just deletion (no insertion).
   * 
   * Example 1: Insert "H" at position 0
   * - oldStart=0, oldEnd=0, replacementText="H"
   * - Meaning: Delete nothing, insert "H"
   * 
   * Example 2: Delete "ello" from positions 1-5
   * - oldStart=1, oldEnd=5, replacementText=""
   * - Meaning: Delete "ello", insert nothing
   * 
   * Example 3: Replace "ell" with "i" at positions 1-4
   * - oldStart=1, oldEnd=4, replacementText="i"
   * - Meaning: Delete "ell", insert "i"
   */
  private final String replacementText;

  /**
   * Creates a new TextEditingDelta
   * 
   * @param oldStart        The start position of deleted region
   * @param oldEnd          The end position of deleted region
   * @param replacementText The text to insert (can be empty string)
   */
  public TextEditingDelta(int oldStart, int oldEnd, String replacementText) {
    this.oldStart = oldStart;
    this.oldEnd = oldEnd;
    // Use empty string if replacementText is null
    this.replacementText = replacementText != null ? replacementText : "";
  }

  /**
   * Gets the start position of the deleted region
   * 
   * @return The start position
   */
  public int getOldStart() {
    return oldStart;
  }

  /**
   * Gets the end position of the deleted region
   * 
   * @return The end position
   */
  public int getOldEnd() {
    return oldEnd;
  }

  /**
   * Gets the replacement text
   * 
   * @return The replacement text (never null, empty string if no replacement)
   */
  public String getReplacementText() {
    return replacementText;
  }

  /**
   * Gets the number of characters deleted
   * 
   * @return The number of deleted characters
   */
  public int getDeletedCount() {
    return oldEnd - oldStart;
  }

  /**
   * Gets the number of characters inserted
   * 
   * @return The number of inserted characters
   */
  public int getInsertedCount() {
    return replacementText.length();
  }

  /**
   * Gets the net change in text length
   * 
   * Positive: more characters inserted than deleted
   * Negative: more characters deleted than inserted
   * Zero: same number of characters deleted and inserted
   * 
   * @return The net change in length
   */
  public int getNetChange() {
    return getInsertedCount() - getDeletedCount();
  }

  /**
   * Checks if this delta is just an insertion (no deletion)
   * 
   * @return true if oldStart == oldEnd (nothing deleted)
   */
  public boolean isInsertion() {
    return oldStart == oldEnd;
  }

  /**
   * Checks if this delta is just a deletion (no insertion)
   * 
   * @return true if replacementText is empty
   */
  public boolean isDeletion() {
    return replacementText.isEmpty();
  }

  /**
   * Checks if this delta is a replacement (both deletion and insertion)
   * 
   * @return true if both deletion and insertion occurred
   */
  public boolean isReplacement() {
    return !isInsertion() && !isDeletion();
  }

  /**
   * Gets the type of delta as a string
   * 
   * @return "insertion", "deletion", or "replacement"
   */
  @NonNull
  public String getType() {
    if (isInsertion()) {
      return "insertion";
    } else if (isDeletion()) {
      return "deletion";
    } else {
      return "replacement";
    }
  }

  /**
   * Gets a human-readable description of this delta
   * 
   * @return Description string
   */
  @NonNull
  public String getDescription() {
    if (isInsertion()) {
      return "Insert '" + replacementText + "' at position " + oldStart;
    } else if (isDeletion()) {
      return "Delete " + getDeletedCount() + " characters from position " + oldStart;
    } else {
      return "Replace " + getDeletedCount() + " characters at position " + oldStart + 
             " with '" + replacementText + "'";
    }
  }

  @NonNull
  @Override
  public String toString() {
    return "TextEditingDelta{" +
        "oldStart=" + oldStart +
        ", oldEnd=" + oldEnd +
        ", replacementText='" + replacementText + '\'' +
        ", type=" + getType() +
        '}';
  }

  /**
   * Gets a detailed debug string
   * 
   * @return Detailed debug string
   */
  @NonNull
  public String toDebugString() {
    return "TextEditingDelta{" +
        "oldStart=" + oldStart +
        ", oldEnd=" + oldEnd +
        ", deletedCount=" + getDeletedCount() +
        ", replacementText='" + replacementText + '\'' +
        ", insertedCount=" + getInsertedCount() +
        ", netChange=" + getNetChange() +
        ", type=" + getType() +
        ", description='" + getDescription() + '\'' +
        '}';
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;

    TextEditingDelta that = (TextEditingDelta) o;

    if (oldStart != that.oldStart) return false;
    if (oldEnd != that.oldEnd) return false;
    return replacementText.equals(that.replacementText);
  }

  @Override
  public int hashCode() {
    int result = oldStart;
    result = 31 * result + oldEnd;
    result = 31 * result + replacementText.hashCode();
    return result;
  }
}