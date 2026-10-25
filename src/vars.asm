; ---------------------------------------------------------------- variables
; RAM above the loaded binary (see main.asm): zeroed at boot, not in the file.

keys:           defs 1
keys_new:       defs 1          ; pressed this frame, not the previous one
kb_matrix:      defs 9          ; 8 half-rows and the Kempston
lang:           defs 1          ; LANG_EN / LANG_GR

framecnt:       defs 1          ; hw.asm: frames (50 Hz interrupts)
ay_present:     defs 1          ; a 128K's AY: the sound goes there, else the beeper
kempston_on:    defs 1
border_col:     defs 1
beep_seed:      defs 2          ; the beeper's noise
bld_attr:       defs 1          ; the building's colour: BRIGHT ink (zxgfx.py PALETTES)
xlat_mode:      defs 1          ; video.asm: XM_NORMAL / XM_BLACK
fx_paper:       defs 1          ; a trap's flash: paper colour << 3, 0 = none
pc_glyph:       defs 2          ; text.asm: the glyph line being printed
pc_attr:        defs 1
pc_col:         defs 1
pc_k1:          defs 1          ; keep masks for the bytes a character covers
pc_k2:          defs 1
pc_k3:          defs 1
pc_bytes:       defs 3

pl_x:           defs 1          ; pl_x/pl_y adjacent: `ld de,(pl_x)` gives E=x, D=y
pl_y:           defs 1
pl_state:       defs 1          ; PS_*
pl_dir:         defs 1
pl_anim:        defs 1
pl_climb:       defs 1
pl_wait:        defs 1
pl_onladder:    defs 1
pl_stair:       defs 1          ; tile flags of the step he stands on mid-flight, else 0
pl_stepped:     defs 1          ; 1: this step was along a flight (walking pose, not climbing)
old_xy:         defs 2

game_state:     defs 1          ; GS_*
camp_ptr:       defs 2          ; campaign being played
camp_index:     defs 1          ; its current building
evidence:       defs 1          ; non-zero once the owner's papers are found
hi_score:       defs 3          ; BCD, this session
big_pen:        defs 1          ; double-size text
big_src:        defs 2
big_top:        defs 2
big_bottom:     defs 2
big_left:       defs 1
big_right:      defs 1
outcome:        defs 1          ; OUT_*
score:          defs 3          ; BCD, most significant byte first
bonus_time:     defs 2          ; BCD, high byte first (these three are cleared together)
bonus_energy:   defs 2
bonus_clean:    defs 2
bcd_lead:       defs 1

clock_hi:       defs 1          ; seconds left, BCD; clock_hi/clock_lo adjacent
clock_lo:       defs 1
clock_frames:   defs 1
dial_step:      defs 1          ; seconds per eighth of the dial
dial_ctr:       defs 1
dial_index:     defs 1          ; 0 full .. DIAL_STEPS empty

energy:         defs 1
border_timer:   defs 1
caption_timer:  defs 1
caption_ptr:    defs 2          ; next character to type, 0 when done
caption_col:    defs 1

vig_ptr:        defs 2
vig_timer:      defs 1
vig_hazard:     defs 2
vig_col:        defs 1          ; vig_col/vig_row adjacent: where the last frame went
vig_row:        defs 1
vig_particle:   defs 1          ; P_* of the vignette playing
vig_spots:      defs 4          ; col,row of each particle drawn (row #ff: none)

bld_ptr:        defs 2          ; building being played
bld_start:      defs 1          ; room Thanos enters first
bld_sign:       defs 1          ; STR_* lit up on the facade
bld_welcome:    defs 1          ; STR_* the owner opens with
bld_rooms:      defs 1
rooms_bcd:      defs 1
bld_signed:     defs 1          ; rooms signed off
signed_bcd:     defs 1
miss_ok:        defs 1          ; BCD: Misses still graded "good"
bld_room_list:  defs 2
bld_marked:     defs MAX_ROOMS/8 ; bit per room: signed off
cur_room:       defs 1
cur_exits:      defs 4          ; neighbours: left, right, up, down (NO_EXIT = none)
miss_tally:     defs 1          ; BCD

scene_ptr:      defs 2
scene_wait:     defs 1
scene_mode:     defs 1          ; SM_*
scene_tick:     defs 1
scene_speaker:  defs 1
scene_hold:     defs 1
scene_actor:    defs 1
scene_target:   defs 1
scene_delay:    defs 1
scene_count:    defs 1
actors:         defs ACTOR_COUNT*ACT_SIZE

room_hazards:   defs 2          ; -> hazard list inside the current room's data
room_map:       defs MAP_W*MAP_H
snd_voice0:     defs V_SIZE         ; sound.asm voices
snd_voice1:     defs V_SIZE
snd_babble:     defs 7              ; one speech syllable, built on the fly
bld_calls:      defs 6              ; this building's call times (s into the inspection)
bld_elapsed:    defs 2              ; seconds into the inspection
call_next:      defs 1              ; phone.asm: next of bld_calls
call_count:     defs 1              ; script rotation, campaign-wide
rant_index:     defs 1
call_state:     defs 1              ; CS_*
call_timer:     defs 1
call_script:    defs 2
call_row:       defs 1              ; panel top row
call_choice:    defs 1              ; 0 top answer, 1 bottom
call_mouth:     defs 1
call_asked:     defs 1              ; the current line is the question
call_happy:     defs 1              ; answered right
call_q:         defs 6              ; up to 3 pairs of lines still to say
call_qlen:      defs 1
call_qpos:      defs 1
npc_on:         defs 1              ; nephew.asm: is he in this room
npc_x:          defs 1              ; npc_x/npc_y adjacent, like pl_x/pl_y
npc_y:          defs 1
npc_min:        defs 1
npc_max:        defs 1
npc_dir:        defs 1              ; 0 right, 1 left
npc_wait:       defs 1
npc_done:       defs 1              ; frames of rest left after a selfie
npc_anim:       defs 1
npc_pose:       defs 1              ; 1: phone up
selfie_step:    defs 1
selfie_timer:   defs 1
selfie_index:   defs 1
paused:         defs 1              ; ESC in a building
joy_wait:       defs 1              ; input.asm: frames one joystick fire has been held
joy_last:       defs 1              ; which: KEY_FIRE or KEY_MARK
joy_lock:       defs 1              ; both were down: nothing until both are up
call_tick:      defs 1              ; halves the answer countdown
rnd_seed:       defs 2              ; phone.asm rand
pl_jump:        defs 1              ; player.asm: steps of a jump still to go, 0 on the ground
pl_duck:        defs 1              ; 1: ducking (down held on the floor)
wk_on:          defs 1              ; workers.asm: a worker in this room
wk_x:           defs 1              ; wk_x/wk_y adjacent
wk_y:           defs 1
wk_min:         defs 1              ; his beat (wk_x..wk_max follow the room data's order)
wk_max:         defs 1
wk_dir:         defs 1              ; 0 right, 1 left
wk_anim:        defs 1
wk_step:        defs 1
wk_pose:        defs 1              ; 0 idle, 1 tool raised
wk_timer:       defs 2              ; frames to the next look / throw
wk_said:        defs 1              ; grumbled at him this visit
wk_line:        defs 1              ; grumble rotation
pj_on:          defs 1              ; the tool in flight
pj_x:           defs 1              ; pj_x/pj_row adjacent
pj_row:         defs 1
pj_dx:          defs 1
pj_gfx:         defs 1              ; first of its two spinning frames
pj_speed:       defs 1
pj_wait:        defs 1
pj_spin:        defs 1
pl_uphold:      defs 1              ; up held since a climb: let go before jumping
hint_count:     defs 1              ; hints.asm: traps hinted so far (up to HINT_COUNT)
hint_ptr:       defs 2              ; the hazard the last hint was for
hint_row:       defs 1              ; top row of the hint window, 0 when closed
hint_kind:      defs 1              ; what it says: HK_TRAP, HK_LAST, HK_MARK
sense_on:       defs 1              ; sense.asm: the "?" is up
sense_xy:       defs 2              ; its cell (E = col, D = row)
sense_tick:     defs 1              ; frames since it went up: the blink
hint_marked:    defs 1              ; a room has been signed off: no more "press M"
blackout:       defs 1              ; blackout.asm: 1 while the lights are out
blackout_timer: defs 2              ; frames to the next change, 0: not scheduled
