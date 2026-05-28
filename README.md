# Claude Code Status Monitor

A minimalist, always-on-top HUD bar that shows Claude Code's real-time status — idle, thinking, executing, waiting, or done. No need to watch the terminal.

![Status](https://img.shields.io/badge/status-active-success)
![Platform](https://img.shields.io/badge/platform-windows-blue)
![License](https://img.shields.io/badge/license-MIT-green)

[简体中文](README_zh-CN.md) | [English](README.md)

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

## Quick Start

### Option A: One-click install

Run `install.bat` and follow the prompts. It will:
1. Copy hook scripts to `%USERPROFILE%\.claude\scripts\`
2. Configure Claude Code hooks in `%USERPROFILE%\.claude\settings.json`
3. Launch the monitor window

### Option B: Manual setup

```powershell
# 1. Copy scripts to your .claude directory
copy scripts\write-status.js   %USERPROFILE%\.claude\scripts\
copy scripts\status-monitor.ps1 %USERPROFILE%\.claude\scripts\
copy scripts\launch-monitor.bat %USERPROFILE%\.claude\scripts\

# 2. Add hooks to %USERPROFILE%\.claude\settings.json
#    See the "Hooks Configuration" section below

# 3. Launch the monitor
scripts\launch-monitor.bat
```

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
