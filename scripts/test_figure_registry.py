"""Small compatibility checks for stable paths and current printed numbers."""

from __future__ import annotations

import json
import csv
import hashlib
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

sys.dont_write_bytecode = True
import figure_packages as packages
from verify_figure_packages import (LAYOUT_FIELDS, PROHIBITED_TEXT, adjacent_file,
                                   check_screenshot_layout, script_reference_text)


class FigureRegistryTests(unittest.TestCase):
    def test_named_csv_package_keeps_existing_numeric_meanings(self):
        record = dict(figure="6.3", package="chapter06/selected_material_distribution",
                      kind="named_csv_plot", csv="selected_material_distribution.csv",
                      matlab="plot_material_distribution.m")
        fake_path = Mock()
        fake_path.read_text.return_value = json.dumps(dict(schema_version=1, figures=[record]))
        with patch.object(packages, "REGISTRY_PATH", fake_path):
            actual = packages.load_registry()["6.3"]
        self.assertIsNone(actual["legacy_id"])
        self.assertEqual(actual["scripts"], ("plot.py", "plot_material_distribution.m"))
        self.assertEqual(actual["inputs"], ("selected_material_distribution.csv",))
        for key, invalid in (("csv", "../private.csv"), ("csv", "data.json"),
                             ("matlab", "../plot.m"), ("matlab", "plot.m"),
                             ("extra_csv", ["../private.csv"]), ("extra_csv", "nodes.csv"),
                             ("extra_csv", ["nodes.csv", "nodes.csv"]),
                             ("extra_csv", ["selected_material_distribution.csv"])):
            fake_path.read_text.return_value = json.dumps(dict(schema_version=1, figures=[{**record, key: invalid}]))
            with self.subTest(key=key, invalid=invalid), patch.object(packages, "REGISTRY_PATH", fake_path):
                with self.assertRaises(ValueError):
                    packages.load_registry()
        fake_path.read_text.return_value = json.dumps(dict(schema_version=1,
            figures=[{**record, "extra_csv": ["nodes.csv", "elements.csv"]}]))
        with patch.object(packages, "REGISTRY_PATH", fake_path):
            actual = packages.load_registry()["6.3"]
        self.assertEqual(actual["inputs"], ("selected_material_distribution.csv", "nodes.csv", "elements.csv"))

    def test_registry_counts_and_kinds(self):
        self.assertEqual(len(packages.LEGACY_PACKAGES), 63)
        self.assertEqual(len(packages.CURRENT_PACKAGES), 68)
        shots = {key for key, value in packages.CURRENT_PACKAGES.items()
                 if value["kind"] == "screenshot_composition"}
        self.assertEqual(shots, {"5.2", "5.17", "6.2"})

    def test_insertion_boundaries(self):
        expected = {"5.1": "5.1", "5.3": "5.2", "5.16": "5.15",
                    "5.18": "5.16", "5.19": "5.17", "6.1": "6.1",
                    "6.4": "6.2", "6.11": "6.8"}
        for current, stable in expected.items():
            with self.subTest(current=current):
                self.assertEqual(packages.CURRENT_PACKAGES[current]["legacy_id"], stable)

    def test_legacy_bare_id_still_resolves_existing_files(self):
        for stable in packages.LEGACY_PACKAGES:
            csv_path, script_path, folder = packages.package_paths(stable)
            chapter, number = stable.split(".")
            self.assertEqual(folder.name, f"figure_{chapter}_{number}")
            self.assertEqual(csv_path.name, f"figure_{chapter}_{number}.csv")
            self.assertEqual(script_path.name, f"plot_{chapter}_{number}.py")
            self.assertTrue(csv_path.is_file())
            self.assertTrue(script_path.is_file())

    def test_current_lookup_is_explicit_and_different(self):
        legacy = packages.package_paths("5.2")
        current = packages.package_paths("5.2", current=True)
        self.assertEqual(legacy[2].name, "figure_5_2")
        self.assertEqual(current[2].name, "representative_topologies")
        self.assertEqual(current[0].name, "layout.csv")
        self.assertEqual(current[1].name, "compose.py")

    def test_unaffected_chapters_retain_numbers(self):
        for key, value in packages.CURRENT_PACKAGES.items():
            if key.split(".")[0] not in {"5", "6"}:
                self.assertEqual(key, value["legacy_id"])

    def test_reader_index_matches_registry(self):
        content = (packages.ROOT / "docs" / "FIGURE_DATA_MAP.md").read_text(encoding="utf-8")
        linked = dict(re.findall(r"\| \[([^\]]+)\]\(\.\./data/figures/([^)]+)\)", content))
        self.assertEqual(linked, {key: spec["package"] for key, spec in packages.CURRENT_PACKAGES.items()})

    def test_duplicate_or_unsafe_registry_rejected(self):
        baseline = json.loads(packages.REGISTRY_PATH.read_text(encoding="utf-8"))
        for mutation in ("duplicate", "path", "image"):
            document = json.loads(json.dumps(baseline))
            if mutation == "duplicate":
                document["figures"].append(document["figures"][0])
            elif mutation == "path":
                document["figures"][0]["package"] = "chapter02/../../outside"
            else:
                shot = next(item for item in document["figures"] if item["kind"] == "screenshot_composition")
                shot["images"] = ["../private.png"]
            fake_path = Mock()
            fake_path.read_text.return_value = json.dumps(document)
            with self.subTest(mutation=mutation), patch.object(packages, "REGISTRY_PATH", fake_path):
                with self.assertRaises(ValueError):
                    packages.load_registry()

    def test_screenshot_layout_guards(self):
        from PIL import Image

        with tempfile.TemporaryDirectory(prefix="thesis-figure-registry-test-") as temporary:
            folder = Path(temporary)
            image_path = folder / "test_native.png"
            Image.new("RGB", (4, 2), "white").save(image_path)
            digest = hashlib.sha256(image_path.read_bytes()).hexdigest()
            fields = sorted(LAYOUT_FIELDS)
            base_rows = [
                dict(figure="test_canvas.png", record_type="canvas", width_px=4, height_px=2),
                dict(figure="test_canvas.png", record_type="image", source_png="test_native.png",
                     x_px=0, y_px=0, width_px=4, height_px=2, source_crop_sha256=digest),
            ]
            spec = dict(folder=folder, primary="layout.csv", images=["test_native.png"])
            for mutation in (None, "outside", "stretch", "hash", "path", "scale", "fractional", "missing", "text"):
                rows = [dict(row) for row in base_rows]
                if mutation == "outside":
                    rows[1]["x_px"] = 1
                elif mutation == "stretch":
                    rows[1]["height_px"] = 0.5
                elif mutation == "hash":
                    rows[1]["source_crop_sha256"] = "0" * 64
                elif mutation == "path":
                    rows[1]["source_png"] = "../outside.png"
                elif mutation == "scale":
                    rows[1]["isotropic_scale_factor"] = 999
                elif mutation == "fractional":
                    rows[0]["width_px"] = 4.5
                elif mutation == "text":
                    rows.append(dict(figure="test_canvas.png", record_type="text", x_px="not-a-number", y_px=0, font_px=12))
                with (folder / "layout.csv").open("w", encoding="utf-8", newline="") as stream:
                    writer = csv.DictWriter(stream, fieldnames=[name for name in fields if mutation != "missing" or name != "font_px"])
                    writer.writeheader()
                    writer.writerows(rows)
                with self.subTest(mutation=mutation):
                    if mutation is None:
                        check_screenshot_layout(spec)
                    else:
                        with self.assertRaises(ValueError):
                            check_screenshot_layout(spec)

    def test_only_exact_svg_namespace_is_exempt(self):
        valid = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
        self.assertIsNone(PROHIBITED_TEXT.search(script_reference_text(valid, "screenshot_composition")))
        for url in ("http://www.w3.org/2000/svg/remote-input", "https://example.invalid/input.png"):
            self.assertIsNotNone(PROHIBITED_TEXT.search(script_reference_text('"' + url + '"', "screenshot_composition")))
        self.assertIsNotNone(PROHIBITED_TEXT.search(script_reference_text(valid, "csv_plot")))

    def test_resolved_input_must_stay_adjacent(self):
        with tempfile.TemporaryDirectory(prefix="thesis-figure-path-test-") as temporary:
            root = Path(temporary)
            folder = root / "package"
            folder.mkdir()
            (root / "outside.png").write_bytes(b"test fixture")
            with self.assertRaises(ValueError):
                adjacent_file(folder, "../outside.png")


if __name__ == "__main__":
    unittest.main()
