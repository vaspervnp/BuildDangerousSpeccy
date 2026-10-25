; Build Dangerous - ZX Spectrum 48K / 128K
; The Amstrad CPC game (../BuildDangerousCPC): its rules, buildings, texts and sounds; the
; picture, the keys, the sound chip and the tape are the Spectrum's.
;
; Memory:
;   #4000-#5AFF  the screen
;   #5B00-#5DFF  the attributes as drawn (video.asm: the screen's go through a table)
;   #5E00-#5EFF  that table: drawn attribute -> shown (blackouts, flashes, a blank screen)
;   #6000-       the code and its data, from the tape (src/loader.bas: CLEAR, LOAD ""CODE,
;                RANDOMIZE USR start); the variables above it, zeroed at start
;   #FCFC        JP int_handler; #FD00 the IM 2 table; the stack below #FCFC
; A 128K is told apart by its AY (sound.asm): the same game, with the sound on the AY
; instead of the beeper.

LOAD_ADDR       equ #6000
LOAD_CLEAR      equ LOAD_ADDR-1     ; the loader's CLEAR
SHADOW          equ #5b00
XLAT            equ #5e00
ATTRS           equ #5800
IM2_TABLE       equ #fd00
IM2_FILL        equ #fc
IM2_JUMP        equ #fcfc
STACK_TOP       equ IM2_JUMP

        org LOAD_ADDR
bin_start:

start:
        di
        ld sp,STACK_TOP
        ld hl,vars_start        ; variables start zeroed
        ld de,vars_start+1
        ld bc,vars_end-vars_start-1
        ld (hl),0
        ldir
        ld hl,#ace1             ; xorshift needs a non-zero seed
        ld (rnd_seed),hl
        call video_init
        call hw_init            ; the interrupt, the AY, the Kempston
        call sound_init
        xor a
        ld (lang),a             ; English until L is pressed in the menu
        ld (keys),a
        call title_show
        ei

main_loop:
        call wait_vbl
        call input_read
        call sound_update
        call rand               ; keep the generator moving: player timing seeds it
        ld a,(game_state)
        cp GS_PLAY
        jr z,.play
        cp GS_RESULTS
        jr z,.results
        cp GS_TITLE
        jr z,.title
        cp GS_END
        jr z,.end
        call hud_update         ; an outdoor scene: Fire skips it
        ld a,(keys_new)
        and KEY_FIRE
        jr nz,.scene_end
        call scene_update
        jr nc,main_loop
.scene_end:
        call scene_finish
        jr main_loop
.play:  ld a,(keys_new)
        and KEY_PAUSE
        call nz,pause_toggle
        ld a,(paused)
        or a
        jr nz,main_loop         ; paused: everything waits, the clock too
        call blackout_update
        call player_update
        call nephew_update
        call worker_update
        call hint_update
        call sense_update
        call hud_update
        call play_update
        jr main_loop
.results:
        call outcome_update
        jr main_loop
.title: call title_update
        jr main_loop
.end:   call end_update
        jr main_loop

boot_campaign:  dw campaign_main   ; the test harness pokes this to play other campaigns

        include "hw.asm"
        include "video.asm"
        include "input.asm"
        include "tiles.asm"
        include "room.asm"
        include "building.asm"
        include "hazards.asm"
        include "vignette.asm"
        include "player.asm"
        include "text.asm"
        include "hud.asm"
        include "outcome.asm"
        include "scene.asm"
        include "campaign.asm"
        include "sound.asm"
        include "phone.asm"
        include "nephew.asm"
        include "workers.asm"
        include "hints.asm"
        include "sense.asm"
        include "blackout.asm"
        include "../build/strings.asm"
        include "../build/tile_attr.asm"

; ---------------------------------------------------------------- buildings
; Generated from assets/buildings/*.txt. Room data stays in RAM: hazard states are
; written into it.
        include "../build/bld_sunnyvale.asm"
        include "../build/bld_test.asm"
        include "../build/bld_gallery.asm"
        include "../build/bld_mall.asm"
        include "../build/bld_hotel.asm"
        include "../build/bld_hospital.asm"
        include "../build/bld_hardknock.asm"
        include "../build/bld_skyscraper.asm"
        include "../build/room_outdoor.asm"
        include "../build/title.asm"

; ---------------------------------------------------------------- assets
tiles_gfx:      incbin "../build/tiles.bin"
font_gfx:       incbin "../build/font.bin"
thanos_gfx:     incbin "../build/thanos.bin"
vignette_gfx:   incbin "../build/vignettes.bin"
hazard_gfx:     incbin "../build/hazards.bin"
people_gfx:     incbin "../build/people.bin"
tasha_gfx:      incbin "../build/tasha.bin"

code_end:
        save "build/bd.bin",bin_start,code_end-bin_start

; ---------------------------------------------------------------- variables
; Above the loaded code; not on the tape. Start zeroes them.
        nocode
vars_start:
        include "vars.asm"
vars_end:
        code
        assert vars_end < STACK_TOP-256, "variables run into the stack"
