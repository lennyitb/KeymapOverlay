#!/usr/bin/env python3
"""Generate a DMG background image with green-to-white gradient and drag arrow."""

from PIL import Image, ImageDraw, ImageFont
import math

W, H = 1320, 800  # 2x Retina (660x400 logical)

img = Image.new("RGB", (W, H))
draw = ImageDraw.Draw(img)

# Light wispy green to white gradient (top-left green, fading to white)
for y in range(H):
    for x in range(W):
        # Diagonal gradient: green in top-left corner, white toward bottom-right
        t = (x / W * 0.5 + y / H * 0.5)
        t = t ** 0.7
        r = int(140 + (255 - 140) * t)
        g = int(200 + (255 - 200) * t)
        b = int(140 + (255 - 140) * t)
        img.putpixel((x, y), (r, g, b))

final = img

final.save("dmg/background.png", "PNG")
final.save("dmg/background@2x.png", "PNG")

# Also save a 1x version
final_1x = final.resize((660, 400), Image.LANCZOS)
final_1x.save("dmg/background@1x.png", "PNG")

print("Created dmg/background.png (1320x800)")
print("Created dmg/background@1x.png (660x400)")
