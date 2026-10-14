// Upload the supplied mobile button artwork. Keep the API key out of files/logs.
const fs = require('node:fs');
const path = require('node:path');

const apiKey = process.env.ROBLOX_API_KEY;
const userId = process.env.ROBLOX_USER_ID || '1081772883';
if (!apiKey) throw new Error('ROBLOX_API_KEY is not set');
if (!/^\d+$/.test(userId)) throw new Error('ROBLOX_USER_ID must be numeric');

const sourceDir = path.resolve(__dirname, '..', 'Sprites');
const output = path.join(__dirname, 'sprite-ids.json');
const files = [
  'AnyOtherActionButton', 'BreakPalletButton', 'ClimbButton',
  'DropPalletButton', 'JumpButton', 'SlideButton', 'SprintButton',
  'ThrowSomethingButton', 'VaultButton',
];
const uploaded = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
const headers = { 'x-api-key': apiKey };
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function readJson(response) {
  const body = await response.text();
  let data;
  try { data = JSON.parse(body); } catch { data = { message: body.slice(0, 250) }; }
  if (!response.ok) throw new Error(`HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}

async function upload(name) {
  const fileName = `${name}.jpg`;
  const file = fs.readFileSync(path.join(sourceDir, fileName));
  const form = new FormData();
  form.append('request', JSON.stringify({
    assetType: 'Decal',
    displayName: `Hit and Run - ${name}`,
    description: 'Mobile control art for Hit and Run',
    creationContext: { creator: { userId } },
  }));
  form.append('fileContent', new Blob([file], { type: 'image/jpeg' }), fileName);
  const operation = await readJson(await fetch('https://apis.roblox.com/assets/v1/assets', {
    method: 'POST', headers, body: form,
  }));
  if (!/^operations\/[A-Za-z0-9_-]+$/.test(operation.path || '')) throw new Error('Unexpected upload operation');
  for (let attempt = 0; attempt < 30; attempt++) {
    await sleep(2000);
    const status = await readJson(await fetch(`https://apis.roblox.com/assets/v1/${operation.path}`, { headers }));
    if (!status.done) continue;
    if (status.error) throw new Error(JSON.stringify(status.error));
    const assetId = String(status.response?.assetId || '');
    if (!/^\d+$/.test(assetId)) throw new Error('Upload completed without assetId');
    return { assetId, moderationState: status.response?.moderationResult?.moderationState || null };
  }
  throw new Error('Upload still processing');
}

(async () => {
  for (const name of files) {
    if (uploaded[name]?.assetId) continue;
    try {
      uploaded[name] = await upload(name);
      fs.writeFileSync(output, JSON.stringify(uploaded, null, 2) + '\n');
      console.log(`Uploaded ${name}: ${uploaded[name].assetId} (${uploaded[name].moderationState || 'pending'})`);
    } catch (error) {
      console.error(`Stopped at ${name}: ${error.message}`);
      process.exitCode = 1;
      break;
    }
  }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
