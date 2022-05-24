
; ===========================
; === X16 Hardware Tester ===
; ===========================

; TODO: use ca65/cl65 instead of vasm6502_oldstyle

TILE_MAP_WIDTH = 128
TILE_MAP_HEIGHT = 64

NR_OF_ROM_BANKS = 32

MARGIN          = 2
INDENT_SIZE     = 2

; Colors
COLOR_TITLE        = $43 ; Background color = 4, foreground color 3 (cyan)
COLOR_NORMAL       = $41 ; Background color = 4, foreground color 1 (white)
COLOR_HEADER       = $47 ; Background color = 4, foreground color 7 (yellow)
COLOR_OK           = $45 ; Background color = 4, foreground color 5 (green)
COLOR_ERROR        = $42 ; Background color = 4, foreground color 2 (red)

; == Zero point addresses

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
DECIMAL_STRING      = $0D ; $0E ; $0F

; Memory testing
START_ADDR_HIGH     = $10
END_ADDR_HIGH       = $11
BANK_TESTING        = $12
MEMORY_ADDR_TESTING = $14 ; 15
NR_OF_WORKING_RAM_BANKS = $16 ; $17
NR_OF_UNIQUE_RAM_BANKS  = $18 ; $19

TIMING_COUNTER      = $20 ; $21
COUNTER_IS_RUNNING  = $22
ESTIMATED_CPU_SPEED = $23

; Some RAM address location we use
IRQ_RAM_ADDRES = $1000
ROM_TEST_CODE  = $4000


    .org $C000

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; We enable VERA as soon as possible (and set it up), to give a sign of life
    .include "rom_only/setup_vera_for_tile_map.s"  

    ; Setup initial (rom only) screen...
    .include "rom_only/setup_screen.s"

    ; Test Zero Page and Stack RAM once (this also prints to screen in a crude way)
    .include "rom_only/test_zp_and_stack_ram_once.s"

    ; These are separate test if VERA is not working properly. They make errors visible on screen.
    ; .include "rom_only/test_vera_write_and_read_continuously.s"
    ; .include "rom_only/test_vera_write_only_continuously.s"

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

    ; === Banked RAM ===
    jsr print_banked_ram_header
    
    ; Measure the amount of banked RAM
    jsr determine_nr_of_ram_banks
    
    ; Based on the number of unique ram banks, we check those ram banks (every byte in it)
    jsr test_banked_ram 
    
    ; === Banked RAM ===
    jsr print_banked_rom_header
    
    ; We filled all ROM banks with incrementing numbers and check these with a program in RAM
    jsr test_rom_banks

    ; === VERA ===
    jsr print_vera_header
    
    ; Test VRAM (read/write)
    jsr test_vram

    ; Use V-sync irqs to measure CPU speed
    jsr measure_cpu_speed

    
loop:
    ; TODO: wait for (keyboard) input
    jmp loop

    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include tests/fixed_ram_tests.s
    .include tests/banked_ram_tests.s
    .include tests/banked_rom_tests.s
    .include tests/vera_tests.s
  
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"

    ; ======== NMI / IRQ =======
nmi:
    ; TODO: implement this
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
