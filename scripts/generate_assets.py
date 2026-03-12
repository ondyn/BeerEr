#!/usr/bin/env python3
"""
generate_assets.py — BeerEr Flutter asset generator
=====================================================
Generates all required logo/icon/favicon assets from a single high-resolution
source image (1024×1024 recommended, SVG or PNG).

Usage
-----
    python3 scripts/generate_assets.py [--source <path>] [--dry-run]

Options
-------
    --source <path>   Path to the source image (default: assets/logo_source.png)
    --dry-run         Print what would be generated without writing any files

Dependencies
------------
    pip install Pillow cairosvg
    (cairosvg is only needed if the source file is an SVG)

Output
------
    iOS app icons     → ios/Runner/Assets.xcassets/AppIcon.appiconset/
    iOS launch images → ios/Runner/Assets.xcassets/LaunchImage.imageset/
    Android mipmaps   → android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/
    Android adaptive  → android/app/src/main/res/mipmap-{…}/ic_launcher_foreground.png
                        android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
    Flutter assets    → assets/images/  (logo + favicon sizes for web)
    Web favicon       → web/favicon.png  +  web/icons/
"""

import argparse
import os
import sys
import shutil
from pathlib import Path

# ---------------------------------------------------------------------------
# Third-party imports (checked at runtime so the error message is helpful)
# ---------------------------------------------------------------------------
try:
    from PIL import Image
except ImportError:
    sys.exit(
        "❌  Pillow is not installed. Run:  pip install Pillow"
    )


# ---------------------------------------------------------------------------
# Project root (one level above this script)
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent


# ---------------------------------------------------------------------------
# Asset specifications
# ---------------------------------------------------------------------------

# iOS AppIcon — all entries from Contents.json
IOS_APP_ICONS = [
    # filename,                  logical_size, scale
    ("Icon-App-20x20@1x.png",   20,  1),
    ("Icon-App-20x20@2x.png",   20,  2),
    ("Icon-App-20x20@3x.png",   20,  3),
    ("Icon-App-29x29@1x.png",   29,  1),
    ("Icon-App-29x29@2x.png",   29,  2),
    ("Icon-App-29x29@3x.png",   29,  3),
    ("Icon-App-40x40@1x.png",   40,  1),
    ("Icon-App-40x40@2x.png",   40,  2),
    ("Icon-App-40x40@3x.png",   40,  3),
    ("Icon-App-60x60@2x.png",   60,  2),
    ("Icon-App-60x60@3x.png",   60,  3),
    ("Icon-App-76x76@1x.png",   76,  1),
    ("Icon-App-76x76@2x.png",   76,  2),
    ("Icon-App-83.5x83.5@2x.png", 83, 2),   # rounded to 167 px
    ("Icon-App-1024x1024@1x.png", 1024, 1),
]

# iOS LaunchImage (plain white/transparent launch screen placeholder)
IOS_LAUNCH_IMAGES = [
    ("LaunchImage.png",    320,  480),
    ("LaunchImage@2x.png", 640,  960),
    ("LaunchImage@3x.png", 750, 1334),
]

# Android launcher icons (ic_launcher + ic_launcher_round)
#   density  →  size in px
ANDROID_DENSITIES = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}

# Adaptive icon foreground (same densities, but with 108dp safe-zone padding)
# Android adaptive icon canvas = 108dp; safe zone = 72dp → padding = 18 dp each side
# We keep 66 % of the image centred on the foreground layer.
ANDROID_ADAPTIVE_DENSITIES = {
    "mipmap-mdpi":    108,
    "mipmap-hdpi":    162,
    "mipmap-xhdpi":   216,
    "mipmap-xxhdpi":  324,
    "mipmap-xxxhdpi": 432,
}

# Flutter in-app assets (images/)
FLUTTER_LOGO_SIZES = [
    ("logo_48.png",   48),
    ("logo_96.png",   96),
    ("logo_192.png", 192),
    ("logo_512.png", 512),
]

# Web icons (PWA manifest + favicon)
WEB_ICON_SIZES = [
    ("Icon-192.png",  192),
    ("Icon-512.png",  512),
    ("Icon-maskable-192.png", 192),
    ("Icon-maskable-512.png", 512),
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_source(source_path: Path) -> Image.Image:
    """Load source image, handling SVG via cairosvg if needed."""
    suffix = source_path.suffix.lower()
    if suffix == ".svg":
        try:
            import cairosvg
            import io
            png_bytes = cairosvg.svg2png(
                url=str(source_path), output_width=1024, output_height=1024
            )
            img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
        except ImportError:
            sys.exit(
                "❌  cairosvg is required for SVG sources. Run:  pip install cairosvg"
            )
    else:
        img = Image.open(source_path).convert("RGBA")

    w, h = img.size
    if w < 512 or h < 512:
        print(
            f"⚠️   Source image is only {w}×{h}px. "
            "For best quality use a 1024×1024 (or larger) source."
        )
    return img


def resize(img: Image.Image, size: int, padding_ratio: float = 0.0) -> Image.Image:
    """
    Resize *img* to *size*×*size*.
    If padding_ratio > 0, the image is scaled to fit within the inner area
    (size * (1 - padding_ratio*2)) and placed on a transparent canvas.
    """
    if padding_ratio > 0:
        inner = int(size * (1 - padding_ratio * 2))
        inner = max(inner, 1)
        scaled = img.resize((inner, inner), Image.LANCZOS)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        offset = (size - inner) // 2
        canvas.paste(scaled, (offset, offset), scaled)
        return canvas
    return img.resize((size, size), Image.LANCZOS)


def save_png(img: Image.Image, dest: Path, dry_run: bool = False) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        print(f"  [dry-run] would write → {dest.relative_to(ROOT)}")
    else:
        img.save(dest, "PNG", optimize=True)
        print(f"  ✓  {dest.relative_to(ROOT)}")


def write_text(content: str, dest: Path, dry_run: bool = False) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        print(f"  [dry-run] would write → {dest.relative_to(ROOT)}")
    else:
        dest.write_text(content, encoding="utf-8")
        print(f"  ✓  {dest.relative_to(ROOT)}")


# ---------------------------------------------------------------------------
# Generation sections
# ---------------------------------------------------------------------------

def gen_ios_app_icons(img: Image.Image, dry_run: bool) -> None:
    print("\n📱  iOS — AppIcon")
    dest_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for filename, logical, scale in IOS_APP_ICONS:
        # Special case for the 83.5pt icon — pixel size is 167
        if "83.5" in filename:
            px = 167
        else:
            px = logical * scale
        resized = resize(img, px)
        save_png(resized, dest_dir / filename, dry_run)


def gen_ios_launch_images(img: Image.Image, dry_run: bool) -> None:
    print("\n📱  iOS — LaunchImage (centred logo on white background)")
    dest_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    for filename, w, h in IOS_LAUNCH_IMAGES:
        # White background with logo centred at ~25 % of the shorter dimension
        canvas = Image.new("RGBA", (w, h), (255, 255, 255, 255))
        logo_size = int(min(w, h) * 0.30)
        logo_size = max(logo_size, 1)
        scaled_logo = img.resize((logo_size, logo_size), Image.LANCZOS)
        ox = (w - logo_size) // 2
        oy = (h - logo_size) // 2
        canvas.paste(scaled_logo, (ox, oy), scaled_logo)
        save_png(canvas.convert("RGB"), dest_dir / filename, dry_run)


def gen_android_icons(img: Image.Image, dry_run: bool) -> None:
    print("\n🤖  Android — ic_launcher (square)")
    res_dir = ROOT / "android" / "app" / "src" / "main" / "res"
    for density, px in ANDROID_DENSITIES.items():
        resized = resize(img, px)
        dest_dir = res_dir / density
        save_png(resized, dest_dir / "ic_launcher.png", dry_run)
        save_png(resized, dest_dir / "ic_launcher_round.png", dry_run)

    print("\n🤖  Android — ic_launcher_foreground (adaptive, with safe-zone padding)")
    for density, px in ANDROID_ADAPTIVE_DENSITIES.items():
        # 16.67 % padding on each side keeps the logo within the safe zone
        resized = resize(img, px, padding_ratio=0.1667)
        dest_dir = res_dir / density
        save_png(resized, dest_dir / "ic_launcher_foreground.png", dry_run)

    # anydpi-v26 XML files
    print("\n🤖  Android — adaptive icon XML (anydpi-v26)")
    anydpi_dir = res_dir / "mipmap-anydpi-v26"

    ic_launcher_xml = """\
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    write_text(ic_launcher_xml, anydpi_dir / "ic_launcher.xml", dry_run)
    write_text(ic_launcher_xml.replace(
        "ic_launcher.xml", "ic_launcher_round.xml"
    ).replace(
        "</adaptive-icon>",
        "    <monochrome android:drawable=\"@mipmap/ic_launcher_foreground\"/>\n</adaptive-icon>"
    ), anydpi_dir / "ic_launcher_round.xml", dry_run)

    # Background colour resource (white by default — change to match brand colour)
    values_dir = res_dir / "values"
    ic_bg_colors_xml = """\
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Adaptive icon background colour — change to your brand colour -->
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
"""
    ic_bg_path = values_dir / "ic_launcher_background.xml"
    if not ic_bg_path.exists() or dry_run:
        write_text(ic_bg_colors_xml, ic_bg_path, dry_run)
    else:
        print(f"  ⏭   skipping (already exists): {ic_bg_path.relative_to(ROOT)}")


def gen_flutter_assets(img: Image.Image, dry_run: bool) -> None:
    print("\n🍺  Flutter in-app assets (assets/images/)")
    dest_dir = ROOT / "assets" / "images"
    for filename, px in FLUTTER_LOGO_SIZES:
        resized = resize(img, px)
        save_png(resized, dest_dir / filename, dry_run)

    # Also write logo.svg passthrough if source is SVG — handled below in main()


def gen_web_icons(img: Image.Image, dry_run: bool) -> None:
    web_dir = ROOT / "web"
    if not web_dir.exists():
        print("\n🌐  web/ directory not found — skipping web icons (not a web project)")
        return

    print("\n🌐  Web — favicon + PWA icons")
    save_png(resize(img, 16),  web_dir / "favicon.png", dry_run)

    icons_dir = web_dir / "icons"
    for filename, px in WEB_ICON_SIZES:
        save_png(resize(img, px), icons_dir / filename, dry_run)


def update_pubspec(dry_run: bool) -> None:
    """Ensure assets/images/ is declared in pubspec.yaml."""
    pubspec = ROOT / "pubspec.yaml"
    content = pubspec.read_text(encoding="utf-8")

    if "assets/images/" in content:
        print("\n📄  pubspec.yaml already declares assets/images/ — skipping")
        return

    print("\n📄  pubspec.yaml — adding assets/images/ declaration")
    old_block = "  generate: true  # enables AppLocalizations code generation"
    new_block = (
        "  generate: true  # enables AppLocalizations code generation\n\n"
        "  assets:\n"
        "    - assets/images/"
    )

    if old_block in content:
        new_content = content.replace(old_block, new_block)
        if dry_run:
            print(f"  [dry-run] would patch {pubspec.relative_to(ROOT)}")
        else:
            pubspec.write_text(new_content, encoding="utf-8")
            print(f"  ✓  patched {pubspec.relative_to(ROOT)}")
    else:
        print(
            "  ⚠️   Could not auto-patch pubspec.yaml — please add the following manually:\n\n"
            "  flutter:\n"
            "    assets:\n"
            "      - assets/images/\n"
        )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate all Flutter logo/icon/favicon assets from a single source image."
    )
    parser.add_argument(
        "--source",
        default=str(ROOT / "assets" / "logo_source.png"),
        help="Path to source image (PNG or SVG, 1024×1024 recommended). "
             "Default: assets/logo_source.png",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be generated without writing any files.",
    )
    args = parser.parse_args()

    source_path = Path(args.source).resolve()
    dry_run: bool = args.dry_run

    if not source_path.exists():
        sys.exit(
            f"❌  Source image not found: {source_path}\n"
            f"    Place your 1024×1024 logo at  assets/logo_source.png  "
            f"(or pass --source <path>)."
        )

    print(f"🖼   Source image : {source_path}")
    print(f"📁  Project root  : {ROOT}")
    if dry_run:
        print("🔍  DRY RUN — no files will be written\n")

    img = load_source(source_path)
    print(f"    Loaded {img.size[0]}×{img.size[1]}px RGBA image")

    # Also copy source SVG into assets/images/ if it is an SVG
    if source_path.suffix.lower() == ".svg":
        svg_dest = ROOT / "assets" / "images" / "logo.svg"
        if not dry_run:
            svg_dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, svg_dest)
            print(f"  ✓  copied SVG → {svg_dest.relative_to(ROOT)}")
        else:
            print(f"  [dry-run] would copy SVG → assets/images/logo.svg")

    gen_ios_app_icons(img, dry_run)
    gen_ios_launch_images(img, dry_run)
    gen_android_icons(img, dry_run)
    gen_flutter_assets(img, dry_run)
    gen_web_icons(img, dry_run)
    update_pubspec(dry_run)

    print("\n✅  Done!")
    if not dry_run:
        print(
            "\nNext steps:\n"
            "  1. Review generated icons and tweak the adaptive icon background\n"
            "     colour in android/app/src/main/res/values/ic_launcher_background.xml\n"
            "  2. Run:  .fvm/flutter_sdk/bin/flutter pub get\n"
            "  3. Rebuild the app to pick up the new icons.\n"
        )


if __name__ == "__main__":
    main()
