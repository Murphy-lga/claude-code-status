# Claude Code 状态监视器

一个始终置顶的小窗口，实时显示 Claude Code 的当前状态（空闲、思考中、执行中、等待确认、完成），无需看命令行就能一眼掌握进度。

![Status](https://img.shields.io/badge/status-active-success)
![Platform](https://img.shields.io/badge/platform-windows-blue)
![License](https://img.shields.io/badge/license-MIT-green)

[English](README.md) | [简体中文](README_zh-CN.md)

## 效果预览

| 状态 | 颜色 | 含义 |
|------|------|------|
| IDLE | 灰色 | 已启动，等待输入 |
| THINKING | 黄色 | 正在分析你的问题 |
| EXECUTING | 蓝色 | 正在执行工具/命令 |
| WAITING | 紫色 | 等待你的确认 |
| DONE | 绿色 | 回复完成 |
| ERROR | 红色 | 出错了 |

## 环境要求

- **Windows 10/11**（使用 WinForms，Windows 原生组件）
- **Claude Code** CLI 已安装
- **PowerShell 5+**（Windows 自带）
- **Node.js**（用于 `write-status.js` hook 脚本）

## 快速开始

> **安装前**：请先下载本项目。在 GitHub 页面点击 **Code → Download ZIP**，解压后进入解压后的目录执行后续步骤。无需 `git clone`，下载 ZIP 即可。

### 方式 A：一键安装

双击运行 `install.bat`，它会自动：
1. 将脚本复制到 `%USERPROFILE%\.claude\scripts\`
2. 在 `%USERPROFILE%\.claude\settings.json` 中配置 hooks
3. 启动监视窗口

### 方式 B：手动安装

**步骤 1：复制脚本到你的 .claude 目录**

在项目文件夹中选中 `scripts\` 目录下的以下三个文件：

- `write-status.js`
- `status-monitor.ps1`
- `launch-monitor.bat`

复制到 `%USERPROFILE%\.claude\scripts\` 目录中（`scripts` 文件夹不存在请新建一个）。在文件管理器地址栏粘贴 `%USERPROFILE%\.claude\scripts` 回车即可快速进入。

**步骤 2：将 hooks 配置添加到 `%USERPROFILE%\.claude\settings.json`**

文件不存在则新建；如果已有 `"hooks"` 块则合并条目。将下面 `C:\Users\你的用户名` 替换为实际用户路径（命令行输入 `echo %USERPROFILE%` 查看）：

```json
{
  "hooks": {
    "SessionStart":     [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" start",     "async": true }] }],
    "UserPromptSubmit": [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" thinking", "async": true }] }],
    "PreToolUse":       [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" executing","async": true }] }],
    "PostToolUse":      [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" thinking", "async": true }] }],
    "Notification":     [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" confirm", "async": true }] }],
    "Stop":             [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" done",     "async": true }] }],
    "SessionEnd":       [{ "matcher": "", "hooks": [{ "type": "command", "command": "node \"C:\\Users\\你的用户名\\.claude\\scripts\\write-status.js\" done",     "async": true }] }]
  }
}
```

**步骤 3：启动监视器**

双击 `%USERPROFILE%\.claude\scripts\launch-monitor.bat` 文件即可启动。或在文件管理器地址栏粘贴 `%USERPROFILE%\.claude\scripts` 回车进入该目录后双击 `launch-monitor.bat`。

### 再次启动

安装完成后，hooks 配置已永久写入 `%USERPROFILE%\.claude\settings.json`，每次启动 Claude Code 都会自动触发，无需重新配置。关闭监视窗口后，如需重新启动监视器，任选以下一种方式：

**方式 1：双击启动脚本**

打开文件管理器，进入 `%USERPROFILE%\.claude\scripts\` 目录，双击 `launch-monitor.bat`。

或在文件管理器地址栏直接输入 `%USERPROFILE%\.claude\scripts` 回车进入该目录。

**方式 2：命令行启动**

按 `Win + R` 打开"运行"对话框，粘贴以下命令并回车：

```
powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\scripts\status-monitor.ps1"
```

或在任意命令行窗口（CMD / PowerShell）中粘贴执行同一命令。

## 工作原理

```
Claude Code ──hook──> write-status.js ──write──> claude-status.json
                                                    │
status-monitor.ps1 ──每 500ms 轮询───read───────────┘
      │
      └─> WinForms 窗口（始终置顶、可拖拽、无边框）
```

### Hooks 触发时机

| Hook | 触发时机 | 写入状态 |
|------|---------|---------|
| SessionStart | Claude Code 启动 | `idle` |
| UserPromptSubmit | 用户发送消息 | `thinking` |
| PreToolUse | Claude 调用工具 | `executing` |
| PostToolUse | 工具执行完毕 | `thinking` |
| Notification | Claude 等待用户确认 | `confirm` |
| Stop | Claude 回复完毕 | `done` |
| SessionEnd | 会话退出 | `done` |

## 窗口特性

- **胶囊形无边框** — 180x44px 紧凑条状，圆角半径等于高度的一半
- **始终置顶** — 钉在屏幕最上层
- **可拖拽** — 按住窗口任意位置即可拖动
- **脉冲动画** — 活跃状态下指示圆点有呼吸闪烁效果
- **深色背景** — `#1e1e2e` 配色，状态色对比度高
- **低开销** — 每 500ms 轮询一次，几乎不占 CPU

## 卸载

### 暂停使用：关闭监视窗口

直接关闭窗口即可，hooks 仍会静默写入状态文件，不影响 Claude Code 正常运行。

### 完全移除

1. **删除 hooks** — 从 `%USERPROFILE%\.claude\settings.json` 中删除 `"hooks"` 块
2. **删除脚本**：
   ```
   del "%USERPROFILE%\.claude\scripts\write-status.js"
   del "%USERPROFILE%\.claude\scripts\status-monitor.ps1"
   del "%USERPROFILE%\.claude\scripts\launch-monitor.bat"
   del "%USERPROFILE%\.claude\claude-status.json"
   ```

## 注意事项

- 监视窗口**需要先于 Claude Code 启动**，否则初始会显示 "CONNECTING"
- 多个 Claude Code 实例同时运行时，状态文件反映的是最后一次写入的状态
- 回复结束后如果约 60 秒内没有输入，Claude Code 内部超时会触发 `Notification` hook，状态变为紫色，提示等待输入

## 许可证

MIT
