from pathlib import Path
import math, struct, zlib

size = 1024
out = Path(__file__).resolve().parent / 'WeatherGlass' / 'Assets.xcassets' / 'AppIcon.appiconset' / 'icon.png'
pixels = bytearray()
for y in range(size):
    row = bytearray()
    for x in range(size):
        glow = max(0, 1 - math.hypot((x - 680) / 650, (y - 220) / 700))
        r = int(9 + 12 * glow)
        g = int(22 + 37 * glow)
        b = int(44 + 67 * glow)
        distance_sun = math.hypot(x - 600, y - 396)
        if distance_sun < 177:
            t = max(0, 1 - distance_sun / 177)
            r = int(245 - 22 * (1 - t))
            g = int(178 + 24 * t)
            b = int(88 + 35 * t)
        cloud = ((x - 375) ** 2 + (y - 566) ** 2 < 160 ** 2 or
                 (x - 560) ** 2 + (y - 530) ** 2 < 210 ** 2 or
                 (x - 704) ** 2 + (y - 605) ** 2 < 135 ** 2 or
                 (240 < x < 829 and 561 < y < 736))
        if cloud:
            fade = max(0, min(1, (755-y) / 400))
            r = int(201 + 40 * fade)
            g = int(226 + 19 * fade)
            b = 250
        row.extend((r, g, b, 255))
    pixels.extend(b'\x00' + row)

def chunk(tag, data):
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

header = b'\x89PNG\r\n\x1a\n'
body = chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
body += chunk(b'IDAT', zlib.compress(pixels, 7))
body += chunk(b'IEND', b'')
out.write_bytes(header + body)
print('ICON_OK', out.name, len(header + body))
