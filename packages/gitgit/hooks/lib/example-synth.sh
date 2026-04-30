#!/bin/bash
# packages/gitgit/hooks/lib/example-synth.sh
# Synthesizes a filled example commit body from the staged diff.
# Sourced by commit-body.sh (block-mode) to populate the deny error message.
#
# Public function:
#   gitgit_synthesize_example
#     Reads staged diff (git diff --cached --name-only + --shortstat).
#     Classifies paths into layers, suggests Slice token and Tests trailer,
#     then prints a multi-line example body on stdout.
#     Never exits non-zero; falls back to a generic template on any error.

# Layer classification regexes (ERE, applied to each path).
_GS_FRONTEND_RE='(\.css|\.scss|\.html|\.tsx?|\.jsx?|app/javascript/)'
_GS_BACKEND_RE='(\.rb|\.py|\.go|\.java|app/controllers/|app/models/|app/services/)'
_GS_SPEC_RE='(spec/|test/|__tests__/|_spec\.|_test\.|\.test\.|\.feature)'
_GS_MIGRATION_RE='(db/migrate/|migrations/)'
_GS_CONFIG_RE='(\.yml|\.yaml|\.json|\.toml|\.lock|Gemfile|package\.json|\.config\.)'
_GS_DOCS_RE='(\.md|\.txt|\.rst|README|CHANGELOG)'

# _gs_classify_path <path>
# Prints the layer name for a single path, or "other" if none matches.
_gs_classify_path() {
  local p="$1"
  # Spec must come before backend because spec paths often match backend regex too.
  if [[ "$p" =~ $_GS_SPEC_RE ]]; then printf 'spec'; return; fi
  if [[ "$p" =~ $_GS_MIGRATION_RE ]]; then printf 'migration'; return; fi
  if [[ "$p" =~ $_GS_FRONTEND_RE ]]; then printf 'frontend'; return; fi
  if [[ "$p" =~ $_GS_BACKEND_RE ]]; then printf 'backend'; return; fi
  if [[ "$p" =~ $_GS_CONFIG_RE ]]; then printf 'config'; return; fi
  if [[ "$p" =~ $_GS_DOCS_RE ]]; then printf 'docs'; return; fi
  printf 'other'
}

# gitgit_synthesize_example
# Prints a multi-line example commit body on stdout.
gitgit_synthesize_example() {
  # Collect staged paths.
  local staged_paths
  staged_paths=$(git diff --cached --name-only 2>/dev/null || true)

  # Collect spec paths from staged diff (used for Tests trailer).
  local spec_paths=""
  local has_frontend=0 has_backend=0 has_spec=0 has_migration=0
  local has_config=0 has_docs=0 has_other=0

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    local layer
    layer=$(_gs_classify_path "$path")
    case "$layer" in
      frontend)  has_frontend=1 ;;
      backend)   has_backend=1 ;;
      spec)      has_spec=1
                 # Accumulate spec paths for the Tests trailer.
                 if [[ -z "$spec_paths" ]]; then
                   spec_paths="$path"
                 else
                   spec_paths="$spec_paths, $path"
                 fi
                 ;;
      migration) has_migration=1 ;;
      config)    has_config=1 ;;
      docs)      has_docs=1 ;;
      *)         has_other=1 ;;
    esac
  done <<< "$staged_paths"

  # Build Slice token.
  local slice_token

  # Check for single-layer opt-out scenarios first.
  local non_docs_count=$(( has_frontend + has_backend + has_spec + has_migration + has_config + has_other ))

  if [[ "$has_docs" -eq 1 && "$non_docs_count" -eq 0 ]]; then
    slice_token="docs-only"
  elif [[ "$has_migration" -eq 1 && "$has_frontend" -eq 0 && "$has_backend" -eq 0 \
          && "$has_spec" -eq 0 && "$has_config" -eq 0 && "$has_docs" -eq 0 && "$has_other" -eq 0 ]]; then
    slice_token="migration-only"
  elif [[ "$has_config" -eq 1 && "$has_frontend" -eq 0 && "$has_backend" -eq 0 \
          && "$has_spec" -eq 0 && "$has_migration" -eq 0 && "$has_docs" -eq 0 && "$has_other" -eq 0 ]]; then
    slice_token="config-only"
  else
    # Build a layer-combination token.
    local parts=""
    [[ "$has_frontend" -eq 1 ]] && parts="${parts:+$parts + }frontend"
    [[ "$has_backend" -eq 1 ]]  && parts="${parts:+$parts + }handler"
    [[ "$has_migration" -eq 1 ]] && parts="${parts:+$parts + }migration"
    [[ "$has_spec" -eq 1 ]]     && parts="${parts:+$parts + }spec"
    [[ "$has_config" -eq 1 ]]   && parts="${parts:+$parts + }config"
    [[ "$has_docs" -eq 1 ]]     && parts="${parts:+$parts + }docs"
    [[ "$has_other" -eq 1 ]]    && parts="${parts:+$parts + }other"
    slice_token="${parts:-handler + spec}"
  fi

  # Build Tests trailer value.
  local tests_value
  if [[ -n "$spec_paths" ]]; then
    tests_value="$spec_paths"
  elif [[ "$slice_token" = "docs-only" || "$slice_token" = "config-only" || \
          "$slice_token" = "migration-only" ]]; then
    tests_value="n/a (${slice_token})"
  else
    tests_value="<spec-path>"
  fi

  # Determine Red-then-green default.
  local rtg_value
  case "$slice_token" in
    docs-only|config-only)
      rtg_value="n/a (no executable behaviour changed)"
      ;;
    migration-only)
      rtg_value="n/a (schema change, no spec required)"
      ;;
    *)
      rtg_value="yes"
      ;;
  esac

  # Print the synthesized example.
  printf '<subject: one imperative sentence>\n'
  printf '\n'
  printf '<WHY paragraph: explain the reason for this change.\n'
  printf 'At least two sentences or 60+ chars ending with a period.>\n'
  printf '\n'
  printf 'Tests: %s\n' "$tests_value"
  printf 'Slice: %s\n' "$slice_token"
  printf 'Red-then-green: %s\n' "$rtg_value"
}
