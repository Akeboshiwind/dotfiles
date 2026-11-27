---
name: review
description: The refine step of a diamond, after /diamond:discover — reads back what the user drew and wrote on their board, in subagents, checks the transcription with a second blind read, then collates it into threads and suggests what to look at next. A re-read reports only what is new or changed since the last one. Use when the user says "/diamond:review <board>", "review the board", "read my notes", or "I've marked up the board".
argument-hint: <board.excalidraw.md> [catalogue]
---

The user has moved the board's cards around and drawn over them, often on an iPad. This reads it back **faithfully**, then proposes where to look next. The mechanics — decoding, clusters, crops, snapshots — are in `board-read`.

- **All reading happens in subagents** that load `board-read`. The main context only ever handles their text: never open a crop here.
- **Never write to the vault**, and never edit the board.

## Where things go

- `BOARD` — the board, `<Name>.excalidraw.md`, and its cards in `<Name> cards/` beside it.
- `STATE` — `<state>/<Name>/`, the state dir being `$DIAMOND_STATE_DIR`, else `~/.local/state/diamond`. Always its absolute path. It holds board-read's snapshots, `/diamond:discover`'s `work/`, and:
  - `resume.md` — where the user got to;
  - `<snapshot>.md` — the report of the review that took that snapshot.
- `READ` — `STATE/review/`, emptied at the start of each review. **Copy the board there**, keeping its file name, so both readers and the snapshot see the same board while the user may still be drawing on it. The cards stay where they are: pass `--cards "<dir of BOARD>/<Name> cards"` to every `board.py` command.
- **The catalogue**, for the items' names: the argument — discover's `catalogue.json`, or for an older board whatever file or folder describes its items — else `STATE/work/catalogue.json`. Where neither exists, say so, and suggest only from the IDs on the board and from leads outside it.

```
B=${CLAUDE_SKILL_DIR}/../board-read/scripts/board.py
COV=${CLAUDE_SKILL_DIR}/scripts/coverage.py
```

## 0. First read or re-read

Read `STATE/resume.md` and the names of `STATE/*.json`. **A snapshot means a re-read**, against the latest one.
Tell the user which it is, the last snapshot's time, and "last time you got to …".

## 1. Transcribe: agent A

Spawn one agent, briefed with `READ`, the cards' folder, the mode, and the rules below; it loads `board-read` and follows its reading discipline. It writes `READ/clusters.json` (`clusters --out`), the crops in `READ/crops/` (`render --out`), and `READ/transcript.md`, and replies with only the clusters it read, the `AMBIGUOUS` flags, and how many `[?]` it wrote.

- **First read:** `text`, `clusters`, `render`; read every cluster.
- **Re-read:** `since` first. Transcribe **only the clusters with added strokes**, and `render --only` those. Quote typed text that is added or changed. Each `MOVED` card is one line. Leave out everything else.
  - **Each `REFILED` cluster is one line**, with both its IDs: the same note, now filed under something else. Never transcribe it again, nor report it as a new note.
- **One `## <cluster ID>` section per cluster**, the ID exactly as `clusters` prints it and first on the heading line, under `#` headings grouping them by theme and card. Under each:
  - the **user's own words**, spelling included, and `[?]` for each word it can't read, never a guess;
  - their **structure**: a nested list for what branches from what, sub-points, and what is circled, underlined or arrowed to another card;
  - the cluster's **`AMBIGUOUS` line, carried through**, with what it thinks the note is about and why.
- **Typed text** in a section of its own, verbatim.
- **No interpretation**: no opening gloss, no title the user didn't write.

## 2. Verify

Transcription from handwriting fails quietly: a fluent line that isn't on the page, and no `[?]` anywhere.

**First, mechanically**: `python3 -I $COV READ/clusters.json READ/transcript.md`, adding `--only <IDs>` on a re-read with the clusters that have added strokes.

- `MISSING` (a cluster with no section) and `LAUNDERED` (a flag dropped) **fail**: send agent A back to fix them.
- `SUSPECT` (100 strokes or more, and no `[?]`) only warns. It is noisy, so it never fails a read: give its IDs to agent B to read first.

**Then a blind second read: agent B**, a **fresh** agent that loads `board-read`. Give it the crops' folder, the transcript, and the IDs to check — never agent A's reply or reasoning. Cluster by cluster, it reads the crops itself first, then marks every line of the transcript, and the first and last line of each cluster before the rest, where invented lines show:

- `OK`;
- `DISAGREE: <what the page says>`;
- `NOT ON PAGE` — invented;
- `MISSED: <what the page says>` — on the page, not in the transcript.

It writes `READ/verdict.md` and replies with the counts.

**Apply the verdict to the transcript yourself**, as text:

- `DISAGREE` — **the words the readers disagree on become `[?]`**. Never pick the likelier reading.
- `NOT ON PAGE` — remove the line.
- `MISSED` — add it, with `[?]` for any word agent B wasn't sure of.

Where nothing handwritten is new on a re-read, skip both agents.

Then take the snapshot, **only after a verified read**, so a failed review never swallows the notes it didn't read:

```
python3 -I $B snapshot READ/<Name>.excalidraw.md --cards "<dir of BOARD>/<Name> cards"
```

## 3. Collate: agent C

A third agent, with no images: give it the corrected transcript, the catalogue, and on a re-read the last report, `STATE/<previous snapshot>.md`. **Everything it interprets is labelled as its own.**

1. **Threads, 3 to 6, as `T1`, `T2` …** — each a line saying what the user keeps coming back to, citing cluster and card IDs and quoting their words. Not every note belongs in a thread: list the leftovers.
2. **Suggestions, as `S<thread>.<n>`**, such as `S2.1`:
   - **2 to 4 catalogue items a thread, in all**, those testing its assumptions included, as `<ID> <name>`, **preferring items the user hasn't cited, and from sections other than the thread's**;
   - plus a few **leads outside the catalogue**: named things to search for, **each its own ID**, so the user can answer one.
3. **Each suggestion is labelled one of:**
   - `unsure` — where the user doubted or asked;
   - `excited` — where they lit up: emphasis, stars, "yes", long writing. Cover these as fully as the doubts;
   - `assumption` — what they seem to take for granted. **Name it first**, as `A1: you seem to assume …`, with the quote it comes from, then the items that would test it.
4. A line of why for each. **No ranking, and no decisions** for the user.

**IDs are stable across reviews**: never renumber or reuse one. On a re-read, the report is **only the delta**: which existing threads the new notes extend, new threads numbered on from the last report's, and new suggestions and assumptions numbered on likewise. Leave unchanged threads out.

Save the report as `STATE/<snapshot>.md`, named after the snapshot just taken.

## 4. Where the user got to

Ask "where did you get to?", unless they have said. Write their words to `STATE/resume.md`, replacing it:

```
updated: <ISO time>
got to: <the user's words>
```

**Never infer it**: where they don't say, leave `resume.md` as it was, and ask again at the end of the report.

## 5. Hand over

- the mode, and the snapshot it compared against;
- **what verification caught**: the coverage result, agent B's counts, and each correction, with an example;
- the threads, assumptions and suggestions, with their IDs;
- where the user got to.

End with: reply with IDs — `T2: …`, `S1.3: yes` — and, when ready to converge, `/diamond:define`.
