
DO_ROTATE = 1  ; otherwise SHEAR

USE_CACHE_FOR_WRITING = 1
USE_TRANSPARENT_WRITING = 1

BACKGROUND_COLOR = 240  ; 240 = Purple in this palette
FOREGROUND_COLOR = 1
CLEAR_COLOR = 0

MAP_WIDTH = 16    ; 16 * 8 = 128 pixels
MAP_HEIGHT = 16   ; 16 * 8 = 128 pixels

TEXTURE_WIDTH = 100
TEXTURE_HEIGHT = 75

TILE_WIDTH = 8
TILE_HEIGHT = 8


TOP_MARGIN = 12
LEFT_MARGIN = 16
VSPACING = 10

ORIGINAL_PICTURE_POS_X = 32
ORIGINAL_PICTURE_POS_Y = 65

DESTINATION_PICTURE_POS_X = 160
DESTINATION_PICTURE_POS_Y = 51

TILEDATA_VRAM_ADDRESS = $13000 ; right behind the 320x240 bitmap layer (which ends at $12C00)


; === Zero page addresses ===

; Bank switching
RAM_BANK                  = $00
ROM_BANK                  = $01

; Temp vars
TMP1                      = $02
TMP2                      = $03
TMP3                      = $04
TMP4                      = $05

; Printing
TEXT_TO_PRINT             = $06 ; 07
TEXT_COLOR                = $08
CURSOR_X                  = $09
CURSOR_Y                  = $0A
INDENTATION               = $0B
BYTE_TO_PRINT             = $0C
DECIMAL_STRING            = $0D ; 0E ; 0F

; Timing
TIMING_COUNTER            = $14 ; 15
TIME_ELAPSED_MS           = $16
TIME_ELAPSED_SUB_MS       = $17 ; one nibble of sub-milliseconds

DATA_PTR_ZP               = $26 ; 27
PALLETE_PTR_ZP            = $28 ; 29
VERA_ADDR_ZP_FROM         = $2A ; 2B
VERA_ADDR_ZP_TO           = $2C ; 2D
VERA_ADDR_ZP_PIXEL        = $2E ; 2F

PIXEL_ADDR_LOWER_X        = $30
PIXEL_ADDR_LOWER_Y        = $31
PIXEL_ADDR_HIGHER_X_LOW   = $32
PIXEL_ADDR_HIGHER_X_HIGH  = $33
PIXEL_ADDR_HIGHER_Y       = $34

; FIXME: these are leftovers of memory tests in the general hardware tester (needed by utils.s atm). We dont use them, but cant remove them right now
BANK_TESTING              = $39
BAD_VALUE                 = $3A

CODE_ADDRESS              = $3D ; 3E

; Affine transformation
X_SUB_PIXEL               = $40 ; 41
Y_SUB_PIXEL               = $42 ; 43

TILE_X                    = $46
TILE_Y                    = $47

; RAM addresses
COPY_ROW_CODE               = $7800


; ROM addresses
PALLETE           = $CC00
PIXELS            = $D000


  .org $C000

reset:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs
    
    jsr setup_vera_for_bitmap_and_tile_map
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor
    jsr init_timer

;    jsr clear_screen_slow
;    lda #$10                 ; 8:1 scale, so we can clearly see the pixels
;    sta VERA_DC_HSCALE
;    sta VERA_DC_VSCALE
;    jsr affine_transform_some_bytes
    
    ; Put orginal picture on screen (slow)
    jsr clear_screen_slow
    jsr copy_palette
    jsr copy_texture_pixels_as_tile_pixels_to_high_vram
    
    ; Copy bitmap image to VRAM from ROM
    lda #<(ORIGINAL_PICTURE_POS_X+ORIGINAL_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO
    lda #>(ORIGINAL_PICTURE_POS_X+ORIGINAL_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO+1
    
; FIXME: we should copy the pixels to the TILEDATA_VRAM_ADDRESS!!
    
    jsr copy_pixels
    
    
    ; Test speed of affine transforming (shearing/rotating) the picture from VRAM (to CPU) to VRAM
    jsr test_speed_of_affine_transforming_bitmap_1_byte_per_pixel
    
  
loop:
  jmp loop

affine_transform_some_bytes:

; FIXME: this hasnt been implemented yet!
; FIXME: this hasnt been implemented yet!
; FIXME: this hasnt been implemented yet!

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

    ; Setting wrpattern to 11b and address % 4 = 00b
    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW

    lda VERA_DATA0           ; read pixel (we ignore the result, it should now be in the 32-bit VERA cache)
    
    ; Test if reading from the palette WONT fill the cache
    lda #%00000111           ; Setting bit 16 of vram address to the highest bit (=1), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #<VERA_PALETTE
    sta VERA_ADDR_LOW
    lda #>VERA_PALETTE
    sta VERA_ADDR_HIGH
    
    lda VERA_DATA0           ; read pixel (we ignore the result, it should now be in the 32-bit VERA cache)

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
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    
    
    
    ; Test if writing to the palette WONT be 4 bytes at the time
    lda #%00000011           ; Setting bit 16 of vram address to the highest bit (=1), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #<VERA_PALETTE
    sta VERA_ADDR_LOW
    lda #>VERA_PALETTE
    sta VERA_ADDR_HIGH
    
    lda #7
    sta VERA_DATA0           ; write 1 or 4 pixel?
    
    
    
    ; Reading first 4 bytes of the palette one-by-one and show them on screen
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL

    lda #%00010001           ; Setting bit 16 of vram address to the highest bit (=1), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #<VERA_PALETTE
    sta VERA_ADDR_LOW
    lda #>VERA_PALETTE
    sta VERA_ADDR_HIGH
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL

    ; Setting wrpattern to 11b and address % 4 = 00b
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_LOW
    
    lda VERA_DATA1           ; read palette byte
    sta VERA_DATA0           ; store single pixel
    
    lda VERA_DATA1           ; read palette byte
    sta VERA_DATA0           ; store single pixel
    
    lda VERA_DATA1           ; read palette byte
    sta VERA_DATA0           ; store single pixel
    
    lda VERA_DATA1           ; read palette byte
    sta VERA_DATA0           ; store single pixel
    
    rts
  
  
  
  
; ====================================== SHEAR SPEED TEST ========================================
  
test_speed_of_affine_transforming_bitmap_1_byte_per_pixel:

    jsr generate_copy_row_code

    jsr start_timer

    ; Setup FROM and TO VRAM addresses
    lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO
    lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO+1
    
    ; Entering *affine helper mode*: selecting ADDR0
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    ; Setting base address and map size
    
    lda #(TILEDATA_VRAM_ADDRESS >> 9)
    sta $9F2A

    lda #%10000000  ; 10000000 for 16x16 map
    ora #%00010000  ; 1 for Clip
    ora #%00000010  ; 10 for no tile lookup
    sta $9F29
    
    jsr rotate_or_shear_bitmap_fast_1_byte_per_copy

    jsr stop_timer

    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #4
    sta CURSOR_Y

    .if(DO_ROTATE)
        lda #<rotate_bitmap_3x100x75_8bpp_message
        sta TEXT_TO_PRINT
        lda #>rotate_bitmap_3x100x75_8bpp_message
        sta TEXT_TO_PRINT + 1
    .else 
        lda #<shear_bitmap_3x100x75_8bpp_message
        sta TEXT_TO_PRINT
        lda #>shear_bitmap_3x100x75_8bpp_message
        sta TEXT_TO_PRINT + 1
    .endif
    
    jsr print_text_zero
    
    lda #8
    sta CURSOR_X
    lda #21
    sta CURSOR_Y

    .if(USE_CACHE_FOR_WRITING)
        lda #<four_bytes_per_write_message
        sta TEXT_TO_PRINT
        lda #>four_bytes_per_write_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #<one_byte_per_write_message
        sta TEXT_TO_PRINT
        lda #>one_byte_per_write_message
        sta TEXT_TO_PRINT + 1
    .endif
    
    jsr print_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #8
    sta CURSOR_X
    lda #26
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts
    


shear_bitmap_3x100x75_8bpp_message: 
    .asciiz "Shearing bitmap 100x75 (8bpp) "
rotate_bitmap_3x100x75_8bpp_message: 
    .asciiz "Rotating bitmap 100x75 (8bpp) "
one_byte_per_write_message: 
    .asciiz "Method: 1 byte per write"
four_bytes_per_write_message: 
    .asciiz "Method: 4 bytes per write"



COSINE_ROTATE = 247
SINE_ROTATE = 67

rotate_or_shear_bitmap_fast_1_byte_per_copy:

    ; Entering *affine helper mode*
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL


    ; Maybe do 15.2 degrees: 
    ;   cos(15.2 degrees)*256 = 247.0  -> +247 = x_delta for row, -67  x_delta for column (start of row)
    ;   sin(15.2 degrees)*256 = 67.1   -> +67  = y_delta for row, +247  x_delta for column (start or row)

    lda #128
    sta Y_SUB_PIXEL
    
    lda #256-28          ; We start a litte above the pixture, so (when rotated) the right top part fits into the drawing rectangle
    sta Y_SUB_PIXEL+1
    lda #128
    sta X_SUB_PIXEL
    lda #0
    sta X_SUB_PIXEL+1
    
    .if(DO_ROTATE)
        lda #COSINE_ROTATE       ; X increment low
        sta $9F29
        lda #%10000100           ; reset subpixel position = 1, 0, X decr = 0, X subpixel increment exponent = 001, X increment high = 00
                                 ; FIXME: **THIS IS DONE BELOW ALSO!!**
        sta $9F2A
        lda #SINE_ROTATE
        sta $9F2B                ; Y increment low
        lda #%00000100           ; 00, Y decr = 0, Y subpixel increment exponent = 001, Y increment high = 00 
        sta $9F2C
    .else
        lda #0                   ; X increment low
        sta $9F29
        lda #%10000101           ; reset subpixel position = 1, 0, X decr = 0, X subpixel increment exponent = 001, X increment high = 01
                                 ; FIXME: **THIS IS DONE BELOW ALSO!!**
        sta $9F2A
        lda #60
        sta $9F2B                ; Y increment low
        lda #%00100100           ; 00, Y decr = 1, Y subpixel increment exponent = 001, Y increment high = 00 
        sta $9F2C
    .endif

    ldx #0
    
rotate_copy_next_row_1:
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL

    ; FIXME: we are resetting the subpixel positions here, but this is kinda awkward! 
    ; FIXME: we do a subpixel RESET here, BUT should do a SET of the subpixel positions here (which is more precise)
    ; FIXME: **IT DONE ABOVE ALSO!!**
    .if(DO_ROTATE)
        lda #%10000100           ; reset subpixel position = 1, 0, X decr = 0, X subpixel increment exponent = 001, X increment high = 01
    .else
        lda #%10000101           ; reset subpixel position = 1, 0, X decr = 0, X subpixel increment exponent = 001, X increment high = 01
    .endif
    sta $9F2A
    
    .if (USE_CACHE_FOR_WRITING)
        .if(USE_TRANSPARENT_WRITING)
            lda #%00110100           ; Setting auto-increment value to 4 byte increment (=%0011) and wrpattern = 10b (=transparent blit)
        .else
            lda #%00110110           ; Setting auto-increment value to 4 byte increment (=%0011) and wrpattern = 11b (=blit)
        .endif
        sta VERA_ADDR_BANK
    .else
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW

    ; Setting the position
    
    lda #%00001001           ; DCSEL=4, ADDRSEL=1
    sta VERA_CTRL
    
    ; FIXME: we should probably set the subpixel positions! (for more precision)

    ; NOTE: we are setting 
    .if(DO_ROTATE)
        ; == ROTATE ==
    
        lda X_SUB_PIXEL+1
        sta $9F29                ; X pixel position low [7:0]
        bpl x_pixel_pos_high_positive
        lda #%00000111           ; sign extending X pixel position (when negative)
        bra x_pixel_pos_high_correct
x_pixel_pos_high_positive:
        lda #%00000000
x_pixel_pos_high_correct:
        sta $9F2A                ; X subpixel position[0] = 0, X pixel position high [10:8] = 000 or 111
    ; FIXME:
    ;    txa
    ; HALF SIZE:    asl
        lda Y_SUB_PIXEL+1
        sta $9F2B                ; Y pixel position low [7:0]
        bpl y_pixel_pos_high_positive
        lda #%01000111           ; sign extending X pixel position (when negative)
        bra y_pixel_pos_high_correct
y_pixel_pos_high_positive:
        lda #%01000000
y_pixel_pos_high_correct:
        sta $9F2C                ; Y subpixel position[0] = 0, Reset cache byte index = 1, Y pixel position high [10:8] = 000 or 111
    .else
        ; == SHEAR ==
    
        lda #0
        sta $9F29                ; X pixel position low [7:0]
        lda #%00000000
        sta $9F2A                ; X subpixel position[0] = 0, X pixel position high [10:8] = 000
        txa
        sta $9F2B                ; Y pixel position low [7:0]
        lda #%01000000
        sta $9F2C                ; Y subpixel position[0] = 0, Reset cache byte index = 1, Y pixel position high [10:8] = 000
    .endif

    ; Copy one row of 100 pixels
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with 320
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(320)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(320)
    sta VERA_ADDR_ZP_TO+1

    clc
    lda Y_SUB_PIXEL
    adc #COSINE_ROTATE
    sta Y_SUB_PIXEL
    lda Y_SUB_PIXEL+1
    adc #0
    sta Y_SUB_PIXEL+1
    
    sec
    lda X_SUB_PIXEL
    sbc #SINE_ROTATE
    sta X_SUB_PIXEL
    lda X_SUB_PIXEL+1
    sbc #0
    sta X_SUB_PIXEL+1
    
    inx
;    cpx #75             ; we do 75 rows
    cpx #100             ; we do 75 rows diagonally ~= 100
    bne rotate_copy_next_row_1
    
done_rotate_copy: 

    ; Exiting affine helper mode
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
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

    .if (USE_CACHE_FOR_WRITING)
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

    .endif

    
    .if (USE_CACHE_FOR_WRITING)
        ; We use the cache for writing, we do not want a mask to we store 0 (stz)
    
        ; -- stz VERA_DATA0 ($9F23)
        lda #$9C               ; stz ....
        jsr add_code_byte

        lda #$23               ; $23
        jsr add_code_byte
        
        lda #$9F               ; $9F
        jsr add_code_byte

    .else
        ; -- sta VERA_DATA0 ($9F23)
        lda #$8D               ; sta ....
        jsr add_code_byte

        lda #$23               ; $23
        jsr add_code_byte
        
        lda #$9F               ; $9F
        jsr add_code_byte
    .endif
    
    inx
    .if (USE_CACHE_FOR_WRITING)
        ; HACK!
        cpx #124/4             ; 124(+3) copy pixels written to VERA (due to diagonal)
    .else
        ; HACK!
        cpx #125               ; 125 copy pixels written to VERA (due to diagonal)
    .endif
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
  
  
clear_screen_slow:
  
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
; FIXME: now drawing a pattern!
;    tya
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
; FIXME: now drawing a pattern!
;    tya
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once2
    inx
    cpx #64                  ; The right part of the screen is 320 - 256 = 64 pixels
    bne vera_wr_fill_bitmap_once2
    
    rts


; ================================== loading picture data from ROM =====================================


copy_palette:

    ; Starting at palette VRAM address

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<VERA_PALETTE
    sta VERA_ADDR_LOW
    lda #>VERA_PALETTE
    sta VERA_ADDR_HIGH

    ldy #0
next_packed_color:
    lda PALLETE, y
    sta VERA_DATA0
    iny
    bne next_packed_color

    ldy #0
next_packed_color2:
    lda PALLETE+256, y
    sta VERA_DATA0
    iny
    bne next_packed_color2

    rts

    
clear_all_tiledata_in_map_slow:
  
    ; FIXME: we are ASSUMING here that this VRAM ADDRESS has its bit16 set to 1!!
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1px (=14=%0001)
    sta VERA_ADDR_BANK
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW
    
    ; TODO: should we allow clearing with a different value?
    lda #CLEAR_COLOR
    
    ldx #(MAP_HEIGHT*TILE_HEIGHT)
clear_tiledata_row:
    ldy #(MAP_WIDTH*TILE_WIDTH)
clear_tiledata_pixel:
    sta VERA_DATA0           ; clear pixel
    dey
    bne clear_tiledata_pixel
    dex
    bne clear_tiledata_row
    
    rts
    
    
copy_texture_pixels_as_tile_pixels_to_high_vram:

; FIXME: move this to *OUTSIDE* this routine!!
    lda #<(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_TO
    lda #>(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_TO+1


    ; Copying a bitmap picture (aka texture) as tiles of 8x8 into VRAM
    
    ; - the following assumes there is no padding: the number of texture bytes = TEXTURE_WIDTH*TEXTURE_HEIGHT
    ; - the following also assumes a map size of 16x16 tiles
    
    ; Steps:
    ;
    ; - clear all tiledata (of 'vitual' map) with 0-bytes (so MAP_WIDTH*8 * MAP_HEIGHT*8 pixels)
    ; - set y to 0
    ; - for each row in the original texture (so: 0 to TEXTURE_HEIGHT-1)
    ;   - set x to 0
    ;   - for each pixel in the row of the original texture (so: 0 to TEXTURE_WIDTH-1)
    ;     - determine the address to write to:
    ;        - VRAM tile address = Y[7:4] * TILE_WIDTH * TILE_HEIGHT * MAP_WIDTH + X[7:4] * TILE_WIDTH * TILE_HEIGHT 
    ;        - VRAM address in tile = VRAM tile address + y[3:0]*TILE_WIDTH + x[3:0]
    ;                 this translates to : 0 00yy yyxx xxyy yxxx
    ;        - VRAM pixel address = VRAM tile base address + VRAM tile address + VRAM address in tile
    ;     - read from texture
    ;     - write to VRAM
    ;     - inxcrement x
    ;   - increment y


    lda #<PIXELS
    sta DATA_PTR_ZP
    lda #>PIXELS
    sta DATA_PTR_ZP+1 
    
    ; Clearing all tiledata beforehand
    jsr clear_all_tiledata_in_map_slow

    ; Note: We should create this : 0 00yy yyxx xxyy yxxx
    
    ldx #0               ; Note: register x represents the Y-coordinate!
next_pixel_row_tiled:  

    txa
    and #%00000111            ; We take y[2:0] = Y_IN_TILE
    asl
    asl
    asl                      ; We shift the Y_IN_TILE-bits 3 places to the left
    sta PIXEL_ADDR_LOWER_Y
    
    txa
    and #%01111000            ; We take y[6:3] = TILE_Y
    lsr                      ; we shift the TILE_Y-bits 1 place to the right
    sta PIXEL_ADDR_HIGHER_Y
    
    ldy #0               ; Note: register y represents the X-coordinate!
next_horizontal_pixel_tiled:

; FIXME: make this more flexible: now only allows for map size 16x16!

    tya
    and #%00000111            ; We take x[2:0] = X_IN_TILE
    sta PIXEL_ADDR_LOWER_X   ; We use the X_IN_TILE-bits directly

    ; We reset X_HIGH
    lda #0
    sta PIXEL_ADDR_HIGHER_X_HIGH
    
    tya
    and #%01111000            ; We take x[6:3] = TILE_X
    asl
    asl
    rol PIXEL_ADDR_HIGHER_X_HIGH
    asl
    rol PIXEL_ADDR_HIGHER_X_HIGH  ; We shift the two higher x-bits (of TILE_X) into X_HIGH
    sta PIXEL_ADDR_HIGHER_X_LOW   ; We keep the two lower x-bits (of TILE_X) into X_LOW
    
    ; We put all the bits together
    lda PIXEL_ADDR_HIGHER_Y
    ora PIXEL_ADDR_HIGHER_X_HIGH
    sta VERA_ADDR_ZP_PIXEL+1       ; 00yy yyxx .... ....

    lda PIXEL_ADDR_HIGHER_X_LOW
    ora PIXEL_ADDR_LOWER_Y
    ora PIXEL_ADDR_LOWER_X
    sta VERA_ADDR_ZP_PIXEL         ; .... .... xxyy yxxx
    
    ; Loading VRAM *pixel* address into VERA  
    ; FIXME: we are ASSUMING here that this VRAM ADDRESS has its bit16 set to 1!!
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    ; Adding pixel address to the base address
    clc
    lda VERA_ADDR_ZP_TO
    adc VERA_ADDR_ZP_PIXEL
    sta VERA_ADDR_LOW
    lda VERA_ADDR_ZP_TO+1
    adc VERA_ADDR_ZP_PIXEL+1
    sta VERA_ADDR_HIGH

    ; Load pixel data
    lda (DATA_PTR_ZP),y

    ; Write pixel data
    sta VERA_DATA0

    iny
    cpy #TEXTURE_WIDTH
    bne next_horizontal_pixel_tiled
    inx

    ; Adding TEXTURE_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #<TEXTURE_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #>TEXTURE_WIDTH
    sta DATA_PTR_ZP+1
    
    cpx #TEXTURE_HEIGHT
    bne next_pixel_row_tiled

    
    rts



; Note: Destination VRAM address (lower 16 bits, bit 16 is assumed to be 0) should be put in VERA_ADDR_ZP_TO before calling this function
copy_pixels:  

    lda #<PIXELS
    sta DATA_PTR_ZP
    lda #>PIXELS
    sta DATA_PTR_ZP+1 

    lda #%00010000      ; setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #0
    sta VERA_ADDR_LOW
    sta VERA_ADDR_HIGH

    ldx #0
next_pixel_row:  
    ; Loading VRAM address into VERA  
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH

    ldy #0
next_horizontal_pixel:
    ; tya  ; ----> This is to generate a pattern!
    lda (DATA_PTR_ZP),y

    sta VERA_DATA0

    iny
    cpy #100
    bne jmp_next_horizontal_pixel
    inx

    ; Adding 100 + 0*256 to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #100
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    ; Adding 64 + 1*256 (=320) to the previous VRAM address
    clc
    lda VERA_ADDR_ZP_TO
    adc #64
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #1
    sta VERA_ADDR_ZP_TO+1

    cpx #75
    bne jmp_next_pixel_row 

    rts
  
jmp_next_horizontal_pixel:
    jmp next_horizontal_pixel
jmp_next_pixel_row:
    jmp next_pixel_row


    
    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/timing.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s

    ; ======== NMI / IRQ =======
nmi:
    ; TODO: implement this
    ; FIXME: ugly hack!
    jmp reset
    rti
   
irq:
    rti
    
    
    
  .org $CC00

  .byte $fe, $0f   ; HACK: we are not using this color, since its the transparent color. We are using color $01 instead of $00.
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $dd, $0f
  .byte $dc, $0e
  .byte $cc, $0e
  .byte $ba, $0e
  .byte $cc, $0d
  .byte $bb, $0d
  .byte $b9, $0e
  .byte $ba, $0c
  .byte $a9, $0c
  .byte $aa, $0b
  .byte $99, $0b
  .byte $98, $0e
  .byte $98, $0c
  .byte $98, $0b
  .byte $87, $0b
  .byte $88, $09
  .byte $77, $0a
  .byte $76, $0a
  .byte $77, $09
  .byte $66, $08
  .byte $66, $07
  .byte $54, $08
  .byte $55, $06
  .byte $30, $0f
  .byte $54, $07
  .byte $44, $08
  .byte $55, $05
  .byte $44, $07
  .byte $43, $07
  .byte $43, $06
  .byte $33, $07
  .byte $20, $0c
  .byte $33, $06
  .byte $33, $06
  .byte $21, $09
  .byte $32, $05
  .byte $22, $05
  .byte $11, $08
  .byte $22, $05
  .byte $00, $0c
  .byte $22, $03
  .byte $11, $06
  .byte $12, $04
  .byte $00, $0a
  .byte $00, $08
  .byte $12, $03
  .byte $00, $05
  .byte $ff, $0f
  .byte $ea, $0f
  .byte $e8, $0f
  .byte $d6, $0f
  .byte $d4, $0f
  .byte $d0, $0f
  .byte $c7, $0e
  .byte $c6, $0e
  .byte $c0, $0f
  .byte $c3, $0f
  .byte $c0, $0f
  .byte $c5, $0d
  .byte $c0, $0d
  .byte $b7, $0d
  .byte $c1, $0d
  .byte $a0, $0f
  .byte $a0, $0e
  .byte $a5, $0c
  .byte $a0, $0d
  .byte $90, $0e
  .byte $90, $0d
  .byte $91, $0a
  .byte $80, $0c
  .byte $70, $0f
  .byte $85, $0a
  .byte $70, $0a
  .byte $74, $08
  .byte $71, $08
  .byte $62, $0c
  .byte $60, $0f
  .byte $77, $07
  .byte $63, $0b
  .byte $70, $09
  .byte $64, $08
  .byte $63, $07
  .byte $65, $06
  .byte $60, $08
  .byte $63, $06
  .byte $53, $08
  .byte $53, $06
  .byte $54, $07
  .byte $53, $06
  .byte $52, $06
  .byte $53, $05
  .byte $53, $06
  .byte $43, $05
  .byte $42, $05
  .byte $43, $05
  .byte $43, $05
  .byte $42, $05
  .byte $43, $05
  .byte $32, $05
  .byte $32, $04
  .byte $32, $04
  .byte $d9, $0d
  .byte $e1, $0d
  .byte $ca, $0c
  .byte $c3, $0d
  .byte $c7, $0a
  .byte $c5, $0a
  .byte $b7, $0b
  .byte $c0, $0a
  .byte $b6, $09
  .byte $a4, $09
  .byte $a6, $0a
  .byte $a0, $09
  .byte $a6, $08
  .byte $a4, $08
  .byte $92, $07
  .byte $90, $07
  .byte $95, $07
  .byte $93, $07
  .byte $83, $07
  .byte $83, $06
  .byte $83, $06
  .byte $82, $06
  .byte $83, $06
  .byte $73, $06
  .byte $73, $06
  .byte $72, $05
  .byte $63, $05
  .byte $63, $05
  .byte $64, $05
  .byte $62, $05
  .byte $63, $05
  .byte $62, $04
  .byte $62, $04
  .byte $54, $05
  .byte $62, $04
  .byte $53, $05
  .byte $61, $04
  .byte $61, $03
  .byte $53, $04
  .byte $52, $04
  .byte $52, $04
  .byte $50, $03
  .byte $50, $03
  .byte $40, $03
  .byte $42, $03
  .byte $42, $03
  .byte $40, $02
  .byte $32, $03
  .byte $31, $02
  .byte $32, $03
  .byte $30, $02
  .byte $a6, $06
  .byte $96, $07
  .byte $95, $05
  .byte $94, $06
  .byte $93, $06
  .byte $84, $05
  .byte $84, $05
  .byte $74, $05
  .byte $74, $04
  .byte $63, $05
  .byte $64, $05
  .byte $64, $04
  .byte $54, $04
  .byte $53, $04
  .byte $51, $03
  .byte $52, $03
  .byte $53, $03
  .byte $52, $03
  .byte $52, $03
  .byte $51, $03
  .byte $43, $03
  .byte $42, $03
  .byte $42, $03
  .byte $41, $02
  .byte $42, $02
  .byte $42, $02
  .byte $41, $02
  .byte $32, $02
  .byte $33, $03
  .byte $32, $02
  .byte $31, $02
  .byte $31, $01
  .byte $30, $01
  .byte $20, $01
  .byte $21, $01
  .byte $20, $00
  .byte $10, $00
  .byte $d9, $08
  .byte $b8, $07
  .byte $a8, $07
  .byte $97, $06
  .byte $97, $05
  .byte $87, $05
  .byte $85, $05
  .byte $54, $03
  .byte $43, $03
  .byte $ff, $09
  .byte $ed, $07
  .byte $cc, $09
  .byte $cc, $07
  .byte $cf, $03
  .byte $bf, $01
  .byte $aa, $07
  .byte $ac, $04
  .byte $99, $06
  .byte $aa, $04
  .byte $cf, $05
  .byte $af, $01
  .byte $9f, $02
  .byte $8d, $03
  .byte $8e, $01
  .byte $8d, $02
  .byte $78, $05
  .byte $7d, $01
  .byte $6b, $02
  .byte $6b, $01
  .byte $59, $02
  .byte $57, $03
  .byte $59, $01
  .byte $46, $03
  .byte $48, $01
  .byte $37, $01
  .byte $34, $02
  .byte $25, $00
  .byte $13, $01
  .byte $00, $00
  .byte $5f, $09
  .byte $66, $06
  .byte $4a, $07
  .byte $4e, $07
  .byte $3e, $08
  .byte $3b, $06
  .byte $48, $06
  .byte $39, $05
  .byte $36, $04
  .byte $27, $04
  .byte $23, $02
  .byte $02, $00
  .byte $bc, $0b
  .byte $ab, $0a
  .byte $89, $09
  .byte $69, $08
  .byte $dd, $0d
  .byte $cd, $0d
  .byte $99, $0a
  .byte $78, $08
  .byte $67, $07
  .byte $44, $04
  .byte $34, $04
  .byte $22, $02
  .byte $12, $03
  


  .org $D000

  .byte  $f1, $f1, $f1, $f1, $f1, $f1, $fe, $ff, $ff, $fe, $30, $fe, $ff, $30, $30, $30, $30, $30, $2d, $30, $29, $2d, $29, $29, $29, $29, $29, $27, $29, $29, $27, $29, $29, $29, $29, $29, $27, $26, $24, $24, $24, $21, $24, $24, $1e, $1c, $1c, $1c, $18, $1c, $18, $1c, $1c, $1c, $18, $1c, $1f, $21, $21, $21, $21, $21, $24, $24, $24, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $26, $26, $26, $26, $26, $26, $26, $26, $65, $65, $65, $65, $65, $64, $61, $60, $90, $90, $90, $90, $90, $8b, $8b, $88
  .byte  $f1, $f1, $e3, $f1, $f1, $fe, $fe, $ff, $ff, $ff, $fe, $30, $fe, $30, $30, $30, $30, $30, $30, $30, $2d, $2d, $29, $29, $29, $29, $29, $29, $27, $29, $27, $29, $29, $2d, $29, $29, $27, $27, $26, $24, $24, $24, $24, $24, $21, $1e, $1c, $1e, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $21, $21, $21, $21, $21, $21, $24, $27, $24, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $26, $27, $26, $26, $26, $65, $65, $63, $65, $63, $66, $63, $64, $60, $60, $90, $90, $90, $90, $90, $8f, $8f
  .byte  $f1, $f1, $f1, $f1, $f1, $fe, $fe, $ff, $ff, $ff, $30, $fe, $30, $30, $30, $30, $30, $30, $30, $30, $2d, $29, $2d, $29, $29, $29, $29, $29, $29, $29, $29, $29, $2d, $2d, $2d, $2d, $29, $27, $26, $26, $24, $24, $24, $24, $20, $1e, $1e, $1e, $1c, $1c, $1c, $1c, $1f, $1c, $1c, $1c, $21, $21, $21, $21, $21, $21, $24, $21, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $26, $27, $26, $26, $65, $65, $63, $63, $63, $63, $63, $63, $61, $60, $60, $90, $90, $90, $90, $90, $a8
  .byte  $f1, $f1, $f1, $f1, $f1, $f1, $ff, $ff, $ff, $ff, $ff, $30, $ff, $ff, $30, $30, $30, $30, $30, $30, $2d, $30, $29, $2d, $29, $29, $29, $29, $29, $29, $29, $29, $2d, $2d, $2d, $29, $29, $27, $26, $24, $27, $24, $24, $24, $24, $1e, $1c, $1e, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $21, $21, $21, $21, $21, $24, $24, $24, $27, $26, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $26, $26, $26, $26, $65, $65, $65, $63, $63, $60, $63, $60, $63, $60, $60, $60, $90, $90, $90, $90, $90
  .byte  $f1, $f1, $f1, $f1, $f1, $fe, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $30, $30, $30, $30, $30, $30, $30, $30, $2d, $2d, $29, $29, $29, $29, $29, $29, $29, $27, $2d, $29, $2d, $2d, $29, $29, $27, $26, $27, $24, $24, $24, $24, $21, $1e, $1e, $1c, $1e, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $1f, $21, $21, $21, $21, $21, $21, $24, $24, $26, $26, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $27, $26, $26, $26, $65, $65, $65, $63, $63, $63, $63, $60, $61, $61, $60, $60, $60, $60, $90, $90, $90, $90
  .byte  $f1, $f1, $f1, $f1, $fe, $fe, $ff, $ff, $ff, $ff, $30, $ff, $30, $ff, $30, $30, $30, $30, $30, $30, $2d, $2d, $29, $29, $29, $29, $67, $27, $27, $26, $27, $29, $29, $29, $2d, $29, $27, $27, $26, $24, $26, $24, $24, $24, $23, $1e, $1e, $1e, $1c, $1b, $1c, $1c, $1c, $1c, $1c, $1c, $1f, $21, $21, $21, $20, $21, $21, $21, $24, $24, $24, $24, $24, $24, $26, $27, $26, $27, $27, $27, $26, $27, $26, $26, $26, $26, $26, $65, $23, $63, $63, $63, $60, $61, $5c, $60, $5c, $60, $60, $60, $90, $90, $90, $90
  .byte  $fe, $f1, $f1, $fe, $f1, $fe, $fe, $ff, $ff, $ff, $ff, $ff, $30, $30, $30, $30, $30, $30, $30, $2d, $2d, $29, $29, $29, $26, $29, $27, $26, $26, $26, $26, $26, $27, $29, $29, $27, $27, $24, $26, $24, $24, $20, $21, $23, $21, $1e, $1b, $1e, $1b, $1c, $58, $58, $1b, $1c, $58, $1c, $1f, $1f, $1f, $1f, $1f, $1f, $20, $20, $21, $23, $24, $23, $23, $24, $24, $24, $24, $24, $24, $24, $23, $24, $65, $26, $65, $65, $65, $65, $63, $63, $63, $63, $63, $60, $60, $5c, $5c, $90, $5d, $60, $60, $90, $90, $90
  .byte  $f1, $f1, $f1, $f1, $f1, $fe, $fe, $ff, $ff, $ff, $30, $30, $ff, $30, $30, $30, $30, $30, $2d, $30, $29, $29, $67, $27, $67, $26, $26, $26, $65, $26, $23, $26, $26, $26, $27, $27, $26, $24, $24, $24, $23, $20, $20, $23, $20, $1e, $1b, $1b, $1e, $1b, $58, $58, $58, $1b, $58, $1c, $1b, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $20, $20, $21, $23, $21, $23, $21, $23, $24, $23, $23, $23, $23, $23, $23, $65, $65, $65, $63, $65, $63, $61, $5c, $5c, $5c, $5c, $5c, $5b, $8b, $5b, $5c, $5d, $8b, $90, $8b, $8f
  .byte  $f1, $f1, $f1, $f1, $f1, $fe, $fe, $ff, $ff, $30, $fe, $30, $30, $30, $30, $30, $30, $30, $2d, $2d, $29, $29, $27, $26, $26, $65, $65, $23, $65, $65, $23, $23, $65, $26, $26, $26, $65, $23, $23, $20, $20, $20, $20, $20, $20, $1b, $1b, $1b, $1b, $1b, $58, $58, $58, $58, $58, $58, $1c, $1f, $1f, $1f, $1b, $1f, $1f, $1f, $20, $1f, $23, $20, $23, $20, $23, $20, $20, $20, $20, $20, $63, $20, $63, $63, $63, $63, $63, $63, $5c, $63, $5c, $5c, $5c, $5b, $86, $86, $83, $83, $86, $86, $8b, $8b, $8b, $8b
  .byte  $f1, $f1, $f1, $f1, $f1, $fe, $fe, $fe, $ff, $fe, $30, $2b, $30, $2b, $30, $2d, $30, $2d, $30, $2d, $29, $67, $26, $65, $65, $65, $65, $23, $23, $23, $23, $23, $65, $65, $65, $23, $23, $23, $20, $20, $20, $5e, $1f, $61, $20, $59, $1b, $1b, $1b, $58, $58, $53, $58, $58, $58, $58, $1c, $1b, $1f, $1f, $1f, $1f, $1f, $1f, $1f, $21, $20, $24, $20, $21, $20, $20, $20, $1e, $20, $5f, $20, $61, $20, $61, $61, $5e, $5c, $5c, $5e, $5c, $5c, $86, $5b, $86, $86, $86, $83, $85, $86, $86, $89, $86, $8b, $86
  .byte  $f1, $f1, $f1, $f1, $f1, $f1, $2b, $fe, $2b, $30, $2b, $2b, $30, $2b, $2d, $2b, $2d, $2b, $29, $29, $67, $26, $66, $23, $64, $23, $63, $63, $61, $63, $63, $23, $63, $23, $23, $63, $20, $63, $20, $5f, $5c, $1e, $5c, $20, $5e, $1b, $59, $59, $1b, $59, $58, $54, $58, $53, $58, $58, $58, $1f, $58, $1f, $1c, $1c, $1f, $1f, $1f, $1f, $20, $20, $20, $20, $1e, $1e, $1e, $1e, $1e, $1e, $5f, $20, $5f, $63, $5e, $61, $5e, $5c, $5c, $5b, $5b, $5c, $5b, $86, $86, $83, $83, $86, $85, $86, $86, $8b, $89, $8b
  .byte  $f1, $e3, $f1, $b7, $f1, $b7, $fe, $2b, $fe, $2b, $2b, $2b, $67, $2b, $2b, $2d, $2b, $29, $67, $67, $26, $65, $65, $63, $63, $61, $63, $5f, $63, $5f, $63, $61, $63, $63, $63, $63, $5e, $5e, $5e, $5e, $5e, $59, $5e, $5e, $5e, $59, $5a, $54, $59, $54, $17, $54, $54, $54, $53, $53, $58, $58, $1b, $58, $58, $58, $58, $1c, $1b, $1c, $1e, $1c, $1e, $1b, $1b, $1b, $5a, $5a, $5a, $5a, $5a, $5f, $5a, $5f, $5e, $5c, $59, $86, $86, $86, $86, $86, $86, $83, $83, $83, $83, $86, $86, $89, $86, $89, $86, $89
  .byte  $e3, $b7, $b7, $b7, $b7, $b7, $2b, $b7, $2b, $2b, $2b, $67, $2b, $67, $67, $67, $67, $67, $67, $65, $66, $65, $63, $63, $61, $61, $5f, $5e, $5e, $5e, $5f, $5c, $20, $61, $63, $5c, $5c, $59, $5c, $59, $59, $5b, $59, $5c, $59, $5a, $57, $59, $54, $57, $54, $54, $54, $54, $54, $53, $53, $58, $58, $58, $58, $58, $58, $58, $58, $58, $1b, $1b, $1b, $1b, $1b, $1b, $1b, $1b, $5a, $5a, $1e, $5a, $5e, $5a, $5c, $59, $86, $83, $57, $83, $86, $86, $86, $86, $83, $83, $83, $83, $86, $86, $8b, $89, $86, $8b
  .byte  $b7, $b7, $b7, $b7, $b7, $b7, $b7, $b7, $2b, $99, $67, $97, $67, $97, $67, $66, $67, $66, $65, $66, $63, $63, $61, $61, $5c, $5f, $5c, $5b, $5b, $5b, $59, $5c, $5e, $5c, $59, $5c, $57, $59, $57, $59, $57, $57, $83, $5b, $59, $57, $57, $55, $57, $54, $57, $54, $55, $54, $54, $58, $58, $58, $58, $59, $53, $58, $53, $58, $58, $58, $18, $1b, $1b, $18, $1b, $1b, $5a, $5a, $5a, $59, $59, $59, $59, $59, $59, $5b, $86, $86, $82, $86, $82, $57, $86, $86, $86, $57, $86, $86, $89, $5b, $89, $86, $a5, $85
  .byte  $b8, $b7, $b8, $97, $b7, $97, $97, $b7, $99, $b7, $97, $97, $67, $66, $66, $66, $66, $66, $66, $66, $63, $60, $60, $5d, $5c, $5d, $5b, $5b, $5b, $86, $5b, $57, $5b, $5b, $5b, $86, $86, $86, $57, $83, $57, $57, $82, $86, $86, $57, $55, $83, $57, $57, $55, $57, $54, $50, $cc, $d3, $cb, $49, $45, $49, $4e, $58, $53, $58, $53, $58, $58, $18, $18, $58, $18, $5a, $18, $59, $18, $59, $5a, $57, $59, $57, $59, $5b, $5b, $86, $86, $86, $86, $86, $86, $57, $86, $86, $84, $86, $86, $86, $89, $8b, $86, $8b
  .byte  $b3, $b3, $c8, $97, $c8, $97, $b7, $97, $97, $67, $97, $66, $97, $66, $66, $66, $62, $94, $63, $62, $60, $60, $5f, $5c, $5d, $86, $5b, $86, $86, $86, $86, $86, $86, $5b, $86, $86, $83, $83, $57, $86, $57, $82, $82, $83, $83, $83, $82, $55, $82, $57, $5b, $59, $72, $c9, $ca, $cd, $cd, $d3, $1a, $4f, $4f, $4f, $4e, $1c, $53, $58, $18, $18, $18, $18, $18, $5a, $18, $59, $5a, $59, $59, $59, $59, $5b, $57, $5b, $57, $5b, $86, $86, $57, $83, $86, $86, $86, $86, $86, $5b, $89, $5d, $8b, $8b, $8e, $8b
  .byte  $b3, $c8, $c8, $95, $c8, $95, $95, $97, $99, $97, $95, $66, $95, $64, $94, $64, $60, $60, $60, $60, $60, $5f, $8b, $5d, $86, $86, $86, $86, $86, $83, $86, $83, $86, $86, $86, $86, $86, $82, $83, $82, $83, $82, $82, $82, $82, $83, $80, $82, $83, $5d, $7a, $69, $69, $6f, $c0, $cd, $d4, $ce, $d6, $2a, $1a, $1a, $4f, $49, $18, $18, $18, $18, $18, $18, $18, $1b, $5a, $1b, $5a, $5a, $5a, $5e, $59, $59, $59, $5b, $5c, $5b, $5b, $5b, $5b, $86, $5b, $5b, $5b, $5b, $5b, $8b, $5b, $5d, $90, $8e, $90, $a8
  .byte  $c8, $c8, $b1, $c8, $95, $c8, $95, $95, $95, $95, $95, $94, $64, $94, $60, $60, $60, $60, $90, $90, $90, $5d, $8b, $8b, $86, $88, $83, $88, $83, $85, $83, $83, $83, $86, $85, $82, $82, $82, $82, $82, $83, $82, $80, $82, $85, $80, $83, $83, $82, $6b, $69, $69, $6f, $6f, $77, $d0, $ce, $d4, $d4, $2a, $2f, $22, $22, $1a, $49, $1c, $18, $18, $53, $53, $18, $18, $18, $5a, $5a, $59, $5a, $5a, $5b, $59, $5b, $57, $5e, $5b, $5e, $5c, $5b, $5b, $5b, $5b, $5b, $5d, $5d, $5d, $5d, $8e, $62, $5d, $90, $62
  .byte  $b1, $b1, $af, $af, $b1, $af, $94, $b1, $94, $94, $94, $90, $94, $90, $90, $90, $90, $90, $90, $8f, $8b, $8b, $8b, $86, $88, $86, $85, $86, $85, $85, $82, $82, $82, $85, $82, $85, $82, $82, $82, $82, $82, $82, $81, $82, $82, $82, $a5, $7d, $6b, $69, $73, $73, $73, $73, $77, $9b, $d4, $ce, $da, $2f, $2a, $2a, $2a, $22, $1a, $0f, $53, $1e, $1e, $18, $1b, $5a, $5a, $5a, $5a, $5a, $5a, $59, $59, $59, $5b, $5e, $5b, $5c, $59, $5e, $5b, $5b, $5b, $5b, $5b, $5e, $5e, $5e, $5d, $5f, $5d, $62, $8e, $62
  .byte  $ac, $af, $ac, $af, $ac, $af, $ad, $af, $ad, $ac, $ad, $90, $ad, $90, $8f, $90, $8f, $8f, $8b, $88, $86, $88, $86, $88, $89, $87, $85, $85, $85, $85, $85, $a4, $82, $85, $85, $82, $82, $82, $80, $82, $80, $82, $82, $81, $85, $a4, $75, $36, $6f, $73, $73, $77, $77, $77, $73, $9d, $d0, $d4, $d7, $2e, $22, $30, $fd, $2c, $2a, $22, $32, $07, $20, $1c, $1b, $1b, $1e, $5a, $5a, $5a, $5a, $5e, $5e, $5d, $59, $5e, $5e, $5e, $5e, $5e, $5e, $5e, $5e, $60, $5f, $5f, $5f, $61, $62, $61, $62, $62, $62, $62
  .byte  $ac, $ac, $ac, $ac, $ac, $ac, $ac, $ad, $ad, $ad, $ad, $8f, $aa, $8f, $8c, $8f, $8f, $8f, $88, $8f, $88, $88, $88, $85, $88, $88, $87, $85, $88, $85, $85, $82, $85, $85, $85, $85, $82, $85, $82, $82, $82, $82, $81, $85, $85, $7b, $40, $6f, $73, $77, $73, $73, $7d, $9f, $9f, $9e, $d0, $ce, $d8, $2f, $28, $e4, $e6, $fe, $2f, $2e, $0b, $32, $01, $53, $1e, $1b, $5a, $5a, $5a, $5a, $5a, $5e, $5e, $5e, $5e, $5f, $5f, $5f, $5f, $61, $61, $61, $63, $61, $61, $61, $5f, $5f, $5f, $62, $62, $62, $62, $62
  .byte  $ad, $ac, $ad, $ac, $ad, $ac, $ad, $ad, $ad, $ae, $ad, $aa, $aa, $8f, $8f, $8c, $8f, $8a, $8f, $8c, $8f, $88, $88, $87, $88, $88, $88, $88, $88, $87, $85, $a4, $85, $85, $88, $85, $87, $85, $85, $85, $85, $85, $85, $85, $81, $3d, $73, $75, $77, $77, $7d, $81, $81, $7d, $76, $9b, $d0, $ce, $d8, $2e, $2a, $ef, $f2, $fd, $2f, $2f, $0b, $01, $32, $32, $12, $5f, $1b, $5a, $5a, $5e, $5f, $5a, $61, $5f, $5f, $5f, $61, $5f, $61, $5f, $5f, $5f, $61, $62, $61, $61, $64, $5f, $62, $5f, $64, $62, $62, $62
  .byte  $aa, $ad, $ad, $ad, $ac, $ad, $ad, $aa, $ae, $aa, $ae, $8c, $aa, $8c, $8a, $8f, $8c, $88, $8c, $88, $8a, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $87, $85, $85, $85, $88, $85, $85, $85, $85, $85, $82, $85, $8c, $6e, $71, $75, $7a, $76, $7b, $7d, $7d, $7d, $7d, $a1, $9d, $d2, $d4, $ef, $2a, $2e, $2a, $21, $2f, $28, $2c, $14, $4e, $06, $04, $32, $11, $5f, $5a, $5a, $5f, $5a, $5f, $5f, $5f, $5f, $61, $5f, $61, $5f, $61, $61, $60, $61, $64, $61, $64, $61, $64, $64, $64, $64, $64, $64, $62
  .byte  $ad, $aa, $ad, $aa, $ad, $aa, $ad, $aa, $ae, $aa, $92, $8c, $91, $8c, $8c, $8a, $8a, $87, $8a, $8a, $87, $87, $87, $87, $87, $8a, $87, $8a, $88, $8a, $85, $85, $a4, $85, $88, $85, $88, $86, $85, $85, $82, $85, $8f, $72, $70, $78, $74, $75, $78, $76, $9f, $9f, $9f, $7d, $a0, $d2, $d0, $d4, $ff, $2e, $2e, $2e, $2f, $31, $2f, $14, $f9, $1c, $25, $22, $1a, $43, $51, $8e, $5a, $5f, $5f, $5f, $5f, $61, $62, $5f, $61, $61, $61, $61, $62, $64, $64, $64, $66, $64, $65, $64, $64, $64, $64, $64, $62, $64
  .byte  $ad, $ad, $ae, $ad, $ad, $ad, $ad, $ae, $aa, $92, $aa, $91, $aa, $a9, $8a, $8c, $8c, $8c, $8c, $8a, $8a, $87, $87, $87, $87, $87, $8a, $87, $8a, $87, $8a, $a4, $87, $85, $85, $88, $88, $88, $85, $85, $87, $8f, $74, $70, $74, $74, $78, $78, $9c, $78, $9c, $9d, $c5, $9d, $9d, $9d, $d3, $ce, $e6, $2f, $2f, $2f, $2e, $2e, $2a, $0e, $fa, $20, $29, $26, $20, $1e, $5e, $5e, $5f, $5e, $5f, $5a, $5f, $5f, $5f, $61, $61, $61, $61, $62, $63, $62, $64, $66, $64, $65, $64, $fd, $64, $65, $64, $64, $64, $62
  .byte  $ae, $b0, $ae, $ae, $ae, $ae, $ae, $ad, $ae, $ae, $92, $91, $91, $91, $8c, $8d, $8a, $8c, $8c, $8d, $87, $8a, $87, $8a, $87, $8a, $87, $8a, $88, $8a, $87, $87, $87, $87, $88, $87, $86, $88, $86, $8f, $80, $70, $70, $75, $78, $7c, $74, $78, $9c, $9c, $c3, $9c, $c4, $d2, $d0, $d2, $d0, $cd, $e4, $31, $31, $31, $2e, $2f, $22, $2b, $64, $5c, $57, $59, $59, $5d, $5e, $5e, $5e, $5f, $5f, $5e, $5e, $5e, $5f, $60, $5f, $61, $5f, $61, $64, $64, $66, $66, $66, $66, $66, $64, $64, $64, $64, $61, $62, $5e
  .byte  $b0, $b0, $ae, $b0, $ae, $ae, $ae, $ae, $ae, $92, $92, $ae, $92, $aa, $8d, $8d, $8d, $8d, $8d, $8c, $8d, $8a, $8a, $87, $8a, $87, $8a, $87, $8a, $87, $8a, $88, $8a, $88, $8f, $8f, $88, $8f, $8f, $7f, $70, $70, $75, $76, $75, $75, $75, $9e, $78, $9f, $78, $c6, $d1, $c4, $d2, $d6, $d8, $cd, $dc, $e6, $31, $31, $25, $22, $ff, $60, $57, $57, $59, $5b, $5b, $5e, $5e, $5f, $5d, $5f, $5e, $5e, $5e, $5f, $5f, $61, $61, $61, $62, $63, $62, $64, $64, $66, $66, $64, $64, $64, $62, $5f, $5e, $5f, $59, $5b
  .byte  $b2, $b0, $b0, $b0, $b0, $b0, $b0, $ae, $b0, $93, $92, $92, $92, $92, $92, $91, $91, $91, $91, $8d, $8d, $8a, $8a, $8a, $8a, $8a, $8a, $8a, $8a, $8a, $8a, $8c, $8c, $8f, $8f, $8f, $8f, $90, $7a, $70, $74, $7b, $7a, $76, $79, $79, $79, $78, $9f, $9e, $9e, $9e, $9e, $a3, $d1, $d2, $dc, $da, $ce, $f2, $e6, $2e, $2f, $25, $f2, $83, $59, $5b, $5b, $5d, $5e, $5d, $5d, $5f, $5d, $5f, $5d, $5e, $5e, $5d, $5f, $62, $61, $61, $5f, $61, $61, $64, $64, $64, $64, $64, $62, $5f, $5d, $5f, $5d, $5d, $5d, $5e
  .byte  $b2, $b0, $b2, $b0, $b0, $ae, $b0, $b0, $92, $96, $96, $93, $93, $92, $92, $92, $91, $91, $91, $91, $8d, $8d, $8d, $8a, $8a, $8a, $8a, $8a, $8a, $8a, $8c, $8a, $8c, $8c, $8f, $8f, $92, $7c, $6c, $74, $75, $75, $7e, $79, $a0, $9f, $7e, $a0, $78, $9e, $9e, $9e, $9d, $c4, $c5, $d2, $c5, $e5, $e2, $d7, $e4, $f2, $2c, $e6, $86, $86, $5b, $86, $5b, $8b, $5d, $5b, $5d, $5d, $5d, $5d, $5e, $5b, $59, $5d, $5e, $60, $5f, $62, $5f, $62, $62, $64, $95, $66, $62, $60, $62, $5d, $5d, $5b, $5b, $5b, $5b, $86
  .byte  $b4, $b5, $b2, $96, $b0, $96, $b2, $96, $b5, $96, $96, $96, $96, $96, $93, $92, $92, $92, $92, $91, $91, $8d, $8d, $8a, $8d, $8a, $8d, $8a, $8d, $8a, $8d, $8a, $8c, $8c, $8f, $92, $78, $6c, $75, $75, $7b, $79, $7b, $a0, $7b, $a0, $9e, $a0, $9e, $9e, $9e, $9b, $9b, $9d, $9d, $9b, $d0, $c2, $e9, $eb, $eb, $ea, $e2, $e5, $82, $86, $8b, $5b, $86, $8b, $8b, $8b, $5d, $5d, $5d, $5d, $5d, $5e, $5d, $5e, $62, $62, $64, $62, $62, $60, $62, $90, $62, $90, $5d, $90, $5d, $5d, $5d, $89, $5d, $5b, $89, $5d
  .byte  $9a, $b5, $b5, $b5, $b5, $96, $b5, $96, $b5, $96, $9a, $96, $96, $96, $93, $96, $92, $92, $91, $91, $91, $8d, $8d, $8d, $8a, $8d, $8a, $8a, $8d, $8a, $8c, $8c, $8c, $8a, $92, $78, $6d, $75, $78, $79, $75, $9f, $9f, $7d, $7e, $a0, $9f, $9e, $a0, $9e, $9e, $9e, $9e, $9b, $c1, $c1, $c4, $d1, $d1, $ef, $ec, $ea, $eb, $ee, $85, $86, $8b, $88, $8b, $8b, $8e, $8b, $8b, $5d, $8e, $5d, $5d, $5d, $5f, $5d, $62, $62, $62, $5d, $90, $8e, $8b, $90, $90, $5d, $8b, $8b, $89, $86, $a5, $86, $a5, $84, $86, $84
  .byte  $b6, $b5, $b5, $b5, $b5, $b5, $b5, $b5, $b5, $9a, $b5, $9a, $96, $96, $96, $92, $92, $92, $92, $91, $91, $91, $8d, $8d, $a9, $8d, $a9, $a9, $a9, $a9, $a9, $a9, $8c, $ae, $7e, $71, $75, $75, $78, $76, $7f, $a0, $7e, $a1, $9f, $a0, $a1, $a0, $9e, $9d, $9d, $9e, $c3, $c2, $c3, $c4, $d1, $c3, $cf, $d9, $f2, $ee, $ea, $e7, $19, $8c, $90, $8b, $8b, $8b, $8e, $8b, $8e, $8b, $89, $5d, $8e, $5b, $89, $5d, $5d, $5d, $5d, $5d, $86, $86, $a5, $86, $89, $88, $89, $86, $a5, $89, $89, $89, $84, $84, $84, $84
  .byte  $b5, $b9, $b5, $98, $b5, $b5, $98, $b5, $9a, $b5, $9a, $9a, $b5, $b5, $96, $93, $96, $92, $92, $92, $92, $91, $8d, $8d, $a9, $a9, $8c, $a9, $a9, $a9, $aa, $aa, $ae, $81, $70, $70, $74, $7b, $7e, $9f, $7d, $7e, $7e, $81, $7e, $a1, $7e, $9f, $9e, $9e, $c3, $a0, $c5, $9d, $c4, $c4, $9d, $c5, $c4, $c4, $de, $e6, $ec, $ea, $e7, $8a, $8f, $8f, $8e, $a8, $a8, $8e, $89, $89, $89, $89, $1d, $89, $19, $89, $86, $89, $5b, $a5, $86, $a5, $86, $8e, $8e, $8e, $a8, $8e, $89, $89, $a5, $a5, $84, $a4, $84, $a4
  .byte  $b9, $98, $b5, $98, $b5, $98, $b2, $98, $b5, $9a, $9a, $98, $9a, $96, $96, $93, $93, $93, $92, $92, $91, $91, $91, $8c, $a9, $a9, $aa, $a9, $aa, $a9, $aa, $ae, $8a, $70, $75, $76, $79, $7b, $7b, $7e, $81, $a3, $81, $a1, $81, $9f, $a0, $9f, $a1, $a0, $c6, $c6, $c5, $c6, $c6, $c6, $c4, $9c, $c2, $c6, $de, $f2, $f0, $e9, $e7, $f6, $8c, $c7, $8f, $a7, $8e, $a6, $8e, $89, $89, $89, $89, $89, $89, $86, $89, $89, $89, $89, $89, $89, $89, $89, $8b, $89, $89, $a5, $a4, $a5, $a5, $a4, $a4, $a4, $a4, $a4
  .byte  $b6, $98, $b4, $98, $b5, $b4, $b5, $98, $98, $98, $98, $98, $98, $98, $98, $93, $93, $93, $92, $92, $92, $92, $aa, $a9, $aa, $a9, $aa, $91, $ae, $91, $ae, $ae, $75, $71, $79, $79, $7d, $7c, $a0, $7e, $a3, $81, $7e, $a1, $a0, $c6, $a1, $c6, $a0, $a1, $a1, $a1, $c6, $c6, $c6, $c6, $78, $c4, $f7, $cf, $c7, $e6, $e9, $ec, $ee, $e7, $aa, $a8, $a8, $a8, $a8, $a8, $a7, $a7, $89, $a5, $89, $a5, $89, $a5, $89, $a5, $a5, $84, $84, $84, $84, $a5, $a6, $89, $a6, $a6, $a5, $a6, $a6, $a6, $a5, $a6, $a6, $a6
  .byte  $98, $b6, $98, $b5, $98, $b4, $98, $98, $98, $98, $9a, $99, $98, $98, $94, $98, $94, $93, $93, $93, $92, $ad, $92, $8c, $aa, $aa, $aa, $aa, $aa, $aa, $ae, $7b, $71, $75, $75, $9f, $7b, $a1, $7c, $a1, $7c, $a0, $a0, $a3, $a1, $a3, $a1, $a1, $a1, $c6, $a1, $c6, $a3, $c2, $71, $6c, $68, $68, $01, $cb, $10, $17, $e9, $ec, $ec, $e9, $e8, $ac, $a8, $a8, $c7, $a7, $a7, $a7, $a7, $a7, $a5, $89, $84, $a5, $a5, $a5, $a5, $a5, $84, $a4, $84, $a6, $89, $a6, $89, $a6, $a6, $a6, $a6, $a7, $a6, $a7, $a8, $a7
  .byte  $99, $b9, $b6, $98, $b4, $98, $98, $98, $b9, $98, $99, $98, $98, $97, $98, $94, $94, $94, $94, $93, $90, $92, $8f, $8c, $aa, $aa, $aa, $aa, $ad, $ae, $88, $6d, $6d, $6d, $75, $c1, $75, $9f, $a1, $a0, $a1, $7f, $a1, $a1, $a3, $a3, $a1, $a1, $a1, $a3, $a3, $a3, $c6, $74, $68, $34, $33, $38, $f8, $f9, $4a, $51, $ee, $e9, $ee, $ef, $f6, $ac, $ab, $a8, $ab, $a8, $c7, $a8, $c7, $a7, $a7, $a5, $89, $a5, $a5, $a5, $a5, $a5, $a5, $a5, $a5, $a5, $a6, $a6, $a6, $a6, $89, $a7, $c7, $c7, $ab, $a8, $ab, $a8
  .byte  $ba, $b9, $b6, $b6, $98, $b6, $b6, $99, $b9, $99, $ba, $99, $99, $98, $97, $94, $98, $94, $93, $94, $b0, $ad, $ac, $ad, $a8, $ad, $a8, $aa, $ab, $b0, $6d, $6c, $c1, $c1, $9b, $9b, $9f, $9d, $a0, $a1, $81, $a3, $a2, $a0, $a3, $a1, $a3, $a3, $a3, $a1, $74, $c2, $a1, $74, $6e, $68, $34, $3f, $0a, $f3, $4a, $48, $ee, $ed, $ec, $f0, $e9, $a8, $ab, $ab, $c7, $ab, $ab, $c7, $c7, $c7, $c7, $a7, $a6, $a6, $a6, $a5, $a6, $a6, $a6, $a4, $a6, $a6, $a8, $c7, $c7, $c7, $c7, $a8, $c7, $c7, $ab, $ab, $ab, $a8
  .byte  $99, $b9, $b9, $b6, $b6, $b9, $99, $b9, $99, $ba, $99, $99, $99, $97, $97, $97, $94, $94, $94, $94, $b0, $60, $ad, $a8, $aa, $ab, $aa, $ab, $b0, $a0, $c0, $c0, $c1, $9b, $9b, $9b, $a1, $9d, $9d, $c6, $a0, $a3, $a1, $a3, $a3, $a3, $a3, $a1, $a3, $9c, $c1, $68, $68, $68, $03, $34, $68, $39, $39, $f3, $4b, $48, $51, $f0, $ef, $ee, $f6, $c7, $b1, $ab, $af, $ab, $af, $ab, $ab, $c7, $c7, $a7, $a7, $a7, $a6, $a6, $a6, $a7, $a7, $a7, $a7, $a8, $c7, $a8, $a8, $a8, $a8, $c7, $c7, $ab, $af, $c7, $a8, $a6
  .byte  $b8, $99, $b8, $99, $b8, $97, $99, $99, $99, $b7, $99, $97, $97, $97, $97, $94, $94, $94, $94, $94, $94, $af, $90, $ac, $90, $ab, $a8, $ab, $a8, $c0, $c1, $c1, $9b, $c5, $c3, $9c, $c4, $9d, $c4, $a1, $c6, $a3, $a4, $a1, $a4, $a3, $a3, $a4, $a3, $9c, $72, $68, $33, $33, $34, $35, $34, $36, $35, $33, $39, $45, $4e, $f0, $ee, $ed, $f6, $c7, $af, $b1, $af, $af, $af, $af, $ab, $c7, $ab, $c7, $c7, $c7, $a7, $a7, $a7, $a8, $a7, $a6, $a6, $a6, $a7, $c7, $c7, $c7, $af, $c7, $af, $c7, $c7, $a8, $a7, $a6
  .byte  $b8, $99, $b8, $b6, $99, $99, $99, $99, $99, $99, $99, $97, $99, $97, $97, $97, $66, $95, $94, $94, $94, $94, $af, $90, $ab, $a8, $ac, $b3, $c0, $ca, $c1, $9b, $c2, $78, $74, $78, $78, $a1, $a2, $a3, $a3, $a8, $a3, $a4, $a4, $a1, $84, $a1, $78, $71, $68, $33, $38, $38, $39, $3d, $3b, $36, $35, $33, $34, $3c, $49, $f0, $ee, $ed, $1d, $b1, $c8, $c8, $c8, $c8, $af, $c8, $af, $ab, $c7, $c7, $c7, $c7, $a7, $a7, $a6, $a7, $a7, $a7, $a7, $c7, $c7, $c7, $af, $c7, $c7, $c7, $c7, $c7, $c7, $a8, $a6, $a6
  .byte  $99, $b8, $99, $99, $b3, $99, $97, $99, $97, $99, $b7, $99, $97, $97, $97, $95, $97, $94, $95, $95, $94, $af, $60, $af, $62, $ac, $95, $c4, $c0, $c0, $c1, $c2, $75, $7a, $4c, $a3, $a4, $84, $a1, $a4, $a7, $ab, $a4, $a7, $a4, $a2, $7c, $78, $43, $38, $34, $34, $34, $34, $35, $3f, $42, $3b, $3b, $36, $3c, $3a, $3c, $21, $f0, $ed, $1d, $b1, $c8, $c8, $c8, $af, $c8, $af, $af, $ab, $c7, $c7, $c7, $c7, $c7, $c7, $a7, $c7, $a7, $a7, $c7, $a7, $c7, $c7, $c7, $c7, $c7, $a6, $a7, $a6, $a6, $a5, $a6, $a4
  .byte  $99, $b8, $99, $b8, $97, $b3, $99, $97, $b7, $99, $99, $97, $97, $99, $97, $97, $97, $95, $97, $95, $94, $94, $62, $af, $8e, $af, $af, $c0, $cc, $cc, $74, $7a, $7c, $a3, $a2, $7f, $a2, $7c, $a5, $a5, $84, $a4, $a3, $a6, $a5, $a2, $7a, $71, $43, $38, $38, $39, $39, $39, $3d, $3b, $42, $42, $3b, $3a, $3c, $3a, $3a, $51, $e5, $ed, $ac, $c8, $c8, $c8, $c8, $c8, $af, $c8, $c8, $af, $af, $af, $ab, $c7, $c7, $c7, $a7, $c7, $a7, $a7, $a7, $a7, $a7, $a7, $a8, $a7, $a6, $a6, $a5, $a6, $a5, $a4, $a4, $a2
  .byte  $ba, $b8, $b8, $b8, $99, $97, $99, $97, $99, $99, $b7, $99, $99, $99, $97, $97, $97, $97, $95, $97, $95, $95, $95, $af, $62, $97, $c1, $cc, $cc, $74, $7e, $a1, $a2, $a2, $4c, $a2, $80, $89, $84, $57, $a4, $a4, $a6, $a6, $a6, $a4, $7f, $71, $35, $35, $36, $35, $3b, $3b, $3b, $42, $42, $3c, $3c, $41, $3c, $37, $3a, $4e, $f2, $ed, $b0, $b3, $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8, $ab, $c7, $c7, $c7, $a7, $a7, $a7, $a6, $a7, $a6, $a7, $a6, $a6, $a5, $a6, $84, $a4, $a4, $a2, $a2, $80, $7f
  .byte  $f1, $b8, $b8, $b8, $99, $b3, $97, $99, $b7, $99, $99, $99, $99, $99, $b7, $99, $97, $97, $97, $97, $97, $95, $66, $af, $64, $c5, $ca, $cf, $4c, $a2, $a2, $a2, $a2, $a2, $a4, $80, $a2, $55, $84, $89, $a7, $a7, $aa, $a7, $ac, $af, $80, $38, $35, $35, $36, $35, $37, $37, $3a, $3a, $3c, $3c, $3c, $3c, $3a, $3c, $3a, $46, $f2, $ab, $b1, $b3, $c8, $c8, $c8, $c8, $c8, $b3, $c8, $c8, $c8, $c8, $af, $ab, $c7, $c7, $c7, $a7, $c7, $a7, $a7, $a6, $a6, $a5, $a4, $84, $a3, $a2, $a2, $7f, $7f, $7c, $7f, $7c
  .byte  $ba, $ba, $b8, $b8, $99, $b3, $97, $97, $97, $99, $99, $99, $99, $99, $97, $97, $97, $95, $97, $95, $97, $95, $95, $62, $af, $ca, $f9, $7c, $7a, $7c, $a2, $a2, $83, $a2, $55, $84, $86, $8e, $8e, $62, $8e, $ab, $ab, $b1, $b8, $7a, $35, $39, $35, $35, $36, $37, $37, $37, $3a, $3c, $3c, $3a, $41, $3c, $3c, $41, $3c, $45, $f1, $af, $b1, $b3, $c8, $b3, $c8, $b3, $b3, $b3, $b3, $c8, $b3, $c8, $c8, $af, $ab, $c7, $ab, $ab, $c7, $a8, $a7, $a4, $a4, $a4, $a3, $a2, $a2, $a1, $7c, $a1, $7f, $7c, $7c, $7b
  .byte  $e3, $ba, $b8, $b8, $b6, $b8, $b8, $b3, $b8, $99, $ba, $99, $99, $99, $99, $99, $99, $99, $97, $99, $99, $99, $95, $97, $cc, $f9, $7b, $7c, $a2, $a4, $a5, $55, $7f, $84, $84, $8e, $8e, $8e, $90, $5d, $60, $c8, $ba, $e3, $4d, $71, $3d, $35, $35, $36, $37, $37, $37, $3a, $3a, $3a, $3a, $3c, $41, $41, $41, $41, $3c, $48, $b3, $b0, $b3, $b3, $b3, $c8, $b3, $b3, $b3, $b8, $b8, $b3, $b3, $b3, $c8, $b1, $af, $ab, $ab, $a8, $a7, $a6, $a4, $a4, $a2, $a2, $7c, $7c, $7c, $7c, $7c, $7c, $7c, $7b, $7b, $7b
  .byte  $ba, $ba, $b8, $b9, $b8, $b8, $99, $99, $b8, $b6, $99, $b9, $99, $99, $99, $99, $99, $97, $b6, $99, $99, $99, $99, $e8, $f4, $7e, $a2, $89, $89, $84, $84, $84, $8e, $c7, $8e, $8e, $90, $5f, $60, $66, $fe, $fe, $60, $47, $6b, $36, $36, $36, $3a, $37, $37, $3a, $37, $3a, $3a, $3c, $3c, $41, $45, $41, $45, $41, $3c, $52, $b4, $b1, $b3, $b3, $b6, $b3, $b3, $b8, $b8, $b6, $b8, $b3, $b8, $b3, $b3, $b1, $ab, $ab, $a8, $a8, $a6, $a4, $a2, $a2, $7f, $7f, $7c, $7c, $7c, $7e, $7c, $7e, $7e, $7e, $7c, $7b
  .byte  $ba, $e3, $ba, $b8, $b8, $b8, $b8, $99, $b6, $99, $b9, $99, $98, $99, $99, $99, $98, $99, $99, $99, $99, $ba, $fb, $72, $7a, $7f, $8e, $83, $a5, $89, $89, $ab, $8e, $8e, $8e, $5d, $62, $2b, $f2, $e6, $97, $4d, $40, $3e, $37, $37, $37, $3a, $37, $37, $37, $37, $3a, $3a, $3c, $3c, $41, $45, $41, $45, $41, $41, $41, $85, $b3, $b2, $b4, $b6, $b6, $b3, $b6, $b6, $b6, $b6, $b6, $b3, $b6, $b3, $b1, $ab, $a8, $a8, $a7, $88, $a4, $80, $80, $7f, $7c, $7c, $7c, $7c, $7c, $7c, $7c, $7e, $7c, $7d, $7b, $7a
  .byte  $ba, $ba, $b9, $b9, $b8, $b6, $b6, $b8, $b3, $99, $b6, $98, $99, $98, $97, $98, $97, $98, $99, $ba, $95, $fa, $a2, $8b, $a6, $90, $8e, $8e, $c7, $af, $c7, $5d, $af, $b7, $fe, $f2, $e6, $be, $c8, $7a, $73, $3e, $37, $37, $37, $3a, $37, $37, $3a, $3a, $3c, $3c, $41, $41, $41, $45, $45, $45, $45, $41, $41, $41, $46, $b4, $b2, $b1, $b4, $b4, $b6, $b6, $b3, $b8, $b6, $b6, $b8, $b6, $b3, $b1, $ab, $a8, $88, $a4, $83, $a4, $82, $7f, $7f, $7f, $7c, $7c, $7c, $7e, $7e, $7e, $7d, $7e, $7d, $7c, $7d, $7b
  .byte  $ba, $ba, $ba, $ba, $b9, $b6, $b6, $99, $b3, $b6, $98, $99, $98, $99, $99, $98, $99, $98, $b7, $55, $50, $89, $8b, $8b, $62, $8e, $c8, $95, $b7, $fe, $e5, $f2, $f2, $e5, $e4, $e1, $de, $c5, $74, $6f, $6b, $3e, $3a, $3e, $3a, $3a, $3a, $3a, $3c, $3c, $3c, $41, $42, $41, $45, $45, $41, $41, $41, $45, $41, $45, $85, $b2, $b1, $b1, $b2, $b3, $b4, $b3, $b6, $b6, $b8, $b6, $b3, $b3, $c8, $ac, $a8, $a4, $83, $84, $82, $83, $80, $80, $7f, $7f, $7f, $7c, $7f, $7b, $81, $7e, $7e, $7e, $7e, $7e, $81, $7d
  .byte  $ba, $ba, $ba, $b9, $b9, $b6, $b6, $b6, $b6, $98, $b6, $98, $98, $98, $98, $98, $98, $97, $1d, $e8, $50, $95, $95, $b7, $8e, $b7, $e5, $e2, $dc, $da, $da, $da, $d7, $d7, $da, $db, $d0, $c1, $74, $71, $40, $3e, $3e, $3a, $3c, $3a, $3c, $3c, $3c, $3c, $41, $3c, $41, $41, $45, $41, $45, $41, $46, $45, $45, $46, $b4, $b0, $b0, $b1, $b2, $b3, $98, $b3, $b4, $b8, $b6, $b6, $b6, $c8, $b0, $ab, $88, $83, $80, $80, $83, $80, $80, $80, $7f, $80, $7f, $7f, $7e, $81, $81, $81, $81, $81, $81, $81, $81, $81
  .byte  $bd, $ba, $ba, $ba, $ba, $b9, $b9, $98, $b9, $b6, $9a, $98, $9a, $9a, $98, $bb, $62, $f1, $fe, $f1, $b7, $b7, $f2, $f2, $e6, $e2, $d4, $d4, $d4, $d5, $d5, $d4, $d4, $d8, $d4, $d8, $d6, $c5, $c6, $71, $40, $3e, $3a, $3a, $3c, $41, $42, $42, $3c, $3c, $42, $41, $41, $41, $45, $45, $45, $46, $45, $46, $42, $ad, $b0, $ad, $b0, $b1, $b2, $b4, $b4, $b6, $b6, $b6, $b8, $b6, $b3, $b0, $c7, $8f, $a4, $82, $80, $a2, $80, $55, $80, $82, $82, $80, $80, $82, $81, $82, $81, $87, $81, $87, $87, $87, $81, $81
  .byte  $bd, $bd, $bd, $ba, $bd, $ba, $ba, $ba, $9a, $9a, $9a, $9a, $9a, $9a, $9a, $98, $98, $94, $b3, $98, $98, $f2, $f2, $e6, $df, $d5, $d4, $d4, $d5, $d5, $d5, $d5, $d5, $d8, $d5, $da, $d7, $de, $70, $38, $6b, $3a, $3e, $42, $42, $42, $42, $3c, $42, $42, $45, $42, $41, $41, $45, $46, $46, $46, $48, $48, $57, $96, $ac, $ae, $ac, $b0, $b0, $b4, $b9, $b5, $b9, $b6, $b9, $b6, $b1, $af, $8f, $a8, $85, $a5, $82, $82, $80, $7f, $80, $80, $83, $86, $85, $85, $87, $87, $8a, $8c, $aa, $a9, $8a, $8a, $8a, $8a
  .byte  $bd, $bd, $bd, $bd, $bc, $ba, $bb, $b9, $bb, $bb, $9a, $9a, $9a, $9a, $9a, $9a, $9a, $9a, $9a, $9a, $97, $f2, $e6, $e4, $d7, $d7, $d7, $d4, $d7, $d7, $d5, $d7, $db, $da, $d7, $da, $db, $cb, $33, $68, $3d, $40, $42, $3e, $42, $42, $42, $42, $44, $45, $44, $42, $45, $46, $46, $46, $45, $48, $52, $47, $b2, $b0, $ae, $b0, $b0, $b0, $b0, $b5, $b4, $b9, $b6, $b9, $b3, $b1, $a8, $8f, $a5, $88, $82, $83, $80, $80, $83, $80, $80, $82, $85, $88, $8f, $aa, $8f, $aa, $aa, $ae, $ae, $a8, $aa, $aa, $aa, $8c
  .byte  $bd, $bd, $bd, $bd, $ba, $bc, $ba, $bc, $b9, $bb, $bb, $bb, $9a, $bb, $9a, $9a, $9a, $98, $9a, $9a, $b3, $e6, $e5, $dc, $da, $da, $da, $dc, $dd, $d7, $dc, $df, $dc, $dc, $da, $df, $cf, $6a, $6a, $68, $3d, $3d, $40, $3e, $42, $44, $42, $46, $46, $44, $44, $45, $44, $46, $46, $46, $48, $4b, $4b, $ad, $b0, $b0, $b2, $b0, $b0, $b2, $b2, $b5, $b6, $b5, $b4, $b1, $ac, $a6, $88, $a6, $85, $83, $82, $80, $80, $82, $80, $83, $82, $88, $8f, $ad, $ad, $ad, $ad, $ad, $ad, $ad, $ad, $aa, $ad, $aa, $ac, $ad
  .byte  $be, $bd, $bd, $bd, $bd, $bd, $bc, $ba, $bc, $bb, $bb, $bb, $9a, $9a, $9a, $9a, $9a, $9a, $98, $9a, $e2, $e2, $dc, $d7, $da, $da, $dc, $df, $e1, $db, $df, $e2, $e2, $e8, $d9, $d9, $f4, $6a, $6a, $6e, $6a, $3d, $40, $42, $44, $44, $44, $46, $46, $46, $46, $46, $46, $46, $46, $48, $52, $52, $ac, $b0, $b0, $b2, $b2, $b2, $b2, $b2, $b2, $b5, $b2, $b0, $ac, $a8, $a6, $88, $a5, $88, $a4, $82, $80, $80, $7f, $80, $83, $88, $88, $ac, $b0, $ac, $b0, $b0, $b0, $ad, $b0, $b0, $b1, $b0, $b1, $b0, $b1, $ac
  .byte  $bd, $bd, $be, $bd, $bd, $bd, $bc, $bc, $bb, $bc, $bb, $bb, $bb, $bb, $9a, $9a, $9a, $9a, $9a, $e3, $df, $db, $dc, $dd, $df, $dc, $dd, $df, $e2, $e0, $e2, $e2, $fb, $f9, $55, $4c, $4a, $6e, $6e, $6e, $6e, $43, $44, $44, $46, $48, $48, $48, $48, $47, $46, $48, $48, $48, $4b, $52, $52, $ac, $ac, $b0, $b2, $b2, $b5, $b2, $b2, $b2, $b5, $b0, $ac, $a8, $a8, $88, $a6, $a6, $a8, $a6, $85, $a4, $80, $82, $a4, $88, $a8, $a8, $ac, $b0, $b1, $b2, $b1, $b2, $b1, $b2, $b3, $b2, $b3, $b1, $b3, $b1, $b1, $ac
  .byte  $be, $be, $bd, $bd, $bd, $bd, $bd, $bd, $bc, $bc, $bc, $bb, $bb, $bb, $bb, $9a, $9a, $9a, $b4, $e2, $db, $d8, $e0, $e1, $df, $dd, $df, $e2, $e4, $e4, $e3, $15, $4c, $19, $5a, $4c, $4a, $4a, $4a, $72, $43, $72, $47, $47, $4b, $52, $4b, $4b, $4b, $4b, $4b, $4b, $47, $52, $52, $56, $ab, $ac, $ab, $b0, $b0, $b2, $b2, $b2, $b2, $b2, $b0, $b0, $ac, $ad, $a8, $a6, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $88, $ac, $b1, $b0, $b1, $b2, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b3, $b2, $b3, $b1, $b1, $b1, $b1
  .byte  $be, $be, $be, $be, $bd, $be, $bd, $bd, $bd, $bd, $bc, $bc, $bc, $bb, $9a, $9a, $9a, $9a, $e0, $e4, $d6, $dd, $dd, $dd, $e1, $df, $de, $e2, $e4, $fc, $55, $19, $5e, $fc, $5b, $55, $4c, $4a, $4c, $4a, $4c, $4c, $4d, $53, $56, $56, $52, $52, $56, $56, $52, $52, $52, $56, $86, $ac, $ab, $aa, $ab, $ac, $b1, $b0, $b2, $b0, $b2, $b2, $b0, $b1, $ad, $ac, $a7, $a4, $82, $a4, $a4, $a4, $a4, $88, $a8, $a8, $b1, $c8, $b2, $c8, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b1, $b1, $c8, $b1, $c8, $b1
  .byte  $be, $be, $be, $be, $be, $bd, $be, $bd, $be, $bd, $bd, $bc, $bc, $bb, $bb, $9a, $9a, $af, $e2, $e3, $db, $dd, $dd, $df, $df, $e2, $e2, $e4, $5d, $19, $19, $19, $1d, $1d, $1d, $19, $fb, $55, $17, $55, $17, $5a, $5f, $65, $21, $21, $52, $58, $57, $54, $4d, $56, $56, $a8, $ab, $ac, $ab, $ac, $ac, $b0, $b0, $b2, $b2, $b2, $b4, $b2, $b0, $ac, $ac, $a8, $a8, $a5, $a4, $a4, $a4, $88, $a6, $a8, $af, $b1, $b2, $b3, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b3, $c8, $b3, $b3, $b2, $c8
  .byte  $bf, $be, $be, $be, $be, $be, $be, $be, $bd, $be, $bd, $bd, $bc, $bb, $bb, $9a, $9a, $e0, $ef, $e2, $db, $dc, $df, $dd, $de, $e2, $e4, $b1, $59, $2c, $1d, $1d, $1d, $1d, $1d, $e8, $55, $17, $19, $19, $19, $5f, $64, $64, $20, $1c, $1f, $5d, $59, $4c, $5c, $56, $aa, $ab, $ac, $ac, $b0, $ac, $b0, $b1, $b1, $b4, $b2, $b4, $b2, $b4, $b1, $b1, $ac, $ac, $a8, $a6, $a5, $a6, $a6, $a8, $ac, $b1, $b3, $b4, $b3, $b4, $b3, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b6, $b4, $b6, $b4, $b3, $b1, $c8, $b3, $b3, $b3
  .byte  $bf, $bf, $be, $be, $be, $be, $be, $be, $be, $be, $be, $be, $bc, $bb, $9a, $9a, $c8, $e0, $f2, $e2, $db, $dc, $e1, $e1, $dd, $e0, $b4, $8a, $86, $28, $aa, $8e, $1d, $1d, $5f, $1d, $19, $19, $19, $1d, $5f, $5f, $64, $66, $66, $21, $51, $16, $57, $60, $8f, $b0, $b1, $ac, $b0, $b1, $b1, $b0, $b1, $b0, $b4, $b2, $b4, $b5, $b6, $98, $b3, $b1, $af, $b1, $ab, $af, $a8, $ab, $b1, $b1, $b3, $b3, $b4, $b3, $b4, $b3, $b4, $b4, $b4, $b5, $b4, $b2, $b4, $b4, $b4, $b4, $b4, $b4, $b3, $b3, $b3, $b3, $b6, $b4
  .byte  $bf, $bf, $be, $be, $be, $be, $be, $be, $be, $be, $be, $bd, $bc, $bc, $bb, $b4, $e0, $f2, $e6, $e2, $db, $dd, $de, $de, $e0, $b3, $a9, $a9, $85, $25, $aa, $a9, $aa, $a8, $8e, $fc, $8e, $62, $62, $fc, $95, $66, $97, $66, $97, $94, $63, $51, $10, $af, $b2, $b1, $b1, $b1, $b1, $b1, $b2, $c8, $b2, $b4, $b4, $b6, $b4, $b9, $b4, $b9, $b6, $b6, $b4, $b6, $b1, $af, $b1, $b3, $b3, $b6, $b6, $b3, $b3, $b4, $b6, $b2, $b3, $b2, $b4, $b2, $b4, $b2, $b4, $b4, $b4, $b4, $b4, $b4, $b4, $b3, $b3, $b4, $b3, $b3
  .byte  $bf, $bf, $be, $be, $be, $be, $bd, $be, $be, $be, $be, $bf, $bd, $bc, $9a, $e0, $f2, $e6, $f2, $e0, $cf, $a7, $87, $a3, $a7, $a9, $a9, $a9, $85, $28, $8f, $a9, $a9, $a9, $8a, $87, $8a, $a8, $ad, $ac, $94, $95, $94, $94, $94, $b0, $b2, $99, $51, $0e, $c7, $b9, $b3, $b2, $b4, $b4, $b4, $b4, $b6, $b4, $b6, $b6, $9a, $b6, $ba, $b9, $ba, $b9, $b9, $b6, $b3, $b3, $b3, $b6, $b8, $b6, $b8, $b6, $b6, $b4, $b3, $b2, $b4, $b2, $b4, $b4, $b5, $b4, $98, $b4, $b5, $b4, $b4, $b4, $b6, $b4, $b3, $b6, $b4, $b4
  .byte  $bf, $bf, $bf, $be, $bf, $be, $be, $be, $be, $be, $bf, $be, $be, $bc, $b3, $f2, $e6, $f2, $e5, $e3, $ae, $91, $91, $a9, $91, $8a, $4c, $80, $87, $2f, $90, $a9, $a9, $a9, $a9, $8a, $8d, $8d, $8d, $a9, $a9, $a9, $aa, $ae, $b0, $b2, $9a, $3f, $0e, $51, $0e, $fb, $ba, $b4, $b6, $b4, $b4, $b4, $b6, $b6, $b9, $b9, $b9, $ba, $b9, $ba, $b9, $ba, $b9, $ba, $b6, $b6, $b8, $b9, $b8, $b9, $b9, $ba, $b9, $b9, $ba, $b9, $b9, $ba, $bb, $bb, $bb, $ba, $bb, $ba, $ba, $bd, $ba, $bd, $bd, $bd, $bd, $ba, $bd, $ba
  .byte  $bf, $bf, $bf, $be, $bf, $be, $be, $be, $be, $bf, $bf, $be, $be, $c8, $e5, $e6, $f2, $f1, $f2, $ae, $91, $8d, $91, $a9, $87, $49, $25, $28, $54, $2f, $2c, $a9, $a9, $a9, $a9, $8a, $8a, $a9, $a9, $91, $a9, $a9, $a9, $ae, $96, $b2, $b9, $3f, $21, $51, $51, $09, $12, $bc, $b9, $bb, $ba, $bb, $ba, $bc, $bd, $bc, $bd, $bc, $bd, $bd, $bd, $bd, $be, $ba, $f1, $e3, $e3, $e3, $e3, $fc, $1d, $fb, $f6, $fa, $f9, $f4, $f4, $f3, $f4, $f4, $f3, $f3, $f3, $f8, $f8, $f7, $f7, $f7, $07, $f8, $f8, $07, $f3, $f3
  .byte  $bf, $bf, $bf, $bf, $be, $be, $be, $be, $be, $be, $be, $be, $ba, $fe, $e6, $e6, $f2, $e6, $b5, $96, $91, $91, $91, $92, $4b, $1b, $2c, $31, $31, $2c, $31, $b0, $ae, $b0, $b2, $ba, $b9, $95, $ac, $8e, $89, $62, $fd, $fd, $fc, $fe, $f2, $54, $61, $1c, $0f, $51, $0e, $fa, $e8, $e8, $fb, $17, $fb, $fa, $fa, $f9, $12, $f5, $f5, $f5, $f9, $f4, $08, $07, $04, $03, $02, $01, $05, $03, $04, $03, $01, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32
  .byte  $e6, $e6, $e6, $bf, $e6, $bf, $e6, $e6, $e6, $e6, $e6, $bf, $e5, $e6, $f1, $ef, $fe, $8e, $50, $50, $19, $f6, $17, $fa, $10, $f3, $17, $fb, $f9, $f5, $fb, $1d, $b7, $2b, $f1, $fd, $19, $17, $19, $18, $15, $15, $0d, $08, $0a, $13, $15, $11, $0b, $08, $05, $f7, $05, $05, $03, $01, $01, $01, $01, $32, $32, $32, $32, $32, $32, $32, $32, $01, $01, $01, $01, $01, $32, $32, $32, $32, $32, $32, $32, $32, $32, $01, $01, $03, $f7, $07, $f7, $01, $32, $01, $32, $32, $32, $32, $32, $32, $32, $32, $32, $32
  .byte  $e8, $50, $fa, $f9, $f9, $0c, $f7, $02, $f7, $01, $32, $f5, $e6, $f9, $32, $f8, $01, $02, $01, $07, $08, $08, $f8, $01, $0c, $f4, $f3, $f3, $f5, $fa, $fa, $1d, $1d, $19, $19, $17, $fa, $12, $f5, $0c, $0d, $10, $f9, $13, $0d, $0b, $0a, $0a, $f9, $0d, $12, $0b, $05, $04, $04, $03, $04, $01, $01, $01, $32, $32, $01, $01, $02, $32, $02, $32, $32, $32, $32, $32, $32, $32, $01, $04, $02, $01, $32, $32, $01, $01, $03, $01, $01, $02, $01, $01, $02, $02, $05, $03, $0a, $05, $03, $04, $03, $01, $01, $01
  .byte  $02, $f7, $f7, $02, $01, $02, $02, $f7, $07, $02, $f9, $e6, $f4, $32, $02, $02, $f7, $f7, $02, $f8, $f8, $f3, $f4, $f8, $0c, $f4, $f4, $f9, $50, $fb, $fb, $fb, $fb, $12, $12, $f9, $12, $f9, $10, $08, $0c, $0c, $07, $04, $05, $05, $07, $11, $0d, $0b, $08, $0c, $01, $f7, $03, $01, $32, $03, $01, $01, $32, $01, $32, $01, $32, $01, $01, $01, $04, $04, $05, $05, $08, $07, $03, $04, $01, $32, $01, $01, $01, $01, $32, $32, $32, $32, $32, $01, $01, $01, $f8, $0c, $0d, $0a, $04, $05, $05, $0a, $05, $08
  .byte  $f7, $f7, $f8, $07, $f8, $f8, $f8, $f3, $f8, $f4, $e8, $f5, $02, $f8, $f7, $f3, $0c, $f9, $f4, $07, $f3, $0d, $f4, $f9, $f5, $fa, $f5, $fa, $fb, $fa, $19, $17, $fb, $17, $fa, $fa, $17, $16, $12, $0d, $12, $0b, $0c, $0a, $0c, $0a, $08, $03, $03, $03, $01, $03, $03, $03, $04, $f7, $03, $03, $04, $01, $03, $01, $03, $04, $03, $01, $01, $04, $01, $05, $05, $01, $01, $01, $01, $03, $01, $03, $04, $05, $04, $02, $03, $03, $01, $01, $03, $01, $01, $01, $01, $32, $32, $01, $01, $04, $01, $07, $08, $08
  .byte  $f8, $08, $f7, $02, $f7, $f8, $f8, $05, $f8, $f5, $f5, $07, $07, $03, $f7, $02, $02, $f7, $f8, $f8, $0d, $f3, $f9, $fa, $fa, $fa, $fb, $fb, $19, $19, $19, $17, $16, $17, $fa, $12, $15, $0d, $0b, $08, $0b, $0d, $0b, $08, $08, $0b, $06, $08, $0a, $0a, $08, $0b, $05, $07, $04, $04, $07, $05, $05, $03, $01, $04, $03, $04, $01, $04, $04, $05, $06, $05, $05, $04, $04, $05, $06, $05, $09, $05, $04, $05, $05, $05, $06, $09, $0b, $0a, $0b, $0a, $08, $08, $0a, $08, $07, $0a, $05, $03, $f7, $08, $07, $02
  .byte  $0c, $0c, $08, $07, $f3, $f8, $f7, $f3, $f9, $50, $07, $02, $07, $f3, $0a, $f3, $0c, $0d, $0c, $f9, $f9, $12, $fb, $1d, $fb, $fa, $19, $19, $15, $1d, $17, $53, $fb, $16, $16, $12, $15, $f9, $10, $10, $13, $10, $08, $10, $0d, $10, $0a, $0a, $08, $05, $0a, $0a, $05, $05, $07, $05, $08, $04, $0b, $0f, $0f, $09, $09, $09, $06, $06, $09, $03, $06, $06, $06, $06, $09, $09, $09, $0b, $09, $04, $0b, $0b, $09, $0b, $0f, $09, $0b, $13, $10, $11, $11, $11, $11, $11, $11, $10, $10, $0b, $0d, $0b, $0d, $0d
  .byte  $12, $fa, $f9, $0d, $0d, $0d, $f9, $17, $17, $fa, $0d, $12, $15, $f9, $10, $f9, $12, $12, $16, $15, $15, $19, $20, $fb, $fa, $fc, $1e, $1d, $18, $1d, $18, $fd, $5a, $17, $15, $17, $17, $16, $53, $16, $16, $15, $11, $16, $10, $15, $11, $10, $10, $13, $11, $11, $10, $13, $0f, $11, $13, $11, $0f, $0d, $0f, $11, $11, $10, $0f, $0f, $10, $0f, $09, $0b, $0f, $10, $11, $0f, $0f, $0f, $10, $0f, $10, $10, $14, $14, $11, $13, $16, $53, $14, $14, $16, $53, $53, $18, $20, $14, $14, $11, $13, $13, $16, $15
    
    
    
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"
    
    

    .org $fffa
    .word nmi
    .word reset
    .word irq
