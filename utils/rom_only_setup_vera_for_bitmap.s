; This sets up VERA for a bitmap (320x240) in layer 0
; It uses no RAM (ROM only)

BITMAP_WIDTH = 320
BITMAP_HEIGHT = 240

    ; -- First wait until VERA is ready
    
wait_for_vera:
    lda #42
    sta VERA_ADDR_LOW

    lda VERA_ADDR_LOW
    cmp #42
    bne wait_for_vera
    
    ; -- Show first sign of live by enabling VGA as soon as possible
  
    lda #%00010001           ; Enable Layer 0, Enable VGA
    sta VERA_DC_VIDEO

    lda #0                   ; Set Horizontal and vertical scoll to 0
    sta VERA_L0_HSCROLL_L
    sta VERA_L0_HSCROLL_H
    sta VERA_L0_VSCROLL_L
    sta VERA_L0_VSCROLL_H

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; VERA.layer0.config = (4 + 3) ; enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    ; VERA.layer0.tilebase = ; set new tilebase for layer 0 (0x00000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($000 >> 1)
    sta VERA_L0_TILEBASE
    
