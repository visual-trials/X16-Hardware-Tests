VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_CTRL         = $9F25

VERA_DC_VIDEO     = $9F29

    .org $C000

reset:
    ; Disable interrupts 
    sei
    
wait_for_vera:
    lda #42
    sta VERA_ADDR_LOW

    lda VERA_ADDR_LOW
    cmp #42
    bne wait_for_vera
    

    lda #%00010001 ; Enable Layer 0, Enable VGA (just to show we are running)
    sta VERA_DC_VIDEO
    

    ; This is a very crude PSG test
    
    lda #0
    sta VERA_CTRL
    
    ; Setting $1F9CO as VRAM address (start of PSG registers)
    
    lda #%00010001     ; bit16 = 1, increment = 1
    sta VERA_ADDR_BANK
    
    lda #$F9
    sta VERA_ADDR_HIGH
    
    lda #$C0
    sta VERA_ADDR_LOW
    
    ; 1kHz = $0A7C
    lda #$7C       ; frequency low byte first
    sta VERA_DATA0
    
    lda #$0A       ; frequency high byte second
    sta VERA_DATA0
    
    lda #(%11000000 | 63) ; left and right speaker, volume is 63/63 ~ 100%
    sta VERA_DATA0
    
    lda #(%10000000 | 32) ; triangle, duty cycle = 32/64 (25%?) 
    sta VERA_DATA0
    
loop:
    jmp loop
  

    .org $fffc
    .word reset
    .word reset
  
  
  
