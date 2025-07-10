#!/bin/bash

# Service monitoring script for Claude Code
# Checks essential services and alerts when they're down

# Services to monitor
declare -A SERVICES=(
    ["mac-receiver"]="/Users/felixlunzenfichter/Documents/ClaudeCodeVoiceControl-Stable/mac-transcription-server"
    ["narrator"]="/Users/felixlunzenfichter/Documents/macos-voice-control"
)

# Track service states and last alert times
declare -A SERVICE_STATES
declare -A LAST_ALERT_TIME

# Initialize states
for service in "${!SERVICES[@]}"; do
    SERVICE_STATES[$service]="unknown"
    LAST_ALERT_TIME[$service]=0
done

# Function to send alert to terminal
send_alert() {
    local message="$1"
    # Send to the main tmux session
    tmux send-keys -t main C-c Enter "# ALERT: $message" Enter 2>/dev/null || true
}

# Function to check if a tmux session exists and is running
check_service() {
    local service_name="$1"
    
    # Check if tmux session exists
    if tmux has-session -t "$service_name" 2>/dev/null; then
        # Check if the process in the session is actually running
        local pane_pid=$(tmux list-panes -t "$service_name" -F '#{pane_pid}' 2>/dev/null | head -1)
        if [ -n "$pane_pid" ] && kill -0 "$pane_pid" 2>/dev/null; then
            return 0  # Service is running
        fi
    fi
    return 1  # Service is not running
}

# Main monitoring loop
while true; do
    for service in "${!SERVICES[@]}"; do
        current_time=$(date +%s)
        
        if check_service "$service"; then
            # Service is running
            if [ "${SERVICE_STATES[$service]}" = "down" ]; then
                # Service just came back up
                SERVICE_STATES[$service]="up"
                send_alert "Service $service is back online ✓"
            elif [ "${SERVICE_STATES[$service]}" = "unknown" ]; then
                SERVICE_STATES[$service]="up"
            fi
        else
            # Service is not running
            if [ "${SERVICE_STATES[$service]}" != "down" ]; then
                # Service just went down
                SERVICE_STATES[$service]="down"
                LAST_ALERT_TIME[$service]=$current_time
                send_alert "Service $service is DOWN! Starting it now..."
                
                # Attempt to start the service
                case "$service" in
                    "mac-receiver")
                        tmux new-session -d -s mac-receiver -c "${SERVICES[$service]}" "node server.js"
                        ;;
                    "narrator")
                        tmux new-session -d -s narrator -c "${SERVICES[$service]}" "python openai-tts-narrator.py"
                        ;;
                esac
            else
                # Service has been down - check if we should send another alert
                time_since_last_alert=$((current_time - LAST_ALERT_TIME[$service]))
                if [ $time_since_last_alert -ge 10 ]; then
                    send_alert "Service $service is still DOWN!"
                    LAST_ALERT_TIME[$service]=$current_time
                fi
            fi
        fi
    done
    
    # Check every second
    sleep 1
done