@echo off
:: Launch the Claude Code status monitor (PowerShell WinForms)
start /min powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\scripts\status-monitor.ps1"
