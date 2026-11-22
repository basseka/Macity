// Capture du téléphone (rubrique Famille, vidéo du partenaire dans la bannière) :
// node capture_famille.js <page.html> <sortie.png>
const { chromium } = require(process.env.PW);
const path = require('path');
(async () => {
  const [page, out] = process.argv.slice(2);
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  await p.goto('file://' + path.resolve(__dirname, page), { waitUntil: 'networkidle' });
  await p.evaluate('document.fonts.ready');
  await p.evaluate('window.render(V.b2 + 3.2)');
  await p.evaluate(`for (const id of ['sticker','arrow']) document.getElementById(id).style.display='none';
    document.getElementById('s2').style.opacity=1; document.getElementById('phone').style.transform='none';`);
  await p.waitForTimeout(300);
  await (await p.$('#phone')).screenshot({ path: out, omitBackground: true });
  await b.close();
})();
