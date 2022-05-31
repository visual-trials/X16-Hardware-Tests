
    .org $C000

reset:
    ; Disable interrupts 
    sei

    ; This will write #01 to $00 effectively writing a byte into the RAM BANK register (74273)
    lda #1
    sta $00

loop:
    jmp loop
    
    .org $fffa
    .word reset
    .word reset
    .word reset
