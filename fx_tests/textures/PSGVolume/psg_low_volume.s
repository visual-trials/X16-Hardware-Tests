; == Very crude PoC of a 128x128px tilemap rotation ==

; To build: cl65 -t cx16 -o PSGLOWVOL.PRG psg_low_volume.s
; To run: x16emu.exe -prg PSGLOWVOL.PRG -run

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; TODO: The following is *copied* from my x16.s (it should be included instead)

; -- some X16 constants --

VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_DATA1        = $9F24
VERA_CTRL         = $9F25

VERA_DC_VIDEO     = $9F29  ; DCSEL=0
VERA_DC_HSCALE    = $9F2A  ; DCSEL=0
VERA_DC_VSCALE    = $9F2B  ; DCSEL=0

VERA_L0_CONFIG    = $9F2D
VERA_L0_TILEBASE  = $9F2F



; === Zero page addresses ===


VOLUME             = $40


start:

    jsr test_psg
    
    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts




test_psg:

    
    
    ; TODO: this is still very crude PSG test, make it more comprehensive
    
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
    
    lda #0
    sta VOLUME
    lda #(%11000000) ; left and right speaker
    ora VOLUME       ; volume is 0/63 ~ 0%
    sta VERA_DATA0
    
    lda #(%10000000 | 32) ; triangle, duty cycle = 32/64 (25%?) 
    sta VERA_DATA0
    
    ; TODO: make a generic routine the "waits" for a while (whithout using interrupts)
    
;    jsr wait_a_second
    
keep_repeating:
    lda #10
    sta VOLUME
    jsr set_volume
    
    jsr wait_a_second
    
    lda #4
    sta VOLUME
    jsr set_volume
    
    jsr wait_a_second
    
    bra keep_repeating
    
    ; == Stopping the sound ==
    
    ; Setting $1F9CO as VRAM address (start of PSG registers)
    
    lda #%00010001     ; bit16 = 1, increment = 1
    sta VERA_ADDR_BANK
    
    lda #$F9
    sta VERA_ADDR_HIGH
    
    lda #$C0
    sta VERA_ADDR_LOW
    
    lda #0       
    sta VERA_DATA0  ; frequency low byte first set to 0
    sta VERA_DATA0  ; frequency high byte second set to 0
    sta VERA_DATA0  ; no left and right speaker, volume is 0
    sta VERA_DATA0  ; waveform and pulse width set to 0
    

    rts
    
    
wait_a_second:
    lda #8
    asl
make_psg_sound_64k:
    ldx #0
make_psg_sound_256:
    ldy #0
make_psg_sound_1:
    iny
    bne make_psg_sound_1
    inx
    bne make_psg_sound_256
    dec
    bne make_psg_sound_64k

    rts

set_volume:

    lda #%00010001     ; bit16 = 1, increment = 1
    sta VERA_ADDR_BANK
    
    lda #$F9
    sta VERA_ADDR_HIGH
    
    lda #$C0+2         ; +2 = volume byte
    sta VERA_ADDR_LOW

    lda #(%11000000) ; left and right speaker, 
    ora VOLUME       ; volume is VOLUME/63 
    sta VERA_DATA0
    
    rts

