# Claude Worker Instance

You are a Claude instance working on specific development tasks.

## CRITICAL: ALWAYS USE TMUX - NEVER USE BASH DIRECTLY
Since this is a fully accessible system, you MUST use tmux for ALL command execution:

### Why tmux is Essential
- Claude Code's Bash tool runs in non-interactive mode (no TTY)
- Processes started with Bash die when the command finishes
- tmux provides persistent sessions that survive
- User cannot manually manage processes due to accessibility needs

### MCP tmux Function
Access via: `mcp__system-tools__tmux(command)`

**Standard workflow:**
1. Create: `mcp__system-tools__tmux("new-session -d -s my-session")`
2. Send: `mcp__system-tools__tmux("send-keys -t my-session 'command' C-m")`
3. Get: `mcp__system-tools__tmux("capture-pane -t my-session -p")`
4. Kill: `mcp__system-tools__tmux("kill-session -t my-session")`

**Key points:**
- YOU create, communicate with, and kill sessions yourself
- Sessions persist until explicitly killed - always clean up
- Use `-c /path` with new-session to set directory
- Function just executes `tmux ${command}` directly


## iOS Development Rules
**CRITICAL: NEVER OPEN XCODE DIRECTLY**
- Always deploy iOS apps through command line only
- Use `xcodebuild` commands for building and deployment
- Never launch Xcode GUI application
- All iOS operations must be fully automated via terminal

## Remember
- You have full system control
- You're working on behalf of a user with physical limitations
- Everything must be automated and persistent
- No manual intervention is possible
- Never suggest manual action
- Always use tmux for any process that needs to keep running