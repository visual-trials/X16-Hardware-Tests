; Tests for checking functionality of VERA Audio

; https://www.reddit.com/r/beneater/comments/horcks/utilizing_65c22_features_t1_timer/
; https://eater.net/datasheets/w65c22.pdf

via_header: 
    .asciiz "Versatile Interface Adapters:"
testing_via1_latch1_message: 
    .asciiz "Testing writing and reading VIA #1 latch 1 ... "
testing_via2_latch1_message: 
    .asciiz "Testing writing and reading VIA #2 latch 1 ... "
testing_measure_cpu_speed_using_via1_counter1: 
    .asciiz "Measuring CPU clock speed using VIA #1 counter 1 ... "
testing_measure_cpu_speed_using_via2_counter1: 
    .asciiz "Measuring CPU clock speed using VIA #2 counter 1 ... "
via_counter_did_not_run_message: 
    .asciiz "counter did not run"
   
print_via_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<via_header
    sta TEXT_TO_PRINT
    lda #>via_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts

        
test_writing_and_reading_via1_latch_1:

    ; We are trying to write to and reac from latch 1 of VIA #1
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_via1_latch1_message
    sta TEXT_TO_PRINT
    lda #>testing_via1_latch1_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; We fill the latch with a value
    lda #$A5
    sta VIA1_T1L_L
    ; Reading back the latch value
    lda VIA1_T1L_L
    cmp #$A5
    beq writing_and_reading_via1_latch_1_ok
    
    sta BAD_VALUE
    
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ldy #<VIA1_T1L_L
    ldx #>VIA1_T1L_L
    jsr print_fixed_ram_address
    
    bra done_writing_and_reading_via1_latch_1

writing_and_reading_via1_latch_1_ok:
    lda #COLOR_OK
    sta TEXT_COLOR

    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_writing_and_reading_via1_latch_1:
    jsr move_cursor_to_next_line
    
    rts
    
    
test_writing_and_reading_via2_latch_1:

    ; We are trying to write to and reac from latch 1 of VIA #2
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_via2_latch1_message
    sta TEXT_TO_PRINT
    lda #>testing_via2_latch1_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; We fill the latch with a value
    lda #$A5
    sta VIA2_T1L_L
    ; Reading back the latch value
    lda VIA2_T1L_L
    cmp #$A5
    beq writing_and_reading_via2_latch_1_ok
    
    sta BAD_VALUE
    
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ldy #<VIA2_T1L_L
    ldx #>VIA2_T1L_L
    jsr print_fixed_ram_address
    
    bra done_writing_and_reading_via2_latch_1

writing_and_reading_via2_latch_1_ok:
    lda #COLOR_OK
    sta TEXT_COLOR

    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_writing_and_reading_via2_latch_1:
    jsr move_cursor_to_next_line
    
    rts

    

measure_cpu_speed_using_via1_counter1:
    ; We are trying to determine the CPU clock speed based on the counter 1 of VIA #1
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_measure_cpu_speed_using_via1_counter1
    sta TEXT_TO_PRINT
    lda #>testing_measure_cpu_speed_using_via1_counter1
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; FIXME: Disabling all interrupts (IER) for the VIA

    ; Using Timer 1 in one-shot mode on VIA to determine speed of CPU
    
    ; We fill the counter with it max 16-bit value ($FFFF)
    lda #$FF
    sta VIA1_T1C_L
    lda #$FF
    sta VIA1_T1C_H
    
    lda #VIA_T1_MODE0  ; One shot mode
    sta VIA1_ACR

    ; We wait for a while
    jsr wait_during_via_counting
    
    ; Then read the high byte of the counter
    ldx VIA1_T1C_H

    lda VIA1_IFR
    ; Check bit 6: if its 1 then we got an interrupt for this counter
    and #$40
    bne cpu_speed_too_low_via1  ; We got an interrupt, so we counted down completely. We are too slow.

    ; High byte of via is in x, this returns the CPU, carry is clear if nothing was counted
    jsr calculate_cpu_speed_based_on_via_high_byte
    bcc nothing_counted_via1

    sta ESTIMATED_CPU_SPEED_VIA1
    
measured_ok_cpu_speed_via1:
    ; We measure the CPU speed, so we are reporting it here
    jsr print_cpu_speed_via

    jmp done_measuring_cpu_speed_via1
cpu_speed_too_low_via1:

    jsr cpu_speed_too_low
    
    jmp done_measuring_cpu_speed_via1
nothing_counted_via1:

    jsr via_counter_did_not_run
    
done_measuring_cpu_speed_via1:

    ; FIXME: unset interrupts!
    ; FIXME: unset interrupts!
    ; FIXME: unset interrupts!

    jsr move_cursor_to_next_line

    rts



measure_cpu_speed_using_via2_counter1:

    ; We are trying to determine the CPU clock speed based on the counter 1 of VIA #2
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_measure_cpu_speed_using_via2_counter1
    sta TEXT_TO_PRINT
    lda #>testing_measure_cpu_speed_using_via2_counter1
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; FIXME: Disabling all interrupts (IER) for the VIA

    ; Using Timer 1 in one-shot mode on VIA to determine speed of CPU
    
    ; We fill the counter with it max 16-bit value ($FFFF)
    lda #$FF
    sta VIA2_T1C_L
    lda #$FF
    sta VIA2_T1C_H
    
    lda #VIA_T1_MODE0  ; One shot mode
    sta VIA2_ACR

    ; We wait for a while
    jsr wait_during_via_counting
    
    ; Then read the high byte of the counter
    ldx VIA2_T1C_H
    
    lda VIA2_IFR
    ; Check bit 6: if its 1 then we got an interrupt for this counter
    and #$40
    bne cpu_speed_too_low_via2  ; We got an interrupt, so we counted down completely. We are too slow.

    ; High byte of via is in x, this returns the CPU, carry is clear if nothing was counted
    jsr calculate_cpu_speed_based_on_via_high_byte
    bcc nothing_counted_via2

    sta ESTIMATED_CPU_SPEED_VIA2
    
measured_ok_cpu_speed_via2:
    ; We measure the CPU speed, so we are reporting it here
    jsr print_cpu_speed_via

    jmp done_measuring_cpu_speed_via2
cpu_speed_too_low_via2:

    jsr cpu_speed_too_low
    
    jmp done_measuring_cpu_speed_via2
nothing_counted_via2:

    jsr via_counter_did_not_run
    
done_measuring_cpu_speed_via2:

    ; FIXME: unset interrupts!
    ; FIXME: unset interrupts!
    ; FIXME: unset interrupts!

    jsr move_cursor_to_next_line

    rts

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


wait_during_via_counting:
    
    ; We loop 4*256 times  
    ldy #4
wait_during_via_counter_256:
    ldx #0
wait_during_via_counter_1:
    inx
    bne wait_during_via_counter_1
    dey
    bne wait_during_via_counter_256
    
    rts

via_counter_did_not_run:
    ; We waited but nothing was counted, something must be wrong with the VIA
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<via_counter_did_not_run_message
    sta TEXT_TO_PRINT
    lda #>via_counter_did_not_run_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    rts

cpu_speed_too_low:
    ; We have a cpu speed that is too low
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<too_low_message
    sta TEXT_TO_PRINT
    lda #>too_low_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    rts

print_cpu_speed_via:
    pha
    cmp ESTIMATED_CPU_SPEED_PCM
    bne cpu_speeds_differ_via
    lda #COLOR_OK
    jmp color_cpu_speed_done_via
cpu_speeds_differ_via:
    lda #COLOR_ERROR
color_cpu_speed_done_via:
    sta TEXT_COLOR

    pla
    jsr print_byte_as_decimal     

    lda #<mhz_message
    sta TEXT_TO_PRINT
    lda #>mhz_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    rts
