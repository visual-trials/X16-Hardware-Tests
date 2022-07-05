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
testing_ym_clock_stretch_message: 
    .asciiz "Testing if clock is streched for YM ... "
versus:
    .asciiz " vs "
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
    
    ; Right now at 8MHz its 12 loops
    ; Right now at 4MHz its 6 loops
    ; Right now at 2MHz its 3 loops
    ; Our guess it that 1MHz its 2 loops
    ; So for now 1 loop is NOT good, everything else (apart from >255) is OK
    cpx #1
    beq ym_too_few_loops
    
    lda #COLOR_OK
    sta TEXT_COLOR
    bra ym_print_how_many_loops_waited
    
ym_too_few_loops:
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
ym_print_how_many_loops_waited:
    
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

test_ym_clock_strech:
    ; We are trying to determine whether the (CPU) clock is stretched when accessing the YM
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_ym_clock_stretch_message
    sta TEXT_TO_PRINT
    lda #>testing_ym_clock_stretch_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; FIXME: Make sure to disable all interrupts (IER) for the VIA

    ; Using Timer 1 in one-shot mode on VIA to determine speed of CPU
    
    ; We fill the counter with it max 16-bit value ($FFFF)
    lda #$FF
    sta VIA1_T1C_L
    lda #$FF
    sta VIA1_T1C_H
    
    lda #VIA_T1_MODE0  ; One shot mode
    sta VIA1_ACR

    ; We wait for a while (while doing nothing meanwhile)
    jsr wait_during_via_counting_and_doing_nothing_meanwhile
    
    ; Read the Interrupt flags into a
    lda VIA1_IFR
    
    ; Then read the high byte of the counter into x
    ldx VIA1_T1C_H
    
    ; Then read the low byte of the counter into y
    ldy VIA1_T1C_L

    ; Check bit 6: if its 1 then we got an interrupt for this counter
    and #$40
    bne counter_speed_ran_out_ym_nothing  ; We got an interrupt, so we counted down (ran out) completely. 

    sty YM_STRECH_DOING_NOTHING
    stx YM_STRECH_DOING_NOTHING+1


    ; We fill the counter with it max 16-bit value ($FFFF)
    lda #$FF
    sta VIA1_T1C_L
    lda #$FF
    sta VIA1_T1C_H
    
    lda #VIA_T1_MODE0  ; One shot mode
    sta VIA1_ACR

    ; We wait for a while (while reading from ym meanwhile)
    jsr wait_during_via_counting_and_reading_from_ym_meanwhile
    
    ; Read the Interrupt flags into a
    lda VIA1_IFR
    
    ; Then read the high byte of the counter into x
    ldx VIA1_T1C_H
    
    ; Then read the low byte of the counter into y
    ldy VIA1_T1C_L

    ; Check bit 6: if its 1 then we got an interrupt for this counter
    and #$40
    bne counter_speed_ran_out_ym_read  ; We got an interrupt, so we counted down (ran out) completely. 
    
    sty YM_STRECH_READING_FROM_YM
    stx YM_STRECH_READING_FROM_YM+1

    jsr print_ym_strech_result

    jmp done_testing_ym_stretch
counter_speed_ran_out_ym_read:
    jsr print_via_ran_out
    
    jmp done_testing_ym_stretch
counter_speed_ran_out_ym_nothing:
    jsr print_via_ran_out
done_testing_ym_stretch:

    ; TODO: unset interrupts?

    jsr move_cursor_to_next_line

    rts

    
    
wait_during_via_counting_and_doing_nothing_meanwhile:
    
    ; We loop 2*256 times  
    ldy #2
wait_during_via_counter_and_doing_nothing_256:
    ldx #0
wait_during_via_counter_and_doing_nothing_1:
    nop ; doing nothing
    nop ; doing nothing
    inx
    bne wait_during_via_counter_and_doing_nothing_1
    dey
    bne wait_during_via_counter_and_doing_nothing_256
    
    rts

wait_during_via_counting_and_reading_from_ym_meanwhile:
    
    ; We loop 2*256 times  
    ldy #2
wait_during_via_counter_and_reading_from_ym_256:
    ldx #0
wait_during_via_counter_and_reading_from_ym_1:
    lda YM_DATA ; reading from YM while via is counting 
    inx
    bne wait_during_via_counter_and_reading_from_ym_1
    dey
    bne wait_during_via_counter_and_reading_from_ym_256
    
    rts

    
print_ym_strech_result:
    ; Printing the result
    
    lda #COLOR_UNKNOWN
    sta TEXT_COLOR

    jsr setup_cursor
    
    lda #' '
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    ldy YM_STRECH_DOING_NOTHING
    ldx YM_STRECH_DOING_NOTHING+1
    stx BYTE_TO_PRINT
    jsr print_byte_as_hex
    sty BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    lda #<versus
    sta TEXT_TO_PRINT
    lda #>versus
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    ldy YM_STRECH_READING_FROM_YM
    ldx YM_STRECH_READING_FROM_YM+1
    stx BYTE_TO_PRINT
    jsr print_byte_as_hex
    sty BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    rts
