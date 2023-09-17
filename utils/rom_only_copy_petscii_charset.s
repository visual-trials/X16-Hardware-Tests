    .ifdef CREATE_PRG
petscii_0 = $C000
petscii_1 = $C100
petscii_2 = $C200
petscii_3 = $C300
petscii_4 = $C400
petscii_5 = $C500
petscii_6 = $C600
petscii_7 = $C700
    .endif

    ; -- Copy petscii charset to VRAM at $1F000-$1F7FF
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$F0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    .ifdef CREATE_PRG
        ; We are assuming this code runs in Fixed RAM, so we can savely switch ROM banks
        
        ; We remember the ROM bank we are in right now
        lda ROM_BANK
        pha
        
        ; We are switching to ROM bank 6 since the PETSCII charset is located there
        lda #6
        sta ROM_BANK
    .endif
    
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
