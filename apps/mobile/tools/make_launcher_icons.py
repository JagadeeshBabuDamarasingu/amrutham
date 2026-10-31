"""Regenerates the Android launcher icons from assets/dhanvantari.png.

    python3 tools/make_launcher_icons.py     (from apps/mobile; needs Pillow)

Release: an adaptive icon. The background layer is the artwork's own pine green
(a colour resource); the foreground is the figure, feathered out to transparent
so it melts into that colour. There is no monochrome layer: a silhouette made
from this artwork turned into a halo-shaped blob, so themed icons keep the colours.
Debug: a white background layer with the figure in a round green medallion, so
a debug build is easy to tell from the real app on the same phone.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent.parent
ART = HERE.parent.parent / "assets" / "dhanvantari.png"
RES = HERE / "android" / "app" / "src"

DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
CANVAS = 432  # 108dp at xxxhdpi
CENTER = (543, 575)  # the middle of the figure in the artwork
# Source pixels from CENTER that land on the edge of the visible circle
# (72dp of the 108dp canvas): keeps the discus and conch inside the mask.
VISIBLE_RADIUS_SRC = 470


def figure_layer(art: Image.Image, visible_radius_px: float) -> Image.Image:
    """The artwork scaled and centred on a CANVAS square, opaque everywhere."""
    s = visible_radius_px / VISIBLE_RADIUS_SRC
    scaled = art.resize((round(art.width * s), round(art.height * s)), Image.LANCZOS)
    # Outside the artwork, continue with its edge colour.
    layer = Image.new("RGB", (CANVAS, CANVAS), art.getpixel((20, 20)))
    layer.paste(scaled, (round(CANVAS / 2 - CENTER[0] * s), round(CANVAS / 2 - CENTER[1] * s)))
    return layer


def radial_alpha(solid_px: float, fade_px: float) -> Image.Image:
    """255 inside solid_px of the centre, easing to 0 at fade_px."""
    a = Image.new("L", (CANVAS, CANVAS), 0)
    px = a.load()
    c = CANVAS / 2
    for y in range(CANVAS):
        for x in range(CANVAS):
            d = math.hypot(x + 0.5 - c, y + 0.5 - c)
            t = 1 - min(max((d - solid_px) / (fade_px - solid_px), 0), 1)
            px[x, y] = round(255 * t * t * (3 - 2 * t))  # smoothstep
    return a


def background_colour(layer: Image.Image, inner: float, outer: float) -> tuple[int, int, int]:
    """Average colour of the ring where the feather happens."""
    c = CANVAS / 2
    total = [0, 0, 0]
    n = 0
    for y in range(CANVAS):
        for x in range(CANVAS):
            if inner <= math.hypot(x - c, y - c) <= outer:
                p = layer.getpixel((x, y))
                for i in range(3):
                    total[i] += p[i]
                n += 1
    return tuple(round(t / n) for t in total)  # type: ignore[return-value]


def save_densities(img: Image.Image, folder: str, name: str, base: int, root: Path) -> None:
    for density, scale in DENSITIES.items():
        size = round(base * scale)
        out = root / "res" / f"mipmap-{density}" / name
        out.parent.mkdir(parents=True, exist_ok=True)
        img.resize((size, size), Image.LANCZOS).save(out)


def rounded(img: Image.Image, radius_frac: float) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1],
                                           radius=round(img.width * radius_frac), fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def main() -> None:
    art = Image.open(ART).convert("RGB")
    scale_dp = CANVAS / 108

    # ---- release ----
    layer = figure_layer(art, 144)
    alpha = radial_alpha(150, 205)
    bg = background_colour(layer, 150, 205)
    fg = layer.convert("RGBA")
    fg.putalpha(alpha)
    main_root = RES / "main"
    save_densities(fg, "", "ic_launcher_foreground.png", 108, main_root)
    # Pre-Android 8 phones: the same picture on its background, rounded.
    legacy = Image.new("RGBA", (CANVAS, CANVAS), bg + (255,))
    legacy.alpha_composite(fg)
    legacy = legacy.crop((round(18 * scale_dp), round(18 * scale_dp),
                          CANVAS - round(18 * scale_dp), CANVAS - round(18 * scale_dp)))
    legacy = rounded(legacy.resize((CANVAS, CANVAS), Image.LANCZOS), 0.2)
    save_densities(legacy, "", "ic_launcher.png", 48, main_root)

    hexbg = "#%02X%02X%02X" % bg
    (main_root / "res" / "values").mkdir(parents=True, exist_ok=True)
    (main_root / "res" / "values" / "ic_launcher_background.xml").write_text(
        f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="ic_launcher_background">{hexbg}</color>\n</resources>\n')
    (main_root / "res" / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (main_root / "res" / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n')

    # ---- debug: white background, round medallion ----
    medallion_r = 33 * 4  # the 66dp safe zone
    layer = figure_layer(art, medallion_r)
    disc = Image.new("L", (CANVAS * 4, CANVAS * 4), 0)
    ImageDraw.Draw(disc).ellipse([(CANVAS * 2 - medallion_r * 4), (CANVAS * 2 - medallion_r * 4),
                                  (CANVAS * 2 + medallion_r * 4), (CANVAS * 2 + medallion_r * 4)], fill=255)
    disc = disc.resize((CANVAS, CANVAS), Image.LANCZOS)  # antialiased edge
    dfg = layer.convert("RGBA")
    dfg.putalpha(disc)
    debug_root = RES / "debug"
    save_densities(dfg, "", "ic_launcher_foreground.png", 108, debug_root)
    dlegacy = Image.new("RGBA", (CANVAS, CANVAS), (255, 255, 255, 255))
    dlegacy.alpha_composite(dfg)
    dlegacy = dlegacy.crop((round(18 * scale_dp), round(18 * scale_dp),
                            CANVAS - round(18 * scale_dp), CANVAS - round(18 * scale_dp)))
    dlegacy = rounded(dlegacy.resize((CANVAS, CANVAS), Image.LANCZOS), 0.2)
    save_densities(dlegacy, "", "ic_launcher.png", 48, debug_root)
    (debug_root / "res" / "values").mkdir(parents=True, exist_ok=True)
    (debug_root / "res" / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        '    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>\n')
    print("release background", hexbg)


if __name__ == "__main__":
    main()
