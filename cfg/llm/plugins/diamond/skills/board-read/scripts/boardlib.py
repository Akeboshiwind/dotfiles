"""Decode an Obsidian Excalidraw board, and group the user's handwriting on it into clusters."""
import collections, datetime, json, os, re, statistics
from dataclasses import dataclass
from typing import NamedTuple, Optional

SUFFIX = ".excalidraw.md"
BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
THEME_MIN_WIDTH = 300  # board-write's theme cards are wider than any other rectangle it draws
ROW = 1500             # canvas units per reading row when ordering themes

# Attribution thresholds, in canvas units or shares of a cluster's strokes, tuned by eye on one board (Prior art)
CONTAINS = 0.6
SPLIT = 0.75
FAR = 1500
FAR_SIDES = 2
SPREAD = 1500
CROWDED = 150
SPANS = 0.15


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
    """What a cluster of handwriting can be filed under: a card, another image, a theme, or a section (a frame)."""
    kind: str
    name: str
    bbox: tuple
    titled: bool = True  # False only for a theme with no text in it

    def __str__(self):
        return f"{self.kind}:{self.name}"


class Flag(NamedTuple):
    """Why a cluster's filing is in doubt: far, spread, crowded, split, spans sections, untitled theme rectangle."""
    reason: str
    detail: str = ""

    def __str__(self):
        return f"{self.reason} ({self.detail})" if self.detail else self.reason


@dataclass(frozen=True)
class Cluster:
    strokes: list
    bbox: tuple
    target: Optional[Target]  # None only on a board with no images or themes
    distance: Optional[float]
    runners_up: list  # [(distance, Target)], nearest first
    section: Optional[Target]  # the frame whose rows hold most of its strokes, if any do
    flags: tuple

    @property
    def far(self):
        return any(f.reason == "far" for f in self.flags)

    def as_json(self, cid):
        updated = [s["updated"] for s in self.strokes]
        return dict(id=cid, strokes=len(self.strokes), stroke_ids=[s["id"] for s in self.strokes],
                    bbox=[round(v) for v in self.bbox],
                    attributed_kind=self.target and self.target.kind, attributed_to=self.target and self.target.name,
                    distance=self.target and round(self.distance),
                    runners_up=[f"{t}@{round(d)}" for d, t in self.runners_up],
                    section=self.section and self.section.name, ambiguous=[str(f) for f in self.flags],
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
        self.themes = self.name_themes()
        self.sections = [Target("section", f.get("name") or "untitled frame", bbox(f))
                         for f in self.live if f["type"] == "frame"]

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
        """The first line of the first text inside `rect`, or None."""
        x0, y0, x1, y1 = bbox(rect)
        inside = sorted((t for t in self.texts if x0 <= t["x"] <= x1 and y0 <= t["y"] <= y1),
                        key=lambda t: (t["y"], t["x"]))
        return inside[0]["text"].split("\n")[0][:60] if inside else None

    def name_themes(self):
        """rect id -> Target, in reading order, for each theme rectangle, each named apart from the others.

        A title shared with an earlier theme, ignoring case and punctuation, gets ` 2`, ` 3`…, as does `Untitled theme`.
        """
        rects = sorted((r for r in self.rects if r["width"] > THEME_MIN_WIDTH), key=lambda r: (r["y"] // ROW, r["x"]))
        taken, themes = set(), {}
        for r in rects:
            title = self.theme_title(r)
            name, n = title or "Untitled theme", 1
            while slug(name).casefold() in taken:
                n += 1
                name = f"{title or 'Untitled theme'} {n}"
            taken.add(slug(name).casefold())
            themes[r["id"]] = Target("theme", name, bbox(r), titled=title is not None)
        return themes

    def rect_name(self, rect):
        theme = self.themes.get(rect["id"])
        return theme.name if theme else self.theme_title(rect) or "rectangle"

    def targets(self):
        return [self.image_target(i) for i in self.images] + list(self.themes.values())

    def clusters(self, gap):
        """id -> Cluster, largest first: strokes whose boxes lie within `gap` of each other, filed by `attribute`."""
        targets = self.targets()
        named = name_clusters(attribute(group, targets, self.sections) for group in group_strokes(self.strokes, gap))
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


def attribute(strokes, targets, sections):
    """The cluster of `strokes`, filed under a target, with a Flag for each reason to doubt it.

    A card or theme holding CONTAINS of the strokes' centres wins; otherwise the nearest, an image winning a tie
    with a theme. A nearest target that is far gives way to the section, if the strokes have one.
    """
    box = union(*(bbox(s) for s in strokes))
    centres = [centre(bbox(s)) for s in strokes]
    n = len(strokes)
    rows = collections.Counter(next((f for f in sections if f.bbox[1] <= y <= f.bbox[3]), None) for _, y in centres)
    section = max(rows, key=lambda f: (rows[f], f is not None, f and f.name))
    ranked = [t for _, _, t in sorted(((distance(box, t.bbox), t.kind == "theme", t) for t in targets),
                                      key=lambda r: r[:2])]
    flags = []
    if not ranked:
        target = None
    else:
        holders = collections.Counter(next((t for t in ranked if inside(c, t.bbox)), None) for c in centres)
        holder, held = max(((t, k) for t, k in holders.items() if t), key=lambda h: h[1], default=(None, 0))
        if held / n >= CONTAINS:
            target = holder
            if held / n < SPLIT:
                flags.append(Flag("split", f"{held} of {n} strokes inside {holder}"))
        else:
            target = ranked[0]
            d = distance(box, target.bbox)
            median = statistics.median(distance((x, y, x, y), target.bbox) for x, y in centres)
            if d > FAR or median > max(FAR, FAR_SIDES * max(target.bbox[2] - target.bbox[0],
                                                             target.bbox[3] - target.bbox[1])):
                flags.append(Flag("far", f"{round(d)} from {target}, median stroke {round(median)}"
                                         + (", filed under its section" if section else "")))
                target = section or target
            else:
                if median > SPREAD:
                    flags.append(Flag("spread", f"median stroke {round(median)} from {target}"))
                crowd = [t for t in ranked[1:] if distance(box, t.bbox) <= d + CROWDED]
                if crowd:
                    flags.append(Flag("crowded", "also near " + ", ".join(map(str, crowd[:3]))))
    if target and target.kind == "theme" and not target.titled:
        flags.append(Flag("untitled theme rectangle"))
    spans = sorted(((k, f.name) for f, k in rows.items() if f), reverse=True)
    if len(spans) > 1 and spans[1][0] / n > SPANS:
        flags.append(Flag("spans sections", ", ".join(f"{name} {k}" for k, name in spans)))
    if target is None:
        return Cluster(strokes, box, None, None, [], section, tuple(flags))
    rest = [(distance(box, t.bbox), t) for t in ranked if t != target][:2]
    return Cluster(strokes, box, target, distance(box, target.bbox), rest, section, tuple(flags))


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
    return "".join(ch if ch.isalnum() else "_" for ch in name)


def bbox(e):
    """(x0, y0, x1, y1) in canvas units; a stroke's or arrow's points are relative to its x, y."""
    if e["type"] in ("freedraw", "arrow", "line") and e.get("points"):
        xs = [e["x"] + p[0] for p in e["points"]]
        ys = [e["y"] + p[1] for p in e["points"]]
        return min(xs), min(ys), max(xs), max(ys)
    return e["x"], e["y"], e["x"] + e["width"], e["y"] + e["height"]


def centre(box):
    return (box[0] + box[2]) / 2, (box[1] + box[3]) / 2


def inside(point, box):
    return box[0] <= point[0] <= box[2] and box[1] <= point[1] <= box[3]


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
