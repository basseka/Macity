"""Rendu image par image de reel.html (window.render(t)) : python render.py <dossier> [t1 t2 ...]"""
import asyncio, sys, os
from playwright.async_api import async_playwright
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]; TIMES = [float(x) for x in sys.argv[2:]]
FPS, DUR = 30, 30.0
async def main():
    os.makedirs(OUT, exist_ok=True)
    async with async_playwright() as p:
        br = await p.chromium.launch(channel='chrome', args=['--disable-gpu-vsync'])
        pg = await br.new_page(viewport={'width': 1080, 'height': 1920}, device_scale_factor=float(os.environ.get('DSF', '1')))
        await pg.goto(f'file://{HERE}/' + os.environ.get('PAGE', 'reel.html')); await pg.wait_for_load_state('networkidle')
        await pg.evaluate('document.fonts.ready'); await pg.wait_for_timeout(800)
        frames = [(f't{t:05.2f}', t) for t in TIMES] if TIMES else [(f'f{i:04d}', i / FPS) for i in range(int(FPS * DUR))]
        for name, t in frames:
            await pg.evaluate(f'window.render({t})')
            await pg.screenshot(path=f'{OUT}/{name}.jpg', type='jpeg', quality=int(os.environ.get('Q', '94')))
        await br.close()
asyncio.run(main())
