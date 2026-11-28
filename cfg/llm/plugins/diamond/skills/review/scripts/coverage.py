#!/usr/bin/env python3
"""Check that a transcript covers the clusters it was meant to, keeping every AMBIGUOUS flag.

usage: coverage.py CLUSTERS_JSON TRANSCRIPT [--only ID ...]

CLUSTERS_JSON is board-read's `clusters --out`. A cluster's section in TRANSCRIPT is each `## <cluster ID>` heading,
the ID its first word, and what follows it up to the next `#` or `##` heading.

  MISSING    no section, or nothing under it                        fails
  LAUNDERED  flagged ambiguous, and no section of it says AMBIGUOUS   fails
  SUSPECT    100 strokes or more, and no [?]                          warns: the checker reads these first

Exit 1 on a failure, 2 on bad input."""
import argparse, json, re, sys
from typing import NamedTuple

SUSPECT_STROKES = 100
HEADING = re.compile(r"(#{1,2})\s+(\S*)")


def refuse(why):
    print(f"coverage: {why}", file=sys.stderr)
    sys.exit(2)


class Cluster(NamedTuple):
    id: str
    strokes: int
    ambiguous: bool


def clusters_of(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    try:
        return [Cluster(c["id"], c["strokes"], bool(c["ambiguous"])) for c in data]
    except (TypeError, KeyError):
        refuse(f"{path} is not board-read's `clusters --out` JSON")


def sections(text):
    """Each cluster ID's sections' bodies, joined."""
    found, current = {}, None
    for line in text.splitlines():
        m = HEADING.match(line)
        if m:
            current = m.group(2) if m.group(1) == "##" else None
            if current is not None:
                found.setdefault(current, [])
        elif current is not None:
            found[current].append(line)
    return {cid: "\n".join(lines) for cid, lines in found.items()}


def problem(cluster, body):
    if body is None or not body.strip():
        return f"MISSING {cluster.id}: no section, or nothing under its heading"
    elif cluster.ambiguous and "AMBIGUOUS" not in body:
        return f"LAUNDERED {cluster.id}: flagged AMBIGUOUS, and its section doesn't say so"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("clusters")
    ap.add_argument("transcript")
    ap.add_argument("--only", nargs="+", metavar="ID", help="check only these clusters, as on a re-read")
    a = ap.parse_args()
    clusters = clusters_of(a.clusters)
    unknown = set(a.only or ()) - {c.id for c in clusters}
    if unknown:
        refuse(f"no such clusters: {' '.join(sorted(unknown))}")
    with open(a.transcript, encoding="utf-8") as f:
        bodies = sections(f.read())
    failed = 0
    for c in clusters:
        if a.only and c.id not in a.only:
            continue
        body = bodies.get(c.id)
        p = problem(c, body)
        if p:
            print(p)
            failed += 1
        if body and c.strokes >= SUSPECT_STROKES and "[?]" not in body:
            print(f"SUSPECT {c.id}: {c.strokes} strokes and no [?] (advisory)")
    print("coverage: ok" if not failed else f"coverage: {failed} problem(s)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
