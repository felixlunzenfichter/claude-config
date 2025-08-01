#!/bin/bash

# Start Claude Coordinator with MCP worker tools

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Kill any existing sessions
tmux kill-session -t claude_orchestrator 2>/dev/null
tmux kill-session -t mcp-server 2>/dev/null

# Start MCP Worker Server first
echo "Starting MCP Worker Server..."
cd "$SCRIPT_DIR/mcp-worker-server"
tmux new-session -d -s mcp-server "npm start"

# Wait for MCP server to initialize
sleep 2

# Start new tmux session in the claude-config directory
tmux new-session -d -s claude_orchestrator -c "$SCRIPT_DIR"

# Register MCP worker-manager server
claude mcp add worker-manager "$SCRIPT_DIR/mcp-worker-server/index.js"

# Start Claude directly in the claude-config directory to access local .claude.json
tmux send-keys -t claude_orchestrator "claude --model sonnet --dangerously-skip-permissions" Enter

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