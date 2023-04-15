
DO_SPEED_TEST = 1
USE_POLYGON_FILLER = 1

    .if (USE_POLYGON_FILLER)
BACKGROUND_COLOR = 251  ; Nice purple
    .else
BACKGROUND_COLOR = 06  ; Blue 
    .endif

NR_OF_TRIANGLES_TO_DRAW = 1
    
    
TEST_FILL_COLOR = 1
TEST_TRIANGLE_TOP_POINT_X = 90
TEST_TRIANGLE_TOP_POINT_Y = 20
    
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

LOAD_ADDRESS              = $20 ; 21
STORE_ADDRESS             = $22 ; 23

; Polygon filler
NUMBER_OF_ROWS             = $30
FILL_LENGTH_LOW            = $31
FILL_LENGTH_HIGH           = $32
X1_THREE_LOWER_BITS        = $33

; Note: a triangle either has:
;   - a single top-point, which means it also has a bottom-left point and bottom-right point
;   - a double top-point (two points are at the same top-y), which means top-left point and top-right point and a single bottom-point
;   TODO: we still need to deal with "triangles" that have three points with the same x or the same y coordinate (which is in fact a vertical or horizontal *line*, not a triangle).
TOP_POINT_X              = $40 ; 41
TOP_POINT_Y              = $42 ; 43
LEFT_POINT_X             = $44 ; 45
LEFT_POINT_Y             = $46 ; 47
RIGHT_POINT_X            = $48 ; 49
RIGHT_POINT_Y            = $4A ; 4B
BOTTOM_POINT_X           = TOP_POINT_X
BOTTOM_POINT_Y           = TOP_POINT_Y

; RAM addresses
CLEAR_COLUMN_CODE        = $7000

; Triangle data is (easely) accessed through an single index (0-255)
TRIANGLES_POINT1_X_LOW   = $7400
TRIANGLES_POINT1_X_HIGH  = $7500
TRIANGLES_POINT1_Y_LOW   = $7600
TRIANGLES_POINT1_Y_HIGH  = $7700
TRIANGLES_POINT2_X_LOW   = $7800
TRIANGLES_POINT2_X_HIGH  = $7900
TRIANGLES_POINT2_Y_LOW   = $7A00
TRIANGLES_POINT2_Y_HIGH  = $7B00
TRIANGLES_POINT3_X_LOW   = $7C00
TRIANGLES_POINT3_X_HIGH  = $7D00
TRIANGLES_POINT3_Y_LOW   = $7E00
TRIANGLES_POINT3_Y_HIGH  = $7F00
TRIANGLES_COLOR          = $8000

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
       jsr test_speed_of_filling_triangle
    .else
    
;      lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
;      sta VERA_DC_HSCALE
;      sta VERA_DC_VSCALE
      jsr test_simple_polygon_filler
    .endif
    
  
loop:
  jmp loop

  
filling_a_rectangle_with_triangles_message: 
    .asciiz "Filling a rectangle with triangles"
rectangle_300x150_8bpp_message: 
    .asciiz "Size: 300x150 (8bpp) "
using_polygon_filler_message: 
    .asciiz "Method: polygon filler (naively)"
without_polygon_filler_message: 
    .asciiz "Method: without polygon filler"
  
  
test_speed_of_filling_triangle:


; FIXME: we need to create a jump table (and the code it jumps to)
;    jsr generate_fill_line_jump_table
    jsr load_triangle_data_into_ram

    jsr start_timer

    jsr draw_many_triangles_in_a_rectangle

    jsr stop_timer

    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #3
    sta CURSOR_X
    lda #2
    sta CURSOR_Y

    lda #<filling_a_rectangle_with_triangles_message
    sta TEXT_TO_PRINT
    lda #>filling_a_rectangle_with_triangles_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #10
    sta CURSOR_X
    lda #4
    sta CURSOR_Y
    
    lda #<rectangle_300x150_8bpp_message
    sta TEXT_TO_PRINT
    lda #>rectangle_300x150_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #4
    sta CURSOR_X
    lda #24
    sta CURSOR_Y

    .if(USE_POLYGON_FILLER)
        lda #<using_polygon_filler_message
        sta TEXT_TO_PRINT
        lda #>using_polygon_filler_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #<without_polygon_filler_message
        sta TEXT_TO_PRINT
        lda #>without_polygon_filler_message
        sta TEXT_TO_PRINT + 1
    .endif
    
    jsr print_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #8
    sta CURSOR_X
    lda #27
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts

    
    
triangles_points:
    ;    x  , y
   .word 100, 30
   .word 200, 70
   .word 100, 50
    
triangles_colors:
    ;     color
    .byte 04
    
    
    
load_triangle_data_into_ram:

    lda #<(triangles_points)
    sta LOAD_ADDRESS
    lda #>(triangles_points)
    sta LOAD_ADDRESS+1
    

    lda #<(triangles_points)
    sta STORE_ADDRESS
    lda #>(triangles_points)
    sta STORE_ADDRESS+1


    rts
    
    
draw_many_triangles_in_a_rectangle:
    
    
    ; FIXME: loop though a series of 3-points
    ;   check which type of triangle this is (single top-point or double top-point_
    ;   Store in appropiate variables: TOP_POINT_X/Y, LEFT_POINT_X/Y, RIGHT_POINT_X/Y, BOTTOM_POINT_X/Y
    ;   jump to correct draw_triangle-function
    
    
    ; HACK we are directly loading from triangles_points!! We should load it into the RAM TABLES first!
    
    ; HACK: we are hardcoding the top/bottom points right now!
    
    
    
    jsr draw_triangle_with_single_top_point
    
    
    
    
    
    rts
    
    
draw_triangle_with_single_top_point:

    ; FIXME: implement this:
    ; calculate 3 slopes for the 2 triangle parts
    ; set starting location on screen (ADDR0 = y, x1, x2 = x)
    ; determine how many rows have to be drawn for both triangle parts
    ; draw each triangle part

    .if(USE_POLYGON_FILLER)
        jsr draw_polygon_part_fast
    .else
        jsr draw_polygon_part_slow
    .endif
    
    rts
    
    
draw_triangle_with_double_top_points:

    ; FIXME: implement this!

    rts
    
    
draw_polygon_part_fast:

    ; FIXME: implement this!

    rts
    
    
draw_polygon_part_slow:

    ; FIXME: implement this!

    rts
    

    

test_simple_polygon_filler:

    ; Setting up for drawing a polygon, setting both addresses at the same starting point

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    ; Note: we are setting ADDR0 to the left most pixel of a pixel row. This means it will be aligned to 4-bytes (which is needed for the polygon filler to work nicely).
    lda #>(TEST_TRIANGLE_TOP_POINT_Y*320)
    sta VERA_ADDR_HIGH
    lda #<(TEST_TRIANGLE_TOP_POINT_Y*320)
    sta VERA_ADDR_LOW
    
    ; Entering *polygon fill mode*: from now on every read from DATA1 will increment x1 and x2, and ADDR1 will be filled with ADDR0 + x1
    lda #%00000011
    sta $9F29

    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
    ; FIXME: NOTE that these increments are *HALF* steps!!
    lda #<(-110)             ; X1 increment low (signed)
    sta $9F29
    lda #>(-110)             ; X1 increment high (signed)
    and #%01111111           ; increment is only 15-bits long
    sta $9F2A
    lda #<(380)              ; X2 increment low (signed)
    sta $9F2B                
    lda #>(380)              ; X2 increment high (signed)
    and #%01111111           ; increment is only 15-bits long
    sta $9F2C    
    
    
    ; Setting x1 and x2 pixel position
    
    lda #%00001001           ; DCSEL=4, ADDRSEL=1
    sta VERA_CTRL
    
    lda #<TEST_TRIANGLE_TOP_POINT_X
    sta $9F29                ; X (=X1) pixel position low [7:0]
    sta $9F2B                ; Y (=X2) pixel position low [7:0]
    
    ; NOTE: we are also *setting* the subpixel position (bit0) here! Even though we just resetted it! 
    ;       but its ok, since its reset to half a pixel (see above), meaning bit0 is 0 anyway
    lda #>TEST_TRIANGLE_TOP_POINT_X
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
    lda #150
    sta NUMBER_OF_ROWS
    
    jsr draw_polygon_part_using_polygon_filler
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
    
    ; FIXME: NOTE that these increments are *HALF* steps!!
    lda #<(-110)              ; X1 increment low
    sta $9F29
    lda #>(-110)              ; X1 increment high
    and #%01111111            ; increment is only 15-bits long
    sta $9F2A
; FIXME: there is no need to set increment Y again!
    lda #<(-1590)             ; X2 increment low
    sta $9F2B                
    lda #>(-1590)             ; X2 increment high
    and #%01111111            ; increment is only 15-bits long
    sta $9F2C

; FIXME: hardcoded!
    lda #50
    sta NUMBER_OF_ROWS
    
    jsr draw_polygon_part_using_polygon_filler
    
    rts



draw_polygon_part_using_polygon_filler:

    lda #%00001011           ; DCSEL=5, ADDRSEL=1
    sta VERA_CTRL
    
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
polygon_fill_triangle_row_next:

    ; SLOW: we are not using all the information we get and are only reconstructing the 10-bit value. But this should normally *not*
    ;       be done! The bits are crafted in such a way to be used for a jump table. But for this example we dont use a jump table,
    ;       since it will be a bit more readably that way.
    
    stz FILL_LENGTH_HIGH
    
    lda $9F2B               ; This contains: X1[2:0], FILL_LENGTH >= 16, FILL_LENGTH[3:0]
    and #%00001111          ; we keep the 4 lower bits
    sta FILL_LENGTH_LOW

    lda $9F2C               ; This contains 00, FILL_LENGTH[9:4]
    asl
    asl
    asl
    rol FILL_LENGTH_HIGH
    asl
    rol FILL_LENGTH_HIGH
    ora FILL_LENGTH_LOW
    sta FILL_LENGTH_LOW
    
    ; FIXME: what if FILL_LENGTH_LOW/FILL_LENGTH_HIGH are 0 or NEGATIVE? -> OR deal with this on the VERA side?
    
    tax
    
    ; FIXME: should we do this +1 here or inside of VERA? -> note: when x = 255, 256 pixels will be drawn (which is what we want right now)
    inx
    
    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using wrpatterns), but this is just an example to explain how the feature works
polygon_fill_triangle_pixel_next_0:
    sty VERA_DATA1
    dex
    bne polygon_fill_triangle_pixel_next_0

    ; We draw an additional FILL_LENGTH_HIGH * 256 pixels on this row
    lda FILL_LENGTH_HIGH
    beq polygon_fill_triangle_row_done

    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using wrpatterns), but this is just an example to explain how the feature works
polygon_fill_triangle_pixel_next_256:
    ldx #0
polygon_fill_triangle_pixel_next_256_0:
    sty VERA_DATA1
    dex
    bne polygon_fill_triangle_pixel_next_256_0
    dec FILL_LENGTH_HIGH
    bne polygon_fill_triangle_pixel_next_256
    
polygon_fill_triangle_row_done:
    
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (= +1 vertically)
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
    dec NUMBER_OF_ROWS
    bne polygon_fill_triangle_row_next
    
    rts
    
    
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
