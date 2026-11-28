#!/usr/bin/env python3
"""Build a NEW Excalidraw board for Obsidian from a catalogue JSON.

usage: build_board.py CATALOGUE --board VAULT/Excalidraw/<Name>.excalidraw.md --vault VAULT [--root DIR]

Card JPEGs go in '<Name> cards/' beside the board. Image 'file' paths resolve against --root (default: the
catalogue's folder). The board and its cards are built and checked in a hidden folder at the vault root, and
moved into place only once the check passes. An existing board or cards folder is never touched.
"""
import argparse, collections, hashlib, json, os, random, shutil, subprocess, sys, tempfile, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_board
import render_cards
from render_cards import PAPER, EDGE, INK, MUTED

SUFFIX = ".excalidraw.md"
SCALE = 1.5          # card pixels to canvas units: room to draw on each picture
GAP, ROW_MAX, SECTION_GAP, FRAME_PAD = 120, 9000, 400, 160
THEME_COLS = 6


class Target:
    """Where a board and its cards folder go, relative to a vault, so they can be built in a stand-in vault."""

    def __init__(self, vault, board):
        self.vault = os.path.abspath(vault)
        board = os.path.abspath(board)
        if not board.endswith(SUFFIX):
            sys.exit(f"--board must end {SUFFIX}")
        rel = os.path.relpath(board, self.vault)
        if rel == os.pardir or rel.startswith(os.pardir + os.sep):
            sys.exit("--board must be inside --vault: its embedded card paths are vault-relative")
        self.board_rel = rel
        self.cards_rel = rel[:-len(SUFFIX)] + " cards"

    def board(self, vault=None):
        return os.path.join(vault or self.vault, self.board_rel)

    def cards(self, vault=None):
        return os.path.join(vault or self.vault, self.cards_rel)


def catalogue_errors(cat, root):
    errors = []
    if not isinstance(cat.get("title"), str) or not isinstance(cat.get("sections"), list):
        return ["catalogue needs a 'title' and a 'sections' list"]
    owners = collections.defaultdict(list)
    for s in cat["sections"]:
        if "title" not in s or not isinstance(s.get("items"), list):
            errors.append(f"section {s.get('id') or s.get('title')!r} needs a 'title' and an 'items' list")
            continue
        for item in s["items"]:
            if not isinstance(item.get("id"), str) or "name" not in item:
                errors.append(f"item {item.get('id')!r} needs an 'id' and a 'name'")
                continue
            owners[render_cards.card_name(item["id"])].append(item["id"])
            for image in item.get("images", []):
                if not isinstance(image.get("file"), str):
                    errors.append(f"item {item['id']}: an image needs a 'file'")
                elif not os.path.isfile(os.path.join(root, image["file"])):
                    errors.append(f"item {item['id']}: missing image {image['file']}")
    for name, ids in owners.items():
        if len(ids) > 1:
            errors.append(f"items {ids} would share the card file {name}")
    known = {i for ids in owners.values() for i in ids}
    for t in cat.get("themes", []):
        if not isinstance(t.get("title"), str):
            errors.append("every theme needs a 'title'")
            continue
        unknown = [r for r in t.get("refs", []) if r not in known]
        if unknown:
            print(f"warning: theme {t['title']!r} refers to unknown ids {unknown}", file=sys.stderr)
    return errors


def wrap(s, n):
    out, line = [], ""
    for w in s.split():
        if line and len(line) + 1 + len(w) > n:
            out.append(line)
            line = w
        else:
            line = (line + " " + w).strip()
    return "\n".join(out + [line])


class Canvas:
    def __init__(self):
        self.rng, self.now = random.Random(2026), int(time.time() * 1000)
        self.elements, self.texts = [], []

    def uid(self):
        return "%016x" % self.rng.getrandbits(64)

    def add(self, kind, x, y, w, h, **extra):
        e = {"id": self.uid(), "type": kind, "x": x, "y": y, "width": w, "height": h, "angle": 0, "strokeColor": INK,
             "backgroundColor": "transparent", "fillStyle": "solid", "strokeWidth": 1, "strokeStyle": "solid",
             "roughness": 0, "opacity": 100, "groupIds": [], "frameId": None, "roundness": None,
             "seed": self.rng.getrandbits(31), "version": 1, "versionNonce": self.rng.getrandbits(31),
             "isDeleted": False, "boundElements": None, "updated": self.now, "link": None, "locked": False}
        e.update(extra)
        self.elements.append(e)
        return e

    def text(self, x, y, s, size, width, color=INK, family=2, **extra):
        e = self.add("text", x, y, width, round(size * 1.25 * (s.count("\n") + 1)), text=s, originalText=s,
                     fontSize=size, fontFamily=family, textAlign="left", verticalAlign="top", containerId=None,
                     lineHeight=1.25, autoResize=False, strokeColor=color, **extra)
        self.texts.append(e)
        return e


def layout(cat, cards_dir, vault):
    """Lay the board out; returns the canvas, its embedded files (id to vault path) and the card pixel count."""
    c, files, pixels = Canvas(), {}, 0
    n_items = sum(len(s["items"]) for s in cat["sections"])
    c.text(0, 0, cat["title"], 160, 6000, family=1)
    sub = cat.get("subtitle") or (f"{n_items} items in {len(cat['sections'])} sections. "
                                  "Each card is one picture: drag it, draw on it, move it between sections.")
    c.text(0, 230, sub, 44, 7000, color=MUTED)
    y = 420
    themes = cat.get("themes", [])
    for i, t in enumerate(themes):
        tx, ty = (i % THEME_COLS) * 1500, y + (i // THEME_COLS) * 640
        g = c.uid()
        c.add("rectangle", tx, ty, 1420, 580, backgroundColor=PAPER, strokeColor=EDGE, roundness={"type": 3},
              groupIds=[g])
        c.text(tx + 50, ty + 44, wrap(t["title"], 34), 56, 1320, family=1, groupIds=[g])
        c.text(tx + 50, ty + 200, wrap(t.get("body", ""), 62), 34, 1320, groupIds=[g])
        c.text(tx + 50, ty + 460, wrap(", ".join(t.get("refs", [])), 80), 28, 1320, color=MUTED, groupIds=[g])
    if themes:
        y += -(-len(themes) // THEME_COLS) * 640 + SECTION_GAP
    for sec in cat["sections"]:
        cards = []
        for item in sec["items"]:
            path = os.path.join(cards_dir, render_cards.card_name(item["id"]))
            w, h = render_cards.image_size(path)
            pixels += w * h
            cards.append((item, path, w * SCALE, h * SCALE))
        rows, row, row_w = [], [], 0
        for card in cards:
            if row and row_w + GAP + card[2] > ROW_MAX:
                rows.append(row)
                row, row_w = [], 0
            row_w += (GAP if row else 0) + card[2]
            row.append(card)
        rows.append(row)
        heading = sec["title"] + (" — " + sec["note"] if sec.get("note") else "")
        width = max(2000, max(sum(k[2] for k in r) + GAP * (len(r) - 1) for r in rows)) + 2 * FRAME_PAD
        height = sum(max((k[3] for k in r), default=0) for r in rows) + GAP * (len(rows) - 1) + 2 * FRAME_PAD + 220
        frame = c.add("frame", 0, y, width, height, name=sec["title"])
        c.text(FRAME_PAD, y + FRAME_PAD - 40, heading, 96, width - 2 * FRAME_PAD, family=1, frameId=frame["id"])
        cy = y + FRAME_PAD + 200
        for r in rows:
            cx = FRAME_PAD
            for item, path, w, h in r:
                with open(path, "rb") as f:
                    fid = hashlib.sha1(f.read()).hexdigest()
                files[fid] = os.path.relpath(path, vault).replace(os.sep, "/")
                # A group of its own, so dragging moves the whole card out of the frame.
                c.add("image", cx, cy, w, h, fileId=fid, status="saved", scale=[1, 1], crop=None,
                      frameId=frame["id"], groupIds=[c.uid()], link=item.get("link"))
                cx += w + GAP
            cy += max((k[3] for k in r), default=0) + GAP
        y += height + SECTION_GAP
    return c, files, pixels


def to_markdown(c, files):
    doc = {"type": "excalidraw", "version": 2, "source": "https://github.com/zsviczian/obsidian-excalidraw-plugin",
           "elements": c.elements, "appState": {"gridSize": None, "viewBackgroundColor": "#ffffff"}, "files": {}}
    md = ["---", "", "excalidraw-plugin: parsed", "tags: [excalidraw]", "", "---",
          "==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠==", "", "",
          "# Excalidraw Data", "", "## Text Elements"]
    for t in c.texts:
        md += [t["text"] + " ^" + t["id"], ""]
    md += ["## Embedded Files"]
    for fid, path in files.items():
        md += [f"{fid}: [[{path}]]", ""]
    return "\n".join(md + ["%%", "## Drawing", "```json", json.dumps(doc, ensure_ascii=False), "```", "%%", ""])


def refuse_existing(target):
    for path in (target.board(), target.cards()):
        if os.path.lexists(path):
            sys.exit(f"{path} exists: a board holds the user's drawings, so build under a new name")


def publish(stage, target):
    """Move the staged cards, then the board, into the vault; neither may replace anything already there."""
    os.makedirs(os.path.dirname(target.board()), exist_ok=True)
    os.mkdir(target.cards())
    try:
        for name in os.listdir(target.cards(stage)):
            os.rename(os.path.join(target.cards(stage), name), os.path.join(target.cards(), name))
        os.link(target.board(stage), target.board())
    except BaseException:
        shutil.rmtree(target.cards())
        raise


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("catalogue")
    ap.add_argument("--board", required=True)
    ap.add_argument("--vault", required=True)
    ap.add_argument("--root")
    a = ap.parse_args()
    if not os.path.isdir(a.vault):
        sys.exit(f"no vault at {a.vault}")
    target = Target(a.vault, a.board)
    refuse_existing(target)
    with open(a.catalogue, encoding="utf-8") as f:
        cat = json.load(f)
    root = a.root or os.path.dirname(os.path.abspath(a.catalogue))
    errors = catalogue_errors(cat, root)
    if errors:
        sys.exit("catalogue rejected:\n  - " + "\n  - ".join(errors))
    with tempfile.TemporaryDirectory(dir=target.vault, prefix=".board-write-") as stage:
        os.makedirs(target.cards(stage))
        items = [i for s in cat["sections"] for i in s["items"]]
        try:
            rendered = render_cards.render_all(items, root, target.cards(stage))
        except subprocess.CalledProcessError as e:
            sys.exit(f"rendering failed: {' '.join(map(str, e.cmd))}")
        c, files, pixels = layout(cat, target.cards(stage), stage)
        md = to_markdown(c, files)
        with open(target.board(stage), "w", encoding="utf-8") as f:
            f.write(md)
        found = check_board.problems(target.board(stage), stage)
        if found:
            sys.exit("board failed its check, so nothing was written:\n  - " + "\n  - ".join(found))
        jpegs = sum(os.path.getsize(p) for p in rendered)
        publish(stage, target)
    print(f"wrote {target.board()}\n"
          f"  {len(rendered)} cards, {jpegs / 1e6:.1f} MB of JPEGs + {len(md) / 1e6:.1f} MB board\n"
          f"  about {pixels * 4 / 1e6:.0f} MB decoded in memory when the board opens\n"
          f"  check: OK")


if __name__ == "__main__":
    main()
