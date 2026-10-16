// Renders background.html to background.tiff (1x and 2x in one file, which
// Finder picks between). Needs Playwright's Chromium:
//   npm i -g playwright && npx playwright install chromium
//   node tools/release/dmg/render-background.mjs
import { execFileSync } from 'node:child_process'
import { mkdtempSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { chromium } from 'playwright'

const here = dirname(fileURLToPath(import.meta.url))
const tmp = mkdtempSync(join(tmpdir(), 'kdash-dmg-'))
const browser = await chromium.launch()
for (const scale of [1, 2]) {
  const page = await browser.newPage({ viewport: { width: 660, height: 400 }, deviceScaleFactor: scale })
  await page.goto(pathToFileURL(join(here, 'background.html')).href)
  await page.evaluate(() => document.fonts.ready)
  await page.screenshot({ path: join(tmp, scale === 1 ? 'bg.png' : 'bg@2x.png') })
}
await browser.close()
execFileSync('/usr/bin/tiffutil', ['-cathidpicheck', join(tmp, 'bg.png'), join(tmp, 'bg@2x.png'), '-out', join(here, 'background.tiff')])
execFileSync('/bin/cp', [join(tmp, 'bg@2x.png'), join(here, 'background-preview.png')])
console.log('wrote background.tiff and background-preview.png')
