; ---------------------------------------------------------------- text
; The font is 6 pixels wide (5 and a space), so the CPC's 40 columns of text fit across
; the Spectrum's 256 pixels: text column E is at pixel 8 + 6*E (0-39), whatever the cells
; under it. A character sets the colour of the cells it touches. Strings are glyph indices
; ending in #ff, generated from assets/text/strings.txt into two tables (EN / GR).
; The CPC's pens are colours here: the names stayed.

PEN1_MASK       equ #46         ; bright yellow (the CPC's orange)
PEN2_MASK       equ #45         ; bright cyan (the CPC's sky blue)
PEN3_MASK       equ #47         ; bright white
TEXT_COLS       equ 40
TEXT_X0         equ 8

LANG_EN         equ 0
LANG_GR         equ 1

; In: A = STR_* id. Out: HL = string in the current language. Trashes AF,DE.
get_string:
        ld l,a
        ld h,0
        add hl,hl               ; ids go past 127
        ld a,(lang)
        or a
        ld de,strings_en
        jr z,.table
        ld de,strings_gr
.table: add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ret

; In: HL = string, D=row, E=col, C = pen mask. Out: E past the text. Trashes AF,HL.
print_str:
        ld a,(hl)
        cp #ff
        ret z
        call print_char
        inc hl
        inc e
        jr print_str

; In: HL = string, D = row, C = pen mask. Centres it on the row.
print_centered:
        push hl
        ld e,0
.len:   ld a,(hl)
        cp #ff
        jr z,.got
        inc hl
        inc e
        jr .len
.got:   ld a,TEXT_COLS
        sub e
        srl a
        ld e,a
        pop hl
        jr print_str

; Print B BCD bytes from HL (most significant first) as 2*B digits at D,E in pen mask C.
; print_bcd blanks leading zeros (the last digit always shows); print_bcd_zeros keeps them.
; Out: E past the digits. Trashes AF,B,HL.
print_bcd_zeros:
        xor a
        jr print_bcd.go
print_bcd:
        ld a,1
.go:    ld (bcd_lead),a
.byte:  ld a,(hl)
        rrca
        rrca
        rrca
        rrca
        call .digit
        ld a,b
        dec a
        jr nz,.lo
        ld (bcd_lead),a         ; last byte: its low digit always shows
.lo:    ld a,(hl)
        call .digit
        inc hl
        djnz .byte
        ret
.digit: and #0f
        jr nz,.show
        ld a,(bcd_lead)
        or a
        jr z,.show              ; A is 0 again below: digit zero
        xor a                   ; glyph 0 is a space
        jr .put
.show:  push af
        xor a
        ld (bcd_lead),a
        pop af
        and #0f
        add a,GLYPH_0
.put:   call print_char
        inc e
        ret

; In: A = 0-99. Out: A = the same value in BCD. Preserves BC.
bin_to_bcd:
        push bc
        ld b,-1
.tens:  inc b
        sub 10
        jr nc,.tens
        add a,10
        ld c,a
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        or c
        pop bc
        ret

; In: A = glyph, D=row, E=text column, C = attribute. Preserves BC,DE,HL.
print_char:
        push hl
        push de
        push bc
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,c
        ld bc,font_gfx
        add hl,bc
        ld (pc_glyph),hl
        ld (pc_attr),a
        call text_x             ; E = byte column, C = shift
        ld hl,#fc00             ; the glyph's 6 columns, shifted: keep masks
        call shift16
        ld a,h
        cpl
        ld (pc_k1),a
        ld a,l
        cpl
        ld (pc_k2),a
        call cell_addr
        ld b,8
.line:  push bc
        push hl
        ld hl,(pc_glyph)
        ld a,(hl)
        inc hl
        ld (pc_glyph),hl
        ld h,a
        ld l,0
        call shift16
        ex de,hl                ; D,E = the line's two bytes
        pop hl
        ld a,(pc_k1)
        and (hl)
        or d
        ld (hl),a
        ld a,c
        cp 3
        jr c,.one
        inc l
        ld a,(pc_k2)
        and (hl)
        or e
        ld (hl),a
        dec l
.one:   inc h
        pop bc
        djnz .line
        ld a,c                  ; and the colours of the cells it touches
        ex af,af'
        pop bc
        pop de
        push de
        push bc
        call text_x
        ld a,(pc_attr)
        call set_attr
        ex af,af'
        cp 3
        jr c,.done
        inc e
        ld a,(pc_attr)
        call set_attr
.done:  pop bc
        pop de
        pop hl
        ret

; In: E = text column. Out: E = its byte (cell) column, C = the pixel offset in it (0, 2,
; 4 or 6). Preserves D,HL; trashes AF.
text_x:
        ld a,e
        add a,a
        add a,e
        add a,a                 ; 6E
        add a,TEXT_X0
        ld e,a
        and 7
        ld c,a
        ld a,e
        rrca
        rrca
        rrca
        and 31
        ld e,a
        ret

; HL >> C (logical). Preserves BC,DE; trashes AF.
shift16:
        ld a,c
        or a
        ret z
        push bc
        ld b,c
.bit:   srl h
        rr l
        djnz .bit
        pop bc
        ret

; ---------------------------------------------------------------- double-size text
; Each font pixel becomes 2x2: a glyph is 12 pixels wide (two text columns) and two cells
; high. Used by the title and end screens.

; In: HL = string, D = top row, C = attribute. Centres it (each glyph is 2 columns wide).
print_big_centered:
        push hl
        ld e,0
.len:   ld a,(hl)
        cp #ff
        jr z,.got
        inc hl
        inc e
        jr .len
.got:   ld a,TEXT_COLS/2
        sub e
        ld e,a
        pop hl
.char:  ld a,(hl)
        cp #ff
        ret z
        call print_big_char
        inc hl
        inc e
        inc e
        jr .char

; In: A = glyph, D = top row, E = text column, C = attribute. Preserves BC,DE,HL.
print_big_char:
        push hl
        push de
        push bc
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,c
        ld bc,font_gfx
        add hl,bc
        ld (pc_glyph),hl
        ld (pc_attr),a
        call text_x             ; E = byte column, C = shift
        ld a,e
        ld (pc_col),a
        ld hl,#fff0             ; keep masks for 12 columns over three bytes
        ld a,0
        call shift24
        ld a,h
        cpl
        ld (pc_k1),a
        ld a,l
        cpl
        ld (pc_k2),a
        ld a,b
        cpl
        ld (pc_k3),a
        ld b,0                  ; glyph line 0-7 -> screen lines 2b and 2b+1
.row:   push bc
        ld hl,(pc_glyph)
        ld a,(hl)
        inc hl
        ld (pc_glyph),hl
        ld hl,0                 ; its 6 pixels doubled into 12, left-aligned
        ld b,6
.wide:  rla
        push af
        adc hl,hl
        pop af
        push af
        adc hl,hl
        pop af
        djnz .wide
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        call shift24            ; H, L, B = the three bytes
        ld (pc_bytes),hl
        ld a,b
        ld (pc_bytes+2),a
        pop bc
        push bc
        ld a,b                  ; screen row = top + (2b >> 3), line = 2b & 7
        add a,a
        rrca
        rrca
        rrca
        and 1
        add a,d
        push de
        ld d,a
        ld a,(pc_col)
        ld e,a
        call cell_addr
        pop de
        ld a,b
        add a,a
        and 7
        add a,h
        ld h,a
        call .line
        inc h
        call .line
        pop bc
        inc b
        ld a,b
        cp 8
        jr nz,.row
        ld a,(pc_col)           ; the colours: two rows of up to three cells
        ld e,a
        ld b,2
.arow:  push bc
        ld a,(pc_attr)
        call set_attr
        inc e
        ld a,(pc_attr)
        call set_attr
        ld a,c
        cp 5                    ; 12 pixels from offset 5+ reach a third byte
        jr c,.two
        inc e
        ld a,(pc_attr)
        call set_attr
        dec e
.two:   dec e
        inc d
        pop bc
        djnz .arow
        pop bc
        pop de
        pop hl
        ret
.line:  push hl
        ld a,(pc_k1)
        and (hl)
        ld b,a
        ld a,(pc_bytes+1)
        or b
        ld (hl),a
        inc l
        ld a,(pc_k2)
        and (hl)
        ld b,a
        ld a,(pc_bytes)
        or b
        ld (hl),a
        ld a,l
        and 31
        cp 31
        jr z,.edge
        inc l
        ld a,(pc_k3)
        and (hl)
        ld b,a
        ld a,(pc_bytes+2)
        or b
        ld (hl),a
.edge:  pop hl
        ret

; H:L:A >> C (24 bits). Out: H, L, B = the three bytes. Preserves C,DE.
shift24:
        ld b,a
        ld a,c
        or a
        ret z
        push de
        ld e,c
.bit:   srl h
        rr l
        rr b
        dec e
        jr nz,.bit
        pop de
        ret
