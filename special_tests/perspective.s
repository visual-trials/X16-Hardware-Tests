
USE_CACHE_FOR_WRITING = 1

BACKGROUND_COLOR = 240  ; 240 = Purple in this palette
COLOR_TEXT  = $03       ; Background color = 0 (transparent), foreground color 3 (white in this palette)

TEXTURE_WIDTH = 64
TEXTURE_HEIGHT = 64

TOP_MARGIN = 12
LEFT_MARGIN = 16
VSPACING = 10

TEXTURE_VRAM_ADDRESS = $18000

DESTINATION_PICTURE_POS_X = 64
DESTINATION_PICTURE_POS_Y = 65


; Mode7 projection: 
;   https://www.coranac.com/tonc/text/mode7.htm
;   https://gamedev.stackexchange.com/questions/24957/doing-an-snes-mode-7-affine-transform-effect-in-pygame


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
VERA_ADDR_ZP_FROM         = $2A ; 2B ; 2C
VERA_ADDR_ZP_TO           = $2D ; 2E


; FIXME: these are leftovers of memory tests in the general hardware tester (needed by utils.s atm). We dont use them, but cant remove them right now
BANK_TESTING              = $32   
BAD_VALUE                 = $3A

CODE_ADDRESS              = $3D ; 3E


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
    jsr copy_pixels_to_high_vram
    
    ; Test speed of repetetion of texture draws
;    jsr test_speed_of_repetition
    
    ; Test speed of perspective style transformation
    jsr test_speed_of_perspective
    
  
loop:
  jmp loop

  
      ;  for y in range(64): print(128/(y+1))
  
; ====================================== PERSPECTIVE SPEED TEST ========================================
  
test_speed_of_perspective:

    jsr generate_copy_row_code

    jsr start_timer

    jsr perspective_bitmap_fast
    
    jsr stop_timer

    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #4
    sta CURSOR_Y

    lda #<perspective_192x64_8bpp_message
    sta TEXT_TO_PRINT
    lda #>perspective_192x64_8bpp_message
    sta TEXT_TO_PRINT + 1
    
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
    
    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #8
    sta CURSOR_X
    lda #26
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts
    


perspective_192x64_8bpp_message: 
    .asciiz "Perspective bitmap 192x64 (8bpp) "
one_byte_per_write_message: 
    .asciiz "Method: 1 byte per write"
four_bytes_per_write_message: 
    .asciiz "Method: 4 bytes per write"

    
; For perspective we need to set the x and y coordinate within the texture for each pixel row on the screen. 
; We also have to set the sub pixel increment for each pixel row on the screen.
; We generated this using the python script (see same folder) and put the data here.
    
x_in_texture_fraction_corrections:
    .byte 213,125,193,169,61,132,132,66,196,13,34,6,190,74,176,240,14,11,233,171,81,222,83,177,249,45,77,91,88,67,31,236,170,91,254,149,32,159,20,126,222,52,130,198,2,53,97,133,161,183,198,206,209,205,195,179,158,132,101,64,23,234,184,129
y_in_texture_fraction_corrections:
    .byte 37,203,13,242,133,202,200,132,4,76,95,66,248,131,231,39,67,63,28,221,131,15,131,224,39,90,122,135,130,109,72,20,210,130,37,187,70,197,57,162,2,88,164,232,35,86,130,165,193,215,229,237,239,235,225,209,187,161,129,93,51,5,211,156
addresses_in_texture_low:
    .byte 36,234,113,247,124,130,199,11,16,20,24,28,32,35,231,170,109,48,243,182,120,251,189,0,130,4,134,72,202,12,142,16,146,19,85,215,24,154,219,92,158,223,97,162,227,36,165,231,40,105,170,235,44,109,174,239,48,113,177,178,243,52,117,182
addresses_in_texture_high:
    .byte 9,10,12,13,15,0,1,3,4,5,6,7,8,9,9,10,11,12,12,13,14,14,15,0,0,1,1,2,2,3,3,4,4,5,5,5,6,6,6,7,7,7,8,8,8,9,9,9,10,10,10,10,11,11,11,11,12,12,12,12,12,13,13,13
x_sub_pixel_steps_low:
    .byte 249,234,219,206,193,181,169,158,148,138,129,120,111,103,95,88,81,74,67,61,55,49,43,38,32,27,23,18,13,9,5,0,252,248,245,241,237,234,231,227,224,221,218,215,212,210,207,204,202,199,197,194,192,190,188,186,183,181,179,177,175,174,172,170
x_sub_pixel_steps_high:
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
y_sub_pixel_steps_low:
    .byte 80,77,75,73,71,69,67,65,64,62,61,59,58,56,55,54,53,52,51,50,49,48,47,46,45,44,44,43,42,42,41,40,40,39,38,38,37,37,36,36,35,35,34,34,33,33,32,32,32,31,31,30,30,30,29,29,29,28,28,28,27,27,27,26
y_sub_pixel_steps_high:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    
    
; FIXME: we need to be able to use NEGATIVE values in the above table! For turning the other way around!
; FIXME: we need to be able to use NEGATIVE values in the above table! For turning the other way around!
; FIXME: we need to be able to use NEGATIVE values in the above table! For turning the other way around!
    
perspective_bitmap_fast:

    ; Setup FROM and TO VRAM addresses
    lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO
    lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO+1
    lda #<(TEXTURE_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM
    lda #>(TEXTURE_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM+1

    lda #(TEXTURE_VRAM_ADDRESS >> 9)
    sta VERA_L0_MAPBASE
    ; VERA_L0_CONFIG = 100 + 011 ; enable bitmap mode and color depth = 8bpp on layer 0
    ;                + 10100000 for 64x64 texture
    lda #%10100111
    sta VERA_L0_CONFIG
    
    ; Making sure the increment for ADDR0 is set correctly (which is used in affine mode by ADDR1)
    lda #%00000000           ; DCSEL=0, ADDRSEL=0, no affine helper
    sta VERA_CTRL
; FIXME: this is the *old* method of copying the incrementer!
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    
    ; Setting up for reading from a new line from a texture/bitmap
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    sta VERA_ADDR_BANK
    
    ; Entering *affine helper mode*: from now on ADDR1 will use two incrementers: the *current* one from ADDR0 (its settings are copied) and from itself
    lda #%00000101           ; Affine helper = 1, DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    ldx #0
    
perspective_copy_next_row_1:
    
    lda #%00000100           ; DCSEL=0, ADDRSEL=0, with affine helper
    sta VERA_CTRL

    .if (USE_CACHE_FOR_WRITING)
        lda #%00110110           ; Setting auto-increment value to 4 byte increment (=%0011) and wrpattern = 11b
        sta VERA_ADDR_BANK
    .else
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW
    
    ; We reset so both x and y sub pixels positions are reset to 128 
    lda #%00000101           ; DCSEL=0, ADDRSEL=1, with affine helper
    sta VERA_CTRL
    
; FIXME: Since loading *once* screws up my cache byte index, we need to load 3 times first!
    .if(USE_CACHE_FOR_WRITING)
    stz $9F29                ; X increment low
    stz $9F2A                ; X increment high (only 1 bit is used)
    stz $9F2B                ; Y increment low
    stz $9F2C                ; Y increment high (only 1 bit is used)
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    .endif
    
    ; We correct both x and y sub pixels positions to the correct starting value by setting the deltas 
; FIXME: we dont take into account whether we have a DECR set to 1 here!
    lda x_in_texture_fraction_corrections, x
    sta $9F29                ; X increment low
    lda #0
; FIXME: we dont take into account whether we have a DECR set to 1 here!
    ora #%00100100           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 001, X increment high = 00 (these two bits are already in a by the lda)
    sta $9F2A                ; X increment high
    lda y_in_texture_fraction_corrections, x
    sta $9F2B                ; Y increment low
    ora #%00100100           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 001, Y increment high = 00 (these two bits are already in a by the lda)
    sta $9F2C                ; Y increment high
    
    ; We read once from ADDR1 which adds the corrections
    lda VERA_DATA1
    
    ; We now set the actual increments
    lda x_sub_pixel_steps_low, x
    sta $9F29                ; X increment low
    lda x_sub_pixel_steps_high, x
; FIXME: we dont take into account whether we have a DECR set to 1 here!
    ora #%00100100           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 001, X increment high = 00 (these two bits are already in a by the lda)
    sta $9F2A                ; X increment high (only 1 bit is used)
    lda y_sub_pixel_steps_low, x
    sta $9F2B                ; Y increment low
    lda y_sub_pixel_steps_high, x
    ora #%00100100           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 001, Y increment high = 00 (these two bits are already in a by the lda)
    sta $9F2C                ; Y increment high (only 1 bit is used)
    
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    sta VERA_ADDR_BANK
    lda addresses_in_texture_high, x
; FIXME: HACK!
    ora #$80                 ; HACK: we have $18000 as base address, so we just set the high bit of the high byte
    sta VERA_ADDR_HIGH
    lda addresses_in_texture_low, x
    sta VERA_ADDR_LOW

    ; Copy three rows of 64 pixels (= 192 pixels)
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with 320
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(320)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(320)
    sta VERA_ADDR_ZP_TO+1

    inx
    cpx #TEXTURE_HEIGHT          ; we do 64 rows
    beq done_perspective_copy
    
    jmp perspective_copy_next_row_1
done_perspective_copy:
    
    ; Exiting affine helper mode
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts

  
; ====================================== REPETITIVE SPEED TEST ========================================
  
test_speed_of_repetition:

    jsr generate_copy_row_code

    jsr start_timer

    jsr repetitive_bitmap_fast
    
    jsr stop_timer

    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #4
    sta CURSOR_Y

    lda #<repetitive_192x64_8bpp_message
    sta TEXT_TO_PRINT
    lda #>repetitive_192x64_8bpp_message
    sta TEXT_TO_PRINT + 1
    
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
    
    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #8
    sta CURSOR_X
    lda #26
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts
    


repetitive_192x64_8bpp_message: 
    .asciiz "Repetitive bitmap 192x64 (8bpp) "

    


repetitive_bitmap_fast:

    ; Setup FROM and TO VRAM addresses
    lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO
    lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO+1
    lda #<(TEXTURE_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM
    lda #>(TEXTURE_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM+1

    lda #(TEXTURE_VRAM_ADDRESS >> 9)
    sta VERA_L0_MAPBASE
    ; VERA_L0_CONFIG = 100 + 011 ; enable bitmap mode and color depth = 8bpp on layer 0
    ;                + 10100000 for 64x64 texture
    lda #%10100111
    sta VERA_L0_CONFIG
    
    ; Making sure the increment for ADDR0 is set correctly (which is used in affine mode by ADDR1)
    lda #%00000000           ; DCSEL=0, ADDRSEL=0, no affine helper
    sta VERA_CTRL
; FIXME: this is the *old* method of copying the incrementer!
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    
    ; Setting up for reading from a new line from a texture/bitmap
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    sta VERA_ADDR_BANK
    
    ; Entering *affine helper mode*: from now on ADDR1 will use two incrementers: the *current* one from ADDR0 (its settings are copied) and from itself
    lda #%00000101           ; Affine helper = 1, DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #0                   ; X increment low
    sta $9F29
    lda #%00100101           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 001, X increment high = 01
; OLD way:    lda #01                  ; X increment high (only 1 bit is used)
    sta $9F2A
    lda #00
    sta $9F2B                ; Y increment low
    lda #%00100100           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 001, Y increment high = 00 
; OLD way:    lda #$20  ; NOTE: 2 = Enable repeat!!
    sta $9F2C                ; Y increment high

    ldx #0
    
repetitive_copy_next_row_1:
    lda #%00000100           ; DCSEL=0, ADDRSEL=0, with affine helper
    sta VERA_CTRL

    .if (USE_CACHE_FOR_WRITING)
        lda #%00110110           ; Setting auto-increment value to 4 byte increment (=%0011) and wrpattern = 11b
        sta VERA_ADDR_BANK
    .else
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW
    
    lda #%00000101           ; DCSEL=0, ADDRSEL=1, with affine helper
    sta VERA_CTRL
    
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    sta VERA_ADDR_BANK
    lda VERA_ADDR_ZP_FROM+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_FROM
    sta VERA_ADDR_LOW

    ; Copy one row of 64 pixels
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with 320
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(320)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(320)
    sta VERA_ADDR_ZP_TO+1

    ; We increment our VERA_ADDR_FROM with 64 if we should proceed to the next pixel row
    clc
    lda VERA_ADDR_ZP_FROM
    adc #<(64)
    sta VERA_ADDR_ZP_FROM
    lda VERA_ADDR_ZP_FROM+1
    adc #>(64)
    sta VERA_ADDR_ZP_FROM+1
    
    inx
    cpx #TEXTURE_HEIGHT          ; we do 64 rows
    bne repetitive_copy_next_row_1
    
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
        cpx #TEXTURE_WIDTH/4             ; 16*4 copy pixels written to VERA (due to diagonal)
    .else
        cpx #TEXTURE_WIDTH               ; 64 copy pixels written to VERA (due to diagonal)
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

    
copy_pixels_to_high_vram:  

    lda #<PIXELS
    sta DATA_PTR_ZP
    lda #>PIXELS
    sta DATA_PTR_ZP+1 

    ; For now copying to TEXTURE_VRAM_ADDRESS
    ; TODO: we are ASSUMING here that TEXTURE_VRAM_ADDRESS has its bit16 set to 1!!
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #<(TEXTURE_VRAM_ADDRESS)
    sta VERA_ADDR_LOW
    lda #>(TEXTURE_VRAM_ADDRESS)
    sta VERA_ADDR_HIGH
    
    ldx #0
next_pixel_row_high_vram:  

    ldy #0
next_horizontal_pixel_high_vram:
    lda (DATA_PTR_ZP),y

    sta VERA_DATA0

    iny
    cpy #TEXTURE_WIDTH
    bne next_horizontal_pixel_high_vram
    inx
    
    ; Adding TEXTURE_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #TEXTURE_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    cpx #TEXTURE_HEIGHT
    bne next_pixel_row_high_vram
    
    rts

    
    
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

  .byte $aa, $0a
  .byte $88, $08
  .byte $00, $00
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $ee, $0e
  .byte $ee, $0f
  .byte $ee, $0e
  .byte $dd, $0e
  .byte $dd, $0e
  .byte $dc, $0e
  .byte $cc, $0d
  .byte $66, $06
  .byte $56, $06
  .byte $55, $06
  .byte $ff, $0f
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $ff, $0f
  .byte $fe, $0f
  .byte $fd, $0f
  .byte $fe, $0f
  .byte $fd, $0f
  .byte $ed, $0f
  .byte $ee, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ee, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ec, $0e
  .byte $ec, $0e
  .byte $ed, $0e
  .byte $dd, $0f
  .byte $ec, $0e
  .byte $dc, $0f
  .byte $dd, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0d
  .byte $db, $0d
  .byte $cb, $0d
  .byte $cc, $0d
  .byte $cc, $0d
  .byte $cb, $0d
  .byte $cb, $0c
  .byte $ba, $0c
  .byte $ba, $0c
  .byte $bb, $0b
  .byte $ba, $0b
  .byte $55, $05
  .byte $34, $03
  .byte $34, $02
  .byte $ab, $0b
  .byte $44, $04
  .byte $44, $04
  .byte $34, $04
  .byte $34, $03
  .byte $34, $03
  .byte $33, $03
  .byte $34, $03
  .byte $33, $03
  .byte $33, $03
  .byte $33, $03
  .byte $33, $03
  .byte $23, $02
  .byte $23, $02
  .byte $11, $01
  .byte $ef, $0e
  .byte $ee, $0e
  .byte $dd, $0d
  .byte $55, $05
  .byte $45, $05
  .byte $45, $05
  .byte $45, $04
  .byte $44, $04
  .byte $44, $04
  .byte $44, $04
  .byte $44, $04
  .byte $34, $04
  .byte $34, $04
  .byte $34, $03
  .byte $ee, $0e
  .byte $de, $0e
  .byte $de, $0e
  .byte $de, $0e
  .byte $dd, $0e
  .byte $dd, $0d
  .byte $55, $06
  .byte $55, $06
  .byte $55, $05
  .byte $55, $05
  .byte $55, $05
  .byte $55, $05
  .byte $45, $05
  .byte $45, $05
  .byte $44, $05
  .byte $22, $02
  .byte $22, $02
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $4a, $07   ; The last few palette I copied from affine_helper.s / finch.s
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

  .byte $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $3e, $4a, $4a, $4a, $4e, $5d, $4a, $5b, $5b, $5b, $5b, $46, $5d, $47, $4b, $47, $5a, $47, $59, $5b, $49, $5c, $5c, $59, $57, $57, $5c, $45, $46, $5c, $5b, $57, $4f
  .byte $00, $20, $24, $25, $20, $1e, $1e, $1b, $06, $1b, $29, $29, $22, $1b, $1b, $1b, $1b, $1b, $1e, $29, $20, $25, $24, $24, $1e, $20, $1e, $04, $08, $1b, $1e, $02, $47, $47, $4c, $5d, $5d, $5c, $5d, $5c, $5a, $5c, $47, $47, $5d, $47, $5c, $5a, $5a, $5b, $4b, $47, $44, $57, $57, $6c, $58, $59, $5a, $5a, $5c, $46, $5d, $02
  .byte $00, $1e, $20, $20, $1d, $1e, $1b, $1c, $07, $04, $1e, $1e, $20, $1e, $1e, $1e, $20, $1b, $1b, $29, $1b, $24, $1b, $1b, $24, $1b, $1e, $21, $1b, $1e, $26, $02, $4a, $4a, $4d, $5d, $4a, $5d, $47, $5b, $46, $4c, $49, $5d, $4b, $4a, $5d, $4c, $47, $5a, $59, $59, $59, $5b, $5b, $59, $49, $46, $5b, $59, $49, $5c, $4b, $02
  .byte $00, $24, $20, $1e, $20, $1e, $1b, $1e, $06, $1c, $2a, $22, $22, $1b, $1b, $1b, $1e, $1b, $25, $1b, $24, $1e, $1e, $1b, $1e, $24, $22, $1c, $21, $04, $1e, $02, $4a, $4c, $4a, $47, $5c, $5c, $5c, $5c, $59, $5b, $47, $4c, $47, $5d, $5b, $5b, $57, $5a, $5a, $5a, $5b, $57, $59, $5b, $46, $5c, $44, $5a, $47, $5b, $5c, $02
  .byte $00, $20, $20, $24, $24, $1b, $1e, $24, $1e, $23, $2b, $07, $06, $2e, $0a, $19, $1f, $21, $1b, $1b, $1e, $1b, $1b, $1e, $04, $1f, $1b, $21, $1e, $22, $22, $02, $4b, $5d, $5d, $5d, $5c, $4c, $47, $5b, $47, $47, $47, $47, $5c, $47, $5c, $5b, $49, $5b, $5a, $59, $48, $5d, $44, $46, $5b, $5b, $69, $5a, $44, $46, $4c, $02
  .byte $00, $1b, $20, $25, $1e, $20, $24, $2d, $1e, $24, $1e, $1e, $1b, $1e, $1e, $22, $1e, $21, $04, $04, $1c, $03, $03, $03, $09, $1c, $14, $1e, $1e, $25, $20, $02, $5c, $5a, $4a, $5c, $5d, $47, $5c, $5b, $5d, $49, $47, $47, $47, $4a, $47, $47, $47, $5a, $5d, $5b, $5b, $59, $5c, $46, $5b, $57, $59, $5d, $43, $5d, $48, $02
  .byte $00, $1b, $30, $1b, $1d, $24, $25, $25, $24, $2c, $1e, $1b, $20, $25, $20, $1e, $1b, $1e, $1b, $1b, $22, $1c, $1b, $1b, $1b, $1b, $05, $1b, $1b, $22, $20, $02, $5d, $47, $4a, $5c, $5c, $5b, $59, $5b, $5b, $4a, $4c, $49, $4c, $4a, $4c, $4a, $5c, $49, $47, $44, $59, $43, $5c, $5c, $5a, $5b, $57, $5a, $44, $4b, $4c, $02
  .byte $00, $20, $2c, $20, $26, $24, $1d, $1e, $20, $20, $1b, $20, $20, $2d, $2c, $24, $15, $15, $1e, $1b, $2a, $1e, $2c, $1b, $1b, $1b, $1b, $1f, $1d, $1e, $24, $02, $4b, $4c, $49, $5a, $5a, $5b, $5b, $47, $5d, $47, $4c, $5d, $4d, $5d, $4d, $4d, $4e, $4b, $5c, $5c, $5d, $5c, $4b, $5a, $59, $5a, $43, $48, $4c, $4b, $49, $02
  .byte $00, $2d, $18, $1d, $1d, $13, $1d, $18, $20, $1e, $2c, $20, $26, $20, $20, $20, $12, $1b, $1b, $20, $25, $32, $1b, $1b, $18, $1b, $1b, $1b, $1b, $12, $1e, $02, $47, $5d, $57, $5c, $5a, $6c, $5a, $5b, $5c, $47, $4a, $4a, $4c, $4c, $4c, $4a, $5d, $4c, $47, $47, $5b, $5d, $5c, $57, $5b, $5c, $5b, $48, $4b, $4d, $5b, $02
  .byte $00, $15, $20, $24, $1b, $1b, $1b, $1b, $18, $20, $1e, $20, $1b, $20, $26, $24, $1d, $1b, $1b, $1e, $25, $25, $24, $20, $29, $1b, $26, $1b, $1b, $1b, $12, $02, $44, $49, $5b, $59, $5b, $5d, $5b, $47, $48, $4d, $5d, $5d, $4a, $5c, $5c, $4c, $47, $47, $5b, $5c, $5b, $5c, $5a, $59, $6c, $59, $5a, $4b, $4b, $4a, $5b, $02
  .byte $00, $1e, $24, $24, $24, $1b, $1b, $20, $1d, $25, $2c, $1d, $24, $18, $20, $1d, $15, $1d, $20, $20, $26, $29, $24, $29, $20, $20, $24, $1b, $1b, $20, $1b, $02, $57, $5a, $5b, $55, $5c, $5b, $5a, $4d, $47, $5c, $5b, $5c, $5c, $5d, $5c, $4c, $47, $47, $4a, $5c, $59, $47, $5a, $5a, $5a, $45, $46, $49, $5a, $5c, $5c, $02
  .byte $00, $24, $1d, $20, $20, $24, $24, $20, $24, $26, $20, $25, $20, $18, $1d, $20, $1d, $13, $24, $24, $20, $24, $26, $2d, $24, $1d, $24, $24, $29, $1e, $15, $02, $55, $55, $6c, $44, $4b, $5d, $5d, $48, $47, $4c, $5c, $4a, $4c, $5c, $4a, $47, $47, $47, $4a, $5b, $59, $59, $55, $5c, $5b, $59, $5a, $4b, $47, $5d, $4b, $02
  .byte $00, $1d, $26, $24, $25, $1d, $20, $1d, $24, $2c, $24, $1d, $20, $18, $1b, $18, $1b, $19, $1b, $25, $1d, $2c, $1e, $24, $29, $20, $26, $24, $20, $25, $24, $02, $57, $6a, $45, $49, $5a, $6c, $5d, $5b, $4c, $47, $5d, $47, $5b, $5b, $5c, $5b, $5c, $5d, $5d, $5a, $59, $57, $59, $43, $5b, $59, $44, $5d, $5c, $5d, $5b, $02
  .byte $00, $20, $25, $26, $26, $25, $20, $20, $24, $26, $26, $20, $1b, $1b, $1a, $13, $18, $15, $18, $1b, $29, $2c, $29, $30, $29, $1b, $24, $26, $20, $24, $24, $02, $56, $57, $59, $59, $59, $46, $5d, $44, $4a, $4b, $5d, $5b, $5b, $5a, $55, $6c, $5d, $5b, $57, $5b, $57, $5c, $5b, $5b, $43, $5b, $48, $5c, $44, $5d, $5b, $02
  .byte $00, $15, $20, $24, $20, $18, $1b, $1b, $20, $26, $24, $24, $20, $20, $13, $20, $20, $29, $1a, $25, $2c, $2d, $20, $2c, $24, $20, $20, $24, $1b, $20, $1e, $02, $55, $57, $43, $58, $45, $49, $59, $5b, $46, $4a, $57, $57, $6c, $55, $57, $59, $5a, $5c, $59, $57, $57, $5a, $5a, $5a, $59, $44, $5a, $5c, $57, $57, $59, $02
  .byte $00, $24, $24, $20, $18, $1b, $1b, $1b, $20, $26, $24, $25, $24, $20, $11, $20, $2d, $20, $1d, $14, $13, $29, $30, $24, $20, $20, $24, $24, $20, $1b, $1b, $02, $6c, $45, $5a, $44, $5a, $44, $59, $5b, $5a, $5a, $6b, $6b, $69, $59, $55, $55, $44, $6c, $57, $6b, $59, $55, $6c, $43, $5a, $5c, $43, $55, $59, $5a, $5a, $02
  .byte $00, $20, $20, $20, $1b, $1b, $1b, $1e, $24, $24, $25, $20, $1e, $19, $15, $24, $30, $20, $20, $26, $26, $29, $20, $14, $1d, $1b, $1b, $1b, $1e, $1b, $1b, $02, $42, $55, $42, $5a, $55, $43, $59, $46, $6c, $6b, $6c, $57, $68, $58, $68, $58, $59, $5a, $6c, $59, $55, $6a, $58, $59, $59, $59, $59, $57, $57, $43, $57, $02
  .byte $00, $1e, $1e, $1e, $1d, $14, $18, $15, $12, $12, $1a, $17, $12, $12, $20, $1b, $26, $1b, $1b, $1d, $29, $25, $29, $19, $20, $20, $24, $1b, $1b, $1f, $08, $02, $6c, $55, $5a, $45, $58, $55, $59, $6c, $6b, $6a, $59, $68, $68, $6a, $6c, $46, $59, $45, $5a, $43, $5a, $56, $44, $48, $45, $59, $5a, $44, $5a, $43, $43, $02
  .byte $00, $1e, $1b, $1b, $12, $20, $12, $15, $1a, $17, $20, $25, $1a, $20, $1b, $20, $13, $1b, $1b, $20, $24, $1e, $25, $24, $24, $1e, $22, $1e, $1e, $09, $1e, $02, $58, $43, $59, $55, $69, $57, $69, $6c, $68, $6b, $6c, $69, $6c, $56, $44, $45, $44, $43, $5a, $6c, $6c, $45, $59, $45, $57, $59, $6c, $57, $45, $5b, $57, $02
  .byte $00, $22, $1e, $14, $22, $1e, $24, $20, $25, $24, $1d, $1e, $18, $1b, $1b, $19, $1e, $1d, $1b, $1b, $20, $1b, $24, $25, $25, $20, $1e, $20, $22, $21, $1b, $02, $6c, $56, $56, $6c, $6c, $69, $67, $69, $67, $65, $54, $6a, $54, $56, $42, $48, $44, $6c, $57, $58, $43, $55, $57, $43, $6b, $6c, $43, $59, $6c, $44, $59, $02
  .byte $00, $1f, $14, $1e, $1c, $12, $14, $1e, $24, $20, $15, $1a, $15, $15, $13, $2d, $1b, $1b, $24, $18, $20, $1d, $20, $25, $29, $20, $20, $22, $24, $06, $1f, $02, $56, $43, $42, $59, $68, $55, $54, $67, $54, $67, $69, $42, $55, $59, $58, $45, $59, $57, $5a, $44, $55, $59, $43, $56, $59, $59, $58, $59, $46, $5a, $6c, $02
  .byte $00, $07, $51, $1e, $04, $1c, $28, $1f, $1b, $31, $1f, $1e, $1b, $1e, $1e, $1b, $1b, $1b, $1d, $1b, $18, $1b, $24, $25, $24, $25, $29, $26, $20, $1e, $1c, $02, $46, $56, $5a, $69, $55, $67, $55, $53, $68, $65, $54, $54, $55, $56, $6c, $42, $55, $44, $44, $6c, $57, $5a, $44, $59, $43, $48, $5b, $48, $59, $5a, $55, $02
  .byte $00, $1c, $1b, $1e, $1e, $22, $08, $06, $50, $5e, $05, $2b, $06, $1f, $08, $2a, $1b, $1b, $1b, $1b, $20, $20, $18, $1b, $20, $20, $24, $2c, $1e, $1e, $1e, $02, $43, $43, $43, $54, $6c, $6a, $68, $69, $66, $67, $54, $67, $42, $42, $42, $6c, $43, $59, $6b, $6b, $42, $43, $57, $45, $46, $45, $45, $5a, $5a, $55, $55, $02
  .byte $00, $51, $08, $1f, $1e, $1e, $24, $21, $09, $20, $62, $21, $3d, $1e, $1b, $0b, $1e, $1e, $1b, $1b, $20, $1b, $1d, $20, $24, $20, $29, $2c, $24, $20, $1b, $02, $43, $43, $44, $6c, $56, $69, $6c, $67, $53, $65, $54, $56, $55, $40, $56, $6c, $58, $6a, $58, $6a, $6c, $43, $44, $43, $46, $5a, $5a, $44, $57, $69, $57, $02
  .byte $00, $07, $09, $22, $1f, $08, $1e, $5f, $1e, $04, $27, $27, $30, $27, $04, $2f, $1e, $1b, $1b, $18, $20, $20, $1d, $1b, $18, $20, $20, $24, $1e, $18, $3c, $02, $59, $6a, $57, $6c, $67, $69, $64, $64, $53, $68, $56, $53, $42, $42, $6c, $56, $55, $43, $55, $43, $58, $42, $59, $46, $59, $59, $5a, $5a, $55, $69, $56, $02
  .byte $00, $21, $21, $1f, $08, $1c, $07, $09, $08, $1b, $1e, $23, $18, $1e, $29, $24, $05, $03, $09, $22, $24, $24, $1d, $1b, $1d, $1e, $1d, $20, $1b, $1c, $1f, $02, $69, $5a, $59, $65, $10, $0f, $68, $69, $54, $65, $66, $42, $55, $43, $58, $42, $6c, $56, $55, $42, $42, $42, $46, $59, $59, $59, $55, $6b, $67, $65, $6a, $02
  .byte $00, $1c, $07, $1f, $28, $1e, $1c, $23, $1c, $21, $1e, $1e, $1e, $1a, $22, $1b, $1c, $07, $23, $1e, $24, $13, $20, $20, $20, $24, $20, $20, $24, $1b, $27, $02, $45, $55, $68, $67, $69, $53, $56, $54, $68, $53, $54, $58, $55, $44, $59, $55, $55, $54, $6b, $58, $43, $55, $57, $69, $57, $55, $6a, $10, $68, $65, $66, $02
  .byte $00, $28, $52, $1f, $07, $1b, $50, $60, $23, $1e, $2c, $2c, $2e, $1b, $1b, $1e, $32, $09, $24, $24, $18, $1b, $1d, $1e, $24, $20, $25, $26, $20, $1b, $2b, $02, $55, $69, $68, $67, $58, $6a, $54, $67, $54, $53, $53, $42, $55, $56, $54, $68, $68, $53, $68, $56, $55, $6c, $6a, $10, $54, $69, $10, $6c, $69, $64, $67, $02
  .byte $00, $22, $07, $1c, $50, $1b, $1e, $28, $1e, $24, $2a, $18, $1b, $1b, $18, $1b, $24, $24, $25, $24, $20, $1a, $24, $24, $26, $29, $29, $20, $1e, $1e, $61, $02, $54, $69, $56, $55, $66, $54, $68, $66, $53, $10, $53, $53, $68, $56, $55, $56, $54, $67, $58, $54, $58, $53, $6b, $65, $69, $68, $53, $56, $10, $0f, $10, $02
  .byte $00, $5f, $1c, $08, $62, $0a, $23, $32, $2c, $1e, $1b, $25, $1e, $1d, $25, $32, $2d, $29, $2c, $2c, $24, $1d, $26, $24, $26, $29, $20, $1e, $20, $1e, $12, $02, $56, $67, $68, $55, $54, $68, $65, $64, $68, $66, $65, $68, $58, $54, $54, $56, $68, $56, $56, $43, $56, $54, $53, $54, $54, $67, $54, $68, $65, $0f, $68, $02
  .byte $00, $1b, $1e, $1e, $1e, $1e, $1e, $1e, $22, $20, $1e, $20, $1b, $1b, $24, $24, $24, $20, $1d, $24, $13, $26, $24, $25, $26, $25, $20, $1b, $24, $05, $1e, $02, $56, $64, $55, $69, $68, $65, $54, $53, $68, $66, $66, $64, $53, $68, $56, $54, $54, $54, $69, $55, $54, $55, $55, $65, $68, $66, $53, $54, $0e, $66, $0f, $02
  .byte $3e, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $6d, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
  .byte $44, $43, $55, $6c, $43, $44, $6c, $58, $56, $6c, $56, $43, $6c, $58, $43, $58, $43, $56, $6b, $54, $6c, $67, $64, $66, $64, $54, $42, $6c, $54, $55, $54, $6e, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $3e
  .byte $44, $58, $59, $56, $44, $3f, $44, $56, $44, $58, $55, $43, $45, $45, $58, $55, $42, $68, $6c, $43, $6a, $6b, $58, $56, $43, $3f, $46, $56, $54, $69, $53, $02, $00, $1f, $1b, $1f, $21, $1e, $24, $1e, $1b, $1e, $13, $1e, $1b, $24, $24, $12, $24, $24, $1e, $1b, $1e, $1b, $2a, $3b, $51, $1f, $1e, $5f, $05, $04, $13, $02
  .byte $44, $43, $43, $45, $44, $40, $59, $5a, $42, $6c, $45, $46, $48, $45, $44, $57, $55, $56, $58, $56, $54, $6b, $56, $44, $43, $45, $58, $55, $55, $54, $54, $02, $00, $1e, $19, $15, $1e, $20, $20, $1e, $1e, $13, $18, $1b, $11, $24, $20, $05, $24, $12, $1d, $1e, $1e, $24, $2e, $08, $22, $2a, $0b, $28, $08, $1b, $19, $02
  .byte $45, $42, $5a, $45, $46, $46, $47, $58, $5b, $45, $43, $44, $46, $46, $5a, $55, $56, $68, $59, $58, $6b, $43, $58, $45, $56, $56, $59, $58, $59, $55, $55, $02, $00, $24, $20, $1e, $1a, $1d, $1b, $1b, $1b, $13, $12, $1b, $22, $15, $29, $1b, $1d, $19, $1e, $20, $20, $24, $24, $63, $2a, $21, $38, $3a, $27, $17, $1e, $02
  .byte $42, $44, $42, $45, $59, $45, $44, $59, $5b, $43, $46, $44, $59, $44, $6b, $6c, $55, $42, $58, $42, $43, $42, $55, $56, $40, $45, $43, $44, $55, $55, $68, $02, $00, $20, $1d, $1b, $19, $1a, $1e, $11, $18, $15, $1b, $1b, $20, $25, $20, $1b, $13, $11, $20, $1e, $20, $25, $22, $22, $2e, $29, $1e, $2a, $29, $12, $1b, $02
  .byte $44, $42, $58, $5a, $57, $44, $6c, $59, $45, $45, $49, $5b, $46, $6c, $57, $55, $58, $58, $44, $44, $58, $43, $43, $48, $46, $59, $48, $59, $54, $6c, $55, $02, $00, $24, $25, $24, $20, $2c, $1f, $18, $18, $18, $13, $1b, $20, $1e, $1d, $15, $12, $12, $1e, $1d, $24, $24, $25, $24, $35, $1b, $1b, $1b, $1b, $1e, $1e, $02
  .byte $56, $44, $59, $58, $46, $59, $57, $58, $46, $5c, $57, $59, $57, $59, $59, $57, $6c, $58, $58, $44, $44, $5b, $58, $46, $5b, $45, $5a, $57, $42, $43, $56, $02, $00, $1d, $24, $26, $30, $20, $18, $1b, $1b, $1b, $18, $20, $1b, $20, $25, $14, $1d, $12, $1b, $1b, $20, $20, $24, $25, $22, $20, $25, $18, $1e, $20, $2c, $02
  .byte $6b, $58, $44, $57, $58, $6c, $45, $46, $46, $5d, $43, $5c, $46, $5a, $59, $43, $43, $59, $55, $5a, $6c, $43, $5a, $44, $46, $48, $5a, $45, $43, $43, $57, $02, $00, $1b, $1d, $20, $1d, $1d, $1a, $20, $1b, $1b, $1b, $24, $1a, $1e, $17, $1d, $12, $24, $20, $1e, $1d, $25, $24, $24, $20, $1e, $1e, $1e, $2c, $2c, $26, $02
  .byte $46, $46, $5a, $6c, $43, $59, $48, $44, $44, $48, $5d, $5d, $59, $57, $5a, $5b, $57, $57, $42, $45, $43, $44, $59, $44, $48, $5c, $59, $59, $5a, $55, $42, $02, $00, $1d, $20, $1d, $15, $1e, $1e, $20, $1d, $1b, $20, $20, $1b, $1d, $24, $20, $12, $1b, $1d, $1d, $1b, $24, $20, $1b, $1e, $20, $1d, $29, $26, $20, $25, $02
  .byte $44, $56, $55, $57, $6c, $45, $43, $43, $5c, $5c, $59, $5c, $5c, $6b, $57, $58, $59, $46, $5a, $43, $5a, $56, $59, $43, $5a, $57, $55, $59, $6c, $57, $68, $02, $00, $20, $20, $1d, $24, $1e, $1b, $1e, $20, $1e, $24, $18, $20, $20, $24, $15, $1d, $12, $1e, $1b, $1b, $20, $20, $1b, $1b, $1b, $24, $20, $34, $2c, $20, $02
  .byte $45, $42, $58, $44, $43, $5a, $59, $5a, $46, $47, $59, $47, $59, $5b, $5b, $46, $43, $45, $5a, $43, $55, $57, $57, $57, $5a, $57, $6c, $58, $57, $58, $69, $02, $00, $20, $24, $1e, $1d, $1e, $1e, $1b, $1b, $1e, $1b, $1b, $1b, $1d, $1d, $24, $12, $14, $24, $20, $20, $1d, $1e, $20, $24, $20, $24, $26, $24, $20, $2c, $02
  .byte $59, $43, $46, $42, $44, $59, $5a, $58, $45, $46, $44, $47, $5b, $57, $59, $46, $58, $5c, $57, $58, $57, $6c, $43, $58, $43, $55, $6b, $43, $43, $44, $58, $02, $00, $20, $24, $20, $1e, $1e, $1b, $1e, $15, $1b, $24, $24, $24, $20, $20, $20, $13, $1d, $20, $24, $25, $24, $1d, $20, $26, $24, $26, $26, $32, $20, $1e, $02
  .byte $58, $58, $43, $57, $5a, $58, $44, $57, $46, $4c, $5d, $5c, $57, $6c, $45, $57, $5c, $43, $59, $6a, $42, $55, $44, $59, $57, $55, $58, $42, $5a, $58, $6b, $02, $00, $24, $1d, $1d, $20, $1e, $1b, $18, $1b, $1d, $1d, $24, $26, $15, $14, $26, $1e, $24, $14, $25, $29, $25, $20, $20, $26, $29, $26, $20, $32, $1b, $1e, $02
  .byte $6c, $56, $43, $59, $59, $46, $43, $44, $48, $45, $5b, $5b, $5a, $49, $59, $5b, $5a, $48, $59, $5b, $6c, $43, $45, $5b, $44, $5b, $55, $5a, $56, $55, $6b, $02, $00, $20, $18, $20, $1b, $1e, $20, $1e, $20, $1d, $18, $1d, $20, $1d, $29, $24, $26, $20, $25, $14, $20, $24, $29, $26, $24, $24, $20, $2c, $20, $1b, $20, $02
  .byte $42, $45, $55, $42, $44, $5a, $43, $44, $5d, $44, $5b, $59, $5b, $57, $5a, $5b, $5c, $5c, $59, $43, $5a, $45, $57, $58, $57, $55, $59, $58, $57, $43, $6c, $02, $00, $29, $20, $20, $1e, $1b, $1b, $1d, $1e, $15, $24, $24, $26, $24, $29, $1a, $2c, $20, $24, $24, $1b, $2c, $25, $24, $24, $20, $1e, $20, $1b, $1b, $20, $02
  .byte $58, $6b, $59, $57, $43, $43, $6c, $45, $43, $59, $5b, $59, $55, $5c, $5b, $58, $6c, $5b, $5b, $59, $55, $69, $6b, $55, $56, $43, $59, $45, $56, $45, $58, $02, $00, $15, $20, $1b, $20, $1e, $1e, $1b, $18, $20, $25, $24, $20, $20, $26, $20, $24, $1d, $2c, $30, $24, $20, $1e, $26, $24, $24, $1d, $1e, $26, $1b, $20, $02
  .byte $6c, $42, $42, $42, $44, $58, $45, $46, $5b, $43, $5c, $5a, $44, $59, $43, $57, $59, $5a, $44, $57, $59, $55, $6b, $6c, $42, $59, $55, $56, $59, $57, $57, $02, $00, $1b, $1e, $1b, $20, $1b, $13, $1b, $15, $1b, $20, $20, $24, $25, $26, $1e, $20, $20, $1e, $24, $24, $1e, $20, $24, $1e, $1d, $22, $1e, $20, $1b, $20, $02
  .byte $58, $45, $44, $6c, $42, $46, $5b, $45, $59, $57, $46, $5b, $5a, $46, $44, $59, $57, $43, $46, $59, $5a, $58, $59, $43, $46, $56, $57, $58, $55, $59, $68, $02, $00, $24, $25, $1b, $14, $15, $1e, $1b, $18, $1e, $26, $25, $24, $1d, $20, $1b, $20, $20, $20, $24, $20, $1b, $1b, $24, $20, $2a, $23, $20, $1c, $1e, $24, $02
  .byte $6c, $58, $55, $43, $48, $5b, $45, $5a, $44, $45, $57, $46, $47, $44, $59, $5a, $5a, $43, $59, $5b, $6c, $57, $42, $5b, $67, $44, $57, $6c, $58, $55, $55, $02, $00, $1b, $1b, $1b, $1b, $1d, $1b, $18, $1b, $20, $20, $15, $14, $20, $20, $1b, $24, $26, $24, $20, $1b, $1d, $1e, $1b, $1e, $37, $22, $5e, $28, $1c, $33, $02
  .byte $55, $55, $59, $46, $44, $45, $5a, $4b, $57, $5a, $59, $40, $5d, $5a, $5c, $5c, $59, $44, $57, $58, $5a, $59, $57, $59, $6c, $57, $44, $58, $6b, $68, $55, $02, $00, $20, $22, $29, $24, $24, $20, $1e, $13, $16, $12, $20, $24, $20, $1e, $1d, $20, $24, $26, $25, $24, $1e, $1b, $20, $22, $31, $22, $27, $22, $41, $38, $02
  .byte $69, $54, $45, $45, $43, $44, $45, $5a, $59, $57, $44, $40, $5b, $5c, $46, $5c, $57, $57, $5c, $44, $43, $59, $58, $59, $6c, $42, $5a, $6a, $6b, $56, $6c, $02, $00, $1e, $1e, $24, $24, $2c, $20, $14, $1b, $24, $20, $1e, $20, $1d, $1b, $24, $24, $1d, $25, $26, $25, $20, $1e, $1e, $1f, $23, $60, $22, $0c, $37, $3c, $02
  .byte $6b, $42, $46, $48, $46, $48, $5a, $44, $47, $45, $47, $49, $5c, $5b, $59, $6c, $55, $55, $57, $6c, $6c, $6c, $43, $56, $57, $48, $56, $68, $6b, $55, $69, $02, $00, $1b, $20, $1e, $20, $25, $30, $29, $24, $25, $20, $20, $1b, $1b, $20, $1d, $1d, $24, $20, $24, $24, $1e, $20, $1b, $08, $03, $5e, $1e, $21, $61, $1c, $02
  .byte $42, $44, $45, $49, $48, $5b, $45, $49, $5c, $57, $46, $5b, $5d, $5b, $5c, $6c, $69, $57, $44, $6c, $5a, $6b, $59, $55, $59, $6c, $6c, $67, $6c, $58, $54, $02, $00, $1b, $1e, $22, $20, $1b, $24, $1b, $1b, $1b, $18, $1b, $20, $20, $1d, $17, $20, $20, $20, $26, $20, $1b, $1e, $21, $1e, $5e, $1e, $28, $1c, $0d, $1e, $02
  .byte $45, $4b, $43, $43, $57, $6c, $44, $46, $59, $49, $5a, $48, $59, $5b, $57, $6c, $6c, $57, $44, $59, $44, $6c, $6c, $56, $67, $55, $69, $69, $56, $58, $54, $02, $00, $20, $1e, $20, $1e, $20, $1d, $25, $19, $12, $15, $1b, $17, $17, $20, $14, $13, $1b, $1b, $20, $1d, $1b, $1b, $04, $5f, $06, $1e, $21, $1e, $36, $1c, $02
  .byte $42, $45, $46, $5a, $45, $5b, $44, $5a, $5a, $5c, $5b, $5a, $5d, $44, $5b, $57, $57, $43, $6b, $59, $58, $68, $55, $54, $56, $6c, $58, $56, $56, $53, $6c, $02, $00, $1b, $12, $18, $1b, $18, $15, $13, $24, $24, $20, $20, $20, $24, $20, $20, $14, $11, $18, $20, $18, $1b, $1b, $05, $21, $08, $1c, $1e, $05, $1f, $1e, $02
  .byte $57, $44, $57, $44, $46, $5c, $40, $47, $45, $49, $4b, $48, $4c, $4c, $5b, $57, $5a, $43, $54, $59, $59, $68, $6c, $59, $59, $69, $55, $53, $6b, $58, $6c, $02, $00, $20, $1b, $1b, $1a, $1b, $1b, $18, $20, $29, $20, $20, $20, $20, $18, $1e, $1b, $1d, $1a, $1a, $1e, $1b, $20, $22, $1c, $1c, $04, $1c, $2f, $1b, $1e, $02
  .byte $44, $48, $48, $45, $46, $49, $5c, $46, $46, $47, $5d, $4a, $4b, $5d, $59, $5a, $57, $58, $57, $58, $57, $59, $43, $59, $54, $6c, $42, $58, $42, $58, $54, $02, $00, $1b, $1b, $20, $1b, $20, $24, $1b, $1e, $25, $20, $1b, $20, $24, $1d, $1b, $20, $26, $1e, $1b, $1d, $22, $1e, $1e, $04, $05, $08, $39, $37, $1e, $2a, $02
  .byte $40, $3f, $49, $5c, $47, $4c, $5b, $4a, $49, $5d, $5c, $5d, $5b, $5c, $6b, $5c, $5b, $5b, $58, $58, $5b, $56, $57, $58, $46, $59, $56, $69, $6a, $54, $55, $02, $00, $24, $20, $24, $24, $24, $20, $1b, $24, $29, $26, $20, $26, $20, $1e, $1b, $1d, $20, $20, $1d, $18, $24, $22, $22, $21, $1c, $0a, $27, $28, $0c, $06, $02
  .byte $44, $4c, $46, $46, $46, $49, $48, $5d, $49, $47, $5d, $5a, $6c, $59, $59, $45, $59, $55, $58, $42, $5a, $43, $43, $5a, $6c, $58, $54, $56, $43, $54, $6a, $02, $00, $25, $24, $25, $26, $24, $25, $29, $1a, $20, $24, $26, $24, $26, $20, $1b, $1e, $1b, $1e, $20, $12, $24, $24, $22, $5e, $1c, $04, $21, $22, $2e, $1e, $02
  .byte $46, $4b, $43, $5c, $5a, $4a, $5c, $47, $5b, $5a, $59, $59, $6c, $5a, $5a, $5c, $5a, $6c, $59, $57, $43, $59, $45, $45, $42, $55, $56, $56, $56, $44, $43, $02, $00, $24, $22, $24, $24, $20, $24, $1e, $24, $30, $20, $1d, $1d, $1d, $1b, $1d, $20, $20, $20, $24, $1d, $1a, $2b, $22, $22, $1e, $1b, $1e, $1e, $24, $22, $02
  .byte $45, $44, $5c, $5b, $44, $49, $47, $5b, $5d, $5a, $6c, $43, $5b, $44, $6c, $45, $6c, $6b, $44, $6c, $43, $59, $5b, $59, $59, $57, $45, $59, $58, $45, $43, $02, $00, $1e, $1b, $24, $1e, $1e, $1d, $20, $29, $26, $2d, $24, $20, $24, $20, $1b, $1b, $1b, $15, $1a, $15, $03, $16, $16, $24, $1e, $18, $1e, $1e, $25, $1e, $02
  .byte $4f, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $3e, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    
    
    
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"
    
    

    .org $fffa
    .word nmi
    .word reset
    .word irq
