# Build Dangerous — ZX Spectrum

A comedy hazard-inspection game for the **ZX Spectrum 48K and 128K**, written in **Z80
assembly**. It is the Spectrum version of the [Amstrad CPC game](../BuildDangerousCPC): the
same six buildings, traps, rules, distractions, score and texts (English and Greek). The
graphics, the screen layout, the keys, the sound chip and the tape are the Spectrum's.

Inspector Thanos — immortal, deadpan, running out of contract renewals — has to sweep every
room of a building before the owner cuts the ribbon. Disarming a trap means setting it off.
The real mistake is a **Miss**: signing a room off while a trap is still live in it. The
story, the traps and the campaign are in the CPC's [scenario.md](docs/scenario.md), and
its technical plan is in [plan.md](docs/plan.md).

**Player's manual:** [English](manual.md) ([PDF](manual.pdf)) · [Ελληνικά](manual_gr.md)
([PDF](manual_gr.pdf)): loading, controls, how to play, the distractions, the buildings,
scoring and tips, with screenshots (`docs/img/`).

## Running

```bash
make
```

`make` builds `build/bd.tap` and `build/bd.tzx`, which hold a BASIC loader, the loading
screen and the code. It also builds the snapshots `build/bd48.z80` and `build/bd128.z80`.
On a 48K type `LOAD ""`; on a 128K or +2 use the Tape Loader. The game is the same on both.
A 128K plays the sound on its AY; a 48K plays it on the beeper.

## Controls

| Action | Keys | Kempston |
|---|---|---|
| Move | Q A O P, the cursor keys (CAPS SHIFT + 5–8), or 5–8 (a cursor joystick) | Stick |
| Jump / duck (on a floor) | Up / Down | Up / Down |
| Up / down a flight of stairs | Up / Down at its foot / top, then Left/Right follow it | Stick |
| Set off a trap | SPACE, ENTER or 0 | Fire |
| Sign off the current room | M | Fire 2 |
| Answer Tasha | Up / Down, then SPACE | Stick, Fire |
| Pause (in a building) | H | Fire 1 + Fire 2 |
| Leave the building (at the exit door) | Up | Up |
| Language (title screen) | L | — |
| Start / skip a scene / continue | SPACE | Fire |

## What changed for the Spectrum

- **The screen.** The CPC shows 40 cells of 8 pixels across; the Spectrum shows 32.
  `tools/narrow.py` took 8 columns out of every room, chosen separately for each storey
  (rows 0–6, 7–13, 14–20, 21–22). It kept all stairs, escalators, doors, traps and walls,
  and kept the places where a flight of stairs meets the floor or ceiling of the next
  storey or room in line. Under those rules it solves for the cheapest columns to remove.
  Furniture lost along the way: 10 pieces in 38 rooms. The Spectrum's rooms
  (`assets/rooms/*.txt`) are now the source; the script stays to show how they were made.
  The engine rooms `test` and `gallery` were made by hand, so the tests' positions carry
  over. The outdoor scene and the title were redrawn at 32 columns.
- **One row less.** The CPC has 25 rows: a 2-row HUD band and a 23-row room. The Spectrum
  has 24, so the HUD is one row. The captions are typed over the room's top row (its
  ceiling), which is put back when they go.
- **Text.** A new 6×8 font (Latin and Greek capitals), so the CPC's 40-character lines fit
  across 256 pixels: text column *n* is at pixel 8 + 6*n*. Every string is the CPC's, except
  the pause key (H instead of ESC).
- **Graphics, drawn from scratch** (`tools/zxart.py` writes `assets/gfx/*.png`; edit those or
  the script). The rooms are drawn on black: there is no wallpaper, so the moving figures
  never clash with a background. Each 8×8 cell has one colour. The floors and walls take
  the building's own colour (cyan, green, red, white, magenta, blue), and the furniture
  keeps its own. Sprites (Thanos, the townsfolk, Bambis, the workers, the owner, 38 trap
  frames) colour their four cells: the hard hat and face on top, the suit below. The
  converter gives every sprite a one-pixel black outline (its mask) so it reads over
  furniture. Hazard tells and particles are 8×8, one colour each. Tasha's portrait is
  32×32 with an open-mouth patch, as on the CPC.
- **Colour effects without inks.** The CPC changed its inks to flash, flood or black out a
  room. Here every attribute is drawn into a shadow copy (`#5B00`) and reaches the screen
  through a 256-byte table (`#5E00`). Changing the table and re-sending the 768 attributes
  does the same thing:
  - a trap's flash paints the paper, and any ink of the same colour goes black, so it shows
    as a silhouette;
  - a blackout dims everything but white;
  - a room being drawn stays black until it is complete.

  The CPC's screen jolt (a hardware scroll) is a white border flash here.
- **Sound.** The CPC's two-voice effects player, unchanged. On a 128K it writes the AY, with
  the periods scaled from the CPC's 1 MHz to 1.7734 MHz. On a 48K, the louder voice plays on
  the beeper in the time each frame leaves free: square waves for tones, a random wave for
  noise.
- **Timing.** One game loop a frame, as on the CPC, through IM 2 (`#FD00`). A play frame takes
  about 7% of the frame's time on average. Room changes take a few frames behind a blank
  screen, as on the CPC.
- **Memory.** Code and data from `#6000` (35 KB), variables above it (about 1 KB), the stack
  under `#FCFC`.
- **No splash screens.** The tape loads the loading picture (the CPC's illustration, in
  Spectrum colours, `tools/loadscreen.py`) and then the game. The CPC disk's REVIVE8BIT
  splash is not used.

## Building and testing

Requirements: [rasm](https://github.com/EdouardBERGE/rasm), and Python 3 with Pillow and the
[`z80`](https://pypi.org/project/z80/) module. `make run` needs FBZX; `make check` needs
floooh/chips (`../CPCTools/cpcemu/chips`) and the ROMs in `/usr/share/spectrum-roms`.

```bash
make            # tape and snapshots
make art        # assets/gfx/*.png again from tools/zxart.py
make test       # every tests/*.txt on the headless Spectrum, 48K and 128K
make check      # the tape loaded through the real 48K and 128K ROMs
make run        # the tape in FBZX
make manual     # manual.pdf and manual_gr.pdf from the Markdown
```

`tools/zxrun.py` is a headless Spectrum: the `z80` module plus the interrupt, keyboard,
Kempston, beeper and AY. It runs the CPC harness's script language (`run`, `goto`, `until`,
`expect`, `poke`, `shot`…), so the CPC's 17 test scripts came across with their
coordinates moved. `tools/route.py` plans a clean run through every campaign building.
`make test` re-plans those routes when a room changes, so each building is proven
completable. `make check` boots the real ROM, types `LOAD ""` and loads the tape. It then
checks that the loading screen survives, that the code is where it should be, IM 2, one
interrupt a frame, and that the AY is found only on the 128K.

## Layout

| Path | Contents |
|---|---|
| `src/` | Z80 source (rasm). `main.asm` includes the rest. `hw.asm`, `video.asm`, `input.asm`, `text.asm` and the output end of `sound.asm` are the Spectrum's; the game logic is the CPC's. |
| `src/loader.bas` | The BASIC loader, tokenised by `tools/mktap.py`. |
| `assets/rooms/`, `assets/buildings/` | Rooms (32×23 text grids, legend in `tools/zxgfx.py`) and buildings. |
| `assets/gfx/` | The art as PNGs (from `tools/zxart.py`) and the loading picture's source. |
| `assets/text/strings.txt` | Every string, `ID \| English \| Greek`. |
| `tools/zxgfx.py` | PNG → tiles, masked sprites, font, portrait; rooms, buildings and strings → asm. |
| `tools/zxart.py` | All the art, as text. |
| `tools/narrow.py` | The one-off 40 → 32 column conversion of the CPC's rooms. |
| `tools/zxrun.py`, `tools/route.py` | Test harness and route planner. |
| `tools/mktap.py`, `tools/mkz80.py`, `tools/zxcheck.py` | Tape, snapshots, real-ROM check (from the Vrouves port). |
| `manual.md`, `manual_gr.md`, `tools/mkmanual.py` | The player's manuals and their PDFs (from the CPC). |

---

**REVIVE8BIT · 2026 · VASPER**
