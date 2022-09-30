; Tests for checking functionality of System Management Controller

SMC_I2C_ADDR  = $42

ECHO_REGISTER = $08

smc_header: 
    .asciiz "System Management Controller:"
testing_smc_echoing_message: 
    .asciiz "Testing echoing towards SMC ($08) ... "
error_while_writing_to_smc_message: 
    .asciiz "error while writing to SMC"
error_while_reading_from_smc_message: 
    .asciiz "error while reading from SMC"

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
