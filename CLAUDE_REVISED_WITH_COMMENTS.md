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

### Output Narration System
<!-- NEW SECTION: Critical for understanding how responses should be formatted -->
- All Claude responses are narrated using OpenAI TTS (Text-to-Speech)
- The narrator reads the entire response aloud with a British accent
- This affects response formatting:
  - Avoid ASCII art or visual diagrams (won't translate well to speech)
  - Use clear punctuation for natural speech flow
  - Spell out symbols when important (e.g., "dollar sign" instead of just "$")
  - Keep file paths and commands clear and unambiguous
  - Avoid long lists of similar items (hard to follow when narrated)
- The user is often looking away from the screen while listening to responses

<!-- REMOVED: "Important Configuration" section - this info was redundant with "User Context" and the skip-permissions info is already mentioned above -->

### Permission Handling in Skip Mode
Since the user cannot interact with accept/reject prompts:
- Claude should be more conversational about potentially destructive actions
- Ask for verbal confirmation before: deleting files, force pushing, running rm -rf, etc.
- Example: "This will delete 10 files. Should I proceed?" (user responds verbally)
- Wait for affirmative response in the conversation before executing risky commands
- This replaces the traditional accept/reject UI with conversational consent

<!-- MOVED: Git operations section will be consolidated later with other git-related content -->

## Interaction Guidelines

<!-- RESTRUCTURED: Combining all the scattered interaction guidelines into one coherent section -->

### 1. Voice-First Approach
- All commands come through the external voice transcription
- All responses are narrated by OpenAI TTS
- Responses should be concise and voice-friendly
- Expect transcription errors (homophones, unclear words, punctuation issues)
- Be forgiving of typos and grammatical oddities from voice transcription
- When unclear, ask for clarification rather than guessing
- If transcription seems completely wrong or nonsensical, ask: "I think the transcription might be incorrect. Could you repeat that?"
- Structure responses for listening, not reading

### 2. Automated Everything
- Every action must be performed through Claude's tools
- No manual steps or UI interactions
- Complete all tasks programmatically

### 3. Accessibility Focus
- The system is designed for users who cannot use keyboard/mouse
- Never suggest manual actions
- Always provide fully automated solutions

### 4. Code Navigation Assistance
- Since the user cannot navigate files manually, verbally guide them through code changes
- Explain what files are being modified and why
- Describe the location of changes (e.g., "Adding error handling at line 45 in server.js")
- Read relevant code sections aloud when requested
- Provide verbal summaries of code structure and organization

### 5. Proactive Task List Usage
- Use task lists for any multi-step work to ensure nothing is forgotten
- Voice interactions can be non-linear, so task lists help maintain focus
- Always show the task list status when working through complex changes
- Mark tasks complete immediately after finishing them

## Command Execution and Process Management

<!-- MAJOR CONSOLIDATION: Combining "Automatic App Execution", "ALWAYS USE TMUX", and "Long-Running Processes with tmux" sections -->

### CRITICAL: ALWAYS USE TMUX - NEVER USE BASH DIRECTLY
Since this is a fully accessible system, you MUST use tmux for ALL command execution:

<!-- REMOVED: Redundant explanation about why tmux is needed - covered in one place now -->

#### Quick Reference
- Create main session: `tmux new-session -d -s main`
- Quick commands: `tmux send-keys -t main "ls -la" Enter`
- Start a server: `tmux new-session -d -s server "node server.js"`
- Check output: `tmux capture-pane -t server -p`
- List sessions: `tmux list-sessions`
- Kill session: `tmux kill-session -t [name]`
- Attach for user: `tmux attach -t server`

<!-- REMOVED: Multiple redundant examples of tmux usage - kept only essential commands -->

### Process Monitoring Requirements
<!-- CONSOLIDATED: Combined all the monitoring requirements from multiple sections -->

After starting ANY process:
1. Verify it's actually running (don't just assume)
2. Check for startup messages
3. Watch for error messages
4. Verify expected behavior (ports listening, connections established)
5. Monitor logs continuously

**Common failure patterns:**
- "EADDRINUSE" - Port already in use
- "Cannot find module" - Missing dependencies
- "Connection refused" - Backend not accessible
- Silent failures - Process starts but immediately exits

<!-- REMOVED: Repetitive examples for Node.js, iOS, etc. - keeping only unique platform-specific info below -->

### Platform-Specific Guidelines

#### Node.js Applications
- Must see "Server started" or similar message
- Verify WebSocket/database connections
- Include logging to file:
```javascript
const LOG_FILE = path.join(__dirname, 'runtime.log');
function log(message) {
  const timestamp = new Date().toISOString();
  const logEntry = `[${timestamp}] ${message}\n`;
  console.log(logEntry.trim());
  fs.appendFileSync(LOG_FILE, logEntry);
}
```

#### iOS/macOS Xcode Projects
- Connected iPhone ID: 00008101-000359212650001E
- Use script: `/Users/felixlunzenfichter/Documents/ClaudeCodeVoiceControl/run-on-iphone.sh`
- Alternative: `xcodebuild -project [project].xcodeproj -scheme [scheme] -destination 'id=00008101-000359212650001E' clean build`

<!-- REMOVED: Redundant build output monitoring instructions - already covered in general monitoring -->

## Git Operations

<!-- CONSOLIDATED: Combined git operations from multiple sections -->

### Git Workflow for Voice Development
When working with git:
1. **Before any changes**: Verbally describe what will be modified
2. **After changes**: Automatically stage, commit, and push
3. **For commits**: Read the commit message aloud before executing

### Automatic Git Operations
<!-- MOVED: From the safety guidelines section since it's more about workflow than safety -->
After any file edit, addition, or deletion:
1. Stage the changes with `git add`
2. Commit with a descriptive message
3. Push to the remote repository
4. This ensures no work is lost and provides immediate backup

<!-- REMOVED: Examples that were redundant with the workflow description -->

## Test-Driven Development (TDD) Approach

<!-- KEPT AS IS: This section is well-structured and not redundant -->

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

<!-- REMOVED: First successful test milestone - too specific and not a general guideline -->

## Safety Guidelines

<!-- SIMPLIFIED: Removed "CRITICAL" redundancy and consolidated safety rules -->

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

<!-- REMOVED: Technical details section - information was either redundant or too specific -->
<!-- REMOVED: Examples section - examples are now integrated where relevant -->

## Critical Reminder

<!-- CONSOLIDATED: Combined the key points from multiple "critical" sections -->

This system enables fully accessible computing through voice alone. The user relies on:
1. The external voice transcription app to convert speech to text
2. Claude Code to execute all computer operations

**The only interface to Claude Code is through voice transcription, and the only interface to the computer is through Claude Code.**

Every interaction must be:
- Fully automated through Claude's tools
- Accessible via voice commands only
- Completed without any manual intervention
- Use tmux for all command execution
- Follow TDD principles for sustainable development

<!-- REMOVED: Final paragraph about this being the "first fully accessible computing system" - while impressive, it's not essential for the configuration -->

# important-instruction-reminders
<!-- KEPT AS IS: These reminders are concise and important -->
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.