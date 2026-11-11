// Rendu image par image : node render_node.js <page.html> <dossier> [fps] [t1 t2 ...]
const { chromium } = require(process.env.PW);
const path = require('path'), fs = require('fs');
(async () => {
  const [page, out, fpsArg, ...times] = process.argv.slice(2);
  const fps = +(fpsArg || 30);
  fs.mkdirSync(out, { recursive: true });
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  await p.goto('file://' + path.resolve(__dirname, page), { waitUntil: 'networkidle' });
  await p.evaluate('document.fonts.ready'); await p.waitForTimeout(600);
  const dur = await p.evaluate('window.DUR');
  const frames = times.length ? times.map(Number) : [...Array(Math.round(dur * fps)).keys()].map(i => i / fps);
  for (let k = 0; k < frames.length; k++) {
    await p.evaluate(`window.render(${frames[k]})`);
    await p.screenshot({ path: `${out}/${times.length ? 't' + frames[k].toFixed(2) : 'f' + String(k).padStart(4, '0')}.jpg`, type: 'jpeg', quality: 92 });
  }
  await b.close();
})();
