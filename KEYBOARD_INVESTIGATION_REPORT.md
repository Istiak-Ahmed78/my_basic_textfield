# Flutter Keyboard Hide/Reappear Issue - Complete Investigation Report

## Executive Summary

This report investigates the keyboard hide/reappear issue in the Flutter text input framework, specifically addressing why the keyboard doesn't reappear on the second tap after being hidden via back press.

**Status**: Issue identified and partially addressed with a platform-side workaround.

---

## The Issue

### Observed Behavior
1. **First tap**: Keyboard appears OK
2. **Back press**: Keyboard is hidden OK
3. **Second tap**: Keyboard does NOT reappear FAIL
4. **Observation**: `_handleFocusChanged` is NOT called on second tap

### Root Causes

After thorough investigation, there are TWO layers of issues:

#### 1. Platform Layer (Android) - PRIMARY ISSUE

**Where it happens**: `TextInputPlugin.java::clearTextInputClient()` and `showTextInput()`

**What happens**:

First Tap:
- Flutter: Calls setClient() with configuration
- Android: Stores configuration, sets inputTarget = FRAMEWORK_CLIENT
- Flutter: Calls show()
- Android: showTextInput() checks if configuration != null OK -> Shows keyboard

Back Press (Keyboard Hidden):
- Android IME hides keyboard
- Flutter: Calls clearClient()
- Android: Sets configuration = null AND inputTarget = NO_TARGET

Second Tap:
- Flutter/Android: Text field still has focus (focus was not lost)
- Flutter: Does NOT call setClient() (field still has focus)
- Flutter: Only calls show()
- Android: showTextInput() checks if configuration != null FAIL -> SKIPS
- Result: Keyboard doesn't appear

**The Bug**: When clearClient() sets configuration = null, the subsequent show() call finds no configuration and exits early.

#### 2. Flutter Framework Layer - SECONDARY ISSUE

**Where it happens**: EditableText widget focus/keyboard lifecycle

When the Android keyboard is hidden via back press:
- Android framework calls clearClient() on the platform side
- BUT the Flutter side doesn't receive notification that focus should be lost
- So _handleFocusChanged() is never triggered
- The field appears to still "have focus" to Flutter
- Therefore, on second tap, _handleFocusChanged() doesn't fire because focus already == true

---

## Investigation Answers

### Question 1: Does hide() or clearClient() get called when keyboard is hidden?

**Answer**: clearClient() is called.

**Evidence from code flow**:

When user presses Back button (Android):
- Android IME starts closing
- Android system calls TextInputChannel.clearClient()
- This calls TextInputPlugin.clearTextInputClient()
  - Sets configuration = null
  - Sets inputTarget = NO_TARGET

### Question 2: Does EditableText lose focus automatically when keyboard is hidden?

**Answer**: NO. The field does NOT lose focus automatically.

**Evidence**:
- FocusNode.hasFocus remains true even after keyboard is hidden
- No mechanism automatically calls FocusNode.unfocus() when IME hides
- This is a Flutter limitation: IME state and focus state are decoupled
- Android can hide the keyboard without Flutter knowing about it

### Question 3: Why would _handleFocusChanged NOT be called on second tap?

**Answer**: Because focus never changed.

**Sequence**:

First Tap:
- hasFocus: false -> hasFocus: true
- _handleFocusChanged() called OK

Back Press (Keyboard hidden):
- hasFocus: true -> hasFocus: still true
- _handleFocusChanged() NOT called (no change)

Second Tap:
- hasFocus: still true -> hasFocus: still true
- _handleFocusChanged() NOT called (no change) FAIL

Result: _openInputConnection() is never triggered

### Question 4: Is there a mechanism to detect when IME is hidden and trigger show() again?

**Answer**: Not in the standard Flutter framework.

**Investigation findings**:
- No automatic IME hide detection mechanism in Flutter's EditableText
- No callback when clearClient() is called on platform side
- No system broadcast about keyboard visibility change
- The framework treats "keyboard hidden" as an operational detail, not a focus event

### Question 5: Could the issue be that the field doesn't actually lose focus?

**Answer**: YES, this is exactly the issue.

**Evidence from logs and code**:
- Field maintains focus state throughout
- When field is tapped again, FocusNode.requestFocus() has no effect (already focused)
- No connection reopening occurs
- No configuration is sent to platform

---

## The Solution Applied

### Fix Location: Android Platform Layer

**File**: android/src/main/java/com/example/my_basic_textfield/editing/TextInputPlugin.java
**Method**: clearTextInputClient() (lines 573-592)

### What Was Changed

BEFORE:
```
void clearTextInputClient() {
    mEditable.removeEditingStateListener(this);
    configuration = null;  // REMOVED THIS LINE
    inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
    unlockPlatformViewInputConnection();
    lastClientRect = null;
}
```

AFTER:
```
void clearTextInputClient() {
    mEditable.removeEditingStateListener(this);
    // FIX: Don't clear configuration - keep it for reuse on second tap
    // configuration = null;  // COMMENTED OUT
    inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
    unlockPlatformViewInputConnection();
    lastClientRect = null;
}
```

### Why This Works

First Tap:
- setClient(config) called -> configuration stored OK
- show() called -> keyboard shown OK

Back Press:
- clearClient() called -> configuration KEPT, inputTarget = NO_TARGET

Second Tap:
- show() called (setClient NOT called because focus unchanged)
- showTextInput() checks if configuration != null OK
- Keyboard shown again OK

---

## Root Cause Analysis: Why is Configuration Set to NULL?

### Original Design Intent

Setting configuration = null in clearTextInputClient() was likely intended to:
1. Signal that no active input client exists
2. Free up memory
3. Force a fresh setClient() call for new connections

### The Problem with This Approach

In the actual keyboard lifecycle, this breaks because:
- The "same connection" (same field) may need to show keyboard again without setClient()
- Android's keyboard hide is an IME action, not a connection closure
- Configuration is field-specific, not connection-specific

---

## Answers Summary

| Question | Answer |
|----------|--------|
| Does hide() or clearClient() get called? | clearClient() is called |
| Does EditableText lose focus automatically? | NO - This is the core issue |
| Why isn't _handleFocusChanged called on 2nd tap? | Focus state didn't change (true -> true) |
| Is there a mechanism to detect IME hide? | No, not in standard Flutter |
| Doesn't the field lose focus on keyboard hide? | NO, and this is the problem |

---

## The Bottom Line

### What Actually Happens
1. Focus and keyboard are independent in Android
2. Keyboard can hide without focus changing (user presses back)
3. Flutter doesn't get notified of IME closure
4. On second tap, no focus change occurs, so no reconnection happens
5. Platform side clears configuration, breaking the show() call

### The Fix Applied
Keep configuration in memory even after keyboard hides. This allows show() to work on subsequent calls without waiting for setClient().

### Limitations
- Doesn't solve the underlying "Flutter unaware of IME state" issue
- Is a workaround, not a complete solution
- Would need cross-platform notifications for full fix

---

Generated: April 2, 2026
Status: Investigation Complete
Fix Status: Platform-side workaround implemented (Partial solution)
