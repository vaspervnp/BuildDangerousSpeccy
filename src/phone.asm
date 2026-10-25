; ---------------------------------------------------------------- Tasha's phone calls
; A few times per building (the header says how many; the times are random: the first
; 20-51 s into the inspection, then every 30-61 s) Thanos's wife phones. He has to take it: input is locked and the clock keeps running,
; so the call is the delay. She asks something; the right answer ends the call quickly
; (and scores), the wrong one - or eight seconds of silence - gets a longer reply and a rant.
;
; The panel: 7 rows across the screen, at the top, or at the bottom when he is up there.
;   row P           bricks
;   rows P+1..P+5   cell 0 brick, cells 1-25 text (text columns 0-32), cell 26 brick,
;                   cells 27-30 her face (32x32, rows P+1..P+4; bricks under it), cell 31
;                   bricks
;   row P+6         bricks
; Her lines on rows P+1 and P+2, the two answers on rows P+4 and P+5. She talks by
; drawing the open-mouth patch over the face, and the face again to shut it.

CS_RING         equ 0           ; phone ringing, he fumbles for it
CS_TALK         equ 1           ; she's talking (mouth moving)
CS_HOLD         equ 2           ; her line stays up a moment
CS_CHOOSE       equ 3           ; pick an answer: Up/Down, Fire

CALL_RING       equ 60
CALL_TALK       equ 48
CALL_HOLD       equ 70
CALL_WAIT       equ 200         ; x2 frames = 8 s to answer, then she notices the silence
MOUTH_FRAMES      equ 6
PHONE_TOP       equ 2
PHONE_BOTTOM    equ 16
PANEL_ROWS      equ 7
PANEL_TEXT_COL  equ 1           ; text columns
ANSWER_COL      equ 3
FACE_COL        equ 27          ; cell
FACE_BYTES      equ 32*32/8+16  ; the bitmap and its attributes
MOUTH_X         equ 8           ; the patch in build/tasha.bin after the face (see Makefile)
MOUTH_Y         equ 22
MOUTH_W         equ 16
MOUTH_H         equ 8
SCORE_CALL      equ #50
CALL_SCRIPT_COUNT    equ 6
CS_SIZE         equ 9           ; call script: Q1, Q2, good, bad, yes1, yes2, no1, no2,
                                ; 1 if the good answer is listed first

; The test harness pokes this to 0 for scripts written without calls.
calls_enabled:  db 1

call_scripts:
        db STR_CALL1_Q1, STR_CALL1_Q2, STR_CALL1_GOOD, STR_CALL1_BAD
        db STR_CALL1_YES1, STR_CALL1_YES2, STR_CALL1_NO1, STR_CALL1_NO2, 1
        db STR_CALL2_Q1, STR_CALL2_Q2, STR_CALL2_GOOD, STR_CALL2_BAD
        db STR_CALL2_YES1, STR_CALL2_YES2, STR_CALL2_NO1, STR_CALL2_NO2, 0
        db STR_CALL3_Q1, STR_CALL3_Q2, STR_CALL3_GOOD, STR_CALL3_BAD
        db STR_CALL3_YES1, STR_CALL3_YES2, STR_CALL3_NO1, STR_CALL3_NO2, 0
        db STR_CALL4_Q1, STR_CALL4_Q2, STR_CALL4_GOOD, STR_CALL4_BAD
        db STR_CALL4_YES1, STR_CALL4_YES2, STR_CALL4_NO1, STR_CALL4_NO2, 1
        db STR_CALL5_Q1, STR_CALL5_Q2, STR_CALL5_GOOD, STR_CALL5_BAD
        db STR_CALL5_YES1, STR_CALL5_YES2, STR_CALL5_NO1, STR_CALL5_NO2, 1
        db STR_CALL6_Q1, STR_CALL6_Q2, STR_CALL6_GOOD, STR_CALL6_BAD
        db STR_CALL6_YES1, STR_CALL6_YES2, STR_CALL6_NO1, STR_CALL6_NO2, 0
call_scripts_end:
        assert call_scripts_end-call_scripts == CALL_SCRIPT_COUNT*CS_SIZE

rant_lines:
        db STR_RANT1A, STR_RANT1B, STR_RANT2A, STR_RANT2B, STR_RANT3A, STR_RANT3B

CALL_FIRST      equ 20          ; seconds: never before this
CALL_GAP        equ 30          ; at least this long between calls
CALL_SPREAD     equ 31          ; plus 0..CALL_SPREAD (a mask)

; In: B = number of calls (1-3). Picks this building's call times into bld_calls
; (seconds into the inspection; 0 = no more calls). Preserves HL.
phone_schedule:
        push hl
        ld hl,bld_calls
        ld c,6
.clear: ld (hl),0
        inc hl
        dec c
        jr nz,.clear
        ld hl,bld_calls
        ld de,CALL_FIRST
.next:  push hl
        push de
        call rand
        ld a,l
        pop de
        pop hl
        and CALL_SPREAD
        add a,e
        ld e,a
        adc a,d
        sub e
        ld d,a                  ; DE = this call's time
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld a,e                  ; the next one comes at least CALL_GAP later
        add a,CALL_GAP
        ld e,a
        adc a,d
        sub e
        ld d,a
        djnz .next
        pop hl
        ret

; 16-bit xorshift. Stirred every game loop (main.asm), so the time spent on the title
; screen seeds it. Out: HL = A = new value (low byte in A). Trashes F.
rand:
        ld hl,(rnd_seed)
        ld a,h
        rra
        ld a,l
        rra
        xor h
        ld h,a
        ld a,l
        rra
        ld a,h
        rra
        xor l
        ld l,a
        xor h
        ld h,a
        ld (rnd_seed),hl
        ld a,l
        ret

; From play_update while he is walking: is a call due?
phone_check:
        ld a,(calls_enabled)
        or a
        ret z
        ld a,(pl_jump)          ; not in mid-air: she can wait for him to land
        or a
        ret nz
        ld a,(call_next)
        cp 3
        ret nc
        add a,a
        ld e,a
        ld d,0
        ld hl,bld_calls
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        ret z                   ; no more calls in this building
        ld hl,(bld_elapsed)
        or a
        sbc hl,de
        ret c                   ; not yet
        ld hl,call_next
        inc (hl)
        ; fall through

phone_start:
        call sense_hide
        ld a,PS_PHONE
        ld (pl_state),a
        xor a                   ; CS_RING
        ld (call_state),a
        ld (call_choice),a
        ld (call_qlen),a
        ld (call_qpos),a
        ld (call_mouth),a
        ld (call_asked),a
        ld a,CALL_RING
        ld (call_timer),a
        ld a,(call_count)       ; the next script, round the campaign
        ld b,a
        inc a
        cp CALL_SCRIPT_COUNT
        jr c,.wrap
        xor a
.wrap:  ld (call_count),a
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,b                 ; * CS_SIZE
        ld e,a
        ld d,0
        ld hl,call_scripts
        add hl,de
        ld (call_script),hl
        ld a,(pl_y)             ; the panel goes where he isn't
        cp 11
        ld a,PHONE_TOP
        jr nc,.row
        ld a,PHONE_BOTTOM
.row:   ld (call_row),a
        ld hl,sfx_ring
        call sfx_play
        ld a,STR_PHONE_RING
        call caption_show
        ld de,(pl_x)            ; he picks up
        call restore_2x2
        ld hl,vignette_gfx+VF_PHONE*68
        ld de,(pl_x)
        jp draw_sprite16

; Every frame of a call (player_update, PS_PHONE).
phone_update:
        ld a,(call_state)
        cp CS_CHOOSE
        jp z,phone_choose
        ld hl,call_timer
        dec (hl)
        jr z,.timeout
        cp CS_TALK
        ret nz
        ld a,(hl)               ; talking: flap the mouth every MOUTH_FRAMES frames
.mod:   sub MOUTH_FRAMES
        jr z,.flap
        jr nc,.mod
        ret
.flap:  ld a,(call_mouth)
        xor 1
        ld (call_mouth),a
        call draw_face
        ld a,(call_timer)
        jp sfx_babble_hi
.timeout:
        ld a,(call_state)
        or a                    ; CS_RING: he answers, she starts
        jr z,.answer
        cp CS_TALK
        jp nz,phone_next        ; CS_HOLD: the next thing she says, or she hangs up
        xor a                   ; she's said it: mouth shut
        ld (call_mouth),a
        call draw_face
        ld a,(call_asked)
        or a
        jr nz,.ask
        ld a,CS_HOLD
        ld (call_state),a
        ld a,CALL_HOLD
        ld (call_timer),a
        ret
.ask:   xor a                   ; that was the question: the answers
        ld (call_asked),a
        ld a,CS_CHOOSE
        ld (call_state),a
        ld a,CALL_WAIT
        ld (call_timer),a
        ld a,STR_PHONE_HINT     ; how to answer, on the spare row
        call get_string
        ld a,(call_row)
        add a,3
        ld d,a
        ld e,PANEL_TEXT_COL
        ld c,PEN2_MASK
        call print_str
        jp draw_answers
.answer:
        call panel_draw
        ld a,1
        ld (call_asked),a
        ld hl,(call_script)
        ld b,(hl)
        inc hl
        ld c,(hl)
        jp phone_say

phone_choose:
        ld a,(keys_new)
        and KEY_UP+KEY_DOWN
        jr z,.fire
        ld a,(call_choice)
        xor 1
        ld (call_choice),a
        jp draw_answers
.fire:  ld a,(keys_new)
        and KEY_FIRE
        jr nz,.chosen
        ld hl,call_tick         ; the answer clock runs at half speed
        inc (hl)
        bit 0,(hl)
        ret nz
        ld hl,call_timer
        dec (hl)
        ret nz
        ld b,STR_PHONE_SILENT1  ; silence: she notices, then as a wrong answer
        ld c,STR_PHONE_SILENT2
        call queue_add
        jr .wrong
.chosen:
        ld hl,(call_script)
        ld de,CS_SIZE-1
        add hl,de
        ld a,(call_choice)      ; 0 = top line: right if the good answer is listed first
        xor (hl)
        jr z,.wrong
        ld de,SCORE_CALL
        call score_add
        call hud_draw_score
        ld hl,(call_script)
        ld de,4                 ; her happy reply
        add hl,de
        ld b,(hl)
        inc hl
        ld c,(hl)
        call queue_add
        ld a,1
        ld (call_happy),a
        jr phone_next
.wrong: ld hl,(call_script)
        ld de,6                 ; her unhappy reply
        add hl,de
        ld b,(hl)
        inc hl
        ld c,(hl)
        call queue_add
        ld a,(rant_index)       ; and a rant, the next of three
        ld e,a
        inc a
        cp 3
        jr c,.rant
        xor a
.rant:  ld (rant_index),a
        ld a,e
        add a,a
        ld e,a
        ld d,0
        ld hl,rant_lines
        add hl,de
        ld b,(hl)
        inc hl
        ld c,(hl)
        call queue_add
        xor a
        ld (call_happy),a
        ; fall through

; Say the next queued pair of lines, or hang up.
phone_next:
        ld a,(call_qpos)
        ld hl,call_qlen
        cp (hl)
        jr nc,phone_end
        inc a
        ld (call_qpos),a
        dec a
        add a,a
        ld hl,call_q
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld b,(hl)
        inc hl
        ld c,(hl)
        ; fall through

; In: B, C = her two lines (STR_*). Prints them and starts her talking.
phone_say:
        push bc
        call panel_clear_text
        pop bc
        ld a,(call_row)
        inc a
        ld d,a
        ld a,b
        call .line
        inc d
        ld a,c
        call .line
        ld a,CS_TALK
        ld (call_state),a
        ld a,CALL_TALK
        ld (call_timer),a
        ret
.line:  push bc
        push de
        call get_string
        pop de
        ld e,PANEL_TEXT_COL
        ld c,PEN3_MASK
        call print_str
        pop bc
        ret

; She hangs up: put the room back.
phone_end:
        ld hl,sfx_hangup
        call sfx_play
        ld a,(call_happy)
        or a
        ld a,STR_PHONE_END_GOOD
        jr nz,.cap
        ld a,STR_PHONE_END_BAD
.cap:   call caption_show
        ld a,(call_row)
        ld d,a
        ld b,PANEL_ROWS
        call rows_restore
        ld a,PS_WALK
        ld (pl_state),a
        ld a,(npc_on)
        or a
        call nz,nephew_draw
        ld de,(pl_x)
        call restore_2x2
        jp player_draw

; In: B, C = a pair of lines to say. Trashes AF,HL.
queue_add:
        ld hl,call_qlen
        ld a,(hl)
        inc (hl)
        add a,a
        ld hl,call_q
        add a,l
        ld l,a
        adc a,h
        sub l
        ld h,a
        ld (hl),b
        inc hl
        ld (hl),c
        ret

; ---------------------------------------------------------------- the panel
panel_draw:
        ld a,(call_row)
        ld d,a
        call brick_row
        ld a,d
        add a,PANEL_ROWS-1
        ld d,a
        call brick_row
        ld a,(call_row)
        inc a
        ld d,a
        ld b,PANEL_ROWS-2
.row:   push bc
        ld e,0
        call .brick
        ld e,FACE_COL-1
        call .brick
        ld e,FACE_COL+4
        call .brick
        inc d
        pop bc
        djnz .row
        ld e,FACE_COL           ; under the face
        dec d
.under: call .brick
        inc e
        ld a,e
        cp FACE_COL+4
        jr nz,.under
        call panel_clear_text
        jr draw_face
.brick: ld a,TILE_BRICK
        jp draw_tile_at

; Blank the text area (rows P+1..P+5, cells 1-25).
panel_clear_text:
        ld a,(call_row)
        inc a
        ld d,a
        ld b,PANEL_ROWS-2
.row:   push bc
        ld e,1
.cell:  ld a,TILE_BLACK
        call draw_tile_at
        inc e
        ld a,e
        cp FACE_COL-1
        jr nz,.cell
        inc d
        pop bc
        djnz .row
        ret

; Tasha's face, then her open mouth over it if call_mouth is set.
draw_face:
        ld hl,tasha_gfx
        ld a,(call_row)
        inc a
        ld d,a
        ld e,FACE_COL
        ld b,4                  ; four rows of cells
.row:   push bc
        push hl
        call cell_addr          ; HL = screen (DE kept)
        ex de,hl
        ex (sp),hl              ; HL = source; row/col on the stack
        ld b,8
.line:  push bc
        push de
        ld bc,4                 ; 32 pixels
        ldir
        pop de
        inc d
        pop bc
        djnz .line
        pop de
        inc d
        pop bc
        djnz .row
        ld a,(call_row)         ; the colours: HL is at them
        inc a
        ld d,a
        ld b,4
.arow:  ld e,FACE_COL
        ld c,4
.acell: ld a,(hl)
        inc hl
        push hl
        call set_attr
        pop hl
        inc e
        dec c
        jr nz,.acell
        inc d
        djnz .arow
        ld a,(call_mouth)
        or a
        ret z
        ld hl,tasha_gfx+FACE_BYTES
        ld c,MOUTH_Y            ; C = face line
.mouth: ld a,c
        rrca
        rrca
        rrca
        and #1f
        ld b,a
        ld a,(call_row)
        inc a
        add a,b
        ld d,a                  ; the screen row holding this line
        ld e,FACE_COL+MOUTH_X/8
        push hl
        call cell_addr
        ld a,c
        and 7
        add a,h                 ; + line * #100
        ld h,a
        ex de,hl
        pop hl
        ld a,c
        ld bc,MOUTH_W/8
        ldir
        ld c,a
        inc c
        ld a,c
        cp MOUTH_Y+MOUTH_H
        jr nz,.mouth
        ret

; The two answers, the chosen one in white with a dash.
draw_answers:
        ld hl,(call_script)
        inc hl
        inc hl
        ld c,(hl)               ; good
        inc hl
        ld b,(hl)               ; bad
        ld de,CS_SIZE-1-3
        add hl,de
        ld a,(hl)
        or a
        jr nz,.order            ; good first: C on top
        ld a,c
        ld c,b
        ld b,a
.order: ld a,(call_row)
        add a,4
        ld d,a
        ld a,c
        ld e,0
        call .one
        inc d
        ld a,b
        ld e,1
.one:   push bc                 ; A = line, D = row, E = 0 top / 1 bottom
        push de
        push af
        ld a,(call_choice)
        cp e
        ld c,PEN1_MASK
        ld a,0                  ; (a space)
        jr nz,.mark
        ld c,PEN3_MASK
        ld a,GLYPH_DASH
.mark:  ld e,PANEL_TEXT_COL
        call print_char
        pop af
        push bc
        push de
        call get_string
        pop de
        pop bc
        ld e,ANSWER_COL
        call print_str
        pop de
        pop bc
        ret
