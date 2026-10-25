; ---------------------------------------------------------------- room
; The room map mirrors the screen: 32x24 cells. Row 0 is the HUD band,
; rows 1-23 come from the room's tile codes (runs, single tiles, copies of the row above;
; see room_load and zxgfx.py encode_cells), terminated by 0.
; The hazard list follows (see hazards.asm). Cells holding a hazard have bit 7 set.
; Room data lives in RAM and hazard states are written back into it, so a room
; remembers what was disarmed when it is loaded again.

MAP_W           equ 32
MAP_H           equ 24
HUD_ROWS        equ 1

; In: HL = room data. The HUD rows of the map are left alone (the HUD owns them).
room_load:
        ld de,room_map+MAP_W*HUD_ROWS
.op:    ld a,(hl)               ; tile codes (zxgfx.py encode_cells)
        inc hl
        or a
        jr z,.hazards
        jp m,.short
        ld b,a                  ; 1-127: a run, then its tile
        ld a,(hl)
        inc hl
.fill:  ld (de),a
        inc de
        djnz .fill
        jr .op
.short: bit 6,a
        jr nz,.copy
        and #3f                 ; %10tttttt: one tile
        ld (de),a
        inc de
        jr .op
.copy:  and #3f                 ; %11nnnnnn: n+1 cells from the row above
        inc a
        ld c,a
        ld b,0
        push hl
        ld hl,-MAP_W
        add hl,de
        ldir
        pop hl
        jr .op
.hazards:
        ld (room_hazards),hl
        ld b,(hl)
        inc hl
        ld a,b
        or a
        ret z
.mark:  ld e,(hl)               ; x
        inc hl
        ld d,(hl)               ; row
        inc hl
        inc hl
        inc hl
        push hl
        call map_addr
        set 7,(hl)
        pop hl
        djnz .mark
        ret

room_draw:
        ld d,0
.row:   ld e,0
.col:   call draw_cell
        inc e
        ld a,e
        cp MAP_W
        jr nz,.col
        inc d
        ld a,d
        cp MAP_H
        jr nz,.row
        ret

; In: D=row, E=col. Out: HL = &room_map[row][col]. Preserves DE; trashes A.
map_addr:
        push de
        ld l,d
        ld h,0
        add hl,hl
        ld de,row_map
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        pop de
        ld a,e
        add a,l
        ld l,a
        ret nc
        inc h
        ret

; In: D=row, E=col. Out: A = tile flags. Anything outside the play area (HUD rows, past
; the bottom, left of column 0, right of column 31) is solid. Preserves BC,DE; trashes HL.
flags_at:
        ld a,d
        cp MAP_H
        jr nc,.solid
        cp HUD_ROWS
        jr c,.solid
        ld a,e
        cp MAP_W
        jr nc,.solid
        call map_addr
        ld a,(hl)
        and #7f
        ld hl,tile_flags
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld a,(hl)
        ret
.solid: ld a,TILEF_SOLID
        ret

; Two cells side by side. In: D=row, E=col. Out: B = flags(col), A = flags(col+1).
; Preserves C,DE.
flags_pair:
        call flags_at
        ld b,a
        inc e
        call flags_at
        dec e
        ret

; Two cells stacked. In: D=row, E=col. Out: A = flags(row,col) | flags(row+1,col).
; Preserves C,DE; trashes B.
flags_col:
        call flags_at
        ld b,a
        inc d
        call flags_at
        dec d
        or b
        ret

row_map:
rowi = 0
        repeat MAP_H
        dw room_map + rowi*MAP_W
rowi = rowi + 1
        rend
