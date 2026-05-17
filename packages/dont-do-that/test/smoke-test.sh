#!/bin/bash
# Smoke test suite for the dont-do-that dispatcher. Every case routes
# through hooks/dispatch.sh with an explicit hook_event_name, so the test
# covers the real path Claude Code takes at runtime.
# Run from the plugin root: bash test/smoke-test.sh
# Exit code 0 = all pass, 1 = failures.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DISPATCH="${SCRIPT_DIR}/../hooks/dispatch.sh"
PASS=0
FAIL=0

stop_payload() {
  local text="$1" active="${2:-false}"
  jq -cn --arg t "$text" --argjson a "$active" \
    '{hook_event_name:"Stop", last_assistant_message:$t, stop_hook_active:$a}'
}

pretool_bash() {
  local cmd="$1"
  jq -cn --arg c "$cmd" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}}'
}

posttool_edit() {
  local file="$1" content="$2"
  jq -cn --arg f "$file" --arg c "$content" \
    '{hook_event_name:"PostToolUse", tool_name:"Edit", tool_input:{file_path:$f, new_string:$c}}'
}

pretool_edit() {
  local file="$1" old="$2" new="$3"
  jq -cn --arg f "$file" --arg o "$old" --arg n "$new" \
    '{hook_event_name:"PreToolUse", tool_name:"Edit", tool_input:{file_path:$f, old_string:$o, new_string:$n}}'
}

pretool_write() {
  local file="$1" content="$2"
  jq -cn --arg f "$file" --arg c "$content" \
    '{hook_event_name:"PreToolUse", tool_name:"Write", tool_input:{file_path:$f, content:$c}}'
}

expect_block() {
  local description="$1" payload="$2"
  local out
  out=$(printf '%s' "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"decision":"block"'; then
    # Verify uniform mnemonic prefix.
    if echo "$out" | grep -q '\[dont-do-that/'; then
      PASS=$((PASS + 1))
    else
      echo "FAIL [missing mnemonic prefix]: ${description}"
      echo "  output: ${out}"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "FAIL [block expected]: ${description}"
    echo "  output: ${out:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

expect_block_mnemonic() {
  local description="$1" mnemonic="$2" payload="$3"
  local out
  out=$(printf '%s' "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q "\[dont-do-that/${mnemonic}\]"; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [block by ${mnemonic} expected]: ${description}"
    echo "  output: ${out:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

expect_pass() {
  local description="$1" payload="$2"
  local out
  out=$(printf '%s' "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"decision":"block"'; then
    echo "FAIL [pass expected]: ${description}"
    echo "  output: ${out}"
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi
}

expect_deny() {
  local description="$1" payload="$2" expected_substring="${3:-}"
  local stderr_file exit_code stderr_content
  stderr_file=$(mktemp)
  printf '%s' "$payload" | bash "$DISPATCH" >/dev/null 2>"$stderr_file"
  exit_code=$?
  stderr_content=$(cat "$stderr_file")
  rm -f "$stderr_file"
  if [ "$exit_code" -ne 2 ]; then
    echo "FAIL [deny expected exit 2]: ${description}"
    echo "  exit: ${exit_code}"
    echo "  stderr: ${stderr_content:-<empty>}"
    FAIL=$((FAIL + 1))
    return
  fi
  if ! echo "$stderr_content" | grep -q '\[dont-do-that/'; then
    echo "FAIL [missing mnemonic prefix]: ${description}"
    echo "  stderr: ${stderr_content}"
    FAIL=$((FAIL + 1))
    return
  fi
  if [ -n "$expected_substring" ] && ! echo "$stderr_content" | grep -qF -- "$expected_substring"; then
    echo "FAIL [expected '${expected_substring}']: ${description}"
    echo "  stderr: ${stderr_content}"
    FAIL=$((FAIL + 1))
    return
  fi
  PASS=$((PASS + 1))
}

expect_allow() {
  local description="$1" payload="$2"
  local stderr_file exit_code
  stderr_file=$(mktemp)
  printf '%s' "$payload" | bash "$DISPATCH" >/dev/null 2>"$stderr_file"
  exit_code=$?
  rm -f "$stderr_file"
  if [ "$exit_code" -ne 0 ]; then
    echo "FAIL [allow expected exit 0]: ${description}"
    echo "  exit: ${exit_code}"
    FAIL=$((FAIL + 1))
    return
  fi
  PASS=$((PASS + 1))
}

expect_context() {
  local description="$1" payload="$2"
  local out
  out=$(printf '%s' "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"additionalContext"'; then
    if echo "$out" | grep -q '\[dont-do-that/dash\]'; then
      PASS=$((PASS + 1))
    else
      echo "FAIL [missing dash mnemonic]: ${description}"
      echo "  output: ${out}"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "FAIL [additionalContext expected]: ${description}"
    echo "  output: ${out:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

# --- premature-interruption ---

expect_block "premature: no escape hatch" \
  "$(stop_payload "Ik heb het aangepast.")"

expect_pass "premature: finish flag with substantive sentence" \
  "$(stop_payload "Beide hooks gefixt en de syntax check slaagt nu. 🏁")"

expect_block "premature: bare finish flag" \
  "$(stop_payload "🏁")"

expect_block "premature: flag without substantive sentence" \
  "$(stop_payload "Klaar 🏁")"

expect_pass "premature: question hands off to compliance" \
  "$(stop_payload "Wat bedoel je precies?")"

expect_block "premature: flag + question is contradiction" \
  "$(stop_payload "Of zal ik hem starten? 🏁")"

expect_block "premature: flag + question separated" \
  "$(stop_payload "Wil je dit nog? Ja hoor. 🏁")"

expect_pass "premature: WIP hatch" \
  "$(stop_payload "Bezig met hooks 🚧")"

expect_pass "premature: mutex skips" \
  "$(stop_payload "Iets." true)"

# --- compliance-reflex ---

expect_block "compliance: shall I question" \
  "$(stop_payload "Wil je dat ik dit nog aanpas?")"

expect_block "compliance: preference question" \
  "$(stop_payload "Wat heeft je voorkeur?")"

expect_block "compliance: English shall I" \
  "$(stop_payload "Should I update this?")"

expect_pass "compliance: compass escape" \
  "$(stop_payload "🧭 Andere richting nodig?")"

expect_pass "compliance: genuine question" \
  "$(stop_payload "Bedoel je de header of de footer?")"

expect_pass "compliance: WIP hatch" \
  "$(stop_payload "Zal ik dit fixen? 🚧")"

expect_pass "compliance: no question mark" \
  "$(stop_payload "Ik heb de configuratie aangepast en alle testen blijven groen. 🏁")"

# --- cache-excuse ---

expect_block "cache: browser cache blame" \
  "$(stop_payload "Dit komt door de browser cache.")"

expect_block "cache: hard refresh suggestion" \
  "$(stop_payload "Probeer Cmd+Shift+R.")"

expect_pass "cache: no cache mention" \
  "$(stop_payload "Het probleem zit in de router config en niet elders. 🏁")"

expect_pass "cache: WIP hatch" \
  "$(stop_payload "Browser cache issue 🚧")"

expect_pass "cache: mutex skips" \
  "$(stop_payload "Browser cache." true)"

# --- false-claims ---

expect_block "false-claims: pre-existing" \
  "$(stop_payload "Dit is een pre-existing failure.")"

expect_block "false-claims: already broken" \
  "$(stop_payload "Dit was al stuk.")"

expect_block "false-claims: known issue" \
  "$(stop_payload "Dit is een known issue.")"

expect_pass "false-claims: clean text" \
  "$(stop_payload "De test faalt door een typo in de config van middleware. 🏁")"

expect_pass "false-claims: WIP hatch" \
  "$(stop_payload "Pre-existing issue 🚧")"

expect_block "false-claims: ignores mutex (always runs)" \
  "$(stop_payload "Dit is een pre-existing failure." true)"

# --- verification-delegation ---
# Every case includes a substantive sentence + 🏁 so the premature-interruption
# guard in the chain hands off to verify instead of blocking first.

expect_block "verification: unproven claim" \
  "$(stop_payload "Ik heb de endpoint niet geraakt maar dit zou nu moeten werken. 🏁")"

expect_block "verification: asks user to check" \
  "$(stop_payload "De wijziging staat in het bestand. Check of het werkt. 🏁")"

expect_block "verification: asks user to refresh" \
  "$(stop_payload "Ik heb de styling aangepast. Refresh de pagina. 🏁")"

expect_block "verification: English claim" \
  "$(stop_payload "I changed the config. This should now work. 🏁")"

expect_pass "verification: Geverifieerd escape" \
  "$(stop_payload "Geverifieerd: screenshot bevestigt de nieuwe styling werkt. 🏁")"

expect_pass "verification: clean text" \
  "$(stop_payload "De wijziging staat in het bestand en de testen blijven groen. 🏁")"

expect_pass "verification: WIP hatch" \
  "$(stop_payload "Zou moeten werken 🚧")"

expect_pass "verification: mutex skips" \
  "$(stop_payload "Zou moeten werken. 🏁" true)"

# --- duh (instruction-instead-of-execution) ---
# Each text is long enough to bypass the premature guard (>=40 non-emoji
# chars + sentence terminator + 🏁), so the block we observe is duh
# itself, not premature catching short text.

expect_block_mnemonic "duh: NL offer with command" "duh" \
  "$(stop_payload "De wijzigingen staan klaar in het bestand. Je kunt dit checken door \`bin/foo\` te draaien op je machine. 🏁")"

expect_block_mnemonic "duh: EN offer with command" "duh" \
  "$(stop_payload "The change is staged in the right module. You can verify this by running \`npm test\` against the suite. 🏁")"

expect_block_mnemonic "duh: imperative Run cmd" "duh" \
  "$(stop_payload "De migratie is voorbereid en klaar voor uitvoering. Run \`bin/migrate\` to apply the changes now. 🏁")"

expect_block_mnemonic "duh: imperative Voer uit" "duh" \
  "$(stop_payload "De spec is bijgewerkt en klaar voor groen. Voer \`bundle exec rspec spec/foo_spec.rb\` uit om te checken. 🏁")"

expect_block_mnemonic "duh: open in browser" "duh" \
  "$(stop_payload "De pagina draait op de dev-server en is bereikbaar. Open http://localhost:3000 in je browser om te kijken. 🏁")"

expect_pass "duh: Instructie escape" \
  "$(stop_payload "De stap is gedocumenteerd voor handmatige uitvoering. Instructie: voer \`bin/foo\` handmatig uit op de prod-host. 🏁")"

expect_pass "duh: WIP hatch" \
  "$(stop_payload "Je kunt dit checken door \`bin/foo\` te draaien op je machine. 🚧")"

expect_pass "duh: clean text" \
  "$(stop_payload "Geverifieerd: alle tests groen na de wijziging, geen verdere actie nodig op deze branch. 🏁")"

# --- block-followup-without-issue ---

expect_deny "followup: follow-up taal in gh api body" \
  "$(pretool_bash 'gh api repos/foo/bar/issues --field body="Komt in een follow-up PR"')" \
  "followup"

expect_deny "followup: buiten-scope phrasing" \
  "$(pretool_bash 'gh api repos/foo/bar/issues --field body="Buiten scope van deze mission"')" \
  "followup"

expect_allow "followup: Bewust uitgesteld escape" \
  "$(pretool_bash 'gh api repos/foo/bar/issues --field body="Bewust uitgesteld: volgt in een follow-up PR"')"

expect_allow "followup: non-gh command passes" \
  "$(pretool_bash 'echo follow-up')"

# --- visual-verify-before-send --- allow-comment: section header
# allow-comment: graham send of a media file requires a recent Read on a preview PNG/JPG in the transcript
# allow-comment: without that, the assistant is sending unverified output

VVBS_DIR=$(mktemp -d)
echo '{"role":"assistant","message":{"content":[{"type":"text","text":"hi"}]}}' \
  > "$VVBS_DIR/empty.jsonl"
echo '{"role":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"/foo/preview.png"}}]}}' \
  > "$VVBS_DIR/with-read.jsonl"

vvbs_payload() {
  local cmd="$1" transcript="$2"
  jq -cn --arg c "$cmd" --arg t "$transcript" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}, transcript_path:$t}'
}

expect_deny "visual-verify: graham file mp4 without recent Read denied" \
  "$(vvbs_payload 'graham file out/iter25.mp4 caption' "$VVBS_DIR/empty.jsonl")" \
  "visual-verify-before-send"

expect_allow "visual-verify: graham file mp4 with recent Read allowed" \
  "$(vvbs_payload 'graham file out/iter25.mp4 caption' "$VVBS_DIR/with-read.jsonl")"

expect_allow "visual-verify: verified-visually escape allowed" \
  "$(vvbs_payload 'graham file out/iter25.mp4 caption # verified-visually' "$VVBS_DIR/empty.jsonl")"

expect_allow "visual-verify: graham status passes silently" \
  "$(vvbs_payload 'graham status' "$VVBS_DIR/empty.jsonl")"

expect_allow "visual-verify: non-media graham file path passes" \
  "$(vvbs_payload 'graham file /tmp/notes.txt caption' "$VVBS_DIR/empty.jsonl")"

rm -rf "$VVBS_DIR"

# --- no-remote ---
# Each case sets up a temp git repo and cd's in before invoking the hook,
# because the guard reads `git remote` against the current working directory.

ORIG_PWD="$PWD"

NO_REMOTE=$(mktemp -d)
git -C "$NO_REMOTE" init -q
cd "$NO_REMOTE"
expect_deny "no-remote: push without any remote" \
  "$(pretool_bash 'git push')" \
  "no-remote"
expect_deny "no-remote: push origin without any remote" \
  "$(pretool_bash 'git push origin main')" \
  "no-remote"
cd "$ORIG_PWD"
rm -rf "$NO_REMOTE"

WITH_REMOTE=$(mktemp -d)
git -C "$WITH_REMOTE" init -q
git -C "$WITH_REMOTE" remote add origin https://example.com/foo.git
cd "$WITH_REMOTE"
expect_allow "no-remote: push allowed when origin configured" \
  "$(pretool_bash 'git push')"
expect_allow "no-remote: push origin matches existing remote" \
  "$(pretool_bash 'git push origin main')"
expect_deny "no-remote: push to unknown named remote" \
  "$(pretool_bash 'git push upstream main')" \
  "no-remote"
cd "$ORIG_PWD"
rm -rf "$WITH_REMOTE"

NO_REMOTE2=$(mktemp -d)
git -C "$NO_REMOTE2" init -q
cd "$NO_REMOTE2"
expect_allow "no-remote: non-push git commands pass" \
  "$(pretool_bash 'git status')"
expect_allow "no-remote: non-git commands pass" \
  "$(pretool_bash 'echo no push here')"
cd "$ORIG_PWD"
rm -rf "$NO_REMOTE2"

# --- no-worktree-deploy --- allow-comment: section divider matches existing smoke-test.sh pattern

pretool_bash_cwd() {
  local cmd="$1" cwd="$2"
  jq -cn --arg c "$cmd" --arg w "$cwd" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}, cwd:$w}'
}

WT_MAIN=$(mktemp -d)
git -C "$WT_MAIN" init -q
git -C "$WT_MAIN" commit --allow-empty -q -m "init"
WT_BRANCH=$(mktemp -u)
git -C "$WT_MAIN" worktree add -q -b feature "$WT_BRANCH"

expect_deny "no-worktree-deploy: ansible-playbook from worktree blocked" \
  "$(pretool_bash_cwd 'ansible-playbook site.yml' "$WT_BRANCH")" \
  "no-worktree-deploy"
expect_allow "no-worktree-deploy: ansible-playbook --check from worktree passes" \
  "$(pretool_bash_cwd 'ansible-playbook --check site.yml' "$WT_BRANCH")"
expect_allow "no-worktree-deploy: ansible-playbook --syntax-check from worktree passes" \
  "$(pretool_bash_cwd 'ansible-playbook --syntax-check site.yml' "$WT_BRANCH")"
expect_allow "no-worktree-deploy: ansible-playbook from canonical checkout passes" \
  "$(pretool_bash_cwd 'ansible-playbook site.yml' "$WT_MAIN")"
expect_allow "no-worktree-deploy: git worktree commands from worktree pass" \
  "$(pretool_bash_cwd 'git status' "$WT_BRANCH")"
expect_allow "no-worktree-deploy: non-ansible command from worktree passes" \
  "$(pretool_bash_cwd 'echo hello' "$WT_BRANCH")"

git -C "$WT_MAIN" worktree remove -f "$WT_BRANCH" 2>/dev/null || rm -rf "$WT_BRANCH"
rm -rf "$WT_MAIN"

NON_GIT=$(mktemp -d)
expect_allow "no-worktree-deploy: ansible-playbook outside git repo passes" \
  "$(pretool_bash_cwd 'ansible-playbook site.yml' "$NON_GIT")"
rm -rf "$NON_GIT"

# --- block-inline-dashes ---
# The awk dash-detect needs an em-dash in a non-code line. We use printf
# to inject the raw byte so the literal stays out of the file.
EMDASH="$(printf '\xe2\x80\x94')"
expect_context "dash: em-dash in Edit new_string" \
  "$(posttool_edit "/tmp/x.md" "Some prose with ${EMDASH} dash here")"

expect_allow "dash: clean Edit new_string passes silent" \
  "$(posttool_edit "/tmp/x.md" "No dash here.")"

# --- no-code-comments ---

expect_deny "no-code-comments: Edit adds // comment in .ts" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'let x = 1;\n// dumb explanation\nlet y = 2;')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds # comment in .py" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\n# dumb explanation\ny = 2')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds multi-line block in .ts" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'let x = 1;\n/* multi\n line\n block */\nlet y = 2;')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds // comment in .swift" \
  "$(pretool_edit "/tmp/x.swift" "let x = 1" $'let x = 1\n// dumb explanation\nlet y = 2')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds # comment in .rb" \
  "$(pretool_edit "/tmp/x.rb" "x = 1" $'x = 1\n# dumb\ny = 2')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds // comment in .go" \
  "$(pretool_edit "/tmp/x.go" "var x = 1" $'var x = 1\n// dumb explanation\nvar y = 2')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds /// doc comment in .rs" \
  "$(pretool_edit "/tmp/x.rs" "let x = 1;" $'let x = 1;\n/// dumb explanation\nfn foo() {}')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit adds JSDoc /** */ in .ts" \
  "$(pretool_edit "/tmp/x.ts" "function foo() {}" $'/**\n * does something\n */\nfunction foo() {}')" \
  "no-code-comments"

expect_deny "no-code-comments: Edit changes existing comment body in .py" \
  "$(pretool_edit "/tmp/x.py" $'# old text\nx = 1' $'# new text\nx = 1')" \
  "no-code-comments"

expect_deny "no-code-comments: Write new .swift with bare comment" \
  "$(pretool_write "/tmp/new-x.swift" $'import Foundation\nlet x = 1\n// bad comment')" \
  "no-code-comments"

expect_allow "no-code-comments: Edit adds string containing // in .ts" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'let x = 1;\nlet u = "// not a comment";')"

expect_allow "no-code-comments: Edit adds string containing # in .py" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\nu = "# not a comment"')"

expect_allow "no-code-comments: Edit adds template literal with // in .ts" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'let x = 1;\nlet t = `// inside template`;')"

expect_allow "no-code-comments: Edit adds triple-quoted text with # in .py" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\ny = """\n# not a comment\n"""')"

expect_allow "no-code-comments: Edit adds URL comment in .swift" \
  "$(pretool_edit "/tmp/x.swift" "let x = 1" $'let x = 1\n// see https://example.com/foo\nlet y = 2')"

expect_allow "no-code-comments: Edit adds URL comment in .py" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\n# see https://example.com\ny = 2')"

expect_allow "no-code-comments: Edit adds allow-comment escape in .py" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\n# allow-comment: legacy quirk\ny = 2')"

expect_allow "no-code-comments: Edit adds frozen_string_literal pragma in .rb" \
  "$(pretool_edit "/tmp/x.rb" "x = 1" $'# frozen_string_literal: true\nx = 1\ny = 2')"

expect_allow "no-code-comments: Edit adds @ts-ignore pragma in .ts" \
  "$(pretool_edit "/tmp/x.ts" "let x = any;" $'// @ts-ignore\nlet x = any;')"

expect_allow "no-code-comments: Edit adds noqa pragma in .py" \
  "$(pretool_edit "/tmp/x.py" "import os" $'import os  # noqa: F401\nimport sys')"

expect_allow "no-code-comments: Edit adds go:build directive in .go" \
  "$(pretool_edit "/tmp/x.go" "package main" $'//go:build linux\npackage main')"

expect_allow "no-code-comments: Edit adds eslint-disable pragma in .ts" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'// eslint-disable-next-line\nlet x = 1;')"

expect_allow "no-code-comments: Write new .sh with shebang on line 1" \
  "$(pretool_write "/tmp/new-x.sh" $'#!/usr/bin/env bash\necho hi')"

expect_allow "no-code-comments: Edit adds // comment in .md (non-code file)" \
  "$(pretool_edit "/tmp/x.md" "# Heading" $'# Heading\n// looks like a comment but markdown ignores it')"

expect_allow "no-code-comments: Edit adds # in .yml (non-code file)" \
  "$(pretool_edit "/tmp/x.yml" "key: value" $'key: value\n# yaml comment is fine')"

expect_allow "no-code-comments: Edit adds // in .json (non-code file)" \
  "$(pretool_edit "/tmp/x.json" '{}' $'{}\n// not actually json')"

expect_allow "no-code-comments: Edit preserves existing comment unchanged" \
  "$(pretool_edit "/tmp/x.py" $'# existing\nx = 1' $'# existing\nx = 1\ny = 2')"

expect_allow "no-code-comments: Edit removes a comment (no new comment)" \
  "$(pretool_edit "/tmp/x.py" $'# leaving\nx = 1' "x = 1")"

expect_allow "no-code-comments: Edit on file with no extension passes" \
  "$(pretool_edit "/tmp/x" "old" $'old\n// looks like comment')"

expect_allow "no-code-comments: Edit on .css passes (style-only language)" \
  "$(pretool_edit "/tmp/x.css" "body {}" $'body {}\n/* css comments are fine */')"

expect_deny "no-code-comments: MultiEdit first edit adds comment" \
  "$(jq -cn '{hook_event_name:"PreToolUse", tool_name:"MultiEdit", tool_input:{file_path:"/tmp/x.ts", edits:[{old_string:"a", new_string:"a;\n// added"}, {old_string:"b", new_string:"b;"}]}}')" \
  "no-code-comments"

expect_allow "no-code-comments: Edit adds JS regex literal with escaped slashes" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'let x = 1;\nconst re = /https?:\\/\\//g;')"

expect_allow "no-code-comments: Edit adds split on URL regex in .js" \
  "$(pretool_edit "/tmp/x.js" "let x = 1;" $'let x = 1;\nconst parts = url.split(/\\/\\//)[1];')"

expect_deny "no-code-comments: bare allow-comment without colon is blocked" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\n# Use allow-comment to bypass')" \
  "no-code-comments"

expect_deny "no-code-comments: pylint mid-prose is blocked" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\n# I hate pylint: it is annoying')" \
  "no-code-comments"

expect_deny "no-code-comments: noqa mid-prose is blocked" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'x = 1\n# the noqa rule is dumb')" \
  "no-code-comments"

expect_allow "no-code-comments: noqa at body start passes" \
  "$(pretool_edit "/tmp/x.py" "import os" $'import os  # noqa: F401')"

expect_allow "no-code-comments: rubocop pragma at body start passes" \
  "$(pretool_edit "/tmp/x.rb" "def foo; end" $'def foo  # rubocop:disable Style/EmptyMethod\nend')"

expect_allow "no-code-comments: SPDX license header passes" \
  "$(pretool_edit "/tmp/x.rs" "fn main() {}" $'// SPDX-License-Identifier: MIT\nfn main() {}')"

expect_allow "no-code-comments: Licensed under MIT passes" \
  "$(pretool_edit "/tmp/x.rb" "x = 1" $'# Licensed under the MIT License, see LICENSE for details\nx = 1')"

expect_allow "no-code-comments: @generated marker passes" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'// @generated by tsoa\nlet x = 1;')"

expect_allow "no-code-comments: Auto-generated marker passes" \
  "$(pretool_edit "/tmp/x.py" "x = 1" $'# Auto-generated by protoc-gen-py. Do not edit.\nx = 1')"

expect_allow "no-code-comments: .jsx files are excluded from inspection" \
  "$(pretool_edit "/tmp/x.jsx" "let x = 1;" $'let x = 1;\n// this passes because jsx is excluded')"

expect_allow "no-code-comments: .tsx files are excluded from inspection" \
  "$(pretool_edit "/tmp/x.tsx" "let x = 1;" $'let x = 1;\n// this passes because tsx is excluded')"

expect_deny "no-code-comments: .js still checked (not jsx)" \
  "$(pretool_edit "/tmp/x.js" "let x = 1;" $'let x = 1;\n// this is still blocked in plain js')" \
  "no-code-comments"

expect_deny "no-code-comments: Swift /// doc comment blocked by design" \
  "$(pretool_edit "/tmp/x.swift" "func foo() {}" $'/// Documentation\nfunc foo() {}')" \
  "no-code-comments"

expect_allow "no-code-comments: Swift /// doc with allow-comment escape" \
  "$(pretool_edit "/tmp/x.swift" "func foo() {}" $'/// Documentation. allow-comment: generates API docs\nfunc foo() {}')"

expect_allow "no-code-comments: /// doc with @generated pragma passes (marker chars stripped)" \
  "$(pretool_edit "/tmp/x.rs" "fn foo() {}" $'/// @generated by build.rs\nfn foo() {}')"

expect_allow "no-code-comments: /** */ block with @generated pragma passes (marker chars stripped)" \
  "$(pretool_edit "/tmp/x.ts" "let x = 1;" $'/** @generated by openapi */\nlet x = 1;')"

expect_allow "no-code-comments: //! Rust inner-doc with @generated passes" \
  "$(pretool_edit "/tmp/x.rs" "fn foo() {}" $'//! @generated by build.rs\nfn foo() {}')"

expect_deny "no-code-comments: prose body starting with 'go:' is blocked (not a Go directive)" \
  "$(pretool_edit "/tmp/x.go" "package main" $'// go: fix this later\npackage main')" \
  "no-code-comments"

expect_allow "no-code-comments: //go:generate directive passes" \
  "$(pretool_edit "/tmp/x.go" "package main" $'//go:generate stringer -type=Pill\npackage main')"

expect_allow "no-code-comments: //go:embed directive passes" \
  "$(pretool_edit "/tmp/x.go" "package main" $'//go:embed static/*\npackage main')"

expect_deny "no-code-comments: Write new .sh with comment after shebang is blocked" \
  "$(pretool_write "/tmp/new-x-after-shebang.sh" $'#!/usr/bin/env bash\n# sets up environment\nexport PATH=$PATH:/foo')" \
  "no-code-comments"

# --- Summary ---

TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo "${TOTAL}/${TOTAL} passed"
  exit 0
else
  echo "${PASS}/${TOTAL} passed, ${FAIL} failed"
  exit 1
fi
