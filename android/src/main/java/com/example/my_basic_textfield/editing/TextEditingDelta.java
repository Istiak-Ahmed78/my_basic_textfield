package com.example.my_basic_textfield.editing;

import androidx.annotation.NonNull;

public class TextEditingDelta {
  private static final String TAG = "TextEditingDelta";

  private final int oldStart;

  private final int oldEnd;

  private final String replacementText;

  public TextEditingDelta(int oldStart, int oldEnd, String replacementText) {
    this.oldStart = oldStart;
    this.oldEnd = oldEnd;
    this.replacementText = replacementText != null ? replacementText : "";
  }

  public int getOldStart() {
    return oldStart;
  }

  public int getOldEnd() {
    return oldEnd;
  }

  public String getReplacementText() {
    return replacementText;
  }

  public int getDeletedCount() {
    return oldEnd - oldStart;
  }

  public int getInsertedCount() {
    return replacementText.length();
  }

  public int getNetChange() {
    return getInsertedCount() - getDeletedCount();
  }

  public boolean isInsertion() {
    return oldStart == oldEnd;
  }

  public boolean isDeletion() {
    return replacementText.isEmpty();
  }

  public boolean isReplacement() {
    return !isInsertion() && !isDeletion();
  }

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