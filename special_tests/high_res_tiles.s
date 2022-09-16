
  .org $C000

reset:

    ; -- First wait until VERA is ready

    ldx #$A5
wait_for_vera:
    lda #42
    sta VERA_ADDR_LOW

    lda VERA_ADDR_LOW
    cmp #42
    beq vera_ready
    
    ldy #0
vera_boot_snooze:
    nop
    nop
    nop
    nop
    nop
    nop
    iny
    bne vera_boot_snooze
    
    dex
    bne wait_for_vera
    
vera_not_working:

    ; TODO: VERA is not responding, we should fall back into outputting to VIA and/or maybe the YM2151
    ; Currently used to trigger an LA
    sta IO3_BASE_ADDRESS
    
vera_ready:    

    lda #%00010001 ; Enable Layer 0, Enable VGA
    sta VERA_DC_VIDEO

    lda #0                   ; Set Horizontal and vertical scoll to 0
    sta VERA_L0_HSCROLL_L
    sta VERA_L0_HSCROLL_H
    sta VERA_L0_VSCROLL_L
    sta VERA_L0_VSCROLL_H

    lda #$80                 ; 1:1 scale (640 x 480 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; TODO: use TILE_MAP_HEIGHT and TILE_MAP_WIDTH to determine this value!
;    lda #%10100000           ; Set map height/width to 64/128, and Tile mode 1 bpp (16 color text mode)
    ; enable tilemap mode: (64 tiles wide, 32 tiles high) and color depth = 2bpp on layer 0
    lda #%00010001
    sta VERA_L0_CONFIG
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 0 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    

;    lda #($1F0 >> 1)         ; Set tilebase for layer 0 to 0x1F000. This also sets the tile width and height to 8 px


; FIXME: BUG IN HARDWARE??? When running this setting on real HW you can see that pixels become 2 high and 1 wide!!
; FIXME: BUG IN HARDWARE??? When running this setting on real HW you can see that pixels become 2 high and 1 wide!!
; FIXME: BUG IN HARDWARE??? When running this setting on real HW you can see that pixels become 2 high and 1 wide!!

    ; // set new tilebase for layer 0 (0x00000) and set TileWidth and TileHeight to 16px (=3)
    lda #%00000011
    sta VERA_L0_TILEBASE
  
  
  
  
loop:
  jmp loop


  
  
    .if 0
  
init_2bit_high_res_draw_screen:


    ; VERA.layer0.config = (4 + 1); // enable bitmap mode and color depth = 2bpp on layer 0
;    lda #(4+1)
    ; enable tilemap mode: (64 tiles wide, 32 tiles high) and color depth = 2bpp on layer 0
    lda #%00010001
    sta VERA_L0_config

    ; VERA.layer0.tilebase = (0x000 >> 1) | 1; // set new tilebase for layer 0 (0x00000) and set TileWidth to 640px (=1)
;    lda #(($000 >> 1) | 1)
    ; // set new tilebase for layer 0 (0x00000) and set TileWidth and TileHeight to 16px (=3)
    lda #%00000011
    sta VERA_L0_tilebase

    ; We set the map base to $16000
    lda #>($16000 >> 1)
    sta VERA_L0_mapbase

    ; ---- Creating basic mapbase ----
    
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the new tilebase (=1), setting auto-increment value to 1
    sta VERA_addr_bank
    lda #$60
    sta VERA_addr_high
    lda #$00
    sta VERA_addr_low
    
    ldy #0
    
next_tile_row:
    ldx #0
    
next_tile_column:
    lda current_tile_index
    sta VERA_data0
    
    ; NOTE: current_tile_index cannot be higher than 1024
    ; instead we do 40 * 26 = 960 tiles (3 rows at top and bottom are assumed to be empty)
    
    lda current_tile_index+1
    sta VERA_data0
    
    cpy #3   ; TODO: Note sure about this one, but it seems to work
    bcc :+

    cpy #26  ; TODO: Note sure about this one, but it seems to work
    bcs :+

    cpx #40
    bcs :+
    inc current_tile_index
    bne :+
    inc current_tile_index+1
:

    inx
    cpx #64
    bne next_tile_column
    
    iny
    cpy #32
    bne next_tile_row
    
    rts

    .endif
  

    ; === Included files ===
    
    .include utils/x16.s

    .org $fffc
    .word reset
    .word reset
  
  
  
