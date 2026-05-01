#!/usr/bin/env bats
# multiple-refspecs.bats
# `git push origin a:a b:b` carries more than one positional refspec. The
# guard cannot derive a single canonical range so it falls back to scanning
# the last 50 commits on HEAD; a wip commit in that fallback window must
# still be detected.

load helpers

@test "git push with multiple refspecs falls back to HEAD scan and still blocks" {
  export GIT_SHIM_UPSTREAM="origin/branch1"
  export GIT_SHIM_VERIFY_REFS=""   # HEAD~50 should NOT verify, forcing fallback to "HEAD"

  wip_shim_set_revlist "HEAD" $'hhhhhhhhhhhh\niiiiiiiiiiii'
  wip_shim_set_body "hhhhhhhhhhhh" $'Add foo\n\nClean body.\n\nSlice: handler + spec\n'
  wip_shim_set_body "iiiiiiiiiiii" $'WIP from branch2\n\nDraft work.\n\nSlice: wip\n'
  wip_shim_set_subject "iiiiiiiiiiii" "WIP from branch2"

  run_dispatch 'git push origin branch1:branch1 branch2:branch2'

  [ "$status" -eq 2 ]
  [[ "$output" == *"[gitgit/push-wip-gate]"* ]]
  [[ "$output" == *"WIP from branch2"* ]]
  [[ "$output" == *"complex push form"* ]]
}
