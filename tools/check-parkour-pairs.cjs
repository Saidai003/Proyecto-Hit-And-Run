// Regression check against the last saved place: every parkour marker must
// resolve to its nearest opposite marker, and the choice must be reciprocal.
const reader = require('../.tools/node_modules/rbx-reader');
const place = process.argv[2] || 'Backup_DO_NOT_TOUCH/ProyectoRobloxPrototype2.rbxl';
const markers = reader.readFile(place).instances.filter((instance) =>
  /^Punto(Salto|Entrada)_[12]$/.test(instance.Name || ''));

const parent = (instance) => instance.getFullName().split('.').slice(0, -1).join('.');
const position = (instance) => instance.getProperty('CFrame').slice(0, 3);
const distance = (a, b) => Math.hypot(...position(a).map((n, i) => n - position(b)[i]));

function nearest(origin) {
  const opposite = origin.Name.replace(/_[12]$/, origin.Name.endsWith('_1') ? '_2' : '_1');
  return markers.filter((candidate) => candidate.Name === opposite && parent(candidate) === parent(origin)
    && Math.abs(position(candidate)[1] - position(origin)[1]) <= 3
    && distance(candidate, origin) < 11)
    .sort((a, b) => distance(a, origin) - distance(b, origin))[0];
}

for (const marker of markers) {
  const target = nearest(marker);
  if (!target || nearest(target) !== marker) {
    throw new Error(`Unpaired parkour marker: ${marker.getFullName()}`);
  }
}
console.log(`${markers.length} parkour markers have reciprocal nearby pairs.`);
