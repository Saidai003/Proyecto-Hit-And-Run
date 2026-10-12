// Roblox does not allow replacing audio content in-place. Upload the balanced
// files as new assets, then point AudioCatalog.luau at their new IDs.
const fs = require('node:fs');
const path = require('node:path');

const apiKey = process.env.ROBLOX_API_KEY;
const userId = process.env.ROBLOX_USER_ID || '1081772883';
if (!apiKey) throw new Error('ROBLOX_API_KEY is not set');
if (!/^\d+$/.test(userId)) throw new Error('ROBLOX_USER_ID must be numeric');

const root = path.resolve(__dirname, '..');
const sourceDir = path.join(root, '.tools', 'normalized-audio');
const report = JSON.parse(fs.readFileSync(path.join(root, '.tools', 'audio-normalization-report.json'), 'utf8'));
const output = path.join(__dirname, 'audio-balanced-ids.json');
const uploaded = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
const limit = Number(process.env.AUDIO_UPLOAD_LIMIT || Infinity);
const headers = { 'x-api-key': apiKey };
const save = () => fs.writeFileSync(output, JSON.stringify(uploaded, null, 2) + '\n');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function readJson(response) {
  const body = await response.text();
  let data;
  try { data = JSON.parse(body); } catch { data = { message: body.slice(0, 250) }; }
  if (!response.ok) throw new Error(`HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}

async function upload(name, fileName) {
  const source = path.join(sourceDir, fileName);
  const file = fs.readFileSync(source);
  if (file.length > 20_000_000) throw new Error(`${fileName} exceeds 20 MB`);
  const form = new FormData();
  form.append('request', JSON.stringify({
    assetType: 'Audio',
    displayName: `Hit and Run - ${name} (balanced)`,
    description: `Volume-balanced game audio: ${fileName}`,
    creationContext: { creator: { userId } },
  }));
  form.append('fileContent', new Blob([file], { type: 'audio/mpeg' }), fileName);
  const operation = await readJson(await fetch('https://apis.roblox.com/assets/v1/assets', {
    method: 'POST', headers, body: form,
  }));
  if (!/^operations\/[A-Za-z0-9_-]+$/.test(operation.path || '')) {
    throw new Error(`Unexpected operation path for ${name}: ${JSON.stringify(operation)}`);
  }
  for (let attempt = 0; attempt < 30; attempt++) {
    await sleep(2000);
    const status = await readJson(await fetch(`https://apis.roblox.com/assets/v1/${operation.path}`, { headers }));
    if (!status.done) continue;
    if (status.error) throw new Error(`${name}: ${JSON.stringify(status.error)}`);
    const assetId = status.response?.assetId;
    if (!/^\d+$/.test(String(assetId || ''))) throw new Error(`${name}: missing assetId`);
    return { assetId: String(assetId), moderationState: status.response?.moderationResult?.moderationState || null };
  }
  throw new Error(`${name}: upload still processing; check ${operation.path}`);
}

(async () => {
  let completed = 0;
  for (const [name, data] of Object.entries(report)) {
    if (uploaded[name]?.assetId) { console.log(`Already uploaded: ${name}`); continue; }
    if (completed >= limit) break;
    try {
      uploaded[name] = await upload(name, data.fileName);
      save();
      completed++;
      console.log(`Uploaded ${name}: ${uploaded[name].assetId} (${uploaded[name].moderationState || 'pending'})`);
    } catch (error) {
      console.error(`Stopped at ${name}: ${error.message}`);
      process.exitCode = 1;
      break;
    }
  }
})().catch((error) => { console.error(error.message); process.exitCode = 1; });
