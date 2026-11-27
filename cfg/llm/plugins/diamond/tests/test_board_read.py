"""board-read: python3 -m unittest discover -s cfg/llm/plugins/diamond/tests (needs ImageMagick)."""
import json, os, subprocess, sys, tempfile, unittest

SCRIPTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills", "board-read", "scripts")
sys.path.insert(0, SCRIPTS)
import boardlib

CARD_FILE = "0af3093ec0928ceff5220d79d1675a063eff4657"
USER_FILE = "92addca07c326b3774cec4644d334f1470c14ad3"
EARLIER, LATER = 1763650000000, 1763657200000  # epoch ms, two hours apart
# lz-string 1.5.0 compressToBase64 of {"type":"excalidraw","elements":[{"id":"t1","type":"text","text":"Inbox 😅 → queue",…}]}
COMPRESSED = ("N4IgLgngDgpiBcIYA8DGBDANgSwCYCd0B3EAGiUxgFsYA7MAZwQG1Q8FwBGM8aORMCjA9ByYYgCStAEYB7ZAAJAvBuBQPYWAkwgUBHAK4w9PZAgAM5"
              "CCfJE8YABYJOpkDZjYA5jfEPyAM1n0AytgAXvwATI46ULjogrj2AL4AuvFAA==")


def stroke(sid, x, y, points, updated=EARLIER, **more):
    return dict(id=sid, type="freedraw", x=x, y=y, points=points, updated=updated, strokeWidth=2, **more)


def board_md(elements, files=(), compressed=None):
    drawing = (["```compressed-json", compressed[:100], compressed[100:], "```"] if compressed else
               ["```json", json.dumps({"type": "excalidraw", "elements": elements}, ensure_ascii=False), "```"])
    embedded = [f"{file_id}: [[{name}]]\n" for file_id, name in files]
    return "\n".join(["# Excalidraw Data", "## Embedded Files", *embedded, "%%", "## Drawing", *drawing, "%%", ""])


class BoardRead(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.dir = os.path.join(tmp.name, "it's 100% here")
        self.cards = os.path.join(self.dir, "Prior art cards")
        os.makedirs(self.cards)
        subprocess.run(["magick", "-size", "300x200", "xc:#88aacc", os.path.join(self.cards, "m1.jpg")], check=True)
        self.board = os.path.join(self.dir, "Prior art.excalidraw.md")
        self.elements = [
            dict(id="card", type="image", fileId=CARD_FILE, x=0, y=0, width=300, height=200, updated=EARLIER),
            dict(id="theme", type="rectangle", x=2000, y=0, width=400, height=200, updated=EARLIER),
            dict(id="title", type="text", text="Theme one\nits body", x=2010, y=10, width=200, height=40,
                 fontSize=20, updated=EARLIER),
            dict(id="note", type="text", text="it's a \\ 100% note", x=0, y=300, width=200, height=20,
                 fontSize=20, updated=LATER),
            stroke("s1", 320, 0, [[0, 0], [50, 50]]),
            stroke("s2", 400, 0, [[0, 0], [30, 30]], updated=LATER),
            stroke("far", 1500, 0, [[0, 0], [50, 50]]),
            stroke("gone", 600, 0, [[0, 0], [800, 0]], updated=LATER, isDeleted=True),
        ]
        self.files = [(CARD_FILE, "m1.jpg")]

    def write(self, **kw):
        with open(self.board, "w", encoding="utf-8") as f:
            f.write(board_md(self.elements, self.files, **kw))

    def load(self):
        self.write()
        return boardlib.Board(self.board)

    def run_board(self, *args):
        return subprocess.run([sys.executable, "-I", os.path.join(SCRIPTS, "board.py"), *args],
                              capture_output=True, text=True)

    def test_reads_a_compressed_board_and_rejoins_emoji(self):
        self.write(compressed=COMPRESSED)
        self.assertEqual([t["text"] for t in boardlib.Board(self.board).texts], ["Inbox 😅 → queue"])

    def test_deleted_elements_are_kept_but_not_live(self):
        b = self.load()
        self.assertIn("gone", [e["id"] for e in b.all])
        self.assertNotIn("gone", [e["id"] for e in b.live])
        self.assertNotIn("gone", [s["id"] for s in b.strokes])

    def test_a_strokes_points_count_from_its_origin(self):
        self.assertEqual(boardlib.bbox(stroke("s", 100, 200, [[0, 0], [-10, 30], [50, 5]])), (90, 200, 150, 230))

    def test_strokes_within_the_gap_share_a_cluster(self):
        found = self.load().clusters(150)
        self.assertEqual([[s["id"] for s in c.strokes] for c in found.values()], [["s1", "s2"], ["far"]])
        self.assertEqual(list(found), ["c01", "c02"])

    def test_a_smaller_gap_splits_a_cluster(self):
        self.assertEqual(len(self.load().clusters(20)), 3)

    def test_a_cluster_is_filed_under_its_nearest_card_or_theme(self):
        near, far = self.load().clusters(150).values()
        self.assertEqual((near.target.kind, near.target.name, near.distance), ("card", "M1", 20))
        self.assertEqual((far.target.kind, far.target.name, far.distance), ("theme", "Theme one", 450))

    def test_a_card_wins_a_tie_with_a_theme(self):
        self.elements[1].update(x=420)
        self.elements[2].update(x=430)
        self.elements[4:] = [stroke("mid", 340, 0, [[0, 0], [40, 40]])]
        (only,) = self.load().clusters(150).values()
        self.assertEqual((only.target.kind, only.distance), ("card", 40))

    def test_an_image_whose_file_is_not_a_card_is_the_users(self):
        self.elements.append(dict(id="pasted", type="image", fileId=USER_FILE, x=0, y=900, width=10, height=10,
                                  updated=EARLIER))
        self.files.append((USER_FILE, "Pasted image.png"))
        b = self.load()
        self.assertEqual([tuple(b.image_target(i))[:2] for i in b.images],
                         [("card", "M1"), ("image", "Pasted image.png")])

    def test_a_board_with_nothing_to_file_under(self):
        self.elements = [stroke("s1", 0, 0, [[0, 0], [5, 5]])]
        (only,) = self.load().clusters(150).values()
        self.assertIsNone(only.target)
        self.assertIsNone(only.as_json("c01")["attributed_to"])

    def test_clusters_out_creates_its_folder(self):
        self.write()
        out = os.path.join(self.dir, "new", "clusters.json")
        done = self.run_board("clusters", self.board, "--out", out)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("gap 150", done.stdout)
        with open(out, encoding="utf-8") as f:
            self.assertEqual([c["stroke_ids"] for c in json.load(f)], [["s1", "s2"], ["far"]])

    def test_since_lists_what_changed_after_the_time(self):
        self.write()
        done = self.run_board("since", self.board, str(EARLIER + 3600000))
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("2 live elements updated, 1 of them not strokes; 1 deleted", done.stdout)
        self.assertIn("100% note", done.stdout)
        self.assertIn("c01 card:M1 1/2 new", done.stdout)
        self.assertNotIn("c02", done.stdout)

    def test_since_reads_a_local_time(self):
        self.assertEqual(boardlib.parse_time("1700000000000"), 1700000000000)
        local = boardlib.parse_time("2026-11-20 19:03")
        self.assertEqual(boardlib.stamp(local), "2026-11-20 19:03")
        with self.assertRaises(ValueError):
            boardlib.parse_time("yesterday")

    def test_since_refuses_a_time_it_cannot_read(self):
        self.write()
        done = self.run_board("since", self.board, "yesterday")
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("yesterday", done.stderr)

    def test_render_draws_each_cluster_each_theme_and_an_overview(self):
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(sorted(os.listdir(out)), ["cluster_c01_M1.png", "cluster_c02_Theme_one.png",
                                                   "overview.png", "theme_Theme_one.png"])

    def test_render_only_an_unknown_cluster_writes_nothing(self):
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out, "--only", "c09")
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("c09", done.stderr)
        self.assertFalse(os.path.exists(out))

    def test_a_file_that_is_not_a_board_is_refused(self):
        notes = os.path.join(self.dir, "notes.md")
        with open(notes, "w") as f:
            f.write("# notes")
        done = self.run_board("inventory", notes)
        self.assertNotEqual(done.returncode, 0)
        self.assertIn(".excalidraw.md", done.stderr)


if __name__ == "__main__":
    unittest.main()
