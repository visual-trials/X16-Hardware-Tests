; Tests for checking functionality of VERA Audio

vera_audio_header: 
    .asciiz "VERA - Audio:"
testing_measure_cpu_speed_using_pcm_message: 
    .asciiz "Measuring CPU clock speed using PCM buffer ... "
testing_psg_message: 
    .asciiz "Testing Programmable Sound Generator (PSG) ... "
no_buffer_fill_message:
     .asciiz "no buffer fill"
listen_message:
     .asciiz "Heard a beep?"
   
print_vera_audio_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<vera_audio_header
    sta TEXT_TO_PRINT
    lda #>vera_audio_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
        
measure_cpu_speed_using_pcm:

    ; We are trying to determine the CPU clock speed based on the rate of emptying of the PCM FIFO buffer (using VERA)
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_measure_cpu_speed_using_pcm_message
    sta TEXT_TO_PRINT
    lda #>testing_measure_cpu_speed_using_pcm_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; Just to be sure, we set the CPU speed to 5MHz: just an odd number, be make it distinct from the real/measured numbers 
    ;   Nore: its used later on to compare with other CPU speed measurements and for making delays/waits take (roughly) the same amount of time
    lda #5
    sta ESTIMATED_CPU_SPEED_PCM
    
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
    
    lda VERA_AUDIO_CTRL
    bpl audio_buffer_is_not_full ; If bit 7 is not set the audio FIFO buffer is not full. We didnt expect that, since we just filled it while PCM should have stopped sampling.
    
    ; The buffer is full. We will now start "playback" by setting a sampling rate. We then do a fixed amount of CPU cycles, stop the sampling and look how much was played (emptied out of the buffer)
    
    ; -- Start playback
    lda #67 ; Slightly more than 64 (=24414 Hz). Using 24414Hz it would play exactly 256 bytes at 8MHz. We want a little more bytes played back (so we can round down and use the high byte of the counter) so we set it a little faster.
    sta VERA_AUDIO_RATE
    
    ; We loop 64*256 times
    ldy #64
wait_block_during_pcm_playback:
    ldx #0
wait_single_during_pcm_playback:
    inx
    bne wait_single_during_pcm_playback
    dey
    bne wait_block_during_pcm_playback
    
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
    
    ldx TIMING_COUNTER+1
    
    ; Approx expected values of counter:
    ; $0100 : 8MHz
    ; $0200 : 4MHz
    ; $0400 : 2MHz
    ; $0800 : 1MHz
    
    lda #1                  ; We start at 1 MHz
    cpx #8                  ; 8 * 256 bytes played (full buffer) -> 1MHz
    bcs cpu_speed_done_pcm  ; We got more or equal counts so we are at 1MHz
    lda #2                  ; We assume 2 MHz now
    cpx #4                  ; 4 * 256 bytes played (half of a buffer) -> 2MHz
    bcs cpu_speed_done_pcm  ; We got more or equal counts so we are at 2MHz
    lda #4                  ; We assume 4 MHz now
    cpx #2                  ; 2 * 256 bytes played (quarter of a buffer) -> 4MHz
    bcs cpu_speed_done_pcm  ; We got more or equal counts so we are at 4MHz
    lda #8                  ; We assume 8 MHz now
    cpx #1                  ; 1 * 256 bytes played (an eighth of a buffer) -> 8MHz
    bcs cpu_speed_done_pcm  ; We got more or equal counts so we are at 4MHz
    jmp cpu_speed_too_high_pcm
    
cpu_speed_done_pcm:
    sta ESTIMATED_CPU_SPEED_PCM
    
measured_ok_cpu_speed_pcm:
    ; We measure the CPU speed, so we are reporting it here
    lda #COLOR_OK
    sta TEXT_COLOR

    lda ESTIMATED_CPU_SPEED_PCM
    jsr print_byte_as_decimal        

    lda #<mhz_message
    sta TEXT_TO_PRINT
    lda #>mhz_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jmp done_measuring_cpu_speed_pcm

cpu_speed_too_high_pcm:

    ; We filled the buffer with 4KB of data but the PCM buffer was not full
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<too_high_message
    sta TEXT_TO_PRINT
    lda #>too_high_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jmp done_measuring_cpu_speed_pcm
    
audio_buffer_is_not_full:

    ; We filled the buffer with 4KB of data but the PCM buffer was not full
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<no_buffer_fill_message
    sta TEXT_TO_PRINT
    lda #>no_buffer_fill_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_measuring_cpu_speed_pcm:
    jsr move_cursor_to_next_line
    
    rts

    
test_psg:

    ; This will make a sound using the PSG of VERA. There is no way to check whether its making any sound though so we wont have a real result from this test.
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_psg_message
    sta TEXT_TO_PRINT
    lda #>testing_psg_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    
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
    
    lda #(%11000000 | 63) ; left and right speaker, volume is 63/63 ~ 100%
    sta VERA_DATA0
    
    lda #(%10000000 | 32) ; triangle, duty cycle = 32/64 (25%?) 
    sta VERA_DATA0
    
    ; TODO: make a generic routine the "waits" for a while (whithout using interrupts)
    
    ; We wait for a around a second (depending on the CPU speed, so the sound can be heard by a human being
    
    lda ESTIMATED_CPU_SPEED_PCM
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
    
    ; Printing "result" : a human being has to listen to the sound, so this is neither an error nor an ok
    
    lda #COLOR_UNKNOWN
    sta TEXT_COLOR
    
    lda #<listen_message
    sta TEXT_TO_PRINT
    lda #>listen_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jsr move_cursor_to_next_line

    rts
