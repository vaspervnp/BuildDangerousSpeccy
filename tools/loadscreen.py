#!/usr/bin/env python3
"""The loading screen: the CPC's illustrated picture as a Spectrum SCREEN$.

  loadscreen.py IN.jpg OUT.scr [--crop X0,Y0,X1,Y1] [--preview OUT.png]

The picture (1024x572, 16:9) is cropped to the part with the title, the inspector and the
building (default 0,0,860,572), squeezed to the Spectrum's 256x192 and given a little more
colour and contrast. Then per attribute cell (8x8) the two colours - and brightness - that
come nearest to its pixels, each pixel the nearer of the two (the method of
../VrouvesSpeccy/tools/zxcolour.py with --levels 1: dithering the two colours in steps of
a quarter, --levels 4, came out noisy for this picture's dusk sky; flat colours read
better, like a hand-drawn loading screen).
"""
import argparse

from PIL import Image, ImageEnhance

RGB = [[(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215),
        (0, 215, 0), (0, 215, 215), (215, 215, 0), (215, 215, 215)],
       [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255),
        (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]]
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dist(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def picture(img, levels=4):
    """A 256x192 RGB image -> (bits[y][x], 768 attributes)."""
    px = [[img.getpixel((x, y)) for x in range(256)] for y in range(192)]
    bits = [[0] * 256 for _ in range(192)]
    attrs = []
    pairs = []
    for br in (0, 1):
        pal = RGB[br]
        for i in range(8):
            for j in range(i, 8):
                mix = [tuple(pal[i][k] * t / levels + pal[j][k] * (levels - t) / levels
                             for k in range(3)) for t in range(levels + 1)]
                pairs.append((i, j, br, mix))
    for cy in range(24):
        for cx in range(32):
            cols = [px[y][x] for y in range(cy * 8, cy * 8 + 8) for x in range(cx * 8, cx * 8 + 8)]
            best = None
            for ink, paper, br, mix in pairs:
                err = 0
                for c in cols:
                    err += min(dist(c, m) for m in mix)
                    if best is not None and err >= best[0]:
                        break
                if best is None or err < best[0]:
                    best = (err, ink, paper, br, mix)
            _, ink, paper, br, mix = best
            for y in range(cy * 8, cy * 8 + 8):
                for x in range(cx * 8, cx * 8 + 8):
                    t = min(range(levels + 1), key=lambda t: dist(px[y][x], mix[t]))
                    bits[y][x] = 1 if BAYER[y & 3][x & 3] < t * 16 // levels else 0
            attrs.append((br << 6) | (paper << 3) | ink)
    return bits, attrs


def screen_addr(x, y):
    """Offset into the 6144-byte bitmap of byte column x, line y."""
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | x


def scr_bytes(bits, attrs):
    out = bytearray(6144)
    for y in range(192):
        for xb in range(32):
            v = 0
            for i in range(8):
                v = v << 1 | bits[y][xb * 8 + i]
            out[screen_addr(xb, y)] = v
    return bytes(out) + bytes(attrs)


def render(scr, scale=2):
    im = Image.new('RGB', (256, 192))
    for y in range(192):
        for x in range(256):
            a = scr[6144 + (y // 8) * 32 + x // 8]
            br = (a >> 6) & 1
            on = scr[screen_addr(x // 8, y)] >> (7 - (x & 7)) & 1
            im.putpixel((x, y), RGB[br][a & 7] if on else RGB[br][(a >> 3) & 7])
    return im.resize((256 * scale, 192 * scale), Image.NEAREST)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('dst')
    ap.add_argument('--crop', default='0,0,860,572')
    ap.add_argument('--preview')
    ap.add_argument('--levels', type=int, default=1)
    args = ap.parse_args()
    im = Image.open(args.src).convert('RGB')
    im = im.crop(tuple(int(v) for v in args.crop.split(',')))
    im = im.resize((256, 192), Image.LANCZOS)
    im = ImageEnhance.Color(im).enhance(1.3)
    im = ImageEnhance.Contrast(im).enhance(1.2)
    bits, attrs = picture(im, args.levels)
    scr = scr_bytes(bits, attrs)
    open(args.dst, 'wb').write(scr)
    print(f"{args.dst}: {len(scr)} bytes")
    if args.preview:
        render(scr).save(args.preview)


if __name__ == '__main__':
    main()
