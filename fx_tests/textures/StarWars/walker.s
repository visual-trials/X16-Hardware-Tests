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
  .byte $05  ,  $09, $37, $01,  $1c, $7c, $06,  $33, $67, $04,  $5b, $ab, $08,  $ea, $aa, $08
  .byte $05  ,  $03, $23, $00,  $1b, $bf, $0a,  $1f, $78, $05,  $2e, $af, $09,  $b8, $6a, $03
  .byte $06  ,  $0c, $ef, $09,  $bd, $59, $03,  $c4, $10, $01,  $c5, $21, $02,  $c8, $15, $00,  $d1, $a9, $0b
  .byte $0b  ,  $09, $7c, $04,  $1c, $48, $02,  $1f, $68, $03,  $38, $43, $04,  $96, $37, $02,  $b6, $54, $05,  $e0, $8d, $07,  $ea, $ac, $07,  $ed, $23, $04,  $f1, $89, $06,  $f2, $99, $0b
  .byte $07  ,  $33, $65, $07,  $36, $8b, $04,  $73, $32, $03,  $87, $ad, $06,  $c5, $48, $03,  $c8, $78, $05,  $cf, $12, $03
  .byte $0d  ,  $09, $15, $00,  $1f, $9e, $08,  $22, $7c, $06,  $2e, $56, $03,  $38, $04, $00,  $45, $15, $01,  $b6, $79, $04,  $ed, $43, $05,  $f0, $9c, $09,  $f1, $ef, $0f,  $f3, $01, $02,  $f4, $76, $08,  $f6, $87, $09
  .byte $09  ,  $03, $7c, $04,  $0c, $45, $02,  $1b, $7a, $04,  $1c, $45, $06,  $36, $89, $06,  $73, $be, $0b,  $87, $a9, $0a,  $b8, $67, $08,  $c8, $9b, $0a
  .byte $0a  ,  $09, $ad, $06,  $22, $78, $05,  $38, $23, $00,  $45, $77, $05,  $96, $bf, $0a,  $cf, $be, $07,  $d0, $bb, $09,  $d2, $32, $03,  $e0, $af, $09,  $e6, $98, $0a
  .byte $08  ,  $0c, $48, $02,  $1c, $6b, $04,  $33, $21, $02,  $4b, $65, $06,  $73, $15, $00,  $87, $37, $02,  $b8, $55, $03,  $c4, $ad, $0a
  .byte $08  ,  $03, $45, $02,  $45, $43, $04,  $96, $26, $01,  $98, $67, $04,  $a1, $cc, $0a,  $b6, $dd, $0b,  $c8, $54, $05,  $d0, $89, $0a
  .byte $0b  ,  $0c, $54, $06,  $1b, $10, $01,  $1c, $aa, $08,  $1f, $88, $06,  $36, $76, $06,  $87, $99, $07,  $92, $98, $08,  $ab, $8b, $08,  $b7, $34, $01,  $b8, $65, $05,  $bd, $77, $09
  .byte $0b  ,  $09, $de, $0e,  $38, $59, $03,  $45, $58, $05,  $73, $6b, $04,  $96, $65, $07,  $98, $7c, $04,  $a1, $9e, $08,  $d0, $89, $06,  $dc, $33, $01,  $e0, $58, $02,  $ea, $bb, $09
  .byte $0f  ,  $0c, $8d, $07,  $1c, $9d, $08,  $1f, $66, $04,  $77, $cd, $09,  $87, $23, $00,  $92, $43, $04,  $ab, $a9, $0a,  $b7, $32, $04,  $bd, $bc, $08,  $e9, $cf, $0c,  $ed, $9b, $0a,  $f0, $ac, $07,  $f3, $77, $05,  $f6, $ae, $09,  $f7, $69, $06
  .byte $09  ,  $61, $56, $08,  $a1, $8b, $0a,  $b6, $79, $09,  $b8, $ab, $0c,  $bf, $cd, $0e,  $dc, $78, $09,  $e7, $ad, $0c,  $ea, $ce, $0d,  $f4, $de, $0f
  .byte $0c  ,  $1f, $9b, $06,  $36, $34, $01,  $3b, $7a, $04,  $92, $ee, $0c,  $ab, $9c, $09,  $b7, $65, $05,  $bd, $35, $04,  $c5, $98, $09,  $e0, $de, $0a,  $e6, $48, $02,  $e9, $aa, $08,  $f3, $87, $07
  .byte $06  ,  $4f, $98, $0a,  $61, $43, $04,  $96, $bb, $0c,  $a1, $44, $02,  $b6, $ad, $06,  $b8, $87, $08
  .byte $0a  ,  $0c, $ba, $0b,  $38, $cd, $0d,  $73, $66, $08,  $87, $87, $09,  $b7, $dd, $0e,  $be, $77, $09,  $bf, $47, $04,  $c4, $a9, $0a,  $c5, $43, $05,  $cf, $7b, $06
  .byte $0c  ,  $a1, $8b, $08,  $ab, $65, $07,  $d0, $88, $06,  $dc, $79, $04,  $e7, $cc, $0a,  $e9, $98, $09,  $ea, $23, $00,  $f2, $57, $02,  $f3, $cb, $0c,  $f4, $67, $04,  $f7, $ce, $08,  $f8, $26, $01
  .byte $0a  ,  $03, $76, $08,  $0c, $89, $06,  $3b, $9c, $09,  $73, $48, $03,  $77, $69, $03,  $96, $dd, $0b,  $b6, $99, $0b,  $b7, $cf, $0c,  $c5, $be, $07,  $e0, $54, $06
  .byte $08  ,  $1c, $7a, $04,  $93, $45, $02,  $a1, $6b, $04,  $d0, $de, $0a,  $d1, $69, $06,  $dc, $aa, $08,  $ed, $10, $02,  $f1, $ad, $0a
  .byte $08  ,  $22, $59, $03,  $3b, $cb, $0b,  $4d, $ef, $0f,  $6e, $9d, $08,  $73, $76, $06,  $77, $ac, $0b,  $96, $8a, $09,  $ab, $88, $0a
  .byte $09  ,  $36, $8b, $08,  $7d, $bc, $08,  $b2, $8c, $07,  $b6, $78, $05,  $c4, $9c, $09,  $d0, $69, $03,  $e0, $65, $07,  $e7, $68, $03,  $ed, $79, $04
  .byte $05  ,  $03, $59, $04,  $3b, $dd, $0b,  $4d, $10, $02,  $73, $34, $01,  $77, $cc, $0a
  .byte $04  ,  $1f, $58, $02,  $45, $bb, $09,  $4c, $ac, $0b,  $57, $ba, $0a
  .byte $07  ,  $3b, $de, $0a,  $4d, $8d, $05,  $6b, $44, $02,  $6c, $9b, $0a,  $7d, $57, $06,  $96, $98, $08,  $ab, $99, $07
  .byte $07  ,  $1c, $cd, $09,  $45, $68, $07,  $4c, $6b, $03,  $57, $77, $05,  $b7, $ef, $0f,  $c4, $66, $04,  $c5, $58, $05
  .byte $11  ,  $03, $8a, $0c,  $3b, $99, $0c,  $6c, $88, $0c,  $77, $9a, $0c,  $96, $89, $0c,  $b8, $8a, $0b,  $dc, $89, $0b,  $e0, $77, $0b,  $e6, $99, $0b,  $e7, $aa, $0c,  $ed, $68, $0a,  $f2, $88, $0b,  $f3, $78, $0b,  $f7, $56, $0a,  $f8, $79, $0b,  $fb, $68, $09,  $fd, $78, $09
  .byte $47  ,  $09, $48, $03,  $0a, $57, $08,  $0f, $37, $02,  $1a, $59, $04,  $1c, $11, $05,  $1f, $67, $0b,  $21, $43, $05,  $22, $af, $0a,  $24, $03, $01,  $28, $33, $01,  $2c, $65, $04,  $38, $ad, $0d,  $3a, $10, $03,  $3d, $11, $03,  $41, $65, $09,  $47, $01, $04,  $4a, $56, $09,  $4b, $11, $04,  $4c, $55, $09,  $4d, $54, $08,  $4e, $21, $05,  $4f, $56, $08,  $52, $65, $08,  $55, $12, $05,  $61, $22, $06,  $68, $34, $08,  $73, $55, $08,  $74, $22, $05,  $75, $21, $04,  $7a, $32, $06,  $7e, $43, $07,  $7f, $43, $06,  $80, $12, $04,  $82, $aa, $0d,  $83, $54, $07,  $87, $ab, $0e,  $8c, $10, $02,  $8f, $44, $08,  $98, $33, $07,  $99, $00, $03,  $9a, $46, $08,  $a1, $45, $09,  $a9, $23, $06,  $ab, $22, $04,  $ad, $78, $0a,  $b0, $66, $09,  $b2, $44, $07,  $b4, $33, $06,  $b5, $01, $03,  $b7, $00, $02,  $c2, $67, $0a,  $c6, $ab, $0d,  $c8, $32, $05,  $c9, $76, $0a,  $ca, $23, $05,  $cc, $45, $08,  $ce, $bd, $0e,  $cf, $ac, $0e,  $d0, $bc, $0f,  $d2, $33, $05,  $d5, $79, $0a,  $d8, $77, $0a,  $df, $ac, $0d,  $e3, $9b, $0d,  $e5, $23, $04,  $e8, $44, $06,  $e9, $01, $02,  $ea, $67, $09,  $eb, $34, $06,  $f0, $bc, $0e,  $fa, $32, $04
  .byte $01  ,  $d3, $cc, $0b
  .byte $08  ,  $21, $df, $0e,  $24, $5a, $04,  $28, $6a, $04,  $2c, $6b, $05,  $38, $25, $03,  $55, $32, $03,  $88, $aa, $0a,  $9a, $8a, $09
  .byte $07  ,  $22, $12, $05,  $92, $68, $04,  $a1, $99, $0d,  $a6, $15, $00,  $d3, $33, $01,  $db, $ce, $0d,  $e1, $65, $04
  .byte $06  ,  $24, $8d, $07,  $28, $8d, $06,  $2c, $8c, $06,  $38, $46, $08,  $88, $9e, $07,  $9a, $34, $01
  .byte $0b  ,  $09, $7c, $06,  $0f, $cc, $0b,  $1a, $00, $04,  $21, $10, $04,  $22, $34, $07,  $3e, $46, $07,  $a2, $35, $06,  $a6, $57, $09,  $d3, $55, $07,  $db, $45, $07,  $ed, $76, $09
  .byte $08  ,  $1c, $ee, $0d,  $28, $dd, $0c,  $68, $6b, $05,  $88, $59, $04,  $94, $7c, $07,  $9a, $af, $09,  $d0, $45, $09,  $e4, $04, $00
  .byte $09  ,  $1f, $cd, $0c,  $21, $48, $03,  $24, $37, $02,  $2c, $11, $05,  $38, $79, $05,  $3e, $49, $03,  $81, $8d, $08,  $8e, $5a, $05,  $93, $bc, $09
  .byte $08  ,  $09, $de, $0d,  $0a, $bf, $09,  $68, $12, $05,  $94, $45, $02,  $9a, $ad, $0d,  $a1, $87, $0b,  $d0, $bd, $0f,  $ed, $bb, $0e
  .byte $06  ,  $3e, $ae, $08,  $55, $af, $09,  $81, $9e, $08,  $88, $34, $08,  $8e, $57, $03,  $a2, $03, $01
  .byte $06  ,  $21, $32, $03,  $24, $8d, $07,  $2b, $57, $08,  $68, $76, $09,  $92, $aa, $0a,  $9a, $43, $05
  .byte $06  ,  $88, $ef, $0c,  $93, $7c, $07,  $94, $99, $0d,  $a1, $7a, $05,  $a2, $bd, $0d,  $d0, $bb, $0d
  .byte $06  ,  $2b, $12, $05,  $2c, $67, $0b,  $6c, $25, $03,  $81, $46, $08,  $8e, $87, $0a,  $c1, $35, $06
  .byte $0d  ,  $0a, $11, $05,  $21, $bb, $0c,  $24, $bf, $0a,  $2a, $35, $05,  $3e, $34, $05,  $55, $12, $03,  $86, $99, $07,  $93, $46, $06,  $94, $68, $08,  $9a, $79, $09,  $a1, $89, $0a,  $a6, $88, $0a,  $da, $46, $05
  .byte $07  ,  $2c, $bc, $0f,  $38, $8c, $07,  $62, $32, $03,  $6c, $88, $0c,  $81, $03, $01,  $8e, $43, $05,  $c1, $76, $06
  .byte $06  ,  $21, $cd, $0f,  $2a, $57, $09,  $79, $99, $0d,  $a3, $46, $07,  $bf, $34, $08,  $ed, $99, $09
  .byte $07  ,  $38, $57, $08,  $6c, $bb, $0e,  $6e, $67, $0b,  $81, $46, $08,  $92, $35, $05,  $c5, $57, $03,  $d0, $9d, $09
  .byte $09  ,  $1c, $88, $0c,  $21, $bd, $0f,  $2a, $15, $00,  $6b, $58, $05,  $88, $bb, $0d,  $95, $aa, $0a,  $a3, $35, $06,  $bf, $bc, $09,  $c1, $47, $05
  .byte $06  ,  $2c, $6a, $05,  $31, $76, $06,  $39, $79, $05,  $6e, $9c, $09,  $81, $10, $00,  $c5, $21, $01
  .byte $07  ,  $79, $48, $03,  $88, $9d, $08,  $8e, $24, $03,  $95, $47, $04,  $b1, $32, $07,  $c1, $45, $09,  $d0, $57, $09
  .byte $03  ,  $2c, $cd, $0f,  $39, $aa, $0a,  $bf, $88, $09
  .byte $08  ,  $29, $9d, $09,  $50, $14, $01,  $68, $77, $08,  $79, $bb, $0d,  $88, $aa, $0b,  $c1, $99, $0a,  $c9, $67, $08,  $de, $66, $08
  .byte $04  ,  $09, $76, $09,  $31, $46, $08,  $8e, $89, $09,  $bf, $34, $08
  .byte $07  ,  $0a, $de, $0d,  $29, $24, $03,  $2c, $25, $01,  $71, $de, $0b,  $88, $79, $0c,  $b1, $45, $09,  $c1, $36, $05
  .byte $06  ,  $25, $11, $05,  $38, $9d, $09,  $39, $88, $09,  $72, $65, $07,  $8e, $56, $07,  $bf, $57, $07
  .byte $04  ,  $31, $cd, $0f,  $71, $89, $09,  $88, $58, $04,  $c1, $79, $05
  .byte $05  ,  $5d, $67, $0b,  $72, $99, $0a,  $93, $8c, $07,  $9e, $cd, $0a,  $e4, $35, $07
  .byte $08  ,  $21, $de, $0c,  $71, $df, $0b,  $9f, $99, $0d,  $a3, $34, $08,  $b1, $46, $06,  $bf, $65, $07,  $c1, $01, $05,  $f6, $53, $07
  .byte $07  ,  $25, $89, $09,  $31, $78, $0c,  $4e, $00, $05,  $6c, $ae, $09,  $92, $47, $03,  $93, $88, $06,  $d0, $45, $06
  .byte $05  ,  $38, $69, $05,  $39, $bb, $0e,  $88, $11, $05,  $a3, $46, $07,  $a9, $68, $04
  .byte $05  ,  $25, $cd, $0d,  $6c, $57, $07,  $6e, $58, $04,  $72, $23, $06,  $9e, $79, $0c
  .byte $0c  ,  $1c, $46, $08,  $24, $99, $0a,  $2a, $43, $05,  $31, $89, $09,  $56, $aa, $0a,  $68, $9d, $09,  $95, $9c, $09,  $a3, $21, $05,  $a9, $76, $0a,  $bf, $02, $01,  $e4, $57, $03,  $f6, $9a, $0b
  .byte $03  ,  $45, $cd, $0f,  $6e, $ce, $0e,  $9e, $cc, $0e
  .byte $04  ,  $56, $03, $01,  $5d, $bf, $0a,  $88, $46, $07,  $bf, $77, $08
  .byte $00
  .byte $07  ,  $1c, $cd, $0e,  $24, $ae, $09,  $2a, $79, $05,  $56, $45, $09,  $68, $35, $06,  $9e, $02, $01,  $b1, $46, $02
  .byte $02  ,  $5d, $58, $04,  $fb, $68, $07
  .byte $07  ,  $1c, $69, $03,  $50, $ca, $0e,  $56, $9c, $06,  $88, $8b, $06,  $94, $db, $0e,  $cc, $dc, $0f,  $f8, $dc, $0e
  .byte $5d  ,  $03, $bd, $0c,  $08, $df, $0e,  $19, $53, $06,  $1a, $ac, $0b,  $22, $aa, $08,  $24, $47, $02,  $27, $bb, $09,  $29, $fe, $0f,  $2b, $b9, $0d,  $2c, $ca, $0d,  $3a, $9d, $07,  $3d, $cb, $0d,  $3e, $ba, $0d,  $41, $a8, $0b,  $44, $b9, $0c,  $45, $ba, $0a,  $47, $a9, $0a,  $4a, $ba, $0b,  $4b, $ce, $08,  $4c, $cb, $0c,  $4d, $ad, $07,  $4e, $ae, $08,  $4f, $8a, $05,  $55, $ed, $0d,  $61, $ed, $0e,  $67, $7a, $04,  $68, $cc, $0d,  $6c, $ee, $0f,  $6e, $ba, $0c,  $72, $32, $02,  $73, $43, $03,  $74, $43, $04,  $75, $54, $04,  $77, $65, $05,  $79, $76, $06,  $7a, $87, $07,  $7d, $98, $08,  $7e, $87, $08,  $7f, $a9, $09,  $80, $aa, $0a,  $82, $bb, $0a,  $86, $cb, $0b,  $87, $bb, $0b,  $8e, $cc, $0c,  $8f, $dd, $0d,  $96, $76, $07,  $98, $98, $09,  $99, $8a, $06,  $9a, $ad, $08,  $9e, $be, $08,  $9f, $ac, $07,  $a1, $ee, $0d,  $a2, $65, $06,  $a3, $bf, $09,  $a9, $cf, $09,  $ab, $bd, $08,  $ad, $ab, $07,  $b0, $54, $05,  $b2, $ce, $09,  $b4, $cd, $09,  $b5, $cd, $0a,  $b7, $bc, $09,  $b8, $ef, $0c,  $bd, $9c, $07,  $c1, $68, $04,  $c2, $7a, $05,  $c6, $8b, $05,  $c9, $9b, $06,  $ca, $79, $04,  $ce, $58, $03,  $cf, $69, $04,  $d0, $de, $0b,  $d2, $8c, $06,  $d5, $de, $0a,  $da, $ce, $0d,  $db, $ef, $0f,  $dc, $df, $0a,  $df, $ee, $0e,  $e0, $dc, $0d,  $e1, $68, $03,  $e3, $57, $02,  $e5, $dc, $0c,  $e7, $de, $0e,  $e9, $bb, $0c,  $ea, $dd, $0e,  $eb, $88, $09,  $f0, $99, $0a,  $f2, $fe, $0e,  $f3, $43, $05,  $f6, $54, $06,  $f7, $65, $07,  $fb, $76, $08,  $fd, $87, $09
  .byte $07  ,  $57, $9a, $06,  $66, $58, $02,  $92, $6a, $04,  $93, $43, $06,  $c8, $7b, $05,  $d1, $97, $0a,  $e8, $45, $02
  .byte $0b  ,  $22, $8a, $09,  $27, $59, $03,  $29, $ca, $0c,  $4b, $47, $03,  $52, $69, $06,  $53, $34, $01,  $ad, $a8, $0c,  $d3, $23, $00,  $de, $67, $03,  $e3, $be, $0b,  $ee, $cf, $0c
  .byte $06  ,  $4e, $cd, $0e,  $6b, $9b, $0a,  $93, $36, $01,  $b4, $aa, $08,  $be, $24, $01,  $ca, $36, $02
  .byte $0f  ,  $19, $57, $06,  $27, $7a, $07,  $29, $35, $01,  $36, $cd, $09,  $3a, $77, $05,  $52, $dd, $0b,  $53, $59, $04,  $57, $fe, $0f,  $a3, $ee, $0c,  $ad, $57, $02,  $c0, $aa, $0b,  $c8, $98, $0a,  $de, $a9, $0b,  $e1, $21, $03,  $f1, $a9, $0c
  .byte $05  ,  $26, $79, $04,  $6b, $bf, $09,  $83, $8b, $08,  $92, $13, $00,  $b4, $34, $01
  .byte $0c  ,  $19, $9b, $0a,  $29, $ff, $0d,  $36, $25, $01,  $3a, $68, $03,  $3b, $58, $05,  $52, $11, $03,  $53, $13, $01,  $64, $69, $06,  $a3, $42, $05,  $a6, $7b, $05,  $d3, $44, $02,  $e8, $8c, $07
  .byte $02  ,  $4d, $ec, $0f,  $4e, $45, $02
  .byte $0b  ,  $29, $9d, $07,  $36, $9d, $06,  $3b, $df, $0f,  $52, $bd, $0d,  $66, $9c, $0a,  $83, $ad, $07,  $92, $57, $07,  $a3, $cd, $0e,  $c4, $59, $04,  $d3, $79, $09,  $e8, $43, $06
  .byte $06  ,  $41, $ed, $0f,  $4d, $25, $02,  $4e, $a8, $0c,  $53, $8b, $08,  $93, $9d, $09,  $ad, $24, $03
  .byte $05  ,  $66, $ec, $0f,  $92, $53, $06,  $a3, $58, $05,  $ca, $a8, $0b,  $d3, $97, $0b
  .byte $05  ,  $4d, $fd, $0f,  $4e, $dd, $0f,  $93, $cd, $0e,  $be, $cc, $0e,  $e8, $aa, $0c
  .byte $0e  ,  $0c, $87, $0d,  $23, $77, $0d,  $26, $98, $0e,  $2d, $99, $0f,  $2e, $97, $0c,  $32, $a9, $0f,  $36, $76, $0b,  $4f, $98, $0d,  $65, $32, $06,  $a3, $86, $0b,  $aa, $53, $07,  $b4, $42, $06,  $b6, $43, $07,  $c4, $87, $0c
  .byte $08  ,  $4b, $24, $01,  $53, $13, $00,  $5b, $24, $02,  $64, $12, $00,  $6b, $ff, $0d,  $9e, $34, $02,  $b1, $35, $02,  $f4, $13, $01
  .byte $0b  ,  $0c, $db, $0c,  $23, $ec, $0d,  $26, $9c, $0a,  $2d, $ca, $0f,  $32, $cb, $0f,  $36, $54, $07,  $65, $21, $04,  $a3, $ba, $0e,  $aa, $cc, $0f,  $b4, $32, $05,  $c4, $89, $0a
  .byte $35  ,  $0f, $da, $0f,  $1c, $12, $04,  $24, $c9, $0e,  $27, $be, $08,  $29, $53, $05,  $3a, $fd, $0e,  $3f, $01, $03,  $45, $56, $08,  $4b, $67, $09,  $53, $87, $0c,  $56, $ab, $08,  $5a, $ab, $0d,  $5b, $99, $0d,  $5d, $23, $05,  $5f, $22, $05,  $60, $69, $06,  $64, $aa, $0e,  $67, $b9, $0f,  $6b, $a9, $0e,  $72, $64, $08,  $73, $ba, $0f,  $77, $b9, $0e,  $79, $bb, $0f,  $7a, $10, $03,  $7d, $31, $04,  $7f, $23, $04,  $81, $88, $0a,  $82, $bb, $0d,  $83, $01, $02,  $86, $86, $08,  $91, $98, $0c,  $92, $79, $09,  $9e, $88, $0b,  $a6, $33, $06,  $a8, $87, $0b,  $a9, $44, $07,  $ae, $55, $08,  $b1, $65, $09,  $c1, $45, $06,  $c5, $34, $05,  $c6, $bc, $0d,  $c9, $44, $06,  $ce, $67, $08,  $cf, $33, $05,  $d2, $55, $07,  $d4, $65, $08,  $d5, $66, $08,  $dd, $77, $09,  $e4, $11, $03,  $e5, $00, $02,  $ee, $12, $03,  $f2, $43, $06,  $f4, $22, $04
  .byte $03  ,  $0c, $47, $02,  $23, $47, $01,  $26, $58, $02
  .byte $0e  ,  $0f, $9e, $06,  $24, $98, $08,  $27, $b8, $0d,  $2d, $13, $01,  $2e, $ae, $06,  $3a, $cf, $0c,  $3b, $23, $01,  $4f, $34, $02,  $53, $97, $08,  $67, $66, $05,  $6b, $cb, $0b,  $73, $87, $07,  $77, $a9, $09,  $b6, $53, $06
  .byte $15  ,  $1c, $c9, $0e,  $32, $89, $0b,  $3f, $88, $0c,  $45, $9a, $0d,  $4b, $9e, $08,  $4d, $69, $03,  $52, $6a, $04,  $5a, $47, $05,  $5d, $57, $03,  $64, $47, $03,  $72, $ae, $07,  $79, $58, $04,  $7d, $9d, $06,  $91, $59, $03,  $a3, $7b, $05,  $a8, $68, $03,  $a9, $20, $03,  $aa, $78, $09,  $ab, $cb, $0e,  $ae, $75, $08,  $b1, $de, $0f
  .byte $07  ,  $0f, $13, $00,  $27, $bf, $09,  $2d, $ff, $0c,  $2e, $78, $04,  $60, $cb, $0a,  $92, $db, $0c,  $d3, $45, $02
  .byte $3e  ,  $03, $24, $01,  $08, $77, $04,  $09, $35, $01,  $0c, $ba, $09,  $10, $54, $03,  $18, $56, $02,  $19, $9a, $06,  $1a, $a9, $08,  $1b, $22, $00,  $1c, $65, $04,  $22, $43, $02,  $23, $de, $0a,  $25, $bd, $08,  $26, $ef, $0b,  $29, $cf, $09,  $2b, $be, $08,  $2c, $cd, $09,  $31, $ee, $0b,  $32, $ee, $0c,  $33, $99, $08,  $36, $55, $04,  $37, $44, $03,  $39, $66, $04,  $3a, $77, $05,  $3c, $99, $07,  $3d, $ff, $0d,  $3e, $cc, $0b,  $3f, $bb, $0a,  $41, $67, $04,  $43, $cc, $0a,  $44, $55, $03,  $45, $56, $03,  $4b, $89, $06,  $4d, $dd, $0a,  $4e, $78, $05,  $50, $dd, $0b,  $52, $ba, $0a,  $57, $dc, $0c,  $58, $33, $02,  $5a, $aa, $08,  $5b, $76, $06,  $5f, $22, $01,  $61, $11, $00,  $62, $65, $05,  $64, $43, $03,  $65, $ca, $0b,  $66, $53, $04,  $68, $88, $06,  $69, $bb, $09,  $6a, $12, $00,  $6c, $ab, $07,  $6e, $44, $02,  $72, $68, $04,  $78, $bc, $08,  $79, $10, $00,  $7a, $33, $01,  $7b, $21, $01,  $7c, $fe, $0e,  $7d, $cc, $09,  $7f, $32, $02,  $81, $57, $04,  $82, $46, $03
  .byte $0b  ,  $0f, $34, $01,  $38, $b9, $0a,  $83, $88, $05,  $84, $01, $01,  $86, $87, $06,  $88, $23, $00,  $89, $dc, $0b,  $8a, $76, $05,  $8b, $32, $01,  $8c, $a8, $09,  $8d, $98, $07
  .byte $0e  ,  $08, $35, $02,  $10, $24, $00,  $1c, $13, $00,  $2e, $89, $05,  $54, $aa, $07,  $66, $36, $01,  $6f, $75, $06,  $74, $33, $04,  $91, $36, $02,  $93, $67, $03,  $94, $13, $01,  $95, $58, $04,  $9c, $9b, $06,  $9d, $02, $00
  .byte $17  ,  $38, $47, $03,  $7d, $58, $03,  $83, $9c, $08,  $8a, $69, $04,  $8c, $64, $05,  $9e, $8b, $06,  $a3, $9b, $09,  $a5, $57, $05,  $a6, $11, $02,  $a7, $46, $02,  $a8, $ae, $09,  $a9, $77, $04,  $aa, $54, $03,  $ab, $47, $02,  $ad, $21, $02,  $ae, $34, $04,  $b0, $69, $05,  $b1, $ac, $0a,  $b4, $ae, $08,  $b6, $9c, $06,  $bc, $24, $02,  $be, $8a, $05,  $bf, $79, $04
  .byte $04  ,  $18, $bb, $08,  $2e, $76, $05,  $54, $46, $04,  $66, $cf, $0b
  .byte $02  ,  $03, $54, $05,  $14, $57, $02
  .byte $04  ,  $22, $a8, $09,  $2e, $9b, $08,  $38, $88, $05,  $54, $86, $07
  .byte $01  ,  $03, $24, $01
  .byte $04  ,  $09, $43, $04,  $10, $89, $05,  $14, $65, $04,  $19, $76, $05
  .byte $02  ,  $03, $56, $02,  $1c, $68, $06
  .byte $04  ,  $08, $df, $09,  $09, $cc, $09,  $0f, $fe, $0d,  $10, $99, $06
  .byte $03  ,  $0e, $43, $04,  $14, $89, $09,  $18, $ed, $0c
  .byte $02  ,  $03, $8a, $07,  $08, $77, $08
  .byte $03  ,  $0e, $78, $08,  $0f, $9a, $06,  $18, $56, $06
  .byte $00
  .byte $04  ,  $08, $54, $05,  $0f, $8a, $08,  $10, $79, $07,  $19, $46, $04
  .byte $02  ,  $0e, $89, $05,  $14, $ad, $07
  .byte $01  ,  $0c, $bf, $08
  .byte $13  ,  $0e, $b4, $0f,  $22, $b5, $0f,  $38, $a5, $0f,  $4d, $10, $09,  $53, $c5, $0f,  $54, $c6, $0f,  $6c, $20, $0a,  $78, $92, $0d,  $86, $92, $0e,  $89, $a4, $0f,  $8b, $a4, $0e,  $8c, $d6, $0f,  $8d, $a3, $0f,  $93, $d5, $0f,  $9f, $e7, $0f,  $a9, $b6, $0f,  $aa, $93, $0e,  $be, $32, $0c,  $bf, $82, $0d
  .byte $06  ,  $09, $41, $06,  $1a, $95, $0f,  $2c, $c9, $0e,  $31, $c4, $0f,  $5b, $96, $0d,  $7a, $97, $0d
  .byte $03  ,  $23, $a6, $0e,  $73, $33, $01,  $86, $32, $01
  .byte $08  ,  $1a, $52, $0e,  $31, $a8, $0e,  $50, $84, $0f,  $5b, $69, $03,  $60, $14, $08,  $65, $42, $03,  $92, $77, $04,  $93, $66, $03
  .byte $07  ,  $24, $41, $0d,  $2c, $85, $08,  $6f, $96, $0d,  $7c, $14, $05,  $86, $52, $0d,  $8d, $b5, $0d,  $a8, $dd, $0b
  .byte $03  ,  $1a, $9d, $06,  $50, $85, $07,  $65, $97, $0c
  .byte $05  ,  $24, $25, $0b,  $2c, $24, $0b,  $5b, $13, $0a,  $8d, $63, $0e,  $a8, $01, $07
  .byte $02  ,  $1a, $23, $09,  $53, $97, $08
  .byte $09  ,  $24, $15, $0b,  $2c, $c5, $0f,  $31, $05, $0b,  $50, $74, $06,  $5b, $59, $0b,  $7c, $15, $08,  $86, $86, $07,  $8d, $34, $0a,  $a8, $26, $09
  .byte $06  ,  $0c, $37, $0a,  $1a, $ee, $0b,  $23, $92, $0e,  $53, $73, $0d,  $62, $15, $09,  $7a, $dd, $0b
  .byte $08  ,  $24, $26, $0b,  $31, $25, $0b,  $3a, $c4, $0f,  $50, $01, $07,  $60, $d5, $0f,  $7c, $26, $0a,  $86, $48, $0b,  $8d, $23, $09
  .byte $07  ,  $0c, $13, $0b,  $1a, $fc, $0f,  $53, $36, $0b,  $62, $23, $08,  $68, $36, $0c,  $6f, $8b, $0f,  $92, $46, $0b
  .byte $08  ,  $43, $47, $0d,  $50, $23, $0a,  $5a, $02, $08,  $60, $fe, $0e,  $65, $93, $0f,  $7c, $46, $0c,  $8d, $34, $0a,  $b6, $cb, $0a
  .byte $09  ,  $0c, $24, $0b,  $1a, $23, $0b,  $24, $e6, $0f,  $31, $8a, $0f,  $3a, $9d, $0f,  $62, $77, $04,  $7a, $aa, $08,  $86, $cc, $0a,  $a8, $14, $08
  .byte $06  ,  $23, $e8, $0f,  $50, $34, $0c,  $65, $9c, $06,  $7e, $84, $0e,  $8d, $7b, $0f,  $b6, $23, $09
  .byte $04  ,  $24, $d5, $0f,  $43, $86, $08,  $68, $92, $0e,  $a8, $6a, $0d
  .byte $05  ,  $23, $71, $0d,  $27, $dd, $0b,  $3a, $23, $08,  $7e, $bd, $07,  $8d, $92, $0f
  .byte $0a  ,  $0c, $bf, $09,  $1a, $ee, $0b,  $24, $25, $05,  $50, $36, $07,  $5a, $46, $08,  $7b, $35, $07,  $7c, $45, $08,  $a8, $54, $08,  $b4, $55, $09,  $b6, $62, $08
  .byte $04  ,  $53, $e8, $0f,  $5b, $c4, $0f,  $8d, $46, $0c,  $ab, $23, $09
  .byte $05  ,  $23, $47, $02,  $24, $36, $08,  $60, $52, $07,  $7f, $74, $08,  $ca, $36, $09
  .byte $08  ,  $1a, $f7, $0f,  $2c, $d5, $0f,  $44, $e6, $0f,  $5b, $9d, $0f,  $68, $63, $0e,  $7e, $14, $08,  $8d, $71, $0d,  $ab, $70, $0b
  .byte $01  ,  $24, $69, $0e
  .byte $0f  ,  $0c, $35, $0b,  $14, $12, $09,  $1a, $92, $0e,  $29, $ee, $0b,  $2b, $73, $0e,  $2c, $00, $09,  $44, $21, $0c,  $5b, $45, $0b,  $64, $54, $0e,  $65, $51, $06,  $7e, $66, $0b,  $8d, $35, $0a,  $ab, $34, $07,  $ca, $35, $08,  $d1, $44, $08
  .byte $04  ,  $23, $34, $0e,  $27, $24, $0a,  $75, $65, $0f,  $77, $97, $0a
  .byte $0b  ,  $0c, $35, $0c,  $0e, $44, $0e,  $14, $23, $0b,  $22, $fc, $0e,  $29, $33, $0d,  $2b, $02, $08,  $3c, $cf, $09,  $44, $36, $0b,  $53, $c9, $0c,  $65, $23, $09,  $7d, $eb, $0d
  .byte $09  ,  $23, $23, $0c,  $39, $45, $0e,  $50, $30, $0a,  $62, $35, $0b,  $68, $30, $0b,  $77, $99, $07,  $8a, $fe, $0d,  $93, $69, $0f,  $9c, $dd, $0b
  .byte $0d  ,  $0e, $24, $0b,  $1a, $47, $0d,  $22, $36, $0c,  $25, $25, $0c,  $29, $63, $0e,  $3c, $57, $0d,  $44, $00, $0a,  $53, $60, $09,  $5b, $36, $09,  $64, $53, $08,  $65, $25, $07,  $7d, $24, $06,  $ec, $45, $09
  .byte $0b  ,  $0c, $45, $0b,  $2b, $96, $0b,  $3a, $23, $09,  $50, $35, $0d,  $52, $14, $08,  $89, $66, $04,  $8a, $bd, $08,  $93, $56, $0d,  $aa, $73, $0e,  $c2, $a9, $09,  $dc, $26, $0a
  .byte $0f  ,  $0e, $df, $0a,  $14, $34, $0c,  $1a, $97, $0a,  $22, $7a, $05,  $25, $be, $09,  $31, $ba, $0a,  $39, $23, $08,  $3c, $36, $07,  $44, $a7, $09,  $5b, $25, $06,  $65, $51, $07,  $6e, $31, $05,  $79, $ca, $0d,  $7f, $61, $08,  $8d, $52, $08
  .byte $0a  ,  $23, $46, $0e,  $24, $24, $0c,  $2b, $15, $0b,  $62, $23, $0b,  $68, $54, $0e,  $6f, $36, $09,  $8a, $45, $0e,  $92, $45, $0c,  $93, $96, $0a,  $aa, $74, $08
  .byte $06  ,  $0c, $35, $0e,  $14, $13, $0c,  $27, $12, $0b,  $39, $69, $04,  $44, $c9, $0c,  $50, $04, $0a
  .byte $0b  ,  $23, $13, $0b,  $2c, $01, $09,  $5b, $45, $0d,  $62, $45, $0b,  $68, $30, $0a,  $75, $64, $05,  $89, $23, $08,  $8a, $51, $06,  $92, $15, $09,  $aa, $04, $08,  $dc, $86, $0b
  .byte $07  ,  $0c, $13, $0a,  $14, $47, $02,  $27, $02, $09,  $3a, $15, $08,  $44, $66, $04,  $52, $cf, $09,  $8b, $74, $08
  .byte $0b  ,  $23, $54, $0e,  $24, $85, $08,  $26, $94, $0e,  $2b, $12, $0a,  $2c, $86, $07,  $5b, $ad, $07,  $68, $95, $0a,  $8a, $56, $0d,  $92, $be, $08,  $aa, $cb, $0e,  $dc, $61, $09
  .byte $06  ,  $0c, $23, $0b,  $14, $ef, $0b,  $1b, $25, $07,  $27, $14, $08,  $3a, $86, $0b,  $65, $23, $09
  .byte $0b  ,  $24, $24, $0c,  $2b, $51, $06,  $2c, $12, $0b,  $31, $51, $07,  $44, $70, $0b,  $57, $00, $09,  $62, $45, $0d,  $68, $87, $0c,  $6b, $76, $0c,  $75, $34, $08,  $8a, $03, $06
  .byte $06  ,  $23, $a3, $0e,  $3a, $01, $09,  $43, $b5, $0f,  $64, $40, $0a,  $65, $13, $0b,  $8b, $a4, $0f
  .byte $06  ,  $24, $02, $0a,  $2b, $b4, $0f,  $2c, $74, $08,  $44, $77, $04,  $62, $04, $08,  $c2, $53, $08
  .byte $06  ,  $0c, $fb, $0f,  $3a, $02, $09,  $64, $8a, $0f,  $65, $25, $05,  $7a, $25, $08,  $89, $24, $07
  .byte $05  ,  $24, $a4, $0c,  $2c, $7a, $04,  $31, $93, $0f,  $44, $26, $0a,  $60, $b6, $0c
  .byte $07  ,  $27, $fc, $0f,  $29, $51, $07,  $3a, $74, $08,  $50, $aa, $08,  $65, $ba, $0a,  $6f, $56, $0d,  $c2, $37, $0a
  .byte $06  ,  $0c, $c5, $0f,  $31, $92, $0e,  $44, $a4, $0d,  $57, $36, $09,  $60, $a4, $0e,  $86, $64, $05
  .byte $03  ,  $65, $fb, $0f,  $6f, $52, $07,  $c2, $14, $08
  .byte $04  ,  $1b, $14, $05,  $3a, $8b, $0f,  $62, $a2, $0f,  $86, $03, $05
  .byte $05  ,  $2c, $fa, $0f,  $31, $70, $09,  $44, $ba, $0a,  $53, $13, $05,  $c2, $23, $06
  .byte $08  ,  $1b, $34, $00,  $3a, $45, $01,  $62, $46, $01,  $7a, $87, $06,  $7f, $cb, $0b,  $86, $65, $04,  $8d, $58, $02,  $a8, $a9, $09
  .byte $33  ,  $09, $35, $01,  $0c, $44, $01,  $0f, $47, $01,  $10, $69, $03,  $18, $cc, $0a,  $19, $35, $02,  $1a, $34, $01,  $1c, $55, $03,  $23, $77, $05,  $24, $22, $00,  $25, $66, $04,  $26, $88, $06,  $27, $44, $02,  $29, $dc, $0c,  $2b, $98, $08,  $2c, $87, $07,  $31, $76, $06,  $38, $65, $05,  $3c, $32, $02,  $43, $87, $08,  $4d, $21, $01,  $52, $54, $04,  $53, $10, $00,  $54, $32, $03,  $57, $43, $04,  $5a, $de, $0a,  $5b, $cb, $0a,  $5c, $13, $00,  $60, $cd, $09,  $64, $24, $01,  $65, $67, $03,  $66, $56, $02,  $68, $89, $05,  $6b, $ab, $07,  $6c, $66, $03,  $6e, $55, $02,  $6f, $24, $00,  $74, $9a, $06,  $75, $78, $04,  $78, $57, $02,  $79, $8a, $05,  $7b, $68, $03,  $7c, $bd, $08,  $7d, $bc, $08,  $7e, $99, $06,  $83, $47, $02,  $84, $33, $00,  $89, $9b, $06,  $8a, $ac, $07,  $8b, $58, $03,  $8c, $79, $04
  .byte $06  ,  $92, $77, $04,  $93, $68, $02,  $94, $43, $03,  $95, $55, $06,  $97, $32, $01,  $9a, $ba, $09
  .byte $05  ,  $86, $33, $04,  $91, $56, $06,  $9b, $10, $01,  $9f, $45, $05,  $a0, $dd, $0a
  .byte $06  ,  $7a, $7a, $04,  $93, $57, $01,  $97, $ed, $0e,  $9a, $77, $08,  $a3, $cc, $0d,  $a5, $8b, $05
  .byte $06  ,  $10, $cf, $0a,  $5b, $8a, $08,  $7e, $54, $03,  $a0, $98, $07,  $a9, $fe, $0e,  $aa, $44, $05
  .byte $06  ,  $0f, $ad, $08,  $7a, $be, $09,  $91, $68, $02,  $92, $35, $03,  $93, $a9, $08,  $9d, $88, $05
  .byte $03  ,  $10, $99, $06,  $22, $ee, $0b,  $39, $77, $04
  .byte $05  ,  $0f, $dd, $0a,  $7a, $01, $01,  $7e, $68, $06,  $83, $9a, $0a,  $91, $ab, $0b
  .byte $0b  ,  $4d, $56, $06,  $8d, $35, $00,  $92, $32, $01,  $9b, $76, $05,  $9e, $7a, $05,  $a5, $69, $04,  $ab, $65, $04,  $b0, $fe, $0f,  $b4, $ee, $0f,  $b6, $aa, $07,  $bb, $cc, $09
  .byte $04  ,  $5b, $10, $01,  $5c, $87, $06,  $7a, $cb, $0a,  $7e, $21, $01
  .byte $02  ,  $39, $54, $03,  $83, $bb, $08
  .byte $0f  ,  $22, $9a, $0a,  $5c, $8a, $08,  $64, $77, $04,  $7a, $bc, $0c,  $8b, $78, $08,  $8d, $cd, $0d,  $91, $bd, $0c,  $92, $ce, $0c,  $9e, $79, $08,  $a3, $df, $0e,  $a5, $68, $07,  $a9, $35, $05,  $ab, $8a, $0a,  $bc, $df, $0f,  $bd, $de, $0f
  .byte $0a  ,  $10, $ee, $0b,  $39, $47, $02,  $83, $69, $04,  $9f, $cb, $0a,  $a0, $cc, $0d,  $be, $43, $02,  $bf, $ce, $0e,  $c1, $ac, $0b,  $c2, $9b, $0a,  $c6, $bd, $0b
  .byte $0e  ,  $22, $ac, $0d,  $5c, $ab, $0b,  $62, $99, $06,  $7c, $dc, $0b,  $8b, $65, $04,  $9e, $bd, $0d,  $a5, $fe, $0e,  $a9, $ba, $09,  $ab, $bd, $0e,  $c4, $9b, $0b,  $c5, $ce, $0f,  $c8, $9b, $0c,  $c9, $cd, $0e,  $ca, $ab, $0c
  .byte $06  ,  $0e, $bc, $0d,  $39, $32, $01,  $83, $98, $07,  $9b, $9c, $0c,  $9d, $ac, $0c,  $c2, $ed, $0c
  .byte $04  ,  $22, $88, $05,  $5b, $76, $05,  $5c, $01, $01,  $6f, $cf, $0e
  .byte $01  ,  $0e, $45, $05
  .byte $03  ,  $0f, $87, $06,  $22, $24, $00,  $4d, $02, $00
  .byte $03  ,  $0e, $24, $01,  $10, $12, $02,  $5c, $13, $00
  .byte $03  ,  $1b, $ee, $0b,  $22, $79, $07,  $4d, $89, $09
  .byte $00
  .byte $01  ,  $10, $54, $03
  .byte $03  ,  $0f, $34, $00,  $1b, $10, $01,  $22, $8a, $08
  .byte $05  ,  $0c, $24, $00,  $39, $79, $07,  $4d, $68, $06,  $5b, $46, $04,  $62, $02, $00
  .byte $01  ,  $22, $76, $05
  .byte $00
  .byte $04  ,  $09, $78, $08,  $0c, $9b, $09,  $1b, $87, $06,  $4d, $57, $06
  .byte $02  ,  $0f, $68, $07,  $5b, $8a, $08
  .byte $01  ,  $09, $32, $01
  .byte $03  ,  $0c, $79, $08,  $1b, $10, $01,  $2d, $35, $04
  .byte $01  ,  $0e, $87, $06
  .byte $01  ,  $0c, $24, $01
  .byte $03  ,  $0f, $89, $09,  $1b, $56, $06,  $2d, $35, $03
  .byte $00
  .byte $01  ,  $0f, $10, $01
  .byte $01  ,  $1b, $ff, $0c
  .byte $00
  .byte $03  ,  $08, $21, $00,  $09, $9a, $0a,  $2d, $89, $09
  .byte $06  ,  $22, $54, $05,  $39, $9b, $09,  $3a, $32, $01,  $4d, $46, $04,  $5b, $57, $05,  $5c, $35, $03
  .byte $02  ,  $08, $13, $00,  $09, $76, $05
  .byte $01  ,  $10, $13, $01
  .byte $02  ,  $1b, $21, $00,  $2d, $54, $03
  .byte $00
  .byte $00
  .byte $01  ,  $0f, $ff, $0c
  .byte $00
  .byte $15  ,  $09, $01, $0a,  $0e, $02, $0b,  $1b, $02, $0a,  $64, $2a, $01,  $6c, $01, $09,  $6f, $02, $09,  $7c, $2a, $00,  $84, $03, $09,  $8b, $29, $00,  $93, $03, $0a,  $9b, $39, $01,  $9f, $3a, $01,  $ab, $29, $01,  $b6, $12, $09,  $bb, $19, $00,  $bc, $4a, $01,  $be, $13, $09,  $c2, $02, $08,  $c5, $01, $08,  $dc, $4b, $02,  $e1, $28, $01
  .byte $10  ,  $1c, $03, $0b,  $23, $df, $0f,  $25, $13, $0b,  $27, $fc, $0f,  $29, $34, $0b,  $2d, $8a, $0a,  $3a, $28, $02,  $3c, $7d, $05,  $55, $03, $07,  $66, $52, $0a,  $6e, $79, $0a,  $73, $31, $08,  $7e, $a8, $0f,  $83, $b9, $0f,  $a5, $53, $0b,  $a9, $35, $00
  .byte $0a  ,  $26, $35, $0b,  $2b, $46, $0b,  $2c, $24, $0b,  $44, $5b, $04,  $53, $25, $07,  $65, $89, $04,  $77, $36, $08,  $7f, $41, $09,  $bf, $66, $04,  $c8, $58, $01
  .byte $0b  ,  $09, $57, $0d,  $0e, $ce, $0e,  $1c, $21, $04,  $24, $cb, $0e,  $25, $21, $03,  $29, $25, $09,  $55, $00, $08,  $73, $10, $05,  $7e, $8e, $06,  $97, $52, $0b,  $a8, $ba, $0a
  .byte $04  ,  $1b, $77, $02,  $2c, $cb, $08,  $3a, $98, $06,  $77, $8b, $03
  .byte $0c  ,  $0e, $d8, $0f,  $1c, $f9, $0f,  $23, $fb, $0f,  $29, $d9, $0f,  $3c, $94, $0b,  $44, $40, $08,  $55, $a6, $0d,  $73, $35, $0c,  $7c, $b7, $0e,  $7e, $46, $0d,  $97, $42, $08,  $e3, $ea, $0f
  .byte $08  ,  $1b, $fa, $0f,  $2c, $c7, $0e,  $3a, $c7, $0f,  $68, $a5, $0f,  $77, $01, $0a,  $a8, $b7, $0d,  $bf, $e9, $0f,  $c8, $95, $0b
  .byte $07  ,  $0e, $c8, $0f,  $1c, $7d, $05,  $3c, $10, $05,  $65, $36, $08,  $7e, $ba, $0a,  $97, $24, $0b,  $a5, $02, $0a
  .byte $0a  ,  $1b, $ce, $0f,  $25, $56, $0e,  $2c, $53, $0b,  $3a, $41, $0a,  $55, $8c, $08,  $68, $89, $04,  $a8, $2a, $00,  $bf, $25, $0b,  $c8, $6a, $07,  $e3, $37, $04
  .byte $06  ,  $3c, $ea, $0f,  $44, $42, $08,  $53, $10, $00,  $65, $59, $06,  $73, $7b, $08,  $ab, $14, $0b
  .byte $0a  ,  $1b, $20, $05,  $25, $46, $00,  $3a, $a5, $0e,  $55, $ce, $07,  $68, $07, $00,  $7f, $63, $0b,  $97, $53, $0c,  $bf, $63, $0c,  $c8, $ad, $06,  $e3, $9d, $06
  .byte $0b  ,  $09, $02, $0b,  $0e, $38, $00,  $23, $85, $0f,  $27, $10, $06,  $29, $22, $0a,  $3c, $94, $0e,  $53, $03, $07,  $65, $7d, $04,  $73, $21, $04,  $a8, $12, $0a,  $ab, $66, $04
  .byte $06  ,  $1b, $55, $0d,  $1c, $c8, $0f,  $25, $5a, $05,  $26, $21, $03,  $50, $41, $0a,  $97, $20, $04
  .byte $08  ,  $0e, $41, $09,  $23, $35, $0b,  $27, $45, $0d,  $29, $10, $00,  $3c, $11, $09,  $53, $57, $0d,  $65, $73, $0a,  $77, $49, $01
  .byte $04  ,  $1b, $34, $0c,  $1c, $31, $06,  $25, $10, $05,  $ab, $7d, $04
  .byte $05  ,  $53, $6a, $07,  $55, $25, $0b,  $68, $63, $0d,  $97, $73, $0b,  $9e, $74, $0e
  .byte $06  ,  $1b, $30, $06,  $25, $22, $0a,  $3a, $7d, $05,  $77, $66, $0e,  $7c, $41, $07,  $ab, $95, $0a
  .byte $05  ,  $27, $53, $0c,  $2c, $20, $06,  $53, $74, $0d,  $55, $84, $0e,  $75, $8d, $06
  .byte $05  ,  $29, $57, $0d,  $65, $53, $0b,  $97, $56, $0e,  $ab, $85, $0f,  $c8, $31, $0a
  .byte $03  ,  $27, $45, $0d,  $2c, $38, $00,  $77, $6a, $07
  .byte $04  ,  $25, $20, $06,  $97, $73, $0b,  $ab, $41, $08,  $c4, $73, $0a
  .byte $08  ,  $0e, $eb, $0c,  $1b, $ea, $0c,  $27, $24, $0c,  $29, $fb, $0e,  $65, $fc, $0e,  $77, $eb, $0d,  $9f, $25, $0c,  $c8, $ec, $0c
  .byte $21  ,  $09, $fc, $0f,  $1c, $03, $0c,  $25, $13, $0c,  $26, $87, $05,  $2c, $b9, $08,  $2d, $76, $04,  $3a, $cd, $06,  $3c, $db, $0a,  $44, $a8, $07,  $50, $88, $02,  $53, $ca, $09,  $55, $78, $01,  $64, $65, $03,  $66, $46, $00,  $68, $66, $01,  $6c, $88, $03,  $6e, $fe, $0b,  $6f, $dd, $07,  $73, $ee, $08,  $75, $eb, $0b,  $7c, $da, $0a,  $7f, $9a, $03,  $83, $79, $0f,  $84, $54, $02,  $97, $cb, $08,  $9e, $dc, $09,  $a5, $ec, $0b,  $a8, $25, $0b,  $ab, $89, $02,  $bf, $14, $0c,  $c4, $fd, $0c,  $dc, $35, $0c,  $e3, $77, $0e
  .byte $05  ,  $1b, $4b, $03,  $29, $53, $0b,  $65, $52, $0b,  $91, $5a, $04,  $9f, $63, $0c
  .byte $1e  ,  $0e, $56, $0e,  $26, $46, $0d,  $2c, $47, $0d,  $2d, $d9, $0f,  $3a, $02, $09,  $3c, $22, $0a,  $44, $02, $0b,  $50, $01, $09,  $53, $bd, $0c,  $55, $21, $04,  $64, $74, $05,  $66, $10, $00,  $68, $62, $09,  $6c, $74, $0e,  $6e, $52, $0c,  $6f, $25, $07,  $73, $84, $0e,  $75, $63, $0d,  $77, $74, $0d,  $7c, $64, $0c,  $7f, $8c, $07,  $83, $8d, $06,  $84, $9d, $05,  $97, $74, $0c,  $9e, $85, $0e,  $a5, $84, $0d,  $ab, $8c, $06,  $bf, $8d, $05,  $c4, $84, $0c,  $c8, $85, $0d
  .byte $00
  .byte $0b  ,  $0e, $44, $0c,  $1c, $9b, $0b,  $26, $36, $0c,  $2c, $9d, $0a,  $2d, $12, $0a,  $64, $03, $09,  $66, $73, $0b,  $68, $75, $0d,  $6e, $95, $0e,  $6f, $96, $0f,  $bf, $76, $0d
  .byte $03  ,  $25, $41, $08,  $65, $45, $0d,  $73, $41, $07
  .byte $07  ,  $09, $13, $0c,  $0e, $3a, $02,  $1c, $53, $0c,  $27, $52, $0b,  $2c, $5b, $03,  $66, $64, $0d,  $dc, $86, $0e
  .byte $05  ,  $25, $55, $0d,  $50, $42, $0b,  $65, $44, $0c,  $73, $10, $00,  $a5, $74, $05
  .byte $05  ,  $1b, $24, $0c,  $26, $34, $0c,  $75, $9b, $0b,  $a8, $67, $0f,  $c4, $84, $0d
  .byte $04  ,  $25, $01, $09,  $2c, $66, $0e,  $50, $84, $0c,  $73, $3a, $01
  .byte $06  ,  $27, $3b, $02,  $84, $2a, $01,  $91, $25, $0b,  $a5, $29, $01,  $a8, $5b, $03,  $e0, $84, $0e
  .byte $01  ,  $1b, $12, $0b
  .byte $05  ,  $26, $fc, $0f,  $27, $45, $0d,  $2c, $dc, $0d,  $3c, $52, $0b,  $75, $6a, $07
  .byte $00
  .byte $05  ,  $26, $c8, $0e,  $3c, $d9, $0f,  $50, $be, $0c,  $75, $1a, $00,  $91, $8c, $08
  .byte $01  ,  $27, $84, $0c
  .byte $05  ,  $2c, $3b, $02,  $2d, $c8, $0f,  $3c, $29, $02,  $50, $ae, $0b,  $65, $63, $0d
  .byte $05  ,  $1b, $44, $0c,  $27, $12, $0a,  $7c, $62, $09,  $a9, $37, $04,  $dc, $77, $0f
  .byte $02  ,  $3c, $33, $0c,  $75, $bf, $0b
  .byte $06  ,  $09, $30, $05,  $27, $12, $0b,  $2d, $a5, $0d,  $50, $83, $0b,  $a9, $b6, $0d,  $dc, $57, $0d
  .byte $02  ,  $3c, $ae, $0a,  $9d, $c8, $0f
  .byte $08  ,  $1b, $ac, $0c,  $1c, $41, $07,  $50, $a5, $0e,  $68, $b6, $0f,  $7c, $94, $0c,  $91, $84, $0b,  $a9, $95, $0f,  $dc, $c7, $0f
  .byte $05  ,  $09, $62, $09,  $26, $53, $0c,  $27, $85, $0f,  $75, $84, $0c,  $9d, $9c, $05
  .byte $01  ,  $68, $4d, $04
  .byte $26  ,  $09, $48, $06,  $1b, $3d, $03,  $1c, $4b, $02,  $24, $8d, $08,  $25, $8d, $07,  $26, $8e, $05,  $27, $7e, $06,  $29, $7d, $06,  $2b, $7e, $05,  $2d, $7b, $07,  $3a, $6e, $05,  $44, $8f, $06,  $50, $7c, $06,  $64, $7d, $05,  $65, $03, $05,  $66, $7b, $06,  $6c, $7c, $05,  $6e, $5c, $03,  $6f, $8f, $07,  $73, $6d, $05,  $75, $8e, $06,  $77, $9f, $06,  $7e, $02, $05,  $84, $84, $0a,  $94, $94, $0b,  $97, $95, $0c,  $9d, $54, $0b,  $9e, $44, $0a,  $9f, $87, $0d,  $a9, $16, $01,  $bd, $26, $02,  $bf, $59, $04,  $c4, $5c, $04,  $c8, $7b, $05,  $c9, $8e, $07,  $dc, $9f, $07,  $e0, $6d, $04,  $e3, $6c, $05
  .byte $02  ,  $47, $3c, $03,  $ca, $3a, $03
  .byte $06  ,  $09, $04, $05,  $1b, $27, $04,  $23, $a9, $0a,  $24, $7d, $07,  $7c, $43, $03,  $e7, $15, $02
  .byte $03  ,  $53, $37, $05,  $65, $59, $07,  $ea, $de, $0f
  .byte $04  ,  $1b, $37, $06,  $1c, $03, $05,  $24, $8d, $08,  $e7, $25, $07
  .byte $03  ,  $09, $04, $07,  $b0, $2a, $01,  $ea, $dd, $0e
  .byte $04  ,  $1b, $2a, $02,  $24, $15, $07,  $da, $fe, $0f,  $e7, $2b, $02
  .byte $06  ,  $53, $25, $07,  $65, $41, $07,  $6c, $5d, $03,  $b0, $15, $03,  $ca, $7e, $04,  $de, $54, $03
  .byte $03  ,  $1b, $fb, $0d,  $24, $eb, $0b,  $bb, $ea, $0c
  .byte $09  ,  $47, $08, $00,  $65, $2c, $01,  $94, $1b, $01,  $a5, $2b, $01,  $a9, $b6, $0d,  $b0, $c8, $0e,  $b4, $2a, $02,  $ca, $2a, $01,  $e7, $17, $00
  .byte $05  ,  $1b, $de, $0f,  $24, $15, $05,  $8c, $83, $09,  $bb, $8e, $08,  $de, $94, $0b
  .byte $04  ,  $53, $15, $04,  $79, $26, $06,  $b0, $84, $0c,  $cc, $7e, $04
  .byte $0a  ,  $09, $04, $04,  $24, $8a, $05,  $47, $48, $08,  $8c, $8b, $05,  $94, $1a, $01,  $ab, $3c, $03,  $b4, $94, $0a,  $bb, $94, $0c,  $ca, $85, $0c,  $da, $44, $0b
  .byte $06  ,  $1b, $cd, $0e,  $53, $04, $05,  $79, $8c, $06,  $a8, $4e, $03,  $a9, $9c, $0c,  $b0, $53, $0b
  .byte $03  ,  $09, $3a, $03,  $8c, $19, $00,  $b4, $36, $09
  .byte $09  ,  $1b, $07, $00,  $24, $7c, $05,  $47, $03, $04,  $94, $86, $0c,  $a8, $53, $0a,  $a9, $35, $0a,  $b0, $16, $01,  $c1, $03, $03,  $f8, $59, $09
  .byte $01  ,  $c8, $dc, $0e
  .byte $02  ,  $09, $ee, $0f,  $1b, $b6, $0c
  .byte $01  ,  $db, $cd, $0e
  .byte $04  ,  $09, $3a, $03,  $4c, $4e, $03,  $53, $4d, $02,  $f8, $1b, $01
  .byte $01  ,  $ab, $37, $05
  .byte $03  ,  $b4, $1a, $00,  $c1, $cb, $0d,  $c8, $3d, $02
  .byte $03  ,  $8c, $8d, $08,  $ab, $48, $06,  $db, $26, $04
  .byte $01  ,  $ca, $cb, $0e
  .byte $04  ,  $1b, $cc, $0e,  $8c, $36, $09,  $bb, $37, $05,  $ea, $03, $03
  .byte $02  ,  $ab, $49, $05,  $db, $dc, $0e
  .byte $04  ,  $1b, $38, $04,  $65, $04, $05,  $8c, $39, $04,  $c1, $8d, $08
  .byte $02  ,  $b4, $fc, $0e,  $bb, $fc, $0f
  .byte $36  ,  $09, $db, $08,  $0e, $ed, $0f,  $1b, $eb, $0f,  $1c, $b7, $0b,  $24, $ca, $07,  $25, $d9, $0d,  $26, $fb, $0c,  $27, $64, $02,  $29, $8b, $05,  $2b, $c9, $08,  $2c, $b8, $07,  $2d, $fb, $0d,  $3a, $86, $03,  $3c, $c8, $0c,  $44, $fb, $0f,  $47, $cb, $07,  $4c, $44, $09,  $50, $da, $0e,  $53, $54, $0a,  $64, $43, $0a,  $65, $65, $0c,  $66, $64, $0b,  $68, $66, $0b,  $6c, $55, $0b,  $6e, $02, $04,  $6f, $88, $0d,  $73, $04, $02,  $75, $46, $09,  $77, $35, $08,  $79, $ca, $08,  $7f, $35, $01,  $83, $98, $04,  $84, $26, $01,  $8c, $36, $00,  $91, $cc, $07,  $97, $eb, $0d,  $a5, $10, $05,  $a9, $10, $06,  $ab, $32, $07,  $b0, $21, $06,  $bf, $a7, $0a,  $c1, $da, $0d,  $c4, $33, $08,  $c8, $a6, $0b,  $c9, $43, $09,  $cc, $54, $09,  $dc, $01, $05,  $de, $65, $0b,  $e0, $64, $0a,  $e1, $75, $0c,  $e3, $25, $02,  $e7, $88, $0c,  $ea, $45, $06,  $f8, $a7, $07
  .byte $00
  .byte $1c  ,  $09, $16, $01,  $0e, $8c, $06,  $1b, $7b, $09,  $1c, $8d, $07,  $24, $8f, $05,  $25, $6f, $04,  $26, $5f, $04,  $27, $7f, $05,  $2b, $8e, $05,  $2c, $5e, $04,  $2d, $7d, $06,  $3a, $7e, $05,  $3c, $7f, $06,  $44, $7c, $07,  $47, $7c, $06,  $50, $3e, $03,  $74, $6e, $05,  $79, $7d, $05,  $83, $5e, $03,  $91, $7e, $06,  $97, $8f, $06,  $b4, $7e, $04,  $bb, $5d, $04,  $bf, $36, $08,  $c1, $94, $0a,  $c8, $94, $0c,  $ca, $07, $00,  $f8, $6e, $04
  .byte $00
  .byte $04  ,  $29, $08, $00,  $44, $1a, $01,  $47, $37, $07,  $a3, $15, $05
  .byte $01  ,  $da, $df, $0e
  .byte $03  ,  $47, $eb, $0f,  $a3, $9a, $06,  $c1, $6e, $03
  .byte $00
  .byte $06  ,  $47, $48, $06,  $75, $7c, $07,  $94, $4f, $03,  $bf, $26, $04,  $c1, $35, $0b,  $ca, $1a, $00
  .byte $03  ,  $74, $36, $08,  $89, $48, $08,  $db, $0b, $00
  .byte $05  ,  $25, $9b, $06,  $73, $dc, $0e,  $75, $8b, $05,  $7b, $7c, $06,  $bf, $44, $0b
  .byte $00
  .byte $06  ,  $1b, $8d, $0a,  $47, $6e, $03,  $75, $6f, $04,  $89, $04, $02,  $c1, $86, $0d,  $c8, $4e, $03
  .byte $01  ,  $bf, $48, $08
  .byte $08  ,  $26, $7b, $09,  $47, $07, $00,  $50, $94, $0a,  $73, $6c, $06,  $94, $6d, $05,  $c1, $5d, $03,  $ca, $8e, $06,  $db, $5c, $03
  .byte $00
  .byte $03  ,  $26, $38, $04,  $73, $de, $0f,  $bf, $6e, $05
  .byte $05  ,  $1b, $7a, $03,  $50, $8b, $05,  $6c, $69, $03,  $74, $7b, $05,  $89, $59, $03
  .byte $23  ,  $08, $7b, $03,  $09, $7b, $04,  $0e, $25, $01,  $0f, $47, $01,  $10, $7a, $04,  $14, $48, $02,  $15, $6b, $04,  $17, $6a, $03,  $1c, $5a, $03,  $1d, $59, $02,  $1e, $58, $01,  $20, $6a, $04,  $22, $37, $01,  $23, $48, $01,  $24, $9c, $06,  $26, $36, $02,  $27, $46, $01,  $29, $47, $02,  $2b, $58, $03,  $2c, $68, $03,  $2d, $69, $04,  $31, $7a, $05,  $33, $79, $04,  $36, $58, $02,  $37, $56, $02,  $38, $8a, $05,  $3a, $8b, $06,  $3b, $9c, $07,  $3c, $ad, $08,  $3e, $bd, $08,  $3f, $68, $06,  $40, $69, $05,  $43, $47, $03,  $44, $8a, $08,  $47, $79, $07
  .byte $02  ,  $48, $cc, $0b,  $4a, $8c, $05
  .byte $01  ,  $46, $58, $04
  .byte $0e  ,  $49, $69, $02,  $4c, $9b, $05,  $4d, $bb, $0a,  $4f, $8b, $04,  $51, $36, $01,  $52, $35, $00,  $53, $6a, $02,  $54, $25, $00,  $55, $45, $01,  $57, $89, $05,  $58, $24, $00,  $5a, $aa, $08,  $5c, $78, $04,  $5f, $7a, $06
  .byte $01  ,  $08, $34, $02
  .byte $02  ,  $0c, $78, $07,  $0e, $67, $03
  .byte $03  ,  $15, $13, $00,  $19, $88, $06,  $1c, $99, $07
  .byte $02  ,  $0c, $35, $02,  $1a, $9c, $08
  .byte $04  ,  $15, $34, $01,  $19, $24, $01,  $1c, $ac, $0b,  $26, $9a, $0a
  .byte $03  ,  $1a, $23, $01,  $4a, $46, $04,  $4c, $9b, $0a
  .byte $06  ,  $19, $78, $07,  $1b, $de, $0a,  $1c, $99, $08,  $26, $13, $00,  $3f, $df, $0a,  $49, $8b, $07
  .byte $09  ,  $0e, $67, $06,  $4c, $34, $00,  $4f, $69, $02,  $55, $24, $01,  $57, $9c, $08,  $5a, $ce, $0d,  $5b, $de, $0e,  $5c, $ab, $0b,  $61, $ef, $0f
  .byte $07  ,  $1b, $89, $05,  $37, $45, $04,  $3f, $89, $08,  $49, $89, $09,  $63, $78, $04,  $64, $ac, $0b,  $65, $67, $03
  .byte $05  ,  $0e, $9a, $0a,  $44, $35, $03,  $47, $56, $02,  $5a, $79, $08,  $5b, $77, $05
  .byte $10  ,  $37, $67, $06,  $4a, $55, $04,  $4c, $12, $01,  $4f, $44, $02,  $53, $88, $06,  $55, $79, $07,  $64, $22, $00,  $66, $68, $06,  $67, $99, $07,  $68, $33, $02,  $6e, $aa, $08,  $6f, $45, $01,  $73, $de, $0a,  $75, $55, $03,  $77, $66, $04,  $79, $cf, $0c
  .byte $0f  ,  $44, $56, $05,  $5a, $de, $0e,  $61, $44, $03,  $63, $66, $05,  $7b, $33, $01,  $7c, $77, $06,  $7e, $24, $01,  $80, $8a, $08,  $83, $11, $00,  $84, $be, $0a,  $86, $be, $09,  $8b, $cf, $0b,  $8f, $be, $0b,  $91, $be, $0c,  $93, $bd, $0c
  .byte $08  ,  $1c, $45, $04,  $55, $ef, $0f,  $66, $78, $04,  $87, $dd, $0d,  $94, $34, $00,  $95, $13, $01,  $96, $22, $01,  $97, $ab, $0c
  .byte $19  ,  $73, $dc, $0d,  $79, $db, $0e,  $8b, $dc, $0e,  $8f, $9c, $05,  $91, $99, $08,  $98, $bb, $0b,  $9a, $dd, $0f,  $9b, $dd, $0e,  $9d, $79, $07,  $9e, $df, $0a,  $9f, $8a, $0b,  $a2, $79, $0b,  $a5, $ca, $0d,  $a6, $9b, $0c,  $a8, $8a, $0c,  $a9, $79, $0a,  $aa, $cb, $0d,  $ab, $ed, $0f,  $ad, $fd, $0f,  $ae, $ac, $06,  $b0, $ed, $0e,  $b4, $bb, $0d,  $b6, $fe, $0f,  $ba, $ee, $0f,  $bb, $cb, $0c
  .byte $1d  ,  $0e, $78, $08,  $4c, $79, $08,  $6f, $79, $09,  $70, $68, $06,  $76, $9b, $05,  $80, $7a, $08,  $87, $7b, $08,  $95, $69, $02,  $ac, $de, $0a,  $bc, $de, $0f,  $bd, $7a, $09,  $be, $8b, $07,  $bf, $96, $0e,  $c0, $97, $0e,  $c1, $88, $0e,  $c2, $68, $0c,  $c3, $79, $0c,  $c4, $78, $0d,  $c5, $7a, $0a,  $c8, $9b, $0b,  $c9, $78, $0b,  $ca, $77, $0c,  $cb, $7a, $07,  $cc, $78, $0a,  $ce, $78, $09,  $cf, $77, $0b,  $d1, $8b, $08,  $d2, $ad, $07,  $d4, $89, $0b
  .byte $06  ,  $1c, $45, $01,  $73, $bc, $0d,  $79, $9a, $0b,  $84, $9a, $0c,  $8b, $89, $0a,  $8f, $cd, $0e
  .byte $0a  ,  $19, $45, $04,  $4c, $67, $07,  $6f, $46, $04,  $76, $ce, $0e,  $80, $23, $02,  $87, $ce, $0d,  $93, $13, $01,  $94, $35, $03,  $98, $57, $05,  $9a, $ac, $0c
  .byte $0a  ,  $86, $12, $01,  $9b, $79, $09,  $9e, $68, $09,  $a0, $9b, $05,  $a2, $78, $07,  $a5, $34, $03,  $aa, $34, $00,  $ab, $24, $02,  $ac, $57, $07,  $ad, $ac, $0d
  .byte $0e  ,  $0e, $67, $08,  $60, $77, $07,  $70, $7a, $03,  $76, $25, $01,  $87, $8a, $08,  $8e, $bb, $0b,  $93, $aa, $0a,  $95, $8c, $06,  $9a, $66, $06,  $a9, $dd, $0d,  $ae, $cc, $0d,  $b0, $55, $05,  $b2, $8a, $04,  $b4, $89, $0c
  .byte $12  ,  $43, $56, $06,  $6f, $78, $08,  $86, $68, $06,  $9b, $cc, $0c,  $9e, $df, $0a,  $9f, $88, $08,  $a6, $13, $01,  $ac, $be, $09,  $b6, $ac, $0c,  $ba, $8b, $04,  $bb, $78, $0c,  $bd, $ab, $0d,  $be, $9a, $0d,  $bf, $77, $04,  $c0, $66, $03,  $c1, $55, $02,  $c2, $99, $06,  $c4, $56, $07
  .byte $10  ,  $27, $ff, $0c,  $64, $ce, $0f,  $76, $df, $0f,  $7b, $cf, $09,  $8b, $36, $02,  $8e, $9b, $0c,  $94, $9a, $0a,  $95, $79, $08,  $96, $aa, $0b,  $b0, $ee, $0f,  $c5, $cd, $09,  $c8, $dd, $0e,  $ca, $bc, $0f,  $cb, $89, $0d,  $cf, $8a, $0d,  $d1, $cf, $0a
  .byte $0f  ,  $98, $46, $01,  $9e, $89, $0a,  $ac, $67, $09,  $ad, $ce, $09,  $ae, $46, $04,  $bb, $ac, $0b,  $bf, $bb, $0d,  $c0, $22, $01,  $c3, $35, $04,  $d8, $cf, $0b,  $d9, $47, $03,  $da, $bd, $0d,  $db, $ab, $0e,  $dc, $8a, $09,  $dd, $fe, $0e
  .byte $1a  ,  $1c, $ef, $0b,  $27, $cd, $0f,  $64, $68, $07,  $70, $55, $06,  $76, $33, $01,  $7b, $bb, $0b,  $8b, $9b, $0a,  $8e, $77, $0a,  $93, $22, $00,  $9b, $cc, $0e,  $a8, $88, $0a,  $aa, $77, $09,  $ab, $12, $01,  $c5, $9b, $0b,  $ca, $55, $05,  $ce, $df, $0e,  $cf, $55, $07,  $de, $bd, $0c,  $e0, $cc, $0d,  $e1, $be, $0a,  $e3, $57, $05,  $e4, $df, $0a,  $e5, $bc, $0e,  $e7, $99, $0d,  $ea, $aa, $0d,  $ec, $56, $08
  .byte $12  ,  $26, $f8, $0f,  $bb, $e7, $0f,  $c1, $fa, $0f,  $c3, $e8, $0f,  $d8, $e9, $0f,  $dd, $fb, $0f,  $ee, $fc, $0f,  $f2, $d6, $0f,  $f3, $ea, $0f,  $f4, $fd, $0f,  $f5, $ec, $0f,  $f6, $d6, $0e,  $f7, $d9, $0f,  $f8, $eb, $0f,  $f9, $ca, $0c,  $fa, $fe, $0f,  $fb, $dc, $0f,  $ff, $dc, $0e
  .byte $0a  ,  $1c, $46, $06,  $64, $33, $03,  $a6, $ac, $0d,  $ce, $46, $05,  $d9, $45, $07,  $de, $34, $00,  $e1, $34, $04,  $e4, $35, $06,  $e7, $33, $04,  $ec, $35, $05
  .byte $10  ,  $0e, $23, $03,  $1e, $22, $02,  $26, $be, $0a,  $27, $24, $02,  $49, $77, $04,  $55, $68, $07,  $5a, $13, $00,  $62, $66, $03,  $6e, $14, $00,  $79, $44, $06,  $7a, $44, $05,  $84, $44, $04,  $8b, $45, $01,  $8d, $45, $05,  $8e, $45, $06,  $8f, $34, $05
  .byte $05  ,  $09, $58, $01,  $1c, $ac, $06,  $59, $7a, $03,  $5c, $79, $03,  $6d, $35, $03
  .byte $12  ,  $62, $00, $08,  $76, $10, $08,  $a0, $10, $09,  $a6, $11, $08,  $b2, $00, $07,  $b6, $10, $07,  $bb, $02, $08,  $c1, $00, $05,  $c2, $20, $08,  $c3, $01, $07,  $d8, $20, $07,  $dd, $02, $09,  $ee, $30, $08,  $f2, $03, $09,  $f6, $00, $06,  $f8, $13, $0a,  $f9, $12, $09,  $ff, $60, $06
  .byte $2d  ,  $09, $21, $0f,  $0f, $10, $0e,  $10, $32, $0f,  $14, $11, $0f,  $17, $22, $0e,  $1b, $f6, $0f,  $1c, $33, $0f,  $1d, $f5, $0f,  $20, $20, $0e,  $22, $32, $0e,  $23, $31, $0e,  $24, $42, $0f,  $25, $00, $0c,  $29, $e6, $0f,  $2b, $20, $0d,  $2c, $42, $0e,  $2d, $f8, $0f,  $33, $e4, $0f,  $36, $f7, $0f,  $38, $52, $0f,  $3e, $f9, $0f,  $47, $d5, $0f,  $50, $e5, $0f,  $51, $53, $0f,  $52, $d4, $0f,  $54, $52, $0e,  $58, $44, $0e,  $59, $20, $0b,  $5c, $00, $0b,  $65, $31, $0c,  $66, $32, $0d,  $6b, $21, $0c,  $6c, $d6, $0f,  $78, $41, $0d,  $7d, $10, $0b,  $89, $22, $0c,  $8a, $fa, $0f,  $8b, $31, $0d,  $8c, $fb, $0f,  $98, $30, $0c,  $a3, $e7, $0f,  $a7, $c4, $0f,  $ba, $c3, $0f,  $d2, $e9, $0f,  $de, $e8, $0f
  .byte $0b  ,  $15, $04, $08,  $31, $91, $0c,  $32, $04, $09,  $3a, $af, $0c,  $4f, $92, $0c,  $6e, $70, $08,  $74, $93, $0b,  $7f, $46, $08,  $93, $81, $0b,  $9c, $c6, $0e,  $d3, $7b, $08
  .byte $15  ,  $09, $9f, $0f,  $0f, $af, $0f,  $10, $9f, $0e,  $14, $43, $0f,  $17, $f4, $0f,  $1c, $9e, $0e,  $20, $9e, $0f,  $22, $df, $0a,  $23, $ff, $0b,  $25, $56, $0d,  $2b, $58, $06,  $50, $9e, $0d,  $52, $9f, $0d,  $5c, $66, $0e,  $66, $58, $09,  $72, $36, $06,  $89, $9d, $0c,  $8b, $47, $08,  $98, $d9, $0e,  $a7, $67, $0f,  $ba, $9f, $09
  .byte $0e  ,  $15, $91, $0f,  $2a, $af, $0e,  $31, $60, $0e,  $32, $68, $0e,  $3a, $14, $09,  $49, $58, $0c,  $4f, $36, $02,  $69, $70, $0f,  $6e, $36, $0a,  $74, $8d, $0f,  $93, $7a, $05,  $9c, $61, $0d,  $ad, $79, $0f,  $d3, $33, $0c
  .byte $26  ,  $09, $93, $0b,  $0f, $92, $0c,  $10, $93, $0c,  $14, $82, $0a,  $17, $80, $0b,  $1b, $69, $04,  $1d, $ce, $09,  $22, $45, $02,  $23, $62, $05,  $24, $dd, $0b,  $29, $ee, $0c,  $2c, $87, $07,  $2d, $76, $05,  $33, $bb, $09,  $36, $ed, $0d,  $38, $54, $03,  $3e, $81, $0b,  $47, $24, $00,  $51, $68, $04,  $52, $79, $05,  $54, $50, $0b,  $58, $60, $0d,  $5c, $60, $0b,  $66, $52, $0a,  $6b, $42, $0b,  $6c, $61, $0b,  $72, $70, $0b,  $78, $70, $0d,  $7d, $60, $0c,  $8a, $71, $0e,  $8b, $80, $0e,  $8c, $52, $0b,  $98, $71, $0b,  $a3, $70, $0c,  $ba, $71, $0d,  $d2, $80, $0d,  $de, $81, $0e,  $f3, $53, $0b
  .byte $0e  ,  $25, $d4, $0f,  $2b, $c3, $0f,  $31, $a1, $0f,  $32, $9f, $0f,  $49, $c4, $0f,  $59, $af, $0f,  $65, $a2, $0f,  $69, $a0, $0f,  $6e, $8e, $0f,  $74, $ea, $0f,  $9c, $80, $0a,  $a7, $a3, $0d,  $ad, $a4, $0c,  $d3, $90, $0f
  .byte $06  ,  $1d, $d5, $0f,  $23, $d6, $0f,  $36, $c2, $0f,  $47, $92, $0b,  $52, $a2, $0d,  $8a, $a5, $0b
  .byte $0d  ,  $1c, $e6, $0f,  $20, $e5, $0f,  $2a, $91, $0c,  $32, $61, $0d,  $50, $90, $0e,  $59, $36, $09,  $69, $14, $00,  $6e, $10, $01,  $89, $94, $0b,  $9c, $60, $05,  $a7, $87, $06,  $ad, $62, $0a,  $d3, $61, $0c
  .byte $05  ,  $1b, $95, $09,  $2d, $58, $08,  $51, $85, $07,  $52, $ce, $09,  $8a, $96, $09
  .byte $07  ,  $22, $76, $05,  $23, $ed, $0d,  $58, $36, $07,  $59, $79, $05,  $6c, $a4, $0c,  $74, $70, $06,  $a0, $72, $0b
  .byte $04  ,  $1b, $fb, $0f,  $2d, $26, $02,  $8a, $41, $03,  $93, $04, $09
  .byte $0c  ,  $09, $83, $07,  $1c, $47, $08,  $20, $60, $0d,  $22, $61, $0b,  $23, $91, $0b,  $45, $46, $02,  $58, $20, $09,  $59, $71, $0c,  $6c, $81, $0d,  $74, $80, $0c,  $a7, $91, $0e,  $ad, $b2, $0f
  .byte $0d  ,  $1b, $69, $0c,  $1d, $58, $0a,  $29, $79, $05,  $2d, $34, $01,  $32, $85, $0b,  $36, $76, $0b,  $50, $75, $0c,  $51, $63, $0b,  $52, $54, $0b,  $8a, $82, $0b,  $93, $73, $0b,  $e5, $81, $0c,  $f4, $82, $0d
  .byte $08  ,  $1c, $e5, $0f,  $23, $d5, $0f,  $45, $fc, $0f,  $58, $b1, $0f,  $6b, $c2, $0f,  $7f, $9f, $09,  $ba, $d9, $0e,  $d3, $93, $0b
  .byte $05  ,  $1b, $e8, $0f,  $20, $fd, $0f,  $2d, $e9, $0f,  $32, $d6, $0f,  $9b, $a3, $0d
  .byte $05  ,  $24, $fb, $0f,  $58, $ea, $0f,  $6b, $d3, $0f,  $ba, $a8, $09,  $dd, $47, $0a
  .byte $02  ,  $1d, $e6, $0f,  $69, $97, $08
  .byte $06  ,  $17, $a3, $0b,  $1c, $da, $0c,  $24, $23, $0b,  $6b, $b8, $0b,  $7f, $91, $0b,  $dd, $71, $0d
  .byte $05  ,  $09, $a4, $0a,  $1b, $d9, $0e,  $2d, $93, $09,  $69, $14, $00,  $93, $01, $09
  .byte $08  ,  $17, $e8, $0f,  $1c, $fb, $0f,  $1d, $e9, $0f,  $24, $83, $07,  $29, $82, $08,  $6b, $84, $08,  $9b, $73, $0b,  $ba, $c8, $0c
  .byte $07  ,  $09, $34, $0c,  $1b, $42, $03,  $23, $90, $0f,  $2d, $69, $04,  $45, $20, $01,  $54, $61, $0c,  $d3, $62, $0a
  .byte $06  ,  $17, $d5, $0f,  $1c, $fc, $0f,  $29, $66, $0e,  $47, $50, $0b,  $6b, $93, $0b,  $ba, $85, $0b
  .byte $08  ,  $09, $fb, $0f,  $1b, $83, $08,  $24, $92, $0b,  $2d, $a7, $0a,  $45, $97, $08,  $54, $a7, $09,  $7f, $79, $05,  $89, $82, $0e
  .byte $04  ,  $1d, $e8, $0f,  $29, $84, $08,  $31, $95, $09,  $32, $83, $07
  .byte $08  ,  $17, $96, $09,  $1b, $47, $08,  $23, $76, $05,  $45, $62, $0b,  $54, $72, $0d,  $69, $92, $0f,  $6b, $84, $0b,  $93, $91, $0d
  .byte $04  ,  $25, $e9, $0f,  $29, $d6, $0f,  $31, $01, $09,  $7f, $97, $08
  .byte $04  ,  $17, $fa, $0f,  $23, $46, $02,  $2d, $ec, $0d,  $74, $72, $0c
  .byte $0a  ,  $1d, $8b, $0f,  $25, $7b, $0f,  $29, $82, $08,  $2b, $9f, $09,  $32, $84, $08,  $47, $83, $08,  $49, $80, $0c,  $7f, $35, $01,  $ad, $ca, $0b,  $d3, $42, $03
  .byte $0a  ,  $09, $34, $0c,  $15, $76, $05,  $17, $83, $07,  $1c, $79, $05,  $23, $36, $07,  $2d, $70, $0e,  $45, $83, $0e,  $65, $92, $0e,  $69, $84, $0f,  $a7, $76, $0a
  .byte $09  ,  $18, $e8, $0f,  $1d, $62, $0a,  $25, $66, $0e,  $2a, $92, $0f,  $2b, $44, $0c,  $38, $75, $0b,  $7f, $93, $0f,  $ad, $55, $0d,  $d3, $45, $0c
  .byte $02  ,  $1b, $fb, $0f,  $23, $e9, $0f
  .byte $0a  ,  $18, $fa, $0f,  $1c, $a7, $0a,  $25, $a2, $0d,  $3a, $82, $0f,  $45, $83, $0f,  $58, $46, $0b,  $65, $54, $0c,  $7f, $83, $0d,  $ad, $83, $0b,  $d3, $82, $0c
  .byte $05  ,  $09, $fc, $0f,  $1b, $ea, $0f,  $23, $93, $0f,  $69, $42, $0b,  $6e, $14, $09
  .byte $08  ,  $18, $e9, $0f,  $1c, $91, $0f,  $24, $83, $0e,  $25, $93, $0b,  $2b, $15, $02,  $3a, $92, $0e,  $58, $63, $0d,  $65, $55, $0d
  .byte $06  ,  $1b, $9e, $0f,  $4f, $94, $0b,  $6e, $79, $05,  $8c, $54, $0c,  $93, $47, $09,  $9b, $10, $01
  .byte $09  ,  $14, $fa, $0f,  $1c, $ea, $0f,  $22, $af, $0f,  $25, $14, $09,  $2b, $7a, $05,  $31, $36, $02,  $32, $84, $0f,  $58, $91, $0d,  $65, $71, $0e
  .byte $07  ,  $18, $61, $0b,  $1b, $03, $04,  $3a, $82, $0a,  $6e, $91, $0f,  $93, $52, $0b,  $9c, $01, $09,  $b0, $42, $03
  .byte $09  ,  $14, $fb, $0f,  $1c, $60, $0d,  $22, $52, $0c,  $25, $64, $0d,  $2b, $73, $0d,  $32, $63, $0c,  $45, $84, $0a,  $47, $92, $0d,  $54, $75, $0e
  .byte $0b  ,  $18, $84, $08,  $1b, $60, $05,  $1d, $14, $03,  $20, $82, $0f,  $2a, $64, $0c,  $38, $65, $0d,  $4f, $75, $0a,  $58, $84, $0e,  $6e, $55, $0c,  $9c, $56, $0b,  $b0, $74, $0a
  .byte $03  ,  $22, $fd, $0f,  $54, $97, $08,  $69, $75, $0b
  .byte $04  ,  $14, $69, $03,  $18, $df, $0a,  $20, $47, $01,  $6e, $ed, $0f
  .byte $3b  ,  $09, $25, $04,  $0f, $42, $03,  $10, $47, $0b,  $17, $34, $00,  $1b, $73, $0b,  $1c, $74, $0b,  $1d, $73, $0c,  $23, $74, $0d,  $24, $75, $09,  $25, $84, $09,  $29, $84, $0d,  $2d, $83, $0a,  $32, $64, $0b,  $38, $74, $0c,  $3e, $65, $0c,  $47, $66, $0b,  $49, $22, $04,  $54, $74, $09,  $59, $84, $0c,  $5c, $95, $0e,  $62, $94, $0d,  $65, $75, $08,  $66, $b6, $0f,  $6c, $a4, $0e,  $72, $73, $0a,  $74, $54, $09,  $76, $64, $0a,  $78, $85, $0d,  $7d, $65, $0b,  $7f, $76, $0d,  $89, $36, $08,  $8a, $85, $0c,  $8b, $64, $09,  $8c, $95, $0d,  $93, $75, $07,  $98, $a6, $0f,  $9c, $a5, $0e,  $a0, $94, $0c,  $a3, $73, $09,  $b2, $21, $04,  $b4, $53, $09,  $bb, $74, $08,  $bc, $63, $0a,  $c2, $54, $08,  $cb, $cd, $0e,  $d2, $76, $0c,  $d3, $55, $09,  $da, $86, $0d,  $db, $65, $0a,  $dd, $87, $0e,  $de, $8c, $06,  $e5, $03, $02,  $ea, $64, $08,  $f4, $95, $0c,  $f5, $53, $04,  $f6, $a6, $0e,  $f7, $a5, $0d,  $f9, $31, $04,  $fb, $53, $08
  .byte $03  ,  $14, $dd, $0f,  $2b, $ee, $0f,  $bd, $58, $0c
  .byte $0a  ,  $10, $ec, $0f,  $17, $47, $07,  $20, $47, $06,  $3a, $35, $00,  $47, $ab, $0d,  $58, $14, $04,  $6c, $63, $0c,  $89, $b5, $0f,  $be, $75, $0d,  $f5, $95, $0a
  .byte $01  ,  $09, $58, $0d
  .byte $05  ,  $17, $03, $05,  $20, $36, $08,  $3a, $25, $04,  $6c, $31, $02,  $bd, $47, $0b
  .byte $08  ,  $09, $a8, $09,  $14, $ec, $0d,  $23, $46, $01,  $3e, $94, $0b,  $89, $36, $07,  $98, $93, $0b,  $be, $83, $0c,  $e5, $66, $0b
  .byte $07  ,  $17, $ea, $0f,  $20, $dc, $0f,  $22, $d9, $0f,  $3a, $93, $0c,  $5c, $74, $0d,  $62, $75, $0d,  $66, $04, $07
  .byte $0a  ,  $09, $dd, $0f,  $14, $65, $0c,  $3e, $63, $0c,  $89, $a7, $0a,  $8c, $58, $0b,  $98, $c8, $0f,  $9c, $72, $0a,  $e5, $86, $0c,  $f6, $96, $0d,  $f7, $c9, $0f
  .byte $02  ,  $22, $94, $0b,  $29, $42, $02
  .byte $08  ,  $17, $fd, $0f,  $23, $a5, $0d,  $58, $a6, $0e,  $6c, $95, $0d,  $89, $66, $0b,  $c3, $bd, $0d,  $f5, $53, $03,  $f7, $99, $05
  .byte $04  ,  $29, $25, $04,  $5c, $02, $06,  $66, $94, $0d,  $9c, $03, $05
  .byte $04  ,  $09, $d9, $0f,  $20, $47, $0a,  $c3, $03, $06,  $f7, $72, $0b
  .byte $07  ,  $17, $36, $07,  $29, $74, $0d,  $5c, $36, $08,  $89, $55, $02,  $bd, $45, $01,  $f5, $72, $0a,  $f9, $58, $0a
  .byte $04  ,  $09, $fd, $0f,  $20, $31, $04,  $98, $bb, $07,  $c3, $46, $08
  .byte $05  ,  $17, $47, $08,  $22, $25, $04,  $3a, $34, $00,  $bd, $03, $02,  $f7, $89, $0c
  .byte $07  ,  $09, $02, $06,  $5c, $94, $0b,  $8c, $dc, $0f,  $98, $93, $0c,  $9c, $66, $0b,  $c3, $ab, $0e,  $f6, $53, $03
  .byte $05  ,  $17, $03, $05,  $22, $03, $06,  $25, $dd, $0f,  $66, $58, $0b,  $89, $47, $09
  .byte $07  ,  $23, $25, $04,  $58, $52, $0a,  $5c, $77, $0d,  $6c, $53, $04,  $93, $42, $04,  $c3, $63, $09,  $f7, $32, $05
  .byte $03  ,  $25, $36, $07,  $33, $c9, $0f,  $de, $bb, $07
  .byte $05  ,  $1b, $36, $08,  $20, $55, $0c,  $3a, $dd, $0f,  $58, $75, $07,  $5c, $8c, $06
  .byte $04  ,  $22, $55, $0d,  $33, $32, $09,  $de, $a5, $0d,  $f9, $73, $0b
  .byte $03  ,  $20, $fc, $0f,  $3a, $fd, $0f,  $93, $03, $06
  .byte $08  ,  $0f, $ea, $0f,  $1d, $42, $04,  $22, $69, $03,  $23, $93, $0b,  $29, $65, $0d,  $89, $84, $09,  $bd, $76, $0e,  $de, $95, $0a
  .byte $03  ,  $1b, $d9, $0f,  $33, $74, $05,  $78, $73, $0c
  .byte $08  ,  $0f, $c8, $0f,  $22, $46, $01,  $23, $66, $0e,  $29, $aa, $06,  $52, $66, $0d,  $89, $94, $0b,  $9c, $31, $03,  $bd, $da, $0f
  .byte $05  ,  $20, $ea, $0f,  $25, $dd, $0f,  $78, $14, $04,  $8a, $42, $03,  $b2, $c9, $0f
  .byte $06  ,  $22, $04, $05,  $23, $21, $04,  $29, $96, $0d,  $66, $85, $0c,  $9c, $54, $0b,  $de, $52, $03
  .byte $04  ,  $78, $74, $0d,  $8c, $a6, $0e,  $98, $66, $0b,  $a0, $85, $0d
  .byte $0a  ,  $1b, $dc, $0f,  $20, $fc, $0f,  $22, $15, $05,  $25, $a5, $0d,  $33, $73, $0c,  $52, $82, $0b,  $8a, $73, $0d,  $9c, $46, $01,  $bd, $89, $0c,  $f6, $52, $0a
  .byte $02  ,  $98, $d9, $0f,  $de, $ea, $0f
  .byte $07  ,  $1b, $da, $0f,  $22, $14, $04,  $52, $03, $02,  $89, $31, $03,  $8a, $94, $0c,  $9c, $58, $0c,  $bd, $85, $0e
  .byte $02  ,  $1d, $dc, $0f,  $33, $65, $0d
  .byte $02  ,  $9c, $42, $04,  $de, $8c, $05
  .byte $05  ,  $10, $84, $08,  $1d, $82, $0c,  $22, $32, $09,  $3e, $a6, $0f,  $dd, $95, $0a
  .byte $0a  ,  $0f, $40, $03,  $1b, $b5, $0f,  $20, $83, $0d,  $3a, $73, $0d,  $52, $55, $0c,  $93, $84, $09,  $98, $94, $0e,  $b2, $93, $0d,  $c5, $57, $0b,  $f6, $86, $0e
  .byte $07  ,  $15, $83, $08,  $22, $54, $0c,  $29, $94, $09,  $33, $76, $0e,  $3e, $94, $0b,  $8c, $82, $0b,  $dd, $46, $01
  .byte $03  ,  $52, $dc, $0f,  $58, $a3, $0a,  $f6, $a5, $0a
  .byte $02  ,  $0f, $03, $07,  $fa, $9c, $05
  .byte $0f  ,  $17, $ec, $0f,  $1b, $30, $02,  $1d, $6a, $03,  $20, $02, $07,  $22, $03, $02,  $33, $63, $0c,  $3a, $66, $0b,  $58, $94, $0d,  $8c, $a4, $0e,  $98, $b5, $0e,  $9b, $83, $09,  $b6, $31, $02,  $dd, $cd, $0f,  $de, $57, $0c,  $f6, $57, $0a
  .byte $01  ,  $15, $58, $0c
  .byte $06  ,  $1d, $fd, $0f,  $20, $fe, $0f,  $98, $86, $0e,  $9b, $83, $08,  $c5, $11, $06,  $de, $35, $00
  .byte $03  ,  $1b, $b5, $0e,  $3a, $03, $05,  $8c, $b5, $0f
  .byte $07  ,  $0f, $a5, $0a,  $15, $a4, $0a,  $17, $83, $09,  $1d, $94, $0e,  $dd, $9a, $0d,  $de, $94, $0a,  $f6, $a5, $0f
  .byte $04  ,  $09, $a4, $0b,  $1b, $a4, $0e,  $b6, $82, $0b,  $bd, $82, $0c
  .byte $05  ,  $0f, $f8, $0f,  $22, $35, $0f,  $25, $e8, $0f,  $3a, $e7, $0f,  $fa, $f9, $0f
  .byte $01  ,  $15, $a5, $0a
  .byte $00
  .byte $10  ,  $09, $03, $07,  $10, $02, $07,  $15, $66, $02,  $17, $53, $0c,  $1b, $85, $0e,  $29, $66, $0b,  $3e, $c7, $0f,  $6c, $95, $0e,  $89, $95, $0a,  $93, $67, $0b,  $9b, $a6, $0f,  $9c, $96, $0e,  $b6, $b7, $0f,  $bb, $62, $0a,  $bd, $56, $0a,  $de, $97, $0e
  .byte $0a  ,  $0f, $84, $09,  $1d, $74, $08,  $22, $03, $02,  $25, $db, $0f,  $3a, $75, $07,  $78, $c8, $0f,  $8c, $a4, $0d,  $dd, $b8, $0f,  $f6, $73, $08,  $fa, $72, $09
  .byte $11  ,  $10, $37, $06,  $15, $26, $04,  $17, $48, $07,  $1b, $9a, $0d,  $3e, $82, $0b,  $58, $93, $0b,  $66, $54, $0c,  $6c, $36, $08,  $89, $d9, $0f,  $93, $cb, $0f,  $98, $b7, $0e,  $9b, $a6, $0e,  $9c, $a5, $0d,  $b2, $23, $05,  $b6, $53, $0a,  $bd, $54, $0b,  $de, $45, $09
  .byte $06  ,  $0f, $94, $0d,  $78, $95, $0a,  $a0, $c6, $0f,  $bb, $c7, $0e,  $dd, $b6, $0e,  $f6, $a5, $0e
  .byte $07  ,  $10, $74, $0d,  $15, $73, $08,  $17, $ca, $0a,  $22, $85, $0d,  $58, $84, $09,  $9b, $53, $04,  $fa, $53, $03
  .byte $08  ,  $0f, $72, $09,  $66, $94, $0b,  $8c, $52, $03,  $98, $74, $05,  $a0, $82, $0a,  $bb, $14, $04,  $dd, $87, $0e,  $f6, $31, $04
  .byte $08  ,  $17, $86, $0e,  $52, $30, $03,  $58, $14, $05,  $78, $03, $05,  $89, $02, $02,  $93, $12, $03,  $9c, $42, $05,  $f5, $11, $02
  .byte $06  ,  $0f, $dc, $0f,  $3a, $85, $0c,  $3e, $84, $09,  $66, $cb, $0e,  $8c, $03, $06,  $a0, $ca, $0f
  .byte $02  ,  $52, $95, $0a,  $de, $94, $0b
  .byte $05  ,  $25, $bd, $0f,  $3a, $13, $04,  $6c, $74, $07,  $9c, $64, $07,  $a0, $9c, $06
  .byte $05  ,  $3e, $b7, $0f,  $52, $ca, $0f,  $98, $c7, $0f,  $bb, $b8, $0f,  $f6, $95, $0e
  .byte $0a  ,  $15, $36, $08,  $18, $57, $0e,  $2c, $6b, $06,  $3b, $42, $04,  $3c, $04, $01,  $58, $42, $05,  $5c, $14, $04,  $9b, $6a, $07,  $a0, $6a, $0b,  $fa, $31, $04
  .byte $02  ,  $66, $94, $0e,  $76, $9e, $0d
  .byte $05  ,  $18, $01, $08,  $2c, $64, $0a,  $3c, $7b, $08,  $54, $22, $0a,  $9b, $53, $04
  .byte $04  ,  $09, $46, $0e,  $8c, $74, $09,  $99, $73, $08,  $b7, $6b, $06
  .byte $02  ,  $18, $34, $0c,  $76, $52, $0c
  .byte $05  ,  $1d, $46, $0b,  $78, $7b, $06,  $99, $15, $02,  $9b, $7b, $09,  $b7, $20, $0a
  .byte $06  ,  $09, $54, $02,  $10, $43, $01,  $24, $b5, $0f,  $33, $03, $05,  $8c, $20, $09,  $ba, $6b, $06
  .byte $09  ,  $1d, $85, $0b,  $20, $01, $09,  $51, $10, $0a,  $54, $23, $0b,  $5c, $01, $08,  $78, $cc, $09,  $a0, $21, $0b,  $ea, $32, $0b,  $fa, $76, $03
  .byte $09  ,  $09, $fe, $0f,  $10, $00, $0a,  $18, $64, $08,  $34, $75, $09,  $6c, $7b, $06,  $76, $65, $02,  $99, $23, $0c,  $c2, $63, $0b,  $de, $03, $07
  .byte $05  ,  $24, $31, $04,  $54, $74, $09,  $5c, $54, $08,  $67, $b6, $0e,  $7b, $6a, $0b
  .byte $04  ,  $34, $ac, $08,  $76, $13, $0b,  $98, $22, $0a,  $ba, $54, $01
  .byte $0a  ,  $09, $11, $0a,  $10, $01, $08,  $18, $11, $0b,  $24, $22, $0b,  $3e, $15, $02,  $66, $15, $07,  $67, $15, $06,  $78, $6b, $0a,  $99, $42, $0c,  $b7, $53, $0c
  .byte $06  ,  $22, $54, $02,  $2d, $54, $0e,  $46, $37, $09,  $98, $cc, $09,  $ba, $65, $02,  $f6, $02, $0a
  .byte $09  ,  $09, $55, $0d,  $10, $64, $08,  $18, $21, $0c,  $20, $75, $09,  $38, $31, $04,  $67, $58, $04,  $78, $84, $08,  $7b, $20, $0a,  $8c, $83, $0a
  .byte $05  ,  $46, $43, $01,  $54, $01, $09,  $76, $85, $0d,  $98, $22, $0a,  $e5, $63, $0c
  .byte $07  ,  $09, $74, $09,  $18, $15, $03,  $31, $55, $0e,  $53, $01, $08,  $7b, $11, $0a,  $de, $a4, $0e,  $fa, $58, $0c
  .byte $09  ,  $10, $10, $0b,  $23, $fe, $0f,  $24, $86, $0c,  $2d, $55, $0d,  $46, $03, $07,  $66, $88, $06,  $67, $36, $02,  $6e, $23, $0c,  $f6, $37, $09
  .byte $06  ,  $09, $6a, $08,  $20, $54, $01,  $3b, $01, $0a,  $45, $20, $0b,  $de, $58, $04,  $fa, $22, $0b
  .byte $04  ,  $18, $75, $09,  $6c, $74, $09,  $6e, $b6, $0e,  $9c, $42, $04
  .byte $01  ,  $45, $ed, $0f
  .byte $02  ,  $a3, $7b, $06,  $f6, $15, $07
  .byte $0a  ,  $09, $44, $0d,  $31, $48, $0b,  $3b, $05, $02,  $45, $59, $09,  $66, $26, $04,  $6c, $62, $0b,  $78, $53, $0d,  $8c, $64, $0e,  $99, $54, $0d,  $c2, $54, $0c
  .byte $08  ,  $18, $b7, $0f,  $53, $01, $0a,  $6e, $15, $0a,  $8b, $54, $0e,  $98, $73, $09,  $a3, $88, $06,  $e9, $6b, $06,  $f6, $37, $09
  .byte $0a  ,  $09, $83, $0a,  $23, $64, $09,  $2d, $ed, $0f,  $31, $58, $0c,  $3b, $01, $08,  $45, $13, $0b,  $48, $22, $0a,  $78, $84, $0a,  $9b, $15, $07,  $f7, $cc, $09
  .byte $06  ,  $6e, $bb, $0c,  $7b, $83, $09,  $8c, $61, $0b,  $bf, $64, $02,  $e9, $7b, $09,  $fa, $cc, $0b
  .byte $08  ,  $20, $ba, $0c,  $2c, $74, $09,  $31, $7b, $06,  $45, $53, $0d,  $66, $75, $09,  $a0, $32, $0c,  $f6, $65, $0e,  $f7, $64, $0d
  .byte $07  ,  $10, $c7, $0f,  $1d, $11, $0a,  $3b, $22, $0b,  $4f, $bb, $0d,  $53, $37, $09,  $7b, $75, $03,  $9b, $53, $02
  .byte $03  ,  $2d, $fe, $0f,  $31, $b5, $0f,  $67, $21, $0b
  .byte $07  ,  $38, $47, $0c,  $3b, $34, $0d,  $53, $ed, $0f,  $7b, $c6, $0f,  $8b, $d9, $0f,  $8c, $13, $0b,  $a0, $15, $07
  .byte $07  ,  $09, $25, $0b,  $45, $31, $04,  $4f, $37, $09,  $67, $48, $0b,  $a3, $15, $05,  $bf, $48, $09,  $e9, $38, $03
  .byte $05  ,  $1d, $48, $0c,  $3b, $64, $02,  $3c, $bb, $0d,  $8b, $83, $0a,  $8c, $58, $0c
  .byte $03  ,  $38, $cb, $0d,  $4f, $7b, $08,  $e9, $6b, $06
  .byte $07  ,  $09, $37, $0c,  $1d, $37, $09,  $51, $83, $09,  $8b, $6a, $08,  $8c, $65, $0f,  $9c, $74, $0d,  $a0, $55, $0c
  .byte $07  ,  $33, $48, $0c,  $66, $10, $0a,  $67, $57, $0e,  $bf, $58, $0c,  $e9, $7b, $09,  $fa, $83, $0a,  $fb, $cb, $0c
  .byte $08  ,  $09, $6b, $06,  $1d, $22, $0b,  $34, $6a, $0d,  $51, $cc, $0b,  $53, $75, $09,  $8b, $64, $0e,  $8c, $54, $0e,  $99, $55, $0e
  .byte $04  ,  $38, $48, $0d,  $67, $01, $0a,  $9b, $26, $0b,  $bf, $37, $0b
  .byte $0a  ,  $09, $ed, $0f,  $28, $42, $04,  $34, $7c, $08,  $3c, $37, $09,  $51, $7c, $06,  $54, $38, $04,  $8b, $53, $02,  $8c, $6a, $08,  $e9, $45, $0c,  $fb, $c5, $0f
  .byte $06  ,  $33, $37, $0c,  $4d, $00, $0a,  $56, $cb, $0d,  $67, $6a, $0d,  $9b, $03, $05,  $fa, $05, $0a
  .byte $08  ,  $28, $48, $0b,  $34, $54, $01,  $51, $75, $02,  $54, $cc, $0b,  $8b, $6b, $07,  $a7, $bb, $0a,  $b0, $ab, $08,  $e9, $75, $03
  .byte $0d  ,  $33, $74, $0a,  $38, $53, $00,  $48, $54, $0e,  $4d, $42, $04,  $4f, $dd, $0c,  $66, $76, $0a,  $67, $01, $09,  $8c, $7c, $08,  $99, $72, $0c,  $a9, $93, $0e,  $bf, $47, $0b,  $de, $65, $0d,  $fa, $75, $0e
  .byte $06  ,  $1d, $dc, $0d,  $8a, $7b, $08,  $8b, $cb, $0c,  $a7, $dd, $0d,  $b0, $10, $0a,  $e9, $58, $0c
  .byte $09  ,  $28, $37, $0c,  $38, $55, $0e,  $3b, $94, $0c,  $48, $ab, $08,  $51, $22, $0b,  $67, $db, $0d,  $99, $75, $0f,  $a9, $55, $0d,  $bf, $76, $0f
  .byte $06  ,  $3c, $83, $0a,  $4d, $25, $0b,  $8b, $7b, $09,  $9b, $22, $0a,  $a3, $00, $0a,  $e9, $64, $0e
  .byte $08  ,  $1d, $47, $0c,  $34, $45, $0c,  $38, $58, $04,  $5c, $6b, $06,  $67, $15, $0b,  $8c, $42, $04,  $99, $6b, $07,  $fb, $15, $05
  .byte $09  ,  $10, $54, $08,  $22, $66, $0f,  $4d, $94, $0e,  $5f, $57, $0b,  $7b, $66, $0d,  $8a, $76, $0e,  $8b, $86, $0f,  $e5, $46, $08,  $e9, $95, $0e
  .byte $0c  ,  $18, $54, $02,  $1d, $25, $0b,  $20, $03, $05,  $28, $7b, $08,  $31, $58, $0c,  $48, $63, $0c,  $51, $46, $0b,  $56, $47, $0b,  $5c, $53, $0d,  $67, $85, $0e,  $99, $47, $09,  $fb, $57, $0a
  .byte $05  ,  $23, $7a, $06,  $2d, $22, $0b,  $4d, $77, $0f,  $6c, $58, $0b,  $f6, $66, $0c
  .byte $04  ,  $22, $af, $0f,  $31, $9f, $0f,  $5c, $af, $0e,  $a1, $65, $0e
  .byte $05  ,  $10, $fe, $0f,  $2d, $59, $0d,  $34, $ab, $08,  $4d, $ba, $0c,  $b5, $94, $0e
  .byte $05  ,  $1d, $b7, $0f,  $22, $77, $0f,  $31, $b5, $0f,  $5c, $37, $09,  $a3, $22, $0b
  .byte $06  ,  $20, $6a, $0d,  $2d, $54, $01,  $51, $8b, $0f,  $8c, $62, $0b,  $9c, $58, $0c,  $a9, $6a, $08
  .byte $04  ,  $22, $c7, $0f,  $54, $45, $0c,  $56, $42, $04,  $5c, $ed, $0c
  .byte $04  ,  $2d, $59, $0d,  $53, $c6, $0f,  $a3, $00, $0a,  $a9, $55, $0d
  .byte $04  ,  $20, $37, $0c,  $3c, $54, $01,  $5c, $22, $0b,  $b0, $cc, $0b
  .byte $06  ,  $2d, $7c, $06,  $54, $77, $0f,  $56, $74, $0d,  $5f, $67, $0e,  $a3, $56, $0c,  $a9, $b5, $0e
  .byte $05  ,  $20, $f9, $0f,  $46, $e9, $0f,  $65, $75, $09,  $8c, $64, $0e,  $c3, $75, $0f
  .byte $36  ,  $08, $da, $0d,  $0c, $75, $08,  $15, $66, $0e,  $18, $cd, $0f,  $1a, $77, $0e,  $1c, $87, $0f,  $27, $cc, $0f,  $2c, $77, $0d,  $2d, $97, $0f,  $31, $88, $0f,  $34, $c8, $0f,  $38, $52, $0a,  $3a, $bc, $0f,  $3b, $cb, $0f,  $3c, $bd, $0e,  $3e, $be, $0d,  $41, $97, $0e,  $45, $da, $0f,  $48, $32, $05,  $51, $54, $08,  $53, $53, $08,  $56, $88, $0e,  $58, $64, $08,  $5a, $98, $0f,  $5b, $c9, $0f,  $5c, $64, $0a,  $5d, $55, $0a,  $5f, $74, $07,  $6a, $bc, $0e,  $6b, $bd, $0d,  $6c, $af, $0b,  $6d, $cb, $0e,  $77, $bb, $0f,  $78, $ac, $0f,  $7e, $db, $0f,  $81, $ad, $0e,  $82, $8a, $0b,  $89, $fb, $0f,  $98, $b8, $0e,  $99, $b9, $0f,  $9c, $43, $07,  $a9, $53, $07,  $ad, $c9, $0e,  $b5, $89, $0e,  $b7, $87, $0d,  $ba, $99, $0f,  $be, $a7, $0e,  $c7, $a8, $0f,  $d0, $44, $08,  $e5, $da, $0e,  $ec, $22, $05,  $f9, $54, $0a,  $fb, $43, $0a,  $fc, $64, $07
  .byte $40  ,  $01, $74, $0b,  $04, $55, $0d,  $0e, $d8, $0f,  $11, $d7, $0e,  $13, $78, $0f,  $19, $d9, $0f,  $1d, $55, $0b,  $1e, $78, $0e,  $20, $d9, $0e,  $2f, $fa, $0f,  $37, $43, $0b,  $3f, $9b, $0f,  $43, $ea, $0f,  $44, $96, $0d,  $49, $44, $09,  $4a, $31, $05,  $4b, $96, $0c,  $4e, $bf, $0b,  $4f, $bb, $0e,  $55, $af, $0a,  $59, $88, $0d,  $61, $89, $0d,  $63, $87, $0c,  $64, $ad, $0d,  $67, $ae, $0c,  $68, $99, $0e,  $72, $ac, $0e,  $75, $ce, $0f,  $7c, $ba, $0f,  $80, $ab, $0f,  $83, $9b, $0e,  $84, $be, $0e,  $86, $9d, $0a,  $88, $8b, $0b,  $8c, $9a, $0f,  $8d, $ca, $0e,  $90, $eb, $0f,  $91, $fc, $0f,  $93, $75, $0a,  $9a, $b9, $0e,  $9b, $db, $0e,  $9f, $85, $0b,  $a2, $86, $0b,  $a3, $32, $06,  $a4, $43, $08,  $a5, $a9, $0f,  $ab, $42, $06,  $ae, $44, $0a,  $b0, $43, $09,  $b2, $42, $07,  $b9, $98, $0e,  $c0, $97, $0d,  $c3, $33, $07,  $c5, $42, $09,  $ca, $31, $06,  $cd, $bf, $0a,  $ce, $ab, $0e,  $d7, $88, $0c,  $e1, $ad, $0c,  $e3, $9a, $0e,  $e9, $ae, $0b,  $ea, $ce, $0e,  $f4, $bb, $0d,  $f5, $ac, $0d
  .byte $02  ,  $08, $25, $01,  $5f, $26, $02
  .byte $07  ,  $11, $47, $0c,  $13, $32, $0b,  $1e, $84, $0a,  $20, $99, $06,  $2f, $83, $0b,  $67, $25, $0b,  $e5, $58, $0b
  .byte $05  ,  $46, $f9, $0f,  $65, $f8, $0f,  $6c, $58, $04,  $84, $94, $0e,  $ab, $01, $0a
  .byte $03  ,  $11, $75, $09,  $51, $74, $07,  $a2, $27, $02
  .byte $0b  ,  $20, $57, $03,  $43, $77, $04,  $46, $be, $0e,  $4d, $83, $09,  $65, $87, $07,  $67, $93, $0c,  $6d, $23, $00,  $89, $22, $0b,  $8d, $63, $0c,  $9b, $66, $0f,  $ab, $73, $0c
  .byte $14  ,  $0c, $05, $00,  $0e, $37, $09,  $10, $54, $08,  $11, $66, $02,  $1e, $de, $0a,  $22, $86, $0b,  $34, $56, $02,  $3f, $32, $01,  $51, $22, $0c,  $81, $74, $0d,  $84, $56, $0c,  $90, $44, $0d,  $91, $85, $0e,  $98, $00, $00,  $a2, $47, $09,  $ad, $56, $0b,  $b5, $67, $0d,  $b6, $46, $08,  $c5, $53, $0c,  $e5, $13, $02
  .byte $08  ,  $4d, $fc, $0f,  $67, $eb, $0f,  $78, $22, $00,  $83, $ba, $0c,  $9f, $42, $09,  $ab, $53, $0a,  $f4, $01, $0a,  $fc, $48, $03
  .byte $0c  ,  $0c, $ea, $0f,  $15, $db, $0d,  $1e, $da, $0d,  $2f, $c8, $0c,  $34, $d9, $0d,  $3f, $84, $0a,  $43, $bb, $0d,  $58, $32, $00,  $75, $cb, $0e,  $84, $78, $0e,  $ad, $b8, $0e,  $b5, $37, $02
  .byte $07  ,  $10, $d8, $0d,  $22, $c8, $0f,  $4d, $c7, $0c,  $65, $77, $04,  $9c, $6b, $05,  $a1, $43, $01,  $f4, $89, $05
  .byte $06  ,  $51, $af, $0f,  $58, $af, $0e,  $75, $ce, $0f,  $ad, $43, $07,  $b5, $78, $0f,  $fc, $58, $0b
  .byte $0e  ,  $10, $37, $02,  $15, $49, $04,  $20, $32, $01,  $34, $15, $00,  $3f, $22, $0c,  $46, $56, $02,  $4d, $9c, $07,  $69, $86, $0b,  $83, $65, $0e,  $84, $85, $0f,  $8c, $96, $0f,  $9b, $01, $00,  $9c, $03, $01,  $be, $36, $08
  .byte $0c  ,  $11, $83, $0b,  $22, $de, $0a,  $2f, $73, $0c,  $51, $55, $0e,  $58, $14, $03,  $76, $73, $09,  $a1, $62, $0a,  $a7, $72, $0a,  $b5, $46, $09,  $bf, $95, $0d,  $f4, $94, $0c,  $fc, $43, $02
  .byte $05  ,  $15, $fe, $0f,  $24, $57, $03,  $34, $75, $09,  $4d, $58, $0b,  $6d, $27, $02
  .byte $0a  ,  $04, $48, $03,  $10, $75, $0b,  $11, $7c, $06,  $1e, $89, $05,  $22, $93, $0c,  $2f, $cb, $0e,  $3f, $23, $00,  $54, $86, $0c,  $90, $66, $02,  $a9, $66, $0e
  .byte $0d  ,  $0c, $9a, $0f,  $15, $53, $07,  $19, $78, $0e,  $24, $ca, $0e,  $44, $77, $0f,  $46, $a7, $0e,  $4b, $b8, $0e,  $4d, $46, $02,  $65, $98, $07,  $76, $93, $0d,  $8c, $72, $0b,  $91, $94, $0d,  $fc, $43, $0d
  .byte $0c  ,  $0e, $af, $0f,  $10, $66, $0f,  $11, $22, $0c,  $2f, $96, $0d,  $34, $49, $08,  $38, $83, $0b,  $54, $58, $0b,  $84, $05, $00,  $90, $43, $02,  $9a, $44, $0d,  $a9, $9e, $0d,  $e3, $8d, $0d
  .byte $08  ,  $19, $78, $04,  $20, $96, $0c,  $24, $9a, $06,  $4b, $cb, $0e,  $65, $43, $01,  $81, $86, $0c,  $8d, $16, $01,  $fc, $75, $09
  .byte $0b  ,  $0e, $6b, $05,  $28, $9a, $0e,  $34, $84, $0a,  $51, $64, $08,  $54, $66, $0e,  $6d, $56, $0b,  $84, $37, $02,  $9a, $57, $03,  $a9, $75, $0b,  $c5, $62, $0b,  $e3, $83, $0d
  .byte $08  ,  $0c, $74, $08,  $11, $44, $0d,  $22, $35, $01,  $32, $55, $0e,  $4d, $7b, $08,  $76, $53, $0c,  $8c, $8e, $08,  $8d, $45, $0c
  .byte $0a  ,  $0e, $46, $02,  $2a, $75, $08,  $3c, $77, $04,  $51, $49, $03,  $6d, $9a, $0f,  $84, $ba, $0c,  $9a, $83, $09,  $ab, $93, $0b,  $ad, $ca, $0e,  $c5, $94, $0a
  .byte $0a  ,  $0c, $fe, $0f,  $19, $ea, $0f,  $22, $fc, $0f,  $2f, $58, $0b,  $3f, $76, $03,  $65, $43, $07,  $8c, $64, $0b,  $8d, $56, $0b,  $91, $64, $0c,  $e3, $49, $04
  .byte $11  ,  $04, $37, $0c,  $0e, $af, $0e,  $10, $af, $0f,  $1e, $37, $0b,  $24, $74, $08,  $3e, $64, $08,  $4b, $87, $07,  $51, $37, $02,  $6c, $23, $00,  $75, $46, $0b,  $93, $83, $0a,  $9a, $57, $0c,  $ab, $21, $01,  $ad, $73, $09,  $bb, $31, $03,  $c5, $56, $0a,  $fa, $77, $03
  .byte $05  ,  $20, $66, $0f,  $22, $47, $0c,  $2f, $15, $00,  $76, $ce, $0f,  $8d, $75, $0a
  .byte $09  ,  $04, $fc, $0f,  $0e, $26, $0b,  $10, $96, $0c,  $19, $58, $04,  $32, $74, $07,  $46, $36, $0c,  $4b, $ca, $0e,  $9a, $56, $0b,  $be, $98, $05
  .byte $08  ,  $11, $75, $06,  $20, $6a, $0d,  $22, $bc, $08,  $23, $53, $04,  $2f, $57, $0c,  $54, $64, $05,  $bf, $85, $0e,  $f7, $36, $08
  .byte $0a  ,  $04, $da, $0d,  $0e, $cc, $09,  $32, $04, $0b,  $46, $16, $0a,  $4b, $b8, $0f,  $69, $cb, $0e,  $75, $16, $01,  $ab, $db, $0e,  $b2, $44, $0d,  $be, $6b, $05
  .byte $08  ,  $1e, $95, $0d,  $20, $42, $07,  $23, $8d, $0b,  $24, $27, $02,  $2f, $16, $09,  $44, $af, $0e,  $54, $86, $0b,  $bb, $66, $0e
  .byte $0a  ,  $04, $05, $0b,  $11, $15, $0b,  $32, $33, $00,  $51, $43, $00,  $75, $74, $08,  $89, $46, $0b,  $ab, $8e, $08,  $be, $27, $0a,  $e3, $62, $0b,  $fc, $72, $0b
  .byte $0a  ,  $0e, $9e, $0e,  $22, $94, $0d,  $24, $57, $0c,  $2f, $75, $09,  $3f, $8d, $0d,  $44, $26, $0b,  $7b, $21, $01,  $bb, $a9, $08,  $bf, $48, $0b,  $fa, $75, $06
  .byte $0e  ,  $04, $78, $0e,  $0c, $38, $02,  $10, $a7, $0e,  $11, $36, $01,  $32, $36, $0c,  $46, $66, $0d,  $51, $c9, $0e,  $53, $66, $0e,  $6c, $56, $0c,  $83, $64, $0e,  $93, $64, $0d,  $ab, $73, $0c,  $b2, $75, $0e,  $be, $83, $0c
  .byte $0b  ,  $0e, $27, $02,  $13, $53, $08,  $24, $31, $03,  $2f, $46, $0d,  $3c, $84, $0d,  $3f, $57, $0b,  $44, $53, $0d,  $69, $96, $0f,  $bb, $53, $0c,  $bf, $96, $0e,  $fa, $37, $09
  .byte $0b  ,  $04, $47, $0c,  $10, $45, $0c,  $11, $83, $0a,  $23, $75, $09,  $32, $96, $0c,  $51, $55, $0d,  $53, $46, $0c,  $83, $67, $0c,  $84, $52, $0a,  $90, $02, $00,  $a0, $02, $01
  .byte $08  ,  $0e, $fe, $0f,  $19, $26, $0b,  $2a, $cb, $0e,  $2f, $55, $0c,  $3c, $65, $0e,  $44, $47, $0a,  $46, $43, $0c,  $6c, $13, $03
  .byte $08  ,  $04, $a7, $0e,  $0c, $75, $08,  $51, $ba, $0c,  $69, $58, $04,  $6d, $84, $0d,  $78, $74, $0d,  $9a, $66, $0d,  $bb, $37, $02
  .byte $09  ,  $0e, $db, $0e,  $19, $c9, $0e,  $2a, $38, $02,  $3c, $ca, $0e,  $53, $da, $0e,  $83, $94, $0e,  $bf, $57, $0c,  $f7, $93, $0c,  $fa, $8d, $0d
  .byte $04  ,  $1a, $c7, $0f,  $4d, $cb, $0e,  $78, $36, $08,  $bb, $56, $0b
  .byte $04  ,  $2a, $c8, $0f,  $bf, $d8, $0f,  $f7, $fe, $0f,  $fa, $fc, $0f
  .byte $08  ,  $04, $ff, $0a,  $2f, $46, $02,  $46, $ce, $09,  $53, $75, $06,  $54, $30, $02,  $75, $42, $03,  $89, $31, $02,  $8d, $53, $04
  .byte $66  ,  $01, $37, $02,  $09, $ac, $07,  $0c, $58, $03,  $0e, $36, $01,  $0f, $9a, $06,  $10, $47, $0b,  $11, $10, $00,  $13, $12, $02,  $15, $11, $00,  $17, $13, $04,  $19, $22, $03,  $1a, $21, $02,  $1c, $23, $05,  $1e, $42, $04,  $20, $35, $08,  $22, $46, $0a,  $23, $20, $01,  $2a, $45, $09,  $2b, $78, $0d,  $2d, $57, $03,  $31, $11, $01,  $32, $01, $01,  $33, $45, $02,  $34, $03, $00,  $37, $12, $00,  $38, $48, $03,  $3b, $47, $04,  $3c, $44, $03,  $3e, $02, $02,  $3f, $12, $03,  $41, $11, $02,  $44, $10, $01,  $45, $32, $02,  $48, $13, $05,  $4a, $24, $07,  $4b, $52, $04,  $4d, $53, $05,  $4e, $22, $04,  $50, $34, $08,  $51, $21, $03,  $52, $20, $02,  $55, $64, $05,  $56, $74, $06,  $58, $45, $0a,  $5a, $12, $01,  $5b, $47, $03,  $5c, $57, $04,  $62, $13, $00,  $64, $46, $04,  $67, $45, $03,  $6d, $34, $03,  $72, $22, $02,  $76, $33, $02,  $78, $56, $03,  $7c, $00, $01,  $7e, $35, $04,  $7f, $02, $03,  $81, $01, $02,  $83, $12, $04,  $84, $11, $03,  $86, $66, $04,  $8a, $12, $05,  $8b, $23, $06,  $8c, $13, $06,  $91, $23, $07,  $93, $34, $09,  $96, $54, $03,  $99, $24, $08,  $9a, $10, $02,  $9c, $63, $05,  $9f, $33, $08,  $a1, $64, $06,  $a5, $21, $04,  $a7, $32, $09,  $a9, $33, $0a,  $ab, $23, $02,  $ad, $35, $03,  $b2, $45, $04,  $b4, $46, $03,  $ba, $34, $02,  $bb, $13, $01,  $bc, $24, $03,  $be, $22, $01,  $bf, $7b, $06,  $c0, $6a, $05,  $c2, $59, $04,  $c7, $14, $00,  $c8, $56, $04,  $ca, $00, $02,  $cd, $48, $04,  $da, $37, $03,  $dd, $46, $05,  $de, $48, $06,  $e1, $47, $05,  $e3, $47, $06,  $e9, $23, $00,  $ea, $25, $04,  $f3, $59, $07,  $f4, $58, $08,  $f7, $01, $03,  $fa, $11, $04,  $fc, $02, $04
  .byte $07  ,  $14, $aa, $0b,  $6b, $46, $0b,  $88, $22, $00,  $a2, $41, $03,  $a8, $44, $02,  $bd, $36, $0a,  $cb, $12, $06
  .byte $07  ,  $0f, $a9, $0f,  $10, $dd, $0a,  $2b, $89, $0e,  $96, $14, $07,  $ea, $7a, $0b,  $f3, $88, $06,  $fd, $55, $03
  .byte $07  ,  $09, $02, $0f,  $0c, $01, $0f,  $0e, $03, $0f,  $46, $01, $0e,  $54, $03, $0e,  $86, $13, $0e,  $b9, $01, $0d
  .byte $0f  ,  $01, $ac, $07,  $04, $ce, $09,  $2f, $66, $04,  $38, $bf, $0b,  $53, $87, $0a,  $96, $75, $05,  $a2, $65, $0c,  $a7, $54, $0b,  $bf, $76, $0d,  $c0, $53, $03,  $c2, $98, $0e,  $c7, $98, $07,  $da, $35, $09,  $de, $03, $01,  $ea, $00, $0a
  .byte $0c  ,  $09, $47, $0f,  $0c, $48, $0f,  $0e, $37, $0f,  $46, $46, $0f,  $54, $37, $0e,  $65, $8b, $0f,  $7f, $25, $0e,  $86, $15, $0e,  $a3, $69, $0f,  $b9, $46, $0e,  $f1, $57, $0f,  $fc, $fe, $0f
  .byte $2f  ,  $01, $02, $0f,  $04, $03, $0e,  $10, $03, $0f,  $11, $02, $0d,  $15, $13, $0d,  $24, $01, $0d,  $26, $14, $0d,  $2d, $12, $0c,  $2f, $02, $04,  $33, $02, $03,  $34, $43, $07,  $3c, $47, $0b,  $45, $75, $06,  $4b, $22, $0b,  $56, $a9, $0c,  $57, $a9, $0d,  $5b, $32, $06,  $69, $36, $0f,  $74, $34, $0d,  $75, $44, $0d,  $78, $55, $0e,  $7b, $45, $0d,  $7d, $54, $0d,  $88, $55, $0d,  $8d, $66, $0f,  $96, $65, $0e,  $a2, $56, $0e,  $a7, $66, $0e,  $a8, $56, $0d,  $b0, $67, $0f,  $b4, $77, $0f,  $b7, $67, $0e,  $bf, $66, $0d,  $c0, $56, $0c,  $c2, $76, $0e,  $c7, $57, $0c,  $cd, $67, $0d,  $d1, $78, $0f,  $d2, $14, $03,  $d6, $36, $0c,  $db, $68, $0d,  $de, $78, $0e,  $e9, $88, $0f,  $f3, $45, $0c,  $f9, $be, $0d,  $fb, $14, $04,  $fd, $25, $0d
  .byte $0a  ,  $09, $46, $02,  $0c, $9d, $08,  $0e, $64, $0a,  $54, $54, $0a,  $65, $ff, $0a,  $7f, $7b, $06,  $86, $32, $09,  $b9, $6a, $05,  $f1, $65, $0a,  $fc, $ad, $08
  .byte $31  ,  $01, $15, $00,  $04, $37, $02,  $0f, $59, $04,  $10, $47, $02,  $11, $48, $03,  $15, $ac, $07,  $24, $55, $03,  $26, $bf, $0a,  $2b, $9a, $06,  $2d, $9d, $07,  $38, $31, $03,  $3c, $11, $00,  $43, $44, $02,  $46, $57, $03,  $4b, $03, $00,  $56, $45, $02,  $57, $52, $04,  $69, $43, $0a,  $6b, $66, $04,  $74, $56, $03,  $75, $21, $01,  $78, $43, $09,  $7b, $7a, $0a,  $7d, $98, $0e,  $88, $ac, $0e,  $8d, $46, $03,  $96, $37, $03,  $a2, $48, $04,  $a3, $14, $00,  $a7, $33, $01,  $a8, $25, $04,  $b0, $32, $02,  $b4, $42, $03,  $b7, $00, $09,  $bf, $02, $07,  $c0, $9c, $0a,  $c2, $10, $03,  $c7, $54, $04,  $cd, $8a, $0a,  $d1, $22, $06,  $d2, $88, $06,  $d6, $32, $07,  $db, $98, $0d,  $de, $23, $08,  $e9, $13, $07,  $f3, $76, $0c,  $f9, $33, $09,  $fb, $34, $0a,  $fd, $a9, $0e
  .byte $0c  ,  $0c, $35, $0a,  $0e, $25, $09,  $22, $02, $06,  $52, $24, $09,  $58, $aa, $0f,  $77, $36, $03,  $7f, $56, $05,  $93, $24, $02,  $a9, $57, $05,  $df, $23, $01,  $e0, $35, $02,  $f5, $ef, $0a
  .byte $09  ,  $2b, $ac, $0d,  $2d, $20, $02,  $48, $74, $06,  $a8, $9b, $0b,  $bd, $21, $05,  $bf, $8b, $09,  $ef, $58, $04,  $fb, $58, $06,  $ff, $ff, $0b
  .byte $0c  ,  $0e, $9d, $07,  $14, $36, $08,  $15, $14, $01,  $26, $bc, $08,  $52, $ce, $09,  $5b, $7a, $05,  $6e, $23, $03,  $82, $57, $06,  $a7, $66, $05,  $aa, $77, $05,  $c0, $36, $05,  $f0, $47, $07
  .byte $01  ,  $a8, $bb, $0f
  .byte $05  ,  $10, $36, $0a,  $14, $bb, $0c,  $22, $24, $09,  $80, $02, $07,  $f5, $13, $05
  .byte $09  ,  $01, $41, $03,  $04, $99, $0a,  $0c, $02, $06,  $24, $a9, $0d,  $45, $ba, $0f,  $53, $32, $06,  $58, $bb, $0d,  $bf, $9b, $0d,  $c2, $25, $03
  .byte $03  ,  $0e, $9c, $0a,  $66, $a9, $0c,  $6b, $47, $02
  .byte $09  ,  $10, $78, $04,  $24, $66, $04,  $48, $36, $09,  $7d, $25, $08,  $86, $36, $04,  $a1, $58, $03,  $bf, $8b, $09,  $e9, $01, $0a,  $ea, $10, $03
  .byte $02  ,  $45, $73, $05,  $c5, $bf, $0a
  .byte $08  ,  $10, $46, $0a,  $24, $56, $0a,  $48, $52, $03,  $65, $55, $03,  $66, $52, $05,  $7d, $64, $0a,  $c2, $9a, $06,  $f2, $ba, $0f
  .byte $05  ,  $0e, $cc, $0d,  $45, $75, $0b,  $7b, $25, $03,  $8c, $53, $03,  $f4, $25, $0b
  .byte $09  ,  $01, $a9, $0c,  $20, $36, $09,  $22, $13, $06,  $69, $35, $0b,  $7d, $64, $04,  $80, $6a, $07,  $b5, $7b, $08,  $c2, $59, $07,  $f0, $13, $07
  .byte $04  ,  $4b, $58, $08,  $da, $47, $07,  $f2, $13, $08,  $f4, $35, $08
  .byte $06  ,  $0e, $43, $0a,  $14, $03, $00,  $43, $7b, $09,  $b5, $79, $0c,  $f5, $32, $09,  $f8, $ba, $0e
  .byte $09  ,  $24, $24, $0b,  $2b, $02, $07,  $45, $41, $03,  $4b, $7a, $0b,  $66, $66, $04,  $8c, $14, $02,  $da, $87, $0b,  $de, $a9, $0d,  $f2, $9b, $0b
  .byte $0a  ,  $01, $56, $0a,  $28, $13, $05,  $43, $46, $09,  $69, $bb, $0c,  $80, $53, $03,  $a1, $98, $0e,  $b5, $44, $02,  $b6, $76, $0a,  $c5, $ac, $0d,  $c7, $25, $04
  .byte $08  ,  $04, $58, $03,  $0c, $9c, $0a,  $17, $58, $08,  $45, $52, $05,  $6b, $37, $02,  $7d, $58, $07,  $8c, $44, $03,  $da, $55, $04
  .byte $02  ,  $3e, $13, $08,  $7b, $ce, $0e
  .byte $0b  ,  $10, $87, $0b,  $17, $41, $03,  $20, $54, $0b,  $2b, $02, $02,  $45, $25, $03,  $4b, $03, $01,  $61, $25, $09,  $6b, $02, $06,  $80, $34, $01,  $a1, $67, $04,  $e9, $8b, $06
  .byte $05  ,  $0f, $23, $08,  $43, $7a, $0b,  $48, $00, $0a,  $86, $02, $07,  $c7, $65, $0c
  .byte $08  ,  $04, $46, $09,  $20, $36, $04,  $3e, $89, $0d,  $4b, $48, $06,  $61, $ef, $0a,  $6b, $69, $07,  $c5, $59, $06,  $f0, $de, $0a
  .byte $05  ,  $01, $58, $03,  $14, $7b, $09,  $2f, $47, $02,  $f2, $48, $05,  $fc, $88, $07
  .byte $05  ,  $17, $ce, $0d,  $4b, $35, $0b,  $b9, $01, $0a,  $c0, $52, $03,  $c5, $36, $09
  .byte $09  ,  $11, $59, $06,  $24, $37, $02,  $28, $22, $00,  $3e, $dd, $0a,  $48, $be, $0e,  $7b, $03, $00,  $96, $47, $08,  $a2, $25, $08,  $a8, $ac, $0d
  .byte $04  ,  $0c, $13, $05,  $10, $36, $05,  $17, $53, $03,  $b5, $6a, $07
  .byte $0a  ,  $1d, $35, $0c,  $28, $a9, $0c,  $3e, $87, $0b,  $4a, $44, $02,  $50, $02, $06,  $69, $64, $04,  $c2, $9b, $0b,  $c7, $9a, $06,  $f2, $99, $07,  $f4, $cc, $0a
  .byte $07  ,  $0c, $9c, $0a,  $48, $48, $04,  $4b, $48, $03,  $86, $35, $08,  $91, $79, $0c,  $c5, $02, $04,  $de, $6a, $08
  .byte $06  ,  $10, $59, $04,  $7b, $6a, $05,  $88, $a9, $0d,  $9e, $23, $07,  $f6, $00, $0a,  $f8, $42, $07
  .byte $04  ,  $28, $73, $05,  $91, $99, $0a,  $a2, $bb, $0c,  $c5, $34, $08
  .byte $0b  ,  $0e, $89, $0a,  $0f, $24, $07,  $45, $41, $03,  $4a, $03, $00,  $4d, $54, $03,  $50, $13, $05,  $68, $7b, $08,  $88, $cf, $09,  $c2, $bb, $09,  $cd, $32, $03,  $f6, $01, $04
  .byte $0a  ,  $0c, $74, $05,  $2c, $47, $07,  $3e, $45, $0c,  $43, $30, $02,  $80, $8b, $0b,  $91, $23, $00,  $a2, $ee, $0b,  $ae, $aa, $09,  $f5, $24, $04,  $f9, $00, $03
  .byte $09  ,  $04, $53, $05,  $06, $87, $0b,  $14, $a9, $0d,  $1d, $99, $0a,  $50, $36, $01,  $86, $ac, $0e,  $96, $89, $05,  $99, $33, $09,  $de, $42, $08
  .byte $04  ,  $33, $ef, $0e,  $68, $9b, $0b,  $91, $25, $03,  $fd, $ad, $08
  .byte $07  ,  $0f, $45, $0a,  $14, $24, $08,  $1d, $cc, $0d,  $43, $02, $03,  $50, $75, $0a,  $86, $64, $09,  $a2, $34, $01
  .byte $08  ,  $2a, $02, $09,  $2f, $a9, $0c,  $59, $23, $08,  $6c, $8a, $0a,  $80, $bb, $0c,  $88, $23, $00,  $91, $24, $07,  $96, $99, $0a
  .byte $05  ,  $14, $8e, $05,  $28, $14, $0c,  $e1, $8d, $05,  $e3, $7d, $04,  $f3, $13, $09
  .byte $28  ,  $0c, $03, $0b,  $0f, $47, $05,  $11, $dc, $0d,  $17, $7c, $04,  $18, $47, $06,  $1b, $46, $00,  $23, $ee, $0e,  $25, $af, $06,  $27, $17, $00,  $2a, $03, $09,  $2c, $03, $08,  $2d, $9e, $09,  $38, $bb, $07,  $3a, $7d, $06,  $3e, $63, $09,  $45, $04, $0b,  $47, $ba, $0c,  $4d, $45, $01,  $4f, $86, $09,  $55, $76, $0c,  $58, $97, $0c,  $59, $16, $05,  $65, $7a, $0b,  $69, $64, $06,  $6a, $27, $02,  $6b, $06, $00,  $73, $43, $0a,  $75, $be, $07,  $7d, $14, $03,  $89, $15, $05,  $9c, $84, $0a,  $a8, $13, $03,  $b0, $03, $02,  $b4, $49, $01,  $b5, $14, $04,  $b7, $4a, $03,  $c0, $6b, $03,  $ce, $14, $05,  $d7, $03, $05,  $db, $a5, $0b
  .byte $06  ,  $22, $04, $0d,  $28, $03, $0c,  $2f, $85, $08,  $b9, $34, $00,  $de, $7b, $08,  $ea, $89, $04
  .byte $15  ,  $0c, $14, $0b,  $11, $cc, $0e,  $18, $8e, $06,  $1b, $24, $08,  $1e, $97, $09,  $2d, $13, $06,  $38, $03, $0a,  $3a, $4a, $02,  $3e, $9f, $09,  $43, $9d, $05,  $45, $63, $05,  $55, $10, $03,  $57, $31, $05,  $58, $45, $00,  $59, $7a, $03,  $65, $42, $08,  $6b, $67, $03,  $89, $94, $0a,  $bf, $53, $09,  $c0, $03, $03,  $f8, $5a, $03
  .byte $09  ,  $22, $14, $0a,  $28, $15, $05,  $63, $47, $07,  $6a, $42, $04,  $b4, $36, $08,  $b9, $7d, $06,  $de, $58, $08,  $e3, $31, $04,  $ea, $5a, $02
  .byte $14  ,  $0c, $14, $0c,  $11, $15, $08,  $17, $87, $0c,  $1b, $38, $04,  $1d, $27, $02,  $1e, $58, $07,  $27, $68, $02,  $2f, $6c, $04,  $3a, $32, $02,  $3e, $06, $00,  $43, $04, $02,  $45, $04, $03,  $58, $59, $02,  $66, $cf, $07,  $68, $49, $02,  $80, $6a, $03,  $bd, $af, $07,  $bf, $48, $01,  $d7, $49, $03,  $fb, $6c, $05
  .byte $0c  ,  $25, $9f, $08,  $2a, $34, $00,  $47, $8a, $04,  $63, $53, $09,  $69, $21, $05,  $6a, $66, $04,  $b4, $04, $06,  $b9, $6b, $04,  $c6, $7c, $05,  $de, $5b, $04,  $e3, $14, $06,  $ea, $86, $0a
  .byte $0e  ,  $0c, $49, $06,  $11, $8b, $04,  $18, $03, $09,  $1b, $59, $06,  $1d, $98, $07,  $27, $17, $00,  $2c, $bd, $0b,  $3a, $14, $09,  $3e, $13, $05,  $57, $56, $02,  $75, $95, $0a,  $97, $85, $0b,  $f3, $53, $08,  $fb, $94, $0b
  .byte $09  ,  $04, $ed, $0f,  $1a, $dc, $0f,  $22, $a9, $0c,  $25, $fe, $0f,  $38, $ed, $0d,  $47, $db, $0c,  $91, $03, $08,  $cd, $52, $06,  $de, $b9, $0b
  .byte $05  ,  $18, $ab, $0c,  $1b, $48, $06,  $1d, $16, $03,  $1e, $5a, $02,  $b4, $58, $06
  .byte $0b  ,  $04, $14, $0a,  $0c, $03, $09,  $1a, $97, $08,  $25, $31, $04,  $27, $ca, $0b,  $45, $6c, $05,  $66, $8a, $04,  $6a, $83, $09,  $bf, $27, $02,  $dc, $36, $08,  $de, $56, $01
  .byte $06  ,  $18, $ff, $0a,  $23, $41, $05,  $2a, $04, $03,  $4d, $ec, $0c,  $59, $52, $07,  $65, $c9, $0b
  .byte $08  ,  $1b, $dc, $0d,  $22, $b9, $0b,  $25, $39, $04,  $27, $17, $00,  $6c, $7a, $03,  $bf, $34, $00,  $de, $27, $04,  $fb, $8a, $09
  .byte $0d  ,  $18, $14, $0b,  $1a, $a7, $0b,  $1d, $54, $0b,  $1e, $03, $0a,  $23, $94, $0b,  $3a, $47, $00,  $4d, $b9, $0a,  $59, $7c, $04,  $65, $13, $09,  $66, $27, $02,  $91, $03, $05,  $97, $64, $06,  $dc, $8e, $06
  .byte $0d  ,  $04, $fc, $0f,  $0c, $ea, $0f,  $17, $ea, $0e,  $1b, $b7, $0b,  $25, $b7, $0c,  $27, $c9, $0d,  $28, $c8, $0c,  $2f, $d9, $0d,  $43, $b7, $0d,  $45, $6a, $07,  $48, $8a, $0a,  $6c, $6c, $07,  $b7, $48, $06
  .byte $0d  ,  $1d, $fd, $0f,  $23, $da, $0e,  $3a, $a9, $0c,  $47, $14, $0a,  $4d, $85, $0b,  $59, $47, $06,  $bf, $da, $0d,  $c5, $4a, $03,  $cd, $8a, $04,  $ce, $b9, $0d,  $dc, $6a, $08,  $de, $95, $09,  $fb, $52, $07
  .byte $10  ,  $04, $ff, $0a,  $0c, $cf, $07,  $17, $bf, $0b,  $1e, $62, $08,  $25, $7b, $08,  $28, $ee, $0e,  $2f, $32, $02,  $38, $7c, $04,  $43, $45, $01,  $45, $44, $02,  $57, $af, $08,  $65, $cf, $08,  $6c, $59, $03,  $92, $03, $04,  $b4, $7c, $06,  $b7, $38, $01
  .byte $10  ,  $11, $24, $0b,  $1a, $38, $04,  $1b, $ba, $0c,  $1d, $8b, $09,  $23, $53, $05,  $27, $58, $06,  $3a, $ab, $0c,  $48, $a9, $08,  $4d, $31, $04,  $59, $94, $0b,  $66, $42, $04,  $91, $84, $08,  $bf, $34, $08,  $ce, $ce, $0c,  $dc, $bc, $06,  $de, $ed, $0b
  .byte $06  ,  $04, $7b, $09,  $18, $87, $0c,  $1e, $48, $06,  $25, $31, $03,  $38, $62, $06,  $43, $14, $05
  .byte $09  ,  $1a, $ff, $0a,  $27, $34, $00,  $2f, $95, $09,  $3a, $85, $0b,  $4d, $bb, $0c,  $6a, $dd, $0e,  $91, $df, $0e,  $cd, $04, $06,  $de, $83, $08
  .byte $0b  ,  $04, $14, $0b,  $0c, $45, $01,  $0f, $83, $09,  $11, $cc, $0d,  $18, $56, $02,  $1e, $48, $01,  $25, $47, $00,  $28, $a5, $0c,  $43, $96, $09,  $ce, $03, $01,  $dc, $bf, $07
  .byte $09  ,  $1a, $24, $0b,  $1d, $ce, $0c,  $3a, $ee, $0f,  $47, $5b, $04,  $48, $74, $0b,  $6a, $95, $0c,  $91, $b6, $0c,  $cd, $6b, $05,  $de, $5a, $04
  .byte $07  ,  $11, $ee, $0e,  $1e, $8a, $04,  $25, $84, $08,  $27, $87, $0c,  $38, $94, $0c,  $7d, $ae, $07,  $bd, $9e, $08
  .byte $08  ,  $17, $03, $0a,  $1a, $24, $08,  $2f, $af, $07,  $3a, $8b, $09,  $47, $48, $01,  $5d, $a4, $0c,  $c5, $04, $00,  $dc, $6a, $04
  .byte $03  ,  $1e, $bf, $07,  $38, $14, $03,  $91, $58, $06
  .byte $08  ,  $1b, $13, $09,  $2a, $14, $0a,  $3a, $03, $09,  $47, $4a, $03,  $48, $a4, $0b,  $b7, $b5, $0c,  $bf, $84, $0b,  $fb, $85, $0b
  .byte $05  ,  $06, $cf, $07,  $22, $ba, $0c,  $25, $56, $01,  $45, $a9, $08,  $b5, $47, $05
  .byte $0b  ,  $18, $ff, $0a,  $1b, $87, $0b,  $2a, $ee, $0f,  $2f, $b9, $0c,  $3a, $52, $07,  $43, $ed, $0d,  $47, $7b, $04,  $6a, $79, $03,  $b7, $95, $0b,  $bf, $a6, $0c,  $cd, $87, $0a
  .byte $07  ,  $11, $56, $02,  $25, $04, $03,  $27, $b6, $0d,  $45, $96, $0a,  $48, $66, $04,  $58, $42, $09,  $5d, $22, $00
  .byte $06  ,  $18, $bc, $0d,  $2a, $dd, $0e,  $2f, $87, $0d,  $66, $96, $09,  $6a, $ed, $0e,  $bf, $24, $09
  .byte $41  ,  $01, $bc, $0e,  $04, $89, $0e,  $06, $23, $09,  $0e, $88, $0d,  $0f, $77, $0d,  $10, $fe, $0d,  $14, $44, $02,  $17, $21, $01,  $1a, $85, $08,  $1e, $ae, $08,  $22, $bf, $08,  $24, $cf, $09,  $25, $33, $01,  $27, $55, $03,  $28, $de, $09,  $34, $bc, $07,  $38, $14, $02,  $3a, $63, $06,  $45, $74, $07,  $47, $02, $04,  $4b, $87, $0c,  $4f, $88, $0c,  $50, $dc, $0d,  $51, $23, $08,  $55, $02, $06,  $58, $13, $07,  $59, $24, $07,  $5b, $34, $00,  $61, $9b, $0b,  $63, $76, $0c,  $65, $cf, $0a,  $68, $8c, $07,  $6c, $bf, $09,  $73, $78, $04,  $75, $24, $00,  $7b, $79, $04,  $7d, $68, $03,  $80, $89, $05,  $89, $9d, $07,  $92, $dd, $0a,  $97, $cc, $09,  $99, $ee, $0b,  $9a, $cd, $08,  $9c, $ac, $07,  $a5, $99, $06,  $b0, $25, $03,  $b4, $dc, $0c,  $b5, $ee, $0e,  $b7, $98, $08,  $b9, $ba, $0a,  $bd, $cb, $0a,  $c0, $cb, $0b,  $c5, $87, $08,  $c6, $33, $06,  $d7, $34, $07,  $db, $76, $06,  $dc, $65, $05,  $de, $32, $03,  $e1, $75, $07,  $e3, $56, $09,  $ea, $86, $08,  $f3, $66, $0a,  $f8, $11, $05,  $fb, $24, $06,  $ff, $13, $04
  .byte $04  ,  $20, $24, $0a,  $23, $89, $0a,  $2d, $ac, $0d,  $bf, $13, $09
  .byte $09  ,  $01, $35, $0a,  $04, $13, $06,  $0f, $42, $04,  $18, $7a, $05,  $34, $33, $09,  $45, $43, $07,  $51, $ae, $09,  $89, $bf, $0a,  $e3, $bb, $08
  .byte $07  ,  $0e, $58, $03,  $10, $54, $03,  $1a, $78, $0d,  $3a, $32, $02,  $86, $97, $09,  $d4, $65, $04,  $de, $98, $07
  .byte $0a  ,  $20, $31, $03,  $2d, $23, $0a,  $34, $32, $03,  $4a, $53, $05,  $55, $88, $0d,  $63, $fe, $0d,  $66, $36, $04,  $69, $56, $09,  $a3, $21, $03,  $e3, $46, $0a
  .byte $0a  ,  $01, $13, $0a,  $06, $10, $02,  $0f, $14, $00,  $10, $20, $02,  $18, $79, $0c,  $1a, $34, $08,  $2f, $56, $0a,  $4d, $8a, $05,  $a5, $be, $08,  $d4, $fe, $0c
  .byte $03  ,  $55, $76, $0c,  $59, $7a, $05,  $89, $03, $00
  .byte $0a  ,  $10, $f9, $0f,  $18, $ea, $0f,  $2f, $f9, $0e,  $58, $fa, $0f,  $84, $f8, $0f,  $9e, $e9, $0f,  $bf, $e8, $0f,  $d4, $f7, $0f,  $de, $e7, $0f,  $f5, $fa, $0e
  .byte $09  ,  $06, $dc, $0f,  $17, $ca, $0f,  $20, $a8, $0e,  $38, $86, $0d,  $61, $eb, $0f,  $9a, $b9, $0f,  $a3, $ec, $0f,  $e3, $b9, $0e,  $fb, $a9, $0d
  .byte $09  ,  $18, $89, $0d,  $2a, $56, $0a,  $2f, $89, $0b,  $51, $21, $05,  $84, $dc, $0a,  $bf, $cd, $08,  $d4, $bb, $08,  $de, $bc, $0d,  $f5, $21, $01
  .byte $0d  ,  $06, $ab, $0d,  $10, $02, $06,  $17, $fe, $0c,  $1a, $99, $06,  $20, $db, $0b,  $38, $78, $0d,  $58, $36, $00,  $61, $98, $07,  $9a, $47, $01,  $9e, $65, $04,  $a3, $79, $03,  $e3, $53, $09,  $fb, $58, $02
  .byte $0b  ,  $18, $b8, $0b,  $28, $fb, $0f,  $2a, $fb, $0e,  $2f, $c8, $0c,  $3e, $da, $0c,  $45, $eb, $0e,  $4a, $da, $0d,  $51, $dd, $0e,  $69, $ca, $0a,  $b0, $20, $02,  $ce, $21, $03
  .byte $0a  ,  $0f, $f8, $0f,  $17, $f7, $0f,  $38, $e8, $0f,  $58, $f9, $0f,  $89, $e9, $0f,  $9a, $b5, $0b,  $a3, $e9, $0e,  $d4, $e7, $0f,  $ee, $fa, $0f,  $fb, $a5, $0a
  .byte $11  ,  $01, $02, $0c,  $0e, $31, $0d,  $18, $32, $0d,  $1a, $b8, $0f,  $20, $32, $0a,  $2f, $03, $0c,  $3e, $23, $0c,  $44, $ba, $0f,  $53, $c9, $0f,  $84, $54, $0d,  $9e, $31, $0b,  $b0, $c8, $0f,  $bd, $42, $0d,  $dc, $42, $0b,  $e1, $74, $0c,  $ea, $31, $0c,  $f5, $43, $0c
  .byte $10  ,  $17, $9b, $0d,  $34, $97, $0d,  $3a, $cb, $0e,  $4a, $ed, $0f,  $61, $cb, $0d,  $69, $dc, $0f,  $86, $bb, $0e,  $97, $cd, $0f,  $99, $88, $0d,  $9a, $98, $0e,  $a3, $dd, $0f,  $b4, $cc, $0e,  $c0, $bb, $0d,  $ce, $69, $03,  $db, $9d, $08,  $fb, $7b, $06
  .byte $24  ,  $01, $8d, $06,  $06, $9d, $06,  $0e, $6b, $04,  $0f, $6a, $04,  $18, $6a, $03,  $1a, $7b, $04,  $20, $ae, $07,  $28, $9d, $07,  $2a, $7c, $05,  $2d, $9e, $07,  $2f, $7b, $05,  $38, $8c, $05,  $3e, $cc, $0f,  $43, $8c, $06,  $44, $7a, $04,  $45, $ad, $07,  $53, $bc, $07,  $54, $97, $0c,  $58, $9b, $0b,  $63, $8a, $0a,  $84, $14, $02,  $89, $cd, $0e,  $92, $9c, $06,  $9e, $de, $0f,  $b0, $ab, $06,  $b9, $bd, $0d,  $bd, $cc, $0d,  $bf, $ee, $0f,  $d4, $bb, $0c,  $dc, $cb, $0c,  $e1, $24, $04,  $e3, $22, $07,  $ea, $98, $0a,  $ee, $45, $09,  $f4, $54, $08,  $f5, $65, $09
  .byte $0c  ,  $04, $58, $03,  $10, $58, $02,  $15, $14, $00,  $34, $03, $00,  $3d, $cc, $0a,  $55, $21, $05,  $66, $6a, $05,  $78, $76, $06,  $91, $99, $06,  $97, $77, $04,  $99, $32, $03,  $9a, $98, $07
  .byte $1e  ,  $01, $47, $01,  $05, $36, $00,  $06, $14, $01,  $0e, $21, $04,  $17, $55, $02,  $29, $ae, $09,  $2a, $10, $03,  $3a, $23, $07,  $3e, $98, $0d,  $47, $36, $01,  $4b, $35, $00,  $53, $ba, $0b,  $54, $58, $07,  $68, $98, $0c,  $69, $88, $0b,  $6a, $8b, $07,  $84, $9c, $07,  $89, $9c, $08,  $9e, $ac, $08,  $a6, $be, $09,  $b0, $ce, $0a,  $b6, $cc, $0b,  $b9, $bc, $0a,  $bf, $bb, $0b,  $d6, $ab, $0b,  $db, $aa, $0a,  $de, $9a, $09,  $ee, $99, $08,  $f1, $89, $07,  $fb, $78, $06
  .byte $32  ,  $07, $bf, $0a,  $0f, $9d, $08,  $18, $9e, $08,  $1a, $58, $06,  $1b, $af, $09,  $1d, $24, $06,  $20, $7a, $06,  $26, $68, $06,  $2d, $67, $05,  $2f, $35, $01,  $34, $24, $01,  $36, $de, $0b,  $38, $ab, $09,  $49, $9a, $07,  $4a, $89, $06,  $4f, $78, $05,  $50, $25, $00,  $51, $bd, $08,  $55, $be, $0a,  $58, $cd, $0a,  $61, $bc, $09,  $63, $79, $05,  $66, $68, $04,  $78, $46, $01,  $80, $47, $02,  $86, $57, $02,  $91, $36, $02,  $99, $aa, $08,  $9a, $bb, $0a,  $9f, $77, $06,  $a3, $8a, $06,  $a4, $67, $06,  $b4, $89, $08,  $b5, $78, $07,  $b7, $dd, $0b,  $b8, $ee, $0d,  $bd, $cd, $09,  $c5, $23, $04,  $cb, $34, $04,  $cc, $33, $05,  $cd, $02, $03,  $ce, $35, $05,  $d0, $34, $06,  $d3, $45, $05,  $dc, $44, $07,  $e3, $11, $03,  $ef, $ab, $08,  $f3, $46, $06,  $f4, $56, $06,  $f5, $55, $08
  .byte $1e  ,  $01, $cd, $0f,  $04, $cc, $0f,  $06, $66, $0a,  $0e, $77, $0a,  $10, $ba, $0f,  $17, $bc, $08,  $2a, $ef, $0c,  $2c, $88, $0c,  $33, $bc, $0e,  $3a, $9e, $07,  $3b, $cc, $0d,  $3e, $89, $05,  $43, $dc, $0c,  $44, $9d, $06,  $53, $ae, $07,  $54, $bb, $0e,  $5e, $7b, $05,  $77, $78, $0a,  $82, $dc, $0d,  $95, $66, $03,  $c1, $bb, $0f,  $c9, $45, $00,  $ca, $a9, $0d,  $d1, $88, $05,  $d4, $a9, $08,  $d8, $99, $0d,  $f6, $aa, $0e,  $f8, $56, $09,  $f9, $df, $0a,  $fa, $ab, $07
  .byte $12  ,  $07, $ff, $0f,  $0f, $fe, $0f,  $15, $ef, $0f,  $18, $ee, $0f,  $1a, $ed, $0f,  $1b, $de, $0f,  $1d, $dd, $0f,  $29, $59, $02,  $55, $6a, $04,  $5f, $48, $02,  $8a, $5a, $02,  $8b, $6a, $03,  $a9, $58, $02,  $cd, $ee, $0e,  $d7, $cb, $0e,  $dd, $5a, $03,  $f7, $58, $03,  $ff, $69, $03
  .byte $0c  ,  $06, $44, $0a,  $10, $ff, $0d,  $2c, $00, $03,  $68, $33, $08,  $77, $66, $0b,  $c1, $55, $0b,  $c3, $44, $09,  $d4, $ef, $0e,  $d6, $43, $09,  $d8, $dc, $0f,  $f6, $45, $0a,  $f8, $ff, $0e
  .byte $07  ,  $15, $01, $07,  $2b, $02, $08,  $53, $22, $09,  $5f, $12, $08,  $82, $01, $06,  $c9, $01, $05,  $f3, $02, $07
  .byte $09  ,  $3e, $01, $09,  $4d, $02, $09,  $69, $23, $09,  $77, $12, $0a,  $c3, $01, $08,  $ca, $22, $07,  $d1, $ae, $07,  $d7, $57, $06,  $d8, $ba, $0b
  .byte $15  ,  $01, $cf, $0c,  $04, $bf, $0a,  $05, $87, $08,  $06, $65, $05,  $0e, $cb, $0a,  $1d, $a9, $08,  $29, $8d, $06,  $2b, $03, $00,  $33, $55, $02,  $54, $ba, $0a,  $7b, $6a, $05,  $8a, $8d, $07,  $95, $9d, $08,  $97, $7b, $06,  $a9, $8c, $07,  $c1, $ba, $09,  $c7, $ae, $09,  $d6, $57, $05,  $dd, $dd, $0e,  $f6, $ed, $0d,  $ff, $dc, $0b
  .byte $1a  ,  $15, $ff, $0c,  $18, $44, $08,  $1b, $9a, $06,  $1c, $99, $06,  $2c, $56, $09,  $3e, $88, $05,  $4d, $65, $04,  $50, $14, $01,  $53, $76, $05,  $5f, $58, $04,  $68, $cb, $0b,  $69, $98, $08,  $73, $46, $08,  $77, $76, $06,  $7e, $54, $04,  $82, $ac, $0c,  $83, $bc, $0d,  $8b, $be, $0a,  $a8, $9b, $06,  $c0, $cf, $0b,  $c3, $8c, $06,  $c9, $ef, $0b,  $ca, $ad, $09,  $ea, $66, $06,  $ec, $55, $05,  $f3, $df, $0c
  .byte $13  ,  $01, $12, $04,  $05, $dd, $0a,  $1a, $23, $05,  $29, $46, $05,  $2b, $79, $04,  $33, $89, $05,  $3a, $78, $04,  $3b, $21, $01,  $55, $8a, $05,  $5e, $77, $04,  $7b, $cd, $08,  $8a, $bb, $08,  $96, $af, $09,  $97, $35, $04,  $d8, $66, $03,  $dd, $67, $02,  $e1, $54, $03,  $e3, $de, $09,  $f5, $ef, $0a
  .byte $0d  ,  $18, $02, $05,  $2c, $46, $06,  $41, $ff, $0b,  $44, $78, $0a,  $4b, $12, $05,  $73, $13, $04,  $7c, $ee, $0b,  $82, $79, $09,  $83, $bc, $07,  $92, $79, $0a,  $ac, $dc, $0a,  $c3, $13, $03,  $d1, $32, $02
  .byte $05  ,  $28, $68, $09,  $3e, $22, $05,  $50, $21, $04,  $55, $24, $04,  $96, $24, $06
  .byte $03  ,  $18, $54, $08,  $44, $68, $0a,  $7e, $54, $09
  .byte $08  ,  $2b, $57, $09,  $2c, $32, $06,  $83, $21, $05,  $95, $99, $0a,  $a9, $11, $05,  $c7, $67, $09,  $dd, $ac, $0c,  $e1, $cb, $09
  .byte $06  ,  $44, $76, $0b,  $4b, $76, $0a,  $55, $77, $0a,  $5f, $cc, $0d,  $6a, $46, $08,  $92, $ae, $09
  .byte $0a  ,  $06, $59, $02,  $29, $6a, $04,  $2b, $9d, $06,  $3b, $58, $02,  $73, $48, $02,  $7b, $69, $03,  $a9, $5a, $03,  $c7, $7b, $05,  $dd, $9c, $06,  $e8, $7c, $05
  .byte $02  ,  $4d, $01, $08,  $e3, $9f, $05
  .byte $05  ,  $1c, $a6, $0f,  $5e, $a5, $0e,  $ac, $a5, $0f,  $e1, $a6, $0e,  $ff, $ec, $0f
  .byte $00
  .byte $0a  ,  $1c, $ca, $0c,  $28, $30, $04,  $53, $c9, $0c,  $5e, $23, $0b,  $6a, $95, $0a,  $ac, $20, $04,  $c1, $68, $0d,  $e1, $53, $03,  $f6, $b8, $0b,  $ff, $20, $03
  .byte $06  ,  $05, $ec, $0f,  $0e, $14, $04,  $1d, $58, $08,  $8a, $7a, $02,  $a9, $03, $03,  $d1, $ad, $05
  .byte $0c  ,  $0c, $7a, $0c,  $43, $69, $0c,  $53, $84, $09,  $54, $03, $04,  $68, $bb, $08,  $6a, $a9, $08,  $7c, $68, $0a,  $96, $68, $09,  $c1, $84, $0a,  $d8, $94, $09,  $e1, $ab, $0f,  $f6, $bb, $0f
  .byte $02  ,  $5e, $ca, $0a,  $d1, $ba, $09
  .byte $07  ,  $53, $ec, $0e,  $68, $8b, $0c,  $8a, $9c, $04,  $c1, $dd, $0a,  $d8, $7b, $08,  $e1, $58, $00,  $e8, $c9, $0c
  .byte $04  ,  $28, $b8, $0b,  $5e, $fd, $0e,  $a9, $32, $02,  $d1, $8c, $04
  .byte $03  ,  $68, $cf, $0e,  $8a, $fc, $0f,  $e1, $69, $0d
  .byte $03  ,  $04, $eb, $0e,  $0e, $ea, $0e,  $54, $d9, $0d
  .byte $04  ,  $5e, $7a, $0d,  $68, $38, $00,  $e1, $bf, $0a,  $f6, $fc, $0e
  .byte $04  ,  $0e, $14, $04,  $1d, $73, $0b,  $54, $b7, $0c,  $c1, $25, $08
  .byte $04  ,  $28, $cf, $08,  $68, $ba, $0c,  $7c, $aa, $0b,  $b7, $dd, $0e
  .byte $36  ,  $01, $9d, $08,  $04, $bb, $0c,  $05, $dc, $0c,  $06, $dc, $0d,  $08, $cb, $0c,  $09, $ba, $0b,  $0c, $a9, $0a,  $0e, $32, $03,  $11, $98, $0a,  $14, $87, $08,  $15, $cf, $0c,  $17, $44, $04,  $18, $88, $08,  $1a, $cd, $0d,  $1b, $dd, $0d,  $1c, $dd, $0c,  $1d, $cc, $0c,  $25, $11, $02,  $27, $ed, $0e,  $29, $33, $03,  $2b, $ab, $0b,  $2c, $bc, $0c,  $2f, $de, $0e,  $33, $bd, $0b,  $34, $77, $08,  $3a, $68, $07,  $3b, $89, $09,  $3d, $ee, $0f,  $3e, $00, $01,  $41, $87, $09,  $43, $76, $07,  $44, $43, $04,  $45, $65, $06,  $46, $98, $09,  $47, $54, $05,  $48, $46, $05,  $4b, $69, $06,  $4d, $9b, $0a,  $4f, $a9, $0b,  $50, $10, $01,  $51, $36, $03,  $53, $43, $05,  $54, $ce, $0c,  $55, $df, $0d,  $56, $76, $08,  $57, $8b, $07,  $59, $9c, $09,  $5b, $ad, $0a,  $5d, $8b, $08,  $5e, $7a, $07,  $62, $79, $08,  $69, $be, $0b,  $6a, $8a, $09,  $6b, $58, $05
  .byte $09  ,  $4e, $24, $01,  $73, $aa, $0c,  $74, $10, $02,  $75, $54, $04,  $77, $ac, $0b,  $78, $21, $02,  $79, $ce, $0d,  $7b, $ee, $0c,  $7d, $ef, $0f
  .byte $0f  ,  $05, $af, $0e,  $0f, $bf, $0e,  $23, $bf, $0d,  $4a, $7a, $05,  $4f, $47, $03,  $53, $56, $03,  $56, $46, $02,  $7e, $22, $04,  $80, $bf, $0c,  $81, $dc, $0e,  $82, $bf, $0b,  $83, $df, $0e,  $86, $cb, $0d,  $88, $54, $06,  $8a, $88, $0a
  .byte $07  ,  $37, $af, $0c,  $50, $13, $00,  $51, $a9, $0b,  $75, $78, $05,  $78, $21, $03,  $91, $11, $03,  $96, $65, $07
  .byte $08  ,  $05, $12, $00,  $0f, $89, $06,  $23, $77, $09,  $4a, $cd, $0e,  $4d, $58, $04,  $4f, $bd, $0c,  $56, $32, $04,  $74, $78, $09
  .byte $08  ,  $01, $7a, $05,  $0e, $44, $06,  $37, $57, $03,  $3c, $43, $05,  $50, $cc, $0e,  $6b, $47, $04,  $75, $36, $04,  $79, $9a, $0b
  .byte $07  ,  $11, $11, $00,  $4f, $9b, $0a,  $56, $10, $01,  $7b, $00, $02,  $7e, $58, $05,  $80, $78, $05,  $81, $67, $08
  .byte $1d  ,  $01, $af, $0f,  $3c, $af, $0e,  $4d, $bf, $0e,  $4e, $af, $0d,  $75, $af, $0c,  $79, $bf, $0c,  $8f, $bf, $0d,  $99, $89, $0a,  $a1, $22, $04,  $a2, $ce, $0d,  $a5, $cc, $0a,  $a8, $ee, $0c,  $a9, $bd, $0c,  $aa, $9d, $08,  $ac, $36, $03,  $bd, $98, $0a,  $c1, $03, $01,  $c2, $54, $03,  $c3, $8b, $09,  $c6, $8a, $0a,  $c7, $9c, $0a,  $cc, $ab, $0c,  $ce, $57, $08,  $d0, $be, $0c,  $d1, $cb, $0b,  $d2, $bc, $0d,  $d8, $57, $07,  $dc, $56, $08,  $dd, $a9, $09
  .byte $12  ,  $0f, $58, $04,  $11, $ae, $0f,  $37, $33, $05,  $4a, $ae, $0e,  $56, $ae, $0c,  $7b, $ae, $0d,  $7e, $be, $0d,  $80, $a9, $08,  $cf, $9a, $0b,  $e3, $af, $0b,  $e4, $34, $05,  $e8, $67, $04,  $f0, $be, $0e,  $f2, $9e, $0b,  $f5, $9d, $0b,  $f6, $ae, $0b,  $f7, $cf, $0d,  $fa, $46, $07
  .byte $09  ,  $23, $58, $05,  $3a, $32, $04,  $51, $01, $02,  $68, $14, $02,  $6b, $54, $04,  $73, $76, $08,  $83, $21, $02,  $86, $10, $02,  $96, $00, $02
  .byte $21  ,  $01, $9f, $07,  $0e, $14, $01,  $11, $58, $03,  $3c, $9e, $06,  $4a, $6a, $04,  $4d, $af, $07,  $4e, $7a, $05,  $4f, $13, $00,  $56, $24, $01,  $75, $47, $03,  $79, $9d, $07,  $7b, $be, $08,  $7e, $9d, $06,  $80, $9c, $06,  $82, $ad, $07,  $8f, $47, $04,  $91, $46, $02,  $a5, $af, $08,  $a8, $98, $08,  $a9, $59, $03,  $bd, $11, $00,  $c1, $57, $03,  $c2, $dc, $0c,  $c3, $cb, $0d,  $c6, $a9, $0b,  $c7, $77, $09,  $cc, $32, $03,  $ce, $9e, $07,  $d0, $ae, $07,  $d1, $bf, $07,  $d5, $69, $04,  $d9, $87, $07,  $dc, $8c, $06
  .byte $14  ,  $07, $25, $00,  $10, $48, $02,  $27, $7b, $05,  $3a, $36, $02,  $3d, $9b, $0a,  $50, $35, $01,  $68, $bd, $08,  $6b, $78, $05,  $77, $9b, $06,  $7d, $65, $07,  $83, $ba, $0c,  $86, $aa, $0c,  $8a, $89, $06,  $96, $ab, $0c,  $a2, $44, $06,  $c5, $af, $06,  $cf, $68, $07,  $d7, $34, $01,  $d8, $7c, $05,  $dd, $8d, $06
  .byte $11  ,  $28, $9d, $0e,  $78, $9d, $0d,  $a8, $8d, $0d,  $b7, $14, $00,  $c2, $37, $02,  $c3, $25, $01,  $c6, $23, $04,  $c9, $9c, $0a,  $d1, $8e, $06,  $d9, $9a, $0b,  $e3, $55, $07,  $e8, $00, $02,  $f0, $ac, $0b,  $f7, $9e, $0a,  $f8, $9e, $0c,  $fa, $8d, $07,  $ff, $8c, $05
  .byte $13  ,  $06, $47, $02,  $07, $25, $02,  $0a, $24, $00,  $10, $43, $05,  $15, $36, $01,  $1b, $67, $04,  $1c, $7d, $06,  $21, $8d, $05,  $2a, $8c, $0a,  $2f, $8c, $0c,  $36, $48, $03,  $3d, $8c, $07,  $3f, $7b, $06,  $42, $8c, $0b,  $4d, $6a, $05,  $50, $8c, $08,  $55, $8c, $09,  $5f, $8b, $05,  $68, $03, $00
  .byte $0a  ,  $01, $11, $03,  $22, $69, $03,  $24, $57, $06,  $28, $bd, $08,  $2c, $45, $02,  $3c, $32, $04,  $51, $66, $08,  $54, $12, $03,  $62, $32, $02,  $69, $7d, $05
  .byte $09  ,  $02, $98, $08,  $08, $35, $01,  $0a, $26, $01,  $0e, $25, $00,  $10, $21, $01,  $1a, $21, $03,  $1c, $01, $02,  $1d, $7c, $04,  $1f, $7a, $04
  .byte $06  ,  $04, $99, $07,  $09, $21, $02,  $1e, $43, $05,  $21, $76, $06,  $22, $6b, $04,  $28, $7b, $04
  .byte $08  ,  $02, $24, $00,  $07, $69, $03,  $0a, $10, $02,  $0b, $88, $06,  $0c, $10, $01,  $10, $54, $04,  $1c, $23, $00,  $1d, $59, $04
  .byte $03  ,  $04, $68, $03,  $06, $79, $04,  $12, $65, $05
  .byte $01  ,  $01, $25, $02
  .byte $01  ,  $03, $47, $02
  .byte $00
  .byte $01  ,  $01, $37, $03
  .byte $01  ,  $02, $25, $02
  .byte $01  ,  $01, $33, $01
  .byte $01  ,  $02, $22, $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  
  
  ; FIXME: added another 0 here!  
  .byte $00

    .include utils/x16.s
    .include utils/utils.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include tests/vera_sd_tests.s
