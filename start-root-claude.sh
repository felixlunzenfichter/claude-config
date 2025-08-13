#!/bin/bash

# Start Claude Coordinator with MCP worker tools

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Close any Terminal windows attached to claude_orchestrator
echo "Closing existing claude_orchestrator Terminal windows..."
osascript -e '
tell application "Terminal"
    set windowList to windows
    repeat with w in windowList
        set tabList to tabs of w
        repeat with t in tabList
            if (processes of t) contains "tmux attach -t claude_orchestrator" then
                close w
                exit repeat
            end if
        end repeat
    end repeat
end tell' 2>/dev/null

# Kill any existing sessions
tmux kill-session -t claude_orchestrator 2>/dev/null
tmux kill-session -t mcp-server 2>/dev/null
tmux kill-session -t system-tools 2>/dev/null

# Start System Tools MCP Server first
echo "Starting System Tools MCP Server..."
cd "$SCRIPT_DIR/system-tools-mcp-server"
tmux new-session -d -s system-tools "npm start"

# Start MCP Worker Server
echo "Starting MCP Worker Server..."
cd "$SCRIPT_DIR/coordinator-tools-mcp-server"
tmux new-session -d -s mcp-server "npm start"

# Wait for MCP servers to initialize
sleep 2

# Start new tmux session in the claude-config directory
tmux new-session -d -s claude_orchestrator -c "$SCRIPT_DIR"


# Register MCP coordinator-tools server
claude mcp add coordinator-tools "$SCRIPT_DIR/coordinator-tools-mcp-server/index.js"

# Register system-tools server with user scope for global access
claude mcp add --scope user system-tools /opt/homebrew/bin/node "$SCRIPT_DIR/system-tools-mcp-server/index.js"

# Start Claude directly in the claude-config directory to access local .claude.json
tmux send-keys -t claude_orchestrator "claude --model sonnet --dangerously-skip-permissions" Enter

# Wait for Claude to be ready
echo "Waiting for Claude to initialize..."
while ! tmux capture-pane -t claude_orchestrator -p -S -100 | grep -q "Welcome to Claude Code"; do
    sleep 0.5
done

# Clear any existing worker tracking
> /tmp/claude_workers.jsonl

# Open new Terminal window and attach to the session
echo "Opening new Terminal window..."
osascript -e '
tell application "Terminal"
    set newWindow to do script "tmux attach -t claude_orchestrator"
    delay 0.5
    tell application "System Events" to tell process "Terminal"
        set value of attribute "AXFullScreen" of window 1 to true
    end tell
end tell'

# Wait for window to fully open and attach
sleep 1

# Send coordinator role message
tmux send-keys -t claude_orchestrator "You are the Claude Coordinator. Please read CLAUDE_COORDINATOR.md and confirm you understand your role by explaining it."
sleep 1
tmux send-keys -t claude_orchestrator Enter

# Wait a bit for coordinator to process the message
sleep 2

# Archive macos-voice-control logs before deployment
echo "Archiving macos-voice-control logs..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGS_DIR="/Users/felixlunzenfichter/Documents/macos-voice-control/logs"

if [ -d "$LOGS_DIR" ]; then
    # Create legacy directory if it doesn't exist
    mkdir -p "$LOGS_DIR/legacy"
    
    # Archive existing log files
    for logfile in "$LOGS_DIR"/*.log "$LOGS_DIR"/*.txt "$LOGS_DIR"/*.json; do
        if [ -f "$logfile" ]; then
            filename=$(basename "$logfile")
            # Move to legacy with timestamp
            mv "$logfile" "$LOGS_DIR/legacy/${TIMESTAMP}_${filename}"
        fi
    done
    
    # Clear/recreate empty log files
    touch "$LOGS_DIR/logs.txt"
    touch "$LOGS_DIR/logs.json"
    touch "$LOGS_DIR/git-client-logs.log"
    
    echo "Logs archived to $LOGS_DIR/legacy/"
fi

# Spawn worker to handle voice control deployment in split screen
echo "Spawning macOS Voice Control deployment worker in split screen..."
PANE_ID=$(tmux split-window -t claude_orchestrator:0 -h -P -F "#{pane_id}" "cd /Users/felixlunzenfichter/Documents/macos-voice-control && claude --model opus --dangerously-skip-permissions")
tmux select-layout -t claude_orchestrator even-horizontal

# Wait for Claude to initialize in the new pane
sleep 2

# Send deployment instructions to worker with pane ID for self-termination
tmux send-keys -t "$PANE_ID" "Please read /Users/felixlunzenfichter/Documents/macos-voice-control/deployment.md and start the backend and mac-server following the deployment guide. Make sure that the iOS app is running and that transcriptions are being received. After receiving a successful transcription, terminate yourself with 'tmux kill-pane -t $PANE_ID'."
sleep 1
tmux send-keys -t "$PANE_ID" Enter