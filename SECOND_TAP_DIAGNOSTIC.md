# Second Tap Issue - Diagnostic Guide

## The Problem
- **First tap**: Keyboard appears ✅
- **After back/hide**: Keyboard hidden
- **Second tap**: Keyboard does NOT reappear ❌

## What We're Looking For

Run the app and perform these steps:
1. Tap text field (first time)
2. Watch for logs showing: `setClient()`, `show()`, keyboard appears
3. Press back to hide keyboard
4. Tap text field again (second time)
5. Look for these critical logs:

### Log Sequence - First Tap (Should Work)
```
🔊 setClient() called - clientId=1
🔧 setTextInputClient() - clientId=1, has config=true
✅ setTextInputClient() complete - config set, input restarted
🔊 show() called - configuration: SET, inputTarget: FRAMEWORK_CLIENT
📊 showTextInput() - config=SET, target=FRAMEWORK_CLIENT
✅ showSoftInput() called
```

### Log Sequence - After Back Press (Watch for clearClient())
```
🔊 clearClient() called - configuration will be cleared
  - Current configuration: InputConfiguration(...)
  - Current inputTarget: InputTarget{type=FRAMEWORK_CLIENT, id=1}
  - Configuration after clear: null
  - InputTarget after clear: InputTarget{type=NO_TARGET, id=0}
```

### Critical: Second Tap Log Sequence
```
Expected:
  🔊 setClient() called - clientId=1  ← Should happen again
  🔧 setTextInputClient() ...
  
But if we see:
  🔊 show() called - configuration: NULL  ← BAD! Configuration is null
  📊 showTextInput() - config=NULL
  ❌ Cannot show keyboard - configuration is NULL  ← THIS IS THE BUG!
```

## The Hypothesis

**What's likely happening:**
1. When keyboard is hidden (back press), `clearClient()` is called
2. This sets `configuration = null` and `inputTarget = NO_TARGET`
3. When you tap the second time:
   - Flutter's EditableText already has focus, so focus event doesn't trigger
   - Flutter may not call `setClient()` again
   - Flutter just calls `show()` directly
   - But `configuration` is still `null`
   - So `showTextInput()` returns early without showing keyboard

## The Fix (Hypothesis)

The solution might be one of these:

### Option A: Don't fully clear configuration
Instead of setting configuration to null in `clearClient()`, preserve it:
```java
void clearTextInputClient() {
  // Don't clear configuration!
  // configuration stays available for next show()
  inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
  // ... rest of cleanup
}
```

### Option B: Recreate connection on show() if missing
In `showTextInput()`, check if configuration is null but focus is active:
```java
void showTextInput(View view) {
  if (configuration == null && inputTarget.type == InputTarget.Type.NO_TARGET) {
    // Need to create a new connection
    // But we don't have the client info...
  }
}
```

### Option C: Handle the lifecycle differently
Keep track of whether the connection was closed and needs recreation.

## What to Do When Logs Show the Issue

1. **Take a screenshot of the relevant logs** showing the second tap sequence
2. **Look specifically for:**
   - Is `setClient()` being called on second tap?
   - Is `configuration` null when `show()` is called?
   - What is `inputTarget` when second tap happens?

3. **Send the logs showing:**
   - First tap (working): setClient() → show() → keyboard appears ✅
   - Back press: clearClient() called ← configuration set to null
   - Second tap (broken): show() called → configuration is NULL → cannot show keyboard ❌

## Key Log Tags to Watch

- `🔊` = Handler method called
- `🔧` = setTextInputClient/Connection setup
- `🔌` = clearClient/cleanup
- `❌` = Error condition

## The Real Question

Will we see one of these on the second tap?

**A)** `🔊 setClient() called` - Flutter is resetting the client
**B)** `🔊 show() called` with config=NULL - Flutter just calling show, config already null
**C)** No platform logs at all - Flutter is handling it differently on second tap

The logs will tell us which one it is!
