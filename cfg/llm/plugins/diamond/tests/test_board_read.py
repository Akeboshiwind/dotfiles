"""board-read: python3 -m unittest discover -s cfg/llm/plugins/diamond/tests (needs ImageMagick)."""
import json, os, subprocess, sys, tempfile, unittest

SCRIPTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills", "board-read", "scripts")
sys.path.insert(0, SCRIPTS)
import boardlib
from board import tiles

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

    def run_board(self, *args, env=None):
        return subprocess.run([sys.executable, "-I", os.path.join(SCRIPTS, "board.py"), *args],
                              capture_output=True, text=True, env=env)

    def snapshot(self, name=None):
        self.write()
        done = self.run_board("snapshot", self.board, "--state-dir", self.state)
        self.assertEqual(done.returncode, 0, done.stderr)
        if name:
            folder = os.path.join(self.state, "Prior art")
            (taken,) = (f for f in os.listdir(folder) if not f.startswith("2000-"))
            os.rename(os.path.join(folder, taken), os.path.join(folder, name))

    def since_snapshot(self, *args):
        self.write()
        done = self.run_board("since", self.board, "--state-dir", self.state, *args)
        self.assertEqual(done.returncode, 0, done.stderr)
        return done.stdout

    @property
    def state(self):
        return os.path.join(self.dir, "state")

    def element(self, eid):
        return next(e for e in self.elements if e["id"] == eid)

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

    def test_a_smaller_gap_splits_a_cluster(self):
        self.assertEqual(len(self.load().clusters(20)), 3)

    def test_a_cluster_is_named_by_what_it_is_filed_under_and_its_corner(self):
        self.assertEqual(list(self.load().clusters(150)), ["M1@320,0", "Theme_one@1500,0"])

    def test_a_clusters_corner_is_rounded_to_10(self):
        self.elements[6] = stroke("far", 1504, -26, [[0, 0], [50, 50]])
        self.assertIn("Theme_one@1500,-30", self.load().clusters(150))
        self.elements[6] = stroke("far", 1500, -3.5, [[0, 0], [50, 50]])
        self.assertIn("Theme_one@1500,0", self.load().clusters(150))

    def test_a_cluster_keeps_its_id_whatever_the_gap_or_the_order_of_strokes(self):
        wide = self.load().clusters(150)
        self.elements.reverse()
        narrow = self.load().clusters(20)
        self.assertEqual(len(narrow), 3)
        self.assertEqual(narrow["Theme_one@1500,0"].strokes, wide["Theme_one@1500,0"].strokes)

    def test_a_cluster_drawn_on_changes_its_id(self):
        self.elements.append(stroke("more", 1450, 0, [[0, 0], [20, 20]]))
        self.assertIn("Theme_one@1450,0", self.load().clusters(150))

    def test_clusters_are_largest_first(self):
        self.elements += [stroke("far2", 1560, 0, [[0, 0], [20, 20]]), stroke("far3", 1590, 0, [[0, 0], [20, 20]])]
        self.assertEqual(list(self.load().clusters(150)), ["Theme_one@1500,0", "M1@320,0"])

    def test_clusters_with_one_name_are_told_apart_by_their_strokes(self):
        ell = [stroke("a1", 500, 1100, [[0, 0], [600, 0]]), stroke("a2", 1100, 500, [[0, 0], [0, 600]])]
        dot = [stroke("b", 500, 500, [[0, 0], [20, 20]])]
        self.elements[4:] = ell + dot
        first = {cid: [s["id"] for s in c.strokes] for cid, c in self.load().clusters(150).items()}
        self.assertEqual(first, {"M1@500,500": ["a1", "a2"], "M1@500,500.2": ["b"]})
        self.elements[4:] = dot + ell[::-1]
        again = {cid: sorted(s["id"] for s in c.strokes) for cid, c in self.load().clusters(150).items()}
        self.assertEqual(again, first)

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
        self.assertIsNone(only.as_json("none@0,0")["attributed_to"])
        self.assertEqual(list(self.load().clusters(150)), ["none@0,0"])

    def frame(self, name, y, height):
        return dict(id=name, type="frame", name=name, x=0, y=y, width=1000, height=height, updated=EARLIER)

    def test_a_card_or_theme_holding_most_of_a_cluster_wins_over_a_nearer_one(self):
        inside = [stroke(f"in{k}", 2050 + 100 * k, 50, [[0, 0], [40, 40]]) for k in range(3)]
        self.elements[4:] = [stroke("reach", 290, 100, [[0, 0], [1720, 0]]), *inside]
        (only,) = self.load().clusters(150).values()
        self.assertEqual((only.target.kind, only.target.name, only.flags), ("theme", "Theme one", ()))

    def test_a_card_or_theme_holding_too_few_of_a_cluster_is_a_split(self):
        inside = [stroke(f"in{k}", 2050 + 100 * k, 50, [[0, 0], [40, 40]]) for k in range(2)]
        self.elements[4:] = [stroke("reach", 290, 100, [[0, 0], [1720, 0]]), *inside]
        (only,) = self.load().clusters(150).values()
        self.assertEqual(only.target.name, "Theme one")
        self.assertEqual([f.reason for f in only.flags], ["split"])

    def test_a_cluster_far_from_any_card_is_filed_under_its_section(self):
        self.elements[4:] = [self.frame("Paper", -500, 1000), stroke("lone", 5000, 0, [[0, 0], [50, 50]])]
        (only,) = self.load().clusters(150).values()
        self.assertEqual((only.target.kind, only.target.name, only.section.name), ("section", "Paper", "Paper"))
        self.assertEqual([f.reason for f in only.flags], ["far"])
        self.assertTrue(only.far)

    def test_a_cluster_far_from_any_card_and_outside_every_section_keeps_its_nearest(self):
        self.elements[4:] = [stroke("lone", 5000, 0, [[0, 0], [50, 50]])]
        (only,) = self.load().clusters(150).values()
        self.assertEqual((only.target.name, only.section), ("Theme one", None))
        self.assertEqual([f.reason for f in only.flags], ["far"])

    def test_a_cluster_whose_median_stroke_is_far_is_far_however_near_its_edge(self):
        crowd = [stroke(f"c{k}", 4000 + 60 * k, 300, [[0, 0], [40, 40]]) for k in range(3)]
        self.elements[4:] = [stroke("reach", 290, 300, [[0, 0], [3700, 0]]), *crowd]
        (only,) = self.load().clusters(150).values()
        self.assertEqual((only.target.name, only.distance), ("M1", 100))
        self.assertEqual([f.reason for f in only.flags], ["far"])

    def test_a_cluster_spread_wide_of_a_large_target_is_spread(self):
        self.elements[1].update(width=1000)
        crowd = [stroke(f"c{k}", 4700 + 60 * k, 0, [[0, 0], [40, 40]]) for k in range(3)]
        self.elements[4:] = [stroke("reach", 3010, 0, [[0, 0], [1700, 0]]), *crowd]
        (only,) = self.load().clusters(150).values()
        self.assertEqual(only.target.name, "Theme one")
        self.assertEqual([f.reason for f in only.flags], ["spread"])
        self.assertFalse(only.far)

    def test_a_cluster_about_as_near_another_target_is_crowded(self):
        self.elements[4:] = [stroke("mid", 1100, 0, [[0, 0], [50, 50]])]
        (only,) = self.load().clusters(150).values()
        self.assertEqual(only.target.name, "M1")
        self.assertEqual([str(f) for f in only.flags], ["crowded (also near theme:Theme one)"])

    def test_a_cluster_across_two_sections_spans_them(self):
        self.elements[4:] = [self.frame("Top", -100, 200), self.frame("Bottom", 150, 300),
                             stroke("a", 320, 0, [[0, 0], [40, 40]]), stroke("b", 320, 160, [[0, 0], [40, 40]])]
        (only,) = self.load().clusters(150).values()
        self.assertEqual(only.target.name, "M1")
        self.assertEqual([f.reason for f in only.flags], ["spans sections"])

    def test_an_untitled_theme_is_named_and_flagged(self):
        del self.elements[2]
        self.elements[3:] = [stroke("in", 2050, 50, [[0, 0], [40, 40]])]
        (cid, only), = self.load().clusters(150).items()
        self.assertEqual((cid, only.target.name), ("Untitled_theme@2050,50", "Untitled theme"))
        self.assertEqual([f.reason for f in only.flags], ["untitled theme rectangle"])

    def test_themes_with_one_title_are_told_apart(self):
        self.elements[4:] = [dict(self.elements[1], id="theme2", y=1000),
                             dict(self.elements[2], id="title2", y=1010),
                             stroke("a", 2050, 50, [[0, 0], [40, 40]]), stroke("b", 2050, 1050, [[0, 0], [40, 40]])]
        b = self.load()
        self.assertEqual([t.name for t in b.targets() if t.kind == "theme"], ["Theme one", "Theme one 2"])
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(sorted(f for f in os.listdir(out) if f.startswith("theme_")),
                         ["theme_Theme_one.png", "theme_Theme_one_2.png"])

    def test_clusters_prints_each_doubtful_call_and_every_section(self):
        self.elements += [self.frame("Paper", -500, 1000), stroke("lone", 5000, 0, [[0, 0], [50, 50]])]
        self.write()
        out = os.path.join(self.dir, "clusters.json")
        done = self.run_board("clusters", self.board, "--out", out)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("AMBIGUOUS Paper@5000,0: far (", done.stdout)
        self.assertEqual(done.stdout.count("AMBIGUOUS"), 1)
        with open(out, encoding="utf-8") as f:
            found = json.load(f)
        self.assertEqual([(c["section"], c["ambiguous"] != []) for c in found],
                         [("Paper", False), ("Paper", True), ("Paper", False)])

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
        self.assertIn("M1@320,0 card:M1 1/2 new", done.stdout)
        self.assertNotIn("Theme_one@", done.stdout)

    def test_since_by_time_says_it_goes_by_updated(self):
        self.write()
        done = self.run_board("since", self.board, str(EARLIER))
        self.assertIn("by `updated`", done.stdout)

    def test_snapshot_is_kept_under_the_boards_file_name(self):
        self.write()
        done = self.run_board("snapshot", self.board, "--state-dir", self.state)
        self.assertEqual(done.returncode, 0, done.stderr)
        (taken,) = os.listdir(os.path.join(self.state, "Prior art"))
        self.assertRegex(taken, r"^\d{4}-\d\d-\d\dT\d\d-\d\d-\d\d\.json$")
        with open(os.path.join(self.state, "Prior art", taken), encoding="utf-8") as f:
            kept = json.load(f)
        self.assertEqual(kept["elements"]["card"], dict(what="card:M1", x=0, y=0, width=300, height=200, text=None,
                                                        file="m1.jpg"))
        self.assertEqual(kept["strokes"], {"s1": [320, 0], "s2": [400, 0], "far": [1500, 0]})
        self.assertEqual([c["stroke_ids"] for c in kept["clusters"]], [["s1", "s2"], ["far"]])

    def test_snapshot_goes_to_the_state_dir_in_the_environment(self):
        self.write()
        env = dict(os.environ, DIAMOND_STATE_DIR=self.state)
        done = self.run_board("snapshot", self.board, env=env)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(len(os.listdir(os.path.join(self.state, "Prior art"))), 1)

    def test_since_without_a_snapshot_says_how_to_take_one(self):
        self.write()
        done = self.run_board("since", self.board, "--state-dir", self.state)
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("run `snapshot`", done.stderr)

    def test_since_an_unchanged_board_has_no_changes(self):
        self.snapshot()
        out = self.since_snapshot()
        self.assertIn("  no element changes\nstrokes: 0 added, 0 removed, 0 moved\n", out)

    def test_a_dragged_card_is_moved_and_nothing_else(self):
        self.snapshot()
        self.element("card").update(x=300, updated=LATER)
        self.assertIn("  MOVED card:M1 by (300,0)\nstrokes: 0 added", self.since_snapshot())

    def test_since_names_each_element_change(self):
        self.snapshot()
        self.element("theme").update(width=500)
        self.element("note").update(text="it's a new note")
        self.element("card").update(fileId=USER_FILE)
        self.files.append((USER_FILE, "m2.jpg"))
        self.elements.remove(self.element("title"))
        self.elements.append(dict(id="typed", type="text", text="typed", x=5, y=6, width=50, height=20, fontSize=20,
                                  updated=LATER))
        out = self.since_snapshot()
        self.assertIn("  RESIZED theme:Untitled theme 400x200 -> 500x200\n", out)
        self.assertIn("  TEXT text \"it's a new note\" was \"it's a \\\\ 100% note\"\n", out)
        self.assertIn("  FILE image:m2.jpg was m1.jpg\n", out)
        self.assertIn("  REMOVED text 'Theme one\\nits body' at [2010,10]\n", out)
        self.assertIn("  ADDED text 'typed' at [5,6]\n", out)

    def test_new_strokes_beside_a_card_count_under_their_current_cluster(self):
        self.snapshot()
        self.elements += [stroke("n1", 310, 150, [[0, 0], [40, 20]], updated=LATER),
                          stroke("n2", 380, 150, [[0, 0], [40, 20]], updated=LATER)]
        out = self.since_snapshot()
        self.assertIn("strokes: 2 added, 0 removed, 0 moved\n  M1@310,0 card:M1: 2 added (of 4 now)\n", out)

    def test_new_strokes_on_their_own_are_a_new_cluster(self):
        self.snapshot()
        self.elements.append(stroke("n1", 0, -300, [[0, 0], [40, 20]], updated=LATER))
        self.assertIn("  M1@0,-300 card:M1: 1 added (of 1 now)\n", self.since_snapshot())

    def test_a_removed_stroke_counts_under_what_is_left_of_its_cluster(self):
        self.snapshot()
        self.elements.remove(self.element("s1"))
        self.assertIn("  M1@400,0 card:M1: 1 removed (of 1 now)\n", self.since_snapshot())

    def test_a_cluster_removed_whole_is_named_as_it_was(self):
        self.snapshot()
        self.elements.remove(self.element("far"))
        self.assertIn("  1 removed with all of Theme_one@1500,0 theme:Theme one (its ID at the snapshot)\n",
                      self.since_snapshot())

    def test_a_moved_stroke_counts_under_the_cluster_it_is_in_now(self):
        self.snapshot()
        self.element("far").update(x=2100, y=50)
        self.assertIn("strokes: 0 added, 0 removed, 1 moved\n  Theme_one@2100,50 theme:Theme one: 1 moved (of 1 now)\n",
                      self.since_snapshot())

    def test_since_a_named_snapshot(self):
        self.snapshot("2000-01-01T00-00-00.json")
        self.element("card").update(x=300)
        self.snapshot()
        self.assertIn("no element changes", self.since_snapshot())
        out = self.since_snapshot("--snapshot", "2000-01-01T00:00")
        self.assertIn("since snapshot 2000-01-01T00-00-00,", out)
        self.assertIn("MOVED card:M1 by (300,0)", out)

    def test_since_a_time_and_a_snapshot_is_refused(self):
        self.write()
        done = self.run_board("since", self.board, str(EARLIER), "--snapshot", "2000", "--state-dir", self.state)
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("not both", done.stderr)

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
        self.assertEqual(sorted(os.listdir(out)), ["cluster_M1@320,0.png", "cluster_Theme_one@1500,0.png",
                                                   "overview.png", "theme_Theme_one.png"])

    def test_render_tiles_a_cluster_wider_than_a_tile_and_maps_them(self):
        self.elements[6] = stroke("far", 1500, 0, [[0, 0], [900, 50]])
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out, "--tile", "400", "--only", "Theme_one@1500,0")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(sorted(os.listdir(out)), ["cluster_Theme_one@1500,0_map.png",
                                                   *(f"cluster_Theme_one@1500,0_tile{k}of3.png" for k in (1, 2, 3))])

    def test_render_skips_a_tile_that_holds_no_strokes(self):
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out, "--tile", "400", "--only", "Theme_one@1500,0")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(os.listdir(out), ["cluster_Theme_one@1500,0.png"])

    def test_render_leaves_a_far_target_out_of_the_crop(self):
        self.elements[4:] = [stroke("lone", 5000, 0, [[0, 0], [50, 50]])]
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out, "--tile", "400")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("cluster_Theme_one@5000,0.png", os.listdir(out))

    def test_a_box_that_fits_one_tile_is_one_tile(self):
        self.assertEqual(tiles((10, 20, 3210, 1020), 3200), [(10, 20, 3210, 1020)])

    def test_a_wide_box_is_cut_into_equal_tiles_that_overlap(self):
        self.assertEqual(tiles((0, 0, 9000, 1000), 3200, overlap=150),
                         [(0, 0, 3075, 1000), (2925, 0, 6075, 1000), (5925, 0, 9000, 1000)])

    def test_tiles_run_row_by_row(self):
        self.assertEqual(tiles((0, 0, 4000, 4000), 3200, overlap=0),
                         [(0, 0, 2000, 2000), (2000, 0, 4000, 2000), (0, 2000, 2000, 4000), (2000, 2000, 4000, 4000)])

    def test_render_only_an_unknown_cluster_writes_nothing(self):
        self.write()
        out = os.path.join(self.dir, "crops")
        done = self.run_board("render", self.board, "--out", out, "--only", "M1@0,0")
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("M1@0,0", done.stderr)
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
