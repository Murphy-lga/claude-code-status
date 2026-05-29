# Claude Code Status Monitor

A minimalist, always-on-top HUD bar that shows Claude Code's real-time status — idle, thinking, executing, waiting, or done. No need to watch the terminal.

![Status](https://img.shields.io/badge/status-active-success)
![Platform](https://img.shields.io/badge/platform-windows-blue)
![License](https://img.shields.io/badge/license-MIT-green)

[English](README_en.md) | [简体中文](README.md)

## Preview

| State | Color | Meaning |
|-------|-------|---------|
| IDLE | Gray | Just started, waiting for input |
| THINKING | Yellow | Analyzing your prompt |
| EXECUTING | Blue | Running a tool / command |
| WAITING | Purple | Waiting for your confirmation |
| DONE | Green | Reply finished |
| ERROR | Red | Something went wrong |

## Requirements

- **Windows 10/11** (uses WinForms, a Windows-native component)
- **Claude Code** CLI installed
- **PowerShell 5+** (bundled with Windows)
- **Node.js** (for the `write-status.js` hook script)

## Compatibility

> **This project only supports Claude Code CLI.** It does not work with the "Claude Code for VS Code" extension.
>
> **Why:** CLI and VS Code extension use separate hook configurations. CLI reads hooks from `%USERPROFILE%\.claude\settings.json`, while the extension reads hooks from `"claudeCode.hooks"` in VS Code's `settings.json` — the two are completely independent. Hooks configured in one are not picked up by the other, so `write-status.js` will never fire from the extension.
>
> If you use both, you need to add hooks separately in each configuration file.

## Quick Start

> **Before installing**: Download this project first. Click **Code → Download ZIP** on the GitHub page, extract it, and open the extracted folder. No `git clone` needed.

### Option A: One-click install

Run `install.bat` and follow the prompts. It will:
1. Copy hook scripts to `%USERPROFILE%\.claude\scripts\`
2. Configure Claude Code hooks in `%USERPROFILE%\.claude\settings.json`
3. Launch the monitor window

### Option B: Manual setup

**Step 1: Copy scripts to your .claude directory**

Select the following three files from the project's `scripts\` folder:

- `write-status.js`
- `status-monitor.ps1`
- `launch-monitor.bat`

Copy them into `%USERPROFILE%\.claude\scripts\` (create the `scripts` folder if it doesn't exist). You can paste `%USERPROFILE%\.claude\scripts` directly into the File Explorer address bar to open it quickly.

**Step 2: Add the `"hooks"` block to `%USERPROFILE%\.claude\settings.json`**

Create the file if it doesn't exist; merge with existing hooks if present. Replace `C:\Users\YourName` with your actual user path (run `echo %USERPROFILE%` in CMD to find it):

```json
{
  "hooks": {
    "SessionStart":     [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" start",     "async": true }] }],
    "UserPromptSubmit": [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" thinking", "async": true }] }],
    "PreToolUse":       [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" executing","async": true }] }],
    "PostToolUse":      [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" thinking", "async": true }] }],
    "Notification":     [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" confirm", "async": true }] }],
    "Stop":             [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" done",     "async": true }] }],
    "SessionEnd":       [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\YourName\\.claude\\scripts\\write-status.js\" done",     "async": true }] }]
  }
}
```

**Step 3: Launch the monitor**

Double-click `%USERPROFILE%\.claude\scripts\launch-monitor.bat`. Or paste `%USERPROFILE%\.claude\scripts` into the File Explorer address bar, press Enter, then double-click `launch-monitor.bat`.

### To restart later

After installation, the hooks are permanently saved in `%USERPROFILE%\.claude\settings.json` and will fire automatically each time you start Claude Code — no need to reinstall or reconfigure. After closing the monitor, restart it with either method below:

**Option 1: Double-click the launch script**

Open File Explorer, navigate to `%USERPROFILE%\.claude\scripts\` (you can paste this path directly into the address bar and press Enter), then double-click `launch-monitor.bat`.

**Option 2: Run from command line**

Press `Win + R` to open the Run dialog, paste the following command, and press Enter:

```
powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\scripts\status-monitor.ps1"
```

Or run the same command in any open terminal (CMD / PowerShell).

## How It Works

```
Claude Code ──hook──> write-status.js ──write──> claude-status.json
                                                     │
status-monitor.ps1 ──poll every 500ms ──read──────────┘
       │
       └─> WinForms window (always-on-top, draggable, borderless)
```

### Hooks

| Hook | Trigger | Status Written |
|------|---------|---------------|
| SessionStart | Claude Code starts | `idle` |
| UserPromptSubmit | User sends a message | `thinking` |
| PreToolUse | Claude calls a tool | `executing` |
| PostToolUse | Tool execution complete | `thinking` |
| Notification | Claude waits for confirmation | `confirm` |
| Stop | Claude finishes a reply | `done` |
| SessionEnd | Session exits | `done` |

## Window Features

- **Borderless capsule** — pill-shaped (180x44px), rounded corners
- **Always on top** — stays above all other windows
- **Draggable** — grab anywhere to reposition
- **Pulse animation** — status dot breathes during active states
- **Dark background** — `#1e1e2e` Catppuccin-inspired dark theme
- **Low overhead** — polls every 500ms, no CPU spike

## Uninstall

### Pause: close the monitor window

Just close the HUD window. Hooks still write the status file silently.

### Remove completely

1. **Remove hooks** — delete the `"hooks"` block from `%USERPROFILE%\.claude\settings.json`
2. **Delete scripts**:
   ```
   del "%USERPROFILE%\.claude\scripts\write-status.js"
   del "%USERPROFILE%\.claude\scripts\status-monitor.ps1"
   del "%USERPROFILE%\.claude\scripts\launch-monitor.bat"
   del "%USERPROFILE%\.claude\claude-status.json"
   ```

## Notes

- Start the monitor **before** opening Claude Code; otherwise it shows "CONNECTING" initially
- Multiple Claude Code instances: the status file reflects the last write
- After a reply, if you don't respond within ~60s, Claude Code's timeout fires `Notification` hook — status turns purple as a gentle "waiting for input" cue

## License

MIT
