; ---------------------------------------------------------------- building
; A building is a set of rooms joined at their edges. Each room has one "signed off"
; bit in bld_marked. Signing off a room that still holds an armed hazard is a Miss: it
; costs more energy than any trap and goes on the tally, but the room still counts as
; signed off. The exit opens once every room has been signed off, Misses included.
;
; Building data (generated from assets/buildings/*.txt by tools/zxgfx.py):
;   db room count, start room, start x, start row
;   db clock seconds (BCD hi, lo), seconds per dial step, Misses still graded "good"
;   db STR_* facade sign, STR_* owner's welcome (outdoor scene), the walls' attribute
;   per room: dw room data, db exit left, right, up, down (room index or NO_EXIT)

MAX_ROOMS       equ 32          ; bld_marked is 4 bytes
MISS_COST       equ 4           ; two hats; traps cost no energy, only time
MISS_TALLY_MAX  equ #99         ; BCD
MISS_BORDER_FRAMES equ 12

NO_EXIT         equ #ff
EXIT_LEFT       equ 0
EXIT_RIGHT      equ 1
EXIT_UP         equ 2
EXIT_DOWN       equ 3
ROOM_REC_SIZE   equ 6

; In: HL = building. Sets up the building from scratch (every hazard armed again, clock
; full) and places Thanos. Draws nothing: the outdoor intro comes first.
building_start:
        ld a,(hl)
        ld (bld_rooms),a
        call bin_to_bcd
        ld (rooms_bcd),a
        inc hl
        ld a,(hl)
        ld (bld_start),a
        inc hl
        ld a,(hl)
        ld (pl_x),a
        inc hl
        ld a,(hl)
        ld (pl_y),a
        inc hl
        ld a,(hl)
        ld (clock_hi),a
        inc hl
        ld a,(hl)
        ld (clock_lo),a
        inc hl
        ld a,(hl)
        ld (dial_step),a
        ld (dial_ctr),a
        inc hl
        ld a,(hl)
        call bin_to_bcd
        ld (miss_ok),a
        inc hl
        ld a,(hl)
        ld (bld_sign),a
        inc hl
        ld a,(hl)
        ld (bld_welcome),a
        inc hl
        ld a,(hl)
        ld (bld_attr),a
        inc hl
        ld b,(hl)               ; Tasha's calls: how many; phone_schedule picks when
        inc hl
        ld (bld_room_list),hl
        call phone_schedule
        ld a,FRAMES_PER_SECOND
        ld (clock_frames),a
        xor a
        ld (dial_index),a
        ld (call_next),a
        ld (bld_elapsed),a
        ld (bld_elapsed+1),a
        ld (miss_tally),a
        ld (bld_signed),a
        ld (signed_bcd),a
        call hazards_reset_all
        xor a
        ld hl,bld_marked
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        ret

; In: A = room index. Loads and draws it (HUD rows included) and its exits.
room_enter:
        ld (cur_room),a
        ld l,a                  ; HL = room list + index*6
        ld h,0
        add hl,hl
        ld e,l
        ld d,h
        add hl,hl
        add hl,de
        ld de,(bld_room_list)
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push de
        ld de,cur_exits
        ld bc,4
        ldir
        pop hl
        call room_load
        jp room_draw

; Arm every hazard in every room of the building.
hazards_reset_all:
        ld a,(bld_rooms)
        ld b,a
        ld hl,(bld_room_list)
.room:  push bc
        push hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl                ; HL = room data
.rle:   ld a,(hl)               ; skip the tile codes: 1-127 run + tile, #80+ one byte, 0 end
        inc hl
        or a
        jr z,.list
        jp m,.rle
        inc hl
        jr .rle
.list:  ld b,(hl)
        inc hl
        ld a,b
        or a
        jr z,.next
.hz:    inc hl
        inc hl
        inc hl
        ld (hl),HZ_ARMED
        inc hl
        djnz .hz
.next:  pop hl
        ld de,ROOM_REC_SIZE
        add hl,de
        pop bc
        djnz .room
        ret

; Walk/climb off the edge into a neighbouring room. pl_x/pl_y must already hold the
; position in the new room. In: A = room index. The screen is blanked while it redraws.
room_change:
        push af
        call palette_black
        pop af
        call room_enter
        call caption_reset
        call hud_draw_room_status
        call hud_draw_numbers
        call nephew_init
        call worker_init
        xor a                   ; a hint window went with the old room
        ld (hint_row),a
        ld (sense_on),a         ; and the "?"
        ld de,(pl_x)
        ld (old_xy),de
        call player_draw
        jp palette_normal

; In: A = room index. Out: HL = its byte in bld_marked, A = its bit. Preserves C,DE.
room_bit:
        ld b,a
        rrca
        rrca
        rrca
        and #1f
        ld hl,bld_marked
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld a,b
        and 7
        ld b,a
        ld a,1
        inc b
.shift: dec b
        ret z
        add a,a
        jr .shift

; Out: Z set if the current room is not signed off yet. Trashes AF,B,HL.
room_is_marked:
        ld a,(cur_room)
        call room_bit
        and (hl)
        ret

; Out: NZ if any trap in the current room is still armed (evidence doesn't count).
; Trashes AF,B,HL.
room_any_armed:
        ld hl,(room_hazards)
        ld b,(hl)
        ld a,b
        or a
        ret z
        inc hl
        inc hl
        inc hl                  ; -> type of the first hazard
.loop:  ld a,(hl)
        inc hl
        cp HZ_EVIDENCE
        jr z,.next
        ld a,(hl)
        cp HZ_ARMED
        jr z,.armed
.next:  inc hl
        inc hl
        inc hl
        djnz .loop
        xor a
        ret
.armed: or 1
        ret

; Mark-safe key: sign off the current room. A room's outcome is decided the first
; time it is signed off; later presses only say so.
try_mark:
        ld a,(cur_room)
        call room_bit
        ld b,a
        and (hl)
        jr z,.new
        ld hl,sfx_already
        call sfx_play
        ld a,STR_MARK_ALREADY
        jp caption_show
.new:   ld a,(hl)
        or b
        ld (hl),a
        ld (hint_marked),a      ; (non-zero) he knows about M now
        ld hl,bld_signed
        inc (hl)
        ld a,(signed_bcd)
        add a,1
        daa
        ld (signed_bcd),a
        call hud_draw_room_status
        call hud_draw_rooms
        call room_any_armed
        jr nz,.miss
        ld de,SCORE_SIGNOFF
        call score_add
        ld hl,sfx_safe
        call sfx_play
        ld a,STR_MARK_SAFE
        jp caption_show
.miss:  ld hl,sfx_miss
        call sfx_play
        ld a,(miss_tally)
        cp MISS_TALLY_MAX
        jr z,.capped
        add a,1
        daa
        ld (miss_tally),a
        call hud_draw_misses
.capped:
        ld de,SCORE_MISS
        call score_sub
        ld b,MISS_COST
        call energy_lose
        ld a,BORDER_MISS
        call set_border
        ld a,MISS_BORDER_FRAMES
        ld (border_timer),a
        ld a,STR_MARK_MISS
        jp caption_show

; Out: carry set if Thanos is standing in front of the exit door.
at_exit:
        ld de,(pl_x)
        inc d                   ; feet row
        call map_addr
        ld a,(hl)
        and #7f
        cp TILE_EXIT_B
        scf
        ret z
        inc hl
        ld a,(hl)
        and #7f
        cp TILE_EXIT_B
        scf
        ret z
        or a
        ret

; Up at the exit door: leave if every room is signed off.
try_exit:
        ld a,(bld_rooms)
.room:  or a
        jr z,.open
        dec a
        ld c,a
        call room_bit
        and (hl)
        jr z,.locked
        ld a,c
        jr .room
.locked:
        ld hl,sfx_locked
        call sfx_play
        ld a,STR_EXIT_LOCKED
        jp caption_show
.open:  ld hl,sfx_exit
        call sfx_play
        ld a,PS_DONE
        ld (pl_state),a
        ld a,STR_EXIT_DONE
        jp caption_show
