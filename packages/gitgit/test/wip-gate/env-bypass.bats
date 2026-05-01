#!/usr/bin/env bats
# env-bypass.bats
# When GITGIT_ALLOW_WIP_PUSH=1 is set in the bash command's leading env-vars,
# the same wip range as wip-blocked.bats is allowed AND a bypass log line is
# written to $GITGIT_WIP_PUSH_LOG.

load helpers

@test "GITGIT_ALLOW_WIP_PUSH=1 git push allows the wip range and logs the bypass" {
  export GIT_SHIM_UPSTREAM="origin/feature/wip-gate"
  export GIT_SHIM_VERIFY_REFS="origin/feature/wip-gate"

  wip_shim_set_revlist "origin/feature/wip-gate..HEAD" $'cccccccccccc\ndddddddddddd'
  wip_shim_set_body "cccccccccccc" $'Add foo\n\nClean body.\n\nSlice: handler + spec\n'
  wip_shim_set_body "dddddddddddd" $'WIP do not ship\n\nQuick scratch.\n\nSlice: wip\n'
  wip_shim_set_subject "dddddddddddd" "WIP do not ship"

  # The guard reads GITGIT_ALLOW_WIP_PUSH from its own environment. The bash
  # command starts with the env-var assignment as the operator would type it;
  # we also export it so the dispatch process inherits it (same shape as a
  # real shell evaluation of "VAR=1 cmd ...").
  GITGIT_ALLOW_WIP_PUSH=1 run_dispatch 'GITGIT_ALLOW_WIP_PUSH=1 git push'

  [ "$status" -eq 0 ]
  [[ "$output" != *"[gitgit/push-wip-gate]"* ]]

  [ -f "$GITGIT_WIP_PUSH_LOG" ]
  grep -q "|env" "$GITGIT_WIP_PUSH_LOG"
  grep -q "dddddddddddd" "$GITGIT_WIP_PUSH_LOG"
}
