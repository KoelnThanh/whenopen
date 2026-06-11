"""Erzeugt die WhenOpen-App-Icons (Quell-PNGs fuer flutter_launcher_icons).

Marke: Teal-Hintergrund (#2F6F6B), weisse Uhr (freundliche 10:10-Stellung),
gruener Haken-Badge (#28B765) = "wann offen / bestaetigt".

Ausgabe:
  assets/icon/icon.png             1024x1024, voll (Legacy-Launcher + Splash)
  assets/icon/icon_foreground.png  1024x1024, transparent, Inhalt in Safe-Zone
                                   (fuer Adaptive-Icon-Vordergrund)
Gezeichnet wird 4x supersampled und dann heruntergerechnet (saubere Kanten).
"""
import math
import os
from PIL import Image, ImageDraw

S = 4              # Supersampling
N = 1024           # Zielgroesse
C = N * S          # Arbeitsleinwand

TEAL = (47, 111, 107, 255)        # #2F6F6B
TEAL_DARK = (28, 74, 71, 255)     # Zeiger/Ring
GREEN = (40, 183, 101, 255)       # #28B765
WHITE = (245, 248, 248, 255)
SHADOW = (0, 0, 0, 38)


def rounded_rect_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def thick_line(draw, x0, y0, x1, y1, width, fill):
    """Linie mit runden Enden (Kappen als Kreise)."""
    draw.line([x0, y0, x1, y1], fill=fill, width=width)
    r = width // 2
    for (cx, cy) in ((x0, y0), (x1, y1)):
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)


def draw_clock(draw, cx, cy, r, hand_scale=1.0):
    # Uhrkoerper
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    # Innenring
    ring = int(r * 0.085)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=TEAL, width=ring)
    # Stundenstriche bei 12/3/6/9
    tick_len = r * 0.16
    tick_w = max(2, int(r * 0.06))
    for ang in (0, 90, 180, 270):
        a = math.radians(ang - 90)
        x_out = cx + math.cos(a) * (r * 0.78)
        y_out = cy + math.sin(a) * (r * 0.78)
        x_in = cx + math.cos(a) * (r * 0.78 - tick_len)
        y_in = cy + math.sin(a) * (r * 0.78 - tick_len)
        thick_line(draw, x_in, y_in, x_out, y_out, tick_w, TEAL_DARK)
    # Zeiger (freundliche 10:10-Stellung)
    def hand(angle_deg, length, width):
        a = math.radians(angle_deg - 90)
        x = cx + math.cos(a) * length
        y = cy + math.sin(a) * length
        thick_line(draw, cx, cy, x, y, width, TEAL_DARK)
    hand(300, r * 0.46 * hand_scale, int(r * 0.11))   # Stunde -> 10
    hand(60, r * 0.66 * hand_scale, int(r * 0.085))    # Minute -> 2
    # Mittelpunkt
    cr = int(r * 0.08)
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=GREEN)


def draw_check_badge(draw, cx, cy, r):
    # gruener Kreis mit weissem Rand
    pad = int(r * 0.16)
    draw.ellipse([cx - r - pad, cy - r - pad, cx + r + pad, cy + r + pad],
                 fill=WHITE)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)
    # Haken
    w = max(3, int(r * 0.18))
    p1 = (cx - r * 0.42, cy + r * 0.02)
    p2 = (cx - r * 0.08, cy + r * 0.38)
    p3 = (cx + r * 0.46, cy - r * 0.34)
    thick_line(draw, *p1, *p2, w, WHITE)
    thick_line(draw, *p2, *p3, w, WHITE)


def build_full():
    img = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, C, C], fill=TEAL)
    # Uhr leicht nach oben-links, Platz fuer Badge unten-rechts
    cx, cy, r = int(C * 0.46), int(C * 0.45), int(C * 0.30)
    draw_clock(d, cx, cy, r)
    draw_check_badge(d, int(C * 0.72), int(C * 0.72), int(C * 0.155))
    # auf runde Ecken maskieren (Legacy-Launcher)
    mask = rounded_rect_mask(C, int(C * 0.22))
    img.putalpha(mask)
    return img.resize((N, N), Image.LANCZOS)


def build_foreground():
    img = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Inhalt kleiner + zentriert (Adaptive-Safe-Zone ~ innere 66%)
    cx, cy, r = int(C * 0.47), int(C * 0.47), int(C * 0.235)
    draw_clock(d, cx, cy, r)
    draw_check_badge(d, int(C * 0.66), int(C * 0.66), int(C * 0.12))
    return img.resize((N, N), Image.LANCZOS)


def main():
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
    os.makedirs(out, exist_ok=True)
    build_full().save(os.path.join(out, "icon.png"))
    build_foreground().save(os.path.join(out, "icon_foreground.png"))
    print("geschrieben:", os.path.normpath(out))


if __name__ == "__main__":
    main()
