
BACKGROUND_COLOR = $02
FOREGROUND_COLOR = $01

TOP_MARGIN = 20
LEFT_MARGIN = 32
VSPACING = 10


  .org $C000

reset:

    ; Disable interrupts 
    sei

    ; Requires bitmap setup for layer 0
    .include "../utils/rom_only_setup_vera_for_bitmap.s"

  
    jsr clear_screen
    
    jsr draw_test_pattern
    
  
loop:
  jmp loop

  
  
draw_test_pattern:
    ; Experiment 1: draw a single pixel several times (with increment to 4)
  
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel
    
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
    
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
  
    ; Experiment 2: draw a double single pixel several times (with increment to 4)
  
    lda #%00010010           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *double* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel


    ; Experiment 3: draw a double single pixel several times (with increment to 4)
  
    lda #%00010100           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *alternative double* or *triple* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
    
    ; Experiment 4: draw a double single pixel several times (with increment to 4)
  
    lda #%00010110           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *quadruple* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
    
    rts

  
clear_screen:
  
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
    
    rts
  

    ; === Included files ===
    
    .include utils/x16.s

    .org $fffc
    .word reset
    .word reset
  
  
  
