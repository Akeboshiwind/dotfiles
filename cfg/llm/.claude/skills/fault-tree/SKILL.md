---
name: fault-tree
description: Root-cause analysis as a tree of named hypotheses — one observed symptom at the root, decomposed one step at a time into the causes that could directly produce it, each node marked open, confirmed or refuted against evidence. Use when the user says "RCA", "root cause", "fault tree", "why did X happen", "/fault-tree", or is investigating an incident or divergence whose cause isn't known; and whenever a debugging session has more than one live hypothesis.
---

# Fault-tree RCA

Interpret MUST, MUST NOT, SHOULD, SHOULD NOT, MAY per RFC 2119.

## An example

```
T open — XT returns row `a` from `events`; Postgres has no row `a`
  Seen: n2
  Not seen: n1, n3
- OR:
  - H1 open — n2 is serving stale data
    - OR:
      - H1.1 open — n2 stopped applying the replica log
      - H1.2 open — n2's query read an earlier basis
  - H2 refuted — Postgres never emitted the DELETE
  - H3 refuted — XT never received the DELETE
  - H4 open — n2 received the DELETE but didn't apply it
    - AND:
      - H4.1 confirmed — a block flush was in flight on n2
      - H4.2 open — n2 closed before the DELETE was applied
```

An investigation is a tree.

- **The root, `T`, is the symptom**: something someone observed.
  Beneath it, `Seen:` and `Not seen:` record where the symptom shows and where it doesn't.
- **Every other node is a hypothesis** about why its parent happened.
- **Each parent's children hang under a gate**:
  - **`OR:`** — any one child alone would produce the parent;
  - **`AND:`** — the children produce it only together.
- **Each node has a stable ID, a status, and a one-line subject.** Evidence for it is kept beside the tree (see *The file*).

The ID is how we talk about the investigation: "H2 is refuted, H1.1 is next" is a complete message.

## The root

**`T` MUST be a single, observed, specific event — the symptom, never a guess at its cause.**

- **Observed**: "XT returns row `a`; Postgres has no row `a`".
  "XT dropped the DELETE" is already a hypothesis, and belongs one level down.
- **Specific**: name the system, the object, the instance and the time, as far as they're known.

**`Seen:` and `Not seen:` are the first evidence to gather.**
They compare places you'd expect to behave the same: other nodes, tables, times, environments, versions.

- **They're the cheapest pruning there is**: a hypothesis that would also produce the symptom where it's `Not seen` is refuted on the spot.
  In the example, H2 and H3 would leave `a` on every node, so `Not seen: n1, n3` refutes both without running a test.
- **An empty `Not seen:` is evidence too**: a symptom seen everywhere refutes hypotheses that are specific to one place.
- **Each entry SHOULD be short** — where it was observed. How it was observed goes in `T`'s evidence.

## Children

**Each child MUST be an immediate cause of its parent.**
Ask "what could *directly* make this node true?", never "what's the root cause?".
A child that skips a step hides the alternatives that lived in that step.

- **After listing a node's children, ask "what else could immediately cause this?"** until the answer is nothing.
  Where the list may still be incomplete, add a child `other — not yet enumerated` with status `open`.
- **Children SHOULD be mutually exclusive.** Two that overlap make evidence ambiguous — split them on the difference.
- **MUST NOT add a node that can't physically happen in this system.**
- **Check every new node against `Seen:` and `Not seen:`** as soon as it's written.
- **A node needs no children when one test, log query, code read or question can settle it.**

## IDs

- The root is `T`; its children `H1`, `H2`, …; theirs `H1.1`, `H1.2`, …; and so on.
- **A new sibling takes the next unused number. IDs MUST NOT be renumbered or reused**, even after a node is refuted or removed.
- **A citation MUST carry the node's subject as well as its ID** — "H2 (Postgres never emitted the DELETE) is refuted" — so a reader without the tree can follow it.

## Status

| Status | Meaning |
|---|---|
| `open` | not settled yet |
| `likely` | evidence points to it, but doesn't settle it |
| `confirmed` | shown to have happened in this incident |
| `possible` | shown to be able to happen, not shown to have happened here |
| `unreproduced` | tried to make it happen, and couldn't — not shown not to have happened here |
| `refuted` | shown not to have happened here |
| `out of scope` | can't produce this symptom, given `Seen:` and `Not seen:` |
| `conflict` | the node's own evidence disagrees with its children |

**Any node can carry evidence, and every status other than `open` MUST cite some.**

- **A node with no children takes its status from its own evidence.**
- **A node with children takes its status from its own evidence where that settles it**, otherwise from its children:
  - an `OR:` is `refuted` once every child is `refuted` or `out of scope`, and `confirmed` once any child is;
  - an `AND:` is `refuted` once any child is, and `confirmed` once every child is.
- **A node keeps its evidence when it gains children.** Evidence about the node as a whole stays on it.
- **When its own evidence and its children disagree, the node is `conflict`**: the tree is wrong somewhere, and that's the next thing to resolve.
- **`possible` is not `confirmed`.** A bug reproduced in a lab stays `possible` until evidence ties it to this incident.
- **`unreproduced` is not `refuted`.** Failing to make it happen in a lab says nothing about whether it happened here.

## The loop

1. **Write `T`**, with its `Seen:` and `Not seen:`.
2. **Add one level of children**, and run the "what else?" check.
3. **Mark what the evidence in hand already settles.**
4. **Pick the next probes** from the open nodes: the cheapest among the likeliest first.
   A question to whoever reported the problem is often the cheapest probe of all.
5. **Run them, record the evidence, update statuses**, and add children to any node that turned out to need them.
6. **Repeat until a path from `T` down to a node with no children is `confirmed`** — that node is the root cause.
   If every branch ends up `refuted`, `T` or the tree is wrong: revisit both.

## The file

**The tree and its evidence MUST live in one file**, `rca/<slug>.md` in the working directory unless the user names another place, so the investigation survives compaction and handover.

````markdown
# XT keeps a row Postgres deleted

```
T open — XT returns row `a` from `events`; Postgres has no row `a`
  Seen: n2
  Not seen: n1, n3
- OR:
  - H1 open — n2 is serving stale data
  - H2 refuted — Postgres never emitted the DELETE
  …
```

## Evidence

### T
- Queried `SELECT * FROM events WHERE _id = 'a'` on each node, 2026-10-02 09:30–09:31: present on n2, absent on n1 and n3.

### H2
- Refuted by `Not seen: n1, n3`: those nodes don't have `a`, so the DELETE reached them.

### H4.1
<details><summary>n2 log, 09:14 — block flush in flight</summary>

```
09:14:02.118 INFO … [cdc] flushing block 12
…
```
</details>
````

- **Evidence MUST be a pointer you can check**: a test and its result, a commit, a log line, a query and its output, a file:line.
- **Long evidence goes in a `<details>` block**, with a summary saying what it shows.
- **In chat, show only what changed**: the updated nodes and the open frontier, not the whole tree again.

## Gotchas
