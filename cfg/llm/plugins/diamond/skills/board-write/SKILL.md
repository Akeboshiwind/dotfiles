---
name: board-write
description: Turn a diamond catalogue JSON into a new Obsidian Excalidraw board (.excalidraw.md) — a title, theme cards, and a frame per section holding one rendered card per item. Called by diamond:discover.
user-invocable: false
---

Builds a **new** board from a catalogue. **It never touches an existing board**: a board holds the user's drawings, and a rebuild would wipe them.

The catalogue's format is in `${CLAUDE_SKILL_DIR}/references/catalogue.md`; read it when you have to write or fix one.

## Inputs

- `CATALOGUE` — the catalogue JSON.
- `VAULT` — the Obsidian vault's root.
- `BOARD` — a path that doesn't exist yet, inside the vault, normally `VAULT/Excalidraw/<Name>.excalidraw.md`. For a rebuild, pick a new name such as `<Name> 2`; never delete or move a board to make room.
- `ROOT` — the folder the images' `file` paths are relative to: the `OUT` folder the catalogue was gathered in. It defaults to the catalogue's own folder.

It needs `python3` and ImageMagick 7 (`magick`).

## Build

```
python3 -I ${CLAUDE_SKILL_DIR}/scripts/build_board.py CATALOGUE --board BOARD --vault VAULT --root ROOT
```

It takes about 30 seconds for 100 cards. It renders a JPEG card per item into `<Name> cards/` beside the board, writes the board, checks it, and only then moves both into the vault. **When it exits non-zero, it has written nothing**: fix what it reports and run it again. It refuses:

- a `BOARD` or `<Name> cards/` folder that already exists;
- a catalogue with missing fields, ids that clash once lowercased, or an image file that isn't there;
- a board that fails its check.

Report to the caller the board's path and the lines it printed.

To check a board again later: `python3 -I ${CLAUDE_SKILL_DIR}/scripts/check_board.py BOARD VAULT`. It fails on overlapping frames, a frame member outside its frame, a missing card file, or a text element missing from `## Text Elements`.

## Memory

The `MB decoded in memory` line is what an iPad holds when the board opens. About 400 MB (113 cards) works; above about 500 MB, tell the caller, and suggest fewer images per item or splitting the catalogue, rather than handing the board over.

## Layout

One canvas: the title and subtitle, then the themes as cards in a grid six wide, then a named **frame per section** holding its heading and one card image per item. Each card is a group of its own, so dragging moves the whole card, including between frames. Cards are drawn at 1.5 times their pixel size, big enough to draw on. A card's link is its item's `link`.

## Fonts

On macOS, titles use Georgia, and body text Hiragino Sans GB, which has the arrows and kana Georgia lacks. Elsewhere, set `BOARD_FONT_TITLE`, `BOARD_FONT_SIG` and `BOARD_FONT_BODY` to font files; DejaVu is tried before falling back to Helvetica.
