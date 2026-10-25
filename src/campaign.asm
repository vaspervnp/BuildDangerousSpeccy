; ---------------------------------------------------------------- campaign
; Title screen -> buildings in order -> an ending.
;   win or soft fail : on to the next building (energy carries over, plus ENERGY_REFILL)
;   fail             : game over ("terminated")
;   win the last one : the good ending; it changes if Thanos found the owner's papers
;   soft fail on the last one: game over, like any fail
; GS_TITLE: the title (Fire starts, L switches language). GS_END: game over or the
; ending (Fire back to the title).

GS_TITLE        equ 4
GS_END          equ 5

ENERGY_REFILL   equ 6           ; 3 hats between buildings

; db building count, then dw building per building
campaign_main:
        db 6
        dw bld_sunnyvale, bld_mall, bld_hotel, bld_hospital, bld_hardknock, bld_skyscraper
; for the test harness (pokew boot_campaign ...)
campaign_test:                  ; the test building twice: progression and endings
        db 2
        dw bld_test, bld_test
campaign_gallery:
        db 1
        dw bld_gallery
campaign_single:                ; one building, poked in by generated route tests
        db 1
        dw bld_sunnyvale

; ---------------------------------------------------------------- title
title_show:
        ld hl,sfx_jingle
        call sfx_play
title_draw:                     ; (L redraws it in the other language, without the jingle)
        ld a,GS_TITLE
        ld (game_state),a
        ld a,BLD_ATTR_DEFAULT
        ld (bld_attr),a
        call palette_black
        call screen_clear
        ld hl,title_logo        ; BUILD in bricks on a girder, DANGEROUS in barrier stripes
        call draw_tilemap
        ld hl,thanos_gfx        ; on the girder: Thanos, and Thanos mid-electrocution
        ld de,6*256+1
        call draw_sprite16
        ld a,AF_VIGNETTE+VF_ZAP_B
        call frame_addr
        ld de,6*256+29
        call draw_sprite16
        ld a,STR_LOGO_DANGEROUS ; between the barriers: yellow on red
        call get_string
        ld d,10
        ld c,#56
        call print_big_centered
        ld a,STR_TITLE_TAG
        ld d,14
        ld c,PEN3_MASK
        call print_text_centered
        ld a,STR_TITLE_START
        ld d,15
        ld c,PEN2_MASK
        call print_text_centered
        ld a,STR_TITLE_LANG
        ld d,16
        ld c,PEN1_MASK
        call print_text_centered
        ld a,STR_TITLE_KEYS1
        ld d,18
        ld c,PEN3_MASK
        call print_text_centered
        ld a,STR_TITLE_KEYS2
        ld d,19
        ld c,PEN3_MASK
        call print_text_centered
        ld a,STR_TITLE_KEYS3
        ld d,20
        ld c,PEN3_MASK
        call print_text_centered
        ld d,21
        call hiscore_line
        ld a,STR_TITLE_CREDIT
        ld d,23
        ld c,PEN1_MASK
        call print_text_centered
        jp palette_normal

title_update:
        ld a,(keys_new)
        and KEY_LANG
        jr z,.start
        ld a,(lang)
        xor 1
        ld (lang),a
        jp title_draw
.start: ld a,(keys_new)
        and KEY_FIRE
        ret z
        ; fall through

; ---------------------------------------------------------------- the campaign
campaign_start:
        ld hl,(boot_campaign)
        ld (camp_ptr),hl
        xor a
        ld (camp_index),a
        ld (evidence),a
        ld (call_count),a       ; Tasha's calls start from the first script
        ld (rant_index),a
        ld (selfie_index),a
        ld (hint_count),a       ; the first-trap hints again
        ld (hint_marked),a      ; and the sign-off one
        ld h,a
        ld l,a
        ld (hint_ptr),hl
        ld hl,score
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        ld a,ENERGY_MAX
        ld (energy),a
        ; fall through

; Start the campaign's current building (camp_index).
campaign_building:
        ld a,(camp_index)
        add a,a
        inc a
        ld hl,(camp_ptr)
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld (bld_ptr),hl
        jp building_new

; Results panel, Fire: on to the next building, or an ending.
outcome_update:
        ld a,(keys_new)
        and KEY_FIRE
        ret z
        ld a,(outcome)
        cp OUT_RIBBON
        jr nc,gameover_show     ; the ribbon was cut, or he ran out of energy
        ld hl,camp_index
        inc (hl)
        ld a,(hl)
        ld hl,(camp_ptr)
        cp (hl)
        jr nc,.last
        ld a,(energy)
        add a,ENERGY_REFILL
        cp ENERGY_MAX+1
        jr c,.refilled
        ld a,ENERGY_MAX
.refilled:
        ld (energy),a
        jr campaign_building
.last:  ld a,(outcome)
        cp OUT_WIN
        jr z,ending_show
        ; a soft fail on the last building ends like a fail

; ---------------------------------------------------------------- endings
gameover_show:
        call end_screen
        ld hl,sfx_trombone
        call sfx_play
        ld a,STR_OVER_BIG
        ld d,3
        ld c,PEN1_MASK
        call big_text
        ld d,2                  ; the stamp's frame
        call brick_row
        ld d,6
        call brick_row
        ld a,AF_UPSIDE_DOWN
        call frame_addr
        ld de,8*256+15
        call draw_sprite16
        ld a,STR_OVER_1
        ld d,12
        call end_line
        ld a,STR_OVER_2
        ld d,14
        call end_line
        jr end_screen_done

ending_show:
        call end_screen
        ld hl,sfx_fanfare
        call sfx_play
        ld a,STR_END_BIG
        ld d,3
        ld c,PEN1_MASK
        call big_text
        ld hl,thanos_gfx
        ld de,8*256+15
        call draw_sprite16
        ld a,(evidence)
        or a
        jr z,.plain
        ld a,STR_END_EVIDENCE1
        ld d,11
        call end_line
        ld a,STR_END_EVIDENCE2
        ld d,13
        call end_line
        ld a,STR_END_EVIDENCE3
        ld d,15
        call end_line
        jr end_screen_done
.plain: ld a,STR_END_PLAIN1
        ld d,12
        call end_line
        ld a,STR_END_PLAIN2
        ld d,14
        call end_line
        ; fall through

; Final score, hi-score, "press fire".
end_screen_done:
        ld d,18
        ld a,STR_LBL_FINAL
        call panel_label
        ld hl,score
        ld e,PANEL_VALUE_COL-2
        ld b,3
        call print_bcd_zeros
        ld d,20
        call hiscore_line
        ld a,STR_PRESS_FIRE
        ld d,23
        ld c,PEN2_MASK
        call print_text_centered
        jp palette_normal

; Blank screen for an ending; records the hi-score first.
end_screen:
        ld a,GS_END
        ld (game_state),a
        call hiscore_update
        call caption_reset
        call palette_black
        jp screen_clear

end_update:
        ld a,(keys_new)
        and KEY_FIRE
        ret z
        jp title_show

; In: A = STR_*, D = row. White, centred.
end_line:
        ld c,PEN3_MASK
        jp print_text_centered

; In: A = STR_*, D = top row, C = pen mask.
big_text:
        push de
        push bc
        call get_string
        pop bc
        pop de
        jp print_big_centered

; In: D = row. "HI-SCORE 000000" under the panel label column.
hiscore_line:
        ld a,STR_LBL_HISCORE
        call panel_label
        ld hl,hi_score
        ld e,PANEL_VALUE_COL-2
        ld b,3
        jp print_bcd_zeros

hiscore_update:
        ld hl,score
        ld de,hi_score
        ld b,3
.cmp:   ld a,(de)
        cp (hl)
        jr c,.new               ; hi < score at the first differing byte
        ret nz                  ; hi > score
        inc hl
        inc de
        djnz .cmp
        ret
.new:   ld hl,score
        ld de,hi_score
        ld bc,3
        ldir
        ret
