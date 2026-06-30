import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from imgdeck import ImageProcessor


class ImageProcessorTests(unittest.TestCase):
    def test_a4_pixel_size_supports_dpi_and_dpcm(self):
        self.assertEqual(ImageProcessor.a4_pixel_size(72, "dpi"), (595, 842))
        self.assertEqual(ImageProcessor.a4_pixel_size(72, "dpcm"), (1512, 2138))

    def test_layout_keeps_unused_cells_white(self):
        image = np.full((877, 620, 3), 40, dtype=np.uint8)

        result = ImageProcessor.page_layout([image], rows=2, cols=2)

        self.assertEqual(result.shape, (1754, 1240, 3))
        self.assertTrue(np.all(result[:877, :620] == 40))
        self.assertTrue(np.all(result[:877, 620:] == 255))
        self.assertTrue(np.all(result[877:, :] == 255))

    def test_layout_shows_complete_image_without_cropping(self):
        image = np.full((10, 20, 3), 20, dtype=np.uint8)
        image[:, 10:] = 200

        result = ImageProcessor.page_layout([image], rows=1, cols=1)

        self.assertTrue(np.all(result[0, :] == 255))
        self.assertTrue(np.all(result[877, 100] == 20))
        self.assertTrue(np.all(result[877, -100] == 200))

    def test_one_cell_uses_only_first_image(self):
        first = np.full((10, 10, 3), 30, dtype=np.uint8)
        second = np.full((10, 10, 3), 220, dtype=np.uint8)

        result = ImageProcessor.page_layout([first, second], rows=1, cols=1)

        self.assertFalse(np.any(result == 220))
        self.assertTrue(np.any(result == 30))

    def test_layout_supports_nine_images(self):
        images = [np.full((10, 10, 3), value, dtype=np.uint8) for value in range(9)]

        result = ImageProcessor.page_layout(images, rows=3, cols=3)

        self.assertEqual(result.shape, (1754, 1240, 3))
        self.assertTrue(np.all(result[100, 100] == 0))
        self.assertTrue(np.all(result[-100, -100] == 8))

    def test_saves_png_and_jpg(self):
        image = np.full((50, 50, 3), 100, dtype=np.uint8)
        with tempfile.TemporaryDirectory() as directory:
            png_path = Path(directory) / "result.png"
            jpg_path = Path(directory) / "result.jpg"

            self.assertTrue(ImageProcessor.save_image(image, str(png_path)))
            self.assertTrue(ImageProcessor.save_image(image, str(jpg_path)))
            self.assertGreater(png_path.stat().st_size, 0)
            self.assertGreater(jpg_path.stat().st_size, 0)


if __name__ == "__main__":
    unittest.main()
