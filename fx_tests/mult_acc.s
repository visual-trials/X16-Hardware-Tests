
TOP_MARGIN = 12
LEFT_MARGIN = 16

TITLE_COLOR    = $01   ; Background color = 0 (transparent), foreground color 1 (white)
VARIABLE_COLOR = $03
VALUE_COLOR    = $05
BACKGROUND_COLOR = 04   ; 4 = Purple in this palette

CONST_C = $0002
CONST_S = $F4C3
VALUE_X1 = $0003
VALUE_X2 = $0007
VALUE_Y1 = $0123
VALUE_Y2 = $FFF3

VRAM_ADDR_SAMPLE_CONST_C      = $00000
VRAM_ADDR_SAMPLE_CONST_S      = $00002

VRAM_ADDR_SAMPLE_VALUE_X1     = $00010
VRAM_ADDR_SAMPLE_VALUE_X2     = $00012
VRAM_ADDR_SAMPLE_VALUE_X3     = $00014
VRAM_ADDR_SAMPLE_VALUE_Y1     = $00020
VRAM_ADDR_SAMPLE_VALUE_Y2     = $00022
VRAM_ADDR_SAMPLE_VALUE_Y3     = $00024
VRAM_ADDR_SAMPLE_VALUE_Z1     = $00030
VRAM_ADDR_SAMPLE_VALUE_Z2     = $00032
VRAM_ADDR_SAMPLE_VALUE_Z3     = $00034
VRAM_ADDR_SAMPLE_VALUE_INV_Z1 = $00040
VRAM_ADDR_SAMPLE_VALUE_INV_Z2 = $00042
VRAM_ADDR_SAMPLE_VALUE_INV_Z3 = $00044

;VRAM_ADDR_SAMPLE_VALUE_CAM_DIR_X = $00050
;VRAM_ADDR_SAMPLE_VALUE_CAM_DIR_Y = $00052
;VRAM_ADDR_SAMPLE_VALUE_CAM_DIR_Z = $00054

VRAM_ADDR_MULT_ACC_OUTPUT     = $00060



; === Zero page addresses ===

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

; Timing
TIMING_COUNTER            = $14 ; 15
TIME_ELAPSED_MS           = $16
TIME_ELAPSED_SUB_MS       = $17 ; one nibble of sub-milliseconds

VALUE                     = $2B ; 2C
VRAM_ADDR_VALUE           = $2D ; 2E ; 2F


VERA_ADDR_HIGH_OPERAND    = $30 ; 31 ; 32
VERA_ADDR_LOW_OPERAND     = $33 ; 34 ; 35
VERA_ADDR_MULT_RESULT_ACC = $36 ; 37 ; 38

MULT_RESULT_ACC           = $3A ; 3B ; 3C ; 3D

MULTIPLIER_STATE          = $3E

; FIXME: these are leftovers of memory tests in the general hardware tester (needed by utils.s atm). We dont use them, but cant remove them right now
BANK_TESTING              = $52   
BAD_VALUE                 = $5A



; RAM addresses

; ROM addresses


  .org $C000

reset:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs

    jsr setup_vera_for_bitmap_and_tile_map
    jsr change_palette_colors
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor
    jsr init_timer

    jsr clear_screen_slow
    
    ;lda #$10                 ; 8:1 scale, so we can clearly see the pixels
    ;sta VERA_DC_HSCALE
    ;sta VERA_DC_VSCALE

    ; jsr HACK_test_8x8_multiplier
    
    jsr test_mult_acc
    
loop:
  jmp loop

  
    
multi_acc_message: 
    .asciiz "Multiplier and accumulator "

test_mult_acc:

    lda #TITLE_COLOR
    sta TEXT_COLOR
    
    lda #7
    sta CURSOR_X
    lda #1
    sta CURSOR_Y

    lda #<multi_acc_message
    sta TEXT_TO_PRINT
    lda #>multi_acc_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    
    jsr test_multiplier_16x16
    
    
    rts
    

    
test_multiplier_16x16:

    lda #2
    sta INDENTATION
    sta CURSOR_X
    lda #4
    sta CURSOR_Y
    
    jsr setup_cursor
    
    jsr place_sample_input_values_into_vram
    jsr move_cursor_to_next_line

    jsr passthrough_of_c_and_x1
    jsr multiply_c_and_x1
    jsr multiply_s_and_x2
    jsr x1_times_c_plus_y1_times_s
    jsr x2_times_s_minus_y2_times_c
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
const_c_message: 
    .asciiz "C: "
const_s_message: 
    .asciiz "S: "
value_x1_message: 
    .asciiz "X1: "
value_x2_message: 
    .asciiz "X2: "
value_y1_message: 
    .asciiz "Y1: "
value_y2_message: 
    .asciiz "Y2: "
    
place_sample_input_values_into_vram:

    ; == Set orginal input values ==

    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; === Constant C ===
    lda #(VRAM_ADDR_SAMPLE_CONST_C>>16)
    sta VRAM_ADDR_VALUE+2
    lda #>VRAM_ADDR_SAMPLE_CONST_C
    sta VRAM_ADDR_VALUE+1
    lda #<VRAM_ADDR_SAMPLE_CONST_C
    sta VRAM_ADDR_VALUE

    lda #>CONST_C
    sta VALUE+1
    lda #<CONST_C
    sta VALUE
    
    jsr store_vram_value
    jsr load_vram_value
    
    lda #<const_c_message
    sta TEXT_TO_PRINT
    lda #>const_c_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_value

    ; === Constant S ===
    lda #(VRAM_ADDR_SAMPLE_CONST_S>>16)
    sta VRAM_ADDR_VALUE+2
    lda #>VRAM_ADDR_SAMPLE_CONST_S
    sta VRAM_ADDR_VALUE+1
    lda #<VRAM_ADDR_SAMPLE_CONST_S
    sta VRAM_ADDR_VALUE

    lda #>CONST_S
    sta VALUE+1
    lda #<CONST_S
    sta VALUE
    
    jsr store_vram_value
    jsr load_vram_value
    
    lda #<const_s_message
    sta TEXT_TO_PRINT
    lda #>const_s_message
    sta TEXT_TO_PRINT + 1
    
    lda #11
    sta CURSOR_X
    
    jsr print_value
    jsr move_cursor_to_next_line
    
    jsr move_cursor_to_next_line
    
    ; === VALUE X1 ===
    lda #(VRAM_ADDR_SAMPLE_VALUE_X1>>16)
    sta VRAM_ADDR_VALUE+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X1
    sta VRAM_ADDR_VALUE+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X1
    sta VRAM_ADDR_VALUE

    lda #>VALUE_X1
    sta VALUE+1
    lda #<VALUE_X1
    sta VALUE
    
    jsr store_vram_value
    jsr load_vram_value
    
    lda #<value_x1_message
    sta TEXT_TO_PRINT
    lda #>value_x1_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_value
    
    lda #12
    sta CURSOR_X

    ; === VALUE Y1 ===
    lda #(VRAM_ADDR_SAMPLE_VALUE_Y1>>16)
    sta VRAM_ADDR_VALUE+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_Y1
    sta VRAM_ADDR_VALUE+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_Y1
    sta VRAM_ADDR_VALUE

    lda #>VALUE_Y1
    sta VALUE+1
    lda #<VALUE_Y1
    sta VALUE
    
    jsr store_vram_value
    jsr load_vram_value
    
    lda #<value_y1_message
    sta TEXT_TO_PRINT
    lda #>value_y1_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_value
    jsr move_cursor_to_next_line

    
    ; === VALUE X2 ===
    lda #(VRAM_ADDR_SAMPLE_VALUE_X2>>16)
    sta VRAM_ADDR_VALUE+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X2
    sta VRAM_ADDR_VALUE+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X2
    sta VRAM_ADDR_VALUE

    lda #>VALUE_X2
    sta VALUE+1
    lda #<VALUE_X2
    sta VALUE
    
    jsr store_vram_value
    jsr load_vram_value
    
    lda #<value_x2_message
    sta TEXT_TO_PRINT
    lda #>value_x2_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_value
    
    lda #12
    sta CURSOR_X
    
    ; === VALUE Y2 ===
    lda #(VRAM_ADDR_SAMPLE_VALUE_Y2>>16)
    sta VRAM_ADDR_VALUE+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_Y2
    sta VRAM_ADDR_VALUE+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_Y2
    sta VRAM_ADDR_VALUE

    lda #>VALUE_Y2
    sta VALUE+1
    lda #<VALUE_Y2
    sta VALUE
    
    jsr store_vram_value
    jsr load_vram_value
    
    lda #<value_y2_message
    sta TEXT_TO_PRINT
    lda #>value_y2_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_value
    jsr move_cursor_to_next_line
    rts
    
    
passthrough_of_c_and_x1_message: 
    .asciiz "X1, C = "
    
passthrough_of_c_and_x1:

    ; == Set multiplier mode: off ==

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00000000           ; Multiplier NOT enabled
    sta MULTIPLIER_STATE
    sta $9F2C
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_X1>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X1
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X1
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache
    
    lda #(VRAM_ADDR_SAMPLE_CONST_C>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #(VRAM_ADDR_MULT_ACC_OUTPUT>>16)
    sta VERA_ADDR_MULT_RESULT_ACC+2
    lda #>(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC+1
    lda #<(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC
    
    jsr write_mult_acc_result_into_vram

    lda #<passthrough_of_c_and_x1_message
    sta TEXT_TO_PRINT
    lda #>passthrough_of_c_and_x1_message
    sta TEXT_TO_PRINT + 1
    
    jsr load_and_print_4_bytes_of_vram
    jsr move_cursor_to_next_line
    
    rts
    
multiply_c_and_x1_message: 
    .asciiz "X1 * C = "
    
multiply_c_and_x1:

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
    sta $9F2C
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_X1>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X1
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X1
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache
    
    lda #(VRAM_ADDR_SAMPLE_CONST_C>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #(VRAM_ADDR_MULT_ACC_OUTPUT>>16)
    sta VERA_ADDR_MULT_RESULT_ACC+2
    lda #>(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC+1
    lda #<(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC

    jsr write_mult_acc_result_into_vram

    lda #<multiply_c_and_x1_message
    sta TEXT_TO_PRINT
    lda #>multiply_c_and_x1_message
    sta TEXT_TO_PRINT + 1
    
    jsr load_and_print_4_bytes_of_vram
    jsr move_cursor_to_next_line
    
    rts
    
    
multiply_s_and_x2_message: 
    .asciiz "X2 * S = "
    
multiply_s_and_x2:
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
    ora #%10000000           ; reset accumulator = 1
    sta $9F2C
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_X2>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X2
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X2
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache

    lda #(VRAM_ADDR_SAMPLE_CONST_S>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_S
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_S
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #(VRAM_ADDR_MULT_ACC_OUTPUT>>16)
    sta VERA_ADDR_MULT_RESULT_ACC+2
    lda #>(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC+1
    lda #<(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC

    jsr write_mult_acc_result_into_vram

    lda #<multiply_s_and_x2_message
    sta TEXT_TO_PRINT
    lda #>multiply_s_and_x2_message
    sta TEXT_TO_PRINT + 1
    
    jsr load_and_print_4_bytes_of_vram
    jsr move_cursor_to_next_line

    rts
    


x1_times_c_plus_y1_times_s_message: 
    .asciiz "X1 * C + Y1 * S = "
    
x1_times_c_plus_y1_times_s:

    ; == Set multiplier mode: on ==
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
    ora #%10000000           ; reset accumulator = 1
    sta $9F2C
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_X1>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X1
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X1
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache
    
    lda #(VRAM_ADDR_SAMPLE_CONST_C>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
; We are testing whether we can accumulate by doing a read from cache32[15:8] instead
;    ora #%01000000           ; accumulate = 1
    sta $9F2C
    
    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    lda $9F2A                ; reading from cache32[15:8] will accumulate

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_Y1>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_Y1
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_Y1
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache

    lda #(VRAM_ADDR_SAMPLE_CONST_S>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_S
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_S
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #(VRAM_ADDR_MULT_ACC_OUTPUT>>16)
    sta VERA_ADDR_MULT_RESULT_ACC+2
    lda #>(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC+1
    lda #<(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC

    jsr write_mult_acc_result_into_vram

    lda #<x1_times_c_plus_y1_times_s_message
    sta TEXT_TO_PRINT
    lda #>x1_times_c_plus_y1_times_s_message
    sta TEXT_TO_PRINT + 1
    
    jsr load_and_print_4_bytes_of_vram
    jsr move_cursor_to_next_line

    rts
    

x2_times_s_minus_y2_times_c_message: 
    .asciiz "X2 * S - Y2 * C = "
    
x2_times_s_minus_y2_times_c:

    ; == Set multiplier mode: on ==
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
; We are testing whether we can reset the accumulator by doing a read from cache32[7:0] instead
;    ora #%10000000           ; reset accumulator = 1
    sta $9F2C

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    lda $9F29                ; reading from cache32[7:0] will reset the accumulator

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_X2>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_X2
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_X2
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache
    
    lda #(VRAM_ADDR_SAMPLE_CONST_S>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_S
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_S
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
    ora #%01000000           ; accumulate = 1
    sta $9F2C
    
; FIXME: a switch to subtracting will immidiatly have an effect, which means the cant do an accumulate and *then* do the switch to subtracting in one write! So we first do an accumulate, then switch to subtracting
    lda #%00010000           ; multiplier enabled = 1, cache index  = 0
    sta MULTIPLIER_STATE
    ora #%00100000           ; add or sub = 1
    sta $9F2C
    
    lda #(VRAM_ADDR_SAMPLE_VALUE_Y2>>16)
    sta VERA_ADDR_LOW_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_VALUE_Y2
    sta VERA_ADDR_LOW_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_VALUE_Y2
    sta VERA_ADDR_LOW_OPERAND
    
    jsr load_low_operand_into_cache

    lda #(VRAM_ADDR_SAMPLE_CONST_C>>16)
    sta VERA_ADDR_HIGH_OPERAND+2
    lda #>VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND+1
    lda #<VRAM_ADDR_SAMPLE_CONST_C
    sta VERA_ADDR_HIGH_OPERAND
    
    jsr load_high_operand_into_cache
    
    lda #(VRAM_ADDR_MULT_ACC_OUTPUT>>16)
    sta VERA_ADDR_MULT_RESULT_ACC+2
    lda #>(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC+1
    lda #<(VRAM_ADDR_MULT_ACC_OUTPUT)
    sta VERA_ADDR_MULT_RESULT_ACC

    jsr write_mult_acc_result_into_vram

    lda #<x2_times_s_minus_y2_times_c_message
    sta TEXT_TO_PRINT
    lda #>x2_times_s_minus_y2_times_c_message
    sta TEXT_TO_PRINT + 1
    
    jsr load_and_print_4_bytes_of_vram
    jsr move_cursor_to_next_line

    rts

    
    
load_low_operand_into_cache:

    ; == Load value into low side of cache32 ==
    
; FIXME: this is probably not needed here! We could have changed ADDRSEL beforehand!
    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    ora VERA_ADDR_LOW_OPERAND+2
    sta VERA_ADDR_BANK
    lda VERA_ADDR_LOW_OPERAND+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_LOW_OPERAND
    sta VERA_ADDR_LOW

    lda #%00100000           ; cache write enabled = 0, cache fill enabled = 1
    sta $9F29
    
    ; We set cache byte index to 0 here
    lda #%00000000           ; 0000, cache byte index = 00, cache nibble index = 0, cache increment mode = 0
    ora MULTIPLIER_STATE
    sta $9F2C
    
    ; Loading the 16-bit value into the cache32
    lda VERA_DATA1
    lda VERA_DATA1

    rts
    
load_high_operand_into_cache:

    ; == Load value into high side of cache32 ==
    
; FIXME: this is probably not needed here! We could have changed ADDRSEL beforehand!
    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    ora VERA_ADDR_HIGH_OPERAND+2
    sta VERA_ADDR_BANK
    lda VERA_ADDR_HIGH_OPERAND+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_HIGH_OPERAND
    sta VERA_ADDR_LOW

    lda #%00100000           ; cache write enabled = 0, cache fill enabled = 1
    sta $9F29
    
    ; We set cache byte index to 2 here
    lda #%00001000           ; 0000, cache byte index = 10, cache nibble index = 0, cache increment mode = 0
    ora MULTIPLIER_STATE
    sta $9F2C
    
    ; Loading the 16-bit value into the cache32
    lda VERA_DATA1
    lda VERA_DATA1

    rts

    
write_mult_acc_result_into_vram:

    ; == Write result into VRAM ==
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    
    ; SLOW: dont do this each time we write the cache to VRAM!
    lda #%01000000           ; blit write enabled = 1
    sta $9F29
    
    ; Writing cache to vram 
    
    lda #%00110110           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 4, with wrpattern = 11 (blit)
    ora VERA_ADDR_MULT_RESULT_ACC+2
    sta VERA_ADDR_BANK
    lda VERA_ADDR_MULT_RESULT_ACC+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_MULT_RESULT_ACC
    sta VERA_ADDR_LOW
    
    stz VERA_DATA0
    
    ; SLOW: dont do this each time we write the cache to VRAM!
    lda #%00000000           ; blit write enabled = 0
    sta $9F29
    
    rts
    

    
    
; Note: this routines assumes you have setup VALUE, CURSOR_X/Y and TEXT_TO_PRINT!
print_value:

    jsr setup_cursor
    
    lda #VARIABLE_COLOR
    sta TEXT_COLOR
    
    jsr print_text_zero
    
    lda #VALUE_COLOR
    sta TEXT_COLOR
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda VALUE+1
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    lda VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    rts
    
; Note: this routines assumes you have setup VERA_ADDR_MULT_RESULT_ACC, CURSOR_X/Y and TEXT_TO_PRINT!
load_and_print_4_bytes_of_vram:

    ; == Read result from VRAM ==
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    ora VERA_ADDR_MULT_RESULT_ACC+2
    sta VERA_ADDR_BANK
    lda VERA_ADDR_MULT_RESULT_ACC+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_MULT_RESULT_ACC
    sta VERA_ADDR_LOW
    
    lda VERA_DATA0
    sta MULT_RESULT_ACC
    lda VERA_DATA0
    sta MULT_RESULT_ACC+1
    lda VERA_DATA0
    sta MULT_RESULT_ACC+2
    lda VERA_DATA0
    sta MULT_RESULT_ACC+3
    
    jsr setup_cursor
    
    lda #VARIABLE_COLOR
    sta TEXT_COLOR
    
    jsr print_text_zero
    
    lda #VALUE_COLOR
    sta TEXT_COLOR
    
    lda #'$'
    sta VERA_DATA0
    lda TEXT_COLOR
    sta VERA_DATA0
    inc CURSOR_X
    
    lda MULT_RESULT_ACC+3
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    lda MULT_RESULT_ACC+2
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    lda MULT_RESULT_ACC+1
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    lda MULT_RESULT_ACC
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    rts

    
store_vram_value:

    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; Set VRAM address for storing the 16-bit value
    lda #%00010000           
    ora VRAM_ADDR_VALUE+2
    sta VERA_ADDR_BANK
    lda VRAM_ADDR_VALUE+1
    sta VERA_ADDR_HIGH
    lda VRAM_ADDR_VALUE
    sta VERA_ADDR_LOW

    ; Store the 16-bit value
    lda VALUE
    sta VERA_DATA0
    lda VALUE+1
    sta VERA_DATA0
    
    rts

load_vram_value:

    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; Set VRAM address for loading the 16-bit value
    lda #%00010000           
    ora VRAM_ADDR_VALUE+2
    sta VERA_ADDR_BANK
    lda VRAM_ADDR_VALUE+1
    sta VERA_ADDR_HIGH
    lda VRAM_ADDR_VALUE
    sta VERA_ADDR_LOW

    ; Store the 16-bit value
    lda VERA_DATA0
    sta VALUE
    lda VERA_DATA0
    sta VALUE+1
    
    rts

    
; -- This part is/was for testing DSPs in dual 8x8 multiplier mode. --
;          It can be removed if/when this testing is done.
    
HACK_test_8x8_multiplier_message: 
    .asciiz "Testing 8x8 multiplier"

HACK_test_8x8_multiplier:

    lda #TITLE_COLOR
    sta TEXT_COLOR
    
    lda #7
    sta CURSOR_X
    lda #1
    sta CURSOR_Y

    lda #<HACK_test_8x8_multiplier_message
    sta TEXT_TO_PRINT
    lda #>HACK_test_8x8_multiplier_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    lda #10
    sta CURSOR_X
    lda #3
    sta CURSOR_Y
    jsr setup_cursor
    
; == 1a ==
    lda #$FF
    sta VERA_L0_HSCROLL_L
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    inc CURSOR_X
    jsr setup_cursor
    
; == 1b ==
    lda #$FF
    sta VERA_L0_VSCROLL_L
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    inc CURSOR_X
    jsr setup_cursor
    
    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL
    
; -- output1[7:0] --
    lda $9F29
    sta VALUE
    
; -- output1[15:8] --
    lda $9F2A
    sta VALUE+1
    
    lda VALUE+1
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    lda VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    


    lda #10
    sta CURSOR_X
    lda #5
    sta CURSOR_Y
    jsr setup_cursor

; == 2a ==
    lda #$20
    sta VERA_L0_MAPBASE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    inc CURSOR_X
    jsr setup_cursor
    
; == 2b ==
    lda #$57
    sta TMP2
    and #$0F
    sta VERA_L0_VSCROLL_H
    
    lda VERA_L0_CONFIG
    and #$0F
    sta TMP3
    
    lda TMP2
    and #$F0
    ora TMP3
    sta VERA_L0_CONFIG
    lda TMP2
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    
    inc CURSOR_X
    jsr setup_cursor
    
    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL
    
; -- output2[7:0] --
    lda $9F2B
    sta VALUE
    
; -- output2[15:8] --
    lda $9F2C
    sta VALUE+1
    
    lda VALUE+1
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex
    lda VALUE
    sta BYTE_TO_PRINT
    jsr print_byte_as_hex

    rts

; / -- DSP dual 8x8 mult test code --
    
    
change_palette_colors:

    ; -- Change some colors in the palette
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$08                 ; We use color 4 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$05                 ; gb
    sta VERA_DATA0
    lda #$05                 ; -r
    sta VERA_DATA0
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$04                 ; We use color 2 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$00                 ; gb
    sta VERA_DATA0
    lda #$0F                 ; -r
    sta VERA_DATA0
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$10                 ; We use color 8 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$80                 ; gb
    sta VERA_DATA0
    lda #$0F                 ; -r
    sta VERA_DATA0

    rts

    
  
clear_screen_slow:
  
vera_wr_start:
    ldx #0
vera_wr_fill_bitmap_once:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #240
vera_wr_fill_bitmap_col_once:
; FIXME: now drawing a pattern!
;    tya
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once
    inx
    bne vera_wr_fill_bitmap_once

    ; Right part of the screen

    ldx #0
vera_wr_fill_bitmap_once2:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$01                ; The right side part of the screen has a start byte starting at address 256 and up
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #240
vera_wr_fill_bitmap_col_once2:
; FIXME: now drawing a pattern!
;    tya
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once2
    inx
    cpx #64                  ; The right part of the screen is 320 - 256 = 64 pixels
    bne vera_wr_fill_bitmap_once2
    
    rts

    
    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/timing.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s

    ; ======== NMI / IRQ =======
nmi:
    ; TODO: implement this
    ; FIXME: ugly hack!
    jmp reset
    rti
   
irq:
    rti
    
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"
    
    

    .org $fffa
    .word nmi
    .word reset
    .word irq
    