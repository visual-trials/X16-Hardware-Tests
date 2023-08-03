
; === Parameters that have to be set ===

; TEST_JUMP_TABLE = 0 or 1     ; This turns off the iteration in-between the jump-table calls
; USE_SOFT_FILL_LEN = 0 or 1;  ; This turns off reading from 9F2B and 9F2C (for fill length data) and instead reads from USE_SOFT_FILL_LEN-variables

; FIXME: are we going to use this? NR_OF_BYTES_PER_LINE = 320 / 160 / 80
; DO_4BIT = 1 or 0
; DO_2BIT = 1 or 0 (DO_4BIT has to be 1 for this to take effect)

; === Required ZP addresses: (one byte each, unless mentioned otherwise) ===

; TMP1
; TMP2

; END_JUMP_ADDRESS (2 bytes)
; START_JUMP_ADDRESS (2 bytes)

; CODE_ADDRESS (2 bytes)
; LOAD_ADDRESS (2 bytes)
; STORE_ADDRESS (2 bytes)

; FILL_LENGTH_LOW   ; FIXME: maybe we should use a differenly named variable using GEN?
; FILL_LENGTH_HIGH  ; FIXME: not actually used!


; FIXME: PREFIX these too with GEN_ ?
; LEFT_OVER_PIXELS (2 bytes)
; NIBBLE_PATTERN
; NR_OF_FULL_CACHE_WRITES
; NR_OF_STARTING_PIXELS
; NR_OF_ENDING_PIXELS

; -- Used to generate jump tables --
; GEN_START_X
; GEN_FILL_LENGTH_LOW
; GEN_FILL_LENGTH_IS_16_OR_MORE (8-bit) / GEN_FILL_LENGTH_IS_8_OR_MORE (4-bit)
; GEN_LOANED_16_PIXELS (8-bit) / GEN_LOANED_8_PIXELS (4-bit)
; GEN_FILL_LINE_CODE_INDEX

; == Required RAM Addresses ==

; -- Only used when USE_SOFT_FILL_LEN is 1 --
; FILL_LENGTH_HIGH_SOFT (1 byte)

; FILL_LINE_START_JUMP (256 bytes)
; FILL_LINE_START_CODE ; 128 different (start of) fill line code patterns -> takes roughly $0C28 (3112) bytes -> so $0D00 is safe

; 8-bit:
; -- IMPORTANT: we set the *two* lower bits of (the HIGH byte of) this address in the code, using FILL_LINE_END_JUMP_0 as base. So the distance between the 4 tables should be $100! AND bits 8 and 9 should be 00b! (for FILL_LINE_END_JUMP_0) --
; FILL_LINE_END_JUMP_0 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_0
; FILL_LINE_END_JUMP_1 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_1
; FILL_LINE_END_JUMP_2 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_2
; FILL_LINE_END_JUMP_3 ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_3

; 4-bit:
; -- IMPORTANT: we set the *three* lower bits of (the HIGH byte of) this address in the code, using FILL_LINE_END_JUMP_0 as base. So the distance between the 8 tables should be $100! AND bits 8, 9 and 10 should be 000b! (for FILL_LINE_END_JUMP_0) --
; FILL_LINE_END_JUMP_0 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_0
; FILL_LINE_END_JUMP_1 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_1
; FILL_LINE_END_JUMP_2 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_2
; FILL_LINE_END_JUMP_3 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_3
; FILL_LINE_END_JUMP_4 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_4
; FILL_LINE_END_JUMP_5 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_5
; FILL_LINE_END_JUMP_6 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_6
; FILL_LINE_END_JUMP_7 ; 40 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_7

; 8-bit:
; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes? -> NO, MORE than 256 bytes!!
; FILL_LINE_END_CODE_0 ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_1 ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_2 ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_3 ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

; 4-bit:
; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes? -> YES??!
; FILL_LINE_END_CODE_0 ; 3 (stz) * 40 (=320/8) = 120                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_1 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_2 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_3 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_4 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_5 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_6 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
; FILL_LINE_END_CODE_7 ; 3 (stz) * 40 (=320/8) = 120 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
    
generate_fill_line_start_code_and_jump:

    lda #<FILL_LINE_START_CODE
    sta CODE_ADDRESS
    lda #>FILL_LINE_START_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    stz GEN_FILL_LINE_CODE_INDEX
gen_next_fill_line_code:
    ; We remember where this partical code starts (where we have to jump to from the jump table)
    clc
    tya
    adc CODE_ADDRESS           ; TODO: CODE_ADDRESS will always stay 0, so this doesnt do anything really
    sta START_JUMP_ADDRESS       
    lda CODE_ADDRESS+1
    sta START_JUMP_ADDRESS+1

    lda GEN_FILL_LINE_CODE_INDEX
    sta FILL_LENGTH_LOW
    jsr generate_single_fill_line_code
    
    ; Storing jump address in jump table
    ldx GEN_FILL_LINE_CODE_INDEX
    lda START_JUMP_ADDRESS
    sta FILL_LINE_START_JUMP, x
    inx
    lda START_JUMP_ADDRESS+1
    sta FILL_LINE_START_JUMP, x
    
    inc GEN_FILL_LINE_CODE_INDEX
    inc GEN_FILL_LINE_CODE_INDEX
    bne gen_next_fill_line_code

    rts

    

    .if(!DO_4BIT)
generate_single_fill_line_code:

    ; This routines expects this:
    ;    FILL_LENGTH_LOW (8-bit)   : FILL_LENGTH >= 16, X1[1:0],        FILL_LENGTH[3:0], 0
    
    ; == We first extract this info (8-bit) ==
    ;
    ;   GEN_START_X[1:0]
    ;   GEN_FILL_LENGTH_LOW = [3:0]
    ;   GEN_FILL_LENGTH_IS_16_OR_MORE
    
    lda FILL_LENGTH_LOW
    asl                   ; We remove the bit for FILL_LENGTH >= 16
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr                   ; We keep the X1[1:0] part
    sta GEN_START_X
    
    lda FILL_LENGTH_LOW
    lsr
    and #%00001111
    sta GEN_FILL_LENGTH_LOW
    
    lda FILL_LENGTH_LOW
    and #%10000000
    lsr
    lsr
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
    sta NR_OF_FULL_CACHE_WRITES
    beq middle_pixels_generated     ; We should not draw any middle pixels
    jsr generate_draw_middle_pixels_code
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
    
    .endif

    
    .if(DO_4BIT && !DO_2BIT)
    
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
    
    ; ============= generate starting pixels code (>=8 pixels) ===============

    ; if NR_OF_STARTING_PIXELS == 8 (meaning GEN_START_X == 0) we add 8 to the total left-over pixel count and NOT generate starting pixels!
    lda NR_OF_STARTING_PIXELS
    cmp #8
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

    ; We divide LEFT_OVER_PIXELS by 8 by shifting it 3 bit positions to the right
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    
    lda LEFT_OVER_PIXELS            ; Note: the result should always fit into one byte
    sta NR_OF_FULL_CACHE_WRITES
    beq middle_pixels_generated     ; We should not draw any middle pixels
    jsr generate_draw_middle_pixels_code
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
    
    .endif
    
    .if(DO_4BIT && DO_2BIT)
        
generate_single_fill_line_code:
    
    ; This routines expects this:
    ;    FILL_LENGTH_LOW (2-bit)   : X2[-1],            X1[1:0], X1[2], FILL_LENGTH[2:0], X1[-1]
            
    ; FIXME: 2-bit is NOT IMPLEMENTED!
            
    .endif
    

    
gen_start_and_end_in_same_column:

    jsr generate_draw_starting_and_ending_pixels_code

    .if(TEST_JUMP_TABLE)
        jsr generate_rts_code
    .else
        jsr generate_fill_line_iterate_code
    .endif
    
    rts
    
    .if(!DO_4BIT)
    
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
    sta NR_OF_FULL_CACHE_WRITES
    beq middle_pixels_generated_16     ; We should not draw any middle pixels
    jsr generate_draw_middle_pixels_code
middle_pixels_generated_16:
    
gen_generate_jump_to_second_table:

    ;   Note: the table is reversed: since the higher y-number will the less pixels. (so the *beginning* of the table will point to the *end* of the code), when no stz-calls are made)

    lda #<FILL_LINE_END_JUMP_0
    sta END_JUMP_ADDRESS
    lda #>FILL_LINE_END_JUMP_0
    ora NR_OF_ENDING_PIXELS     ; We set the *two* lower bits of the HIGH byte of the JUMP TABLE address to indicate which jump table we want to jump to
    sta END_JUMP_ADDRESS+1

    lda GEN_LOANED_16_PIXELS
    beq jump_address_is_valid
    
    ; if GEN_LOANED_16_PIXELS == 1 we should jump as-if 16 pixels less have to be drawn -> so we subtract 4 bytes (2 jump addresses)
    
    sec
    lda END_JUMP_ADDRESS
    sbc #4
    sta END_JUMP_ADDRESS
    lda END_JUMP_ADDRESS+1
    sbc #0
    sta END_JUMP_ADDRESS+1
    
; FIXME: CHECK: if exactly 16-pixels have to be drawn due to the HIGH fill length, we should not draw any pixels!
    
jump_address_is_valid:

    jsr generate_table_jump
    
    rts
    
    .endif
    
    
    .if(DO_4BIT && !DO_2BIT)
    
gen_more_or_equal_to_8_pixels:

    ; ============= generate starting pixels code (>=8 pixels) ===============

    ; if NR_OF_STARTING_PIXELS == 8 (meaning GEN_START_X == 0) we add 8 to the total left-over pixel count and NOT generate starting pixels!
    lda NR_OF_STARTING_PIXELS
    cmp #8
    beq gen_generate_middle_pixels_8
    
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
    
    clc
    lda LEFT_OVER_PIXELS
    adc #8
    sta LEFT_OVER_PIXELS
    lda LEFT_OVER_PIXELS+1
    adc #0
    sta LEFT_OVER_PIXELS+1
    
    lda #1
    sta GEN_LOANED_8_PIXELS

    jsr generate_draw_starting_pixels_code

gen_generate_middle_pixels_8:

    ; We divide LEFT_OVER_PIXELS by 8 by shifting it 3 bit positions to the right
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    lsr LEFT_OVER_PIXELS+1
    ror LEFT_OVER_PIXELS
    
    lda LEFT_OVER_PIXELS               ; Note: the result should always fit into one byte
    sta NR_OF_FULL_CACHE_WRITES
    beq middle_pixels_generated_8      ; We should not draw any middle pixels
    jsr generate_draw_middle_pixels_code
middle_pixels_generated_8:
    
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
    
; FIXME: CHECK: if exactly 8-pixels have to be drawn due to the HIGH fill length, we should not draw any pixels!
    
jump_address_is_valid:

    jsr generate_table_jump
    
    rts
    
    .endif
    
    .if(DO_4BIT && !DO_2BIT)
    
        ; FIXME! NOT IMPLEMENTED!
        
    .endif
    
    
generate_table_jump:

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

    lda END_JUMP_ADDRESS        ; low byte of jump base address
    jsr add_code_byte
    
    lda END_JUMP_ADDRESS+1      ; high byte of jump base address
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
        
    ; -- jmp (FILL_LINE_START_JUMP,x)
    lda #$7C               ; jmp (....,x)
    jsr add_code_byte

    lda #<FILL_LINE_START_JUMP  ; low byte of jump table
    jsr add_code_byte
    
    lda #>FILL_LINE_START_JUMP  ; high byte of jump table
    jsr add_code_byte
    
    ; -- rts
    lda #$60               ; rts
    jsr add_code_byte

    rts
    
    
    
generate_fill_line_end_code:

; FIXME! this needs to be extended to FILL_LINE_END_CODE_7 for 4-bit mode!

    ; -------------- FILL_LINE_END_CODE_0 ---------------
    
    lda #<FILL_LINE_END_CODE_0
    sta CODE_ADDRESS
    lda #>FILL_LINE_END_CODE_0
    sta CODE_ADDRESS+1
    
    jsr generate_40_or_80_fill_line_end_codes
    
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
    
    jsr generate_40_or_80_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    .if(!DO_4BIT)
        lda #%11111100         ; NIBBLE_PATTERN = 1 pixel at the end
    .else
        lda #%11111101         ; NIBBLE_PATTERN = 1 pixel at the end
    .endif
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
    
    jsr generate_40_or_80_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    .if(!DO_4BIT)
        lda #%11110000         ; NIBBLE_PATTERN = 2 pixels at the end
    .else
        lda #%11111100         ; NIBBLE_PATTERN = 2 pixels at the end
    .endif
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
    
    jsr generate_40_or_80_fill_line_end_codes
    
    ; -- lda #{NIBBLE_PATTERN}
    lda #$A9               ; lda #....
    jsr add_code_byte

    .if(!DO_4BIT)
        lda #%11000000         ; NIBBLE_PATTERN = 3 pixels at the end
    .else
        lda #%11110100         ; NIBBLE_PATTERN = 3 pixels at the end
    .endif
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

    
    .if(DO_4BIT)
    
        ; -------------- FILL_LINE_END_CODE_4 ---------------

        lda #<FILL_LINE_END_CODE_4
        sta CODE_ADDRESS
        lda #>FILL_LINE_END_CODE_4
        sta CODE_ADDRESS+1
        
        jsr generate_40_or_80_fill_line_end_codes
        
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
        
        jsr generate_40_or_80_fill_line_end_codes
        
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
        
        jsr generate_40_or_80_fill_line_end_codes
        
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
        
        jsr generate_40_or_80_fill_line_end_codes
        
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
    
    .endif
    
    rts

    
generate_fill_line_end_jump:

    .if(!DO_4BIT)
        lda #<FILL_LINE_END_JUMP_0
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_0
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_0+80*3)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_0+80*3)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_16

        
        lda #<FILL_LINE_END_JUMP_1
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_1
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_1+80*3)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_1+80*3)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_16
        
        
        lda #<FILL_LINE_END_JUMP_2
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_2
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_2+80*3)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_2+80*3)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_16
        
        
        lda #<FILL_LINE_END_JUMP_3
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_3
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 80 'stz'-calls in the FILL_LINE_CODE  (80 * 4 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_3+80*3)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_3+80*3)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_16
    .else
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
        lda #<(FILL_LINE_END_CODE_0+40*4)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_0+40*4)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_8

        
        lda #<FILL_LINE_END_JUMP_5
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_5
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_1+40*5)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_1+40*5)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_8
        
        
        lda #<FILL_LINE_END_JUMP_6
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_6
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_2+40*6)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_2+40*6)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_8
        
        
        lda #<FILL_LINE_END_JUMP_7
        sta STORE_ADDRESS
        lda #>FILL_LINE_END_JUMP_7
        sta STORE_ADDRESS+1
        
        ; We start at the end of the series of 40 'stz'-calls in the FILL_LINE_CODE  (40 * 8 pixels = 320 pixels)
        lda #<(FILL_LINE_END_CODE_3+40*7)
        sta LOAD_ADDRESS
        lda #>(FILL_LINE_END_CODE_3+40*7)
        sta LOAD_ADDRESS+1
        
        jsr generate_jump_table_8
    
    
    .endif
    
    
    rts

    
generate_jump_table_16:

    ; We backup the address of the *end* of the the series of 80 'stz'-calls
    lda LOAD_ADDRESS
    sta TMP1
    lda LOAD_ADDRESS+1
    sta TMP2

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
    sbc #4*3               ; we need to skip 16 pixels, so four times a stz, this is 4 * 3 bytes of code
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    sbc #0
    sta LOAD_ADDRESS+1
    
    cpy #80+4                ; We need 20 entries of 16 pixels (=320 pixels) *plus* an entry for 0 pixels. Each entry is 4 bytes (two addresses, so we stop at 4*21=84 bytes.
    bne generate_next_jump_table_16_entry


    ; --- fill length > 768 (or in our case >320) ---

    ; If the length of the fill line >768 (or in our case even >320) we should not draw the fill line
    ; TODO: For now we keep on iterating, but we *might* want to do an rts here instead 

    ; We restore the address of the *end* of the the series of 80 'stz'-calls
    lda TMP1
    sta LOAD_ADDRESS
    lda TMP2
    sta LOAD_ADDRESS+1
    
generate_next_jump_table_16_entry_overflow:

    lda LOAD_ADDRESS
    sta (STORE_ADDRESS), y
    iny
    lda LOAD_ADDRESS+1
    sta (STORE_ADDRESS), y
    iny
    
    cpy #0                ; We fill in the whole table
    bne generate_next_jump_table_16_entry_overflow
    
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
    
    
    
generate_40_or_80_fill_line_end_codes:
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
    .if(!DO_4BIT)
        cpx #80
    .else
        cpx #40
    .endif
    bne next_fill_instruction  ; 80 (or 40) times a "fill 4-bytes" written to VERA
    
    rts

    .if(!DO_4BIT)
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
    .endif
    
    .if(DO_4BIT && !DO_2BIT)
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
    .endif

    .if(DO_4BIT && DO_2BIT)
        ; FIXME! NOT IMPLEMENTED -> should we use the same patterns as 4-bit but divide x by 2?
    .endif
    
    
generate_draw_middle_pixels_code:

    ldx #0                 ; counts nr of draw middle pixels instructions (four 8-bit pixels, eight 4-bit pixels)

next_draw_middle_pixels_instruction:

    ; -- stz VERA_DATA1 ($9F24)
    lda #$9C               ; stz ....
    jsr add_code_byte
    
    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx NR_OF_FULL_CACHE_WRITES
    bne next_draw_middle_pixels_instruction

    rts

generate_draw_starting_and_ending_pixels_code:

    ldx NR_OF_STARTING_PIXELS
    lda nr_of_starting_pixels_to_nibble_pattern, x
    sta TMP2

    ldx NR_OF_ENDING_PIXELS
    lda nr_of_ending_pixels_to_nibble_pattern, x
    ora TMP2
    sta NIBBLE_PATTERN
    beq generate_nibble_pattern_is_0
    
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

generate_nibble_pattern_is_0:

    ; -- stz VERA_DATA1 ($9F24)
    lda #$9C               ; stz ....
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
  