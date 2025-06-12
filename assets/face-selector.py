#!/usr/bin/env python3

import os
import shutil
import subprocess
from pathlib import Path
from PyQt5.QtWidgets import QApplication, QFileDialog

def generate_thumbnails(image_path: str, cache_dir: str):
    sizes = [
        (93, 93),
    ]

    for width, height in sizes:
        output_filename = f"@{width}x{height}-exact.png"
        output_path = os.path.join(cache_dir, output_filename)

        cmd = [
            "magick", "convert",
            image_path,
            "-thumbnail", f"{width}x{height}^",
            "-gravity", "center",
            "-extent", f"{width}x{height}",
            output_path
        ]

        try:
            subprocess.run(cmd, check=True)
            print(f"Generated: {output_path}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to generate thumbnail: {e}")

def select_face_image():
    app = QApplication([])

    home = str(Path.home())
    file_path, _ = QFileDialog.getOpenFileName(
        None,
        "Select New Avatar",
        home,
        "Images (*.png *.jpg *.jpeg *.bmp *.webp)"
    )

    if file_path:
        dest = os.path.join(home, ".face")
        shutil.copyfile(file_path, dest)
        print(f"Avatar updated: {dest}")

        thumbnail_dir = os.path.join(home, ".cache", "caelestia", "thumbnails")
        os.makedirs(thumbnail_dir, exist_ok=True)

        for thumb in os.listdir(thumbnail_dir):
            if thumb.endswith("-exact.png"):
                try:
                    os.remove(os.path.join(thumbnail_dir, thumb))
                    print(f"Deleted: {thumb}")
                except Exception:
                    pass

        generate_thumbnails(dest, thumbnail_dir)

    app.quit()

if __name__ == "__main__":
    select_face_image()
