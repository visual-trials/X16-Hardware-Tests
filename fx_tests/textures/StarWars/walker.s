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
NUMBER_OF_FRAMES = 72


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

; FIXME! DO THIS INSTEAD!!
; FIXME! DO THIS INSTEAD!!
; FIXME! DO THIS INSTEAD!!
;    jsr COPY_SECTOR_CODE
    

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
  .byte $0b  ,  $e2, $25, $02,  $e3, $69, $05,  $e4, $46, $02,  $e5, $ce, $09,  $e6, $7a, $06,  $e7, $bd, $08,  $e8, $bf, $0d,  $e9, $ad, $0d,  $ea, $ac, $0d,  $eb, $87, $06,  $ec, $76, $05
  .byte $08  ,  $39, $13, $00,  $6f, $76, $06,  $72, $8b, $09,  $77, $8b, $08,  $7a, $7a, $09,  $8b, $9b, $0b,  $a8, $21, $02,  $c5, $87, $07
  .byte $09  ,  $5d, $36, $02,  $6d, $02, $00,  $73, $7a, $07,  $79, $69, $06,  $bf, $9c, $07,  $c9, $24, $01,  $ca, $65, $03,  $d1, $32, $01,  $d2, $ba, $09
  .byte $02  ,  $72, $21, $00,  $7a, $98, $07
  .byte $04  ,  $38, $03, $00,  $57, $9c, $09,  $5d, $ed, $0d,  $79, $a9, $0b
  .byte $05  ,  $39, $47, $03,  $6d, $13, $00,  $70, $57, $03,  $73, $ed, $0f,  $77, $dc, $0b
  .byte $02  ,  $1f, $36, $02,  $38, $23, $00
  .byte $05  ,  $39, $98, $08,  $5d, $bf, $0a,  $64, $cb, $0d,  $6d, $68, $07,  $70, $22, $00
  .byte $04  ,  $1f, $13, $00,  $38, $10, $00,  $57, $46, $05,  $69, $cb, $0b
  .byte $1f  ,  $64, $34, $01,  $6d, $45, $06,  $70, $9a, $0b,  $72, $cd, $0e,  $73, $78, $0a,  $77, $89, $0b,  $79, $9a, $0c,  $7a, $78, $0b,  $8b, $89, $0c,  $a8, $79, $0c,  $ad, $ab, $0e,  $b2, $68, $0b,  $b4, $ab, $0f,  $b5, $57, $0a,  $ba, $56, $0a,  $bb, $34, $06,  $bc, $33, $05,  $bd, $23, $04,  $be, $ab, $0c,  $c0, $67, $0a,  $c1, $56, $08,  $c4, $88, $0a,  $c6, $34, $05,  $d0, $56, $07,  $d1, $55, $07,  $d2, $66, $08,  $d3, $bd, $0c,  $d4, $87, $08,  $d7, $32, $01,  $da, $33, $01,  $e0, $54, $02
  .byte $21  ,  $23, $02, $00,  $38, $9c, $09,  $50, $9c, $0a,  $57, $ad, $0b,  $69, $9c, $0b,  $c5, $ad, $0e,  $cd, $bd, $0e,  $dd, $ce, $0e,  $e1, $ce, $0f,  $e2, $cf, $0f,  $e3, $ad, $0c,  $e4, $cf, $0e,  $e7, $be, $0d,  $e8, $ad, $0a,  $ed, $bf, $0f,  $ee, $be, $0e,  $ef, $ac, $0c,  $f0, $be, $0f,  $f1, $bd, $0d,  $f2, $bf, $0e,  $f3, $8a, $0a,  $f4, $79, $09,  $f5, $77, $09,  $f6, $78, $09,  $f7, $bc, $0d,  $f8, $68, $08,  $f9, $67, $08,  $fa, $89, $0a,  $fb, $9b, $0a,  $fc, $21, $02,  $fd, $cc, $0a,  $fe, $87, $07,  $ff, $10, $00
  .byte $16  ,  $64, $79, $0a,  $70, $7a, $0a,  $72, $7a, $0b,  $73, $8a, $0c,  $77, $8b, $0c,  $79, $9b, $0c,  $7a, $9c, $0c,  $8b, $9c, $0d,  $93, $9c, $0e,  $a8, $ad, $0f,  $ad, $bd, $0f,  $b2, $cd, $0f,  $b4, $7a, $09,  $b5, $8b, $0b,  $ba, $ac, $0e,  $bb, $7a, $08,  $bc, $8a, $0b,  $bd, $68, $07,  $be, $ae, $0d,  $c0, $ae, $0b,  $c1, $aa, $08,  $c4, $99, $07
  .byte $06  ,  $23, $43, $02,  $38, $34, $01,  $69, $7a, $07,  $6d, $9c, $09,  $c6, $9c, $0b,  $ca, $ae, $0e
  .byte $09  ,  $50, $02, $00,  $64, $57, $03,  $65, $89, $05,  $70, $fe, $0f,  $72, $8b, $0a,  $73, $9b, $0d,  $77, $9b, $0b,  $79, $dc, $0b,  $93, $21, $01
  .byte $02  ,  $38, $69, $06,  $a8, $8b, $0c
  .byte $02  ,  $1f, $46, $02,  $50, $ba, $0a
  .byte $03  ,  $38, $13, $00,  $57, $02, $00,  $64, $bf, $09
  .byte $02  ,  $50, $ed, $0f,  $65, $57, $06
  .byte $00
  .byte $01  ,  $1f, $cf, $09
  .byte $02  ,  $50, $89, $05,  $65, $8a, $05
  .byte $02  ,  $1f, $69, $05,  $38, $8b, $08
  .byte $0a  ,  $57, $a9, $09,  $64, $02, $00,  $69, $13, $00,  $6d, $dd, $0f,  $72, $de, $0f,  $73, $98, $0a,  $77, $a9, $0b,  $79, $dc, $0e,  $7a, $12, $03,  $8b, $ba, $0c
  .byte $09  ,  $1f, $9c, $09,  $38, $cb, $0d,  $a2, $88, $0a,  $a8, $99, $0b,  $ad, $aa, $0c,  $ae, $bb, $0d,  $b0, $cc, $0e,  $b1, $87, $09,  $b2, $df, $0e
  .byte $0a  ,  $57, $34, $01,  $6d, $69, $05,  $70, $ed, $0f,  $7a, $ab, $0c,  $8b, $dd, $0f,  $b4, $ad, $0b,  $b5, $9c, $0d,  $b9, $57, $07,  $bb, $cb, $0a,  $bc, $dc, $0c
  .byte $25  ,  $38, $57, $05,  $73, $57, $03,  $be, $cd, $0e,  $c0, $cf, $0d,  $c4, $33, $05,  $c6, $12, $04,  $c7, $bb, $0e,  $ca, $ab, $0d,  $cb, $cd, $0f,  $cd, $bc, $0e,  $ce, $9a, $0c,  $d0, $34, $06,  $d4, $22, $04,  $d7, $45, $07,  $d8, $cc, $0f,  $da, $df, $0f,  $dd, $56, $08,  $de, $33, $06,  $e0, $78, $0a,  $e1, $67, $09,  $e2, $ab, $0e,  $e4, $aa, $0d,  $e5, $56, $09,  $e7, $45, $08,  $ea, $44, $07,  $eb, $99, $0c,  $ed, $ba, $0d,  $ee, $fe, $0f,  $f0, $cf, $0f,  $f1, $9a, $0d,  $f2, $34, $07,  $f3, $89, $0c,  $f4, $bc, $0f,  $f8, $ab, $0f,  $fc, $9a, $0e,  $fd, $89, $0d,  $ff, $88, $0c
  .byte $11  ,  $57, $a9, $09,  $6d, $87, $06,  $77, $ba, $0a,  $79, $ce, $09,  $8e, $7a, $07,  $aa, $36, $02,  $b5, $ba, $0c,  $b9, $9c, $0a,  $bb, $9c, $0c,  $bc, $9b, $0b,  $bd, $ad, $0f,  $bf, $ac, $0d,  $cc, $8a, $0b,  $cf, $9b, $0c,  $d5, $43, $04,  $d6, $68, $08,  $fb, $32, $03
  .byte $09  ,  $69, $25, $02,  $9f, $58, $04,  $c6, $69, $05,  $e0, $76, $07,  $e7, $a9, $0a,  $ed, $12, $03,  $f2, $21, $02,  $f4, $dd, $0b,  $f9, $45, $09
  .byte $15  ,  $1f, $be, $0b,  $70, $10, $01,  $73, $79, $04,  $79, $78, $04,  $8e, $47, $03,  $aa, $99, $07,  $b4, $32, $04,  $b9, $9c, $09,  $ba, $ad, $0b,  $bb, $ed, $0f,  $bc, $9c, $0b,  $bd, $ac, $0e,  $c0, $9b, $0b,  $c2, $ad, $0f,  $c5, $79, $0a,  $cc, $8a, $0a,  $cf, $8a, $0b,  $d6, $9b, $0c,  $d9, $ad, $0e,  $dc, $ac, $0b,  $f0, $9c, $0d
  .byte $05  ,  $57, $10, $00,  $69, $57, $03,  $6d, $9c, $07,  $9f, $01, $02,  $c6, $88, $06
  .byte $06  ,  $64, $36, $02,  $72, $69, $05,  $7a, $23, $00,  $8e, $34, $01,  $a2, $02, $00,  $a8, $87, $06
  .byte $0a  ,  $1f, $a9, $09,  $57, $7a, $07,  $6d, $35, $04,  $77, $de, $0f,  $aa, $ab, $0c,  $ac, $88, $0a,  $ad, $99, $0b,  $ae, $33, $01,  $b0, $cb, $0a,  $b3, $ba, $0a
  .byte $06  ,  $64, $69, $06,  $72, $22, $00,  $7a, $13, $02,  $8e, $aa, $0c,  $9f, $cc, $0e,  $a8, $99, $07
  .byte $1f  ,  $1f, $68, $0c,  $57, $46, $05,  $77, $57, $06,  $8b, $57, $0a,  $aa, $79, $0e,  $ab, $8a, $0e,  $ad, $8a, $0f,  $b0, $35, $09,  $b1, $24, $08,  $b3, $24, $09,  $b4, $35, $0a,  $b5, $46, $0a,  $b9, $00, $05,  $ba, $01, $02,  $bb, $12, $05,  $bc, $00, $04,  $bd, $11, $04,  $be, $01, $03,  $bf, $bf, $09,  $c2, $02, $05,  $c5, $46, $09,  $c7, $12, $04,  $ca, $de, $0f,  $cb, $69, $05,  $cc, $87, $08,  $cd, $ba, $0b,  $cf, $ba, $0c,  $d3, $87, $09,  $d8, $ce, $0d,  $d9, $ab, $0d,  $e3, $bd, $0c
  .byte $10  ,  $64, $a9, $09,  $68, $cf, $0c,  $72, $10, $00,  $7a, $cf, $0d,  $a8, $cf, $0e,  $c9, $be, $0b,  $e0, $cf, $0f,  $e4, $be, $0d,  $e8, $9c, $09,  $e9, $ad, $0a,  $eb, $34, $01,  $ef, $24, $01,  $f0, $ed, $0f,  $f4, $76, $07,  $f7, $65, $07,  $f8, $cd, $0e
  .byte $12  ,  $1f, $24, $03,  $57, $69, $08,  $6d, $79, $09,  $70, $79, $08,  $77, $8b, $0c,  $8b, $8b, $0b,  $aa, $8a, $0a,  $ab, $7a, $0a,  $ad, $7a, $09,  $b0, $7a, $08,  $b1, $56, $03,  $b3, $69, $0a,  $b4, $8b, $0a,  $b5, $58, $06,  $b9, $69, $06,  $ba, $13, $00,  $bb, $10, $01,  $bc, $99, $07
  .byte $02  ,  $64, $58, $04,  $7a, $a9, $09
  .byte $02  ,  $1f, $57, $06,  $57, $cb, $0a
  .byte $05  ,  $64, $57, $0a,  $68, $cb, $0b,  $6d, $00, $02,  $77, $35, $08,  $7a, $35, $05
  .byte $0c  ,  $1f, $cf, $0c,  $57, $cf, $0d,  $6c, $8b, $08,  $70, $47, $04,  $72, $79, $09,  $8b, $ac, $0f,  $8e, $ab, $0f,  $aa, $bf, $0e,  $ab, $8a, $0a,  $ac, $9b, $0f,  $ad, $bd, $0f,  $b0, $cb, $0a
  .byte $1c  ,  $64, $10, $00,  $68, $79, $0a,  $69, $69, $08,  $6d, $8b, $0d,  $77, $9c, $0e,  $7a, $9c, $0d,  $b3, $9c, $0c,  $b4, $8b, $0b,  $b5, $8b, $0a,  $b9, $79, $08,  $bc, $8b, $0c,  $bd, $7a, $0a,  $be, $7a, $09,  $bf, $69, $07,  $c2, $45, $02,  $c4, $58, $04,  $c5, $ad, $0b,  $c6, $9c, $0a,  $c7, $ad, $0d,  $cf, $9c, $0b,  $d0, $be, $0f,  $d1, $ad, $0e,  $d2, $ad, $0c,  $d3, $88, $0a,  $d4, $01, $02,  $d6, $aa, $0c,  $de, $66, $08,  $ea, $88, $06
  .byte $0f  ,  $57, $69, $06,  $6c, $ae, $09,  $70, $dc, $0e,  $8b, $7a, $08,  $8e, $7a, $0c,  $a8, $ae, $0f,  $aa, $cf, $0e,  $ab, $8b, $09,  $ac, $cf, $0d,  $b0, $55, $07,  $eb, $34, $06,  $ed, $22, $04,  $f7, $21, $03,  $f9, $87, $09,  $fd, $8a, $0c
  .byte $05  ,  $64, $7a, $07,  $69, $ba, $0c,  $6d, $57, $0a,  $bc, $9b, $0c,  $bf, $8b, $0c
  .byte $04  ,  $57, $57, $03,  $68, $36, $03,  $72, $ce, $09,  $77, $cd, $09
  .byte $07  ,  $1f, $10, $00,  $64, $58, $05,  $69, $34, $01,  $6d, $79, $0a,  $7a, $7a, $0b,  $8b, $9c, $0d,  $8e, $a9, $09
  .byte $05  ,  $68, $9c, $07,  $72, $ba, $0c,  $77, $cf, $0c,  $a8, $57, $06,  $ac, $46, $02
  .byte $03  ,  $57, $8b, $08,  $64, $57, $03,  $69, $35, $01
  .byte $02  ,  $1f, $34, $01,  $68, $23, $00
  .byte $03  ,  $57, $10, $00,  $64, $9c, $07,  $69, $87, $06
  .byte $02  ,  $5d, $57, $03,  $6c, $22, $00
  .byte $10  ,  $64, $36, $02,  $69, $47, $04,  $6d, $8b, $08,  $72, $35, $05,  $7a, $46, $06,  $8e, $24, $05,  $a8, $ad, $0f,  $aa, $7a, $0d,  $ab, $36, $09,  $ac, $24, $07,  $b4, $8a, $0e,  $b9, $14, $07,  $bd, $35, $09,  $be, $13, $07,  $bf, $24, $06,  $c1, $65, $03
  .byte $03  ,  $1f, $9c, $07,  $5d, $46, $02,  $68, $ba, $0a
  .byte $02  ,  $64, $7a, $07,  $69, $02, $01
  .byte $0c  ,  $1f, $24, $03,  $5d, $79, $0a,  $68, $89, $0d,  $6d, $bf, $0e,  $72, $cf, $0e,  $7a, $bf, $0f,  $8b, $45, $09,  $8e, $33, $06,  $9f, $cf, $0d,  $a8, $44, $07,  $aa, $46, $02,  $ab, $a9, $09
  .byte $05  ,  $69, $ba, $0a,  $6c, $57, $03,  $70, $ae, $0d,  $ac, $44, $06,  $ad, $34, $01
  .byte $14  ,  $1f, $bf, $0a,  $5d, $02, $01,  $64, $25, $02,  $68, $13, $02,  $8b, $79, $08,  $8e, $7a, $07,  $9f, $68, $08,  $a8, $79, $09,  $aa, $7a, $09,  $ab, $8b, $08,  $b0, $8b, $09,  $b4, $7a, $08,  $b9, $bd, $0f,  $ba, $ad, $0f,  $bd, $8b, $0c,  $be, $9c, $0d,  $bf, $bd, $08,  $c1, $cf, $0d,  $c4, $a9, $09,  $d4, $22, $00
  .byte $04  ,  $39, $47, $03,  $57, $13, $00,  $69, $57, $06,  $6d, $69, $07
  .byte $04  ,  $5d, $10, $00,  $64, $aa, $08,  $6c, $98, $08,  $79, $87, $06
  .byte $03  ,  $39, $ba, $0a,  $69, $57, $03,  $6d, $46, $02
  .byte $0a  ,  $57, $69, $06,  $68, $13, $00,  $70, $46, $05,  $72, $35, $01,  $79, $69, $09,  $7a, $7a, $0a,  $8b, $8b, $0b,  $8e, $7a, $0b,  $a3, $cf, $0e,  $aa, $cd, $09
  .byte $0a  ,  $39, $36, $03,  $4c, $9c, $07,  $6d, $bc, $08,  $a1, $ab, $07,  $a5, $dc, $0d,  $ab, $68, $04,  $ac, $cb, $0c,  $ad, $ae, $0d,  $b0, $55, $07,  $b4, $cb, $0b
  .byte $10  ,  $57, $58, $05,  $5c, $7a, $07,  $64, $8b, $08,  $68, $58, $04,  $69, $13, $00,  $70, $69, $07,  $72, $35, $04,  $79, $34, $01,  $7a, $ad, $08,  $8b, $ed, $0e,  $8e, $9d, $0b,  $9f, $bf, $0e,  $a8, $ce, $09,  $ae, $aa, $08,  $b3, $ba, $0a,  $b5, $79, $08
  .byte $03  ,  $39, $33, $01,  $5d, $98, $07,  $6d, $66, $03
  .byte $0c  ,  $69, $57, $03,  $70, $13, $00,  $72, $46, $02,  $8e, $79, $09,  $9f, $7a, $09,  $a1, $8b, $0a,  $a8, $bc, $08,  $aa, $ac, $0e,  $ac, $8b, $0b,  $ad, $cb, $0c,  $ae, $ae, $0a,  $b0, $aa, $08
  .byte $02  ,  $68, $87, $06,  $6d, $a9, $08
  .byte $00
  .byte $05  ,  $4c, $10, $00,  $5d, $47, $04,  $68, $69, $06,  $6d, $58, $04,  $8e, $36, $03
  .byte $02  ,  $39, $9c, $07,  $57, $33, $01
  .byte $06  ,  $4c, $98, $07,  $5d, $58, $05,  $72, $47, $03,  $9f, $36, $02,  $a1, $46, $02,  $a3, $ba, $09
  .byte $00
  
; FIXME: added another 0 here!  
  .byte $00

    .include utils/x16.s
    .include utils/utils.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include tests/vera_sd_tests.s
