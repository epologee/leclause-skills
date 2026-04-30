#!/usr/bin/env bats
# suggest-slice.bats
# Unit tests for suggest_slice in layer-classify.sh.

load helpers

_slice() {
  bash -c "source '$CLASSIFY_LIB'; suggest_slice '$1'"
}

# ---------------------------------------------------------------------------
# Single-layer opt-outs
# ---------------------------------------------------------------------------

@test "suggest_slice: 'docs' -> 'docs-only'" {
  result=$(_slice "docs")
  [ "$result" = "docs-only" ]
}

@test "suggest_slice: 'config' -> 'config-only'" {
  result=$(_slice "config")
  [ "$result" = "config-only" ]
}

@test "suggest_slice: 'migration' -> 'migration-only'" {
  result=$(_slice "migration")
  [ "$result" = "migration-only" ]
}

@test "suggest_slice: 'spec' -> 'spec-only'" {
  result=$(_slice "spec")
  [ "$result" = "spec-only" ]
}

@test "suggest_slice: 'other' -> 'chore-deps'" {
  result=$(_slice "other")
  [ "$result" = "chore-deps" ]
}

# ---------------------------------------------------------------------------
# Multi-layer combinations
# ---------------------------------------------------------------------------

@test "suggest_slice: 'backend spec' -> 'backend + spec'" {
  result=$(_slice "backend spec")
  [ "$result" = "backend + spec" ]
}

@test "suggest_slice: 'backend frontend spec' -> 'backend + frontend + spec'" {
  result=$(_slice "backend frontend spec")
  [ "$result" = "backend + frontend + spec" ]
}

@test "suggest_slice: 'backend migration spec' -> 'backend + migration + spec'" {
  result=$(_slice "backend migration spec")
  [ "$result" = "backend + migration + spec" ]
}
