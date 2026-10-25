; ---------------------------------------------------------------- tile set
; Ids follow the order of assets/gfx/tiles.png and ROOM_LEGEND in tools/zxgfx.py; their colours
; are tile_attr (build/tile_attr.asm, from the same PNG).

TILE_BLACK      equ 0
TILE_WALLPAPER  equ 1
TILE_FLOOR      equ 2
TILE_BRICK      equ 3
TILE_LADDER_L   equ 4
TILE_LADDER_R   equ 5
TILE_WINDOW     equ 6
TILE_DOOR_T     equ 7
TILE_DOOR_B     equ 8
TILE_LAMP       equ 9
TILE_SOCKET     equ 10          ; a safe one: the live ones are hazard overlays
TILE_HAT_FULL   equ 11          ; HUD energy icons
TILE_HAT_EMPTY  equ 12
TILE_CHECK_EMPTY equ 13         ; HUD: current room not signed off yet
TILE_CHECK_DONE equ 14
TILE_EXIT_T     equ 15          ; building exit door
TILE_EXIT_B     equ 16
TILE_HAT_HALF   equ 17          ; HUD: half a hat of energy left
TILE_MISS       equ 18          ; HUD: Miss tally icon
TILE_DIAL_0     equ 19          ; HUD: clock dial, full ... TILE_DIAL_0+8 empty
TILE_STAR       equ 28          ; outdoor scene
TILE_MOON       equ 29
TILE_RIBBON     equ 30
TILE_RIBBON_CUT equ 31
; 32-42: building decor and decoys (see ROOM_LEGEND in tools/zxgfx.py); never solid
TILE_STAIR_R    equ 43          ; one step of a flight rising to the right
TILE_STAIR_L    equ 44          ; ... rising to the left
TILE_ESC_UP_R   equ 45          ; escalator steps: carry him up / down by themselves
TILE_ESC_UP_L   equ 46
TILE_ESC_DN_R   equ 47
TILE_ESC_DN_L   equ 48
TILE_TITLE_BRICK equ 49         ; title logo materials (assets/title.txt)
TILE_BARRIER    equ 50
TILE_GIRDER     equ 51
TILE_SLOT       equ 52          ; Hard Knock decor: slot machine, guitar on the wall, amp
TILE_GUITAR     equ 53
TILE_AMP        equ 54
; 55-62 furniture: sofa (2), picture, clock, TV, fridge (2, top/bottom), bin
; 63-69 bookcase (top/bottom), water cooler (top/bottom), reception desk (3)
; (tiles from 64 on cost two bytes each in room data: no one-byte code for them)
TILE_COUNT      equ 70

TILEF_SOLID     equ 1
TILEF_CLIMB     equ 2           ; ladder
TILEF_STAIR_R   equ 4           ; a step of a flight: holds him up from above, never blocks
TILEF_STAIR_L   equ 8
TILEF_ESC_UP    equ 16          ; with a STAIR_* bit: an escalator running up
TILEF_ESC_DOWN  equ 32          ; ... or down

tile_flags:
        db 0                    ; BLACK
        db 0                    ; WALLPAPER
        db TILEF_SOLID          ; FLOOR
        db TILEF_SOLID          ; BRICK
        db TILEF_CLIMB          ; LADDER_L
        db TILEF_CLIMB          ; LADDER_R
        db 0                    ; WINDOW
        db 0                    ; DOOR_T
        db 0                    ; DOOR_B
        db 0                    ; LAMP
        db 0                    ; SOCKET
        db 0                    ; HAT_FULL
        db 0                    ; HAT_EMPTY
        db 0                    ; CHECK_EMPTY
        db 0                    ; CHECK_DONE
        db 0                    ; EXIT_T
        db 0                    ; EXIT_B
        db 0                    ; HAT_HALF
        db 0                    ; MISS
        ds 9,0                  ; DIAL_0..8
        ds 4,0                  ; STAR, MOON, RIBBON, RIBBON_CUT
        ds 11,0                 ; decor and decoys
        db TILEF_STAIR_R        ; STAIR_R
        db TILEF_STAIR_L        ; STAIR_L
        db TILEF_STAIR_R+TILEF_ESC_UP
        db TILEF_STAIR_L+TILEF_ESC_UP
        db TILEF_STAIR_R+TILEF_ESC_DOWN
        db TILEF_STAIR_L+TILEF_ESC_DOWN
        ds 3,0                  ; title logo materials
        ds 3,0                  ; Hard Knock decor
        ds 8,0                  ; furniture
        ds 7,0                  ; bookcase, water cooler, reception desk
tile_flags_end:
        assert tile_flags_end-tile_flags == TILE_COUNT, "one tile_flags entry per tile"
