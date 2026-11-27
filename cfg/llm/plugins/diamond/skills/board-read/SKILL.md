---
name: board-read
description: Read back what the user hand-wrote on an Obsidian Excalidraw board that diamond's board-write built — its typed text, its handwriting grouped into clusters by the card or theme they sit beside, readable crops of each, and what changed since a time. Loaded by the agent that runs diamond:review.
user-invocable: false
---

Reads a board (`<Name>.excalidraw.md`) the user has written on, so you can **transcribe what they wrote**. **It never writes to the board**: work on a copy in a scratch folder when you can, and never edit the vault.

It needs `python3` and, for `render`, ImageMagick 7 (`magick`).

## Inputs

- `BOARD` — the board's `.excalidraw.md` file.
- Its cards, found in `<Name> cards/` beside the board; pass `--cards DIR` when they are elsewhere. An image whose file is in that folder is a **card**, named by its file: `m7.jpg` is **M7**. Any other image is one the user added.

## Commands

```
B=${CLAUDE_SKILL_DIR}/scripts/board.py
python3 -I $B inventory BOARD                     # elements by type, how many cards were found, the themes
python3 -I $B text BOARD                          # typed text, images, and arrows with what they join
python3 -I $B clusters BOARD [--gap 150] [--out clusters.json]
python3 -I $B render BOARD --out DIR [--gap 150] [--width 1600] [--tile 3200] [--only K5@10100,29680 ...]
python3 -I $B since BOARD "2026-11-20 19:03" [--gap 150]   # a local time, or epoch milliseconds
```

- **clusters** groups the handwriting: strokes join a cluster when their boxes lie within `--gap` canvas units of each other, and files each cluster where it belongs:
  - under the **card or theme holding at least 60%** of its strokes (a theme is a rectangle wider than 300 units, titled by its first line of text; an untitled one is `Untitled theme`, and a title used twice gets ` 2`);
  - otherwise under the **nearest** card or theme, a card winning a tie;
  - but where that is **far** — the cluster more than 1500 units from it, or its middle stroke more than 1500 or twice the target's longest side — under its **section**, the frame whose rows hold it.

  Every cluster names its section, and **every call it can't make confidently** is printed as `AMBIGUOUS <id>: <reasons>`, from `far`, `spread` (its middle stroke more than 1500 units from what it is filed under), `crowded` (another card or theme at most 150 units further away), `split` (only 60–75% of its strokes inside), `spans sections` (more than 15% of its strokes in a second section) and `untitled theme rectangle`. Clusters come **largest first**, each with an ID such as `K5@10100,29680`: what it is filed under (a theme's title with `_` for spaces and punctuation), and its box's top-left corner rounded to 10. **A cluster with the same strokes keeps its ID whatever the gap**, and from one run to the next; it gets a new one when its box changes, say when a stroke is added. Two clusters that would share an ID become `…` and `….2`. The JSON adds each cluster's stroke ids, box, distance to what it is filed under, the next two nearest, its `section`, its `ambiguous` reasons, and when its strokes were first and last drawn.
- **render** draws, at most `--width` pixels wide:
  - `cluster_<id>.png` — the cluster's strokes over what it is filed under, a card **faded** so the ink reads over it; a cluster filed under a section, or flagged `far`, is drawn without it;
  - a cluster more than `--tile` canvas units wide or tall is cut into `cluster_<id>_tile<k>of<n>.png` instead: tiles of about equal size, numbered **row by row** from the top left, leaving out any that hold no strokes, each overlapping its neighbours by about 150 units, so it stays legible however large it is. With them comes `cluster_<id>_map.png`, a small picture of the whole cluster with each tile outlined and numbered — only for finding your way;
  - `theme_<title>.png` — each theme with the clusters filed under it;
  - `overview.png` — the whole board, only for finding your way: it is too small to read.

  **Read the cluster crops**, and a tiled cluster's tiles **in order**, tile 1 first, carrying a line that runs off one tile's edge on to the next. `--only` re-renders a few clusters.
- **since** lists the elements whose `updated` time is after the time given: the cards, text and arrows, then the clusters holding new strokes and how many of their strokes are new. Deleted elements are left out. A card's time moves when it is dragged or restyled, so a changed card isn't a note.

## Reading discipline

1. **Transcribe faithfully**, in the user's words, spelling included. Write `[?]` for a word you cannot read, and never guess one to make a sentence read better. A transcript that says `[?]` is worth more than one that is fluent and wrong.
2. **Keep the structure.** Handwriting here is often a small mindmap: keep what branches from what (an arrow runs from the parent to its head), what is circled or underlined, and indented lines (`↳` or `L>` marks a sub-point). Write it as a nested list, never as flattened prose.
3. **Keep typed text apart from handwriting**, verbatim.
4. **The filing can be wrong. Never drop an `AMBIGUOUS` flag**: report each one with its cluster's transcription, and say what you think the note is about and why. A cluster filed under a section is about that section's theme, or several of its cards: read it to decide which. Where an unflagged note is plainly about something else — a nearer heading, an arrow leading to another card — say so too. A note can be about two cards.
5. **Interpretation comes after the transcription**, labelled as yours.

## When a crop is hard to read

- **Arrows and braces are strokes** on a board drawn by hand, as on Prior art: `text` lists no arrows, so read what branches from what in the crops.
- A cluster too large for one crop is already tiled: **read its tiles**, and **don't shrink `--gap` to split it**, which cuts one mindmap into pieces filed apart. Lower `--tile` for tiles that are larger still.
- A cluster can spread across a whole section when notes run into each other. Run `clusters` again with a smaller gap, say `--gap 80`, then `render --gap 80 --only` the clusters you need. A cluster the smaller gap splits has new IDs; one it leaves whole keeps its own.
- Labels need a font file. On macOS it uses Hiragino Sans GB; elsewhere, set `BOARD_FONT_BODY` to a `.ttf` or `.ttc` file, as for board-write.
