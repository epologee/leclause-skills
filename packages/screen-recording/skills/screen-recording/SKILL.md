---
name: screen-recording
user-invocable: true
disable-model-invocation: true
description: Use when creating automated screen recordings, demo videos, or visual documentation of browser-based features. Requires a global `npm install -g playwright` before the first run.
---

# Screen Recording

Geautomatiseerde screen recordings en demo video's van browser-gebaseerde features.

## Verboden tools

- **NOOIT `screencapture`** voor demo video's. Het neemt het hele scherm op, inclusief alles wat de user op dat moment doet. Niet bruikbaar als demo.
- **NOOIT Safari, osascript, of andere macOS-specifieke browser tools.**

Gebruik ALTIJD Playwright's ingebouwde video recording. Die neemt alleen de browser viewport op, onafhankelijk van wat er verder op het scherm staat.

## Core Pattern: Playwright Video Recording

Playwright kan automatisch video opnemen van de browser context. Geen externe screen recording tools nodig.

```javascript
import { chromium } from 'playwright';

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 1280, height: 900 },
  recordVideo: { dir: '/tmp/videos/', size: { width: 1280, height: 900 } },
});
const page = await context.newPage();

// ... automatiseer de browser ...

await context.close(); // Video wordt pas opgeslagen bij context.close()
// Video pad: await page.video().path()
await browser.close(); // Standalone Playwright instantie, niet de user's Chrome
```

**Belangrijk:** `recordVideo` neemt alleen de viewport op. Headless of headed maakt niet uit voor de opname. De video is altijd alleen de browser content.

## Volledig Flow

1. Schrijf een Playwright script met `recordVideo` naar `/tmp/`
2. Draai het script: `NODE_PATH=$(npm root -g) node /tmp/demo.mjs`
3. Converteer webm naar mp4: `ffmpeg -i /tmp/videos/xxx.webm -c:v libx264 -preset fast -crf 28 /tmp/demo.mp4`
4. Deel het resultaat met de user

## Voorbeeld Script

```javascript
import { chromium } from 'playwright';

const BASE = 'http://example.test:3000';
const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 1280, height: 900 },
  recordVideo: { dir: '/tmp/videos/', size: { width: 1280, height: 900 } },
});
const page = await context.newPage();

await page.goto(`${BASE}/sign_in`);
await page.waitForLoadState('networkidle');
await page.waitForTimeout(1000);
await page.locator('button[type="submit"]').click();
await page.waitForLoadState('networkidle');
await page.waitForTimeout(1500);

await page.goto(`${BASE}/dashboard`);
await page.waitForLoadState('networkidle');
await page.waitForTimeout(2000);

await context.close();
await browser.close(); // Standalone Playwright instantie, niet de user's Chrome
```

## NODE_PATH

Playwright is globaal geinstalleerd maar niet altijd vindbaar vanuit projectdirectories. Gebruik:

```bash
NODE_PATH=$(npm root -g) node /tmp/script.mjs
```

## Tips

- `waitForTimeout(1000-2000)` tussen acties voor visuele helderheid
- Playwright slaat video op als `.webm`, converteer naar `.mp4` voor compatibility
- `/tmp/videos/` voor output, `/tmp/` voor scripts
- Bekijk altijd het resultaat (extract frames met ffmpeg of open het bestand) voordat je het deelt
