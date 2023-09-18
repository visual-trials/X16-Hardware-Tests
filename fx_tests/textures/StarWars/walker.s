; == Very crude PoC of 320x136px video playback using AUTOTX ==

; To build: ./vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\textures\StarWars\walker.s -wdc02 -D CREATE_PRG -o .\fx_tests\textures\StarWars\WALKER.PRG
; To run (from StarWars dir) : C:\x16emu_win-r44\x16emu.exe -prg .\WALKER.PRG -run -sdcard .\walker_sdcard.img

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

SECTOR_NUMBER             = $37



; === RAM addresses ===

COPY_SECTOR_CODE               = $7800

; FIXME: we are NOT USING THESE! (but they are required for vera_sd_tests.s)
MBR_L          = $9000
MBR_H          = $9100
MBR_SLOW_L     = $9200
MBR_SLOW_H     = $9300
MBR_FAST_L     = $9400
MBR_FAST_H     = $9500


; === Other constants ===

NR_OF_SECTORS_TO_COPY = 136*320 / 512 ; Note (320x136 resolution): 136 * 320 = 170 * 256 = 85 * 512 bytes (1 sector = 512 bytes)


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

    jsr copy_palette_from_index_1

    jsr generate_copy_sector_code


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
 
; FIXME! 
; FIXME! 
; FIXME! 
;    lda #1
    lda #0
    sta SD_USE_AUTOTX
	lda #SPI_CHIP_SELECT_AND_FAST
	sta VERA_SPI_CTRL
    
    jsr load_and_draw_frame
    

done_with_sd_checks:

    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts
    
    
; FIXME: NOT USED!
setup_vera_for_layer0_bitmap:

    lda VERA_DC_VIDEO
    ora #%00010000           ; Enable Layer 0 
    and #%10011111           ; Disable Layer 1 and sprites
    sta VERA_DC_VIDEO

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; Enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    ; Set layer0 tilebase to 0x00000 and tile width to 320 px
    lda #0
    sta VERA_L0_TILEBASE
    
    rts

setup_screen_borders:

    ; Setting VSTART/VSTOP so that we have 200 rows on screen (320x200 pixels on screen)

    lda #%00000010  ; DCSEL=1
    sta VERA_CTRL
   
    lda #52
    sta VERA_DC_VSTART
    lda #136+52-1
    sta VERA_DC_VSTOP
    
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



walker_spi_send_command17:

    ; The command index requires the highest bit to be 0 and the bit after that to be 1 = $40
    lda #(17 | $40)      
    jsr spi_write_byte
    
    ; Command 17 has four bytes of argument, so sending four bytes with their as argument
    
    ; FIXME: allow for choice of sector!
    lda #0
    jsr spi_write_byte
    lda #0
    jsr spi_write_byte
    lda #0
    jsr spi_write_byte
    lda #0
    jsr spi_write_byte
    
    ; Command 17 requires no CRC. So we send 0
    lda #0
    jsr spi_write_byte

    ; We wait for a response (which should be R1 + data bytes)
    ldx #20                   ; TODO: how many retries do we want to do?
walker_spi_wait_command17:
    dex
    beq walker_spi_command17_timeout
    jsr spi_read_byte
    tay                       ; we want to keep the original value (so we put it in y for now)
    ; FIXME: Use 65C02 processor so we can use "bit #$80" here
    and #$80
    cmp #$80
    beq walker_spi_wait_command17
    
    tya                       ; we restore the original value (stored in y)
    
    sec  ; set the carry: we succeeded
    rts

walker_spi_command17_timeout:
    clc  ; clear the carry: we did not succeed
    rts



walker_vera_read_sector:

    ; We send command 17 to read single sector
; FIXME: we need to set the sector number!!
    jsr walker_spi_send_command17
    
    bcs walker_command17_success
walker_command17_timed_out:
    
    ; If carry is unset, we timed out. We print 'Timeout' as an error
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<vera_sd_timeout_message
    sta TEXT_TO_PRINT
    lda #>vera_sd_timeout_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jmp walker_done_reading_sector_do_not_proceed
    
walker_command17_success:

    ; We got our byte of response. We check if the SD Card is not in an IDLE state (which is expected)
    cmp #%0000000   ; NOT in IDLE state! (we initialized earlier, so we should NOT be in IDLE state anymore!)
    beq walker_command17_not_in_idle_state

walker_command17_in_idle_state:
    ; The reponse says we are in an IDLE state, which means there is an error
    ldx #17 ; command number to print
    jsr print_spi_cmd_error
    
    jmp walker_done_reading_sector_do_not_proceed
    
walker_command17_not_in_idle_state:
    
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
    ora #%00000100       ; AUTOTX bit = 1
    sta VERA_SPI_CTRL
    
    
    ; This loads and draws 512 bytes from SD card to VRAM
    
    ; Start first read transfer
    lda VERA_SPI_DATA    ; Auto-tx
    ldy #0                ; 2

; FIXME! DO THIS INSTEAD!!
; FIXME! DO THIS INSTEAD!!
; FIXME! DO THIS INSTEAD!!
;    jsr COPY_SECTOR_CODE
    

    ; Efficiently read first 256 bytes (hide SPI transfer time)
    ldy #0                ; 2
walker_reading_sector_8_bytes_L:
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 0, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 1, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 2, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 3, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 4, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 5, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 6, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_L + 7, y    ; 5
    tya                ; 2
    clc                ; 2
    adc #8                ; 2
    tay                ; 2
    bne walker_reading_sector_8_bytes_L  ; 2+1

    ; Efficiently read second 256 bytes (hide SPI transfer time)
walker_reading_sector_8_bytes_H:
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 0, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 1, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 2, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 3, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 4, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 5, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 6, y    ; 5
    lda VERA_SPI_DATA            ; 4
    sta MBR_H + 7, y    ; 5
    tya                ; 2
    clc                ; 2
    adc #8                ; 2
    tay                ; 2
    bne walker_reading_sector_8_bytes_H  ; 2+1

    ; Disable auto-tx mode
    lda VERA_SPI_CTRL
    and #%11111011     ; AUTOTX bit = 1
    sta VERA_SPI_CTRL

    ; Next read is now already done (first CRC byte), read second CRC byte
    jsr spi_read_byte
    jsr spi_read_byte_measure ; We are measuring the speed of this last read


walker_read_sector_check_mbr:

    ; The last two bytes of the MBR should always be $55AA
    lda MBR_H+254
    cmp #$55
    bne walker_mbr_malformed
    
    lda MBR_H+255
    cmp #$AA
    bne walker_mbr_malformed

    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #<ok_message
    sta TEXT_TO_PRINT
    lda #>ok_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr print_number_of_loops
    
    jmp walker_done_reading_sector_proceed
    
walker_mbr_malformed:

    ; The MBR is not correctly formed
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<vera_sd_malformed_msb
    sta TEXT_TO_PRINT
    lda #>vera_sd_malformed_msb
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jmp walker_done_reading_sector_do_not_proceed
    
walker_wait_for_data_packet_start_timeout:
    
    ; If carry is unset, we timed out. We print 'Timeout' as an error
    lda #COLOR_ERROR
    sta TEXT_COLOR
    
    lda #<vera_sd_timeout_message
    sta TEXT_TO_PRINT
    lda #>vera_sd_timeout_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    jmp walker_done_reading_sector_do_not_proceed
    
    
walker_done_reading_sector_do_not_proceed:
    jsr move_cursor_to_next_line

    ; We unselect the card
    lda #SPI_CHIP_DESELECT_AND_SLOW
    sta VERA_SPI_CTRL

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
    
    
    stz SECTOR_NUMBER
next_sector_to_copy:

    ; FIXME: setup for loading the NEXT! sector
    jsr walker_vera_read_sector

    ; SPEED: we can make this a bit quicker by counting DOWN
    inc SECTOR_NUMBER
    lda SECTOR_NUMBER
    cmp #NR_OF_SECTORS_TO_COPY
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

palette_data:
  .byte $66, $05
  .byte $68, $06
  .byte $88, $06
  .byte $88, $07
  .byte $8a, $07
  .byte $8a, $08
  .byte $aa, $08
  .byte $aa, $09
  .byte $ac, $09
  .byte $ac, $0a
  .byte $cc, $0a
  .byte $cc, $0b
  .byte $ce, $0b
  .byte $ce, $0c
  .byte $ee, $0d
  .byte $ee, $0e
  .byte $24, $02
  .byte $24, $03
  .byte $44, $05
  .byte $46, $05
  .byte $66, $06
  .byte $88, $09
  .byte $88, $08
  .byte $44, $04
  .byte $22, $03
  .byte $44, $03
  .byte $42, $02
  .byte $42, $03
  .byte $22, $02
  .byte $22, $01
  .byte $66, $07
  .byte $64, $05
  .byte $00, $01
  .byte $00, $00
  .byte $68, $05
  .byte $ac, $08
  .byte $ce, $0a
  .byte $ee, $0f
  .byte $8c, $09
  .byte $26, $02
  .byte $02, $00
  .byte $44, $02
  .byte $8a, $06
  .byte $8c, $08
  .byte $ae, $0a
  .byte $ee, $0c
  .byte $68, $07
  .byte $68, $04
  .byte $64, $04
  .byte $aa, $0a
  .byte $02, $01
  .byte $02, $02
  .byte $22, $00
  .byte $66, $04
  .byte $8a, $09
  .byte $24, $01
  .byte $46, $04
  .byte $20, $01
  .byte $46, $03
  .byte $24, $04
  .byte $ae, $09
  .byte $00, $02
  .byte $8c, $07
  .byte $ce, $0d
  .byte $22, $04
  .byte $ac, $0b
  .byte $cc, $0d
  .byte $68, $08
  .byte $cc, $0c
  .byte $46, $06
  .byte $a8, $0a
  .byte $aa, $0b
  .byte $ce, $0e
  .byte $cc, $0e
  .byte $88, $0a
  .byte $aa, $0c
  .byte $ae, $0b
  .byte $66, $08
  .byte $ec, $0e
  .byte $ca, $0c
  .byte $ac, $0c
  .byte $ec, $0f
  .byte $64, $06
  .byte $ae, $0c
  .byte $ce, $0f
  .byte $ae, $0d
  .byte $44, $06
  .byte $8a, $0a
  .byte $ae, $0e
  .byte $8c, $0a
  .byte $ac, $0d
  .byte $86, $08
  .byte $42, $04
  .byte $ae, $0f
  .byte $ac, $0e
  .byte $8a, $0c
  .byte $a8, $09
  .byte $46, $02
  .byte $ce, $09
  .byte $6a, $06
  .byte $86, $06
  .byte $6a, $09
  .byte $8a, $0b
  .byte $20, $02
  .byte $86, $07
  .byte $6a, $07
  .byte $64, $03
  .byte $20, $00
  .byte $ec, $0d
  .byte $a8, $0b
  .byte $ca, $0d
  .byte $ca, $0b
  .byte $68, $0a
  .byte $88, $0b
  .byte $68, $0b
  .byte $88, $0c
  .byte $68, $0c
  .byte $aa, $0e
  .byte $aa, $0f
  .byte $46, $0a
  .byte $24, $06
  .byte $22, $05
  .byte $66, $0a
  .byte $46, $08
  .byte $24, $05
  .byte $46, $07
  .byte $44, $07
  .byte $8c, $0b
  .byte $68, $09
  .byte $66, $09
  .byte $6a, $0a
  .byte $6a, $0b
  .byte $8c, $0c
  .byte $8c, $0d
  .byte $8c, $0e
  .byte $ac, $0f
  .byte $cc, $0f
  .byte $6a, $08
  .byte $88, $05
  .byte $8a, $0d
  .byte $8a, $05
  .byte $02, $03
  .byte $aa, $0d
  .byte $86, $09
  .byte $ca, $0a
  .byte $02, $04
  .byte $22, $06
  .byte $46, $09
  .byte $44, $08
  .byte $24, $07
  .byte $8a, $0e
  .byte $88, $0d
  .byte $66, $0b
  .byte $44, $09
  .byte $68, $0d
  .byte $8a, $0f
  .byte $88, $0e
  .byte $66, $0c
  .byte $68, $0e
  .byte $66, $0e
  .byte $66, $0d
  .byte $68, $0f
  .byte $88, $0f
  .byte $46, $0c
  .byte $44, $0b
  .byte $46, $0d
  .byte $44, $0a
  .byte $24, $0a
  .byte $46, $0b
  .byte $24, $09
  .byte $44, $0c
  .byte $24, $0b
  .byte $22, $0a
  .byte $22, $09
  .byte $02, $09
  .byte $24, $08
  .byte $22, $08
  .byte $02, $07
  .byte $00, $07
  .byte $00, $06
  .byte $22, $07
  .byte $02, $05
  .byte $00, $05
  .byte $02, $06
  .byte $00, $04
  .byte $a8, $08
  .byte $86, $0a
  .byte $42, $05
  .byte $00, $03
  .byte $48, $04
  .byte $46, $0e
  .byte $64, $07
  .byte $48, $06
  .byte $6a, $0c
  .byte $20, $03
  .byte $8c, $0f
  .byte $26, $03
  .byte $cc, $09
  .byte $48, $05
  .byte $6a, $0d
  .byte $26, $09
  .byte $04, $07
  .byte $aa, $07
  .byte $66, $03
end_of_palette_data:


    .include utils/x16.s
    .include utils/utils.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include tests/vera_sd_tests.s
