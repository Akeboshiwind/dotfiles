"""review's coverage.py: python3 -m unittest discover -s cfg/llm/plugins/diamond/tests."""
import json, os, subprocess, sys, tempfile, unittest

COVERAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills", "review", "scripts", "coverage.py")


def cluster(cid, strokes=10, ambiguous=()):
    return dict(id=cid, strokes=strokes, stroke_ids=[f"{cid}-{k}" for k in range(strokes)], ambiguous=list(ambiguous))


class Coverage(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.dir = tmp.name

    def check(self, clusters, transcript, *args):
        cj, tr = os.path.join(self.dir, "clusters.json"), os.path.join(self.dir, "transcript.md")
        with open(cj, "w", encoding="utf-8") as f:
            json.dump(clusters, f)
        with open(tr, "w", encoding="utf-8") as f:
            f.write(transcript)
        return subprocess.run([sys.executable, "-I", COVERAGE, cj, tr, *args], capture_output=True, text=True)

    def assertPasses(self, run):
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def assertFails(self, run, *says):
        self.assertEqual(run.returncode, 1, run.stdout + run.stderr)
        for s in says:
            self.assertIn(s, run.stdout)

    def test_passes_when_every_cluster_has_a_section_and_keeps_its_flag(self):
        run = self.check([cluster("K5@10,20"), cluster("Untitled_theme@-30,40", ambiguous=["untitled theme rectangle"])],
                         "# Notebooks\n\n## K5@10,20 (card:K5)\n- Use SQL\n  - L> Simple user DSL\n\n"
                         "# Themes\n\n## Untitled_theme@-30,40\n- I like this!\n\n"
                         "AMBIGUOUS: untitled theme rectangle. My view: it's about P1.\n")
        self.assertPasses(run)
        self.assertIn("coverage: ok", run.stdout)

    def test_fails_on_a_cluster_with_no_section(self):
        self.assertFails(self.check([cluster("K5@10,20"), cluster("K8@0,0")], "## K5@10,20\n- Use SQL\n"),
                         "MISSING K8@0,0")

    def test_a_heading_with_nothing_under_it_is_missing(self):
        self.assertFails(self.check([cluster("K5@10,20"), cluster("K8@0,0")],
                                    "## K5@10,20\n\n## K8@0,0\n- Use SQL\n"), "MISSING K5@10,20")

    def test_an_id_that_only_prefixes_a_heading_does_not_cover_it(self):
        self.assertFails(self.check([cluster("K5@10,20"), cluster("K5@10,20.2")], "## K5@10,20.2\n- Use SQL\n"),
                         "MISSING K5@10,20:")

    def test_an_id_mentioned_in_a_body_does_not_cover_it(self):
        self.assertFails(self.check([cluster("K5@10,20"), cluster("K8@0,0")],
                                    "## K8@0,0\n- see K5@10,20\n"), "MISSING K5@10,20")

    def test_fails_on_a_dropped_ambiguous_flag(self):
        self.assertFails(self.check([cluster("G15@0,0", ambiguous=["crowded (also near card:P4)"])],
                                    "## G15@0,0\n- record shop\n"), "LAUNDERED G15@0,0")

    def test_a_flag_in_the_next_section_does_not_count(self):
        self.assertFails(self.check([cluster("G15@0,0", ambiguous=["far"]), cluster("P1@5,5", ambiguous=["far"])],
                                    "## G15@0,0\n- record shop\n\n## P1@5,5\n- fully private\nAMBIGUOUS: far\n"),
                         "LAUNDERED G15@0,0")

    def test_a_subheading_stays_in_its_clusters_section(self):
        self.assertPasses(self.check([cluster("G15@0,0", ambiguous=["far"])],
                                     "## G15@0,0\n- record shop\n### Flags\nAMBIGUOUS: far\n"))

    def test_a_cluster_filed_twice_is_covered_by_either_section(self):
        self.assertPasses(self.check([cluster("G15@0,0", ambiguous=["far"])],
                                     "# G15\n## G15@0,0\n- record shop\n# P4\n## G15@0,0 (also)\nAMBIGUOUS: far\n"))

    def test_warns_but_passes_on_a_large_cluster_with_no_unreadable_word(self):
        run = self.check([cluster("G15@0,0", strokes=100), cluster("K8@0,0", strokes=99)],
                         "## G15@0,0\n- record shop\n\n## K8@0,0\n- Use SQL\n")
        self.assertPasses(run)
        self.assertIn("SUSPECT G15@0,0", run.stdout)
        self.assertNotIn("K8@0,0", run.stdout)

    def test_an_unreadable_word_quiets_the_warning(self):
        run = self.check([cluster("G15@0,0", strokes=500)], "## G15@0,0\n- record [?] shop\n")
        self.assertPasses(run)
        self.assertNotIn("SUSPECT", run.stdout)

    def test_only_checks_the_clusters_named(self):
        clusters = [cluster("K5@10,20"), cluster("K8@0,0")]
        self.assertPasses(self.check(clusters, "## K8@0,0\n- new note\n", "--only", "K8@0,0"))
        self.assertFails(self.check(clusters, "## K8@0,0\n- new note\n", "--only", "K5@10,20"), "MISSING K5@10,20")

    def test_refuses_an_unknown_id_in_only(self):
        run = self.check([cluster("K5@10,20")], "## K5@10,20\n- x\n", "--only", "K5@10,21")
        self.assertEqual(run.returncode, 2)
        self.assertIn("K5@10,21", run.stderr)

    def test_refuses_clusters_json_that_is_not_board_reads(self):
        run = self.check({"clusters": [cluster("K5@10,20")]}, "## K5@10,20\n- x\n")
        self.assertEqual(run.returncode, 2)
        self.assertIn("clusters --out", run.stderr)


if __name__ == "__main__":
    unittest.main()
