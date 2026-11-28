"""Merge a discover run's work folder into the catalogue board-write builds a board from.

usage: merge.py WORK --title TITLE [--subtitle SUBTITLE]

Reads, from WORK:
  slices.json         [{"id": "M", "title", "note"}], in board order
  items/<slice>.json  {"items": [{"id": "M1", "name", "kind", "link", "sig", "use"}]}, written by the slice's agent
  images/<id>.json    {"id": "M1", "images": [{"file", "caption", "source"}]}, written by fetch-images' keep.py
  themes.json         [{"title", "body", "refs": ["M1", "P2"]}], optional

An image record belongs to the item whose id its file is named by, exactly. Writes WORK/catalogue.json, then prints
the counts and the items without images. Every problem found is reported, and then nothing is written."""
import argparse, json, os, re, sys

OPTIONAL = ("kind", "link", "sig", "use")


def load(work, rel, problems):
    try:
        with open(os.path.join(work, rel), encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        problems.append(f"{rel} is missing")
    except ValueError as e:
        problems.append(f"{rel} is not JSON: {e}")


def slices_of(work, problems):
    data = load(work, "slices.json", problems)
    if data is None:
        return []
    ok = isinstance(data, list) and all(
        isinstance(s, dict) and re.fullmatch(r"[A-Za-z]+", str(s.get("id"))) and isinstance(s.get("title"), str)
        for s in data)
    if not ok or len({s["id"] for s in data}) != len(data):
        problems.append('slices.json must be [{"id": "M", "title": "…", "note": "…"}], ids distinct letters')
        return []
    return data


def section(work, s, problems):
    rel = f"items/{s['id']}.json"
    data = load(work, rel, problems)
    if data is None:
        return []
    if not isinstance(data, dict) or not isinstance(data.get("items"), list):
        problems.append(f'{rel} needs an "items" list')
        return []
    items = []
    for it in data["items"]:
        i = it.get("id") if isinstance(it, dict) else None
        if not isinstance(i, str) or not re.fullmatch(re.escape(s["id"]) + r"[0-9]+", i):
            problems.append(f"{rel}: id {i!r} is not slice {s['id']}'s prefix then a number")
        elif not isinstance(it.get("name"), str) or not it["name"].strip():
            problems.append(f"{rel}: {i} needs a name")
        else:
            items.append({"id": i, "name": it["name"], **{k: it.get(k) or "" for k in OPTIONAL}})
    return items


def image_records(work, problems):
    folder = os.path.join(work, "images")
    records = {}
    for name in sorted(os.listdir(folder)) if os.path.isdir(folder) else []:
        if not name.endswith(".json"):
            continue
        rel, stem = f"images/{name}", name[:-len(".json")]
        data = load(work, rel, problems)
        if data is None:
            continue
        if not isinstance(data, dict) or data.get("id") != stem or not isinstance(data.get("images"), list):
            got = data.get("id") if isinstance(data, dict) else None
            problems.append(f'{rel} must be {{"id": {stem!r}, "images": [...]}}, but records id {got!r}')
            continue
        for image in data["images"]:
            if not os.path.isfile(os.path.join(work, image.get("file") or "")):
                problems.append(f"{rel}: missing image {image.get('file')}")
        records[stem] = (rel, data["images"])
    return records


def merge(work, title, subtitle):
    problems = []
    slices = slices_of(work, problems)
    sections = [{"id": s["id"], "title": s["title"], "note": s.get("note") or "", "items": section(work, s, problems)}
                for s in slices]

    ids = [it["id"] for s in sections for it in s["items"]]
    for i in sorted({i for i in ids if ids.count(i) > 1}):
        problems.append(f"duplicate id {i}")
    records = image_records(work, problems)
    for stem in sorted(set(records) - set(ids)):
        problems.append(f"{records[stem][0]} has no item {stem}: image records are named by the exact id")
    for s in sections:
        for it in s["items"]:
            it["images"] = records.get(it["id"], (None, []))[1]

    themes = load(work, "themes.json", problems) if os.path.exists(os.path.join(work, "themes.json")) else []
    if themes is None:
        themes = []
    elif not (isinstance(themes, list) and all(isinstance(t, dict) and isinstance(t.get("title"), str)
                                               and isinstance(t.get("refs", []), list) for t in themes)):
        problems.append('themes.json must be [{"title": "…", "body": "…", "refs": ["M1"]}]')
        themes = []
    for t in themes:
        unknown = [r for r in t.get("refs", []) if r not in ids]
        if unknown:
            problems.append(f"theme {t['title']!r} cites unknown ids {', '.join(unknown)}")

    catalogue = {"title": title, **({"subtitle": subtitle} if subtitle else {}), "themes": themes,
                 "sections": sections}
    return catalogue, problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("work")
    ap.add_argument("--title", required=True)
    ap.add_argument("--subtitle")
    a = ap.parse_args()

    catalogue, problems = merge(a.work, a.title, a.subtitle)
    if problems:
        sys.exit("\n".join(f"problem: {p}" for p in problems) + "\nnothing written")
    path = os.path.join(a.work, "catalogue.json")
    with open(path + ".part", "w", encoding="utf-8") as f:
        json.dump(catalogue, f, ensure_ascii=False, indent=1)
    os.replace(path + ".part", path)

    items = [it for s in catalogue["sections"] for it in s["items"]]
    without = [it["id"] for it in items if not it["images"]]
    print(f"{len(catalogue['sections'])} sections, {len(items)} items ({len(items) - len(without)} with images), "
          f"{len(catalogue['themes'])} themes")
    print(f"without images: {', '.join(without) or 'none'}")


if __name__ == "__main__":
    main()
