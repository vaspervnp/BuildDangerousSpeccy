; ---------------------------------------------------------------- video
; The Spectrum screen: 32x24 cells of 8x8, one byte a cell line, one attribute a cell.
; Bitmap address of (row,line,col) = #4000 + (row & #18)*256 + line*256 + (row & 7)*32 + col.
;
; Attributes are drawn into SHADOW (#5B00, laid out like the screen's #5800) and go to the
; screen through XLAT, a 256-byte table: normally each to itself; a blank screen (while a
; room draws) makes them all black on black, a blackout dims everything but white, a trap's
; flash paints the paper. Changing the table puts the whole shadow through it again
; (attrs_refresh), so nothing on the screen has to be redrawn - the CPC did all this by
; changing its inks.
;
; Paper is black everywhere (no wallpaper on the Spectrum: the rooms are drawn on black),
; so sprites, drawn in cells of their own colour with a black ring round them, never clash
; with what is behind them more than a cell's colour.

SCREEN          equ #4000

BORDER_BLACK    equ 0
BORDER_MISS     equ 3           ; magenta: a Miss
BORDER_HIT      equ 2           ; red: a tool hit him
BORDER_SHAKE    equ 7           ; white: a trap's jolt (the CPC moved the picture)

BLD_ATTR_DEFAULT equ #45        ; bright cyan: the title's and Sunny Vale's walls
XM_NORMAL       equ 0           ; xlat_mode
XM_BLACK        equ 1

video_init:
        xor a
        call set_border
        call screen_clear
        ld a,BLD_ATTR_DEFAULT
        ld (bld_attr),a
        jp palette_normal

; Normal colours: as drawn, dimmed in a blackout (blackout.asm), no flash.
palette_normal:
        xor a
        ld (fx_paper),a
        ld (xlat_mode),a
        jr palette_set
; Everything black on black: the screen is blanked (a room being drawn).
palette_black:
        ld a,XM_BLACK
        ld (xlat_mode),a
; Build XLAT for the current mode and put the shadow through it. Trashes AF,BC,DE,HL.
palette_set:
        ld hl,XLAT
        ld a,(xlat_mode)
        or a
        jr z,.build
.zero:  ld (hl),0               ; black: every attribute shows as 0
        inc l
        jr nz,.zero
        jr attrs_refresh
.build: ld a,(blackout)
        ld d,a
        ld a,(fx_paper)
        ld e,a                  ; paper bits (colour << 3), 0 = black
.attr:  ld a,l
        bit 0,d
        jr z,.lit
        and 7                   ; the lights are out: white stays, the rest goes dark blue
        cp 7
        ld a,l
        jr z,.lit
        and #38
        or 1
.lit:   ld c,a
        ld a,e
        or a
        ld a,c
        jr z,.store
        and #c7
        or e
        ld c,a                  ; an ink the flash's colour goes black: a silhouette
        rrca
        rrca
        rrca
        xor c
        and 7
        ld a,c
        jr nz,.store
        and #f8
.store: ld (hl),a
        inc l
        jr nz,.attr
        ; fall through

; Every attribute of the screen from the shadow, through XLAT.
attrs_refresh:
        ld hl,SHADOW
        ld de,ATTRS
        ld b,XLAT>>8
.cell:  ld c,(hl)
        ld a,(bc)
        ld (de),a
        inc hl
        inc de
        ld a,d
        cp (ATTRS+768)>>8
        jr nz,.cell
        ret

; In: A = FX_* (vignette.asm). The paper of the whole screen in that effect's colour.
; Trashes AF,BC,DE,HL.
set_fx:
        ld hl,fx_papers
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld a,(hl)
        ld (fx_paper),a
        jr palette_set

fx_papers:      ; paper bits per FX_*
        db 0, 7<<3, 2<<3, 1<<3, 4<<3, 5<<3, 6<<3
                ; none, flash white, fire red, water blue, gas green, ice cyan, dust yellow

; The whole screen blank: bitmap 0, attributes black on black.
screen_clear:
        ld hl,SCREEN
        ld de,SCREEN+1
        ld bc,6143
        ld (hl),0
        ldir
        ld hl,SHADOW
        ld de,SHADOW+1
        ld bc,767
        ld (hl),0
        ldir
        jr attrs_refresh

; In: D=row (0-23), E=col (0-31). Out: HL = screen address of the cell's top line.
; Preserves BC,DE; trashes A.
cell_addr:
        ld a,d
        and #18
        or SCREEN>>8
        ld h,a
        ld a,d
        rrca
        rrca
        rrca
        and #e0
        or e
        ld l,a
        ret

; In: A = attribute, D=row, E=col. Into the shadow and, through XLAT, the screen.
; Preserves BC,DE; trashes AF,HL.
set_attr:
        push bc
        ld c,a
        ld a,d
        rrca
        rrca
        rrca
        ld b,a
        and #e0
        or e
        ld l,a
        ld a,b
        and 3
        add a,SHADOW>>8
        ld h,a
        ld (hl),c
        ld b,XLAT>>8
        ld a,(bc)
        ld c,a
        ld a,h
        sub (SHADOW-ATTRS)>>8
        ld h,a
        ld (hl),c
        pop bc
        ret

; Blank one character row of the screen (white on black). In: D = row.
; Preserves DE; trashes AF,BC,HL.
clear_row:
        push de
        ld e,0
        call cell_addr
        ld c,8
.line:  push hl
        ld b,32
.byte:  ld (hl),0
        inc l
        djnz .byte
        pop hl
        inc h
        dec c
        jr nz,.line
.attr:  ld a,#47
        call set_attr
        inc e
        ld a,e
        cp 32
        jr nz,.attr
        pop de
        ret

; Draw the room-map cell at D=row, E=col: its tile, plus the hazard sitting on it if
; bit 7 is set. Preserves DE; trashes AF,BC,HL.
draw_cell:
        call map_addr
        ld a,(hl)
        or a
        jp p,draw_tile_at
        and #7f
        call draw_tile_at
        call hazard_find
        ret nc
        jp draw_hazard

; Draw an RLE tile map (zxgfx.py tilemap) from the top-left of the screen, skipping
; black cells (the screen is clear). In: HL = map. Trashes AF,BC,DE,HL.
draw_tilemap:
        ld de,0
.run:   ld a,(hl)
        or a
        ret z
        ld b,a
        inc hl
        ld c,(hl)
        inc hl
.cell:  ld a,c
        or a
        jr z,.skip
        push bc
        push hl
        call draw_tile_at
        pop hl
        pop bc
.skip:  inc e
        ld a,e
        cp MAP_W
        jr nz,.next
        ld e,0
        inc d
.next:  djnz .cell
        jr .run

; Draw tile A at D=row, E=col, with its colour. Preserves DE; trashes AF,BC,HL.
draw_tile_at:
        push af
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld bc,tiles_gfx
        add hl,bc
        ld b,h
        ld c,l
        call cell_addr
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        inc bc
        inc h
        ld a,(bc)
        ld (hl),a
        pop af
        ld hl,tile_attr
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld a,(hl)
        or a
        jp p,set_attr
        and #38                 ; the building's colour as the ink
        ld hl,bld_attr
        or (hl)
        jp set_attr

; Masked 16x16 sprite at cell D=row, E=col (cell aligned), and its cells' colours.
; In: HL = frame (16 lines x 2 x (mask,data), then 4 attributes; 0 = leave the cell's).
; Preserves DE; trashes AF,BC,HL.
draw_sprite16:
        push de
        ld b,h
        ld c,l
        call cell_addr
        call blit16
        inc d
        call cell_addr
        call blit16
        dec d
        ld a,(bc)               ; the four cells' colours
        inc bc
        call .attr
        inc e
        ld a,(bc)
        inc bc
        call .attr
        inc d
        dec e
        ld a,(bc)
        inc bc
        call .attr
        inc e
        ld a,(bc)
        call .attr
        pop de
        ret
.attr:  or a
        ret z
        jp set_attr

; 8 lines of a 2-byte-wide masked image: screen = (screen AND mask) OR data.
; In: HL = screen, BC = (mask,data) pairs. Out: BC past them. Preserves DE; trashes AF,HL.
blit16:
        push de
        ld e,8
.line:  ld a,(bc)
        and (hl)
        inc bc
        ld d,a
        ld a,(bc)
        or d
        ld (hl),a
        inc bc
        inc l
        ld a,(bc)
        and (hl)
        inc bc
        ld d,a
        ld a,(bc)
        or d
        ld (hl),a
        inc bc
        dec l
        inc h
        dec e
        jr nz,.line
        pop de
        ret

; Masked 8x8 sprite at cell D=row, E=col.
; In: HL = frame (8 lines x (mask,data), then its attribute). Preserves DE; trashes AF,BC,HL.
draw_sprite8:
        ld b,h
        ld c,l
        call cell_addr
        push de
        ld e,8
.line:  ld a,(bc)
        and (hl)
        inc bc
        ld d,a
        ld a,(bc)
        or d
        ld (hl),a
        inc bc
        inc h
        dec e
        jr nz,.line
        pop de
        ld a,(bc)
        or a
        ret z
        jp set_attr

; A 16x16 frame's address. In: A = frame, DE = the sheet. Out: HL = sheet + A*68.
; Trashes AF,DE.
frame68:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        push hl                 ; *4
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; *64
        add hl,de
        pop de
        add hl,de
        ret

; An 8x8 sprite's address. In: A = sprite. Out: HL = hazard_gfx + A*17. Trashes AF,DE.
sprite17:
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,de
        ld de,hazard_gfx
        add hl,de
        ret
