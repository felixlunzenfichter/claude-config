# Claude Worker Instance

You are a Claude worker instance spawned by the root controller to perform specific tasks.

## CRITICAL: ALWAYS USE TMUX - NEVER USE BASH DIRECTLY
Since this is a fully accessible system, you MUST use tmux for ALL command execution:

### Why tmux is Essential
- Claude Code's Bash tool runs in non-interactive mode (no TTY)
- Processes started with Bash die when the command finishes
- tmux provides persistent sessions that survive
- User cannot manually manage processes due to accessibility needs

### Quick Reference
```bash
# Create session
tmux new-session -d -s [name] "command"

# Send commands
tmux send-keys -t [name] "command" Enter

# Check output
tmux capture-pane -t [name] -p

# List sessions
tmux list-sessions

# Kill session
tmux kill-session -t [name]
```

## Server Management
When starting any server or long-running process:

1. **Check if already running**
   ```bash
   tmux list-sessions | grep [name]
   ```

2. **Kill existing if needed**
   ```bash
   tmux kill-session -t [name] 2>/dev/null
   ```

3. **Start in tmux**
   ```bash
   tmux new-session -d -s [name] "npm start"
   ```

4. **Verify it's running**
   ```bash
   tmux capture-pane -t [name] -p | tail -20
   ```

## Process Monitoring
- Wait for startup messages before assuming success
- Check for errors: EADDRINUSE, "Cannot find module", etc.
- Monitor for at least 10 seconds after starting
- Never assume a process is running just because tmux started

## Common Patterns

### Development Server
```bash
tmux new-session -d -s dev-server "npm run dev"
tmux capture-pane -t dev-server -p
```

### Background Task
```bash
tmux new-session -d -s worker "node worker.js"
```

### Monitoring Logs
```bash
tmux new-session -d -s logs "tail -f app.log"
tmux attach -t logs  # For user to view
```

## Remember
- You're working on behalf of a user with physical limitations
- Everything must be automated and persistent
- No manual intervention is possible
- Always use tmux for any process that needs to keep running