
DO_SPEED_TEST = 0
USE_AFFINE_HELPER = 1

    .if (USE_AFFINE_HELPER)
BACKGROUND_COLOR = 251  ; Nice purple
    .else
BACKGROUND_COLOR = 06  ; Blue 
    .endif

TEST_FILL_COLOR = 1
TRIANGLE_TOP_POINT_X = 90
TRIANGLE_TOP_POINT_Y = 30
    
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

; FIXME: remove this line drawing stuff!!
; FIXME: remove this line drawing stuff!!
; FIXME: remove this line drawing stuff!!

START_ADDRESS              = $20 ; 21
NR_OF_LINES_TO_DRAW        = $22
SLOPE                      = $23 ; 24? TODO: do we want a more precise SLOPE?
LINE_LENGTH                = $25 ; 26 ; This is the length of the line in the axis we are essentially drawing
LINE_COLOR                 = $27


; Polygon filler
NUMBER_OF_ROWS             = $30
FILL_LENGTH_LOW            = $31
FILL_LENGTH_HIGH           = $32
X1_THREE_LOWER_BITS        = $33
; REMOVE:  X2_TWO_LOWER_BITS          = $34


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
; FIXME: IMPLEMENT THIS!      jsr test_speed_of_filling_triangle
    .else
    
;      lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
;      sta VERA_DC_HSCALE
;      sta VERA_DC_VSCALE
      jsr test_simple_polygon_filler
    .endif
    
  
loop:
  jmp loop


test_simple_polygon_filler:

    ; Setting up for drawing a polygon, setting both addresses at the same starting point

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    ; Note: we are setting ADDR0 to the left most pixel of a pixel row. This means it will be aligned to 4-bytes (which is needed for the polygon filler to work nicely).
    lda #>(TRIANGLE_TOP_POINT_Y*320)
    sta VERA_ADDR_HIGH
    lda #<(TRIANGLE_TOP_POINT_Y*320)
    sta VERA_ADDR_LOW
    
    ; Entering *polygon fill mode*: from now on every read from DATA1 will increment x1 and x2, and ADDR1 will be filled with ADDR0 + x1
    lda #%00000011
    sta $9F29

    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
    ; FIXME: NOTE that these increments are *HALF* steps!!
    lda #<(-173)           ; X increment low (signed)
    sta $9F29
    lda #>(-173)           ; X increment high (signed)
    and #%01111111            ; increment is only 15-bits long
    sta $9F2A
    lda #<(130)            ; Y increment low (signed)
    sta $9F2B                
    lda #>(130)            ; Y increment high (signed)
    and #%01111111            ; increment is only 15-bits long
    sta $9F2C    
    
    
    ; Setting x1 and x2 pixel position
    
    lda #%00001001           ; DCSEL=4, ADDRSEL=1
    sta VERA_CTRL
    
    lda #<TRIANGLE_TOP_POINT_X
    sta $9F29                ; X (=X1) pixel position low [7:0]
    sta $9F2B                ; Y (=X2) pixel position low [7:0]
    
    ; NOTE: we are also *setting* the subpixel position (bit0) here! Even though we just resetted it! 
    ;       but its ok, since its reset to half a pixel (see above), meaning bit0 is 0 anyway
    lda #>TRIANGLE_TOP_POINT_X
    sta $9F2A                ; X subpixel position[0] = 0, X (=X1) pixel position high [10:8]
    ora #%00100000           ; Reset subpixel position
    sta $9F2C                ; Y subpixel position[0] = 0, Y (=X2) pixel position high [10:8]


; FIXME: this should be switched between 1 and 4 within the draw_polygon_part routine!!
; FIXME: this should be switched between 1 and 4 within the draw_polygon_part routine!!
; FIXME: this should be switched between 1 and 4 within the draw_polygon_part routine!!

; PROBLEM: its possible that bit16 of ADDR1 is 1, so when settings this *during* a horizontal line draw, you could set bit16 wrongly!
; PROBLEM: its possible that bit16 of ADDR1 is 1, so when settings this *during* a horizontal line draw, you could set bit16 wrongly!
; PROBLEM: its possible that bit16 of ADDR1 is 1, so when settings this *during* a horizontal line draw, you could set bit16 wrongly!
; FIXME: We need to read VERA_ADDR_BANK and FLIP bit 1 of the incrementer (which is bit 5 of VERA_ADDR_BANK)
; IDEA: maybe use TRB or TSB opcodes here!
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.

    
    ldy #TEST_FILL_COLOR     ; We use y as color

; FIXME: hardcoded!
    lda #50
    sta NUMBER_OF_ROWS
    
    jsr draw_polygon_part
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
    
    ; FIXME: NOTE that these increments are *HALF* steps!!
    lda #<(286)            ; X increment low
    sta $9F29
    lda #>(286)            ; X increment high
    and #%01111111            ; increment is only 15-bits long
    sta $9F2A
; FIXME: there is no need to set increment Y again!
    lda #<(130)            ; Y increment low
    sta $9F2B                
    and #%01111111            ; increment is only 15-bits long
    lda #>(130)            ; Y increment high
    sta $9F2C

; FIXME: hardcoded!
    lda #98
    sta NUMBER_OF_ROWS
    
    jsr draw_polygon_part
    
    rts



draw_polygon_part:

    lda #%00001011           ; DCSEL=5, ADDRSEL=1
    sta VERA_CTRL
    
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
; FIXME: right now getting fill length via DATA1 is not enabled!    
;    sta FILL_LENGTH_LOW ; we get important information back, so we store it

    
draw_triangle_row_next:

; FIXME: when we reset VERA things look a bit different. This is most likely due to the fact we are not resetting the subpixel position!
; FIXME: when we reset VERA things look a bit different. This is most likely due to the fact we are not resetting the subpixel position!
; FIXME: when we reset VERA things look a bit different. This is most likely due to the fact we are not resetting the subpixel position!

    ; HACK: we are reconstructing the separate bits we are getting into three 8-bit values. But this should normally *not*
    ;       be done! The bits are crafted in such a way to be used for a jump table. But for this example we dont use a jump table,
    ;       since it will be a bit more readably that way.
    
; FIXME: actually use the X1 and "FILL_LENGTH >= 16"-bit information!
    
    lda $9F2B      ; This contains: X1[2:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0]
;    lda FILL_LENGTH_LOW      ; This contains: X1[2:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0]
    and #%00001111          ; we keep the 4 lower bits
    sta FILL_LENGTH_LOW
    
; FIXME: we should check the bit that says if FILL_LENGTH >= 16!! (now we always assume this is the case)

    lda $9F2C               ; This contains 00, FILL_LENGTH[9:4]
    asl
    asl
    asl
    rol FILL_LENGTH_HIGH
    asl
    rol FILL_LENGTH_HIGH
    ora FILL_LENGTH_LOW
    sta FILL_LENGTH_LOW
    
; FIXME: what if FILL_LENGTH_LOW/FILL_LENGTH_HIGH are 0 or NEGATIVE?
    
; FIXME: we are ignoring if length > 256 atm!!

    tax
    
; FIXME: should we do this +1 here or inside of VERA?
    inx
    
    ; Note: we can speed this up *massively*, by unrolling this loop, but this is just an example to explain how the feature works
draw_triangle_pixel_next:
    
    sty VERA_DATA1
    
    dex
    bne draw_triangle_pixel_next
    
; FIXME
;    lda #0
;    sta VERA_DATA0
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (+1 vertically)
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
; FIXME: right now getting fill length via DATA1 is not enabled!    
;    sta FILL_LENGTH_LOW ; we get important information back, so we store it
    
    dec NUMBER_OF_ROWS
    bne draw_triangle_row_next
    
    rts

    

    .if(0)
; FIXME: implement this!!
; FIXME: implement this!!
; FIXME: implement this!!
test_speed_of_drawing_triangle:
        
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
        lda #<draw_lines_without_linked_mode_message
        sta TEXT_TO_PRINT
        lda #>draw_lines_without_linked_mode_message
        sta TEXT_TO_PRINT + 1
    .endif
    
    jsr print_text_zero
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts
    .endif
    
;draw_lines_320x240_8bpp_message: 
;    .asciiz "Drew 32 lines 320x240 (8bpp) "
;draw_lines_without_linked_mode_message: 
;    ; TODO: maybe specify what method exactly is used!
;    .asciiz "Method: not using affine helper"
;draw_lines_with_affine_helper_message: 
;    .asciiz "Method: using affine helper"
    
    

    
    
clear_screen_fast_4_bytes:

    ; Left part of the screen (256 columns)

    
    ldx #0
    
clear_next_column_left_4_bytes:
    lda #%11100010           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110) and wrpatter to 01
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
    lda #%11100010           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110) and wrpatter to 01
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
    lda #$8D               ; sta ....
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
