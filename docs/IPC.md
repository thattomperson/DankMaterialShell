# IPC Commands Reference

DankMaterialShell provides comprehensive IPC (Inter-Process Communication) functionality that allows external control of the shell through command-line commands. All IPC commands follow the format:

```bash
qs -c DankMaterialShell ipc call <target> <function> [parameters...]
```

## Target: `audio`

Audio system control and information.

### Functions

**`setvolume <percentage>`**
- Set output volume to specific percentage (0-100)
- Returns: Confirmation message

**`increment <step>`**
- Increase output volume by step amount
- Parameters: `step` - Volume increase amount (default: 5)
- Returns: Confirmation message

**`decrement <step>`**
- Decrease output volume by step amount  
- Parameters: `step` - Volume decrease amount (default: 5)
- Returns: Confirmation message

**`mute`**
- Toggle output device mute state
- Returns: Current mute status

**`setmic <percentage>`**
- Set input (microphone) volume to specific percentage (0-100)
- Returns: Confirmation message

**`micmute`**
- Toggle input device mute state
- Returns: Current mic mute status

**`status`**
- Get current audio status for both input and output devices
- Returns: Volume levels and mute states

### Examples
```bash
qs -c DankMaterialShell ipc call audio setvolume 50
qs -c DankMaterialShell ipc call audio increment 10
qs -c DankMaterialShell ipc call audio mute
```

## Target: `brightness`

Display brightness control for internal and external displays.

### Functions

**`set <percentage> [device]`**
- Set brightness to specific percentage (1-100)
- Parameters:
  - `percentage` - Brightness level (1-100)
  - `device` - Optional device name (empty string for default)
- Returns: Confirmation with device info

**`increment <step> [device]`**
- Increase brightness by step amount
- Parameters:
  - `step` - Brightness increase amount
  - `device` - Optional device name (empty string for default)
- Returns: Confirmation with new brightness level

**`decrement <step> [device]`**
- Decrease brightness by step amount
- Parameters:
  - `step` - Brightness decrease amount  
  - `device` - Optional device name (empty string for default)
- Returns: Confirmation with new brightness level

**`status`**
- Get current brightness status
- Returns: Current device and brightness level

**`list`**
- List all available brightness devices
- Returns: Device names and classes

### Examples
```bash
qs -c DankMaterialShell ipc call brightness set 80
qs -c DankMaterialShell ipc call brightness increment 10 ""
qs -c DankMaterialShell ipc call brightness decrement 5 "intel_backlight"
```

## Target: `night`

Night mode (gamma/color temperature) control.

### Functions

**`toggle`**
- Toggle night mode on/off
- Returns: Current night mode state

**`enable`**
- Enable night mode
- Returns: Confirmation message

**`disable`** 
- Disable night mode
- Returns: Confirmation message

**`status`**
- Get current night mode status
- Returns: Night mode enabled/disabled state

**`temperature [value]`**
- Get or set night mode color temperature
- Parameters:
  - `value` - Optional temperature in Kelvin (2500-6000, steps of 500)
- Returns: Current or newly set temperature

### Examples
```bash
qs -c DankMaterialShell ipc call night toggle
qs -c DankMaterialShell ipc call night temperature 4000
```

## Target: `mpris`

Media player control via MPRIS interface.

### Functions

**`list`**
- List all available media players
- Returns: Player names

**`play`**
- Start playback on active player
- Returns: Nothing

**`pause`**
- Pause playback on active player  
- Returns: Nothing

**`playPause`**
- Toggle play/pause state on active player
- Returns: Nothing

**`previous`**
- Skip to previous track
- Returns: Nothing

**`next`**
- Skip to next track
- Returns: Nothing

**`stop`**
- Stop playback on active player
- Returns: Nothing

### Examples
```bash
qs -c DankMaterialShell ipc call mpris playPause
qs -c DankMaterialShell ipc call mpris next
```

## Target: `lock`

Screen lock control and status.

### Functions

**`lock`**
- Lock the screen immediately
- Returns: Nothing

**`demo`**
- Show lock screen in demo mode (doesn't actually lock)
- Returns: Nothing

**`isLocked`**
- Check if screen is currently locked
- Returns: Boolean lock state

### Examples
```bash
qs -c DankMaterialShell ipc call lock lock
qs -c DankMaterialShell ipc call lock isLocked
```

## Target: `inhibit`

Idle inhibitor control to prevent automatic sleep/lock.

### Functions

**`toggle`**
- Toggle idle inhibit state
- Returns: Current inhibit state message

**`enable`**
- Enable idle inhibit (prevent sleep/lock)
- Returns: Confirmation message

**`disable`**
- Disable idle inhibit (allow sleep/lock)
- Returns: Confirmation message

### Examples
```bash
qs -c DankMaterialShell ipc call inhibit toggle
qs -c DankMaterialShell ipc call inhibit enable
```

## Target: `wallpaper`

Wallpaper management and retrieval.

### Functions

**`get`**
- Get current wallpaper path
- Returns: Full path to current wallpaper file

**`set <path>`**
- Set wallpaper to specified path
- Parameters: `path` - Absolute or relative path to image file
- Returns: Confirmation message or error

### Examples
```bash
qs -c DankMaterialShell ipc call wallpaper get
qs -c DankMaterialShell ipc call wallpaper set /path/to/image.jpg
```

## Target: `theme`

Theme mode control (light/dark mode switching).

### Functions

**`toggle`**
- Toggle between light and dark themes
- Returns: Current theme mode ("light" or "dark")

**`light`**
- Switch to light theme mode
- Returns: "light"

**`dark`**
- Switch to dark theme mode  
- Returns: "dark"

### Examples
```bash
qs -c DankMaterialShell ipc call theme toggle
qs -c DankMaterialShell ipc call theme dark
```

## Modal Controls

These targets control various modal windows and overlays.

### Target: `spotlight`
Application launcher modal control.

**Functions:**
- `open` - Show the spotlight launcher
- `close` - Hide the spotlight launcher
- `toggle` - Toggle spotlight launcher visibility

### Target: `clipboard`
Clipboard history modal control.

**Functions:**
- `open` - Show clipboard history
- `close` - Hide clipboard history  
- `toggle` - Toggle clipboard history visibility

### Target: `notifications`
Notification center modal control.

**Functions:**
- `open` - Show notification center
- `close` - Hide notification center
- `toggle` - Toggle notification center visibility

### Target: `settings`
Settings modal control.

**Functions:**
- `open` - Show settings modal
- `close` - Hide settings modal
- `toggle` - Toggle settings modal visibility

### Target: `processlist`
System process list and performance modal control.

**Functions:**
- `open` - Show process list modal
- `close` - Hide process list modal
- `toggle` - Toggle process list modal visibility

### Modal Examples
```bash
# Open application launcher
qs -c DankMaterialShell ipc call spotlight toggle

# Show clipboard history
qs -c DankMaterialShell ipc call clipboard open

# Toggle notification center
qs -c DankMaterialShell ipc call notifications toggle

# Show settings
qs -c DankMaterialShell ipc call settings open

# Show system monitor
qs -c DankMaterialShell ipc call processlist toggle
```

## Common Usage Patterns

### Keybinding Integration

These IPC commands are designed to be used with window manager keybindings. Example niri configuration:

```kdl
binds {
    Mod+Space { spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "spotlight" "toggle"; }
    Mod+V { spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "clipboard" "toggle"; }
    XF86AudioRaiseVolume { spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "audio" "increment" "3"; }
    XF86MonBrightnessUp { spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "brightness" "increment" "5" ""; }
}
```

### Scripting and Automation

IPC commands can be used in scripts for automation:

```bash
#!/bin/bash
# Toggle night mode based on time of day
hour=$(date +%H)
if [ $hour -ge 20 ] || [ $hour -le 6 ]; then
    qs -c DankMaterialShell ipc call night enable
else
    qs -c DankMaterialShell ipc call night disable
fi
```

### Status Checking

Many commands provide status information useful for scripts:

```bash
# Check if screen is locked before performing action
if qs -c DankMaterialShell ipc call lock isLocked | grep -q "false"; then
    # Perform action only if unlocked
    qs -c DankMaterialShell ipc call notifications open
fi
```

## Return Values

Most IPC functions return string messages indicating:
- Success confirmation with current values
- Error messages if operation fails
- Status information for query functions
- Empty/void return for simple action functions

Functions that return void (like media controls) execute the action but don't provide feedback. Check the application state through other means if needed.