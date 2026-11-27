"""Decode an Obsidian Excalidraw board, and group the user's handwriting on it into clusters."""
import datetime, json, os, re
from dataclasses import dataclass
from typing import NamedTuple, Optional

SUFFIX = ".excalidraw.md"
BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
THEME_MIN_WIDTH = 300  # board-write's theme cards are wider than any other rectangle it draws
ROW = 1500             # canvas units per reading row when ordering themes


def lz_decompress_base64(text):
    """LZString's decompressFromBase64. Like the original, it returns UTF-16 code units, one per character."""
    bits = (value >> shift & 1 for value in (BASE64.index(c) for c in text if c in BASE64)
            for shift in range(5, -1, -1))

    def read(n):
        try:
            return sum(next(bits) << i for i in range(n))
        except StopIteration:
            raise ValueError("LZString stream ends before its end marker") from None

    words = [None, None, None]
    kind = read(2)
    if kind == 2:
        return ""
    w = chr(read(8 if kind == 0 else 16))
    words.append(w)
    out, width, enlarge = [w], 3, 4
    while True:
        code = read(width)
        if code == 2:
            return "".join(out)
        if code in (0, 1):
            words.append(chr(read(8 if code == 0 else 16)))
            code = len(words) - 1
            enlarge -= 1
            if enlarge == 0:
                width, enlarge = width + 1, 1 << width
        if code < len(words):
            entry = words[code]
        elif code == len(words):
            entry = w + w[0]
        else:
            raise ValueError("corrupt LZString stream")
        out.append(entry)
        words.append(w + entry[0])
        enlarge -= 1
        if enlarge == 0:
            width, enlarge = width + 1, 1 << width
        w = entry


def join_surrogates(s):
    return s.encode("utf-16-le", "surrogatepass").decode("utf-16-le", "replace")


def drawing(md):
    """The Excalidraw document in a board's `## Drawing` block, compressed or not."""
    if m := re.search(r"```compressed-json\n(.*?)```", md, re.S):
        return json.loads(join_surrogates(lz_decompress_base64(m.group(1))))
    if m := re.search(r"```json\n(.*?)\n```", md, re.S):
        return json.loads(m.group(1))
    raise ValueError("no ```json or ```compressed-json drawing block")


def embedded_files(md):
    """fileId -> file name, from `## Embedded Files` lines like `<fileId>: [[Excalidraw/Prior art cards/m1.jpg]]`."""
    return {file_id: os.path.basename(link.split("|")[0])
            for file_id, link in re.findall(r"^([0-9a-f]{40}): \[\[(.*?)\]\]", md, re.M)}


class Target(NamedTuple):
    """What a cluster of handwriting can be about: a card, another image, or a theme."""
    kind: str
    name: str
    bbox: tuple


@dataclass(frozen=True)
class Cluster:
    strokes: list
    bbox: tuple
    target: Optional[Target]  # None only on a board with no images or themes
    distance: Optional[float]
    runners_up: list  # [(distance, Target)], nearest first

    def as_json(self, cid):
        updated = [s["updated"] for s in self.strokes]
        return dict(id=cid, strokes=len(self.strokes), stroke_ids=[s["id"] for s in self.strokes],
                    bbox=[round(v) for v in self.bbox],
                    attributed_kind=self.target and self.target.kind, attributed_to=self.target and self.target.name,
                    distance=self.target and round(self.distance),
                    runners_up=[f"{t.kind}:{t.name}@{round(d)}" for d, t in self.runners_up],
                    first_updated=stamp(min(updated)), last_updated=stamp(max(updated)))


class Board:
    def __init__(self, path, cards_dir=None):
        if not path.endswith(SUFFIX):
            raise ValueError(f"a board's name ends {SUFFIX}: {path}")
        with open(path, encoding="utf-8") as f:
            md = f.read()
        self.all = drawing(md)["elements"]
        self.live = [e for e in self.all if not e.get("isDeleted")]
        self.files = embedded_files(md)
        self.cards_dir = cards_dir or os.path.abspath(path)[:-len(SUFFIX)] + " cards"
        self.strokes = [e for e in self.live if e["type"] == "freedraw" and len(e["points"]) >= 2]
        self.images = [e for e in self.live if e["type"] == "image"]
        self.texts = [e for e in self.live if e["type"] == "text"]
        self.rects = [e for e in self.live if e["type"] == "rectangle"]
        self.themes = [r for r in self.rects if r["width"] > THEME_MIN_WIDTH]

    def card_path(self, image):
        """The image's file in the cards folder, or None: a user-added image, or a card file that is missing."""
        name = self.files.get(image.get("fileId"))
        path = name and os.path.join(self.cards_dir, name)
        return path if path and os.path.isfile(path) else None

    def image_target(self, image):
        name = self.files.get(image.get("fileId"))
        if self.card_path(image):
            return Target("card", os.path.splitext(name)[0].upper(), bbox(image))
        return Target("image", name or f"fileId {str(image.get('fileId'))[:8]}", bbox(image))

    def theme_title(self, rect):
        x0, y0, x1, y1 = bbox(rect)
        inside = sorted((t for t in self.texts if x0 <= t["x"] <= x1 and y0 <= t["y"] <= y1),
                        key=lambda t: (t["y"], t["x"]))
        return inside[0]["text"].split("\n")[0][:60] if inside else f"rect@{round(x0)},{round(y0)}"

    def targets(self):
        return ([self.image_target(i) for i in self.images] +
                [Target("theme", self.theme_title(r), bbox(r)) for r in self.themes])

    def clusters(self, gap):
        """id -> Cluster, largest first: strokes whose boxes lie within `gap` of each other, by nearest target."""
        targets = self.targets()
        named = name_clusters(attribute(group, targets) for group in group_strokes(self.strokes, gap))
        return dict(sorted(named.items(), key=lambda item: (-len(item[1].strokes), item[0])))


def group_strokes(strokes, gap):
    """Strokes linked, directly or through others, by bounding boxes no more than `gap` apart."""
    boxes = [bbox(s) for s in strokes]
    parent = list(range(len(strokes)))

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    by_left = sorted(range(len(boxes)), key=lambda i: boxes[i][0])
    for n, i in enumerate(by_left):
        for j in by_left[n + 1:]:
            if boxes[j][0] > boxes[i][2] + gap:
                break
            if boxes[j][1] <= boxes[i][3] + gap and boxes[i][1] <= boxes[j][3] + gap:
                parent[root(i)] = root(j)
    groups = {}
    for i, s in enumerate(strokes):
        groups.setdefault(root(i), []).append(s)
    return list(groups.values())


def attribute(strokes, targets):
    """The cluster of `strokes`, filed under the nearest target; an image wins a tie with a theme."""
    box = union(*(bbox(s) for s in strokes))
    ranked = sorted(((distance(box, t.bbox), t.kind == "theme", t) for t in targets), key=lambda r: r[:2])
    if not ranked:
        return Cluster(strokes, box, None, None, [])
    (d, _, nearest), rest = ranked[0], ranked[1:3]
    return Cluster(strokes, box, nearest, d, [(d, t) for d, _, t in rest])


def name_clusters(clusters):
    """id -> Cluster, an id such as `K5@10100,29680`: what it is filed under, and its box's corner rounded to 10.

    Clusters sharing a name are numbered `.2`, `.3`… by their lowest stroke id, never by the order strokes are read in.
    """
    by_name = {}
    for c in clusters:
        name = f"{slug(c.target.name) if c.target else 'none'}@{int(round(c.bbox[0], -1))},{int(round(c.bbox[1], -1))}"
        by_name.setdefault(name, []).append(c)
    named = {}
    for name, same in by_name.items():
        same.sort(key=lambda c: min(s["id"] for s in c.strokes))
        named.update((name if n == 1 else f"{name}.{n}", c) for n, c in enumerate(same, 1))
    return named


def slug(name):
    return "".join(ch if ch.isalnum() else "_" for ch in name)[:40]


def bbox(e):
    """(x0, y0, x1, y1) in canvas units; a stroke's or arrow's points are relative to its x, y."""
    if e["type"] in ("freedraw", "arrow", "line") and e.get("points"):
        xs = [e["x"] + p[0] for p in e["points"]]
        ys = [e["y"] + p[1] for p in e["points"]]
        return min(xs), min(ys), max(xs), max(ys)
    return e["x"], e["y"], e["x"] + e["width"], e["y"] + e["height"]


def union(*boxes):
    return (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))


def distance(a, b):
    dx = max(0, b[0] - a[2], a[0] - b[2])
    dy = max(0, b[1] - a[3], a[1] - b[3])
    return (dx * dx + dy * dy) ** .5


def stamp(ms):
    return datetime.datetime.fromtimestamp(ms / 1000).strftime("%Y-%m-%d %H:%M")


def parse_time(s):
    """Epoch milliseconds, from epoch milliseconds or a local time such as '2026-11-20 19:03'."""
    if re.fullmatch(r"\d{12,}", s):
        return int(s)
    try:
        return int(datetime.datetime.fromisoformat(s).timestamp() * 1000)
    except ValueError:
        raise ValueError(f"not a local time like '2026-11-20 19:03', nor epoch milliseconds: {s!r}") from None
