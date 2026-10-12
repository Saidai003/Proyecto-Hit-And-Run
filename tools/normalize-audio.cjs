// Offline mastering only. This script never changes in-game Sound.Volume values.
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const ffmpeg = process.env.FFMPEG_PATH || path.join(root, '.tools', 'ffmpeg-9.0.2-essentials_build', 'bin', 'ffmpeg.exe');
const output = path.join(root, '.tools', 'normalized-audio');
const reportPath = path.join(root, '.tools', 'audio-normalization-report.json');
const originalDir = process.env.AUDIO_ORIGINAL_DIR || path.join(root, '.tools', 'audio-originals-2026-10-11');

const tracks = [
  ['Click', 'simple_click_button.mp3', -24],
  ['DoubleClick', 'double_click_button.mp3', -24],
  ['VaultWindow', 'vaulting_a_window.mp3', -19],
  ['VaultPallet', 'vaulting_a_pallet.mp3', -18],
  ['PalletDrop', 'Pallet_being_dropped_.mp3', -18],
  ['PalletBreak1', 'Heavy_pallet_breakin_#1.mp3', -18],
  ['PalletBreak2', 'Heavy_pallet_breakin_#2.mp3', -18],
  ['PalletBreak3', 'Heavy_pallet_breakin_#3.mp3', -18],
  ['PalletBreak4', 'Heavy_pallet_breakin_#4.mp3', -18],
  ['HandHit', 'Hit_someone.mp3', -18],
  ['BatHit', 'bat_hit_to_someone.mp3', -18],
  ['Throw', 'throwing_weapon.mp3', -19],
  ['HardLanding', 'hard_landing_from_great_heights.mp3', -18],
  ['SoftLanding', 'soft_landing_from_heights.mp3', -20],
  ['Pain', 'stupid_pain_complaint.mp3', -20],
  ['Climb', 'climbing_metalic_structure.mp3', -21],
  ['Slide', 'Sliding_on_the_floor.mp3', -20],
  ['RoundWin', 'win_bass_sfx.mp3', -20],
  ['RoundLose', 'lose-bass-sfx.mp3', -20],
  ['FinalWin', 'endgame_win_sfx.mp3', -20],
  ['FinalLose', 'endgame_lose_sfx.mp3', -20],
  ['WinVoice', 'you_win.mp3', -20],
  ['LoseVoice', 'you_lose_voice.mp3', -20],
  ['LobbyMusic', 'lobby_music.mp3', -16],
];

function run(args) {
  const result = spawnSync(ffmpeg, args, { encoding: 'utf8', maxBuffer: 2_000_000 });
  if (result.error || result.status !== 0) throw new Error(result.error?.message || result.stderr);
  return result.stderr;
}

function measure(file) {
  const result = run(['-hide_banner', '-nostats', '-i', file, '-af', 'loudnorm=I=-20:TP=-1.5:LRA=11:print_format=json', '-f', 'null', 'NUL']);
  const match = result.match(/\{\s*"input_i"[\s\S]*?\}/);
  if (!match) throw new Error(`Loudness measurement missing for ${file}`);
  const data = JSON.parse(match[0]);
  return { lufs: Number(data.input_i), truePeakDb: Number(data.input_tp) };
}

function leadingSilence(file) {
  const result = run(['-hide_banner', '-nostats', '-i', file, '-af', 'silencedetect=noise=-45dB:d=0.02', '-f', 'null', 'NUL']);
  const start = result.match(/silence_start:\s*([\d.]+)/);
  const end = result.match(/silence_end:\s*([\d.]+)/);
  return start && end && Number(start[1]) === 0 ? Number(end[1]) : 0;
}

fs.mkdirSync(output, { recursive: true });
const report = {};
for (const [name, fileName, targetLufs] of tracks) {
  const original = path.join(originalDir, fileName);
  const source = fs.existsSync(original) ? original : path.join(root, 'SFX', fileName);
  const destination = path.join(output, fileName);
  const before = measure(source);
  const silence = name === 'LobbyMusic' ? 0 : leadingSilence(source);
  const filters = [];
  if (silence > 0.05) filters.push('silenceremove=start_periods=1:start_silence=0.01:start_threshold=-45dB');
  if (name === 'VaultWindow' || name === 'DoubleClick') {
    filters.push('acompressor=threshold=0.08:ratio=4:attack=0.5:release=80:detection=peak');
  }
  filters.push(`loudnorm=I=${targetLufs}:TP=-2:LRA=11`);
  run(['-hide_banner', '-loglevel', 'error', '-y', '-i', source, '-af', filters.join(','), '-codec:a', 'libmp3lame', '-b:a', '192k', destination]);
  const after = measure(destination);
  if (after.truePeakDb > -1.2) throw new Error(`${name} true peak too high: ${after.truePeakDb} dB`);
  if (fs.statSync(destination).size > 20_000_000) throw new Error(`${name} exceeds Roblox's 20 MB limit`);
  report[name] = { fileName, targetLufs, trimmedLeadingMs: Math.round(silence > 0.05 ? silence * 1000 : 0), before, after };
  console.log(`${name}: ${before.lufs} -> ${after.lufs} LUFS; peak ${after.truePeakDb} dB`);
}
fs.writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n');
console.log(`Normalized ${tracks.length} files in ${output}`);
