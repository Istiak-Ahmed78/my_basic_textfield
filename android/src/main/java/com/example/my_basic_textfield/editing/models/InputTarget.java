package com.example.my_basic_textfield.editing.models;

import androidx.annotation.NonNull;

/**
 * Represents the target of text input.
 * 
 * This class identifies which widget or platform view is currently
 * receiving text input from the keyboard.
 */
public class InputTarget {
  /**
   * Types of input targets
   */
  public enum Type {
    /**
     * No target is currently focused
     */
    NO_TARGET,

    /**
     * A Flutter framework widget (EditableText) is focused
     */
    FRAMEWORK_CLIENT,

    /**
     * A platform view with virtual display is focused
     */
    VIRTUAL_DISPLAY_PLATFORM_VIEW,

    /**
     * A platform view with physical display is focused
     */
    PHYSICAL_DISPLAY_PLATFORM_VIEW,
  }

  /**
   * The type of input target
   */
  @NonNull
  public Type type;

  /**
   * The ID of the input target
   * - For FRAMEWORK_CLIENT: the client ID from Flutter
   * - For platform views: the platform view ID
   * - For NO_TARGET: unused (0)
   */
  public int id;

  /**
   * Creates a new InputTarget
   *
   * @param type The type of input target
   * @param id   The ID of the input target
   */
  public InputTarget(@NonNull Type type, int id) {
    this.type = type;
    this.id = id;
  }

  /**
   * Checks if this target is a framework client
   *
   * @return true if type is FRAMEWORK_CLIENT
   */
  public boolean isFrameworkClient() {
    return type == Type.FRAMEWORK_CLIENT;
  }

  /**
   * Checks if this target is a platform view
   *
   * @return true if type is a platform view
   */
  public boolean isPlatformView() {
    return type == Type.VIRTUAL_DISPLAY_PLATFORM_VIEW
        || type == Type.PHYSICAL_DISPLAY_PLATFORM_VIEW;
  }

  /**
   * Checks if this target is active (not NO_TARGET)
   *
   * @return true if type is not NO_TARGET
   */
  public boolean isActive() {
    return type != Type.NO_TARGET;
  }

  @NonNull
  @Override
  public String toString() {
    return "InputTarget{" +
        "type=" + type +
        ", id=" + id +
        '}';
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;

    InputTarget that = (InputTarget) o;

    if (id != that.id) return false;
    return type == that.type;
  }

  @Override
  public int hashCode() {
    int result = type.hashCode();
    result = 31 * result + id;
    return result;
  }
}




