---
name: screen-recording
user-invocable: true
disable-model-invocation: true
description: Use when creating automated screen recordings, demo videos, or visual documentation of browser-based features. Requires a global `npm install -g playwright` before the first run.
---

# Screen Recording

Automated screen recordings and demo videos of browser-based features.

## Forbidden tools

- **NEVER `screencapture`** for demo videos. It records the entire screen, including everything the user is doing at that moment. Not usable as a demo.
- **NEVER Safari, osascript, or other macOS-specific browser tools.**

ALWAYS use Playwright's built-in video recording. It captures only the browser viewport, independent of anything else on the screen.

## Core Pattern: Playwright Video Recording

Playwright can automatically record video from the browser context. No external screen recording tools needed.

```javascript
import { chromium } from 'playwright';

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 1280, height: 900 },
  recordVideo: { dir: '/tmp/videos/', size: { width: 1280, height: 900 } },
});
const page = await context.newPage();

// ... automate the browser ...

await context.close(); // Video is only saved on context.close()
// Video path: await page.video().path()
await browser.close(); // Standalone Playwright instance, not the user's Chrome
```

**Important:** `recordVideo` captures only the viewport. Headless or headed makes no difference for the recording. The video is always browser content only.

## Full Flow

1. Write a Playwright script with `recordVideo` to `/tmp/`
2. Run the script: `NODE_PATH=$(npm root -g) node /tmp/demo.mjs`
3. Convert webm to mp4: `ffmpeg -i /tmp/videos/xxx.webm -c:v libx264 -preset fast -crf 28 /tmp/demo.mp4`
4. Share the result with the user

## Example Script

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
await browser.close(); // Standalone Playwright instance, not the user's Chrome
```

## NODE_PATH

Playwright is installed globally but not always resolvable from project directories. Use:

```bash
NODE_PATH=$(npm root -g) node /tmp/script.mjs
```

## Tips

- `waitForTimeout(1000-2000)` between actions for visual clarity
- Playwright saves video as `.webm`, convert to `.mp4` for compatibility
- `/tmp/videos/` for output, `/tmp/` for scripts
- Always review the result (extract frames with ffmpeg or open the file) before sharing
