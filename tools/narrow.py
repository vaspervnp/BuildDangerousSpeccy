#!/usr/bin/env python3
"""One-off conversion of the CPC's 40-column rooms to the Spectrum's 32 columns.

  narrow.py ../BuildDangerousCPC/assets      writes assets/rooms/*.txt, assets/buildings/*.txt

The CPC screen is 40 cells of 8 pixels across, the Spectrum's 32: every room loses 8
columns. Which ones is worked out per band of a room - rows 0-6, 7-13, 14-20 (a storey
each, with the floor slab over it) and 21-22 (the bottom slab) - so the flights of
stairs, which zig-zag across the whole width, can all be kept:

  * a column a band keeps whole: the edges, stairs, escalators, ladders, doors, the exit,
    hazards, walls, and both halves of anything two or three cells wide (windows, sofas,
    desks...); a column holding a picture, a lamp or a plant can go, at a cost;
  * where a band meets the band under it - the slab row, the top step of a flight or a
    ladder, a trap in the floor - both bands must have taken out as many columns to its
    left (so the step stays where the floor above leads to it), and the band above none
    of the five round it;
  * a flight through a ceiling: the room above must have taken out as many columns to the
    left of where it carries on as this room to the left of where it leaves.

The counts at those meeting points are the unknowns (one per set of points tied together);
a band's choice given them is a small dynamic programme over its columns, the counts are
found by coordinate descent. Columns that every band of a room can lose are preferred, so
the storeys keep their windows over each other. Once converted, the Spectrum's rooms are
the source: this script is kept to show where they came from.
"""
import os
import random
import sys

OLD_W, NEW_W, ROOM_H = 40, 32, 23
CUT = OLD_W - NEW_W
BANDS = [(0, 7), (7, 14), (14, 21), (21, 23)]
SLABS = (7, 14, 21)
STAIR_DX = {'/': 1, '\\': -1}
KEEP = set('/\\uUnN[]DdXx#swyzkKbeRMJ')    # columns holding these stay
PAIRS = set('hA$')                         # these stay only when next to their own kind
DECOR2 = set('FfBEWV')                     # two cells high: losing one loses both


def band_of(row):
    for i, (a, b) in enumerate(BANDS):
        if a <= row < b:
            return i
    raise ValueError(row)


def read_room(path):
    head, grid, extra = [], [], []
    for line in open(path, encoding='utf-8').read().split('\n'):
        if line.startswith(';'):
            head.append(line)
        elif line.startswith(('hazard ', 'nephew ', 'worker ', 'owner ')):
            extra.append(line.split())
        elif line:
            grid.append(line)
    assert len(grid) == ROOM_H and all(len(r) == OLD_W for r in grid), path
    return head, grid, extra


class Room:
    def __init__(self, name, path):
        self.name = name
        self.head, self.grid, self.extra = read_room(path)
        self.hazards = [(int(e[2]), int(e[3])) for e in self.extra if e[0] == 'hazard']
        # cost[band][col]: None = must stay
        self.cost = [[0.0] * OLD_W for _ in BANDS]
        for b, (r0, r1) in enumerate(BANDS):
            for x in range(OLD_W):
                c = 0.0
                if x in (0, OLD_W - 1):
                    c = None
                for y in range(r0, r1):
                    ch = self.grid[y][x]
                    if c is None:
                        break
                    if ch == '#' and y not in (0, 21, 22) and y not in SLABS:
                        c = None
                    elif ch in KEEP - {'#'}:
                        c = None
                    elif ch in PAIRS and ((x > 0 and self.grid[y][x - 1] == ch) or
                                          (x < OLD_W - 1 and self.grid[y][x + 1] == ch)):
                        c = None
                    elif ch in DECOR2:
                        c += 1.0
                    elif ch not in '.=# ':
                        c += 1.0
                if c is not None and any(hx == x and r0 <= hy < r1 for hx, hy in self.hazards):
                    c = None
                self.cost[b][x] = c
        # the meeting points with the band below: (slab row, col)
        self.anchors = []
        for y in SLABS:
            for x in range(OLD_W):
                if self.grid[y][x] not in '=#' or (x, y) in self.hazards:
                    self.anchors.append((y, x))
                    for dx in range(-2, 3):         # the band above keeps the columns round it
                        if 0 <= x + dx < OLD_W:
                            self.cost[band_of(y) - 1][x + dx] = None


def solve(rooms, links):
    """rooms: name -> Room; links: (lower, upper) pairs. Returns name -> [removed cols per band]."""
    # tie points: node (room, band, col); union-find over them
    parent = {}

    def find(a):
        parent.setdefault(a, a)
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a, b):
        parent[find(a)] = find(b)

    pts = {(n, b): set() for n in rooms for b in range(len(BANDS))}
    for n, r in rooms.items():
        for y, x in r.anchors:
            b = band_of(y)
            pts[(n, b)].add(x)
            pts[(n, b - 1)].add(x)
            union((n, b, x), (n, b - 1, x))
    for lo, up in links:
        for x, c in enumerate(rooms[lo].grid[0]):
            if c in STAIR_DX:
                dx = STAIR_DX[c]
                pts[(lo, 0)].add(x)
                pts[(up, 3)].add(x + dx)
                union((lo, 0, x), (up, 3, x + dx))
    classes = sorted({find((n, b, x)) for (n, b), xs in pts.items() for x in xs})
    cls_of = {(n, b, x): classes.index(find((n, b, x))) for (n, b), xs in pts.items() for x in xs}
    prefer = {n: set() for n in rooms}

    def band_dp(n, b, k):
        """Cheapest CUT columns for band b of room n with the prefix counts k at its points.
        Returns (cost, cols) or (inf, None)."""
        cost = rooms[n].cost[b]
        need = {x: k[cls_of[(n, b, x)]] for x in pts[(n, b)]}
        INF = float('inf')
        best = [INF] * (CUT + 1)
        best[0] = 0.0
        choice = []
        for x in range(OLD_W):
            if x in need:                       # removed to the left of x so far
                best = [v if i == need[x] else INF for i, v in enumerate(best)]
            nb = list(best)
            ch = [False] * (CUT + 1)
            c = cost[x]
            if c is not None:
                c += 0.0 if x in prefer[n] else 0.4
                for i in range(CUT):
                    if best[i] + c < nb[i + 1]:
                        nb[i + 1] = best[i] + c
                        ch[i + 1] = True
            choice.append(ch)
            best = nb
        if best[CUT] == INF:
            return INF, None
        cols, i = [], CUT
        for x in range(OLD_W - 1, -1, -1):
            if choice[x][i]:
                cols.append(x)
                i -= 1
        return best[CUT], sorted(cols)

    def total(k):
        s = 0.0
        for n in rooms:
            for b in range(len(BANDS)):
                c, _ = band_dp(n, b, k)
                s += c
                if s == float('inf'):
                    return s
        return s

    # Depth-first over the classes, pruned by each band's capacity between its assigned
    # points; then coordinate descent from the first few complete assignments.
    free = {(n, b): [x for x in range(OLD_W) if rooms[n].cost[b][x] is not None]
            for n in rooms for b in range(len(BANDS))}
    by_class = [[] for _ in classes]
    for (n, b, x), c in cls_of.items():
        by_class[c].append((n, b))

    def band_ok(n, b, k):
        prev_x, prev_k = 0, 0
        for x in sorted(pts[(n, b)]):
            v = k[cls_of[(n, b, x)]]
            if v is None:
                continue
            room = sum(1 for c in free[(n, b)] if prev_x <= c < x)
            if v < prev_k or v - prev_k > room:
                return False
            prev_x, prev_k = x, v
        room = sum(1 for c in free[(n, b)] if c >= prev_x)
        return CUT - prev_k <= room

    order = sorted(range(len(classes)), key=lambda i: -len(by_class[i]))
    k = [None] * len(classes)
    found = []

    def dfs(i):
        if len(found) >= 6:
            return
        if i == len(order):
            found.append(list(k))
            return
        c = order[i]
        guess = round(CUT * classes[c][2] / OLD_W)
        for v in sorted(range(CUT + 1), key=lambda v: abs(v - guess)):
            k[c] = v
            if all(band_ok(n, b, k) for n, b in set(by_class[c])):
                dfs(i + 1)
                if len(found) >= 6:
                    break
        k[c] = None

    sys.setrecursionlimit(10000)
    dfs(0)
    best_k, best_s = None, float('inf')
    for k in found:
        s = total(k)
        for _ in range(6):
            improved = False
            for i in range(len(classes)):
                for v in range(CUT + 1):
                    if v == k[i]:
                        continue
                    old = k[i]
                    k[i] = v
                    t = total(k)
                    if t < s:
                        s, improved = t, True
                    else:
                        k[i] = old
            if not improved:
                break
        if s < best_s:
            best_s, best_k = s, list(k)
    # line the storeys up: prefer what most bands of a room took out, and solve again
    for _ in range(3):
        for n in rooms:
            votes = {}
            for b in range(len(BANDS)):
                for x in band_dp(n, b, best_k)[1]:
                    votes[x] = votes.get(x, 0) + 1
            prefer[n] = set(sorted(votes, key=lambda x: (-votes[x], x))[:CUT])
        s = total(best_k)
        for i in range(len(classes)):
            for v in range(CUT + 1):
                old = best_k[i]
                best_k[i] = v
                t = total(best_k)
                if t < s:
                    s = t
                else:
                    best_k[i] = old
    return {n: [band_dp(n, b, best_k)[1] for b in range(len(BANDS))] for n in rooms}


def remap(cols, x):
    """New column of old column x, given the band's removed columns."""
    return x - sum(1 for c in cols if c < x)


def write_room(r, removed, path):
    out = list(r.head)
    for y, row in enumerate(r.grid):
        cols = removed[band_of(y)]
        out.append(''.join(ch for x, ch in enumerate(row) if x not in cols))
    for e in r.extra:
        if e[0] == 'hazard':
            x, y = int(e[2]), int(e[3])
            out.append(f"hazard {e[1]} {remap(removed[band_of(y)], x)} {y}")
        else:
            xmin, xmax, feet = int(e[1]), int(e[2]), int(e[3])
            cols = removed[band_of(feet)]
            out.append(f"{e[0]} {remap(cols, xmin)} {remap(cols, xmax)} {feet}")
    open(path, 'w', encoding='utf-8').write('\n'.join(out) + '\n')


def main():
    """narrow.py [CPC assets] [--json FILE]: --json only writes which columns each band of
    each room lost (to move the CPC's test scripts over), and touches no room."""
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    src = args[0] if args else '../BuildDangerousCPC/assets'
    json_out = sys.argv[sys.argv.index('--json') + 1] if '--json' in sys.argv else None
    if json_out:
        args = [a for a in args if a != json_out]
    maps = {}
    done = set()
    for bf in sorted(os.listdir(os.path.join(src, 'buildings'))):
        lines = open(os.path.join(src, 'buildings', bf), encoding='utf-8').read().split('\n')
        names, links = [], []
        for line in lines:
            p = line.split(';', 1)[0].split()
            if p and p[0] == 'room':
                names.append(p[1])
                for kv in p[2:]:
                    k, _, v = kv.partition('=')
                    if k == 'up':
                        links.append((p[1], v))
        rooms = {n: Room(n, os.path.join(src, 'rooms', n + '.txt')) for n in names}
        removed = solve(rooms, links)
        if removed is None:
            sys.exit(f"{bf}: no way to take {CUT} columns out of every room")
        maps.update(removed)
        if json_out:
            continue
        for n, r in rooms.items():
            write_room(r, removed[n], os.path.join('assets', 'rooms', n + '.txt'))
            lost = sum(r.cost[b][x] for b in range(len(BANDS)) for x in removed[n][b])
            print(f"{bf}: {n}: {[c for c in removed[n]]} decor lost {lost:.0f}")
            done.add(n)
        out = []
        for line in lines:
            p = line.split()
            if p and p[0] == 'start':
                y = int(p[3]) - 2               # screen row (2 HUD rows on the CPC)
                x = remap(removed[p[1]][band_of(y + 1)], int(p[2]))
                line = f"start {p[1]} {x} {y + 1}"   # 1 HUD row on the Spectrum
            out.append(line)
        open(os.path.join('assets', 'buildings', bf), 'w', encoding='utf-8').write('\n'.join(out))
    if json_out:
        import json
        json.dump(maps, open(json_out, 'w'))


if __name__ == '__main__':
    main()
