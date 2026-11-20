#!/usr/bin/env bash
set -eu
source bin/backends/herdr.sh
lab() { env PATH="$LAB_REAL_PATH" bash bin/fm-herdr-lab.sh run fm-lab-doorbell "$@"; }
for shape in foreign-glyph width-mismatch blank-continuation boxed-continuation unindented-transcript stale-envelope; do
  ws=$(lab workspace create --cwd "$PWD" --label "adversarial-$shape" --no-focus)
  pane=$(jq -er '.result.root_pane.pane_id' <<<"$ws")
  wid=$(jq -er '.result.workspace.workspace_id' <<<"$ws")
  lab pane run "$pane" "python3 '$PWD/.lab/adversarial/emit.py' '$shape'" >/dev/null
  sleep 0.6
  lab pane read "$pane" --source visible > "$EVIDENCE/adversarial-$shape.txt"
  got=$(fm_backend_herdr_composer_state "fm-lab-doorbell:$pane")
  printf '%s: composer=%s; expected=unknown\n' "$shape" "$got"
  lab workspace close "$wid" >/dev/null
  [ "$got" = unknown ] || exit 1
done
