; This is a single test for the Zero page and stack memory in the X16
; This memory spans from $0002 to $01FF 
; Note that addresses $0000 and $0001 are special addresses and should NOT be regarded as RAM here (and are -for now- skipped)

ram_block_0 = $0000
ram_block_1 = $0100

print_testing_zp_stack_ram:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B4
    sta VERA_ADDR_HIGH
    lda #($00+MARGIN*2+INDENT_SIZE*2)
    sta VERA_ADDR_LOW
    
    ldx #0
print_testing_message:
    lda testing_message, x
    beq done_print_testing_message
    cmp #97  ; 'a'
    bpl larger_than_or_equal_to_a
smaller_than_a:            
    cmp #65  ; 'A'
    bpl between_A_and_a
    ; This part is roughly the same between ASCII and PETSCII
    jmp char_convert_done
between_A_and_a:           ; Uppercase letters
    sec
    sbc #64
    jmp char_convert_done
larger_than_or_equal_to_a: ; Lowercase letters
    sec
    sbc #96
    clc
    adc #128
char_convert_done:  
    inx
    sta VERA_DATA0
    lda #$41                 ; Background color 4, foreground color 1
    sta VERA_DATA0           
    jmp print_testing_message
    
done_print_testing_message:
    jmp test_zp_stack_ram_start
    
testing_message: 
    .asciiz "Testing zero page and stack memory ($0002 - $01FF) ... "

test_zp_stack_ram_start:

    ldy #0                        ; y represents the high byte of the address (0 for $0002 - $00FF)
    
    ldx #2                        ; Skipping $0000 and $0001
check_ram_block_0_FF:
    lda #$FF
    sta ram_block_0, x
    lda ram_block_0, x
    cmp #$FF
    bne zp_stack_ram_is_not_ok
    inx
    bne check_ram_block_0_FF
    
    ldx #2                        ; Skipping $0000 and $0001
check_ram_block_0_00:
    lda #$00
    sta ram_block_0, x
    lda ram_block_0, x
    cmp #$00
    bne zp_stack_ram_is_not_ok
    inx
    bne check_ram_block_0_00
    
    ldy #1                        ; y represents the high byte of the address (1 for $0100 - $01FF)
    
    ldx #0
check_ram_block_1_FF:
    lda #$FF
    sta ram_block_1, x
    lda ram_block_1, x
    cmp #$FF
    bne zp_stack_ram_is_not_ok
    inx
    bne check_ram_block_1_FF
    
    ldx #0
check_ram_block_1_00:
    lda #$00
    sta ram_block_1, x
    lda ram_block_1, x
    cmp #$00
    bne zp_stack_ram_is_not_ok
    inx
    bne check_ram_block_1_00
    
zp_stack_done_checking_ram:
    jmp zp_stack_ram_is_ok
    
zp_stack_ram_is_not_ok:
    ; Currently used to trigger an LA
    lda IO3_BASE_ADDRESS

    lda #('N'-64)
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0             
    lda #('O'-64)
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0             
    lda #('T'-64)
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    lda #' '
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    lda #('O'-64)
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0             
    lda #('K'-64)
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0

    lda #' '
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    lda #'('
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    lda #'$'
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    lda #'0'
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    
    tya
    clc
    adc #'0'
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           


    ; Show high nibble
    txa
    lsr
    lsr
    lsr
    lsr
    cmp #10
    bpl zp_stack_high_nibble_is_larger_than_or_equal_to_10
    clc
    adc #'0'
    jmp zp_stack_high_nibble_ready
zp_stack_high_nibble_is_larger_than_or_equal_to_10:
    sec
    sbc #9
zp_stack_high_nibble_ready:
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0
    
    ; Show low nibble
    txa
    and #$0f
    cmp #10
    bpl zp_stack_low_nibble_is_larger_than_or_equal_to_10
    clc
    adc #'0'
    jmp zp_stack_low_nibble_ready
zp_stack_low_nibble_is_larger_than_or_equal_to_10:
    sec
    sbc #9
zp_stack_low_nibble_ready:
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0
    
    lda #')'
    sta VERA_DATA0
    lda #$42                 ; Background color 4, foreground color 2
    sta VERA_DATA0           
    
    ; TODO: we should probably move on after this somehow. For now we are halting.
    
zp_stack_loop_ram_not_ok:
    jmp zp_stack_loop_ram_not_ok
    
zp_stack_ram_is_ok:
    lda #('O'-64)
    sta VERA_DATA0
    lda #$45                 ; Background color 4, foreground color 5 (green)
    sta VERA_DATA0             
    lda #('K'-64)
    sta VERA_DATA0
    lda #$45                 ; Background color 4, foreground color 5 (green)
    sta VERA_DATA0           
