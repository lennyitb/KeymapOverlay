#!/usr/bin/env python3
"""Create a green-tinted drive icon for the DMG volume."""

from PIL import Image, ImageFilter
import colorsys
import subprocess
import tempfile, os, shutil

SRC = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/iDiskGenericIcon.icns"
OUT_PNG = "dmg/volume_icon.png"
OUT_ICNS = "dmg/volume_icon.icns"

subprocess.run(["sips", "-s", "format", "png", SRC, "--out", "/tmp/drive_base.png"],
               capture_output=True, check=True)

img = Image.open("/tmp/drive_base.png").convert("RGBA")
pixels = img.load()
w, h = img.size

# --- Step 1: Remove the cloud ---
# The cloud is white/light pixels on the blue panel.
# Strategy: for each row in the cloud zone, sample the panel color from the
# far-left edge of the panel (which is cloud-free), then use the horizontal
# gradient ratio (left-to-right) from rows that have no cloud to reconstruct
# the panel under the cloud.

# The panel occupies roughly x=130..890, y=130..580
# The cloud occupies roughly x=200..820, y=190..530
# Columns x=130..170 are reliably cloud-free on the left

cloud_y_min, cloud_y_max = 145, 575
cloud_x_min, cloud_x_max = 165, 860

# For each row, get the left-edge panel color and right-edge panel color
# from cloud-free zones
left_sample_x = 155
right_sample_x = 875

for y in range(cloud_y_min, cloud_y_max):
    lr, lg, lb, la = pixels[left_sample_x, y]
    rr, rg, rb, ra = pixels[right_sample_x, y]

    for x in range(cloud_x_min, cloud_x_max):
        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        t = (x - left_sample_x) / (right_sample_x - left_sample_x)
        exp_r = int(lr + (rr - lr) * t)
        exp_g = int(lg + (rg - lg) * t)
        exp_b = int(lb + (rb - lb) * t)
        pixels[x, y] = (exp_r, exp_g, exp_b, a)

# Gentle blur on the patched region to smooth any seams
patched = img.copy()
patched_blur = patched.filter(ImageFilter.GaussianBlur(radius=3))
bp = patched_blur.load()
for y in range(cloud_y_min, cloud_y_max):
    for x in range(cloud_x_min, cloud_x_max):
        r, g, b, a = pixels[x, y]
        br, bg, bb, ba = bp[x, y]
        # Blend: 70% original, 30% blurred to smooth edges
        pixels[x, y] = (
            int(r * 0.7 + br * 0.3),
            int(g * 0.7 + bg * 0.3),
            int(b * 0.7 + bb * 0.3),
            a
        )

# --- Step 2: Hue-shift blue to green ---
app_icon = Image.open("icon.png").convert("RGB")
app_px = app_icon.load()
aw, ah = app_icon.size
greens = []
for sy in range(ah // 3, 2 * ah // 3, 10):
    for sx in range(aw // 3, 2 * aw // 3, 10):
        r, g, b = app_px[sx, sy]
        if g > r and g > b:
            hv, sv, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            greens.append(hv)

target_hue = sum(greens) / len(greens)
print(f"Target hue: {target_hue:.3f} ({target_hue * 360:.0f} degrees)")

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        hv, sv, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if 0.45 < hv < 0.75 and sv > 0.08:
            hv = target_hue + (hv - 0.6) * 0.3
            hv = hv % 1.0
            nr, ng, nb = colorsys.hsv_to_rgb(hv, sv, vv)
            pixels[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)

img.save(OUT_PNG, "PNG")
print(f"Saved {OUT_PNG}")

# --- Step 3: Create .icns ---
iconset = tempfile.mkdtemp(suffix=".iconset")
sizes = [16, 32, 64, 128, 256, 512]
for s in sizes:
    img.resize((s, s), Image.LANCZOS).save(os.path.join(iconset, f"icon_{s}x{s}.png"))
    img.resize((s * 2, s * 2), Image.LANCZOS).save(os.path.join(iconset, f"icon_{s}x{s}@2x.png"))

proper_path = iconset.replace(".iconset", "") + ".iconset"
os.rename(iconset, proper_path)
subprocess.run(["iconutil", "-c", "icns", proper_path, "-o", OUT_ICNS], check=True)
shutil.rmtree(proper_path)
print(f"Saved {OUT_ICNS}")
