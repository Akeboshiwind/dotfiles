#!/usr/bin/env python3
"""Check an Excalidraw board: frames don't overlap, frame members sit inside their frame, every image's file
exists, and every text element is listed under '## Text Elements'.

usage: check_board.py BOARD.excalidraw.md VAULT   (exit 1 on any problem)
"""
import json, os, re, sys


def overlap(a, b):
    return (a["x"] < b["x"] + b["width"] and b["x"] < a["x"] + a["width"]
            and a["y"] < b["y"] + b["height"] and b["y"] < a["y"] + a["height"])


def outside(e, f):
    return (e["x"] < f["x"] or e["y"] < f["y"]
            or e["x"] + e["width"] > f["x"] + f["width"] or e["y"] + e["height"] > f["y"] + f["height"])


def problems(board, vault):
    with open(board, encoding="utf-8") as f:
        md = f.read()
    drawing = re.search(r"^```json\n(.*?)\n```$", md, re.S | re.M)
    if not drawing:
        return ["no ```json drawing block"]
    elements = json.loads(drawing.group(1))["elements"]
    found = []
    frames = {e["id"]: e for e in elements if e["type"] == "frame"}
    listed = list(frames.values())
    for i, a in enumerate(listed):
        for b in listed[i + 1:]:
            if overlap(a, b):
                found.append(f"frames overlap: {a['name']} / {b['name']}")
    for e in elements:
        if e.get("frameId") is None:
            continue
        f = frames.get(e["frameId"])
        if f is None:
            found.append(f"{e['type']} {e['id']} names a frame that doesn't exist")
        elif outside(e, f):
            found.append(f"{e['type']} {e['id']} sits outside frame {f['name']}")
    files = dict(re.findall(r"^([0-9a-f]{40}): \[\[(.*?)\]\]$", md, re.M))
    for e in elements:
        if e["type"] != "image":
            continue
        path = files.get(e["fileId"])
        if path is None:
            found.append(f"image {e['id']} has no entry under Embedded Files")
        elif not os.path.isfile(os.path.join(vault, path)):
            found.append(f"missing file {path}")
    listed_texts = set(re.findall(r" \^([0-9a-f]{16})$", md, re.M))
    for e in elements:
        if e["type"] == "text" and e["id"] not in listed_texts:
            found.append(f"text {e['id']} missing from Text Elements")
    return found


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__.strip())
    found = problems(sys.argv[1], sys.argv[2])
    print("OK" if not found else f"{len(found)} problems")
    for p in found:
        print("  -", p)
    sys.exit(1 if found else 0)


if __name__ == "__main__":
    main()
