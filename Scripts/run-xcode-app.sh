#!/bin/bash

# Script to open Xcode, run the app, and return to terminal
# Usage: run-xcode-app.sh [project-path]
# If no project path is provided, it looks for .xcodeproj in current directory

# Determine the project path
if [ -n "$1" ]; then
    PROJECT_PATH="$1"
else
    # Find .xcodeproj in current directory
    PROJECT_PATH=$(find . -maxdepth 1 -name "*.xcodeproj" | head -n 1)
    
    if [ -z "$PROJECT_PATH" ]; then
        # Try to find .xcworkspace
        PROJECT_PATH=$(find . -maxdepth 1 -name "*.xcworkspace" | head -n 1)
    fi
    
    if [ -z "$PROJECT_PATH" ]; then
        echo "Error: No Xcode project found in current directory"
        echo "Usage: $0 [path-to-xcodeproj-or-xcworkspace]"
        exit 1
    fi
fi

# Convert to absolute path
PROJECT_PATH=$(cd "$(dirname "$PROJECT_PATH")" && pwd)/$(basename "$PROJECT_PATH")

echo "Opening Xcode project: $PROJECT_PATH"
echo "Running the app..."

# Open the Xcode project
open "$PROJECT_PATH"

# Wait for Xcode to fully load
sleep 2

# Use AppleScript to press the Run button
osascript <<EOF
tell application "Xcode"
    activate
    tell application "System Events"
        tell process "Xcode"
            -- Press Cmd+R to run
            keystroke "r" using command down
        end tell
    end tell
end tell
EOF

# Wait a moment for the build to start
sleep 2

# Return focus to Terminal
osascript <<EOF
tell application "Terminal"
    activate
end tell
EOF

echo "App is building and running in Xcode. Terminal is now active."