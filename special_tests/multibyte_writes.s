
BACKGROUND_COLOR = $02
FOREGROUND_COLOR = $01

TOP_MARGIN = 12
LEFT_MARGIN = 32
VSPACING = 10


  .org $C000

reset:

    ; Disable interrupts 
    sei

    ; Requires bitmap setup for layer 0
    .include "../utils/rom_only_setup_vera_for_bitmap.s"

    lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    jsr clear_screen
    
    jsr draw_test_pattern
    
;    jsr blit_some_bytes
    
  
loop:
  jmp loop

blit_some_bytes:

; FIXME: test this *WITH* increments!!
; FIXME: test this *WITH* increments!!
; FIXME: test this *WITH* increments!!

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW
    
    lda #01
    sta VERA_DATA0           ; store single pixel
    lda #04
    sta VERA_DATA0           ; store single pixel
    lda #05
    sta VERA_DATA0           ; store single pixel
    lda #06
    sta VERA_DATA0           ; store single pixel

    ; Setting wrpattern to 11b and address % 4 = 01b
    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 + 1)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 + 1)
    sta VERA_ADDR_LOW
    
    lda #07
    sta VERA_DATA0           ; store pixel (this actually writes 4 bytes -with the same value- inside of VERA!)
    
    ; Setting wrpattern to 11b and address % 4 = 00b
    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW

    lda VERA_DATA0           ; read pixel (we ignore the result, it should now be in the 32-bit VERA cache)

; FIXME: when setting up this address it is likely VERA is *fetching ahead* the data at these (partial) addresses, therfore corrupting our cache!!
;   In fact: setting the to-be-written address will amount to reading at the address you want to write, therefore filling the cache with
;   the *same* value of the vram address you are writing to!!!
    ; Setting wrpattern to 11b and address % 4 = 00b
    lda #%00110110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 4 byte increment (=%0011)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW
    
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    
    rts
  
draw_test_pattern:

; FIXME: remove this setup of ADDR1!!
; FIXME: remove this setup of ADDR1!!
; FIXME: remove this setup of ADDR1!!
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
;;    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
;    lda #%00000111           ; Setting bit 16 of vram address to the highest bit (=1), setting auto-increment value to 0 byte increment (=%0000)
;    sta VERA_ADDR_BANK
;    lda #0
;    sta VERA_ADDR_HIGH
;    lda #0
;    sta VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
;!    lda #%00110110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 4 byte increment (=%0011)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL


; FIXME: creating some specific background pixels, to see if the cache contains general background or this new background

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_1:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_1
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_2:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_2

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_3:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_3

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_4:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_4

    


    

    ; Experiment 1: draw a single pixel several times (with increment to 4)
  
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW
    
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
    sta VERA_ADDR_LOW
    
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


    ; Experiment 3: draw a triple single pixel several times (with increment to 4)
  
    lda #%00010100           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *alternative double* or *triple* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW
    
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
    
    ; Experiment 4: draw a quadruple single pixel several times (with increment to 4)
  
    lda #%00010110           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *quadruple* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_LOW
    
    ; We use A as color
    lda #FOREGROUND_COLOR

; FIXME: just testing the blitter!!
    ldx VERA_DATA1

    sta VERA_DATA0           ; store pixel --> blit!

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
  
  
  
