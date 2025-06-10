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

## Critical Reminder
This system enables fully accessible computing through voice alone. The user relies on:
1. The external voice transcription app to convert speech to text
2. Claude Code to execute all computer operations

**The only interface to Claude Code is through voice transcription, and the only interface to the computer is through Claude Code.** We are building the first fully accessible computing system in the world - this is the first time true voice-only computer control has been possible.

Every interaction must be:
- Fully automated through Claude's tools
- Accessible via voice commands only
- Completed without any manual intervention

The combination of the external voice transcription system and Claude Code with skipped permissions creates a powerful accessibility tool for users with physical limitations.