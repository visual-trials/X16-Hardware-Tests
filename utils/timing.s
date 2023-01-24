    
init_timer:
    ; We reset the FIFO and configure it
    lda #%10000000  ; FIFO Reset, 8-bit, Mono, no volume
    sta VERA_AUDIO_CTRL
    
    ; We set the PCM sample rate to 0 (no sampling)
    lda #$00
    sta VERA_AUDIO_RATE
    
    ; We fill the PCM buffer with 4KB (= 16 * 256 bytes) of data

    lda #$00  ; It really doesn't matter where we fill it with
    ldy #16
fill_pcm_audio_block_with_ff:
    ldx #0
fill_pcm_audio_byte_with_ff:
    sta VERA_AUDIO_DATA
    inx
    bne fill_pcm_audio_byte_with_ff
    dey
    bne fill_pcm_audio_block_with_ff
    
    ; NOTE: we are assuming the buffer is full now
    
    rts
    
start_timer:
    
    ; NOTE: The buffer is asumed to be full and playback not running. 
    
    ; We will now start "playback" by setting a sampling rate. 
    
    ; -- Start playback
    ; Formula: frequency = 48828.125/(128/VERA_AUDIO_RATE)
    ; lda #26   ;  9918.2 Hz (fairly close to 10000Hz) 
    ; lda #27   ; 10299.7 Hz (fairly close to 10000Hz) 
    lda #42   ; 16021.7 Hz (fairly close to 16000Hz) -> divide by 16 and you get the milliseconds
    sta VERA_AUDIO_RATE

timer_is_not_yet_running:
    lda VERA_AUDIO_CTRL
    bmi timer_is_not_yet_running ; If bit 7 is set the audio FIFO buffer is still full. So we wait
    
    rts
    
    
stop_timer:
    ; -- Stop playback
    lda #$00
    sta VERA_AUDIO_RATE
    
    ; We fill the PCM buffer again, but now we keep checking if its full: that we know how many bytes it sampled/played
    lda #0
    sta TIMING_COUNTER
    sta TIMING_COUNTER+1
    
    lda #0 ; It really doesn't matter where we fill it with
fill_pcm_audio_byte:
    sta VERA_AUDIO_DATA
    inc TIMING_COUNTER
    bne no_increment_counter_pcm
    inc TIMING_COUNTER+1    
no_increment_counter_pcm:
    lda VERA_AUDIO_CTRL
    bpl fill_pcm_audio_byte ; If bit 7 is not set the audio FIFO buffer is not full. So we repeat
    
    lda TIMING_COUNTER
    and #$0F
    sta TIME_ELAPSED_SUB_MS
    
    lda TIMING_COUNTER
    lsr
    lsr
    lsr
    lsr
    sta TIME_ELAPSED_MS
    
    ; We assume we ran at 16000Hz, so we divide by 16 and the remaining byte is the number of milliseconds elapsed
    lda TIMING_COUNTER+1
    and #$0F
    asl
    asl
    asl
    asl
    ora TIME_ELAPSED_MS
    sta TIME_ELAPSED_MS
    
    rts

print_time_elapsed:

    lda #<time_elapsed_message
    sta TEXT_TO_PRINT
    lda #>time_elapsed_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    lda TIME_ELAPSED_MS
    sta BYTE_TO_PRINT
    jsr print_byte_as_decimal
    
    lda #'.'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda TIME_ELAPSED_SUB_MS
    tax
    lda sub_ms_nibble_as_decimal, x
    sta BYTE_TO_PRINT
    jsr print_byte_as_decimal
    
    lda #<time_elapsed_ms_message
    sta TEXT_TO_PRINT
    lda #>time_elapsed_ms_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr move_cursor_to_next_line
    
    rts

time_elapsed_message: 
    .asciiz "Elapsed time... "
time_elapsed_ms_message: 
    .asciiz " ms  "
    
sub_ms_nibble_as_decimal:
    .byte 00 ; 0/16 = 0.0
    .byte 10 ; 1/16 = 0.0625  --> FIXME: this will show up as .6!! (we have no leading zeros) -> so made this 10 for now
    .byte 13 ; 2/16 = 0.125
    .byte 19 ; 3/16 = 0.1865

    .byte 25 ; 4/16 = 0.25
    .byte 31 ; 5/16 = 0.3125
    .byte 38 ; 6/16 = 0.375
    .byte 44 ; 7/16 = 0.4375

    .byte 50 ; 8/16 = 0.5
    .byte 56 ; 9/16 = 0.5625
    .byte 63 ; 10/16 = 0.625
    .byte 69 ; 11/16 = 0.6875

    .byte 75 ; 12/16 = 0.75
    .byte 81 ; 13/16 = 0.8125
    .byte 88 ; 14/16 = 0.875
    .byte 94 ; 15/16 = 0.9375

