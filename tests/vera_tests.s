; Tests for checking functionality of VERA

vera_header: 
    .asciiz "VERA:"
testing_vram_message: 
; FIXME: extend this range!
    .asciiz "Testing VRAM ($00000 - $1F8FF) ... "
testing_vsync_irq_message: 
    .asciiz "Testing VSync interrupts ... "
testing_measure_cpu_speed_using_vsync_message: 
    .asciiz "Measuring CPU clock speed using VSync ... "
testing_measure_cpu_speed_using_pcm_message: 
    .asciiz "Measuring CPU clock speed using PCM buffer ... "
mhz_message:
    .asciiz "MHz"
too_high_message:
     .asciiz "too high"
too_low_message:
     .asciiz "too low"
no_buffer_fill_message:
     .asciiz "no buffer fill"
   
print_vera_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<vera_header
    sta TEXT_TO_PRINT
    lda #>vera_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
    
vram_not_ok_jmp:
    jmp vram_not_ok
    
test_vram:

    ; IMPORTANT: when trying to read and write to VERA, we should trigger a *reload* of the register that we want to *read*
    ;             this is because it sets the DATA value at the moment the *write* occurs ***BEFORE*** it was changed!!

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_vram_message
    sta TEXT_TO_PRINT
    lda #>testing_vram_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; Start with checking the first 64KB of VRAM
    
    jsr setup_vram_address_00000

    ldx #0
next_vram_block_FF:

    ldy #0
next_vram_byte_FF:
    lda #$FF
    sta VERA_DATA1           ; Write byte
    
    ; This will trigger a reload of VERA_DATA0!
    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda VERA_DATA0           ; Read byte
    cmp #$FF
    bne vram_not_ok_jmp
    
    iny
    bne next_vram_byte_FF
    inx
    bne next_vram_block_FF
    
    jsr setup_vram_address_00000
    
    ldx #0
next_vram_block_00:

    ldy #0
next_vram_byte_00:
    lda #$00
    sta VERA_DATA1           ; Write byte
    
    ; This will trigger a reload of VERA_DATA0!
    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda VERA_DATA0           ; Read byte
    cmp #$00
    bne vram_not_ok_jmp
    
    iny
    bne next_vram_byte_00
    inx
    bne next_vram_block_00
    
    jsr copy_tiles_and_map_to_low_vram

    lda #($0B0 >> 1)         ; Set mapbase for layer 0 to 0x0B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    
    lda #($0F0 >> 1)         ; Set tilebase for layer 0 to 0x0F000. This also sets the tile width and height to 8 px
    sta VERA_L0_TILEBASE
    
    jsr setup_vram_address_10000
    
    ldx #0
next_vram_block_high_FF:

    ldy #0
next_vram_byte_high_FF:
    lda #$FF
    sta VERA_DATA1           ; Write byte
    
    ; This will trigger a reload of VERA_DATA0!
    lda #%00010001           ; Setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda VERA_DATA0           ; Read byte
    cmp #$FF
    bne vram_not_ok_after_copy
    
    iny
    bne next_vram_byte_high_FF
    inx
    cpx #$F9
    bne next_vram_block_high_FF
    
    jsr setup_vram_address_10000
    
    ldx #0
next_vram_block_high_00:

    ldy #0
next_vram_byte_high_00:
    lda #$00
    sta VERA_DATA1           ; Write byte
    
    ; This will trigger a reload of VERA_DATA0!
    lda #%00010001           ; Setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda VERA_DATA0           ; Read byte
    cmp #$00
    bne vram_not_ok_after_copy
    
    iny
    bne next_vram_byte_high_00
    inx
    cpx #$F9
    bne next_vram_block_high_00
    
    ; FIXME: also check $1F900 - $1F9BF!!
    
    jsr copy_back_tiles_and_map_to_high_vram
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 0 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 0 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L0_TILEBASE

    ; -- Printing 'OK'
    
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jmp done_vram_test
    
vram_not_ok_after_copy:

    jsr copy_back_tiles_and_map_to_high_vram
    
vram_not_ok:
    lda #($1B0 >> 1)         ; Set mapbase for layer 0 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 0 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L0_TILEBASE
    
; FIXME: also add VRAM address!
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_vram_test:
    jsr move_cursor_to_next_line
    
    rts
    
    
copy_tiles_and_map_to_low_vram:

    ; Copying $1B000-$1F7FF -> $0B000-$0F7FF
    
    jsr setup_vram_address_copy
    
    ldx #$B0
next_vram_block_copy:

    ldy #0
next_vram_byte_copy:
    
    lda VERA_DATA1           ; Read byte
    sta VERA_DATA0           ; Write byte
    
    iny
    bne next_vram_byte_copy
    inx
    cpx #$F8
    bne next_vram_block_copy
    
    rts

copy_back_tiles_and_map_to_high_vram:

    ; Copying $0B000-$0F7FF -> $1B000-$1F7FF
    
    jsr setup_vram_address_copy
    
    ldx #$B0
next_vram_block_copy_back:

    ldy #0
next_vram_byte_copy_back:
    
    lda VERA_DATA0           ; Read byte
    sta VERA_DATA1           ; Write byte
    
    iny
    bne next_vram_byte_copy_back
    inx
    cpx #$F8
    bne next_vram_block_copy_back
    
    rts
    
    
setup_vram_address_00000:

    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL

    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW

    rts
    
setup_vram_address_10000:

    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL

    lda #%00010001           ; Setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010001           ; Setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW

    rts
    
setup_vram_address_copy:

    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL

    lda #%00010001           ; Setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0                 ; Start of tile map
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW

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
    
measure_cpu_speed_using_vsync:

    ; We are trying to determine the CPU clock speed based on VSync interrupts from VERA 

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_vsync_irq_message
    sta TEXT_TO_PRINT
    lda #>testing_vsync_irq_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; Copy irq default code to RAM

    ldx #0
copy_irq_cpu_speed_measurment_code:
    lda irq_cpu_speed_measurment, x
    sta IRQ_RAM_ADDRES, x
    inx 
    cpx #(end_of_irq_cpu_speed_measurment-irq_cpu_speed_measurment)
    bne copy_irq_cpu_speed_measurment_code

    ; We determine the CPU clock speed by measuring the amount of loops we can perform in 1 frame (using V-Sync)
    
    lda #0
    sta TIMING_COUNTER
    sta TIMING_COUNTER+1
    sta COUNTER_IS_RUNNING

    ; Enable interupts
    cli
    
    lda #%00000001  ; enable only v-sync irq
    sta VERA_IEN
    
    ; We wait for the V-SYNC interrupt to start the counter (COUNTER_IS_RUNNING: 0 -> 1)
waiting_to_start_counter_vsync:
    inc TIMING_COUNTER
    bne waiting_no_increment_vsync
    inc TIMING_COUNTER+1
    beq waiting_too_long_vsync
waiting_no_increment_vsync:
    lda COUNTER_IS_RUNNING
    beq waiting_to_start_counter_vsync

    lda #0
    sta TIMING_COUNTER
    sta TIMING_COUNTER+1
    
    ; We start counting until 1 frame has passed (COUNTER_IS_RUNNING: 1 -> 0)
increment_counter:
    inc TIMING_COUNTER
    bne no_increment
    inc TIMING_COUNTER+1
no_increment:
    lda COUNTER_IS_RUNNING
    bne increment_counter

    ; The interrupt turned off COUNTER_IS_RUNNING so the VSync interrupt worked
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr move_cursor_to_next_line

    ; At 8MHz the counter goes to 9580 ($256c) in one frame ~ 9600
    ; At 4Mhz ~ 4800
    ; At 2Mhz ~ 2400
    ; At 1Mhz ~ 1200
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #<testing_measure_cpu_speed_using_vsync_message
    sta TEXT_TO_PRINT
    lda #>testing_measure_cpu_speed_using_vsync_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; We use the high byte of the counter
    ldx TIMING_COUNTER+1
    
; FIXME: if out of bounds (either too low or too high) we should make this an ERROR!
    
    lda #8                    ; We start at 8 MHz
    cpx #$1C                  ; Value between 8 and 4 MHz: 7200 == $1C20 == $1C
    bcs cpu_speed_done_vsync  ; We got more counts so we are at 8MHz
    lda #4                    ; We assume 4 MHz now
    cpx #$0E                  ; Value between 4 and 2 MHz: 3600 == $0E10 == $0E
    bcs cpu_speed_done_vsync  ; We got more counts so we are at 4MHz
    lda #2                    ; We assume 2 MHz now
    cpx #$07                  ; Value between 2 and 1 MHz: 1800 == $0708 == $07
    bcs cpu_speed_done_vsync  ; We got more counts so we are at 2MHz
    lda #1                    ; We assume 1 MHz now
    cpx #$03                  ; Value between 1 and 0.5 MHz: 900 == $0384 == $03
    bcs cpu_speed_done_vsync  ; We got more counts so we are at 1MHz
    jmp cpu_speed_too_low_vsync

cpu_speed_done_vsync:
    sta ESTIMATED_CPU_SPEED_VSYNC
    
measured_ok_cpu_speed_vsync:
    ; We measure the CPU speed, so we are reporting it here
    jsr print_cpu_speed_vsync

    jmp done_measuring_cpu_speed_vsync

cpu_speed_too_low_vsync:

    ; We have a cpu speed that is too low
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<too_low_message
    sta TEXT_TO_PRINT
    lda #>too_low_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jmp done_measuring_cpu_speed_vsync
    
waiting_too_long_vsync:
    ; We waited for the interrupt to start the counter, but it took too long, Vsync interrupt must have failed
    lda #COLOR_ERROR
    sta TEXT_COLOR

    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
done_measuring_cpu_speed_vsync:

    jsr move_cursor_to_next_line
    ; Disable interrupts 
    sei
    
    rts

print_cpu_speed_vsync:
    cmp ESTIMATED_CPU_SPEED_PCM
    bne cpu_speeds_differ
    lda #COLOR_OK
    jmp color_cpu_speed_done
cpu_speeds_differ:
    lda #COLOR_ERROR
color_cpu_speed_done:
    sta TEXT_COLOR

    lda ESTIMATED_CPU_SPEED_VSYNC
    jsr print_byte_as_decimal        

    lda #<mhz_message
    sta TEXT_TO_PRINT
    lda #>mhz_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    rts
    
irq_cpu_speed_measurment:
    pha
    
    ; TODO: disable interrupts 
    
    ; TODO: we are not checking if VERA generated the IRQ (and if its a VSYNC interrupt). We should probably do that.
    lda COUNTER_IS_RUNNING
    beq start_counter
    ; The counter is running, we should stop it 
    lda #0
    sta COUNTER_IS_RUNNING
    
    beq end_of_interrupt  ; since a = 0 we always do this (TODO: use 'bra' instead)
start_counter:
    lda #1
    sta COUNTER_IS_RUNNING
end_of_interrupt:
    ; clear V-SYNC and LINE interrupt (just to be sure)
    lda #%00000011
    sta VERA_ISR
    
    ; TODO: enable interrupts 
    
    pla
    rti
end_of_irq_cpu_speed_measurment:
