import struct
import zlib
import random

def png_chunk(chunk_type, data):
    chunk = struct.pack(">I", len(data))
    chunk += chunk_type
    chunk += data
    crc = zlib.crc32(chunk_type + data) & 0xffffffff
    chunk += struct.pack(">I", crc)
    return chunk

def create_png_with_text(output_file):
    png_signature = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk (1x1 pixel, 8-bit depth, Truecolor)
    ihdr_data = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)

    # tEXt chunk with randomized content
    keyword = b'Comment'
    random_value = random.randint(0, 1_000_000)
    text = f'Fuzz seed {random_value}'.encode()
    text_chunk = png_chunk(b'tEXt', keyword + b'\x00' + text)

    # IDAT chunk (1x1 black pixel, compressed)
    raw_image_data = b'\x00\x00\x00\x00'
    compressed_data = zlib.compress(raw_image_data)
    idat = png_chunk(b'IDAT', compressed_data)

    # IEND chunk
    iend = png_chunk(b'IEND', b'')

    with open(output_file, 'wb') as f:
        f.write(png_signature)
        f.write(ihdr)
        f.write(text_chunk)
        f.write(idat)
        f.write(iend)

    print(f"PNG file with tEXt chunk written to: {output_file}")

if __name__ == "__main__":
    for i in range(10):  # generate 10 random PNGs
        filename = f"libpng/contrib/oss-fuzz/seeds/with_text_{i}_{random.randint(0,99999)}.png"
        create_png_with_text(filename)