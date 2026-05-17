# State machine that walks source code character-by-character, tracking
# string and block-comment state, and emits one line per detected comment
# of the form LINE_NUMBER:COMMENT_BODY.
#
# Invocation:
#   awk -v MODE=slash -f comment-detect.awk < source.{ts,js,go,rs,swift,java,kt,c,cpp,cs}
#   awk -v MODE=hash  -f comment-detect.awk < source.{py,rb,sh,zsh,bash,pl,ex,exs,cr}
#
# MODE=slash recognises:
#   line block:   // ...
#   block block:  /* ... */ (spans newlines)
#   string types: "..." '...' `...` (template literal, spans newlines)
#   In NORMAL state, a backslash-then-anything sequence is consumed as a
#   pair so regex-literal escapes (/foo\/bar/) and stray backslashes do not
#   mis-trigger // comment detection on the trailing slash.
#   `//` only opens a comment when at the start of a line or preceded by
#   whitespace, so `http://foo` written as a bare expression does not get
#   mis-read as a comment whose body has lost the URL prefix.
#
# MODE=hash recognises:
#   line block:   # ...
#   string types: "..." '...' """...""" '''...'''
#   A `#` only opens a comment when it sits at the start of a line or is
#   preceded by whitespace. `Recipes#create` (Ruby method notation) and
#   `$foo#bar` (bash parameter expansion in the wild) therefore do not fire,
#   even when an Edit snippet begins mid-string and the state machine has no
#   way to know we started inside one.
#
# Strings shield their contents from comment detection. Block comments stay
# open across newlines; the emitted body is the joined content with newlines
# replaced by a single space so consumers can compare bodies as flat strings.
# Trailing whitespace is stripped from every emitted body so block-comment
# closers on their own line do not introduce a body that differs only in
# end-of-line padding from an inline equivalent.

BEGIN {
  if (MODE == "") MODE = "slash"
  state = "NORMAL"
  block_start_line = 0
  block_buf = ""
}

{
  process_line($0)
  if (state == "BLOCK") block_buf = block_buf " "
}

END {
  if (state == "BLOCK") {
    sub(/[[:space:]]+$/, "", block_buf)
    print block_start_line ":" block_buf
  }
}

function process_line(src,    n, i, ch, nx, nx2, buf) {
  n = length(src)
  i = 1
  while (i <= n) {
    ch = substr(src, i, 1)
    nx = (i < n) ? substr(src, i+1, 1) : ""
    nx2 = (i+1 < n) ? substr(src, i+2, 1) : ""

    if (state == "BLOCK") {
      if (ch == "*" && nx == "/") {
        sub(/[[:space:]]+$/, "", block_buf)
        print block_start_line ":" block_buf
        block_buf = ""
        state = "NORMAL"
        i += 2
        continue
      }
      block_buf = block_buf ch
      i++
      continue
    }

    if (state == "STRING_DQ") {
      if (ch == "\\" && i < n) { i += 2; continue }
      if (ch == "\"") { state = "NORMAL"; i++; continue }
      i++
      continue
    }

    if (state == "STRING_SQ") {
      if (ch == "\\" && i < n) { i += 2; continue }
      if (ch == "'")  { state = "NORMAL"; i++; continue }
      i++
      continue
    }

    if (state == "TEMPLATE") {
      if (ch == "\\" && i < n) { i += 2; continue }
      if (ch == "`") { state = "NORMAL"; i++; continue }
      i++
      continue
    }

    if (state == "TRIPLE_DQ") {
      if (ch == "\\" && i < n) { i += 2; continue }
      if (ch == "\"" && nx == "\"" && nx2 == "\"") {
        state = "NORMAL"; i += 3; continue
      }
      i++
      continue
    }

    if (state == "TRIPLE_SQ") {
      if (ch == "\\" && i < n) { i += 2; continue }
      if (ch == "'" && nx == "'" && nx2 == "'") {
        state = "NORMAL"; i += 3; continue
      }
      i++
      continue
    }

    if (MODE == "slash") {
      if (ch == "\\" && i < n) { i += 2; continue }
      if (ch == "/" && nx == "/" && (i == 1 || substr(src, i-1, 1) ~ /[[:space:]]/)) {
        buf = substr(src, i+2)
        sub(/[[:space:]]+$/, "", buf)
        print NR ":" buf
        return
      }
      if (ch == "/" && nx == "*") {
        state = "BLOCK"
        block_start_line = NR
        block_buf = ""
        i += 2
        continue
      }
      if (ch == "\"") { state = "STRING_DQ"; i++; continue }
      if (ch == "'")  { state = "STRING_SQ"; i++; continue }
      if (ch == "`")  { state = "TEMPLATE"; i++; continue }
      i++
      continue
    } else {
      if (ch == "#" && (i == 1 || substr(src, i-1, 1) ~ /[[:space:]]/)) {
        buf = substr(src, i+1)
        sub(/[[:space:]]+$/, "", buf)
        print NR ":" buf
        return
      }
      if (ch == "\"" && nx == "\"" && nx2 == "\"") {
        state = "TRIPLE_DQ"
        i += 3
        continue
      }
      if (ch == "'" && nx == "'" && nx2 == "'") {
        state = "TRIPLE_SQ"
        i += 3
        continue
      }
      if (ch == "\"") { state = "STRING_DQ"; i++; continue }
      if (ch == "'")  { state = "STRING_SQ"; i++; continue }
      i++
      continue
    }
  }
}
