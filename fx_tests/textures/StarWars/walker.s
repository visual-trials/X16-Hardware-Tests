; == Very crude PoC of 320x136px video playback using AUTOTX ==

; To build: ./vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\textures\StarWars\walker.s -wdc02 -D CREATE_PRG -o .\fx_tests\textures\StarWars\WALKER.PRG
; To run (from StarWars dir) : C:\x16emu_win-r44\x16emu.exe -prg .\WALKER.PRG -run -sdcard .\walker_sdcard.img

; FIXME: REMOVE THIS!
IS_EMULATOR = 1
DO_PRINT = 0
DO_BORDER_COLOR = 1
DO_MULTI_SECTOR_READS = 0
SD_USE_AUTOTX = 1

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

LOAD_ADDRESS              = $30 ; 31
CODE_ADDRESS              = $32 ; 33

VERA_ADDR_ZP_TO           = $34 ; 35 ; 36
PALETTE_CHANGE_ADDRESS    = $37 ; 38
NR_OF_COLORS_TO_CHANGE    = $39

SECTOR_NUMBER             = $47 ; 48 ; 49 ; 4A
NR_OF_SECTORS_TODO        = $4B

FRAME_NUMBER              = $4C ; 4D

BORDER_COLOR              = $4E
COMMAND18_INITIATED       = $4F

COPY_TO_VRAM_OR_AUDIO     = $50
PARTIAL_AUDIO_COPY        = $51

; === RAM addresses ===

COPY_SECTORPART_TO_AUDIO_CODE = $77E0
COPY_SECTOR_TO_AUDIO_CODE = $83F0
COPY_SECTOR_TO_VRAM_CODE  = $9000  ; (3 + 3) * 512 = 3kB + rts ~ $0C01

; FIXME: we are NOT USING THESE! (but they are required for vera_sd_tests.s)
MBR_L          = $8000
MBR_H          = $8100
MBR_SLOW_L     = $8200
MBR_SLOW_H     = $8300
MBR_FAST_L     = $8400
MBR_FAST_H     = $8500


; === Other constants ===

; Format:

; Each frame:
; 6 sectors of audio
; 1 sector of palette
; 30 sectors of video
; 3 sectors of audio (last sector is NOT full!)
; 55 sectors of video

; 1 frame of video = 85 sectors of VIDEO = 136*320 / 512 ; Note (320x136 resolution): 136 * 320 = 170 * 256 = 85 * 512 bytes (1 sector = 512 bytes)
NR_OF_SECTORS_TO_COPY_FIRST_HALF = 30  ; 48 lines of 320px
NR_OF_SECTORS_TO_COPY_SECOND_HALF = 55 ; 88 lines of 320px
NUMBER_OF_FRAMES = 968
;NUMBER_OF_FRAMES = 157

; Timings:
; assuming 25000000/(800*525) = 59.5238095238 frame rate (VSYNC)
; video will run at: 59.5238095238/3 = 19.8412698413 fps (we use 3 VSYNC frames for one frame)
; Set audio rate at 115/128 -> 43869.02Hz  = (25000000/512)*(115/128)
; This means: 4422 audio bytes for every frame (16bit mono)
;   -> (25000000/512)*(115/128) / (59.5238095238/3) * 2 bytes = 4421.99707031 bytes per (video) frame
; We can load audio in 9 sectors: 9 * 512 = 4608
; The last sector is a partial load: 256 - (4608 - 4422) = 70 bytes (186 dummy reads)

; Note: since ffmpeg can only do encode the video at 19.84 (not precise) we also slow down the audio encoding a bit (to 43866Hz)
;       so the video and audio actually *both* run a little slower than the original video. This should not really affect the calculations above
;       apart from the fact that the audio encoding is also not precise: 43866 vs 43866.2123827 -> (19.84/19.8412698413*43869.02 = 43866.2123827)

AUDIO_PART_BYTES = 70  ; 70 bytes (186 dummy bytes)
AUDIO_RATE = 115

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

    jsr generate_copy_sector_to_vram_code
    jsr generate_copy_sector_to_audio_code
    jsr generate_copy_sectorpart_to_audio_code


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
 
    .if (SD_USE_AUTOTX)
        lda #SPI_CHIP_SELECT_AND_FAST
        sta VERA_SPI_CTRL
    .endif
    
; FIXME: we are currently not resetting COMMAND18_INITIATED here! (see above)
;     .if(DO_MULTI_SECTOR_READS)
;        stz COMMAND18_INITIATED
;    .endif

    stz SECTOR_NUMBER
    stz SECTOR_NUMBER+1
    stz SECTOR_NUMBER+2
    stz SECTOR_NUMBER+3

    lda #<NUMBER_OF_FRAMES
    sta FRAME_NUMBER
    lda #>NUMBER_OF_FRAMES
    sta FRAME_NUMBER+1
 
    ; === SETUP AUDIO ===
    
    lda #%00000000
    sta VERA_AUDIO_RATE  ; stop audio
    
    lda #%10101111       ; Reset FIFO, 16bit mono, max volume
    sta VERA_AUDIO_CTRL

; FIXME: we should load 1 *sector* of palette instead!

    jsr copy_palette_from_index_1

    ; We start at the beginning of the palette changes (first change is AFTER frame 0)
    lda #<palette_changes_per_frame
    sta PALETTE_CHANGE_ADDRESS
    lda #>palette_changes_per_frame
    sta PALETTE_CHANGE_ADDRESS+1

; FIXME! Instead of this, keep track of whether you started! If not, then set to 1 and start! (but AFTER the first 6 sectors of audio load!)
; FIXME: as long as we dont do double buffering, we START playing the AUDIO here!
;    lda #AUDIO_RATE              ; Audio rate
;    sta VERA_AUDIO_RATE
    
next_frame:

    jsr load_and_draw_frame

; FIXME: make this part of the frame loading!    
    jsr do_palette_changes
    
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



load_and_draw_frame:

    ; -- loading 6 sectors of AUDIO (last one is not full) --
    
    stz COPY_TO_VRAM_OR_AUDIO ; set to load AUDIO
    stz PARTIAL_AUDIO_COPY
    
    jsr walker_vera_read_sector
    jsr walker_vera_read_sector
    jsr walker_vera_read_sector
    jsr walker_vera_read_sector
    jsr walker_vera_read_sector
    jsr walker_vera_read_sector

    ; -- loading 1 sector of PALETTE --

    ; FIXME: we should load 1 *sector* of palette instead!
    .if(0)
        lda #1
        sta COPY_TO_VRAM_OR_AUDIO ; set to load VRAM
        
        lda #<VERA_PALETTE
        sta VERA_ADDR_LOW
        lda #>VERA_PALETTE
        sta VERA_ADDR_HIGH
        lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
        sta VERA_ADDR_BANK
        
        jsr walker_vera_read_sector
    .endif

    ; -- loading 30 sectors of VIDEO (48 lines of 320px) --
    ; FIXME: no need to set this if we just dod the palette load!
    lda #1
    sta COPY_TO_VRAM_OR_AUDIO ; set to load VRAM
    
    lda #0
    sta VERA_ADDR_LOW
    sta VERA_ADDR_HIGH

    lda #%00010000      ; setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #NR_OF_SECTORS_TO_COPY_FIRST_HALF
    sta NR_OF_SECTORS_TODO
    
next_sector_to_copy_first_half:

    jsr walker_vera_read_sector

    dec NR_OF_SECTORS_TODO
    bne next_sector_to_copy_first_half


    ; -- loading 3 sectors of AUDIO (last one is not full) --
    
    stz COPY_TO_VRAM_OR_AUDIO ; set to load AUDIO
    stz PARTIAL_AUDIO_COPY
    
    jsr walker_vera_read_sector
    jsr walker_vera_read_sector
    lda #1
    sta PARTIAL_AUDIO_COPY
    jsr walker_vera_read_sector

    lda #1
    sta COPY_TO_VRAM_OR_AUDIO ; set to load VRAM
    
    lda #NR_OF_SECTORS_TO_COPY_SECOND_HALF
    sta NR_OF_SECTORS_TODO
    
next_sector_to_copy_second_half:

    jsr walker_vera_read_sector

    dec NR_OF_SECTORS_TODO
    bne next_sector_to_copy_second_half

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

    .if(SD_USE_AUTOTX)
        ; FIXME: SPEED: we should NOT do this bra, but insread *remove* (with an .if) the next section!
        bra walker_read_autotx_read_sector
    .endif
    
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

    lda COPY_TO_VRAM_OR_AUDIO
    bne copy_to_vram 
    
copy_to_audio:
    lda PARTIAL_AUDIO_COPY
    bne copy_part_to_audio
        jsr COPY_SECTOR_TO_AUDIO_CODE
    bra done_copy_to_audio_or_vram
    
copy_part_to_audio: 
        jsr COPY_SECTORPART_TO_AUDIO_CODE
    bra done_copy_to_audio_or_vram
    
copy_to_vram:
        jsr COPY_SECTOR_TO_VRAM_CODE
        
done_copy_to_audio_or_vram:

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
    ; Incrementing the SECTOR_NUMBER is NOT NEEDED when using MULTI-sector reads
    .if(!DO_MULTI_SECTOR_READS)
        inc SECTOR_NUMBER
        bne sector_number_is_incremented
        inc SECTOR_NUMBER+1
        bne sector_number_is_incremented
        inc SECTOR_NUMBER+2
        bne sector_number_is_incremented
        inc SECTOR_NUMBER+3
        bne sector_number_is_incremented
sector_number_is_incremented:
    .endif
    
    ; jsr move_cursor_to_next_line
    ; sec
    rts
    



    

generate_copy_sector_to_vram_code:

    lda #<COPY_SECTOR_TO_VRAM_CODE
    sta CODE_ADDRESS
    lda #>COPY_SECTOR_TO_VRAM_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_low_vram:

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
    bne next_copy_instruction_low_vram
    
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_high_vram:

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
    bne next_copy_instruction_high_vram
    

    ; -- rts --
    lda #$60
    jsr add_code_byte

    rts



generate_copy_sector_to_audio_code:

    lda #<COPY_SECTOR_TO_AUDIO_CODE
    sta CODE_ADDRESS
    lda #>COPY_SECTOR_TO_AUDIO_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_low_audio:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_AUDIO_DATA ($9F3D)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$3D               ; $3D
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    bne next_copy_instruction_low_audio
    
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_high_audio:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_AUDIO_DATA ($9F3D)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$3D               ; $3D
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    bne next_copy_instruction_high_audio
    

    ; -- rts --
    lda #$60
    jsr add_code_byte

    rts



generate_copy_sectorpart_to_audio_code:

    lda #<COPY_SECTORPART_TO_AUDIO_CODE
    sta CODE_ADDRESS
    lda #>COPY_SECTORPART_TO_AUDIO_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_low_audiopart:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_AUDIO_DATA ($9F3D)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$3D               ; $3D
    jsr add_code_byte

    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    cpy #AUDIO_PART_BYTES
    bne next_copy_instruction_low_audiopart
    

next_copy_instruction_low_audiodummy:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte


    ; -- lda VERA_ADDR_LOW ($9F20) -> DUMMY!
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$20               ; VERA_ADDR_LOW
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    inx
    bne next_copy_instruction_low_audiodummy

    
    ldx #0                 ; counts nr of copy instructions
next_copy_instruction_high_audiodummy:

    ; -- lda VERA_SPI_DATA ($9F3E)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$3E               ; VERA_SPI_DATA
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- lda VERA_ADDR_LOW ($9F20) -> DUMMY!
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$20               ; VERA_ADDR_LOW
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    inx
    bne next_copy_instruction_high_audiodummy
    

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
  .byte $00, $00
end_of_palette_data:


palette_changes_per_frame:
  .byte $01  ,  $02, $01, $00
  .byte $06  ,  $03, $23, $02,  $04, $22, $02,  $05, $22, $01,  $06, $12, $01,  $07, $12, $00,  $08, $11, $00
  .byte $10  ,  $09, $44, $03,  $0a, $44, $04,  $0b, $33, $03,  $0c, $43, $03,  $0d, $34, $03,  $0e, $34, $02,  $0f, $24, $02,  $10, $34, $01,  $11, $24, $01,  $12, $33, $01,  $13, $33, $02,  $14, $13, $00,  $15, $23, $00,  $16, $23, $01,  $17, $13, $01,  $18, $22, $00
  .byte $10  ,  $04, $66, $05,  $19, $66, $06,  $1a, $56, $05,  $1b, $55, $05,  $1c, $56, $04,  $1d, $56, $03,  $1e, $55, $04,  $1f, $46, $04,  $20, $55, $03,  $21, $46, $03,  $22, $46, $02,  $23, $45, $03,  $24, $45, $02,  $25, $35, $02,  $26, $44, $02,  $27, $02, $00
  .byte $0f  ,  $0a, $88, $07,  $0b, $78, $07,  $0c, $78, $06,  $0d, $77, $07,  $28, $68, $05,  $29, $77, $05,  $2a, $68, $04,  $2b, $77, $06,  $2c, $67, $04,  $2d, $67, $06,  $2e, $57, $04,  $2f, $67, $05,  $30, $57, $03,  $31, $66, $04,  $32, $35, $01
  .byte $1a  ,  $01, $89, $09,  $03, $99, $08,  $09, $99, $09,  $13, $89, $08,  $17, $79, $05,  $1b, $88, $08,  $1e, $79, $04,  $1f, $89, $06,  $33, $79, $06,  $34, $69, $05,  $35, $69, $04,  $36, $89, $07,  $37, $79, $07,  $38, $88, $06,  $39, $78, $05,  $3a, $24, $00,  $3b, $67, $03,  $3c, $56, $02,  $3d, $68, $03,  $3e, $46, $01,  $3f, $36, $02,  $40, $34, $00,  $41, $57, $02,  $42, $47, $03,  $43, $45, $01,  $44, $58, $04
  .byte $18  ,  $04, $bb, $0a,  $05, $ab, $0a,  $06, $9b, $06,  $08, $aa, $0a,  $0b, $8b, $07,  $0d, $9b, $07,  $0f, $aa, $09,  $12, $9b, $09,  $18, $aa, $08,  $19, $9a, $06,  $1a, $8b, $06,  $20, $9b, $08,  $26, $8b, $05,  $29, $8a, $05,  $2b, $9a, $09,  $2d, $8a, $07,  $2f, $7a, $05,  $31, $7a, $04,  $45, $8a, $06,  $46, $9a, $08,  $47, $9a, $07,  $48, $58, $03,  $49, $47, $02,  $4a, $36, $01
  .byte $1b  ,  $01, $cc, $0c,  $03, $cc, $0b,  $0a, $cb, $0b,  $0c, $9d, $07,  $13, $ac, $08,  $1b, $ac, $07,  $1c, $cc, $0a,  $37, $bc, $08,  $38, $bc, $0b,  $4b, $9c, $08,  $4c, $bb, $0b,  $4d, $ab, $09,  $4e, $ab, $07,  $4f, $9c, $07,  $50, $ab, $08,  $51, $bc, $09,  $52, $ac, $09,  $53, $bc, $0a,  $54, $9c, $06,  $55, $bb, $09,  $56, $69, $03,  $57, $7a, $06,  $58, $22, $00,  $59, $78, $04,  $5a, $35, $00,  $5b, $25, $01,  $5c, $03, $00
  .byte $1d  ,  $02, $ee, $0d,  $08, $de, $0d,  $09, $de, $0c,  $0b, $dd, $0d,  $0f, $dd, $0b,  $12, $dd, $0c,  $18, $ae, $07,  $19, $be, $09,  $28, $bd, $08,  $2b, $be, $08,  $2d, $ce, $0a,  $33, $cd, $0c,  $36, $ce, $09,  $39, $ae, $09,  $46, $cd, $09,  $47, $bd, $0a,  $5d, $cd, $0b,  $5e, $cd, $0a,  $5f, $ad, $09,  $60, $ad, $08,  $61, $ad, $07,  $62, $bd, $09,  $63, $9d, $06,  $64, $25, $00,  $65, $6a, $04,  $66, $89, $05,  $67, $7b, $05,  $68, $8c, $06,  $69, $14, $00
  .byte $1f  ,  $01, $ff, $0f,  $04, $ff, $0e,  $05, $ef, $0f,  $0a, $ef, $0e,  $1f, $ee, $0e,  $20, $ff, $0d,  $37, $df, $0a,  $38, $df, $0b,  $44, $ef, $0d,  $4b, $ce, $0b,  $4c, $de, $0a,  $4d, $cf, $0b,  $4e, $df, $0c,  $50, $bf, $09,  $52, $ef, $0c,  $55, $bf, $08,  $58, $cf, $0a,  $6a, $cf, $09,  $6b, $de, $0b,  $6c, $ee, $0c,  $6d, $ae, $06,  $6e, $ad, $06,  $6f, $8b, $04,  $70, $47, $01,  $71, $78, $05,  $72, $be, $07,  $73, $ae, $08,  $74, $58, $02,  $75, $36, $00,  $76, $9c, $05,  $77, $8c, $05
  .byte $07  ,  $03, $ef, $0b,  $0b, $df, $09,  $12, $ff, $0c,  $1c, $cf, $08,  $23, $8a, $04,  $33, $68, $05,  $39, $58, $04
  .byte $0c  ,  $05, $ef, $0a,  $07, $ff, $0b,  $08, $9a, $06,  $0f, $89, $06,  $16, $79, $03,  $27, $37, $01,  $46, $68, $02,  $47, $57, $01,  $4c, $ac, $06,  $51, $58, $01,  $53, $bd, $07,  $57, $9b, $05
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $01  ,  $02, $9a, $07
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $01  ,  $02, $ce, $08
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $01  ,  $02, $be, $0a
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $74  ,  $1f, $99, $09,  $23, $aa, $0a,  $5c, $9a, $0a,  $65, $56, $06,  $6d, $78, $08,  $6e, $45, $05,  $6f, $67, $07,  $76, $01, $01,  $78, $00, $00,  $79, $01, $00,  $7a, $ab, $0a,  $7b, $78, $07,  $7c, $89, $08,  $7d, $55, $05,  $7e, $66, $06,  $7f, $88, $08,  $80, $77, $06,  $81, $66, $05,  $82, $bb, $0a,  $83, $11, $01,  $84, $22, $02,  $85, $89, $07,  $86, $9a, $09,  $87, $12, $02,  $88, $44, $04,  $89, $77, $07,  $8a, $aa, $09,  $8b, $99, $08,  $8c, $57, $06,  $8d, $34, $04,  $8e, $22, $01,  $8f, $9a, $08,  $90, $9b, $08,  $91, $8a, $08,  $92, $99, $07,  $93, $bb, $09,  $94, $02, $00,  $95, $68, $06,  $96, $aa, $08,  $97, $12, $01,  $98, $ac, $0a,  $99, $34, $03,  $9a, $9a, $07,  $9b, $44, $03,  $9c, $35, $04,  $9d, $46, $04,  $9e, $ab, $09,  $9f, $9b, $09,  $a0, $13, $02,  $a1, $56, $05,  $a2, $11, $00,  $a3, $bb, $0b,  $a4, $57, $05,  $a5, $47, $05,  $a6, $13, $01,  $a7, $67, $06,  $a8, $36, $04,  $a9, $12, $00,  $aa, $cc, $0c,  $ab, $bb, $08,  $ac, $79, $07,  $ad, $58, $05,  $ae, $47, $04,  $af, $69, $06,  $b0, $8a, $07,  $b1, $45, $04,  $b2, $aa, $07,  $b3, $46, $05,  $b4, $02, $01,  $b5, $24, $03,  $b6, $dd, $0d,  $b7, $79, $06,  $b8, $23, $03,  $b9, $45, $03,  $ba, $55, $04,  $bb, $78, $06,  $bc, $88, $07,  $bd, $ab, $08,  $be, $ac, $09,  $bf, $88, $06,  $c0, $33, $03,  $c1, $66, $04,  $c2, $23, $01,  $c3, $77, $05,  $c4, $7a, $06,  $c5, $bc, $09,  $c6, $bd, $0a,  $c7, $23, $02,  $c8, $de, $0a,  $c9, $33, $02,  $ca, $bc, $0a,  $cb, $bc, $0b,  $cc, $35, $03,  $cd, $cc, $0b,  $ce, $cd, $09,  $cf, $59, $04,  $d0, $56, $04,  $d1, $de, $0d,  $d2, $ee, $0d,  $d3, $67, $05,  $d4, $8b, $07,  $d5, $dd, $0b,  $d6, $9c, $08,  $d7, $ee, $0b,  $d8, $cd, $0c,  $d9, $cc, $0a,  $da, $ab, $07,  $db, $bc, $08,  $dc, $24, $02,  $dd, $ce, $0c,  $de, $dd, $0c,  $df, $14, $01,  $e0, $cc, $09,  $e1, $25, $02,  $e2, $36, $03,  $e3, $bd, $0b
  .byte $03  ,  $05, $df, $0d,  $07, $55, $03,  $0b, $25, $03
  .byte $04  ,  $16, $89, $09,  $1c, $03, $00,  $27, $48, $04,  $3c, $8a, $09
  .byte $00
  .byte $02  ,  $27, $58, $06,  $3b, $ab, $0b
  .byte $04  ,  $05, $ee, $0e,  $3c, $77, $08,  $3e, $66, $07,  $40, $68, $07
  .byte $01  ,  $0b, $79, $08
  .byte $06  ,  $05, $df, $0d,  $1c, $7a, $07,  $3b, $9c, $09,  $3e, $78, $09,  $40, $88, $09,  $41, $8b, $08
  .byte $03  ,  $27, $8a, $09,  $3d, $59, $05,  $43, $6a, $06
  .byte $0a  ,  $02, $bc, $0c,  $07, $68, $07,  $18, $54, $04,  $3b, $43, $03,  $3c, $21, $01,  $41, $9b, $0a,  $46, $8c, $07,  $47, $76, $06,  $48, $03, $00,  $49, $ee, $0e
  .byte $09  ,  $27, $9c, $09,  $31, $22, $03,  $35, $44, $05,  $4a, $ab, $0b,  $4c, $33, $04,  $51, $ae, $07,  $53, $87, $07,  $55, $32, $02,  $56, $00, $01
  .byte $06  ,  $05, $69, $04,  $18, $55, $06,  $3c, $66, $07,  $3d, $36, $01,  $41, $cd, $0d,  $46, $be, $0a
  .byte $03  ,  $02, $df, $0d,  $07, $47, $02,  $0b, $8b, $08
  .byte $01  ,  $18, $77, $08
  .byte $07  ,  $0b, $bc, $0c,  $1c, $bf, $08,  $1e, $58, $03,  $31, $55, $06,  $35, $37, $02,  $3b, $26, $01,  $3e, $ad, $0a
  .byte $01  ,  $15, $22, $00
  .byte $02  ,  $1c, $68, $07,  $43, $7a, $07
  .byte $05  ,  $07, $7a, $04,  $15, $23, $00,  $18, $79, $04,  $27, $7b, $06,  $31, $8c, $07
  .byte $0a  ,  $1e, $34, $05,  $35, $46, $06,  $3b, $87, $08,  $3c, $35, $05,  $3d, $56, $07,  $3e, $55, $06,  $40, $77, $08,  $41, $65, $06,  $43, $54, $05,  $47, $9d, $08
  .byte $03  ,  $48, $79, $08,  $49, $6a, $05,  $4a, $ae, $09
  .byte $05  ,  $0b, $7a, $07,  $1e, $58, $03,  $35, $69, $03,  $3b, $ee, $0e,  $3c, $9c, $09
  .byte $05  ,  $1c, $37, $03,  $27, $7c, $05,  $3d, $6a, $04,  $3e, $03, $00,  $40, $8b, $08
  .byte $09  ,  $18, $ab, $0b,  $35, $48, $04,  $3b, $6a, $06,  $41, $25, $03,  $43, $14, $02,  $47, $10, $00,  $48, $ad, $0a,  $4a, $47, $02,  $4c, $68, $07
  .byte $06  ,  $27, $48, $03,  $51, $36, $01,  $53, $cd, $0d,  $55, $37, $02,  $56, $33, $01,  $57, $7b, $06
  .byte $13  ,  $35, $69, $03,  $3b, $bc, $0c,  $3e, $44, $05,  $40, $43, $03,  $41, $65, $05,  $43, $a9, $09,  $47, $68, $03,  $4a, $66, $07,  $4c, $33, $04,  $59, $88, $09,  $5a, $55, $06,  $64, $76, $07,  $66, $55, $03,  $70, $79, $04,  $72, $99, $0a,  $74, $65, $06,  $75, $54, $05,  $77, $98, $09,  $a5, $46, $01
  .byte $10  ,  $49, $48, $02,  $51, $58, $02,  $53, $59, $03,  $55, $21, $01,  $56, $44, $02,  $63, $00, $01,  $a8, $77, $08,  $ab, $47, $02,  $b2, $87, $08,  $b4, $43, $04,  $d7, $22, $03,  $e0, $8b, $08,  $e4, $aa, $0b,  $e5, $21, $02,  $e6, $76, $06,  $e7, $bf, $0a
  .byte $1d  ,  $31, $26, $00,  $35, $37, $00,  $40, $36, $00,  $a5, $37, $01,  $b3, $49, $02,  $e8, $9e, $06,  $e9, $5a, $02,  $ea, $5a, $03,  $eb, $6b, $03,  $ec, $5b, $03,  $ed, $8d, $05,  $ee, $9e, $07,  $ef, $bf, $08,  $f0, $36, $01,  $f1, $35, $00,  $f2, $8d, $06,  $f3, $af, $08,  $f4, $7b, $04,  $f5, $7c, $05,  $f6, $47, $01,  $f7, $48, $01,  $f8, $aa, $07,  $f9, $25, $00,  $fa, $ae, $07,  $fb, $59, $02,  $fc, $37, $02,  $fd, $8c, $05,  $fe, $9d, $06,  $ff, $6a, $03
  .byte $0c  ,  $08, $cd, $0d,  $1c, $ad, $06,  $3e, $38, $01,  $41, $57, $02,  $47, $be, $07,  $55, $6b, $04,  $56, $03, $00,  $63, $11, $02,  $66, $46, $01,  $70, $a9, $0a,  $75, $ba, $0b,  $8c, $6a, $05
  .byte $0b  ,  $3c, $df, $09,  $b2, $4a, $02,  $d7, $ee, $0e,  $e0, $7d, $05,  $e4, $9f, $07,  $e5, $46, $05,  $e6, $dd, $0a,  $e9, $ae, $06,  $f1, $af, $07,  $f8, $ee, $0b,  $fc, $02, $01
  .byte $06  ,  $0b, $6c, $04,  $41, $79, $04,  $48, $55, $03,  $4c, $37, $02,  $b4, $7c, $04,  $e7, $bb, $0c
  .byte $0a  ,  $43, $27, $00,  $63, $21, $02,  $70, $26, $01,  $77, $10, $00,  $9c, $32, $03,  $a0, $43, $03,  $e0, $37, $03,  $e4, $6b, $05,  $e5, $9c, $05,  $e6, $16, $00
  .byte $12  ,  $08, $8e, $06,  $1c, $9f, $07,  $3b, $39, $01,  $3c, $49, $03,  $41, $cb, $0b,  $47, $33, $04,  $48, $7d, $06,  $5a, $8c, $07,  $64, $44, $02,  $66, $38, $02,  $74, $8a, $09,  $75, $11, $02,  $a8, $15, $00,  $e7, $00, $01,  $e9, $35, $04,  $f6, $27, $01,  $f7, $9d, $08,  $f8, $ad, $0a
  .byte $0b  ,  $40, $22, $03,  $4a, $bc, $0c,  $51, $69, $03,  $59, $9c, $09,  $63, $57, $02,  $72, $be, $0b,  $77, $79, $08,  $9c, $49, $01,  $a0, $8b, $08,  $ec, $55, $03,  $f3, $46, $05
  .byte $0a  ,  $35, $af, $08,  $3b, $de, $0e,  $3c, $5a, $04,  $41, $79, $04,  $48, $58, $02,  $b2, $7d, $05,  $e0, $7c, $06,  $e4, $13, $02,  $ef, $26, $02,  $fb, $03, $01
  .byte $0b  ,  $18, $6c, $03,  $31, $48, $04,  $3e, $6b, $05,  $43, $bd, $0c,  $63, $ce, $0d,  $72, $59, $02,  $c1, $bf, $08,  $e5, $ba, $0b,  $e6, $5b, $03,  $ec, $55, $06,  $ff, $32, $03
  .byte $0b  ,  $3b, $bf, $0a,  $3c, $ac, $0b,  $47, $37, $03,  $64, $ab, $0b,  $74, $6a, $03,  $9c, $7b, $07,  $b2, $9b, $0a,  $da, $68, $07,  $ef, $7a, $07,  $f6, $ae, $09,  $fb, $5a, $02
  .byte $0c  ,  $15, $de, $0e,  $48, $8e, $05,  $63, $be, $0b,  $75, $49, $03,  $a8, $df, $0e,  $e5, $9c, $0a,  $e6, $6a, $06,  $e7, $66, $04,  $e9, $cb, $0c,  $f1, $8b, $09,  $f3, $8d, $07,  $ff, $9d, $05
  
  
  ; FIXME: added another 0 here!  
  .byte $00

    .include utils/x16.s
    .include utils/utils.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include tests/vera_sd_tests.s
