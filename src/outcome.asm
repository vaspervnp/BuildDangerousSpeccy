; ---------------------------------------------------------------- game state and outcomes
; GS_INTRO: the outdoor scene before the building (owner's speech, Thanos walks in).
; GS_PLAY: Thanos inspects. It ends one of three ways (see scenario.md):
;   win      - he leaves through the exit (every room signed off). Graded by Misses.
;   soft fail- the clock runs out with at least half the rooms signed off: the owner
;              delays the opening.
;   fail     - the clock runs out with fewer signed off (the crowd goes in), or his
;              energy runs out (contract terminated).
; GS_OUTRO: the outdoor scene for that ending.
; GS_RESULTS: the results panel over it; Fire moves the campaign on (campaign.asm).

GS_PLAY         equ 0
GS_RESULTS      equ 1
GS_INTRO        equ 2
GS_OUTRO        equ 3

OUT_WIN         equ 0
OUT_DELAY       equ 1
OUT_RIBBON      equ 2
OUT_NOENERGY    equ 3

PANEL_TOP       equ 6
PANEL_BOTTOM    equ 18
PANEL_LABEL_COL equ 8
PANEL_VALUE_COL equ 28          ; 4-digit values; the score starts 2 columns earlier

; Start building bld_ptr from scratch, with its intro. Score and energy carry over.
building_new:
        call palette_black
        ld hl,(bld_ptr)
        call building_start
        call hud_init
        call player_init
        ld a,GS_INTRO
        ld (game_state),a
        ld hl,scene_intro
        jp scene_start

; The intro is over (or skipped): Thanos is through the door.
play_begin:
        call blackout_reset
        ld a,GS_PLAY
        ld (game_state),a
        xor a
        ld (paused),a
        ld a,(bld_start)
        jp room_change

; ESC in a building: stop everything (the clock included) until ESC again.
pause_toggle:
        ld a,(paused)
        xor 1
        ld (paused),a
        ld d,1                  ; the caption row
        jr z,.resume
        call sound_init         ; silence (trashes DE)
        ld d,1
        call clear_row
        ld a,STR_PAUSED
        call get_string
        ld d,1
        ld c,PEN2_MASK
        jp print_centered
.resume:
        call caption_reset
        jp caption_clear

; A scene ended or was skipped with Fire.
scene_finish:
        ld a,(game_state)
        cp GS_INTRO
        jr z,play_begin
        ; fall through: the outro is over

results_show:
        ld a,GS_RESULTS
        ld (game_state),a
        call caption_reset
        call caption_clear
        jp outcome_draw

; Once per frame while playing, after the player has moved.
play_update:
        ld a,(pl_state)
        cp PS_DONE
        ld a,OUT_WIN
        jp z,outcome_start
        call clock_update
        ld a,(pl_state)
        cp PS_WALK
        ret nz                  ; let a trap finish playing first
        ld a,(energy)
        or a
        ld a,OUT_NOENERGY
        jp z,outcome_start
        ld a,(clock_hi)
        ld b,a
        ld a,(clock_lo)
        or b
        jp nz,phone_check       ; time left: maybe Tasha calls
        ld a,(bld_signed)       ; time's up: at least half signed off is a soft fail
        add a,a
        ld b,a
        ld a,(bld_rooms)
        cp b
        ld a,OUT_DELAY
        jr c,outcome_start
        jr z,outcome_start
        ld a,OUT_RIBBON
        ; fall through

; In: A = OUT_*. Adds the bonuses (wins only), then plays that ending's outdoor scene.
outcome_start:
        push af
        call blackout_reset     ; lights on for the crowd
        call palette_normal
        pop af
        ld (outcome),a
        ld hl,bonus_time
        ld b,6
.zero:  ld (hl),0
        inc hl
        djnz .zero
        ld a,(outcome)
        cp OUT_WIN
        jr nz,outro_start
        ld a,(clock_hi)         ; time bonus = seconds left * 10: shift the BCD a digit
        add a,a
        add a,a
        add a,a
        add a,a
        ld b,a
        ld a,(clock_lo)
        rrca
        rrca
        rrca
        rrca
        and #0f
        or b
        ld (bonus_time),a
        ld a,(clock_lo)
        add a,a
        add a,a
        add a,a
        add a,a
        ld (bonus_time+1),a
        ld a,(energy)           ; energy bonus = units * 25
        ld de,0
        or a
        jr z,.energy_done
        ld b,a
.energy:
        ld a,e
        add a,#25
        daa
        ld e,a
        ld a,d
        adc a,0
        daa
        ld d,a
        djnz .energy
.energy_done:
        ld a,d
        ld (bonus_energy),a
        ld a,e
        ld (bonus_energy+1),a
        ld a,(miss_tally)
        or a
        jr nz,.add
        ld a,SCORE_CLEAN_SWEEP>>8
        ld (bonus_clean),a
.add:   ld hl,bonus_time
        call add_bonus
        ld hl,bonus_energy
        call add_bonus
        ld hl,bonus_clean
        call add_bonus
        ; fall through

outro_start:
        ld a,GS_OUTRO
        ld (game_state),a
        ld a,(outcome)
        add a,a
        ld l,a
        ld h,0
        ld de,outro_scripts
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jp scene_start

outcome_draw:
        ld d,PANEL_TOP
.clear: call clear_row
        inc d
        ld a,d
        cp PANEL_BOTTOM+1
        jr nz,.clear
        ld d,PANEL_TOP
        call brick_row
        ld d,PANEL_BOTTOM
        call brick_row

        ld a,(outcome)          ; title and verdict
        add a,a
        ld l,a
        ld h,0
        ld de,outcome_texts
        add hl,de
        ld a,(hl)
        inc hl
        ld b,(hl)
        push bc
        ld d,PANEL_TOP+2
        ld c,PEN1_MASK
        call print_text_centered
        pop bc
        ld a,b
        or a
        call z,win_verdict
        ld d,PANEL_TOP+3
        ld c,PEN3_MASK
        call print_text_centered

        ld d,PANEL_TOP+5
        ld a,STR_LBL_MISSES
        call panel_label
        ld hl,miss_tally
        ld e,PANEL_VALUE_COL+2
        ld b,1
        call print_bcd
        ld d,PANEL_TOP+6
        ld a,STR_LBL_TIME
        ld hl,bonus_time
        call panel_line
        ld d,PANEL_TOP+7
        ld a,STR_LBL_ENERGY
        ld hl,bonus_energy
        call panel_line
        ld d,PANEL_TOP+8
        ld a,STR_LBL_CLEAN
        ld hl,bonus_clean
        call panel_line
        ld d,PANEL_TOP+9
        ld a,STR_LBL_SCORE
        call panel_label
        ld hl,score
        ld e,PANEL_VALUE_COL-2
        ld b,3
        call print_bcd_zeros
        ld d,PANEL_BOTTOM-1
        ld a,STR_PRESS_FIRE
        ld c,PEN2_MASK
        ; fall through

; In: A = STR_*, D = row, C = pen mask.
print_text_centered:
        call get_string_keep_de
        jp print_centered

; Out: A = verdict string for a win, by Misses against the building's tolerance.
win_verdict:
        ld a,(miss_tally)
        or a
        ld a,STR_OUT_CLEAN
        ret z
        ld a,(miss_ok)
        ld b,a
        ld a,(miss_tally)
        cp b
        ld a,STR_OUT_GOOD
        ret c
        ret z
        ld a,STR_OUT_BARELY
        ret

; In: D = row, A = label STR_*, HL = 2 BCD bytes. Label left, value right.
panel_line:
        push hl
        call panel_label
        pop hl
        ld e,PANEL_VALUE_COL
        ld b,2
        jp print_bcd

; In: D = row, A = label STR_*. Out: C = white pen mask.
panel_label:
        ld c,PEN3_MASK
        call get_string_keep_de
        ld e,PANEL_LABEL_COL
        jp print_str

; get_string, keeping DE. In: A = STR_*. Out: HL.
get_string_keep_de:
        push de
        call get_string
        pop de
        ret

; In: HL = 2 BCD bytes (high first). Adds them to the score.
add_bonus:
        ld d,(hl)
        inc hl
        ld e,(hl)
        jp score_add

; In: D = row. A row of bricks across the screen.
brick_row:
        ld e,0
.cell:  ld a,TILE_BRICK
        call draw_tile_at
        inc e
        ld a,e
        cp MAP_W
        jr nz,.cell
        ret

; title, verdict per OUT_* (verdict 0 = graded by win_verdict)
outcome_texts:
        db STR_EXIT_DONE, 0
        db STR_OUT_TIMEUP, STR_OUT_DELAY
        db STR_OUT_TIMEUP, STR_OUT_RIBBON
        db STR_OUT_FIRED, STR_OUT_NOENERGY

