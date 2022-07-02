VERA_ADDR_LOW     = $9F20

VERA_DC_VIDEO     = $9F29

VERA_AUDIO_CTRL   = $9F3B
VERA_AUDIO_RATE   = $9F3C
VERA_AUDIO_DATA   = $9F3D

AUDIO_COPY_ADDR   = $02 ; $03
    
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
    

    ; This is a very crude PCM test
    
    ;    lda #$8F    ; reset, 8 bit, mono + max volume
    ;    lda #$AF    ; reset, 16 bit, mono + max volume
    ;    lda #$9F    ; reset, 8 bit, stereo + max volume
    
    lda #$BF    ; reset, 16 bit, stereo + max volume
    sta VERA_AUDIO_CTRL
    lda #$00    ; zero sample rate 
    sta VERA_AUDIO_RATE
    
    ; Copy audio data to VERA FIFO buffer
    
    lda #<pcm_audio_data
    sta AUDIO_COPY_ADDR
    
    ldx #>pcm_audio_data
next_256_bytes:
    stx AUDIO_COPY_ADDR+1

    ldy #0
next_byte:
    lda (AUDIO_COPY_ADDR),y
    sta VERA_AUDIO_DATA
    iny
    bne next_byte
    
    inx
    cpx #(>pcm_audio_data+16)                ; 16 * 256 bytes = 4kB
    bne next_256_bytes
    
    ; Start PCM playback
    
    lda #116    ; 44250 Hz sample rate (roughly 44100 Hz)
    sta VERA_AUDIO_RATE
    
loop:
    jmp loop
  
    .org $C800
pcm_audio_data:  
    .binary "chirp_audio.pcm"
    

    .org $fffc
    .word reset
    .word reset
  
  
  
