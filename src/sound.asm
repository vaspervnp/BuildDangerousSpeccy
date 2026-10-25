; ---------------------------------------------------------------- sound
; AY-3-8912 sound effects, stepped once per game loop (sound_update). Two voices:
;   voice 0, channel A: events - traps, sign-off, Miss, exit, scenes, jingles
;   voice 1, channel B: small things - footsteps, the escalator, clock ticks, speech
; Channel C stays silent. A new effect replaces whatever its voice was playing.
;
; An effect is a list of 6-byte steps ended by a 0:
;   db frames           ; how long the step lasts (1-255)
;   dw period           ; tone period: 62500/period Hz; 0 = no tone
;   db slide            ; signed, added to the period every frame after the first
;   db noise            ; noise period 1 (hiss) - 31 (rumble); 0 = no noise
;   db volume           ; low nibble: volume 0-15; high nibble: frames per volume step down
;                       ; (0 = steady)
; On a 128K the voices go to the AY (#FFFD selects a register, #BFFD writes it), the
; periods scaled from the CPC's 1 MHz AY to the Spectrum's 1.7734 MHz. On a 48K the
; beeper plays the louder voice in the time each frame leaves free (beeper_frame, called
; instead of waiting for the interrupt): the periods give the pitch, noise is a random
; square wave, the volume only whether it sounds.

V_PTR           equ 0           ; dw next step, 0 = silent
V_FRAMES        equ 2           ; frames left in this step
V_PERIOD        equ 3           ; dw
V_SLIDE         equ 5
V_NOISE         equ 6
V_VOL           equ 7
V_RATE          equ 8
V_COUNT         equ 9
V_SIZE          equ 10

SND_MIXER_OFF   equ %00111111   ; every tone and noise off, PSG port A input

sound_init:
        ld hl,snd_voice0
        ld b,2*V_SIZE
.clear: ld (hl),0
        inc hl
        djnz .clear
        jp sound_write          ; the silent state

; Write both voices to the AY (a 128K only). Trashes AF,BC,DE,HL.
sound_write:
        ld a,(ay_present)
        or a
        ret z
        ld hl,(snd_voice0+V_PERIOD)
        call ay_period
        xor a
        ld c,l
        call psg_write
        ld a,1
        ld c,h
        call psg_write
        ld hl,(snd_voice1+V_PERIOD)
        call ay_period
        ld a,2
        ld c,l
        call psg_write
        ld a,3
        ld c,h
        call psg_write
        ld a,(snd_voice0+V_NOISE)       ; one noise generator: voice 0 has it first
        or a
        jr nz,.noise
        ld a,(snd_voice1+V_NOISE)
.noise: ld c,a                          ; x 1.75, at most 31
        srl a
        add a,c
        srl c
        srl c
        add a,c
        cp 32
        jr c,.nset
        ld a,31
.nset:  ld c,a
        ld a,6
        call psg_write
        ld e,SND_MIXER_OFF
        ld hl,snd_voice0+V_PERIOD
        ld d,%00001001                  ; channel A: tone bit 0, noise bit 3
        call .mix
        ld hl,snd_voice1+V_PERIOD
        ld d,%00010010                  ; channel B: tone bit 1, noise bit 4
        call .mix
        ld a,7
        ld c,e
        call psg_write
        ld a,(snd_voice0+V_VOL)
        ld c,a
        ld a,8
        call psg_write
        ld a,(snd_voice1+V_VOL)
        ld c,a
        ld a,9
        call psg_write
        ld a,10
        ld c,0
        jp psg_write
; In: HL = voice+V_PERIOD, D = its tone and noise bits, E = mixer. Clears the bits in use.
.mix:   ld a,(hl)
        inc hl
        or (hl)
        jr z,.notone
        ld a,d
        and %00000111
        cpl
        and e
        ld e,a
.notone:
        inc hl
        inc hl                          ; V_NOISE
        ld a,(hl)
        or a
        ret z
        ld a,d
        and %00111000
        cpl
        and e
        ld e,a
        ret

; In: HL = a CPC period (1 MHz). Out: HL = the Spectrum AY's (1.7734 MHz): x 1.766
; (1 + 1/2 + 1/4 + 1/64), at most 4095. Trashes AF,DE.
ay_period:
        ld d,h
        ld e,l
        srl d
        rr e
        push de                 ; /2
        srl d
        rr e                    ; /4
        add hl,de
        srl d
        rr e
        srl d
        rr e
        srl d
        rr e
        srl d
        rr e                    ; /64
        add hl,de
        pop de
        add hl,de
        ld a,h
        cp #10
        ret c
        ld hl,#0fff
        ret

; In: A = register, C = value. Trashes AF,BC.
psg_write:
        push de
        ld e,c
        ld bc,#fffd
        out (c),a
        ld b,#bf
        out (c),e
        pop de
        ret

; ---------------------------------------------------------------- the 48K's beeper
; Until the next interrupt, the louder of the two voices: a square wave whose half period
; is the CPC period x 28 T (its tone is 62500/period Hz), or for noise a level flipped at
; random every noise period x 56 T. A voice under BEEP_MIN is quiet. The border keeps its
; colour.
BEEP_MIN        equ 2

beeper_frame:
        ld a,(framecnt)
        ld b,a
        ld ix,snd_voice0
        ld a,(ix+V_VOL)
        cp BEEP_MIN
        jr nc,.voice
        ld ix,snd_voice1
        ld a,(ix+V_VOL)
        cp BEEP_MIN
        jr c,.quiet
.voice: ld a,(ix+V_NOISE)
        or a
        jr nz,.noise
        ld l,(ix+V_PERIOD)
        ld h,(ix+V_PERIOD+1)
        ld a,h
        or l
        jr z,.quiet
        ld d,h                  ; counter = P + P/16: its loop is 26 T
        ld e,l
        srl d
        rr e
        srl d
        rr e
        srl d
        rr e
        srl d
        rr e
        add hl,de
        ex de,hl                ; DE = counter
        ld a,(border_col)
        ld c,a
.cycle: ld a,c
        xor #10
        ld c,a
        out (#fe),a
        ld h,d
        ld l,e
.d:     dec hl
        ld a,h
        or l
        jr nz,.d
        ld a,(framecnt)
        cp b
        jr z,.cycle
        jr .off
.noise: ld e,a                  ; noise period 1-31: counter 3.5 x (loop 16 T)
        add a,a
        add a,e
        srl e
        add a,e
        ld e,a
        ld a,(border_col)
        ld c,a
        ld hl,(beep_seed)
        ld a,h
        or l
        jr nz,.nstep
        inc hl
.nstep: add hl,hl               ; LFSR: a random bit in the carry
        ld a,c
        jr nc,.n0
        xor #10
        ld c,a
        ld a,l
        xor #2d
        ld l,a
        ld a,c
.n0:    out (#fe),a
        ld d,e
.nd:    nop
        dec d
        jr nz,.nd
        ld a,(framecnt)
        cp b
        jr z,.nstep
        ld (beep_seed),hl
.off:   ld a,(border_col)
        out (#fe),a
        ret
.quiet: halt
        ld a,(framecnt)
        cp b
        jr z,.quiet
        ret

; In: HL = effect. sfx_play on voice 0, sfx_play_b on voice 1. Preserves all but AF.
sfx_play:
        push de
        ld de,snd_voice0
        jr sfx_start
sfx_play_b:
        push de
        ld de,snd_voice1
sfx_start:
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),0               ; V_FRAMES 0: the first step loads on the next update
        dec hl
        dec hl
        ex de,hl
        pop de
        ret

; Once per game loop.
sound_update:
        ld ix,snd_voice0
        call voice_tick
        ld ix,snd_voice1
        call voice_tick
        jp sound_write

; In: IX = voice. Trashes AF,DE,HL.
voice_tick:
        ld l,(ix+V_PTR)
        ld h,(ix+V_PTR+1)
        ld a,h
        or l
        jr z,.silent
        ld a,(ix+V_FRAMES)
        or a
        jr nz,.run
        ld a,(hl)               ; the next step
        or a
        jr z,.ended
        dec a
        ld (ix+V_FRAMES),a
        inc hl
        ld a,(hl)
        ld (ix+V_PERIOD),a
        inc hl
        ld a,(hl)
        ld (ix+V_PERIOD+1),a
        inc hl
        ld a,(hl)
        ld (ix+V_SLIDE),a
        inc hl
        ld a,(hl)
        ld (ix+V_NOISE),a
        inc hl
        ld a,(hl)
        and #0f
        ld (ix+V_VOL),a
        ld a,(hl)
        rrca
        rrca
        rrca
        rrca
        and #0f
        ld (ix+V_RATE),a
        ld (ix+V_COUNT),a
        inc hl
        ld (ix+V_PTR),l
        ld (ix+V_PTR+1),h
        ret
.run:   dec (ix+V_FRAMES)
        ld a,(ix+V_SLIDE)
        or a
        jr z,.decay
        ld e,a
        add a,a
        sbc a,a
        ld d,a                  ; DE = slide, sign-extended
        ld l,(ix+V_PERIOD)
        ld h,(ix+V_PERIOD+1)
        add hl,de
        ld a,h
        and #0f                 ; 12-bit period
        ld (ix+V_PERIOD+1),a
        ld (ix+V_PERIOD),l
.decay: ld a,(ix+V_RATE)
        or a
        ret z
        dec (ix+V_COUNT)
        ret nz
        ld (ix+V_COUNT),a
        ld a,(ix+V_VOL)
        or a
        ret z
        dec (ix+V_VOL)
        ret
.ended: ld (ix+V_PTR),a
        ld (ix+V_PTR+1),a
.silent:
        xor a
        ld (ix+V_VOL),a
        ld (ix+V_NOISE),a
        ld (ix+V_PERIOD),a
        ld (ix+V_PERIOD+1),a
        ret

; A syllable of speech on voice 1, its pitch picked by A (any value): a 4-frame blip,
; sagging, built in snd_babble. sfx_babble_hi is Tasha on the phone. Preserves all but AF.
sfx_babble_hi:
        push hl
        push de
        ld hl,babble_pitches_hi
        jr sfx_babble.pick
sfx_babble:
        push hl
        push de
        ld hl,babble_pitches
.pick:  and 7
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,snd_babble
        ld (hl),4               ; frames
        inc hl
        ld (hl),e               ; period
        inc hl
        ld (hl),d
        inc hl
        ld (hl),6               ; slide: the pitch sags
        inc hl
        ld (hl),0               ; no noise
        inc hl
        ld (hl),#1a             ; volume 10, down a step a frame
        inc hl
        ld (hl),0               ; end
        ld hl,snd_babble
        call sfx_play_b
        pop de
        pop hl
        ret

babble_pitches:
        dw 180, 150, 210, 165, 240, 140, 195, 225
babble_pitches_hi:
        dw 90, 75, 105, 82, 120, 70, 98, 112

; ---------------------------------------------------------------- effects
; Notes as periods: C3 477  G3 319  C4 239  E4 189  G4 159  A4 142  C5 119  E5 95
; G5 80  C6 60  E6 47  G6 40

; voice 1
sfx_step:       db 2 : dw 0 : db 0, 3, #16
                db 0
sfx_hum:        db 3 : dw 900 : db 0, 0, #06
                db 0
sfx_tick:       db 2 : dw 47 : db 0, 0, #19
                db 0
sfx_jump:       db 8 : dw 300 : db -28, 0, #1c  ; boing
                db 0
sfx_crowd:      db 12 : dw 0 : db 0, 9, #07
                db 12 : dw 0 : db 0, 8, #0a
                db 12 : dw 0 : db 0, 9, #0c
                db 70 : dw 0 : db 0, 8, #6c
                db 0

; voice 0: the inspection sheet
sfx_safe:       db 5 : dw 119 : db 0, 0, #1c
                db 5 : dw 95 : db 0, 0, #1c
                db 14 : dw 80 : db 0, 0, #2c
                db 0
sfx_miss:       db 10 : dw 600 : db 0, 0, #0e
                db 4 : dw 0 : db 0, 0, #00
                db 20 : dw 640 : db 4, 0, #2e
                db 0
sfx_already:    db 5 : dw 300 : db 0, 0, #1a
                db 0
sfx_locked:     db 4 : dw 400 : db 0, 0, #0b
                db 3 : dw 0 : db 0, 0, #00
                db 6 : dw 420 : db 0, 0, #1b
                db 0
sfx_exit:       db 4 : dw 119 : db 0, 0, #0c
                db 4 : dw 95 : db 0, 0, #0c
                db 4 : dw 80 : db 0, 0, #0c
                db 20 : dw 60 : db 0, 0, #2d
                db 0

; voice 0: traps, one per HZ_* type (trap_sfx), roughly following each vignette's beats
sfx_zap:        db 3 : dw 40 : db 0, 1, #0f     ; buzz...
                db 3 : dw 70 : db 0, 0, #0e
                db 3 : dw 40 : db 0, 1, #0f
                db 3 : dw 70 : db 0, 0, #0e
                db 3 : dw 40 : db 0, 1, #0f
                db 3 : dw 70 : db 0, 0, #0e
                db 3 : dw 40 : db 0, 1, #0f
                db 24 : dw 0 : db 0, 2, #2c     ; ...crackle
                db 0
sfx_bite:       db 3 : dw 0 : db 0, 6, #0f      ; snap
                db 5 : dw 0 : db 0, 0, #00
                db 3 : dw 0 : db 0, 6, #0f      ; snap
                db 5 : dw 0 : db 0, 0, #00
                db 3 : dw 0 : db 0, 6, #0f      ; snap
                db 6 : dw 0 : db 0, 0, #00
                db 14 : dw 45 : db 3, 0, #2e    ; yelp
                db 0
sfx_drown:      db 14 : dw 0 : db 0, 5, #2f     ; splash
                db 2 : dw 120 : db -12, 0, #0b  ; bubbles
                db 4 : dw 0 : db 0, 0, #00
                db 2 : dw 90 : db -9, 0, #0a
                db 3 : dw 0 : db 0, 0, #00
                db 2 : dw 150 : db -12, 0, #0b
                db 5 : dw 0 : db 0, 0, #00
                db 2 : dw 100 : db -10, 0, #0a
                db 3 : dw 0 : db 0, 0, #00
                db 2 : dw 130 : db -12, 0, #0a
                db 18 : dw 380 : db 8, 0, #2c   ; glug
                db 0
sfx_head:       db 2 : dw 0 : db 0, 3, #0f      ; clonk
                db 16 : dw 160 : db 14, 0, #1f  ; bonnng
                db 6 : dw 0 : db 0, 0, #00
                db 4 : dw 45 : db 0, 0, #09     ; tweet tweet
                db 4 : dw 0 : db 0, 0, #00
                db 4 : dw 40 : db 0, 0, #09
                db 4 : dw 0 : db 0, 0, #00
                db 4 : dw 45 : db 0, 0, #09
                db 4 : dw 0 : db 0, 0, #00
                db 4 : dw 40 : db 0, 0, #09
                db 0
sfx_cut:        db 10 : dw 0 : db 0, 12, #08    ; doors rush in
                db 3 : dw 0 : db 0, 1, #0f      ; slam
                db 24 : dw 70 : db 0, 0, #2d    ; clanng
                db 0
sfx_impale:     db 6 : dw 0 : db 0, 4, #0b      ; pfff
                db 4 : dw 0 : db 0, 0, #00
                db 20 : dw 300 : db -13, 0, #1f ; boinng up
                db 0
sfx_squash:     db 18 : dw 0 : db 0, 31, #0c    ; walls rumble in
                db 6 : dw 0 : db 0, 20, #0f     ; crunch
                db 10 : dw 0 : db 0, 0, #00
                db 14 : dw 260 : db -16, 0, #1d ; spring back
                db 0
sfx_fire:       db 30 : dw 0 : db 0, 28, #2f    ; whoomp
                db 2 : dw 0 : db 0, 4, #09      ; crackles
                db 4 : dw 0 : db 0, 0, #00
                db 2 : dw 0 : db 0, 6, #08
                db 3 : dw 0 : db 0, 0, #00
                db 2 : dw 0 : db 0, 4, #09
                db 5 : dw 0 : db 0, 0, #00
                db 2 : dw 0 : db 0, 5, #08
                db 0
sfx_ice:        db 3 : dw 40 : db 0, 0, #0b     ; frost shimmer
                db 3 : dw 50 : db 0, 0, #0a
                db 3 : dw 36 : db 0, 0, #0b
                db 3 : dw 45 : db 0, 0, #0a
                db 3 : dw 33 : db 0, 0, #0b
                db 14 : dw 0 : db 0, 0, #00
                db 4 : dw 0 : db 0, 2, #0f      ; crack
                db 3 : dw 0 : db 0, 0, #00
                db 10 : dw 0 : db 0, 3, #1e     ; shatter
                db 2 : dw 30 : db 0, 0, #0a     ; tinkle
                db 2 : dw 38 : db 0, 0, #09
                db 2 : dw 27 : db 0, 0, #08
                db 0
sfx_poison:     db 6 : dw 200 : db 0, 0, #0b    ; wobble
                db 6 : dw 240 : db 0, 0, #0b
                db 6 : dw 200 : db 0, 0, #0b
                db 6 : dw 240 : db 0, 0, #0b
                db 36 : dw 160 : db 6, 0, #3c   ; deflate
                db 0
sfx_suck:       db 30 : dw 400 : db -11, 6, #0c ; vacuum winds up
                db 3 : dw 0 : db 0, 1, #0f      ; thwop
                db 20 : dw 0 : db 0, 0, #00
                db 24 : dw 40 : db 3, 0, #3c    ; falling whistle
                db 6 : dw 0 : db 0, 25, #1f     ; thud
                db 0
sfx_catapult:   db 6 : dw 500 : db 0, 0, #09    ; creak
                db 8 : dw 300 : db -30, 0, #0f  ; sproing
                db 30 : dw 30 : db 2, 0, #3c    ; up... and down
                db 12 : dw 0 : db 0, 20, #1f    ; crash
                db 0
sfx_evidence:   db 4 : dw 0 : db 0, 2, #08      ; paper rustle
                db 3 : dw 0 : db 0, 0, #00
                db 4 : dw 0 : db 0, 2, #08
                db 6 : dw 0 : db 0, 0, #00
                db 6 : dw 159 : db 0, 0, #0c    ; ta-
                db 16 : dw 119 : db 0, 0, #2d   ; -daa
                db 0

trap_sfx:       ; by HZ_* type
        dw sfx_zap, sfx_bite, sfx_drown, sfx_head, sfx_cut, sfx_impale, sfx_squash
        dw sfx_fire, sfx_ice, sfx_poison, sfx_suck, sfx_catapult, sfx_evidence
trap_sfx_end:
        assert trap_sfx_end-trap_sfx == HZ_TYPE_COUNT*2, "one trap_sfx entry per HZ_* type"

; voice 0: scenes and screens
sfx_snip:       db 2 : dw 0 : db 0, 1, #0f
                db 3 : dw 0 : db 0, 0, #00
                db 2 : dw 0 : db 0, 1, #0c
                db 0
sfx_fanfare:    db 7 : dw 119 : db 0, 0, #0c
                db 7 : dw 95 : db 0, 0, #0c
                db 7 : dw 80 : db 0, 0, #0c
                db 14 : dw 60 : db 0, 0, #1d
                db 6 : dw 80 : db 0, 0, #0c
                db 30 : dw 60 : db 0, 0, #3d
                db 0
sfx_trombone:   db 14 : dw 319 : db 1, 0, #0c   ; wah
                db 3 : dw 0 : db 0, 0, #00
                db 14 : dw 338 : db 1, 0, #0c   ; wah
                db 3 : dw 0 : db 0, 0, #00
                db 14 : dw 358 : db 1, 0, #0c   ; wah
                db 3 : dw 0 : db 0, 0, #00
                db 5 : dw 379 : db 2, 0, #0c    ; waaa-a-a-ah
                db 5 : dw 389 : db -2, 0, #0c
                db 5 : dw 379 : db 2, 0, #0b
                db 5 : dw 389 : db -2, 0, #0b
                db 5 : dw 379 : db 2, 0, #0a
                db 20 : dw 389 : db 1, 0, #2a
                db 0
sfx_thud:       db 8 : dw 0 : db 0, 26, #1f
                db 0
sfx_ring:       db 2 : dw 45 : db 0, 0, #0c     ; brrring...
                db 2 : dw 38 : db 0, 0, #0c
                db 2 : dw 45 : db 0, 0, #0c
                db 2 : dw 38 : db 0, 0, #0c
                db 2 : dw 45 : db 0, 0, #0c
                db 2 : dw 38 : db 0, 0, #0c
                db 2 : dw 45 : db 0, 0, #0c
                db 2 : dw 38 : db 0, 0, #0c
                db 10 : dw 0 : db 0, 0, #00
                db 2 : dw 45 : db 0, 0, #0c     ; ...brrring
                db 2 : dw 38 : db 0, 0, #0c
                db 2 : dw 45 : db 0, 0, #0c
                db 2 : dw 38 : db 0, 0, #0c
                db 2 : dw 45 : db 0, 0, #0c
                db 2 : dw 38 : db 0, 0, #0c
                db 2 : dw 45 : db 0, 0, #0c
                db 2 : dw 38 : db 0, 0, #0c
                db 0
sfx_throw:      db 2 : dw 0 : db 0, 2, #0c      ; grunt...
                db 8 : dw 0 : db 0, 6, #18      ; ...whoosh
                db 0
sfx_bonk:       db 2 : dw 0 : db 0, 2, #0f      ; bonk
                db 10 : dw 200 : db 16, 0, #1e
                db 0
sfx_powerdown:  db 30 : dw 120 : db 12, 0, #2d     ; the hum of everything, dying
                db 0
sfx_click:      db 1 : dw 0 : db 0, 1, #0f      ; camera shutter
                db 2 : dw 0 : db 0, 0, #00
                db 2 : dw 0 : db 0, 3, #0c
                db 0
sfx_hangup:     db 2 : dw 0 : db 0, 1, #0c      ; click
                db 4 : dw 0 : db 0, 0, #00
                db 2 : dw 0 : db 0, 1, #0a
                db 0
sfx_jingle:     db 6 : dw 159 : db 0, 0, #0c    ; G4
                db 6 : dw 119 : db 0, 0, #0c    ; C5
                db 6 : dw 95 : db 0, 0, #0c     ; E5
                db 12 : dw 80 : db 0, 0, #1c    ; G5
                db 6 : dw 95 : db 0, 0, #0b     ; E5
                db 24 : dw 80 : db 0, 0, #2c    ; G5
                db 6 : dw 0 : db 0, 0, #00
                db 4 : dw 142 : db 0, 0, #0a    ; A4 - oops
                db 4 : dw 150 : db 0, 0, #09
                db 16 : dw 159 : db 1, 0, #29   ; G4 sagging
                db 0
