#!/usr/bin/env python3
"""Headless ZX Spectrum harness for Build Dangerous.

Runs the game binary on a bare Z80 (the `z80` module, no ROM), with only what the game
touches: the 50 Hz interrupt (IM 2; the bus reads #FF), the keyboard's half-rows and the
border/beeper on port #FE, the Kempston on #1F, and on --model 128 the AY (#FFFD / #BFFD).
Memory contention is not modelled. Drives it from a script and saves screenshots / checks
variables.

  zxrun.py build/bd.bin --sym build/bd.sym --script tests/smoke.txt --out build/shots

Script lines (';' starts a comment):
  run <frames> [key+key...]     hold keys (or none) for N game loops
  shot <name>                   save <out>/<name>.png
  expect <addr> <value>         assert byte at addr == value (decimal or #hex)
  poke <addr> <value>           write a byte
  pokew <addr> <value>          write a word; value may be a symbol (e.g. a building to boot)
  until <addr> <value> [keys] [max]   run frames (holding keys, or - for none) until the
                                byte equals value; fails after max frames (default 3000)
  goto <room> <x> <y> [keys] [max]    hold keys until Thanos is in that room at x, y
                                (cur_room, pl_x, pl_y); fails after max frames (default 1000)
  print <addr> [count]          print bytes (hex), e.g. the clock left at the end of a run
  psgon <reg>                   assert a sound voice is playing: 8 the events' (voice 0),
                                9 the small things' (voice 1); on a 128K its AY volume too

A game loop is one pass from wait_vbl to wait_vbl, as on the CPC: the first arrival there
is the end of the boot, not a loop.

--wav <file> renders what the AY (128K) or the beeper (48K) played to a WAV.
--video <file.mp4> records the run at 50 frames a second of emulated time, 768x576, with
the sound when --wav is given too. Needs ffmpeg.
--autophone answers Tasha like a player would: about a second after her question, Fire.
--autododge jumps like a player would: over a worker's tool, and once over Bambis.

<addr> is SYMBOL, SYMBOL+N, or *SYMBOL+N (N bytes past the pointer stored at SYMBOL).

Keys: up down left right fire mark lang esc (Q A O P, SPACE, M, L, H) and jup jdown jleft
jright jfire1 jfire2 (the Kempston).
"""
import argparse
import os
import subprocess
import sys

import z80
from PIL import Image

MODELS = {'48': (224 * 312, 3_500_000, 32), '128': (228 * 311, 3_546_900, 36)}
SLICE_T = 64

# half-row (port #FE address bit), bit
KEYS = {
    'up': (2, 0), 'down': (1, 0), 'left': (5, 1), 'right': (5, 0),
    'fire': (7, 0), 'mark': (7, 2), 'lang': (6, 1), 'esc': (6, 4),
}
KEMPSTON = {'jright': 1, 'jleft': 2, 'jdown': 4, 'jup': 8, 'jfire1': 16, 'jfire2': 32}

NORMAL = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215),
          (0, 215, 0), (0, 215, 215), (215, 215, 0), (215, 215, 215)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255),
          (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
BORDER = 24


def load_symbols(path):
    syms = {}
    if path:
        for line in open(path):
            parts = line.split()
            if len(parts) >= 2 and parts[1].startswith('#'):
                syms[parts[0].upper()] = int(parts[1][1:], 16)
    return syms


class Spectrum:
    def __init__(self, binary, org, syms, model='48'):
        self.frame_t, self.hz, self.int_len = MODELS[model]
        self.model = model
        self.m = z80.Z80Machine()
        self.m.set_memory_block(org, binary)
        self.m.pc = syms.get('START', org)
        self.m.sp = 0x5CFE
        self.org, self.end = org, org + len(binary)
        self.t = 0
        self.border = 0
        self.speaker = 0
        self.beep_log = []      # (T-state, level)
        self.ay_sel = 0
        self.ay = [0] * 16
        self.psg_log = []       # (T-state, register, value)
        self.matrix = [0] * 8   # bits pressed, per half-row
        self.kemp = 0
        self.int_pending = False
        self.busy = []          # (loop no, T-states of work from the frame's start to wait_vbl)
        self.frame_no = 0
        self.at_wait = False
        self.booted = False
        self.wait_vbl = syms.get('WAIT_VBL')
        self.frame_start_t = None
        self.video = None       # ffmpeg's stdin while recording
        self.next_frame_t = 0
        self.script_keys = []
        self.keys_now = []
        self.syms = syms
        self.phone = None       # (pl_state, call_state) addresses with --autophone
        self.choosing = 0
        self.dodge = None       # symbol addresses with --autododge
        self.jump = None        # None, or 'tool' / 'nephew' / 'retreat' while it plays out
        self.jump_frames = 0
        self.nephew_jumped = False
        self.goto_x = None      # the x a goto is heading for (same room)
        self.log = []
        self.m.set_output_callback(self.on_out)
        self.m.set_input_callback(self.on_in)
        self.m.set_get_int_vector_callback(lambda: 0xFF)
        if self.wait_vbl is not None:
            self.m.set_breakpoint(self.wait_vbl)

    def now(self):
        return self.t + SLICE_T - self.m.ticks_to_stop

    def on_out(self, addr, val):
        if not addr & 1:                                    # ULA
            self.border = val & 7
            s = (val >> 4) & 1
            if s != self.speaker:
                self.speaker = s
                self.beep_log.append((self.now(), s))
        if self.model == '128':
            if addr & 0xC002 == 0xC000:                     # #FFFD: select
                self.ay_sel = val & 15
            elif addr & 0xC002 == 0x8000:                   # #BFFD: write
                self.ay[self.ay_sel] = val
                self.psg_log.append((self.now(), self.ay_sel, val))

    def on_in(self, addr):
        if not addr & 1:
            hi = addr >> 8
            v = 0x1F
            for row in range(8):
                if not hi & (1 << row):
                    v &= ~self.matrix[row] & 0x1F
            return 0xA0 | v
        if addr & 0xFF == 0x1F:
            return self.kemp
        if self.model == '128' and addr & 0xC002 == 0xC000:
            return self.ay[self.ay_sel]
        return 0xFF

    def apply_keys(self, names):
        self.keys_now = list(names)
        self.matrix = [0] * 8
        self.kemp = 0
        for n in names:
            if n in KEMPSTON:
                self.kemp |= KEMPSTON[n]
            else:
                row, bit = KEYS[n]
                self.matrix[row] |= 1 << bit

    def set_keys(self, names):
        self.script_keys = list(names)
        self.apply_keys(names)

    def reflexes(self):
        """Once a game loop: the player's own reactions (--autophone, --autododge) on top of
        the keys the script holds."""
        self.apply_keys(self.script_keys)
        if self.phone:
            pl_state, call_state = self.phone
            if self.peek(pl_state) == 3 and self.peek(call_state) == 3:
                self.choosing += 1
                if self.choosing == 45:         # ~1 s to read, then Fire
                    self.apply_keys(self.script_keys + ['fire'])
                    return
            else:
                self.choosing = 0
        if self.dodge:
            self.dodge_reflex()

    def held(self, name):
        return name in self.script_keys

    def dodge_reflex(self):
        v = {k: self.peek(a) for k, a in self.dodge.items()}
        if self.jump == 'retreat':              # back up the stairs until the tool is gone
            self.jump_frames += 1
            if (v['wk_pose'] == 0 and v['pj_on'] == 0) or self.jump_frames > 150:
                self.jump = None
            else:
                self.apply_keys(['up'])
            return
        if self.jump:                           # a jump under way
            self.jump_frames += 1
            if v['pl_jump'] == 0 and self.jump_frames > 1:
                if self.jump_frames > 8 or self.jump == 'nephew':
                    self.jump = None            # landed (or never took off): back to the script
                    return
            if v['pl_jump'] == 0:               # not off the ground yet: Up
                keys = ['up'] + ([d for d in ('left', 'right') if self.held(d)]
                                 if self.jump == 'nephew' else [])
                self.apply_keys(keys)
            elif self.jump == 'tool':           # in the air: straight up and down
                self.apply_keys([])
            return
        if v['pl_state'] or v['pl_jump'] or v['pl_onladder']:
            return
        x, y = v['pl_x'], v['pl_y']
        if v['pl_stair']:
            near = v['wk_x'] - 1 - (x + 1) if x < v['wk_x'] else x - (v['wk_x'] + 2)
            if v['wk_pose'] == 1 and 0 <= v['wk_y'] - y <= 3 and near <= 5:
                self.jump, self.jump_frames = 'retreat', 0
                self.apply_keys(['up'])
                self.log.append(f"frame {self.frame_no}: backs up the stairs from a worker")
            return
        tool = None
        if v['pj_on'] and v['pj_row'] in (y, y + 1):
            dist = x - v['pj_x'] if v['pj_dx'] == 1 else v['pj_x'] - (x + 1)
            if 1 <= dist <= (5 if v['pj_row'] == y else 4):
                tool = 'a thrown tool'
        elif v['wk_pose'] == 1 and v['wk_y'] == y and 3 <= v['wk_timer'] <= 10:
            near = v['wk_x'] - 1 - (x + 1) if x < v['wk_x'] else x - (v['wk_x'] + 2)
            if near <= 5:
                tool = 'a tool about to be thrown'
        if tool:
            self.jump, self.jump_frames = 'tool', 0
            self.apply_keys(['up'])
            self.log.append(f"frame {self.frame_no}: jumps {tool}")
            return
        if (not self.nephew_jumped and v['npc_on'] and v['npc_y'] == y and not v['npc_done']
                and self.goto_x is not None):
            for d, sign in (('right', 1), ('left', -1)):
                gap = (v['npc_x'] - x) * sign
                if self.held(d) and 3 <= gap <= 5 and (self.goto_x - x) * sign >= 7:
                    self.jump, self.jump_frames = 'nephew', 0
                    self.nephew_jumped = True
                    self.apply_keys(['up', d])
                    self.log.append(f"frame {self.frame_no}: jumps over Bambis")
                    return

    def frame_image(self):
        mem = self.m.memory
        img = Image.new('RGB', (256 + 2 * BORDER, 192 + 2 * BORDER), NORMAL[self.border])
        px = img.load()
        for y in range(192):
            base = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
            for cx in range(32):
                b = mem[base + cx]
                a = mem[0x5800 + (y >> 3) * 32 + cx]
                pal = BRIGHT if a & 0x40 else NORMAL
                ink, paper = pal[a & 7], pal[(a >> 3) & 7]
                for k in range(8):
                    px[BORDER + cx * 8 + k, BORDER + y] = ink if b & (0x80 >> k) else paper
        return img

    def run_frames(self, n):
        """Run n game-loop iterations: stop when the game enters wait_vbl for the n-th time,
        so every frame's work is complete when a script inspects memory."""
        loops = 0
        m = self.m
        while loops < n:
            if m.pc == self.wait_vbl and self.at_wait:
                m.clear_breakpoint(self.wait_vbl)          # step past the breakpoint
                m.ticks_to_stop = 1
                m.run()
                self.t += 4
                m.set_breakpoint(self.wait_vbl)
                self.at_wait = False
            m.ticks_to_stop = SLICE_T
            events = m.run()
            t0 = self.t
            self.t += SLICE_T - m.ticks_to_stop
            if self.t // self.frame_t != t0 // self.frame_t:
                self.int_pending = True
                self.frame_start_t = (self.t // self.frame_t) * self.frame_t
            if self.int_pending and self.t % self.frame_t < self.int_len + SLICE_T:
                if m.on_handle_active_int():
                    self.int_pending = False
            elif self.t % self.frame_t >= self.int_len + SLICE_T:
                self.int_pending = False
            while self.video and self.t >= self.next_frame_t:
                self.video.write(self.frame_image().tobytes())
                self.next_frame_t += self.frame_t
            pc = m.pc
            if pc == self.wait_vbl and events & z80.Z80Machine._BREAKPOINT_HIT:
                self.at_wait = True
                if not self.booted:     # first arrival = end of boot, not a game loop
                    self.booted = True
                    continue
                loops += 1
                if self.phone or self.dodge:
                    self.reflexes()
                if self.frame_start_t is not None:
                    self.busy.append((self.frame_no, self.t - self.frame_start_t))
                    self.frame_start_t = None
                self.frame_no += 1
            if not (self.org <= pc < self.end or pc == 0xFCFC):
                raise RuntimeError(f"PC escaped the program: #{pc:04X} at T {self.t}")
            if not 0x5000 <= m.sp <= 0xFD00:
                raise RuntimeError(f"SP out of place: #{m.sp:04X} at PC #{pc:04X}")

    def peek(self, addr):
        return self.m.memory[addr & 0xFFFF]

    def poke(self, addr, value):
        self.m.memory[addr & 0xFFFF] = value & 0xFF

    def resolve(self, expr, syms):
        deref = expr.startswith('*')
        name, _, off = expr.lstrip('*').partition('+')
        addr = syms[name.upper()]
        if deref:
            addr = self.peek(addr) | (self.peek(addr + 1) << 8)
        return addr + (int(off) if off else 0)

    def screenshot(self, path):
        img = self.frame_image()
        img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(path)


def render_beeper(log, end_t, path, cpu_hz, rate=22050):
    import array
    import wave
    out = array.array('h')
    i, level = 0, 0
    for n in range(int(end_t / cpu_hz * rate)):
        t = n * cpu_hz / rate
        while i < len(log) and log[i][0] <= t:
            level = log[i][1]
            i += 1
        out.append(9000 if level else -9000)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(out.tobytes())


def render_wav(log, end_t, path, cpu_hz, rate=22050):
    """Play back AY register writes through a simple AY-3-8912 model."""
    import array
    import wave
    ay_hz = 1_773_400
    vol = [0.0] + [2 ** ((v - 15) / 2) for v in range(1, 16)]
    regs = [0] * 16
    regs[7] = 0x3F
    phase = [0.0, 0.0, 0.0]
    noise_phase, lfsr, noise_bit = 0.0, 1, 1
    out = array.array('h')
    i, n_samples = 0, int(end_t / cpu_hz * rate)
    dc = 0.0
    for n in range(n_samples):
        t = n * cpu_hz / rate
        while i < len(log) and log[i][0] <= t:
            regs[log[i][1]] = log[i][2]
            i += 1
        np_ = (regs[6] & 31) or 1
        noise_phase += ay_hz / (16 * np_) / rate
        while noise_phase >= 1:
            noise_phase -= 1
            bit = (lfsr ^ (lfsr >> 3)) & 1
            lfsr = (lfsr >> 1) | (bit << 16)
            noise_bit = lfsr & 1
        acc = 0.0
        for ch in range(3):
            p = (regs[2 * ch] | (regs[2 * ch + 1] & 15) << 8) or 1
            phase[ch] = (phase[ch] + ay_hz / (16 * p) / rate) % 1.0
            tone_on = not (regs[7] >> ch) & 1
            noise_on = not (regs[7] >> (3 + ch)) & 1
            level = ((phase[ch] < 0.5) or not tone_on) and (noise_bit or not noise_on)
            if level and (tone_on or noise_on):
                acc += vol[regs[8 + ch] & 15]
        dc += (acc - dc) * 0.002            # take the DC offset out
        out.append(max(-32767, min(32767, int((acc - dc) * 12000))))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(out.tobytes())


def parse_value(v, cpc, syms):
    """#hex, decimal, or a symbol (its address)."""
    if v.startswith('#'):
        return int(v[1:], 16)
    if v.lstrip('-').isdigit():
        return int(v)
    return cpc.resolve(v, syms)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('binary')
    ap.add_argument('--sym', required=True)
    ap.add_argument('--model', choices=('48', '128'), default='48')
    ap.add_argument('--script')
    ap.add_argument('--out', default='build/shots')
    ap.add_argument('--frames', type=int, default=50, help='frames to run when no script')
    ap.add_argument('--wav', help='render what the AY or the beeper played to this WAV file')
    ap.add_argument('--video', help='record the run to this video file (needs ffmpeg)')
    ap.add_argument('--autophone', action='store_true', help="answer Tasha's calls with Fire")
    ap.add_argument('--autododge', action='store_true',
                    help="jump thrown tools, and once over Bambis")
    args = ap.parse_args()

    syms = load_symbols(args.sym)
    org = syms.get('BIN_START', 0x6000)
    zx = Spectrum(open(args.binary, 'rb').read(), org, syms, args.model)
    os.makedirs(args.out, exist_ok=True)
    if args.autophone:
        zx.phone = (syms['PL_STATE'], syms['CALL_STATE'])
    if args.autododge:
        zx.dodge = {k: syms[k.upper()] for k in (
            'pl_state', 'pl_jump', 'pl_onladder', 'pl_stair', 'pl_x', 'pl_y', 'pj_on', 'pj_x',
            'pj_row', 'pj_dx', 'npc_on', 'npc_x', 'npc_y', 'npc_done', 'wk_pose', 'wk_x',
            'wk_y', 'wk_timer')}
    silent = None
    if args.video:
        silent = args.video + '.silent.mp4' if args.wav else args.video
        w, h = 256 + 2 * BORDER, 192 + 2 * BORDER
        ff = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo',
                               '-pix_fmt', 'rgb24', '-s', f'{w}x{h}', '-r', '50', '-i', '-',
                               '-vf', f'scale={w * 2}:{h * 2}:flags=neighbor', '-c:v', 'libx264',
                               '-pix_fmt', 'yuv420p', '-crf', '20', silent],
                              stdin=subprocess.PIPE)
        zx.video = ff.stdin

    steps = []
    if args.script:
        for raw in open(args.script):
            line = raw.split(';', 1)[0].strip()
            if line:
                steps.append(line.split())
    else:
        steps = [['run', str(args.frames)], ['shot', 'final']]

    failures = 0
    for st in steps:
        cmd = st[0]
        if cmd == 'run':
            keys = st[2].split('+') if len(st) > 2 and st[2] != '-' else []
            zx.set_keys(keys)
            zx.run_frames(int(st[1]))
        elif cmd == 'shot':
            path = os.path.join(args.out, st[1] + '.png')
            zx.screenshot(path)
            print(f"shot {path}")
        elif cmd in ('until', 'goto'):
            if cmd == 'until':
                addrs = [zx.resolve(st[1], syms)]
                want = [parse_value(st[2], zx, syms)]
                rest = st[3:]
                limit = 3000
            else:
                addrs = [syms['CUR_ROOM'], syms['PL_X'], syms['PL_Y']]
                want = [int(v) for v in st[1:4]]
                rest = st[4:]
                limit = 1000
            keys = rest[0].split('+') if rest and rest[0] != '-' else []
            if len(rest) > 1:
                limit = int(rest[1])
            zx.set_keys(keys)
            zx.goto_x = want[1] if cmd == 'goto' and want[0] == zx.peek(syms['CUR_ROOM']) else None
            n = 0
            while [zx.peek(a) for a in addrs] != want and n < limit:
                zx.run_frames(1)
                n += 1
            zx.goto_x = None
            if [zx.peek(a) for a in addrs] != want:
                failures += 1
                print(f"FAIL {' '.join(st)}: got {[zx.peek(a) for a in addrs]} after {n} frames")
                break               # the rest of a route makes no sense from the wrong place
        elif cmd == 'psgon':
            reg = int(st[1])
            voice = syms['SND_VOICE0' if reg == 8 else 'SND_VOICE1']
            got = zx.peek(voice + syms['V_VOL']) if 'V_VOL' in syms else zx.peek(voice + 7)
            ok = got != 0
            if args.model == '128':
                ok = ok and (zx.ay[reg] & 15) != 0
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} sound {reg} = {got} (expected sound)")
        elif cmd == 'print':
            addr = zx.resolve(st[1], syms)
            count = int(st[2]) if len(st) > 2 else 1
            print(f"{st[1]}: " + ' '.join(f"{zx.peek(addr + i):02x}" for i in range(count)))
        elif cmd in ('expect', 'poke', 'pokew'):
            value = parse_value(st[2], zx, syms)
            addr = zx.resolve(st[1], syms)
            if cmd == 'poke':
                zx.poke(addr, value)
                continue
            if cmd == 'pokew':
                zx.poke(addr, value & 0xFF)
                zx.poke(addr + 1, value >> 8)
                continue
            got = zx.peek(addr)
            ok = got == value
            failures += not ok
            print(f"{'ok  ' if ok else 'FAIL'} {st[1]} = {got} (expected {value})")
        else:
            sys.exit(f"unknown script command: {cmd}")

    for line in zx.log:
        print(line)
    if args.wav:
        if args.model == '128':
            render_wav(zx.psg_log, zx.t, args.wav, zx.hz)
        else:
            render_beeper(zx.beep_log, zx.t, args.wav, zx.hz)
        print(f"wav {args.wav}: {zx.t / zx.hz:.1f} s")
    if args.video:
        zx.video.close()
        ff.wait()
        if args.wav:
            subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', silent, '-i', args.wav,
                            '-c:v', 'copy', '-c:a', 'aac', '-b:a', '128k', '-shortest',
                            args.video], check=True)
            os.remove(silent)
        print(f"video {args.video}: {zx.t / zx.frame_t / 50:.1f} s")
    if zx.busy:
        frame, worst = max(zx.busy, key=lambda b: b[1])
        over = [f for f, t in zx.busy if t > zx.frame_t]
        print(f"frames: {len(zx.busy)}, worst per-frame work: {worst} T in loop {frame} "
              f"({100 * worst / zx.frame_t:.0f}% of a 50Hz frame, no contention)"
              + (f"; over budget in {len(over)} loops" if over else ""))
    if failures:
        sys.exit(f"{failures} expectation(s) failed")


if __name__ == '__main__':
    main()
