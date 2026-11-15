// Render the generated SVGs to 1024px PNGs with the preinstalled Chromium
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const out = process.argv[2];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 512, height: 512 }, deviceScaleFactor: 2 });
  for (const name of ['icon-banner', 'icon-plain']) {
    const svg = fs.readFileSync(path.join(out, name + '.svg'), 'utf8');
    await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    await page.waitForTimeout(200);
    await page.locator('svg').screenshot({ path: path.join(out, name + '@1024.png'), omitBackground: true });
  }
  await browser.close();
})();
