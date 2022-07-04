; Tests for checking functionality of YM2151 Audio

; NOTE: the code below was derived using input (and source code) from ZeroByte. 
;       I personally have very little knowledge about the YM2151!
;       Help to get these tests working properly is greatly appreciated.
;       Also see: https://github.com/ZeroByteOrg/ymtester

;       Here is also a bit of info: http://7800.8bitdev.org/index.php/YM2151_Programming

ym_header: 
    .asciiz "YM2151 FM-based soundchip:"
   
testing_busy_flag_message: 
    .asciiz "Testing busy flag ... "
busy_loops:
    .asciiz " loops"
busy_waited_for:
    .asciiz "waited for "
busy_for_too_long:
    .asciiz "busy for too long"
    
    
print_ym_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<ym_header
    sta TEXT_TO_PRINT
    lda #>ym_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts

        
ym_busy_flag_test:

    ; We are doing a very simple check if the YM gives a busy flag after writing to it
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_busy_flag_message
    sta TEXT_TO_PRINT
    lda #>testing_busy_flag_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; Store a 0 into register 0 (which is an unused register)
    lda #0
    sta YM_REG
    nop
    nop
    nop
    sta YM_DATA

    ldx #0
ym_still_busy:
    inx
    beq ym_stop_trying
    
    ; Checking bit 7 of the data register to 
    bit YM_DATA
    bmi ym_still_busy
    
    lda #COLOR_UNKNOWN
    sta TEXT_COLOR
    
    ; FIXME: we should have some kind of criteria here to determine whether the value is any good!

    lda #<busy_waited_for
    sta TEXT_TO_PRINT
    lda #>busy_waited_for
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    txa
    jsr print_byte_as_decimal        

    lda #<busy_loops
    sta TEXT_TO_PRINT
    lda #>busy_loops
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
 
    jmp done_ym_busy
    
ym_stop_trying:

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<busy_for_too_long
    sta TEXT_TO_PRINT
    lda #>busy_for_too_long
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_ym_busy: 
    jsr move_cursor_to_next_line

    rts

