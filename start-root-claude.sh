#!/bin/bash

# Start Claude Coordinator with auto-loaded worker functions

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the worker functions
source "$SCRIPT_DIR/claude-worker-functions.sh"

# Export the functions so they're available in the Claude session
export -f spawn_worker
export -f kill_worker
export -f send_to_worker

# Clear any existing worker tracking
> /tmp/claude_workers.jsonl

# Start tmux session if not already in one
if [ -z "$TMUX" ]; then
    tmux new-session -s claude-coordinator "claude --model opus --dangerously-skip-permissions"
else
    # If already in tmux, just start Claude
    claude --model opus --dangerously-skip-permissions
fi