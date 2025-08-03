# DankMaterialShell

A [Quickshell](https://quickshell.org/)-based desktop shell with Material 3 design principles, built for functionality and modern aesthetics.

Specifically optimized for the [niri](https://github.com/YaLTeR/niri) compositor, but compatible with other Wayland compositors.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Core Dependencies](#core-dependencies)
  - [Optional Dependencies](#optional-dependencies)
  - [Shell Installation](#shell-installation)
- [Configuration](#configuration)
  - [Theme Configuration](#theme-configuration)
  - [App Theming Setup](#app-theming-setup)
- [Usage](#usage)
  - [Basic Controls](#basic-controls)
  - [IPC Commands](#ipc-commands)
- [Calendar Integration](#calendar-integration)
- [Troubleshooting](#troubleshooting)

## Features

- **Material 3 Design**: Modern, clean interface following Google's latest design language
- **Dynamic Theming**: Automatic color extraction from wallpapers using matugen
- **System Integration**: Built-in audio controls, brightness management, and media controls
- **Application Launcher**: Spotlight-style launcher for quick app access
- **Clipboard History**: Visual clipboard manager with search functionality
- **Process Manager**: Built-in task manager for system monitoring
- **Notification Center**: Centralized notification management
- **Calendar Support**: Integration with various calendar services
- **Lockscreen**: Secure screen locking functionality

## Requirements

**Base Requirements:**
- Wayland compositor (niri recommended)
- NetworkManager (for WiFi functionality)
- Material Symbols font
- Inter and Fira Code fonts (recommended)

**Distribution Support:**
- Compatible with any Linux distribution
- Installation examples provided for Arch Linux and Fedora

## Installation

### Core Dependencies

#### Material Symbols Font

**Manual Installation:**
```bash
mkdir -p ~/.local/share/fonts
curl -L "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" -o ~/.local/share/fonts/MaterialSymbolsRounded.ttf
fc-cache -f
```

**Package Installation:**
```bash
# Arch Linux
paru -S ttf-material-symbols-variable-git

# Fedora
# Use manual installation - Fedora packages contain legacy Material Icons
```

#### Typography

**Inter Variable Font:**
```bash
# Manual
mkdir -p ~/.local/share/fonts
curl -L "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -o /tmp/Inter.zip
unzip -j /tmp/Inter.zip "InterVariable.ttf" "InterVariable-Italic.ttf" -d ~/.local/share/fonts/
rm /tmp/Inter.zip && fc-cache -f

# Package managers
# Arch: pacman -S inter-font
# Fedora: sudo dnf install rsms-inter-fonts
```

**Fira Code Font:**
```bash
# Manual
mkdir -p ~/.local/share/fonts
curl -L "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip" -o /tmp/FiraCode.zip
unzip -j /tmp/FiraCode.zip "ttf/*.ttf" -d ~/.local/share/fonts/
rm /tmp/FiraCode.zip && fc-cache -f

# Package managers
# Arch: pacman -S ttf-fira-code
# Fedora: sudo dnf install fira-code-fonts
```

#### Quickshell

**Arch Linux:**
```bash
paru -S quickshell-git
```

**Fedora:**
```bash
sudo dnf copr enable errornointernet/quickshell
sudo dnf install quickshell
# or for git version
sudo dnf install quickshell-git
```

### Optional Dependencies

| Component | Purpose | Missing Functionality |
|-----------|---------|----------------------|
| matugen | Dynamic wallpaper-based theming | Limited to preconfigured themes |
| ddcutil | External monitor brightness control | No DDC/CI brightness control |
| brightnessctl | Laptop display brightness control | No backlight control |
| wl-clipboard | Copy functionality for PIDs and other elements | No clipboard operations |
| qt5ct + qt6ct | Qt application theming | No Qt theme integration |
| gsettings | GTK application theming | No GTK theme integration |

#### Installation by Distribution

**Arch Linux:**
```bash
# Core optional packages
pacman -S cava wl-clipboard cliphist ddcutil brightnessctl qt5ct qt6ct

# AUR packages
paru -S matugen
```

**Fedora:**
```bash
# Core packages
sudo dnf install cava wl-clipboard ddcutil brightnessctl qt5ct qt6ct

# COPR repositories
sudo dnf copr enable wef/cliphist && sudo dnf install cliphist
sudo dnf copr enable heus-sueh/packages && sudo dnf install matugen
```

### Shell Installation

1. **Create configuration directory:**
   ```bash
   mkdir -p ~/.config/quickshell
   ```

2. **Clone the repository:**
   ```bash
   git clone https://github.com/bbedward/DankMaterialShell.git ~/.config/quickshell/DankMaterialShell
   ```

3. **Launch the shell:**
   ```bash
   qs -c DankMaterialShell
   ```

## Configuration

### Theme Configuration

#### GTK Applications

Install a compatible theme like [Colloid](https://github.com/vinceliuice/Colloid-gtk-theme):

```bash
# Install Colloid theme
./install.sh -s standard -l --tweaks normal
```

Configure in `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`:
```ini
[Settings]
gtk-theme-name=Colloid
```

#### Qt Applications

**Install Breeze theme:**
```bash
# Arch
pacman -S breeze breeze5
```

**Configure Qt5 and Qt6:**

In `~/.config/qt5ct/qt5ct.conf` and `~/.config/qt6ct/qt6ct.conf`:
```ini
[Appearance]
style=Breeze
```

#### KDE Applications

Create `~/.config/kdeglobals`:
```ini
[UiSettings]
ColorScheme=qt6ct
```

### App Theming Setup

Enable system app theming in **Settings → Appearance → System App Theming** after installing the required dependencies.

### Ghostty Theming
If using [Ghostty](https://ghostty.org/), you can automatically theme its colors as well by adding the following to your `~/.config/ghostty/config` file

```
config-file = ./config-dankcolors
```

Ghostty doesn't hot-reload config changes, but does with a keyboard shortcut `ctrl+,`

## Usage

### Basic Controls

#### Niri Configuration

Add to your niri configuration:

```bash
# Auto-start
spawn-at-startup "qs" "-c" "DankMaterialShell"

# Key bindings
Mod+Space hotkey-overlay-title="Run an Application: Spotlight" { 
    spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "spotlight" "toggle"; 
}

Mod+V hotkey-overlay-title="Open Clipboard History" { 
    spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "clipboard" "toggle"; 
}
```

### IPC Commands

The shell provides extensive IPC (Inter-Process Communication) functionality:

```bash
qs -c DankMaterialShell ipc call <target> <function> [parameters]
```

#### Audio Controls

| Command | Function |
|---------|----------|
| `audio setvolume 50` | Set volume to 50% |
| `audio increment 10` | Increase volume by 10% |
| `audio decrement 5` | Decrease volume by 5% |
| `audio mute` | Toggle audio mute |
| `audio setmic 75` | Set microphone to 75% |
| `audio micmute` | Toggle microphone mute |
| `audio status` | Get current audio status |

#### Application Controls

| Command | Function |
|---------|----------|
| `spotlight toggle` | Toggle application launcher |
| `clipboard toggle` | Toggle clipboard history |
| `processlist toggle` | Toggle process manager |
| `settings toggle` | Toggle settings |
| `lock lock` | Activate lockscreen |

#### Media Controls

| Command | Function |
|---------|----------|
| `mpris list` | List available media players |
| `mpris playPause` | Toggle play/pause |
| `mpris next` | Next track |
| `mpris previous` | Previous track |

#### System Services

| Command | Function |
|---------|----------|
| `wallpaper set /path/to/image.jpg` | Set wallpaper and refresh theme |
| `theme toggle` | Toggle light/dark mode |
| `notifs clear` | Clear all notifications |

## Calendar Integration

### Prerequisites

Install required packages:

```bash
# Arch Linux
pacman -S vdirsyncer khal python-aiohttp-oauthlib

# Fedora
sudo dnf install python3-vdirsyncer khal python3-aiohttp-oauthlib
```

### Configuration

1. **Create vdirsyncer directory:**
   ```bash
   mkdir -p ~/.vdirsyncer
   ```

2. **Configure calendar sync** in `~/.vdirsyncer/config`:
   ```ini
   [general]
   status_path = "~/.calendars/status"

   [pair personal_sync]
   a = "personal"
   b = "personallocal"
   collections = ["from a", "from b"]
   conflict_resolution = "a wins"
   metadata = ["color"]

   [storage personal]
   type = "google_calendar"
   token_file = "~/.vdirsyncer/google_calendar_token"
   client_id = "your_client_id"
   client_secret = "your_client_secret"

   [storage personallocal]
   type = "filesystem"
   path = "~/.calendars/Personal"
   fileext = ".ics"
   ```

3. **Initial sync:**
   ```bash
   vdirsyncer sync
   ```

4. **Configure automatic sync:**
   ```bash
   crontab -e
   # Add: */5 * * * * /usr/bin/vdirsyncer sync
   ```

5. **Configure khal:**
   ```bash
   khal configure
   # Follow the interactive setup
   ```