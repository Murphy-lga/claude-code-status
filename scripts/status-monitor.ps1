# status-monitor.ps1
# Claude Code real-time status monitor - minimalist borderless HUD bar
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32Drag {
    [DllImport("user32.dll")]
    public static extern int ReleaseCapture();
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    public const uint WM_NCLBUTTONDOWN = 0x00A1;
    public const int HTCAPTION = 2;
}
"@

$STATUS_FILE = "$env:USERPROFILE\.claude\claude-status.json"

# Create borderless form
$form = New-Object System.Windows.Forms.Form
$form.Text = ""
$form.Size = New-Object System.Drawing.Size(180, 44)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.ShowInTaskbar = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1e2e")
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.DoubleBuffered = $true

# Position at bottom-right of screen
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(
    [Math]::Max(0, $screen.Right - $form.Width - 20),
    [Math]::Max(0, $screen.Bottom - $form.Height - 20)
)

# Capsule shape — full semicircle corners
$radius = [Math]::Floor($form.Height / 2)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddArc(0, 0, $radius * 2, $radius * 2, 180, 90)
$path.AddArc($form.Width - $radius * 2, 0, $radius * 2, $radius * 2, 270, 90)
$path.AddArc($form.Width - $radius * 2, $form.Height - $radius * 2, $radius * 2, $radius * 2, 0, 90)
$path.AddArc(0, $form.Height - $radius * 2, $radius * 2, $radius * 2, 90, 90)
$path.CloseFigure()
$form.Region = New-Object System.Drawing.Region($path)

# Drag handler — uses Win32 ReleaseCapture+SendMessage for reliable dragging
$dragAction = {
    [Win32Drag]::ReleaseCapture()
    [Win32Drag]::SendMessage($form.Handle, [Win32Drag]::WM_NCLBUTTONDOWN, [IntPtr][Win32Drag]::HTCAPTION, [IntPtr]::Zero)
}

# Indicator dot (16x16 circle)
$dot = New-Object System.Windows.Forms.Panel
$dot.Location = New-Object System.Drawing.Point(14, 14)
$dot.Size = New-Object System.Drawing.Size(16, 16)
$dotPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$dotPath.AddEllipse(0, 0, 16, 16)
$dot.Region = New-Object System.Drawing.Region($dotPath)
$dot.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#9ca3af")
$form.Controls.Add($dot)

$dot.Add_MouseDown($dragAction)

# Status text
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "CONNECTING"
$lblStatus.Location = New-Object System.Drawing.Point(38, 10)
$lblStatus.Size = New-Object System.Drawing.Size(100, 24)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9ca3af")
$lblStatus.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1e2e")
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$form.Controls.Add($lblStatus)

$lblStatus.Add_MouseDown($dragAction)

# Close button — right side, vertically centered
$btnClose = New-Object System.Windows.Forms.Label
$btnClose.Text = [char]0x00D7
$btnClose.Location = New-Object System.Drawing.Point(150, 8)
$btnClose.Size = New-Object System.Drawing.Size(24, 28)
$btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#4b5563")
$btnClose.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1e2e")
$btnClose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnClose)

$btnClose.Add_MouseEnter({ $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#f87171") })
$btnClose.Add_MouseLeave({ $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#4b5563") })
$btnClose.Add_MouseDown({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $form.Close()
    }
})

# State
$script:isActive = $false
$script:currentStatus = $null

# Pulse animation — dot gently fades in/out (fast & smooth)
$pulsePhase = 0
$timerPulse = New-Object System.Windows.Forms.Timer
$timerPulse.Interval = 40
$timerPulse.Add_Tick({
    # No pulse for IDLE (gray) and DONE (green)
    if ($script:currentStatus -eq "start" -or $script:currentStatus -eq "idle" -or $script:currentStatus -eq "done") {
        if ($dot.Tag) {
            $color = [System.Drawing.ColorTranslator]::FromHtml($dot.Tag)
            $dot.BackColor = $color
        }
        $dot.Size = New-Object System.Drawing.Size(16, 16)
        $dot.Location = New-Object System.Drawing.Point(14, 14)
        return
    }

    $script:pulsePhase = ($script:pulsePhase + 1) % 40
    $alpha = if ($script:pulsePhase -le 12) { 255 } else { [int](255 * (1 - ($script:pulsePhase - 12) / 13.0)) }
    $alpha = [Math]::Max(60, $alpha)
    if ($dot.Tag) {
        $color = [System.Drawing.ColorTranslator]::FromHtml($dot.Tag)
        $dot.BackColor = [System.Drawing.Color]::FromArgb($alpha, $color.R, $color.G, $color.B)
    }
    $dot.Size = New-Object System.Drawing.Size(16, 16)
    $dot.Location = New-Object System.Drawing.Point(14, 14)
})
$timerPulse.Start()

# Main poll timer
$timerMain = New-Object System.Windows.Forms.Timer
$timerMain.Interval = 500
$timerMain.Add_Tick({
    try {
        if (Test-Path $STATUS_FILE) {
            $json = Get-Content $STATUS_FILE -Raw -ErrorAction SilentlyContinue
            if ($json) {
                $data = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($data) {
                    $newColor = $data.color
                    if (-not $newColor) { $newColor = "#9ca3af" }
                    $display = $data.display
                    if (-not $display) { $display = "UNKNOWN" }

                    $lblStatus.Text = $display
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($newColor)

                    # Update dot
                    $dot.Tag = $newColor
                    $dot.BackColor = [System.Drawing.ColorTranslator]::FromHtml($newColor)

                    # Pulse state
                    $raw = $data.status
                    $script:currentStatus = $raw
                    if ($raw -eq "thinking" -or $raw -eq "executing" -or $raw -eq "waiting") {
                        $script:isActive = $true
                    } else {
                        $script:isActive = $false
                    }

                }
            }
        } else {
            # No file yet
            $lblStatus.Text = "CONNECTING"
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#585b70")
            $dot.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#585b70")
            $script:currentStatus = $null
            $script:isActive = $false
        }
    } catch {
        # Silently ignore read errors
    }
})
$timerMain.Start()

[System.Windows.Forms.Application]::Run($form)
