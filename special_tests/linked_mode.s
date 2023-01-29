
DO_SPEED_TEST = 0
USE_LINKED_MODE = 1

BACKGROUND_COLOR = 57  ; Nice red color
;FOREGROUND_COLOR = 1
DATA0_UNLINKED_COLOR = 1
DATA0_LINKED_COLOR = 5
DATA1_LINKED_COLOR = 4

TEST_LINE_COLOR = 1
TEST_LINE_SLOPE = 70  ; the number of sub pixels (SLOPE/256 of a pixel) that the line moves down each horizontal step
TEST_LINE_MIDDLE = 128  ; The position (in sub pixels) we start at: MIDDLE/256 of a pixel
TEST_LINE_WIDTH = 50

; FIXME
;TOP_MARGIN = 12
TOP_MARGIN = 13
LEFT_MARGIN = 16
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
BANK_TESTING              = $12   
BAD_VALUE                 = $1A

CODE_ADDRESS              = $1D ; 1E ; TODO: this can probably share the address of LOAD_ADDRESS

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


; RAM addresses
LINE_DRAW_CODE        = $7E00


  .org $C000

reset:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs
    
    jsr setup_vera_for_bitmap_and_tile_map
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor
    jsr init_timer

    jsr clear_screen_slow
    
    .if(DO_SPEED_TEST)
    .if(USE_LINKED_MODE)
; FIXME: implement this!
      jsr test_speed_of_drawing_lines_using_linked_mode
    .else
; FIXME: implement this!
; FIXME: maybe do three version: 
;   - one with re-setup of increment: 320, then 1 again
;   - one with keeping track of the vram address ourselved and incrementing ourselved
;   - one with reading addr0 and writing into addr1 each time, so we can easely increment 320
      jsr test_speed_of_drawing_lines_not_using_linked_mode
    .endif
    .else
;      jsr clear_screen_slow ; TODO: this is already done!
      lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
      sta VERA_DC_HSCALE
      sta VERA_DC_VSCALE
      ; jsr draw_test_pixels
      jsr draw_test_line
    .endif
    
  
loop:
  jmp loop


draw_test_pixels:

    ; Experiment: setup ADDR1, then setup ADDR0 (differently) and enable Linked Mode -> ADDR0 should now be equal to ADDR1
  
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW
    lda #%00000000           ; Linked Mode=0, DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00110000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 4 byte increment (=%0011)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_LOW

    ; We use A as color
    lda #DATA0_UNLINKED_COLOR
    sta VERA_DATA0           ; store pixel (DATA0)   --> we see this pixel higher in the screen, since ADDR0 is still different from ADDR1

    ; Entering *Linked mode* here!
    lda #%01000000           ; Linked Mode=1, DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; We use A as color
    lda #DATA0_LINKED_COLOR
    sta VERA_DATA0           ; store pixel (DATA0)  --> we see this pixel lower in the screen, since ADDR0 is the same as ADDR1 -> this should INCREMENT *both* addresses by 4!
    lda #DATA1_LINKED_COLOR
    sta VERA_DATA1           ; store pixel (DATA1)  --> we see this pixel to the *4 pixels to the right* of the previous pixel, since the ADDR0 was incremented by 4, and they are *linked*
    
    rts


draw_test_line:

; FIXME: we should start at half Y *and* half X?
; FIXME: we should start at half Y *and* half X?
; FIXME: we should start at half Y *and* half X?
    
    ; Experiment: draw a line from the top left to the bottom right of the (small) screen
  
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_LOW
    
    ; Entering *Linked mode*: this will copy ADDR1 to ADDR0
    lda #%01000000           ; Linked Mode=1, DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK

    ldy #TEST_LINE_COLOR     ; We use y as color
    sty VERA_DATA0           ; we always draw the first pixel
    clc
    
    ldx #TEST_LINE_WIDTH     ; Number of pixels to draw
    lda #TEST_LINE_MIDDLE    ; a contains the sub pixel y position, we start at half the pixel (vertically)
next_test_pixel_to_draw:
    adc #TEST_LINE_SLOPE     ; we add the sub pixel we moved down each pixel (SLOPE)
    bcc draw_next_test_pixel
    bit VERA_DATA1           ; we have carried over to the next row, so move down (+320 bytes)
    clc                      ; this may be ommited, if you allow a little bit of inaccuracy
draw_next_test_pixel:
    sty VERA_DATA0           ; draw pixel and move right (+1 byte)
    dex
    bne next_test_pixel_to_draw
    
    rts

    
  
  
test_speed_of_drawing_lines_not_using_linked_mode:

; FIXME: do we want to unroll the loop when doing a comparison?
;    jsr generate_clear_column_code

    jsr start_timer
    jsr draw_lines_without_linked_mode
    jsr stop_timer

; FIXME: we probably want non-transparent text here!! (due to all the lines)
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #8
    sta CURSOR_Y

    lda #<draw_lines_320x240_8bpp_message
    sta TEXT_TO_PRINT
    lda #>draw_lines_320x240_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #7
    sta CURSOR_X
    lda #12
    sta CURSOR_Y

    lda #<draw_lines_without_linked_mode_message
    sta TEXT_TO_PRINT
    lda #>draw_lines_without_linked_mode_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts


test_speed_of_drawing_lines_using_linked_mode:

; FIXME: do we want to unroll the loop when doing a comparison?
;    jsr generate_clear_column_code

    jsr start_timer
    jsr draw_lines_with_linked_mode
    jsr stop_timer

; FIXME: we probably want non-transparent text here!! (due to all the lines)
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #8
    sta CURSOR_Y

    lda #<draw_lines_320x240_8bpp_message
    sta TEXT_TO_PRINT
    lda #>draw_lines_320x240_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #7
    sta CURSOR_X
    lda #12
    sta CURSOR_Y

    lda #<draw_lines_with_linked_mode_message
    sta TEXT_TO_PRINT
    lda #>draw_lines_with_linked_mode_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts


    
draw_lines_320x240_8bpp_message: 
    .asciiz "Drew 256 lines 320x240 (8bpp) "
draw_lines_without_linked_mode_message: 
; FIXME: maybe specify what method exactly is used!
; FIXME: maybe specify what method exactly is used!
; FIXME: maybe specify what method exactly is used!
    .asciiz "Method: not using linked mode"
draw_lines_with_linked_mode_message: 
    .asciiz "Method: using linked mode"

    
    
draw_lines_without_linked_mode:

; FIXME: implement this!
    
    rts



draw_lines_with_linked_mode:

; FIXME: implement this!

    rts


    
generate_clear_column_code:

    lda #<LINE_DRAW_CODE
    sta CODE_ADDRESS
    lda #>LINE_DRAW_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of clear instructions

next_line_draw_instruction:

; FIXME: do we want to implement unrolled line drawing?

    ; -- sta VERA_DATA0 ($9F23)
;    lda #$8D               ; sta ....
;    jsr add_code_byte

;    lda #$23               ; $23
;    jsr add_code_byte
    
;    lda #$9F               ; $9F
;    jsr add_code_byte
    
;    inx
;    cpx #240               ; 240 clear pixels written to VERA
;    bne next_line_draw_instruction

    ; -- rts --
;    lda #$60
;    jsr add_code_byte

    rts

add_code_byte:
    sta (CODE_ADDRESS),y   ; store code byte at address (located at CODE_ADDRESS) + y
    iny                    ; increase y
    cpy #0                 ; if y == 0
    bne done_adding_code_byte
    inc CODE_ADDRESS+1     ; increment high-byte of CODE_ADDRESS
done_adding_code_byte:
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
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
