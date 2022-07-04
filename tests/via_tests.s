; Tests for checking functionality of VERA Audio

via_header: 
    .asciiz "Versatile Interface Adapters:"
testing_measure_cpu_speed_using_via1_counter1: 
    .asciiz "Measuring CPU clock speed using VIA #1 counter 1 ... "
   
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
        
measure_cpu_speed_using_via1_counter1:

    ; We are trying to determine the CPU clock speed based on the counter 1 of VIA #1
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_measure_cpu_speed_using_via1_counter1
    sta TEXT_TO_PRINT
    lda #>testing_measure_cpu_speed_using_via1_counter1
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero


    
    ; Use Timer 1 in one-shot mode on VIA1 to determine speed of CPU
    
    ; https://www.reddit.com/r/beneater/comments/horcks/utilizing_65c22_features_t1_timer/
    ; https://eater.net/datasheets/w65c22.pdf
    
    ; We fill the counter with it max 16-bit value ($FFFF)
    lda #$FF
    sta VIA1_T1C_L
    lda #$FF
    sta VIA1_T1C_H
    
    lda #VIA_T1_MODE0  ; One shot mode
    sta VIA1_ACR
 
    ; We loop 4*256 times  
    ldy #4
wait_during_via1_counter1_256:
    ldx #0
wait_during_via1_counter1_1:
    inx
    bne wait_during_via1_counter1_1
    dey
    bne wait_during_via1_counter1_256
    
    ldx VIA1_T1C_H
    
    ; Approx expected values of counter:
    ; $EBD6 : 8MHz (65536 - 60374 = 5162 counts)
    ; $D7AC : 4MHz (65536 - 55212 = 10324 counts)
    ; $AF58 : 2MHz (65536 - 44888 = 20648 counts)
    ; $5EB0 : 1MHz (65536 - 24240 = 41296 counts)

    ; FIXME: check if we actually got the *counter1* interrupt!
    lda VIA1_IFR
    bne cpu_speed_too_low_via1  ; We got an interrupt, so we counted down completely. We are too slow.
    
    cpx #$FF                  ; Value that is too high, so counter wasn't running?
    beq nothing_counted_via1
    lda #8                    ; We start at 8 MHz
    cpx #$E1                  ; Value between 8 and 4 MHz: 57793 = $E1C1
    bcs cpu_speed_done_via1   ; We got more uncounted so we are at 8MHz
    lda #4                    ; We assume 4 MHz now
    cpx #$C3                  ; Value between 4 and 2 MHz: 50050 = $C382
    bcs cpu_speed_done_via1   ; We got more uncounted so we are at 4MHz
    lda #2                    ; We assume 2 MHz now
    cpx #$87                  ; Value between 2 and 1 MHz: 34564 = $8704
    bcs cpu_speed_done_via1   ; We got more uncounted so we are at 2MHz
    lda #1                    ; We assume 1 MHz now
    bra cpu_speed_done_via1

cpu_speed_done_via1:
    sta ESTIMATED_CPU_SPEED_VIA1
    
measured_ok_cpu_speed_via1:
    ; We measure the CPU speed, so we are reporting it here
    jsr print_cpu_speed_via1

    jmp done_measuring_cpu_speed_via1

cpu_speed_too_low_via1:

    ; We have a cpu speed that is too low
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<too_low_message
    sta TEXT_TO_PRINT
    lda #>too_low_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jmp done_measuring_cpu_speed_via1
    
nothing_counted_via1:
    ; We waited but nothing was counted, something must be wrong with the VIA
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; FIXME: print *what* went wrong!!
    
done_measuring_cpu_speed_via1:

    jsr move_cursor_to_next_line
    
    ; FIXME: unset interrupts!
    ; FIXME: unset interrupts!
    ; FIXME: unset interrupts!


    jsr move_cursor_to_next_line

    rts

print_cpu_speed_via1:
    cmp ESTIMATED_CPU_SPEED_PCM
    bne cpu_speeds_differ_via1
    lda #COLOR_OK
    jmp color_cpu_speed_done_via1
cpu_speeds_differ_via1:
    lda #COLOR_ERROR
color_cpu_speed_done_via1:
    sta TEXT_COLOR

    lda ESTIMATED_CPU_SPEED_VIA1
    jsr print_byte_as_decimal     

    lda #<mhz_message
    sta TEXT_TO_PRINT
    lda #>mhz_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    rts
