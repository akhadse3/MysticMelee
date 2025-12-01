# Mobile Support Guide for MysticCards

This document outlines what needs to be done to make MysticCards playable on mobile devices (iOS and Android).

---

## Overview

MysticCards is currently designed for desktop/web platforms. To support mobile, you'll need to make changes to:
1. **Game Code** - UI scaling, touch controls, input handling
2. **Godot Project Settings** - Export presets, permissions, icons
3. **Server Configuration** - No changes needed (already works!)

---

## 1. Code Changes Required

### A. UI Scaling & Layout

**Problem**: Current UI is designed for 1280×800 desktop resolution. Mobile screens vary widely (phones: 360×640 to 414×896, tablets: 768×1024 to 1024×1366).

**Solution**: Implement responsive UI scaling.

#### In `Main.tscn`:
- Use **Control anchors** instead of fixed positions
- Set `layout_mode = 3` (full rect) for containers
- Use `size_flags` for flexible sizing

#### In `Main.gd`:
```gdscript
func _ready():
    # Detect mobile platform
    if OS.has_feature("mobile"):
        _setup_mobile_ui()
    else:
        _setup_desktop_ui()

func _setup_mobile_ui():
    # Adjust card sizes for smaller screens
    var card_size = Vector2(80, 120)  # Smaller than desktop
    # Reduce font sizes
    # Adjust panel sizes
    # Enable touch-friendly spacing
```

#### In `Card.gd`:
```gdscript
func _ready():
    if OS.has_feature("mobile"):
        # Smaller cards on mobile
        custom_minimum_size = Vector2(60, 90)
    else:
        custom_minimum_size = Vector2(100, 140)
```

### B. Touch Input

**Problem**: Game uses mouse clicks. Mobile needs touch support.

**Solution**: Godot automatically converts touch to mouse events, but you may need adjustments.

#### In `Card.gd`:
```gdscript
func _gui_input(event: InputEvent):
    # Works for both mouse and touch
    if event is InputEventMouseButton or event is InputEventScreenTouch:
        if event.pressed:
            # Handle tap/click
```

#### In `Main.gd`:
- **Drag and drop** may need larger hit areas on mobile
- Consider **tap-to-select** instead of drag for card playing
- Add **haptic feedback** for better UX:
```gdscript
if OS.has_feature("mobile"):
    Input.vibrate_handheld(50)  # 50ms vibration
```

### C. Screen Orientation

**Problem**: Game is landscape-oriented. Need to handle portrait/landscape.

**Solution**: Lock to landscape or support both.

#### In `project.godot`:
```ini
[display]

window/size/viewport_width=1280
window/size/viewport_height=800
window/handheld/orientation=1  # 0=portrait, 1=landscape, 2=reverse_landscape, 3=reverse_portrait, 4=sensor
```

Or in code:
```gdscript
# In Main.gd _ready()
if OS.has_feature("mobile"):
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
```

### D. Text Input

**Problem**: Player name input needs mobile keyboard support.

**Solution**: Already handled by Godot's `LineEdit`, but ensure it's visible when keyboard appears.

#### In `TitleScreen.gd`:
```gdscript
func _on_multiplayer():
    multiplayer_panel.visible = true
    if OS.has_feature("mobile"):
        # Scroll to name input when keyboard appears
        await get_tree().process_frame
        player_name_input.grab_focus()
```

### E. Button Sizes

**Problem**: Buttons may be too small for touch.

**Solution**: Increase minimum button sizes.

#### In `TitleScreen.tscn` and `Main.tscn`:
- Set `custom_minimum_size` for all buttons to at least `Vector2(100, 50)`
- Increase spacing between buttons

### F. Reaction Timer

**Problem**: 5-second reaction timer may be too short on mobile.

**Solution**: Increase timer or make it configurable.

#### In `GameManager.gd`:
```gdscript
const REACTION_TIME = 5.0  # Desktop
const REACTION_TIME_MOBILE = 7.0  # Mobile

func start_reaction_window(card: CardType, is_player_reacting: bool):
    var timer_duration = REACTION_TIME_MOBILE if OS.has_feature("mobile") else REACTION_TIME
    # ...
```

---

## 2. Godot Export Settings

### A. Android Export

#### Prerequisites:
1. Install **Android SDK** and **NDK**
2. Download **Godot Android Export Templates**
3. Enable **Android Export** in Project → Export

#### Export Preset Configuration:

**General Tab:**
- **Package**: `com.yourname.mysticcards`
- **Version**: `1.0.0`
- **Version Code**: `1`
- **Min SDK**: `21` (Android 5.0)
- **Target SDK**: `33` (Android 13)

**Permissions Tab:**
- ✅ **Internet** (required for Nakama)
- ✅ **Access Network State** (optional, for connection checks)

**Graphics Tab:**
- **Graphics API**: OpenGL ES 3.0
- **Support 32 Bits**: ✅ (for older devices)
- **Support 64 Bits**: ✅

**Architectures:**
- ✅ **armeabi-v7a** (32-bit ARM)
- ✅ **arm64-v8a** (64-bit ARM)
- ✅ **x86** (for emulators)
- ✅ **x86_64** (for emulators)

**Keystore:**
- Create a keystore for release builds:
```bash
keytool -genkey -v -keystore mysticcards.keystore -alias mysticcards -keyalg RSA -keysize 2048 -validity 10000
```

### B. iOS Export

#### Prerequisites:
1. **macOS** computer (required)
2. **Xcode** installed
3. **Apple Developer Account** ($99/year)
4. **Godot iOS Export Templates**

#### Export Preset Configuration:

**General Tab:**
- **Bundle Identifier**: `com.yourname.mysticcards`
- **Version**: `1.0.0`
- **Short Version**: `1.0`
- **Minimum iOS Version**: `13.0`

**Capabilities Tab:**
- ✅ **Internet** (required for Nakama)

**Icons:**
- Provide all required icon sizes (1024×1024, 180×180, 120×120, etc.)

**Info.plist:**
- Add description for Internet usage:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 3. Server Configuration

**Good News**: Your Nakama server setup **already works for mobile!**

- ✅ HTTPS/WSS is configured (required for mobile)
- ✅ CORS headers are set (for web, not needed for native apps)
- ✅ Domain is accessible from anywhere

**No server changes needed!**

---

## 4. Testing Checklist

### Android:
- [ ] Test on different screen sizes (phone, tablet)
- [ ] Test landscape orientation
- [ ] Test touch input (tap, drag)
- [ ] Test keyboard input for player name
- [ ] Test network connection (WiFi, mobile data)
- [ ] Test on Android 5.0+ devices
- [ ] Test performance on low-end devices

### iOS:
- [ ] Test on iPhone (various sizes)
- [ ] Test on iPad
- [ ] Test landscape orientation
- [ ] Test touch input
- [ ] Test network connection
- [ ] Test on iOS 13.0+ devices

---

## 5. Performance Optimizations

### A. Reduce Particle Effects
```gdscript
# In Card.gd
if OS.has_feature("mobile"):
    PARTICLE_REGEN_INTERVAL[CardType.FIRE] = 0.15  # Slower on mobile
    # Reduce particle counts
```

### B. Disable Animations Option
Already implemented via `SettingsManager.animations_enabled` - ensure it's easily accessible on mobile.

### C. Texture Compression
- Use **ETC2** for Android
- Use **ASTC** for iOS
- Already configured in `project.godot`:
```ini
[rendering]
textures/vram_compression/import_etc2_astc=true
```

### D. Reduce Draw Calls
- Batch card rendering where possible
- Limit simultaneous animations

---

## 6. Platform-Specific Features

### Android:
- **Back Button**: Handle Android back button
```gdscript
func _notification(what):
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        # Handle back button
        if game_menu_panel.visible:
            game_menu_panel.visible = false
        else:
            _on_back()
```

### iOS:
- **Safe Area**: Handle iPhone notch/status bar
```gdscript
func _ready():
    if OS.has_feature("ios"):
        var safe_area = DisplayServer.get_display_safe_area()
        # Adjust UI to safe area
```

---

## 7. Distribution

### Android:
1. **Google Play Store**:
   - Create developer account ($25 one-time)
   - Upload APK/AAB
   - Fill out store listing
   - Submit for review

2. **Alternative**: Direct APK distribution (no store)

### iOS:
1. **App Store**:
   - Create Apple Developer account ($99/year)
   - Use Xcode to archive and upload
   - Submit for review

2. **TestFlight**: Beta testing before release

---

## 8. Estimated Development Time

| Task | Time Estimate |
|------|---------------|
| UI scaling & responsive layout | 4-6 hours |
| Touch input adjustments | 2-3 hours |
| Mobile export setup | 2-3 hours |
| Testing & bug fixes | 4-6 hours |
| **Total** | **12-18 hours** |

---

## 9. Recommended Approach

### Phase 1: Quick Mobile Support (Minimum Viable)
1. Lock to landscape orientation
2. Scale UI elements for mobile screens
3. Increase button sizes
4. Test on one Android device
5. Export and test basic functionality

### Phase 2: Polish (Full Mobile Support)
1. Add haptic feedback
2. Optimize performance
3. Test on multiple devices
4. Add mobile-specific UI improvements
5. Handle edge cases (keyboard, safe areas, etc.)

---

## 10. Code Examples

### Detect Mobile Platform:
```gdscript
func is_mobile() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS")
```

### Responsive Card Size:
```gdscript
func get_card_size() -> Vector2:
    if is_mobile():
        var screen_width = get_viewport().get_visible_rect().size.x
        # Cards should be ~15% of screen width
        var card_width = screen_width * 0.15
        return Vector2(card_width, card_width * 1.4)  # 1.4:1 aspect ratio
    else:
        return Vector2(100, 140)  # Desktop size
```

### Touch-Friendly Spacing:
```gdscript
const MOBILE_SPACING = 20
const DESKTOP_SPACING = 10

func get_spacing() -> int:
    return MOBILE_SPACING if is_mobile() else DESKTOP_SPACING
```

---

## Summary

**What Works Already:**
- ✅ Server connectivity (HTTPS/WSS)
- ✅ NetworkManager abstraction
- ✅ Game logic (platform-agnostic)

**What Needs Work:**
- ⚠️ UI scaling for different screen sizes
- ⚠️ Touch input optimization
- ⚠️ Button sizes and spacing
- ⚠️ Text input handling
- ⚠️ Performance on low-end devices

**Server Changes:**
- ✅ **None required!** Your current setup works for mobile.

---

## Next Steps

1. **Start with Android** (easier to test, no Mac required for development)
2. **Test on real device** (emulators are slow)
3. **Iterate on UI** based on user feedback
4. **Optimize performance** as needed
5. **Add iOS support** once Android is stable


