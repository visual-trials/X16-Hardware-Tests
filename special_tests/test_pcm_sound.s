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
;    cpx #(>pcm_audio_data+16)                ; 16 * 256 bytes = 4kB
    cpx #(>pcm_audio_data+8)                ; 8 * 256 bytes = 2kB
    bne next_256_bytes
    
    ; Start PCM playback
    
    lda #116    ; 44250 Hz sample rate (roughly 44100 Hz)
;    lda #58 
;    lda #5
    sta VERA_AUDIO_RATE

;tmp_loop:
;    jmp tmp_loop

    ; We start at the point we ended with last time
;    ldx #(>pcm_audio_data+16)                ; 16 * 256 bytes = 4kB
    ldx #(>pcm_audio_data+8)                ; 8 * 256 bytes = 2kB
    stx AUDIO_COPY_ADDR+1
    ldy #0
    sty AUDIO_COPY_ADDR
    
keep_filling_fifo_buffer:
    lda VERA_AUDIO_CTRL
    bpl audio_buffer_is_not_full 
    
    lda #0
wait_for_a_while:
    inc
    bne wait_for_a_while
    
    bra keep_filling_fifo_buffer
    
audio_buffer_is_not_full:

    lda (AUDIO_COPY_ADDR),y
    sta VERA_AUDIO_DATA
    iny
    
    bne keep_filling_fifo_buffer        ; We assume our audio data ends in a chunk of 256 bytes (so we can safely move on here)

    ; Next 256 bytes of audio data
;    stp
    inx
    stx AUDIO_COPY_ADDR+1
    ; We check if we reached the end of the audio data
    cpx #(>pcm_audio_data+40)                ; 40 * 256 bytes = 10kB
    beq done_with_filling
    
    bra keep_filling_fifo_buffer
    
done_with_filling:
    
loop:
    jmp loop
  
    .org $C200
pcm_audio_data:  
    .binary "chirp_audio.signed.pcm"  ; This should be signed 16-bit little endian (raw) pcm (hint: Audacity can export this!)
    

    .org $fffc
    .word reset
    .word reset
  
  
  
