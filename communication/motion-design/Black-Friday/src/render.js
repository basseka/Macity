// Rendu image par image de bf.html (window.render(t)).
// node render.js <dossier> [t1 t2 ...]   (sans instants : toutes les images, 30 i/s, en parallèle)
const path = require('path'), fs = require('fs');
const { chromium } = require(process.env.PW || 'playwright');
const OUT = process.argv[2], TIMES = process.argv.slice(3).map(Number);
const FPS = 30, DUR = 15, WORKERS = +(process.env.WORKERS || 8);
(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const frames = TIMES.length ? TIMES.map(t => [`t${t.toFixed(2).padStart(5, '0')}`, t])
    : Array.from({ length: FPS * DUR }, (_, i) => [`f${String(i).padStart(4, '0')}`, i / FPS]);
  const chunks = Array.from({ length: Math.min(WORKERS, frames.length) }, (_, w) => frames.filter((_, i) => i % WORKERS === w));
  await Promise.all(chunks.map(async list => {
    const br = await chromium.launch({ args: ['--disable-gpu-vsync', '--disable-partial-raster', '--disable-features=PaintHolding', '--force-device-scale-factor=1'] });
    const pg = await br.newPage({ viewport: { width: 1080, height: 1920 } });
    await pg.goto('file://' + path.join(__dirname, 'bf.html')); await pg.evaluate(() => document.fonts.ready); await pg.waitForTimeout(600);
    for (const [name, t] of list) {
      if (fs.existsSync(`${OUT}/${name}.jpg`)) continue;
      for (let essai = 1; ; essai++) { // réessaie si une capture dépasse le délai (machine chargée)
        try {
          await pg.evaluate(t => window.render(t), t);
          await pg.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))));
          await pg.screenshot({ type: 'jpeg', quality: 10, timeout: 90000 }); // passe de chauffe : force la rastérisation de toutes les tuiles
          await pg.screenshot({ path: `${OUT}/${name}.jpg`, type: 'jpeg', quality: 94, timeout: 90000 });
          break;
        } catch (e) { if (essai >= 4) throw e; console.error(`${name} : nouvel essai (${essai})`); }
      }
    }
    await br.close();
  }));
})();
