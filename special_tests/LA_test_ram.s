; This is a single test for the Zero page and stack memory in the X16
; This memory spans from $0002 to $01FF 
; Note that addresses $0000 and $0001 are special addresses and should NOT be regarded as RAM here (and are -for now- skipped)

; Note: It has no output to VERA, it is meant for LA analysis

ram_block_0 = $0000
ram_block_1 = $0100

; This is currently used to trigger an LA
IO3_BASE_ADDRESS  = $9F60

    .org $C000

reset:
    ; Disable interrupts 
    sei

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
    sta IO3_BASE_ADDRESS
    
    lda #'N'
    jmp zp_stack_ram_is_not_ok
    
zp_stack_ram_is_ok:
    lda #'Y'
    jmp zp_stack_ram_is_ok

    .org $fffa
    .word reset
    .word reset
    .word reset
