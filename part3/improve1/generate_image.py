import os
import struct
import random
import zipfile
from PIL import Image, PngImagePlugin

os.makedirs("seed", exist_ok=True)

# === Images avec chunks spécifiques ===
def create_text_png(path):
    img = Image.new("RGB", (10, 10), "white")
    meta = PngImagePlugin.PngInfo()
    meta.add_text("Comment", "This is a test tEXt chunk")
    img.save(path, pnginfo=meta)

def create_itxt_png(path):
    img = Image.new("RGB", (10, 10), "blue")
    meta = PngImagePlugin.PngInfo()
    meta.add_itxt("Description", "iTXt support example", lang="en", tkey="desc")
    img.save(path, pnginfo=meta)

def create_trns_png(path):
    img = Image.new("RGBA", (10, 10), (255, 0, 0, 128))
    img.save(path)

def create_phys_png(path):
    img = Image.new("RGB", (10, 10), "green")
    meta = PngImagePlugin.PngInfo()
    meta.add_text("pHYs", struct.pack(">IIB", 3780, 3780, 1))
    img.save(path, pnginfo=meta)

def create_srgb_png(path):
    img = Image.new("RGB", (10, 10), "purple")
    meta = PngImagePlugin.PngInfo()
    meta.add_text("sRGB", struct.pack("B", 0))
    img.save(path, pnginfo=meta)

def create_offs_png(path):
    img = Image.new("RGB", (10, 10), "yellow")
    meta = PngImagePlugin.PngInfo()
    meta.add_text("oFFs", struct.pack(">iiB", 100, 200, 1))
    img.save(path, pnginfo=meta)

def create_exif_png(path):
    img = Image.new("RGB", (10, 10), "black")
    meta = PngImagePlugin.PngInfo()
    fake_exif = b"\x01\x02" * 50
    meta.add_text("eXIf", fake_exif)
    img.save(path, pnginfo=meta)

# === Images aléatoires ===
def create_random_png(path, width=10, height=10):
    img = Image.new("RGB", (width, height))
    pixels = [
        (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        for _ in range(width * height)
    ]
    img.putdata(pixels)
    img.save(path)

# === Génération ===
create_text_png("seed/text_chunk.png")
create_itxt_png("seed/itxt_chunk.png")
create_trns_png("seed/trns_alpha.png")
create_phys_png("seed/phys_chunk.png")
create_srgb_png("seed/srgb_chunk.png")
create_offs_png("seed/offs_chunk.png")
create_exif_png("seed/exif_chunk.png")

# Génère 20 images aléatoires
for i in range(20):
    create_random_png(f"seed/random_{i:02d}.png")

# === Archive ZIP ===
with zipfile.ZipFile("libpng_read_fuzzer_seed_corpus.zip", "w") as zipf:
    for filename in os.listdir("seed"):
        if filename.endswith(".png"):
            zipf.write(os.path.join("seed", filename), arcname=filename)

print("✅ Done: images + corpus ZIP generated")