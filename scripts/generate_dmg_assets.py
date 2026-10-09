#!/usr/bin/env python3
import os, subprocess
from PIL import Image, ImageDraw, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
DMG_DIR = os.path.join(PROJECT_DIR, 'Clipmory', 'Resources', 'DMG')
os.makedirs(DMG_DIR, exist_ok=True)

# 1. Canvas dimensions (Retina @2x for 660x420 pt window)
W, H = 1320, 840
bg = Image.new('RGBA', (W, H), (255, 255, 255, 255))

# 2. Rounded Card Container
card_box = (60, 50, 1260, 790)
corner_radius = 52

card_mask = Image.new('L', (W, H), 0)
mask_draw = ImageDraw.Draw(card_mask)
mask_draw.rounded_rectangle(card_box, radius=corner_radius, fill=255)

gradient = Image.new('RGBA', (W, H), (0, 0, 0, 0))
g_draw = ImageDraw.Draw(gradient)
for y in range(50, 791):
    t = (y - 50) / (790 - 50)
    # Match the clean, soft grey card gradient from the design mockup
    r = int(226 + t * (240 - 226))
    g = int(230 + t * (243 - 230))
    b = int(234 + t * (246 - 234))
    g_draw.line([(60, y), (1260, y)], fill=(r, g, b, 255))

bg.paste(gradient, (0, 0), card_mask)

# Subtle card border
border_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
b_draw = ImageDraw.Draw(border_layer)
b_draw.rounded_rectangle(card_box, radius=corner_radius, outline=(214, 218, 224, 255), width=2)
bg.paste(border_layer, (0, 0), border_layer)

# 3. Directional Arrow in Center
# Extract arrow from scratch or draw crisp vector
arrow_path = os.path.join(PROJECT_DIR, 'Clipmory', 'Resources', 'DMG', 'arrow_source.png')
if not os.path.exists(arrow_path):
    scratch_arrow = '/Users/owel/.gemini/antigravity-ide/brain/daf84f5b-4270-480c-9cf7-7de3a001b716/scratch/arrow.png'
    if os.path.exists(scratch_arrow):
        import shutil
        shutil.copyfile(scratch_arrow, arrow_path)

if os.path.exists(arrow_path):
    arrow = Image.open(arrow_path).convert('RGBA')
    aw, ah = arrow.size
    target_aw = int(aw * 1.35)
    target_ah = int(ah * 1.35)
    arrow_scaled = arrow.resize((target_aw, target_ah), Image.Resampling.LANCZOS)

    arrow_mask = Image.new('L', (target_aw, target_ah), 255)
    m_draw = ImageDraw.Draw(arrow_mask)
    m_draw.rectangle([0, 0, target_aw, target_ah], fill=0)
    m_draw.rectangle([10, 10, target_aw - 10, target_ah - 10], fill=255)
    arrow_mask = arrow_mask.filter(ImageFilter.GaussianBlur(8))

    arrow_x = (W - target_aw) // 2
    arrow_y = (H - target_ah) // 2 - 10

    bg.paste(arrow_scaled, (arrow_x, arrow_y), arrow_mask)
else:
    # Vector fallback
    arrow_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    a_draw = ImageDraw.Draw(arrow_layer)
    arrow_poly = [
        (600, 390), (675, 390), (675, 355),
        (748, 415),
        (675, 475), (675, 440), (600, 440)
    ]
    a_draw.polygon(arrow_poly, fill=(255, 255, 255, 255))
    shadow_alpha = arrow_layer.split()[3].filter(ImageFilter.GaussianBlur(12))
    shadow_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    shadow_layer.paste((30, 40, 50, 255), mask=shadow_alpha.point(lambda p: int(p * 0.3)))
    bg.paste(shadow_layer, (0, 6), shadow_layer)
    bg.paste(arrow_layer, (0, 0), arrow_layer)

bg_rgb = bg.convert('RGB')
bg_2x_path = os.path.join(DMG_DIR, 'background@2x.png')
bg_1x_path = os.path.join(DMG_DIR, 'background.png')
bg_tiff_path = os.path.join(DMG_DIR, 'background.tiff')

bg_rgb.save(bg_2x_path, dpi=(144, 144))
bg_1x = bg_rgb.resize((660, 420), Image.Resampling.LANCZOS)
bg_1x.save(bg_1x_path, dpi=(72, 72))

subprocess.run(['tiffutil', '-cathidpicheck', bg_1x_path, bg_2x_path, '-out', bg_tiff_path], check=True)
print(f"Generated HiDPI background at {bg_tiff_path}")
