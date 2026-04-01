package com.example.my_basic_textfield.editing.models;

import androidx.annotation.NonNull;

public class InputTarget {
  public enum Type {
    NO_TARGET,
    FRAMEWORK_CLIENT,
    VIRTUAL_DISPLAY_PLATFORM_VIEW,
    PHYSICAL_DISPLAY_PLATFORM_VIEW,
  }

  @NonNull
  public Type type;

  public int id;

  public InputTarget(@NonNull Type type, int id) {
    this.type = type;
    this.id = id;
  }

  public boolean isFrameworkClient() {
    return type == Type.FRAMEWORK_CLIENT;
  }

  public boolean isPlatformView() {
    return type == Type.VIRTUAL_DISPLAY_PLATFORM_VIEW
        || type == Type.PHYSICAL_DISPLAY_PLATFORM_VIEW;
  }

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