; ---------------------------------------------------------------- first-trap hints
; The first three traps Thanos comes within reach of (campaign-wide, so in practice in
; Sunny Vale) open a window: "You are in front of a trap. Press SPACE to activate it."
; The third adds "From now on, you are on your own. Find and activate all the traps."
; The window closes when the trap goes off or he walks away, and opens again if he comes
; back to that trap. After the third trap, no more.
; And when he has set off every trap in a room, until he first signs one off: "This room is
; clear. Don't forget to sign it off: press M."

HINT_TRAPS      equ 3
HINT_ROWS       equ 6               ; bricks, four lines, bricks
HINT_TOP        equ 2               ; where he isn't: the top, or just above the bottom
HINT_BOTTOM     equ MAP_H-HINT_ROWS

; Close the window, if one is up: put those rows of the room back.
hint_hide:
        ld a,(hint_row)
        or a
        ret z
        ld d,a
        xor a
        ld (hint_row),a
        ld b,HINT_ROWS
        call rows_restore
        jp player_draw

; Redraw B rows of the room from row D. Trashes AF,BC,DE,HL.
rows_restore:
        push bc
        ld e,0
.cell:  call draw_cell
        inc e
        ld a,e
        cp MAP_W
        jr nz,.cell
        inc d
        pop bc
        djnz rows_restore
        ret

; Every play frame, after the player.
hint_update:
        ld a,(pl_state)
        or a                    ; walking only; a trap, a call or a selfie closes it
        jr nz,hint_hide
        call mark_hint_due      ; a cleared room, not signed off: that comes first
        ld a,HK_MARK
        jr c,.want
        call hazard_in_reach
        jr nc,hint_hide
        push ix                 ; the trap the last window was for?
        pop de
        ld hl,(hint_ptr)
        or a
        sbc hl,de
        jr z,.trap
        ld a,(hint_count)       ; a new trap: one of the first three?
        cp HINT_TRAPS
        jr nc,hint_hide
        inc a
        ld (hint_count),a
        ld (hint_ptr),ix
        call hint_hide          ; (a window still up for another trap)
.trap:  ld a,(hint_count)       ; two lines, or four on the last
        cp HINT_TRAPS
        ld a,HK_TRAP
        jr nz,.want
        ld a,HK_LAST
.want:  ld hl,hint_kind         ; the window wanted: up already?
        cp (hl)
        jr nz,.new
        ld a,(hint_row)
        or a
        ret nz
        jr .show
.new:   push af
        call hint_hide
        pop af
        ld (hint_kind),a
.show:  ld a,(pl_y)             ; where he isn't
        cp 11
        ld a,HINT_TOP
        jr nc,.row
        ld a,HINT_BOTTOM
.row:   ld (hint_row),a
        ld d,a
        call brick_row
        ld b,HINT_ROWS-2        ; the sides, black inside
.side:  inc d
        push bc
        ld e,0
.cell:  ld a,e
        or a
        jr z,.brick
        cp MAP_W-1
        ld a,TILE_BLACK
        jr nz,.put
.brick: ld a,TILE_BRICK
.put:   call draw_tile_at
        inc e
        ld a,e
        cp MAP_W
        jr nz,.cell
        pop bc
        djnz .side
        inc d
        call brick_row
        ld a,(hint_kind)        ; the text: line count, then row, string, pen per line
        add a,a
        ld hl,hint_texts-2
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld b,(hl)
        inc hl
.line:  push bc
        ld a,(hint_row)
        add a,(hl)
        ld d,a
        inc hl
        ld a,(hl)
        inc hl
        ld c,(hl)
        inc hl
        push hl
        call print_text_centered
        pop hl
        pop bc
        djnz .line
        ret

HK_TRAP         equ 1
HK_LAST         equ 2
HK_MARK         equ 3
hint_texts:
        dw .trap,.last,.mark
.trap:  db 2, 2,STR_HINT_TRAP1,PEN3_MASK, 3,STR_HINT_TRAP2,PEN3_MASK
.last:  db 4, 1,STR_HINT_TRAP1,PEN3_MASK, 2,STR_HINT_TRAP2,PEN3_MASK
        db    3,STR_HINT_OWN1,PEN1_MASK,  4,STR_HINT_OWN2,PEN1_MASK
.mark:  db 2, 2,STR_HINT_MARK1,PEN3_MASK, 3,STR_HINT_MARK2,PEN3_MASK

; Out: carry set if this room's traps have all gone off, it isn't signed off yet and
; no room has been signed off this campaign (after that he knows about M).
mark_hint_due:
        ld a,(hint_marked)
        or a
        ret nz
        call room_is_marked
        ret nz
        ld hl,(room_hazards)
        ld b,(hl)
        ld c,0                  ; traps gone off
        ld a,b
        or a
        ret z
.loop:  inc hl
        inc hl
        inc hl
        ld a,(hl)               ; type
        inc hl
        cp HZ_EVIDENCE
        ld a,(hl)               ; state
        jr z,.next
        cp HZ_ARMED
        ret z                   ; (no carry: one still armed)
        inc c
.next:  djnz .loop
        ld a,c
        cp 1
        ccf                     ; carry if at least one
        ret
