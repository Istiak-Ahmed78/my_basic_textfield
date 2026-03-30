package com.example.my_basic_textfield.editing.models;

import androidx.annotation.NonNull;

/**
 * Represents the complete state of text editing.
 * 
 * This immutable class holds all the information about the current state
 * of a text field:
 * - The actual text content
 * - The cursor position (selection)
 * - The composing region (for IME composition)
 * 
 * This is used to communicate the text state between native Android
 * and Flutter Dart code.
 * 
 * Example:
 * Text: "Hello World"
 * Selection: start=5, end=5 (cursor after "Hello")
 * Composing: start=-1, end=-1 (no composing)
 */
public class TextEditState {
  /**
   * The actual text content
   * 
   * Example: "Hello World"
   */
  @NonNull
  public final String text;

  /**
   * The start of the selection (cursor position)
   * 
   * This is the position where selection starts.
   * For a collapsed selection (just cursor), selectionStart == selectionEnd
   * 
   * Example: 5 (after "Hello")
   */
  public final int selectionStart;

  /**
   * The end of the selection (cursor position)
   * 
   * This is the position where selection ends.
   * For a collapsed selection (just cursor), selectionStart == selectionEnd
   * 
   * Example: 5 (cursor at same position)
   */
  public final int selectionEnd;

  /**
   * The start of the composing region
   * 
   * The composing region is used by IME (Input Method Editor) for
   * languages that require composition (like Chinese, Japanese, Korean).
   * 
   * -1 means no composing region is active.
   * 
   * Example: -1 (no composing)
   */
  public final int composingStart;

  /**
   * The end of the composing region
   * 
   * The composing region is used by IME (Input Method Editor) for
   * languages that require composition (like Chinese, Japanese, Korean).
   * 
   * -1 means no composing region is active.
   * 
   * Example: -1 (no composing)
   */
  public final int composingEnd;

  /**
   * Creates a new TextEditState
   *
   * @param text             The text content
   * @param selectionStart   The start of selection
   * @param selectionEnd     The end of selection
   * @param composingStart   The start of composing region
   * @param composingEnd     The end of composing region
   */
  public TextEditState(
      @NonNull String text,
      int selectionStart,
      int selectionEnd,
      int composingStart,
      int composingEnd) {
    this.text = text;
    this.selectionStart = selectionStart;
    this.selectionEnd = selectionEnd;
    this.composingStart = composingStart;
    this.composingEnd = composingEnd;
  }

  /**
   * Creates a TextEditState with no selection or composing
   *
   * @param text The text content
   */
  public TextEditState(@NonNull String text) {
    this(text, 0, 0, -1, -1);
  }

  /**
   * Creates an empty TextEditState
   */
  public TextEditState() {
    this("", 0, 0, -1, -1);
  }

  /**
   * Checks if there is a composing region active
   *
   * @return true if composing region is valid (start >= 0 and end >= 0)
   */
  public boolean hasComposing() {
    return composingStart >= 0 && composingEnd >= 0;
  }

  /**
   * Checks if the selection is collapsed (cursor only, no selection)
   *
   * @return true if selectionStart == selectionEnd
   */
  public boolean isSelectionCollapsed() {
    return selectionStart == selectionEnd;
  }

  /**
   * Gets the length of selected text
   *
   * @return The number of characters selected
   */
  public int getSelectionLength() {
    return Math.abs(selectionEnd - selectionStart);
  }

  /**
   * Gets the length of composing region
   *
   * @return The number of characters in composing region, or 0 if no composing
   */
  public int getComposingLength() {
    if (!hasComposing()) {
      return 0;
    }
    return Math.abs(composingEnd - composingStart);
  }

  /**
   * Gets the text length
   *
   * @return The number of characters in text
   */
  public int getTextLength() {
    return text.length();
  }

  /**
   * Checks if selection is at the beginning
   *
   * @return true if selectionStart == 0
   */
  public boolean isAtBeginning() {
    return selectionStart == 0;
  }

  /**
   * Checks if selection is at the end
   *
   * @return true if selectionStart == text.length()
   */
  public boolean isAtEnd() {
    return selectionStart == text.length();
  }

  /**
   * Gets the selected text
   *
   * @return The substring of selected text, or empty string if no selection
   */
  @NonNull
  public String getSelectedText() {
    if (isSelectionCollapsed()) {
      return "";
    }
    int start = Math.min(selectionStart, selectionEnd);
    int end = Math.max(selectionStart, selectionEnd);
    return text.substring(start, end);
  }

  /**
   * Gets the composing text
   *
   * @return The substring of composing text, or empty string if no composing
   */
  @NonNull
  public String getComposingText() {
    if (!hasComposing()) {
      return "";
    }
    int start = Math.min(composingStart, composingEnd);
    int end = Math.max(composingStart, composingEnd);
    return text.substring(start, end);
  }

  @NonNull
  @Override
  public String toString() {
    return "TextEditState{" +
        "text='" + text + '\'' +
        ", selectionStart=" + selectionStart +
        ", selectionEnd=" + selectionEnd +
        ", composingStart=" + composingStart +
        ", composingEnd=" + composingEnd +
        '}';
  }

  /**
   * Gets a detailed string representation for debugging
   *
   * @return Detailed debug string
   */
  @NonNull
  public String toDebugString() {
    return "TextEditState{" +
        "text='" + text + '\'' +
        ", textLength=" + getTextLength() +
        ", selectionStart=" + selectionStart +
        ", selectionEnd=" + selectionEnd +
        ", selectionLength=" + getSelectionLength() +
        ", isSelectionCollapsed=" + isSelectionCollapsed() +
        ", selectedText='" + getSelectedText() + '\'' +
        ", composingStart=" + composingStart +
        ", composingEnd=" + composingEnd +
        ", composingLength=" + getComposingLength() +
        ", hasComposing=" + hasComposing() +
        ", composingText='" + getComposingText() + '\'' +
        '}';
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;

    TextEditState that = (TextEditState) o;

    if (selectionStart != that.selectionStart) return false;
    if (selectionEnd != that.selectionEnd) return false;
    if (composingStart != that.composingStart) return false;
    if (composingEnd != that.composingEnd) return false;
    return text.equals(that.text);
  }

  @Override
  public int hashCode() {
    int result = text.hashCode();
    result = 31 * result + selectionStart;
    result = 31 * result + selectionEnd;
    result = 31 * result + composingStart;
    result = 31 * result + composingEnd;
    return result;
  }
}