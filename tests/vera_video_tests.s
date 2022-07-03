; Tests for checking functionality of VERA Video

vera_video_header: 
    .asciiz "VERA - Video:"
testing_vram_message: 
    .asciiz "Testing VRAM ($00000 - $1F9BF) ... "
testing_vsync_irq_message: 
    .asciiz "Testing VSync interrupts ... "
testing_measure_cpu_speed_using_vsync_message: 
    .asciiz "Measuring CPU clock speed using VSync ... "
   
print_vera_video_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<vera_video_header
    sta TEXT_TO_PRINT
    lda #>vera_video_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
    
lower_vram_not_ok_jmp:
    jmp lower_vram_not_ok
    
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
    bne lower_vram_not_ok_jmp
    
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
    bne lower_vram_not_ok_jmp
    
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
    bne upper_vram_not_ok
    
    cpx #$F9
    bne next_y_FF
    
    ; When we are at $1F9xx we should check the lower part of the VRAM address too, since we go until $1F9BF
    
    iny
    cpy #$C0
    bne next_vram_byte_high_FF
    bra next_x_FF
    
next_y_FF:    
    iny
    bne next_vram_byte_high_FF
next_x_FF:
    inx
    cpx #$FA  ; TODO: we never reach this point, might as well remove this check
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
    bne upper_vram_not_ok
    
    cpx #$F9
    bne next_y_00
    
    ; When we are at $1F9xx we should check the lower part of the VRAM address too, since we go until $1F9BF
    
    iny
    cpy #$C0
    bne next_vram_byte_high_00
    bra next_x_00
    
next_y_00    
    iny
    bne next_vram_byte_high_00
next_x_00:
    inx
    cpx #$FA   ; TODO: we never reach this point, might as well remove this check
    bne next_vram_block_high_00

    
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
    
upper_vram_not_ok:
    ; We preserve the bad value into a ZP register
    sta BAD_VALUE

    ; We want to keep x and y, so we put them on the stack
    txa
    pha
    tya
    pha
    
    ; Since we were testing the upper vram, we must have copied our tiles and map, so we need to restore that first
    jsr copy_back_tiles_and_map_to_high_vram
    
    pla
    tay
    pla
    tax
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 0 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 0 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L0_TILEBASE
    
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; This uses x as high byte and y as low byte of the address to print    
    jsr print_upper_vram_address
    
    jmp done_vram_test

lower_vram_not_ok:
    ; We preserve the bad value into a ZP register
    sta BAD_VALUE
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 0 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L0_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 0 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L0_TILEBASE
    
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<not_ok_message
    sta TEXT_TO_PRINT
    lda #>not_ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; This uses x as high byte and y as low byte of the address to print    
    jsr print_lower_vram_address
    
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

    lda #%00000111 ; ACK any existing IRQs in VERA
    sta VERA_ISR
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
