
; FIXME: ISSUE: what if VERA says: draw 321 pixels? We will crash now...

; === Parameters that have to be set ===

; USE_POLYGON_FILLER = 0 or 1  ; This turns on the use of the 'polygon filler' addr1-mode in the FX Updated VERA
; USE_SLOPE_TABLES = 0 or 1    ; This turns on the use of slope tables: given x and y distance -> how many subpixels do we move in x for every y?
; USE_UNROLLED_LOOP = 0 or 1   ; This turns on the use on unrolled loops (only used when jump tables are not used)
; USE_JUMP_TABLE = 0 or 1      ; This turns on the use of jump tables and uses part of the 'polygon filler' addr1-mode in the FX Updated VERA
; USE_WRITE_CACHE = USE_JUMP_TABLE ; This turns on the use of the cache32 which is part the FX Updated VERA

; TEST_JUMP_TABLE = 0 or 1     ; This turns off the iteration in-between the jump-table calls
; USE_SOFT_FILL_LEN = 0 or 1;  ; This turns off reading from 9F2B and 9F2C (for fill length data) and instead reads from USE_SOFT_FILL_LEN-variables

; USE_180_DEGREES_SLOPE_TABLE = 0 or 1  ; When in polygon filler mode and slope tables turned on, its possible to use a 180 degrees slope table

; USE_Y_TO_ADDRESS_TABLE = 1   ; This turns on the use of the Y to address table

; === Required ZP addresses: (one byte each, unless mentioned otherwise) ===

; RAM_BANK (=$00)
; ROM_BANK (=$01)

; TMP1
; TMP2

; MULTIPLIER (2 bytes)
; MULTIPLICAND (2 bytes)
; PRODUCT (4 bytes)

; DIVIDEND (3 bytes)
; DIVISOR (3 bytes)
; REMAINDER (3 bytes)

; JUMP16_ADDRESS (2 bytes)
; JUMP_ADDRESS (2 bytes)

; CODE_ADDRESS (2 bytes)
; LOAD_ADDRESS (2 bytes)
; STORE_ADDRESS (2 bytes)

; TABLE_ROM_BANK
; DRAW_LENGTH

; TRIANGLE_INDEX

; NUMBER_OF_ROWS
; FILL_LENGTH_LOW
; FILL_LENGTH_HIGH

; -- These SOFT-addresses are only needed when USE_POLYGON_FILLER is 0 --
; SOFT_Y (2 bytes)
; SOFT_X1_SUB (2 bytes)
; SOFT_X1 (2 bytes)
; SOFT_X2_SUB (2 bytes)
; SOFT_X2 (2 bytes)
; SOFT_X1_INCR_SUB (2 bytes)
; SOFT_X1_INCR (2 bytes)
; SOFT_X2_INCR_SUB (2 bytes)
; SOFT_X2_INCR (2 bytes)

; SOFT_X1_INCR_HALF_SUB (2 bytes)
; SOFT_X1_INCR_HALF (2 bytes)
; SOFT_X2_INCR_HALF_SUB (2 bytes)
; SOFT_X2_INCR_HALF (2 bytes)


; -- A triangle either has: --
;   - a single top-point, which means it also has a bottom-left point and bottom-right point
;   - a double top-point (two points are at the same top-y), which means top-left point and top-right point and a single bottom-point
;   TODO: we still need to deal with "triangles" that have three points with the same x or the same y coordinate (which is in fact a vertical or horizontal *line*, not a triangle).
; TOP_POINT_X (2 bytes)
; TOP_POINT_Y (2 bytes)
; LEFT_POINT_X (2 bytes)
; LEFT_POINT_Y (2 bytes)
; RIGHT_POINT_X (2 bytes)
; RIGHT_POINT_Y (2 bytes)
; BOTTOM_POINT_X = TOP_POINT_X
; BOTTOM_POINT_Y = TOP_POINT_Y
; TRIANGLE_COLOR

; -- Used for calculating the slope between two points --
; X_DISTANCE (2 bytes)
; X_DISTANCE_IS_NEGATED
; Y_DISTANCE_LEFT_TOP (2 bytes)
; Y_DISTANCE_BOTTOM_LEFT = Y_DISTANCE_LEFT_TOP
; Y_DISTANCE_RIGHT_TOP (2 bytes)
; Y_DISTANCE_BOTTOM_RIGHT = Y_DISTANCE_RIGHT_TOP
; Y_DISTANCE_RIGHT_LEFT (2 bytes)
; Y_DISTANCE_LEFT_RIGHT = Y_DISTANCE_RIGHT_LEFT
; Y_DISTANCE_IS_NEGATED
; SLOPE_TOP_LEFT (3 bytes)
; SLOPE_LEFT_BOTTOM = SLOPE_TOP_LEFT
; SLOPE_TOP_RIGHT (3 bytes)
; SLOPE_RIGHT_BOTTOM = SLOPE_TOP_RIGHT
; SLOPE_LEFT_RIGHT (3 bytes)
; SLOPE_RIGHT_LEFT = SLOPE_LEFT_RIGHT

; Y_DISTANCE_FIRST (2 bytes)
; Y_DISTANCE_SECOND (2 bytes)

; Used to generate the y2address table
; VRAM_ADDRESS (3 bytes)

; LEFT_OVER_PIXELS (2 bytes)
; NIBBLE_PATTERN
; NR_OF_4_PIXELS
; NR_OF_STARTING_PIXELS
; NR_OF_ENDING_PIXELS

; -- Used to generate jump tables --
; GEN_START_X
; GEN_FILL_LENGTH_LOW
; GEN_FILL_LENGTH_IS_16_OR_MORE
; GEN_LOANED_16_PIXELS
; GEN_FILL_LINE_CODE_INDEX

; == Required RAM Addresses ==

; -- Only used when USE_SOFT_FILL_LEN is 1 --
; FILL_LENGTH_HIGH_SOFT (1 byte)

; FILL_LINE_JUMP_TABLE (256 bytes)
; FILL_LINE_BELOW_16_CODE ; 128 different (below 16 pixel) fill line code patterns -> takes roughly $0C28 (3112) bytes -> so $0D00 is safe

; -- IMPORTANT: we set the two lower bits of this address in the code, using JUMP_TABLE_16_0 as base. So the distance between the 4 tables should be $100! AND bits 8 and 9 should be 00b! (for JUMP_TABLE_16_0) --
; JUMP_TABLE_16_0 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_0
; JUMP_TABLE_16_1 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_1
; JUMP_TABLE_16_2 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_2
; JUMP_TABLE_16_3 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_3

; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes?
; FILL_LINE_CODE_0 ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_CODE_1 ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_CODE_2 ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_CODE_3 ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

; -- Triangle data is (easely) accessed through an single index (0-255) --
; MAX_NR_OF_TRIANGLES = 256  ; has to be set to the distance in memory of the tables below
; == IMPORTANT: we assume a *clockwise* ordering of the 3 points of a triangle! ==
; TRIANGLES_POINT1_X (MAX_NR_OF_TRIANGLES * 2 bytes)
; TRIANGLES_POINT1_Y (MAX_NR_OF_TRIANGLES * 2 bytes)
; TRIANGLES_POINT2_X (MAX_NR_OF_TRIANGLES * 2 bytes)
; TRIANGLES_POINT2_Y (MAX_NR_OF_TRIANGLES * 2 bytes)
; TRIANGLES_POINT3_X (MAX_NR_OF_TRIANGLES * 2 bytes)
; TRIANGLES_POINT3_Y (MAX_NR_OF_TRIANGLES * 2 bytes)
; TRIANGLES_COLOR (MAX_NR_OF_TRIANGLES bytes)

; Y_TO_ADDRESS_LOW (256 bytes)
; Y_TO_ADDRESS_HIGH (256 bytes)
; Y_TO_ADDRESS_BANK (256 bytes)

; COPY_SLOPE_TABLES_TO_BANKED_RAM (less than 256 bytes)

; -- This is used for unrolled code, not used when jump tables are used --
; This should be an address inside Banked RAM (in 64 banks: 3 (stz) * 64 + rts) -> so $100 of space is safe
; Example addresses:
;   DRAW_ROW_64_CODE         = $AA00   ; When USE_POLYGON_FILLER is 1: A000-A9FF and B0600-BFFF are occucpied by the slope tables! (the latter by the 90-180 degrees slope tables)
;   DRAW_ROW_64_CODE         = $B500   ; When USE_POLYGON_FILLER is 0: A000-B4FF are occucpied by the slope tables!
    
generate_fill_line_codes_and_table:

    lda #<FILL_LINE_BELOW_16_CODE
    sta CODE_ADDRESS
    lda #>FILL_LINE_BELOW_16_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    stz GEN_FILL_LINE_CODE_INDEX
gen_next_fill_line_code:
    ; We remember where this partical code starts (where we have to jump to from the jump table)
    clc
    tya
    adc CODE_ADDRESS           ; TODO: CODE_ADDRESS will always stay 0, so this doesnt do anything really
    sta JUMP_ADDRESS       
    lda CODE_ADDRESS+1
    sta JUMP_ADDRESS+1

    lda GEN_FILL_LINE_CODE_INDEX
    sta FILL_LENGTH_LOW
    jsr generate_single_fill_line_code
    
    ; Storing jump address in jump table
    ldx GEN_FILL_LINE_CODE_INDEX
    lda JUMP_ADDRESS
    sta FILL_LINE_JUMP_TABLE, x
    inx
    lda JUMP_ADDRESS+1
    sta FILL_LINE_JUMP_TABLE, x
    
    inc GEN_FILL_LINE_CODE_INDEX
    inc GEN_FILL_LINE_CODE_INDEX
    bne gen_next_fill_line_code

    rts

    
; This routines expects:
;    FILL_LENGTH_LOW    : X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0

generate_single_fill_line_code:

    ; == We first extract this info ==
    ;
    ;   GEN_START_X[1:0]
    ;   GEN_FILL_LENGTH_LOW = [3:0]
    ;   GEN_FILL_LENGTH_IS_16_OR_MORE
    ;
    
    ; stp
    
    lda FILL_LENGTH_LOW
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    sta GEN_START_X
    
    lda FILL_LENGTH_LOW
    lsr
    and #%00001111
    sta GEN_FILL_LENGTH_LOW
    
    lda FILL_LENGTH_LOW
    and #%00100000
    lsr
    lsr
    lsr
    lsr
    lsr
    sta GEN_FILL_LENGTH_IS_16_OR_MORE
    
    stz GEN_LOANED_16_PIXELS
    
    ; ================================  

    
    ; -- NR_OF_STARTING_PIXELS = 4 - GEN_START_X --
    sec
    lda #4
    sbc GEN_START_X
    sta NR_OF_STARTING_PIXELS

    ; -- NR_OF_ENDING_PIXELS = (GEN_START_X + GEN_FILL_LENGTH_LOW) % 4 --
    clc
    lda GEN_START_X
    adc GEN_FILL_LENGTH_LOW
    and #%00000011
    sta NR_OF_ENDING_PIXELS               ; the lower 2 bits contain the nr of ending pixels
    
    ; -- we start with LEFT_OVER_PIXELS = GEN_FILL_LENGTH_LOW --
    stz LEFT_OVER_PIXELS+1
    lda GEN_FILL_LENGTH_LOW
    sta LEFT_OVER_PIXELS
    
    ; -- check if more than or equal to 16 extra pixels have to be drawn
    lda GEN_FILL_LENGTH_IS_16_OR_MORE
    bne gen_more_or_equal_to_16_pixels
    
gen_less_than_16_pixels:

    ; If we have less than 16 pixels AND fill length low == 0, we have nothing to do, so we go to the end
    lda GEN_FILL_LENGTH_LOW
    beq gen_ending_pixels_are_generated

    ; ===== We need to check if the starting and ending pixels are in the same 4-pixel colum ====
    ; check if GEN_START_X + GEN_FILL_LENGTH_LOW >= 4
    clc
    lda GEN_START_X
    adc GEN_FILL_LENGTH_LOW
    cmp #4
    bcc gen_start_and_end_in_same_column  ; we end in the same 4-pixel column as where we start
    beq gen_start_and_end_in_same_column
    
    ; ============= generate starting pixels code (>=16 pixels) ===============

    ; if NR_OF_STARTING_PIXELS == 4 (meaning GEN_START_X == 0) we add 4 to the total left-over pixel count and NOT generate starting pixels!
    lda NR_OF_STARTING_PIXELS
    cmp #4
    beq gen_generate_middle_pixels
    
gen_generate_starting_pixels:
    
    ; -- we subtract the starting pixels from LEFT_OVER_PIXELS --
    sec
    lda LEFT_OVER_PIXELS
    sbc NR_OF_STARTING_PIXELS
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    sbc #0
    sta LEFT_OVER_PIXELS+1
    
    jsr generate_draw_starting_pixels_code
    
gen_generate_middle_pixels:

    ; We divide LEFT_OVER_PIXELS by 4 by shifting it 2 bit positions to the right
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    
    lda LEFT_OVER_PIXELS            ; Note: the result should always fit into one byte
    sta NR_OF_4_PIXELS
    beq middle_pixels_generated     ; We should not draw any middle pixels
    jsr generate_draw_4_pixels_code
middle_pixels_generated:
    
    
gen_generate_ending_pixels:
    lda NR_OF_ENDING_PIXELS
    beq gen_ending_pixels_are_generated    ; If there should be no ending pixels generated, we skip generating them

    jsr generate_draw_ending_pixels_code
    
gen_ending_pixels_are_generated:
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    rts

    
gen_start_and_end_in_same_column:

    jsr generate_draw_starting_and_ending_pixels_code

    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    rts

    
gen_more_or_equal_to_16_pixels:

    ; ============= generate starting pixels code (>=16 pixels) ===============

    ; if NR_OF_STARTING_PIXELS == 4 (meaning GEN_START_X == 0) we add 4 to the total left-over pixel count and NOT generate starting pixels!
    lda NR_OF_STARTING_PIXELS
    cmp #4
    beq gen_generate_middle_pixels_16
    
gen_generate_starting_pixels_16:

    ; -- we subtract the starting pixels from LEFT_OVER_PIXELS --
    sec
    lda LEFT_OVER_PIXELS
    sbc NR_OF_STARTING_PIXELS
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    sbc #0
    sta LEFT_OVER_PIXELS+1
    
    ; if NR_OF_STARTING_PIXELS > LEFT_OVER_PIXELS (which is possible since LEFT_OVER_PIXELS == GEN_FILL_LENGTH_LOW and >16 fill length)
    ; we should *LOAN* 16 pixels. So we add 16 pixels here, and subtract it by jumping 4*stz later in the code fill code.
    
    clc
    lda LEFT_OVER_PIXELS
    adc #16
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    adc #0
    sta LEFT_OVER_PIXELS+1
    
    lda #1
    sta GEN_LOANED_16_PIXELS

    jsr generate_draw_starting_pixels_code

gen_generate_middle_pixels_16:

    ; We divide LEFT_OVER_PIXELS by 4 by shifting it 2 bit positions to the right
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    
    lda LEFT_OVER_PIXELS               ; Note: the result should always fit into one byte
    sta NR_OF_4_PIXELS
    beq middle_pixels_generated_16     ; We should not draw any middle pixels
    jsr generate_draw_4_pixels_code
middle_pixels_generated_16:
    
gen_generate_jump_to_second_table:

    ;   Note: the table is reversed: since the higher y-number will the less pixels. (so the *beginning* of the table will point to the *end* of the code), when no stz-calls are made)

    lda #<JUMP_TABLE_16_0
    sta JUMP16_ADDRESS
    lda #>JUMP_TABLE_16_0
    ora NR_OF_ENDING_PIXELS     ; We set the two lower bits of the HIGH byte of the JUMP TABLE address to indicate which jump table we want to jump to
    sta JUMP16_ADDRESS+1

    lda GEN_LOANED_16_PIXELS
    beq jump_address_is_valid
    
    ; if GEN_LOANED_16_PIXELS == 1 we should jump as-if 16 pixels less have to be drawn -> so we subtract 4 bytes (2 jump addresses)
    
    sec
    lda JUMP16_ADDRESS
    sbc #4
    sta JUMP16_ADDRESS
    lda JUMP16_ADDRESS+1
    sbc #0
    sta JUMP16_ADDRESS+1
    
; FIXME: CHECK: if exactly 16-pixels have to be drawn due to the HIGH fill length, we should not draw any pixels!
    
jump_address_is_valid:
    
    ; -- ldx $9F2C (= FILL_LENGTH_HIGH from VERA)
    lda #$AE               ; ldx ....
    jsr add_code_byte

    .if(USE_SOFT_FILL_LEN)
        lda #<FILL_LENGTH_HIGH_SOFT
        jsr add_code_byte
        
        lda #>FILL_LENGTH_HIGH_SOFT
        jsr add_code_byte
    .else
        lda #$2C               ; $2C
        jsr add_code_byte
        
        lda #$9F               ; $9F
        jsr add_code_byte
    .endif

    ; -- jmp ($....,x)
    lda #$7C               ; jmp (....,x)
    jsr add_code_byte

    lda JUMP16_ADDRESS        ; low byte of jump base address
    jsr add_code_byte
    
    lda JUMP16_ADDRESS+1      ; high byte of jump base address
    jsr add_code_byte
    
    rts
    
    
generate_fill_line_iterate_code:

    ; -- lda VERA_DATA0 ($9F23)
    lda #$AD               ; lda ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
        
    ; -- dey
    lda #$88               ; dey
    jsr add_code_byte
        
    ; -- beq fill_done
    lda #$F0               ; beq ...
    jsr add_code_byte
        
    ; IMPORTANT: if you change any of the below code byte make sure you change this number accordingly!
    lda #$09               ; ... fill_done -> branches to the rts opcode below!
    jsr add_code_byte
        
    ; -- lda VERA_DATA1 ($9F24)
    lda #$AD               ; lda ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
        
    ; -- ldx $9F2B (FILL_LENGTH_LOW)
    lda #$AE               ; ldx ....
    jsr add_code_byte

    lda #$2B               ; $2B
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
        
    ; -- jmp (FILL_LINE_JUMP_TABLE,x)
    lda #$7C               ; jmp (....,x)
    jsr add_code_byte

    lda #<FILL_LINE_JUMP_TABLE  ; low byte of jump table
    jsr add_code_byte
    
    lda #>FILL_LINE_JUMP_TABLE  ; high byte of jump table
    jsr add_code_byte
    
    ; -- rts
    lda #$60               ; rts
    jsr add_code_byte

    rts
    
    
    
generate_four_times_fill_line_code:

    ; -------------- FILL_LINE_CODE_0 ---------------
    
    lda #<FILL_LINE_CODE_0
    sta CODE_ADDRESS
    lda #>FILL_LINE_CODE_0
    sta CODE_ADDRESS+1
    
    jsr generate_80_fill_line_codes
    
    ; Note: for FILL_LINE_CODE_0 there is no additional (sub 4) pixel draw
    
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif

    ; -------------- FILL_LINE_CODE_1 ---------------

    lda #<FILL_LINE_CODE_1
    sta CODE_ADDRESS
    lda #>FILL_LINE_CODE_1
    sta CODE_ADDRESS+1
    
    jsr generate_80_fill_line_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11111100         ; NIBBLE_PATTERN = 1 pixel at the end
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    ; -------------- FILL_LINE_CODE_2 ---------------

    lda #<FILL_LINE_CODE_2
    sta CODE_ADDRESS
    lda #>FILL_LINE_CODE_2
    sta CODE_ADDRESS+1
    
    jsr generate_80_fill_line_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11110000         ; NIBBLE_PATTERN = 2 pixels at the end
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    ; -------------- FILL_LINE_CODE_3 ---------------

    lda #<FILL_LINE_CODE_3
    sta CODE_ADDRESS
    lda #>FILL_LINE_CODE_3
    sta CODE_ADDRESS+1
    
    jsr generate_80_fill_line_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11000000         ; NIBBLE_PATTERN = 3 pixels at the end
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif

    rts

    
generate_four_times_jump_table_16:

    lda #<JUMP_TABLE_16_0
    sta STORE_ADDRESS
    lda #>JUMP_TABLE_16_0
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
    lda #<(FILL_LINE_CODE_0+80*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_CODE_0+80*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_16

    
    lda #<JUMP_TABLE_16_1
    sta STORE_ADDRESS
    lda #>JUMP_TABLE_16_1
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
    lda #<(FILL_LINE_CODE_1+80*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_CODE_1+80*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_16
    
    
    lda #<JUMP_TABLE_16_2
    sta STORE_ADDRESS
    lda #>JUMP_TABLE_16_2
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
    lda #<(FILL_LINE_CODE_2+80*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_CODE_2+80*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_16
    
    
    lda #<JUMP_TABLE_16_3
    sta STORE_ADDRESS
    lda #>JUMP_TABLE_16_3
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
    lda #<(FILL_LINE_CODE_3+80*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_CODE_3+80*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_16
    
    
    rts

    
generate_jump_table_16:
    ldy #0
generate_next_jump_table_16_entry:

    lda LOAD_ADDRESS
    sta (STORE_ADDRESS), y
    iny
    lda LOAD_ADDRESS+1
    sta (STORE_ADDRESS), y
    iny

    ; We do *two* addresses since the 9F2C (FILL_LENGTH_HIGH) value also contains bit 3, but we essentially *ignore* it. Therefore creating the same entry *twice*.
    lda LOAD_ADDRESS
    sta (STORE_ADDRESS), y
    iny
    lda LOAD_ADDRESS+1
    sta (STORE_ADDRESS), y
    iny
    
    sec
    lda LOAD_ADDRESS
    sbc #4*3               ; we need to skip 16 pixels, so three times a stz, this is 4 * 3 bytes of code
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    sbc #0
    sta LOAD_ADDRESS+1
    
    cpy #80+4                ; We need 20 entries of 16 pixels (=320 pixels) *plus* an entry for 0 pixels. Each entry is 4 bytes (two addresses_, so we stop at 4*21=84 bytes.
    bne generate_next_jump_table_16_entry
    
    rts


    
    
generate_80_fill_line_codes:
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of fill instructions
next_fill_instruction:

    ; -- stz VERA_DATA1 ($9F24)
    lda #$9C               ; stz ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx #80
    bne next_fill_instruction  ; 80 times a "fill 4-pixels" written to VERA
    
    rts


    
TEST_set_address_using_y2address_table_and_point_x:
    
    ; TODO: we limit the y-coordinate to 1 byte (so max 255 right now)
    ldx LEFT_POINT_Y
    
    clc
    lda Y_TO_ADDRESS_LOW, x
    adc LEFT_POINT_X
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH, x
    adc LEFT_POINT_X+1
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK, x     ; This will include some kind of auto-increment value
    adc #0
; FIXME: ULGY way of forcing the auto-increment to be what we want
    and #%00001111
    ora #%00110000   ; Forcing auto-increment of 4
    sta VERA_ADDR_BANK
    
    rts

    
nr_of_starting_pixels_to_nibble_pattern:
    .byte %00000000     ; 4 pixels         ; only used in combination with ending pixels
    .byte %00111111     ; 1 pixel
    .byte %00001111     ; 2 pixels
    .byte %00000011     ; 3 pixels
    
nr_of_ending_pixels_to_nibble_pattern:
    .byte %00000000     ; 4 pixels         ; only used in combination with starting pixels
    .byte %11111100     ; 1 pixel
    .byte %11110000     ; 2 pixels
    .byte %11000000     ; 3 pixels

generate_draw_4_pixels_code:

    ldx #0                 ; counts nr of draw 4 pixels instructions

next_draw_4_pixels_instruction:

    ; -- stz VERA_DATA1 ($9F24)
    lda #$9C               ; stz ....
    jsr add_code_byte
    
    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx NR_OF_4_PIXELS
    bne next_draw_4_pixels_instruction

    rts

generate_draw_starting_and_ending_pixels_code:

    ldx NR_OF_STARTING_PIXELS
    lda nr_of_starting_pixels_to_nibble_pattern, x
    sta TMP2

    ldx NR_OF_ENDING_PIXELS
    lda nr_of_ending_pixels_to_nibble_pattern, x
    ora TMP2
    sta NIBBLE_PATTERN
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda NIBBLE_PATTERN      ; NIBBLE_PATTERN
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    rts

    
generate_draw_starting_pixels_code:

    ldx NR_OF_STARTING_PIXELS
    lda nr_of_starting_pixels_to_nibble_pattern, x
    sta NIBBLE_PATTERN
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda NIBBLE_PATTERN      ; NIBBLE_PATTERN
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    rts


generate_draw_ending_pixels_code:

    ldx NR_OF_ENDING_PIXELS
    lda nr_of_ending_pixels_to_nibble_pattern, x
    sta NIBBLE_PATTERN
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda NIBBLE_PATTERN      ; NIBBLE_PATTERN
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    rts

    
generate_rts_code:

    ; -- rts --
    lda #$60
    jsr add_code_byte
    
    rts
  
  
  
    
MACRO_copy_point_x .macro TRIANGLES_POINT_X, POINT_X
    lda \TRIANGLES_POINT_X, x
    sta \POINT_X
    lda \TRIANGLES_POINT_X+MAX_NR_OF_TRIANGLES, x
    sta \POINT_X+1
.endmacro

MACRO_copy_point_y .macro TRIANGLES_POINT_Y, POINT_Y
    lda \TRIANGLES_POINT_Y, x
    sta \POINT_Y
;    lda \TRIANGLES_POINT_Y+MAX_NR_OF_TRIANGLES, x
;    sta \POINT_Y+1
.endmacro

    
draw_all_triangles:

    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL

    ; Entering *polygon fill mode*: from now on every read from DATA1 will increment x1 and x2, and ADDR1 will be filled with ADDR0 + x1
    lda #%00000011
    sta $9F29
    
    .if(USE_JUMP_TABLE)
        lda #%00110000           ; Setting auto-increment value to 4 byte increment (=%0011)
        sta VERA_ADDR_BANK
    .else
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    ; Loop though a series of 3-points:
    ;   check which type of triangle this is (single top-point or double top-point_
    ;   Store in appropiate variables: TOP_POINT_X/Y, LEFT_POINT_X/Y, RIGHT_POINT_X/Y, BOTTOM_POINT_X/Y
    ;   jump to correct draw_triangle-function

    ; We start at triangle 0
    stz TRIANGLE_INDEX
draw_next_triangle:

    ldx TRIANGLE_INDEX
    
    lda TRIANGLES_COLOR, x
    sta TRIANGLE_COLOR
    
    .if(USE_JUMP_TABLE)
; FIXME: we should create a (fast) macro for this!
        ; We first need to fill the 32-bit cache with 4 times our color
; FIXME: cant we assume we are still in this mode?
        lda #%00000101           ; DCSEL=2, ADDRSEL=1
        sta VERA_CTRL
        
        lda #%00000000           ; normal addr1 mode 
        sta $9F29
        
        lda #%00000001           ; ... cache fill enabled = 1
        sta $9F2C   
        
; FIXME: why would we need to do this?
        lda #%00000000           ; map base addr = 0, blit write enabled = 0, repeat/clip = 0
        sta $9F2B  
        
; FIXME: we should use a different VRAM address for this cache filling!!
        lda #%00000000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 bytes (=0=%00000)
        sta VERA_ADDR_BANK
        stz VERA_ADDR_HIGH
        stz VERA_ADDR_LOW

        lda TRIANGLE_COLOR
        sta VERA_DATA1
        
        lda VERA_DATA1    
        lda VERA_DATA1
        lda VERA_DATA1
        lda VERA_DATA1
         
        lda #%00000000           ; ... cache fill enabled = 0
        sta $9F2C   

; FIXME: This is SLOW!
        lda #%00110000           ; Setting auto-increment value to 4 byte increment (=%0011)
        sta VERA_ADDR_BANK
        
        lda #%00000010           ; map base addr = 0, blit write enabled = 1, repeat/clip = 0
        sta $9F2B  

        ; FIXME: this is SLOW
        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        ; Re-entering *polygon fill mode*: from now on every read from DATA1 will increment x1 and x2, and ADDR1 will be filled with ADDR0 + x1
        lda #%00000011
        sta $9F29
        
    .endif
    
    
    ; -- Determining which point is/are top point(s) --

;    lda TRIANGLES_POINT1_Y+MAX_NR_OF_TRIANGLES, x
;    cmp TRIANGLES_POINT2_Y+MAX_NR_OF_TRIANGLES, x
;    bcc point1_is_lower_in_y_than_point2
;    bne point1_is_higher_in_y_than_point2

    lda TRIANGLES_POINT1_Y, x
    cmp TRIANGLES_POINT2_Y, x
    bcc point1_is_lower_in_y_than_point2
    beq point1_is_the_same_in_y_as_point2
    bne point1_is_higher_in_y_than_point2
    
point1_is_lower_in_y_than_point2:
    
;    lda TRIANGLES_POINT1_Y+MAX_NR_OF_TRIANGLES, x
;    cmp TRIANGLES_POINT3_Y+MAX_NR_OF_TRIANGLES, x
;    bcc pt1_lower_pt2_point1_is_lower_in_y_than_point3
;    bne pt1_lower_pt2_point1_is_higher_in_y_than_point3

    lda TRIANGLES_POINT1_Y, x
    cmp TRIANGLES_POINT3_Y, x
    bcc pt1_lower_pt2_point1_is_lower_in_y_than_point3
    beq pt1_lower_pt2_point1_is_the_same_in_y_as_point3
    bne pt1_lower_pt2_point1_is_higher_in_y_than_point3
    
pt1_lower_pt2_point1_is_lower_in_y_than_point3:

    ; This means point1 is lower than point2 and point3
    jmp point1_is_top_point
    
pt1_lower_pt2_point1_is_higher_in_y_than_point3:

    ; This means point1 is lower than point2 but higher than point3, this means point3 is the lowest
    jmp point3_is_top_point
    
pt1_lower_pt2_point1_is_the_same_in_y_as_point3:

    ; This means point1 is lower than point2 but is equal to point3, this means point1 and point3 are both the lowest
    jmp point3_and_point1_are_top_points
    
    
point1_is_higher_in_y_than_point2:

;    lda TRIANGLES_POINT2_Y+MAX_NR_OF_TRIANGLES, x
;    cmp TRIANGLES_POINT3_Y+MAX_NR_OF_TRIANGLES, x
;    bcc pt1_higher_pt2_point2_is_lower_in_y_than_point3
;    bne pt1_higher_pt2_point2_is_higher_in_y_than_point3

    lda TRIANGLES_POINT2_Y, x
    cmp TRIANGLES_POINT3_Y, x
    bcc pt1_higher_pt2_point2_is_lower_in_y_than_point3
    beq pt1_higher_pt2_point2_is_the_same_in_y_as_point3
    bne pt1_higher_pt2_point2_is_higher_in_y_than_point3

pt1_higher_pt2_point2_is_lower_in_y_than_point3:

    ; Point1 is higher than point2 and point2 is lower than point3, this means point2 is lowest
    jmp point2_is_top_point
    
pt1_higher_pt2_point2_is_higher_in_y_than_point3:

    ; Point1 is higher than point2 and point2 is higher than point 3, this means point3 is lowest
    jmp point3_is_top_point

pt1_higher_pt2_point2_is_the_same_in_y_as_point3:

    ; Point1 is higher than point2 and point2 is the same as point3, this means point2 and point3 are both the lowest
    jmp point2_and_point3_are_top_points

    
point1_is_the_same_in_y_as_point2:

;    lda TRIANGLES_POINT1_Y+MAX_NR_OF_TRIANGLES, x
;    cmp TRIANGLES_POINT3_Y+MAX_NR_OF_TRIANGLES, x
;    bcc pt1_same_pt2_point1_is_lower_in_y_than_point3
;    bne pt1_same_pt2_point1_is_higher_in_y_than_point3

    lda TRIANGLES_POINT1_Y, x
    cmp TRIANGLES_POINT3_Y, x
    bcc pt1_same_pt2_point1_is_lower_in_y_than_point3
    beq pt1_same_pt2_point1_is_the_same_in_y_as_point3
    bne pt1_same_pt2_point1_is_higher_in_y_than_point3

pt1_same_pt2_point1_is_lower_in_y_than_point3:

    ; Point1 and point2 are the same, thet are both lower than point3, this means point1 and point2 are both the lowest
    jmp point1_and_point2_are_top_points

pt1_same_pt2_point1_is_higher_in_y_than_point3:

    ; Point1 and point2 are the same, thet are both higher than point3, this means point3 is lowest
    jmp point3_is_top_point

pt1_same_pt2_point1_is_the_same_in_y_as_point3:

    ; All points have the same y, this means we have a horizontal line
    jmp point1_point2_and_point3_are_top_points

    
point1_is_top_point:

    ; -- TOP POINT --
    MACRO_copy_point_x TRIANGLES_POINT1_X, TOP_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT1_Y, TOP_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point_x TRIANGLES_POINT2_X, RIGHT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT2_Y, RIGHT_POINT_Y
    
    ; -- LEFT POINT --
    MACRO_copy_point_x TRIANGLES_POINT3_X, LEFT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT3_Y, LEFT_POINT_Y

    jmp draw_triangle_with_single_top_point


point2_is_top_point:
    
    ; -- TOP POINT --
    MACRO_copy_point_x TRIANGLES_POINT2_X, TOP_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT2_Y, TOP_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point_x TRIANGLES_POINT3_X, RIGHT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT3_Y, RIGHT_POINT_Y
    
    ; -- LEFT POINT --
    MACRO_copy_point_x TRIANGLES_POINT1_X, LEFT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT1_Y, LEFT_POINT_Y

    jmp draw_triangle_with_single_top_point

point3_is_top_point:

    ; -- TOP POINT --
    MACRO_copy_point_x TRIANGLES_POINT3_X, TOP_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT3_Y, TOP_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point_x TRIANGLES_POINT1_X, RIGHT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT1_Y, RIGHT_POINT_Y
    
    ; -- LEFT POINT --
    MACRO_copy_point_x TRIANGLES_POINT2_X, LEFT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT2_Y, LEFT_POINT_Y

    jmp draw_triangle_with_single_top_point

point1_and_point2_are_top_points:

    ; -- LEFT POINT --
    MACRO_copy_point_x TRIANGLES_POINT1_X, LEFT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT1_Y, LEFT_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point_x TRIANGLES_POINT2_X, RIGHT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT2_Y, RIGHT_POINT_Y

    ; -- BOTTOM POINT --
    MACRO_copy_point_x TRIANGLES_POINT3_X, BOTTOM_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT3_Y, BOTTOM_POINT_Y
    
    jmp draw_triangle_with_double_top_points

point2_and_point3_are_top_points:

    ; -- LEFT POINT --
    MACRO_copy_point_x TRIANGLES_POINT2_X, LEFT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT2_Y, LEFT_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point_x TRIANGLES_POINT3_X, RIGHT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT3_Y, RIGHT_POINT_Y

    ; -- BOTTOM POINT --
    MACRO_copy_point_x TRIANGLES_POINT1_X, BOTTOM_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT1_Y, BOTTOM_POINT_Y
    
    jmp draw_triangle_with_double_top_points

point3_and_point1_are_top_points:
    
    ; -- LEFT POINT --
    MACRO_copy_point_x TRIANGLES_POINT3_X, LEFT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT3_Y, LEFT_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point_x TRIANGLES_POINT1_X, RIGHT_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT1_Y, RIGHT_POINT_Y

    ; -- BOTTOM POINT --
    MACRO_copy_point_x TRIANGLES_POINT2_X, BOTTOM_POINT_X
    MACRO_copy_point_y TRIANGLES_POINT2_Y, BOTTOM_POINT_Y
    
    jmp draw_triangle_with_double_top_points

point1_point2_and_point3_are_top_points:

    ; FIXME: what should we do in this case? Should we draw a horizonal line? 
    
    ; FIXME: right now, we just move on to the next triangle
    
    
done_drawing_polygon_part:

    inc TRIANGLE_INDEX
    lda TRIANGLE_INDEX
    cmp #NR_OF_TRIANGLES
    beq done_drawing_all_triangles
    jmp draw_next_triangle
    
    
done_drawing_all_triangles:
    
    ; Turning off polygon filler mode
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    .if(USE_JUMP_TABLE)
        lda #%00000000           ; map base addr = 0, blit write enabled = 0, repeat/clip = 0
        sta $9F2B     
    .endif
    
    ; Normal addr1 mode
    lda #%00000000
    sta $9F29
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
    
MACRO_get_slope_from_180_degrees_slope_table: .macro Y_DISTANCE, SLOPE

    ; We get the SLOPE from the slope 180 degrees table. We need:
    ;   y = Y_DISTANCE
    ;   RAM_BANK = X_DISTANCE[5:0]
    ;   LOAD_ADDR_HIGH[4:1] = X_DISTANCE[9:6]  ; Note: X_DISTANCE is considered to be a *signed* number here, where bit9 is used to determine its sign
        
    ldy \Y_DISTANCE

    lda X_DISTANCE
    and #%00111111
    sta RAM_BANK

    ; We rotate bits 7 and 6 into X_DISTANCE+1 (which contains bit 8 and 9)
    asl X_DISTANCE
    rol X_DISTANCE+1
    asl X_DISTANCE
    rol X_DISTANCE+1
    
    ; We shift bits 9, 8, 7 and 6 into bits 4, 3, 2 and 1
    asl X_DISTANCE+1
    
    lda X_DISTANCE+1
    and #%00011111         ; we use bit9 of X_DISTANCE (here bit4) to switch between Ax and Bx. The upper bits we discard, since we dont want an address too high when the X_DISTANCE is negative
    ora #>($A000)          ; We combine bits 4:1 with A0
    sta LOAD_ADDRESS+1
    
    ; SPEED: we dont need to do this again and again, this stays at zero!
    lda #<($A000)
    sta LOAD_ADDRESS
    
    ; We load the SLOPE_LOW
    lda (LOAD_ADDRESS), y
    sta \SLOPE
    
    ; We load the SLOPE_HIGH
    inc LOAD_ADDRESS+1
    lda (LOAD_ADDRESS), y
    sta \SLOPE+1

.endmacro

    
MACRO_get_slope_from_slope_table: .macro Y_DISTANCE, SLOPE

    .if(USE_POLYGON_FILLER)
        ; We get the SLOPE from the slope table. We need:
        ;   y = Y_DISTANCE
        ;   RAM_BANK = X_DISTANCE[5:0]
        ;   LOAD_ADDR_HIGH[3:1] = X_DISTANCE[8:6]
            
        ldy \Y_DISTANCE

        lda X_DISTANCE
        and #%00111111
        sta RAM_BANK

        ; We rotate bits 7 and 6 into X_DISTANCE+1 (which contains bit 8)
        asl X_DISTANCE
        rol X_DISTANCE+1
        asl X_DISTANCE
        rol X_DISTANCE+1
        
        ; We shift bits 8, 7 and 6 into bits 3, 2 and 1
        asl X_DISTANCE+1
        
        ; We combine bits 3:1 with A0
        lda #>($A000)
        ora X_DISTANCE+1
        sta LOAD_ADDRESS+1
        
        ; SPEED: we dont need to do this again and again, this stays at zero!
        lda #<($A000)
        sta LOAD_ADDRESS
        
        ; We load the SLOPE_LOW
        lda (LOAD_ADDRESS), y
        sta \SLOPE
        
        ; We load the SLOPE_HIGH
        inc LOAD_ADDRESS+1
        lda (LOAD_ADDRESS), y
        sta \SLOPE+1
    .else
        ; We get the SLOPE from the slope table. We need:
        ;   y = Y_DISTANCE
        ;   RAM_BANK = X_DISTANCE[5:0]
        ;   LOAD_ADDR_HIGH[4:2] = X_DISTANCE[8:6]
            
        ldy \Y_DISTANCE

        lda X_DISTANCE
        and #%00111111
        sta RAM_BANK

        ; We rotate bits 7 and 6 into X_DISTANCE+1 (which contains bit 8)
        asl X_DISTANCE
        rol X_DISTANCE+1
        asl X_DISTANCE
        rol X_DISTANCE+1
        
        ; We shift bits 8, 7 and 6 into bits 4, 3 and 2
        asl X_DISTANCE+1
        asl X_DISTANCE+1
        
        ; We combine bits 4:2 with A0
        lda #>($A000)
        ora X_DISTANCE+1
        sta LOAD_ADDRESS+1
        
        ; SPEED: we dont need to do this again and again, this stays at zero!
        lda #<($A000)
        sta LOAD_ADDRESS
        
        ; We load the SLOPE_LOW
        lda (LOAD_ADDRESS), y
        sta \SLOPE
        
        ; We load the SLOPE_HIGH
        inc LOAD_ADDRESS+1
        lda (LOAD_ADDRESS), y
        sta \SLOPE+1
        
        ; We load the SLOPE_VHIGH
        inc LOAD_ADDRESS+1
        lda (LOAD_ADDRESS), y
        sta \SLOPE+2
    .endif
.endmacro


MACRO_calculate_slope_using_division: .macro Y_DISTANCE, SLOPE

    ; We do the divide: X_DISTANCE * 256 / Y_DISTANCE
    lda X_DISTANCE+1
    sta DIVIDEND+2
    lda X_DISTANCE
    sta DIVIDEND+1
    lda #0
    sta DIVIDEND

    lda #0
    sta DIVISOR+2
    lda #0
;    lda \Y_DISTANCE+1
    sta DIVISOR+1
    lda \Y_DISTANCE
    sta DIVISOR

    jsr divide_24bits
    
    lda DIVIDEND+2
    sta \SLOPE+2
    lda DIVIDEND+1
    sta \SLOPE+1
    lda DIVIDEND
    sta \SLOPE
    
    .if(USE_POLYGON_FILLER)
    
        ; If SLOPE >= 64 we should shift 5 bits to the right AND set bit15
        
        lda \SLOPE+2
        bne \@slope_is_64_or_higher
        lda \SLOPE+1
        cmp #64
        bcs \@slope_is_64_or_higher  ; if slope >= 64 then we want to shift 5 positions
        bra \@slope_is_correctly_packed
    \@slope_is_64_or_higher:

        ; We divide the slope by 32 (aka shifting 5 bits to the right)
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE

        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lda \SLOPE+1
        ora #%10000000          ; we set bit 15 (here bit 7) to 1, to indicate the value has to be multiplied to x32 (inside of VERA)
        sta \SLOPE+1

\@slope_is_correctly_packed:

    .endif
    
.endmacro


MACRO_subtract_and_make_positive_x .macro POSITION_A, POSITION_B, DISTANCE, DISTANCE_IS_NEGATED
    
    stz \DISTANCE_IS_NEGATED
    
    ; We subtract: DISTANCE: POSITION_A - POSITION_B
    sec
    lda \POSITION_A
    sbc \POSITION_B
    sta \DISTANCE
    lda \POSITION_A+1
    sbc \POSITION_B+1
    sta \DISTANCE+1
    bpl \@distance_is_positive
    
    lda #1
    sta \DISTANCE_IS_NEGATED

    ; We negate the DISTANCE
    sec
    lda #0
    sbc \DISTANCE
    sta \DISTANCE
    lda #0
    sbc \DISTANCE+1
    sta \DISTANCE+1
    
\@distance_is_positive:

.endmacro


MACRO_subtract_and_make_positive_y .macro POSITION_A, POSITION_B, DISTANCE, DISTANCE_IS_NEGATED
    
    stz \DISTANCE_IS_NEGATED
    
    ; We subtract: DISTANCE: POSITION_A - POSITION_B
    sec
    lda \POSITION_A
    sbc \POSITION_B
    sta \DISTANCE
    bpl \@distance_is_positive
    
    lda #1
    sta \DISTANCE_IS_NEGATED

    ; We negate the DISTANCE
    sec
    lda #0
    sbc \DISTANCE
    sta \DISTANCE
    
\@distance_is_positive:

.endmacro


MACRO_subtract_x .macro POSITION_A, POSITION_B, DISTANCE

    ; We subtract: DISTANCE: POSITION_A - POSITION_B
    sec
    lda \POSITION_A
    sbc \POSITION_B
    sta \DISTANCE
    lda \POSITION_A+1
    sbc \POSITION_B+1
    sta \DISTANCE+1

.endmacro

MACRO_subtract_y .macro POSITION_A, POSITION_B, DISTANCE

    ; We subtract: DISTANCE: POSITION_A - POSITION_B
    sec
    lda \POSITION_A
    sbc \POSITION_B
    sta \DISTANCE
;    lda \POSITION_A+1
;    sbc \POSITION_B+1
;    sta \DISTANCE+1

.endmacro


MACRO_negate_slope .macro SLOPE
    
    .if(USE_POLYGON_FILLER)
        ; We need to preserve the x32 bit here!
        and #%10000000
        sta TMP2

        ; We unset the x32 (in case it was set) because we have to negate the number
        ; SPEED: can we use a different opcode here to unset the x32 bit?
        lda \SLOPE+1
        and #%01111111
        sta \SLOPE+1
    .endif
    
    sec
    lda #0
    sbc \SLOPE
    sta \SLOPE
    lda #0
    sbc \SLOPE+1
    .if(USE_POLYGON_FILLER)
        and #%01111111         ; Only keep the lower 7 bits
        ora TMP2               ; We restore the x32 bit
    .endif
    sta \SLOPE+1
    
    .if(!USE_POLYGON_FILLER)
        lda #0
        sbc \SLOPE+2
        sta \SLOPE+2
    .endif
    
.endmacro


MACRO_copy_slope_to_soft_incr_and_shift_right .macro SLOPE, SOFT_X_INCR_HALF, SOFT_X_INCR_HALF_SUB

; SPEED: can we do this faster? Maybe use 3 bytes and use a different slope lookup table?
; SPEED: the conditional sign extend is also slow!
    lda \SLOPE+2
    bpl \@slope_is_positive
    lsr a
    ora #%10000000
    bra \@slope_is_correctly_signed
\@slope_is_positive:
    lsr a
\@slope_is_correctly_signed:
    sta \SOFT_X_INCR_HALF+1     ; X1 or X2 increment high (signed)
    lda \SLOPE+1
    ror a
    sta \SOFT_X_INCR_HALF       ; X1 or X2 increment low (signed)
    lda \SLOPE  
    ror a
    sta \SOFT_X_INCR_HALF_SUB+1 ; X1 or X2 increment sub high (signed)                
    lda #0
    ror a
    sta \SOFT_X_INCR_HALF_SUB   ; X1 or X2 increment sub low (signed)

.endmacro


MACRO_copy_slope_to_soft_incr .macro SLOPE, SOFT_X_INCR, SOFT_X_INCR_SUB

    lda \SLOPE+2
    sta \SOFT_X_INCR+1       ; X1 or X2 increment high (signed)
    lda \SLOPE+1
    sta \SOFT_X_INCR         ; X1 or X2 increment low (signed)
    lda \SLOPE  
    sta \SOFT_X_INCR_SUB+1   ; X1 or X2 increment sub high (signed)                

.endmacro


MACRO_set_address_using_y2address_table .macro POINT_Y
    
    ; TODO: we limit the y-coordinate to 1 byte (so max 255 right now)
    ldx \POINT_Y
    
    lda Y_TO_ADDRESS_LOW, x
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH, x
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK, x     ; This will include the auto-increment of 320 byte
    sta VERA_ADDR_BANK
    
.endmacro

MACRO_set_address_using_y2address_table_and_point_x .macro POINT_Y, POINT_X
    
    ; TODO: we limit the y-coordinate to 1 byte (so max 255 right now)
    ldx \POINT_Y
    
    clc
    lda Y_TO_ADDRESS_LOW, x
    adc \POINT_X
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH, x
    adc \POINT_X+1
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK, x     ; This will include the auto-increment of 1 byte
    adc #0
    sta VERA_ADDR_BANK
    
.endmacro

MACRO_set_address_using_multiplication .macro POINT_Y

    ; SPEED: we should do this *much* earlier and not for every triangle!
    lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    
    ; -- THIS IS SLOW! --
    ; We need to multiply the Y-coordinate with 320
    lda \POINT_Y
    sta MULTIPLICAND
    lda \POINT_Y+1
    sta MULTIPLICAND+1
    
    lda #<320
    sta MULTIPLIER
    lda #>320
    sta MULTIPLIER+1
    
    jsr multply_16bits
    
    ; HACK: we are assuming our bitmap address starts at 00000 here! AND we assume we never exceed 64kB!! (bit16 is always assumed to be 0)
    ; Note: we are setting ADDR0 to the left most pixel of a pixel row. This means it will be aligned to 4-bytes (which is needed for the polygon filler to work nicely).
    lda PRODUCT+1
    sta VERA_ADDR_HIGH
    lda PRODUCT
    sta VERA_ADDR_LOW

.endmacro

    
draw_triangle_with_single_top_point:

    ; Note: we can assume here that:
    ;  - the triangle has a single top point, its coordinate is in: TOP_POINT_X/TOP_POINT_Y
    ;  - the triangle has a left-bottom point, its coordinate is on: LEFT_POINT_X/LEFT_POINT_Y
    ;  - the triangle has a right-bottom point, its coordinate is on: RIGHT_POINT_X/RIGHT_POINT_Y
    ;  - the color of the triangle is in: TRIANGLE_COLOR

    ; We need to calculate 3 slopes for the 2 triangle parts:
    ;  - the slope between TOP and LEFT
    ;  - the slope between TOP and RIGHT
    ;  - the slope between LEFT and RIGHT or RIGHT and LEFT (depending which one is higher in y)
    
    ; IMPORTANT: be careful with LEFT and RIGHT slope: if they at the same Y you shoud *not* divide/determine the slope, but *stop* instead.
    
    ; About slopes:
    ;  - slopes are up to 15+5=20 bits (signed) numbers: ranging from +-1024 pixels/2 down to +-(1/512th of a pixel)/2
    ;  - slopes are *half* the actual slope between two point (since they are increment in 2 steps)
    ;  - slopes are packed into a signed 15 bit + 1 "times 32"-bit 

    ; SPEED: cant we and use only 1 byte for Y? (since Y < 240 pixels)
    
    ; ============== LEFT POINT vs TOP POINT ============
    
    .if(USE_POLYGON_FILLER && USE_SLOPE_TABLES && USE_180_DEGREES_SLOPE_TABLE)
    
        ; We subtract: X_DISTANCE: LEFT_POINT_X - TOP_POINT_X
        
        MACRO_subtract_x LEFT_POINT_X, TOP_POINT_X, X_DISTANCE
        
        ; We subtract: Y_DISTANCE_LEFT_TOP: LEFT_POINT_Y - TOP_POINT_Y
        
        MACRO_subtract_y LEFT_POINT_Y, TOP_POINT_Y, Y_DISTANCE_LEFT_TOP
        
        ; Note: since we know the top point has a lower y than the left point, there is no need to negate it!
        
        MACRO_get_slope_from_180_degrees_slope_table Y_DISTANCE_LEFT_TOP, SLOPE_TOP_LEFT
        
    .else
        ; We subtract: X_DISTANCE: LEFT_POINT_X - TOP_POINT_X
        
        MACRO_subtract_and_make_positive_x LEFT_POINT_X, TOP_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED
        
        ; We subtract: Y_DISTANCE_LEFT_TOP: LEFT_POINT_Y - TOP_POINT_Y
        
        MACRO_subtract_y LEFT_POINT_Y, TOP_POINT_Y, Y_DISTANCE_LEFT_TOP
        
        ; Note: since we know the top point has a lower y than the left point, there is no need to negate it!
        
        .if(USE_SLOPE_TABLES)
            MACRO_get_slope_from_slope_table Y_DISTANCE_LEFT_TOP, SLOPE_TOP_LEFT
        .else
            MACRO_calculate_slope_using_division Y_DISTANCE_LEFT_TOP, SLOPE_TOP_LEFT
        .endif
        
        ldx X_DISTANCE_IS_NEGATED
        beq slope_top_left_is_correctly_signed   ; if X_DISTANCE is not negated we dont have to negate now, otherwise we do

        MACRO_negate_slope SLOPE_TOP_LEFT
        
slope_top_left_is_correctly_signed:
    .endif


    ; ============== RIGHT POINT vs TOP POINT ============

    .if(USE_POLYGON_FILLER && USE_SLOPE_TABLES && USE_180_DEGREES_SLOPE_TABLE)
    
        ; We subtract: X_DISTANCE: RIGHT_POINT_X - TOP_POINT_X
        
        MACRO_subtract_x RIGHT_POINT_X, TOP_POINT_X, X_DISTANCE
        
        ; We subtract: Y_DISTANCE_RIGHT_TOP: RIGHT_POINT_Y - TOP_POINT_Y
        
        MACRO_subtract_y RIGHT_POINT_Y, TOP_POINT_Y, Y_DISTANCE_RIGHT_TOP
        
        ; Note: since we know the top point has a lower y than the right point, there is no need to negate it!
        
        MACRO_get_slope_from_180_degrees_slope_table Y_DISTANCE_RIGHT_TOP, SLOPE_TOP_RIGHT
        
    .else
        ; We subtract: X_DISTANCE: RIGHT_POINT_X - TOP_POINT_X
        
        MACRO_subtract_and_make_positive_x RIGHT_POINT_X, TOP_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED    
        
        ; We subtract: Y_DISTANCE_RIGHT_TOP: RIGHT_POINT_Y - TOP_POINT_Y
        
        MACRO_subtract_y RIGHT_POINT_Y, TOP_POINT_Y, Y_DISTANCE_RIGHT_TOP
        
        ; Note: since we know the top point has a lower y than the right point, there is no need to negate it!
        
        .if(USE_SLOPE_TABLES)
            MACRO_get_slope_from_slope_table Y_DISTANCE_RIGHT_TOP, SLOPE_TOP_RIGHT
        .else
            MACRO_calculate_slope_using_division Y_DISTANCE_RIGHT_TOP, SLOPE_TOP_RIGHT
        .endif
        
        ldx X_DISTANCE_IS_NEGATED
        beq slope_top_right_is_correctly_signed   ; if X_DISTANCE is not negated we dont have to negate now, otherwise we do
        
        MACRO_negate_slope SLOPE_TOP_RIGHT
        
slope_top_right_is_correctly_signed:
    .endif

    ; ============== RIGHT POINT vs LEFT POINT ============

    .if(USE_POLYGON_FILLER && USE_SLOPE_TABLES && USE_180_DEGREES_SLOPE_TABLE)
    
        ; We subtract: Y_DISTANCE_RIGHT_LEFT: RIGHT_POINT_Y - LEFT_POINT_Y
        
        MACRO_subtract_and_make_positive_y RIGHT_POINT_Y, LEFT_POINT_Y, Y_DISTANCE_RIGHT_LEFT, Y_DISTANCE_IS_NEGATED
        
        ldx Y_DISTANCE_IS_NEGATED
        bne left_point_is_higher_in_y
        
right_point_is_higher_in_y:

        ; We subtract: X_DISTANCE: RIGHT_POINT_X - LEFT_POINT_X
        
        MACRO_subtract_x RIGHT_POINT_X, LEFT_POINT_X, X_DISTANCE

        MACRO_get_slope_from_180_degrees_slope_table Y_DISTANCE_RIGHT_LEFT, SLOPE_RIGHT_LEFT
        
        bra slope_right_left_is_correctly_signed
        
left_point_is_higher_in_y:
        
        ; We subtract: X_DISTANCE: LEFT_POINT_X - RIGHT_POINT_X
        
        MACRO_subtract_x LEFT_POINT_X, RIGHT_POINT_X, X_DISTANCE

        MACRO_get_slope_from_180_degrees_slope_table Y_DISTANCE_RIGHT_LEFT, SLOPE_RIGHT_LEFT
        
slope_right_left_is_correctly_signed:

    .else
        ; We subtract: X_DISTANCE: RIGHT_POINT_X - LEFT_POINT_X
        
        MACRO_subtract_and_make_positive_x RIGHT_POINT_X, LEFT_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED

        ; We subtract: Y_DISTANCE_RIGHT_LEFT: RIGHT_POINT_Y - LEFT_POINT_Y
        
        MACRO_subtract_and_make_positive_y RIGHT_POINT_Y, LEFT_POINT_Y, Y_DISTANCE_RIGHT_LEFT, Y_DISTANCE_IS_NEGATED
        
        .if(USE_SLOPE_TABLES)
            MACRO_get_slope_from_slope_table Y_DISTANCE_RIGHT_LEFT, SLOPE_RIGHT_LEFT
        .else
            MACRO_calculate_slope_using_division Y_DISTANCE_RIGHT_LEFT, SLOPE_RIGHT_LEFT
        .endif
        
        ldx X_DISTANCE_IS_NEGATED
        bne slope_right_left_is_negated_in_x
slope_right_left_is_not_negated_in_x:
        
        ldx Y_DISTANCE_IS_NEGATED
        beq slope_right_left_is_correctly_signed   ; if Y_DISTANCE is negated we have to negate now, otherwise we dont
        
        MACRO_negate_slope SLOPE_RIGHT_LEFT
        
        bra slope_right_left_is_correctly_signed
        
slope_right_left_is_negated_in_x:
    
        ldx Y_DISTANCE_IS_NEGATED
        bne slope_right_left_is_correctly_signed   ; if Y_DISTANCE is not negated we have to negate now, otherwise we dont
        
        MACRO_negate_slope SLOPE_RIGHT_LEFT

slope_right_left_is_correctly_signed:
    .endif

    
    ; -- We setup the starting x and y and the color --
    .if(USE_POLYGON_FILLER)
        ; Setting up for drawing a polygon, setting both addresses at the same starting point

        .if(USE_Y_TO_ADDRESS_TABLE)
            MACRO_set_address_using_y2address_table TOP_POINT_Y
        .else
            MACRO_set_address_using_multiplication TOP_POINT_Y
        .endif
    
        ; Setting x1 and x2 pixel position
        
        lda #%00001000           ; DCSEL=4, ADDRSEL=0
        sta VERA_CTRL
        
        lda TOP_POINT_X
        sta $9F29                ; X (=X1) pixel position low [7:0]
        sta $9F2B                ; Y (=X2) pixel position low [7:0]
        
        ; NOTE: we are also *setting* the subpixel position (bit0) here! Even though we just resetted it! 
        ;       but its ok, since its reset to half a pixel (see above), meaning bit0 is 0 anyway
        lda TOP_POINT_X+1
        sta $9F2A                ; X subpixel position[0] = 0, X (=X1) pixel position high [10:8]
        ora #%00100000           ; Reset subpixel position
        sta $9F2C                ; Y subpixel position[0] = 0, Y (=X2) pixel position high [10:8]

        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
; FIXME: dont do this when using JUMP tables!
        ldy TRIANGLE_COLOR      ; We use y as color
    .else 
    
        ; Setting up for drawing a polygon, setting both X1 and X2 positions at the same starting point
        
        ; Note: without the polygon filler helper we *only* use ADDR1, not ADDR0

        lda #%00000000           ; DCSEL=0, ADDRSEL=0
        sta VERA_CTRL

        ; Setting starting (sub)pixel position X1 and X2
        stz SOFT_X1_SUB          ; Reset subpixel position X1 [0]
        stz SOFT_X2_SUB          ; Reset subpixel position X2 [0]

        lda #(256>>1)            ; Half a pixel
        sta SOFT_X1_SUB+1        ; Reset subpixel position X1 [8:1]
        sta SOFT_X2_SUB+1        ; Reset subpixel position X2 [8:1]
        
        lda TOP_POINT_X
        sta SOFT_X1              ; X1 pixel position low [7:0]
        sta SOFT_X2              ; X2 pixel position low [7:0]
        
        lda TOP_POINT_X+1
        sta SOFT_X1+1            ; X1 pixel position high [10:8]
        sta SOFT_X2+1            ; X2 pixel position high [10:8]
        
        ; Starting Y
        lda TOP_POINT_Y
        sta SOFT_Y
        lda TOP_POINT_Y+1
        sta SOFT_Y+1
        
        ldy TRIANGLE_COLOR      ; We use y as color
        
    .endif


    .if(USE_POLYGON_FILLER)

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL

        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_TOP_LEFT       ; X1 increment low (signed)
        sta $9F29
        lda SLOPE_TOP_LEFT+1     ; X1 increment high (signed)
        sta $9F2A

        lda SLOPE_TOP_RIGHT      ; X2 increment low (signed)
        sta $9F2B                
        lda SLOPE_TOP_RIGHT+1    ; X2 increment high (signed)
        sta $9F2C    
    
        ; We determine which of LEFT or RIGHT is lower in y and chose number of rows to that point
        lda Y_DISTANCE_IS_NEGATED
        bne first_right_point_is_lower_in_y
first_left_point_is_lower_in_y:
        
        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            ldy Y_DISTANCE_LEFT_TOP
            
            lda #%00001010           ; DCSEL=5, ADDRSEL=0
            sta VERA_CTRL

            lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
            ldx $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
            
            jsr do_the_jump_to_the_table
        .else
            lda Y_DISTANCE_LEFT_TOP
            sta NUMBER_OF_ROWS
            
            ; -- We draw the first part of the triangle --
            jsr draw_polygon_part_using_polygon_filler_naively
        .endif
            

        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            ldy Y_DISTANCE_RIGHT_LEFT
            beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        .else
            lda Y_DISTANCE_RIGHT_LEFT
            beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
            sta NUMBER_OF_ROWS
        .endif
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
        ; Note: this *implicitly* resets the X1 subpixel position, which is what we want, since we start a new line/side of the triangle
    
        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_RIGHT_LEFT     ; X1 increment low
        sta $9F29
        lda SLOPE_RIGHT_LEFT+1   ; X1 increment high
        sta $9F2A

        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            lda #%00001010           ; DCSEL=5, ADDRSEL=0
            sta VERA_CTRL

            lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
            ldx $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
            
            jsr do_the_jump_to_the_table
        .else
            ; -- We draw the second part of the triangle --
            jsr draw_polygon_part_using_polygon_filler_naively
        .endif

        bra done_drawing_polygon_part_single_top
first_right_point_is_lower_in_y:
        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            ldy Y_DISTANCE_RIGHT_TOP
            
            lda #%00001010           ; DCSEL=5, ADDRSEL=0
            sta VERA_CTRL

            lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
            ldx $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
            
            jsr do_the_jump_to_the_table
        .else
            lda Y_DISTANCE_RIGHT_TOP
            sta NUMBER_OF_ROWS
            
            ; -- We draw the first part of the triangle --
            jsr draw_polygon_part_using_polygon_filler_naively
        .endif

        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            ldy Y_DISTANCE_RIGHT_LEFT
            beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        .else
            lda Y_DISTANCE_RIGHT_LEFT
            beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
            sta NUMBER_OF_ROWS
        .endif
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
        ; Note: this *implicitly* resets the X2 subpixel position, which is what we want, since we start a new line/side of the triangle
    
        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_RIGHT_LEFT     ; X2 increment low
        sta $9F2B                
        lda SLOPE_RIGHT_LEFT+1   ; X2 increment high
        sta $9F2C
        
        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            lda #%00001010           ; DCSEL=5, ADDRSEL=0
            sta VERA_CTRL

            lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
            ldx $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
            
            jsr do_the_jump_to_the_table
        .else
            ; -- We draw the second part of the triangle --
            jsr draw_polygon_part_using_polygon_filler_naively
        .endif
        
    .else
    
        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        ; NOTE that these increments are *WHOLE* steps!!
        MACRO_copy_slope_to_soft_incr SLOPE_TOP_LEFT, SOFT_X1_INCR, SOFT_X1_INCR_SUB
        MACRO_copy_slope_to_soft_incr SLOPE_TOP_RIGHT, SOFT_X2_INCR, SOFT_X2_INCR_SUB
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_TOP_LEFT, SOFT_X1_INCR_HALF, SOFT_X1_INCR_HALF_SUB
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_TOP_RIGHT, SOFT_X2_INCR_HALF, SOFT_X2_INCR_HALF_SUB

        ; We determine which of LEFT or RIGHT is lower in y and chose number of rows to that point
        lda Y_DISTANCE_IS_NEGATED
        bne soft_first_right_point_is_lower_in_y
soft_first_left_point_is_lower_in_y:
        lda Y_DISTANCE_LEFT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively

        lda Y_DISTANCE_RIGHT_LEFT
        beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        sta NUMBER_OF_ROWS
        
        ; We reset the X1 subpixel position here too, since we start a new line/side of the triangle
        stz SOFT_X1_SUB          ; Reset subpixel position X1 [0]
        lda #(256>>1)            ; Half a pixel
        sta SOFT_X1_SUB+1        ; Reset subpixel position X1 [8:1]
        
        ; NOTE that these increments are *WHOLE* steps!!
        MACRO_copy_slope_to_soft_incr SLOPE_RIGHT_LEFT, SOFT_X1_INCR, SOFT_X1_INCR_SUB
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_RIGHT_LEFT, SOFT_X1_INCR_HALF, SOFT_X1_INCR_HALF_SUB

        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively

        bra done_drawing_polygon_part_single_top
soft_first_right_point_is_lower_in_y:
        lda Y_DISTANCE_RIGHT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively

        lda Y_DISTANCE_RIGHT_LEFT
        beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        sta NUMBER_OF_ROWS
        
        ; We reset the X2 subpixel position here too, since we start a new line/side of the triangle
        stz SOFT_X2_SUB          ; Reset subpixel position X2 [0]
        lda #(256>>1)            ; Half a pixel
        sta SOFT_X2_SUB+1        ; Reset subpixel position X2 [8:1]
        
        ; NOTE that these increments are *WHOLE* steps!!
        MACRO_copy_slope_to_soft_incr SLOPE_RIGHT_LEFT, SOFT_X2_INCR, SOFT_X2_INCR_SUB
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_RIGHT_LEFT, SOFT_X2_INCR_HALF, SOFT_X2_INCR_HALF_SUB
        
        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively
    .endif
        
done_drawing_polygon_part_single_top:
    
    jmp done_drawing_polygon_part
    
    
draw_triangle_with_double_top_points:

    ; Note: we can assume here that:
    ;  - the triangle has a left-top point, its coordinate is on: LEFT_POINT_X/LEFT_POINT_Y
    ;  - the triangle has a right-top point, its coordinate is on: RIGHT_POINT_X/RIGHT_POINT_Y
    ;  - the left-top point and right-top point have the same y-coordinate
    ;  - the triangle has a single bottom point, its coordinate is in: BOTTOM_POINT_X/BOTTOM_POINT_Y
    ;  - the color of the triangle is in: TRIANGLE_COLOR

    ; We need to calculate 2 slopes for the 1 triangle part:
    ;  - the slope between LEFT and BOTTOM
    ;  - the slope between RIGHT and BOTTOM
    
    ; About slopes:
    ;  - slopes are up to 15+5=20 bits (signed) numbers: ranging from +-1024 pixels/2 down to +-(1/512th of a pixel)/2
    ;  - slopes are *half* the actual slope between two point (since they are increment in 2 steps)
    ;  - slopes are packed into a signed 15 bit + 1 "times 32"-bit 

    ; SPEED: cant we and use only 1 byte for Y? (since Y < 240 pixels)
    
    ; ============== BOTTOM POINT vs LEFT POINT ============
    
    .if(USE_POLYGON_FILLER && USE_SLOPE_TABLES && USE_180_DEGREES_SLOPE_TABLE)

        ; We subtract: X_DISTANCE:  BOTTOM_POINT_X - LEFT_POINT_X
        
        MACRO_subtract_x BOTTOM_POINT_X, LEFT_POINT_X, X_DISTANCE
        
        ; We subtract: Y_DISTANCE_BOTTOM_LEFT: BOTTOM_POINT_Y - LEFT_POINT_Y
        
        MACRO_subtract_y BOTTOM_POINT_Y, LEFT_POINT_Y, Y_DISTANCE_BOTTOM_LEFT
        
        ; Note: since we know the left point has a lower y than the bottom point, there is no need to negate it!
        
        MACRO_get_slope_from_180_degrees_slope_table Y_DISTANCE_BOTTOM_LEFT, SLOPE_LEFT_BOTTOM
        
    .else
        
        ; We subtract: X_DISTANCE:  BOTTOM_POINT_X - LEFT_POINT_X
        
        MACRO_subtract_and_make_positive_x BOTTOM_POINT_X, LEFT_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED
        
        ; We subtract: Y_DISTANCE_BOTTOM_LEFT: BOTTOM_POINT_Y - LEFT_POINT_Y
        
        MACRO_subtract_y BOTTOM_POINT_Y, LEFT_POINT_Y, Y_DISTANCE_BOTTOM_LEFT
        
        ; Note: since we know the left point has a lower y than the bottom point, there is no need to negate it!
        
        .if(USE_SLOPE_TABLES)
            MACRO_get_slope_from_slope_table Y_DISTANCE_BOTTOM_LEFT, SLOPE_LEFT_BOTTOM
        .else
            MACRO_calculate_slope_using_division Y_DISTANCE_BOTTOM_LEFT, SLOPE_LEFT_BOTTOM
        .endif
        
        ldx X_DISTANCE_IS_NEGATED
        beq slope_left_bottom_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
        
        MACRO_negate_slope SLOPE_LEFT_BOTTOM
        
slope_left_bottom_is_correctly_signed:

    .endif
        

    ; ============== BOTTOM POINT vs RIGHT POINT ============

    .if(USE_POLYGON_FILLER && USE_SLOPE_TABLES && USE_180_DEGREES_SLOPE_TABLE)
        
        ; We subtract: X_DISTANCE: BOTTOM_POINT_X - RIGHT_POINT_X
        
        MACRO_subtract_x BOTTOM_POINT_X, RIGHT_POINT_X, X_DISTANCE
        
        ; We subtract: Y_DISTANCE_BOTTOM_RIGHT: BOTTOM_POINT_Y - RIGHT_POINT_Y
        
        MACRO_subtract_y BOTTOM_POINT_Y, RIGHT_POINT_Y, Y_DISTANCE_BOTTOM_RIGHT
        
        ; Note: since we know the right point has a lower y than the bottom point, there is no need to negate it!
        
        MACRO_get_slope_from_180_degrees_slope_table Y_DISTANCE_BOTTOM_RIGHT, SLOPE_RIGHT_BOTTOM
        
    .else
        
        ; We subtract: X_DISTANCE: BOTTOM_POINT_X - RIGHT_POINT_X
        
        MACRO_subtract_and_make_positive_x BOTTOM_POINT_X, RIGHT_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED    
        
        ; We subtract: Y_DISTANCE_BOTTOM_RIGHT: BOTTOM_POINT_Y - RIGHT_POINT_Y
        
        MACRO_subtract_y BOTTOM_POINT_Y, RIGHT_POINT_Y, Y_DISTANCE_BOTTOM_RIGHT
        
        ; Note: since we know the right point has a lower y than the bottom point, there is no need to negate it!
        
        .if(USE_SLOPE_TABLES)
            MACRO_get_slope_from_slope_table Y_DISTANCE_BOTTOM_RIGHT, SLOPE_RIGHT_BOTTOM
        .else
            MACRO_calculate_slope_using_division Y_DISTANCE_BOTTOM_RIGHT, SLOPE_RIGHT_BOTTOM
        .endif
        
        ldx X_DISTANCE_IS_NEGATED
        beq slope_right_bottom_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
        
        MACRO_negate_slope SLOPE_RIGHT_BOTTOM
        
slope_right_bottom_is_correctly_signed:

    .endif

    ; -- We setup the starting x and y and the color --
    .if(USE_POLYGON_FILLER)
        ; Setting up for drawing a polygon, setting both addresses at the same starting point

        .if(USE_Y_TO_ADDRESS_TABLE)
            MACRO_set_address_using_y2address_table LEFT_POINT_Y
        .else
            MACRO_set_address_using_multiplication LEFT_POINT_Y
        .endif
    
        ; Setting x1 and x2 pixel position
        
        lda #%00001000           ; DCSEL=4, ADDRSEL=0
        sta VERA_CTRL
        
        lda LEFT_POINT_X
        sta $9F29                ; X (=X1) pixel position low [7:0]
        lda RIGHT_POINT_X
        sta $9F2B                ; Y (=X2) pixel position low [7:0]
        
        ; NOTE: we are also *setting* the subpixel position (bit0) here! Even though we just resetted it! 
        ;       but its ok, since its reset to half a pixel (see above), meaning bit0 is 0 anyway
        lda LEFT_POINT_X+1
        sta $9F2A                ; X subpixel position[0] = 0, X (=X1) pixel position high [10:8]
        lda RIGHT_POINT_X+1
        ora #%00100000           ; Reset subpixel position
        sta $9F2C                ; Y subpixel position[0] = 0, Y (=X2) pixel position high [10:8]

        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
    
        ldy TRIANGLE_COLOR      ; We use y as color
    .else 
    
        ; Setting up for drawing a polygon, setting both X1 and X2 positions at the same starting point
        
        ; Note: without the polygon filler helper we *only* use ADDR1, not ADDR0

        lda #%00000000           ; DCSEL=0, ADDRSEL=0
        sta VERA_CTRL

        ; Setting starting (sub)pixel position X1 and X2
        stz SOFT_X1_SUB          ; Reset subpixel position X1 [0]
        stz SOFT_X2_SUB          ; Reset subpixel position X2 [0]

        lda #(256>>1)            ; Half a pixel
        sta SOFT_X1_SUB+1        ; Reset subpixel position X1 [8:1]
        sta SOFT_X2_SUB+1        ; Reset subpixel position X2 [8:1]
        
        lda LEFT_POINT_X
        sta SOFT_X1              ; X1 pixel position low [7:0]
        lda RIGHT_POINT_X
        sta SOFT_X2              ; X2 pixel position low [7:0]
        
        lda LEFT_POINT_X+1
        sta SOFT_X1+1            ; X1 pixel position high [10:8]
        lda RIGHT_POINT_X+1
        sta SOFT_X2+1            ; X2 pixel position high [10:8]
        
        ; Starting Y
        lda LEFT_POINT_Y
        sta SOFT_Y
        lda LEFT_POINT_Y+1
        sta SOFT_Y+1
        
        ldy TRIANGLE_COLOR      ; We use y as color
        
    .endif


    .if(USE_POLYGON_FILLER)

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL

        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_LEFT_BOTTOM    ; X1 increment low (signed)
        sta $9F29
        lda SLOPE_LEFT_BOTTOM+1  ; X1 increment high (signed)
        sta $9F2A

        lda SLOPE_RIGHT_BOTTOM   ; X2 increment low (signed)
        sta $9F2B                
        lda SLOPE_RIGHT_BOTTOM+1 ; X2 increment high (signed)
        sta $9F2C    
    
        .if(USE_JUMP_TABLE && !TEST_JUMP_TABLE)
            ldy Y_DISTANCE_LEFT_TOP
            
            lda #%00001010           ; DCSEL=5, ADDRSEL=0
            sta VERA_CTRL

            lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
            ldx $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
            
            jsr do_the_jump_to_the_table
        .else
            lda Y_DISTANCE_LEFT_TOP
            sta NUMBER_OF_ROWS
            
            ; -- We draw the first (and only) part of the triangle --
            jsr draw_polygon_part_using_polygon_filler_naively
        .endif
        
    .else

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        ; NOTE that these increments are *WHOLE* steps!!
        MACRO_copy_slope_to_soft_incr SLOPE_LEFT_BOTTOM, SOFT_X1_INCR, SOFT_X1_INCR_SUB
        MACRO_copy_slope_to_soft_incr SLOPE_RIGHT_BOTTOM, SOFT_X2_INCR, SOFT_X2_INCR_SUB
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_LEFT_BOTTOM, SOFT_X1_INCR_HALF, SOFT_X1_INCR_HALF_SUB
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_RIGHT_BOTTOM, SOFT_X2_INCR_HALF, SOFT_X2_INCR_HALF_SUB
    
        lda Y_DISTANCE_LEFT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first (and only) part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively
        
    .endif
        
    jmp done_drawing_polygon_part
    
    

    
draw_polygon_part_using_software_polygon_filler_naively:

    ; First we will increment x1 and x2 with *HALF* the normal increment (32-bit add)
    
    clc
    lda SOFT_X1_SUB
    adc SOFT_X1_INCR_HALF_SUB
    sta SOFT_X1_SUB
    lda SOFT_X1_SUB+1
    adc SOFT_X1_INCR_HALF_SUB+1
    sta SOFT_X1_SUB+1
    lda SOFT_X1
    adc SOFT_X1_INCR_HALF
    sta SOFT_X1
    lda SOFT_X1+1
    adc SOFT_X1_INCR_HALF+1
    sta SOFT_X1+1
    
    clc
    lda SOFT_X2_SUB
    adc SOFT_X2_INCR_HALF_SUB
    sta SOFT_X2_SUB
    lda SOFT_X2_SUB+1
    adc SOFT_X2_INCR_HALF_SUB+1
    sta SOFT_X2_SUB+1
    lda SOFT_X2
    adc SOFT_X2_INCR_HALF
    sta SOFT_X2
    lda SOFT_X2+1
    adc SOFT_X2_INCR_HALF+1
    sta SOFT_X2+1

    
soft_polygon_fill_triangle_row_next:

    .if(USE_Y_TO_ADDRESS_TABLE)
        MACRO_set_address_using_y2address_table_and_point_x SOFT_Y, SOFT_X1
    .else
        MACRO_set_address_using_multiplication_and_point_x SOFT_Y, SOFT_X1
    .endif
    
;    sty VERA_DATA0
;    
;    .if(USE_Y_TO_ADDRESS_TABLE)
;        MACRO_set_address_using_y2address_table_and_point_x SOFT_Y, SOFT_X2
;    .else
;        MACRO_set_address_using_multiplication_and_point_x SOFT_Y, SOFT_X2
;    .endif
;    
;    sty VERA_DATA0
    
    sec
    lda SOFT_X2
    sbc SOFT_X1
    sta FILL_LENGTH_LOW
    lda SOFT_X2+1
    sbc SOFT_X1+1
    sta FILL_LENGTH_HIGH


    .if(USE_UNROLLED_LOOP)
        lda FILL_LENGTH_LOW
        beq soft_done_fill_triangle_pixel_0  ; If FILL_LENGTH_LOW = 0, we dont have to draw any pixels
        and #%00111111
        beq soft_done_fill_triangle_pixel_0_still_64  ; If FILL_LENGTH_LOW[5:0] = 0, we dont have to draw any pixels
        sta RAM_BANK
        jsr DRAW_ROW_64_CODE
        
soft_done_fill_triangle_pixel_0_still_64:
        lda FILL_LENGTH_LOW
        and #%11000000
        beq soft_done_fill_triangle_pixel_0  ; If FILL_LENGTH_LOW[7:6] = 0, we dont have to draw any pixels
        
        ; We need the two highest bits of FILL_LENGTH_LOW as the two lowest bits
        stz TMP2
        asl FILL_LENGTH_LOW
        rol TMP2
        asl FILL_LENGTH_LOW
        rol TMP2
        
        ; We draw 64 pixels each time here
        stz RAM_BANK
        ldx TMP2
soft_polygon_fill_triangle_pixel_next_64:
        jsr DRAW_ROW_64_CODE
        dex
        bne soft_polygon_fill_triangle_pixel_next_64
    .else
        ldx FILL_LENGTH_LOW
        
        ; If FILL_LENGTH_LOW = 0, we dont have to draw any pixels
        beq soft_done_fill_triangle_pixel_0
soft_polygon_fill_triangle_pixel_next_0:    
        ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
        sty VERA_DATA0
        dex
        bne soft_polygon_fill_triangle_pixel_next_0

    .endif
soft_done_fill_triangle_pixel_0:
    
    ; We draw an additional FILL_LENGTH_HIGH * 256 pixels on this row
    lda FILL_LENGTH_HIGH
    beq soft_polygon_fill_triangle_row_done

    .if(USE_UNROLLED_LOOP)
soft_polygon_fill_triangle_pixel_next_256:
        stz RAM_BANK
        jsr DRAW_ROW_64_CODE
        jsr DRAW_ROW_64_CODE
        jsr DRAW_ROW_64_CODE
        jsr DRAW_ROW_64_CODE
        dec FILL_LENGTH_HIGH
        bne soft_polygon_fill_triangle_pixel_next_256
    .else
        ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
soft_polygon_fill_triangle_pixel_next_256:
        ldx #0
soft_polygon_fill_triangle_pixel_next_256_0:
        sty VERA_DATA0
        dex
        bne soft_polygon_fill_triangle_pixel_next_256_0
        dec FILL_LENGTH_HIGH
        bne soft_polygon_fill_triangle_pixel_next_256
    .endif
    
soft_polygon_fill_triangle_row_done:
    
    ; We always increment SOFT_Y
    inc SOFT_Y
    ; FIXME: we are now assuming a max value of 240, so no need for SOFT_Y+1

    
    ; We check if we have reached the end, if so, we do *NOT* do a WHOLE increment!
    dec NUMBER_OF_ROWS
    beq soft_polygon_fill_triangle_done

    ; Do a *WHOLE* increment (24-bit add)
    clc
    lda SOFT_X1_SUB+1
    adc SOFT_X1_INCR_SUB+1
    sta SOFT_X1_SUB+1
    lda SOFT_X1
    adc SOFT_X1_INCR
    sta SOFT_X1
    lda SOFT_X1+1
    adc SOFT_X1_INCR+1
    sta SOFT_X1+1
    
    clc
    lda SOFT_X2_SUB+1
    adc SOFT_X2_INCR_SUB+1
    sta SOFT_X2_SUB+1
    lda SOFT_X2
    adc SOFT_X2_INCR
    sta SOFT_X2
    lda SOFT_X2+1
    adc SOFT_X2_INCR+1
    sta SOFT_X2+1

    jmp soft_polygon_fill_triangle_row_next
    
soft_polygon_fill_triangle_done:

    ; When we are done we increment the other *HALF* (32-bit add)
    clc
    lda SOFT_X1_SUB
    adc SOFT_X1_INCR_HALF_SUB
    sta SOFT_X1_SUB
    lda SOFT_X1_SUB+1
    adc SOFT_X1_INCR_HALF_SUB+1
    sta SOFT_X1_SUB+1
    lda SOFT_X1
    adc SOFT_X1_INCR_HALF
    sta SOFT_X1
    lda SOFT_X1+1
    adc SOFT_X1_INCR_HALF+1
    sta SOFT_X1+1
    
    clc
    lda SOFT_X2_SUB
    adc SOFT_X2_INCR_HALF_SUB
    sta SOFT_X2_SUB
    lda SOFT_X2_SUB+1
    adc SOFT_X2_INCR_HALF_SUB+1
    sta SOFT_X2_SUB+1
    lda SOFT_X2
    adc SOFT_X2_INCR_HALF
    sta SOFT_X2
    lda SOFT_X2+1
    adc SOFT_X2_INCR_HALF+1
    sta SOFT_X2+1
    
    rts
    
    
; FIXME: UGLY and SLOW! -> this ensures this works with TEST_JUMP_TABLE! (which contains an rts)
do_the_jump_to_the_table:
    jmp (FILL_LINE_JUMP_TABLE,x)

draw_polygon_part_using_polygon_filler_naively:

; FIXME
;    rts

    lda #%00001010           ; DCSEL=5, ADDRSEL=0
    sta VERA_CTRL

    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
polygon_fill_triangle_row_next:

    .if(USE_JUMP_TABLE)
        ldx $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
        
        jsr do_the_jump_to_the_table
    
        ; We always increment ADDR0
        lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (= +1 vertically)
        
        ; We check if we have reached the end, if so, we do *NOT* change ADDR1!
        dec NUMBER_OF_ROWS
        beq polygon_fill_triangle_done_table
        
        lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
        bra polygon_fill_triangle_row_next
    
polygon_fill_triangle_done_table:
    
; FIXME: this is a bit of an UGLY HACK! We should create a macro that does the polygon filling using the jump tables
        rts
    .endif

    
; FIXME!
; FIXME!
; FIXME!
;    stz VERA_DATA1
;    jmp polygon_fill_triangle_row_done


    ; SLOW: we are not using all the information we get and are only reconstructing the 10-bit value. But this should normally *not*
    ;       be done! The bits are crafted in such a way to be used for a jump table. But for this example we dont use a jump table,
    ;       since it will be a bit more readably that way.
    
    stz FILL_LENGTH_HIGH
    
    lda $9F2B               ; This contains: X1[1:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0], 0
    lsr
    and #%00000111          ; we keep the 3 lower bits (bit 4 is ALSO in the HIGH byte, so we discard it here)
    sta FILL_LENGTH_LOW

    lda $9F2C               ; This contains FILL_LENGTH[9:3], 0
    asl
    rol FILL_LENGTH_HIGH
    asl
    rol FILL_LENGTH_HIGH
    ora FILL_LENGTH_LOW
    sta FILL_LENGTH_LOW

    .if(USE_UNROLLED_LOOP)
        lda FILL_LENGTH_LOW
        beq done_fill_triangle_pixel_0  ; If FILL_LENGTH_LOW = 0, we dont have to draw any pixels
        and #%00111111
        beq done_fill_triangle_pixel_0_still_64  ; If FILL_LENGTH_LOW[5:0] = 0, we dont have to draw any pixels
        sta RAM_BANK
        jsr DRAW_ROW_64_CODE
        
done_fill_triangle_pixel_0_still_64:
        lda FILL_LENGTH_LOW
        and #%11000000
        beq done_fill_triangle_pixel_0  ; If FILL_LENGTH_LOW[7:6] = 0, we dont have to draw any pixels
        
        ; We need the two highest bits of FILL_LENGTH_LOW as the two lowest bits
        stz TMP2
        asl FILL_LENGTH_LOW
        rol TMP2
        asl FILL_LENGTH_LOW
        rol TMP2
        
        ; We draw 64 pixels each time here
        stz RAM_BANK
        ldx TMP2
polygon_fill_triangle_pixel_next_64:
        jsr DRAW_ROW_64_CODE
        dex
        bne polygon_fill_triangle_pixel_next_64
    .else
        
        ; FIXME: what if FILL_LENGTH_LOW/FILL_LENGTH_HIGH are 0 or NEGATIVE? -> OR deal with this on the VERA side?
        
        tax
        
        ; FIXME: should we do this +1 here or inside of VERA? -> note: when x = 255, 256 pixels will be drawn (which is what we want right now)
    ;    inx
        
        ; If x = 0, we dont have to draw any pixels
        beq done_fill_triangle_pixel_0
polygon_fill_triangle_pixel_next_0:
        ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
        sty VERA_DATA1
        dex
        bne polygon_fill_triangle_pixel_next_0

    .endif
done_fill_triangle_pixel_0:

    ; We draw an additional FILL_LENGTH_HIGH * 256 pixels on this row
    lda FILL_LENGTH_HIGH
    beq polygon_fill_triangle_row_done

    .if(USE_UNROLLED_LOOP)
polygon_fill_triangle_pixel_next_256:
        stz RAM_BANK
        jsr DRAW_ROW_64_CODE
        jsr DRAW_ROW_64_CODE
        jsr DRAW_ROW_64_CODE
        jsr DRAW_ROW_64_CODE
        dec FILL_LENGTH_HIGH
        bne polygon_fill_triangle_pixel_next_256
    .else
        ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
polygon_fill_triangle_pixel_next_256:
        ldx #0
polygon_fill_triangle_pixel_next_256_0:
        sty VERA_DATA1
        dex
        bne polygon_fill_triangle_pixel_next_256_0
        dec FILL_LENGTH_HIGH
        bne polygon_fill_triangle_pixel_next_256
    .endif
    
polygon_fill_triangle_row_done:
    
    ; We always increment ADDR0
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (= +1 vertically)
    
    ; We check if we have reached the end, if so, we do *NOT* change ADDR1!
    dec NUMBER_OF_ROWS
    beq polygon_fill_triangle_done
    
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    bra polygon_fill_triangle_row_next
    
polygon_fill_triangle_done:
    
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
    
    lda VRAM_ADDRESS+2
    adc #0
    sta VRAM_ADDRESS+2
    .if(USE_POLYGON_FILLER)
        ora #%11100000              ; For polygon filler helper: auto-increment = 320
    .else
        ora #%00010000              ; Without polygon filler helper: auto-increment = 1
    .endif
    sta Y_TO_ADDRESS_BANK, y
    
    iny
    
    cpy #240
    bne generate_next_y_to_address_entry

    rts
    
    
; NOTE: we are now using ROM banks to contain tables. We need to copy those tables to Banked RAM, but have to run that copy-code in Fixed RAM.
    
copy_slope_table_copier_to_ram:

    ; Copying copy_slope_tables_to_banked_ram -> COPY_SLOPE_TABLES_TO_BANKED_RAM
    
    ldy #0
copy_tables_to_banked_ram_byte:
    lda copy_slope_tables_to_banked_ram, y
    sta COPY_SLOPE_TABLES_TO_BANKED_RAM, y
    iny 
    cpy #(end_of_copy_slope_tables_to_banked_ram-copy_slope_tables_to_banked_ram)
    bne copy_tables_to_banked_ram_byte

    rts
    

    .if(USE_POLYGON_FILLER)
    
copy_slope_tables_to_banked_ram:

    ; We copy 10 tables to banked RAM, but we pack them in such a way that they are easily accessible

    lda #1               ; Our first tables starts at ROM Bank 1
    sta TABLE_ROM_BANK
    
next_table_to_copy:    
    lda #<($C000)        ; Our source table starts at C000
    sta LOAD_ADDRESS
    lda #>($C000)
    sta LOAD_ADDRESS+1

    lda #<($A000)        ; We store at Ax00
    sta STORE_ADDRESS
    
    clc
    lda #>($A000)        ; We put the 5 columns of tables (LOW/HIGH): A0/A1, A2/A3, A4/A5, A6/A7, A8/A9
    adc TABLE_ROM_BANK
    sec
    sbc #1               ; since the TABLE_ROM_BANK starts at 1, we substract one from it
    sta STORE_ADDRESS+1

    ; Switching ROM BANK
    lda TABLE_ROM_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
        ldx #0                             ; x = x-coordinate (within a column of 64)
next_x_to_copy_to_banked_ram:
        ; Switching to RAM BANK x
        stx RAM_BANK
    ; FIXME: remove nop!
        nop
        
        ldy #0                             ; y = y-coordinate (0-239)
next_byte_to_copy_to_banked_ram:
        lda (LOAD_ADDRESS), y
        sta (STORE_ADDRESS), y
        iny
        cpy #240
        bne next_byte_to_copy_to_banked_ram
        
        ; We increment LOAD_ADDRESS by 256 bytes to move to the next x  (there is 240 bytes of data + 16 bytes of padding for each x)
        clc
        lda LOAD_ADDRESS
        adc #<256
        sta LOAD_ADDRESS
        lda LOAD_ADDRESS+1
        adc #>256
        sta LOAD_ADDRESS+1
        
        inx
        cpx #64
        bne next_x_to_copy_to_banked_ram

    inc TABLE_ROM_BANK
    lda TABLE_ROM_BANK
    cmp #11               ; we go from 1-10 so we need to stop at 11
    bne next_table_to_copy

    
    .if(USE_180_DEGREES_SLOPE_TABLE)
        
        ; We copy ANOTHER 10 tables (but for NEGATIVE slopes) to banked RAM, but we pack them in such a way that they are easily accessible

        lda #11               ; Our first tables starts at ROM Bank 11
        sta TABLE_ROM_BANK
    
next_table_to_copy_neg:
        lda #<($C000)        ; Our source table starts at C000
        sta LOAD_ADDRESS
        lda #>($C000)
        sta LOAD_ADDRESS+1

        lda #<($B600)        ; We store at Bx00
        sta STORE_ADDRESS
        
        clc
        lda #>($B600)        ; We put the 5 columns of tables (LOW/HIGH): B6/B7, B8/B9, BA/BB, BC/BD, BE/BF
        adc TABLE_ROM_BANK
        sec
        sbc #11              ; since the TABLE_ROM_BANK starts at 11, we substract one from it
        sta STORE_ADDRESS+1

        ; Switching ROM BANK
        lda TABLE_ROM_BANK
        sta ROM_BANK
    ; FIXME: remove nop!
        nop
        
            ldx #0                             ; x = x-coordinate (within a column of 64)
next_x_to_copy_to_banked_ram_neg:
            ; Switching to RAM BANK x
            stx RAM_BANK
        ; FIXME: remove nop!
            nop
            
            ldy #0                             ; y = y-coordinate (0-239)
next_byte_to_copy_to_banked_ram_neg:
            lda (LOAD_ADDRESS), y
            sta (STORE_ADDRESS), y
            iny
            cpy #240
            bne next_byte_to_copy_to_banked_ram_neg
            
            ; We increment LOAD_ADDRESS by 256 bytes to move to the next x  (there is 240 bytes of data + 16 bytes of padding for each x)
            clc
            lda LOAD_ADDRESS
            adc #<256
            sta LOAD_ADDRESS
            lda LOAD_ADDRESS+1
            adc #>256
            sta LOAD_ADDRESS+1
            
            inx
            cpx #64
            bne next_x_to_copy_to_banked_ram_neg

        inc TABLE_ROM_BANK
        lda TABLE_ROM_BANK
        cmp #21               ; we go from 11-20 so we need to stop at 21
        bne next_table_to_copy_neg
    
    .endif
    
    
    ; Switching back to ROM bank 0
    lda #$00
    sta ROM_BANK
; FIXME: remove nop!
    nop
   
    rts
end_of_copy_slope_tables_to_banked_ram:

    .else
    
copy_slope_tables_to_banked_ram:

    ; We copy 15+5 tables (15 real, 5 dummy) to banked RAM, but we pack them in such a way that they are easily accessible

    lda #1               ; Our first tables starts at ROM Bank 1
    sta TABLE_ROM_BANK
    
next_table_to_copy:    
    lda #<($C000)        ; Our source table starts at C000
    sta LOAD_ADDRESS
    lda #>($C000)
    sta LOAD_ADDRESS+1

    lda #<($A000)        ; We store at Ax00
    sta STORE_ADDRESS
    
    clc
    lda #>($A000)
    adc TABLE_ROM_BANK
    sec
    sbc #1               ; since the TABLE_ROM_BANK starts at 1, we substract one from it
    sta STORE_ADDRESS+1

    ; Switching ROM BANK
    lda TABLE_ROM_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
        ldx #0                             ; x = x-coordinate (within a column of 64)
next_x_to_copy_to_banked_ram:
        ; Switching to RAM BANK x
        stx RAM_BANK
    ; FIXME: remove nop!
        nop
        
        ldy #0                             ; y = y-coordinate (0-239)
next_byte_to_copy_to_banked_ram:
        lda (LOAD_ADDRESS), y
        sta (STORE_ADDRESS), y
        iny
        cpy #240
        bne next_byte_to_copy_to_banked_ram
        
        ; We increment LOAD_ADDRESS by 256 bytes to move to the next x  (there is 240 bytes of data + 16 bytes of padding for each x)
        clc
        lda LOAD_ADDRESS
        adc #<256
        sta LOAD_ADDRESS
        lda LOAD_ADDRESS+1
        adc #>256
        sta LOAD_ADDRESS+1
        
        inx
        cpx #64
        bne next_x_to_copy_to_banked_ram

    inc TABLE_ROM_BANK
    lda TABLE_ROM_BANK
    cmp #21               ; we go from 1-20 so we need to stop at 21
    bne next_table_to_copy

    ; Switching back to ROM bank 0
    lda #$00
    sta ROM_BANK
; FIXME: remove nop!
    nop
   
    rts
end_of_copy_slope_tables_to_banked_ram:
    
    .endif

    
    
generate_draw_row_64_code:

    lda #64                 ; We start at draw length of 64 (we do this *instead* of draw length 0)
    sta DRAW_LENGTH
next_draw_64_length:
    lda #<DRAW_ROW_64_CODE
    sta CODE_ADDRESS
    lda #>DRAW_ROW_64_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    lda DRAW_LENGTH
    and #%00111111         ; if DRAW_LENGTH == 64, this will set RAM_BANK to 0
    sta RAM_BANK
    
    ldx #0                 ; counts nr of draw instructions

next_draw_64_instruction:

    ; -- sty VERA_DATA0/1 ($9F23/4)
    lda #$8C               ; sty ....
    jsr add_code_byte
    
    .if(USE_POLYGON_FILLER)
        lda #$24               ; $24
        jsr add_code_byte
    .else 
        lda #$23               ; $23
        jsr add_code_byte
    .endif
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx DRAW_LENGTH        ; draw pixels written to VERA
    bne next_draw_64_instruction

    ; -- rts --
    lda #$60
    jsr add_code_byte

    dec DRAW_LENGTH
    bne next_draw_64_length
    
    
    rts

    
    
add_code_byte:
    sta (CODE_ADDRESS),y   ; store code byte at address (located at CODE_ADDRESS) + y
    iny                    ; increase y
    cpy #0                 ; if y == 0
    bne done_adding_code_byte
    inc CODE_ADDRESS+1     ; increment high-byte of CODE_ADDRESS
done_adding_code_byte:
    rts

    
    
; =========== FIXME: put this somewhere else! ==============
; https://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product
multply_16bits:
    phx
    lda    #$00
    sta    PRODUCT+2    ; clear upper bits of PRODUCT
    sta    PRODUCT+3
    ldx    #$10         ; set binary count to 16
shift_r:
    lsr    MULTIPLIER+1 ; divide MULTIPLIER by 2
    ror    MULTIPLIER
    bcc    rotate_r
    lda    PRODUCT+2    ; get upper half of PRODUCT and add MULTIPLICAND
    clc
    adc    MULTIPLICAND
    sta    PRODUCT+2
    lda    PRODUCT+3
    adc    MULTIPLICAND+1
rotate_r:
    ror                 ; rotate partial PRODUCT
    sta    PRODUCT+3
    ror    PRODUCT+2
    ror    PRODUCT+1
    ror    PRODUCT
    dex
    bne    shift_r
    plx

    rts
    
; FIXME: put this somewhere else!
; https://codebase64.org/doku.php?id=base:24bit_division_24-bit_result
divide_24bits:
    phx
    phy

    lda #0            ; preset REMAINDER to 0
    sta REMAINDER
    sta REMAINDER+1
    sta REMAINDER+2
    ldx #24            ; repeat for each bit: ...

div24loop:
    asl DIVIDEND    ; DIVIDEND lb & hb*2, msb -> Carry
    rol DIVIDEND+1
    rol DIVIDEND+2
    rol REMAINDER    ; REMAINDER lb & hb * 2 + msb from carry
    rol REMAINDER+1
    rol REMAINDER+2
    lda REMAINDER
    sec
    sbc DIVISOR        ; substract DIVISOR to see if it fits in
    tay                ; lb result -> Y, for we may need it later
    lda REMAINDER+1
    sbc DIVISOR+1
    sta TMP1
    lda REMAINDER+2
    sbc DIVISOR+2
    bcc div24skip     ; if carry=0 then DIVISOR didnt fit in yet

    sta REMAINDER+2 ; else save substraction result as new REMAINDER,
    lda TMP1
    sta REMAINDER+1
    sty REMAINDER
    inc DIVIDEND    ; and INCrement result cause DIVISOR fit in 1 times

div24skip:
    dex
    bne div24loop

    ply
    plx
    rts
; =========== / FIXME: put this somewhere else! ==============
