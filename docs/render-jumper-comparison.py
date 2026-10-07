"""Crop the actual KiBot board renders into a front/back jumper comparison."""
from pathlib import Path

import pcbnew
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
board = pcbnew.LoadBoard(str(root / 'pcbs/choc_demo.kicad_pcb'))
bounds = board.GetBoardEdgesBoundingBox()
x_min, y_min, width, height = [pcbnew.ToMM(v) for v in
                            (bounds.GetX(), bounds.GetY(), bounds.GetWidth(), bounds.GetHeight())]
margin = 2  # Matches jumper-preview.kibot.yaml.
footprints = {fp.GetReference(): fp for fp in board.GetFootprints()}
canvas = Image.new('RGB', (1240, 1040), '#17191d')
draw = ImageDraw.Draw(canvas)
font = lambda size: ImageFont.truetype('DejaVuSans.ttf', size)
draw.text((40, 24), 'JST PH reversible solder jumpers', font=font(34), fill='white')
draw.text((40, 77), 'Actual choc_demo PCB rendered with KiBot / PcbDraw', font=font(21), fill='#bac0cb')

for col, (reference, label) in enumerate([('JST1', 'Chevron (default)'), ('JST3', 'Rectangular')]):
    fp = footprints[reference]
    x, y = pcbnew.ToMM(fp.GetPosition().x), pcbnew.ToMM(fp.GetPosition().y)
    # The connectors have the demo's -90 degree rotation. Include the complete
    # body outline and jumper pads, with clearance around each footprint.
    left, right, top, bottom = x - 8, x + 3, y - 4.5, y + 4.5
    draw.text((40 + col * 620, 127), label, font=font(27), fill='white')
    for row, side in enumerate(['top', 'bottom']):
        source = Image.open(root / f'docs/images/choc_demo-{side}.png').convert('RGB')
        sx = source.width / (width + margin * 2)
        sy = source.height / (height + margin * 2)
        if side == 'bottom':
            # PcbDraw mirrors the whole board for the underside view.
            a, b = x_min * 2 + width - right, x_min * 2 + width - left
        else:
            a, b = left, right
        box = (round((a - x_min + margin) * sx), round((top - y_min + margin) * sy),
               round((b - x_min + margin) * sx), round((bottom - y_min + margin) * sy))
        crop = source.crop(box)
        crop.thumbnail((550, 350), Image.Resampling.LANCZOS)
        crop = crop.resize((428, 350), Image.Resampling.LANCZOS)
        x0, y0 = 40 + col * 620, 185 + row * 410
        draw.text((x0, y0), 'Front' if side == 'top' else 'Back', font=font(21), fill='#bac0cb')
        canvas.paste(crop, (x0 + 60, y0 + 38))

draw.text((40, 1000), 'Rectangular pads: 0.6 × 1.2 mm   |   Jumper gap: 0.3 mm', font=font(20), fill='#bac0cb')
canvas.save(root / 'docs/images/jst-ph-jumper-comparison.png')
