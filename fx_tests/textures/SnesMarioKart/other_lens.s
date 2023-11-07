; == Very crude PoC of a 256x192px bitmap with a lens effect  ==

; To build: cl65 -t cx16 -o OTHER-LENS.PRG other_lens.s
; To run: x16emu.exe -prg OTHER-LENS.PRG -run

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

VERA_FX_CTRL      = $9F29  ; DCSEL=2
VERA_FX_TILEBASE  = $9F2A  ; DCSEL=2
VERA_FX_MAPBASE   = $9F2B  ; DCSEL=2

VERA_FX_X_INCR_L  = $9F29  ; DCSEL=3
VERA_FX_X_INCR_H  = $9F2A  ; DCSEL=3
VERA_FX_Y_INCR_L  = $9F2B  ; DCSEL=3
VERA_FX_Y_INCR_H  = $9F2C  ; DCSEL=3

VERA_FX_X_POS_L   = $9F29  ; DCSEL=4
VERA_FX_X_POS_H   = $9F2A  ; DCSEL=4
VERA_FX_Y_POS_L   = $9F2B  ; DCSEL=4
VERA_FX_Y_POS_H   = $9F2C  ; DCSEL=4

VERA_FX_X_POS_S   = $9F29  ; DCSEL=5
VERA_FX_Y_POS_S   = $9F2A  ; DCSEL=5

VERA_L0_CONFIG    = $9F2D
VERA_L0_TILEBASE  = $9F2F


; Kernal API functions
SETNAM            = $FFBD  ; set filename
SETLFS            = $FFBA  ; Set LA, FA, and SA
LOAD              = $FFD5  ; Load a file into main memory or VRAM


; -- VRAM addresses --


BITMAP_VRAM_ADDRESS   = $00000

SPRITES_VRAM_ADDRESS  = $12000

VERA_PALETTE      = $1FA00
VERA_SPRITES      = $1FC00 



; === Zero page addresses ===


LOAD_ADDRESS              = $30 ; 31
CODE_ADDRESS              = $32 ; 33
VRAM_ADDRESS              = $34 ; 35 ; 36


LENS_X_POS                = $40 ; 41
LENS_Y_POS                = $42 ; 43  ; second byte is never used
Z_DEPTH_BIT               = $44
QUADRANT                  = $45


COSINE_OF_ANGLE           = $51 ; 52
SINE_OF_ANGLE             = $53 ; 53

; === RAM addresses ===

BITMAP_QUADRANT_BUFFER    = $6000  ; 40 * 40 bytes = 1600 bytes (assuming a lens of 80x80)
Y_TO_ADDRESS_LOW          = $7600
Y_TO_ADDRESS_HIGH         = $7700

COPY_ROW_CODE             = $7800


; === Other constants ===

BITMAP_WIDTH = 256
BITMAP_HEIGHT = 192

start:

    jsr setup_vera_for_layer0_bitmap

    jsr copy_palette_from_index_16
    jsr load_bitmap_into_vram
    jsr generate_y_to_address_table
    
;    jsr generate_copy_row_code

    ; If set the first 4 sprites will be enabled, the others not
    lda #%00001000  ; Z-depth = 2
    sta Z_DEPTH_BIT
    
    lda #<(160-64)
    sta LENS_X_POS
    lda #>(160-64)
    sta LENS_X_POS+1
    
    lda #<(100-64)
    sta LENS_Y_POS
    lda #>(100-64)
    sta LENS_Y_POS+1
    
    jsr clear_sprite_memory
    jsr setup_sprites
    
    lda #0
    sta QUADRANT
    jsr download_bitmap_quadrant_into_buffer


    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts
    
    
download_bitmap_quadrant_into_buffer:

; FIXME: do something with theses!
; FIXME: do something with theses!
; FIXME: do something with theses!

;    lda QUADRANT

;    lda LENS_X_POS
;    lda LENS_X_POS+1  ; -> also NEGATIVE NUMBERS!
    
;    lda LENS_Y_POS
;    lda LENS_Y_POS+1  ; -> also NEGATIVE NUMBERS!

    ; -- Setup polygon mode --
    
    ; -> setup increment direction (of ADDR0 and ADDR1) based on QUADRANT

    ; -- loop through lines to download (0-39) --
    
        ; -- Calculate line number on screen --

        ; -- Skip downloading lines < 0 -- 
        ; -- Skip downloading lines > 200 -- 
    
    
        ; -- Set ADDR0 to the line we want to download --
        
        ; -- call download routine (which copies one row of VRAM (40 pixels) into Fixed RAM)




    rts
    
    
    
setup_vera_for_layer0_bitmap:

    lda VERA_DC_VIDEO
    ora #%01010000           ; Enable Layer 0 and sprites
    and #%11011111           ; Disable Layer 1
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
   
    lda #20
    sta VERA_DC_VSTART
    lda #400/2+20-1
    sta VERA_DC_VSTOP
    
    rts
    
    
clear_sprite_memory:

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<(SPRITES_VRAM_ADDRESS)
    sta VERA_ADDR_LOW
    lda #>(SPRITES_VRAM_ADDRESS)
    sta VERA_ADDR_HIGH

    ; FIXME: PERFORMANCE we can do this MUCH faster using CACHE writes and UNROLLING!
    
    ldy #128
clear_next_256:
    ldx #0
clear_next_1:

; FIXME: we should CLEAR! (for now filling with red)
;    stz VERA_DATA0
    lda #2
    sta VERA_DATA0

    inx
    bne clear_next_1
    
    dey
    bne clear_next_256
    
    rts
    
sprite_address_l:  ; Addres bits: 12:5  -> starts at $12000, then $13000: so first is %00000000, second is %10000000 = $00 and $80
    .byte $00, $80, $00, $80, $00, $80, $00, $80
sprite_address_h:  ; Addres bits: 16:13  -> starts at $12000, so first is %10001001 (mode = 8bpp, $12000) = $09
    .byte $09, $09, $0A, $0A, $0B, $0B, $0C, $0C
sprite_x_offset:
    .byte 64,  0, 0, 64, 64,  0, 0, 64
sprite_y_offset:
    .byte 64, 64, 0,  0, 64, 64, 0,  0
sprite_flips:
    .byte 0, 1, 3,  2, 0, 1, 3,  2
    
setup_sprites:

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<(VERA_SPRITES)
    sta VERA_ADDR_LOW
    lda #>(VERA_SPRITES)
    sta VERA_ADDR_HIGH

    ldx #0

setup_next_sprite:

    ; TODO: for performance we could skip writing certain sprite attibutes and just read them 

    ; Address (12:5)
    lda sprite_address_l, x
    sta VERA_DATA0

    ; Mode,	-	, Address (16:13)
    lda sprite_address_h, x
    ora #%10000000 ; 8bpp
    sta VERA_DATA0
    
    ; X (7:0)
    clc
    lda sprite_x_offset, x
    adc LENS_X_POS
    sta VERA_DATA0
    
    ; X (9:8)
    lda #0
    adc LENS_X_POS+1
    sta VERA_DATA0

    ; Y (7:0)
    clc
    lda sprite_y_offset, x
    adc LENS_Y_POS
    sta VERA_DATA0

    ; Y (9:8)
    lda #0
    adc LENS_Y_POS+1
    sta VERA_DATA0
    
    ; Collision mask	Z-depth	V-flip	H-flip
    lda Z_DEPTH_BIT
    ora sprite_flips, x
    sta VERA_DATA0

    ; Sprite height,	Sprite width,	Palette offset
; FIXME: we want to use a different palette (blue-ish color) for the pixels inside the lens
    lda #%11110000 ; 64x64, 0*16 = 0 palette offset
    sta VERA_DATA0
    
    inx
    
    ; if x == 4 we flip the Z_DEPTH_BIT
    cpx #4
    bne z_depth_bit_is_correct
    
    lda Z_DEPTH_BIT
    eor #%00001000
    sta Z_DEPTH_BIT

z_depth_bit_is_correct:

    cpx #8
    bne setup_next_sprite
    
    rts
    


copy_palette_from_index_16:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 16 of the palette (we preserve the first 16 default VERA colors)
    lda #<(VERA_PALETTE+2*16)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE+2*16)
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


bitmap_filename:      .byte    "other.bin" 
end_bitmap_filename:

load_bitmap_into_vram:

    lda #(end_bitmap_filename-bitmap_filename) ; Length of filename
    ldx #<bitmap_filename      ; Low byte of Fname address
    ldy #>bitmap_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
           
    jsr SETLFS
 
    lda #2            ; load into Bank 0 of VRAM (see https://github.com/X16Community/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-load )
    ldx #<BITMAP_VRAM_ADDRESS
    ldy #>BITMAP_VRAM_ADDRESS
    jsr LOAD
    bcc bitmap_loaded
; FIXME: do proper error handling!
    stp

bitmap_loaded:
    rts

    
    
    
generate_y_to_address_table:

    ; TODO: we assume the base address is 0 here!
    stz VRAM_ADDRESS
    stz VRAM_ADDRESS+1
    stz VRAM_ADDRESS+2
    
    ldy #0
generate_next_y_to_address_entry:
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    sta Y_TO_ADDRESS_LOW, y
    
    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    sta Y_TO_ADDRESS_HIGH, y
    
    ; FIXME: not storing VRAM_ADDRESS+2 at the moment!
    ; FIXME: not storing Y_TO_ADDRESS_BANK here!
    
    iny
    bne generate_next_y_to_address_entry

    rts
    
    

generate_copy_row_code:

    lda #<COPY_ROW_CODE
    sta CODE_ADDRESS
    lda #>COPY_ROW_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions

next_copy_instruction:

    ; -- lda VERA_DATA1 ($9F24)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$24               ; VERA_DATA1
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; When using the cache for writing we only write 1/4th of the time, so we read 3 extra bytes here (they go into the cache)
    
    ; -- lda VERA_DATA1 ($9F24)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$24               ; VERA_DATA1
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- lda VERA_DATA1 ($9F24)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$24               ; VERA_DATA1
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- lda VERA_DATA1 ($9F24)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$24               ; VERA_DATA1
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; We use the cache for writing, we do not want a mask to we store 0 (stz)

    ; -- stz VERA_DATA0 ($9F23)
    lda #$9C               ; stz ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    cpx #320/4
    bne next_copy_instruction

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



; Python script to generate sine and cosine bytes
;   import math
;   cycle=256
;   ampl=256   # -256 ($FF.00) to +256 ($01.00)
;   [(int(math.sin(float(i)/cycle*2.0*math.pi)*ampl) % 256) for i in range(cycle)]
;   [(int(math.sin(float(i)/cycle*2.0*math.pi)*ampl) // 256) for i in range(cycle)]
;   [(int(math.cos(float(i)/cycle*2.0*math.pi)*ampl) % 256) for i in range(cycle)]
;   [(int(math.cos(float(i)/cycle*2.0*math.pi)*ampl) // 256) for i in range(cycle)]
; Manually: replace -1 with 255!
    
sine_values_low:
    .byte 0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92, 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176, 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234, 236, 238, 241, 243, 244, 246, 248, 249, 251, 252, 253, 254, 254, 255, 255, 255, 0, 255, 255, 255, 254, 254, 253, 252, 251, 249, 248, 246, 244, 243, 241, 238, 236, 234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185, 181, 176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103, 97, 92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6, 0, 250, 244, 238, 231, 225, 219, 213, 207, 200, 194, 188, 182, 176, 170, 164, 159, 153, 147, 141, 136, 130, 125, 120, 114, 109, 104, 99, 94, 89, 85, 80, 75, 71, 67, 63, 59, 55, 51, 47, 44, 40, 37, 34, 31, 28, 25, 22, 20, 18, 15, 13, 12, 10, 8, 7, 5, 4, 3, 2, 2, 1, 1, 1, 0, 1, 1, 1, 2, 2, 3, 4, 5, 7, 8, 10, 12, 13, 15, 18, 20, 22, 25, 28, 31, 34, 37, 40, 44, 47, 51, 55, 59, 63, 67, 71, 75, 80, 85, 89, 94, 99, 104, 109, 114, 120, 125, 130, 136, 141, 147, 153, 159, 164, 170, 176, 182, 188, 194, 200, 207, 213, 219, 225, 231, 238, 244, 250
sine_values_high:
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
cosine_values_low:
    .byte 0, 255, 255, 255, 254, 254, 253, 252, 251, 249, 248, 246, 244, 243, 241, 238, 236, 234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185, 181, 176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103, 97, 92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6, 0, 250, 244, 238, 231, 225, 219, 213, 207, 200, 194, 188, 182, 176, 170, 164, 159, 153, 147, 141, 136, 130, 125, 120, 114, 109, 104, 99, 94, 89, 85, 80, 75, 71, 67, 63, 59, 55, 51, 47, 44, 40, 37, 34, 31, 28, 25, 22, 20, 18, 15, 13, 12, 10, 8, 7, 5, 4, 3, 2, 2, 1, 1, 1, 0, 1, 1, 1, 2, 2, 3, 4, 5, 7, 8, 10, 12, 13, 15, 18, 20, 22, 25, 28, 31, 34, 37, 40, 44, 47, 51, 55, 59, 63, 67, 71, 75, 80, 85, 89, 94, 99, 104, 109, 114, 120, 125, 130, 136, 141, 147, 153, 159, 164, 170, 176, 182, 188, 194, 200, 207, 213, 219, 225, 231, 238, 244, 250, 0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92, 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176, 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234, 236, 238, 241, 243, 244, 246, 248, 249, 251, 252, 253, 254, 254, 255, 255, 255
cosine_values_high:
    .byte 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0



; ==== DATA ====

palette_data:
  .byte $f0, $0f
  .byte $e0, $0e
  .byte $c8, $0e
  .byte $c0, $0e
  .byte $ac, $0e
  .byte $a8, $0e
  .byte $a8, $0c
  .byte $a0, $0c
  .byte $ac, $08
  .byte $88, $0c
  .byte $84, $0c
  .byte $80, $0c
  .byte $84, $0a
  .byte $8c, $08
  .byte $88, $08
  .byte $88, $06
  .byte $64, $0a
  .byte $60, $0a
  .byte $68, $06
  .byte $68, $04
  .byte $40, $0a
  .byte $44, $08
  .byte $40, $08
  .byte $20, $08
  .byte $20, $06
  .byte $48, $04
  .byte $44, $04
  .byte $44, $02
  .byte $20, $04
  .byte $24, $02
  .byte $00, $00
end_of_palette_data:


