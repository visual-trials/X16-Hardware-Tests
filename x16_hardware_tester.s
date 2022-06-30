
; ===========================
; === X16 Hardware Tester ===
; ===========================


; == Zero page addresses

; Bank switching
RAM_BANK            = $00
ROM_BANK            = $01

; Temp vars
TMP1                = $02
TMP2                = $03
TMP3                = $04
TMP4                = $05

; Printing
TEXT_TO_PRINT       = $06 ; 07
TEXT_COLOR          = $08
CURSOR_X            = $09
CURSOR_Y            = $0A
INDENTATION         = $0B
BYTE_TO_PRINT       = $0C
DECIMAL_STRING      = $0D ; 0E ; 0F

; Memory testing
START_ADDR_HIGH     = $10
END_ADDR_HIGH       = $11
BANK_TESTING        = $12
MEMORY_ADDR_TESTING = $14 ; 15
NR_OF_WORKING_RAM_BANKS = $16 ; 17
NR_OF_UNIQUE_RAM_BANKS  = $18 ; 19
BAD_VALUE           = $1A

TIMING_COUNTER      = $20 ; 21
COUNTER_IS_RUNNING  = $22
ESTIMATED_CPU_SPEED_PCM   = $23
ESTIMATED_CPU_SPEED_VSYNC = $24

; Some RAM address locations we use
IRQ_RAM_ADDRES = $1000
ROM_TEST_CODE  = $4000


    .org $C000

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; We enable VERA as soon as possible (and set it up), to give a sign of life (rom only)
    .include "utils/rom_only_setup_vera_for_tile_map.s"  

    ; Setup initial (rom only) screen and title
    .include "utils/rom_only_setup_screen.s"

    ; Test Zero Page and Stack RAM once
    .include "tests/rom_only_test_zp_and_stack_ram_once.s"

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
    
    ; Test Fixed RAM
    jsr test_fixed_ram
    
jmp after_sound_test
; FIXME: very crude PSG test
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
    
; FIXME!
tmp_loop:
    jmp tmp_loop
after_sound_test:    

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
    
    ; TODO: read MBR sector and test/show results!
    
done_with_sd_checks:

; FIXME: there is something VERY WEIRD: when I put the VERA Video code BEFORE the VERA SD code the pcm speed test will fail!

    ; === VERA Video ===
    jsr print_vera_video_header
    
    ; Test VRAM (read/write)
    jsr test_vram

    ; Use PCM FIFO buffer to measure CPU speed
    jsr measure_cpu_speed_using_pcm
    
    ; Use V-sync irqs to measure CPU speed
    jsr measure_cpu_speed_using_vsync
    
    
    
loop:
    ; TODO: wait for (keyboard) input
    jmp loop

    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include tests/fixed_ram_tests.s
    .include tests/banked_ram_tests.s
    .include tests/banked_rom_tests.s
    .include tests/vera_video_tests.s
    .include tests/vera_sd_tests.s
  
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
