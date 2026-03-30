package com.example.my_basic_textfield.editing.models;

import androidx.annotation.Nullable;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;

/**
 * Configuration for text input from Flutter.
 * 
 * This class holds all the configuration parameters that Flutter sends
 * to the native side to configure how the keyboard should behave.
 * 
 * Examples:
 * - Input type (text, number, email, etc.)
 * - Input action (done, send, next, etc.)
 * - Whether text should be obscured (password field)
 * - Autocorrect settings
 * - Text capitalization
 */
public class InputConfiguration {
  /**
   * The type of input (text, number, email, phone, etc.)
   * 
   * Example: TextInputType.text, TextInputType.number
   */
  @Nullable
  public TextInputChannel.InputType inputType;

  /**
   * The action to perform when user presses the action button on keyboard
   * 
   * Example: EditorInfo.IME_ACTION_DONE, EditorInfo.IME_ACTION_SEND
   */
  @Nullable
  public Integer inputAction;

  /**
   * Whether the text should be obscured (for passwords)
   * 
   * When true, the keyboard will hide the typed characters.
   * Default: false
   */
  public boolean obscureText;

  /**
   * Whether autocorrect should be enabled
   * 
   * When true, the keyboard will suggest corrections.
   * Default: true
   */
  public boolean autocorrect;

  /**
   * Whether suggestions should be enabled
   * 
   * When true, the keyboard will show word suggestions.
   * Default: true
   */
  public boolean enableSuggestions;

  /**
   * Whether IME personalized learning should be enabled
   * 
   * When true, the keyboard can learn from user input.
   * Default: true
   */
  public boolean enableIMEPersonalizedLearning;

  /**
   * Text capitalization mode
   * 
   * Example: TextCapitalization.none, TextCapitalization.sentences
   */
  @Nullable
  public TextInputChannel.TextCapitalization textCapitalization;

  /**
   * Custom label for the action button
   * 
   * If set, this replaces the default action button label.
   * Example: "Send", "Search", "Go"
   */
  @Nullable
  public String actionLabel;

  /**
   * Creates a new InputConfiguration with all parameters
   *
   * @param inputType                         The type of input
   * @param inputAction                       The action button behavior
   * @param obscureText                       Whether to hide typed text
   * @param autocorrect                       Whether to enable autocorrect
   * @param enableSuggestions                 Whether to show suggestions
   * @param enableIMEPersonalizedLearning     Whether IME can learn
   * @param textCapitalization                How to capitalize text
   * @param actionLabel                       Custom action button label
   */
  public InputConfiguration(
      @Nullable TextInputChannel.InputType inputType,
      @Nullable Integer inputAction,
      boolean obscureText,
      boolean autocorrect,
      boolean enableSuggestions,
      boolean enableIMEPersonalizedLearning,
      @Nullable TextInputChannel.TextCapitalization textCapitalization,
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

  /**
   * Creates a basic InputConfiguration with default values
   *
   * @param inputType The type of input
   */
  public InputConfiguration(@Nullable TextInputChannel.InputType inputType) {
    this(
        inputType,
        null,
        false,
        true,
        true,
        true,
        TextInputChannel.TextCapitalization.NONE,
        null);
  }

  /**
   * Checks if this is a password field
   *
   * @return true if obscureText is true
   */
  public boolean isPasswordField() {
    return obscureText;
  }

  /**
   * Checks if this is a multiline input
   *
   * @return true if inputType is multiline
   */
  public boolean isMultiline() {
    return inputType != null
        && inputType.type == TextInputChannel.TextInputType.MULTILINE;
  }

  /**
   * Checks if this is a number input
   *
   * @return true if inputType is number
   */
  public boolean isNumberInput() {
    return inputType != null
        && inputType.type == TextInputChannel.TextInputType.NUMBER;
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