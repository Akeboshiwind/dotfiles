#!/usr/bin/python3
"""Claude Code status line: location, git, model, context window, rate limits, cost.

The interpreter is pinned rather than found via env, so installing a managed python can't
silently move this onto a different one.
"""

import json
import math
import os
import subprocess
import sys
import time
from typing import List, NamedTuple, Optional

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
BLUE = "\033[0;34m"
MAGENTA = "\033[0;35m"
CYAN = "\033[0;36m"
DIM = "\033[2m"
RESET = "\033[0m"

BG_DARK = "\033[48;5;236m"
# A rate limit bar carries a second reading in its background: cells behind the clock are
# lighter, so the boundary between the two shades is where an evenly-spent window would have
# reached by now. Fill running past it is overspend, shown positionally.
BG_ELAPSED = "\033[48;5;238m"
FG_GREEN = "\033[32m"
FG_YELLOW = "\033[33m"
FG_RED = "\033[31m"

BAR_CHARS = "▁▂▃▄▅▆▇█"

# Groups are space-separated inside and divided by this. Whitespace alone won't do the job:
# two of the groups have spaces between their own segments, so a wider gap would be
# competing with the gaps it needs to be distinguishable from.
SEPARATOR = f" {DIM}│{RESET} "

PACE_UNKNOWN_BELOW = 15
CONTEXT_CELLS = 10

# Spend as a percentage of elapsed time. 100 is dead on schedule, and it has to sit inside
# the green band with room to spare: both figures are integers, so perfectly even usage lands
# on either side of 100 by rounding alone. A ratio exhausts the window at 100/ratio of the way
# through it, so 115 runs dry with a fourteenth of the window left and 150 with a third of it.
PACE_AHEAD = 115
PACE_WELL_AHEAD = 150


class Window(NamedTuple):
    """A rate limit window, one cell per natural unit of it - an hour, a day.

    Tying the cell count to the unit is what makes a partly-filled cell readable: on the
    weekly bar a half-full fourth cell is the middle of the fourth day, not 50% of some
    arbitrary fraction. `seconds` is hardcoded because the payload reports when a window
    resets and never how long it runs.
    """

    label: str
    key: str
    seconds: int
    cells: int
    unit: str


FIVE_HOUR = Window("5h", "five_hour", 18000, 5, "h")
SEVEN_DAY = Window("7d", "seven_day", 604800, 7, "d")


def render_bar(percent: int, width: int) -> str:
    """Bar geometry, no colour. Each cell carries 8 graduations."""
    filled = percent * width * 8 // 100
    cells = []
    for i in range(width):
        cell_fill = filled - i * 8
        if cell_fill >= 8:
            cells.append(BAR_CHARS[7])
        elif cell_fill <= 0:
            cells.append(" ")
        else:
            cells.append(BAR_CHARS[cell_fill - 1])
    return "".join(cells)


def paint(color: str, bar: str) -> str:
    return f"{BG_DARK}{color}{bar}{RESET}"


def paint_paced(color: str, bar: str, elapsed: Optional[int]) -> str:
    """As paint, but with the background split at wherever the clock has reached.

    An elapsed of None leaves the whole bar on the base shade: with no resets_at there is no
    clock to mark, and a boundary drawn at zero would read as a window that just opened.
    """
    if elapsed is None:
        return paint(color, bar)
    lit = elapsed * len(bar) // 100
    cells = (f"{BG_ELAPSED if i < lit else BG_DARK}{color}{g}" for i, g in enumerate(bar))
    return "".join(cells) + RESET


def level_color(percent: int, yellow_at: int, red_at: int) -> str:
    if percent < yellow_at:
        return FG_GREEN
    if percent < red_at:
        return FG_YELLOW
    return FG_RED


def sparkline(percent: int, width: int, yellow_at: int, red_at: int) -> str:
    """Coloured by level - how full the bar is."""
    return paint(level_color(percent, yellow_at, red_at), render_bar(percent, width))


def pace_color(percent: int, elapsed: Optional[int]) -> str:
    """Spend against elapsed time rather than against the ceiling.

    A rate limit window is meant to reach 100% just as it resets, so a full-but-on-schedule
    bar is success and level colouring would cry wolf at exactly the wrong moment. Below
    PACE_UNKNOWN_BELOW the ratio is dominated by noise, and elapsed is None when there is no
    resets_at to work from - both fall back to level.
    """
    if elapsed is None or elapsed < PACE_UNKNOWN_BELOW:
        return level_color(percent, 50, 75)
    ratio = percent * 100 // elapsed
    return level_color(ratio, PACE_AHEAD, PACE_WELL_AHEAD)


def window_elapsed_percent(resets_at: Optional[int], window: int) -> Optional[int]:
    """How much of a fixed-length window has gone. None when it can't be worked out."""
    if resets_at is None:
        return None
    remaining = resets_at - int(time.time())
    if remaining > window:
        return None
    remaining = max(remaining, 0)
    return (window - remaining) * 100 // window


def pace_gap(percent: int, elapsed: Optional[int], window: Window) -> str:
    """How far spend has run ahead of the clock, in the window's own units.

    A debt already run up rather than a forecast: +1.0h means running out an hour early even
    on slowing to the sustainable rate this instant, where a projection from the current rate
    would say sooner. Unlike the pace ratio there's no small denominator to guard against, so
    this stays meaningful from the first minute of a window. Without a resets_at there is no
    clock to be ahead of, and it falls back to reporting the level the bar is already showing.
    """
    if elapsed is None:
        return f"{percent}%"
    gap = (percent - elapsed) / 100 * window.cells
    if abs(gap) < 0.05:
        gap = 0.0
    return f"{gap:+.1f}{window.unit}"


def meter(label: str, bar: str, reading: str) -> str:
    """A labelled bar and its reading, spaced so the label doesn't crowd the bar."""
    return f"{DIM}{label}{RESET} {bar} {DIM}{reading}{RESET}"


def limit_segment(window: Window, limits: dict) -> Optional[str]:
    """One rate limit window as a meter, or None when the window is absent."""
    data = limits.get(window.key)
    if not data:
        return None
    percent = data.get("used_percentage")
    if percent is None:
        return None
    percent = math.floor(percent)

    resets_at = data.get("resets_at")
    elapsed = window_elapsed_percent(
        math.floor(resets_at) if resets_at is not None else None, window.seconds
    )
    bar = paint_paced(pace_color(percent, elapsed), render_bar(percent, window.cells), elapsed)
    return meter(window.label, bar, pace_gap(percent, elapsed, window))


def git_run(cwd: str, *args: str) -> Optional[str]:
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", *args],
            capture_output=True,
            text=True,
        )
    except OSError:
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip()


def git_segment(cwd: str) -> Optional[str]:
    if git_run(cwd, "rev-parse", "--git-dir") is None:
        return None
    branch = git_run(cwd, "rev-parse", "--abbrev-ref", "HEAD") or ""

    dirty = subprocess.run(
        ["git", "-C", cwd, "--no-optional-locks", "diff", "--quiet"],
        capture_output=True,
    ).returncode
    status = f"{GREEN}✓" if dirty == 0 else f"{YELLOW}●"

    if git_run(cwd, "ls-files", "--others", "--exclude-standard"):
        status += f"{CYAN}+"

    counts = git_run(cwd, "rev-list", "--left-right", "--count", "HEAD...@{upstream}")
    if counts:
        ahead, behind = counts.split("\t")[:2]
        if int(ahead) > 0:
            status += f"{GREEN}↑{ahead}"
        if int(behind) > 0:
            status += f"{RED}↓{behind}"

    return f"{MAGENTA}{branch}{RESET}[{status}{RESET}]"


def join_groups(groups: List[List[Optional[str]]]) -> str:
    """Space-separated within a group, SEPARATOR between them.

    Absent segments and groups left empty by them drop out, so a missing git repo or an
    API-key account can't strand a separator with nothing on one side of it.
    """
    rendered = [" ".join(s for s in group if s) for group in groups]
    return SEPARATOR.join(r for r in rendered if r)


def main() -> None:
    data = json.load(sys.stdin)

    workspace = data.get("workspace") or {}
    current_dir = workspace.get("current_dir") or ""
    project_dir = workspace.get("project_dir") or ""
    location = os.path.basename(current_dir)
    if current_dir != project_dir:
        location = f"{os.path.basename(project_dir)}→{location}"

    context = data.get("context_window") or {}
    context_percent = math.floor(context.get("used_percentage") or 0)
    context_k = (context.get("total_input_tokens") or 0) // 1000

    cost = data.get("cost") or {}
    limits = data.get("rate_limits") or {}

    model = (data.get("model") or {}).get("display_name")

    sys.stdout.write(
        join_groups(
            [
                [f"{CYAN}{location}{RESET}" if location else None, git_segment(current_dir)],
                [f"{BLUE}{model}{RESET}" if model else None],
                [f"{YELLOW}${cost.get('total_cost_usd') or 0:.2f}{RESET}"],
                [meter("ctx", sparkline(context_percent, CONTEXT_CELLS, 50, 70), f"{context_k}k")],
                [limit_segment(FIVE_HOUR, limits)],
                [limit_segment(SEVEN_DAY, limits)],
            ]
        )
    )


if __name__ == "__main__":
    main()
