
; ===========================
; === X16 Hardware Tester ===
; ===========================


; == Zero page addresses

; Bank switching
RAM_BANK                  = $00
ROM_BANK                  = $01

; Temp vars
TMP1                      = $02
TMP2                      = $03
TMP3                      = $04
TMP4                      = $05

; Printing
TEXT_TO_PRINT             = $06 ; 07
TEXT_COLOR                = $08
CURSOR_X                  = $09
CURSOR_Y                  = $0A
INDENTATION               = $0B
BYTE_TO_PRINT             = $0C
DECIMAL_STRING            = $0D ; 0E ; 0F

; Memory testing
START_ADDR_HIGH           = $10
END_ADDR_HIGH             = $11
BANK_TESTING              = $12
MEMORY_ADDR_TESTING       = $14 ; 15
NR_OF_WORKING_RAM_BANKS   = $16 ; 17
NR_OF_UNIQUE_RAM_BANKS    = $18 ; 19
BAD_VALUE                 = $1A

SD_DUMP_ADDR              = $1C ; 1D

TIMING_COUNTER            = $20 ; 21
COUNTER_IS_RUNNING        = $22
ESTIMATED_CPU_SPEED_PCM   = $23
ESTIMATED_CPU_SPEED_VSYNC = $24

YM_STRECH_DOING_NOTHING   = $25 ; 26
YM_STRECH_READING_FROM_YM = $27 ; 28
    
; Some RAM address locations we use
IRQ_RAM_ADDRES = $8F00
MBR_SLOW_L     = $9000
MBR_SLOW_H     = $9100
MBR_FAST_L     = $9200
MBR_FAST_H     = $9300
ROM_TEST_CODE  = $9400


    .include utils/build_as_prg_or_rom.s

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; We enable VERA as soon as possible (and set it up), to give a sign of life (rom only)
    .include "utils/rom_only_setup_vera_for_tile_map.s"  

    ; Setup initial (rom only) screen and title
    .include "utils/rom_only_setup_screen.s"

    .ifndef CREATE_PRG
        ; Test Zero Page and Stack RAM once
        .include "tests/rom_only_test_zp_and_stack_ram_once.s"
    .endif
    
    ; === Zero page and stack memory checks out OK, we can now use it ===

    ; Setup stack
    ldx #$ff
    txs

    ; Init cursor for printing to screen
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    sta CURSOR_X
    lda #5          ; We already printed a title, a header and one line when testing Zero page and stack memory
    sta CURSOR_Y

    ; === Fixed RAM ===
    ; Note: We already printed the header in rom-only mode

    .ifndef CREATE_PRG
        ; Test Fixed RAM
        jsr test_fixed_ram
    
        ; === Banked RAM ===
        jsr print_banked_ram_header
        
        ; Measure the amount of banked RAM
        jsr determine_nr_of_ram_banks
        
        ; Based on the number of unique ram banks, we check those ram banks (every byte in it)
        jsr test_banked_ram 
        
        ; === Banked ROM ===
        jsr print_banked_rom_header
        
        ; We filled all ROM banks with incrementing numbers and check these with a program in RAM
        jsr test_rom_banks
    .endif

    ; FIXME: there is something VERY WEIRD: when I put the VERA Video code BEFORE the VERA SD code the pcm speed test will fail!

    ; === VERA Audio ===
    jsr print_vera_audio_header
    
    ; Use PCM FIFO buffer to measure CPU speed
    jsr measure_cpu_speed_using_pcm
    
    ; --> TODO: play a (generated) simple sound using PCM
    
    ; Play a sound using the PSG
    jsr test_psg
    
    ; --> TODO: add a test that check whether the AFLOW-interrupt is working!
    
    ; === VERA Video ===
    jsr print_vera_video_header
    
    ; Test VRAM (read/write)
    jsr test_vram

    ; Use V-sync irqs to measure CPU speed
    jsr measure_cpu_speed_using_vsync
    
    ; --> TODO: add a test showing the sprites working!
    
    ; --> TODO: add a test showing the line interrupts working!
    
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
    
    ; Reading the MBR in slow speed
    jsr vera_read_sector
    
    ; Reading the MBR in fast speed
	lda #SPI_CHIP_SELECT_AND_FAST
	sta VERA_SPI_CTRL
    jsr vera_read_sector
    
    ; bcc show_differences   ; We could not read a sector so we do not proceed with SD Card tests

    ; Show results:
    ; jsr print_mbr
    
done_with_sd_checks:

    ; === VIA ===
    jsr print_via_header
    
    ; We are writing to and reading from latch 1 of VIA #1
    jsr test_writing_and_reading_via1_latch_1
    
    ; We are trying to determine the CPU clock speed based on the counter 1 of VIA #1
    jsr test_via1_counter1_speed
    
    ; We are writing to and reading from latch 1 of VIA #2
    jsr test_writing_and_reading_via2_latch_1
    
    ; We are trying to determine the CPU clock speed based on the counter 1 of VIA #2
    jsr test_via2_counter1_speed
    
    ; === SMC ===
    ; FIXME: Maybe only do the SMC tests if VIA1 has no errors?
    jsr print_smc_header
    
    ; We are echoing towards the SMC
    jsr test_echoing_towards_smc
    
    ; We are trying to receive keyboard keycode from the SMC
    jsr test_receiving_keyboard_keycode_smc
    
    ; === RTC ===
    ; FIXME: Maybe only do the RTC tests if VIA1 has no errors?
    jsr print_rtc_header
    
    ; We are writing and reading from the SRAM of the RTC
    jsr test_rtc_sram

    ; === YM2151 ===
    jsr print_ym_header
    
    ; Do a very simple check if the YM gives a busy flag after writing to it
    jsr ym_busy_flag_test
    
    ; Test whether there is a clock stretch when accessing the YM
    jsr test_ym_clock_strech
    
    ; --> TODO: add a test generating an interrupt using a YM-counter (see https://discord.com/channels/547559626024157184/547560914744901644/995079548502822982 )
    
loop:
    ; TODO: wait for (keyboard) input
    jmp loop

    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/i2c.s
    .include utils/memory.s
    .include tests/fixed_ram_tests.s
    .include tests/banked_ram_tests.s
    .include tests/banked_rom_tests.s
    .include tests/vera_audio_tests.s
    .include tests/vera_video_tests.s
    .include tests/vera_sd_tests.s
    .include tests/via_tests.s
    .include tests/smc_tests.s
    .include tests/rtc_tests.s
    .include tests/ym_tests.s
  
    .ifndef CREATE_PRG
    
        ; ======== PETSCII CHARSET =======

        .org $F700
        .include "utils/petscii.s"

        ; ======== NMI / IRQ =======
nmi:
        ; TODO: implement this
        ; FIXME: ugly hack!
        jmp reset
        rti
   
irq:
        ; Right now we also jump to a certain RAM adress where we copy our irq handling code (which may vary)
        jmp IRQ_RAM_ADDRES


        .org $fffa
        .word nmi
        .word reset
        .word irq

        ; 31 ROM banks filled entirely with their own bank index
        
        .fill 16384, $01
        .fill 16384, $02
        .fill 16384, $03
        .fill 16384, $04
        .fill 16384, $05
        .fill 16384, $06
        .fill 16384, $07
        .fill 16384, $08
        .fill 16384, $09
        .fill 16384, $0A
        .fill 16384, $0B
        .fill 16384, $0C
        .fill 16384, $0D
        .fill 16384, $0E
        .fill 16384, $0F

        .fill 16384, $10
        .fill 16384, $11
        .fill 16384, $12
        .fill 16384, $13
        .fill 16384, $14
        .fill 16384, $15
        .fill 16384, $16
        .fill 16384, $17
        .fill 16384, $18
        .fill 16384, $19
        .fill 16384, $1A
        .fill 16384, $1B
        .fill 16384, $1C
        .fill 16384, $1D
        .fill 16384, $1E
        .fill 16384, $1F
    
    .endif