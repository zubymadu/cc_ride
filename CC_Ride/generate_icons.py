"""
CC Ride — App Icon Generator
Draws the app icon programmatically with Pillow (no Cairo / SVG parsing needed).

Icon design:
  • Royal blue (#0047FF) background
  • Rounded-rect shape (squircle-ish via pillow)
  • Large white "CC" centred upper area
  • Bold "RIDE" in a white strip at the bottom
  • Simple white car silhouette between CC and RIDE

Run:  python generate_icons.py
Outputs icons to the correct Flutter / store directories.
"""

import os, math
from PIL import Image, ImageDraw, ImageFont

# ── Brand colours ──────────────────────────────────────────────────────────────
BLUE   = (0, 71, 255)      # #0047FF  primary
DBLUE  = (0, 26, 128)      # #001A80  deep navy (gradient stop)
WHITE  = (255, 255, 255)
STRIP  = (0, 58, 204)      # #003ACC  strip background (slightly darker blue)

# ── Output size map ────────────────────────────────────────────────────────────
SIZES = {
    # Store / master
    "icon_1024.png": 1024,
    "icon_512.png":  512,

    # Android mipmap
    "android/mipmap-mdpi/ic_launcher.png":    48,
    "android/mipmap-hdpi/ic_launcher.png":    72,
    "android/mipmap-xhdpi/ic_launcher.png":   96,
    "android/mipmap-xxhdpi/ic_launcher.png":  144,
    "android/mipmap-xxxhdpi/ic_launcher.png": 192,

    # iOS AppIcon (no rounded corners — iOS applies mask itself)
    "ios/AppIcon-20.png":    20,
    "ios/AppIcon-29.png":    29,
    "ios/AppIcon-40.png":    40,
    "ios/AppIcon-60.png":    60,
    "ios/AppIcon-76.png":    76,
    "ios/AppIcon-83.png":    83,
    "ios/AppIcon-1024.png":  1024,
}

ANDROID_DIRS = [
    "android/mipmap-mdpi", "android/mipmap-hdpi",
    "android/mipmap-xhdpi", "android/mipmap-xxhdpi", "android/mipmap-xxxhdpi",
]
IOS_DIR = "ios"

# Output base — same folder as this script
BASE = os.path.dirname(os.path.abspath(__file__))
OUT  = os.path.join(BASE, "generated_icons")


def ensure_dirs():
    os.makedirs(OUT, exist_ok=True)
    for d in ANDROID_DIRS:
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    os.makedirs(os.path.join(OUT, IOS_DIR), exist_ok=True)


def draw_car(draw: ImageDraw.ImageDraw, cx: float, cy: float, w: float, color):
    """Draw a simple side-view car silhouette centred at (cx, cy) with width w."""
    h = w * 0.45
    # Body
    body_pts = [
        (cx - w/2,       cy + h*0.1),
        (cx - w*0.35,    cy - h*0.45),
        (cx - w*0.05,    cy - h*0.9),
        (cx + w*0.25,    cy - h*0.9),
        (cx + w*0.45,    cy - h*0.45),
        (cx + w/2,       cy + h*0.1),
    ]
    draw.polygon(body_pts, fill=color)

    # Roof cabin (slightly lighter shade for definition at large sizes)
    roof_pts = [
        (cx - w*0.28, cy - h*0.45),
        (cx - w*0.05, cy - h*0.88),
        (cx + w*0.22, cy - h*0.88),
        (cx + w*0.42, cy - h*0.45),
    ]
    draw.polygon(roof_pts, fill=color)

    # Wheels
    wr = w * 0.12
    for wx in [cx - w*0.28, cx + w*0.28]:
        draw.ellipse([wx - wr, cy + h*0.05 - wr, wx + wr, cy + h*0.05 + wr],
                     fill=(0, 0, 0, 0) if color == WHITE else color,
                     outline=color, width=max(2, int(w * 0.025)))
        # Inner hub
        hr = wr * 0.45
        draw.ellipse([wx - hr, cy + h*0.05 - hr, wx + hr, cy + h*0.05 + hr],
                     fill=color)

    # Windows (cut-out using bg colour)
    win_pts = [
        (cx - w*0.24, cy - h*0.47),
        (cx - w*0.04, cy - h*0.82),
        (cx + w*0.18, cy - h*0.82),
        (cx + w*0.38, cy - h*0.47),
    ]
    draw.polygon(win_pts, fill=BLUE)


def make_icon(size: int, rounded: bool = True) -> Image.Image:
    """Render a single CC Ride app icon at the given pixel size."""
    S = size

    # Work at 4× for anti-aliasing, then down-sample
    scale = 4
    W = S * scale

    img  = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # ── Background ────────────────────────────────────────────────────────────
    if rounded:
        radius = int(W * 0.22)   # ~22% corner radius (Google Play style)
        draw.rounded_rectangle([0, 0, W - 1, W - 1], radius=radius, fill=BLUE)
    else:
        draw.rectangle([0, 0, W - 1, W - 1], fill=BLUE)

    # Subtle vertical gradient overlay (darker at bottom)
    for y in range(W):
        alpha = int(60 * (y / W))          # 0 → 60 opacity
        draw.line([(0, y), (W - 1, y)], fill=(*DBLUE, alpha))

    # ── "CC" text ─────────────────────────────────────────────────────────────
    # Use a bold system font at W*0.38 pt; fall back to default if not found
    cc_size = int(W * 0.36)
    font = None
    for candidate in [
        "C:/Windows/Fonts/ariblk.ttf",   # Arial Black
        "C:/Windows/Fonts/arialbd.ttf",  # Arial Bold
        "C:/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]:
        if os.path.exists(candidate):
            try:
                font = ImageFont.truetype(candidate, cc_size)
                break
            except Exception:
                pass

    if font is None:
        font = ImageFont.load_default()

    cc_text = "CC"
    bb = draw.textbbox((0, 0), cc_text, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    # Place "CC" in upper 55% of icon
    tx = (W - tw) // 2 - bb[0]
    ty = int(W * 0.07) - bb[1]
    draw.text((tx, ty), cc_text, font=font, fill=WHITE)

    # ── Car silhouette ────────────────────────────────────────────────────────
    car_w  = W * 0.60
    car_cx = W / 2
    car_cy = W * 0.60
    draw_car(draw, car_cx, car_cy, car_w, WHITE)

    # ── "RIDE" bottom strip ───────────────────────────────────────────────────
    strip_h = int(W * 0.22)
    strip_y = W - strip_h
    if rounded:
        # Draw a plain rect that bleeds into the rounded corners (looks fine)
        draw.rectangle([0, strip_y, W - 1, W - 1], fill=STRIP)
    else:
        draw.rectangle([0, strip_y, W - 1, W - 1], fill=STRIP)

    ride_size = int(strip_h * 0.62)
    rfont = None
    for candidate in [
        "C:/Windows/Fonts/ariblk.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]:
        if os.path.exists(candidate):
            try:
                rfont = ImageFont.truetype(candidate, ride_size)
                break
            except Exception:
                pass
    if rfont is None:
        rfont = ImageFont.load_default()

    rb = draw.textbbox((0, 0), "RIDE", font=rfont)
    rw, rh = rb[2] - rb[0], rb[3] - rb[1]
    rx = (W - rw) // 2 - rb[0]
    ry = strip_y + (strip_h - rh) // 2 - rb[1]
    draw.text((rx, ry), "RIDE", font=rfont, fill=WHITE)

    # ── Down-sample to target size ────────────────────────────────────────────
    img = img.resize((S, S), Image.LANCZOS)

    # Flatten onto white background for non-transparent formats
    flat = Image.new("RGBA", (S, S), WHITE)
    flat.paste(img, mask=img.split()[3])

    return flat.convert("RGB")


def main():
    ensure_dirs()
    generated = []

    for rel_path, size in SIZES.items():
        # iOS icons have no rounded corners (system applies mask)
        rounded = not rel_path.startswith("ios/")
        img = make_icon(size, rounded=rounded)

        out_path = os.path.join(OUT, rel_path)
        img.save(out_path, "PNG", optimize=True)
        generated.append(f"  {size:>5}px  →  {rel_path}")
        print(f"✓  {size}px  {rel_path}")

    print(f"\n✅  Generated {len(generated)} icons in:\n   {OUT}")
    print("\nNext steps:")
    print("  1. Copy android/ subdirs to:")
    print("     CC_Ride_Flutter/android/app/src/main/res/")
    print("  2. Copy ios/ PNGs to:")
    print("     CC_Ride_Flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset/")
    print("  3. Copy icon_1024.png / icon_512.png for store submissions.")
    print("  4. Update pubspec.yaml flutter_launcher_icons section.")


if __name__ == "__main__":
    main()
