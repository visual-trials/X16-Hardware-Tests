; This code reads and writes tile data to VERA contiuously. 
; Is is meant to show erros in reading and write and let the 
; errors be cumulative. Meaning when an error occurs in either reading or writing
; what error will be the new tile and stay on screen

; The reason for using tiles is to make it easier/more apparent
; for the viewer that there is an error (an 8x8 pixel change is much more
; visible than a single pixel change).

; Requires tile setup (8x8) for layer 0

    ; -- Fill tilemap into VRAM at $1B000-$1EBFF
    
vera_rdwr_start:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #(TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH))
vera_rdwr_fill_tile_map_once:
    ldx #0
vera_rdwr_fill_tile_map_row_once:
    lda #$51                 ; 'Bullet'
    sta VERA_DATA0           ; store character index 
    lda #$41                 ; Background color 4, foreground color 1
    sta VERA_DATA0           ; Fill Foreground and background color
    inx
    bne vera_rdwr_fill_tile_map_row_once
    dey
    bne vera_rdwr_fill_tile_map_once
    
vera_rdwr_keep_reading_and_writing:
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #(TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH))
vera_rdwr_fill_tile_map:
    ldx #0
vera_rdwr_fill_tile_map_row:

; FIXME: VERA_DATA1 has not been updated! We should trigger a reload of it!

    lda VERA_DATA1           ; Read character index
    sta VERA_DATA0           ; Write back character index
    
; FIXME: VERA_DATA1 has not been updated! We should trigger a reload of it!

    lda VERA_DATA1           ; Read foreground and background color
    
    
    sta VERA_DATA0           ; Write Foreground and background color
    inx
    bne vera_rdwr_fill_tile_map_row
    dey
    bne vera_rdwr_fill_tile_map
    
    jmp vera_rdwr_keep_reading_and_writing
