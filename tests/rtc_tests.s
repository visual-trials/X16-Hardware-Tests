; Tests for checking functionality of System Management Controller

RTC_I2C_ADDR  = $6F

START_OF_SRAM_REGISTER = $20

rtc_header: 
    .asciiz "Real Time Clock:"
testing_rtc_sram_message: 
    .asciiz "Testing SRAM of the RTC (64 bytes) ... "
error_while_writing_to_rtc_sram_message: 
    .asciiz "error while writing to RTC SRAM"
error_while_reading_from_rtc_sram_message: 
    .asciiz "error while reading from RTC SRAM"

print_rtc_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<rtc_header
    sta TEXT_TO_PRINT
    lda #>rtc_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts

test_rtc_sram:

    ; We are trying to write to and read from SRAM of the RTC
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_rtc_sram_message
    sta TEXT_TO_PRINT
    lda #>testing_rtc_sram_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
; FIXME: this can *HANG* if there is no RTC available!?
    ldx #RTC_I2C_ADDR
    ldy #START_OF_SRAM_REGISTER
    
rtc_sram_next:
    lda #$FF
    jsr i2c_write_byte
    bcs rtc_sram_write_error
    
    eor #$FF  ; making sure register a is inverted (TODO: this is really not needed, but wont hurt)
    jsr i2c_read_byte
    bcs rtc_sram_read_error
    
    cmp #$FF   ; Check if its the same number
    bne rtc_sram_not_the_same_value
    
    lda #$00
    jsr i2c_write_byte
    bcs rtc_sram_write_error
    
    eor #$FF  ; making sure register a is inverted (TODO: this is really not needed, but wont hurt)
    jsr i2c_read_byte
    bcs rtc_sram_read_error
    
    cmp #$00   ; Check if its the same number
    bne rtc_sram_not_the_same_value

    iny
    cpy #$60             ; the SRAM memory runs up to register 5F
    bne rtc_sram_next
    
    lda #COLOR_OK
    sta TEXT_COLOR

    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    bra done_rtc_sram

rtc_sram_not_the_same_value:
    
    sta IO3_BASE_ADDRESS
    
    sta BAD_VALUE
    
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

; FIXME: print SRAM register address!
    
; FIXME: say $A5!=$A4
; FIXME: say $A5!=$A4
; FIXME: say $A5!=$A4
    
    ; lda BAD_VALUE
    ; sta BYTE_TO_PRINT
    ; jsr print_byte_as_hex
    
    bra done_rtc_sram
    
rtc_sram_write_error:

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<error_while_writing_to_rtc_sram_message
    sta TEXT_TO_PRINT
    lda #>error_while_writing_to_rtc_sram_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    bra done_rtc_sram
    
rtc_sram_read_error:

    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<error_while_reading_from_rtc_sram_message
    sta TEXT_TO_PRINT
    lda #>error_while_reading_from_rtc_sram_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_rtc_sram:
    jsr move_cursor_to_next_line
    
    rts
