
; This will generate a bitmap given a text string
; The size of the bitmap will be BITMAP_TEXT_LENGTH * 6 pixels wide by 5 pixels high
; Each of the 5 horizontal lines will be stored in a different bank.
; The address each line is stored is STORE_ADDRESS+1 + 256-(6*BITMAP_TEXT_LENGTH)
; The text input should start BITMAP_TEXT_TO_DRAW and be in ascii lower case. BITMAP_TEXT_LENGTH should be set appropiatly (zero-termination is ignored)

ascii_to_5x5_character_index:
; FIXME: implement this!
    rts


set_load_address_to_5x5_character_data:

    lda #<font_5x5_data
    sta LOAD_ADDRESS
    lda #>font_5x5_data
    sta LOAD_ADDRESS+1
    
    ; HACK: in order to multiply the character index by 25 (=5x5 bytes) we multiply by 16, by 8 and by 1 and add the results (16+8+1=25)
    lda CHARACTER_INDEX_TO_DRAW
    sta TMP1
    stz TMP2
    
    ; Adding CHARACTER_INDEX_TO_DRAW * 1
    clc
    lda LOAD_ADDRESS
    adc TMP1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc TMP2
    sta LOAD_ADDRESS+1
    
    ; CHARACTER_INDEX_TO_DRAW * 2
    asl TMP1
    rol TMP2  

    ; CHARACTER_INDEX_TO_DRAW * 4
    asl TMP1
    rol TMP2  
    
    ; CHARACTER_INDEX_TO_DRAW * 8
    asl TMP1
    rol TMP2
    
    ; Adding CHARACTER_INDEX_TO_DRAW * 8
    clc
    lda LOAD_ADDRESS
    adc TMP1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc TMP2
    sta LOAD_ADDRESS+1
    
    ; CHARACTER_INDEX_TO_DRAW * 16
    asl TMP1
    rol TMP2

    ; Adding CHARACTER_INDEX_TO_DRAW * 16
    clc
    lda LOAD_ADDRESS
    adc TMP1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc TMP2
    sta LOAD_ADDRESS+1

    rts


generate_one_5x5_character:
    
    ldx #0   ; x represents the line number of the character
generate_one_line_of_char:
    ldy #0   ; y represents the pixel number within the line of a character
generate_one_pixel_of_char:
    lda (LOAD_ADDRESS)
    bne char_pixel_color_ok
    lda #BACKGROUND_COLOR      ; If we see a 00, we want to replace it with the background color
char_pixel_color_ok:
    sta (STORE_ADDRESS), y
    
    ; We need to move to the next pixel to load
    clc
    lda LOAD_ADDRESS
    adc #1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    iny
    cpy #5
    bne generate_one_pixel_of_char
    
    ; We are one more empty pixel (whitespace)
    lda #BACKGROUND_COLOR
    sta (STORE_ADDRESS), y

    ; The next line to be store is in the next RAM_BANK
    inc RAM_BANK
    
    inx
    cpx #5
    bne generate_one_line_of_char
    
    rts


copy_vera_firmware_version:

    lda #%01111110           ; DCSEL=63, ADDRSEL=0
    sta VERA_CTRL
    
    ; Note we are skipping VERA_DC_VER0 here, since it must be 'V' when we reach this point
    
    clc
    lda VERA_DC_VER1
    adc #27          ; our 0 starts at character index 27
    sta end_of_vera_firmware_version_text-5
    
    clc
    lda VERA_DC_VER2
    adc #27          ; our 0 starts at character index 27
    sta end_of_vera_firmware_version_text-3
    
    clc
    lda VERA_DC_VER3
    adc #27          ; our 0 starts at character index 27
    sta end_of_vera_firmware_version_text-1

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    rts

copy_bitmap_to_banked_ram:

    lda #<BITMAP
    sta STORE_ADDRESS
    lda #>BITMAP
    sta STORE_ADDRESS+1
    
    ; Switching the the appropiate RAM_BANK
    lda BITMAP_RAM_BANK_START
    sta RAM_BANK

    lda BITMAP_TO_DRAW
    sta LOAD_ADDRESS
    lda BITMAP_TO_DRAW+1
    sta LOAD_ADDRESS+1

    ldx #0   ; x represents the y position in the bitmap
generate_one_line_of_bitmap:
    ldy #0   ; y represents the x position the horizontal line of a bitmap
generate_one_pixel_of_bitmap:
    lda (LOAD_ADDRESS)
    bne bitmap_pixel_color_ok
    lda #BACKGROUND_COLOR      ; If we see a 00, we want to replace it with the background color
bitmap_pixel_color_ok:
    sta (STORE_ADDRESS), y
    
    ; We need to move to the next pixel to load
    clc
    lda LOAD_ADDRESS
    adc #1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    iny
    cpy BITMAP_WIDTH_PIXELS
    bne generate_one_pixel_of_bitmap
    
    ; The next line to be store is in the next RAM_BANK
    inc RAM_BANK
    
    inx
    cpx BITMAP_HEIGHT_PIXELS
    bne generate_one_line_of_bitmap
    

; FIXME: restore the RAM_BANK properly?!
    lda #0
    sta RAM_BANK
    
    rts

generate_text_as_bitmap_in_banked_ram:    

    ; FIXME: we need to offset STORE_ADDRESS by 256 - 6*BITMAP_TEXT_LENGTH!
    lda #<BITMAP_TEXT
    sta STORE_ADDRESS
    lda #>BITMAP_TEXT
    sta STORE_ADDRESS+1

    ; We start at the first character of the string
; FIXME: use a different variable than TMP4 here!
    stz TMP4
    
generate_next_character:
    ; TODO: jsr ascii_to_5x5_character_index

; FIXME: use a different variable than TMP4 here!
    ldy TMP4  ; the index in the string
    lda (BITMAP_TEXT_TO_DRAW), y
    sta CHARACTER_INDEX_TO_DRAW

    jsr set_load_address_to_5x5_character_data
    
    ; Switching the the appropiate RAM_BANK
    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    jsr generate_one_5x5_character
    
    ; Moving to the next place to draw a character (6 pixels to the right: 5 for the character + 1 for whitespace)
    clc
    lda STORE_ADDRESS
    adc #6
    sta STORE_ADDRESS
    lda STORE_ADDRESS+1
    adc #0
    sta STORE_ADDRESS+1

; FIXME: use a different variable than TMP4 here!
    inc TMP4

    dec BITMAP_TEXT_LENGTH
    bne generate_next_character

; FIXME: restore the RAM_BANK properly?!
    lda #0
    sta RAM_BANK
    
    rts
    
    
; FIXME: use generated code to make this FASTER!!
draw_bitmap_text_to_screen:

; FIXME: SPEED this is setup each time this routine is called. 
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
 
;    lda #%01001000           ; cache write enabled = 1, 16bit hop = 1, addr1-mode = normal
;    sta VERA_FX_CTRL
    
; FIXME: SPEED this is setup each time this routine is called. 
    ; Setting ADDR0 + increment
    lda #%00010000           ; +1 increment
    .ifdef USE_DOUBLE_BUFFER
        ora FRAME_BUFFER_INDEX   ; contains 0 or 1
    .endif
    sta VERA_ADDR_BANK

    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    ; FIXME: we need to offset LOAD_ADDRESS by 256 - 6*BITMAP_TEXT_LENGTH!
    lda #<BITMAP_TEXT
    sta LOAD_ADDRESS
    lda #>BITMAP_TEXT
    sta LOAD_ADDRESS+1
    
    ldx #5
draw_bitmap_text_next_line:

    lda VRAM_ADDRESS
    sta VERA_ADDR_LOW
    lda VRAM_ADDRESS+1
    sta VERA_ADDR_HIGH
    
    ; We draw 6 pixels for each character
    ldy #0
draw_bitmap_text_next_character_line:
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    cpy BITMAP_TEXT_LENGTH_PIXELS
    bne draw_bitmap_text_next_character_line
    
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    
    inc RAM_BANK
    
    dex
    bne draw_bitmap_text_next_line

    rts
    
    
    .if(USE_POLYGON_FILLER_FOR_BITMAP)
    
draw_bitmap_to_screen_using_polygon_filler:

; FIXME: SPEED this is setup each time this routine is called. 
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    lda VRAM_ADDRESS
    sta VERA_ADDR_LOW
    lda VRAM_ADDRESS+1
    sta VERA_ADDR_HIGH
    lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
    ora VRAM_ADDRESS+2
    sta VERA_ADDR_BANK

    ; Entering *polygon fill mode* 
    lda #%00000010           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, polygon filler mode 
    sta VERA_FX_CTRL

    ; Setting all increments to 0
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL

    stz VERA_FX_X_INCR_L
    stz VERA_FX_X_INCR_H
    stz VERA_FX_Y_INCR_L
    stz VERA_FX_Y_INCR_H
    
    ; Setting the X-position
    
    lda #%00001001           ; DCSEL=4, ADDRSEL=1
    sta VERA_CTRL
    
    lda BITMAP_X_POS
    sta VERA_FX_X_POS_L      ; X (=X1) pixel position low [7:0]
    sta VERA_FX_Y_POS_L      ; Y (=X2) pixel position low [7:0]
    lda BITMAP_X_POS+1
    sta VERA_FX_X_POS_H      ; X subpixel position[0] = 0, X (=X1) pixel position high [10:8]
    sta VERA_FX_Y_POS_H      ; Y subpixel position[0] = 0, Y (=X2) pixel position high [10:8]

    ; Setting auto-increment value to 1 byte increment for ADDR1
    
    lda #%00010000           
    sta VERA_ADDR_BANK

    ; Setup source bitmap data
    
    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    lda #<BITMAP
    sta LOAD_ADDRESS
    lda #>BITMAP
    sta LOAD_ADDRESS+1
    
    ; Setup for drawing pixels
    
    lda #%00001011           ; DCSEL=5, ADDRSEL=1
    sta VERA_CTRL
    
    ; Draw rows of pixels
    
    ldx BITMAP_HEIGHT_PIXELS
draw_bitmap_next_line:
    
    lda VERA_DATA1          ; This will do three things (inside of VERA): 
                            ;   1) Increment the X1 and X2 positions.   -> they are 0, so nothing happens!
                            ;   2) Calculate the fill_length value (= x2 - x1) -> we are not using it!
                            ;   3) Set ADDR1 to ADDR0 + X1
                            
    ldy #0
draw_bitmap_next_pixel:
    lda (LOAD_ADDRESS),y
    sta VERA_DATA1
    iny
    cpy BITMAP_WIDTH_PIXELS
    bne draw_bitmap_next_pixel
    
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (= +1 vertically)
    
    inc RAM_BANK
    
    dex
    bne draw_bitmap_next_line

; FIXME: SPEED: can we remove this?
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting auto-increment value to 1 byte increment
    sta VERA_ADDR_BANK

    rts
    
    .else
    
draw_bitmap_to_screen:

; FIXME: SPEED this is setup each time this routine is called. 
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
 
;    lda #%01001000           ; cache write enabled = 1, 16bit hop = 1, addr1-mode = normal
;    sta VERA_FX_CTRL
    
; FIXME: SPEED this is setup each time this routine is called. 
    ; Setting ADDR0 + increment
    lda #%00010000           ; +1 increment
    .ifdef USE_DOUBLE_BUFFER
        ora FRAME_BUFFER_INDEX   ; contains 0 or 1
    .endif
    sta VERA_ADDR_BANK

    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    lda #<BITMAP
    sta LOAD_ADDRESS
    lda #>BITMAP
    sta LOAD_ADDRESS+1
    
    ldx BITMAP_HEIGHT_PIXELS
draw_bitmap_next_line:

    lda VRAM_ADDRESS
    sta VERA_ADDR_LOW
    lda VRAM_ADDRESS+1
    sta VERA_ADDR_HIGH

; FIXME: SPEED this is SLOW!    
; FIXME: SPEED this is SLOW!    
; FIXME: SPEED this is SLOW!    
    ldy #0
draw_bitmap_next_pixel:
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    cpy BITMAP_WIDTH_PIXELS
    bne draw_bitmap_next_pixel
    
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    
    inc RAM_BANK
    
    dex
    bne draw_bitmap_next_line

    rts
    
    .endif
    

draw_cursor_keys:

    ; -- UP key --

    lda #UP_KEY_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #UP_KEY_HEIGHT_PIXELS
    sta BITMAP_HEIGHT_PIXELS
    
    lda #UP_KEY_WIDTH_PIXELS
    sta BITMAP_WIDTH_PIXELS
    
    .if(USE_POLYGON_FILLER_FOR_BITMAP)
        lda #<(320*UP_KEY_Y_POS)
        sta VRAM_ADDRESS
        lda #>(320*UP_KEY_Y_POS)
        sta VRAM_ADDRESS+1
        lda #((320*UP_KEY_Y_POS)>>16)
        sta VRAM_ADDRESS+2
        
        lda #<UP_KEY_X_POS
        sta BITMAP_X_POS
        lda #>UP_KEY_X_POS
        sta BITMAP_X_POS+1
    
        jsr draw_bitmap_to_screen_using_polygon_filler
    .else
        lda #<(320*UP_KEY_Y_POS+UP_KEY_X_POS)
        sta VRAM_ADDRESS
        lda #>(320*UP_KEY_Y_POS+UP_KEY_X_POS)
        sta VRAM_ADDRESS+1
        
        jsr draw_bitmap_to_screen
    .endif

    ; -- LEFT, DOWN, RIGHT key --

    lda #LEFT_DOWN_RIGHT_KEY_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #LEFT_DOWN_RIGHT_KEY_HEIGHT_PIXELS
    sta BITMAP_HEIGHT_PIXELS
    
    lda #LEFT_DOWN_RIGHT_KEY_WIDTH_PIXELS
    sta BITMAP_WIDTH_PIXELS
    
    .if(USE_POLYGON_FILLER_FOR_BITMAP)
        lda #<(320*LEFT_DOWN_RIGHT_KEY_Y_POS)
        sta VRAM_ADDRESS
        lda #>(320*LEFT_DOWN_RIGHT_KEY_Y_POS)
        sta VRAM_ADDRESS+1
        lda #((320*LEFT_DOWN_RIGHT_KEY_Y_POS)>>16)
        sta VRAM_ADDRESS+2
        
        lda #<LEFT_DOWN_RIGHT_KEY_X_POS
        sta BITMAP_X_POS
        lda #>LEFT_DOWN_RIGHT_KEY_X_POS
        sta BITMAP_X_POS+1
    
        jsr draw_bitmap_to_screen_using_polygon_filler
    .else
        lda #<(320*LEFT_DOWN_RIGHT_KEY_Y_POS+LEFT_DOWN_RIGHT_KEY_X_POS)
        sta VRAM_ADDRESS
        lda #>(320*LEFT_DOWN_RIGHT_KEY_Y_POS+LEFT_DOWN_RIGHT_KEY_X_POS)
        sta VRAM_ADDRESS+1
        
        jsr draw_bitmap_to_screen
    .endif

    rts

    