
    
generate_single_fill_line_code:
    
    ; This routines expects this:
    ;    FILL_LENGTH_LOW (4-bit)   : FILL_LENGTH >= 8,  X1[1:0], X1[2], FILL_LENGTH[2:0], 0

    ; == We first extract this info (4-bit) ==
    ;
    ;   GEN_START_X[2:0]
    ;   GEN_FILL_LENGTH_LOW = [2:0]
    ;   GEN_FILL_LENGTH_IS_8_OR_MORE
    
    lda FILL_LENGTH_LOW
    asl                   ; We remove the bit for FILL_LENGTH >= 8
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr                   ; We keep the X1[1:0] part
    sta GEN_START_X
    
    lda FILL_LENGTH_LOW
    and #%00010000        ; X1[2], 0000b
    lsr
    lsr                   ; X1[2], 00b
    ora GEN_START_X       ; OR with X1[1:0]
    sta GEN_START_X       ; X1[2:0]
    
    lda FILL_LENGTH_LOW
    lsr
    and #%00000111
    sta GEN_FILL_LENGTH_LOW ; FILL_LENGTH[2:0]
    
    lda FILL_LENGTH_LOW
    and #%10000000
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    sta GEN_FILL_LENGTH_IS_8_OR_MORE
    
    stz GEN_LOANED_8_PIXELS
    
    ; ================================  

    
    ; -- NR_OF_STARTING_PIXELS = 8 - GEN_START_X --
    sec
    lda #8
    sbc GEN_START_X
    sta NR_OF_STARTING_PIXELS

    ; -- NR_OF_ENDING_PIXELS = (GEN_START_X + GEN_FILL_LENGTH_LOW) % 8 --
    clc
    lda GEN_START_X
    adc GEN_FILL_LENGTH_LOW
    and #%00000111
    sta NR_OF_ENDING_PIXELS               ; the lower 3 bits contain the nr of ending pixels
    
    ; -- we start with LEFT_OVER_PIXELS = GEN_FILL_LENGTH_LOW --
    stz LEFT_OVER_PIXELS+1
    lda GEN_FILL_LENGTH_LOW
    sta LEFT_OVER_PIXELS
    
    ; -- check if more than or equal to 8 extra pixels have to be drawn
    lda GEN_FILL_LENGTH_IS_8_OR_MORE
    bne gen_more_or_equal_to_8_pixels
    
gen_less_than_8_pixels:

    ; If we have less than 8 pixels AND fill length low == 0, we have nothing to do, so we go to the end
    lda GEN_FILL_LENGTH_LOW
    beq gen_ending_pixels_are_generated

    ; ===== We need to check if the starting and ending pixels are in the same 8-pixel colum ====
    ; check if GEN_START_X + GEN_FILL_LENGTH_LOW >= 8
    clc
    lda GEN_START_X
    adc GEN_FILL_LENGTH_LOW
    cmp #8
    bcc gen_start_and_end_in_same_column  ; we end in the same 8-pixel column as where we start
    beq gen_start_and_end_in_same_column
    
    ; ============= generate starting pixels code (< 8 pixels) ===============

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
    
    
gen_more_or_equal_to_8_pixels:

    ; ============= generate starting pixels code (>=8 pixels) ===============

    ; if NR_OF_STARTING_PIXELS == 8 (meaning GEN_START_X == 0) we do not subtract 8 of the total left-over pixel count and we do NOT generate starting pixels!
    lda NR_OF_STARTING_PIXELS
    cmp #8
    beq gen_generate_jump_to_second_table
    
gen_generate_starting_pixels_8:

    ; -- we subtract the starting pixels from LEFT_OVER_PIXELS --
    sec
    lda LEFT_OVER_PIXELS
    sbc NR_OF_STARTING_PIXELS
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    sbc #0
    sta LEFT_OVER_PIXELS+1
    
    ; if NR_OF_STARTING_PIXELS > LEFT_OVER_PIXELS (which is possible since LEFT_OVER_PIXELS == GEN_FILL_LENGTH_LOW and >8 fill length)
    ; we should *LOAN* 8 pixels. So we add 8 pixels here, and subtract it by jumping 2*stz later in the code fill code.
    bpl do_not_loan_pixels
    
    clc
    lda LEFT_OVER_PIXELS
    adc #8
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    adc #0
    sta LEFT_OVER_PIXELS+1
    
    lda #1
    sta GEN_LOANED_8_PIXELS
    
do_not_loan_pixels:
    jsr generate_draw_starting_pixels_code

gen_generate_jump_to_second_table:

    ;   Note: the table is reversed: since the higher y-number will the less pixels. (so the *beginning* of the table will point to the *end* of the code), when no stz-calls are made)

    lda #<FILL_LINE_END_JUMP_0
    sta END_JUMP_ADDRESS
    lda #>FILL_LINE_END_JUMP_0
    ora NR_OF_ENDING_PIXELS     ; We set the *three* lower bits of the HIGH byte of the JUMP TABLE address to indicate which jump table we want to jump to
    sta END_JUMP_ADDRESS+1

    lda GEN_LOANED_8_PIXELS
    beq jump_address_is_valid
    
    ; if GEN_LOANED_8_PIXELS == 1 we should jump as-if 8 pixels less have to be drawn -> so we subtract 2 bytes (1 jump address)
    
    sec
    lda END_JUMP_ADDRESS
    sbc #2
    sta END_JUMP_ADDRESS
    lda END_JUMP_ADDRESS+1
    sbc #0
    sta END_JUMP_ADDRESS+1
    
; FIXME: CHECK: if exactly 8 pixels have to be drawn due to the HIGH fill length, we should not draw any pixels!
    
jump_address_is_valid:

    jsr generate_table_jump
    
    rts
    
    
    
generate_fill_line_end_code:

    ; -------------- FILL_LINE_END_CODE_0 ---------------
    
    lda #<FILL_LINE_END_CODE_0
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_0
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; Note: for FILL_LINE_END_CODE_0 there is no additional (sub 4 byte) pixel draw
    
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif

    ; -------------- FILL_LINE_END_CODE_1 ---------------

    lda #<FILL_LINE_END_CODE_1
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_1
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11111101         ; NIBBLE_PATTERN = 1 pixel at the end
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
    
    ; -------------- FILL_LINE_END_CODE_2 ---------------

    lda #<FILL_LINE_END_CODE_2
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_2
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11111100         ; NIBBLE_PATTERN = 2 pixels at the end
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
    
    ; -------------- FILL_LINE_END_CODE_3 ---------------

    lda #<FILL_LINE_END_CODE_3
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_3
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11110100         ; NIBBLE_PATTERN = 3 pixels at the end
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

    
    ; -------------- FILL_LINE_END_CODE_4 ---------------

    lda #<FILL_LINE_END_CODE_4
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_4
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11110000         ; NIBBLE_PATTERN = 4 pixels at the end
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

    ; -------------- FILL_LINE_END_CODE_5 ---------------

    lda #<FILL_LINE_END_CODE_5
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_5
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11010000         ; NIBBLE_PATTERN = 5 pixels at the end
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

    ; -------------- FILL_LINE_END_CODE_6 ---------------

    lda #<FILL_LINE_END_CODE_6
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_6
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%11000000         ; NIBBLE_PATTERN = 6 pixels at the end
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

    ; -------------- FILL_LINE_END_CODE_7 ---------------

    lda #<FILL_LINE_END_CODE_7
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_7
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    lda #%01000000         ; NIBBLE_PATTERN = 7 pixels at the end
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

    
generate_fill_line_end_jump:

    lda #<FILL_LINE_END_JUMP_0
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_0
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_0+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_0+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8

    
    lda #<FILL_LINE_END_JUMP_1
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_1
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_1+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_1+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8
    
    
    lda #<FILL_LINE_END_JUMP_2
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_2
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_2+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_2+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8
    
    
    lda #<FILL_LINE_END_JUMP_3
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_3
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_3+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_3+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8

    lda #<FILL_LINE_END_JUMP_4
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_4
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_4+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_4+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8

    
    lda #<FILL_LINE_END_JUMP_5
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_5
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_5+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_5+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8
    
    
    lda #<FILL_LINE_END_JUMP_6
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_6
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_6+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_6+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8
    
    
    lda #<FILL_LINE_END_JUMP_7
    sta STORE_ADDRESS
    lda #>FILL_LINE_END_JUMP_7
    sta STORE_ADDRESS+1
    
    ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
    lda #<(FILL_LINE_END_CODE_7+40*3)
    sta LOAD_ADDRESS
    lda #>(FILL_LINE_END_CODE_7+40*3)
    sta LOAD_ADDRESS+1
    
    jsr generate_jump_table_8
    
    
    rts

    
generate_jump_table_8:

    ; We backup the address of the *end* of the the series of 40 'stz'-calls
    lda LOAD_ADDRESS
    sta TMP1
    lda LOAD_ADDRESS+1
    sta TMP2

    ldy #0
generate_next_jump_table_8_entry:

    lda LOAD_ADDRESS
    sta (STORE_ADDRESS), y
    iny
    lda LOAD_ADDRESS+1
    sta (STORE_ADDRESS), y
    iny

    sec
    lda LOAD_ADDRESS
    sbc #3               ; we need to skip 8 pixels (4-bit), so one time a stz, this is 3 bytes of code
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    sbc #0
    sta LOAD_ADDRESS+1
    
    cpy #80+2                ; We need 40 entries of 8 pixels (=320 pixels) *plus* an entry for 0 pixels. Each entry is 2 bytes (one addresses, so we stop at 2*41=82 bytes.
    bne generate_next_jump_table_8_entry


    ; --- fill length > 768 (or in our case >320) ---

    ; If the length of the fill line >768 (or in our case even >320) we should not draw the fill line
    ; TODO: For now we keep on iterating, but we *might* want to do an rts here instead 

    ; We restore the address of the *end* of the the series of 80 'stz'-calls
    lda TMP1
    sta LOAD_ADDRESS
    lda TMP2
    sta LOAD_ADDRESS+1
    
generate_next_jump_table_8_entry_overflow:

    lda LOAD_ADDRESS
    sta (STORE_ADDRESS), y
    iny
    lda LOAD_ADDRESS+1
    sta (STORE_ADDRESS), y
    iny
    
    cpy #0                ; We fill in the whole table
    bne generate_next_jump_table_8_entry_overflow
    
    rts
    
    
    
generate_40_fill_line_end_codes:
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
    cpx #40
    bne next_fill_instruction  ; 80 (or 40) times a "fill 4-bytes" written to VERA
    
    rts

    ; Note: for 2-bit mode we divide the number of starting/ending pixels by 2 before using these patterns!
nr_of_starting_pixels_to_nibble_pattern:
    .byte %00000000     ; 8 pixels         ; only used in combination with ending pixels
    .byte %10111111     ; 1 pixel
    .byte %00111111     ; 2 pixels
    .byte %00101111     ; 3 pixels
    .byte %00001111     ; 4 pixels
    .byte %00001011     ; 5 pixels
    .byte %00000011     ; 6 pixels
    .byte %00000010     ; 7 pixels
    
nr_of_ending_pixels_to_nibble_pattern:
    .byte %00000000     ; 8 pixels         ; only used in combination with starting pixels
    .byte %11111101     ; 1 pixel
    .byte %11111100     ; 2 pixels
    .byte %11110100     ; 3 pixels
    .byte %11110000     ; 4 pixels
    .byte %11010000     ; 5 pixels
    .byte %11000000     ; 6 pixels
    .byte %01000000     ; 7 pixels

