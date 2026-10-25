; ---------------------------------------------------------------- trap vignettes
; A vignette is a short script of full 16x16 Thanos frames, a few seconds long. It starts
; with a db P_* (the particle sprite this trap throws about: sparks, bubbles...), then
; 4-byte steps:
;   db frame + pattern   frame VF_* (or VF_NONE), plus P1/P2/P3: two particles around him
;   db frames to hold
;   db fx + extras        FX_* (pen 0 recoloured: the room floods, fills with gas...), plus
;                         SHAKE (the border flashes for the step), SND (the trap's sound again),
;                         and L1..L4 / R1..R3 (he is shoved that many cells sideways)
;   db dy                 signed rows from where he stands
; terminated by VIG_END. Input is locked while it plays; when it ends the hazard is disarmed.

VIG_END         equ #ff
VF_NONE         equ #3e             ; draw nothing: he is off screen / inside the vent

P1              equ #40             ; particles beside him, left high and right low
P2              equ #80             ; ... right high and left low
P3              equ #c0             ; ... over his head

FX_NONE         equ 0
FX_FLASH        equ 1
FX_FIRE         equ 2
FX_WATER        equ 3
FX_GAS          equ 4
FX_ICE          equ 5
FX_DUST         equ 6
SHAKE           equ 8
SND             equ 16
R1              equ #20             ; dx, signed, in bits 5-7
R2              equ #40
R3              equ #60
L4              equ #80
L3              equ #a0
L2              equ #c0
L1              equ #e0


; Particle sprites, in the hazard sheet after the thrown tools
P_SPARK         equ 32
P_BUBBLE        equ 33
P_FLAME         equ 34
P_SMOKE         equ 35
P_STAR          equ 36
P_SHARD         equ 37
P_SKULL         equ 38
P_FEATHER       equ 39

; Where the two particles of each pattern go: dx, dy, dx, dy from his top-left cell
particle_spots:
        db -1, 0, 2, 1
        db 2, 0, -1, 1
        db 0, -1, 1, -1

; Frames in build/vignettes.bin
VF_ZAP_A        equ 0               ; lit up, hat blown off his head
VF_ZAP_B        equ 1               ; x-ray
VF_ZAP_C        equ 2               ; singed and smoking
VF_BITE_A       equ 3
VF_BITE_B       equ 4
VF_BITE_C       equ 5               ; bandaged ankle
VF_DROWN_A      equ 6               ; bubbles
VF_DROWN_B      equ 7               ; bobbing, rubber duck on the hat
VF_DROWN_C      equ 8               ; dripping
VF_HEAD_A       equ 9               ; lamp on the hat
VF_HEAD_B       equ 10              ; accordion
VF_HEAD_C       equ 11              ; stars
VF_CUT_A        equ 12              ; doors slam
VF_CUT_B        equ 13              ; two halves
VF_CUT_C        equ 14              ; taped together
VF_IMP_A        equ 15              ; sits down
VF_IMP_B        equ 16              ; leaps
VF_IMP_C        equ 17              ; plaster
VF_SQ_A         equ 18              ; walls close in
VF_SQ_B         equ 19              ; pancake
VF_SQ_C         equ 20              ; springs back
VF_FIRE_A       equ 21              ; fireball
VF_FIRE_B       equ 22              ; briquette
VF_FIRE_C       equ 23              ; smoking briquette
VF_ICE_A        equ 24              ; ice block
VF_ICE_B        equ 25              ; cracking
VF_ICE_C        equ 26              ; shards
VF_POI_A        equ 27              ; wobble left
VF_POI_B        equ 28              ; wobble right
VF_POI_C        equ 29              ; deflated
VF_SUCK_A       equ 30              ; lifted
VF_SUCK_B       equ 31              ; legs only
VF_UPSIDE_DOWN  equ 32              ; spat out / falling back down
VF_CAT_A        equ 33              ; crouch
VF_CAT_B        equ 34              ; launched
VF_CAT_D        equ 35              ; landed, plaster and feathers
VF_READ         equ 36              ; reading the owner's papers
VF_PHONE        equ 37              ; on the phone (not a trap: phone.asm)

vig_electric:
        db P_SPARK
        db VF_ZAP_A+P1, 3, FX_FLASH+SHAKE, 0
        db VF_ZAP_B+P2, 3, FX_NONE, 0
        db VF_ZAP_A+P3, 3, FX_FLASH, 0
        db VF_ZAP_B+P1, 3, FX_NONE+SHAKE, 0
        db VF_ZAP_A+P2, 3, FX_FLASH, 0
        db VF_ZAP_B+P3, 3, FX_NONE, 0
        db VF_ZAP_A+P1, 3, FX_FLASH+SND+SHAKE, 0     ; and again
        db VF_ZAP_B+P2, 3, FX_NONE, 0
        db VF_ZAP_A+P3, 3, FX_FLASH, 0
        db VF_ZAP_B+P1, 3, FX_NONE+SHAKE, 0
        db VF_ZAP_A+P2, 3, FX_FLASH, 0
        db VF_ZAP_B, 8, FX_NONE, 0
        db VF_ZAP_C+P3, 12, FX_NONE, 0               ; sparks still coming off the hat
        db VF_ZAP_C, 12, FX_NONE, 0
        db VF_ZAP_C+P3, 12, FX_NONE, 0
        db VF_ZAP_C, 40, FX_NONE, 0
        db VIG_END

vig_bite:
        db P_STAR
        db VF_BITE_A+P1, 3, FX_NONE, 0
        db VF_BITE_B+P2, 3, FX_NONE+SHAKE, 0
        db VF_BITE_A+P3, 3, FX_NONE, -1
        db VF_BITE_B+P1, 3, FX_NONE+L1, 0
        db VF_BITE_A+P2, 3, FX_NONE+SND, -1
        db VF_BITE_B+P3, 3, FX_NONE+R1, 0
        db VF_BITE_A+P1, 3, FX_NONE+SHAKE, 0
        db VF_BITE_B+P2, 3, FX_NONE, -1
        db VF_BITE_A+P3, 3, FX_NONE+L1, 0
        db VF_BITE_B+P1, 3, FX_NONE, 0
        db VF_BITE_A+P2, 3, FX_NONE+R1, -1
        db VF_BITE_B, 6, FX_NONE, 0
        db VF_BITE_C, 14, FX_NONE, 0                 ; hopping on the good foot
        db VF_BITE_C, 4, FX_NONE, -1
        db VF_BITE_C, 14, FX_NONE, 0
        db VF_BITE_C, 4, FX_NONE, -1
        db VF_BITE_C, 40, FX_NONE, 0
        db VIG_END

vig_drown:
        db P_BUBBLE
        db VF_DROWN_A+P1, 6, FX_WATER, 0
        db VF_DROWN_A+P2, 6, FX_WATER, 0
        db VF_DROWN_B+P3, 6, FX_WATER, -1
        db VF_DROWN_B+P1, 6, FX_WATER, 0
        db VF_DROWN_A+P2, 6, FX_WATER+SND, 0
        db VF_DROWN_A+P3, 6, FX_WATER, 0
        db VF_DROWN_B+P1, 6, FX_WATER, -1
        db VF_DROWN_B+P2, 6, FX_WATER, 0
        db VF_DROWN_A+P3, 6, FX_WATER, 0
        db VF_DROWN_B+P3, 10, FX_WATER, -1
        db VF_DROWN_C, 10, FX_NONE, 0
        db VF_DROWN_C+P1, 8, FX_NONE, 0              ; the last of the bubbles
        db VF_DROWN_C, 40, FX_NONE, 0
        db VIG_END

vig_head:
        db P_STAR
        db VF_HEAD_A, 6, FX_NONE, 0
        db VF_HEAD_B, 2, FX_DUST+SHAKE, 0
        db VF_HEAD_B, 3, FX_NONE+SHAKE, 0
        db VF_HEAD_B, 12, FX_NONE, 0
        db VF_HEAD_C+P1, 6, FX_NONE, 0               ; stars going round
        db VF_HEAD_C+P3, 6, FX_NONE+R1, 0
        db VF_HEAD_C+P2, 6, FX_NONE, 0
        db VF_HEAD_C+P3, 6, FX_NONE+L1, 0
        db VF_HEAD_C+P1, 6, FX_NONE, 0
        db VF_HEAD_C+P3, 6, FX_NONE+R1, 0
        db VF_HEAD_C+P2, 6, FX_NONE, 0
        db VF_HEAD_C+P3, 6, FX_NONE, 0
        db VF_HEAD_C, 40, FX_NONE, 0
        db VIG_END

vig_cut:
        db P_SMOKE
        db VF_CUT_A, 3, FX_DUST+SHAKE, 0
        db VF_CUT_A+P1, 3, FX_NONE+SHAKE, 0
        db VF_CUT_B+P2, 6, FX_NONE, 0
        db VF_CUT_B, 20, FX_NONE, 0
        db VF_CUT_B, 6, FX_NONE+R1, 0                ; the halves wobble
        db VF_CUT_B, 6, FX_NONE, 0
        db VF_CUT_B, 6, FX_NONE+L1, 0
        db VF_CUT_B, 10, FX_NONE, 0
        db VF_CUT_C+P3, 8, FX_NONE+SND, 0            ; taped back together
        db VF_CUT_C, 12, FX_NONE, 0
        db VF_CUT_C+P3, 8, FX_NONE, 0
        db VF_CUT_C, 40, FX_NONE, 0
        db VIG_END

vig_impale:
        db P_FEATHER
        db VF_IMP_A, 10, FX_NONE, 0
        db VF_IMP_A+P1, 3, FX_NONE+SHAKE, 0
        db VF_IMP_B+P2, 3, FX_NONE, -1
        db VF_IMP_B+P3, 3, FX_NONE, -2
        db VF_IMP_B+P1, 3, FX_NONE, -3
        db VF_IMP_B+P2, 5, FX_NONE, -3
        db VF_IMP_B+P3, 3, FX_NONE, -2
        db VF_IMP_B+P1, 3, FX_NONE, -1
        db VF_IMP_A+P2, 3, FX_NONE+SHAKE, 0
        db VF_IMP_C+P3, 12, FX_NONE, 0               ; feathers settling
        db VF_IMP_C+P1, 10, FX_NONE, 0
        db VF_IMP_C+P2, 10, FX_NONE, 0
        db VF_IMP_C, 40, FX_NONE, 0
        db VIG_END

vig_squash:
        db P_SMOKE
        db VF_SQ_A, 8, FX_NONE, 0
        db VF_SQ_A, 4, FX_NONE+SHAKE, 0
        db VF_SQ_B+P1, 2, FX_DUST+SHAKE, 0
        db VF_SQ_B+P2, 3, FX_NONE+SHAKE, 0
        db VF_SQ_B, 18, FX_NONE, 0
        db VF_SQ_C, 4, FX_NONE+SND, -1               ; boing...
        db VF_SQ_B, 3, FX_NONE, 0
        db VF_SQ_C, 4, FX_NONE, -1
        db VF_SQ_B, 3, FX_NONE, 0
        db VF_SQ_C, 6, FX_NONE, -2
        db VF_SQ_C+P3, 10, FX_NONE, 0
        db VF_SQ_C, 40, FX_NONE, 0
        db VIG_END

vig_fire:
        db P_FLAME
        db VF_FIRE_A+P1, 3, FX_FIRE+SHAKE, 0
        db VF_FIRE_A+P2, 3, FX_FLASH, 0
        db VF_FIRE_A+P3, 3, FX_FIRE+SHAKE, 0
        db VF_FIRE_A+P1, 3, FX_FLASH, 0
        db VF_FIRE_A+P2, 3, FX_FIRE, 0
        db VF_FIRE_A+P3, 3, FX_FLASH+SND, 0
        db VF_FIRE_A+P1, 3, FX_FIRE, 0
        db VF_FIRE_A+P2, 3, FX_FLASH, 0
        db VF_FIRE_B+P3, 8, FX_FIRE, 0
        db VF_FIRE_B+P1, 8, FX_NONE, 0
        db VF_FIRE_B+P3, 8, FX_NONE, 0
        db VF_FIRE_C+P3, 10, FX_NONE, 0              ; still smouldering
        db VF_FIRE_C, 10, FX_NONE, 0
        db VF_FIRE_C+P3, 10, FX_NONE, 0
        db VF_FIRE_C, 40, FX_NONE, 0
        db VIG_END

vig_ice:
        db P_SHARD
        db VF_ICE_A+P1, 6, FX_ICE, 0
        db VF_ICE_A+P2, 6, FX_ICE, 0
        db VF_ICE_A, 20, FX_ICE, 0
        db VF_ICE_B, 6, FX_ICE+SHAKE, 0
        db VF_ICE_B, 10, FX_ICE, 0
        db VF_ICE_B, 4, FX_ICE+SHAKE+SND, 0
        db VF_ICE_C+P1, 4, FX_FLASH, 0               ; shards everywhere
        db VF_ICE_C+P2, 4, FX_NONE, 0
        db VF_ICE_C+P3, 4, FX_NONE, 0
        db VF_ICE_C+P1, 4, FX_NONE, 0
        db VF_ICE_C, 8, FX_NONE, 0
        db VF_ICE_C, 3, FX_NONE+R1, 0                ; shivering
        db VF_ICE_C, 3, FX_NONE, 0
        db VF_ICE_C, 3, FX_NONE+L1, 0
        db VF_ICE_C, 3, FX_NONE, 0
        db VF_ICE_C, 3, FX_NONE+R1, 0
        db VF_ICE_C, 40, FX_NONE, 0
        db VIG_END

vig_poison:
        db P_SKULL
        db VF_POI_A+P3, 5, FX_GAS, 0
        db VF_POI_B+P1, 5, FX_GAS, 0
        db VF_POI_A, 5, FX_GAS+L1, 0
        db VF_POI_B+P3, 5, FX_GAS+R1, 0
        db VF_POI_A+P2, 5, FX_GAS, 0
        db VF_POI_B, 5, FX_GAS+R1, 0
        db VF_POI_A+P3, 5, FX_GAS+SND, 0
        db VF_POI_B+P1, 5, FX_GAS+L1, 0
        db VF_POI_A, 5, FX_GAS, 0
        db VF_POI_C+P3, 10, FX_GAS, 0
        db VF_POI_C, 10, FX_NONE, 0
        db VF_POI_C+P3, 10, FX_NONE, 0
        db VF_POI_C, 40, FX_NONE, 0
        db VIG_END

vig_suck:
        db P_SMOKE
        db VF_SUCK_A+P1, 4, FX_NONE, 0
        db VF_SUCK_A+P2, 4, FX_NONE+SHAKE, -1
        db VF_SUCK_B+P3, 4, FX_NONE, -2
        db VF_NONE, 30, FX_NONE, 0                   ; somewhere in the ducts
        db VF_NONE, 4, FX_NONE+SHAKE, 0
        db VF_NONE, 8, FX_NONE, 0
        db VF_NONE, 4, FX_NONE+SHAKE+SND, 0
        db VF_UPSIDE_DOWN+P3, 3, FX_DUST, -3         ; spat out
        db VF_UPSIDE_DOWN, 3, FX_NONE, -2
        db VF_UPSIDE_DOWN, 3, FX_NONE, -1
        db VF_UPSIDE_DOWN+P1, 3, FX_DUST+SHAKE, 0
        db VF_UPSIDE_DOWN+P2, 20, FX_NONE, 0
        db VF_UPSIDE_DOWN, 30, FX_NONE, 0
        db VIG_END

vig_catapult:                       ; up through every floor above, then back down
        db P_STAR
        db VF_CAT_A, 8, FX_NONE, 0
        db VF_CAT_A, 4, FX_NONE+SHAKE, 0
        db VF_CAT_B, 2, FX_NONE, -3
        db VF_CAT_B, 2, FX_NONE, -6
        db VF_CAT_B, 2, FX_NONE, -9
        db VF_CAT_B, 2, FX_NONE, -12
        db VF_CAT_B, 2, FX_NONE, -15
        db VF_CAT_B, 2, FX_NONE, -19
        db VF_NONE, 25, FX_NONE, 0
        db VF_UPSIDE_DOWN, 2, FX_NONE, -19
        db VF_UPSIDE_DOWN, 2, FX_NONE, -15
        db VF_UPSIDE_DOWN, 2, FX_NONE, -11
        db VF_UPSIDE_DOWN, 2, FX_NONE, -7
        db VF_UPSIDE_DOWN, 2, FX_NONE, -3
        db VF_CAT_D+P1, 3, FX_DUST+SHAKE+SND, 0
        db VF_CAT_D+P2, 4, FX_NONE+SHAKE, 0
        db VF_CAT_D+P3, 8, FX_NONE, 0                ; seeing stars
        db VF_CAT_D+P1, 8, FX_NONE, 0
        db VF_CAT_D+P3, 8, FX_NONE, 0
        db VF_CAT_D+P2, 8, FX_NONE, 0
        db VF_CAT_D, 40, FX_NONE, 0
        db VIG_END

vig_evidence:
        db 0
        db VF_READ, 50, FX_NONE, 0
        db VIG_END

; In: IX = hazard entry. Charges the energy, shows the caption, starts the script.
vig_start:
        call sense_hide         ; the "?" first: the vignette draws over his head
        ld (vig_hazard),ix
        call vig_sound
        ld a,(ix+HZ_TYPE)
        call hz_type_entry
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,(de)               ; the script's particle sprite
        ld (vig_particle),a
        inc de
        ld (vig_ptr),de
        inc hl
        inc hl
        inc hl
        ld b,(hl)               ; cost
        dec hl
        ld a,(hl)               ; caption
        push af
        call energy_lose
        pop af
        call caption_show
        ld de,(pl_x)
        ld (vig_col),de         ; vig_col, vig_row
        ld a,#ff
        ld (vig_spots+1),a      ; no particles yet
        ld (vig_spots+3),a
        xor a
        ld (vig_timer),a
        ld a,PS_VIGNETTE
        ld (pl_state),a
        ret

; The hazard's own sound (vig_hazard's type).
vig_sound:
        ld ix,(vig_hazard)
        ld a,(ix+HZ_TYPE)
        add a,a
        ld l,a
        ld h,0
        ld de,trap_sfx
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        jp sfx_play

vig_update:
        ld a,(vig_timer)
        or a
        jr z,.step
        dec a
        ld (vig_timer),a
        ret
.step:  ld hl,(vig_ptr)
        ld a,(hl)
        cp VIG_END
        jp z,.done
        ld c,a                  ; frame + pattern
        inc hl
        ld a,(hl)
        ld (vig_timer),a
        inc hl
        ld a,(hl)               ; fx + extras
        inc hl
        ld b,(hl)               ; dy
        inc hl
        ld (vig_ptr),hl
        push bc
        push af
        and 7
        call set_fx
        call vig_erase
        pop af
        push af
        and SHAKE
        call vig_shake
        pop af
        push af
        and SND
        call nz,vig_sound
        pop af
        sra a                   ; dx: bits 5-7, signed
        sra a
        sra a
        sra a
        sra a
        ld hl,pl_x
        add a,(hl)
        cp MAP_W-1              ; kept on screen
        jr c,.col
        ld a,(hl)
.col:   ld (vig_col),a
        pop bc
        ld a,(pl_y)             ; row = pl_y + dy, kept below the HUD
        add a,b
        cp HUD_ROWS
        jr c,.clamp
        cp #80
        jr c,.row
.clamp: ld a,HUD_ROWS
.row:   ld (vig_row),a
        ld a,c
        and #3f
        cp VF_NONE
        jr z,.particles
        ld de,vignette_gfx
        call frame68
        ld de,(vig_col)
        push bc
        call draw_sprite16
        pop bc
.particles:                     ; two particles where the pattern puts them
        ld a,c
        rlca
        rlca
        and 3
        ret z
        dec a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,particle_spots
        add hl,de
        ld de,vig_spots
        ld b,2
.spot:  push bc
        ld a,(vig_col)
        add a,(hl)
        inc hl
        cp MAP_W
        jr nc,.skip
        ld c,a
        ld a,(vig_row)
        add a,(hl)
        cp HUD_ROWS
        jr c,.skip
        cp MAP_H
        jr nc,.skip
        ld b,a                  ; B = row, C = col
        ld a,c
        ld (de),a
        inc de
        ld a,b
        ld (de),a
        dec de
        push de
        push hl
        ld a,(vig_particle)
        call sprite17
        ld d,b
        ld e,c
        call draw_sprite8
        pop hl
        pop de
.skip:  inc hl
        inc de
        inc de
        pop bc
        djnz .spot
        ret

.done:  xor a
        call set_fx
        xor a
        call vig_shake
        call vig_erase
        ld ix,(vig_hazard)
        ld (ix+HZ_STATE),HZ_DISARMED
        ld e,(ix+HZ_X)
        ld d,(ix+HZ_ROW)
        call draw_cell
        ld de,SCORE_DISARM
        ld a,(ix+HZ_TYPE)
        cp HZ_EVIDENCE
        jr nz,.score
        ld (evidence),a         ; non-zero: found
        ld de,SCORE_EVIDENCE
.score: call score_add
        ld a,PS_WALK
        ld (pl_state),a
        jp player_draw

; Restore the background where the last vignette frame and its particles were drawn.
vig_erase:
        ld de,(vig_col)
        call restore_2x2
        ld hl,vig_spots
        ld b,2
.spot:  ld e,(hl)
        inc hl
        ld d,(hl)
        ld (hl),#ff             ; done with it
        inc hl
        ld a,d
        inc a
        jr z,.next
        push bc
        push hl
        call draw_cell
        pop hl
        pop bc
.next:  djnz .spot
        ret

; In: A = 0: the border black again, else white for the step (the CPC jolted the picture
; up a row; the Spectrum has no way to). Trashes AF.
vig_shake:
        or a
        jr z,.set
        ld a,BORDER_SHAKE
.set:   jp set_border
