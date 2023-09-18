; == Very crude PoC of 320x136px video playback using AUTOTX ==

; To build: cl65 -t cx16 -o WALKER.PRG walker.s
; To run: x16emu.exe -prg WALKER.PRG -run 

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; TODO: The following is *copied* from my x16.s (it should be included instead)

; -- some X16 constants --

VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_DATA1        = $9F24
VERA_CTRL         = $9F25

VERA_DC_VIDEO     = $9F29  ; DCSEL=0
VERA_DC_HSCALE    = $9F2A  ; DCSEL=0
VERA_DC_VSCALE    = $9F2B  ; DCSEL=0

VERA_DC_VSTART    = $9F2B  ; DCSEL=1
VERA_DC_VSTOP     = $9F2C  ; DCSEL=1

VERA_L0_CONFIG    = $9F2D
VERA_L0_TILEBASE  = $9F2F

; -- VRAM addresses --

VERA_PALETTE          = $1FA00



; === Zero page addresses ===


LOAD_ADDRESS              = $30 ; 31
CODE_ADDRESS              = $32 ; 33

VERA_ADDR_ZP_TO           = $34 ; 35 ; 36

SECTOR_NUMBER             = $37


; === RAM addresses ===

COPY_SECTOR_CODE               = $7800

; === Other constants ===

NR_OF_SECTORS_TO_COPY = 136*320 / 512 ; Note (320x136 resolution): 136 * 320 = 170 * 256 = 85 * 512 bytes (1 sector = 512 bytes)


start:

    jsr setup_vera_for_layer0_bitmap

    jsr copy_palette_from_index_1

    jsr generate_copy_sector_code

    ; FIXME: Setup the SD card
    ; FIXME: Setup the SD card
    ; FIXME: Setup the SD card
;    jsr setup_sd_card_for_reading

    jsr load_and_draw_frame
    
; FIXME: color 0 should NOT be TOUCHED!
; FIXME: color 0 should NOT be TOUCHED!
; FIXME: color 0 should NOT be TOUCHED!
    

    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts
    
    
    
setup_vera_for_layer0_bitmap:

    lda VERA_DC_VIDEO
    ora #%00010000           ; Enable Layer 0 
    and #%10011111           ; Disable Layer 1 and sprites
    sta VERA_DC_VIDEO

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; Enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    ; Set layer0 tilebase to 0x00000 and tile width to 320 px
    lda #0
    sta VERA_L0_TILEBASE

    ; Setting VSTART/VSTOP so that we have 200 rows on screen (320x200 pixels on screen)

    lda #%00000010  ; DCSEL=1
    sta VERA_CTRL
   
    lda #52
    sta VERA_DC_VSTART
    lda #136+52-1
    sta VERA_DC_VSTOP
    
    rts
    
    
copy_palette_from_index_1:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 1 of the palette
    lda #<(VERA_PALETTE+2*1)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE+2*1)
    sta VERA_ADDR_HIGH

    ; HACK: we know we have more than 128 colors to copy (meaning: > 256 bytes), so we are just going to copy 128 colors first
    
    ldy #0
next_packed_color_256:
    lda palette_data, y
    sta VERA_DATA0
    iny
    bne next_packed_color_256

    ldy #0
next_packed_color_1:
    lda palette_data+256, y
    sta VERA_DATA0
    iny
    cpy #<(end_of_palette_data-palette_data)
    bne next_packed_color_1
    
    rts





load_and_draw_frame:

    lda #0
    sta VERA_ADDR_LOW
    sta VERA_ADDR_HIGH

    lda #%00010000      ; setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    
    
    stz SECTOR_NUMBER
next_sector_to_copy:

    ; FIXME: setup for loading (the next) sector

    ; This loads and draws 512 bytes from SD card to VRAM
    jsr COPY_SECTOR_CODE
    
    ; SPEED: we can make this a bit quicker by counting DOWN
    inc SECTOR_NUMBER
    lda SECTOR_NUMBER
    cmp #NR_OF_SECTORS_TO_COPY
    bne next_sector_to_copy
    


    rts
    
    




generate_copy_sector_code:

    lda #<COPY_SECTOR_CODE
    sta CODE_ADDRESS
    lda #>COPY_SECTOR_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_low:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    bne next_copy_instruction_low
    
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_high:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    bne next_copy_instruction_high
    

    ; -- rts --
    lda #$60
    jsr add_code_byte

    rts


    
add_code_byte:
    sta (CODE_ADDRESS),y   ; store code byte at address (located at CODE_ADDRESS) + y
    iny                    ; increase y
    cpy #0                 ; if y == 0
    bne done_adding_code_byte
    inc CODE_ADDRESS+1     ; increment high-byte of CODE_ADDRESS
done_adding_code_byte:
    rts




; ==== DATA ====

; FIXME: all this DATA is included as asm text right now, but should be *loaded* from SD instead!

palette_data:
  .byte $66, $05
  .byte $68, $06
  .byte $88, $06
  .byte $88, $07
  .byte $8a, $07
  .byte $8a, $08
  .byte $aa, $08
  .byte $aa, $09
  .byte $ac, $09
  .byte $ac, $0a
  .byte $cc, $0a
  .byte $cc, $0b
  .byte $ce, $0b
  .byte $ce, $0c
  .byte $ee, $0d
  .byte $ee, $0e
  .byte $24, $02
  .byte $24, $03
  .byte $44, $05
  .byte $46, $05
  .byte $66, $06
  .byte $88, $09
  .byte $88, $08
  .byte $44, $04
  .byte $22, $03
  .byte $44, $03
  .byte $42, $02
  .byte $42, $03
  .byte $22, $02
  .byte $22, $01
  .byte $66, $07
  .byte $64, $05
  .byte $00, $01
  .byte $00, $00
  .byte $68, $05
  .byte $ac, $08
  .byte $ce, $0a
  .byte $ee, $0f
  .byte $8c, $09
  .byte $26, $02
  .byte $02, $00
  .byte $44, $02
  .byte $8a, $06
  .byte $8c, $08
  .byte $ae, $0a
  .byte $ee, $0c
  .byte $68, $07
  .byte $68, $04
  .byte $64, $04
  .byte $aa, $0a
  .byte $02, $01
  .byte $02, $02
  .byte $22, $00
  .byte $66, $04
  .byte $8a, $09
  .byte $24, $01
  .byte $46, $04
  .byte $20, $01
  .byte $46, $03
  .byte $24, $04
  .byte $ae, $09
  .byte $00, $02
  .byte $8c, $07
  .byte $ce, $0d
  .byte $22, $04
  .byte $ac, $0b
  .byte $cc, $0d
  .byte $68, $08
  .byte $cc, $0c
  .byte $46, $06
  .byte $a8, $0a
  .byte $aa, $0b
  .byte $ce, $0e
  .byte $cc, $0e
  .byte $88, $0a
  .byte $aa, $0c
  .byte $ae, $0b
  .byte $66, $08
  .byte $ec, $0e
  .byte $ca, $0c
  .byte $ac, $0c
  .byte $ec, $0f
  .byte $64, $06
  .byte $ae, $0c
  .byte $ce, $0f
  .byte $ae, $0d
  .byte $44, $06
  .byte $8a, $0a
  .byte $ae, $0e
  .byte $8c, $0a
  .byte $ac, $0d
  .byte $86, $08
  .byte $42, $04
  .byte $ae, $0f
  .byte $ac, $0e
  .byte $8a, $0c
  .byte $a8, $09
  .byte $46, $02
  .byte $ce, $09
  .byte $6a, $06
  .byte $86, $06
  .byte $6a, $09
  .byte $8a, $0b
  .byte $20, $02
  .byte $86, $07
  .byte $6a, $07
  .byte $64, $03
  .byte $20, $00
  .byte $ec, $0d
  .byte $a8, $0b
  .byte $ca, $0d
  .byte $ca, $0b
  .byte $68, $0a
  .byte $88, $0b
  .byte $68, $0b
  .byte $88, $0c
  .byte $68, $0c
  .byte $aa, $0e
  .byte $aa, $0f
  .byte $46, $0a
  .byte $24, $06
  .byte $22, $05
  .byte $66, $0a
  .byte $46, $08
  .byte $24, $05
  .byte $46, $07
  .byte $44, $07
  .byte $8c, $0b
  .byte $68, $09
  .byte $66, $09
  .byte $6a, $0a
  .byte $6a, $0b
  .byte $8c, $0c
  .byte $8c, $0d
  .byte $8c, $0e
  .byte $ac, $0f
  .byte $cc, $0f
  .byte $6a, $08
  .byte $88, $05
  .byte $8a, $0d
  .byte $8a, $05
  .byte $02, $03
  .byte $aa, $0d
  .byte $86, $09
  .byte $ca, $0a
  .byte $02, $04
  .byte $22, $06
  .byte $46, $09
  .byte $44, $08
  .byte $24, $07
  .byte $8a, $0e
  .byte $88, $0d
  .byte $66, $0b
  .byte $44, $09
  .byte $68, $0d
  .byte $8a, $0f
  .byte $88, $0e
  .byte $66, $0c
  .byte $68, $0e
  .byte $66, $0e
  .byte $66, $0d
  .byte $68, $0f
  .byte $88, $0f
  .byte $46, $0c
  .byte $44, $0b
  .byte $46, $0d
  .byte $44, $0a
  .byte $24, $0a
  .byte $46, $0b
  .byte $24, $09
  .byte $44, $0c
  .byte $24, $0b
  .byte $22, $0a
  .byte $22, $09
  .byte $02, $09
  .byte $24, $08
  .byte $22, $08
  .byte $02, $07
  .byte $00, $07
  .byte $00, $06
  .byte $22, $07
  .byte $02, $05
  .byte $00, $05
  .byte $02, $06
  .byte $00, $04
  .byte $a8, $08
  .byte $86, $0a
  .byte $42, $05
  .byte $00, $03
  .byte $48, $04
  .byte $46, $0e
  .byte $64, $07
  .byte $48, $06
  .byte $6a, $0c
  .byte $20, $03
  .byte $8c, $0f
  .byte $26, $03
  .byte $cc, $09
  .byte $48, $05
  .byte $6a, $0d
  .byte $26, $09
  .byte $04, $07
  .byte $aa, $07
  .byte $66, $03
end_of_palette_data:


