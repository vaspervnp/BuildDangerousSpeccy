; ---------------------------------------------------------------- the inspector's sixth sense
; With an armed trap within reach (the same test as SPACE's), a "?" tingles over Thanos's
; head, blinking white and orange: the first three traps get the hint window as well,
; the rest only this. Not in mid-air, not over the owner's papers, not under the HUD.
; It sits in the cell row over his head, from the middle of his left cell to the middle
; of his right one; going away it puts those two cells of the room back.

SENSE_BLINK     equ 8               ; frames per colour

; Every play frame, after the player.
sense_update:
        ld a,(pl_state)
        or a
        jr nz,sense_hide
        ld a,(pl_jump)
        or a
        jr nz,sense_hide
        ld a,(pl_y)
        cp HUD_ROWS+1           ; room for it over his head
        jr c,sense_hide
        call hazard_in_reach
        jr nc,sense_hide
        ld a,(ix+HZ_TYPE)
        cp HZ_EVIDENCE
        jr z,sense_hide
        ld de,(pl_x)
        dec d                   ; the row over his head
        ld a,(sense_on)
        or a
        jr z,.new
        ld hl,(sense_xy)        ; still there: blink
        or a
        sbc hl,de
        jr z,.blink
        push de                 ; he moved: from the old place to the new
        call sense_hide
        pop de
.new:   ld (sense_xy),de
        ld a,1
        ld (sense_on),a
        xor a
        ld (sense_tick),a
        jr .paint
.blink: ld hl,sense_tick
        inc (hl)
        ld a,(hl)
        and SENSE_BLINK-1
        ret nz                  ; (repainted on every change: workers and tools wipe it)
.paint: ld a,(sense_tick)
        and SENSE_BLINK
        ld c,PEN3_MASK
        jr z,.pen
        ld c,PEN1_MASK
.pen:   ld a,c
        call set_attr           ; (DE = sense_xy) both cells in the blink's colour
        inc e
        ld a,c
        call set_attr
        dec e
        call cell_addr
        ld de,sense_gfx
        ld b,8
.line:  ld a,(de)               ; two bytes: screen AND mask, OR data
        and (hl)
        inc de
        ex de,hl
        or (hl)
        ex de,hl
        ld (hl),a
        inc de
        inc l
        ld a,(de)
        and (hl)
        inc de
        ex de,hl
        or (hl)
        ex de,hl
        ld (hl),a
        inc de
        dec l
        inc h
        djnz .line
        ret

; Take it away, if it is up: the two cells back, and Thanos over them if he climbed
; into them. Called too as a trap, a call or a selfie starts. Preserves all registers.
sense_hide:
        push af
        ld a,(sense_on)
        or a
        jr z,.done
        push bc
        push de
        push hl
        push ix
        xor a
        ld (sense_on),a
        ld de,(sense_xy)
        call draw_cell
        inc e
        call draw_cell
        ld a,(pl_state)         ; (a trap or a call: they draw him themselves)
        or a
        call z,player_draw
        pop ix
        pop hl
        pop de
        pop bc
.done:  pop af
        ret

; Masked: mask, data for each of the two bytes of a line; the "?" is 4 pixels in, from
; the middle of his left cell to the middle of his right one:
;   ....oo####oo....
;   ....o##oo##o....
;   ....ooooo##o....
;   ......oo##oo....
;   ......o##oo.....
;   ......oooo......
;   ......o##o......
;   ......oooo......
sense_gfx:
        db #f0,#03,#0f,#c0
        db #f0,#06,#0f,#60
        db #f0,#00,#0f,#60
        db #fc,#00,#0f,#c0
        db #fc,#01,#1f,#80
        db #fc,#00,#3f,#00
        db #fc,#01,#3f,#80
        db #fc,#00,#3f,#00
