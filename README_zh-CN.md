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

### 方式 A：一键安装

双击运行 `install.bat`，它会自动：
1. 将脚本复制到 `%USERPROFILE%\.claude\scripts\`
2. 在 `%USERPROFILE%\.claude\settings.json` 中配置 hooks
3. 启动监视窗口

### 方式 B：手动安装

```powershell
# 1. 复制脚本到你的 .claude 目录
copy scripts\write-status.js   %USERPROFILE%\.claude\scripts\
copy scripts\status-monitor.ps1 %USERPROFILE%\.claude\scripts\
copy scripts\launch-monitor.bat %USERPROFILE%\.claude\scripts\

# 2. 在 %USERPROFILE%\.claude\settings.json 中添加 hooks 配置
#    见下方 "Hooks 配置" 一节

# 3. 启动监视器
scripts\launch-monitor.bat
```

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
