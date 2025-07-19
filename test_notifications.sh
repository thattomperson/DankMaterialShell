#!/bin/bash

# Test script for the new 2nd tier notification system

echo "Testing 2nd tier notification system..."

# Send a few test notifications to create a group
notify-send "Test App" "Short message 1"
sleep 1
notify-send "Test App" "This is a much longer message that should trigger the expand/collapse functionality for individual messages within the notification group system"
sleep 1
notify-send "Test App" "Message 3 with some content"

echo "Test notifications sent. Check the notification popup and center for:"
echo "1. 1st tier controls moved above group header"
echo "2. Message count badge next to app name when expanded"
echo "3. 'title • timestamp' format for individual messages" 
echo "4. Expand/collapse buttons for long individual messages"