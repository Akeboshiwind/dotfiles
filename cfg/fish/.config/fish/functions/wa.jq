# Input: `claude agents --json --all`.
# $ARGS.positional: the cwds that still exist. $jobs: id → {detail, updatedAt} from ~/.claude/jobs.
# $running: the ids `claude agents --json` lists without --all; the rest are paused.
# $home: abbreviated to ~ in the repository headings.
# Output: one fzf row per repository and per agent, as "<cd target>\t<display>".

def age:
  if . < 60 then "\(floor)s"
  elif . < 3600 then "\(. / 60 | floor)m"
  elif . < 86400 then "\(. / 3600 | floor)h"
  elif . < 604800 then "\(. / 86400 | floor)d"
  else "\(. / 604800 | floor)w" end;

def pad($w): . + (" " * ($w - length));

def tilde: if startswith($home) then "~" + .[($home | length):] else . end;

def oneline: gsub("[\t\n]+"; " ");

def status_label:
  {blocked: "\u001b[33mNeeds input",
   done: "\u001b[32mDone",
   working: "\u001b[36mWorking",
   failed: "\u001b[31mFailed"}[.]
  // "\u001b[2m\(.)";

def marker: if IN($running[]) then "\u001b[33m✻\u001b[0m" else "\u001b[2m·\u001b[0m" end;

def updated:
  (.updatedAt | if . then sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 else null end)
  // ((.startedAt // 0) / 1000);

[.[]
 | select(.cwd | IN($ARGS.positional[]))
 | . + ($jobs[.id] // {})
 | .name |= oneline
 | .root = (.cwd | sub("/\\.claude/worktrees/[^/]+(/.*)?$"; ""))
 | .age = (now - updated | age)]
| (map(.name | length) | max) as $w
| group_by(.root)[]
| (.[0].root | "\(.)\t\u001b[1m\(tilde)\u001b[0m"),
  (.[] | "\(.cwd)\t\(.id | marker) \(.name | pad($w))  \(.age | pad(3))  \(.state | status_label)\u001b[0m · \(.detail // "" | oneline)")
