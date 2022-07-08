; This code generates interrupts (that is: lets chips assert their output irq pins)
: If an interrupt controller is installed the source of these interrupts
; can be seen in the address space of IO7. 
: The code below records an shows the progression of interrupt registers over time
: it also shows the corresponding IO7 data.

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

; TODO: some these are needed by the utils.s, but are not used by the interrupt controller. We should get rid of this dependency. 
; Memory testing
START_ADDR_HIGH           = $10
END_ADDR_HIGH             = $11
BANK_TESTING              = $12
MEMORY_ADDR_TESTING       = $14 ; 15
NR_OF_WORKING_RAM_BANKS   = $16 ; 17
NR_OF_UNIQUE_RAM_BANKS    = $18 ; 19
BAD_VALUE                 = $1A
    
TIME_INDEX                = $20

; RAM

VIA1_RESULTS              = $4000
VIA2_RESULTS              = $4100
VERA_RESULTS              = $4200

IO7_RESULTS               = $4F00


; Other constants

TIME_INDEX_Y_POS           = 20
VIA1_INTERRUPT_FLAGS_Y_POS = 22
VIA2_INTERRUPT_FLAGS_Y_POS = 24
VERA_INTERRUPT_FLAGS_Y_POS = 26
IO7_Y_POS                  = 28

ROW_HEADER_X_POS           = 2



    .org $C000

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; Requires tile setup (8x8) for layer 0
    .include "../utils/rom_only_setup_vera_for_tile_map.s"

    ; Change pallete colors
    .include "utils/rom_only_change_palette_colors.s"
    
    ; Copy petscii charset to VRAM
    .include "../utils/rom_only_copy_petscii_charset.s"
    
    ; Clear tilemap screen
    .include "utils/rom_only_clear_tilemap_screen.s"
    
    ; Setup stack
    ldx #$ff
    txs
    
    jsr print_title

    ; Init cursor for printing to screen
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    sta CURSOR_X
    lda #5         ; We already printed a title
    sta CURSOR_Y
    
    ; Setup VIA1 counter in single shot Mode
    jsr setup_via1_counter1_in_single_shot_mode
    
    ; Setup VIA2 counter in single shot Mode
    jsr setup_via2_counter1_in_single_shot_mode
    
    ; Setup VERA PCM playback and enable AFLOW interrupt
    jsr setup_pcm_playback_with_aflow_interrupt
    
    
    ; Registering progress of interrupt flags over time
    
    ldx #0
register_next_time_index:
    
    lda VIA1_IFR
    sta VIA1_RESULTS,x
    
    lda VIA2_IFR
    sta VIA2_RESULTS,x
    
    lda VERA_ISR
    sta VERA_RESULTS,x
    
    lda IO7_BASE_ADDRESS
    sta IO7_RESULTS,x
    
    phx
    jsr wait_a_while
    plx
    
    inx
    cpx #16
    bne register_next_time_index
    
    
    ; Printing results
    
    jsr print_row_headers

    ; Setup indentation
    lda #14
    sta INDENTATION
    
    stz TIME_INDEX
print_next_time_index:
    lda #COLOR_OK
    sta TEXT_COLOR
    jsr reset_column
    jsr print_time_index
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    jsr reset_column
    jsr print_via1_counter1_interrupt_flags
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    jsr reset_column
    jsr print_via2_counter1_interrupt_flags
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    jsr reset_column
    jsr print_vera_interrupt_flags
    
    ; .... more to follow ...
    
    lda #COLOR_TITLE
    sta TEXT_COLOR
    jsr reset_column
    jsr print_io7_flags
    
    inc TIME_INDEX
    lda TIME_INDEX
    cmp #16
    bne print_next_time_index
    
tmp_loop:
    jmp tmp_loop
    
    
    rts
    
    
    
setup_via1_counter1_in_single_shot_mode:

    ; Printing message to screen

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    lda #<setup_via1_in_single_shot_mode_message
    sta TEXT_TO_PRINT
    lda #>setup_via1_in_single_shot_mode_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; Using Timer 1 in Single Shot mode on VIA 1
    
    ; We fill the counter with it specific 16-bit value
    lda #$00
    sta VIA1_T1C_L
    lda #$80
    sta VIA1_T1C_H
    
    lda #VIA_T1_MODE0  ; single-shot mode
    sta VIA1_ACR
   
    lda #%01111111  ; Disable all interrupts
    sta VIA1_IER 

    lda #%11111111  ; Clear all interrupts
    sta VIA1_IFR 
    
    lda #%11000000  ; Enable interrupt for timer 1
    sta VIA1_IER 
    
    lda #COLOR_OK
    sta TEXT_COLOR
    lda #<done_message
    sta TEXT_TO_PRINT
    lda #>done_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr move_cursor_to_next_line
    jsr move_cursor_to_next_line
    
    rts
    
setup_via2_counter1_in_single_shot_mode:

    ; Printing message to screen

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    lda #<setup_via2_in_single_shot_mode_message
    sta TEXT_TO_PRINT
    lda #>setup_via2_in_single_shot_mode_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; Using Timer 1 in Single Shot mode on VIA 2
    
    ; We fill the counter with it specific 16-bit value
    lda #$00
    sta VIA2_T1C_L
    lda #$C0
    sta VIA2_T1C_H
    
    lda #VIA_T1_MODE0  ; single-shot mode
    sta VIA2_ACR
   
    lda #%01111111  ; Disable all interrupts
    sta VIA2_IER 

    lda #%11111111  ; Clear all interrupts
    sta VIA2_IFR 
    
    lda #%11000000  ; Enable interrupt for timer 1
    sta VIA2_IER 
    
    lda #COLOR_OK
    sta TEXT_COLOR
    lda #<done_message
    sta TEXT_TO_PRINT
    lda #>done_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr move_cursor_to_next_line
    jsr move_cursor_to_next_line
    
    rts
    

setup_pcm_playback_with_aflow_interrupt:

    ; Printing message to screen

    lda #COLOR_NORMAL
    sta TEXT_COLOR
    lda #<setup_pcm_playback_with_aflow_interrupt_message
    sta TEXT_TO_PRINT
    lda #>setup_pcm_playback_with_aflow_interrupt_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; We reset the FIFO and configure it
    lda #%10000000  ; FIFO Reset, 8-bit, Mono, no volume
    sta VERA_AUDIO_CTRL
    
    ; We set the PCM sample rate to 0 (no sampling)
    lda #$00
    sta VERA_AUDIO_RATE
    
    ; We fill the PCM buffer with a few hunderd bytes of data

    lda #$00  ; It really doesn't matter where we fill it with
    ldy #5
fill_pcm_audio_block_with_ff:
    ldx #0
fill_pcm_audio_byte_with_ff:
    sta VERA_AUDIO_DATA
    inx
    bne fill_pcm_audio_byte_with_ff
    dey
    bne fill_pcm_audio_block_with_ff
    
    ; The buffer should be full. We will now start "playback" by setting a sampling rate. 

    ; -- Start playback
    lda #67 ; Slightly more than 64 (=24414 Hz). Using 24414Hz it would play exactly 256 bytes at 8MHz. 
    sta VERA_AUDIO_RATE
    
    ; Reset and enable AFLOW interrupt

    lda #%00000111 ; ACK any existing IRQs in VERA
    sta VERA_ISR
    
    lda #%00001000  ; enable only AFLOW irq
    sta VERA_IEN

    lda #COLOR_OK
    sta TEXT_COLOR
    lda #<done_message
    sta TEXT_TO_PRINT
    lda #>done_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    jsr move_cursor_to_next_line
    jsr move_cursor_to_next_line
    
    rts


wait_a_while:
    ldx #4
wait_a_while_256:
    ldy #0
wait_a_while_1:

    iny
    bne wait_a_while_1
    dex
    bne wait_a_while_256

    rts



; ========== Printing ==============


print_time_index:
    
    lda #TIME_INDEX_Y_POS
    sta CURSOR_Y
    
    jsr setup_cursor
    
    lda TIME_INDEX
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    rts

print_via1_counter1_interrupt_flags:

    lda #VIA1_INTERRUPT_FLAGS_Y_POS
    sta CURSOR_Y
    
    jsr setup_cursor
    
    ldx TIME_INDEX
    lda VIA1_RESULTS, x
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    rts
    
print_via2_counter1_interrupt_flags:

    lda #VIA2_INTERRUPT_FLAGS_Y_POS
    sta CURSOR_Y
    
    jsr setup_cursor
    
    ldx TIME_INDEX
    lda VIA2_RESULTS, x
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    rts
    
print_vera_interrupt_flags:

    lda #VERA_INTERRUPT_FLAGS_Y_POS
    sta CURSOR_Y
    
    jsr setup_cursor
    
    ldx TIME_INDEX
    lda VERA_RESULTS, x
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    rts
    
print_io7_flags:

    lda #IO7_Y_POS
    sta CURSOR_Y
    
    jsr setup_cursor
    
    ldx TIME_INDEX
    lda IO7_RESULTS, x
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    rts
    
print_row_headers:
    lda #COLOR_OK
    sta TEXT_COLOR
    
    lda #ROW_HEADER_X_POS
    sta CURSOR_X
    lda #TIME_INDEX_Y_POS
    sta CURSOR_Y
    jsr setup_cursor
    lda #<index_row_header
    sta TEXT_TO_PRINT
    lda #>index_row_header
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #ROW_HEADER_X_POS
    sta CURSOR_X
    lda #VIA1_INTERRUPT_FLAGS_Y_POS
    sta CURSOR_Y
    jsr setup_cursor
    lda #<via1_row_header
    sta TEXT_TO_PRINT
    lda #>via1_row_header
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero
    
    lda #ROW_HEADER_X_POS
    sta CURSOR_X
    lda #VIA2_INTERRUPT_FLAGS_Y_POS
    sta CURSOR_Y
    jsr setup_cursor
    lda #<via2_row_header
    sta TEXT_TO_PRINT
    lda #>via2_row_header
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero
    
    lda #ROW_HEADER_X_POS
    sta CURSOR_X
    lda #VERA_INTERRUPT_FLAGS_Y_POS
    sta CURSOR_Y
    jsr setup_cursor
    lda #<vera_row_header
    sta TEXT_TO_PRINT
    lda #>vera_row_header
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero

    lda #COLOR_TITLE
    sta TEXT_COLOR
    
    lda #ROW_HEADER_X_POS
    sta CURSOR_X
    lda #IO7_Y_POS
    sta CURSOR_Y
    jsr setup_cursor
    lda #<io7_row_header
    sta TEXT_TO_PRINT
    lda #>io7_row_header
    sta TEXT_TO_PRINT + 1
    jsr print_text_zero

    rts


reset_column:
    lda TIME_INDEX
    asl
    asl
    clc
    adc INDENTATION
    sta CURSOR_X
    
    rts


setup_via1_in_single_shot_mode_message:
    .asciiz "Setting up VIA1 counter in single shot mode ... "
setup_via2_in_single_shot_mode_message:
    .asciiz "Setting up VIA2 counter in single shot mode ... "
setup_pcm_playback_with_aflow_interrupt_message:
    .asciiz "Setting up VERA PCM playback with AFLOW interrupt enabled ... "
    
index_row_header:
    .asciiz "Index: "
via1_row_header:
    .asciiz "VIA1 IFR: "
via2_row_header:
    .asciiz "VIA2 IFR: "
vera_row_header:
    .asciiz "VERA ISR: "
io7_row_header:
    .asciiz "IO7: "
    
    
    
title_message:
    .asciiz "*** Interrupt Controller Tester v0.1 ***"

print_title:
    ; Init cursor for printing title to screen
    lda #0
    sta INDENTATION
    lda #18
    sta CURSOR_X
    lda #2
    sta CURSOR_Y

    ; Print title
    
    lda #COLOR_TITLE
    sta TEXT_COLOR
    lda #<title_message
    sta TEXT_TO_PRINT
    lda #>title_message
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
    

    ; === Included files ===
    
    .include "utils/x16.s"
    .include "utils/utils.s"

    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"

    ; ======== NMI / IRQ =======
nmi:
    rti
   
irq:
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
