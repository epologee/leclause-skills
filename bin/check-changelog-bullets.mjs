#!/usr/bin/env node
//
// Enforce a 280-character cap (the pre-X Twitter limit) per top-level
// bullet in CHANGELOG.md files under packages/. Long enough to land a
// user-visible change plus one consequence, short enough that the
// post-update broadcast stays skimmable.
//
// Modes:
//   bin/check-changelog-bullets.mjs --staged
//     Only flag bullets that overlap with lines added in the staged diff.
//     This is what the pre-commit hook uses: history stays untouched, new
//     or edited bullets must fit the cap.
//
//   bin/check-changelog-bullets.mjs [path...]
//     Lint the given files (or every packages/*/CHANGELOG.md when no path
//     is given). Useful for ad-hoc audits.
//
// Bullet rules:
//   - Top-level bullet starts with "- " at column 0.
//   - Continuation lines indented with whitespace concatenate into the
//     same bullet, separated by a single space.
//   - A blank line, the next "- " at column 0, or a non-indented non-bullet
//     line ends the bullet.

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join } from "node:path";

const CAP = 280;

function collectBullets(text) {
  const lines = text.split("\n");
  const bullets = [];
  let current = null;
  let startLine = 0;
  let endLine = 0;

  const flush = () => {
    if (current !== null) {
      bullets.push({ text: current.trim(), startLine, endLine });
      current = null;
    }
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;
    if (/^- /.test(line)) {
      flush();
      current = line.replace(/^- /, "");
      startLine = lineNum;
      endLine = lineNum;
    } else if (current !== null) {
      if (line.trim() === "") {
        flush();
      } else if (/^\s+/.test(line)) {
        current += " " + line.trim();
        endLine = lineNum;
      } else {
        flush();
      }
    }
  }
  flush();
  return bullets;
}

function stagedAddedLines(path) {
  let diff;
  try {
    diff = execFileSync("git", ["diff", "--cached", "--unified=0", "--", path], {
      encoding: "utf8",
    });
  } catch {
    return new Set();
  }
  const added = new Set();
  let newLine = 0;
  for (const line of diff.split("\n")) {
    const hunk = line.match(/^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/);
    if (hunk) {
      newLine = parseInt(hunk[1], 10);
      continue;
    }
    if (line.startsWith("+++") || line.startsWith("---")) continue;
    if (line.startsWith("+")) {
      added.add(newLine);
      newLine++;
    } else if (line.startsWith(" ")) {
      newLine++;
    }
  }
  return added;
}

function checkFile(path, stagedOnly) {
  const text = readFileSync(path, "utf8");
  const bullets = collectBullets(text);
  const touched = stagedOnly ? stagedAddedLines(path) : null;
  const violations = [];
  for (const b of bullets) {
    if (b.text.length <= CAP) continue;
    if (stagedOnly) {
      let overlap = false;
      for (let l = b.startLine; l <= b.endLine; l++) {
        if (touched.has(l)) {
          overlap = true;
          break;
        }
      }
      if (!overlap) continue;
    }
    violations.push({
      path,
      line: b.startLine,
      length: b.text.length,
      preview: b.text.slice(0, 80),
    });
  }
  return violations;
}

function defaultPaths() {
  const root = "packages";
  if (!existsSync(root)) return [];
  const out = [];
  for (const entry of readdirSync(root)) {
    const candidate = join(root, entry, "CHANGELOG.md");
    if (existsSync(candidate) && statSync(candidate).isFile()) {
      out.push(candidate);
    }
  }
  return out;
}

function stagedChangelogPaths() {
  const out = execFileSync(
    "git",
    ["diff", "--cached", "--name-only", "--diff-filter=ACM"],
    { encoding: "utf8" },
  );
  return out
    .split("\n")
    .filter((p) => /^packages\/[^/]+\/CHANGELOG\.md$/.test(p))
    .filter((p) => existsSync(p));
}

const args = process.argv.slice(2);
const staged = args.includes("--staged");
const paths = staged
  ? stagedChangelogPaths()
  : args.length
    ? args
    : defaultPaths();

let total = 0;
for (const p of paths) {
  if (!existsSync(p)) continue;
  const v = checkFile(p, staged);
  for (const x of v) {
    console.error(`${x.path}:${x.line}: bullet exceeds ${CAP} chars (${x.length})`);
    console.error(`  ${x.preview}...`);
    total++;
  }
}

if (total > 0) {
  console.error("");
  console.error(`ERROR: ${total} CHANGELOG bullet(s) exceed the ${CAP}-character cap.`);
  console.error("Trim the entry to a user-visible change plus at most one consequence.");
  console.error("Engineering history belongs in the commit message, not the broadcast.");
  process.exit(1);
}
