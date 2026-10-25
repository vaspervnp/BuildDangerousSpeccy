; ---------------------------------------------------------------- outdoor scenes
; The ribbon-cutting outside every building: one shared tile room (assets/rooms/outdoor.txt)
; with the building's name lit up on the facade, up to ACTOR_COUNT 16x16 actors, and a
; byte-code script per scene. Commands run one after another; SAY, WALK and CHEER take
; several frames. Fire skips the whole scene (handled in main.asm).
;
;   SC_WAIT  frames
;   SC_SAY   actor (or NOBODY), STR_* (or SAY_WELCOME), frames to hold once typed
;            - types a caption; the actor's mouth (frame pair) moves while it types
;   SC_SHOW  actor, x, row, frame
;   SC_HIDE  actor
;   SC_FRAME actor, frame
;   SC_WALK  actor, target x, frames per step - flips the actor's frame pair as it goes
;   SC_TILE  x, row, tile
;   SC_CHEER times (even) - every visible townsperson flips to the other frame of its pair

SC_END          equ 0
SC_WAIT         equ 1
SC_SAY          equ 2
SC_SHOW         equ 3
SC_HIDE         equ 4
SC_FRAME        equ 5
SC_WALK         equ 6
SC_TILE         equ 7
SC_CHEER        equ 8
SC_SFX          equ 9           ; db voice (0/1) : dw effect

SAY_WELCOME     equ #fe             ; the building's own welcome line
NOBODY          equ #ff

SM_NEXT         equ 0               ; scene_mode: ready for the next command
SM_SAY          equ 1
SM_WALK         equ 2
SM_CHEER        equ 3

ACT_THANOS      equ 0
ACT_OWNER       equ 1
ACT_CROWD       equ 2               ; 2..5
ACTOR_COUNT     equ 6
ACT_SIZE        equ 4
A_VIS           equ 0
A_X             equ 1
A_Y             equ 2
A_FRAME         equ 3

; Actor frames: 0-7 build/thanos.bin, 8-63 build/people.bin, 64+ build/vignettes.bin
AF_THANOS_R     equ 0
AF_THANOS_L     equ 4
AF_PEOPLE       equ 8
AF_OWNER_IDLE   equ 8               ; pairs: idle/talk, cut/shrug
AF_OWNER_TALK   equ 9
AF_OWNER_CUT    equ 10
AF_OWNER_SHRUG  equ 11
AF_GRANDMA      equ 12              ; townsfolk: idle, cheer
AF_MAN          equ 14
AF_KID          equ 16
AF_NEPHEW       equ 18              ; Bambis (nephew.asm): walk A, walk B, selfie
AF_NEPHEW_SELFIE equ 20
AF_VIGNETTE     equ 64
AF_UPSIDE_DOWN  equ AF_VIGNETTE+VF_UPSIDE_DOWN

SIGN_ROW        equ 4
DOOR_X          equ 15
DOOR_ROW        equ 20              ; the ribbon is across the bottom of the door
STREET_Y        equ 19
TALK_FRAMES     equ 6
CHEER_FRAMES    equ 8

actors_init:                        ; visible, x, row, frame
        db 0, 30, STREET_Y, AF_THANOS_L
        db 1, 20, STREET_Y-1, AF_OWNER_IDLE     ; on the stage
        db 1, 0, STREET_Y, AF_GRANDMA
        db 1, 2, STREET_Y, AF_MAN
        db 1, 4, STREET_Y, AF_KID
        db 1, 6, STREET_Y, AF_MAN

; ---------------------------------------------------------------- scripts
scene_intro:
        db SC_SFX, 1 : dw sfx_crowd
        db SC_WAIT, 25
        db SC_SAY, ACT_OWNER, SAY_WELCOME, 40
        db SC_SAY, ACT_OWNER, STR_INTRO_2, 40
        db SC_SAY, ACT_OWNER, STR_INTRO_3, 30
        db SC_SHOW, ACT_THANOS, 30, STREET_Y, AF_THANOS_L
        db SC_WALK, ACT_THANOS, DOOR_X, 3
        db SC_WAIT, 10
        db SC_HIDE, ACT_THANOS
        db SC_WAIT, 15
        db SC_END

; per OUT_*
outro_scripts:
        dw outro_win, outro_delay, outro_ribbon, outro_noenergy

outro_win:
        db SC_WAIT, 20
        db SC_SHOW, ACT_THANOS, DOOR_X, STREET_Y, AF_THANOS_L
        db SC_WALK, ACT_THANOS, DOOR_X-3, 4
        db SC_SAY, NOBODY, STR_OUTRO_WIN1, 30
        db SC_FRAME, ACT_OWNER, AF_OWNER_CUT
        db SC_SFX, 0 : dw sfx_snip
        db SC_TILE, DOOR_X, DOOR_ROW, TILE_RIBBON_CUT
        db SC_TILE, DOOR_X+1, DOOR_ROW, TILE_RIBBON_CUT
        db SC_WAIT, 20
        db SC_SAY, NOBODY, STR_OUTRO_WIN2, 0
        db SC_SFX, 0 : dw sfx_fanfare
        db SC_SFX, 1 : dw sfx_crowd
        db SC_CHEER, 10
        db SC_WAIT, 20
        db SC_END

outro_delay:
        db SC_WAIT, 20
        db SC_SHOW, ACT_THANOS, DOOR_X, STREET_Y, AF_THANOS_L
        db SC_WALK, ACT_THANOS, DOOR_X-3, 4
        db SC_SAY, NOBODY, STR_OUTRO_DELAY1, 30
        db SC_FRAME, ACT_OWNER, AF_OWNER_SHRUG
        db SC_SFX, 0 : dw sfx_trombone
        db SC_SAY, NOBODY, STR_OUTRO_DELAY2, 40
        db SC_END

outro_noenergy:                     ; thrown out of his own inspection, then as below
        db SC_WAIT, 20
        db SC_SHOW, ACT_THANOS, DOOR_X, STREET_Y, AF_UPSIDE_DOWN
        db SC_SFX, 0 : dw sfx_thud
        db SC_WAIT, 5
        db SC_SHOW, ACT_THANOS, DOOR_X-2, STREET_Y, AF_UPSIDE_DOWN
        db SC_WAIT, 5
        db SC_SHOW, ACT_THANOS, DOOR_X-4, STREET_Y, AF_UPSIDE_DOWN
        db SC_WAIT, 30
        db SC_SAY, ACT_OWNER, STR_OUTRO_HURT1, 20
        db SC_FRAME, ACT_OWNER, AF_OWNER_CUT
        db SC_SFX, 0 : dw sfx_snip
        db SC_TILE, DOOR_X, DOOR_ROW, TILE_RIBBON_CUT
        db SC_TILE, DOOR_X+1, DOOR_ROW, TILE_RIBBON_CUT
        db SC_SFX, 1 : dw sfx_crowd
        db SC_WAIT, 15
        db SC_WALK, ACT_CROWD+3, DOOR_X, 2
        db SC_HIDE, ACT_CROWD+3
        db SC_WALK, ACT_CROWD+2, DOOR_X, 2
        db SC_HIDE, ACT_CROWD+2
        db SC_WALK, ACT_CROWD+1, DOOR_X, 2
        db SC_HIDE, ACT_CROWD+1
        db SC_WALK, ACT_CROWD, DOOR_X, 2
        db SC_HIDE, ACT_CROWD
        db SC_SFX, 0 : dw sfx_trombone
        db SC_SAY, NOBODY, STR_OUTRO_LATE2, 40
        db SC_END

outro_ribbon:                       ; time's up: the owner opens anyway, Thanos still inside
        db SC_WAIT, 20
        db SC_SAY, ACT_OWNER, STR_OUTRO_LATE1, 20
        db SC_FRAME, ACT_OWNER, AF_OWNER_CUT
        db SC_SFX, 0 : dw sfx_snip
        db SC_TILE, DOOR_X, DOOR_ROW, TILE_RIBBON_CUT
        db SC_TILE, DOOR_X+1, DOOR_ROW, TILE_RIBBON_CUT
        db SC_SFX, 1 : dw sfx_crowd
        db SC_WAIT, 15
        db SC_WALK, ACT_CROWD+3, DOOR_X, 2
        db SC_HIDE, ACT_CROWD+3
        db SC_WALK, ACT_CROWD+2, DOOR_X, 2
        db SC_HIDE, ACT_CROWD+2
        db SC_WALK, ACT_CROWD+1, DOOR_X, 2
        db SC_HIDE, ACT_CROWD+1
        db SC_WALK, ACT_CROWD, DOOR_X, 2
        db SC_HIDE, ACT_CROWD
        db SC_SFX, 0 : dw sfx_trombone
        db SC_SAY, NOBODY, STR_OUTRO_LATE2, 40
        db SC_END

; ---------------------------------------------------------------- engine
; In: HL = script. Draws the outdoor scene for the current building and starts the script.
scene_start:
        ld (scene_ptr),hl
        xor a
        ld (scene_wait),a
        ld (scene_mode),a
        call palette_black
        call caption_reset
        ld hl,room_outdoor
        call room_load
        call room_draw
        call hud_draw_numbers
        ld a,(bld_sign)
        call get_string
        ld d,SIGN_ROW
        ld c,PEN1_MASK
        call print_centered
        ld hl,actors_init
        ld de,actors
        ld bc,ACTOR_COUNT*ACT_SIZE
        ldir
        call actors_draw
        jp palette_normal

; One frame of the script. Out: carry set once it has ended.
scene_update:
        ld a,(scene_wait)
        or a
        jr z,.mode
        dec a
        ld (scene_wait),a
        or a
        ret
.mode:  ld a,(scene_mode)
        cp SM_SAY
        jp z,say_tick
        cp SM_WALK
        jp z,walk_tick
        cp SM_CHEER
        jp z,cheer_tick
        ld hl,(scene_ptr)
        ld a,(hl)
        inc hl
        or a
        scf
        ret z                   ; SC_END
        dec a
        add a,a
        ld e,a
        ld d,0
        push hl
        ld hl,scene_commands
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ex (sp),hl              ; handler on the stack, HL = its operands
        ret

scene_commands:
        dw cmd_wait, cmd_say, cmd_show, cmd_hide, cmd_frame, cmd_walk, cmd_tile, cmd_cheer
        dw cmd_sfx

; Handlers get HL = operands, must leave scene_ptr past them and return carry clear.
cmd_wait:
        ld a,(hl)
        inc hl
        ld (scene_wait),a
scene_next:
        ld (scene_ptr),hl
scene_cont:
        or a
        ret

cmd_say:
        ld a,(hl)
        inc hl
        ld (scene_speaker),a
        ld a,(hl)
        inc hl
        cp SAY_WELCOME
        jr nz,.text
        ld a,(bld_welcome)
.text:  ld b,(hl)
        inc hl
        ld (scene_ptr),hl
        ld hl,scene_hold
        ld (hl),b
        call caption_show
        xor a
        ld (scene_tick),a
        ld a,SM_SAY
        ld (scene_mode),a
        jr scene_cont

say_tick:
        ld hl,(caption_ptr)
        ld a,h
        or l
        jr z,.said
        ld hl,scene_tick
        inc (hl)
        ld a,(hl)
        cp TALK_FRAMES
        jr c,scene_cont
        ld (hl),0
        ld a,(scene_speaker)
        cp NOBODY
        jr z,scene_cont
        call actor_ix
        call actor_erase
        ld a,(ix+A_FRAME)
        xor 1
        ld (ix+A_FRAME),a
        call actors_draw
        ld a,(caption_ptr)      ; a syllable per mouth movement
        call sfx_babble
        jr scene_cont
.said:  ld a,(scene_speaker)
        cp NOBODY
        jr z,.hold
        call actor_ix
        call actor_erase
        ld a,(ix+A_FRAME)
        and #fe
        ld (ix+A_FRAME),a
        call actors_draw
.hold:  ld a,(scene_hold)
        ld (scene_wait),a
        xor a
        ld (scene_mode),a
        jr scene_cont

cmd_sfx:
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (scene_ptr),hl
        ex de,hl
        or a
        jr nz,.b
        call sfx_play
        jp scene_cont
.b:     call sfx_play_b
        jp scene_cont

cmd_show:
        ld a,(hl)
        inc hl
        push hl
        call actor_ix
        call actor_erase
        pop hl
        ld a,(hl)
        inc hl
        ld (ix+A_X),a
        ld a,(hl)
        inc hl
        ld (ix+A_Y),a
        ld a,(hl)
        inc hl
        ld (ix+A_FRAME),a
        ld (ix+A_VIS),1
        ld (scene_ptr),hl
        call actors_draw
        jp scene_cont

cmd_hide:
        ld a,(hl)
        inc hl
        ld (scene_ptr),hl
        call actor_ix
        call actor_erase
        ld (ix+A_VIS),0
        call actors_draw
        jp scene_cont

cmd_frame:
        ld a,(hl)
        inc hl
        push hl
        call actor_ix
        call actor_erase
        pop hl
        ld a,(hl)
        inc hl
        ld (ix+A_FRAME),a
        ld (scene_ptr),hl
        call actors_draw
        jp scene_cont

cmd_walk:
        ld a,(hl)
        inc hl
        ld (scene_actor),a
        ld a,(hl)
        inc hl
        ld (scene_target),a
        ld a,(hl)
        inc hl
        ld (scene_delay),a
        ld (scene_ptr),hl
        xor a
        ld (scene_tick),a
        ld a,SM_WALK
        ld (scene_mode),a
        jp scene_cont

walk_tick:
        ld hl,scene_tick
        inc (hl)
        ld a,(scene_delay)
        cp (hl)
        jp nz,scene_cont
        ld (hl),0
        ld a,(scene_actor)
        call actor_ix
        call actor_erase
        ld a,(scene_target)
        cp (ix+A_X)
        jr z,.arrived
        jr nc,.right
        dec (ix+A_X)
        jr .step
.right: inc (ix+A_X)
.step:  ld a,(ix+A_FRAME)
        xor 1
        ld (ix+A_FRAME),a
        call actors_draw
        jp scene_cont
.arrived:
        ld a,(ix+A_FRAME)
        and #fe
        ld (ix+A_FRAME),a
        call actors_draw
        xor a
        ld (scene_mode),a
        jp scene_cont

cmd_tile:
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        inc hl
        ld (scene_ptr),hl
        call map_addr_keep_a
        ld (hl),a
        call draw_cell
        call actors_draw
        jp scene_cont

cmd_cheer:
        ld a,(hl)
        inc hl
        ld (scene_count),a
        ld (scene_ptr),hl
        xor a
        ld (scene_tick),a
        ld a,SM_CHEER
        ld (scene_mode),a
        jp scene_cont

cheer_tick:
        ld hl,scene_tick
        inc (hl)
        ld a,(hl)
        cp CHEER_FRAMES
        jp c,scene_cont
        ld (hl),0
        ld a,ACT_CROWD
.one:   push af
        call actor_ix
        ld a,(ix+A_VIS)
        or a
        jr z,.skip
        call actor_erase
        ld a,(ix+A_FRAME)
        xor 1
        ld (ix+A_FRAME),a
.skip:  pop af
        inc a
        cp ACTOR_COUNT
        jr nz,.one
        call actors_draw
        ld hl,scene_count
        dec (hl)
        jp nz,scene_cont
        xor a
        ld (scene_mode),a
        jp scene_cont

; ---------------------------------------------------------------- actors
; In: A = actor. Out: IX = its record. Trashes DE.
actor_ix:
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld ix,actors
        add ix,de
        ret

; Restore the background under actor IX if it is on screen.
actor_erase:
        ld a,(ix+A_VIS)
        or a
        ret z
        ld d,(ix+A_Y)
        ld e,(ix+A_X)
        jp restore_2x2

; Draw every visible actor, in order (later ones on top).
actors_draw:
        push ix
        ld ix,actors
        ld b,ACTOR_COUNT
.one:   push bc
        ld a,(ix+A_VIS)
        or a
        jr z,.next
        ld a,(ix+A_FRAME)
        call frame_addr
        ld d,(ix+A_Y)
        ld e,(ix+A_X)
        call draw_sprite16
.next:  ld de,ACT_SIZE
        add ix,de
        pop bc
        djnz .one
        pop ix
        ret

; In: A = AF_* frame. Out: HL = its 68 bytes. Trashes AF,DE.
frame_addr:
        cp AF_VIGNETTE
        jr nc,.vignette
        cp AF_PEOPLE
        jr nc,.people
        ld de,thanos_gfx
        jr .mul
.people:
        sub AF_PEOPLE
        ld de,people_gfx
        jr .mul
.vignette:
        sub AF_VIGNETTE
        ld de,vignette_gfx
.mul:   jp frame68
