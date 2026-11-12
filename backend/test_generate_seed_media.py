import tempfile
import unittest
from pathlib import Path

from PIL import Image

from generate_seed_media import (
    DEFAULT_OUTPUT_DIR,
    SEED_MEDIA,
    UPLOAD_DIR,
    generate_seed_media,
    validate_output_directory,
)


class GenerateSeedMediaTest(unittest.TestCase):
    def test_default_output_is_not_the_upload_directory(self):
        self.assertNotEqual(DEFAULT_OUTPUT_DIR.resolve(), UPLOAD_DIR.resolve())

    def test_upload_directory_requires_explicit_opt_in(self):
        output_dir = UPLOAD_DIR / "isolated-test-output"
        with self.assertRaisesRegex(ValueError, "inside backend/uploads"):
            validate_output_directory(output_dir)
        self.assertEqual(
            validate_output_directory(output_dir, allow_uploads=True),
            output_dir.resolve(),
        )

    def test_generates_seed_compatible_images_with_visible_watermarks(self):
        with tempfile.TemporaryDirectory(prefix="epupuk-seed-media-") as temp_dir:
            output_dir = Path(temp_dir)
            generate_seed_media(output_dir)

            expected_files = {
                output_dir / category / filename
                for category, filename in SEED_MEDIA
            }
            self.assertEqual(set(output_dir.rglob("*.jpg")), expected_files)

            for image_path in expected_files:
                with Image.open(image_path) as image:
                    self.assertEqual(image.format, "JPEG")
                    pixels = image.convert("RGB")
                    self.assertGreater(
                        sum(
                            1
                            for red, green, blue in pixels.getdata()
                            if red > 150 and green < 80 and blue < 80
                        ),
                        10_000,
                    )

    def test_refuses_to_overwrite_an_existing_seed_asset(self):
        with tempfile.TemporaryDirectory(prefix="epupuk-seed-media-") as temp_dir:
            output_dir = Path(temp_dir)
            existing_file = output_dir / "ktp" / "sample_ktp_budi.jpg"
            existing_file.parent.mkdir(parents=True)
            existing_file.write_bytes(b"keep existing content")

            with self.assertRaisesRegex(FileExistsError, "Refusing to overwrite"):
                generate_seed_media(output_dir)

            self.assertEqual(existing_file.read_bytes(), b"keep existing content")


if __name__ == "__main__":
    unittest.main()
