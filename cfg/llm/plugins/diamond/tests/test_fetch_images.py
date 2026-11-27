"""fetch-images: python3 -m unittest discover -s cfg/llm/plugins/diamond/tests (macOS: needs sips, and ImageMagick)."""
import http.server, json, os, subprocess, sys, tempfile, threading, unittest

SCRIPTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills", "fetch-images", "scripts")
HAS_SIPS = os.path.exists("/usr/bin/sips")


def image(path, size, fmt=None):
    subprocess.run(["magick", "-size", size, "xc:#88aacc", f"{fmt}:{path}" if fmt else path], check=True)
    return path


def sips_size(path):
    out = subprocess.run(["/usr/bin/sips", "-g", "pixelWidth", "-g", "pixelHeight", path],
                         capture_output=True, text=True, check=True).stdout
    return tuple(int(line.split(":")[1]) for line in out.splitlines() if "pixel" in line)


def tree(root):
    return sorted(os.path.relpath(os.path.join(d, n), root) for d, _, files in os.walk(root) for n in files)


class Temp(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.tmp = tmp.name


@unittest.skipUnless(HAS_SIPS, "keep.py converts with macOS sips")
class Keep(Temp):
    def setUp(self):
        super().setUp()
        self.out = os.path.join(self.tmp, "out")
        self.raw = image(os.path.join(self.tmp, "shot.png"), "1200x2400")

    def keep(self, item="M1", raw=None, caption="Castro's Inbox", source="https://example.com/castro", crop=None):
        return subprocess.run([sys.executable, "-I", os.path.join(SCRIPTS, "keep.py"), *(["--crop", crop] if crop else []),
                               self.out, item, raw or self.raw, caption, source], capture_output=True, text=True)

    def record(self, item="M1"):
        with open(os.path.join(self.out, "images", f"{item}.json"), encoding="utf-8") as f:
            return json.load(f)

    def test_the_record_is_named_by_the_exact_id_and_the_image_by_it_lowercased(self):
        self.assertEqual(self.keep().stdout.strip(), "img/m1-1.jpg")
        self.assertEqual(self.keep(caption=" Castro's Queue ").stdout.strip(), "img/m1-2.jpg")
        self.assertEqual(tree(self.out), ["images/M1.json", "img/m1-1.jpg", "img/m1-2.jpg"])
        self.assertEqual(self.record(), {"id": "M1", "images": [
            {"file": "img/m1-1.jpg", "caption": "Castro's Inbox", "source": "https://example.com/castro"},
            {"file": "img/m1-2.jpg", "caption": "Castro's Queue", "source": "https://example.com/castro"}]})

    def test_ids_that_differ_only_by_padding_stay_apart(self):
        self.keep("M1")
        self.keep("M01")
        self.assertEqual(tree(self.out), ["images/M01.json", "images/M1.json", "img/m01-1.jpg", "img/m1-1.jpg"])

    def test_a_large_image_is_shrunk_to_900_on_its_longest_side_as_a_jpeg(self):
        self.keep()
        path = os.path.join(self.out, "img", "m1-1.jpg")
        self.assertEqual(sips_size(path), (450, 900))
        with open(path, "rb") as f:
            self.assertEqual(f.read(3), b"\xff\xd8\xff")

    def test_a_small_image_is_not_enlarged(self):
        self.keep(raw=image(os.path.join(self.tmp, "small.webp"), "300x200"))
        self.assertEqual(sips_size(os.path.join(self.out, "img", "m1-1.jpg")), (300, 200))

    def halves(self):
        path = os.path.join(self.tmp, "wide.png")
        subprocess.run(["magick", "-size", "1000x1000", "xc:red", "-size", "1000x1000", "xc:blue", "+append", path],
                       check=True)
        return path

    def colours(self, *points):
        path = os.path.join(self.out, "img", "m1-1.jpg")
        fmt = " ".join(f"%[fx:p{{{x},{y}}}.r>0.5?1:0]%[fx:p{{{x},{y}}}.b>0.5?1:0]" for x, y in points)
        return subprocess.run(["magick", path, "-format", fmt, "info:"], capture_output=True, text=True,
                               check=True).stdout.split()

    def test_a_crop_keeps_that_part_in_source_pixels(self):
        self.assertEqual(self.keep(raw=self.halves(), crop="400x300+800+100").returncode, 0)
        self.assertEqual(sips_size(os.path.join(self.out, "img", "m1-1.jpg")), (400, 300))
        self.assertEqual(self.colours((10, 150), (190, 150), (210, 150), (390, 150)), ["10", "10", "01", "01"])

    def test_a_crop_on_the_left_edge_reaching_the_bottom_is_where_it_says(self):
        self.keep(raw=self.halves(), crop="1100x300+0+700")
        self.assertEqual(sips_size(os.path.join(self.out, "img", "m1-1.jpg")), (900, 245))
        self.assertEqual(self.colours((10, 100), (800, 100), (830, 100)), ["10", "10", "01"])

    def test_a_crop_is_taken_before_the_shrink(self):
        self.keep(raw=self.halves(), crop="1200x1000+0+0")
        self.assertEqual(sips_size(os.path.join(self.out, "img", "m1-1.jpg")), (900, 750))
        self.assertEqual(self.colours((10, 10), (740, 10), (760, 10)), ["10", "10", "01"])

    def test_refuses_a_bad_crop(self):
        for crop in ["400x300", "0x300+0+0", "400x300+-1+0", "400x300+0+0+0", "400 x300+0+0"]:
            self.assertRefused("crop", raw=self.halves(), crop=crop)

    def test_refuses_a_crop_outside_the_image(self):
        for crop in ["400x300+1601+0", "400x300+0+701", "2001x1+0+0"]:
            self.assertRefused("outside", raw=self.halves(), crop=crop)

    def test_refuses_a_fifth_image(self):
        for _ in range(4):
            self.assertEqual(self.keep().returncode, 0)
        before = tree(self.out)
        refused = self.keep()
        self.assertNotEqual(refused.returncode, 0)
        self.assertIn("4 images", refused.stderr)
        self.assertEqual(tree(self.out), before)
        self.assertEqual(len(self.record()["images"]), 4)

    def assertRefused(self, why, **kw):
        refused = self.keep(**kw)
        self.assertNotEqual(refused.returncode, 0)
        self.assertIn(why, refused.stderr)
        self.assertFalse(os.path.exists(self.out), "a refusal writes nothing")

    def test_refuses_an_empty_caption(self):
        for caption in ["", "  \n"]:
            self.assertRefused("caption", caption=caption)

    def test_refuses_a_source_that_isnt_http(self):
        for source in ["file:///etc/passwd", "javascript:alert(1)", "example.com/castro", "https://", "https://a b"]:
            self.assertRefused("source", source=source)

    def test_refuses_a_bad_id(self):
        for item in ["", "M", "1", "1M", "M1a", "m 1", "../M1", "M1/..", "M-1"]:
            self.assertRefused("bad id", item=item)

    def test_refuses_a_file_that_isnt_an_image(self):
        text = os.path.join(self.tmp, "page.png")
        with open(text, "w") as f:
            f.write("<html>not an image</html>")
        self.assertRefused("not an image", raw=text)

    def test_refuses_to_overwrite_an_image_its_record_doesnt_know(self):
        os.makedirs(os.path.join(self.out, "img"))
        stale = image(os.path.join(self.out, "img", "m1-1.jpg"), "10x10")
        refused = self.keep()
        self.assertNotEqual(refused.returncode, 0)
        self.assertIn("already exists", refused.stderr)
        self.assertEqual(tree(self.out), ["img/m1-1.jpg"])
        self.assertEqual(sips_size(stale), (10, 10))


class Server(http.server.ThreadingHTTPServer):
    """Serves `routes`: path -> list of (status, headers, body), one per request, the last repeating."""

    def __init__(self, routes):
        self.routes, self.hits = routes, []
        super().__init__(("127.0.0.1", 0), Handler)

    def url(self, path):
        return f"http://127.0.0.1:{self.server_address[1]}{path}"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.server.hits.append((self.path, self.headers.get("User-Agent")))
        replies = self.server.routes[self.path]
        status, headers, body = replies.pop(0) if len(replies) > 1 else replies[0]
        self.send_response(status)
        for k, v in headers.items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


class Download(Temp):
    def setUp(self):
        super().setUp()
        png = image(os.path.join(self.tmp, "a.png"), "40x30")
        with open(png, "rb") as f:
            self.png = f.read()
        self.raw = os.path.join(self.tmp, "raw", "M1")
        self.server = Server({})
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)

    def dl(self, *pairs):
        return subprocess.run(["bash", os.path.join(SCRIPTS, "dl.sh"), self.raw, *pairs],
                              capture_output=True, text=True, timeout=60)

    def serve(self, path, *replies):
        self.server.routes[path] = list(replies)
        return self.server.url(path)

    def test_names_the_file_by_its_sniffed_type_not_its_url(self):
        url = self.serve("/shot.jpg", (200, {"Content-Type": "image/jpeg"}, self.png))
        done = self.dl(f"a1={url}")
        self.assertEqual(done.returncode, 0, done.stdout)
        self.assertEqual(done.stdout.split(), ["ok", os.path.join(self.raw, "a1.png")])
        self.assertEqual(tree(self.raw), ["a1.png"])

    def test_sends_a_generic_user_agent(self):
        self.dl(f"a1={self.serve('/a', (200, {}, self.png))}")
        self.assertTrue(self.server.hits[0][1].startswith("Mozilla/5.0"), self.server.hits)

    def test_a_page_that_isnt_an_image_leaves_nothing(self):
        done = self.dl(f"a1={self.serve('/page', (200, {'Content-Type': 'image/png'}, b'<html>hi</html>'))}")
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("FAIL a1: not an image", done.stdout)
        self.assertEqual(tree(self.raw), [])

    def test_retries_a_429_after_its_retry_after(self):
        url = self.serve("/busy", (429, {"Retry-After": "1"}, b""), (200, {}, self.png))
        done = self.dl(f"a1={url}")
        self.assertIn("ok", done.stdout)
        self.assertEqual(len(self.server.hits), 2)

    def test_gives_up_on_a_5xx_after_three_tries(self):
        done = self.dl(f"a1={self.serve('/down', (503, {'Retry-After': '0'}, b''))}")
        self.assertIn("FAIL a1: http 503", done.stdout)
        self.assertEqual(len(self.server.hits), 3)
        self.assertEqual(tree(self.raw), [])

    def test_does_not_retry_a_404(self):
        done = self.dl(f"a1={self.serve('/gone', (404, {}, b''))}")
        self.assertIn("FAIL a1: http 404", done.stdout)
        self.assertEqual(len(self.server.hits), 1)

    def test_refuses_a_name_that_could_leave_the_raw_folder(self):
        url = self.serve("/a", (200, {}, self.png))
        for pair in [f"../a1={url}", f".a1={url}", f"={url}", "a1"]:
            done = self.dl(pair)
            self.assertIn("FAIL", done.stdout)
        self.assertEqual(self.server.hits, [])
        self.assertEqual(tree(os.path.dirname(self.raw)), [])

    def test_fetches_only_http(self):
        secret = image(os.path.join(self.tmp, "secret.png"), "10x10")
        done = self.dl(f"a1=file://{secret}")
        self.assertIn("FAIL a1", done.stdout)
        self.assertEqual(tree(self.raw), [])

    def test_one_failure_does_not_stop_the_rest(self):
        done = self.dl(f"a1={self.serve('/gone', (404, {}, b''))}", f"a2={self.serve('/a', (200, {}, self.png))}")
        self.assertNotEqual(done.returncode, 0)
        self.assertEqual(tree(self.raw), ["a2.png"])


@unittest.skipUnless(HAS_SIPS, "sheet.sh makes thumbnails with macOS sips")
class Sheet(Temp):
    def test_one_labelled_sheet_per_twenty_images_skipping_what_isnt_one(self):
        raw = os.path.join(self.tmp, "raw")
        os.makedirs(raw)
        for n in range(21):
            image(os.path.join(raw, f"a{n}.png"), "60x40")
        with open(os.path.join(raw, "junk.png"), "w") as f:
            f.write("not an image")
        sheets = os.path.join(self.tmp, "sheets")
        done = subprocess.run(["bash", os.path.join(SCRIPTS, "sheet.sh"), raw, sheets],
                              capture_output=True, text=True, timeout=120)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(done.stdout.split(), [os.path.join(sheets, "sheet-1.jpg"), os.path.join(sheets, "sheet-2.jpg")])
        self.assertIn("junk.png", done.stderr)
        self.assertEqual(tree(sheets), ["sheet-1.jpg", "sheet-2.jpg"])


if __name__ == "__main__":
    unittest.main()
