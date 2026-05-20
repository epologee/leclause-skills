---
name: screen-recording
user-invocable: true
disable-model-invocation: true
description: Use when creating automated screen recordings, demo videos, or visual documentation of browser-based features. Requires a global `npm install -g playwright` before the first run.
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the screen-recording plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("screen-recording was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new screen-recording`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# Screen Recording

Automated screen recordings and demo videos of browser-based features.

## The principle: viewport-only capture

The outcome is a video that captures only the browser viewport, independent of anything else on the screen. Full-screen recorders (`screencapture`, generic OS-level screen recorders) record whatever else the operator was doing at that moment and produce demos full of strangers' notifications and chat windows. Browser-only recorders (Playwright's `recordVideo`, Chrome via MCP, Puppeteer screen-recording, headless browser test drivers with built-in capture) keep the demo to the page under test.

The script below uses Playwright because that is what this skill ships with; sessions that already have another browser-automation route can use it instead. The shape stays the same: viewport-only, scripted navigation, video saved on context close.

## Example: Playwright video recording

Playwright can automatically record video from the browser context, no external screen recording tool needed.

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
