#!/usr/bin/env bash
set -eu
ROOT=$PWD
EVIDENCE=~/.no-mistakes/evidence/01M7D2BA3TY0PSJM18X2XHFC4B
LAB=$(mktemp -d "$ROOT/data/nm-verbose-test/fm-lab.XXXXXX")
trap 'rm -rf "$LAB"' EXIT
"$ROOT/bin/fm-lab-home.sh" create "$LAB" >/dev/null
mkdir -p "$LAB/.claude"
printf '{"verbose":true}\n' > "$LAB/.claude/settings.local.json"
printf 'Reply exactly OK without using tools.\n' > "$LAB/prompt"
printf 'Reply exactly OK.\n' > "$LAB/message"
unset FM_SUPERVISION_ENGINE_CLAUDE_BIN FM_ROOT_OVERRIDE FM_STATE_OVERRIDE FM_CONFIG_OVERRIDE FM_DATA_OVERRIDE FM_PROJECTS_OVERRIDE FM_SUPERVISION_ACTOR FM_BRANCH_REPORT_TURN FM_LEASE_HOLDER_PID
. "$ROOT/bin/fm-wake-lib.sh"
. "$ROOT/bin/fm-timeout-lib.sh"
FM_ROOT=$LAB FM_HOME=$LAB STATE=$LAB/state
export FM_ROOT FM_HOME STATE
run_turn() {
  local label=$1 lib=$2 session=$3 mode=$4 prior=$5
  (
    . "$lib"
    fm_supervision_engine_turn claude sonnet "$LAB/prompt" "$LAB/message" "$session" "$mode" 180 "$LAB/$label.json" "$LAB/$label.err"
    printf '%s parser: ' "$label"
    fm_supervision_engine_result claude "$LAB/$label.json" "$prior"
  )
  node - "$label" "$LAB/$label.json" <<'JS'
const fs = require('node:fs');
const [label, path] = process.argv.slice(2);
const raw = JSON.parse(fs.readFileSync(path, 'utf8'));
const result = Array.isArray(raw) ? raw.findLast(x => x.type === 'result') : raw;
const summary = {label, shape: Array.isArray(raw) ? 'array' : 'object', type: result.type,
 subtype: result.subtype, is_error: result.is_error, result: result.result,
 cost: result.total_cost_usd, turns: result.num_turns, usage: result.usage};
console.log(JSON.stringify(summary));
if (result.subtype !== 'success' || result.is_error !== false || result.result.trim() !== 'OK') process.exit(1);
if (label === 'base-verbose' ? !Array.isArray(raw) : Array.isArray(raw)) process.exit(1);
JS
}
uuid() { node -e 'console.log(require("node:crypto").randomUUID())'; }
printf 'Real installed CLI: %s\n' "$(claude --version)"
run_turn base-verbose "$ROOT/data/nm-verbose-test/base-engine.sh" "$(uuid)" new 0
session=$(uuid)
run_turn fixed-verbose-new "$ROOT/bin/fm-supervision-engine-lib.sh" "$session" new 0
prior=$(node -p 'require(process.argv[1]).total_cost_usd' "$LAB/fixed-verbose-new.json")
run_turn fixed-verbose-resume "$ROOT/bin/fm-supervision-engine-lib.sh" "$session" resume "$prior"
printf '{"verbose":false}\n' > "$LAB/.claude/settings.local.json"
run_turn fixed-nonverbose "$ROOT/bin/fm-supervision-engine-lib.sh" "$(uuid)" new 0
printf 'Project setting after fixed calls: %s\n' "$(cat "$LAB/.claude/settings.local.json")"
printf 'Cleanup: disposable lab removed by EXIT trap.\n'
