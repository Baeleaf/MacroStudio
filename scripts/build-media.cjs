// Development-only asset build: node scripts/build-media.cjs [path-to-sharp]
// Runtime addon ships only the emblem TGA, with no added dependencies.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const media = path.join(root, 'Media');
const assets = path.join(root, 'assets');

function tga(filename, width, height, rgba, channels = 4) {
  const header = Buffer.alloc(18);
  header[2] = 2; // Uncompressed true color, top-left origin.
  header.writeUInt16LE(width, 12);
  header.writeUInt16LE(height, 14);
  header[16] = channels * 8;
  header[17] = 0x20 | (channels === 4 ? 8 : 0);
  const pixels = Buffer.alloc(width * height * channels);
  for (let i = 0; i < width * height; ++i) {
    pixels[i * channels] = rgba[i * 4 + 2];
    pixels[i * channels + 1] = rgba[i * 4 + 1];
    pixels[i * channels + 2] = rgba[i * 4];
    if (channels === 4) pixels[i * channels + 3] = rgba[i * 4 + 3];
  }
  fs.writeFileSync(path.join(media, filename), Buffer.concat([header, pixels]));
}

async function main() {
  const svg = fs.readFileSync(path.join(assets, 'MacroStudioEmblem.svg'));
  for (const size of [32, 64, 256]) {
    const artwork = sharp(svg, { density: 384 }).resize(size, size).ensureAlpha();
    await artwork.clone().png().toFile(path.join(assets, `MacroStudioEmblem-${size}.png`));
    if (size === 64) tga('MacroStudioIcon.tga', size, size, await artwork.raw().toBuffer());
  }
  console.log('Built original scroll-and-quill emblem variants. UI surfaces come from Blizzard.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
