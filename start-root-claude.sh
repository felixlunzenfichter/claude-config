#!/bin/bash

# Start Claude Coordinator with auto-loaded worker functions

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Kill any existing test session
tmux kill-session -t claude_orchestrator_test 2>/dev/null

# Source the worker functions
source "$SCRIPT_DIR/claude-worker-functions.sh"

# Start new tmux session
tmux new-session -d -s claude_orchestrator_test

# Export the functions so they're available in the Claude session
export -f spawn_worker
export -f kill_worker
export -f send_to_worker

# Send command to start Claude with sourced functions
tmux send-keys -t claude_orchestrator_test "source '$SCRIPT_DIR/claude-worker-functions.sh' && claude --model opus --dangerously-skip-permissions" Enter

# Clear any existing worker tracking
> /tmp/claude_workers.jsonl

# Attach to the session
tmux attach -t claude_orchestrator_test