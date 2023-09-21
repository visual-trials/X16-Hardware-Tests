; == Very crude PoC of 320x136px video playback using AUTOTX ==

; To build: ./vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\textures\StarWars\walker.s -wdc02 -D CREATE_PRG -o .\fx_tests\textures\StarWars\WALKER.PRG
; To run (from StarWars dir) : C:\x16emu_win-r44\x16emu.exe -prg .\WALKER.PRG -run -sdcard .\walker_sdcard.img

; FIXME: REMOVE THIS!
IS_EMULATOR = 1
DO_PRINT = 0
DO_BORDER_COLOR = 1
DO_MULTI_SECTOR_READS = 0

BACKGROUND_COLOR = $00 ; black

TOP_MARGIN = 2
LEFT_MARGIN = 0
VSPACING = 10


; === Zero page addresses ===

; Bank switching
RAM_BANK                  = $00
ROM_BANK                  = $01

; Temp vars
TMP1                      = $02
TMP2                      = $03
TMP3                      = $04
TMP4                      = $05

; FIXME: these are leftovers of memory tests in the general hardware tester (needed by utils.s atm). We dont use them, but cant remove them right now
BANK_TESTING              = $06   
BAD_VALUE                 = $07

; Printing
TEXT_TO_PRINT             = $07 ; 08
TEXT_COLOR                = $09
CURSOR_X                  = $0A
CURSOR_Y                  = $0B
INDENTATION               = $0C
BYTE_TO_PRINT             = $0D
DECIMAL_STRING            = $0E ; 0F ; 10

SD_DUMP_ADDR              = $1C ; 1D
SD_USE_AUTOTX             = $1E

LOAD_ADDRESS              = $30 ; 31
CODE_ADDRESS              = $32 ; 33

VERA_ADDR_ZP_TO           = $34 ; 35 ; 36
PALETTE_CHANGE_ADDRESS    = $37 ; 38
NR_OF_COLORS_TO_CHANGE    = $39

SECTOR_NUMBER             = $47 ; 48 ; 49 ; 4A
SECTOR_NUMBER_IN_FRAME    = $4B

FRAME_NUMBER              = $4C ; 4D

BORDER_COLOR              = $4E
COMMAND18_INITIATED       = $4F


; === RAM addresses ===

COPY_SECTOR_CODE               = $9000  ; (3 + 3) * 512 = 3kB + rts ~ $0C01

; FIXME: we are NOT USING THESE! (but they are required for vera_sd_tests.s)
MBR_L          = $8000
MBR_H          = $8100
MBR_SLOW_L     = $8200
MBR_SLOW_H     = $8300
MBR_FAST_L     = $8400
MBR_FAST_H     = $8500


; === Other constants ===

NR_OF_SECTORS_TO_COPY = 136*320 / 512 ; Note (320x136 resolution): 136 * 320 = 170 * 256 = 85 * 512 bytes (1 sector = 512 bytes)
NUMBER_OF_FRAMES = 968
;NUMBER_OF_FRAMES = 157


    .include utils/build_as_prg_or_rom.s

start:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs

    lda #0
    sta INDENTATION
    sta CURSOR_X
    sta CURSOR_Y


    jsr setup_vera_for_bitmap_and_tile_map
    jsr setup_screen_borders
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor

    ; FIXME: we should do a CLEAR SCREEN here!

    jsr generate_copy_sector_code


    .if(!DO_PRINT)
        lda VERA_DC_VIDEO
        ; ora #%00010000           ; Enable Layer 0 
        and #%10011111           ; Disable Layer 1 and sprites
        sta VERA_DC_VIDEO
    .endif
    
    .if(DO_BORDER_COLOR)
        lda BORDER_COLOR
        sta VERA_DC_BORDER
    .endif

    ; === VERA SD ===
    jsr print_vera_sd_header
    
    ; Try to detect/reset the SD card
    jsr vera_reset_sd_card
    bcc done_with_sd_checks   ; If card was not detected (or there was some error) we do not proceed with SD Card tests
    
    ; Check if card is SDC Ver.2+
    jsr vera_check_sdc_version
    bcc done_with_sd_checks   ; If card was SDC Ver.2+ we do not proceed with SD Card tests
    
    ; Initialize SD card
    jsr vera_initialize_sd_card
    bcc done_with_sd_checks   ; If card was not propely initialized we do not proceed with SD Card tests
    
    jsr vera_check_block_addressing_mode
    bcc done_with_sd_checks   ; If card does not support block addrssing mode so we do not proceed with SD Card tests
 
    .if(DO_MULTI_SECTOR_READS)
        stz COMMAND18_INITIATED
    .endif

start_movie:
 
    jsr copy_palette_from_index_1

    ; We start at the beginning of the palette changes (first change is AFTER frame 0)
    lda #<palette_changes_per_frame
    sta PALETTE_CHANGE_ADDRESS
    lda #>palette_changes_per_frame
    sta PALETTE_CHANGE_ADDRESS+1

; FIXME: we are currently not resetting COMMAND18_INITIATED here! (see above)
;     .if(DO_MULTI_SECTOR_READS)
;        stz COMMAND18_INITIATED
;    .endif

     stz SECTOR_NUMBER
     stz SECTOR_NUMBER+1
     stz SECTOR_NUMBER+2
     stz SECTOR_NUMBER+3

; FIXME! 
; FIXME! 
; FIXME! 
    lda #1
;    lda #0
    sta SD_USE_AUTOTX
	lda #SPI_CHIP_SELECT_AND_FAST
	sta VERA_SPI_CTRL
    
    lda #<NUMBER_OF_FRAMES
    sta FRAME_NUMBER
    lda #>NUMBER_OF_FRAMES
    sta FRAME_NUMBER+1
    
next_frame:

    jsr load_and_draw_frame
    
    jsr do_palette_changes
    
; FIXME: we need to be able to do more than 256 frames!
    dec FRAME_NUMBER
    bne next_frame
    dec FRAME_NUMBER+1
    bne next_frame
    
    jmp start_movie
    

done_with_sd_checks:

    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts
    
    
setup_screen_borders:

    ; Setting VSTART/VSTOP so that we have 200 rows on screen (320x200 pixels on screen)

    lda #%00000010  ; DCSEL=1
    sta VERA_CTRL
   
    lda #52
    sta VERA_DC_VSTART
    lda #136+52-1
    sta VERA_DC_VSTOP
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
copy_palette_from_index_1:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 1 of the palette
    lda #<(VERA_PALETTE+2*1)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE+2*1)
    sta VERA_ADDR_HIGH

    ; HACK: we know we have more than 128 colors to copy (meaning: > 256 bytes), so we are just going to copy 128 colors first
    
    ldy #0
next_packed_color_256:
    lda palette_data, y
    sta VERA_DATA0
    iny
    bne next_packed_color_256

    ldy #0
next_packed_color_1:
    lda palette_data+256, y
    sta VERA_DATA0
    iny
    cpy #<(end_of_palette_data-palette_data)
    bne next_packed_color_1
    
    rts


do_palette_changes:

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ldy #0
    lda (PALETTE_CHANGE_ADDRESS),y
    iny
    sta NR_OF_COLORS_TO_CHANGE
    lda NR_OF_COLORS_TO_CHANGE  ; FIXME: SPEED: we lda, sta and lda again! (just so Z is correct and y is incremented)
    beq done_with_changing_colors  ; if there are 0 colors to change we are done

next_palette_color_change:
    ; Load palette index of the color
    lda (PALETTE_CHANGE_ADDRESS),y
    iny
    
    asl a
    sta TMP2
    bcs change_high_palette_color

change_low_palette_color:

    clc
    lda #<(VERA_PALETTE)
    adc TMP2
    sta VERA_ADDR_LOW
    ; FIXME: the carry is never 1 here, right? So this adc is not needed! (the lda+sta is)
    lda #>(VERA_PALETTE)
    adc #0
    sta VERA_ADDR_HIGH
    ; Note: since the entire palette is in high VRAM we dont need to set the highest byte here

    lda (PALETTE_CHANGE_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (PALETTE_CHANGE_ADDRESS),y
    sta VERA_DATA0
    iny
    
    bra changed_palette_color

change_high_palette_color:

    clc
    lda #<(VERA_PALETTE+256)
    adc TMP2
    sta VERA_ADDR_LOW
    ; FIXME: the carry is never 1 here, right? So this adc is not needed! (the lda+sta is)
    lda #>(VERA_PALETTE+256)
    adc #0
    sta VERA_ADDR_HIGH
    ; Note: since the entire palette is in high VRAM we dont need to set the highest byte here

    lda (PALETTE_CHANGE_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (PALETTE_CHANGE_ADDRESS),y
    sta VERA_DATA0
    iny

changed_palette_color:

    ; FIXME: HACK! If y > 128 we increment PALETTE_CHANGE_ADDRESS by 128 and decrement y by 128!
    tya
    bpl y_is_below_128
    
    sec
    sbc #128
    tay
    
    clc
    lda PALETTE_CHANGE_ADDRESS
    adc #128
    sta PALETTE_CHANGE_ADDRESS
    lda PALETTE_CHANGE_ADDRESS+1
    adc #0
    sta PALETTE_CHANGE_ADDRESS+1

y_is_below_128:
    dec NR_OF_COLORS_TO_CHANGE
    bne next_palette_color_change
done_with_changing_colors:

    ; We add y to the PALETTE_CHANGE_ADDRESS (since it contains the number of bytes we just comsumed)
    sty TMP1 
    
    ; FIXME: we are assuming that the number of bytes for ONE frame never exceeds 255 bytes!
    clc
    lda PALETTE_CHANGE_ADDRESS
    adc TMP1
    sta PALETTE_CHANGE_ADDRESS
    lda PALETTE_CHANGE_ADDRESS+1
    adc #0
    sta PALETTE_CHANGE_ADDRESS+1

    rts






walker_spi_send_command17: ; or command 18

    ; The command index requires the highest bit to be 0 and the bit after that to be 1 = $40
    .if(DO_MULTI_SECTOR_READS)
        lda #(18 | $40)      
    .else
        lda #(17 | $40)      
    .endif
    jsr spi_write_byte
    
    ; Command 17 (or 18) has four bytes of argument, so sending four bytes with their as argument
    
    lda SECTOR_NUMBER+3
    jsr spi_write_byte
    lda SECTOR_NUMBER+2
    jsr spi_write_byte
    lda SECTOR_NUMBER+1
    jsr spi_write_byte
    lda SECTOR_NUMBER
    jsr spi_write_byte
    
    ; Command 17 (or 18) requires no CRC. So we send 0
    lda #0
    jsr spi_write_byte


    ; We wait for a response (which should be R1 + data bytes)
    ldx #20                   ; TODO: how many retries do we want to do?
walker_spi_wait_command17: ; or command 18
    dex
    beq walker_spi_command17_timeout ; or command 18
    jsr spi_read_byte
    tay                       ; we want to keep the original value (so we put it in y for now)
    ; FIXME: Use 65C02 processor so we can use "bit #$80" here
    and #$80
    cmp #$80
    beq walker_spi_wait_command17 ; or command 18
    
    tya                       ; we restore the original value (stored in y)
    
    sec  ; set the carry: we succeeded
    rts

walker_spi_command17_timeout: ; or command 18
    clc  ; clear the carry: we did not succeed
    rts



walker_vera_read_sector:

    .if(DO_MULTI_SECTOR_READS)
        lda COMMAND18_INITIATED
        bne walker_start_reading_data_packet
    .endif
    
    ; We send command 17 to read single sector (or command 18 to read multiple sectors)
    jsr walker_spi_send_command17  ; or command 18
    
    bcs walker_command17_success ; or command 18
walker_command17_timed_out:  ; or command18

    ; TODO: is it correct that we do not set COMMAND18_INITIATED to 1 here?
    
    .if(DO_PRINT)
        ; If carry is unset, we timed out. We print 'Timeout' as an error
        lda #COLOR_ERROR
        sta TEXT_COLOR
        
        lda #<vera_sd_timeout_message
        sta TEXT_TO_PRINT
        lda #>vera_sd_timeout_message
        sta TEXT_TO_PRINT + 1
        
        jsr print_text_zero
    .endif

    jmp walker_done_reading_sector_do_not_proceed
    
walker_command17_success: ; or command 18

    ; We got our byte of response. We check if the SD Card is not in an IDLE state (which is expected)
    cmp #%0000000   ; NOT in IDLE state! (we initialized earlier, so we should NOT be in IDLE state anymore!)
    beq walker_command17_not_in_idle_state

walker_command17_in_idle_state: ; or command 18

    ; TODO: is it correct that we do not set COMMAND18_INITIATED to 1 here?
    
    .if(DO_PRINT)
        ; The reponse says we are in an IDLE state, which means there is an error
        .if(DO_MULTI_SECTOR_READS)
            ldx #18 ; command number to print
        .else
            ldx #17 ; command number to print
        .endif
        jsr print_spi_cmd_error
    .endif
    
    jmp walker_done_reading_sector_do_not_proceed
    
walker_command17_not_in_idle_state: ; or command 18
    
    .if(DO_MULTI_SECTOR_READS)
        lda #1
        sta COMMAND18_INITIATED
    .endif

walker_start_reading_data_packet:

    ; Wait for start of data packet
    ldx #0
walker_wait_for_data_packet_start_256:
    ldy #0
walker_wait_for_data_packet_start_1:
    jsr spi_read_byte
    cmp #%11111110    ; Data token for CMD17
    beq walker_start_reading_sector_data
    dey
    bne walker_wait_for_data_packet_start_1
    .if(DO_BORDER_COLOR)
        inc BORDER_COLOR
        lda BORDER_COLOR
        sta VERA_DC_BORDER
    .endif
    dex
    bne walker_wait_for_data_packet_start_256
    
    jmp walker_wait_for_data_packet_start_timeout
    
walker_start_reading_sector_data:

    ; Retrieve the additional 512 bytes 
    
    lda SD_USE_AUTOTX
    bne walker_read_autotx_read_sector
    
    
walker_read_slow_read_sector:
    ldx #0
walker_reading_sector_byte_L:
    jsr spi_read_byte
    sta VERA_DATA0
    inx
    bne walker_reading_sector_byte_L
    
    ldx #0
walker_reading_sector_byte_H:
    jsr spi_read_byte
    sta VERA_DATA0
    inx
    bne walker_reading_sector_byte_H
    
    ; Read the 2 CRC bytes
    jsr spi_read_byte
    jsr spi_read_byte_measure ; We are measuring the speed of this last read
    
    jmp walker_read_sector_check_mbr
    
walker_read_autotx_read_sector:

    lda VERA_SPI_CTRL
; FIXME: EMULATOR BIT!!
    .if(IS_EMULATOR)
        ora #%00001000       ; AUTOTX bit = 1
    .else
        ora #%00000100       ; AUTOTX bit = 1
    .endif
    sta VERA_SPI_CTRL
    
    
    ; This loads and draws 512 bytes from SD card to VRAM
    
    ; Start first read transfer
    lda VERA_SPI_DATA    ; Auto-tx
    ldy #0                ; 2

    .if(1)
        jsr COPY_SECTOR_CODE
    .else
    
    ; Efficiently read first 256 bytes (hide SPI transfer time)
    ldy #0                ; 2
walker_reading_sector_8_bytes_L:
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    tya                ; 2
    clc                ; 2
    adc #8                ; 2
    tay                ; 2
    bne walker_reading_sector_8_bytes_L  ; 2+1

    ; Efficiently read second 256 bytes (hide SPI transfer time)
walker_reading_sector_8_bytes_H:
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    lda VERA_SPI_DATA            ; 4
    sta VERA_DATA0               ; 4
    tya                ; 2
    clc                ; 2
    adc #8                ; 2
    tay                ; 2
    bne walker_reading_sector_8_bytes_H  ; 2+1
    
    .endif

    ; Disable auto-tx mode
    lda VERA_SPI_CTRL
; FIXME: EMULATOR BIT!!
    .if(IS_EMULATOR)
        and #%11110111     ; AUTOTX bit = 1
    .else
        and #%11111011     ; AUTOTX bit = 1
    .endif
    sta VERA_SPI_CTRL

    ; Next read is now already done (first CRC byte), read second CRC byte
    jsr spi_read_byte
    jsr spi_read_byte_measure ; We are measuring the speed of this last read


walker_read_sector_check_mbr:
    
; FIXME: REMOVE!
    .if(0)
        ; The last two bytes of the MBR should always be $55AA
        lda MBR_H+254
        cmp #$55
        bne walker_mbr_malformed
        
        lda MBR_H+255
        cmp #$AA
        bne walker_mbr_malformed

        .if(DO_PRINT)
            lda #COLOR_OK
            sta TEXT_COLOR
            
            lda #<ok_message
            sta TEXT_TO_PRINT
            lda #>ok_message
            sta TEXT_TO_PRINT + 1
            
            jsr print_text_zero
            
            jsr print_number_of_loops
        .endif
    .endif
    
    jmp walker_done_reading_sector_proceed
    
walker_mbr_malformed:

    .if(DO_PRINT)
        ; The MBR is not correctly formed
        lda #COLOR_ERROR
        sta TEXT_COLOR
        
        lda #<vera_sd_malformed_msb
        sta TEXT_TO_PRINT
        lda #>vera_sd_malformed_msb
        sta TEXT_TO_PRINT + 1
        
        jsr print_text_zero
    .endif

    jmp walker_done_reading_sector_do_not_proceed
    
walker_wait_for_data_packet_start_timeout:
    
    .if(DO_PRINT)
        ; If carry is unset, we timed out. We print 'Timeout' as an error
        lda #COLOR_ERROR
        sta TEXT_COLOR
        
        lda #<vera_sd_timeout_message
        sta TEXT_TO_PRINT
        lda #>vera_sd_timeout_message
        sta TEXT_TO_PRINT + 1
        
        jsr print_text_zero
    .endif

    jmp walker_done_reading_sector_do_not_proceed
    
    
walker_done_reading_sector_do_not_proceed:
    jsr move_cursor_to_next_line

    ; We unselect the card
    lda #SPI_CHIP_DESELECT_AND_SLOW
    sta VERA_SPI_CTRL
    
    .if(DO_BORDER_COLOR)
        lda #2   ; green!
        sta VERA_DC_BORDER
    .endif

    ; TODO: Can we further 'POWER OFF' the card?
    clc
    rts
    
walker_done_reading_sector_proceed:
    jsr move_cursor_to_next_line
    sec
    rts
    



load_and_draw_frame:

    lda #0
    sta VERA_ADDR_LOW
    sta VERA_ADDR_HIGH

    lda #%00010000      ; setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #NR_OF_SECTORS_TO_COPY
    sta SECTOR_NUMBER_IN_FRAME
    
next_sector_to_copy:

    ; FIXME: setup for loading the NEXT! sector
    jsr walker_vera_read_sector

    inc SECTOR_NUMBER
    bne sector_number_is_incremented
    inc SECTOR_NUMBER+1
    bne sector_number_is_incremented
    inc SECTOR_NUMBER+2
    bne sector_number_is_incremented
    inc SECTOR_NUMBER+3
    bne sector_number_is_incremented
    
sector_number_is_incremented:
    dec SECTOR_NUMBER_IN_FRAME
    bne next_sector_to_copy


    rts
    
    

generate_copy_sector_code:

    lda #<COPY_SECTOR_CODE
    sta CODE_ADDRESS
    lda #>COPY_SECTOR_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_low:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    bne next_copy_instruction_low
    
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_high:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    bne next_copy_instruction_high
    

    ; -- rts --
    lda #$60
    jsr add_code_byte

    rts


    
add_code_byte:
    sta (CODE_ADDRESS),y   ; store code byte at address (located at CODE_ADDRESS) + y
    iny                    ; increase y
    cpy #0                 ; if y == 0
    bne done_adding_code_byte
    inc CODE_ADDRESS+1     ; increment high-byte of CODE_ADDRESS
done_adding_code_byte:
    rts




; ==== DATA ====

; FIXME: all this DATA is included as asm text right now, but should be *loaded* from SD instead!

; - Initial palette -
palette_data:
  .byte $67, $05
  .byte $78, $06
  .byte $89, $06
  .byte $89, $07
  .byte $8a, $07
  .byte $9a, $07
  .byte $9a, $08
  .byte $9b, $08
  .byte $ab, $08
  .byte $ab, $09
  .byte $ac, $09
  .byte $bc, $0a
  .byte $bd, $0a
  .byte $cd, $0a
  .byte $cd, $0b
  .byte $ce, $0b
  .byte $df, $0c
  .byte $ef, $0d
  .byte $ef, $0e
  .byte $ff, $0e
  .byte $ff, $0d
  .byte $de, $0c
  .byte $34, $02
  .byte $34, $03
  .byte $55, $05
  .byte $56, $05
  .byte $66, $06
  .byte $88, $07
  .byte $99, $09
  .byte $aa, $09
  .byte $98, $08
  .byte $55, $04
  .byte $33, $03
  .byte $44, $03
  .byte $43, $02
  .byte $43, $03
  .byte $33, $02
  .byte $22, $02
  .byte $22, $01
  .byte $77, $07
  .byte $88, $08
  .byte $65, $05
  .byte $54, $04
  .byte $44, $04
  .byte $11, $01
  .byte $00, $00
  .byte $68, $05
  .byte $79, $06
  .byte $ac, $08
  .byte $ad, $09
  .byte $bd, $09
  .byte $ce, $0a
  .byte $cf, $0b
  .byte $df, $0b
  .byte $ff, $0f
  .byte $9c, $09
  .byte $26, $02
  .byte $12, $00
  .byte $45, $04
  .byte $66, $05
  .byte $44, $02
  .byte $11, $00
  .byte $78, $05
  .byte $79, $05
  .byte $8a, $06
  .byte $9b, $07
  .byte $9c, $08
  .byte $be, $0a
  .byte $ef, $0c
  .byte $89, $08
  .byte $77, $06
  .byte $78, $07
  .byte $67, $06
  .byte $99, $08
  .byte $01, $00
  .byte $68, $04
  .byte $8b, $07
  .byte $de, $0b
  .byte $23, $01
  .byte $65, $04
  .byte $aa, $0a
  .byte $54, $03
  .byte $55, $03
  .byte $12, $01
  .byte $12, $02
  .byte $00, $01
  .byte $22, $00
  .byte $66, $04
  .byte $9a, $09
  .byte $23, $02
  .byte $23, $03
  .byte $ad, $08
  .byte $24, $01
  .byte $cf, $0a
  .byte $35, $02
  .byte $56, $04
  .byte $57, $04
  .byte $01, $01
  .byte $32, $02
  .byte $10, $00
  .byte $21, $01
  .byte $67, $04
  .byte $45, $03
  .byte $56, $03
  .byte $33, $01
  .byte $34, $04
  .byte $bc, $09
  .byte $45, $02
  .byte $32, $01
  .byte $be, $09
  .byte $02, $00
  .byte $34, $01
  .byte $11, $02
  .byte $9c, $07
  .byte $23, $00
  .byte $46, $03
  .byte $df, $0d
  .byte $33, $04
  .byte $df, $0a
  .byte $9b, $09
  .byte $57, $03
  .byte $35, $01
  .byte $79, $07
  .byte $8a, $08
  .byte $46, $04
  .byte $89, $09
  .byte $68, $06
  .byte $cc, $0b
  .byte $de, $0d
  .byte $ee, $0d
  .byte $ee, $0e
  .byte $45, $05
  .byte $bc, $0b
  .byte $dd, $0d
  .byte $ee, $0f
  .byte $ef, $0f
  .byte $ce, $0c
  .byte $78, $08
  .byte $ba, $0a
  .byte $cc, $0c
  .byte $56, $06
  .byte $a9, $0a
  .byte $bb, $0b
  .byte $cd, $0d
  .byte $aa, $0b
  .byte $de, $0e
  .byte $fe, $0f
  .byte $cd, $0c
  .byte $dd, $0e
  .byte $ab, $0b
  .byte $99, $0a
  .byte $bb, $0c
  .byte $13, $01
  .byte $cc, $0d
  .byte $24, $02
  .byte $ac, $0a
  .byte $bd, $0b
  .byte $88, $09
  .byte $be, $0b
  .byte $77, $08
  .byte $ed, $0e
  .byte $57, $05
  .byte $dc, $0d
  .byte $44, $05
  .byte $cb, $0c
  .byte $dd, $0c
  .byte $bc, $0c
  .byte $ed, $0f
  .byte $66, $07
  .byte $65, $06
  .byte $ba, $0b
  .byte $cf, $0c
  .byte $ad, $0a
  .byte $be, $0c
  .byte $ab, $0a
  .byte $df, $0e
  .byte $df, $0f
  .byte $cf, $0e
  .byte $ce, $0d
  .byte $be, $0d
  .byte $bd, $0c
  .byte $55, $06
  .byte $9a, $0a
  .byte $bb, $0a
  .byte $cf, $0d
  .byte $cf, $0f
  .byte $bf, $0e
  .byte $ad, $0c
  .byte $ad, $0b
  .byte $ce, $0e
  .byte $ac, $0c
  .byte $9b, $0a
  .byte $9c, $0a
  .byte $ac, $0b
  .byte $67, $07
  .byte $bd, $0d
  .byte $45, $06
  .byte $87, $08
  .byte $54, $05
  .byte $22, $03
  .byte $35, $04
  .byte $67, $08
  .byte $76, $07
  .byte $32, $03
  .byte $99, $07
  .byte $79, $08
  .byte $43, $04
  .byte $ce, $0f
  .byte $be, $0e
  .byte $ae, $0b
  .byte $be, $0f
  .byte $bd, $0e
  .byte $98, $09
  .byte $8a, $09
  .byte $9b, $0c
  .byte $10, $01
  .byte $88, $06
  .byte $aa, $08
  .byte $35, $03
  .byte $77, $05
  .byte $cc, $0a
  .byte $dd, $0b
  .byte $bb, $09
  .byte $ee, $0c
  .byte $a9, $09
end_of_palette_data:


palette_changes_per_frame:
  .byte $00
  .byte $0b  ,  $e2, $25, $02,  $e3, $46, $02,  $e4, $87, $06,  $e5, $bf, $0d,  $e6, $ad, $0d,  $e7, $bd, $08,  $e8, $76, $05,  $e9, $69, $05,  $ea, $ce, $09,  $eb, $7a, $06,  $ec, $ac, $0d
  .byte $08  ,  $39, $9b, $0b,  $6f, $13, $00,  $72, $7a, $09,  $77, $8b, $08,  $7a, $21, $02,  $8b, $87, $07,  $a8, $76, $06,  $c5, $8b, $09
  .byte $07  ,  $73, $36, $02,  $79, $02, $00,  $bf, $7a, $07,  $c9, $9c, $07,  $ca, $69, $06,  $d1, $ba, $09,  $d2, $65, $03
  .byte $02  ,  $39, $98, $07,  $72, $21, $00
  .byte $03  ,  $57, $03, $00,  $73, $a9, $0b,  $7a, $ed, $0d
  .byte $04  ,  $70, $47, $03,  $77, $ed, $0f,  $79, $57, $03,  $ad, $dc, $0b
  .byte $03  ,  $1f, $36, $02,  $57, $21, $02,  $64, $23, $00
  .byte $05  ,  $6f, $68, $07,  $70, $bf, $0a,  $72, $98, $08,  $73, $cb, $0d,  $79, $22, $00
  .byte $04  ,  $1f, $13, $00,  $38, $cb, $0b,  $64, $46, $05,  $69, $10, $00
  .byte $1c  ,  $39, $68, $0b,  $57, $56, $0a,  $6f, $57, $0a,  $73, $67, $0a,  $77, $78, $0b,  $79, $79, $0c,  $7a, $89, $0c,  $ad, $78, $0a,  $b2, $ab, $0f,  $b4, $89, $0b,  $ba, $ab, $0e,  $bb, $56, $08,  $bc, $34, $06,  $bd, $9a, $0c,  $be, $33, $05,  $bf, $88, $0a,  $c0, $34, $05,  $c1, $cd, $0e,  $c4, $56, $07,  $c5, $9a, $0b,  $ca, $66, $08,  $d0, $45, $06,  $d1, $23, $04,  $d3, $ab, $0c,  $d4, $55, $07,  $d7, $33, $01,  $da, $34, $01,  $e0, $54, $02
  .byte $1d  ,  $23, $be, $0e,  $38, $be, $0f,  $64, $bd, $0e,  $cd, $ad, $0e,  $e1, $bf, $0e,  $e2, $ce, $0e,  $e3, $bf, $0f,  $e5, $ce, $0f,  $e7, $67, $08,  $e9, $be, $0d,  $ed, $bd, $0d,  $ee, $78, $09,  $ef, $cf, $0f,  $f0, $ac, $0c,  $f1, $9c, $0b,  $f2, $ad, $0c,  $f3, $ad, $0b,  $f4, $cf, $0e,  $f5, $77, $09,  $f6, $68, $08,  $f7, $79, $09,  $f8, $bc, $0d,  $f9, $9b, $0a,  $fa, $02, $00,  $fb, $9c, $09,  $fc, $ad, $0a,  $fd, $89, $0a,  $fe, $21, $02,  $ff, $8a, $0a
  .byte $17  ,  $39, $8b, $0c,  $57, $7a, $0b,  $6f, $ad, $0f,  $73, $8a, $0c,  $77, $8a, $0b,  $79, $bd, $0f,  $7a, $9b, $0c,  $93, $ac, $0e,  $ad, $8b, $0b,  $b2, $79, $0a,  $b4, $7a, $0a,  $ba, $7a, $09,  $bb, $68, $07,  $bc, $7a, $08,  $bd, $ae, $0d,  $be, $9c, $0c,  $bf, $9c, $0d,  $c0, $9c, $0e,  $c1, $aa, $08,  $c5, $cd, $0f,  $ca, $ae, $0b,  $d1, $99, $07,  $d2, $9c, $0a
  .byte $03  ,  $69, $ae, $0e,  $6d, $43, $02,  $c4, $7a, $07
  .byte $08  ,  $39, $8b, $0a,  $57, $9b, $0b,  $73, $57, $03,  $77, $fe, $0f,  $7a, $9b, $0d,  $ad, $dc, $0b,  $b2, $89, $05,  $b4, $98, $07
  .byte $03  ,  $69, $8b, $0c,  $6f, $8b, $0b,  $ae, $69, $06
  .byte $02  ,  $1f, $46, $02,  $23, $ba, $0a
  .byte $02  ,  $38, $bf, $09,  $39, $13, $00
  .byte $03  ,  $23, $ed, $0f,  $57, $57, $06,  $64, $10, $00
  .byte $00
  .byte $01  ,  $1f, $cf, $09
  .byte $01  ,  $23, $8a, $05
  .byte $02  ,  $1f, $69, $05,  $38, $8b, $08
  .byte $08  ,  $57, $98, $0a,  $69, $a9, $0b,  $6f, $a9, $09,  $73, $dc, $0e,  $79, $ba, $0c,  $7a, $dd, $0f,  $93, $de, $0f,  $ad, $12, $03
  .byte $08  ,  $1f, $99, $0b,  $38, $88, $0a,  $a2, $bb, $0d,  $ae, $cc, $0e,  $b1, $87, $09,  $b3, $cb, $0d,  $b9, $aa, $0c,  $ba, $56, $07
  .byte $07  ,  $5d, $ce, $0d,  $6f, $57, $07,  $77, $cb, $0a,  $79, $69, $05,  $ad, $ed, $0f,  $b4, $dc, $0c,  $bc, $ac, $0e
  .byte $1b  ,  $57, $12, $09,  $64, $23, $09,  $b3, $23, $0a,  $bd, $22, $09,  $be, $33, $0a,  $c0, $34, $0b,  $c4, $45, $0c,  $ca, $55, $0c,  $cb, $78, $0f,  $ce, $66, $0d,  $d1, $56, $0d,  $d2, $01, $07,  $d7, $67, $0e,  $d8, $00, $06,  $de, $79, $0f,  $e0, $35, $0b,  $e1, $22, $08,  $e3, $01, $06,  $e4, $67, $0d,  $ea, $77, $0d,  $ec, $34, $09,  $ed, $12, $07,  $f1, $89, $0f,  $f6, $34, $0a,  $f7, $56, $0c,  $fe, $56, $0b,  $ff, $23, $08
  .byte $0c  ,  $6f, $57, $09,  $77, $46, $08,  $79, $47, $08,  $8e, $66, $09,  $b4, $35, $07,  $bb, $bd, $0d,  $bf, $9b, $0c,  $c1, $79, $0c,  $c9, $79, $0b,  $d6, $9c, $0a,  $da, $ac, $0d,  $f9, $9c, $0c
  .byte $11  ,  $39, $57, $0c,  $57, $68, $0d,  $64, $68, $0a,  $9f, $57, $07,  $b3, $67, $0a,  $bd, $69, $05,  $be, $76, $07,  $c0, $a9, $0a,  $d2, $dd, $0b,  $d7, $57, $08,  $d8, $21, $02,  $de, $aa, $08,  $e0, $dc, $0c,  $e1, $68, $09,  $e3, $46, $0d,  $e9, $57, $0e,  $f6, $12, $03
  .byte $0a  ,  $6f, $79, $0a,  $77, $9b, $0a,  $79, $9c, $0d,  $b1, $9c, $0b,  $b4, $be, $0b,  $c1, $99, $07,  $d9, $8a, $0a,  $ef, $78, $04,  $f4, $32, $04,  $f9, $68, $07
  .byte $0e  ,  $39, $9c, $07,  $57, $10, $00,  $64, $88, $06,  $8e, $01, $02,  $9f, $ba, $0a,  $b3, $79, $04,  $bd, $24, $01,  $c4, $57, $03,  $c9, $57, $05,  $ca, $98, $0a,  $ce, $10, $01,  $d1, $22, $04,  $d7, $ba, $0c,  $e0, $32, $01
  .byte $06  ,  $1f, $69, $05,  $38, $23, $00,  $6f, $34, $01,  $77, $36, $02,  $79, $cd, $0e,  $7a, $87, $06
  .byte $08  ,  $39, $88, $0a,  $57, $99, $0b,  $5d, $cb, $0a,  $a2, $35, $04,  $aa, $33, $01,  $ac, $a9, $09,  $ad, $7a, $07,  $ae, $fe, $0f
  .byte $07  ,  $1f, $22, $00,  $38, $cc, $0e,  $6f, $13, $02,  $77, $69, $06,  $79, $65, $06,  $7a, $34, $05,  $8e, $8a, $09
  .byte $20  ,  $57, $00, $04,  $5d, $00, $05,  $73, $35, $0a,  $9f, $45, $08,  $ac, $01, $04,  $ad, $35, $09,  $b1, $45, $09,  $b4, $01, $03,  $bb, $45, $0a,  $bc, $57, $0c,  $c5, $01, $05,  $cd, $67, $0a,  $d2, $79, $0e,  $d6, $46, $05,  $d9, $11, $04,  $da, $35, $07,  $dd, $68, $0c,  $e0, $57, $06,  $e2, $8a, $0f,  $e3, $79, $0c,  $e5, $46, $08,  $e6, $24, $08,  $e9, $46, $09,  $f0, $9b, $0a,  $f2, $01, $02,  $f3, $68, $0d,  $f4, $02, $05,  $f7, $57, $0a,  $f8, $88, $0b,  $f9, $24, $09,  $fb, $46, $0a,  $fc, $79, $0b
  .byte $06  ,  $1f, $cc, $0f,  $68, $bd, $0e,  $6f, $cd, $0f,  $77, $ac, $0d,  $8e, $ac, $0e,  $c1, $dd, $0f
  .byte $1b  ,  $57, $7a, $09,  $5d, $69, $08,  $69, $79, $09,  $73, $69, $0a,  $a2, $79, $08,  $ac, $7a, $0a,  $ad, $8a, $0a,  $b1, $8b, $0a,  $b4, $8b, $0b,  $bb, $8b, $0c,  $bc, $56, $03,  $c5, $24, $03,  $c7, $13, $00,  $cc, $7a, $08,  $d2, $99, $07,  $d6, $69, $06,  $d9, $58, $06,  $da, $8a, $0b,  $dd, $10, $00,  $e0, $23, $04,  $e2, $ed, $0f,  $e3, $9c, $09,  $e5, $ad, $0a,  $e6, $cb, $0d,  $e9, $54, $06,  $ea, $cd, $0e,  $f2, $cc, $0a
  .byte $09  ,  $1f, $a9, $0b,  $68, $32, $03,  $6f, $54, $05,  $77, $58, $04,  $7a, $be, $0b,  $8e, $cf, $0c,  $9f, $ce, $0d,  $ba, $dd, $0b,  $bf, $a9, $09
  .byte $0b  ,  $57, $68, $07,  $5d, $57, $06,  $69, $56, $07,  $73, $34, $05,  $ac, $cb, $0a,  $ad, $56, $08,  $b1, $34, $06,  $b4, $bc, $0d,  $bb, $66, $08,  $c2, $9b, $0b,  $c5, $9a, $0b
  .byte $19  ,  $39, $35, $08,  $65, $01, $03,  $77, $00, $02,  $7a, $45, $08,  $8e, $46, $08,  $ae, $79, $0d,  $bf, $78, $0d,  $c7, $35, $05,  $cc, $78, $0c,  $d2, $57, $09,  $d6, $79, $0c,  $d8, $45, $09,  $d9, $cb, $0b,  $da, $8a, $09,  $e1, $32, $01,  $e2, $9b, $0d,  $e6, $89, $0c,  $e9, $8a, $0d,  $f0, $89, $0d,  $f3, $78, $0b,  $f4, $68, $0a,  $f8, $68, $0b,  $f9, $12, $04,  $fb, $23, $05,  $fd, $67, $0b
  .byte $0b  ,  $38, $79, $09,  $57, $8a, $0b,  $5d, $bd, $0f,  $64, $13, $00,  $6c, $8a, $0a,  $a2, $ac, $0d,  $c1, $be, $0b,  $d4, $bd, $0e,  $dd, $cf, $0c,  $e0, $be, $0e,  $ee, $ac, $0e
  .byte $1a  ,  $1f, $78, $0a,  $39, $8b, $0b,  $65, $9c, $0c,  $73, $7a, $0a,  $77, $68, $09,  $7a, $79, $0a,  $8e, $8b, $0a,  $ae, $8b, $0c,  $b1, $cc, $0e,  $c4, $be, $0f,  $c7, $9c, $0d,  $d1, $9c, $0b,  $d2, $21, $02,  $d7, $7a, $09,  $d8, $8b, $0d,  $d9, $ad, $0d,  $da, $89, $0b,  $e2, $55, $08,  $ed, $ad, $0b,  $f4, $9c, $0a,  $f6, $69, $08,  $f7, $9c, $0e,  $f8, $89, $0a,  $f9, $dd, $0f,  $fb, $45, $02,  $fd, $ad, $0c
  .byte $08  ,  $ac, $45, $08,  $bf, $9b, $0d,  $ca, $57, $07,  $cc, $23, $05,  $d6, $22, $04,  $e1, $9c, $0f,  $e4, $34, $06,  $f0, $ae, $0f
  .byte $07  ,  $77, $78, $0c,  $cb, $67, $0b,  $d8, $8a, $09,  $d9, $7a, $07,  $e9, $ba, $0c,  $f6, $9b, $0c,  $fb, $57, $0a
  .byte $16  ,  $38, $57, $03,  $39, $ad, $0d,  $57, $36, $03,  $6c, $cd, $09,  $73, $bc, $0e,  $7a, $cf, $0f,  $8e, $be, $0d,  $a2, $cd, $0f,  $ac, $21, $01,  $bb, $ae, $09,  $bf, $69, $05,  $c2, $fe, $0f,  $c6, $bd, $0d,  $ca, $ac, $0b,  $cc, $df, $0f,  $d0, $ce, $0e,  $d6, $cf, $0e,  $d7, $ce, $0f,  $e1, $be, $0c,  $e4, $99, $0b,  $ec, $ce, $09,  $f0, $dc, $0e
  .byte $0e  ,  $77, $68, $09,  $cb, $7a, $0a,  $cd, $7a, $0b,  $d9, $79, $0a,  $dd, $8a, $0b,  $e2, $8a, $0a,  $e6, $ac, $0d,  $e9, $45, $06,  $ee, $9b, $0b,  $f3, $45, $02,  $f6, $58, $05,  $f7, $66, $08,  $fb, $45, $07,  $ff, $a9, $09
  .byte $09  ,  $57, $9c, $07,  $64, $57, $06,  $6c, $46, $02,  $8e, $ba, $0c,  $c1, $cf, $0c,  $c6, $87, $08,  $e1, $10, $00,  $ec, $88, $0a,  $fd, $79, $08
  .byte $08  ,  $1f, $13, $00,  $39, $be, $0b,  $5d, $35, $01,  $65, $98, $07,  $69, $8b, $08,  $73, $68, $07,  $77, $99, $07,  $7a, $88, $06
  .byte $05  ,  $57, $23, $00,  $64, $98, $0a,  $8e, $34, $01,  $93, $32, $01,  $a2, $a9, $08
  .byte $04  ,  $38, $9c, $07,  $5d, $87, $06,  $65, $58, $04,  $69, $55, $07
  .byte $04  ,  $64, $57, $03,  $6c, $56, $07,  $70, $22, $00,  $93, $9b, $0a
  .byte $1f  ,  $38, $13, $07,  $5d, $14, $07,  $65, $24, $07,  $9f, $24, $06,  $a2, $67, $0a,  $ad, $35, $09,  $ae, $8a, $0d,  $b9, $ac, $0e,  $bb, $7a, $0d,  $bf, $ad, $0f,  $c4, $de, $0f,  $cb, $36, $09,  $cd, $24, $05,  $d0, $cd, $0f,  $d6, $ad, $0d,  $d9, $46, $06,  $da, $bd, $0f,  $dd, $9b, $0c,  $de, $36, $02,  $e0, $9c, $0c,  $e7, $8b, $0a,  $e9, $35, $05,  $f5, $bd, $0d,  $f6, $ad, $0c,  $f7, $8b, $08,  $f9, $9c, $0f,  $fb, $35, $07,  $fc, $bc, $0e,  $fd, $65, $03,  $fe, $bc, $0f,  $ff, $ac, $0f
  .byte $05  ,  $57, $9c, $07,  $64, $46, $02,  $69, $ba, $0a,  $6c, $98, $07,  $70, $69, $05
  .byte $06  ,  $38, $58, $04,  $5d, $22, $00,  $65, $7a, $07,  $73, $32, $01,  $8e, $ce, $0d,  $93, $02, $01
  .byte $26  ,  $57, $67, $0b,  $69, $45, $09,  $6c, $55, $09,  $70, $44, $07,  $9f, $56, $09,  $ad, $45, $07,  $ae, $bf, $0f,  $b1, $56, $08,  $b9, $cf, $0e,  $bb, $be, $0f,  $bf, $45, $06,  $c4, $9a, $0c,  $c7, $56, $0a,  $cb, $34, $06,  $cd, $be, $0e,  $d0, $cf, $0f,  $d1, $be, $0c,  $d7, $77, $09,  $d9, $67, $09,  $da, $89, $0b,  $dd, $9a, $0d,  $de, $77, $0a,  $e0, $79, $0a,  $e2, $33, $06,  $e6, $67, $08,  $e7, $56, $07,  $e8, $66, $08,  $e9, $78, $0a,  $ea, $8a, $0b,  $f4, $89, $0d,  $f5, $ce, $0e,  $f7, $be, $0d,  $f9, $88, $0b,  $fb, $9b, $0d,  $fc, $a9, $09,  $fd, $aa, $0c,  $fe, $24, $03,  $ff, $ab, $0e
  .byte $06  ,  $1f, $ce, $0f,  $38, $ae, $0d,  $5d, $bd, $0d,  $73, $69, $05,  $93, $98, $07,  $f0, $34, $01
  .byte $1e  ,  $57, $9c, $0c,  $64, $8b, $0c,  $69, $9c, $0d,  $6c, $9b, $0c,  $70, $8b, $0a,  $7a, $ac, $0d,  $9f, $8a, $0a,  $a2, $79, $09,  $ad, $bd, $0f,  $b1, $79, $08,  $b4, $9b, $0a,  $bf, $ad, $0f,  $c4, $68, $07,  $c5, $7a, $09,  $c7, $9c, $0b,  $cb, $9c, $0a,  $d3, $bd, $08,  $d7, $bf, $0a,  $d9, $13, $02,  $da, $22, $00,  $dd, $8b, $08,  $de, $02, $01,  $e0, $25, $02,  $e2, $57, $03,  $e4, $68, $08,  $e6, $8b, $09,  $e7, $7a, $08,  $e8, $ad, $0e,  $e9, $ac, $0c,  $f1, $cf, $0d
  .byte $05  ,  $72, $13, $00,  $77, $57, $06,  $93, $76, $05,  $ae, $47, $03,  $ba, $69, $07
  .byte $06  ,  $57, $88, $06,  $64, $99, $07,  $69, $98, $08,  $6c, $aa, $08,  $7a, $dd, $0b,  $a1, $87, $06
  .byte $04  ,  $38, $de, $0f,  $65, $ed, $0e,  $70, $46, $02,  $77, $ba, $0a
  .byte $0e  ,  $93, $7a, $0a,  $a1, $8b, $0b,  $a3, $9c, $0c,  $ad, $9b, $0c,  $ae, $7a, $0b,  $b1, $9c, $0d,  $ba, $cd, $09,  $bf, $ac, $0d,  $c4, $69, $09,  $c5, $35, $01,  $c7, $89, $0b,  $d9, $46, $05,  $da, $69, $06,  $dd, $78, $09
  .byte $12  ,  $38, $56, $08,  $65, $55, $07,  $70, $67, $09,  $77, $34, $06,  $de, $23, $05,  $e0, $9a, $0b,  $e6, $57, $08,  $e7, $ab, $0c,  $ea, $9a, $0c,  $ec, $78, $0a,  $ef, $bc, $08,  $f0, $ae, $0d,  $f4, $dc, $0d,  $f9, $ae, $0c,  $fc, $67, $08,  $fd, $ab, $07,  $fe, $36, $03,  $ff, $cb, $0b
  .byte $11  ,  $1f, $58, $04,  $93, $35, $04,  $a1, $9c, $0b,  $a2, $69, $07,  $a3, $7a, $07,  $aa, $ed, $0e,  $ad, $9d, $0b,  $ae, $79, $08,  $b1, $58, $05,  $bb, $8b, $08,  $c2, $a9, $09,  $c4, $34, $01,  $c5, $68, $07,  $c7, $ce, $09,  $d4, $ba, $0a,  $d9, $bf, $0e,  $da, $9c, $07
  .byte $06  ,  $38, $fe, $0f,  $5d, $de, $0f,  $65, $66, $03,  $6f, $33, $01,  $70, $76, $05,  $77, $98, $07
  .byte $12  ,  $93, $be, $0f,  $a2, $79, $0b,  $ab, $ce, $0f,  $ad, $79, $09,  $ba, $8b, $0c,  $c7, $68, $09,  $d4, $ac, $0e,  $d9, $bd, $0e,  $dd, $46, $02,  $de, $7a, $09,  $e0, $9b, $0c,  $e1, $8b, $0a,  $e4, $54, $05,  $e6, $9c, $0d,  $e7, $bd, $0d,  $ea, $8b, $0b,  $ec, $ae, $0a,  $f0, $22, $00
  .byte $03  ,  $1f, $ba, $0b,  $5d, $a9, $08,  $65, $87, $06
  .byte $00
  .byte $05  ,  $39, $10, $00,  $5d, $58, $04,  $65, $32, $01,  $77, $69, $06,  $7a, $47, $04
  .byte $01  ,  $73, $be, $0b
  .byte $04  ,  $39, $36, $02,  $7a, $98, $07,  $8e, $47, $03,  $93, $ba, $09
  .byte $01  ,  $65, $69, $05
  .byte $19  ,  $7a, $36, $0e,  $93, $25, $0c,  $9f, $36, $0d,  $a2, $35, $0b,  $b9, $57, $0f,  $ba, $47, $0e,  $be, $58, $0f,  $bf, $36, $0c,  $cc, $46, $0c,  $d4, $69, $0f,  $d5, $58, $0e,  $d9, $35, $0a,  $de, $46, $0a,  $e0, $79, $0f,  $e6, $13, $08,  $ea, $7a, $0f,  $ec, $25, $08,  $ef, $8a, $0f,  $f5, $8b, $0f,  $f8, $69, $0e,  $f9, $47, $09,  $fb, $46, $09,  $fd, $9b, $0f,  $fe, $57, $0a,  $ff, $ff, $0b
  .byte $18  ,  $1f, $79, $0a,  $38, $8c, $0f,  $50, $6a, $0e,  $52, $8c, $0d,  $56, $9c, $0d,  $57, $8b, $0c,  $6d, $8b, $0d,  $70, $8d, $0f,  $87, $69, $09,  $95, $7a, $0c,  $97, $7a, $0e,  $98, $7a, $0b,  $9a, $8c, $0c,  $a5, $8b, $0b,  $aa, $bc, $0d,  $b1, $8a, $0a,  $b2, $7b, $0e,  $c0, $7b, $0f,  $c2, $7a, $0a,  $d7, $76, $07,  $dc, $8c, $0b,  $df, $8a, $0b,  $f2, $41, $03,  $f4, $41, $04
  .byte $17  ,  $7a, $85, $0c,  $93, $da, $0f,  $9f, $a7, $0e,  $a2, $db, $0f,  $b9, $ca, $0f,  $ba, $b9, $0f,  $be, $eb, $0f,  $bf, $96, $0d,  $cc, $a8, $0f,  $d0, $85, $0b,  $d4, $a9, $0e,  $d5, $87, $0e,  $d9, $86, $0d,  $de, $75, $0b,  $e0, $ba, $0f,  $e6, $cb, $0f,  $e8, $a8, $0e,  $ec, $97, $0e,  $ef, $76, $0c,  $f8, $64, $0a,  $f9, $98, $0e,  $fb, $98, $0d,  $fe, $b9, $0e
  .byte $18  ,  $23, $55, $0b,  $38, $65, $0b,  $39, $57, $0a,  $50, $66, $0b,  $52, $55, $0a,  $56, $55, $09,  $57, $56, $09,  $6d, $67, $0b,  $6f, $67, $0c,  $70, $68, $0b,  $87, $66, $0c,  $95, $77, $0c,  $97, $58, $03,  $98, $24, $04,  $9a, $56, $0a,  $a5, $69, $07,  $b2, $89, $0d,  $b3, $79, $0b,  $c0, $24, $00,  $c2, $35, $05,  $dc, $56, $08,  $ea, $67, $0a,  $f0, $cf, $0e,  $f5, $77, $05
  .byte $10  ,  $7a, $36, $0f,  $93, $47, $0f,  $9f, $46, $0e,  $b9, $57, $0f,  $ba, $36, $0e,  $cc, $35, $0d,  $d0, $47, $0e,  $d5, $58, $0f,  $d9, $67, $0f,  $de, $36, $0d,  $e1, $68, $0f,  $e8, $69, $0f,  $ec, $57, $0d,  $ef, $7a, $0f,  $f9, $46, $0d,  $fe, $23, $08
  .byte $0b  ,  $38, $58, $0e,  $50, $46, $0c,  $52, $57, $0e,  $70, $57, $08,  $87, $56, $0c,  $95, $46, $07,  $b3, $68, $0e,  $be, $47, $0d,  $bf, $25, $02,  $df, $52, $05,  $f8, $51, $04
  .byte $1d  ,  $56, $ec, $0f,  $57, $fd, $0f,  $6c, $10, $02,  $6d, $ed, $0f,  $7a, $88, $06,  $93, $dd, $0f,  $97, $cc, $0e,  $98, $aa, $0d,  $9f, $bb, $0e,  $b2, $53, $05,  $b9, $52, $04,  $ba, $23, $05,  $c2, $ce, $0d,  $c7, $fe, $0e,  $cc, $58, $05,  $d0, $dd, $0b,  $d5, $de, $0a,  $d6, $ff, $0c,  $d9, $ce, $0e,  $de, $cd, $0e,  $e1, $df, $0a,  $e8, $ee, $0f,  $ea, $dd, $0e,  $ef, $df, $0f,  $f7, $cc, $0f,  $f9, $bc, $0e,  $fb, $dc, $0f,  $fd, $cd, $0f,  $fe, $de, $0f
  .byte $17  ,  $1f, $fc, $0f,  $23, $cf, $0f,  $38, $be, $0d,  $39, $58, $03,  $50, $20, $03,  $52, $30, $03,  $64, $64, $06,  $6f, $41, $05,  $70, $30, $04,  $87, $98, $07,  $95, $dc, $0e,  $9a, $31, $04,  $a5, $42, $05,  $b3, $32, $05,  $b8, $bb, $0c,  $be, $fe, $0f,  $bf, $57, $06,  $c0, $77, $09,  $d3, $cc, $0d,  $dc, $99, $0a,  $ec, $89, $0a,  $f6, $ed, $0e,  $ff, $35, $04
  .byte $09  ,  $63, $e9, $0f,  $7a, $c8, $0f,  $ac, $96, $0d,  $c7, $da, $0f,  $cc, $c9, $0f,  $ce, $ea, $0f,  $d0, $97, $0c,  $d5, $a7, $0f,  $f2, $87, $0c
  .byte $05  ,  $23, $31, $02,  $6f, $65, $09,  $87, $41, $03,  $a1, $66, $0a,  $b3, $eb, $0e
  .byte $0e  ,  $38, $12, $04,  $50, $8a, $0b,  $63, $10, $00,  $64, $dd, $0b,  $69, $86, $07,  $70, $8c, $07,  $7a, $88, $06,  $9a, $8a, $05,  $a5, $20, $01,  $b2, $30, $02,  $ba, $ee, $0c,  $d5, $69, $04,  $df, $8b, $06,  $e1, $7a, $05
  .byte $23  ,  $1f, $bf, $0f,  $56, $cf, $0f,  $57, $af, $0f,  $6d, $ae, $0a,  $6f, $bf, $0c,  $93, $9d, $0a,  $95, $ae, $08,  $97, $be, $0d,  $98, $a9, $09,  $9f, $52, $03,  $a1, $63, $05,  $a2, $ae, $0f,  $aa, $68, $09,  $ac, $be, $0f,  $ad, $ae, $0e,  $b1, $7a, $08,  $b3, $ae, $09,  $c7, $78, $09,  $cb, $76, $08,  $cc, $65, $07,  $ce, $bb, $0a,  $d0, $68, $08,  $d4, $9a, $0b,  $de, $9b, $0c,  $e0, $45, $06,  $e6, $33, $01,  $e8, $34, $05,  $e9, $23, $00,  $f2, $35, $01,  $f7, $36, $02,  $f8, $21, $01,  $f9, $53, $04,  $fb, $10, $01,  $fd, $32, $02,  $fe, $00, $01
  .byte $05  ,  $50, $48, $0f,  $64, $47, $0f,  $be, $37, $0e,  $c0, $48, $0e,  $ff, $36, $0d
  .byte $0a  ,  $57, $a9, $0e,  $6f, $dc, $0f,  $98, $87, $0c,  $9f, $7a, $0f,  $a1, $6a, $0d,  $cb, $ee, $0f,  $cc, $6b, $0f,  $ce, $7a, $0d,  $d6, $7b, $0f,  $ea, $bb, $0e
  .byte $0f  ,  $1f, $ba, $0e,  $64, $a9, $0d,  $6c, $cc, $0a,  $93, $aa, $0d,  $97, $36, $03,  $aa, $9d, $07,  $ab, $7b, $06,  $ad, $02, $02,  $be, $77, $0b,  $c0, $77, $0a,  $d9, $56, $08,  $f0, $88, $0b,  $f1, $9d, $08,  $f6, $56, $07,  $ff, $66, $08
  .byte $13  ,  $50, $ba, $0f,  $56, $cb, $0e,  $6d, $88, $0c,  $7a, $65, $07,  $98, $dd, $0e,  $9a, $bb, $0a,  $9f, $98, $07,  $a1, $87, $06,  $a2, $14, $00,  $ac, $9c, $0e,  $b1, $7a, $0c,  $c6, $78, $0b,  $cc, $89, $0b,  $ce, $9d, $0e,  $d1, $9c, $0d,  $d6, $67, $0a,  $de, $9a, $0c,  $ea, $ad, $0e,  $ef, $53, $05
  .byte $06  ,  $1f, $87, $08,  $63, $cc, $0e,  $6c, $87, $0c,  $ad, $b9, $0e,  $be, $ad, $07,  $f0, $76, $08
  .byte $13  ,  $56, $cf, $0d,  $57, $99, $0d,  $64, $dc, $0e,  $6f, $ba, $0d,  $9f, $be, $08,  $a1, $ba, $0c,  $a2, $69, $07,  $ab, $cb, $0d,  $ac, $bd, $08,  $b1, $14, $01,  $c6, $7a, $08,  $cc, $10, $00,  $ce, $98, $0a,  $d1, $78, $0a,  $d6, $99, $0b,  $de, $bc, $0e,  $e7, $9c, $06,  $ea, $77, $09,  $ee, $55, $07
  .byte $08  ,  $50, $06, $0f,  $63, $16, $0f,  $6c, $17, $0f,  $77, $03, $0f,  $93, $28, $0f,  $ad, $14, $0f,  $ed, $04, $0f,  $f7, $25, $0f
  .byte $50  ,  $12, $26, $0a,  $13, $37, $09,  $14, $15, $0b,  $15, $24, $07,  $1f, $37, $0b,  $32, $25, $0a,  $33, $37, $0d,  $34, $15, $0d,  $35, $15, $0e,  $36, $05, $0f,  $37, $14, $0a,  $38, $58, $08,  $39, $27, $0c,  $44, $04, $0d,  $45, $26, $0e,  $52, $36, $0b,  $55, $25, $0c,  $56, $25, $08,  $57, $47, $09,  $5b, $47, $0b,  $5c, $35, $08,  $5d, $26, $0b,  $5e, $47, $08,  $62, $27, $0e,  $64, $47, $0d,  $69, $48, $0b,  $6d, $47, $0a,  $6e, $26, $0c,  $6f, $16, $0e,  $70, $37, $0c,  $72, $69, $06,  $73, $47, $07,  $75, $37, $0e,  $82, $36, $09,  $83, $47, $0e,  $87, $48, $0a,  $88, $88, $04,  $8b, $36, $0a,  $8e, $38, $0c,  $95, $48, $0c,  $97, $59, $0b,  $99, $58, $0b,  $9b, $46, $0b,  $9e, $47, $0c,  $9f, $58, $0c,  $a1, $35, $0a,  $a5, $59, $0d,  $aa, $69, $0b,  $ab, $58, $0d,  $ac, $36, $0c,  $b0, $46, $09,  $b1, $49, $0d,  $b2, $59, $0a,  $b3, $35, $0b,  $b9, $69, $0a,  $ba, $68, $0b,  $bb, $58, $0a,  $be, $57, $0b,  $c0, $48, $0d,  $c1, $36, $0d,  $cb, $59, $09,  $cd, $48, $09,  $ce, $68, $0a,  $d4, $58, $09,  $d6, $57, $0a,  $db, $26, $0d,  $dc, $38, $0d,  $de, $48, $0e,  $e1, $35, $07,  $e3, $68, $09,  $e5, $69, $09,  $e7, $37, $0f,  $ea, $46, $07,  $ec, $38, $0e,  $ef, $03, $0d,  $f0, $20, $03,  $f1, $8b, $09,  $f4, $cd, $0e,  $f9, $9a, $06,  $fa, $89, $05
  .byte $08  ,  $29, $9c, $09,  $7a, $55, $01,  $a0, $88, $05,  $ad, $bc, $0d,  $c7, $88, $06,  $d1, $43, $02,  $ee, $66, $03,  $ff, $99, $07
  .byte $16  ,  $12, $65, $07,  $13, $88, $08,  $14, $20, $01,  $15, $76, $05,  $1f, $9c, $0a,  $32, $65, $04,  $33, $8a, $05,  $34, $54, $03,  $35, $78, $04,  $36, $32, $01,  $37, $32, $04,  $38, $31, $03,  $39, $21, $03,  $44, $20, $02,  $45, $42, $04,  $50, $43, $05,  $52, $54, $06,  $55, $10, $02,  $56, $42, $03,  $57, $67, $03,  $5b, $68, $03,  $5c, $79, $04
  .byte $03  ,  $11, $ad, $09,  $29, $bd, $09,  $51, $56, $02
  .byte $03  ,  $10, $57, $02,  $13, $55, $02,  $15, $45, $01
  .byte $03  ,  $0b, $12, $02,  $0c, $23, $03,  $0d, $44, $01
  .byte $01  ,  $03, $35, $05
  .byte $03  ,  $04, $57, $07,  $05, $46, $06,  $06, $46, $05
  .byte $00
  .byte $06  ,  $03, $78, $09,  $07, $77, $08,  $08, $66, $08,  $09, $31, $04,  $0a, $79, $09,  $0b, $69, $08
  .byte $01  ,  $0c, $7a, $09
  .byte $04  ,  $05, $89, $07,  $08, $89, $0a,  $09, $8a, $0a,  $0d, $8b, $0a
  .byte $02  ,  $04, $88, $08,  $0e, $8a, $07
  .byte $04  ,  $03, $bc, $0a,  $06, $57, $07,  $07, $8b, $08,  $0f, $89, $06
  .byte $05  ,  $08, $78, $09,  $0d, $9a, $08,  $10, $bd, $0a,  $11, $ab, $09,  $12, $ac, $09
  .byte $06  ,  $0f, $cd, $0b,  $13, $8b, $0a,  $14, $9b, $08,  $15, $77, $08,  $16, $aa, $0a,  $17, $7a, $0a
  .byte $2f  ,  $18, $8c, $0f,  $1e, $8b, $0f,  $23, $6b, $0f,  $24, $7b, $0f,  $25, $7a, $0f,  $26, $6a, $0f,  $27, $6a, $0d,  $29, $69, $0f,  $2a, $6a, $0e,  $2d, $7b, $0d,  $2e, $5a, $0f,  $2f, $59, $0f,  $31, $7a, $0e,  $32, $8b, $0e,  $33, $5a, $0e,  $34, $7b, $0e,  $35, $8a, $0e,  $36, $4a, $0f,  $37, $6a, $0c,  $38, $9b, $0d,  $39, $5a, $0d,  $3a, $59, $0e,  $3d, $8b, $0d,  $3e, $7a, $0d,  $40, $8a, $0d,  $41, $8b, $0c,  $42, $8b, $0b,  $43, $9b, $0c,  $44, $9a, $0b,  $45, $69, $0c,  $4b, $7b, $0c,  $4c, $6a, $0b,  $4d, $7b, $0a,  $4e, $9c, $0c,  $4f, $7a, $0c,  $50, $9b, $0b,  $51, $9a, $07,  $52, $89, $06,  $53, $89, $0a,  $54, $49, $0e,  $55, $7a, $0b,  $56, $49, $0f,  $57, $8a, $0c,  $5a, $8a, $0b,  $5b, $39, $0f,  $5c, $9c, $0b,  $5d, $38, $0f
  .byte $0a  ,  $03, $9c, $0d,  $04, $69, $0e,  $06, $79, $0a,  $0f, $68, $05,  $10, $79, $0c,  $16, $58, $0e,  $1d, $8a, $06,  $21, $9c, $09,  $22, $79, $0b,  $2b, $ac, $0c
  .byte $01  ,  $15, $88, $08
  .byte $02  ,  $03, $cd, $0b,  $04, $bc, $0a
  .byte $00
  .byte $03  ,  $06, $ab, $08,  $08, $9b, $07,  $10, $9c, $08
  .byte $01  ,  $0b, $bd, $0a
  .byte $01  ,  $13, $8b, $07
  .byte $02  ,  $15, $bd, $0d,  $16, $ac, $08
  .byte $73  ,  $09, $ff, $0f,  $17, $fe, $0f,  $1f, $fd, $0f,  $22, $ef, $0f,  $23, $ff, $0e,  $24, $99, $0f,  $25, $db, $0f,  $26, $ff, $0d,  $27, $ec, $0f,  $29, $c9, $0e,  $2a, $ca, $0f,  $2d, $76, $0e,  $2e, $76, $0c,  $2f, $bb, $0f,  $33, $ac, $0f,  $34, $ee, $0f,  $36, $ad, $0f,  $37, $b9, $0e,  $39, $ed, $0f,  $3a, $ef, $0e,  $3d, $cc, $0f,  $3e, $ca, $0e,  $41, $87, $0e,  $42, $ef, $0d,  $45, $bd, $0f,  $4b, $97, $0e,  $4c, $a8, $0d,  $4d, $87, $0a,  $4f, $86, $0a,  $53, $ef, $0c,  $54, $ce, $0f,  $55, $9c, $0f,  $56, $86, $0b,  $5a, $77, $0c,  $5b, $96, $0c,  $5c, $cf, $0a,  $5d, $df, $0b,  $5e, $df, $0c,  $62, $89, $0f,  $63, $97, $0d,  $64, $cf, $0b,  $69, $cf, $0c,  $6c, $02, $00,  $6d, $01, $00,  $6e, $be, $0f,  $6f, $67, $0d,  $70, $76, $09,  $71, $97, $0b,  $73, $de, $0b,  $75, $df, $0d,  $77, $76, $08,  $7a, $02, $01,  $82, $ee, $0e,  $83, $68, $0e,  $87, $9c, $0e,  $88, $97, $0c,  $8b, $b9, $0d,  $8e, $de, $0f,  $93, $9b, $0f,  $95, $df, $0e,  $97, $77, $0a,  $99, $87, $07,  $9b, $be, $0a,  $9e, $de, $0c,  $9f, $01, $01,  $a0, $cd, $0f,  $a1, $77, $0b,  $a2, $ba, $0d,  $a5, $ee, $0d,  $aa, $13, $02,  $ab, $12, $01,  $ac, $23, $02,  $b0, $11, $00,  $b1, $67, $0f,  $b2, $cb, $0e,  $b3, $ce, $0b,  $b9, $00, $00,  $ba, $12, $02,  $bb, $bc, $0f,  $be, $ad, $0e,  $c0, $53, $03,  $c1, $ba, $0c,  $c7, $ce, $0a,  $cb, $22, $02,  $cd, $33, $02,  $ce, $22, $01,  $d0, $dd, $0f,  $d1, $9b, $0e,  $d4, $bd, $08,  $d6, $ad, $09,  $d9, $23, $03,  $db, $ac, $0e,  $dc, $77, $09,  $de, $ad, $08,  $e0, $87, $08,  $e1, $53, $05,  $e3, $63, $04,  $e5, $be, $0b,  $e6, $12, $00,  $e7, $42, $03,  $e8, $63, $05,  $ea, $24, $03,  $ec, $be, $09,  $ed, $ac, $0d,  $ee, $64, $05,  $ef, $66, $08,  $f0, $ad, $0d,  $f2, $53, $04,  $f6, $cd, $0a,  $f7, $34, $02,  $f9, $11, $01,  $fa, $98, $09,  $fb, $52, $03,  $fe, $bd, $09,  $ff, $33, $03
  .byte $05  ,  $0c, $45, $0b,  $a3, $45, $0c,  $ad, $68, $0f,  $c6, $46, $0c,  $f1, $45, $0a
  .byte $18  ,  $15, $8c, $0c,  $2d, $9c, $0d,  $32, $89, $0d,  $34, $8b, $0a,  $41, $77, $0f,  $43, $ae, $0f,  $4b, $24, $07,  $54, $23, $04,  $56, $57, $0c,  $5a, $9d, $0e,  $5b, $9a, $0e,  $63, $36, $09,  $8e, $46, $06,  $a0, $8b, $09,  $b2, $8c, $0a,  $bb, $56, $0b,  $c8, $ab, $0d,  $d1, $68, $0c,  $e1, $78, $0c,  $e3, $35, $08,  $e4, $ae, $08,  $e8, $8c, $0e,  $f4, $8c, $0d,  $fb, $9d, $0d
  .byte $17  ,  $17, $ce, $0f,  $1f, $bf, $0f,  $25, $87, $0f,  $27, $cf, $0f,  $29, $ae, $0d,  $2a, $54, $0a,  $2e, $76, $0d,  $37, $76, $0e,  $39, $88, $0f,  $3d, $98, $0f,  $3e, $65, $0a,  $4c, $65, $0b,  $4f, $46, $0d,  $70, $66, $0c,  $71, $77, $0e,  $77, $7a, $0d,  $88, $7a, $0c,  $8b, $56, $0f,  $95, $45, $0d,  $a2, $9b, $0c,  $c0, $ae, $0c,  $d0, $87, $0c,  $d7, $44, $09
  .byte $13  ,  $18, $7b, $0f,  $22, $7b, $0e,  $2f, $8b, $0e,  $32, $69, $0d,  $35, $8b, $0c,  $40, $69, $0b,  $56, $42, $02,  $5b, $69, $07,  $63, $52, $04,  $79, $7b, $0d,  $8e, $33, $01,  $93, $52, $03,  $b2, $7a, $0b,  $bb, $9d, $0c,  $c8, $79, $0b,  $d1, $a9, $0a,  $e1, $68, $03,  $e3, $8c, $06,  $e4, $79, $05
  .byte $2c  ,  $0c, $7a, $0a,  $17, $69, $09,  $1f, $7b, $0c,  $24, $7a, $09,  $25, $10, $01,  $27, $79, $04,  $29, $8c, $0f,  $2a, $7b, $0b,  $2e, $65, $06,  $31, $75, $05,  $37, $7a, $08,  $39, $7a, $07,  $3d, $99, $0b,  $3e, $68, $04,  $41, $8a, $0a,  $45, $8b, $0b,  $4b, $79, $0a,  $4c, $8a, $0b,  $4d, $24, $02,  $4f, $13, $00,  $54, $23, $01,  $62, $99, $09,  $6f, $35, $03,  $70, $34, $03,  $71, $13, $01,  $76, $88, $08,  $83, $aa, $0a,  $8b, $ad, $0a,  $95, $99, $0a,  $97, $22, $03,  $a3, $88, $09,  $ad, $aa, $09,  $b1, $77, $08,  $c0, $44, $03,  $c1, $ba, $0b,  $c6, $ad, $0b,  $d0, $9c, $0b,  $d4, $ad, $0c,  $d7, $9d, $0f,  $db, $8b, $0d,  $dc, $9c, $0a,  $ef, $55, $03,  $f1, $aa, $08,  $fc, $25, $01
  .byte $19  ,  $15, $25, $02,  $18, $47, $04,  $22, $54, $05,  $2b, $11, $02,  $2d, $89, $0a,  $32, $44, $02,  $56, $43, $03,  $57, $65, $05,  $5a, $24, $00,  $5b, $31, $02,  $63, $54, $04,  $6e, $35, $01,  $72, $35, $04,  $79, $7a, $05,  $87, $9b, $06,  $8e, $8a, $05,  $93, $47, $03,  $a1, $58, $03,  $a2, $36, $02,  $c8, $47, $02,  $e1, $8c, $07,  $e8, $58, $04,  $ed, $57, $02,  $ee, $9c, $06,  $f4, $ac, $07
  .byte $04  ,  $0a, $58, $05,  $0c, $64, $05,  $17, $14, $00,  $1e, $69, $06
  .byte $04  ,  $15, $68, $03,  $18, $cb, $0c,  $1f, $99, $07,  $24, $98, $08
  .byte $0c  ,  $0a, $be, $0f,  $17, $bd, $0f,  $25, $be, $0e,  $27, $bd, $0e,  $29, $9d, $0e,  $2a, $9d, $0b,  $2f, $9c, $0d,  $31, $cc, $0a,  $33, $ac, $0c,  $35, $9e, $0f,  $37, $ce, $0e,  $38, $46, $05
  .byte $0d  ,  $1e, $cf, $0f,  $1f, $57, $0a,  $2b, $ce, $0f,  $40, $56, $09,  $45, $ef, $0f,  $4b, $de, $0f,  $5a, $47, $08,  $5b, $9b, $0d,  $77, $67, $0a,  $88, $9b, $0e,  $97, $8a, $0c,  $b2, $ab, $0d,  $db, $78, $0b
  .byte $0e  ,  $18, $ed, $0f,  $24, $dd, $0f,  $2a, $cc, $0e,  $31, $ed, $0e,  $34, $dc, $0f,  $35, $cc, $0f,  $43, $fe, $0f,  $6e, $ee, $0f,  $bb, $df, $0f,  $f1, $79, $0a,  $f4, $ab, $0e,  $f5, $58, $05,  $fb, $bc, $0f,  $fc, $66, $08
  .byte $12  ,  $06, $fd, $0f,  $0a, $fe, $0e,  $0c, $bc, $0e,  $15, $9b, $0c,  $1e, $9a, $0c,  $1f, $dc, $0e,  $22, $cd, $0e,  $29, $bc, $0d,  $2e, $ab, $0c,  $2f, $bb, $0d,  $32, $78, $09,  $36, $cd, $0f,  $40, $ac, $0d,  $4a, $aa, $0c,  $4e, $bd, $0d,  $4f, $67, $08,  $54, $68, $08,  $55, $79, $09
  .byte $02  ,  $01, $aa, $0d,  $03, $bb, $0e
  .byte $00
  .byte $04  ,  $02, $cd, $0b,  $05, $89, $0b,  $06, $df, $0e,  $07, $ac, $0e
  .byte $0d  ,  $01, $89, $07,  $08, $cf, $0e,  $0a, $be, $0f,  $13, $78, $06,  $16, $67, $05,  $18, $cf, $0d,  $19, $ab, $08,  $1b, $8b, $08,  $1c, $8b, $0a,  $1d, $9c, $0d,  $20, $9a, $0d,  $23, $be, $0c,  $26, $be, $0d
  .byte $0a  ,  $03, $88, $07,  $05, $23, $01,  $1f, $bf, $0a,  $2a, $66, $06,  $2c, $99, $08,  $2f, $55, $05,  $31, $8a, $06,  $32, $8b, $07,  $34, $ac, $08,  $35, $9b, $07
  .byte $04  ,  $06, $55, $04,  $07, $44, $02,  $08, $35, $01,  $09, $ae, $0a
  .byte $10  ,  $0a, $8b, $0f,  $0c, $ad, $0f,  $17, $9c, $0f,  $18, $8c, $0f,  $1e, $7a, $0e,  $1f, $8b, $0e,  $20, $9c, $0c,  $22, $9c, $0e,  $23, $8b, $0d,  $24, $44, $04,  $25, $13, $00,  $26, $ac, $07,  $27, $8b, $0b,  $29, $df, $0a,  $2b, $79, $0c,  $2d, $8a, $0d
  .byte $06  ,  $09, $99, $07,  $2e, $77, $05,  $33, $76, $05,  $36, $88, $06,  $37, $aa, $08,  $38, $33, $01
  .byte $0c  ,  $0a, $87, $06,  $0c, $22, $03,  $15, $65, $04,  $17, $98, $07,  $18, $a9, $08,  $1c, $56, $02,  $1d, $ce, $09,  $1e, $bf, $0a,  $1f, $76, $07,  $20, $9d, $07,  $22, $54, $03,  $23, $ae, $09
  .byte $09  ,  $27, $ff, $0d,  $29, $ff, $0e,  $2b, $ff, $0f,  $2d, $78, $04,  $3d, $9d, $08,  $40, $25, $01,  $41, $24, $00,  $43, $47, $04,  $44, $ad, $07
  .byte $1c  ,  $0c, $ac, $0f,  $17, $9c, $0f,  $18, $7a, $0a,  $1d, $7a, $0d,  $1e, $9c, $0c,  $22, $63, $05,  $23, $53, $05,  $4a, $64, $05,  $4b, $79, $0b,  $4c, $ac, $0c,  $4e, $54, $05,  $4f, $8b, $0a,  $54, $98, $08,  $5a, $9c, $0e,  $6e, $ac, $0e,  $77, $7a, $0c,  $7a, $ae, $08,  $97, $63, $04,  $a4, $8b, $0c,  $aa, $64, $06,  $b2, $cb, $0c,  $bb, $9a, $0b,  $be, $68, $03,  $bf, $46, $05,  $c1, $75, $06,  $c6, $53, $03,  $cc, $64, $04,  $d2, $7a, $08
  .byte $07  ,  $07, $86, $06,  $09, $a9, $09,  $0a, $ba, $0b,  $15, $dd, $0b,  $1c, $79, $04,  $1f, $52, $03,  $2d, $65, $06
  .byte $0b  ,  $0c, $10, $00,  $17, $22, $00,  $18, $97, $08,  $1d, $89, $0a,  $1e, $99, $0b,  $23, $44, $02,  $33, $99, $07,  $41, $69, $03,  $43, $21, $02,  $44, $13, $02,  $4b, $52, $04
  .byte $0a  ,  $07, $24, $00,  $15, $62, $04,  $2d, $74, $05,  $39, $46, $01,  $40, $02, $01,  $4c, $78, $09,  $4e, $56, $02,  $4f, $dc, $0d,  $50, $a9, $0b,  $55, $bb, $09
  .byte $10  ,  $1c, $bf, $0f,  $1d, $ae, $0f,  $1f, $be, $0e,  $41, $cf, $0f,  $5a, $be, $0f,  $5b, $ad, $0e,  $69, $ae, $0e,  $6e, $ce, $0f,  $77, $ce, $0e,  $7a, $be, $0d,  $88, $9c, $0c,  $8e, $be, $0c,  $a0, $ad, $0b,  $a4, $ce, $09,  $aa, $7a, $07,  $bf, $69, $06
  .byte $06  ,  $03, $df, $0f,  $07, $df, $0e,  $08, $cf, $0e,  $09, $cf, $0d,  $0a, $de, $0a,  $0c, $df, $0a
  .byte $01  ,  $15, $cd, $0e
  .byte $03  ,  $03, $bd, $0d,  $07, $bd, $0e,  $08, $bd, $0f
  .byte $18  ,  $06, $7a, $0f,  $09, $7b, $0f,  $0a, $7a, $0e,  $0c, $8b, $0f,  $15, $79, $0e,  $17, $8a, $0c,  $18, $68, $0c,  $1a, $8b, $0c,  $1e, $79, $0b,  $20, $8c, $0f,  $22, $8b, $0d,  $23, $9b, $0d,  $24, $69, $0b,  $25, $7a, $0c,  $26, $9c, $0f,  $27, $9c, $0d,  $28, $68, $0a,  $29, $9c, $0e,  $2a, $ad, $0f,  $2b, $79, $09,  $2c, $57, $08,  $2d, $ac, $0c,  $2e, $79, $0d,  $2f, $68, $09
  .byte $0a  ,  $37, $ab, $0d,  $38, $ac, $0f,  $39, $9a, $0c,  $3a, $ac, $0d,  $3b, $9b, $0c,  $3c, $ac, $0e,  $3d, $9b, $0b,  $40, $9d, $0d,  $43, $88, $07,  $44, $cd, $09
  .byte $04  ,  $06, $8b, $0b,  $09, $8a, $0a,  $0c, $8b, $0e,  $15, $47, $04
  .byte $00
  .byte $07  ,  $05, $ff, $0f,  $06, $ef, $0e,  $07, $ff, $0e,  $08, $df, $0f,  $09, $de, $0f,  $0a, $df, $0e,  $0c, $df, $0a
  .byte $00
  .byte $00
  .byte $01  ,  $03, $44, $02
  .byte $00
  .byte $00
  .byte $2f  ,  $08, $ff, $0c,  $09, $ff, $0d,  $0a, $be, $07,  $15, $66, $06,  $17, $56, $05,  $18, $bf, $09,  $1a, $ae, $07,  $1b, $9d, $08,  $1c, $ef, $0b,  $1d, $44, $04,  $1e, $45, $04,  $1f, $cf, $08,  $20, $55, $05,  $22, $ae, $08,  $23, $55, $04,  $24, $bf, $08,  $25, $24, $00,  $26, $be, $08,  $27, $cf, $09,  $28, $9d, $07,  $29, $ad, $07,  $2a, $54, $03,  $2b, $22, $00,  $2c, $df, $09,  $2d, $ac, $07,  $2e, $65, $04,  $2f, $32, $01,  $37, $14, $00,  $38, $bd, $08,  $39, $44, $05,  $3a, $ed, $0e,  $3b, $35, $01,  $3c, $13, $00,  $3d, $ee, $0c,  $40, $77, $07,  $41, $33, $01,  $44, $23, $01,  $4a, $21, $00,  $4b, $99, $08,  $4c, $77, $05,  $4d, $aa, $08,  $4e, $66, $05,  $4f, $43, $02,  $50, $de, $0a,  $54, $ee, $0f,  $55, $10, $00,  $5a, $a9, $09
  .byte $04  ,  $21, $dc, $0d,  $32, $98, $08,  $5b, $dd, $0b,  $68, $cc, $0a
  .byte $04  ,  $37, $8b, $07,  $39, $9c, $09,  $69, $11, $02,  $6e, $cd, $09
  .byte $02  ,  $2e, $bb, $09,  $71, $ed, $0d
  .byte $0c  ,  $39, $cf, $0c,  $68, $af, $0b,  $69, $df, $0e,  $6e, $ae, $0b,  $72, $bf, $0b,  $77, $cf, $0d,  $7a, $ae, $0a,  $87, $bf, $0a,  $88, $25, $01,  $8b, $ab, $07,  $8e, $ae, $09,  $97, $ba, $0a
  .byte $01  ,  $21, $cf, $0e
  .byte $08  ,  $68, $ef, $0a,  $6e, $36, $01,  $71, $33, $04,  $72, $dc, $0d,  $7a, $9b, $06,  $87, $ba, $0b,  $8b, $99, $06,  $8e, $24, $02
  .byte $02  ,  $21, $13, $01,  $2e, $ab, $07
  .byte $01  ,  $32, $cc, $0a
  .byte $1d  ,  $2e, $be, $0f,  $5a, $bf, $0f,  $68, $be, $0e,  $72, $bf, $0e,  $87, $cf, $0f,  $88, $ae, $0c,  $8b, $ce, $0f,  $8e, $ae, $0d,  $97, $ce, $0e,  $9f, $df, $0f,  $a1, $9b, $0b,  $aa, $ae, $0b,  $ae, $cf, $0e,  $b2, $ae, $09,  $b4, $ad, $0a,  $b5, $bd, $0d,  $bb, $8b, $09,  $bf, $be, $0d,  $c1, $14, $00,  $c2, $8b, $0b,  $c5, $ac, $0d,  $c6, $35, $00,  $c8, $44, $05,  $ca, $9c, $0c,  $cc, $67, $03,  $cf, $be, $0c,  $d0, $bf, $0b,  $d1, $bb, $09,  $d2, $ae, $0a
  .byte $0e  ,  $21, $57, $09,  $93, $02, $03,  $b8, $69, $0b,  $d4, $9c, $0e,  $d7, $de, $0f,  $db, $9a, $0d,  $dc, $8a, $0c,  $e1, $67, $0a,  $e7, $9a, $0c,  $ed, $8a, $0b,  $f2, $7a, $0b,  $f5, $9b, $0c,  $fa, $79, $0b,  $fc, $cd, $0f
  .byte $15  ,  $2a, $13, $08,  $2e, $23, $08,  $36, $12, $07,  $37, $46, $0b,  $5a, $02, $06,  $65, $56, $0b,  $6e, $79, $0d,  $72, $23, $07,  $88, $01, $05,  $8e, $89, $0e,  $99, $00, $04,  $aa, $57, $0b,  $ae, $46, $0a,  $b2, $8a, $0e,  $c1, $57, $0c,  $ca, $02, $05,  $d0, $9a, $0f,  $d2, $34, $06,  $e0, $35, $0a,  $e5, $68, $0b,  $eb, $67, $0c
  .byte $1d  ,  $21, $67, $09,  $3a, $77, $09,  $3d, $8a, $05,  $68, $69, $05,  $69, $47, $03,  $77, $7a, $06,  $87, $54, $03,  $97, $8b, $07,  $9f, $56, $09,  $a0, $78, $0b,  $a1, $89, $0c,  $b5, $89, $0b,  $b8, $35, $06,  $bb, $45, $08,  $bf, $23, $04,  $c2, $44, $06,  $c5, $45, $07,  $cc, $33, $05,  $cf, $99, $0b,  $d4, $56, $08,  $d8, $bb, $0d,  $dc, $56, $07,  $e8, $78, $09,  $ea, $34, $05,  $ed, $89, $0a,  $f0, $bb, $0c,  $f2, $45, $06,  $f5, $67, $08,  $fa, $9a, $0b
  .byte $0a  ,  $2a, $25, $00,  $2e, $36, $01,  $33, $67, $03,  $36, $87, $07,  $37, $88, $06,  $39, $24, $02,  $5a, $ee, $0c,  $65, $ed, $0e,  $6e, $bc, $0d,  $72, $47, $02
  .byte $09  ,  $21, $cf, $0e,  $3a, $df, $0e,  $3d, $df, $0f,  $4c, $cf, $0d,  $54, $cf, $0c,  $71, $58, $03,  $88, $99, $07,  $8b, $58, $04,  $8e, $01, $01
  .byte $20  ,  $36, $ad, $0d,  $50, $7a, $0b,  $5b, $ce, $0f,  $72, $57, $08,  $93, $8a, $09,  $97, $ad, $0b,  $99, $58, $08,  $9f, $8a, $0b,  $a0, $9b, $0c,  $aa, $bd, $0d,  $ae, $79, $0b,  $b2, $be, $0b,  $ba, $bd, $0e,  $bb, $9c, $09,  $bf, $77, $05,  $c1, $ac, $0b,  $c2, $ce, $0e,  $c5, $ac, $0d,  $c6, $98, $09,  $ca, $dc, $0d,  $cc, $ee, $0f,  $cf, $79, $0c,  $d0, $46, $07,  $d2, $68, $09,  $d3, $ab, $0c,  $d8, $ac, $0c,  $dc, $68, $0a,  $e0, $9b, $0d,  $e5, $ac, $0e,  $ea, $ac, $0f,  $eb, $9b, $0e,  $f2, $bc, $0e
  .byte $07  ,  $21, $56, $09,  $32, $34, $06,  $33, $34, $05,  $65, $56, $07,  $87, $8b, $07,  $8e, $23, $04,  $d5, $45, $06
  .byte $17  ,  $2a, $01, $01,  $2e, $45, $08,  $36, $69, $04,  $3a, $12, $02,  $4c, $57, $09,  $4d, $33, $04,  $50, $47, $02,  $69, $65, $04,  $72, $cc, $0a,  $93, $33, $05,  $97, $11, $03,  $99, $bc, $08,  $aa, $54, $03,  $b4, $87, $07,  $bb, $cc, $0f,  $c1, $de, $0a,  $c2, $12, $03,  $ca, $88, $0a,  $cf, $78, $0b,  $d0, $12, $04,  $d8, $34, $07,  $ea, $24, $06,  $eb, $23, $05
  .byte $09  ,  $21, $36, $01,  $3d, $47, $03,  $54, $aa, $08,  $5b, $ae, $09,  $9f, $98, $08,  $ae, $47, $04,  $b2, $58, $05,  $b8, $ad, $0a,  $ba, $79, $04
  .byte $05  ,  $2a, $69, $06,  $2e, $67, $03,  $32, $ed, $0e,  $33, $8a, $05,  $37, $57, $06
  .byte $0c  ,  $25, $88, $06,  $36, $76, $05,  $3a, $dc, $0d,  $4c, $fe, $0f,  $4d, $13, $01,  $65, $76, $07,  $69, $8a, $09,  $6e, $68, $07,  $8b, $79, $08,  $8e, $dd, $0b,  $91, $cb, $0b,  $93, $dc, $0c
  .byte $0c  ,  $37, $df, $0e,  $50, $cf, $0e,  $54, $cf, $0c,  $97, $cf, $0d,  $99, $58, $04,  $9f, $69, $04,  $a0, $57, $02,  $a1, $12, $02,  $ae, $ba, $0a,  $b2, $aa, $0b,  $b4, $cd, $09,  $b5, $cc, $0d
  .byte $05  ,  $2e, $24, $00,  $32, $47, $02,  $33, $9a, $06,  $36, $aa, $08,  $3a, $25, $01
  .byte $04  ,  $25, $8a, $05,  $37, $46, $01,  $4c, $87, $07,  $50, $58, $05
  .byte $08  ,  $33, $7a, $04,  $36, $69, $03,  $54, $67, $03,  $65, $98, $08,  $69, $9c, $09,  $88, $be, $0b,  $8e, $98, $07,  $91, $ef, $0a
  .byte $06  ,  $4c, $cf, $0e,  $50, $df, $0e,  $93, $14, $00,  $a0, $25, $00,  $a1, $dd, $0b,  $ae, $6a, $05
  .byte $04  ,  $2a, $87, $07,  $33, $aa, $08,  $36, $88, $06,  $54, $57, $02
  .byte $04  ,  $37, $7b, $06,  $4c, $ed, $0e,  $4f, $9a, $06,  $50, $35, $04
  .byte $03  ,  $33, $7a, $04,  $36, $58, $02,  $65, $43, $02
  .byte $07  ,  $25, $8b, $05,  $45, $6a, $04,  $50, $15, $00,  $69, $26, $01,  $6e, $99, $07,  $88, $98, $08,  $8b, $76, $05
  .byte $07  ,  $33, $35, $00,  $3d, $46, $01,  $4f, $68, $07,  $54, $67, $03,  $5a, $78, $04,  $72, $ef, $0f,  $8e, $8a, $05
  .byte $09  ,  $37, $7a, $04,  $50, $59, $04,  $69, $03, $00,  $6e, $aa, $08,  $88, $88, $06,  $8b, $76, $07,  $91, $47, $03,  $97, $12, $02,  $98, $ac, $0b
  .byte $28  ,  $36, $af, $0d,  $3d, $ae, $0e,  $4f, $af, $0f,  $54, $bf, $0d,  $5a, $af, $0e,  $8e, $bf, $0f,  $ae, $ae, $0b,  $b8, $be, $0d,  $ba, $ae, $0c,  $bb, $ad, $0c,  $be, $af, $0c,  $c2, $bf, $0e,  $c5, $ae, $0d,  $ca, $ae, $0f,  $cf, $9d, $0b,  $d0, $be, $0f,  $d1, $69, $08,  $d2, $ad, $0b,  $d3, $cf, $0d,  $d4, $be, $0c,  $d5, $bf, $0c,  $d7, $be, $0b,  $d8, $cf, $0c,  $db, $69, $06,  $dc, $25, $02,  $e0, $bf, $0b,  $e1, $9d, $09,  $e5, $ae, $0a,  $e7, $47, $01,  $e8, $bf, $0a,  $ea, $9c, $0a,  $eb, $8c, $08,  $ed, $54, $05,  $f1, $cc, $0a,  $f2, $dd, $0e,  $f4, $ba, $0b,  $f5, $a9, $0a,  $fa, $98, $08,  $fb, $65, $04,  $fc, $01, $01
  .byte $08  ,  $45, $8a, $05,  $4d, $68, $03,  $50, $46, $01,  $69, $36, $00,  $6c, $65, $06,  $6e, $9b, $0a,  $88, $00, $01,  $99, $22, $03
  .byte $0b  ,  $33, $df, $0e,  $36, $cf, $0e,  $3d, $03, $00,  $4f, $33, $04,  $54, $21, $02,  $5a, $02, $00,  $8e, $11, $02,  $a1, $dc, $0d,  $ae, $13, $01,  $b8, $fe, $0f,  $ba, $87, $08
  .byte $03  ,  $37, $6a, $04,  $4c, $78, $04,  $4d, $ba, $0a
  .byte $06  ,  $4f, $68, $03,  $54, $35, $00,  $69, $34, $00,  $6c, $9d, $06,  $6e, $87, $06,  $98, $57, $02
  .byte $08  ,  $4c, $58, $02,  $4d, $7b, $05,  $5b, $36, $00,  $87, $7a, $04,  $99, $59, $03,  $a2, $bc, $08,  $ae, $a9, $09,  $b8, $58, $04
  .byte $0c  ,  $25, $48, $02,  $33, $26, $00,  $36, $6a, $05,  $50, $15, $00,  $69, $36, $02,  $88, $ee, $0c,  $91, $ba, $0a,  $ba, $69, $03,  $bb, $8b, $07,  $be, $88, $06,  $c2, $43, $04,  $c5, $13, $01
  .byte $08  ,  $54, $46, $01,  $8e, $37, $01,  $99, $8c, $05,  $a1, $89, $05,  $a2, $99, $07,  $ca, $78, $04,  $cf, $98, $07,  $d0, $ae, $09
  .byte $07  ,  $36, $8b, $05,  $50, $00, $01,  $6e, $11, $02,  $87, $aa, $08,  $91, $33, $04,  $bf, $34, $00,  $c2, $35, $00
  .byte $05  ,  $1b, $7a, $04,  $39, $87, $08,  $3d, $dc, $0d,  $8e, $ab, $07,  $98, $76, $05
  .byte $08  ,  $33, $ef, $0a,  $50, $57, $02,  $6c, $79, $04,  $91, $ed, $0e,  $99, $45, $01,  $a1, $77, $05,  $a2, $56, $02,  $ae, $6a, $05
  .byte $04  ,  $25, $24, $02,  $37, $48, $03,  $39, $a9, $09,  $3d, $03, $00
  .byte $03  ,  $5b, $59, $03,  $69, $ac, $0b,  $87, $9b, $0a
  .byte $06  ,  $1b, $df, $0e,  $33, $cf, $0e,  $37, $6a, $04,  $39, $9d, $08,  $3a, $99, $07,  $3d, $37, $02
  .byte $09  ,  $4d, $bb, $09,  $6e, $36, $02,  $87, $aa, $08,  $91, $22, $03,  $98, $87, $06,  $99, $03, $00,  $ae, $33, $00,  $b4, $26, $01,  $c8, $ce, $0d
  .byte $07  ,  $33, $7b, $05,  $3a, $44, $05,  $3d, $87, $08,  $4c, $a9, $09,  $8e, $6a, $05,  $b8, $9a, $06,  $bf, $9b, $0a
  .byte $06  ,  $1b, $99, $07,  $5b, $cd, $09,  $69, $45, $01,  $6c, $76, $05,  $91, $34, $00,  $98, $37, $02
  .byte $0e  ,  $2a, $9d, $06,  $37, $58, $04,  $3a, $8c, $07,  $3d, $47, $03,  $45, $58, $05,  $4c, $8d, $07,  $77, $8a, $09,  $8b, $ad, $0a,  $8e, $bc, $08,  $99, $ce, $08,  $ae, $ac, $0b,  $b4, $dd, $0b,  $c6, $79, $08,  $ca, $8b, $08
  .byte $07  ,  $08, $7a, $06,  $0a, $9c, $09,  $1c, $ab, $07,  $1f, $13, $02,  $21, $24, $03,  $2c, $47, $05,  $2f, $dc, $0d
  .byte $29  ,  $32, $68, $0c,  $33, $57, $0b,  $36, $79, $0d,  $4a, $8a, $0e,  $50, $57, $0a,  $54, $79, $0c,  $55, $9b, $0d,  $56, $9b, $0e,  $57, $68, $0b,  $63, $79, $0b,  $65, $ce, $0f,  $69, $bd, $0f,  $6c, $8a, $0c,  $79, $ab, $0d,  $91, $bc, $0f,  $93, $89, $0b,  $98, $ab, $0e,  $9f, $78, $0a,  $a0, $df, $0f,  $a2, $8a, $0b,  $aa, $57, $09,  $ba, $9a, $0c,  $c2, $68, $0a,  $ca, $79, $0a,  $cf, $9b, $0c,  $d1, $de, $0f,  $d2, $89, $0a,  $d5, $cf, $0f,  $e0, $cf, $0e,  $e1, $67, $09,  $e5, $bb, $0d,  $e7, $ac, $0e,  $e8, $cd, $0f,  $ea, $df, $0e,  $eb, $9c, $0c,  $ed, $ab, $0c,  $ee, $ac, $0d,  $f5, $dd, $0f,  $f8, $bc, $0d,  $fb, $ce, $0e,  $fd, $68, $07
  .byte $0b  ,  $1c, $47, $08,  $24, $23, $04,  $2b, $25, $05,  $2c, $57, $08,  $3b, $56, $08,  $41, $69, $0a,  $58, $56, $09,  $7a, $35, $06,  $99, $34, $05,  $a8, $45, $06,  $b8, $8b, $08
  .byte $13  ,  $32, $25, $01,  $33, $35, $01,  $36, $9a, $06,  $37, $58, $08,  $3d, $14, $01,  $4c, $7a, $05,  $4f, $9e, $07,  $57, $ab, $07,  $6e, $58, $07,  $71, $68, $09,  $91, $68, $08,  $a9, $79, $09,  $d5, $8a, $0a,  $dc, $9b, $0b,  $e0, $9a, $0b,  $e5, $78, $09,  $eb, $ac, $0c,  $f4, $67, $08,  $fa, $35, $05
  .byte $11  ,  $0a, $47, $03,  $1c, $69, $04,  $2a, $58, $04,  $2b, $33, $04,  $2c, $58, $03,  $2f, $22, $03,  $3b, $66, $07,  $41, $44, $05,  $4a, $ba, $0b,  $50, $56, $07,  $54, $bd, $0c,  $55, $46, $05,  $56, $bd, $0d,  $58, $35, $04,  $63, $02, $01,  $65, $57, $06,  $69, $7a, $07
  .byte $0f  ,  $32, $8a, $0d,  $33, $9a, $0d,  $37, $bd, $0f,  $3d, $79, $0b,  $5a, $bc, $0f,  $6e, $bb, $0d,  $8e, $9b, $0d,  $99, $57, $0a,  $a0, $99, $0b,  $aa, $9b, $06,  $b8, $dd, $0a,  $d7, $bc, $0e,  $d8, $bd, $0e,  $db, $cc, $0e,  $fb, $57, $07
  .byte $05  ,  $03, $69, $06,  $09, $9c, $09,  $0a, $9e, $08,  $2a, $bf, $0a,  $2b, $cd, $0e
  .byte $06  ,  $24, $ff, $0d,  $2c, $47, $03,  $2e, $58, $04,  $2f, $bc, $08,  $32, $11, $02,  $33, $36, $03
  .byte $07  ,  $09, $36, $02,  $1c, $25, $01,  $2b, $35, $01,  $36, $44, $02,  $37, $33, $01,  $3b, $22, $00,  $3d, $cf, $0c
  .byte $04  ,  $24, $69, $04,  $2a, $cd, $0e,  $2c, $02, $00,  $2e, $66, $04
  .byte $07  ,  $1c, $ff, $0d,  $2b, $dc, $0d,  $32, $47, $03,  $33, $9c, $09,  $37, $24, $00,  $3a, $ed, $0e,  $3b, $25, $02
  .byte $02  ,  $18, $33, $01,  $24, $fe, $0f
  .byte $03  ,  $09, $bf, $09,  $2a, $35, $01,  $2b, $cc, $09
  .byte $04  ,  $32, $bf, $08,  $3b, $22, $00,  $3d, $dc, $0d,  $41, $9a, $06
  .byte $01  ,  $08, $66, $07
  .byte $05  ,  $03, $be, $07,  $0a, $89, $05,  $2a, $87, $07,  $2d, $54, $04,  $33, $ce, $08
  .byte $06  ,  $1f, $35, $01,  $21, $a9, $0a,  $45, $47, $04,  $4a, $65, $05,  $4c, $44, $05,  $4f, $ac, $07
  .byte $00
  .byte $01  ,  $03, $ed, $0d
  .byte $01  ,  $08, $79, $04
  .byte $01  ,  $0a, $98, $08
  .byte $02  ,  $08, $68, $03,  $21, $fe, $0e
  .byte $03  ,  $0a, $cb, $0b,  $2a, $57, $02,  $2b, $dc, $0c
  .byte $02  ,  $08, $ba, $0a,  $2d, $cb, $0c
  .byte $05  ,  $0a, $76, $06,  $21, $66, $07,  $33, $43, $04,  $37, $a9, $0a,  $4a, $79, $04
  .byte $05  ,  $2a, $24, $00,  $2d, $be, $07,  $45, $cc, $09,  $4c, $aa, $07,  $50, $99, $06
  .byte $08  ,  $33, $56, $07,  $4a, $65, $05,  $55, $87, $07,  $56, $98, $08,  $58, $cb, $0b,  $5a, $98, $09,  $63, $cb, $0c,  $65, $a9, $09
  .byte $01  ,  $25, $8a, $05
  .byte $04  ,  $21, $57, $06,  $33, $7a, $09,  $45, $54, $04,  $4c, $24, $02
  .byte $02  ,  $25, $cc, $09,  $2c, $ba, $0b
  .byte $03  ,  $33, $bb, $08,  $37, $89, $05,  $45, $aa, $07
  .byte $08  ,  $2c, $56, $07,  $50, $47, $03,  $5a, $54, $04,  $63, $ad, $0b,  $68, $46, $05,  $69, $02, $00,  $6c, $25, $01,  $6e, $8b, $09
  .byte $05  ,  $45, $bd, $0d,  $55, $a9, $08,  $71, $cb, $0c,  $79, $ad, $0c,  $7a, $46, $06
  .byte $04  ,  $50, $34, $05,  $58, $66, $07,  $65, $99, $06,  $8e, $aa, $07
  .byte $1e  ,  $37, $6a, $04,  $45, $7a, $04,  $55, $7b, $05,  $63, $6a, $05,  $68, $8b, $05,  $6c, $9c, $06,  $79, $58, $04,  $93, $8c, $05,  $98, $ba, $0b,  $99, $69, $04,  $9f, $69, $05,  $a0, $7a, $06,  $b6, $32, $03,  $ba, $22, $03,  $c2, $87, $08,  $c8, $98, $09,  $cf, $a9, $0a,  $d1, $43, $04,  $d3, $bf, $0a,  $d4, $65, $06,  $d7, $87, $07,  $d8, $cb, $0b,  $db, $43, $03,  $e1, $7a, $05,  $e7, $32, $02,  $e8, $a9, $09,  $ea, $10, $00,  $ed, $21, $01,  $f4, $cf, $0c,  $f5, $00, $01
  .byte $0c  ,  $1a, $47, $03,  $1b, $33, $04,  $21, $fe, $0e,  $25, $44, $05,  $2c, $55, $06,  $2d, $9d, $06,  $2e, $76, $07,  $2f, $11, $02,  $32, $21, $02,  $33, $54, $05,  $36, $47, $04,  $39, $10, $01
  .byte $1e  ,  $18, $00, $0f,  $41, $01, $0f,  $54, $02, $0f,  $57, $03, $0f,  $65, $01, $0e,  $69, $02, $0e,  $6e, $00, $0e,  $72, $00, $0d,  $87, $00, $0c,  $88, $01, $0d,  $8b, $02, $0d,  $8e, $04, $0f,  $91, $04, $0e,  $a1, $14, $0f,  $a2, $15, $0f,  $ae, $05, $0f,  $b4, $01, $0c,  $b7, $16, $0f,  $b8, $27, $0f,  $be, $01, $0b,  $bf, $47, $0f,  $c6, $38, $0f,  $d5, $02, $0c,  $dc, $03, $0e,  $e0, $56, $0f,  $eb, $25, $0f,  $ee, $05, $0e,  $f8, $57, $0f,  $fb, $02, $0b,  $fd, $48, $0f
  .byte $04  ,  $1a, $aa, $08,  $21, $ed, $0f,  $3c, $99, $07,  $90, $ee, $0c
  .byte $12  ,  $18, $63, $0f,  $3b, $64, $0f,  $41, $74, $0f,  $54, $a8, $0f,  $57, $53, $0f,  $65, $da, $0f,  $69, $43, $0f,  $6e, $ca, $0f,  $72, $32, $0e,  $87, $b9, $0f,  $88, $97, $0f,  $8b, $33, $0f,  $a1, $43, $0e,  $b4, $22, $0c,  $c6, $9b, $0c,  $d5, $32, $0d,  $dc, $33, $0b,  $ef, $32, $0c
  .byte $05  ,  $1a, $9f, $0f,  $2a, $9e, $0f,  $3c, $8e, $0f,  $4d, $af, $0f,  $c1, $af, $0e
  .byte $07  ,  $18, $7b, $06,  $2c, $ad, $0a,  $3b, $25, $02,  $41, $24, $03,  $50, $8a, $05,  $54, $58, $05,  $57, $36, $02
  .byte $04  ,  $1a, $bb, $09,  $2a, $69, $06,  $3c, $55, $06,  $4d, $9a, $0a
  .byte $05  ,  $1f, $47, $03,  $2c, $58, $03,  $36, $ef, $0f,  $3b, $cd, $0d,  $41, $13, $00
  .byte $02  ,  $1a, $59, $04,  $21, $9c, $09
  .byte $05  ,  $1b, $bb, $09,  $2a, $a9, $08,  $2d, $ed, $0f,  $3c, $fe, $0e,  $57, $aa, $08
  .byte $03  ,  $1a, $35, $01,  $21, $dd, $0b,  $41, $98, $07
  .byte $11  ,  $18, $ca, $0b,  $1b, $b9, $0a,  $2f, $db, $0c,  $57, $86, $07,  $65, $97, $08,  $69, $b9, $09,  $6e, $87, $06,  $72, $a8, $09,  $77, $ec, $0d,  $7a, $bf, $08,  $7e, $77, $05,  $87, $79, $04,  $88, $25, $02,  $8b, $55, $06,  $8e, $69, $06,  $91, $99, $07,  $a1, $cb, $0a
  .byte $07  ,  $1a, $47, $02,  $21, $36, $03,  $2a, $aa, $08,  $37, $55, $03,  $50, $89, $09,  $96, $cb, $0d,  $a2, $25, $01
  .byte $01  ,  $58, $ab, $0b
  .byte $07  ,  $21, $35, $01,  $2d, $8a, $05,  $2f, $dd, $0b,  $37, $ad, $0a,  $4d, $db, $0d,  $69, $11, $02,  $77, $7b, $06
  .byte $12  ,  $18, $43, $0f,  $1b, $ca, $0f,  $63, $a8, $0f,  $7a, $64, $0f,  $90, $53, $0e,  $91, $a8, $0e,  $96, $b9, $0f,  $a1, $44, $0f,  $a2, $ba, $0f,  $ae, $43, $0e,  $b7, $a9, $0f,  $b8, $43, $0d,  $c1, $86, $0f,  $c4, $75, $0f,  $e9, $53, $0f,  $ee, $ed, $0f,  $f1, $34, $0d,  $fd, $54, $0f
  .byte $06  ,  $03, $47, $04,  $2a, $6a, $05,  $2f, $34, $01,  $37, $9a, $0a,  $3c, $33, $04,  $4d, $36, $03
  .byte $0c  ,  $18, $bf, $0f,  $21, $97, $0f,  $41, $ec, $0f,  $57, $58, $0a,  $5b, $ae, $0e,  $65, $db, $0f,  $6e, $ae, $0f,  $72, $8a, $0a,  $7e, $25, $0b,  $90, $66, $08,  $91, $87, $0e,  $e9, $bd, $0e
  .byte $04  ,  $03, $cd, $09,  $2f, $59, $04,  $54, $8c, $07,  $e2, $66, $07
  .byte $05  ,  $18, $57, $03,  $1b, $ed, $0d,  $21, $ce, $0d,  $41, $cd, $0e,  $57, $bc, $0d
  .byte $05  ,  $03, $58, $05,  $25, $34, $01,  $4d, $9c, $09,  $5b, $7a, $07,  $63, $bb, $0d
  .byte $02  ,  $18, $44, $05,  $54, $48, $03
  .byte $01  ,  $4d, $57, $03
  .byte $1b  ,  $1b, $58, $01,  $65, $69, $02,  $6e, $59, $02,  $72, $48, $01,  $7a, $48, $02,  $7e, $65, $08,  $88, $47, $01,  $8e, $43, $05,  $91, $10, $03,  $96, $58, $02,  $a1, $21, $05,  $a2, $57, $02,  $a9, $21, $04,  $ae, $68, $03,  $b4, $10, $02,  $b7, $43, $06,  $b8, $76, $0a,  $bf, $54, $06,  $c1, $54, $09,  $c4, $65, $09,  $d5, $21, $06,  $e9, $69, $03,  $eb, $36, $01,  $ef, $cb, $0d,  $f1, $32, $04,  $fa, $6a, $04,  $fd, $46, $01
  .byte $24  ,  $03, $8c, $0c,  $08, $9c, $0c,  $09, $8c, $0a,  $0a, $9c, $0a,  $0c, $9d, $0c,  $1c, $8b, $0a,  $1f, $43, $08,  $22, $8c, $09,  $25, $9c, $0d,  $26, $9d, $0b,  $27, $7a, $09,  $29, $8b, $0c,  $2b, $ae, $0f,  $2d, $ad, $0c,  $2f, $9b, $0b,  $38, $8b, $0d,  $3d, $ad, $0d,  $3f, $8b, $0b,  $4a, $8c, $08,  $4f, $9d, $0a,  $52, $65, $0a,  $53, $8c, $0b,  $54, $9c, $0e,  $56, $43, $09,  $66, $32, $06,  $6c, $53, $05,  $93, $7a, $08,  $aa, $97, $0a,  $d3, $8b, $09,  $d7, $ab, $0e,  $d8, $99, $0c,  $db, $ab, $0f,  $e8, $66, $09,  $ea, $88, $0b,  $ed, $a9, $0e,  $f3, $98, $0c
  .byte $08  ,  $19, $24, $0d,  $47, $35, $0d,  $5a, $25, $0d,  $a4, $13, $0c,  $bc, $24, $0c,  $c5, $23, $0c,  $ce, $46, $0e,  $e7, $be, $0e
  .byte $0c  ,  $03, $35, $0e,  $1c, $46, $0f,  $27, $43, $07,  $29, $35, $0c,  $4a, $32, $08,  $53, $7a, $0c,  $93, $86, $08,  $9a, $75, $06,  $bd, $86, $07,  $d0, $77, $06,  $d3, $45, $0e,  $ee, $32, $07
  .byte $0c  ,  $09, $24, $0f,  $22, $34, $0f,  $44, $23, $0e,  $51, $35, $0f,  $5f, $ed, $0f,  $aa, $86, $0a,  $b0, $13, $00,  $c0, $64, $07,  $c5, $42, $06,  $d5, $24, $01,  $e6, $97, $0b,  $f7, $42, $04
  .byte $1d  ,  $03, $ec, $0f,  $08, $db, $0f,  $0a, $ca, $0e,  $0c, $a9, $0f,  $19, $20, $03,  $1f, $ca, $0f,  $25, $54, $04,  $26, $8c, $08,  $29, $b9, $0d,  $2b, $b9, $0c,  $2d, $42, $05,  $38, $75, $08,  $3a, $22, $01,  $3d, $68, $02,  $3f, $59, $03,  $43, $37, $01,  $47, $44, $03,  $4a, $75, $0a,  $53, $9a, $0d,  $54, $a9, $0d,  $56, $98, $0b,  $5a, $89, $0c,  $93, $9b, $0f,  $9a, $99, $0d,  $a4, $24, $0a,  $bc, $00, $03,  $bd, $89, $0d,  $cd, $98, $0d,  $ce, $88, $0c
  .byte $14  ,  $09, $43, $08,  $1c, $7b, $07,  $22, $ed, $0e,  $23, $a8, $0e,  $44, $a8, $0d,  $4b, $8a, $05,  $4c, $97, $0a,  $4d, $9b, $0e,  $4e, $aa, $0f,  $51, $79, $0c,  $67, $66, $0a,  $6c, $76, $0b,  $74, $99, $0e,  $d0, $87, $0b,  $d3, $12, $06,  $d5, $55, $0a,  $dd, $23, $08,  $e7, $9a, $0f,  $ee, $97, $0c,  $f7, $78, $0c
  .byte $0b  ,  $25, $24, $02,  $2b, $ef, $0c,  $3a, $36, $02,  $47, $ae, $09,  $4f, $31, $05,  $93, $9c, $0a,  $a1, $34, $02,  $a4, $8a, $0c,  $ad, $78, $0b,  $bc, $68, $0a,  $dc, $66, $0b
  .byte $13  ,  $09, $36, $03,  $0f, $fc, $0f,  $23, $88, $07,  $26, $ae, $08,  $2d, $23, $01,  $2f, $46, $03,  $3d, $ac, $07,  $43, $44, $03,  $4d, $64, $06,  $51, $ad, $0c,  $60, $ab, $08,  $6b, $8b, $09,  $aa, $aa, $09,  $b0, $54, $0a,  $c1, $77, $0b,  $c5, $87, $0c,  $c6, $88, $0d,  $f6, $99, $0f,  $fd, $34, $09
  .byte $13  ,  $08, $ff, $0d,  $0a, $bf, $0a,  $0c, $24, $01,  $19, $9b, $0b,  $1f, $12, $00,  $27, $86, $08,  $29, $cd, $0a,  $38, $cc, $0a,  $3a, $75, $07,  $4a, $9a, $0e,  $4c, $65, $0b,  $4f, $12, $07,  $66, $13, $08,  $79, $76, $0c,  $91, $56, $09,  $a9, $11, $03,  $ad, $77, $0c,  $bc, $67, $0b,  $e6, $cd, $0f
  .byte $12  ,  $09, $db, $0f,  $0f, $df, $0a,  $16, $68, $05,  $1c, $9c, $06,  $26, $ca, $0f,  $2d, $9b, $0c,  $3d, $56, $04,  $43, $9a, $07,  $44, $53, $05,  $4b, $8c, $08,  $51, $ad, $07,  $60, $db, $0e,  $a1, $97, $0a,  $aa, $10, $03,  $b0, $22, $07,  $c5, $89, $0e,  $ee, $56, $0a,  $fb, $88, $0e
  .byte $0c  ,  $08, $13, $00,  $0c, $ca, $0e,  $38, $b9, $0f,  $39, $7b, $07,  $3e, $68, $02,  $4c, $77, $06,  $52, $55, $04,  $66, $86, $0a,  $6f, $a8, $0b,  $73, $42, $04,  $79, $23, $01,  $cd, $86, $09
  .byte $0d  ,  $0f, $ff, $0d,  $1c, $98, $0d,  $23, $54, $09,  $27, $65, $0a,  $2d, $97, $0b,  $2f, $67, $05,  $44, $68, $04,  $51, $45, $03,  $61, $87, $0c,  $7d, $86, $0b,  $80, $00, $03,  $d3, $33, $08,  $ee, $67, $0a
  .byte $0b  ,  $08, $a8, $0e,  $3e, $57, $04,  $4c, $58, $04,  $4d, $43, $07,  $52, $b9, $0c,  $60, $89, $06,  $6f, $a9, $0f,  $a4, $a8, $0f,  $b0, $75, $0a,  $be, $65, $0b,  $fd, $10, $01
  .byte $11  ,  $0c, $8c, $05,  $1f, $75, $08,  $25, $76, $0c,  $29, $97, $0c,  $2d, $fc, $0f,  $3a, $31, $05,  $43, $42, $05,  $4b, $86, $0c,  $4f, $bf, $09,  $51, $42, $06,  $73, $db, $0e,  $79, $97, $0e,  $91, $a8, $0d,  $bc, $21, $04,  $d3, $58, $05,  $dd, $8a, $0a,  $ee, $79, $09
  .byte $04  ,  $0a, $45, $03,  $52, $44, $0a,  $66, $30, $03,  $a4, $33, $09
  .byte $06  ,  $2d, $54, $0a,  $3d, $43, $09,  $4f, $32, $08,  $d3, $21, $05,  $dd, $64, $0a,  $ee, $33, $08
  .byte $07  ,  $0c, $42, $0a,  $0f, $ef, $0b,  $47, $fc, $0f,  $52, $42, $08,  $60, $53, $0a,  $66, $ca, $0e,  $a4, $42, $07
  .byte $06  ,  $1f, $10, $05,  $3e, $32, $07,  $7d, $ca, $0d,  $a5, $42, $09,  $b0, $bf, $0a,  $d3, $9b, $0c
  .byte $0a  ,  $08, $8a, $0c,  $0c, $b9, $0d,  $0f, $46, $04,  $47, $21, $05,  $60, $34, $02,  $66, $21, $07,  $79, $77, $06,  $91, $ad, $0c,  $a1, $ee, $0d,  $cd, $56, $09
  .byte $09  ,  $0a, $ff, $0d,  $1f, $fc, $0f,  $29, $a8, $0e,  $43, $9b, $0d,  $4f, $12, $06,  $52, $6a, $06,  $a4, $97, $0e,  $a5, $8a, $0d,  $fc, $67, $0a
  .byte $0b  ,  $08, $86, $09,  $0c, $75, $08,  $0f, $ca, $0e,  $2d, $97, $0c,  $47, $75, $0a,  $4b, $79, $0d,  $60, $98, $0e,  $66, $a8, $0f,  $73, $86, $0d,  $91, $cb, $0f,  $c9, $aa, $0e
  .byte $0e  ,  $29, $eb, $0f,  $2b, $da, $0f,  $3e, $8a, $0c,  $43, $01, $01,  $44, $42, $05,  $4c, $db, $0e,  $4f, $ca, $0c,  $52, $a8, $0d,  $7d, $21, $05,  $a4, $56, $0a,  $a5, $11, $05,  $b0, $64, $08,  $dd, $78, $0d,  $ee, $56, $08
  .byte $05  ,  $2d, $ef, $0c,  $3a, $32, $07,  $3d, $64, $06,  $4b, $97, $0e,  $79, $b9, $0d
  .byte $08  ,  $08, $57, $05,  $0c, $97, $0a,  $1b, $86, $08,  $3e, $97, $0c,  $4c, $75, $07,  $4f, $00, $05,  $7d, $00, $04,  $b0, $97, $0d
  .byte $05  ,  $39, $21, $08,  $51, $31, $08,  $6b, $32, $08,  $a5, $43, $09,  $c0, $43, $0a
  .byte $0c  ,  $08, $10, $05,  $0a, $34, $0b,  $1b, $97, $0f,  $1f, $64, $0c,  $29, $44, $0b,  $2b, $20, $08,  $2d, $42, $09,  $4c, $75, $0d,  $a1, $20, $07,  $c2, $86, $0f,  $cd, $33, $09,  $d3, $86, $0e
  .byte $04  ,  $39, $11, $05,  $51, $20, $06,  $7f, $9b, $0c,  $ab, $10, $06
  .byte $08  ,  $08, $14, $00,  $0a, $ff, $0b,  $0f, $df, $09,  $2b, $ef, $0c,  $47, $ff, $0c,  $52, $24, $00,  $79, $14, $01,  $c0, $13, $00
  .byte $6f  ,  $03, $67, $04,  $09, $56, $02,  $0c, $aa, $08,  $19, $36, $03,  $1b, $99, $07,  $1c, $66, $04,  $1f, $25, $03,  $21, $af, $07,  $22, $45, $02,  $23, $35, $02,  $24, $bf, $07,  $25, $02, $01,  $26, $13, $01,  $27, $03, $00,  $29, $25, $01,  $2d, $46, $03,  $32, $12, $00,  $38, $9e, $08,  $39, $24, $03,  $3a, $ae, $07,  $3d, $bf, $08,  $3e, $af, $08,  $3f, $57, $04,  $41, $cf, $08,  $44, $25, $02,  $4a, $ef, $0a,  $4b, $34, $01,  $4c, $8d, $05,  $4d, $6b, $03,  $4e, $9e, $06,  $4f, $47, $04,  $51, $12, $01,  $53, $02, $00,  $54, $46, $04,  $56, $13, $02,  $57, $57, $06,  $5a, $11, $00,  $5f, $22, $01,  $60, $23, $01,  $61, $35, $04,  $63, $77, $06,  $65, $24, $02,  $66, $24, $01,  $67, $36, $02,  $6b, $46, $05,  $6c, $79, $08,  $6e, $68, $07,  $6f, $57, $05,  $71, $47, $03,  $72, $58, $04,  $73, $6b, $05,  $74, $7c, $05,  $75, $35, $01,  $7a, $46, $02,  $7d, $59, $04,  $7e, $8c, $05,  $7f, $8d, $06,  $80, $9d, $06,  $88, $9e, $07,  $8e, $ae, $08,  $90, $56, $04,  $91, $44, $03,  $93, $8c, $07,  $98, $9d, $08,  $9a, $be, $08,  $a1, $ae, $09,  $a2, $bf, $09,  $a4, $45, $03,  $a5, $35, $03,  $a8, $55, $04,  $a9, $cf, $09,  $aa, $34, $02,  $ab, $58, $05,  $ad, $df, $0a,  $ae, $33, $02,  $b0, $68, $04,  $b4, $ad, $07,  $b5, $57, $03,  $b7, $69, $06,  $b8, $78, $05,  $bc, $68, $06,  $bd, $23, $00,  $be, $8a, $05,  $bf, $9b, $06,  $c1, $ff, $0d,  $c2, $ef, $0b,  $c4, $7c, $06,  $c5, $ab, $08,  $c6, $bc, $09,  $c9, $7b, $04,  $ca, $bd, $08,  $cc, $ce, $09,  $cd, $aa, $09,  $ce, $9c, $06,  $d0, $bf, $0a,  $d2, $6b, $04,  $d3, $cd, $0a,  $d4, $99, $08,  $d5, $de, $0b,  $d7, $88, $07,  $d8, $bb, $0a,  $db, $ee, $0d,  $dc, $de, $0a,  $dd, $66, $05,  $e0, $9a, $07,  $e5, $25, $00,  $e6, $cc, $0a,  $e7, $ee, $0c,  $e8, $cc, $0b,  $ea, $bb, $09,  $ed, $77, $05
  .byte $0b  ,  $2e, $8d, $07,  $ee, $9c, $05,  $ef, $df, $0d,  $f0, $9f, $08,  $f1, $56, $03,  $f2, $be, $07,  $f3, $7c, $04,  $f4, $9c, $09,  $f6, $be, $0b,  $f7, $88, $06,  $f8, $8a, $09
  .byte $05  ,  $0c, $65, $06,  $1b, $47, $05,  $1c, $ac, $07,  $1f, $21, $02,  $5b, $26, $02
  .byte $07  ,  $e0, $44, $02,  $ee, $7a, $07,  $f0, $cf, $0c,  $f3, $67, $03,  $f4, $99, $07,  $f6, $9f, $07,  $f7, $ac, $0b
  .byte $06  ,  $09, $ef, $09,  $1f, $7c, $04,  $5b, $bb, $0c,  $fb, $76, $07,  $fc, $9a, $07,  $fd, $bd, $0c
  .byte $09  ,  $03, $48, $02,  $1b, $10, $01,  $96, $47, $01,  $b8, $66, $04,  $bd, $dd, $0b,  $c4, $68, $03,  $c5, $ad, $06,  $d0, $8b, $08,  $e0, $ad, $0a
  
  
  ; FIXME: added another 0 here!  
  .byte $00

    .include utils/x16.s
    .include utils/utils.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include tests/vera_sd_tests.s
