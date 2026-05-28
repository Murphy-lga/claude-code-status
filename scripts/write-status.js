// write-status.js
// Called by Claude Code hooks to write the current status to claude-status.json
// Usage: node write-status.js <status_label> [message]

const fs = require('fs');
const path = require('path');
const os = require('os');

const STATUS_FILE = path.join(
  os.homedir(),
  '.claude',
  'claude-status.json'
);

const status = process.argv[2] || 'idle';
const message = process.argv.slice(3).join(' ') || '';

const statusLabels = {
  'start':     { display: 'IDLE',      color: '#9ca3af' },
  'idle':      { display: 'IDLE',      color: '#9ca3af' },
  'thinking':  { display: 'THINKING',  color: '#f59e0b' },
  'executing': { display: 'EXECUTING', color: '#3b82f6' },
  'confirm':   { display: 'WAITING',   color: '#a855f7' },
  'waiting':   { display: 'THINKING',  color: '#f59e0b' },
  'done':      { display: 'DONE',      color: '#22c55e' },
  'error':     { display: 'ERROR',     color: '#ef4444' },
};

const label = statusLabels[status] || { display: status.toUpperCase(), color: '#9ca3af' };

const data = {
  status: status,
  display: label.display,
  color: label.color,
  message: message,
  timestamp: Date.now(),
};

try {
  fs.writeFileSync(STATUS_FILE, JSON.stringify(data, null, 2));
} catch (err) {
  setTimeout(() => {
    try {
      fs.writeFileSync(STATUS_FILE, JSON.stringify(data, null, 2));
    } catch (e2) {
      process.exit(1);
    }
  }, 50);
}
