
; -- FIXME: SLOW HACK! --
MULTIPLIER_XOR_MULTIPLICAND_NEGATED = TMP2
multiply_16bits_signed:
    stz MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    
    lda MULTIPLIER+1
    bpl multiplier_is_positive
    
    ; We negate the multiplier
    sec
    lda #0
    sbc MULTIPLIER
    sta MULTIPLIER
    lda #0
    sbc MULTIPLIER+1
    sta MULTIPLIER+1
    
    lda #1
    sta MULTIPLIER_XOR_MULTIPLICAND_NEGATED
multiplier_is_positive:

    lda MULTIPLICAND+1
    bpl multiplcand_is_positive

    ; We negate the multiplicand
    sec
    lda #0
    sbc MULTIPLICAND
    sta MULTIPLICAND
    lda #0
    sbc MULTIPLICAND+1
    sta MULTIPLICAND+1
    
    lda MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    eor #1
    sta MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    
multiplcand_is_positive:

    jsr multiply_16bits
    
    lda MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    beq signed_product_is_valid
    
    ;We negate the product
    sec
    lda #0
    sbc PRODUCT
    sta PRODUCT
    lda #0
    sbc PRODUCT+1
    sta PRODUCT+1
    lda #0
    sbc PRODUCT+2
    sta PRODUCT+2
    lda #0
    sbc PRODUCT+3
    sta PRODUCT+3
    
signed_product_is_valid:

    rts


; https://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product
multiply_16bits:
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
