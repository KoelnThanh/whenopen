"""Erzeugt die WhenOpen-App-Icons (Quell-PNGs fuer flutter_launcher_icons).

Marke v0.3 — Logo B „PinTime": Indigo-Hintergrund (Verlauf #6366F1 -> #4F46E5),
weisser Karten-Pin, darin eine kleine Uhr (Ort + Oeffnungszeit).

Ausgabe:
  assets/icon/icon.png             1024x1024, voll (Legacy-Launcher + Splash)
  assets/icon/icon_foreground.png  1024x1024, transparent, Inhalt in Safe-Zone
                                   (fuer Adaptive-Icon-Vordergrund)
Gezeichnet wird 4x supersampled und dann heruntergerechnet (saubere Kanten).
"""
import os
from PIL import Image, ImageDraw

S = 4              # Supersampling
N = 1024           # Zielgroesse
C = N * S          # Arbeitsleinwand

INDIGO = (99, 102, 241, 255)       # #6366F1
INDIGO_DEEP = (79, 70, 229, 255)   # #4F46E5
WHITE = (246, 248, 251, 255)
PIN_INNER = (90, 95, 227, 255)     # Uhrflaeche (etwas dunkler als BG)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def rounded_rect_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def vertical_gradient(size, top, bottom):
    base = Image.new("RGB", (1, size))
    for y in range(size):
        base.putpixel((0, y), lerp(top, bottom, y / (size - 1)))
    return base.resize((size, size))


def thick_line(draw, x0, y0, x1, y1, width, fill):
    draw.line([x0, y0, x1, y1], fill=fill, width=width)
    r = width // 2
    for (cx, cy) in ((x0, y0), (x1, y1)):
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)


def draw_pin(draw, cx, cy, r):
    """Karten-Pin (weiss): Kopf-Kreis + Spitze nach unten, darin eine Uhr."""
    # Spitze (Dreieck) unter dem Kopf
    tip_y = cy + r * 2.15
    draw.polygon(
        [(cx - r * 0.66, cy + r * 0.62),
         (cx + r * 0.66, cy + r * 0.62),
         (cx, tip_y)],
        fill=WHITE,
    )
    # Kopf-Kreis
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    # Uhrflaeche
    ir = r * 0.62
    draw.ellipse([cx - ir, cy - ir, cx + ir, cy + ir], fill=PIN_INNER)
    # Zeiger (freundliche Stellung), weiss
    cw = max(3, int(r * 0.10))
    thick_line(draw, cx, cy, cx, cy - ir * 0.62, cw, WHITE)          # nach oben
    thick_line(draw, cx, cy, cx + ir * 0.52, cy + ir * 0.30, cw, WHITE)  # nach unten rechts
    draw.ellipse([cx - cw, cy - cw, cx + cw, cy + cw], fill=WHITE)   # Mittelpunkt


def build_full():
    grad = vertical_gradient(C, INDIGO, INDIGO_DEEP).convert("RGBA")
    d = ImageDraw.Draw(grad)
    cx, cy, r = int(C * 0.5), int(C * 0.42), int(C * 0.205)
    draw_pin(d, cx, cy, r)
    mask = rounded_rect_mask(C, int(C * 0.22))
    grad.putalpha(mask)
    return grad.resize((N, N), Image.LANCZOS)


def build_foreground():
    img = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Inhalt in der Adaptive-Safe-Zone (~ innere 66 %), leicht hoeher zentriert.
    cx, cy, r = int(C * 0.5), int(C * 0.45), int(C * 0.17)
    draw_pin(d, cx, cy, r)
    return img.resize((N, N), Image.LANCZOS)


def main():
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
    os.makedirs(out, exist_ok=True)
    build_full().save(os.path.join(out, "icon.png"))
    build_foreground().save(os.path.join(out, "icon_foreground.png"))
    print("geschrieben:", os.path.normpath(out))


if __name__ == "__main__":
    main()
