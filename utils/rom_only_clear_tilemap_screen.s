    ; This will clear the screen without using RAM.

    ; -- Fill tilemap into VRAM at $1B000-$1EBFF

vera_clear_start:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #(TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH))
vera_clear_fill_tile_map:
    ldx #0
vera_clear_fill_tile_map_row:
    lda #$20
    sta VERA_DATA0           ; character index = 'space'
    lda #COLOR_NORMAL
    sta VERA_DATA0           ; Fill Foreground and background color
    inx
    bne vera_clear_fill_tile_map_row
    dey
    bne vera_clear_fill_tile_map
