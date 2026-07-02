// install-hooks.js
// Adds or updates hooks in %USERPROFILE%\.claude\settings.json
// Usage: node install-hooks.js <settings_path> [--create]

const fs = require('fs');
const path = require('path');

const settingsPath = process.argv[2];
const createMode = process.argv[3] === '--create';

if (!settingsPath) {
  console.error('Usage: node install-hooks.js <settings.json> [--create]');
  process.exit(1);
}

// Script directory (USERPROFILE expanded at install time)
const SCRIPT_DIR = '%USERPROFILE%\\.claude\\scripts';

const hooks = {
  SessionStart: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" start`,
      async: true,
    }],
  },
  UserPromptSubmit: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" thinking`,
      async: true,
    }],
  },
  PreToolUse: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" executing`,
      async: true,
    }],
  },
  PostToolUse: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" thinking`,
      async: true,
    }],
  },
  PostToolUseFailure: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" error`,
      async: true,
    }],
  },
  StopFailure: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" error`,
      async: true,
    }],
  },
  Notification: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" confirm`,
      async: true,
    }],
  },
  Stop: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" done`,
      async: true,
    }],
  },
  SessionEnd: {
    matcher: '',
    hooks: [{
      type: 'command',
      command: `node "${SCRIPT_DIR}\\write-status.js" done`,
      async: true,
    }],
  },
};

function expandEnv(p) {
  return p.replace('%USERPROFILE%', process.env.USERPROFILE || '');
}

// Expand paths in hooks
const expandedHooks = {};
for (const [key, value] of Object.entries(hooks)) {
  expandedHooks[key] = {
    matcher: value.matcher,
    hooks: value.hooks.map(h => ({
      ...h,
      command: expandEnv(h.command),
    })),
  };
}

let settings = {};
let exists = false;

if (fs.existsSync(settingsPath)) {
  exists = true;
  try {
    settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  } catch (e) {
    console.error('Error: Failed to parse settings.json:', e.message);
    process.exit(1);
  }
} else if (!createMode) {
  console.error('Error: settings.json not found. Use --create to create it.');
  process.exit(1);
}

// Merge hooks
if (!settings.hooks) {
  settings.hooks = {};
}

for (const [hookName, hookConfig] of Object.entries(expandedHooks)) {
  if (!settings.hooks[hookName]) {
    settings.hooks[hookName] = [];
  }
  // Check if our hook entry already exists (by checking for write-status.js)
  const existing = settings.hooks[hookName];
  const ourIndex = existing.findIndex(h =>
    h.matcher !== undefined &&
    h.hooks &&
    h.hooks.some(hk => hk.command && hk.command.includes('write-status.js'))
  );
  if (ourIndex >= 0) {
    settings.hooks[hookName][ourIndex] = hookConfig;
    console.log(`  Updating hook: ${hookName}`);
  } else {
    settings.hooks[hookName].push(hookConfig);
    console.log(`  Adding hook: ${hookName}`);
  }
}

// Serialize with indentation
const output = JSON.stringify(settings, null, 2);
fs.writeFileSync(settingsPath, output + '\n', 'utf8');

console.log(`\n${exists ? 'Updated' : 'Created'} ${settingsPath}`);
