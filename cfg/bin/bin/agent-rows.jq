# Input: `claude agents --json --all`.
# $ARGS.positional: the cwds that still exist. $jobs: id → {detail, updatedAt, worktreePath} from ~/.claude/jobs.
# $running: the ids `claude agents --json` lists without --all; the rest are paused.
# $home: abbreviated to ~ in the repository headings.
# $cols: the terminal width; summaries are cut so the age lands at the right edge.
# Output: one fzf row per repository and per agent, as "<cd target>\t<display>".

def age:
  if . < 60 then "\(floor)s"
  elif . < 3600 then "\(. / 60 | floor)m"
  elif . < 86400 then "\(. / 3600 | floor)h"
  elif . < 604800 then "\(. / 86400 | floor)d"
  else "\(. / 604800 | floor)w" end;

def pad($w): . + (" " * ($w - length));

def lpad($w): (" " * ($w - length)) + .;

def fit($w): if length > $w then .[:([$w - 1, 0] | max)] + "…" else pad($w) end;

def tilde: if startswith($home) then "~" + .[($home | length):] else . end;

def oneline: gsub("[\t\n]+"; " ");

def status:
  {blocked: ["33", "Needs input"],
   done: ["32", "Done"],
   working: ["36", "Working"],
   failed: ["31", "Failed"]}[.]
  // ["2", .];

def marker: if IN($running[]) then "\u001b[33m✻\u001b[0m" else "\u001b[2m·\u001b[0m" end;

def updated:
  (.updatedAt | if . then sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 else null end)
  // ((.startedAt // 0) / 1000);

def heading($target; $title): "\($target)\t\u001b[1m\($title)\u001b[0m";

def row($w):
  (.state | status) as [$colour, $label]
  # fzf's pointer and scrollbar take 3 columns; the rest is "✻ name  label · summary  age"
  | ($cols - 3 - (2 + $w + 2) - ($label | length) - 3 - (2 + 3)) as $room
  | "\(.cwd)\t\(.id | marker) \(.name | pad($w))  \u001b[\($colour)m\($label)\u001b[0m · \(.detail // "" | oneline | fit($room))  \u001b[2m\(.age | lpad(3))\u001b[0m";

[.[]
 | . + ($jobs[.id] // {})
 # `claude agents` gives a paused agent the directory it started in, not its worktree
 | .cwd = (.worktreePath // .cwd)
 | select(.cwd | IN($ARGS.positional[]))
 | .name |= oneline
 | .root = (.cwd | sub("/\\.claude/worktrees/[^/]+(/.*)?$"; ""))
 | .age = (now - updated | age)]
| (map(.name | length) | max) as $w
| group_by(.root)[]
| (.[0].root | heading(.; tilde)), (.[] | row($w))
