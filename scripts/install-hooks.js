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

const SCRIPT_DIR = '%USERPROFILE%\\.claude\\scripts';

const hooks = {
  SessionStart: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" start`,
  },
  UserPromptSubmit: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" thinking`,
  },
  PreToolUse: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" executing`,
  },
  PostToolUse: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" thinking`,
  },
  Notification: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" confirm`,
  },
  Stop: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" done`,
  },
  SessionEnd: {
    match: /./,
    run: `node "${SCRIPT_DIR}\\write-status.js" done`,
  },
};

function expandEnv(p) {
  return p.replace('%USERPROFILE%', process.env.USERPROFILE || '');
}

// Expand paths in hooks
const expandedHooks = {};
for (const [key, value] of Object.entries(hooks)) {
  expandedHooks[key] = {
    match: value.match,
    run: expandEnv(value.run),
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
  const ourIndex = existing.findIndex(h => h.run && h.run.includes('write-status.js'));
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
