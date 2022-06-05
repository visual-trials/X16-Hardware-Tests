
    ; -- Copy petscii charset to VRAM at $1F000-$1F7FF
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$F0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #0
copy_petscii_0:
    lda petscii_0, y
    sta VERA_DATA0
    iny
    bne copy_petscii_0
    
    ldy #0
copy_petscii_1:
    lda petscii_1, y
    sta VERA_DATA0
    iny
    bne copy_petscii_1
    
    ldy #0
copy_petscii_2:
    lda petscii_2, y
    sta VERA_DATA0
    iny
    bne copy_petscii_2
    
    ldy #0
copy_petscii_3:
    lda petscii_3, y
    sta VERA_DATA0
    iny
    bne copy_petscii_3
    
    ldy #0
copy_petscii_4:
    lda petscii_4, y
    sta VERA_DATA0
    iny
    bne copy_petscii_4
    
    ldy #0
copy_petscii_5:
    lda petscii_5, y
    sta VERA_DATA0
    iny
    bne copy_petscii_5
    
    ldy #0
copy_petscii_6:
    lda petscii_6, y
    sta VERA_DATA0
    iny
    bne copy_petscii_6
    
    ldy #0
copy_petscii_7:
    lda petscii_7, y
    sta VERA_DATA0
    iny
    bne copy_petscii_7
