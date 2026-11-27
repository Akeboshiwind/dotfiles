---
name: discover
description: The diverge step of a diamond — wide prior-art research on a question, split into non-overlapping slices researched by parallel background agents, ending in one new Excalidraw board of image cards that the user rearranges and draws over, then reads back with /diamond:review. Use when the user says "/diamond:discover <question>", "survey prior art for …", or "research how others do …".
argument-hint: <the question, plus any examples you have seen>
---

**Wide, not deep.** The output is **one new board** the user moves around and draws on, often on an iPad, not a report.
This skill is the way of working; the mechanics are in `board-write`, `pick-images` and `fetch-images`.

## Where things go

- `VAULT` — the Obsidian vault's root: the working directory when it holds `.obsidian/`, else ask.
- `<Name>` — the board's name. The board is `VAULT/Excalidraw/<Name>.excalidraw.md`.
- `WORK` — the run's work folder, **outside the vault**: `<state>/<Name>/work/`, the state dir being `$DIAMOND_STATE_DIR`, else `~/.local/state/diamond`. Always use its absolute path.
  `/diamond:review` finds the catalogue there by the board's name.

```
WORK/slices.json   brief.md   items/<slice>.json   images/<id>.json   img/   raw/   themes.json   catalogue.json
```

Downloads stay in `WORK/raw/`; only the rendered cards enter the vault.

## 1. Frame and slice

From the question and any examples the user has seen, write down:

- **Our thing:** what we are designing, so that every item's `use` line answers "what could this mean for our thing?".
- **Slices:** separate, **non-overlapping** parts of the space, such as media apps, trackers and collections, physical places, games. Each has:
  - an id prefix of letters (`M`, `T`, `P` …), which numbers its items `M1`, `M2` … with **no zero padding**;
  - a title, and a one-line note;
  - a **seed list** of examples, and "go beyond" them.
- **The board's name.** Neither the board nor `WORK` may exist yet.

**Confirm the slices and the board's name with the user before spending anything.**
Show the slices, their seeds, and the budget: about 12–20 items a slice, at roughly $0.30–0.50 an item with images.
For a topic new to this skill, offer a sample run first: 2 slices of 3–4 items.
Go on without asking only where the user has said the slices are already approved.
Ids are stable from here on: the user will reply "P9: try that".

## 2. Brief and dispatch

Write `WORK/slices.json` — `[{"id": "M", "title": "…", "note": "…"}]`, in board order — and **one** shared `WORK/brief.md`.
The brief holds the context: our thing, what the user liked, and what to collect. It tells each agent to:

- **Favour breadth over depth.** Examples **unlike each other**, and unlike a plain list or grid; the strongest and most distinctive first.
- **Write `WORK/items/<slice id>.json` itself**, as `{"items": [{"id", "name", "kind", "link", "sig", "use"}], "top3": ["…"]}`.
  - `name` is what the item is called; `kind` what it is ("podcast app", "bookshop"); `link` its page.
  - `sig` is its signature idea in one line: how things are represented and organised, what is foregrounded, browsing or finding.
  - `use` is what it could mean for our thing.
  - Plain text, one line each. Ids are `<prefix><n>`, unique, never reused.
- **Load `pick-images` and `fetch-images`, and keep images for each item** that show its idea, with `OUT=<WORK>` and `RAW=<WORK>/raw`, both absolute. An item with no good image keeps none.
- **Reply with the slice's 3 ideas that matter most**, citing ids, and the ids without images. The JSON is the deliverable, so no prose catalogue.

**Before dispatching, tell the user what the agents will ask permission for**, and offer to allowlist it:

- running the image scripts: `Bash(bash <FETCH>/*)` and `Bash(python3 -I <FETCH>/*)`, where `<FETCH>` is `fetch-images`' `scripts` folder by its absolute path (`${CLAUDE_SKILL_DIR}/../fetch-images/scripts`, resolved) — or more broadly `Bash(bash:*)` and `Bash(python3:*)`;
- reading and writing the state dir: `Read(<state>/**)` and `Edit(<state>/**)`, such as `Edit(~/.local/state/diamond/**)`;
- `WebSearch` and `WebFetch`.

Then spawn **one agent per slice, in parallel and in the background**, leaving the model at its default.
Each gets a one-line prompt, never the brief pasted in:

```
Slice M (Media apps): read <WORK>/brief.md. Seeds: Castro, Pocket, … Number items M1, M2, … OUT=<WORK> RAW=<WORK>/raw
```

## 3. Progress

As each agent finishes, post its 3 highlights, with ids, and **its gaps, honestly**: items without images, and items it couldn't verify.

## 4. Merge and themes

Write `WORK/themes.json`: `[{"title": "…", "body": "…", "refs": ["M1", "P2"]}]`.
Themes are **cross-cutting patterns citing items from different slices**, drawn from the highlights and the items' `sig` lines; 6–10 is plenty, 2–3 for a sample run. Then:

```
python3 -I ${CLAUDE_SKILL_DIR}/scripts/merge.py WORK --title "<title>" [--subtitle "<subtitle>"]
```

It writes `WORK/catalogue.json` and prints the counts and the ids without images.
**When it reports problems, it has written nothing**: fix the agents' JSON, never by transcribing their prose, and run it again.
An image record matches an item by its **exact** id: `images/M01.json` belongs to no item `M1`. Rename the record, and its `id`, to the item's.

## 5. Build

**Over about 100 items, tell the user before building**, and offer fewer images an item, or a smaller board.
Load `board-write`, with `CATALOGUE=WORK/catalogue.json`, `ROOT=WORK`, `VAULT`, and `BOARD=VAULT/Excalidraw/<Name>.excalidraw.md`.
**Always a new board, one canvas**: never overwrite or delete one; a rebuild takes a new name.
When its memory line reads over about 500 MB, tell the user before handing it over.

## 6. Hand over

Tell the user:

- the board's path;
- the counts: items, with images, and without;
- the memory estimate;
- the gaps.

Invite them to open it, rearrange it, draw over it and mark what matters, then run `/diamond:review`.
**Never edit a board once it's built**: it holds the user's drawing.
