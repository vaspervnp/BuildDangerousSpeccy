; ---------------------------------------------------------------- last-minute workers
; Most rooms still have a worker in them (room data: after the nephew), pacing one floor,
; and he is not pleased to see the inspector. Whenever Thanos is on his floor he stops,
; raises a tool, then
; throws it along the floor: hammers and half the wrenches at head height (duck), nails
; and the other wrenches at the feet (jump). A hit costs half a hat and leaves him reeling.
; One tool in the air at a time.
;
; In some rooms the slot holds the owner instead (room data type 2): he paces the same
; way but doesn't throw - he puts traps back. Any disarmed trap he passes in a room that
; isn't signed off yet is armed again ("That was decorative!") - though never in front of
; the inspector: with Thanos close by he just walks on. So sign rooms off as soon as they
; are clear.

WK_WINDUP       equ 22          ; frames the tool is up before it flies: the warning
WK_PAUSE        equ 40          ; frames before his first look, on entering the room
WK_REST         equ 500         ; frames after a throw before the next: 10 s, plus up to 63
WK_LOOK         equ 10          ; Thanos off his floor: look again this soon
WK_LINES        equ 4
AF_WORKER       equ AF_PEOPLE+13 ; idle (and walking A), tool up
AF_WORKER_STEP  equ AF_PEOPLE+16 ; walking B
WK_OWNER        equ 2           ; the room data's type byte: 1 a worker, 2 the owner
WK_PACE         equ 14          ; frames per step: slower than Bambis
TOOL_GFX          equ 26          ; hazard sheet: hammer, wrench, nails, two spin frames each
HIT_COST        equ 1           ; energy units: half a hat
HIT_BORDER      equ 10

; The test harness pokes this to 0 for scripts written without them.
workers_enabled: db 1

; Per kind: first frame, row (0 head height, 1 feet), frames per cell.
pj_kinds:
        db TOOL_GFX, 0, 3         ; hammer
        db TOOL_GFX+2, 0, 3       ; wrench, high
        db TOOL_GFX+2, 1, 3       ; wrench, low
        db TOOL_GFX+4, 1, 2       ; nails: low and quick

worker_lines:
        db STR_WORKER1, STR_WORKER2, STR_WORKER3, STR_WORKER4

; After a room is drawn: is there a worker in it?
worker_init:
        xor a
        ld (wk_on),a
        ld (pj_on),a
        ld (wk_said),a
        ld (wk_pose),a
        ld a,(workers_enabled)
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
        ld a,(hl)               ; and the nephew
        or a
        jr z,.own
        ld e,4
        add hl,de
.own:   inc hl
        ld a,(hl)
        or a
        ret z
        ld (wk_on),a
        inc hl
        ld de,wk_x              ; wk_x, wk_y, wk_min, wk_max
        ld bc,4
        ldir
        xor a
        ld (wk_dir),a
        ld (wk_anim),a
        ld hl,WK_PAUSE
        ld (wk_timer),hl
        ld a,l
        ld (wk_step),a
        ; fall through

worker_draw:
        ld a,(wk_on)
        cp WK_OWNER
        jr nz,.worker
        ld a,(wk_anim)          ; the owner: idle and talking frames, in step
        add a,AF_OWNER_IDLE
        jr .frame
.worker:
        ld a,(wk_pose)
        or a
        ld a,AF_WORKER+1        ; tool up
        jr nz,.frame
        ld a,(wk_anim)
        or a
        ld a,AF_WORKER
        jr z,.frame
        ld a,AF_WORKER_STEP
.frame: call frame_addr
        ld de,(wk_x)
        jp draw_sprite16

worker_redraw:
        ld de,(wk_x)
        call restore_2x2
worker_overlap:
        call worker_draw
        ld hl,wk_x              ; Thanos may be standing in front of him
        call near_player
        ret nc
        jp player_draw

; Every play frame, after the player.
worker_update:
        ld a,(wk_on)
        or a
        ret z
        ld a,(pl_state)
        or a                    ; PS_WALK only: everyone waits for calls and vignettes
        ret nz
        ld a,(pj_on)
        or a
        call nz,pj_update
        ld hl,wk_x              ; close to Thanos, redraws wipe each other: draw both
        call near_player
        call c,worker_overlap
        ld a,(wk_on)
        cp WK_OWNER
        jr z,owner_update
        ld a,(wk_pose)          ; walking, unless the tool is up
        or a
        call z,worker_walk
        ld hl,(wk_timer)
        dec hl
        ld (wk_timer),hl
        ld a,h
        or l
        ret nz
        ld a,(wk_pose)
        or a
        jp nz,worker_throw
        ld l,WK_LOOK            ; (H is 0)
        ld (wk_timer),hl
        ld a,(pj_on)
        or a
        ret nz
        ld a,(wk_y)             ; Thanos on his floor (or jumping on it)?
        ld hl,pl_y
        sub (hl)
        cp 4
        ret nc
        ld hl,WK_WINDUP         ; tool up
        ld (wk_timer),hl
        ld a,1
        ld (wk_pose),a
        call worker_redraw
        ld a,(wk_said)          ; a few words, once a visit
        or a
        ret nz
        inc a
        ld (wk_said),a
        ld a,(wk_line)
        ld e,a
        inc a
        cp WK_LINES
        jr c,.line
        xor a
.line:  ld (wk_line),a
        ld d,0
        ld hl,worker_lines
        add hl,de
        ld a,(hl)
        jp caption_show

; The owner: a step now and then, and any trap he is standing at put back.
owner_update:
        call worker_walk
        ld hl,wk_x              ; not with the inspector watching
        call near_player
        ret c
        call room_is_marked     ; signed off: too late for him
        ret nz
        ld ix,(room_hazards)
        ld b,(ix+0)
        inc ix
        ld a,b
        or a
        ret z
.loop:  ld a,(ix+HZ_STATE)
        cp HZ_DISARMED
        jr nz,.next
        ld a,(ix+HZ_TYPE)
        cp HZ_EVIDENCE          ; he'd never put his own papers back
        jr z,.next
        ld a,(ix+HZ_X)          ; under one of his two columns
        ld hl,wk_x
        sub (hl)
        cp 2
        jr nc,.next
        ld a,(wk_y)             ; from his knees to a hand's reach over his head
        inc a
        sub (ix+HZ_ROW)
        cp 5
        jr nc,.next
        ld (ix+HZ_STATE),HZ_ARMED
        ld e,(ix+HZ_X)
        ld d,(ix+HZ_ROW)
        call draw_cell          ; the tell is back
        call worker_draw
        ld hl,sfx_locked
        call sfx_play
        ld a,STR_OWNER_REARM
        jp caption_show
.next:  ld de,HZ_SIZE
        add ix,de
        djnz .loop
        ret

; A step along his beat every WK_PACE frames; at either end he turns round.
worker_walk:
        ld hl,wk_step
        dec (hl)
        ret nz
        ld (hl),WK_PACE
        ld de,(wk_x)
        call restore_2x2
        ld a,(wk_dir)
        or a
        ld a,(wk_x)
        jr nz,.left
        ld hl,wk_max
        cp (hl)
        jr nc,.turn
        inc a
        jr .moved
.left:  ld hl,wk_min
        cp (hl)
        jr z,.turn
        jr c,.turn
        dec a
.moved: ld (wk_x),a
        jr .anim
.turn:  ld hl,wk_dir
        ld a,(hl)
        xor 1
        ld (hl),a
.anim:  ld hl,wk_anim
        ld a,(hl)
        xor 1
        ld (hl),a
        jp worker_overlap

worker_throw:
        xor a
        ld (wk_pose),a
        call worker_redraw
        call rand               ; then a long rest
        and 63
        ld l,a
        ld h,0
        ld de,WK_REST
        add hl,de
        ld (wk_timer),hl
        ld a,(pl_x)             ; towards Thanos, from beside him
        ld hl,wk_x
        cp (hl)                 ; carry: Thanos is to the left
        ld a,(hl)
        ld c,-1
        dec a                   ; (keeps carry)
        jr c,.dir
        ld c,1
        add a,3
.dir:   ld (pj_x),a
        ld a,c
        ld (pj_dx),a
        call rand
        and 3
        ld c,a
        add a,a
        add a,c
        ld e,a
        ld d,0
        ld hl,pj_kinds
        add hl,de
        ld a,(hl)
        ld (pj_gfx),a
        inc hl
        ld a,(wk_y)
        add a,(hl)
        ld (pj_row),a
        inc hl
        ld a,(hl)
        ld (pj_speed),a
        ld (pj_wait),a
        ld a,1
        ld (pj_on),a
        ld hl,sfx_throw
        call sfx_play
        jr pj_enter

; The tool in flight: a cell every pj_speed frames, until a wall, the edge, or Thanos.
pj_update:
        ld hl,pj_wait
        dec (hl)
        ret nz
        ld a,(pj_speed)
        ld (hl),a
        ld de,(pj_x)
        call draw_cell          ; off the cell it was on, putting back whoever was there
        ld a,(npc_on)
        or a
        jr z,.thanos
        ld hl,npc_x
        call in_2x2
        call c,nephew_draw
        ld de,(pj_x)
.thanos:
        ld hl,pl_x
        call in_2x2
        call c,player_draw
        ld a,(pj_dx)
        ld hl,pj_x
        add a,(hl)
        ld (hl),a
        ld a,(pj_spin)
        xor 1
        ld (pj_spin),a
pj_enter:
        ld de,(pj_x)
        ld a,e
        cp MAP_W
        jr nc,pj_gone
        call flags_at
        and TILEF_SOLID
        jr nz,pj_gone
        ld a,(pl_x)             ; Thanos's columns: his feet always count, his head
        ld b,a                  ; unless he is ducking
        ld a,e
        sub b
        cp 2
        jr nc,.draw
        ld a,(pl_y)
        inc a
        cp d
        jr z,pl_hit
        dec a
        cp d
        jr nz,.draw
        ld a,(pl_duck)
        or a
        jr z,pl_hit
.draw:  ld a,(pj_spin)
        ld hl,pj_gfx
        add a,(hl)
        push de
        call sprite17
        pop de
        jp draw_sprite8

pl_hit:
        xor a
        ld (pj_on),a
        ld (pl_jump),a          ; knocked out of a jump: he drops when he comes to
        ld hl,sfx_bonk
        call sfx_play
        ld b,HIT_COST
        call energy_lose
        ld a,HIT_STUN
        ld (pl_wait),a
        ld a,BORDER_HIT
        call set_border
        ld a,HIT_BORDER
        ld (border_timer),a
        ld a,STR_OUCH
        jp caption_show

pj_gone:
        xor a
        ld (pj_on),a
        ret

; In: DE = a cell (E col, D row), HL -> x,y of a 2x2 figure. Out: carry if the cell is
; part of it. Preserves DE.
in_2x2:
        ld a,e
        sub (hl)
        cp 2
        ret nc
        inc hl
        ld a,d
        sub (hl)
        cp 2
        ret

; In: HL -> x,y of a 2x2 figure. Out: carry if Thanos is within two cells of it each way.
near_player:
        ld a,(pl_x)
        sub (hl)
        add a,2
        cp 5
        ret nc
        inc hl
        ld a,(pl_y)
        sub (hl)
        add a,2
        cp 5
        ret
