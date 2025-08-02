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
The MCP system provides a tmux function that handles tmux command execution. Here's the actual implementation:

```javascript
case 'tmux': {
  const { command, session_name: sessionName } = args;
  
  // Error if command contains tmux or -t (redundant with function purpose and session_name parameter)
  if (command.startsWith('tmux')) {
    throw new Error('Command should not start with "tmux". Just pass the tmux subcommand.');
  }
  if (command.includes('-t ')) {
    throw new Error('Command should not contain -t flag. Use session_name parameter instead.');
  }
  
  // Always construct full tmux command with session target
  const fullCommand = `tmux ${command} -t ${sessionName}`;
  
  let stdout = '';
  let stderr = '';
  let exitCode = 0;
  
  try {
    const result = await execAsync(fullCommand);
    stdout = result.stdout || '';
    stderr = result.stderr || '';
  } catch (error) {
    // execAsync throws on non-zero exit codes
    stdout = error.stdout || '';
    stderr = error.stderr || '';
    exitCode = error.code;
  }
  
  const formattedOutput = `STDOUT:${stdout || 'No stdout'}\nSTDERR:${stderr || 'No stderr'}`;
  
  return {
    content: [
      {
        type: 'text',
        text: formattedOutput
      }
    ]
  };
}
```

**Important Notes:**
- session_name is REQUIRED for all commands (no empty strings)
- For global commands like list-sessions, use "default" as the session name
- To create sessions in specific directories, use `-c /path/to/dir` with new-session
- For existing sessions, use send-keys to change directories (tmux limitation)

## Voice Control System Management

### Starting the Voice Control Servers
```javascript
// 1. Kill existing sessions (ignore errors if not running)
mcp__system-tools__tmux("kill-session", "backend")
mcp__system-tools__tmux("kill-session", "mac-server")

// 2. Start Backend Server (with Google credentials)
mcp__system-tools__tmux("new-session -d -c /Users/felixlunzenfichter/Documents/macos-voice-control/backend 'GOOGLE_APPLICATION_CREDENTIALS=/Users/felixlunzenfichter/.config/gcloud/legacy_credentials/id-speech-to-text-app@gen-lang-client-0047710702.iam.gserviceaccount.com/adc.json node server.js'", "backend")

// 3. Start Mac Server (handles transcription & TTS)
mcp__system-tools__tmux("new-session -d -c /Users/felixlunzenfichter/Documents/macos-voice-control/mac-server 'npm start'", "mac-server")

// 4. Wait for startup then check status
setTimeout(() => {
  mcp__system-tools__tmux("capture-pane -p | tail -10", "backend")
  // Should show: "Server running on port 8080"
  
  mcp__system-tools__tmux("capture-pane -p | tail -10", "mac-server")
  // Should show: "Connected to transcription backend", "✅ TTS enabled with OpenAI"
}, 3000);
```

## Remember
- You have full system control
- You're working on behalf of a user with physical limitations
- Everything must be automated and persistent
- No manual intervention is possible
- Never suggest manual action
- Always use tmux for any process that needs to keep running