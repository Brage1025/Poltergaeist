"""Generate icon.ico (the program icon) from the mascot head. Run by build.bat."""
from pathlib import Path
from PIL import Image

src = Path(__file__).parent / "assets" / "mascot_head.png"
img = Image.open(src).convert("RGBA").resize((256, 256), Image.LANCZOS)
img.save("icon.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print("Wrote icon.ico from", src.name)