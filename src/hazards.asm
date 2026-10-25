; ---------------------------------------------------------------- hazards
; Room hazard list: count, then per hazard 4 bytes: x, row, type, state.
; Triggering an armed hazard is the only way to disarm it: it always plays the type's
; vignette. It costs time (the clock runs on while he is being wrecked), not energy:
; energy is for Misses. TRAP_COST is per-type data if that ever needs tuning.

TRAP_COST       equ 0

; Type ids follow HAZARD_TYPES in tools/zxgfx.py.
HZ_ELECTRIC     equ 0
HZ_BITE         equ 1
HZ_DROWN        equ 2
HZ_HEAD         equ 3
HZ_CUT          equ 4
HZ_IMPALE       equ 5
HZ_SQUASH       equ 6
HZ_FIRE         equ 7
HZ_ICE          equ 8
HZ_POISON       equ 9
HZ_SUCK         equ 10
HZ_CATAPULT     equ 11
HZ_EVIDENCE     equ 12          ; not a trap: the owner's papers. Never counts as live.
HZ_TYPE_COUNT   equ 13

HZ_ARMED        equ 0
HZ_DISARMED     equ 1

HZ_X            equ 0
HZ_ROW          equ 1
HZ_TYPE         equ 2
HZ_STATE        equ 3
HZ_SIZE         equ 4

; Sprites in build/hazards.bin: per type its armed tell (type*2), then its disarmed look.

; Reach: Thanos can set off a hazard within one column of his body and anywhere
; from 4 rows above his head down to his feet, i.e. the whole storey he is on.
REACH_LEFT      equ 1
REACH_W         equ 4
REACH_UP        equ 4
REACH_H         equ 6

HZT_VIGNETTE    equ 0           ; dw script
HZT_SPRITE      equ 2           ; db armed tell sprite (disarmed = +1)
HZT_CAPTION     equ 3           ; db STR_* id
HZT_COST        equ 4           ; db energy lost
HZT_SIZE        equ 5

hz_types:
        dw vig_electric
        db HZ_ELECTRIC*2, STR_CAP_ZAP, TRAP_COST
        dw vig_bite
        db HZ_BITE*2, STR_CAP_BITE, TRAP_COST
        dw vig_drown
        db HZ_DROWN*2, STR_CAP_DROWN, TRAP_COST
        dw vig_head
        db HZ_HEAD*2, STR_CAP_HEAD, TRAP_COST
        dw vig_cut
        db HZ_CUT*2, STR_CAP_CUT, TRAP_COST
        dw vig_impale
        db HZ_IMPALE*2, STR_CAP_IMPALE, TRAP_COST
        dw vig_squash
        db HZ_SQUASH*2, STR_CAP_SQUASH, TRAP_COST
        dw vig_fire
        db HZ_FIRE*2, STR_CAP_FIRE, TRAP_COST
        dw vig_ice
        db HZ_ICE*2, STR_CAP_ICE, TRAP_COST
        dw vig_poison
        db HZ_POISON*2, STR_CAP_POISON, TRAP_COST
        dw vig_suck
        db HZ_SUCK*2, STR_CAP_SUCK, TRAP_COST
        dw vig_catapult
        db HZ_CATAPULT*2, STR_CAP_CATAPULT, TRAP_COST
        dw vig_evidence
        db HZ_EVIDENCE*2, STR_CAP_EVIDENCE, 0
hz_types_end:
        assert hz_types_end-hz_types == HZ_TYPE_COUNT*HZT_SIZE, "hz_types must have one entry per HZ_* type"

; In: A = hazard type. Out: HL = its hz_types entry. Trashes AF.
hz_type_entry:
        push de
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,de               ; *5
        ld de,hz_types
        add hl,de
        pop de
        ret

; Find the hazard at D=row, E=col. Out: carry set and HL = entry if found.
; Preserves DE; trashes AF,B.
hazard_find:
        ld hl,(room_hazards)
        ld b,(hl)
        inc hl
        ld a,b
        or a
        ret z
.loop:  ld a,(hl)
        cp e
        jr nz,.next
        inc hl
        ld a,(hl)
        dec hl
        cp d
        jr nz,.next
        scf
        ret
.next:  inc hl
        inc hl
        inc hl
        inc hl
        djnz .loop
        or a
        ret

; Overlay hazard HL's sprite on cell D=row, E=col. Preserves DE; trashes AF,BC,HL.
draw_hazard:
        inc hl
        inc hl
        ld a,(hl)               ; type
        inc hl
        ld c,(hl)               ; state: armed tell or disarmed look
        call hz_type_entry
        inc hl
        inc hl
        ld a,(hl)
        add a,c
        push de
        call sprite17
        pop de
        jp draw_sprite8

; Fire pressed: set off the first armed hazard within reach.
; Out: carry set if a vignette started.
try_trigger:
        call hazard_in_reach
        ret nc
        call vig_start
        scf
        ret

; Out: carry set and IX = the first armed hazard within Thanos's reach (hints.asm too).
hazard_in_reach:
        ld ix,(room_hazards)
        ld b,(ix+0)
        inc ix
        ld a,b
        or a
        ret z
.loop:  ld a,(ix+HZ_STATE)
        cp HZ_ARMED
        jr nz,.next
        ld a,(pl_x)
        sub REACH_LEFT
        ld c,a
        ld a,(ix+HZ_X)
        sub c
        cp REACH_W
        jr nc,.next
        ld a,(pl_y)
        sub REACH_UP
        ld c,a
        ld a,(ix+HZ_ROW)
        sub c
        cp REACH_H
        ret c                   ; (carry: found)
.next:  ld de,HZ_SIZE
        add ix,de
        djnz .loop
        or a
        ret
