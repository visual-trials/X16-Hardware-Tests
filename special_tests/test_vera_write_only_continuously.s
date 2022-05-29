; This code writes tile data to VERA contiuously. 
; Is is meant to show erros in writing only. The errors will
; only show up briefly, they will not stay on the screen.

; The reason for using tiles is to make it easier/more apparent
; for the viewer that there is an error (an 8x8 pixel change is much more
; visible than a single pixel change).

    .org $C000

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; Requires tile setup (8x8) for layer 0
    .include "../utils/rom_only_setup_vera_for_tile_map.s"

    ; -- Fill tilemap into VRAM at $1B000-$1EBFF

vera_wr_start:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK

vera_wr_keep_filling:
    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #(TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH))
vera_wr_fill_tile_map:
    ldx #0
    lda #$27                 ; Background color 2, foreground color 7
vera_wr_fill_tile_map_row:
    stx VERA_DATA0           ; character index = x
    sta VERA_DATA0           ; Fill Foreground and background color
    inx
    bne vera_wr_fill_tile_map_row
    dey
    bne vera_wr_fill_tile_map
    
    ; TODO: pause between each fill!
    ; TODO: pause between each fill!
    ; TODO: pause between each fill!
    
    jmp vera_wr_keep_filling

    ; === Included files ===
    
    .include utils/x16.s

    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"

    ; ======== NMI / IRQ =======
nmi:
    rti
   
irq:
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
