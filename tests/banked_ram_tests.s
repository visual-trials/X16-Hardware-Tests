
; Note: these start and end addresses need to end with 00
BANKED_RAM_START_ADDR = $A000
BANKED_RAM_END_ADDR   = $C000

banked_ram_header: 
    .asciiz "Banked RAM:"
testing_banked_ram_message1: 
    .asciiz "Testing "
testing_banked_ram_message2: 
    .asciiz " unique RAM Banks ($A000 - $BFFF) ... "
nr_of_working_ram_banks_message: 
    .asciiz "Measuring number of working RAM banks ... "
nr_of_unique_ram_banks_message: 
    .asciiz "Measuring number of unique RAM banks ... "
nr_of_ram_banks_256_message: 
    .asciiz "256"

print_banked_ram_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<banked_ram_header
    sta TEXT_TO_PRINT
    lda #>banked_ram_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
    
    
    ; --- Testing Banked RAM
test_banked_ram:

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_banked_ram_message1
    sta TEXT_TO_PRINT
    lda #>testing_banked_ram_message1
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda NR_OF_UNIQUE_RAM_BANKS+1
    bne print_256_unique_while_testing 
    
    ; Less than 256 unqiue banks
    lda NR_OF_UNIQUE_RAM_BANKS
    jsr print_byte_as_decimal
    
    jmp done_printing_nr_of_banked_ram
print_256_unique_while_testing:
    ; Exactly 256 unqiue banks
    lda #<nr_of_ram_banks_256_message
    sta TEXT_TO_PRINT
    lda #>nr_of_ram_banks_256_message
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero
    
done_printing_nr_of_banked_ram:    
    lda #<testing_banked_ram_message2
    sta TEXT_TO_PRINT
    lda #>testing_banked_ram_message2
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #0
    sta BANK_TESTING
    
next_ram_bank_to_test:
    lda BANK_TESTING
    sta RAM_BANK
    ; FIXME: remove this nop!
    nop
    
    ldx CURSOR_X
    stx TMP4
    jsr print_byte_as_decimal
    ldx TMP4
    stx CURSOR_X
    
    ; Setting up setup the range to check
    lda #>BANKED_RAM_START_ADDR
    sta START_ADDR_HIGH
    lda #>BANKED_RAM_END_ADDR
    sta END_ADDR_HIGH
    
    jsr test_ram_block
    
    bcc banked_ram_is_not_ok
    
    ldx BANK_TESTING
    inx
    stx BANK_TESTING
    cpx NR_OF_UNIQUE_RAM_BANKS
    bne next_ram_bank_to_test
    
banked_ram_is_ok:
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; TODO: this is a dirty workaround to overwrite the 3-digit counter that is not covered by the 2-letter word 'ok'
    lda #' '
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0           
    
    jmp done_testing_banked_ram
    
banked_ram_is_not_ok:
    ; Currently used to trigger an LA
    lda IO3_BASE_ADDRESS

    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; This uses x as high byte and y as low byte of the address to print    
    jsr print_banked_address
    
done_testing_banked_ram:
    jsr move_cursor_to_next_line

    rts
    
    
    
    
    ; -- Determine amount of Banked RAM
    
determine_nr_of_ram_banks:

    lda #0
    sta NR_OF_WORKING_RAM_BANKS
    sta NR_OF_WORKING_RAM_BANKS+1
    sta NR_OF_UNIQUE_RAM_BANKS
    sta NR_OF_UNIQUE_RAM_BANKS+1
    
    ; - First we set the first byte of each byte to 00 (and check if its working at all)
    
    ldx #0 ; We start with bank 0
check_for_working_next_ram_bank:
    stx RAM_BANK                 ; Switching to the RAM bank
; FIXME: we should remove this nop!!
    nop
    
    lda #$FF
    sta BANKED_RAM_START_ADDR
    lda BANKED_RAM_START_ADDR
    cmp #$FF
    bne bank_is_not_working
    lda #$00
    sta BANKED_RAM_START_ADDR
    lda BANKED_RAM_START_ADDR
    cmp #$00
    bne bank_is_not_working
    inx
    bne check_for_working_next_ram_bank
    
    ; All 256 banks are working
    lda #1
    sta NR_OF_WORKING_RAM_BANKS+1   ; Storing the value $0100
    
    jmp start_unique_ram_check

bank_is_not_working:
    stx NR_OF_WORKING_RAM_BANKS
    cpx #0   ; If we found no working banks at all, we should not check the number of unique banks
    beq done_nr_of_banks

start_unique_ram_check:
    ; - Then we read each first byte and (if still 0) we store an incrementing number in it
    ldx #0 ; We start with bank 0
check_next_ram_bank:
    stx RAM_BANK                 ; Switching to the RAM bank
; FIXME: we should remove this nop!!
    nop
    
    lda BANKED_RAM_START_ADDR  ; We read the current value (0 if not yet touched)
    bne bank_already_counted   ; If not 0, the memory is looping/reused
    lda #42
    sta BANKED_RAM_START_ADDR  ; We store a 'random' number in it
    inx
    cpx NR_OF_WORKING_RAM_BANKS  ; Note that if NR_OF_WORKING_RAM_BANKS = $0100, this will check all 256 banks
    bne check_next_ram_bank

    ; All working banks are unique
    lda NR_OF_WORKING_RAM_BANKS+1
    sta NR_OF_UNIQUE_RAM_BANKS+1
    lda NR_OF_WORKING_RAM_BANKS
    sta NR_OF_UNIQUE_RAM_BANKS
    jmp done_nr_of_banks
    
bank_already_counted:
    stx NR_OF_UNIQUE_RAM_BANKS

done_nr_of_banks:
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<nr_of_working_ram_banks_message
    sta TEXT_TO_PRINT
    lda #>nr_of_working_ram_banks_message
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero

    ; Print byte as decimal (and if 256, print '256')
    
    lda NR_OF_WORKING_RAM_BANKS+1
    bne print_256_working
    
    ; Giving a 'WARNING/ERROR' is not all 256 ram banks are working
    
    ; Currently used to trigger an LA
    lda IO3_BASE_ADDRESS

    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda NR_OF_WORKING_RAM_BANKS
    jsr print_byte_as_decimal
    
    jmp done_printing_working_banks
    
print_256_working:    
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<nr_of_ram_banks_256_message
    sta TEXT_TO_PRINT
    lda #>nr_of_ram_banks_256_message
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero

done_printing_working_banks:
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    jsr move_cursor_to_next_line
    
    lda #<nr_of_unique_ram_banks_message
    sta TEXT_TO_PRINT
    lda #>nr_of_unique_ram_banks_message
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero
    
    lda NR_OF_UNIQUE_RAM_BANKS+1
    bne print_256_unique
    
    ; Print byte as decimal (and if 256, print '256')

    lda NR_OF_UNIQUE_RAM_BANKS
    cmp #64
    beq print_unique_banks_ok
    cmp #128
    beq print_unique_banks_ok
    
    ; Giving a 'WARNING/ERROR' if you unique bank count is other than 64 or 128 (note that 1 bank means that your bank switching is not working/disbled)

print_unique_banks_not_ok:
    ; Currently used to trigger an LA
    lda IO3_BASE_ADDRESS

    lda #COLOR_ERROR
    sta TEXT_COLOR
    jmp print_unique_banks
print_unique_banks_ok:
    lda #COLOR_OK
    sta TEXT_COLOR
print_unique_banks:
    lda NR_OF_UNIQUE_RAM_BANKS
    jsr print_byte_as_decimal

    jmp done_printing_unique_banks

print_256_unique:
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<nr_of_ram_banks_256_message
    sta TEXT_TO_PRINT
    lda #>nr_of_ram_banks_256_message
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero
    
    
done_printing_unique_banks:
    jsr move_cursor_to_next_line

    rts

