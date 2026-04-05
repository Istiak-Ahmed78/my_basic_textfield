package com.example.my_basic_textfield.editing.models;

import androidx.annotation.NonNull;

public class TextEditState {
  @NonNull
  public final String text;

  public final int selectionStart;

  public final int selectionEnd;

  public final int composingStart;

  public final int composingEnd;

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

  public TextEditState(@NonNull String text) {
    this(text, 0, 0, -1, -1);
  }

  public TextEditState() {
    this("", 0, 0, -1, -1);
  }

  public boolean hasComposing() {
    return composingStart >= 0 && composingEnd >= 0;
  }

  public boolean isSelectionCollapsed() {
    return selectionStart == selectionEnd;
  }

  public int getSelectionLength() {
    return Math.abs(selectionEnd - selectionStart);
  }

  public int getComposingLength() {
    if (!hasComposing()) {
      return 0;
    }
    return Math.abs(composingEnd - composingStart);
  }

  public int getTextLength() {
    return text.length();
  }

  public boolean isAtBeginning() {
    return selectionStart == 0;
  }

  public boolean isAtEnd() {
    return selectionStart == text.length();
  }

  @NonNull
  public String getSelectedText() {
    if (isSelectionCollapsed()) {
      return "";
    }
    int start = Math.min(selectionStart, selectionEnd);
    int end = Math.max(selectionStart, selectionEnd);
    return text.substring(start, end);
  }

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