; ---------------------------------------------------------------- the Spectrum's hardware
; The 50 Hz interrupt (IM 2), the frame pace, the AY (a 128K) and the Kempston.

; IM 2 through a table of 257 bytes IM2_FILL: whatever is on the bus, the vector is
; IM2_JUMP, where a JP to the handler sits. I >= #80, or a 48K shows snow.
hw_init:
        ld hl,IM2_TABLE
        ld de,IM2_TABLE+1
        ld bc,256
        ld (hl),IM2_FILL
        ldir
        ld a,#c3                ; JP nn
        ld (IM2_JUMP),a
        ld hl,int_handler
        ld (IM2_JUMP+1),hl
        ld a,IM2_TABLE>>8
        ld i,a
        im 2
        ei
        call ay_detect
        jp kempston_detect

; Once a frame, at its start: just count it.
int_handler:
        push af
        ld a,(framecnt)
        inc a
        ld (framecnt),a
        pop af
        ei
        reti

; Wait for the next frame (a new interrupt), as the CPC waits for its VSYNC. A 48K plays
; the beeper until then (sound.asm); a 128K's AY plays by itself.
wait_vbl:
        ld a,(ay_present)
        or a
        jp z,beeper_frame
        ld a,(framecnt)
        ld b,a
.wait:  halt
        ld a,(framecnt)
        cp b
        jr z,.wait
        ret

; The AY (128K, +2, +3): register reads come back from #FFFD; on a 48K that is the
; floating bus, #FF in the border.
ay_detect:
        halt
        ld bc,#fffd
        xor a
        out (c),a               ; register 0
        ld b,#bf
        ld a,#55
        out (c),a
        ld b,#ff
        in a,(c)
        cp #55
        ret nz
        ld b,#bf
        ld a,#aa
        out (c),a
        ld b,#ff
        in a,(c)
        cp #aa
        ret nz
        ld b,#bf                ; period back to 0
        xor a
        out (c),a
        inc a
        ld (ay_present),a
        ret

; Kempston only if port #1F read like a joystick (none of bits 6-7, nothing pushed both
; ways) for two whole frames: with no interface there it is the floating bus.
kempston_detect:
        halt
        ld a,(framecnt)
        add a,2
        ld l,a
        ld h,0
.listen:
        in a,(#1f)
        or h
        ld h,a
        ld a,(framecnt)
        cp l
        jr nz,.listen
        ld a,h
        and #c0
        ret nz
        ld a,h                  ; left and right at once, or up and down: not a stick
        and 3
        cp 3
        ret z
        ld a,h
        and 12
        cp 12
        ret z
        ld a,1
        ld (kempston_on),a
        ret

; In: A = border colour (0-7). Trashes AF.
set_border:
        and 7
        ld (border_col),a
        out (#fe),a
        ret
