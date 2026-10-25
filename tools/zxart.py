#!/usr/bin/env python3
"""The Spectrum's art for Build Dangerous, drawn from scratch as text, written out as PNGs.

  zxart.py            every sheet: assets/gfx/<name>.png
  zxart.py tiles font only those

The PNGs are what tools/zxgfx.py converts; they can be touched up in an editor, but running
this again overwrites them.

Pixels, one character each:
  .        transparent (sprites) / paper (tiles: black unless the tile gives a paper)
  k        black, opaque: holes and lines inside a sprite
  B R M G C Y W    blue, red, magenta, green, cyan, yellow, white - BRIGHT
  b r m g c y w    the same without BRIGHT
  P        tiles only: the building's own colour (set per building, src/tiles.asm)

A Spectrum attribute cell (8x8) has one ink: the converter takes, per cell, the colour most
of its pixels have. So a sprite is drawn in 8x8 colour blocks - the hard hat and the face in
the top row of cells, the suit in the bottom one. Sprites get a black ring round them (their
mask) from the converter, so they read over the furniture.
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'gfx')

N, H = 0xD7, 0xFF
COLOURS = {
    'k': (0, 0, 0), 'b': (0, 0, N), 'r': (N, 0, 0), 'm': (N, 0, N), 'g': (0, N, 0),
    'c': (0, N, N), 'y': (N, N, 0), 'w': (N, N, N),
    'B': (0, 0, H), 'R': (H, 0, 0), 'M': (H, 0, H), 'G': (0, H, 0), 'C': (0, H, H),
    'Y': (H, H, 0), 'W': (H, H, H),
    'P': (0x80, 0x80, 0x80),        # the building's colour: grey in the PNG
}


def strip(name, frames, w, h, transparent=True):
    """Frames side by side -> assets/gfx/<name>.png."""
    im = Image.new('RGBA', (w * len(frames), h), (0, 0, 0, 0 if transparent else 255))
    px = im.load()
    for f, rows in enumerate(frames):
        assert len(rows) == h, (name, f, len(rows))
        for y, row in enumerate(rows):
            assert len(row) == w, (name, f, y, row)
            for x, ch in enumerate(row):
                if ch == '.':
                    continue
                px[f * w + x, y] = COLOURS[ch] + (255,)
    im.save(os.path.join(OUT, name + '.png'))
    print(f"assets/gfx/{name}.png: {len(frames)} frames")


# ------------------------------------------------------------------ helpers
def edit(base, rows):
    """base with some rows replaced: {row: text}."""
    return [rows.get(i, r) for i, r in enumerate(base)]


def over(base, top):
    """top drawn over base; '.' in top keeps base."""
    return [''.join(t if t != '.' else b for b, t in zip(br, tr)) for br, tr in zip(base, top)]


def recolour(rows, mapping, y0=0, y1=99):
    return [''.join(mapping.get(c, c) for c in r) if y0 <= i < y1 else r
            for i, r in enumerate(rows)]


def hflip(rows):
    return [r[::-1] for r in rows]


def vflip(rows):
    return rows[::-1]


def shift(rows, dx=0, dy=0):
    w, h = len(rows[0]), len(rows)
    out = ['.' * w] * h
    out = [list(r) for r in out]
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c != '.' and 0 <= x + dx < w and 0 <= y + dy < h:
                out[y + dy][x + dx] = c
    return [''.join(r) for r in out]


def blank(w=16, h=16):
    return ['.' * w] * h


def paint(rows, c):
    """Every drawn pixel (not k) in colour c."""
    return [''.join(c if ch not in '.k' else ch for ch in r) for r in rows]


# ------------------------------------------------------------------ tiles (8x8)
# (colour, rows): '#' ink, '.' paper. colour 'Y' or 'Y/r' (ink / paper).
T = {}


def tile(name, colour, *rows):
    assert len(rows) == 8 and all(len(r) == 8 for r in rows), name
    T[name] = (colour, rows)


tile('black', 'W', *['........'] * 8)
tile('wallpaper', 'W', *['........'] * 8)       # no wallpaper on the Spectrum: black walls
tile('floor', 'P', '########', '#.#.#.#.', '........', '##.###.#', '##.###.#', '........',
     '.#.#.#.#', '########')
tile('brick', 'P', '###.####', '###.####', '###.####', '........', '#######.', '#######.',
     '#######.', '........')
tile('ladder_l', 'Y', '.#......', '.#......', '.#######', '.#......', '.#......', '.#......',
     '.#######', '.#......')
tile('ladder_r', 'Y', '......#.', '......#.', '#######.', '......#.', '......#.', '......#.',
     '#######.', '......#.')
tile('window', 'c', '########', '#..#..##', '#.#..#.#', '##..#..#', '########', '#..#..##',
     '#.#..#.#', '########')
tile('door_t', 'y', '.######.', '##....##', '#.####.#', '#.#..#.#', '#.#..#.#', '#.#..#.#',
     '#.####.#', '#......#')
tile('door_b', 'y', '#......#', '#....###', '#.####.#', '#.#..#.#', '#.#..#.#', '#.####.#',
     '#......#', '########')
tile('lamp', 'Y', '...#....', '...#....', '...#....', '..###...', '.#####..', '#######.',
     '..#.#...', '.#..#.#.')
tile('socket', 'W', '........', '.#####..', '.#...#..', '.#.#.#..', '.#...#..', '.#####..',
     '........', '........')
tile('hat_full', 'Y', '........', '...##...', '..####..', '.######.', '.######.', '########',
     '........', '........')
tile('hat_empty', 'b', '........', '...##...', '..#..#..', '.#....#.', '.#....#.', '########',
     '........', '........')
tile('check_empty', 'W', '........', '.######.', '.#....#.', '.#....#.', '.#....#.', '.#....#.',
     '.######.', '........')
tile('check_done', 'G', '.......#', '.#####.#', '.#...#.#', '.#..#.##', '.##.#..#', '.#.##..#',
     '.######.', '........')
tile('exit_t', 'G', '########', '#......#', '#..#...#', '#..##..#', '#######.', '#..##..#',
     '#..#...#', '#......#')
tile('exit_b', 'G', '#......#', '#......#', '#....#.#', '#......#', '#......#', '#......#',
     '#......#', '########')
tile('hat_half', 'Y', '........', '...#....', '..###...', '.####.#.', '.####.#.', '########',
     '........', '........')
tile('miss', 'R', '........', '##....##', '.##..##.', '..####..', '..####..', '.##..##.',
     '##....##', '........')


def dial(gone):
    import math
    rows = []
    for y in range(8):
        r = ''
        for x in range(8):
            dx, dy = x - 3.5, y - 3.5
            d = math.hypot(dx, dy)
            ch = '.'
            if d <= 3.9:
                if d > 2.9:
                    ch = '#'
                else:
                    a = math.atan2(dx, -dy) % (2 * math.pi)
                    ch = '.' if a / (2 * math.pi) < gone / 8 else '#'
            r += ch
        rows.append(r)
    return rows


for s in range(9):
    tile(f'dial_{s}', 'Y', *dial(s))
tile('star', 'W', '........', '........', '...#....', '..###...', '...#....', '........',
     '........', '........')
tile('moon', 'Y', '..###...', '.####...', '###.....', '###.....', '###.....', '.####...',
     '..###...', '........')
tile('ribbon', 'R', '........', '........', '........', '########', '########', '........',
     '........', '........')
tile('ribbon_cut', 'R', '........', '........', '........', '###..###', '##....##', '#......#',
     '........', '........')
tile('shelf', 'y', '########', '.#.##.#.', '.#.##.#.', '########', '#.#..##.', '#.#..##.',
     '########', '#......#')
tile('plant', 'G', '..#.#...', '.###.#..', '..###...', '.#.#.#..', '...#....', '..###...',
     '..###...', '...#....')
tile('bed_l', 'W', '........', '........', '##......', '####....', '########', '########',
     '#.......', '#.......')
tile('bed_r', 'W', '........', '........', '........', '.......#', '########', '########',
     '.......#', '.......#')
tile('cross', 'R/W', '........', '...##...', '...##...', '.######.', '.######.', '...##...',
     '...##...', '........')
tile('desk_l', 'y', '........', '..###...', '..#.#...', '...#....', '...#....', '########',
     '#.......', '#.......')
tile('desk_r', 'y', '........', '........', '.....##.', '.....##.', '....###.', '########',
     '.......#', '.......#')
tile('chandelier', 'Y', '...#....', '...#....', '.#####..', '#..#..#.', '.#.#.#..', '#.#.#.#.',
     '........', '........')
tile('grille', 'w', '........', '########', '#.#.#.##', '#.#.#.##', '#.#.#.##', '########',
     '........', '........')
tile('drum', 'g', '........', '.#####..', '##...##.', '.#####..', '.#...#..', '.#####..',
     '........', '........')
tile('vent', 'w', '########', '#......#', '#.####.#', '#......#', '#.####.#', '########',
     '........', '........')
STAIR_R = ['########', '#.....#.', '#....#..', '#...#...', '#..#....', '#.#.....', '##......',
           '#.......']
tile('stair_r', 'W', *STAIR_R)
tile('stair_l', 'W', *[r[::-1] for r in STAIR_R])
ESC_R = ['#.#.#.#.', '#######.', '#...#.#.', '#..#.#..', '#.#.#...', '##.#....', '#.#.....',
         '#.......']
tile('esc_up_r', 'G', *ESC_R)
tile('esc_up_l', 'G', *[r[::-1] for r in ESC_R])
tile('esc_dn_r', 'R', *ESC_R)
tile('esc_dn_l', 'R', *[r[::-1] for r in ESC_R])
tile('title_brick', 'R/y', '#######.', '#######.', '#######.', '........', '###.####', '###.####',
     '###.####', '........')
tile('barrier', 'Y/r', '####....', '###....#', '##....##', '#....###', '....####', '...####.',
     '..####..', '.####...')
tile('girder', 'C', '########', '#.#..#.#', '.#....#.', '#.#..#.#', '.#....#.', '#.#..#.#',
     '.#....#.', '########')
tile('slot', 'M', '.#####..', '.#...#.#', '.#.#.#.#', '.#...#.#', '.#####.#', '.#.#.###',
     '.#####..', '.#####..')
tile('guitar', 'Y', '......##', '.....##.', '....#...', '.###....', '##.##...', '#####...',
     '####....', '.##.....')
tile('amp', 'w', '########', '#......#', '#.####.#', '#.#..#.#', '#.#..#.#', '#.####.#',
     '#......#', '########')
tile('sofa_l', 'M', '........', '..######', '.#######', '##......', '##.#####', '########',
     '########', '.#......')
tile('sofa_r', 'M', '........', '######..', '#######.', '......##', '#####.##', '########',
     '########', '......#.')
tile('picture', 'Y', '########', '#......#', '#.#....#', '#.##.#.#', '#.######', '########',
     '........', '........')
tile('clock', 'W', '..####..', '.#....#.', '#..#...#', '#..#...#', '#..###.#', '#......#',
     '.#....#.', '..####..')
tile('tv', 'C', '..#..#..', '...##...', '########', '#......#', '#.#....#', '#......#',
     '########', '.#....#.')
tile('fridge_t', 'W', '.######.', '.#....#.', '.#...##.', '.#...##.', '.#....#.', '.#....#.',
     '.######.', '.#....#.')
tile('fridge_b', 'W', '.#...##.', '.#...##.', '.#....#.', '.#....#.', '.#....#.', '.#....#.',
     '.######.', '..#..#..')
tile('bin', 'g', '........', '........', '.######.', '..#..#..', '..#..#..', '..#..#..',
     '..#..#..', '..####..')
tile('bookcase_t', 'y', '########', '#.#.##.#', '#.#.##.#', '#.#.##.#', '########', '##.#.#.#',
     '##.#.#.#', '##.#.#.#')
tile('bookcase_b', 'y', '########', '#.##.#.#', '#.##.#.#', '#.##.#.#', '########', '#......#',
     '#.####.#', '########')
tile('cooler_t', 'C', '........', '..####..', '.#....#.', '.#....#.', '.#....#.', '..#..#..',
     '...##...', '.######.')
tile('cooler_b', 'W', '.#....#.', '.#.##.#.', '.#....#.', '.#....#.', '.#....#.', '.#....#.',
     '.#....#.', '.#....#.')
tile('desk_front_l', 'y', '........', '........', '########', '#.......', '#.######', '#.......',
     '#.......', '########')
tile('desk_front_m', 'y', '...#....', '..###...', '########', '........', '########', '........',
     '........', '########')
tile('desk_front_r', 'y', '........', '........', '########', '.......#', '######.#', '.......#',
     '.......#', '########')

TILE_ORDER = [
    'black', 'wallpaper', 'floor', 'brick', 'ladder_l', 'ladder_r', 'window', 'door_t',
    'door_b', 'lamp', 'socket', 'hat_full', 'hat_empty', 'check_empty', 'check_done', 'exit_t',
    'exit_b', 'hat_half', 'miss'] + [f'dial_{s}' for s in range(9)] + [
    'star', 'moon', 'ribbon', 'ribbon_cut', 'shelf', 'plant', 'bed_l', 'bed_r', 'cross',
    'desk_l', 'desk_r', 'chandelier', 'grille', 'drum', 'vent', 'stair_r', 'stair_l',
    'esc_up_r', 'esc_up_l', 'esc_dn_r', 'esc_dn_l', 'title_brick', 'barrier', 'girder', 'slot',
    'guitar', 'amp', 'sofa_l', 'sofa_r', 'picture', 'clock', 'tv', 'fridge_t', 'fridge_b',
    'bin', 'bookcase_t', 'bookcase_b', 'cooler_t', 'cooler_b', 'desk_front_l', 'desk_front_m',
    'desk_front_r']
assert len(TILE_ORDER) == 70


def tile_frames():
    out = []
    for name in TILE_ORDER:
        colour, rows = T[name]
        ink, _, paper = colour.partition('/')
        out.append([''.join(ink if c == '#' else (paper or 'k') for c in r) for r in rows])
    return out


# ------------------------------------------------------------------ Thanos (16x16)
# Top row of cells yellow (hard hat and face), bottom row cyan (the inspector's suit).
THANOS_R = [
    '.....YYYYY......',
    '....YYYYYYY.....',
    '...YYYYYYYYY....',
    '..YYYYYYYYYYYY..',
    '...kkkkkkkkk....',
    '....YYYYYkYY....',
    '....YYYYYYYY....',
    '.....YYYkkY.....',
    '....CCCCCC......',
    '...CCCCCCCC.....',
    '..CC.CCCC.CW....',
    '..C..CCCC.WWW...',
    '.....CCCC.WWW...',
    '....CC..CC......',
    '...CC....CC.....',
    '..CCC....CCC....',
]
THANOS_R2 = edit(THANOS_R, {
    10: '...C.CCCC.CW....', 11: '...C.CCCC.WWW...', 13: '.....CCCC.......',
    14: '.....CC.CC......', 15: '....CCC.CCC.....'})
THANOS_CLIMB = [
    '.....YYYYYY.....',
    '....YYYYYYYY....',
    '...YYYYYYYYYY...',
    '..YYYYYYYYYYYY..',
    '...kkkkkkkkkk...',
    '....YYYYYYYY....',
    '..C.YYYYYYYY.C..',
    '..C..YYYYYY..C..',
    '..CCCCCCCCCCCC..',
    '....CCCCCCCC....',
    '....CCCCCCCC....',
    '....CCCCCCCC....',
    '....CC....CC....',
    '....CC....CCC...',
    '...CCC....CC....',
    '..........CC....',
]
THANOS_FRONT = [
    '......YYYY......',
    '....YYYYYYYY....',
    '...YYYYYYYYYY...',
    '..YYYYYYYYYYYY..',
    '...kkkkkkkkkk...',
    '....YYkYYkYY....',
    '....YYYYYYYY....',
    '.....YYkkYY.....',
    '....CCCCCCCC....',
    '...CCCCCCCCCC...',
    '..CC.CCCCCC.CC..',
    '..C..CCCCCC..C..',
    '.....CCCCCC.....',
    '.....CC..CC.....',
    '.....CC..CC.....',
    '....CCC..CCC....',
]


def thanos_frames():
    return [THANOS_R, THANOS_R2, THANOS_CLIMB, hflip(THANOS_CLIMB)]


# ------------------------------------------------------------------ trap vignettes (16x16)
F = THANOS_FRONT
NOHAT = edit(F, {0: '................', 1: '................', 2: '.....YYYYYY.....',
                 3: '....YYYYYYYY....', 4: '....kkkkkkkk....'})


def vignette_frames():
    v = []
    # 0 ZAP_A: lit up white, hat blown off over his head
    v.append(paint(over(edit(F, {0: '..YYYY..........', 1: '.YYYYYY.........', 2: '................',
                                 3: '................', 4: '................'}),
                        ['................'] * 2 + ['....W.W..W.W....', '...W.WWWWWW.W...',
                                                    '....WWWWWWWW....'] + ['................'] * 11),
                   'W'))
    # 1 ZAP_B: the x-ray - a skeleton
    v.append([
        '......WWWW......', '.....W.WW.W.....', '.....WWWWWW.....', '.....W.kk.W.....',
        '......WWWW......', '.......WW.......', '...WWWWWWWWWW...', '..W....WW....W..',
        '..W..WWWWWW..W..', '..W....WW....W..', '.W...WWWWWW...W.', '.......WW.......',
        '.....WWWWWW.....', '.....W....W.....', '.....W....W.....', '....WW....WW....'])
    # 2 ZAP_C: singed - black face, hair standing up, smoking
    v.append(over(recolour(edit(F, {0: '...R.R..R.R.....', 1: '....R.RR.R......', 2: '................',
                                    3: '................', 4: '....RRRRRRRR....'}),
                           {'Y': 'R'}, 0, 8), blank()))
    # 3-5 BITE: the ferret on his ankle
    ferret = ['................'] * 12 + ['................', '..........WWWW..', '.........WkWWWWW',
                                         '..........W..W..']
    bite_a = over(edit(F, {5: '....YkkYYkkY....', 7: '.....YkkkkY.....'}), ferret)
    v.append(bite_a)
    v.append(over(edit(F, {5: '....YkkYYkkY....', 7: '.....YYkkYY.....', 13: '.....CC..CC.....',
                           14: '.....CC...CC....'}),
                  ['................'] * 12 + ['................', '...........WWWW.', '..........WkWWWW',
                                               '...........W..W.']))
    v.append(edit(F, {13: '.....CC..WWW....', 14: '.....CC..WWW....', 15: '....CCC.........'}))
    # 6-8 DROWN: blue, bubbles; the duck on the hat; dripping
    v.append(recolour(edit(F, {7: '.....YkkkkY.....'}), {'Y': 'B', 'C': 'B'}))
    duck = ['..........YY....', '.........YYkY...', '...YY....YYYYY..', '...YYYYYYYYY....']
    v.append(recolour(over(shift(F, 0, 2), duck + ['................'] * 12), {'C': 'B'}, 8))
    v.append(over(F, ['.....B....B.....', '................', '.B............B.', '................',
                      '..B..........B..'] + ['................'] * 11))
    # 9-11 HEAD: the lamp lands on the hat; accordion; stars
    lamp = ['.......Y........', '......YYY.......', '.....YYYYY......']
    v.append(over(shift(F, 0, 3), lamp + ['................'] * 13))
    acc = shift(over(edit(F, {}), blank()), 0, 0)
    accordion = ['................'] * 6 + ['......YYYY......', '...YYYYYYYYYY...', '...kkkkkkkkkk...',
                                          '....YYkYYkYY....', '....CCCCCCCC....', '...CCCCCCCCCC...',
                                          '....CCCCCCCC....', '...CCCCCCCCCC...', '....CC....CC....',
                                          '...CCC....CCC...']
    v.append(accordion)
    v.append(edit(F, {5: '....YWkYYkWY....'}))
    # 12-14 CUT: doors slam in from both sides; two halves; taped together
    doors = ['WW............WW'] * 16
    v.append(over(F, doors))
    halves = shift(F[:8], 2, 0) + shift(F[8:], -2, 0)
    v.append(halves)
    v.append(over(F, ['................'] * 7 + ['...WWWWWWWWWW...'] + ['................'] * 8))
    # 15-17 IMPALE: sits down on the cushion; leaps; a plaster on the seat
    sit = ['................'] * 3 + F[:8] + ['....CCCCCCCC....', '...CCCCCCCC.CC..', '..CC.......CC...',
                                             '..CC............', '................'][:5]
    v.append(sit[:16])
    v.append(edit(F, {5: '....YkkYYkkY....', 7: '.....YkkkkY.....', 10: '.CC..CCCCCC..CC.',
                      11: 'C....CCCCCC....C'}))
    v.append(over(F, ['................'] * 12 + ['.....WWWWWW.....'] + ['................'] * 3))
    # 18-20 SQUASH: walls close in; the pancake; springing back
    v.append(over(shift(F, 0, 0), ['WWW..........WWW'] * 16))
    v.append(['................'] * 12 + ['...YYYYYYYYYY...', '..kkkkkkkkkkkk..', '.CCCCCCCCCCCCCC.',
                                         'CCCCCCCCCCCCCCCC'])
    spring = ['................'] * 4 + ['......YYYY......', '....YYYYYYYY....', '...kkkkkkkkkk...',
                                         '....YYkYYkYY....', '....CCCCCCCC....', '.....W....W.....',
                                         '......W..W......', '.....W....W.....', '......W..W......',
                                         '.....W....W.....', '......W..W......', '....CCC..CCC....']
    v.append(spring)
    # 21-23 FIRE: a fireball; a walking briquette; smoking
    ball = []
    for y in range(16):
        r = ''
        for x in range(16):
            d = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** .5
            r += 'Y' if d < 4 else 'R' if d < 7.5 else '.'
        ball.append(r)
    v.append(ball)
    briq = recolour(edit(F, {0: '................', 1: '................', 2: '......rrrr......',
                             3: '....rrrrrrrr....', 4: '....rrrrrrrr....', 5: '....rrrrrWrr....',
                             6: '....rrrrrrrr....', 7: '.....rrrrrr.....'}), {'C': 'r', 'Y': 'r'})
    v.append(briq)
    v.append(over(briq, ['.......w........', '........w.......', '.......w........'] + ['................'] * 13))
    # 24-26 ICE: in a block; cracking; shards
    block = ['WWWWWWWWWWWWWWWW'] + ['W' + r[1:15] + 'W' for r in recolour(F, {'Y': 'C', 'C': 'C'})[1:15]] + \
        ['WWWWWWWWWWWWWWWW']
    v.append(recolour(block, {'C': 'C'}))
    crack = over(block, ['................', '....W...........', '.....W..........', '....W.W.........',
                         '...........W....', '..........W.....', '...........W....', '................',
                         '......W.........', '.....W.W........', '................', '.........W......',
                         '..........W.....', '................', '................', '................'])
    v.append(recolour(crack, {'W': 'W'}))
    v.append(recolour(F, {'Y': 'C'}))
    # 27-29 POISON: green, wobbling; deflated
    green = recolour(edit(F, {5: '....YkYYYYkY....'}), {'Y': 'G', 'C': 'G'})
    v.append(shift(green, -1, 0))
    v.append(shift(green, 1, 0))
    v.append(['................'] * 8 + recolour(['......YYYY......', '...YYYYYYYYYY...', '...kkkkkkkkkk...',
                                                 '....YkYYYYkY....', '...CCCCCCCCCC...', '..CCCCCCCCCCCC..',
                                                 '..CCCCCCCCCCCC..', '...CCC....CCC...'], {'Y': 'G', 'C': 'G'}))
    # 30-32 SUCK: lifted off his feet; only the legs left; spat out upside down
    v.append(shift(edit(F, {10: '.CC..CCCCCC..CC.', 11: 'C....CCCCCC....C'}), 0, -1))
    v.append(['................'] * 9 + ['.....CCCCCC.....', '.....CC..CC.....', '.....CC..CC.....',
                                        '....CCC..CCC....', '................', '................',
                                        '................'])
    v.append(vflip(F))
    # 33-35 CATAPULT: crouch; launched, arms up; landed with a plaster and feathers
    crouch = ['................'] * 3 + F[:8] + ['....CCCCCCCC....', '...CCCCCCCCCC...', '...CC......CC...',
                                                '..CCC......CCC..', '................'][:5]
    v.append(crouch)
    v.append(edit(F, {8: '.C..CCCCCCCC..C.', 9: '.CC.CCCCCCCC.CC.', 10: '..CCCCCCCCCCCC..',
                      11: '.....CCCCCC.....', 13: '.....CC..CC.....', 14: '......C..C......',
                      15: '......C..C......'}))
    v.append(over(edit(F, {5: '....YWkYYkWY....'}),
                  ['.W............W.', '..W..........W..', '................', '................',
                   '................', '..........WW....', '..........WW....'] + ['................'] * 9))
    # 36 READ: the papers held up in front of his face
    v.append(over(F, ['................'] * 4 + ['...WWWWWWWWWW...', '...WkkkkkkkkW...', '...WWWWWWWWWW...',
                                                 '...WkkkkkkWWW...', '...WWWWWWWWWW...'] + ['................'] * 7))
    # 37 PHONE: handset at his ear, eyes on the ceiling
    v.append(over(edit(F, {5: '....YkYYYkYY....'}),
                  ['................'] * 4 + ['...........WW...', '...........WW...', '...........WW...',
                                             '...........W....', '..........W.....'] + ['................'] * 7))
    assert len(v) == 38
    return v


# ------------------------------------------------------------------ outdoor people (16x16)
def people_frames():
    owner = [
        '................',
        '.....YYYYY......',
        '....YYYYYYY.....',
        '....YkYYYkY.....',
        '....YYYYYYY.....',
        '....YYkkkYY.....',
        '.....YYYYY......',
        '...MMMWRWMMM....',
        '..MMMMWRWMMMM...',
        '..MMMMWRWMMMM...',
        '..WMMMWRWMMMW...',
        '...MMMMMMMMM....',
        '...MMMMMMMMM....',
        '....MMM.MMM.....',
        '....MMM.MMM.....',
        '...MMMM.MMMM....',
    ]
    owner_talk = edit(owner, {5: '....YYWWWYY.....', 7: '...MMMWRWMMM..W.', 8: '..MMMMWRWMMMMM..',
                              10: '..WMMMWRWMMM....'})
    owner_cut = edit(owner, {7: '...MMMWRWMMMMWW.', 8: '..MMMMWRWMMMWWWW', 9: '..MMMMWRWMMMMWW.',
                             10: '..WMMMWRWMMM....'})
    owner_shrug = edit(owner, {7: '.W.MMMWRWMMM.W..', 8: '.MMMMMWRWMMMMM..', 10: '..MMMMWRWMMMM...'})
    grandma = [
        '......WWW.......',
        '.....WWWWW......',
        '....WWWWWWW.....',
        '....WYkYkYW.....',
        '.....YYYYY......',
        '......YYY.......',
        '....MMMMMMM.....',
        '...MMMMMMMMM....',
        '...YMMMMMMMY....',
        '....MMMMMMM.....',
        '....MMMMMMM.....',
        '...MMMMMMMMM....',
        '...MMMMMMMMM....',
        '.....M...M......',
        '.....M...M......',
        '....MM...MM.....',
    ]
    grandma_cheer = edit(grandma, {6: '..Y.MMMMMMM.Y...', 7: '..MMMMMMMMMMM...', 8: '....MMMMMMM.....'})
    man = [
        '................',
        '.....GGGGG......',
        '....GGGGGGGG....',
        '.....YYYYY......',
        '.....YkYkY......',
        '.....YYYYY......',
        '......YYY.......',
        '....GGGGGGG.....',
        '...GGGGGGGGG....',
        '...YGGGGGGGY....',
        '....GGGGGGG.....',
        '....BBBBBBB.....',
        '....BBB.BBB.....',
        '....BBB.BBB.....',
        '....BBB.BBB.....',
        '...BBBB.BBBB....',
    ]
    man_cheer = edit(man, {7: '..Y.GGGGGGG.Y...', 8: '..GGGGGGGGGGG...', 9: '....GGGGGGG.....'})
    kid = [
        '................', '................', '................', '................',
        '......RRRR......',
        '.....RRRRRR.....',
        '.....YYYYYY.....',
        '.....YkYYkY.....',
        '.....YYYYYY.....',
        '....RWRWRWR.....',
        '....RWRWRWR.....',
        '....YWRWRWY.....',
        '.....RRRRR......',
        '.....RR.RR......',
        '.....RR.RR......',
        '....RRR.RRR.....',
    ]
    kid_cheer = edit(kid, {9: '..Y.RWRWRWR.Y...', 10: '...RWRWRWRWR....', 11: '.....WRWRW......'})
    nephew = [
        '......BBBB......',
        '.....BBBBBB.....',
        '....BBBBBBBBBB..',
        '....YYYYYYYY....',
        '....kkkkkkkk....',
        '....YkkkkkkY....',
        '....YYYWWYYY....',
        '.....YYYYYY.....',
        '...WWWWWWWWWW...',
        '..WWWWWMMWWWWW..',
        '..W.WWWMMWWW.W..',
        '..Y.WWWWWWWW.Y..',
        '....WWWWWWWW....',
        '....BBBBBBBB....',
        '....BBB..BBB....',
        '...WWWW..WWWW...',
    ]
    nephew_step = edit(nephew, {14: '.....BBBBBB.....', 15: '.....WWWWWWW....'})
    nephew_selfie = edit(nephew, {0: '......BBBB..WWW.', 1: '.....BBBBBB.WkW.', 2: '....BBBBBBBBWWW.',
                                  3: '....YYYYYYYY.Y..', 4: '....kkkkkkkk.Y..', 5: '....YkkkkkkY.Y..',
                                  6: '....YYYWWYYY.Y..', 7: '.....YYYYYY..Y..', 8: '...WWWWWWWWWWW..',
                                  9: '..WWWWWMMWWWWW..', 10: '..W.WWWMMWWWWW..', 11: '..Y.WWWWWWWWW...'})
    worker = [
        '......YYYY......',
        '.....YYYYYY.....',
        '....YYYYYYYY....',
        '...YYYYYYYYYY...',
        '....kkkkkkkk....',
        '....YkYYYYkY....',
        '....YYkkkkYY....',
        '.....YYYYYY.....',
        '...RRRRRRRRRR...',
        '..RRRRRRRRRRRR..',
        '..R.RRRRRRRR.R..',
        '..Y.RRRRRRRR.Y..',
        '....RRRRRRRR....',
        '....RRR..RRR....',
        '....RRR..RRR....',
        '...RRRR..RRRR...',
    ]
    worker_throw = edit(worker, {0: 'WWW...YYYY......', 1: 'WWW..YYYYYY.....', 2: '.W..YYYYYYYY....',
                                 3: '.Y.YYYYYYYYYY...', 8: '.YRRRRRRRRRRR...', 9: '..RRRRRRRRRRRR..',
                                 10: '....RRRRRRRR.R..'})
    worker_step = edit(worker, {13: '...RRR....RRR...', 14: '..RRR......RRR..', 15: '..RRR......RRR..'})
    duck = ['................'] * 6 + [
        '......YYYYY.....',
        '....YYYYYYYYY...',
        '..YYYYYYYYYYYYY.',
        '...kkkkkkkkkk...',
        '....YkYYkYYkY...',
        '....YYYYYYYYY...',
        '...CCCCCCCCCCC..',
        '..CCCCCCCCCCCCC.',
        '..CCCCC...CCCCC.',
        '..CCCCC...CCCCC.']
    # the owner indoors: the same, his suit (magenta) shows on black anyway
    return [owner, owner_talk, owner_cut, owner_shrug, grandma, grandma_cheer, man, man_cheer,
            kid, kid_cheer, nephew, nephew_step, nephew_selfie, worker, worker_throw, duck,
            worker_step]


# ------------------------------------------------------------------ hazards (8x8, masked)
def hazard_frames():
    h = [
        ['......Y.', '.WWWW.Y.', '.WkkW..Y', '.WWWW.Y.', '.WkkW..Y', '.WWWW...', '........', '........'],  # electric
        ['........', '.WWWW...', '.WkkW...', '.WWWW...', '.WkkW...', '.WWWW...', '........', '........'],  #   taped
        ['........', 'WWWWWWWW', 'WkWkWkWW', 'WRkRkWkW', 'WkWkWkWW', 'WWWWWWWW', '........', '........'],  # bite
        ['........', 'WWWWWWWW', 'WkWkWkWW', 'WkWkWkWW', 'WkWkWkWW', 'WWWWWWWW', '........', '........'],  #   locked
        ['........', 'BBBBBBBB', 'BBBkkBBB', 'BBBBBBBB', '....B...', '........', '....B...', '........'],  # drown
        ['........', 'BBBBBBBB', 'BBBkkBBB', 'BBBBBBBB', '........', '........', '........', '........'],  #   fixed
        ['...Y....', '....Y...', '...Y....', '..YYY...', '.YYYYY..', 'YYYYYYY.', '..Y.Y...', '........'],  # head
        ['...Y....', '...Y....', '...Y....', '..YYY...', '.YYYYY..', 'YYYYYYY.', '..Y.Y...', '........'],  #   fixed
        ['........', '.WWWWW..', '.WkkkW..', '.WkRkW..', '.WkkkW.R', '.WWWWW..', '...R....', '........'],  # cut
        ['........', '.WWWWW..', '.WkkkW..', '.WkWkW..', '.WkkkW..', '.WWWWW..', '........', '........'],  #   reset
        ['........', '........', '........', '........', '.MMMMMM.', 'MWMWMWMM', 'MMMMMMMM', '........'],  # impale
        ['........', '........', '........', '........', '.MMMMMM.', 'MMMMMMMM', 'MMMMMMMM', '........'],  #   cushion
        ['WWWWWWWW', 'WkWkkWkW', 'WWWWWWWW', 'WkkWkWkW', 'WWWWWWWW', '...W....', '...W....', '...W....'],  # squash
        ['WWWWWWWW', 'WkkkkkkW', 'WWWWWWWW', 'WkkkkkkW', 'WWWWWWWW', '...W....', '...W....', '...W....'],  #   struck
        ['.R......', '..R.....', '.R......', '........', '...R....', '..RYR...', '..RRR...', 'RRRRRRR.'],  # fire
        ['........', '........', '........', '........', '........', '...R....', '........', 'RRRRRRR.'],  #   off
        ['CCCCCCCC', 'CkCCCCCC', 'CkkkkkCC', 'CkCWCkCC', 'CkkkkkCC', 'CkCCCCCC', 'CCCCCCCC', 'CCCCCCCC'],  # ice
        ['CCCCCCCC', 'CkCCCCCC', 'CkkkkkCC', 'CkCCCkCC', 'CkkkkkCC', 'CkCCCCCC', 'CCCCCCCC', 'CCCCCCCC'],  #   fixed
        ['........', '.GGGGG..', '.GkkkG..', '.GGGGG..', '.GkkkG..', '.GGGGG..', '...G....', '..GGG...'],  # poison
        ['........', '.GGGGG..', '.GkkkG..', '.GGGGG..', '.GkkkG..', '.GGGGG..', '........', '........'],  #   sealed
        ['WWWWWWWW', 'WkkkkkkW', 'WkkkkkkW', 'WkkkkkkW', 'WkkkkkkW', 'WWWWWWWW', 'W.W.W...', '........'],  # suck
        ['WWWWWWWW', 'WkWkWkWW', 'WkWkWkWW', 'WkWkWkWW', 'WkWkWkWW', 'WWWWWWWW', '........', '........'],  #   grille
        ['...Y....', '...W....', '..Y.Y...', '...Y....', '...Y....', '...Y....', 'YYYYYYYY', 'YkYkYkYk'],  # catapult
        ['...Y....', '...Y....', '...Y....', '...Y....', '...Y....', '...Y....', 'YYYYYYYY', 'YkYkYkYk'],  #   cable
        ['........', '........', '.YYYYYY.', '.YWWWWY.', '.YWkkWY.', '.YWWWWY.', '.YYYYYY.', '........'],  # evidence
        ['........'] * 8,                                                                                   #   taken
        # thrown by workers: hammer, wrench, nails - two spinning frames each
        ['........', '.WWW....', 'WWWWW...', 'WWWWYYYY', 'WWWWW...', '.WWW....', '........', '........'],
        ['..WWWWW.', '.WWWWWWW', '..WWYWW.', '....Y...', '....Y...', '....Y...', '....Y...', '........'],
        ['........', 'WW....WW', '.W....W.', '.WWWWWW.', '.W....W.', 'WW....WW', '........', '........'],
        ['WW......', 'W.W.....', '.WWW....', '...WW...', '....WWW.', '.....W.W', '......WW', '........'],
        ['........', '........', 'CWWWWW..', '........', '...CWWWW', '........', '........', '........'],
        ['........', '........', '..CWWWWW', '........', 'CWWWWW..', '........', '........', '........'],
        # particles: spark, bubble, flame, smoke, star, ice shard, skull, feather
        ['...Y....', '..YY....', '.YY.....', 'YYYYYY..', '....YY..', '...YY...', '..YY....', '.Y......'],
        ['..BBBB..', '.B....B.', 'B..B...B', 'B.B....B', 'B......B', 'B......B', '.B....B.', '..BBBB..'],
        ['...R....', '..RR..R.', '..RRR.R.', '.RRRRRR.', '.RRYYRR.', 'RRYYYYRR', 'RRYYYYRR', '.RRRRRR.'],
        ['...ww...', '..wwww..', '.ww.www.', 'wwwww.ww', 'ww.wwwww', '.wwwwww.', '..wwww..', '........'],
        ['...Y....', '...Y....', 'YYYYYYY.', '.YYYYY..', '..YYY...', '.YY.YY..', '.Y...Y..', '........'],
        ['....C...', '...CC...', '..CCC...', '.CCC....', 'CCC.....', 'CC......', 'C.......', '........'],
        ['.WWWWW..', 'WWWWWWW.', 'WkkWkkW.', 'WkkWkkW.', 'WWWkWWW.', '.WWWWW..', '.W.W.W..', '........'],
        ['......W.', '.....WW.', '....WWW.', '...WWW..', '..WWW...', '.WWW....', 'WW......', 'W.......'],
    ]
    assert len(h) == 40
    return h


# ------------------------------------------------------------------ font (6x8)
# Glyph order: FONT_CHARS in tools/zxgfx.py. 5x7 in a 6x8 cell, capitals; Greek letters
# shaped like Latin ones use the Latin glyph.
FONT = {
    ' ': ['.....'] * 7,
    'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
    'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
    'C': ['.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.'],
    'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
    'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
    'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
    'G': ['.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.####'],
    'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
    'I': ['.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.'],
    'J': ['..###', '...#.', '...#.', '...#.', '...#.', '#..#.', '.##..'],
    'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
    'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
    'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
    'N': ['#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#', '#...#'],
    'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
    'Q': ['.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#'],
    'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
    'S': ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
    'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
    'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
    'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '#.#.#', '.#.#.'],
    'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
    'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
    'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
    '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
    '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
    '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
    '3': ['####.', '....#', '....#', '.###.', '....#', '....#', '####.'],
    '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
    '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
    '6': ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
    '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
    '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
    '9': ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
    '.': ['.....', '.....', '.....', '.....', '.....', '.##..', '.##..'],
    ',': ['.....', '.....', '.....', '.....', '.##..', '..#..', '.#...'],
    '!': ['..#..', '..#..', '..#..', '..#..', '..#..', '.....', '..#..'],
    '?': ['.###.', '#...#', '....#', '...#.', '..#..', '.....', '..#..'],
    ':': ['.....', '.##..', '.##..', '.....', '.##..', '.##..', '.....'],
    ';': ['.....', '.##..', '.##..', '.....', '.##..', '..#..', '.#...'],
    '-': ['.....', '.....', '.....', '#####', '.....', '.....', '.....'],
    "'": ['..#..', '..#..', '.#...', '.....', '.....', '.....', '.....'],
    '/': ['....#', '....#', '...#.', '..#..', '.#...', '#....', '#....'],
    'Γ': ['#####', '#....', '#....', '#....', '#....', '#....', '#....'],
    'Δ': ['..#..', '.#.#.', '.#.#.', '#...#', '#...#', '#...#', '#####'],
    'Θ': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '.###.'],
    'Λ': ['..#..', '.#.#.', '.#.#.', '#...#', '#...#', '#...#', '#...#'],
    'Ξ': ['#####', '.....', '.....', '.###.', '.....', '.....', '#####'],
    'Π': ['#####', '#...#', '#...#', '#...#', '#...#', '#...#', '#...#'],
    'Σ': ['#####', '#....', '.#...', '..#..', '.#...', '#....', '#####'],
    'Φ': ['..#..', '.###.', '#.#.#', '#.#.#', '#.#.#', '.###.', '..#..'],
    'Ψ': ['#.#.#', '#.#.#', '#.#.#', '.###.', '..#..', '..#..', '..#..'],
    'Ω': ['.###.', '#...#', '#...#', '#...#', '.#.#.', '.#.#.', '##.##'],
}
FONT_CHARS = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?:;-'/ΓΔΘΛΞΠΣΦΨΩ"


def font_frames():
    out = []
    for ch in FONT_CHARS:
        g = FONT[ch]
        assert len(g) == 7 and all(len(r) == 5 for r in g), ch
        out.append([r.replace('#', 'W') + '.' for r in g] + ['......'])
    return out


# ------------------------------------------------------------------ Tasha (32x32 portrait)
# Two frames: mouth shut and open, differing only inside the 16x8 patch at (8,22).
# Colour cells (8x8): curlers yellow, hair red, face white, handset/blouse cyan.
TASHA = [
    '................................',
    '.....YY...YY...YY...YY..........',
    '....YYYY.YYYY.YYYY.YYYY.........',
    '.....YY...YY...YY...YY..........',
    '...RRRRRRRRRRRRRRRRRRRRRR.......',
    '..RRRRRRRRRRRRRRRRRRRRRRRR......',
    '.RRRRRRRRRRRRRRRRRRRRRRRRRR.....',
    'RRRRRRRRRRRRRRRRRRRRRRRRRRRR....',
    'RRRR.....................RRR....',
    'RRR..WW...........WW......RR....',
    'RR..W..W.........W..W.....RR....',
    'RR.......................RRR....',
    'RR..WWWW.........WWWW....RR..CC.',
    'RR..WkkW.........WkkW....RR.CCCC',
    'RR..WWWW.........WWWW.....R.CCCC',
    'RR........................R.CCCC',
    'RR..........WW............R..CC.',
    'RR...........W..............CC..',
    'RR..........WW.............CC...',
    'RR.........................C....',
    'RR........................CC....',
    'RR........................C.....',
    'RR........................C.....',
    'RR.......WWWWWWWWW.......CC.....',
    'RR.........................CC...',
    'RR..........................CC..',
    'RRR........................CCCC.',
    'RRRR.......................CCCC.',
    '.RRRWW..................WW..CC..',
    '..RR.WWWWWWWWWWWWWWWWWWWW.......',
    '.....CCCCCCCCCCCCCCCCCCCC.......',
    '....CCCCCCCCCCCCCCCCCCCCCC......',
]
MOUTH_OPEN = {          # (8,22) 16x8: the open mouth, over the shut one
    22: '..WWWWWWWWW.....',
    23: '.W.........W....',
    24: '.W.kkkkkkk.W....',
    25: '..WWWWWWWWW.....',
}
TASHA_OPEN = [r[:8] + MOUTH_OPEN.get(y, r[8:24] if not 22 <= y < 30 else '.' * 16) + r[24:]
              for y, r in enumerate(TASHA)]


def tasha_frames():
    # the face is filled white where it is drawn as outline: fill the inside (paper is black)
    return [TASHA, TASHA_OPEN]


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    only = set(argv[1:])
    sheets = {
        'tiles': (tile_frames, 8, 8, False),
        'thanos': (thanos_frames, 16, 16, True),
        'vignettes': (vignette_frames, 16, 16, True),
        'people': (people_frames, 16, 16, True),
        'hazards': (hazard_frames, 8, 8, True),
        'font': (font_frames, 6, 8, True),
        'tasha': (tasha_frames, 32, 32, False),
    }
    for name, (fn, w, h, tr) in sheets.items():
        if only and name not in only:
            continue
        strip(name, fn(), w, h, tr)


if __name__ == '__main__':
    main(sys.argv)
