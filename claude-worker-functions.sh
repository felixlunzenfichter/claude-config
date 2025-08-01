#!/bin/bash

# Claude Worker Management Functions
# These functions are automatically loaded when starting Claude Coordinator

# Function to spawn and track workers
spawn_worker() {
  local WORKER_NAME=$1
  local WORK_DIR=$2
  local START_MESSAGE=$3
  
  # Spawn worker with Opus model and capture pane ID
  local PANE_ID=$(tmux split-window -h -P -F "#{pane_id}" "cd $WORK_DIR && claude --model opus --dangerously-skip-permissions")
  
  # Set pane ID as variable
  eval "export $WORKER_NAME=$PANE_ID"
  
  # Adjust layout for even distribution
  tmux select-layout even-horizontal
  
  # Track in file for stop button system
  echo "{\"name\": \"$WORKER_NAME\", \"paneId\": \"$PANE_ID\"}" >> /tmp/claude_workers.jsonl
  
  # Send start message if provided
  if [ -n "$START_MESSAGE" ]; then
    send_to_worker $PANE_ID "$START_MESSAGE"
  fi
  
  echo $PANE_ID
}

# Function to kill workers cleanly
kill_worker() {
  local PANE_ID=$1
  
  # Kill the pane
  tmux kill-pane -t "$PANE_ID"
  
  # Rebalance windows
  tmux select-layout even-horizontal
  
  # Remove from tracking file
  grep -v "\"paneId\": \"$PANE_ID\"" /tmp/claude_workers.jsonl > /tmp/claude_workers.tmp
  mv /tmp/claude_workers.tmp /tmp/claude_workers.jsonl
}

# Function to send messages to workers with proper timing
send_to_worker() {
  local PANE_ID=$1
  local MESSAGE=$2
  
  tmux send-keys -t "$PANE_ID" "$MESSAGE"
  sleep 1
  tmux send-keys -t "$PANE_ID" Enter
}