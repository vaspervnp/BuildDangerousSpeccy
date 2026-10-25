; ---------------------------------------------------------------- HUD band (row 0)
; Row 0, left to right (icons in cells, numbers in text columns between them):
;   hats (energy, two units per hat: a Miss costs two hats)
;   current-room checkbox, rooms signed off / rooms in the building
;   Miss icon and tally
;   clock dial (the crowd's patience) and seconds left
;   score
; Icons are tiles written into the map's HUD row, so room redraws keep them; numbers
; are printed straight to the screen and must be reprinted after a full redraw.
; Row 1: caption line, typed out a few characters per frame (keeps every frame inside
; budget) and cleared after CAPTION_FRAMES. The Spectrum has a row less than the CPC, so
; it is the room's top row (the ceiling): blanked for the caption, put back after it.

ENERGY_MAX      equ 16          ; units; shown as ENERGY_HATS hats
ENERGY_HATS     equ 8
HUD_ROW         equ 0
ENERGY_ROW      equ HUD_ROW
ENERGY_COL      equ 0           ; cells 0-7
ROOM_ICON_ROW   equ HUD_ROW
ROOM_ICON_COL   equ 8           ; cell
ROOMS_COL       equ 11          ; text column: "nn/nn", pixels 74-103
MISS_ICON_COL   equ 13          ; cell
MISS_COL        equ 18          ; text: pixels 116-127
DIAL_COL        equ 16          ; cell
CLOCK_COL       equ 22          ; text, 4 digits: pixels 140-163
SCORE_COL       equ 34          ; text, 6 digits: pixels 212-247
CAPTION_ROW     equ 1

FRAMES_PER_SECOND equ 50
DIAL_STEPS      equ 8

SCORE_DISARM    equ #0050       ; BCD
SCORE_SIGNOFF   equ #0100
SCORE_MISS      equ #0200       ; taken off
SCORE_CLEAN_SWEEP equ #0500
SCORE_EVIDENCE  equ #0500
CAPTION_FRAMES  equ 150         ; 3 seconds
CAPTION_CPF     equ 2           ; characters typed per frame

; Energy is not reset here: it carries over through the campaign.
hud_init:
        xor a
        ld (border_timer),a
        call set_border
        call caption_reset
        ld a,TILE_MISS
        ld d,HUD_ROW
        ld e,MISS_ICON_COL
        call hud_set_tile
        call hud_draw_room_status
        call hud_draw_energy
        call hud_draw_dial
        jp hud_draw_numbers

; In: A = tile, D,E = HUD cell. Writes it into the map and draws it.
hud_set_tile:
        call map_addr_keep_a
        ld (hl),a
        jp draw_cell

; Everything printed rather than tiled; needed after any full-screen redraw.
hud_draw_numbers:
        call hud_draw_rooms
        call hud_draw_misses
        call hud_draw_clock
        jp hud_draw_score

hud_draw_rooms:
        ld d,HUD_ROW
        ld e,ROOMS_COL
        ld c,PEN3_MASK
        ld hl,signed_bcd
        ld b,1
        call print_bcd
        ld a,GLYPH_SLASH
        call print_char
        inc e
        ld hl,rooms_bcd
        ld b,1
        jp print_bcd

hud_draw_misses:
        ld d,HUD_ROW
        ld e,MISS_COL
        ld c,PEN1_MASK
        ld hl,miss_tally
        ld b,1
        jp print_bcd

hud_draw_clock:
        ld d,HUD_ROW
        ld e,CLOCK_COL
        ld c,PEN3_MASK
        ld hl,clock_hi
        ld b,2
        jp print_bcd

hud_draw_dial:
        ld a,(dial_index)
        add a,TILE_DIAL_0
        ld d,HUD_ROW
        ld e,DIAL_COL
        jp hud_set_tile

hud_draw_score:
        ld d,HUD_ROW
        ld e,SCORE_COL
        ld c,PEN3_MASK
        ld hl,score
        ld b,3
        jp print_bcd_zeros

; One frame of the outside clock: a second goes every FRAMES_PER_SECOND frames, the
; dial loses an eighth every dial_step seconds. Stops at zero.
clock_update:
        ld a,(clock_hi)
        ld b,a
        ld a,(clock_lo)
        or b
        ret z
        ld hl,clock_frames
        dec (hl)
        ret nz
        ld (hl),FRAMES_PER_SECOND
        ld hl,(bld_elapsed)     ; seconds into the inspection (Tasha's call times)
        inc hl
        ld (bld_elapsed),hl
        ld a,(clock_lo)
        sub 1
        daa
        ld (clock_lo),a
        ld a,(clock_hi)
        sbc a,0
        daa
        ld (clock_hi),a
        ld b,a
        ld a,(clock_lo)
        or b
        jr z,.empty
        ld a,b                  ; the last 30 seconds tick
        or a
        jr nz,.dial_step
        ld a,(clock_lo)
        cp #31
        jr nc,.dial_step
        ld hl,sfx_tick
        call sfx_play_b
.dial_step:
        ld hl,dial_ctr
        dec (hl)
        jp nz,hud_draw_clock
        ld a,(dial_step)
        ld (hl),a
        ld a,(dial_index)
        cp DIAL_STEPS-1         ; the last eighth only goes when the clock hits zero
        jp nc,hud_draw_clock
        inc a
        jr .dial
.empty: ld a,DIAL_STEPS
.dial:  ld (dial_index),a
        call hud_draw_dial
        jp hud_draw_clock

; In: DE = BCD amount 0-9999. Saturates at 999999.
score_add:
        ld hl,score+2
        ld a,(hl)
        add a,e
        daa
        ld (hl),a
        dec hl
        ld a,(hl)
        adc a,d
        daa
        ld (hl),a
        dec hl
        ld a,(hl)
        adc a,0
        daa
        ld (hl),a
        jp nc,hud_draw_score
        ld a,#99
        jr score_fill

; In: DE = BCD amount 0-9999. Stops at 0.
score_sub:
        ld hl,score+2
        ld a,(hl)
        sub e
        daa
        ld (hl),a
        dec hl
        ld a,(hl)
        sbc a,d
        daa
        ld (hl),a
        dec hl
        ld a,(hl)
        sbc a,0
        daa
        ld (hl),a
        jp nc,hud_draw_score
        xor a
score_fill:
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        jp hud_draw_score

; Forget any caption in progress (the screen under it has been redrawn).
caption_reset:
        xor a
        ld (caption_timer),a
        ld h,a
        ld l,a
        ld (caption_ptr),hl
        ret

; In: B = energy to lose (stops at 0). Redraws the hats.
energy_lose:
        ld a,(energy)
        sub b
        jr nc,.set
        xor a
.set:   ld (energy),a
        jp hud_draw_energy

; Checkbox for the current room: empty until it has been signed off.
hud_draw_room_status:
        call room_is_marked
        ld a,TILE_CHECK_EMPTY
        jr z,.set
        ld a,TILE_CHECK_DONE
.set:   ld d,ROOM_ICON_ROW
        ld e,ROOM_ICON_COL
        jp hud_set_tile

; Hats are written into the HUD rows of the room map, so redraws keep them.
hud_draw_energy:
        ld d,ENERGY_ROW
        ld e,ENERGY_COL
.hat:   ld a,e                  ; units left for this hat = energy - 2*index
        sub ENERGY_COL
        add a,a
        ld c,a
        ld a,(energy)
        sub c
        jr c,.empty
        jr z,.empty
        dec a
        jr z,.half
        ld a,TILE_HAT_FULL
        jr .set
.half:  ld a,TILE_HAT_HALF
        jr .set
.empty: ld a,TILE_HAT_EMPTY
.set:   call map_addr_keep_a
        ld (hl),a
        call draw_cell
        inc e
        ld a,e
        cp ENERGY_COL+ENERGY_HATS
        jr nz,.hat
        ret

; map_addr that keeps A. In: D,E. Out: HL. Preserves DE.
map_addr_keep_a:
        push af
        call map_addr
        pop af
        ret

; In: A = STR_* id. The text appears over the next frames (see hud_update).
caption_show:
        push af
        call caption_blank
        pop af
        call get_string
        ld (caption_ptr),hl
        xor a
        ld (caption_col),a
        ld a,CAPTION_FRAMES
        ld (caption_timer),a
        ret

; The caption row blank, for a caption to be typed on.
caption_blank:
        ld d,CAPTION_ROW
        jp clear_row

; The caption gone: the room's top row back, and Thanos if he is up there.
caption_clear:
        ld d,CAPTION_ROW
        ld b,1
        call rows_restore
        ld a,(game_state)
        or a                    ; GS_PLAY
        ret nz
        ld a,(pl_y)
        cp CAPTION_ROW+1
        ret nc
        jp player_draw

hud_update:
        ld a,(border_timer)
        or a
        jr z,.caption
        dec a
        ld (border_timer),a
        jr nz,.caption
        call set_border         ; (A = 0: black)
.caption:
        ld hl,(caption_ptr)
        ld a,h
        or l
        jr z,.timer
        ld a,(caption_col)
        ld e,a
        ld d,CAPTION_ROW
        ld c,PEN3_MASK
        ld b,CAPTION_CPF
.char:  ld a,(hl)
        cp #ff
        jr z,.typed
        call print_char
        inc hl
        inc e
        djnz .char
        ld (caption_ptr),hl
        ld a,e
        ld (caption_col),a
        ret
.typed: ld hl,0
        ld (caption_ptr),hl
        ret
.timer: ld a,(caption_timer)
        or a
        ret z
        dec a
        ld (caption_timer),a
        ret nz
        jp caption_clear
