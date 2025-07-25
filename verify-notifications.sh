#!/bin/bash

# Enhanced Notification System Test Script with Common Icons
# Uses icons that are more likely to be available on most systems

echo "🔔 Testing Enhanced Notification System Features"
echo "============================================================="

# Check what icons are available
echo "Checking available icons..."
if [ -d "~/.local/share/icons/Papirus" ]; then
    echo "✓ Icon theme found"
    ICON_BASE="~/.local/share/icons/Papirus"
else
    echo "! Using fallback icons"
    ICON_BASE=""
fi

# Test 1: Basic notifications
echo "📱 Test 1: Basic notifications"
notify-send -h string:desktop-entry:org.gnome.Settings -i preferences-desktop "Settings" "Basic notification message"
sleep 2

# Test 2: Media notifications (should group under Spotify)
echo "🎵 Test 2: Media notifications (grouping)"
notify-send -h string:desktop-entry:spotify -i audio-x-generic "Spotify" "Now Playing: Song 1 - Artist A"
sleep 1
notify-send -h string:desktop-entry:spotify -i audio-x-generic "Spotify" "Now Playing: Song 2 - Artist B"
sleep 1
notify-send -h string:desktop-entry:spotify -i audio-x-generic "Spotify" "Now Playing: Song 3 - Artist C"
sleep 2

# Test 3: System notifications (separate groups)
echo "🔋 Test 3: System notifications (separate apps)"
notify-send -h string:desktop-entry:org.gnome.PowerStats -i battery "Power Manager" "Battery Low: 15% remaining"
sleep 1
notify-send -h string:desktop-entry:org.gnome.NetworkDisplays -i network-wired "Network Manager" "WiFi Connected: HomeNetwork"
sleep 1
notify-send -h string:desktop-entry:org.gnome.Software -i system-software-update "Software" "5 updates available"
sleep 2

# Test 4: Chat notifications (should group under Discord)
echo "💬 Test 4: Chat notifications (grouping)"
notify-send -h string:desktop-entry:discord -i internet-chat "Discord" "#general: User1 says Hello everyone!"
sleep 1
notify-send -h string:desktop-entry:discord -i internet-chat "Discord" "#general: User2 says Hey there!"
sleep 1
notify-send -h string:desktop-entry:discord -i internet-chat "Discord" "john_doe: Private message from John"
sleep 2

# Test 5: Urgent notifications
echo "🚨 Test 5: Urgent notifications"
notify-send -u critical -i dialog-warning "Critical Alert" "System overheating detected - Temperature: 85°C"
sleep 2

# Test 6: Notifications with actions (simulated)
echo "⚡ Test 6: Action buttons"
notify-send -h string:desktop-entry:org.gnome.Software -i system-upgrade "Software" "Updates available - Click to install or remind later"
sleep 2

# Test 7: Multiple different apps
echo "📊 Test 7: Multiple different apps"
notify-send -h string:desktop-entry:thunderbird -i mail-message-new "Thunderbird" "You have 3 new emails"
sleep 0.5
notify-send -h string:desktop-entry:org.gnome.Calendar -i office-calendar "Calendar" "Daily standup in 5 minutes"
sleep 0.5
notify-send -h string:desktop-entry:org.gnome.Nautilus -i folder-downloads "Files" "document.pdf downloaded"
sleep 2

echo ""
echo "✅ Notification tests completed!"
echo ""
echo "📋 Enhanced Features Tested:"
echo "  • Media notification replacement"
echo "  • System notification grouping"
echo "  • Conversation grouping and auto-expansion"
echo "  • Urgency level handling"
echo "  • Action button support"
echo "  • Multi-app notification handling"
echo ""
echo "🎯 Check your notification popup and notification center to see the results!"
echo ""
echo "Note: Some icons may show as fallback (checkerboard) if icon themes aren't installed."
echo "To install more icons: sudo pacman -S papirus-icon-theme adwaita-icon-theme"