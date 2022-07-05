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


    
; FIXME: this was copied from the via check code, refactor it for measuring clock stretch!
    
calculate_cpu_speed_based_on_via_high_byte:
    ; High byte of via is in x, this returns the CPU, carry is clear if nothing was counted
    
    ; Approx expected values of counter:
    ; $EBD6 : 8MHz (65536 - 60374 = 5162 counts)
    ; $D7AC : 4MHz (65536 - 55212 = 10324 counts)
    ; $AF58 : 2MHz (65536 - 44888 = 20648 counts)
    ; $5EB0 : 1MHz (65536 - 24240 = 41296 counts)

    cpx #$FF                  ; Value that is too high, so counter wasn't running?
    beq nothing_counted_via
    lda #8                    ; We start at 8 MHz
    cpx #$E1                  ; Value between 8 and 4 MHz: 57793 = $E1C1
    bcs cpu_speed_done_via   ; We got more uncounted so we are at 8MHz
    lda #4                    ; We assume 4 MHz now
    cpx #$C3                  ; Value between 4 and 2 MHz: 50050 = $C382
    bcs cpu_speed_done_via   ; We got more uncounted so we are at 4MHz
    lda #2                    ; We assume 2 MHz now
    cpx #$87                  ; Value between 2 and 1 MHz: 34564 = $8704
    bcs cpu_speed_done_via   ; We got more uncounted so we are at 2MHz
    lda #1                    ; We assume 1 MHz now
    bra cpu_speed_done_via

cpu_speed_done_via:
    sec
    rts

nothing_counted_via:
    clc
    rts
