
; Print margins
MARGIN          = 2
INDENT_SIZE     = 2

; Colors
COLOR_TITLE        = $43 ; Background color = 4, foreground color 3 (cyan)
COLOR_NORMAL       = $41 ; Background color = 4, foreground color 1 (white)
COLOR_TRANSPARANT  = $01 ; Background color = 0, foreground color 1 (white)
COLOR_HEADER       = $47 ; Background color = 4, foreground color 7 (yellow)
COLOR_OK           = $45 ; Background color = 4, foreground color 5 (green)
COLOR_ERROR        = $42 ; Background color = 4, foreground color 2 (red)
COLOR_WARNING      = $48 ; Background color = 4, foreground color 8 (orange)
COLOR_ACTION       = $43 ; Background color = 4, foreground color 3 (cyan)
COLOR_UNKNOWN      = $4F ; Background color = 4, foreground color F (light grey)

ok_message: 
    .asciiz "OK"
done_message: 
    .asciiz "DONE"
not_ok_message: 
    .asciiz "NOT OK"
spi_command_error: 
    .asciiz "NOT OK (CMD"

too_low_message:
     .asciiz "too low"
too_high_message:
     .asciiz "too high"
mhz_message:
    .asciiz "MHz"

move_cursor_to_next_line:
    pha

    lda INDENTATION
    sta CURSOR_X
    inc CURSOR_Y

    pla
    rts

setup_cursor:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0
    clc
    adc CURSOR_Y             ; this assumes TILE_MAP_WIDTH = 128 (and each tile takes 2 bytes, so we add $100 for each Y)
    sta VERA_ADDR_HIGH
    lda CURSOR_X
    asl                      ; each tile takes to bytes, so we shift to the left once
    sta VERA_ADDR_LOW
    rts


; -- Prints a zero-terminated string
;
; TEXT_TO_PRINT : address containing the ASCII text to print
; TEXT_COLOR : two nibbles containing the background and foreground color of the text
; CURSOR_X : the x-position of the cursor to start printing
; CURSOR_Y : the y-position of the cursor to start printing (assuming TILE_MAP_WIDTH = 128)
;
print_text_zero:
    pha
    tya
    pha

    jsr setup_cursor

    ldy #0
print_next_char:
    lda (TEXT_TO_PRINT), y
    beq done_print_text
    cmp #97  ; 'a'
    bpl char_larger_than_or_equal_to_a
char_smaller_than_a:            
    cmp #65  ; 'A'
    bpl char_between_A_and_a
    ; This part is roughly the same between ASCII and PETSCII
    jmp char_conversion_done
char_between_A_and_a:           ; Uppercase letters
    sec
    sbc #64
    jmp char_conversion_done
char_larger_than_or_equal_to_a: ; Lowercase letters
    sec
    sbc #96
    clc
    adc #128
char_conversion_done:
    iny
    sta VERA_DATA0
    lda TEXT_COLOR                 ; Background color is high nibble, foreground color is low nibble
    sta VERA_DATA0           
    jmp print_next_char
  
done_print_text:

    clc
    tya
    adc CURSOR_X
    sta CURSOR_X

    pla
    tay
    pla

    rts
    
print_raw_text_zero:
    pha
    tya
    pha

    jsr setup_cursor

    ldy #0
print_next_char_raw:
    lda (TEXT_TO_PRINT), y
    beq done_print_text_raw
    iny
    sta VERA_DATA0
    lda TEXT_COLOR                 ; Background color is high nibble, foreground color is low nibble
    sta VERA_DATA0           
    jmp print_next_char_raw
  
done_print_text_raw:

    clc
    tya
    adc CURSOR_X
    sta CURSOR_X

    pla
    tay
    pla

    rts
    
    
print_petscii_table:

    pha
    tya
    pha

    lda INDENTATION
    sta CURSOR_X
    
    jsr setup_cursor

    ldy #0
    ldx #0
print_next_petscii_char:
    sty VERA_DATA0
    lda TEXT_COLOR                 ; Background color is high nibble, foreground color is low nibble
    sta VERA_DATA0           
    
    inx
    cpx #16
    bne keep_printing_perscii_chars

    ldx #0
    jsr move_cursor_to_next_line
    jsr setup_cursor
    
keep_printing_perscii_chars:
    iny
    bne print_next_petscii_char
    
    pla
    tay
    pla

    rts
  

    
print_byte_as_decimal:

    sta BYTE_TO_PRINT
    jsr setup_cursor
    
    lda BYTE_TO_PRINT
    
    jsr mod10
    clc
    adc #'0'
    sta DECIMAL_STRING+2
    txa
    jsr mod10
    clc
    adc #'0'
    sta DECIMAL_STRING+1
    txa
    jsr mod10
    clc
    adc #'0'
    sta DECIMAL_STRING
    
    lda BYTE_TO_PRINT
    cmp #10
    bcc print_ones
    cmp #100
    bcc print_tens
    
print_hundreds:
    lda DECIMAL_STRING
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
print_tens:
    lda DECIMAL_STRING+1
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
print_ones:
    lda DECIMAL_STRING+2
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    rts


; modulus 10 a byte
; Input
;   a : byte to do modulus once
; Result
;   a : a % 10
;   x : a / 10
mod10:
    ; TODO: This is not a good way of doing a mod10, make it better someday
    sta TMP2

    ; Divide by 10 ( from: https://codebase64.org/doku.php?id=base:8bit_divide_by_constant_8bit_result )
    lsr
    sta  TMP1
    lsr
    adc  TMP1
    ror
    lsr
    lsr
    adc  TMP1
    ror
    adc  TMP1
    ror
    lsr
    lsr
    
    sta TMP1  ; number divided by 10 is in TMP1
    tax      ; a = a / 10
    
    ; We multiply the divided number by 10 again
    
    asl
    asl
    asl      ; * 8
    asl TMP1 ; * 2
    clc
    adc TMP1 ; a * 8 + a * 2 = a * 10
    sta TMP1
    
    lda TMP2
    sec
    sbc TMP1 ; a - ((a / 10) * 10) = a % 10
    
    rts



; -- Prints an 16-byte address as an hexidecimal string to screen (including a space and parentheses)
; y contains the low byte of the address
; x contains the high byte of the address
; BAD_VALUE contains value that was read from RAM but was not equal to what was stored into RAM
;
print_fixed_ram_address:

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

    lda #'='
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda BAD_VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    inc CURSOR_X

    rts
    
; -- Prints an 16-byte address as an hexidecimal string to screen (including a space and parentheses)
; y contains the low byte of the address
; x contains the high byte of the address
; BAD_VALUE contains value that was read from RAM but was not equal to what was stored into RAM
; 
print_banked_address:

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
    
    txa
    pha
    tya
    pha
    
    lda BANK_TESTING
    jsr print_byte_as_decimal
    
    pla
    tay
    pla
    tax
    
    lda #':'
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

    lda #'='
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda BAD_VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    inc CURSOR_X

    rts
    


; -- Prints an 16-byte address as an hexidecimal string to screen (including a space and parentheses)
; y contains the low byte of the address
; x contains the high byte of the address
; BAD_VALUE contains value that was read from RAM but was not equal to what was stored into RAM
; 
print_lower_vram_address:

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

    ; Since this is the lower part of vram, we first print a 0 here
    lda #'0'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    stx BYTE_TO_PRINT
    jsr print_byte_as_hex
    sty BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #'='
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda BAD_VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    inc CURSOR_X

    rts

; -- Prints an 16-byte address as an hexidecimal string to screen (including a space and parentheses)
; y contains the low byte of the address
; x contains the high byte of the address
; BAD_VALUE contains value that was read from RAM but was not equal to what was stored into RAM
; 
print_upper_vram_address:

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

    ; Since this is the upper part of vram, we first print a 1 here
    lda #'1'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    stx BYTE_TO_PRINT
    jsr print_byte_as_hex
    sty BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #'='
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda BAD_VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    inc CURSOR_X

    rts

; x = command number (to print as decimal)
; a = error byte to print in hex
print_spi_cmd_error:
    pha
    txa
    pha
    
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<spi_command_error
    sta TEXT_TO_PRINT
    lda #>spi_command_error
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    pla ; contains command number
    jsr print_byte_as_decimal

    lda #':'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    ; FIXME: for now we are simply printing the value we received from the SD card
    ; if the value is #$01 we should say 'OK', otherwise we should print the byte as error
    pla
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    lda #')'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    rts
    

; BYTE_TO_PRINT : contains the byte to print as hex
print_byte_as_hex:
    
    ; Print high nibble
    lda BYTE_TO_PRINT
    lsr
    lsr
    lsr
    lsr
    cmp #10
    bpl high_nibble_is_larger_than_or_equal_to_10
    clc
    adc #'0'
    jmp high_nibble_ready
high_nibble_is_larger_than_or_equal_to_10:
    sec
    sbc #9
high_nibble_ready:
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    ; Print low nibble
    lda BYTE_TO_PRINT
    and #$0f
    cmp #10
    bpl low_nibble_is_larger_than_or_equal_to_10
    clc
    adc #'0'
    jmp low_nibble_ready
low_nibble_is_larger_than_or_equal_to_10:
    sec
    sbc #9
low_nibble_ready:
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    rts
    

output_3bits_as_debug_leds:

    pha

    lda #%11111111  ; Set all pins on port B to output
    sta VIA2_DDRB
    
    ; We have 3 leds connected: red on bit 0, yellow on bit 2, greenon bit 4, so we need to convert the number to these output bits
    lda #0
    sta TMP2
    
    lda #%00000001
    and BYTE_TO_PRINT
    beq red_light_set
    
    lda TMP2
    ora #%00000001  ; set RED light
    sta TMP2
red_light_set:

    lda #%0000010
    and BYTE_TO_PRINT
    beq yellow_light_set

    lda TMP2
    ora #%00000100  ; set YELLOW light
    sta TMP2
yellow_light_set:

    lda #%00000100
    and BYTE_TO_PRINT
    beq green_light_set

    lda TMP2
    ora #%00010000  ; set GREEN light
    sta TMP2
green_light_set:
    
    lda TMP2
    sta VIA2_PORTB 
    
    pla
    
    rts
