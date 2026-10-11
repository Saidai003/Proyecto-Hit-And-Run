// Upload only the audio used by the MVP. Requires a Roblox Open Cloud key in
// ROBLOX_API_KEY; never put the key in this repository or the command line.
const fs = require('node:fs');
const path = require('node:path');

const apiKey = process.env.ROBLOX_API_KEY;
const userId = process.env.ROBLOX_USER_ID || '1081772883';
if (!apiKey) throw new Error('ROBLOX_API_KEY is not set');
if (!/^\d+$/.test(userId)) throw new Error('ROBLOX_USER_ID must be numeric');

const root = path.resolve(__dirname, '..');
const output = path.join(__dirname, 'audio-ids.json');
const files = [
  ['Click', 'simple_click_button.mp3'],
  ['VaultWindow', 'vaulting_a_window.mp3'],
  ['PalletDrop', 'Pallet_being_dropped_.mp3'],
  ['PalletBreak1', 'Heavy_pallet_breakin_#1.mp3'],
  ['HandHit', 'Hit_someone.mp3'],
  ['BatHit', 'bat_hit_to_someone.mp3'],
  ['Throw', 'throwing_weapon.mp3'],
  ['HardLanding', 'hard_landing_from_great_heights.mp3'],
  ['RoundWin', 'win_bass_sfx.mp3'],
  ['RoundLose', 'lose-bass-sfx.mp3'],
  ['VaultPallet', 'vaulting_a_pallet.mp3'],
  ['Climb', 'climbing_metalic_structure.mp3'],
  ['SoftLanding', 'soft_landing_from_heights.mp3'],
  ['Pain', 'stupid_pain_complaint.mp3'],
  ['DoubleClick', 'double_click_button.mp3'],
  ['FinalWin', 'endgame_win_sfx.mp3'],
  ['FinalLose', 'endgame_lose_sfx.mp3'],
  ['WinVoice', 'you_win.mp3'],
  ['LoseVoice', 'you_lose_voice.mp3'],
  ['PalletBreak2', 'Heavy_pallet_breakin_#2.mp3'],
  ['PalletBreak3', 'Heavy_pallet_breakin_#3.mp3'],
  ['PalletBreak4', 'Heavy_pallet_breakin_#4.mp3'],
];

const uploaded = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
const uploadLimit = Number(process.env.AUDIO_UPLOAD_LIMIT || Infinity);
const save = () => fs.writeFileSync(output, JSON.stringify(uploaded, null, 2) + '\n');
const headers = { 'x-api-key': apiKey };
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function readJson(response) {
  const body = await response.text();
  let data;
  try { data = JSON.parse(body); } catch { data = { message: body.slice(0, 250) }; }
  if (!response.ok) throw new Error(`HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
}

async function upload(name, fileName) {
  const source = path.join(root, 'SFX', fileName);
  const file = fs.readFileSync(source);
  if (file.length > 20_000_000) throw new Error(`${fileName} exceeds 20 MB`);
  const form = new FormData();
  form.append('request', JSON.stringify({
    assetType: 'Audio',
    displayName: `Hit and Run - ${name}`,
    description: `Sound effect for Hit and Run MVP (${fileName})`,
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
  throw new Error(`${name}: upload is still processing; check ${operation.path}`);
}

(async () => {
	let completed = 0;
  for (const [name, fileName] of files) {
    if (uploaded[name]?.assetId) { console.log(`Already uploaded: ${name}`); continue; }
		if (completed >= uploadLimit) break;
    try {
      uploaded[name] = await upload(name, fileName);
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
