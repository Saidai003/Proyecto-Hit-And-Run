// Refresh moderation state for the balanced audio assets without printing the API key.
const fs = require('node:fs');
const path = require('node:path');

const apiKey = process.env.ROBLOX_API_KEY;
if (!apiKey) throw new Error('ROBLOX_API_KEY is not set');
const output = path.join(__dirname, 'audio-balanced-ids.json');
const assets = JSON.parse(fs.readFileSync(output, 'utf8'));

(async () => {
  const counts = {};
  for (const [name, data] of Object.entries(assets)) {
    const response = await fetch(`https://apis.roblox.com/assets/v1/assets/${data.assetId}`, {
      headers: { 'x-api-key': apiKey },
    });
    if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
    const asset = await response.json();
    data.moderationState = asset.moderationResult?.moderationState || 'Unknown';
    counts[data.moderationState] = (counts[data.moderationState] || 0) + 1;
  }
  fs.writeFileSync(output, JSON.stringify(assets, null, 2) + '\n');
  console.log(counts);
})().catch((error) => { console.error(error.message); process.exitCode = 1; });
