; ---------------------------------------------------------------- blackouts
; From the second building on, the owner hasn't paid the electricity bill: every 40-60 s
; the lights go for 5 s: everything but white goes dark blue (video.asm's XLAT), so only
; the white things show - sockets, the fridges, the text. The workers keep throwing.
; palette_normal dims the colours while it lasts, so a room change or a phone call
; doesn't switch the lights back on.

BLACKOUT_GAP    equ 2000            ; frames between blackouts, plus up to 1023
BLACKOUT_LEN    equ 250             ; 5 s

; The test harness pokes this to 0 for scripts written without them.
blackouts_enabled: db 1

; Every play frame, whatever Thanos is doing.
blackout_update:
        ld a,(blackouts_enabled)
        or a
        ret z
        ld a,(camp_index)       ; not in the first building
        or a
        ret z
        ld hl,(blackout_timer)
        ld a,h
        or l
        jr z,.schedule          ; a new building: the first one is still to come
        dec hl
        ld (blackout_timer),hl
        ld a,h
        or l
        ret nz
        ld a,(blackout)         ; time: lights off, or back on
        xor 1
        ld (blackout),a
        push af
        call palette_normal
        pop af
        jr z,.schedule
        ld hl,BLACKOUT_LEN
        ld (blackout_timer),hl
        ld hl,sfx_powerdown
        call sfx_play
        ld a,STR_BLACKOUT
        jp caption_show
.schedule:
        call rand
        and 3
        ld h,a
        call rand
        ld l,a
        ld de,BLACKOUT_GAP
        add hl,de
        ld (blackout_timer),hl
        ret

; A building starts or ends: lights on, nothing scheduled.
blackout_reset:
        xor a
        ld (blackout),a
        ld h,a
        ld l,a
        ld (blackout_timer),hl
        ret
