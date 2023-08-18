
    
; FIXME: we could move this down again and inline it! (not in a routine)
decode_fill_length_low:

    ; == We extract this info (4-bit) ==
    ;
    ;   GEN_START_X[2:0] = X1[2:0]
    ;   GEN_START_X_SUB = X1[-1]  -> indicates whether we should do a start-POKE
    ;   GEN_FILL_LENGTH_LOW = FILL_LENGTH[2:0]
    ;
    
    lda FILL_LENGTH_LOW
    and #%11000000        ; X1[1:0], 000000
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr                   ; 000000, X1[1:0]
    sta GEN_START_X
    
    lda FILL_LENGTH_LOW
    and #%00100000        ; 00, X1[2], 00000
    lsr
    lsr
    lsr                   ; 00000, X1[2], 00
    ora GEN_START_X       ; OR with X1[1:0]
    sta GEN_START_X       ; 00000, X1[2:0]
    
    lda FILL_LENGTH_LOW
    and #%00011100        ; 000, FILL_LENGTH[2:0], 00
    lsr
    lsr
    sta GEN_FILL_LENGTH_LOW ; 00000, FILL_LENGTH[2:0]
    
    lda FILL_LENGTH_LOW
    and #%00000010        ; 000000, X1[-1], 0
    lsr
    sta GEN_START_X_SUB   ; 0000000, X1[-1]

    stz GEN_LOANED_8_PIXELS  ; Meaning: EIGHT 4-bit pixels
    
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
    sta NR_OF_ENDING_PIXELS               ; the lower 3 bits contain the nr of (4-bit) ending pixels
    
    ; -- we start with LEFT_OVER_PIXELS = GEN_FILL_LENGTH_LOW --
    stz LEFT_OVER_PIXELS+1
    lda GEN_FILL_LENGTH_LOW
    sta LEFT_OVER_PIXELS
    
    rts

    
generate_single_fill_line_code:
    
    ; This routines expects this:
    ;    FILL_LENGTH_LOW (shifted left) (2-bit)   : X1[1:0], X1[2], FILL_LENGTH[2:0], X1[-1], 0
    ;
    ; Note: X2[-1] is not mentioned here, since it is shifted-out and put in the CARRY instead (during code-run)
    ;       So we are assuming all bits are already shifted to the left!
    ;
    ; Important: the 'fill length' from VERA is in 4-bit pixels! (not in 2-bit pixels). 
    ;            the X1 and X2 positions are in 4-bit positions! And X1/X2[-1] means: 'half a 4-bit pixel' (aka a 2-bit pixel)

    jsr decode_fill_length_low

    ; We create a conditional branch to the code when FILL_LENGTH_HIGH (during run time) is zero -> towards the code 
    jsr generate_load_fill_len_high  ; = ldx VERA_FX_POLY_FILL_H
    jsr generate_beq                 ; = beq ...
    
    ; Since we dont know yet how long the code (when FILL_LENGTH_HIGH is not zero) will be, we remember the place WHERE we have to PATCH the offset
    sty STORE_ADDRESS
    lda CODE_ADDRESS+1
    sta STORE_ADDRESS+1
    
    jsr generate_dummy_offset        ; = dummy offset byte (PATCHED later on!)
    
    ; We first generate the code that deals with >= 8 pixels (4-bit)
    jsr gen_more_or_equal_to_8_pixels
    
    ; We remember the address where the code (when FILL_LENGTH_HIGH is zero) will start
    sty LOAD_ADDRESS
    lda CODE_ADDRESS+1
    sta LOAD_ADDRESS+1
    
    ; We calculate the branch-offset
    sec
    lda LOAD_ADDRESS
    sbc STORE_ADDRESS
    
    ; We adjust it the branch-offset by 1
    dec
    
    ; We PATCH the branch-offset (we overwrite the dummy offset value)
    phy
    ldy #0
    sta (STORE_ADDRESS), y
    ply
    
    
    
    ; === We adjust the 4-bit variables when start-poking is needed ===
    
    jsr decode_fill_length_low
    
    lda GEN_START_X_SUB
    beq done_adjusting_4bit_variables

    ; When doing a starting POKE, we *skip* the first 4-bit pixel, so we remove it here
    sec
    lda LEFT_OVER_PIXELS
    sbc #1
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    sbc #0
    sta LEFT_OVER_PIXELS+1
    
    bpl left_over_pixels_is_ok
    
    ; It is possible only ONE pixel has to be drawn (just a single POKE). In that case LEFT_OVER_PIXELS would be 0 and it would become NEGATIVE here!
    ; So we set LEFT_OVER_PIXELS to 0 here
    stz LEFT_OVER_PIXELS+1
    stz LEFT_OVER_PIXELS
    
left_over_pixels_is_ok:    
    
    ; We are also incrementing GEN_START_X, since (in case of a start-poke) we start one 4-bit pixel later
    ; If this exceeds 7 (so is equal to 8) we set it to 0
    inc GEN_START_X
    lda GEN_START_X
    cmp #8
    bne gen_start_x_is_ok
    stz GEN_START_X
gen_start_x_is_ok:

    ; We re-calculate NR_OF_STARTING_PIXELS based on the new GEN_START_X
    ; -- NR_OF_STARTING_PIXELS = 8 - GEN_START_X --
    sec
    lda #8
    sbc GEN_START_X
    sta NR_OF_STARTING_PIXELS
    
done_adjusting_4bit_variables:    
    
    
    
    
    
    
    ; We then generate the code that deals with < 8 pixels (4-bit)
    
gen_less_than_8_pixels:

    .if(1)
        lda LEFT_OVER_PIXELS
        cmp #20
        bcs tmp_skip_stp ; if a is larger than the value above
        
        ; Note that register y contains the nr of fill lines left (so it counts down)
        lda #2
        sta DEBUG_VALUE
        ;jsr generate_loop_at_y_equals
        jsr generate_stp_at_y_equals
tmp_skip_stp:
    .endif


    ; ============= generate start-POKE code and empty cache write (< 8 (4-bit) pixels) ===============
    
    lda GEN_START_X_SUB
    beq starting_pixels_can_be_generated
    
    jsr generate_start_poke
    
    lda NR_OF_STARTING_PIXELS
    bne starting_pixels_can_be_generated
    ; When NR_OF_STARTING_PIXELS is 0 we should not draw any starting 4-bit pixels,
    ; BUT we have to proceeed to the next 4-byte column (when doing a start-poke)! So we have to write $FF to DATA1 (which is a transparent cache write)
    jsr generate_empty_cache_write
    
    ; Since we dont want to generate any starting pixels, we can proceed to generating the ending pixels
    bra gen_generate_ending_pixels
    
starting_pixels_can_be_generated:

    ; If we have less than 8 pixels AND fill length low == 0, we have nothing to do, so we go to the end (well, we might have to end-poke still)
    ; Note: we check LEFT_OVER_PIXELS (16-bit) instead of GEN_FILL_LENGTH_LOW here, since LEFT_OVER_PIXELS could have just been changed
    lda LEFT_OVER_PIXELS
    beq gen_generate_ending_poke_only

    ; ===== We need to check if the starting and ending pixels are in the same 8-pixel colum (note: 4-bit pixels) ====
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

    ; We need to generate the conditional end-poke in 2-bit mode here
    jsr generate_conditional_end_poke
    
    jsr generate_draw_ending_pixels_code
    
    bra gen_ending_pixels_are_generated
    
gen_generate_ending_poke_only:
    
    ; We need to generate the conditional end-poke in 2-bit mode here
    jsr generate_conditional_end_poke
    
gen_ending_pixels_are_generated:
    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    rts

    
gen_start_and_end_in_same_column:

    ; We need to generate the conditional end-poke in 2-bit mode here
    jsr generate_conditional_end_poke
    
    jsr generate_draw_starting_and_ending_pixels_code

    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    rts
    
    
gen_more_or_equal_to_8_pixels:

    ; ============= generate start-POKE code and empty cache write (>= 8 (4-bit) pixels) ===============
    
    lda GEN_START_X_SUB
    beq starting_pixels_can_be_generated_8

    .if(0)
        lda LEFT_OVER_PIXELS
        cmp #5
        bne tmp_skip_stp
        jsr generate_infinite_loop_code
tmp_skip_stp:
    .endif

    
    jsr generate_start_poke
    
    ; When doing a starting POKE, we *skip* the first 4-bit pixel, so we remove it here
    sec
    lda LEFT_OVER_PIXELS
    sbc #1
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    sbc #0
    sta LEFT_OVER_PIXELS+1
    
    ; Note: we are also incrementing GEN_START_X, since start at the next (4-bit) pixel
    ; If this exceeds 7 (so is equal to 8) we set it to 0
    inc GEN_START_X
; FIXME! WHY DOES TURNING THIS OFF WORK???
; FIXME! WHY DOES TURNING THIS OFF WORK???
; FIXME! WHY DOES TURNING THIS OFF WORK???
;    lda GEN_START_X
;    cmp #8
;    bne gen_start_x_is_ok_8
;    stz GEN_START_X
;gen_start_x_is_ok_8:
    
    ; -- NR_OF_STARTING_PIXELS = 8 - GEN_START_X --
    sec
    lda #8
    sbc GEN_START_X
    sta NR_OF_STARTING_PIXELS
       
    lda NR_OF_STARTING_PIXELS
; FIXME: remove this!
;    dec NR_OF_STARTING_PIXELS
    bne starting_pixels_can_be_generated_8
    ; When NR_OF_STARTING_PIXELS is decremented to 0 we should not draw any starting 4-bit pixels,
    ; BUT we have to proceeed to the next 4-byte column! So we have to write $FF to DATA1
    jsr generate_empty_cache_write
    
    ; Since we dont want to generate any starting pixels, we can proceed to jumping to the second table
    bra gen_generate_jump_to_second_table
    
starting_pixels_can_be_generated_8:
    
    ; ============= generate starting pixels code (>= 8 (4-bit) pixels) ===============

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

    lda GEN_LOANED_8_PIXELS     ; Note: 4-bit pixels!
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

    ; Since (in 2-bit mode) we already loaded register x, we dont have to do it again here
    jsr generate_table_jump_without_ldx
    
    rts
    
    
    
generate_start_poke:

    ; -- lda #{START_POKE_BYTE}
    lda #$A9               ; lda #....
    jsr add_code_byte

    ; Note: GEN_START_X is in 4-bit pixels!
    
    lda GEN_START_X          ; 00000, X1[2], X1[1], X1[0]
    lsr a                    ; 000000, X1[2], X1[1]
    sta GEN_POKE_BYTE
    
    lda GEN_START_X          ; 00000, X1[2], X1[1], X1[0]
    and #%00000001
    lsr a                    ; 00000000 (X1[0] in CARRY)
    ror a                    ; X1[0], 0000000
    
    ; Since this is a start-poke, X1 has to be *odd* (so X1[-1] has to be 1)
    ora #%01000000           ; X1[0], X1[-1], 000000  (since we are start-poking, X1[-1] has to be 1)
    ora GEN_POKE_BYTE        ; X1[0], X1[-1], 0000, X1[2], X1[1]
    jsr add_code_byte        ; #{START_POKE_BYTE}
    
    ; -- sta VERA_ADDR_LOW ($9F20)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$20               ; $20
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte

    rts

    
generate_conditional_end_poke:

    ; -- bcc ..
    lda #$90               ; bcc ....
    jsr add_code_byte

    ; The opcoming POKE commands take 8 bytes of code (we want to skip that code if no END-POKE is needed)
    lda #$08               ; branch-offset
    jsr add_code_byte

    ; -- lda #{END_POKE_BYTE}
    lda #$A9               ; lda #....
    jsr add_code_byte

    ; Note: NR_OF_ENDING_PIXELS is in 4-bit pixels!
    
    lda NR_OF_ENDING_PIXELS  ; 00000, X2[2], X2[1], X2[0]
    lsr a                    ; 000000, X2[2], X2[1]
    sta GEN_POKE_BYTE
    
    lda NR_OF_ENDING_PIXELS  ; 00000, X2[2], X2[1], X2[0]
    and #%00000001
    lsr a                    ; 00000000 (X2[0] in CARRY)
    ror a                    ; X2[0], 0000000
    
    ; Since this is an end-poke, X2 has to be *even* (so X2[-1] has to be 0)
    ora #%00000000           ; X2[0], X2[-1], 000000  (since we are end-poking, X2[-1] has to be 0)
    ora GEN_POKE_BYTE        ; X2[0], X2[-1], 0000, X2[2], X2[1]
    jsr add_code_byte        ; #{END_POKE_BYTE}
    
    ; -- sta VERA_ADDR_LOW ($9F20)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$20               ; $20
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    ; -- sta VERA_DATA1 ($9F24)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte

    rts
    
    
generate_fill_line_end_code:

; FIXME: for 2-bit mode (and 320px wide screen) we only need to generate 40 cache writes! (but for 640px we need 40, so we might as well generate 40?)

    ; -------------- FILL_LINE_END_CODE_0 ---------------
    
    lda #<FILL_LINE_END_CODE_0
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_0
    sta CODE_ADDRESS+1
    
    jsr generate_40_fill_line_end_codes
    
    lda #0
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #1
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #2
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #3
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #4
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #5
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #6
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    
    lda #7
    sta NR_OF_ENDING_PIXELS
    jsr generate_conditional_end_poke
    
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
    bne next_fill_instruction  ; 40 times a "fill 4-bytes" written to VERA
    
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

