; ---------------------------------------------------------------- the owner's nephew
; Bambis, influencer, paces one floor of many rooms (room data: after the hazards). If he
; gets within a cell of Thanos he takes a selfie: Thanos is stuck for a few seconds -
; two camera flashes and a caption - while the clock runs. A few seconds later he is ready
; for another. He can be dodged: jump over him, or wait up a flight while he walks under.

NEPHEW_DELAY    equ 9           ; frames per step
SELFIE_PAIRS    equ 3           ; pairs of captions, taken in turn
NEPHEW_REST     equ 200         ; frames after a selfie before he wants another

; The test harness pokes this to 0 for scripts written without him.
nephew_enabled: db 1

selfie_lines:
        db STR_NEPHEW_HI1, STR_NEPHEW_BYE1
        db STR_NEPHEW_HI2, STR_NEPHEW_BYE2
        db STR_NEPHEW_HI3, STR_NEPHEW_BYE3

; After a room is drawn: is he in it?
nephew_init:
        xor a
        ld (npc_on),a
        ld a,(nephew_enabled)
        or a
        ret z
        ld hl,(room_hazards)
        ld a,(hl)               ; past the hazard list
        add a,a
        add a,a
        inc a
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        or a
        ret z
        ld (npc_on),a
        inc hl
        ld de,npc_x             ; npc_x, npc_y, npc_min, npc_max
        ld bc,4
        ldir
        xor a
        ld (npc_dir),a
        ld (npc_done),a
        ld (npc_anim),a
        ld (npc_pose),a
        ld a,NEPHEW_DELAY
        ld (npc_wait),a
        ; fall through

nephew_draw:
        ld a,(npc_pose)
        or a
        ld a,AF_NEPHEW_SELFIE
        jr nz,.frame
        ld a,(npc_anim)
        add a,AF_NEPHEW
.frame: call frame_addr
        ld de,(npc_x)
        jp draw_sprite16

; Every play frame, after the player: walk, maybe pounce.
nephew_update:
        ld a,(npc_on)
        or a
        ret z
        ld a,(pl_state)
        or a                    ; PS_WALK only: not over a vignette or the phone
        ret nz
        ld hl,npc_done          ; resting after the last selfie?
        ld a,(hl)
        or a
        jr z,.look
        dec (hl)
        jr .walk
.look:  ld a,(pl_jump)          ; no selfie with Thanos in the air
        or a
        jr nz,.walk
        ld a,(pl_y)             ; within a cell, same floor: selfie
        ld hl,npc_y
        sub (hl)
        inc a
        cp 3
        jr nc,.walk
        ld a,(pl_x)
        ld hl,npc_x
        sub (hl)
        inc a
        cp 3
        jp c,selfie_start
.walk:  ld hl,npc_wait
        dec (hl)
        jr nz,nephew_overlap
        ld (hl),NEPHEW_DELAY
        ld de,(npc_x)
        call restore_2x2
        ld a,(npc_dir)
        or a
        ld a,(npc_x)
        ld hl,npc_max
        jr z,.right
        dec a
        ld hl,npc_min
        jr .moved
.right: inc a
.moved: ld (npc_x),a
        cp (hl)
        jr nz,.anim
        ld a,(npc_dir)          ; the end of his beat: turn round
        xor 1
        ld (npc_dir),a
.anim:  ld a,(npc_anim)
        xor 1
        ld (npc_anim),a
        call nephew_draw
        ; fall through

; Close to Thanos, each one's redraw can wipe the other: draw both, Thanos on top.
nephew_overlap:
        ld a,(pl_x)
        ld hl,npc_x
        sub (hl)
        add a,2
        cp 5
        ret nc
        ld a,(pl_y)
        ld hl,npc_y
        sub (hl)
        add a,2
        cp 5
        ret nc
        call nephew_draw
        jp player_draw

selfie_start:
        call sense_hide
        ld a,PS_SELFIE
        ld (pl_state),a
        ld a,NEPHEW_REST
        ld (npc_done),a
        ld a,1
        ld (npc_pose),a
        xor a
        ld (selfie_step),a
        ld (selfie_timer),a
        call nephew_draw
        call player_draw
        ld a,(selfie_index)     ; this selfie's captions
        add a,a
        ld e,a
        ld d,0
        ld hl,selfie_lines
        add hl,de
        ld a,(hl)
        jp caption_show

; PS_SELFIE: a little timed sequence. Steps: 0 pose (caption already up), 1 flash,
; 2 dark, 3 flash, 4 dark + his sign-off line, 5 done.
selfie_update:
        ld hl,selfie_timer
        ld a,(hl)
        or a
        jr z,.step
        dec (hl)
        ret
.step:  ld hl,selfie_step
        ld a,(hl)
        inc (hl)
        or a
        ld b,70
        jr z,.wait              ; 0: let the caption type out
        cp 5
        jr z,.done
        rrca
        jr nc,.dark             ; 2, 4
        ld a,FX_FLASH           ; 1, 3: flash
        call set_fx
        ld hl,sfx_click
        call sfx_play
        ld b,3
        jr .wait
.dark:  push af
        ld a,FX_NONE
        call set_fx
        pop af
        ld b,8
        cp 2                    ; (A = step/2 after the rrca: 1 = step 2, 2 = step 4)
        jr z,.bye
.wait:  ld a,b
        ld (selfie_timer),a
        ret
.bye:   ld a,(selfie_index)
        add a,a
        inc a
        ld e,a
        ld d,0
        ld hl,selfie_lines
        add hl,de
        ld a,(hl)
        call caption_show
        ld a,90
        ld (selfie_timer),a
        ret
.done:  ld a,(selfie_index)
        inc a
        cp SELFIE_PAIRS
        jr c,.next
        xor a
.next:  ld (selfie_index),a
        xor a
        ld (npc_pose),a
        ld (pl_state),a         ; PS_WALK
        call nephew_draw
        jp player_draw
