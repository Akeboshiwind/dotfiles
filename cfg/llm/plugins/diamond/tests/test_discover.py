"""discover's merge.py: python3 -m unittest discover -s cfg/llm/plugins/diamond/tests."""
import json, os, subprocess, sys, tempfile, unittest

SKILLS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills")
MERGE = os.path.join(SKILLS, "discover", "scripts", "merge.py")
sys.path.insert(0, os.path.join(SKILLS, "board-write", "scripts"))
import build_board


class Merge(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.work = tmp.name
        self.write("slices.json", [{"id": "M", "title": "Media apps", "note": "where things wait"},
                                   {"id": "P", "title": "Places"}])
        self.write("items/M.json", {"items": [
            {"id": "M1", "name": "Castro", "kind": "podcast app", "link": "https://example.com/castro",
             "sig": "Inbox, then queue", "use": "Triage apart from use"},
            {"id": "M2", "name": "Pocket", "kind": "read-later app", "link": "", "sig": "", "use": ""}],
            "top3": ["M1: triage"]})
        self.write("items/P.json", {"items": [{"id": "P1", "name": "Daunt Books", "kind": "bookshop",
                                               "link": "https://example.com/daunt", "sig": "By country",
                                               "use": "Shelve by place"}]})
        self.keep("M1", "img/m1-1.jpg", "Castro's Inbox")
        self.write("themes.json", [{"title": "Triage apart from use", "body": "Inbox, then queue.", "refs": ["M1", "P1"]}])

    def path(self, rel):
        return os.path.join(self.work, rel)

    def write(self, rel, data):
        os.makedirs(os.path.dirname(self.path(rel)), exist_ok=True)
        with open(self.path(rel), "w", encoding="utf-8") as f:
            f.write(data if isinstance(data, str) else json.dumps(data))

    def keep(self, item, file, caption):
        record = f"images/{item}.json"
        kept = self.read(record) if os.path.exists(self.path(record)) else {"id": item, "images": []}
        kept["images"].append({"file": file, "caption": caption, "source": "https://example.com"})
        self.write(record, kept)
        self.write(file, "jpeg")

    def read(self, rel):
        with open(self.path(rel), encoding="utf-8") as f:
            return json.load(f)

    def merge(self, *args):
        return subprocess.run([sys.executable, "-I", MERGE, self.work, "--title", "Prior art", *args],
                              capture_output=True, text=True)

    def assertRefused(self, run, *says):
        self.assertNotEqual(run.returncode, 0, run.stdout)
        for s in says:
            self.assertIn(s, run.stdout + run.stderr)
        self.assertFalse(os.path.exists(self.path("catalogue.json")))

    def test_builds_the_catalogue_in_slice_order_with_each_items_images(self):
        run = self.merge("--subtitle", "A first look")
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
        self.assertEqual(self.read("catalogue.json"), {
            "title": "Prior art", "subtitle": "A first look",
            "themes": [{"title": "Triage apart from use", "body": "Inbox, then queue.", "refs": ["M1", "P1"]}],
            "sections": [
                {"id": "M", "title": "Media apps", "note": "where things wait", "items": [
                    {"id": "M1", "name": "Castro", "kind": "podcast app", "link": "https://example.com/castro",
                     "sig": "Inbox, then queue", "use": "Triage apart from use",
                     "images": [{"file": "img/m1-1.jpg", "caption": "Castro's Inbox", "source": "https://example.com"}]},
                    {"id": "M2", "name": "Pocket", "kind": "read-later app", "link": "", "sig": "", "use": "",
                     "images": []}]},
                {"id": "P", "title": "Places", "note": "", "items": [
                    {"id": "P1", "name": "Daunt Books", "kind": "bookshop", "link": "https://example.com/daunt",
                     "sig": "By country", "use": "Shelve by place", "images": []}]}]})

    def test_board_write_accepts_the_catalogue_with_the_work_folder_as_its_root(self):
        self.merge()
        self.assertEqual(build_board.catalogue_errors(self.read("catalogue.json"), self.work), [])

    def test_reports_the_counts_and_the_items_without_images(self):
        self.assertEqual(self.merge().stdout.splitlines(),
                         ["2 sections, 3 items (1 with images), 1 themes", "without images: M2, P1"])

    def test_the_subtitle_is_left_to_board_write_when_not_given(self):
        self.merge()
        self.assertNotIn("subtitle", self.read("catalogue.json"))

    def test_optional_item_fields_default_to_empty(self):
        self.write("items/P.json", {"items": [{"id": "P1", "name": "Daunt Books"}]})
        self.merge()
        self.assertEqual(self.read("catalogue.json")["sections"][1]["items"],
                         [{"id": "P1", "name": "Daunt Books", "kind": "", "link": "", "sig": "", "use": "", "images": []}])

    def test_no_themes_file_means_no_themes(self):
        os.remove(self.path("themes.json"))
        self.assertEqual(self.merge().returncode, 0)
        self.assertEqual(self.read("catalogue.json")["themes"], [])

    def test_image_records_match_ids_exactly_so_a_padded_one_is_refused(self):
        self.keep("M02", "img/m02-1.jpg", "Pocket's list")
        self.assertRefused(self.merge(), "images/M02.json", "no item M02")

    def test_an_image_record_must_name_the_id_its_file_is_named_by(self):
        self.write("images/M2.json", {"id": "M1", "images": []})
        self.assertRefused(self.merge(), "images/M2.json", "'M1'")

    def test_a_missing_image_file_is_refused(self):
        os.remove(self.path("img/m1-1.jpg"))
        self.assertRefused(self.merge(), "img/m1-1.jpg")

    def test_a_slice_without_its_items_file_is_refused(self):
        os.remove(self.path("items/P.json"))
        self.assertRefused(self.merge(), "items/P.json")

    def test_an_item_outside_its_slices_prefix_is_refused(self):
        self.write("items/P.json", {"items": [{"id": "M3", "name": "Daunt Books"}, {"id": "PX1", "name": "Foyles"}]})
        self.assertRefused(self.merge(), "M3", "PX1")

    def test_a_duplicate_id_is_refused(self):
        self.write("items/P.json", {"items": [{"id": "P1", "name": "Daunt Books"}, {"id": "P1", "name": "Foyles"}]})
        self.assertRefused(self.merge(), "duplicate id P1")

    def test_an_item_without_a_name_is_refused(self):
        self.write("items/P.json", {"items": [{"id": "P1", "name": " "}]})
        self.assertRefused(self.merge(), "P1", "name")

    def test_a_theme_citing_an_unknown_id_is_refused(self):
        self.write("themes.json", [{"title": "Shelving", "body": "", "refs": ["P1", "P9"]}])
        self.assertRefused(self.merge(), "Shelving", "P9")

    def test_a_file_that_is_not_json_is_refused_by_name(self):
        self.write("items/M.json", "{not json")
        self.assertRefused(self.merge(), "items/M.json")

    def test_every_problem_is_reported_at_once(self):
        os.remove(self.path("items/P.json"))
        self.write("themes.json", [{"title": "Shelving", "body": "", "refs": ["M9"]}])
        self.assertRefused(self.merge(), "items/P.json", "M9")

    def test_a_refusal_leaves_an_earlier_catalogue_alone(self):
        self.merge()
        before = self.read("catalogue.json")
        os.remove(self.path("items/P.json"))
        self.assertNotEqual(self.merge().returncode, 0)
        self.assertEqual(self.read("catalogue.json"), before)


if __name__ == "__main__":
    unittest.main()
