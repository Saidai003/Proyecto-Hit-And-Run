// One-way extraction of Luau source from a local Roblox place backup.
// Run from the repository root: node tools/extract-rbxl.cjs <place.rbxl>
const fs = require('node:fs');
const path = require('node:path');
const reader = require('../.tools/node_modules/rbx-reader');

const source = process.argv[2];
if (!source || !fs.existsSync(source)) {
  throw new Error('Provide an existing .rbxl path');
}

const root = path.resolve('src');
const result = reader.readFile(source);
const scripts = result.instances.filter((instance) =>
  ['Script', 'LocalScript', 'ModuleScript'].includes(instance.ClassName)
  && typeof instance.getProperty('Source') === 'string');

for (const instance of scripts) {
  const parents = instance.getFullName().split('.');
  if (!['ServerScriptService', 'StarterPlayer', 'ReplicatedStorage', 'ServerStorage'].includes(parents[0])) {
    continue;
  }
  const suffix = instance.ClassName === 'Script' ? '.server.luau'
    : instance.ClassName === 'LocalScript' ? '.client.luau' : '.luau';
  const relative = parents.map((name) => name.replace(/[<>:"/\\|?*]/g, '_'));
  const destination = path.join(root, ...relative.slice(0, -1), relative.at(-1) + suffix);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, instance.getProperty('Source'), 'utf8');
  console.log(path.relative(root, destination));
}

console.log(`Extracted ${scripts.length} script instances; see src/ for gameplay sources.`);
