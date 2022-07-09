; Tests for checking functionality of VERA Audio

; https://www.reddit.com/r/beneater/comments/horcks/utilizing_65c22_features_t1_timer/
; https://eater.net/datasheets/w65c22.pdf

via_header: 
    .asciiz "Versatile Interface Adapters:"
testing_via1_latch1_message: 
    .asciiz "Testing write and read VIA #1 latch 1 ... "
testing_via2_latch1_message: 
    .asciiz "Testing write and read VIA #2 latch 1 ... "
testing_speed_of_via1_counter1: 
    .asciiz "Testing speed of VIA #1 counter 1 ... "
testing_speed_of_via2_counter1: 
    .asciiz "Testing speed of VIA #2 counter 1 ... "
via_counter_ran_out_message: 
    .asciiz "counter ran out"

   
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
    
    sta IO3_BASE_ADDRESS
    
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
    
    sta IO3_BASE_ADDRESS
    
    sta BAD_VALUE
    
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

; FIXME: say $A5!=$A4
; FIXME: say $A5!=$A4
; FIXME: say $A5!=$A4
    
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

test_via1_counter1_speed:
    ; We are trying to determine whether the counter 1 of VIA #1 run at the correct speed
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_speed_of_via1_counter1
    sta TEXT_TO_PRINT
    lda #>testing_speed_of_via1_counter1
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

    ; We wait for a while
    jsr wait_during_via_counting
    
    ; Read the Interrupt flags into a
    lda VIA1_IFR
    
    ; Then read the high byte of the counter into x
    ldx VIA1_T1C_H
    
    ; Then read the low byte of the counter into y
    ldy VIA1_T1C_L

    ; Check bit 6: if its 1 then we got an interrupt for this counter
    and #$40
    bne counter_speed_ran_out_via1  ; We got an interrupt, so we counted down (ran out) completely. 

    cpx #$EB                  ; Normally the count is around $EB1F, so we check if the high byte is $EB
    bne counter_speed_not_ok_via1

counter_speed_ok_via1:
    jsr print_via_ok

    jmp done_testing_counter_speed_via1
counter_speed_not_ok_via1:
    jsr print_via_not_ok

    jmp done_testing_counter_speed_via1
counter_speed_ran_out_via1:
    jsr print_via_ran_out
done_testing_counter_speed_via1:

    ; TODO: unset interrupts?

    jsr move_cursor_to_next_line

    rts
    
    
test_via2_counter1_speed:
    ; We are trying to determine whether the counter 1 of VIA #2 run at the correct speed
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_speed_of_via2_counter1
    sta TEXT_TO_PRINT
    lda #>testing_speed_of_via2_counter1
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; FIXME: Make sure to disable all interrupts (IER) for the VIA

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
    
    ; Read the Interrupt flags into a
    lda VIA2_IFR
    
    ; Then read the high byte of the counter into x
    ldx VIA2_T1C_H
    
    ; Then read the low byte of the counter into y
    ldy VIA2_T1C_L

    ; Check bit 6: if its 1 then we got an interrupt for this counter
    and #$40
    bne counter_speed_ran_out_via2  ; We got an interrupt, so we counted down (ran out) completely. 

    cpx #$EB                  ; Normally the count is around $EB1F, so we check if the high byte is $EB
    bne counter_speed_not_ok_via2

counter_speed_ok_via2:
    jsr print_via_ok

    jmp done_testing_counter_speed_via2
counter_speed_not_ok_via2:
    jsr print_via_not_ok

    jmp done_testing_counter_speed_via2
counter_speed_ran_out_via2:
    jsr print_via_ran_out
done_testing_counter_speed_via2:

    ; TODO: unset interrupts?

    jsr move_cursor_to_next_line

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

print_via_ok:
    lda #COLOR_OK
    sta TEXT_COLOR

    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; TODO: remove this?
    jsr print_via_counter_value

    rts
    
print_via_not_ok:
    ; We waited but we did not get the expected counter value
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jsr print_via_counter_value

    rts
    
print_via_ran_out:
    ; We waited but the counter ran out (to 0) causing an interrupt
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<via_counter_ran_out_message
    sta TEXT_TO_PRINT
    lda #>via_counter_ran_out_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jsr print_via_counter_value

    rts
    
; x = high byte, y = low byte
print_via_counter_value:

    jsr setup_cursor
    
    lda #' '
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'('
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    stx BYTE_TO_PRINT
    jsr print_byte_as_hex
    sty BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    inc CURSOR_X

    rts
