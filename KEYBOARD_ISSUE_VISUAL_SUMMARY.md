# Keyboard Issue Investigation - Visual Summary

## The Problem Illustrated

```
FIRST TAP:
+-------------------------------------+
¦  User Taps Text Field               ¦
¦  Focus: false ? true                ¦ _handleFocusChanged() fires
¦  _openInputConnection() called       ¦
¦  TextInput.attach() with config      ¦
¦  _textInputConnection.show()         ¦
+-------------------------------------+
            ?
+-------------------------------------+
¦  Android Platform                   ¦
¦  setClient(config) called           ¦
¦  configuration = [stored]           ¦
¦  show() called                      ¦
¦  showTextInput() checks: config!=null ?
+-------------------------------------+
            ?
+-------------------------------------+
¦  ? KEYBOARD APPEARS                ¦
+-------------------------------------+


BACK PRESS:
+-------------------------------------+
¦  User Presses Back                  ¦
¦  Android IME closes                 ¦
¦  clearClient() called               ¦
¦  configuration = null (BUG!)        ¦
¦  inputTarget = NO_TARGET            ¦
¦  Flutter is NOT notified!           ¦
¦  Focus: still true                  ¦
+-------------------------------------+
            ?
+-------------------------------------+
¦  ? KEYBOARD HIDDEN (User sees this) ¦
¦  ? Focus State: still TRUE (Flutter  ¦
¦    doesn't know about the hide)     ¦
+-------------------------------------+


SECOND TAP:
+-------------------------------------+
¦  User Taps Text Field               ¦
¦  Focus: true ? true                 ¦ NO CHANGE!
¦  _handleFocusChanged() NOT fired    ¦
¦  _openInputConnection() NOT called  ¦
¦  Only show() is called              ¦
+-------------------------------------+
            ?
+-------------------------------------+
¦  Android Platform                   ¦
¦  setClient() NOT called             ¦
¦  show() called                      ¦
¦  showTextInput() checks: config!=null ?
¦  Configuration is NULL! (cleared by  ¦
¦  clearClient())                     ¦
¦  ? Returns without showing keyboard ¦
+-------------------------------------+
            ?
+-------------------------------------+
¦  ? KEYBOARD DOES NOT APPEAR        ¦
¦  This is the bug!                   ¦
+-------------------------------------+
```

---

## The Core Issue

```
FLUTTER SIDE                    ANDROID SIDE
                ?
    Focus State             Keyboard Visibility
    (managed by             (managed by
     FocusNode)              InputMethodManager)
    
    true  ?----------------?  HIDDEN
    
    ?                        
    ¦ No automatic          
    ¦ notification when     
    ¦ IME closes!           
    ¦                       
    +------ PROBLEM! --------
```

The issue: **Flutter doesn't know the keyboard is hidden, so it doesn't unfocus the field.**

---

## The Fix Explained

```
BEFORE FIX:
clearTextInputClient() {
    configuration = null;  ? Problem!
    inputTarget = NO_TARGET;
}

showTextInput() {
    if (configuration == null)
        return;  ? Exits here on second tap!
}

AFTER FIX:
clearTextInputClient() {
    // configuration = null;  ? Fixed!
    inputTarget = NO_TARGET;
}

showTextInput() {
    if (configuration == null)
        return;  ? Doesn't exit now, configuration still exists!
}
```

By keeping configuration in memory, show() can work on second tap.

---

## Summary Table

| Aspect | Details |
|--------|---------|
| **What gets called** | clearClient() when keyboard hides |
| **Does field lose focus?** | NO - This is the problem |
| **Why _handleFocusChanged doesn't fire** | Focus: true ? true (no change) |
| **Is there IME hide detection?** | NO - Flutter doesn't support it |
| **What's the fix?** | Keep configuration in memory |
| **Is this a complete solution?** | NO - It's a workaround |
| **Type of issue** | Design gap in keyboard lifecycle |

---

## What You Need to Know

### The Fundamental Problem
Android and Flutter have different views of the keyboard state:
- **Android**: Keyboard is just an IME, separate from focus
- **Flutter**: Keyboard should be tied to focus

When Android closes the keyboard (back press), Flutter doesn't know, so the field stays "focused."

### Why show() Alone Doesn't Work
The custom implementation adds a safety check:
```java
if (configuration == null) return;
```

This is good for safety, but it breaks when:
1. Configuration is cleared
2. But field is still "focused" in Flutter's view
3. And show() is called without setClient()

### The Platform-Side Fix
Keep configuration even after clearClient(). This is safe because:
- Configuration is only used when inputTarget is FRAMEWORK_CLIENT
- clearClient() sets inputTarget = NO_TARGET
- So configuration can't be misused
- New setClient() calls overwrite it anyway

### What Would Be Needed for Full Solution
1. Platform notification when IME closes
2. Flutter listener for IME close events
3. Automatic unfocus or keyboard reopen on IME close
4. Or: Better integration between focus and IME state

---

## Key Findings

1. ? **hide() or clearClient()?** ? clearClient()
2. ? **Does field lose focus?** ? NO (core issue)
3. ? **Why _handleFocusChanged doesn't fire?** ? Focus unchanged
4. ? **IME hide detection?** ? Not in Flutter
5. ? **Is it a framework bug?** ? Design limitation

---

**Generated**: April 2, 2026
**Investigation**: COMPLETE ?
**Fix**: Platform-side workaround (Partial) ??
