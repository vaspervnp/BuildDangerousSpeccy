; ---------------------------------------------------------------- input
; Reads the keyboard's 8 half-rows (port #FE) and the Kempston into kb_matrix (active low,
; like the CPC's matrix) and folds them into `keys`. The Kempston is line 8, laid out like
; the CPC's joystick line: bit 0 up, 1 down, 2 left, 3 right, 4 fire 2, 5 fire 1. Its two
; fire buttons together are a pause: one alone waits JOY_GRACE frames for the other before
; it counts as Fire / M (or counts as it is let go, for a quick tap); after both, nothing
; more until both are up. (Most Kempston sticks have one button: Fire.)
;
; Keys: Q A O P, the cursor keys (CAPS SHIFT + 5-8; 5-8 alone too, for a cursor joystick),
; SPACE / ENTER / 0 fire, M signs off, L the language, H pauses.

JOY_GRACE       equ 5               ; 0.1 s: "together", for two thumbs
JOY_FIRES       equ %00110000       ; line 8: bit 5 fire 1, bit 4 fire 2
JOY_LINE        equ 8

KEY_UP          equ %00000001
KEY_DOWN        equ %00000010
KEY_LEFT        equ %00000100
KEY_RIGHT       equ %00001000
KEY_FIRE        equ %00010000
KEY_MARK        equ %00100000
KEY_LANG        equ %01000000
KEY_PAUSE       equ %10000000

input_read:
        ld hl,kb_matrix
        ld bc,#fefe
.row:   in a,(c)
        or #e0
        ld (hl),a
        inc hl
        rlc b
        jr c,.row
        ld a,(kempston_on)      ; the Kempston (active high): to the CPC's layout, active low
        or a
        ld a,#ff
        jr z,.nostick
        in a,(#1f)
        ld e,a
        xor a
        bit 3,e
        jr z,.k1
        or %00000001            ; up
.k1:    bit 2,e
        jr z,.k2
        or %00000010            ; down
.k2:    bit 1,e
        jr z,.k3
        or %00000100            ; left
.k3:    bit 0,e
        jr z,.k4
        or %00001000            ; right
.k4:    bit 4,e
        jr z,.k5
        or %00100000            ; fire 1
.k5:    bit 5,e
        jr z,.k6
        or %00010000            ; fire 2
.k6:    cpl
.nostick:
        ld (hl),a

        ld hl,key_map
        ld c,0
.map:   ld a,(hl)               ; matrix line, #ff ends the table
        cp #ff
        jr z,.done
        inc hl
        ld de,kb_matrix
        add a,e
        ld e,a
        adc a,d
        sub e
        ld d,a
        ld a,(de)
        and (hl)                ; matrix bits are 0 when pressed
        inc hl
        jr nz,.skip
        ld a,c
        or (hl)
        ld c,a
.skip:  inc hl
        jr .map
.done:  ld a,(kb_matrix+JOY_LINE) ; the joystick's fire buttons
        cpl
        and JOY_FIRES
        jr nz,.fires
        ld a,(joy_lock)         ; both up: a tap let go before its time counts now
        or a
        jr nz,.free
        ld a,(joy_wait)
        or a
        jr z,.free
        cp JOY_GRACE+1
        jr nc,.free
        ld a,(joy_last)
        or c
        ld c,a
.free:  xor a
        ld (joy_lock),a
        ld (joy_wait),a
        jr .edge
.fires: ld b,a
        ld a,(joy_lock)
        or a
        jr nz,.edge             ; after a pause: until both are up
        ld a,b
        cp JOY_FIRES
        jr nz,.one
        ld (joy_lock),a         ; both: pause
        ld a,c
        or KEY_PAUSE
        ld c,a
        jr .edge
.one:   cp %00100000            ; one: fire 1 is Fire, fire 2 is M
        ld a,KEY_FIRE
        jr z,.which
        ld a,KEY_MARK
.which: ld (joy_last),a
        ld b,a
        ld a,(joy_wait)
        cp JOY_GRACE
        jr nc,.held
        inc a
        ld (joy_wait),a
        jr .edge
.held:  ld a,JOY_GRACE+1        ; past waiting: it counts while held
        ld (joy_wait),a
        ld a,c
        or b
        ld c,a
.edge:  ld a,(keys)              ; keys_new = pressed now but not last frame
        cpl
        and c
        ld (keys_new),a
        ld a,c
        ld (keys),a
        ret

; matrix line (half-row: 0 = CAPS..V, 1 = A..G, 2 = Q..T, 3 = 1..5, 4 = 0..6, 5 = P..Y,
; 6 = ENTER..H, 7 = SPACE..B; 8 = the Kempston), bit mask, KEY_* flag
key_map:
        db 2,%00000001,KEY_UP           ; Q
        db 4,%00001000,KEY_UP           ; 7 (cursor up)
        db 8,%00000001,KEY_UP           ; joystick up
        db 1,%00000001,KEY_DOWN         ; A
        db 4,%00010000,KEY_DOWN         ; 6 (cursor down)
        db 8,%00000010,KEY_DOWN         ; joystick down
        db 5,%00000010,KEY_LEFT         ; O
        db 3,%00010000,KEY_LEFT         ; 5 (cursor left)
        db 8,%00000100,KEY_LEFT         ; joystick left
        db 5,%00000001,KEY_RIGHT        ; P
        db 4,%00000100,KEY_RIGHT        ; 8 (cursor right)
        db 8,%00001000,KEY_RIGHT        ; joystick right
        db 7,%00000001,KEY_FIRE         ; SPACE
        db 6,%00000001,KEY_FIRE         ; ENTER
        db 4,%00000001,KEY_FIRE         ; 0 (cursor joystick fire)
        db 7,%00000100,KEY_MARK         ; M
        db 6,%00000010,KEY_LANG         ; L
        db 6,%00010000,KEY_PAUSE        ; H
        db #ff
