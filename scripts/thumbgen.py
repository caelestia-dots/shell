#!/usr/bin/env python3
"""
Thumbnail Generator for Caelestia.

Generates 280x158-crop JPG thumbnails for every media file the Wallpapers
service finds in its configured directory tree. Both still images and
video/GIF sources go through this script so the picker can render
thumbnails for everything without depending on the C++ imagecacher
having ffmpeg built into it.

Cache layout mirrors wallsdir:
  <wallsdir>/foo/bar.mp4  ->  <cache>/wallpaper-thumbs/foo/bar.mp4.jpg

Requires ffmpeg (videos and gifs) and ImageMagick (images). Missing tools
cause the affected file types to be skipped; other types still process.
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import List, Optional, Tuple

VIDEO_EXTENSIONS = {".mp4", ".webm", ".mov", ".avi", ".mkv"}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff", ".bmp", ".svg"}
GIF_EXTENSIONS = {".gif"}

THUMB_W, THUMB_H = 280, 158  # matches Tokens.sizes.launcher.wallpaperWidth / 16 * 9


class ThumbGenerator:
    def __init__(self, wallsdir: Path, cache_root: Path, fallback: Optional[Path] = None):
        self.wallsdir = wallsdir
        self.cache_root = cache_root
        self.fallback = fallback
        self.thumbs_dir = cache_root / "wallpaper-thumbs"
        self.processed = 0
        self.total = 0
        self.lock = threading.Lock()
        self._have_im7: Optional[bool] = None
        self._have_ffmpeg: Optional[bool] = None

    def run(self) -> int:
        scan_dir = self.wallsdir
        if not scan_dir.exists() and self.fallback is not None:
            scan_dir = self.fallback
            print(f"wallsdir not found, using fallback: {self.fallback}")
        if not scan_dir.exists():
            print(f"ERROR: Wallpaper directory not found: {self.wallsdir}")
            return 1

        self.wallsdir = scan_dir.resolve()
        self.thumbs_dir.mkdir(parents=True, exist_ok=True)

        self._have_im7 = self._check_imagemagick()
        self._have_ffmpeg = self._check_ffmpeg()

        print(f"Source: {self.wallsdir}")
        print(f"Cache:  {self.thumbs_dir}")
        print(f"ffmpeg: {'yes' if self._have_ffmpeg else 'no (videos/gifs will be skipped)'}")
        print(f"ImageMagick: {'yes' if self._have_im7 else 'no (images will be skipped)'}")

        files = self.find_files()
        if not files:
            print("No media files found")
            return 0

        self.total = len(files)
        pending = [p for p in files if self.needs_generation(p)]
        self.total = len(pending) or self.total
        if not pending:
            print(f"All {len(files)} thumbnails are up to date")
            return 0

        print(f"Need to generate {len(pending)} thumbnails (out of {len(files)} files)")

        max_workers = min(4, os.cpu_count() or 1, len(pending))
        failed: List[Tuple[Path, str]] = []
        with ThreadPoolExecutor(max_workers=max_workers) as ex:
            futures = {ex.submit(self.generate, p): p for p in pending}
            for fut in as_completed(futures):
                src = futures[fut]
                try:
                    ok, msg = fut.result()
                except Exception as exc:
                    ok, msg = False, str(exc)
                if not ok:
                    failed.append((src, msg))

        print(f"Done — {len(pending) - len(failed)}/{len(pending)} generated")
        if failed:
            print(f"Failed: {len(failed)}")
            for src, msg in failed[:3]:
                print(f"  {src.name}: {msg[:80]}")
        return 0

    def find_files(self) -> List[Path]:
        out: List[Path] = []
        try:
            for p in self.wallsdir.rglob("*"):
                if not p.is_file() or p.name.startswith("."):
                    continue
                try:
                    parents = p.relative_to(self.wallsdir).parts[:-1]
                except ValueError:
                    continue
                if any(part.startswith(".") for part in parents):
                    continue
                ext = p.suffix.lower()
                if ext in VIDEO_EXTENSIONS or ext in IMAGE_EXTENSIONS or ext in GIF_EXTENSIONS:
                    out.append(p)
        except Exception as exc:
            print(f"ERROR scanning {self.wallsdir}: {exc}")
        out.sort()
        return out

    def thumb_path(self, src: Path) -> Path:
        rel = src.relative_to(self.wallsdir)
        return self.thumbs_dir / rel.parent / (src.name + ".jpg")

    def needs_generation(self, src: Path) -> bool:
        dst = self.thumb_path(src)
        if not dst.exists():
            return True
        try:
            return src.stat().st_mtime > dst.stat().st_mtime
        except OSError:
            return True

    def generate(self, src: Path) -> Tuple[bool, str]:
        dst = self.thumb_path(src)
        ext = src.suffix.lower()

        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            if ext in VIDEO_EXTENSIONS or ext in GIF_EXTENSIONS:
                ok = self._have_ffmpeg and self.run_ffmpeg(src, dst)
                kind = "video" if ext in VIDEO_EXTENSIONS else "gif"
            else:
                ok = self._have_im7 and self.run_imagemagick(src, dst)
                kind = "image"

            with self.lock:
                self.processed += 1
                pct = (self.processed / self.total * 100) if self.total else 100
                tag = "ok" if ok else "skip"
                print(f"[{self.processed}/{self.total}] {kind} {tag}: {src.name} ({pct:.0f}%)")
            return ok, "ok" if ok else "tool-unavailable-or-failed"
        except Exception as exc:
            return False, str(exc)[:80]

    def run_ffmpeg(self, src: Path, dst: Path) -> bool:
        cmd = [
            "ffmpeg", "-y",
            "-loglevel", "error",
            "-ss", "00:00:00.100",
            "-i", str(src),
            "-vframes", "1",
            "-vf", (
                f"scale={THUMB_W}:{THUMB_H}:force_original_aspect_ratio=increase,"
                f"crop={THUMB_W}:{THUMB_H}"
            ),
            "-q:v", "2",
            str(dst),
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            return result.returncode == 0 and dst.exists()
        except subprocess.TimeoutExpired:
            return False

    def run_imagemagick(self, src: Path, dst: Path) -> bool:
        im_cmd = "magick" if self._have_im7 else "convert"
        cmd = [
            im_cmd, str(src),
            "-resize", f"{THUMB_W}x{THUMB_H}^",
            "-gravity", "center",
            "-extent", f"{THUMB_W}x{THUMB_H}",
            "-quality", "85",
            str(dst),
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            return result.returncode == 0 and dst.exists()
        except subprocess.TimeoutExpired:
            return False

    def _check_imagemagick(self) -> bool:
        for cmd in (["magick", "--version"], ["convert", "--version"]):
            try:
                if subprocess.run(cmd, capture_output=True, timeout=5).returncode == 0:
                    self._have_im7 = (cmd[0] == "magick")
                    return True
            except (FileNotFoundError, subprocess.TimeoutExpired):
                continue
        return False

    def _check_ffmpeg(self) -> bool:
        try:
            return subprocess.run(
                ["ffmpeg", "-version"], capture_output=True, timeout=5
            ).returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False


def parse_args(argv: List[str]) -> Tuple[Path, Path, Optional[Path]]:
    if len(argv) < 3 or len(argv) > 4:
        print("Usage: thumbgen.py <wallsdir> <cache_root> [fallback_wallsdir]")
        sys.exit(1)
    return (
        Path(argv[1]).expanduser(),
        Path(argv[2]).expanduser(),
        Path(argv[3]).expanduser() if len(argv) == 4 else None,
    )


def main() -> int:
    wallsdir, cache_root, fallback = parse_args(sys.argv)
    gen = ThumbGenerator(wallsdir, cache_root, fallback)
    return gen.run()


if __name__ == "__main__":
    sys.exit(main())
