"""Render each catalogue item to one JPEG card with ImageMagick: title, kind, sig, use, then its images with captions."""
import os, re, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor

IMG_H = 360
GAP, PAD, MIN_W = 20, 28, 820
PAPER, EDGE, INK, MUTED = "#f5f2ea", "#b9b2a3", "#1e1e1e", "#6b6559"


def font(env, *candidates):
    for c in (os.environ.get(env),) + candidates:
        if c and os.path.exists(c):
            return c
    return "Helvetica"


SERIF_B = font("BOARD_FONT_TITLE", "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
               "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf")
SERIF = font("BOARD_FONT_SIG", "/System/Library/Fonts/Supplemental/Georgia.ttf",
             "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf")
# Georgia has no arrow glyph; Hiragino has arrows and kana.
SANS = font("BOARD_FONT_BODY", "/System/Library/Fonts/Hiragino Sans GB.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")


def card_name(item_id):
    return re.sub(r"[^a-z0-9._-]+", "-", item_id.lower()) + ".jpg"


def image_size(path):
    # ImageMagick 7 rejects -quiet before the subcommand.
    out = subprocess.run(["magick", "identify", "-quiet", "-format", "%w %h", path + "[0]"],
                         capture_output=True, text=True, check=True).stdout.split()
    return int(out[0]), int(out[1])


def caption_text(s):
    """caption: expands % escapes, and reads a file named by a leading @."""
    s = s.replace("%", "%%")
    return " " + s if s.startswith("@") else s


def text_png(path, s, fnt, pt, width, color):
    if fnt in (SERIF, SERIF_B):
        s = s.replace("→", "›")
    subprocess.run(["magick", "-quiet", "-background", PAPER, "-fill", color, "-font", fnt, "-pointsize", str(pt),
                    "-size", f"{width}x", "caption:" + caption_text(s), path], check=True)


def spacer(w, h):
    return ["(", "-size", f"{w}x{h}", "xc:" + PAPER, ")"]


def render(item, root, out_dir):
    images = item.get("images", [])
    paths = [os.path.join(root, i["file"]) for i in images]
    widths = [round(IMG_H * w / h) for w, h in map(image_size, paths)]
    inner = max(MIN_W, sum(widths) + GAP * max(0, len(widths) - 1))
    lines = [(f'{item["id"]} · {item["name"]}', 34, SERIF_B, INK),
             (item.get("kind", ""), 17, SANS, MUTED),
             (item.get("sig", ""), 23, SERIF, INK),
             ("Use: " + item["use"] if item.get("use") else "", 19, SANS, MUTED)]
    out = os.path.join(out_dir, card_name(item["id"]))
    with tempfile.TemporaryDirectory() as work:
        args = ["magick", "-quiet", "-background", PAPER]
        for k, (s, pt, fnt, color) in enumerate(l for l in lines if l[0]):
            p = os.path.join(work, f"t{k}.png")
            text_png(p, s, fnt, pt, inner, color)
            args += [p] + spacer(1, 14 if k else 6)
        columns = []
        for j, (image, path, w) in enumerate(zip(images, paths, widths)):
            col = os.path.join(work, f"col{j}.png")
            cmd = ["magick", "-quiet", "-background", PAPER, path + "[0]", "-resize", f"x{IMG_H}"]
            if image.get("caption"):
                cap = os.path.join(work, f"cap{j}.png")
                text_png(cap, image["caption"], SANS, 14, max(w, 120), MUTED)
                cmd += spacer(1, 8) + [cap]
            subprocess.run(cmd + ["-gravity", "west", "-append", col], check=True)
            columns.append(col)
        if columns:
            row = ["("]
            for j, col in enumerate(columns):
                row += (spacer(GAP, 1) if j else []) + [col]
            args += spacer(1, 10) + row + ["-gravity", "north", "+append", ")"]
        subprocess.run(args + ["-gravity", "west", "-append", "-bordercolor", PAPER, "-border", str(PAD),
                               "-bordercolor", EDGE, "-border", "2", "-quality", "80", out], check=True)
    return out


def render_all(items, root, out_dir, jobs=4):
    with ThreadPoolExecutor(jobs) as ex:
        return list(ex.map(lambda i: render(i, root, out_dir), items))
