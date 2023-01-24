    
    
    ; --- Testing a range of RAM (one block of 256 bytes at a time)
test_ram_block:

    lda #0
    sta MEMORY_ADDR_TESTING
    ldx START_ADDR_HIGH
    
check_next_ram_block:
    stx MEMORY_ADDR_TESTING+1
    
    ldy #0
check_ram_block_FF:
    lda #$FF
    sta (MEMORY_ADDR_TESTING), y
    lda (MEMORY_ADDR_TESTING), y
    cmp #$FF
    bne ram_is_not_ok
    iny
    bne check_ram_block_FF
    
    ldy #0
check_ram_block_00:
    lda #$00
    sta (MEMORY_ADDR_TESTING), y
    lda (MEMORY_ADDR_TESTING), y
    cmp #$00
    bne ram_is_not_ok
    iny
    bne check_ram_block_00
    
    inx
    cpx END_ADDR_HIGH
    bne check_next_ram_block
    
    sec   ; We set the carry flag: 'ok'
    jmp done_testing_ram
ram_is_not_ok:
    ; Currently used to trigger an LA
    sta IO3_BASE_ADDRESS
    
    clc    ; We clear the carry flag: 'not ok'
done_testing_ram:
    rts