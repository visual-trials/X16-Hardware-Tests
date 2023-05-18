
DO_SPEED_TEST = 0
USE_AFFINE_HELPER = 1

    .if (USE_AFFINE_HELPER)
BACKGROUND_COLOR = 251  ; Nice purple
    .else
BACKGROUND_COLOR = 06  ; Blue 
    .endif

;FOREGROUND_COLOR = 1

TEST_LINE_COLOR = 1
TEST_LINE_SLOPE = 70  ; the number of sub pixels (SLOPE/256 of a pixel) that the line moves down each horizontal step
TEST_LINE_MIDDLE = 128  ; The position (in sub pixels) we start at: MIDDLE/256 of a pixel
TEST_LINE_WIDTH = 50

; FIXME
;TOP_MARGIN = 12
TOP_MARGIN = 13
LEFT_MARGIN = 16
VSPACING = 10

SLOPE_INCREMENT_HOR = 16
SLOPE_INCREMENT_VER = 16
NR_OF_LINES_TO_DRAW_HOR = 16
NR_OF_LINES_TO_DRAW_VER = 16

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

; Timing
TIMING_COUNTER            = $14 ; 15
TIME_ELAPSED_MS           = $16
TIME_ELAPSED_SUB_MS       = $17 ; one nibble of sub-milliseconds

; For geneating code
CODE_ADDRESS              = $1D ; 1E

; Line drawing
START_ADDRESS              = $20 ; 21
NR_OF_LINES_TO_DRAW        = $22
SLOPE                      = $23 ; 24? TODO: do we want a more precise SLOPE?
LINE_LENGTH                = $25 ; 26 ; This is the length of the line in the axis we are essentially drawing
LINE_COLOR                 = $27


; RAM addresses
CLEAR_COLUMN_CODE     = $7000
AFFINE_DRAW_256_CODE  = $7C00
AFFINE_DRAW_240_CODE  = $8000
AFFINE_DRAW_64_CODE   = $8400


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

    jsr generate_clear_column_code
    jsr clear_screen_fast_4_bytes
    
    .if(DO_SPEED_TEST)
      jsr test_speed_of_drawing_lines
    .else
    
      lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
      sta VERA_DC_HSCALE
      sta VERA_DC_VSCALE
;FIXME: is this name correct?
      jsr test_sub_pixel_increments
    .endif
    
  
loop:
  jmp loop


test_sub_pixel_increments:

    ; Setting up for drawing a new line

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    
    ; Entering *line draw mode*: from now on ADDR1 will use two incrementers: the one from ADDR0 and from itself
    lda #%00000001
    sta $9F29
    
    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #0
    sta VERA_ADDR_HIGH       ; Setting $00000
    lda #0
    sta VERA_ADDR_LOW        ; Setting $00000
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
    lda #<(73<<1)            ; X increment low
    sta $9F29
    lda #>(73<<1)            ; X increment high
    sta $9F2A
    
    ; Note: we do not need to set the Y low/high increments.
    

    ldx #150 ; Drawing 150 pixels to the right
    lda #1   ; White color

    .if(0)
draw_line_next_pixel:
    sta VERA_DATA1
    dex
    bne draw_line_next_pixel
    .endif

    .if(1)
draw_dotted_line_next_pixel:
    sta VERA_DATA1
    dex
    ; We are not interested in the value we get back so we just put it in y
    ldy VERA_DATA1
    dex
    ldy VERA_DATA1
    dex
    bne draw_dotted_line_next_pixel
    .endif
    
    
    .if(0)
        ; Starting to draw: 4 cpu cycles per pixel
        
        ldy #TEST_LINE_COLOR     ; We use y as color
        
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1

        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1

        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
        sty VERA_DATA1
    .endif
    
    rts
  

test_speed_of_drawing_lines:
        
    ; TODO: do we want to unroll the loop when doing a comparison? Probably.
    .if(USE_AFFINE_HELPER)
        jsr generate_affine_draw_line_code
    .endif

    jsr start_timer
    jsr draw_lines
    jsr stop_timer

    ; TODO: do we want non-transparent text here? (due to all the lines)
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #7
    sta CURSOR_X
    lda #8
    sta CURSOR_Y

    lda #<draw_lines_320x240_8bpp_message
    sta TEXT_TO_PRINT
    lda #>draw_lines_320x240_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #12
    sta CURSOR_Y

    .if(USE_AFFINE_HELPER)
    
        lda #6
        sta CURSOR_X
        lda #<draw_lines_with_affine_helper_message
        sta TEXT_TO_PRINT
        lda #>draw_lines_with_affine_helper_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #6
        sta CURSOR_X
        lda #<draw_lines_without_affine_helper_message
        sta TEXT_TO_PRINT
        lda #>draw_lines_without_affine_helper_message
        sta TEXT_TO_PRINT + 1
    .endif
    
    jsr print_text_zero
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts

draw_lines_320x240_8bpp_message: 
    .asciiz "Drew 32 lines 320x240 (8bpp) "
draw_lines_without_affine_helper_message: 
    ; TODO: maybe specify what method exactly is used!
    .asciiz "Method: not using affine helper"
draw_lines_with_affine_helper_message: 
    .asciiz "Method: using affine helper"
    
    

draw_lines:

    lda #<(320*0+0)
    sta START_ADDRESS
    lda #>(320*0+0)
    sta START_ADDRESS+1

    ; ====================== Drawing mainly left to right and then down ===================

    lda #0
    sta SLOPE
    
    lda #0
    sta LINE_COLOR
    
    lda #NR_OF_LINES_TO_DRAW_HOR
    sta NR_OF_LINES_TO_DRAW
    
draw_line_to_the_right_from_left_top_corner_next:
    
    clc
    lda SLOPE
    adc #SLOPE_INCREMENT_HOR
    sta SLOPE
    
    .if(USE_AFFINE_HELPER)
        ; Setting up for drawing a new line

        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
        sta VERA_ADDR_BANK
        
        ; Entering *line draw mode*: from now on ADDR1 will use two incrementers: the one from ADDR0 and from itself
        lda #%00000001
        sta $9F29
        
        lda #%00000101           ; DCSEL=2, ADDRSEL=1
        sta VERA_CTRL
        
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
        lda #0
        sta VERA_ADDR_HIGH       ; Resetting back to $00000
        lda #0
        sta VERA_ADDR_LOW        ; Resetting back to $00000
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
        lda SLOPE                ; X increment low -> HERE used as Y increment!
        asl
        sta $9F29
        lda #0                   ; X increment high
        rol
        sta $9F2A

; FIXME: there is no easy way to reset the subpixel position! (without setting a pixel position that is not relevant for line drawing!
        
    .else
        lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
        lda START_ADDRESS+1
        sta VERA_ADDR_HIGH
        lda START_ADDRESS
        sta VERA_ADDR_LOW
    .endif

    inc LINE_COLOR
    ldy LINE_COLOR

    .if(USE_AFFINE_HELPER)
        ; FIXME: we can make a single routines for 320 pixels instead
        jsr AFFINE_DRAW_256_CODE
        jsr AFFINE_DRAW_64_CODE
    .else
        lda #<(320)
        sta LINE_LENGTH
        ; lda #>(320)
        ; sta LINE_LENGTH+1

        ldy LINE_COLOR           ; We use y as color
        sty VERA_DATA0           ; we always draw the first pixel
        clc

        jsr draw_256_right_line_pixels_first
    .endif
    
    dec NR_OF_LINES_TO_DRAW
    bne draw_line_to_the_right_from_left_top_corner_next
    
    ; ====================== / Drawing mainly left to right and then down ===================

    ; ====================== Drawing mainly top to bottom and then right ===================

    lda #0
    sta SLOPE
    
    lda #1
    sta LINE_COLOR
    
    lda #NR_OF_LINES_TO_DRAW_VER
    sta NR_OF_LINES_TO_DRAW
    
draw_line_to_the_bottom_from_left_top_corner_next:
    
    clc
    lda SLOPE
    adc #SLOPE_INCREMENT_VER
    sta SLOPE
    
    .if(USE_AFFINE_HELPER)
    
        ; Setting up for drawing a new line

        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
        
        ; Entering *line draw mode*: from now on ADDR1 will use two incrementers: the one from ADDR0 and from itself
        lda #%00000001
        sta $9F29
        
        lda #%00000101           ; DCSEL=2, ADDRSEL=1
        sta VERA_CTRL
        
        lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
        sta VERA_ADDR_BANK
        lda #0
        sta VERA_ADDR_HIGH       ; Resetting back to $00000
        lda #0
        sta VERA_ADDR_LOW        ; Resetting back to $00000
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
        lda SLOPE                ; X increment low -> HERE used as Y increment!
        asl
        sta $9F29
        lda #0                   ; X increment high
        rol
        sta $9F2A

; FIXME: there is no easy way to reset the subpixel position! (without setting a pixel position that is not relevant for line drawing!
        
    .else
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 byte increment (=%1110)
        sta VERA_ADDR_BANK
        lda START_ADDRESS+1
        sta VERA_ADDR_HIGH
        lda START_ADDRESS
        sta VERA_ADDR_LOW
    .endif

    inc LINE_COLOR
    ldy LINE_COLOR

    .if(USE_AFFINE_HELPER)
        jsr AFFINE_DRAW_240_CODE
    .else
        lda #<(240)
        sta LINE_LENGTH
        ; lda #>(240)
        ; sta LINE_LENGTH+1
        
        ldy LINE_COLOR           ; We use y as color
        sty VERA_DATA0           ; we always draw the first pixel
        clc

        jsr draw_less_than_256_right_line_pixels
    .endif
    
    dec NR_OF_LINES_TO_DRAW
    bne draw_line_to_the_bottom_from_left_top_corner_next
    
    ; ====================== / Drawing mainly top to bottom and then right ===================
    
    .if(USE_AFFINE_HELPER)
        ; Turn off affine helper mode
        lda #%00000000           ; DCSEL=0, ADDRSEL=0
        sta VERA_CTRL
    .endif
    
    rts

    
    
    
    ; TODO: maybe do three alternative versions: 
    ;   - one with re-setup of increment: 320, then 1 again
    ;   - one with keeping track of the vram address ourselved and incrementing ourselved
    ;   - one with reading addr0 and writing into addr1 each time, so we can easely increment 320
    
draw_256_right_line_pixels_first:
    lda #TEST_LINE_MIDDLE    ; a contains the sub pixel y position, we start at half the pixel (vertically)
    ldx #255                   ; We first draw 255 pixels (one less than 256, since the next loop will always draw 1!)
next_line_pixel_to_draw_256_right:
    adc SLOPE                ; we add the sub pixel we moved down each pixel (SLOPE)
    bcc draw_next_line_pixel_256_right
    
    pha
    lda VERA_ADDR_BANK       ; We cannot simply set the VERA_ADDR_BANK because we dont know the value of bit16!
    eor #%11110000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    lda VERA_DATA0           ; we have carried over to the next row, so move down (+320 bytes)
    lda VERA_ADDR_BANK       ; We cannot simply set the VERA_ADDR_BANK because we dont know the value of bit16!
    eor #%11110000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    pla
    
    clc                      ; this may be ommited, if you allow a little bit of inaccuracy
draw_next_line_pixel_256_right:
    sty VERA_DATA0           ; draw pixel and move right (+1 byte)
    dex
    bne next_line_pixel_to_draw_256_right
    bra draw_remaining_line_pixels_right  ; we have drawn 255 pixels, we move on to the remaining pixels
    
    ; TODO: we assume LINE_LENGTH != 0. Is this assured right now?
    
draw_less_than_256_right_line_pixels:
    lda #TEST_LINE_MIDDLE    ; a contains the sub pixel y position, we start at half the pixel (vertically)
draw_remaining_line_pixels_right:
    ldx LINE_LENGTH          ; Number of pixels to draw
next_line_pixel_to_draw_right:
    adc SLOPE                ; we add the sub pixel we moved down each pixel (SLOPE)
    bcc draw_next_line_pixel_right
    
    pha
    lda VERA_ADDR_BANK       ; We cannot simply set the VERA_ADDR_BANK because we dont know the value of bit16!
    eor #%11110000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    lda VERA_DATA0           ; we have carried over to the next row, so move down (+320 bytes)
    lda VERA_ADDR_BANK       ; We cannot simply set the VERA_ADDR_BANK because we dont know the value of bit16!
    eor #%11110000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    pla
    
    clc                      ; this may be ommited, if you allow a little bit of inaccuracy
draw_next_line_pixel_right:
    sty VERA_DATA0           ; draw pixel and move right (+1 byte)
    dex
    bne next_line_pixel_to_draw_right

    rts
    
    
    
clear_screen_fast_4_bytes:

    ; We first need to fill the 32-bit cache with 4 times our background color

    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00000000           ; normal addr1 mode 
    sta $9F29
    
    lda #%00000001           ; ... cache fill enabled = 1
    sta $9F2C   
    
    lda #%00000000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 bytes (=0=%00000)
    sta VERA_ADDR_BANK
    stz VERA_ADDR_HIGH
    stz VERA_ADDR_LOW

    lda #BACKGROUND_COLOR
    sta VERA_DATA1
    
    lda VERA_DATA1    
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
     
    lda #%00000010           ; map base addr = 0, blit write enabled = 1, repeat/clip = 0
    sta $9F2B     

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    
    ; Left part of the screen (256 columns)

    
    ldx #0
    
clear_next_column_left_4_bytes:
    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; Color for clearing screen
    lda #BACKGROUND_COLOR
    jsr CLEAR_COLUMN_CODE
    
    inx
    inx
    inx
    inx
    bne clear_next_column_left_4_bytes
    
    ; Right part of the screen (64 columns)

    ldx #0

clear_next_column_right_4_bytes:
    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$01
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; Color for clearing screen
    lda #BACKGROUND_COLOR
    jsr CLEAR_COLUMN_CODE
    
    inx
    inx
    inx
    inx
    cpx #64
    bne clear_next_column_right_4_bytes

    lda #%00000000           ; map base addr = 0, blit write enabled = 0, repeat/clip = 0
    sta $9F2B       
    
    rts


    
generate_affine_draw_line_code:
    lda #<AFFINE_DRAW_256_CODE
    sta CODE_ADDRESS
    lda #>AFFINE_DRAW_256_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    ldx #0                 ; counts nr of clear instructions
next_affine_line_draw_instruction_256:

    ; -- sty VERA_DATA1 ($9F24)
    lda #$8C               ; sty ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx #0                 ; 256 draw pixels written to VERA
    bne next_affine_line_draw_instruction_256

    ; -- rts --
    lda #$60
    jsr add_code_byte
    


    lda #<AFFINE_DRAW_240_CODE
    sta CODE_ADDRESS
    lda #>AFFINE_DRAW_240_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    ldx #0                 ; counts nr of clear instructions
next_affine_line_draw_instruction_240:

    ; -- sty VERA_DATA1 ($9F24)
    lda #$8C               ; sty ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx #240                 ; 256 draw pixels written to VERA
    bne next_affine_line_draw_instruction_240

    ; -- rts --
    lda #$60
    jsr add_code_byte
    



    lda #<AFFINE_DRAW_64_CODE
    sta CODE_ADDRESS
    lda #>AFFINE_DRAW_64_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    ldx #0                 ; counts nr of clear instructions
next_affine_line_draw_instruction_64:

    ; -- sty VERA_DATA1 ($9F24)
    lda #$8C               ; sty ....
    jsr add_code_byte

    lda #$24               ; $24
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
    cpx #64                 ; 64 draw pixels written to VERA
    bne next_affine_line_draw_instruction_64

    ; -- rts --
    lda #$60
    jsr add_code_byte
    

    rts

generate_clear_column_code:

    lda #<CLEAR_COLUMN_CODE
    sta CODE_ADDRESS
    lda #>CLEAR_COLUMN_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of clear instructions

next_clear_instruction:

    ; -- sta VERA_DATA0 ($9F23)
    lda #$9C               ; stz ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    inx
; FIXME: this will overflow into KEYBOARD_SCANCODE_BUFFER!!
    cpx #240               ; 240 clear pixels written to VERA
    bne next_clear_instruction

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
