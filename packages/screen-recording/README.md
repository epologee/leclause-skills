# screen-recording

Automated screen recordings and demo videos of browser-based features using Playwright video recording. Useful for bug evidence, demo clips, and visual regression checks where a static screenshot is not enough.

## Commands

### `/screen-recording`

Drives a headless browser through a scripted flow and captures the session as a video file. Output lands in a path the skill names in its report so you can share or attach it.

## Activation

Invoked explicitly with `/screen-recording`. The skill does not self-activate, because Playwright is an out-of-band global install: silent activation without that runtime would fail.

## Requirements

[Playwright](https://playwright.dev/) installed globally:

```bash
npm install -g playwright
```

Always close the browser explicitly at the end of a script; orphaned Playwright processes can block a fresh Chrome launch. If Chrome refuses to start, kill stale processes:

```bash
pkill -f "user-data-dir=/tmp/pw-"
```

## Installation

```bash
/plugin install screen-recording@leclause
```
