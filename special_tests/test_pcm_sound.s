VERA_ADDR_LOW     = $9F20

VERA_DC_VIDEO     = $9F29

VERA_AUDIO_CTRL   = $9F3B
VERA_AUDIO_RATE   = $9F3C
VERA_AUDIO_DATA   = $9F3D

RAM_BANK          = $00
ROM_BANK          = $01

AUDIO_COPY_ADDR   = $02 ; $03
PLAYING_BANK      = $04

RANDOM_SEED       = $05

PLAY_PCM_CODE  = $4000
PCM_AUDIO_DATA = $C000   ; BANK 1+
    
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
    
    ; Copying play_pcm_audio -> PLAY_PCM_CODE
    
    ldy #0
copy_play_pcm_audio_code:
    lda play_pcm_audio, y
    sta PLAY_PCM_CODE, y
    iny 
    cpy #(end_of_play_pcm_audio-play_pcm_audio)
    bne copy_play_pcm_audio_code

    lda #$CD
    sta RANDOM_SEED
    
loop:
    jsr PLAY_PCM_CODE
    jsr wait_random_time
    jmp loop
  
  
wait_random_time:
    lda RANDOM_SEED
    
wait_random_64k:
    ldx #128
wait_random_256:
    ldy #0
wait_random_1:
    iny
    bne wait_random_1
    dex
    bne wait_random_256
    dec
    bne wait_random_64k
    
    jsr pseudo_random_byte
    
    rts
    
; Taken from here: https://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
pseudo_random_byte:
    lda RANDOM_SEED
    beq doEor
    asl
    beq noEor ;if the input was $80, skip the EOR
    bcc noEor
doEor:
    eor #$1d
noEor:
    sta RANDOM_SEED

    rts
    
; Note: this routine is COPIED to RAM and run there!    
play_pcm_audio:
    lda #1
    sta PLAYING_BANK

    ; Switching ROM BANK
    lda PLAYING_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    ; This is a very crude PCM test
    
    lda #$BF    ; reset, 16 bit, stereo + max volume
    sta VERA_AUDIO_CTRL
    lda #$00    ; zero sample rate 
    sta VERA_AUDIO_RATE
    
    ; Copy audio data to VERA FIFO buffer
    
    lda #<PCM_AUDIO_DATA
    sta AUDIO_COPY_ADDR
    
    ldx #>PCM_AUDIO_DATA
next_256_bytes:
    stx AUDIO_COPY_ADDR+1

    ldy #0
next_byte:
    lda (AUDIO_COPY_ADDR),y
    sta VERA_AUDIO_DATA
    iny
    bne next_byte
    
    inx
;    cpx #(>PCM_AUDIO_DATA+16)                ; 16 * 256 bytes = 4kB
    cpx #(>PCM_AUDIO_DATA+8)                ; 8 * 256 bytes = 2kB
    bne next_256_bytes
    
    ; Start PCM playback
    
    lda #116    ; 44250 Hz sample rate (roughly 44100 Hz)
    sta VERA_AUDIO_RATE

    ; We start at the point we ended with last time
;    ldx #(>PCM_AUDIO_DATA+16)                ; 16 * 256 bytes = 4kB
    ldx #(>PCM_AUDIO_DATA+8)                ; 8 * 256 bytes = 2kB
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
    inx
    stx AUDIO_COPY_ADDR+1
    ; We check if we reached the end of the ROM BANK
    beq next_rom_bank
    
    bra keep_filling_fifo_buffer
    
next_rom_bank:
    ; Incerement BANK
    inc PLAYING_BANK
    
    ldx #>PCM_AUDIO_DATA
    stx AUDIO_COPY_ADDR+1
    
    ; Note that y should already be 0 here
    
    ; Switching ROM BANK (if end is not reached)
    lda PLAYING_BANK
    cmp #32                 ; we only play 31 banks
    beq done_with_filling

    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    bra keep_filling_fifo_buffer
    
done_with_filling:

    ; Switching back to ROM bank 0
    lda #0
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    rts
end_of_play_pcm_audio:
    
    
    .org $fffc
    .word reset
    .word reset
  
    .binary "chirp_audio.signed.pcm"  ; This should be signed 16-bit little endian (raw) pcm (hint: Audacity can export this!)
    

  
  
