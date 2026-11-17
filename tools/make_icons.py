#!/usr/bin/env python3
"""Generates the 1024px app icon PNGs (needs Pillow: pip install pillow)."""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

S = 2                      # supersampling
W = 1024 * S
OUT = os.path.join(os.path.dirname(__file__), "..", "Icons")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def hexc(h): h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def gradient(top, bottom):
    img = Image.new("RGB", (W, W))
    px = ImageDraw.Draw(img)
    t, b = hexc(top), hexc(bottom)
    for y in range(W):
        f = y / (W - 1)
        px.line([(0, y), (W, y)], fill=tuple(int(t[i] + (b[i] - t[i]) * f) for i in range(3)))
    return img

def squircle_base(top, bottom):
    m = 100 * S
    box = (m, m, W - m, W - m)
    r = int((W - 2 * m) * 0.225)
    canvas = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    # soft shadow
    sh = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((m, m + 14 * S, W - m, W - m + 14 * S), r, fill=(0, 0, 0, 90))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14 * S)))
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, r, fill=255)
    canvas.paste(gradient(top, bottom), (0, 0), mask)
    return canvas

def thick_line(d, pts, width, fill):
    for a, b in zip(pts, pts[1:]):
        d.line([a, b], fill=fill, width=width)
    for p in pts:
        d.ellipse((p[0] - width / 2, p[1] - width / 2, p[0] + width / 2, p[1] + width / 2), fill=fill)

def calendar_icon(name, top, bottom, accent, label):
    img = squircle_base(top, bottom)
    d = ImageDraw.Draw(img)
    # card
    x0, y0, x1, y1 = 262 * S, 262 * S, 762 * S, 782 * S
    d.rounded_rectangle((x0, y0, x1, y1), 64 * S, fill=(255, 255, 255, 255))
    # header band
    hdr = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hdr)
    hd.rounded_rectangle((x0, y0, x1, y0 + 170 * S), 64 * S, fill=hexc(accent) + (255,))
    hd.rectangle((x0, y0 + 100 * S, x1, y0 + 170 * S), fill=hexc(accent) + (255,))
    img.alpha_composite(hdr)
    d = ImageDraw.Draw(img)
    # binder rings
    for cx in (x0 + 130 * S, x1 - 130 * S):
        d.rounded_rectangle((cx - 18 * S, y0 - 40 * S, cx + 18 * S, y0 + 40 * S), 18 * S, fill=(255, 255, 255, 255))
    # label
    f = ImageFont.truetype(FONT, 88 * S)
    bb = d.textbbox((0, 0), label, font=f)
    d.text(((x0 + x1) / 2 - (bb[0] + bb[2]) / 2, y0 + 85 * S - (bb[1] + bb[3]) / 2), label, font=f, fill=(255, 255, 255, 255))
    # checkmark
    cy = (y0 + 170 * S + y1) / 2 + 10 * S
    pts = [(392 * S, cy + 0 * S), (475 * S, cy + 85 * S), (640 * S, cy - 80 * S)]
    thick_line(d, pts, 64 * S, hexc(accent) + (255,))
    save(img, name)

def papaya_icon(name):
    img = squircle_base("#FFE9B0", "#FFC24D")
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = W / 2, W / 2 + 20 * S
    def ell(rx, ry, fill):
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=fill)
    ell(230 * S, 340 * S, hexc("#7DB83A") + (255,))     # skin
    ell(205 * S, 315 * S, hexc("#FF8A1F") + (255,))     # flesh
    ell(110 * S, 225 * S, hexc("#E8590C") + (255,))     # cavity
    # seeds
    for sy in range(-170, 171, 62):
        for sx in (-45, 0, 45):
            if (sy // 62) % 2 == 0 and sx == 0: continue
            px, py = cx + sx * S, cy + (sy + (20 if sx else 0)) * S
            d.ellipse((px - 17 * S, py - 22 * S, px + 17 * S, py + 22 * S), fill=(30, 20, 15, 255))
    # highlight
    d.arc((cx - 205 * S, cy - 315 * S, cx + 205 * S, cy + 315 * S), 200, 250, fill=(255, 255, 255, 140), width=14 * S)
    layer = layer.rotate(28, resample=Image.BICUBIC, center=(W / 2, W / 2))
    img.alpha_composite(layer)
    d = ImageDraw.Draw(img)
    # leaf
    d.polygon([(690 * S, 250 * S), (790 * S, 190 * S), (760 * S, 300 * S)], fill=hexc("#3F8F2B") + (255,))
    save(img, name)

def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))
    print("wrote", name + ".png")

if __name__ == "__main__":
    calendar_icon("WeeklyRituals",  "#FFA24D", "#F2620F", "#E4530A", "WEEK")
    calendar_icon("MonthlyRituals", "#3ED6C4", "#0E8C80", "#0B7A70", "MONTH")
    calendar_icon("YearlyRituals",  "#8F7BFF", "#4A32C9", "#4330B8", "YEAR")
    papaya_icon("PapayaTracker")
