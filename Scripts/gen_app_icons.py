#!/usr/bin/env python3
import os
import subprocess
ICON_DIR = "ProcureFinder/Resources/Assets.xcassets/AppIcon.appiconset"
os.makedirs(ICON_DIR, exist_ok=True)
ppm_path = os.path.join(ICON_DIR, "Icon-1024.ppm")
png_path = os.path.join(ICON_DIR, "Icon-1024.png")

# 1024x1024 solid blue (PPM) -> PNG
w = h = 1024
with open(ppm_path, "w") as f:
    f.write(f"P3\n{w} {h}\n255\n")
    row = ("0 122 255 " * w).strip()
    for _ in range(h):
        f.write(row + "\n")

subprocess.run(["sips", "-s", "format", "png", ppm_path, "--out", png_path], check=True, stdout=subprocess.DEVNULL)

sizes = {
    "Icon-20@2x.png": 40,
    "Icon-20@3x.png": 60,
    "Icon-29@2x.png": 58,
    "Icon-29@3x.png": 87,
    "Icon-40@2x.png": 80,
    "Icon-40@3x.png": 120,
    "Icon-60@2x.png": 120,
    "Icon-60@3x.png": 180,
}
for name, size in sizes.items():
    subprocess.run(["sips", "-Z", str(size), png_path, "--out", os.path.join(ICON_DIR, name)], check=True, stdout=subprocess.DEVNULL)

os.remove(ppm_path)
print("App icons generated.")
