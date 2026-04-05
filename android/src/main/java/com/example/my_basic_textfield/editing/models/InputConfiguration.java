package com.example.my_basic_textfield.editing.models;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class InputConfiguration {
  // Define our own InputType enum (decoupled from Flutter)
  public enum InputType {
    TEXT,
    MULTILINE,
    NUMBER,
    EMAIL_ADDRESS,
    PHONE,
    URL,
    DATETIME,
    VISIBLE_PASSWORD,
    NAME,
    POSTAL_ADDRESS,
    TWITTER,
    WEB_SEARCH,
    NONE
  }

  // Define our own TextCapitalization enum
  public enum TextCapitalization {
    NONE,
    CHARACTERS,
    WORDS,
    SENTENCES
  }

  @Nullable
  public InputType inputType;

  @Nullable
  public Integer inputAction;

  public boolean obscureText;

  public boolean autocorrect;

  public boolean enableSuggestions;

  public boolean enableIMEPersonalizedLearning;

  @Nullable
  public TextCapitalization textCapitalization;

  @Nullable
  public String actionLabel;

  // Full constructor
  public InputConfiguration(
      @Nullable InputType inputType,
      @Nullable Integer inputAction,
      boolean obscureText,
      boolean autocorrect,
      boolean enableSuggestions,
      boolean enableIMEPersonalizedLearning,
      @Nullable TextCapitalization textCapitalization,
      @Nullable String actionLabel) {
    this.inputType = inputType;
    this.inputAction = inputAction;
    this.obscureText = obscureText;
    this.autocorrect = autocorrect;
    this.enableSuggestions = enableSuggestions;
    this.enableIMEPersonalizedLearning = enableIMEPersonalizedLearning;
    this.textCapitalization = textCapitalization;
    this.actionLabel = actionLabel;
  }

  // Convenience constructor with just input type
  public InputConfiguration(@Nullable InputType inputType) {
    this(
        inputType,
        null,
        false,
        true,
        true,
        true,
        TextCapitalization.NONE,
        null);
  }

  // Default constructor
  public InputConfiguration() {
    this(InputType.TEXT);
  }

  // Helper methods
  public boolean isPasswordField() {
    return obscureText;
  }

  public boolean isMultiline() {
    return inputType == InputType.MULTILINE;
  }

  public boolean isNumberInput() {
    return inputType == InputType.NUMBER;
  }

  public boolean isEmailInput() {
    return inputType == InputType.EMAIL_ADDRESS;
  }

  public boolean isPhoneInput() {
    return inputType == InputType.PHONE;
  }

  public boolean isUrlInput() {
    return inputType == InputType.URL;
  }

  @NonNull
  @Override
  public String toString() {
    return "InputConfiguration{" +
        "inputType=" + inputType +
        ", inputAction=" + inputAction +
        ", obscureText=" + obscureText +
        ", autocorrect=" + autocorrect +
        ", enableSuggestions=" + enableSuggestions +
        ", enableIMEPersonalizedLearning=" + enableIMEPersonalizedLearning +
        ", textCapitalization=" + textCapitalization +
        ", actionLabel='" + actionLabel + '\'' +
        '}';
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;

    InputConfiguration that = (InputConfiguration) o;

    if (obscureText != that.obscureText) return false;
    if (autocorrect != that.autocorrect) return false;
    if (enableSuggestions != that.enableSuggestions) return false;
    if (enableIMEPersonalizedLearning != that.enableIMEPersonalizedLearning) return false;
    if (inputType != that.inputType) return false;
    if (inputAction != null ? !inputAction.equals(that.inputAction) : that.inputAction != null)
      return false;
    if (textCapitalization != that.textCapitalization) return false;
    return actionLabel != null ? actionLabel.equals(that.actionLabel) : that.actionLabel == null;
  }

  @Override
  public int hashCode() {
    int result = inputType != null ? inputType.hashCode() : 0;
    result = 31 * result + (inputAction != null ? inputAction.hashCode() : 0);
    result = 31 * result + (obscureText ? 1 : 0);
    result = 31 * result + (autocorrect ? 1 : 0);
    result = 31 * result + (enableSuggestions ? 1 : 0);
    result = 31 * result + (enableIMEPersonalizedLearning ? 1 : 0);
    result = 31 * result + (textCapitalization != null ? textCapitalization.hashCode() : 0);
    result = 31 * result + (actionLabel != null ? actionLabel.hashCode() : 0);
    return result;
  }
}