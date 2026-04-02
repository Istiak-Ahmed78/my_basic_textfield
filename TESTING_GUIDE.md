# Testing Guide - Keyboard Reappear Fix

## Quick Test

### Test 1: Basic Second Tap Fix
**Expected**: Keyboard reappears on second tap after back press

1. Run the app
2. Tap the text field → Keyboard appears
3. Press Android back button → Keyboard hides
4. Tap the text field again → **Keyboard should now appear** ✅

## Detailed Test Scenarios

### Test 2: Multiple Cycles
**Expected**: Keyboard works consistently across multiple hide/show cycles

1. Tap field → Keyboard shows
2. Press back → Keyboard hides
3. Tap field → Keyboard shows
4. Press back → Keyboard hides
5. Tap field → Keyboard shows
6. **Result**: All cycles should work ✅

### Test 3: Focus Loss vs Back Press
**Expected**: Different behaviors are handled correctly

1. Tap field → Keyboard shows
2. Tap outside field → Focus lost → Keyboard hides (normal)
3. Tap field → Keyboard shows (new connection created)
4. Press back → Keyboard hides (configuration cleared)
5. Tap field → Keyboard shows (new connection created) ✅

### Test 4: Text Editing
**Expected**: Text can be edited normally throughout

1. Tap field → Keyboard shows
2. Type some text → Text appears in field ✅
3. Press back → Keyboard hides
4. Tap field → Keyboard shows
5. Continue typing → More text appears ✅

### Test 5: Programmatic Hide/Show
**Expected**: Programmatic calls work correctly

If your example app has buttons for hide/show keyboard:
1. Tap field → Keyboard shows
2. Tap "Hide Keyboard" button → Keyboard hides
3. Tap "Show Keyboard" button → Keyboard shows
4. **Result**: Both should work ✅

## Log Verification

### What to Look For in Logs

**On Android Logcat:**
```
TextInputPlugin: clearTextInputClient: configuration cleared, ready for reconnection
```

**In Flutter Debug Output:**
Look for this pattern on second tap:
```
⌨️ ========== _showKeyboard() ==========
📊 _hasInputConnection: true
📊 _textInputConnection: Instance of 'TextInputConnection'
📞 Connection not attached to platform - Opening new connection
   - Clearing stale connection: 1
🔌 ========== _openInputConnection() ==========
📞 Creating new input connection...
✅ TextInput.attach() completed
   - Connection: Instance of 'TextInputConnection'
   - Connection ID: 2
```

**Key Indicators:**
- Different connection IDs (id=1 then id=2) = new connection created ✅
- "Connection not attached to platform" log = stale connection detected ✅
- "configuration cleared" on back press = platform state managed correctly ✅

## Performance Verification

### Memory
- No memory leaks from stale connection objects
- Old connection is garbage collected after new one is created
- App memory should be stable across multiple tap cycles

### Responsiveness
- Keyboard appears quickly on second tap (similar to first tap)
- No noticeable delay

## Edge Cases to Test

### Edge Case 1: Rapid Taps
**Scenario**: User rapidly taps field multiple times

1. Tap field
2. Press back immediately (before keyboard fully appears)
3. Tap field multiple times rapidly
4. **Expected**: Keyboard should appear on one of the taps ✅

### Edge Case 2: Hide with onTap
**Scenario**: Tap field while another operation is hiding keyboard

1. Tap field → Keyboard shows
2. Hide keyboard programmatically
3. Immediately tap field again
4. **Expected**: Keyboard shows after the hide completes ✅

### Edge Case 3: Configuration State
**Scenario**: Verify platform configuration state is correct

1. Tap field → Keyboard shows
2. Check Android: configuration should not be null
3. Press back → Keyboard hides
4. Check Android logs: configuration should be null
5. Tap field → Keyboard shows
6. Check Android: new configuration should be set (not null) ✅

## Regression Testing

Make sure existing functionality still works:

### Test 6: Single Field
- [ ] Tap field → Keyboard shows
- [ ] Type text → Text appears
- [ ] Delete text → Text removed
- [ ] Unfocus → Keyboard hides

### Test 7: Multiple Fields
- [ ] Focus field 1 → Keyboard shows
- [ ] Focus field 2 → Keyboard switches
- [ ] Focus field 1 → Keyboard switches back
- [ ] Press back → Keyboard hides
- [ ] Tap field 2 → Keyboard shows for field 2 ✅

### Test 8: Read-Only Field
- [ ] Create read-only field
- [ ] Tap it → Keyboard should NOT show
- [ ] Try to edit → Should fail ✅

### Test 9: Different Input Types
- [ ] Text field → Text keyboard
- [ ] Email field → Email keyboard  
- [ ] Number field → Number keyboard
- [ ] All work after back press ✅

## Debugging Tips

### If Keyboard Still Doesn't Appear

**Check Logs For:**
1. Is `clearTextInputClient` being called? 
   - If not, back press isn't triggering it
2. Is configuration actually null after clear?
   - Check Android logs
3. Is `_showKeyboard()` detecting detached connection?
   - Look for "Connection not attached" log
4. Is new connection being created?
   - Check for new connection ID in logs

**Common Issues:**
- **Keyboard doesn't hide on back**: Focus might not be lost, keyboard hides but appears again
  - Solution: Ensure back button properly triggers IME close
- **Keyboard shows but doesn't receive input**: Connection created but not fully initialized
  - Solution: Check `setClient()` is being called with proper configuration
- **Lag on second tap**: Connection recreation takes time
  - Normal: Takes ~100-200ms for Android to show keyboard

### Enable Verbose Logging

Add to your main.dart:
```dart
debugPrint('Verbose mode enabled');
```

All methods already have detailed logging that will print to the console.

## Success Criteria

✅ **Pass If:**
- [ ] Test 1: Keyboard appears on second tap (THE FIX)
- [ ] Test 2: Multiple cycles all work
- [ ] Test 3: Both focus loss and back press work correctly
- [ ] Test 4: Text can be edited throughout
- [ ] Test 6-9: All regression tests pass
- [ ] Logs show expected patterns

❌ **Fail If:**
- [ ] Keyboard doesn't appear on second tap after back press
- [ ] Any regression in existing functionality
- [ ] Memory leaks or performance degradation
- [ ] Keyboard state becomes inconsistent

## Commit & Verification

**Commit Hash**: `8fd1347`  
**Changes**:
- Android: Clear configuration in `clearTextInputClient()`
- Dart: Check `attached` property before reusing connection
- Enhanced logging for debugging

**To Verify Implementation**:
```bash
git log --oneline | head -5
# Should show: 8fd1347 Implement Flutter framework pattern...

git show 8fd1347
# Should show changes in:
# - TextInputPlugin.java (clearTextInputClient method)
# - editable_text.dart (_showKeyboard method)
```

## Next Steps (If Issues Found)

1. **Check Logs**: Review logcat and Flutter debug output
2. **Verify Configuration**: Ensure Android configuration state matches expectations
3. **Test Isolation**: Test with just the text field, no other widgets
4. **Check Framework**: Verify Flutter version compatibility
5. **Review Changes**: See `IMPLEMENTATION_COMPLETE.md` for architectural details
