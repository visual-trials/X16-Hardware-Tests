
; Note: these start and end addresses need to end with 00
FIXED_RAM_START_ADDR = $0200
FIXED_RAM_END_ADDR   = $9F00

fixed_ram_header_message: 
    .asciiz "Fixed RAM:"
testing_fixed_ram_message: 
    .asciiz "Testing Fixed RAM ($0200 - $9EFF) ... "

; --- Testing Fixed RAM
test_fixed_ram:

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_fixed_ram_message
    sta TEXT_TO_PRINT
    lda #>testing_fixed_ram_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; Setting up setup the range to check
    lda #>FIXED_RAM_START_ADDR
    sta START_ADDR_HIGH
    lda #>FIXED_RAM_END_ADDR
    sta END_ADDR_HIGH
    
    jsr test_ram_block
    
    bcc fixed_ram_is_not_ok

fixed_ram_is_ok:
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    jmp done_testing_fixed_ram
    
fixed_ram_is_not_ok:
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; This uses x as high byte and y as low byte of the address to print    
    jsr print_address
    
    ; Currently used to trigger an LA
    lda IO3_BASE_ADDRESS

done_testing_fixed_ram:
    jsr move_cursor_to_next_line

    rts
    