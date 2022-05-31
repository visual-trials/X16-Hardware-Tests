
; Note: these start and end addresses need to end with 00
BANKED_ROM_START_ADDR = $C000
BANKED_ROM_END_ADDR   = $0000
NR_OF_ROM_BANKS       = 32

banked_rom_header: 
    .asciiz "Banked ROM:"
testing_banked_rom_message: 
    .asciiz "Testing ROM Banks 1-31 ($C000 - $FFFF) ... "

    
print_banked_rom_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<banked_rom_header
    sta TEXT_TO_PRINT
    lda #>banked_rom_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
    

    ; --- Testing ROM Banks
test_rom_banks:

    ; Copying test_rom_bank -> ROM_TEST_CODE
    
    ldy #0
copy_rom_test_code_byte:
    lda test_rom_bank, y
    sta ROM_TEST_CODE, y
    iny 
    cpy #(end_of_test_rom_bank-test_rom_bank)
    bne copy_rom_test_code_byte
    
    ; Printing message

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_banked_rom_message
    sta TEXT_TO_PRINT
    lda #>testing_banked_rom_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; Setting up setup the range to check
    
    lda #>BANKED_ROM_START_ADDR
    sta START_ADDR_HIGH
    lda #>BANKED_ROM_END_ADDR
    sta END_ADDR_HIGH
    
    ; We start at rom bank 1, since rom bank 0 is obviously working (we run this code from it!)
    lda #1
    sta BANK_TESTING
    
next_rom_bank_to_test:
    ldx CURSOR_X
    stx TMP4
    jsr print_byte_as_decimal
    ldx TMP4
    stx CURSOR_X
    
    jsr ROM_TEST_CODE
    
    bcc banked_rom_is_not_ok
    
    ldx BANK_TESTING
    inx
    stx BANK_TESTING
    cpx #NR_OF_ROM_BANKS
    bne next_rom_bank_to_test
    
banked_rom_is_ok:
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jmp done_testing_banked_rom
    
banked_rom_is_not_ok:
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; This uses x as high byte and y as low byte of the address to print    
    jsr print_banked_address
    
    ; Currently used to trigger an LA
    lda IO3_BASE_ADDRESS

done_testing_banked_rom:
    jsr move_cursor_to_next_line

    rts
    
    
    
    
; Note: this function is copied to RAM so we can switch to a different ROM bank (and switch back afterwards)
test_rom_bank:

    ; Switching ROM BANK
    ldx BANK_TESTING
    stx ROM_BANK
; FIXME: remove nop!
    nop

    ; --- Testing a range of ROM (one block of 256 bytes at a time)

    lda #0
    sta MEMORY_ADDR_TESTING
    ldx START_ADDR_HIGH
    
check_next_rom_block:
    stx MEMORY_ADDR_TESTING+1

    ldy #0
check_rom_block:
    lda (MEMORY_ADDR_TESTING), y
    cmp BANK_TESTING
    bne rom_is_not_ok
    iny
    bne check_rom_block
    
    inx
    cpx END_ADDR_HIGH
    bne check_next_rom_block
    
    sec   ; We set the carry flag: 'ok'
    
    ; Switching bank to ROM bank 0
    ldx #$00
    stx ROM_BANK
; FIXME: remove nop!
    nop
    rts
rom_is_not_ok:
    clc    ; We clear the carry flag: 'not ok'
    
    ; Switching bank to ROM bank 0
    ldx #$00
    stx ROM_BANK
; FIXME: remove nop!
    nop
    rts
end_of_test_rom_bank: