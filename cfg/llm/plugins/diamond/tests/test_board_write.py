"""board-write: python3 -m unittest discover -s cfg/llm/plugins/diamond/tests (needs ImageMagick)."""
import contextlib, io, json, os, subprocess, sys, tempfile, unittest
from unittest import mock

SCRIPTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills", "board-write", "scripts")
sys.path.insert(0, SCRIPTS)
import build_board


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def tree(root):
    return sorted(os.path.relpath(os.path.join(d, n), root)
                  for d, dirs, files in os.walk(root) for n in dirs + files)


class BoardWrite(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.vault = os.path.join(tmp.name, "vault")
        self.research = os.path.join(tmp.name, "research")
        os.makedirs(os.path.join(self.vault, "Excalidraw"))
        os.makedirs(os.path.join(self.research, "images"))
        for name, size in [("a.png", "300x200"), ("b.png", "200x300")]:
            subprocess.run(["magick", "-size", size, "xc:#88aacc", os.path.join(self.research, "images", name)], check=True)
        self.catalogue = {
            "title": "Prior art",
            "themes": [{"title": "Triage apart from use", "body": "Inbox, then queue.", "refs": ["M1"]}],
            "sections": [
                {"id": "M", "title": "Media apps", "note": "where things wait",
                 "items": [{"id": "M1", "name": "Castro", "kind": "app", "sig": "Inbox → Queue: 100% @triage",
                            "use": "Swipe to queue.", "link": "https://example.com/castro",
                            "images": [{"file": "images/a.png", "caption": "The inbox", "source": "https://example.com"},
                                       {"file": "images/b.png"}]},
                           {"id": "M2", "name": "Pocket"}]},
                {"title": "Paper", "items": [{"id": "P1", "name": "Index cards", "images": [{"file": "images/b.png"}]}]}]}
        self.board = os.path.join(self.vault, "Excalidraw", "Prior art.excalidraw.md")
        self.cards = os.path.join(self.vault, "Excalidraw", "Prior art cards")

    def build(self, board=None):
        path = os.path.join(self.research, "catalogue.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(self.catalogue, f)
        argv = ["build_board.py", path, "--board", board or self.board, "--vault", self.vault, "--root", self.research]
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(sys, "argv", argv), contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                build_board.main()
                code = 0
            except SystemExit as e:
                code = e.code if isinstance(e.code, int) else 1
                if isinstance(e.code, str):
                    err.write(e.code)
        return code, out.getvalue() + err.getvalue()

    def check(self):
        return subprocess.run([sys.executable, "-I", os.path.join(SCRIPTS, "check_board.py"), self.board, self.vault],
                              capture_output=True, text=True)

    def test_builds_a_board_whose_cards_sit_beside_it(self):
        code, out = self.build()
        self.assertEqual(code, 0, out)
        self.assertEqual(sorted(os.listdir(self.cards)), ["m1.jpg", "m2.jpg", "p1.jpg"])
        self.assertIn("[[Excalidraw/Prior art cards/m1.jpg]]", read(self.board))
        checked = self.check()
        self.assertEqual(checked.returncode, 0, checked.stdout)

    def test_leaves_no_staging_folder_behind(self):
        self.build()
        self.assertEqual(tree(self.vault), ["Excalidraw", "Excalidraw/Prior art cards",
                                            "Excalidraw/Prior art cards/m1.jpg", "Excalidraw/Prior art cards/m2.jpg",
                                            "Excalidraw/Prior art cards/p1.jpg", "Excalidraw/Prior art.excalidraw.md"])

    def test_creates_the_boards_folder_when_the_vault_has_none(self):
        board = os.path.join(self.vault, "Boards", "New.excalidraw.md")
        code, out = self.build(board)
        self.assertEqual(code, 0, out)
        self.assertTrue(os.path.isfile(board))

    def test_never_overwrites_a_board(self):
        with open(self.board, "w") as f:
            f.write("the user's drawings")
        before = tree(self.vault)
        code, out = self.build()
        self.assertNotEqual(code, 0)
        self.assertIn("exists", out)
        self.assertEqual(read(self.board), "the user's drawings")
        self.assertEqual(tree(self.vault), before)

    def test_never_writes_into_another_boards_cards(self):
        os.makedirs(self.cards)
        before = tree(self.vault)
        code, _ = self.build()
        self.assertNotEqual(code, 0)
        self.assertEqual(tree(self.vault), before)

    def test_a_second_build_is_refused(self):
        self.assertEqual(self.build()[0], 0)
        before = tree(self.vault)
        self.assertNotEqual(self.build()[0], 0)
        self.assertEqual(tree(self.vault), before)

    def test_a_missing_image_fails_before_anything_is_written(self):
        self.catalogue["sections"][1]["items"][0]["images"] = [{"file": "images/gone.png"}]
        before = tree(self.vault)
        code, out = self.build()
        self.assertNotEqual(code, 0)
        self.assertIn("images/gone.png", out)
        self.assertEqual(tree(self.vault), before)

    def test_ids_that_would_share_a_card_file_are_refused(self):
        self.catalogue["sections"][1]["items"].append({"id": "m1", "name": "Clash"})
        before = tree(self.vault)
        code, out = self.build()
        self.assertNotEqual(code, 0)
        self.assertIn("m1.jpg", out)
        self.assertEqual(tree(self.vault), before)

    def test_a_board_that_fails_its_check_is_not_published(self):
        before = tree(self.vault)
        with mock.patch.object(build_board.check_board, "problems", return_value=["frames overlap: A / B"]):
            code, out = self.build()
        self.assertNotEqual(code, 0)
        self.assertIn("frames overlap", out)
        self.assertEqual(tree(self.vault), before)

    def test_a_render_that_fails_leaves_nothing_behind(self):
        before = tree(self.vault)
        failing = subprocess.CalledProcessError(1, ["magick"])
        with mock.patch.object(build_board.render_cards, "render", side_effect=failing):
            code, _ = self.build()
        self.assertNotEqual(code, 0)
        self.assertEqual(tree(self.vault), before)

    def test_board_must_sit_inside_the_vault(self):
        code, out = self.build(os.path.join(self.research, "Elsewhere.excalidraw.md"))
        self.assertNotEqual(code, 0)
        self.assertIn("inside", out)


if __name__ == "__main__":
    unittest.main()
