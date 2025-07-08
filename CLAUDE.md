# Claude Code Accessibility Configuration

## External Voice Transcription System

The user interacts with Claude Code through an external voice transcription application that automatically types into the terminal. This enables fully accessible, hands-free interaction.

### How the External System Works
- A separate voice transcription app (https://github.com/felixlunzenfichter/live-transcription-app) runs alongside Claude Code
- Voice is continuously transcribed using Google Speech-to-Text
- Final transcriptions are automatically typed into the Claude Code terminal using AppleScript
- After typing each sentence, Enter is pressed automatically after 1 second
- This is NOT Claude's auto-typing feature - it's an external accessibility tool

### User Context
- The user may have physical limitations preventing keyboard/mouse use
- All interactions happen through the external voice transcription system
- The transcription app types directly into whatever text field has focus (usually Claude Code terminal)
- Claude Code runs with `--dangerously-skip-permissions` for seamless command execution

### Important Configuration
- The external transcription system is always active during Claude Code sessions
- Voice commands appear as regular text input in Claude Code
- Claude Code runs with `--dangerously-skip-permissions` flag
- All commands are automatically executed without manual approval prompts
- This enables fully accessible computing for users with mobility limitations

### Permission Handling in Skip Mode
Since the user cannot interact with accept/reject prompts:
- Claude should be more conversational about potentially destructive actions
- Ask for verbal confirmation before: deleting files, force pushing, running rm -rf, etc.
- Example: "This will delete 10 files. Should I proceed?" (user responds verbally)
- Wait for affirmative response in the conversation before executing risky commands
- This replaces the traditional accept/reject UI with conversational consent

### Git Operations and Code Changes
When staging changes or performing git operations:
- Verbally present all changes before committing
- Read out the files being modified and describe the changes
- Example: "I'm about to stage 3 files: 
  - server.js: Added mute button detection at line 150
  - index.html: Updated the UI to show mute status
  - README.md: Added documentation for the mute feature
  Should I proceed with staging these changes?"
- For commits, read the commit message aloud before executing
- Describe what git status shows in a user-friendly way

### Interaction Guidelines

1. **Voice-First Approach**
   - All commands come through the external voice transcription
   - Responses should be concise and voice-friendly
   - Assume all text is spoken, not typed

2. **Automated Everything**
   - Every action must be performed through Claude's tools
   - No manual steps or UI interactions
   - Complete all tasks programmatically

3. **Accessibility Focus**
   - The system is designed for users who cannot use keyboard/mouse
   - Never suggest manual actions
   - Always provide fully automated solutions

4. **Code Navigation Assistance**
   - Since the user cannot navigate files manually, verbally guide them through code changes
   - Explain what files are being modified and why
   - Describe the location of changes (e.g., "Adding error handling at line 45 in server.js")
   - Read relevant code sections aloud when requested
   - Provide verbal summaries of code structure and organization
   - Example: "I'm now updating the server configuration in server.js. This change adds audio monitoring to detect when you press your mute button."

5. **Automatic App Execution and Monitoring**
   - After making code changes, always run/restart the application
   - The user cannot manually run apps, so Claude must handle all execution
   - Kill existing processes if needed before restarting
   
   **CRITICAL: ALWAYS USE TMUX - NEVER USE BASH DIRECTLY**
   Since this is a fully accessible system, you MUST use tmux for ALL command execution:
   - Create a default tmux session called "main" for general commands: `tmux new-session -d -s main`
   - For ANY long-running process (servers, monitors, etc.), create a dedicated tmux session
   - NEVER use `bash` tool directly for running processes
   - NEVER use `&` to background processes
   - ALWAYS use tmux to ensure persistent sessions that survive disconnections
   
   Example workflow:
   - Quick commands: `tmux send-keys -t main "ls -la" Enter`
   - Start a server: `tmux new-session -d -s server "node server.js"`
   - Check output: `tmux capture-pane -t server -p`
   - Attach for user: `tmux attach -t server`
   
   This ensures the user can always reconnect to running processes, which is critical for accessibility.
   
   **CRITICAL: Monitor ALL Execution Stages**
   - Don't just start a process - verify it's actually running properly
   - For any app/server startup:
     1. Start the process
     2. Wait for startup messages
     3. Check for error messages
     4. Verify expected behavior (ports listening, connections established, etc.)
     5. Test basic functionality
   
   **For Node.js servers:**
   - Must see "Server started" or similar message
   - Check for "Connected to backend" or database connections
   - Verify WebSocket connections are established
   - Monitor for at least 10 seconds to catch startup errors
   
   **Common patterns to watch for:**
   - "EADDRINUSE" - Port already in use
   - "Cannot find module" - Missing dependencies
   - "Connection refused" - Backend not accessible
   - Silent failures - Process starts but immediately exits
   
   - Always run with visible output - never background processes
   - Example: After updating server.js, run it and WAIT to see "Connected to transcription backend"
   
   **For iOS/macOS Xcode Projects:**
   - ALWAYS run apps via command line, NOT through Xcode UI
   - Connected iPhone ID: 00008101-000359212650001E
   - Use the script: `/Users/felixlunzenfichter/Documents/ClaudeCodeVoiceControl/run-on-iphone.sh`
   - This script will:
     1. Detect the connected iPhone
     2. Build the project using xcodebuild
     3. Install and launch on the iPhone
     4. Show build output and any errors
   - Usage from project directory: `./run-on-iphone.sh`
   
   **CRITICAL: Always Monitor Build Output**
   - The script output MUST show these key messages in order:
     1. "Building for iPhone..." - Build started
     2. "** BUILD SUCCEEDED **" - Build completed successfully
     3. "Installing and running on iPhone..." - Installation starting
     4. "App installed:" with bundleID - Installation successful
     5. "Launched application" - App is running
   - If ANY of these messages are missing, the app is NOT running
   - Common issues to check:
     - Build errors: Look for red error messages in output
     - Missing provisioning profiles
     - Device not trusted
     - App crash on launch
   
   **Log Files to Monitor:**
   - Build logs: Check for compilation errors
   - Console output: Run `xcrun devicectl device process list` to verify app is running
   - Server logs: Check `/tmp/claude_conversation.log` for transcription activity
   - Always read through ALL output before confirming success
   
   **RUNTIME LOG MONITORING:**
   - ALL applications MUST write runtime logs to files
   - Monitor these logs CONTINUOUSLY during execution:
     - Server logs: `/tmp/server_debug.log` or similar
     - iOS app logs: Use `xcrun devicectl device log` to capture device logs
     - WebSocket connection logs
     - Error logs
   - Every Node.js server MUST include:
     ```javascript
     const LOG_FILE = path.join(__dirname, 'runtime.log');
     function log(message) {
       const timestamp = new Date().toISOString();
       const logEntry = `[${timestamp}] ${message}\n`;
       console.log(logEntry.trim());
       fs.appendFileSync(LOG_FILE, logEntry);
     }
     ```
   - After starting ANY process:
     1. tail -f the log file
     2. Watch for successful startup messages
     3. Monitor for errors
     4. Verify expected connections are established
     5. Confirm data is flowing (transcripts, responses, etc.)
   - NEVER assume an app is working just because the process started
   - Always verify through runtime logs that:
     - Connections are established
     - Data is being received
     - Responses are being sent
     - No errors are occurring
   
   - Alternative direct command:
     ```bash
     xcodebuild -project ClaudeCodeVoiceControl.xcodeproj \
       -scheme ClaudeCodeVoiceControl \
       -destination 'id=00008101-000359212650001E' \
       -configuration Debug \
       clean build
     ```
   - This provides full visibility into the build process and errors
   - The user can see all output without manual Xcode interaction

6. **Proactive Task List Usage**
   - Use task lists for any multi-step work to ensure nothing is forgotten
   - Voice interactions can be non-linear, so task lists help maintain focus
   - Always show the task list status when working through complex changes
   - Mark tasks complete immediately after finishing them
   - Example task list for a feature:
     1. Understand the requirement
     2. Modify the necessary files
     3. Test the changes
     4. Commit to git
     5. Push to repository

   - Execute the app and report any errors or issues
   - For web apps, open the browser automatically
   - For CLI tools, run them with appropriate test commands
   - Example: "I've updated the server. Let me run it now to make sure the mute detection works properly."

### Technical Details
- External transcription app shows real-time transcription in browser
- Only final (confirmed) transcriptions are typed into Claude Code
- Empty transcriptions are ignored
- 1 second delay before Enter allows for natural speech patterns
- Uses AppleScript to simulate keyboard input

### Examples of Appropriate Interactions
- ✅ User speaks: "Create a new Python file" → Transcription app types it → Claude creates file
- ✅ User speaks: "Run the tests" → Transcription app types it → Claude executes tests
- ✅ User speaks: "Deploy to production" → Transcription app types it → Claude runs deployment
- ✅ User speaks: "Show me the error" → Transcription app types it → Claude reads and explains

## Test-Driven Development (TDD) Approach

This project follows strict Test-Driven Development principles:

### TDD Rules
1. **Red**: Write a failing test first
   - Write only enough test code to make it fail
   - The test defines the desired behavior
   - Run the test to confirm it fails for the right reason

2. **Green**: Write minimal code to pass
   - Write only enough production code to make the test pass
   - Don't write more functionality than the test requires
   - Keep the implementation simple

3. **Refactor**: Clean up the code
   - Improve code structure without changing behavior
   - All tests must continue to pass
   - Remove duplication and improve readability

### TDD Workflow for Voice Development
- User describes desired functionality through voice
- Claude writes the failing test first
- Run test to verify it fails appropriately
- Write minimal implementation to pass the test
- Run test to verify it passes
- Refactor if needed while keeping tests green
- Commit each complete TDD cycle

### Testing Infrastructure
- **Test Execution**: Use `xcodebuild test -project ClaudeCodeVoiceControl.xcodeproj -scheme ClaudeCodeVoiceControl -destination 'id=00008101-000359212650001E' -only-testing:ClaudeCodeVoiceControlTests`
- **iPhone Device**: 00008101-000359212650001E
- **Run Script**: `./run-on-iphone.sh` for app deployment
- **Live Feedback**: Xcode provides real-time test indicators (✅/❌)

### First Successful Test Milestone
✅ **Microphone Permission Test** - Validates device audio access
- Test: `testMicrophonePermission()` in ClaudeCodeVoiceControlTests
- Status: PASSED ✅ - Microphone permission GRANTED
- Execution: 0.007 seconds on device
- Foundation for voice-controlled accessibility features

## Critical Reminder
This system enables fully accessible computing through voice alone. The user relies on:
1. The external voice transcription app to convert speech to text
2. Claude Code to execute all computer operations

**The only interface to Claude Code is through voice transcription, and the only interface to the computer is through Claude Code.** We are building the first fully accessible computing system in the world - this is the first time true voice-only computer control has been possible.

Every interaction must be:
- Fully automated through Claude's tools
- Accessible via voice commands only
- Completed without any manual intervention
- Follow TDD principles for sustainable development

The combination of the external voice transcription system and Claude Code with skipped permissions creates a powerful accessibility tool for users with physical limitations.

## CRITICAL SAFETY GUIDELINES

### Root Directory Operations
- **WARNING**: You are currently working in the root directory (/Users/felixlunzenfichter)
- Be EXTREMELY careful with any file operations that could affect system files
- ALWAYS ask for explicit verbal confirmation before:
  - Deleting any files or directories
  - Moving or renaming files
  - Running commands with sudo
  - Executing rm -rf or any recursive deletion
  - Modifying system configuration files
  - Installing or uninstalling software
- Example: "This command will delete files in your home directory. Should I proceed?"
- Wait for clear verbal confirmation like "yes, proceed" before executing

### Automatic Git Operations
- When working in a git repository, ALWAYS push changes immediately after every modification
- After any file edit, addition, or deletion:
  1. Stage the changes with git add
  2. Commit with a descriptive message
  3. Push to the remote repository
- This ensures no work is lost and provides immediate backup
- Example workflow:
  - Edit file → git add → git commit → git push
  - All in one continuous operation without waiting
- This is especially important given the voice-only interface where manual git operations are difficult

## Long-Running Processes with tmux

### Why tmux is Essential
- Claude Code's Bash tool runs in non-interactive mode (no TTY)
- Processes that need continuous operation must run in tmux sessions
- This provides real terminal environments for servers, monitors, and interactive tools

### Required tmux Usage
For ANY process that needs to run continuously (servers, narrators, monitors), ALWAYS use tmux:

1. **Create session**: `tmux new-session -d -s [name] "command"`
   - Example: `tmux new-session -d -s narrator "cd /path && python app.py"`
   
2. **Check output**: `tmux capture-pane -t [name] -p`
   - Use with `| tail -20` to see recent output
   - Use with `| head -20` to see startup messages
   
3. **Send commands**: `tmux send-keys -t [name] "command" Enter`
   - Useful for interacting with running processes
   
4. **List sessions**: `tmux list-sessions`
   - Always check what's already running
   
5. **Kill session**: `tmux kill-session -t [name]`
   - Clean up when done

### Common Use Cases
- **Python/Node.js servers**: Always run in tmux
- **Monitoring tools**: Keep them running in background
- **Interactive CLIs**: Maintain their state in tmux
- **Voice narrators**: Run Gemini Live API tools in tmux

### Example Workflow
```bash
# Check if session exists
tmux list-sessions | grep narrator || echo "Not running"

# Start narrator
tmux new-session -d -s narrator "cd ~/project && python narrator.py"

# Monitor output
tmux capture-pane -t narrator -p | tail -20

# Stop when done
tmux kill-session -t narrator
```

This ensures all long-running processes remain accessible and manageable.

