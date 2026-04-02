# Android Logging Quick Reference

## Super Quick Summary

**3 Critical Points to Check in Logs:**

### 1. Does `setClient()` appear in logs?
```
🔊 TextInputMethodHandler.setClient() called
  - textInputClientId: 1
  - configuration: InputConfiguration(...)
```
**If NOT present**: Handler never called → channels setup is wrong

---

### 2. Is `configuration` NOT NULL when `showTextInput()` is called?
```
🔍 showTextInput() called
  - Current configuration: InputConfiguration(...) ✅ GOOD
  
vs.

❌ ERROR: configuration is NULL - cannot show keyboard!
```
**If NULL**: setClient() was never called before show()

---

### 3. Does `createInputConnection()` get called?
```
🔍 createInputConnection() called
  - configuration: InputConfiguration(...) ✅ EXISTS
✅ InputConnection created successfully
```
**If NOT called or configuration NULL**: Android IME can't create proper connection

---

## Log Grep Commands

### See ALL keyboard-related logs:
```bash
adb logcat | grep -E "setClient|showTextInput|configuration|createInputConnection"
```

### See ONLY errors:
```bash
adb logcat | grep "❌\|ERROR"
```

### See flow step-by-step:
```bash
adb logcat | grep -E "═══|🔧|🔊|✅|❌"
```

---

## Most Common Issue

```
❌ ERROR: configuration is NULL - cannot show keyboard!
```

**Root Cause**: `setClient()` handler is registered on a **NEW** TextInputChannel  
instead of Flutter's **ACTUAL** system channel.

**Location to fix**: `MyBasicTextfieldPlugin.java` lines 155-156
```java
// WRONG - Creating new channels
textInputChannel = new TextInputChannel(flutterEngine.getDartExecutor());
scribeChannel = new ScribeChannel(flutterEngine.getDartExecutor());
```

**Should be**: Get Flutter's actual channels from the engine

---

## Timeline: What You'll See

```
App starts (5 seconds)
    ↓
[ANDROID_LOGGING_GUIDE.md shows "INITIALIZING TEXTINPUTPLUGIN"]
    ↓
You tap text field
    ↓
[Should see "setClient() called"]
[Should see "configuration stored"]
[Should see "InputConnection created"]
    ↓
[Should see "showTextInput() called"]
[Should see "Keyboard show requested!"]
    ↓
Keyboard appears (if all above are green ✅)
```

---

## Color Guide

- 🔧 = Setup/initialization
- 🔊 = Handler being called
- 🔍 = Inspection point
- ✏️  = Text input
- ✅ = Success (good!)
- ❌ = Error (bad!)
- 📢 = Important transition
- ⏭️ = Skipping something

---

## File Locations

| Component | File |
|-----------|------|
| Plugin entry | `android/src/main/java/.../MyBasicTextfieldPlugin.java` |
| Keyboard logic | `android/src/main/java/.../editing/TextInputPlugin.java` |
| Text input | `android/src/main/java/.../editing/InputConnectionAdaptor.java` |

---

## Key Methods to Watch

| Method | File | What It Does |
|--------|------|-------------|
| `initializeTextInputPlugin()` | MyBasicTextfieldPlugin | Creates channels & TextInputPlugin |
| `setClient()` | TextInputPlugin | **Receives config from Flutter** (CRITICAL) |
| `showTextInput()` | TextInputPlugin | Shows the keyboard |
| `createInputConnection()` | TextInputPlugin | Android IME calls this for connection |
| `commitText()` | InputConnectionAdaptor | Receives text from keyboard |

---

## Success = This Message Appears

```
✅ Keyboard show requested!
```

Then keyboard actually appears on screen.

---

## Failure = This Message Appears

```
❌ ERROR: configuration is NULL - cannot show keyboard!
```

Then keyboard does NOT appear.

---

## Next Fix Location

Once logs confirm `setClient()` is never called:

**File**: `android/src/main/java/com/example/my_basic_textfield/MyBasicTextfieldPlugin.java`  
**Lines**: 155-156  
**Issue**: Creating new channels instead of using Flutter's system channels

**Fix**: Need to access Flutter's actual TextInputChannel from the engine
