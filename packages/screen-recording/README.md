# screen-recording

Automated screen recordings and demo videos of browser-based features using Playwright video recording. Useful for bug evidence, demo clips, and visual regression checks where a static screenshot is not enough.

## Commands

### `/screen-recording`

Drives a headless browser through a scripted flow and captures the session as a video file. Output lands in a path the skill names in its report so you can share or attach it.

## Auto-trigger

Activates when the user asks for an automated recording, demo video, or visual documentation of a browser flow.

## Requirements

[Playwright](https://playwright.dev/) installed globally:

```bash
npm install -g playwright
```

The skill never closes the browser explicitly inside scripts; zombie Playwright processes block the real Chrome session. If Chrome refuses to start, kill stale processes:

```bash
pkill -f "user-data-dir=/tmp/pw-"
```

## Installation

```bash
/plugin install screen-recording@leclause
```
