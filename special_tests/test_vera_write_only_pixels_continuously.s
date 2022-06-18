; This code writes pixel data to VERA contiuously. 
; Is is meant to show erros in writing only. The errors will
; only show up briefly, they will not stay on the screen. 
; BUT sinse we use borders at the right and bottom of the screen we will see if there 
; are any 'double-writes' or 'random-writes': if there are more writes to a row
; this will show up as entering a color into the borde (which is normally only painted
; once and in black).

; The reason for using pixels is to make more data appear on screen.


BACKGROUND_COLOR = $00

    .org $C000

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; Requires bitmap setup for layer 0
    .include "../utils/rom_only_setup_vera_for_bitmap.s"

    ; -- Fill pixels into VRAM at $0000-$0FFFF
    
    ; NOTE: this will not fill the complete screen!!
    
vera_wr_start:
    ldx #0
vera_wr_fill_bitmap_once:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #240
vera_wr_fill_bitmap_col_once:
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once
    inx
    bne vera_wr_fill_bitmap_once

    ; Right part of the screen

    ldx #0
vera_wr_fill_bitmap_once2:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$01                ; The right side part of the screen has a start byte starting at address 256 and up
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #240
vera_wr_fill_bitmap_col_once2:
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once2
    inx
    cpx #64                  ; The right part of the screen is 320 - 256 = 64 pixels
    bne vera_wr_fill_bitmap_once2

    
vera_wr_keep_writing:
    ldx #0
vera_wr_fill_bitmap:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #200                 ; IMPORTANT: we only have columns of 200 pixels here, so we will notice if there are writes into the border below
vera_wr_fill_bitmap_col:
    stx VERA_DATA0           ; store pixel with x as color
    dey
    bne vera_wr_fill_bitmap_col
    inx
    bne vera_wr_fill_bitmap

    jmp vera_wr_keep_writing
    

    ; === Included files ===
    
    .include utils/x16.s

    ; ======== NMI / IRQ =======
nmi:
    rti
   
irq:
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
