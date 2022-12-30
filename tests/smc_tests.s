; Tests for checking functionality of System Management Controller

SMC_I2C_ADDR  = $42

KEYBOARD_SCANCODE_REGISTER = $07
ECHO_REGISTER = $08

smc_header: 
    .asciiz "System Management Controller:"
testing_smc_echoing_message: 
    .asciiz "Testing echoing towards SMC ($08) ... "
error_while_writing_to_smc_message: 
    .asciiz "error while writing to SMC"
error_while_reading_from_smc_message: 
    .asciiz "error while reading from SMC"
testing_smc_receiving_keyboard_scancode_message:
    .asciiz "Testing receiving keyboard scancodes ($07) ... "
warning_no_scancode_received_message:
    .asciiz "No scancode received"
please_press_spacebar_message:
    .asciiz "please press SPACEBAR!"
please_press_spacebar_clear_message:
    .asciiz "                      "
error_unexpected_scancode_message:
    .asciiz "Unexpected keycode ($"


print_smc_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<smc_header
    sta TEXT_TO_PRINT
    lda #>smc_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts

test_echoing_towards_smc:

    ; We are trying to write to and read one byte to the 'echo' register of the SMC
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_smc_echoing_message
    sta TEXT_TO_PRINT
    lda #>testing_smc_echoing_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
; FIXME: this can *HANG* if there is no SMC available!?
    ldx #SMC_I2C_ADDR
    ldy #ECHO_REGISTER
    
    lda #0
    sta TMP1
echo_to_smc_next:
    lda TMP1
    jsr i2c_write_byte
    bcs echo_write_error
    
    eor #$FF  ; making sure register a is inverted (TODO: this is really not needed, but wont hurt)
    jsr i2c_read_byte
    bcs echo_read_error
    
    cmp TMP1   ; Check if its the same number
    bne echo_not_the_same_value
    
    inc TMP1
    bne echo_to_smc_next
    
    lda #COLOR_OK
    sta TEXT_COLOR

    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    bra done_echoing_towards_smc

echo_not_the_same_value:
    
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
    ; lda TMP1
    ; sta BYTE_TO_PRINT
    ; jsr print_byte_as_hex
    
    ; lda BAD_VALUE
    ; sta BYTE_TO_PRINT
    ; jsr print_byte_as_hex
    
    bra done_echoing_towards_smc
    
echo_write_error:

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<error_while_writing_to_smc_message
    sta TEXT_TO_PRINT
    lda #>error_while_writing_to_smc_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    bra done_echoing_towards_smc
    
echo_read_error:

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<error_while_reading_from_smc_message
    sta TEXT_TO_PRINT
    lda #>error_while_reading_from_smc_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_echoing_towards_smc:
    jsr move_cursor_to_next_line
    
    rts

    
test_receiving_keyboard_scancode_smc:

    ; FIXME: try to read more that ONE keycode and check for keyUp keycodes as well!

    ; We are trying to write to and read one byte to the 'echo' register of the SMC
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_smc_receiving_keyboard_scancode_message
    sta TEXT_TO_PRINT
    lda #>testing_smc_receiving_keyboard_scancode_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #COLOR_ACTION
    sta TEXT_COLOR

    ; We remember the position of the cursor before printing the action-message
    lda CURSOR_X
    sta TMP4
    
    lda #<please_press_spacebar_message
    sta TEXT_TO_PRINT
    lda #>please_press_spacebar_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

; FIXME: this can *HANG* if there is no SMC available!?
    ldx #SMC_I2C_ADDR
    ldy #KEYBOARD_SCANCODE_REGISTER

    ; See: https://techdocs.altium.com/display/FPGA/PS2+Keyboard+Scan+Codes
    lda #$29  ; = scan code for space bar
    sta TMP1   ; we store the expected value in TMP1
    
; FIXME: we need to test this on real hardware: how much iterations do we need here? Maybe pause a bit in between i2c read bytes?
    lda #0
    sta TMP2 ; we use TMP2 as a simple counter (low byte)
    lda #30
    sta TMP3 ; we use TMP3 as a simple counter (high byte)
scancode_next_try:
    lda #0
    jsr i2c_read_byte
    
    bcs scancode_read_error
    bne scancode_non_zero
    
    inc TMP2
    bne scancode_next_try
    
    dec TMP3
    bne scancode_next_try
    
    bra scancode_nothing_received
    
scancode_non_zero:
    sta BYTE_TO_PRINT

    cmp TMP1   ; Check if its the same number
    bne scancode_not_the_space_bar_value
    
    jsr clear_spacebar_message
    
    lda #COLOR_OK
    sta TEXT_COLOR

    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    bra done_receiving_keyboard_scancode_smc


scancode_nothing_received:
    jsr clear_spacebar_message

    ; Give a warning if no scancodes were received (maybe the user didnt press a key)
    
    lda #COLOR_WARNING
    sta TEXT_COLOR

    lda #<warning_no_scancode_received_message
    sta TEXT_TO_PRINT
    lda #>warning_no_scancode_received_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    bra done_receiving_keyboard_scancode_smc
    
scancode_not_the_space_bar_value:
    jsr clear_spacebar_message

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<error_unexpected_scancode_message
    sta TEXT_TO_PRINT
    lda #>error_unexpected_scancode_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr print_byte_as_hex
    
    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    inc CURSOR_X

    bra done_receiving_keyboard_scancode_smc
    
scancode_read_error:
    jsr clear_spacebar_message

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<error_while_reading_from_smc_message
    sta TEXT_TO_PRINT
    lda #>error_while_reading_from_smc_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero


done_receiving_keyboard_scancode_smc:
    jsr move_cursor_to_next_line
    
    rts
    

clear_spacebar_message:    
    ; We clear the spacebar-message
    lda TMP4
    sta CURSOR_X
    
    lda #<please_press_spacebar_clear_message
    sta TEXT_TO_PRINT
    lda #>please_press_spacebar_clear_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda TMP4
    sta CURSOR_X
    
    rts
    
    
    