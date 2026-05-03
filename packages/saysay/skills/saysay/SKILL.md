---
name: saysay
user-invocable: true
description: Use when the user types /saysay to enter speech mode, or /saysay off to exit. In speech mode, Claude speaks its output aloud via macOS say command after every response.
allowed-tools:
  - Bash(saysay *)
  - Bash(*| saysay*)
  - Bash(say-phonetic add *)
  - Bash(say-phonetic remove *)
  - Bash(say-phonetic list*)
disable-model-invocation: true
---

# Say Mode

Speech output as a replacement for the screen. When say mode is active, speak your response aloud via the macOS `say` command after every response. Text still appears on screen, but the user is not watching. Speech IS the output.

## Activation

| Command | Effect |
|---------|--------|
| `/saysay` | Activate say mode |
| `/saysay off` | Deactivate say mode |

On activation: confirm with speech that the mode is active. On deactivation: confirm with speech that you are stopping.

## Voice

Always the system default voice, no `-v` flag. Ever. The Siri voice set in System Settings is used for everything: Dutch, English, code, all of it.

Speed: `-r 240`

**Phonetic preprocessor:** English words that the default voice mispronounces can be phonetically translated via `say-phonetic`. This is an opt-in dictionary per user, stored in `$XDG_DATA_HOME/saysay/phonetics.json` (default: `~/.local/share/saysay/phonetics.json`). Most loanwords are pronounced correctly; only problem cases are added.

```bash
say-phonetic add retake rietéék
say-phonetic remove retake
say-phonetic list
```

**Phonetics via natural language:** When the user specifies a phonetic mapping in plain language, run the `say-phonetic` command. Recognizable patterns:

- "retake als rietéék" -> `say-phonetic add retake rietéék`
- "spreek retake uit als rietéék" -> `say-phonetic add retake rietéék`
- "retake niet meer fonetisch" -> `say-phonetic remove retake`

This also works mid-session during `/saysay`. Add the word and use it immediately in the next speech output.

## The say command

**Always use `saysay` instead of `say`.** `saysay` handles the full chain: phonetic preprocessing, serialization (multiple sessions speak in sequence, not simultaneously), and a short separator sound (Pop) at the start of each message.

```bash
echo "The text to be spoken." | saysay --context "label"
```

**Never this:** `say -r 240` (direct say, no serialization)
**Never this:** `say-phonetic process | say -r 240` (old pipeline)
**Never this:** heredoc syntax (`saysay <<'SAY'`), that sprawls in the tool call display
**Always this:** `echo "text" | saysay --context "label"`

Default speed is `-r 240`. Overridable: `echo "text" | saysay -r 180 --context "label"`.

`saysay` blocks in the shell: it waits until the message has been spoken. But ALWAYS invoke it with `run_in_background: true` on the Bash tool call. That lets text output and the prompt continue while speech runs. The Bash call stops automatically when speaking is done.

### Session context

Every saysay call includes `--context "label"` so the user with multiple parallel sessions can hear which session is speaking. The label is at most two words and describes the **topic** of the conversation, not the branch or directory.

On activation of say mode: determine a short thematic label based on the conversation so far. Use that label consistently in all saysay calls for the session.

Examples:
- Conversation about saysay improvements -> `--context "saysay fixes"`
- Conversation about a calculator feature -> `--context "calculator"`
- Conversation about hook configuration -> `--context "hook config"`

Without `--context`, saysay falls back to git remote + branch (max 2 words). With `--no-context` the prefix is omitted entirely.

## Translating to speech

Speech replaces the screen. That means: do not read out what is there, but convey what the user needs to know. This is the core of the skill.

### Principles

- **Summarize at the right level.** A table with 10 rows is not read cell by cell. "There are ten results, the most important are X and Y" is better.
- **Structure becomes intonation.** Bullet points, headers, and sections do not exist in speech. Use transitional phrases: "There is also...", "The most important point is..."
- **Dose technical details.** A file path or short code snippet can be literal. An entire diff or long stack trace cannot. Describe the essence: "The error is on line 42 of the user model, a nil reference on the email field."
- **Omit punctuation markers.** No "period", "comma", "quote mark". The text must sound like spoken language.
- **Numbers and special characters.** Speak them out: `127.0.0.1` becomes "one twenty-seven dot zero dot zero dot one". `$HOME` becomes "dollar HOME". But be pragmatic: if a value is not relevant, skip it.

### What IS literal

- Short code snippets (method name, variable, command)
- Error messages (the first line)
- File names and paths (when the user needs them)
- Numbers that matter

### What is NOT literal

- Markdown formatting (`**`, `#`, `` ` ``, `---`)
- Tables (describe the contents)
- Long diffs (describe what changed)
- Repeating patterns ("and then three more similar entries")
- URLs and links (already on screen, reading them aloud adds nothing)

### Tool calls

While working (writing code, reading files, running tests) you do not need to speak every tool call. Speak the conclusion, not the process. "Tests are green" is enough, not "I am now running bundle exec rspec spec slash models and the result is twelve examples zero failures".

Exception: if a tool call fails or produces something unexpected, do speak that.

## Example

Suppose the user asks "what is the status of the test suite?" and you run the tests.

**Screen (text output):**
```
Tests: 847 examples, 2 failures
- spec/models/user_spec.rb:42 - expected nil to eq "test@example.com"
- spec/services/billing_spec.rb:108 - timeout after 5 seconds
```

**Speech:**
```bash
echo "The test suite has two failures out of eight hundred and forty-seven tests. The first is in the user model, a nil value where an email address is expected, on line 42. The second is a timeout in the billing service on line 108." | saysay
```

## Combination with other skills

When say mode is active and another skill produces output (recap, changelog, analysis), that output must also be spoken. Not just an intro ("here is the recap") but the content itself, translated to speech. The text on screen contains the details (tables, paths, lists); speech summarizes what the user needs to know in order to act.

**Wrong:** `echo "Here is the recap." | saysay` followed by unspoken text.
**Right:** `echo "We were working on X. The status is Y. There are still Z things open, namely..." | saysay` with the full content translated to speech.

## Persistent mode

Say mode stays active until the user says `/saysay off`. Every response ends with a `say` call. This applies to short answers, error messages, and intermediate steps as well. If you have nothing substantial to report, you do not need to speak (e.g. a pure tool call without a conclusion).
