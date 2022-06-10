; Tests for checking functionality of VERA SD

; We use this as basis for SD card communication using SPI:
;   http://elm-chan.org/docs/mmc/mmc_e.html

; We try to implement this chart for SD Card initialization:
;   http://elm-chan.org/docs/mmc/m/sdinit.png


SPI_CHIP_DESELECT_AND_SLOW =   %00000010
SPI_CHIP_SELECT_AND_SLOW   =   %00000011

vera_sd_header: 
    .asciiz "VERA - SD:"
    
vera_sd_reset_message:
    .asciiz "Detecting and resetting SD Card ... "
vera_sd_no_card_detected: 
    .asciiz "No card detected"
   
print_vera_sd_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<vera_sd_header
    sta TEXT_TO_PRINT
    lda #>vera_sd_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts

    
vera_reset_sd_card:

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<vera_sd_reset_message
    sta TEXT_TO_PRINT
    lda #>vera_sd_reset_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    

    ; === Power ON ===

    ; "Set SPI clock rate between 100 kHz and 400 kHz.
    ;  Set DI and CS high and apply 74 or more clock pulses to SCLK"
       
    ; Note that DI is pulled high (in hardware) so we dont have to do anything in software to arrange that.
    ; We deselect (=CS high) the card by setting a bit to 1 in the CTRL register in VERA. The speed of the clock is set to 390kHz.
    
    lda #SPI_CHIP_DESELECT_AND_SLOW
    sta VERA_SPI_CTRL
    
    ; We apply (at least) 74 clock pulses a reading 10 bytes (10 * 8 = 80 clock pulses) from the card
    ldx #10
spi_dummy_clock_loop:
    jsr spi_read_byte
    dex
    bne spi_dummy_clock_loop
    
    
    ; === Software reset ===
    
    ; "Send a CMD0 with CS low to reset the card. The card samples CS signal on a CMD0 is received successfully. 
    ;  If the CS signal is low, the card enters SPI mode and responds R1 with In Idle State bit set (0x01). 
    ;  Since the CMD0 must be sent as a native command, the CRC field must have a valid value. When once the card 
    ;  enters SPI mode, the CRC feature is disabled and the command CRC and data CRC are not checked by the card, 
    ;  so that command transmission routine can be written with the hardcorded CRC value that valid for only CMD0 
    ;  and CMD8 used in the initialization process."

    ; We set CS low (but keep the clock speed slow)
    lda #SPI_CHIP_SELECT_AND_SLOW
    sta VERA_SPI_CTRL
    
; FIXME: maybe we have to read adter the select?
    jsr spi_read_byte
    jsr spi_read_byte
; FIXME: maybe we have to wait for the card to be ready?
;    ldx #0
;    tmp_loop_x:
;    ldy #0
;    tmp_loop_y:
;    jsr spi_read_byte
;    iny
;    bne tmp_loop_y
;    inx
;    bne tmp_loop_x

    
    ; We send command 0 to do a software reset
    jsr spi_send_command0
    
    bcs command0_success
command0_timed_out:

    ; If carry is unset, we timed out. We print 'No Card Detected' as a warning
    lda #COLOR_WARNING
    sta TEXT_COLOR
    
    lda #<vera_sd_no_card_detected
    sta TEXT_TO_PRINT
    lda #>vera_sd_no_card_detected
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jmp done_with_command0
command0_success:
    pha

    ; FIXME: if carry is set we get a byte of response. We should print that in hex. -> in green if there are no errors and we are in idle state
    
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    pla
    
    ; FIXME: for now we are simply printing the value we received from the SD card
    ; if the value is #$01 we should say 'OK', otherwise we should print the byte as error
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    
done_with_command0:

    rts



spi_send_command0:

    ; The command index requires the highest bit to be 0 and the bit after that to be 1 = $40
    lda #(0 | $40)      
    jsr spi_write_byte
    
    ; Command 0 has no arguments, so sending 4 bytes with value 0
    lda #0
    jsr spi_write_byte
    jsr spi_write_byte
    jsr spi_write_byte
    jsr spi_write_byte
    
    ; Command 0 requires an CRC. Since everything is fixed for this command, the CRC is already known
    lda #$95            ; CRC for command0
    jsr spi_write_byte

    ; We wait for a response
    ldx #20                   ; TODO: how many retries do we want to do?
spi_wait_command0:
    dex
    beq spi_command0_timeout
    jsr spi_read_byte
    tay                       ; we want to keep the original value (so we put it in y for now)
    ; FIXME: Use 65C02 processor so we can use "bit #$80" here
    and #$80
    cmp #$80
    beq spi_wait_command0
    
    tya                       ; we restore the original value (stored in y)

    sec  ; set the carry: we succeeded
    rts

spi_command0_timeout:
    clc  ; clear the carry: we did not succeed
    rts



spi_read_byte:

    ; "Because the data transfer is driven by serial clock generated by host controller, the host controller 
    ;  must continue to read data, send a 0xFF and get received byte, until a valid response is detected. 
    ;  The DI signal must be kept high during read transfer (send a 0xFF and get the received data). 
    ;  The response is sent back within command response time (NCR), 0 to 8 bytes for SDC, 1 to 8 bytes for MMC."
     
    ; Send 1s (=FF) to the card (MOSI), while keeping the clock running
    lda #$FF
    sta VERA_SPI_DATA
    
    ; VERA is sending the data using SPI to the SD card. This takes some time. We wait until VERA says it has done the sending (and receiving a response).
wait_spi_read_busy:
    bit VERA_SPI_CTRL
    bmi wait_spi_read_busy
    
    ; Read the byte of data VERA got back from the card
    lda VERA_SPI_DATA
    rts


    ; Data in register a will be written using SPI to the SD card (through VERA registers)
spi_write_byte:
    sta VERA_SPI_DATA
    
    ; VERA is sending the data using SPI to the SD card. This takes some time. We wait until VERA says it has done the sending (and receiving a response).
wait_spi_write_busy:
    bit VERA_SPI_CTRL
    bmi wait_spi_write_busy  ; if bit 7 is high (Busy bit) we keep waiting
    
    rts

