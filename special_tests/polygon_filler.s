
DO_SPEED_TEST = 1

USE_POLYGON_FILLER = 0
USE_SLOPE_TABLES = 0    ; FIXME: this doesnt work for non-polygon filler mode right now!
USE_UNROLLED_LOOP = 0
USE_JUMP_TABLE = 0
USE_WRITE_CACHE = 0

USE_Y_TO_ADDRESS_TABLE = 1

    .if (USE_POLYGON_FILLER || USE_WRITE_CACHE)
BACKGROUND_COLOR = 251  ; Nice purple
    .else
BACKGROUND_COLOR = 06  ; Blue 
    .endif
    
COLOR_CHECK        = $05 ; Background color = 0, foreground color 5 (green)
COLOR_CROSS        = $02 ; Background color = 0, foreground color 2 (red)

BASE_X = 20
BASE_Y = 50
BX = BASE_X
BY = BASE_Y
    
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
TEXT_TO_PRINT             = $08 ; 09
TEXT_COLOR                = $0A
CURSOR_X                  = $0B
CURSOR_Y                  = $0C
INDENTATION               = $0D
BYTE_TO_PRINT             = $0E
DECIMAL_STRING            = $0F ; 10 ; 11

; Timing
TIMING_COUNTER            = $14 ; 15
TIME_ELAPSED_MS           = $16
TIME_ELAPSED_SUB_MS       = $17 ; one nibble of sub-milliseconds

; Used only by (slow) 16-bit multiplier (multply_16bits)
MULTIPLIER                = $18 ; 19
MULTIPLICAND              = $1A ; 1B
PRODUCT                   = $1C ; 1D ; 1E ; 1F

; Used by the (slow) 24-bit divider (divide_24bits)
DIVIDEND                  = $20 ; 21 ; 22  ; the thing you want to divide (e.g. 100 /) . This will also the result after the division
DIVISOR                   = $23 ; 24 ; 25  ; the thing you divide by (e.g. / 10)
REMAINDER                 = $26 ; 27 ; 28

; For geneating code
CODE_ADDRESS              = $30 ; 31
LOAD_ADDRESS              = $32 ; 33
STORE_ADDRESS             = $34 ; 35

TABLE_ROM_BANK            = $36

TRIANGLE_INDEX            = $38

; Polygon filler
NUMBER_OF_ROWS             = $39
FILL_LENGTH_LOW            = $3A
FILL_LENGTH_HIGH           = $3B
X1_THREE_LOWER_BITS        = $3C

; "Software" implementation of polygon filler
SOFT_Y                     = $3E ; 3F
SOFT_X1_SUB                = $40 ; 41
SOFT_X1                    = $42 ; 43
SOFT_X2_SUB                = $44 ; 45
SOFT_X2                    = $46 ; 47
SOFT_X1_INCR_SUB           = $48 ; 49
SOFT_X1_INCR               = $4A ; 4B
SOFT_X2_INCR_SUB           = $4C ; 4D
SOFT_X2_INCR               = $4E ; 4F

; Note: a triangle either has:
;   - a single top-point, which means it also has a bottom-left point and bottom-right point
;   - a double top-point (two points are at the same top-y), which means top-left point and top-right point and a single bottom-point
;   TODO: we still need to deal with "triangles" that have three points with the same x or the same y coordinate (which is in fact a vertical or horizontal *line*, not a triangle).
TOP_POINT_X              = $50 ; 51
TOP_POINT_Y              = $52 ; 53
LEFT_POINT_X             = $54 ; 55
LEFT_POINT_Y             = $56 ; 57
RIGHT_POINT_X            = $58 ; 59
RIGHT_POINT_Y            = $5A ; 5B
BOTTOM_POINT_X           = TOP_POINT_X
BOTTOM_POINT_Y           = TOP_POINT_Y
TRIANGLE_COLOR           = $5C

; Used for calculating the slope between two points
X_DISTANCE               = $60 ; 61
X_DISTANCE_IS_NEGATED    = $62
Y_DISTANCE_LEFT_TOP      = $63 ; 64
Y_DISTANCE_BOTTOM_LEFT = Y_DISTANCE_LEFT_TOP
Y_DISTANCE_RIGHT_TOP     = $65 ; 66
Y_DISTANCE_BOTTOM_RIGHT = Y_DISTANCE_RIGHT_TOP
Y_DISTANCE_RIGHT_LEFT    = $67 ; 68
Y_DISTANCE_LEFT_RIGHT = Y_DISTANCE_RIGHT_LEFT
Y_DISTANCE_IS_NEGATED    = $69
SLOPE_TOP_LEFT           = $6A ; 6B ; 6C   ; TODO: do we really need 24 bits here?
SLOPE_LEFT_BOTTOM = SLOPE_TOP_LEFT
SLOPE_TOP_RIGHT          = $6D ; 6E ; 6F   ; TODO: do we really need 24 bits here?
SLOPE_RIGHT_BOTTOM = SLOPE_TOP_RIGHT
SLOPE_LEFT_RIGHT         = $70 ; 71 ; 72   ; TODO: do we really need 24 bits here?
SLOPE_RIGHT_LEFT = SLOPE_LEFT_RIGHT


Y_DISTANCE_FIRST         = $76 ; 77
Y_DISTANCE_SECOND        = $78 ; 79

VRAM_ADDRESS             = $80 ; 81 ; 82

; RAM addresses
CLEAR_COLUMN_CODE        = $7000

; Triangle data is (easely) accessed through an single index (0-255)
; == IMPORTANT: we assume a *clockwise* ordering of the 3 points of a triangle! ==
TRIANGLES_POINT1_X       = $7400 ; 7500
TRIANGLES_POINT1_Y       = $7600 ; 7700
TRIANGLES_POINT2_X       = $7800 ; 7900
TRIANGLES_POINT2_Y       = $7A00 ; 7B00
TRIANGLES_POINT3_X       = $7C00 ; 7D00
TRIANGLES_POINT3_Y       = $7E00 ; 7F00
TRIANGLES_COLOR          = $8000

Y_TO_ADDRESS_LOW         = $8100
Y_TO_ADDRESS_HIGH        = $8200
Y_TO_ADDRESS_BANK        = $8300

COPY_SLOPE_TABLES_TO_BANKED_RAM   = $8400

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
    
    jsr copy_palette_from_index_16

    .if (USE_POLYGON_FILLER || USE_WRITE_CACHE)
        jsr generate_clear_column_code
        jsr clear_screen_fast_4_bytes
    .else
        jsr clear_screen_slow
    .endif
    
    jsr generate_y_to_address_table
    
    .if(USE_SLOPE_TABLES)
        jsr copy_slope_table_copier_to_ram
        jsr COPY_SLOPE_TABLES_TO_BANKED_RAM
    .endif
    
    
    .if(DO_SPEED_TEST)
       jsr test_speed_of_filling_triangle
    .else
      lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
      sta VERA_DC_HSCALE
      sta VERA_DC_VSCALE      
    
      jsr test_simple_polygon_filler
    .endif
    
  
loop:
  jmp loop


check_raw_message: 
    .byte $FA, 0
cross_raw_message: 
    .byte $56, 0
  
filling_a_rectangle_with_triangles_message: 
    .asciiz "Filling rectangle with "
filling_a_rectangle_with_triangles_message2: 
    .asciiz " triangles"
    
rectangle_280x120_8bpp_message: 
    .asciiz "Size: 280x120 (8bpp) "
    
polygon_filler_message: 
    .asciiz " Polygon filler "
slope_table_message: 
    .asciiz " Slope table "
unrolled_message: 
    .asciiz " Unrolled "
jump_table_message: 
    .asciiz " Jump table "
write_cache_message: 
    .asciiz " Write cache "
  
  
test_speed_of_filling_triangle:


; FIXME: we need to create a jump table (and the code it jumps to)
;    jsr generate_fill_line_jump_table
    jsr load_triangle_data_into_ram

    jsr start_timer

    jsr draw_many_triangles_in_a_rectangle

    jsr stop_timer

    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #2
    sta CURSOR_X
    lda #2
    sta CURSOR_Y

    lda #<filling_a_rectangle_with_triangles_message
    sta TEXT_TO_PRINT
    lda #>filling_a_rectangle_with_triangles_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #NR_OF_TRIANGLES
    sta BYTE_TO_PRINT
    jsr print_byte_as_decimal

    lda #<filling_a_rectangle_with_triangles_message2
    sta TEXT_TO_PRINT
    lda #>filling_a_rectangle_with_triangles_message2
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    
    lda #10
    sta CURSOR_X
    lda #4
    sta CURSOR_Y
    
    lda #<rectangle_280x120_8bpp_message
    sta TEXT_TO_PRINT
    lda #>rectangle_280x120_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero


    ; ---------- Used techniques -----------
    
    lda #2
    sta CURSOR_X
    lda #23
    sta CURSOR_Y

    ; -- Slope table --
    
    .if(USE_SLOPE_TABLES)
        lda #COLOR_CHECK
        sta TEXT_COLOR
    
        lda #<check_raw_message
        sta TEXT_TO_PRINT
        lda #>check_raw_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #COLOR_CROSS
        sta TEXT_COLOR
    
        lda #<cross_raw_message
        sta TEXT_TO_PRINT
        lda #>cross_raw_message
        sta TEXT_TO_PRINT + 1
    .endif
    jsr print_raw_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
        
    lda #<slope_table_message
    sta TEXT_TO_PRINT
    lda #>slope_table_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; -- Unrolled loop --
    
    .if(USE_UNROLLED_LOOP)
        lda #COLOR_CHECK
        sta TEXT_COLOR
    
        lda #<check_raw_message
        sta TEXT_TO_PRINT
        lda #>check_raw_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #COLOR_CROSS
        sta TEXT_COLOR
    
        lda #<cross_raw_message
        sta TEXT_TO_PRINT
        lda #>cross_raw_message
        sta TEXT_TO_PRINT + 1
    .endif
    jsr print_raw_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
        
    lda #<unrolled_message
    sta TEXT_TO_PRINT
    lda #>unrolled_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    ; -- Jump table --
    
    .if(USE_JUMP_TABLE)
        lda #COLOR_CHECK
        sta TEXT_COLOR
    
        lda #<check_raw_message
        sta TEXT_TO_PRINT
        lda #>check_raw_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #COLOR_CROSS
        sta TEXT_COLOR
    
        lda #<cross_raw_message
        sta TEXT_TO_PRINT
        lda #>cross_raw_message
        sta TEXT_TO_PRINT + 1
    .endif
    jsr print_raw_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
        
    lda #<jump_table_message
    sta TEXT_TO_PRINT
    lda #>jump_table_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero

    lda #4
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    ; -- Polygon filler --
    
    .if(USE_POLYGON_FILLER)
        lda #COLOR_CHECK
        sta TEXT_COLOR
    
        lda #<check_raw_message
        sta TEXT_TO_PRINT
        lda #>check_raw_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #COLOR_CROSS
        sta TEXT_COLOR
    
        lda #<cross_raw_message
        sta TEXT_TO_PRINT
        lda #>cross_raw_message
        sta TEXT_TO_PRINT + 1
    .endif
    jsr print_raw_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
        
    lda #<polygon_filler_message
    sta TEXT_TO_PRINT
    lda #>polygon_filler_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    ; -- Write cache --
    
    .if(USE_WRITE_CACHE)
        lda #COLOR_CHECK
        sta TEXT_COLOR
    
        lda #<check_raw_message
        sta TEXT_TO_PRINT
        lda #>check_raw_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #COLOR_CROSS
        sta TEXT_COLOR
    
        lda #<cross_raw_message
        sta TEXT_TO_PRINT
        lda #>cross_raw_message
        sta TEXT_TO_PRINT + 1
    .endif
    jsr print_raw_text_zero
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
        
    lda #<write_cache_message
    sta TEXT_TO_PRINT
    lda #>write_cache_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    

    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #8
    sta CURSOR_X
    lda #27
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts

    
    .if(0)
NR_OF_TRIANGLES = 12
triangle_data:
    ;     x1,  y1,    x2,  y2,    x3,  y3    cl
   .word   0,   0,   100,  70,    0,  50,    4
   .word   0,   0,   200,   1,  100,  70,    5
   .word   0,   0,   280,   0,  200,   1,    3
   .word 200,   1,   279,   0,  280,   120,  7
   .word 279,   0,   280,   0,  280,   120,  15
   .word 180,  50,   200,   1,  280,   120,  8
   .word   0, 120,    80, 100,  280,   120,  9
   .word 100,  70,   200,   1,  180,    50,  10
   .word   0,  50,    80, 100,    0,   120,  11
   .word   0,  50,   100,  70,   80,   100,  12
   .word 100,  70,   180,  50,   80,   100,  13
   .word 180,  50,   280, 120,   80,   100,  14
    .endif
   
   
NR_OF_TRIANGLES = 72
triangle_data:
    ;     x1,  y1,    x2,  y2,    x3,  y3    cl
    .word 260 ,26  ,267 ,13  ,280 ,20  ,16
    .word 260 ,26  ,280 ,20  ,280 ,52  ,17
    .word 262 ,64  ,260 ,26  ,280 ,52  ,18
    .word 270 ,120 ,244 ,120 ,280 ,103 ,17
    .word 244 ,120 ,262 ,64  ,280 ,103 ,19
    .word 280 ,20  ,267 ,13  ,280 ,5   ,20
    .word 267 ,13  ,264 ,8   ,280 ,5   ,21
    .word 280 ,103 ,262 ,64  ,280 ,63  ,22
    .word 270 ,120 ,280 ,103 ,280 ,109 ,23
    .word 270 ,120 ,270 ,120 ,280 ,109 ,24
    .word 280 ,119 ,270 ,120 ,280 ,109 ,24
    .word 270 ,120 ,280 ,119 ,280 ,120 ,25
    .word 280 ,63  ,262 ,64  ,280 ,60  ,26
    .word 262 ,64  ,280 ,52  ,280 ,60  ,27
    .word 280 ,5   ,264 ,8   ,280 ,0   ,21
    .word 264 ,8   ,254 ,6   ,280 ,0   ,28
    .word 254 ,6   ,232 ,0   ,280 ,0   ,18
    .word 244 ,120 ,219 ,76  ,262 ,64  ,29
    .word 219 ,76  ,227 ,64  ,262 ,64  ,30
    .word 227 ,64  ,260 ,26  ,262 ,64  ,21
    .word 260 ,26  ,254 ,6   ,264 ,8   ,31
    .word 260 ,26  ,264 ,8   ,267 ,13  ,31
    .word 233 ,120 ,219 ,76  ,244 ,120 ,32
    .word 223 ,3   ,181 ,0   ,232 ,0   ,33
    .word 214 ,11  ,228 ,4   ,260 ,26  ,34
    .word 227 ,64  ,214 ,11  ,260 ,26  ,18
    .word 228 ,4   ,254 ,6   ,260 ,26  ,22
    .word 228 ,4   ,232 ,0   ,254 ,6   ,30
    .word 213 ,117 ,219 ,76  ,233 ,120 ,35
    .word 177 ,66  ,214 ,11  ,227 ,64  ,36
    .word 208 ,120 ,213 ,117 ,233 ,120 ,37
    .word 214 ,11  ,223 ,3   ,228 ,4   ,24
    .word 228 ,4   ,223 ,3   ,232 ,0   ,38
    .word 214 ,11  ,181 ,0   ,223 ,3   ,17
    .word 219 ,76  ,177 ,66  ,227 ,64  ,28
    .word 213 ,117 ,208 ,120 ,219 ,76  ,31
    .word 177 ,66  ,181 ,0   ,214 ,11  ,16
    .word 208 ,120 ,177 ,66  ,219 ,76  ,31
    .word 177 ,66  ,168 ,0   ,181 ,0   ,17
    .word 139 ,120 ,177 ,66  ,208 ,120 ,39
    .word 91  ,65  ,139 ,0   ,177 ,66  ,40
    .word 139 ,0   ,168 ,0   ,177 ,66  ,39
    .word 139 ,120 ,91  ,65  ,177 ,66  ,41
    .word 91  ,65  ,82  ,55  ,107 ,0   ,37
    .word 115 ,120 ,91  ,65  ,139 ,120 ,34
    .word 91  ,65  ,107 ,0   ,139 ,0   ,26
    .word 82  ,55  ,75  ,0   ,107 ,0   ,28
    .word 74  ,97  ,91  ,65  ,115 ,120 ,42
    .word 83  ,120 ,74  ,97  ,115 ,120 ,42
    .word 64  ,49  ,75  ,0   ,82  ,55  ,43
    .word 64  ,49  ,59  ,0   ,75  ,0   ,44
    .word 0   ,120 ,10  ,111 ,83  ,120 ,17
    .word 74  ,97  ,82  ,55  ,91  ,65  ,33
    .word 36  ,88  ,64  ,49  ,74  ,97  ,45
    .word 74  ,97  ,64  ,49  ,82  ,55  ,23
    .word 36  ,88  ,74  ,97  ,83  ,120 ,34
    .word 10  ,111 ,36  ,88  ,83  ,120 ,37
    .word 34  ,0   ,59  ,0   ,64  ,49  ,26
    .word 13  ,75  ,0   ,60  ,64  ,49  ,46
    .word 0   ,20  ,34  ,0   ,64  ,49  ,47
    .word 0   ,60  ,0   ,20  ,64  ,49  ,48
    .word 36  ,88  ,13  ,75  ,64  ,49  ,49
    .word 0   ,20  ,0   ,0   ,34  ,0   ,26
    .word 0   ,92  ,13  ,75  ,36  ,88  ,50
    .word 10  ,111 ,0   ,92  ,36  ,88  ,40
    .word 0   ,0   ,0   ,0   ,34  ,0   ,51
    .word 0   ,120 ,0   ,116 ,10  ,111 ,52
    .word 0   ,70  ,0   ,70  ,13  ,75  ,32
    .word 0   ,81  ,0   ,70  ,13  ,75  ,24
    .word 0   ,92  ,0   ,81  ,13  ,75  ,17
    .word 0   ,70  ,0   ,60  ,13  ,75  ,23
    .word 0   ,116 ,0   ,92  ,10  ,111 ,46

palette_data:
    .byte $c8, $08  ; palette index 16
    .byte $c7, $09  ; palette index 17
    .byte $c9, $07  ; palette index 18
    .byte $a6, $06  ; palette index 19
    .byte $fd, $0a  ; palette index 20
    .byte $a6, $07  ; palette index 21
    .byte $b9, $07  ; palette index 22
    .byte $fb, $0c  ; palette index 23
    .byte $74, $03  ; palette index 24
    .byte $ff, $0f  ; palette index 25
    .byte $95, $05  ; palette index 26
    .byte $85, $04  ; palette index 27
    .byte $b6, $07  ; palette index 28
    .byte $b8, $07  ; palette index 29
    .byte $ec, $09  ; palette index 30
    .byte $db, $08  ; palette index 31
    .byte $fe, $0b  ; palette index 32
    .byte $e8, $0c  ; palette index 33
    .byte $f9, $0d  ; palette index 34
    .byte $b8, $08  ; palette index 35
    .byte $b7, $07  ; palette index 36
    .byte $d8, $0b  ; palette index 37
    .byte $f9, $0e  ; palette index 38
    .byte $d9, $09  ; palette index 39
    .byte $d8, $0a  ; palette index 40
    .byte $e8, $0b  ; palette index 41
    .byte $fa, $0f  ; palette index 42
    .byte $b7, $08  ; palette index 43
    .byte $ea, $0b  ; palette index 44
    .byte $fa, $0d  ; palette index 45
    .byte $e9, $0b  ; palette index 46
    .byte $a7, $06  ; palette index 47
    .byte $d9, $0a  ; palette index 48
    .byte $fa, $0c  ; palette index 49
    .byte $c7, $0a  ; palette index 50
    .byte $a7, $05  ; palette index 51
    .byte $fc, $0f  ; palette index 52
end_of_palette_data:

   
load_triangle_data_into_ram:

    lda #<(triangle_data)
    sta LOAD_ADDRESS
    lda #>(triangle_data)
    sta LOAD_ADDRESS+1

    ldx #0
load_next_triangle:
    
    ldy #0
    
    ; -- Point 1 --
    clc
    lda (LOAD_ADDRESS), y
    iny
    adc #<BX
    sta TRIANGLES_POINT1_X, x
    lda (LOAD_ADDRESS), y
    iny
    adc #>BX
    sta TRIANGLES_POINT1_X+256, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    adc #<BY
    sta TRIANGLES_POINT1_Y, x
    lda (LOAD_ADDRESS), y
    iny
    adc #>BY
    sta TRIANGLES_POINT1_Y+256, x
    
    ; -- Point 2 --
    clc
    lda (LOAD_ADDRESS), y
    iny
    adc #<BX
    sta TRIANGLES_POINT2_X, x
    lda (LOAD_ADDRESS), y
    iny
    adc #>BX
    sta TRIANGLES_POINT2_X+256, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    adc #<BY
    sta TRIANGLES_POINT2_Y, x
    lda (LOAD_ADDRESS), y
    iny
    adc #>BY
    sta TRIANGLES_POINT2_Y+256, x

    ; -- Point 3 --
    clc
    lda (LOAD_ADDRESS), y
    iny
    adc #<BX
    sta TRIANGLES_POINT3_X, x
    lda (LOAD_ADDRESS), y
    iny
    adc #>BX
    sta TRIANGLES_POINT3_X+256, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    adc #<BY
    sta TRIANGLES_POINT3_Y, x
    lda (LOAD_ADDRESS), y
    iny
    adc #>BY
    sta TRIANGLES_POINT3_Y+256, x
    
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_COLOR, x
    
    clc
    lda LOAD_ADDRESS
    adc #14             ; 7 words (3 * x and y, color uses only one byte, but takes space of a word)
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    inx
    
    cpx #NR_OF_TRIANGLES
    bne load_next_triangle

    rts
    

MACRO_copy_point .macro TRIANGLES_POINT_X, POINT_X
    lda \TRIANGLES_POINT_X, x
    sta \POINT_X
    lda \TRIANGLES_POINT_X+256, x
    sta \POINT_X+1
.endmacro

    
draw_many_triangles_in_a_rectangle:
    
    
    ; Loop though a series of 3-points:
    ;   check which type of triangle this is (single top-point or double top-point_
    ;   Store in appropiate variables: TOP_POINT_X/Y, LEFT_POINT_X/Y, RIGHT_POINT_X/Y, BOTTOM_POINT_X/Y
    ;   jump to correct draw_triangle-function

    ; We start at triangle 0
    stz TRIANGLE_INDEX
draw_next_triangle:

    ldx TRIANGLE_INDEX
    
    lda TRIANGLES_COLOR, x
    sta TRIANGLE_COLOR
    
    ; -- Determining which point is/are top point(s) --

    lda TRIANGLES_POINT1_Y+256, x
    cmp TRIANGLES_POINT2_Y+256, x
    bcc point1_is_lower_in_y_than_point2
    bne point1_is_higher_in_y_than_point2

    lda TRIANGLES_POINT1_Y, x
    cmp TRIANGLES_POINT2_Y, x
    bcc point1_is_lower_in_y_than_point2
    beq point1_is_the_same_in_y_as_point2
    bne point1_is_higher_in_y_than_point2
    
point1_is_lower_in_y_than_point2:
    
    lda TRIANGLES_POINT1_Y+256, x
    cmp TRIANGLES_POINT3_Y+256, x
    bcc pt1_lower_pt2_point1_is_lower_in_y_than_point3
    bne pt1_lower_pt2_point1_is_higher_in_y_than_point3

    lda TRIANGLES_POINT1_Y, x
    cmp TRIANGLES_POINT3_Y, x
    bcc pt1_lower_pt2_point1_is_lower_in_y_than_point3
    beq pt1_lower_pt2_point1_is_the_same_in_y_as_point3
    bne pt1_lower_pt2_point1_is_higher_in_y_than_point3
    
pt1_lower_pt2_point1_is_lower_in_y_than_point3:

    ; This means point1 is lower than point2 and point3
    jmp point1_is_top_point
    
pt1_lower_pt2_point1_is_higher_in_y_than_point3:

    ; This means point1 is lower than point2 but higher than point3, this means point3 is the lowest
    jmp point3_is_top_point
    
pt1_lower_pt2_point1_is_the_same_in_y_as_point3:

    ; This means point1 is lower than point2 but is equal to point3, this means point1 and point3 are both the lowest
    jmp point3_and_point1_are_top_points
    
    
point1_is_higher_in_y_than_point2:

    lda TRIANGLES_POINT2_Y+256, x
    cmp TRIANGLES_POINT3_Y+256, x
    bcc pt1_higher_pt2_point2_is_lower_in_y_than_point3
    bne pt1_higher_pt2_point2_is_higher_in_y_than_point3

    lda TRIANGLES_POINT2_Y, x
    cmp TRIANGLES_POINT3_Y, x
    bcc pt1_higher_pt2_point2_is_lower_in_y_than_point3
    beq pt1_higher_pt2_point2_is_the_same_in_y_as_point3
    bne pt1_higher_pt2_point2_is_higher_in_y_than_point3

pt1_higher_pt2_point2_is_lower_in_y_than_point3:

    ; Point1 is higher than point2 and point2 is lower than point3, this means point2 is lowest
    jmp point2_is_top_point
    
pt1_higher_pt2_point2_is_higher_in_y_than_point3:

    ; Point1 is higher than point2 and point2 is higher than point 3, this means point3 is lowest
    jmp point3_is_top_point

pt1_higher_pt2_point2_is_the_same_in_y_as_point3:

    ; Point1 is higher than point2 and point2 is the same as point3, this means point2 and point3 are both the lowest
    jmp point2_and_point3_are_top_points

    
point1_is_the_same_in_y_as_point2:

    lda TRIANGLES_POINT1_Y+256, x
    cmp TRIANGLES_POINT3_Y+256, x
    bcc pt1_same_pt2_point1_is_lower_in_y_than_point3
    bne pt1_same_pt2_point1_is_higher_in_y_than_point3

    lda TRIANGLES_POINT1_Y, x
    cmp TRIANGLES_POINT3_Y, x
    bcc pt1_same_pt2_point1_is_lower_in_y_than_point3
    beq pt1_same_pt2_point1_is_the_same_in_y_as_point3
    bne pt1_same_pt2_point1_is_higher_in_y_than_point3

pt1_same_pt2_point1_is_lower_in_y_than_point3:

    ; Point1 and point2 are the same, thet are both lower than point3, this means point1 and point2 are both the lowest
    jmp point1_and_point2_are_top_points

pt1_same_pt2_point1_is_higher_in_y_than_point3:

    ; Point1 and point2 are the same, thet are both higher than point3, this means point3 is lowest
    jmp point3_is_top_point

pt1_same_pt2_point1_is_the_same_in_y_as_point3:

    ; All points have the same y, this means we have a horizontal line
    jmp point1_point2_and_point3_are_top_points

    
point1_is_top_point:

    ; -- TOP POINT --
    MACRO_copy_point TRIANGLES_POINT1_X, TOP_POINT_X
    MACRO_copy_point TRIANGLES_POINT1_Y, TOP_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point TRIANGLES_POINT2_X, RIGHT_POINT_X
    MACRO_copy_point TRIANGLES_POINT2_Y, RIGHT_POINT_Y
    
    ; -- LEFT POINT --
    MACRO_copy_point TRIANGLES_POINT3_X, LEFT_POINT_X
    MACRO_copy_point TRIANGLES_POINT3_Y, LEFT_POINT_Y

    jmp draw_triangle_with_single_top_point


point2_is_top_point:
    
    ; -- TOP POINT --
    MACRO_copy_point TRIANGLES_POINT2_X, TOP_POINT_X
    MACRO_copy_point TRIANGLES_POINT2_Y, TOP_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point TRIANGLES_POINT3_X, RIGHT_POINT_X
    MACRO_copy_point TRIANGLES_POINT3_Y, RIGHT_POINT_Y
    
    ; -- LEFT POINT --
    MACRO_copy_point TRIANGLES_POINT1_X, LEFT_POINT_X
    MACRO_copy_point TRIANGLES_POINT1_Y, LEFT_POINT_Y

    jmp draw_triangle_with_single_top_point

point3_is_top_point:

    ; -- TOP POINT --
    MACRO_copy_point TRIANGLES_POINT3_X, TOP_POINT_X
    MACRO_copy_point TRIANGLES_POINT3_Y, TOP_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point TRIANGLES_POINT1_X, RIGHT_POINT_X
    MACRO_copy_point TRIANGLES_POINT1_Y, RIGHT_POINT_Y
    
    ; -- LEFT POINT --
    MACRO_copy_point TRIANGLES_POINT2_X, LEFT_POINT_X
    MACRO_copy_point TRIANGLES_POINT2_Y, LEFT_POINT_Y

    jmp draw_triangle_with_single_top_point

point1_and_point2_are_top_points:

    ; -- LEFT POINT --
    MACRO_copy_point TRIANGLES_POINT1_X, LEFT_POINT_X
    MACRO_copy_point TRIANGLES_POINT1_Y, LEFT_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point TRIANGLES_POINT2_X, RIGHT_POINT_X
    MACRO_copy_point TRIANGLES_POINT2_Y, RIGHT_POINT_Y

    ; -- BOTTOM POINT --
    MACRO_copy_point TRIANGLES_POINT3_X, BOTTOM_POINT_X
    MACRO_copy_point TRIANGLES_POINT3_Y, BOTTOM_POINT_Y
    
    jmp draw_triangle_with_double_top_points

point2_and_point3_are_top_points:

    ; -- LEFT POINT --
    MACRO_copy_point TRIANGLES_POINT2_X, LEFT_POINT_X
    MACRO_copy_point TRIANGLES_POINT2_Y, LEFT_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point TRIANGLES_POINT3_X, RIGHT_POINT_X
    MACRO_copy_point TRIANGLES_POINT3_Y, RIGHT_POINT_Y

    ; -- BOTTOM POINT --
    MACRO_copy_point TRIANGLES_POINT1_X, BOTTOM_POINT_X
    MACRO_copy_point TRIANGLES_POINT1_Y, BOTTOM_POINT_Y
    
    jmp draw_triangle_with_double_top_points

point3_and_point1_are_top_points:
    
    ; -- LEFT POINT --
    MACRO_copy_point TRIANGLES_POINT3_X, LEFT_POINT_X
    MACRO_copy_point TRIANGLES_POINT3_Y, LEFT_POINT_Y

    ; -- RIGHT POINT --
    MACRO_copy_point TRIANGLES_POINT1_X, RIGHT_POINT_X
    MACRO_copy_point TRIANGLES_POINT1_Y, RIGHT_POINT_Y

    ; -- BOTTOM POINT --
    MACRO_copy_point TRIANGLES_POINT2_X, BOTTOM_POINT_X
    MACRO_copy_point TRIANGLES_POINT2_Y, BOTTOM_POINT_Y
    
    jmp draw_triangle_with_double_top_points

point1_point2_and_point3_are_top_points:

    ; FIXME: what should we do in this case? Should we draw a horizonal line? 
    
    ; FIXME: right now, we just move on to the next triangle
    
    
done_drawing_polygon_part:

    inc TRIANGLE_INDEX
    lda TRIANGLE_INDEX
    cmp #NR_OF_TRIANGLES
    beq done_drawing_all_triangles
    jmp draw_next_triangle
    
    
done_drawing_all_triangles:
    
    ; Turning off polygon filler mode
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    ; Normal addr1 mode
    lda #%00000000
    sta $9F29
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
    
MACRO_get_slope_from_slope_table: .macro Y_DISTANCE, SLOPE

    ; We get the SLOPE from the slope table. We need:
    ;   y = Y_DISTANCE
    ;   RAM_BANK = X_DISTANCE[5:0]
    ;   ADDR_HIGH[3:1] = X_DISTANCE[8:6]
        
    ldy \Y_DISTANCE

    lda X_DISTANCE
    and #%00111111
    sta RAM_BANK

    ; We rotate bits 7 and 6 into X_DISTANCE+1 (which contains bit 8)
    asl X_DISTANCE
    rol X_DISTANCE+1
    asl X_DISTANCE
    rol X_DISTANCE+1
    
    ; We shift bits 8, 7 and 6 into bits 3, 2 and 1
    asl X_DISTANCE+1
    
    ; We combine bits 3:1 with A0
    lda #>($A000)
    ora X_DISTANCE+1
    sta LOAD_ADDRESS+1
    
    ; SPEED: we dont need to do this again and again, this stays at zero!
    lda #<($A000)
    sta LOAD_ADDRESS
    
    ; We load the SLOPE_LOW
    lda (LOAD_ADDRESS), y
    sta \SLOPE
    
    ; We load the SLOPE_HIGH
    inc LOAD_ADDRESS+1
    lda (LOAD_ADDRESS), y
    sta \SLOPE+1
.endmacro


MACRO_calculate_slope_using_division: .macro Y_DISTANCE, SLOPE

    ; We do the divide: X_DISTANCE * 256 / Y_DISTANCE
    lda X_DISTANCE+1
    sta DIVIDEND+2
    lda X_DISTANCE
    sta DIVIDEND+1
    lda #0
    sta DIVIDEND

    lda #0
    sta DIVISOR+2
    lda \Y_DISTANCE+1
    sta DIVISOR+1
    lda \Y_DISTANCE
    sta DIVISOR

    jsr divide_24bits
    
    lda DIVIDEND+2
    sta \SLOPE+2
    lda DIVIDEND+1
    sta \SLOPE+1
    lda DIVIDEND
    sta \SLOPE
    
    .if(USE_POLYGON_FILLER)
    
        ; If SLOPE >= 64 we should shift 5 bits to the right AND set bit15
        
        lda \SLOPE+2
        bne \@slope_is_64_or_higher
        lda \SLOPE+1
        cmp #64
        bcs \@slope_is_64_or_higher  ; if slope >= 64 then we want to shift 5 positions
        bra \@slope_is_correctly_packed
    \@slope_is_64_or_higher:

        ; We divide the slope by 32 (aka shifting 5 bits to the right)
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE

        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lsr \SLOPE+2
        ror \SLOPE+1
        ror \SLOPE
        
        lda \SLOPE+1
        ora #%10000000          ; we set bit 15 (here bit 7) to 1, to indicate the value has to be multiplied to x32 (inside of VERA)
        sta \SLOPE+1

\@slope_is_correctly_packed:

    .endif
    
.endmacro


MACRO_subtract_and_make_positive .macro POSITION_A, POSITION_B, DISTANCE, DISTANCE_IS_NEGATED
    
    stz \DISTANCE_IS_NEGATED
    
    ; We subtract: DISTANCE: POSITION_A - POSITION_B
    sec
    lda \POSITION_A
    sbc \POSITION_B
    sta \DISTANCE
    lda \POSITION_A+1
    sbc \POSITION_B+1
    sta \DISTANCE+1
    bpl \@distance_is_positive
    
    lda #1
    sta \DISTANCE_IS_NEGATED

    ; We negate the DISTANCE
    sec
    lda #0
    sbc \DISTANCE
    sta \DISTANCE
    lda #0
    sbc \DISTANCE+1
    sta \DISTANCE+1
    
\@distance_is_positive:

.endmacro


MACRO_subtract .macro POSITION_A, POSITION_B, DISTANCE

    ; We subtract: DISTANCE: POSITION_A - POSITION_B
    sec
    lda \POSITION_A
    sbc \POSITION_B
    sta \DISTANCE
    lda \POSITION_A+1
    sbc \POSITION_B+1
    sta \DISTANCE+1

.endmacro

MACRO_negate_slope .macro SLOPE
    
    .if(USE_POLYGON_FILLER)
        ; We need to preserve the x32 bit here!
        and #%10000000
        sta TMP2

        ; We unset the x32 (in case it was set) because we have to negate the number
        ; SPEED: can we use a different opcode here to unset the x32 bit?
        lda \SLOPE+1
        and #%01111111
        sta \SLOPE+1
    .endif
    
    sec
    lda #0
    sbc \SLOPE
    sta \SLOPE
    lda #0
    sbc \SLOPE+1
    .if(USE_POLYGON_FILLER)
        and #%01111111         ; Only keep the lower 7 bits
        ora TMP2               ; We restore the x32 bit
    .endif
    sta \SLOPE+1
    
    .if(!USE_POLYGON_FILLER)
        lda #0
        sbc \SLOPE+2
        sta \SLOPE+2
    .endif
    
.endmacro


MACRO_copy_slope_to_soft_incr_and_shift_right .macro SLOPE, SOFT_X_INCR, SOFT_X_INCR_SUB

; SPEED: can we do this faster? Maybe use 3 bytes and use a different slope lookup table?
; SPEED: the conditional sign extend is also slow!
    lda \SLOPE+2
    bpl \@slope_is_positive
    lsr a
    ora #%10000000
    bra \@slope_is_correctly_signed
\@slope_is_positive:
    lsr a
\@slope_is_correctly_signed:
    sta \SOFT_X_INCR+1       ; X1 or X2 increment high (signed)
    lda \SLOPE+1
    ror a
    sta \SOFT_X_INCR         ; X1 or X2 increment low (signed)
    lda \SLOPE  
    ror a
    sta \SOFT_X_INCR_SUB+1   ; X1 or X2 increment sub high (signed)                
    lda #0
    ror a
    sta \SOFT_X_INCR_SUB     ; X1 or X2 increment sub low (signed)

.endmacro


MACRO_set_address_using_y2address_table .macro POINT_Y
    
    ; TODO: we limit the y-coordinate to 1 byte (so max 255 right now)
    ldx \POINT_Y
    
    lda Y_TO_ADDRESS_LOW, x
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH, x
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK, x     ; This will include the auto-increment of 320 byte
    sta VERA_ADDR_BANK
    
.endmacro

MACRO_set_address_using_y2address_table_and_point_x .macro POINT_Y, POINT_X
    
    ; TODO: we limit the y-coordinate to 1 byte (so max 255 right now)
    ldx \POINT_Y
    
    clc
    lda Y_TO_ADDRESS_LOW, x
    adc \POINT_X
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH, x
    adc \POINT_X+1
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK, x     ; This will include the auto-increment of 1 byte
    adc #0
    sta VERA_ADDR_BANK
    
.endmacro

MACRO_set_address_using_multiplication .macro POINT_Y

    ; SPEED: we should do this *much* earlier and not for every triangle!
    lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
    sta VERA_ADDR_BANK
    
    ; -- THIS IS SLOW! --
    ; We need to multiply the Y-coordinate with 320
    lda \POINT_Y
    sta MULTIPLICAND
    lda \POINT_Y+1
    sta MULTIPLICAND+1
    
    lda #<320
    sta MULTIPLIER
    lda #>320
    sta MULTIPLIER+1
    
    jsr multply_16bits
    
    ; HACK: we are assuming our bitmap address starts at 00000 here! AND we assume we never exceed 64kB!! (bit16 is always assumed to be 0)
    ; Note: we are setting ADDR0 to the left most pixel of a pixel row. This means it will be aligned to 4-bytes (which is needed for the polygon filler to work nicely).
    lda PRODUCT+1
    sta VERA_ADDR_HIGH
    lda PRODUCT
    sta VERA_ADDR_LOW

.endmacro

    
draw_triangle_with_single_top_point:

    ; Note: we can assume here that:
    ;  - the triangle has a single top point, its coordinate is in: TOP_POINT_X/TOP_POINT_Y
    ;  - the triangle has a left-bottom point, its coordinate is on: LEFT_POINT_X/LEFT_POINT_Y
    ;  - the triangle has a right-bottom point, its coordinate is on: RIGHT_POINT_X/RIGHT_POINT_Y
    ;  - the color of the triangle is in: TRIANGLE_COLOR

    ; We need to calculate 3 slopes for the 2 triangle parts:
    ;  - the slope between TOP and LEFT
    ;  - the slope between TOP and RIGHT
    ;  - the slope between LEFT and RIGHT or RIGHT and LEFT (depending which one is higher in y)
    
    ; IMPORTANT: be careful with LEFT and RIGHT slope: if they at the same Y you shoud *not* divide/determine the slope, but *stop* instead.
    
    ; About slopes:
    ;  - slopes are up to 15+5=20 bits (signed) numbers: ranging from +-1024 pixels/2 down to +-(1/512th of a pixel)/2
    ;  - slopes are *half* the actual slope between two point (since they are increment in 2 steps)
    ;  - slopes are packed into a signed 15 bit + 1 "times 32"-bit 

    ; SPEED: cant we and use only 1 byte for Y? (since Y < 240 pixels)
    
    ; ============== LEFT POINT vs TOP POINT ============
    
    ; We subtract: X_DISTANCE: LEFT_POINT_X - TOP_POINT_X
    
    MACRO_subtract_and_make_positive LEFT_POINT_X, TOP_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED
    
    ; We subtract: Y_DISTANCE_LEFT_TOP: LEFT_POINT_Y - TOP_POINT_Y
    
    MACRO_subtract LEFT_POINT_Y, TOP_POINT_Y, Y_DISTANCE_LEFT_TOP
    
    ; Note: since we know the top point has a lower y than the left point, there is no need to negate it!
    
    .if(USE_SLOPE_TABLES)
        MACRO_get_slope_from_slope_table Y_DISTANCE_LEFT_TOP, SLOPE_TOP_LEFT
    .else
        MACRO_calculate_slope_using_division Y_DISTANCE_LEFT_TOP, SLOPE_TOP_LEFT
    .endif
    
    ldx X_DISTANCE_IS_NEGATED
    beq slope_top_left_is_correctly_signed   ; if X_DISTANCE is not negated we dont have to negate now, otherwise we do

    MACRO_negate_slope SLOPE_TOP_LEFT
    
slope_top_left_is_correctly_signed:


    ; ============== RIGHT POINT vs TOP POINT ============

    ; We subtract: X_DISTANCE: RIGHT_POINT_X - TOP_POINT_X
    
    MACRO_subtract_and_make_positive RIGHT_POINT_X, TOP_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED    
    
    ; We subtract: Y_DISTANCE_RIGHT_TOP: RIGHT_POINT_Y - TOP_POINT_Y
    
    MACRO_subtract RIGHT_POINT_Y, TOP_POINT_Y, Y_DISTANCE_RIGHT_TOP
    
    ; Note: since we know the top point has a lower y than the right point, there is no need to negate it!
    
    .if(USE_SLOPE_TABLES)
        MACRO_get_slope_from_slope_table Y_DISTANCE_RIGHT_TOP, SLOPE_TOP_RIGHT
    .else
        MACRO_calculate_slope_using_division Y_DISTANCE_RIGHT_TOP, SLOPE_TOP_RIGHT
    .endif
    
    ldx X_DISTANCE_IS_NEGATED
    beq slope_top_right_is_correctly_signed   ; if X_DISTANCE is not negated we dont have to negate now, otherwise we do
    
    MACRO_negate_slope SLOPE_TOP_RIGHT
    
slope_top_right_is_correctly_signed:

    ; ============== RIGHT POINT vs LEFT POINT ============

    ; We subtract: X_DISTANCE: RIGHT_POINT_X - LEFT_POINT_X
    
    MACRO_subtract_and_make_positive RIGHT_POINT_X, LEFT_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED

    ; We subtract: Y_DISTANCE_RIGHT_LEFT: RIGHT_POINT_Y - LEFT_POINT_Y
    
    MACRO_subtract_and_make_positive RIGHT_POINT_Y, LEFT_POINT_Y, Y_DISTANCE_RIGHT_LEFT, Y_DISTANCE_IS_NEGATED
    
    .if(USE_SLOPE_TABLES)
        MACRO_get_slope_from_slope_table Y_DISTANCE_RIGHT_LEFT, SLOPE_RIGHT_LEFT
    .else
        MACRO_calculate_slope_using_division Y_DISTANCE_RIGHT_LEFT, SLOPE_RIGHT_LEFT
    .endif
    
    ldx X_DISTANCE_IS_NEGATED
    bne slope_right_left_is_negated_in_x
slope_right_left_is_not_negated_in_x:
    
    ldx Y_DISTANCE_IS_NEGATED
    beq slope_right_left_is_correctly_signed   ; if Y_DISTANCE is negated we have to negate now, otherwise we dont
    
    MACRO_negate_slope SLOPE_RIGHT_LEFT
    
    bra slope_right_left_is_correctly_signed
    
slope_right_left_is_negated_in_x:
    
    ldx Y_DISTANCE_IS_NEGATED
    bne slope_right_left_is_correctly_signed   ; if Y_DISTANCE is not negated we have to negate now, otherwise we dont
    
    MACRO_negate_slope SLOPE_RIGHT_LEFT

slope_right_left_is_correctly_signed:

    
    ; -- We setup the starting x and y and the color --
    .if(USE_POLYGON_FILLER)
        ; Setting up for drawing a polygon, setting both addresses at the same starting point

        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        .if(USE_Y_TO_ADDRESS_TABLE)
            MACRO_set_address_using_y2address_table TOP_POINT_Y
        .else
            MACRO_set_address_using_multiplication TOP_POINT_Y
        .endif
    
        ; SPEED: we should do this *much* earlier and not for every triangle!
        ; Entering *polygon fill mode*: from now on every read from DATA1 will increment x1 and x2, and ADDR1 will be filled with ADDR0 + x1
        lda #%00000011
        sta $9F29
        
        ; Setting x1 and x2 pixel position
        
        lda #%00001001           ; DCSEL=4, ADDRSEL=1
        sta VERA_CTRL
        
        lda TOP_POINT_X
        sta $9F29                ; X (=X1) pixel position low [7:0]
        sta $9F2B                ; Y (=X2) pixel position low [7:0]
        
        ; NOTE: we are also *setting* the subpixel position (bit0) here! Even though we just resetted it! 
        ;       but its ok, since its reset to half a pixel (see above), meaning bit0 is 0 anyway
        lda TOP_POINT_X+1
        sta $9F2A                ; X subpixel position[0] = 0, X (=X1) pixel position high [10:8]
        ora #%00100000           ; Reset subpixel position
        sta $9F2C                ; Y subpixel position[0] = 0, Y (=X2) pixel position high [10:8]

        ; SPEED: we should do this *much* earlier and not for every triangle!
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
    
        ldy TRIANGLE_COLOR      ; We use y as color
    .else 
    
        ; Setting up for drawing a polygon, setting both X1 and X2 positions at the same starting point
        
        ; Note: without the polygon filler helper we *only* use ADDR1, not ADDR0

        lda #%00000001           ; DCSEL=0, ADDRSEL=1
        sta VERA_CTRL

        ; Setting starting (sub)pixel position X1 and X2
        stz SOFT_X1_SUB          ; Reset subpixel position X1 [0]
        stz SOFT_X2_SUB          ; Reset subpixel position X2 [0]

        lda #(256>>1)            ; Half a pixel
        sta SOFT_X1_SUB+1        ; Reset subpixel position X1 [8:1]
        sta SOFT_X2_SUB+1        ; Reset subpixel position X2 [8:1]
        
        lda TOP_POINT_X
        sta SOFT_X1              ; X1 pixel position low [7:0]
        sta SOFT_X2              ; X2 pixel position low [7:0]
        
        lda TOP_POINT_X+1
        sta SOFT_X1+1            ; X1 pixel position high [10:8]
        sta SOFT_X2+1            ; X2 pixel position high [10:8]
        
        ; Starting Y
        lda TOP_POINT_Y
        sta SOFT_Y
        lda TOP_POINT_Y+1
        sta SOFT_Y+1
        
        ldy TRIANGLE_COLOR      ; We use y as color
        
; FIXME: for now we are resetting these here. Is this correct?
; FIXME: for now we are resetting these here. Is this correct?
; FIXME: for now we are resetting these here. Is this correct?
;        stz SOFT_X1_INCR_SUB
;        stz SOFT_X1_INCR+1
;        stz SOFT_X2_INCR_SUB
;        stz SOFT_X2_INCR+1
        
    .endif


    .if(USE_POLYGON_FILLER)

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL

        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_TOP_LEFT       ; X1 increment low (signed)
        sta $9F29
        lda SLOPE_TOP_LEFT+1     ; X1 increment high (signed)
        sta $9F2A

        lda SLOPE_TOP_RIGHT      ; X2 increment low (signed)
        sta $9F2B                
        lda SLOPE_TOP_RIGHT+1    ; X2 increment high (signed)
        sta $9F2C    
    
        ; We determine which of LEFT or RIGHT is lower in y and chose number of rows to that point
        lda Y_DISTANCE_IS_NEGATED
        bne first_right_point_is_lower_in_y
first_left_point_is_lower_in_y:
        lda Y_DISTANCE_LEFT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively

        lda Y_DISTANCE_RIGHT_LEFT
        beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        sta NUMBER_OF_ROWS
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
    ; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
        
        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_RIGHT_LEFT     ; X1 increment low
        sta $9F29
        lda SLOPE_RIGHT_LEFT+1   ; X1 increment high
        sta $9F2A

        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively

        bra done_drawing_polygon_part_single_top
first_right_point_is_lower_in_y:
        lda Y_DISTANCE_RIGHT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively

        lda Y_DISTANCE_RIGHT_LEFT
        beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        sta NUMBER_OF_ROWS
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
    ; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
        
        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_RIGHT_LEFT     ; X2 increment low
        sta $9F2B                
        lda SLOPE_RIGHT_LEFT+1   ; X2 increment high
        sta $9F2C
        
        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively
        
    .else
    
        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_TOP_LEFT, SOFT_X1_INCR, SOFT_X1_INCR_SUB
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_TOP_RIGHT, SOFT_X2_INCR, SOFT_X2_INCR_SUB

        ; We determine which of LEFT or RIGHT is lower in y and chose number of rows to that point
        lda Y_DISTANCE_IS_NEGATED
        bne soft_first_right_point_is_lower_in_y
soft_first_left_point_is_lower_in_y:
        lda Y_DISTANCE_LEFT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively

        lda Y_DISTANCE_RIGHT_LEFT
        beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        sta NUMBER_OF_ROWS
        
    ; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_RIGHT_LEFT, SOFT_X1_INCR, SOFT_X1_INCR_SUB

        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively

        bra done_drawing_polygon_part_single_top
soft_first_right_point_is_lower_in_y:
        lda Y_DISTANCE_RIGHT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively

        lda Y_DISTANCE_RIGHT_LEFT
        beq done_drawing_polygon_part_single_top   ; The left and right point are at the same y-coordinate, so there is nothing left to draw.
        sta NUMBER_OF_ROWS
        
    ; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_RIGHT_LEFT, SOFT_X2_INCR, SOFT_X2_INCR_SUB
        
        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively
    .endif
        
done_drawing_polygon_part_single_top:
    
    jmp done_drawing_polygon_part
    
    
draw_triangle_with_double_top_points:

    ; Note: we can assume here that:
    ;  - the triangle has a left-top point, its coordinate is on: LEFT_POINT_X/LEFT_POINT_Y
    ;  - the triangle has a right-top point, its coordinate is on: RIGHT_POINT_X/RIGHT_POINT_Y
    ;  - the left-top point and right-top point have the same y-coordinate
    ;  - the triangle has a single bottom point, its coordinate is in: BOTTOM_POINT_X/BOTTOM_POINT_Y
    ;  - the color of the triangle is in: TRIANGLE_COLOR

    ; We need to calculate 2 slopes for the 1 triangle part:
    ;  - the slope between LEFT and BOTTOM
    ;  - the slope between RIGHT and BOTTOM
    
    ; About slopes:
    ;  - slopes are up to 15+5=20 bits (signed) numbers: ranging from +-1024 pixels/2 down to +-(1/512th of a pixel)/2
    ;  - slopes are *half* the actual slope between two point (since they are increment in 2 steps)
    ;  - slopes are packed into a signed 15 bit + 1 "times 32"-bit 

    ; SPEED: cant we and use only 1 byte for Y? (since Y < 240 pixels)
    
    ; ============== BOTTOM POINT vs LEFT POINT ============
    
    ; We subtract: X_DISTANCE:  BOTTOM_POINT_X - LEFT_POINT_X
    
    MACRO_subtract_and_make_positive BOTTOM_POINT_X, LEFT_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED
    
    ; We subtract: Y_DISTANCE_BOTTOM_LEFT: BOTTOM_POINT_Y - LEFT_POINT_Y
    
    MACRO_subtract BOTTOM_POINT_Y, LEFT_POINT_Y, Y_DISTANCE_BOTTOM_LEFT
    
    ; Note: since we know the left point has a lower y than the bottom point, there is no need to negate it!
    
    .if(USE_SLOPE_TABLES)
        MACRO_get_slope_from_slope_table Y_DISTANCE_BOTTOM_LEFT, SLOPE_LEFT_BOTTOM
    .else
        MACRO_calculate_slope_using_division Y_DISTANCE_BOTTOM_LEFT, SLOPE_LEFT_BOTTOM
    .endif
    
    ldx X_DISTANCE_IS_NEGATED
    beq slope_left_bottom_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
    
    MACRO_negate_slope SLOPE_LEFT_BOTTOM
    
slope_left_bottom_is_correctly_signed:


    ; ============== BOTTOM POINT vs RIGHT POINT ============

    ; We subtract: X_DISTANCE: BOTTOM_POINT_X - RIGHT_POINT_X
    
    MACRO_subtract_and_make_positive BOTTOM_POINT_X, RIGHT_POINT_X, X_DISTANCE, X_DISTANCE_IS_NEGATED    
    
    ; We subtract: Y_DISTANCE_BOTTOM_RIGHT: BOTTOM_POINT_Y - RIGHT_POINT_Y
    
    MACRO_subtract BOTTOM_POINT_Y, RIGHT_POINT_Y, Y_DISTANCE_BOTTOM_RIGHT
    
    ; Note: since we know the right point has a lower y than the bottom point, there is no need to negate it!
    
    .if(USE_SLOPE_TABLES)
        MACRO_get_slope_from_slope_table Y_DISTANCE_BOTTOM_RIGHT, SLOPE_RIGHT_BOTTOM
    .else
        MACRO_calculate_slope_using_division Y_DISTANCE_BOTTOM_RIGHT, SLOPE_RIGHT_BOTTOM
    .endif
    
    ldx X_DISTANCE_IS_NEGATED
    beq slope_right_bottom_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
    
    MACRO_negate_slope SLOPE_RIGHT_BOTTOM
    
slope_right_bottom_is_correctly_signed:

    
    ; -- We setup the starting x and y and the color --
    .if(USE_POLYGON_FILLER)
        ; Setting up for drawing a polygon, setting both addresses at the same starting point

        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        .if(USE_Y_TO_ADDRESS_TABLE)
            MACRO_set_address_using_y2address_table LEFT_POINT_Y
        .else
            MACRO_set_address_using_multiplication LEFT_POINT_Y
        .endif
    
        ; SPEED: we should do this *much* earlier and not for every triangle!
        ; Entering *polygon fill mode*: from now on every read from DATA1 will increment x1 and x2, and ADDR1 will be filled with ADDR0 + x1
        lda #%00000011
        sta $9F29
        
        ; Setting x1 and x2 pixel position
        
        lda #%00001001           ; DCSEL=4, ADDRSEL=1
        sta VERA_CTRL
        
        lda LEFT_POINT_X
        sta $9F29                ; X (=X1) pixel position low [7:0]
        lda RIGHT_POINT_X
        sta $9F2B                ; Y (=X2) pixel position low [7:0]
        
        ; NOTE: we are also *setting* the subpixel position (bit0) here! Even though we just resetted it! 
        ;       but its ok, since its reset to half a pixel (see above), meaning bit0 is 0 anyway
        lda LEFT_POINT_X+1
        sta $9F2A                ; X subpixel position[0] = 0, X (=X1) pixel position high [10:8]
        lda RIGHT_POINT_X+1
        ora #%00100000           ; Reset subpixel position
        sta $9F2C                ; Y subpixel position[0] = 0, Y (=X2) pixel position high [10:8]

        ; SPEED: we should do this *much* earlier and not for every triangle!
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
    
        ldy TRIANGLE_COLOR      ; We use y as color
    .else 
    
        ; Setting up for drawing a polygon, setting both X1 and X2 positions at the same starting point
        
        ; Note: without the polygon filler helper we *only* use ADDR1, not ADDR0

        lda #%00000001           ; DCSEL=0, ADDRSEL=1
        sta VERA_CTRL

        ; Setting starting (sub)pixel position X1 and X2
        stz SOFT_X1_SUB          ; Reset subpixel position X1 [0]
        stz SOFT_X2_SUB          ; Reset subpixel position X2 [0]

        lda #(256>>1)            ; Half a pixel
        sta SOFT_X1_SUB+1        ; Reset subpixel position X1 [8:1]
        sta SOFT_X2_SUB+1        ; Reset subpixel position X2 [8:1]
        
        lda LEFT_POINT_X
        sta SOFT_X1              ; X1 pixel position low [7:0]
        lda RIGHT_POINT_X
        sta SOFT_X2              ; X2 pixel position low [7:0]
        
        lda LEFT_POINT_X+1
        sta SOFT_X1+1            ; X1 pixel position high [10:8]
        lda RIGHT_POINT_X+1
        sta SOFT_X2+1            ; X2 pixel position high [10:8]
        
        ; Starting Y
        lda LEFT_POINT_Y
        sta SOFT_Y
        lda LEFT_POINT_Y+1
        sta SOFT_Y+1
        
        ldy TRIANGLE_COLOR      ; We use y as color
        
; FIXME: for now we are resetting these here. Is this correct?
; FIXME: for now we are resetting these here. Is this correct?
; FIXME: for now we are resetting these here. Is this correct?
;        stz SOFT_X1_INCR_SUB
;        stz SOFT_X1_INCR+1
;        stz SOFT_X2_INCR_SUB
;        stz SOFT_X2_INCR+1
        
    .endif


    .if(USE_POLYGON_FILLER)

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL

        ; NOTE that these increments are *HALF* steps!!
        lda SLOPE_LEFT_BOTTOM    ; X1 increment low (signed)
        sta $9F29
        lda SLOPE_LEFT_BOTTOM+1  ; X1 increment high (signed)
        sta $9F2A

        lda SLOPE_RIGHT_BOTTOM   ; X2 increment low (signed)
        sta $9F2B                
        lda SLOPE_RIGHT_BOTTOM+1 ; X2 increment high (signed)
        sta $9F2C    
    
        lda Y_DISTANCE_LEFT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first (and only) part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively
        
    .else

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        ; NOTE that these increments are *HALF* steps!!
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_LEFT_BOTTOM, SOFT_X1_INCR, SOFT_X1_INCR_SUB
        MACRO_copy_slope_to_soft_incr_and_shift_right SLOPE_RIGHT_BOTTOM, SOFT_X2_INCR, SOFT_X2_INCR_SUB
    
        lda Y_DISTANCE_LEFT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first (and only) part of the triangle --
        jsr draw_polygon_part_using_software_polygon_filler_naively
        
    .endif
        
    jmp done_drawing_polygon_part
    
    

    
draw_polygon_part_using_software_polygon_filler_naively:

    ; First we will increment x1 and x2 with *HALF* the normal increment
    
    clc
    lda SOFT_X1_SUB
    adc SOFT_X1_INCR_SUB
    sta SOFT_X1_SUB
    lda SOFT_X1_SUB+1
    adc SOFT_X1_INCR_SUB+1
    sta SOFT_X1_SUB+1
    lda SOFT_X1
    adc SOFT_X1_INCR
    sta SOFT_X1
    lda SOFT_X1+1
    adc SOFT_X1_INCR+1
    sta SOFT_X1+1
    
    clc
    lda SOFT_X2_SUB
    adc SOFT_X2_INCR_SUB
    sta SOFT_X2_SUB
    lda SOFT_X2_SUB+1
    adc SOFT_X2_INCR_SUB+1
    sta SOFT_X2_SUB+1
    lda SOFT_X2
    adc SOFT_X2_INCR
    sta SOFT_X2
    lda SOFT_X2+1
    adc SOFT_X2_INCR+1
    sta SOFT_X2+1

    
soft_polygon_fill_triangle_row_next:

    .if(USE_Y_TO_ADDRESS_TABLE)
        MACRO_set_address_using_y2address_table_and_point_x SOFT_Y, SOFT_X1
    .else
        MACRO_set_address_using_multiplication_and_point_x SOFT_Y, SOFT_X1
    .endif
    
;    sty VERA_DATA1
;    
;    .if(USE_Y_TO_ADDRESS_TABLE)
;        MACRO_set_address_using_y2address_table_and_point_x SOFT_Y, SOFT_X2
;    .else
;        MACRO_set_address_using_multiplication_and_point_x SOFT_Y, SOFT_X2
;    .endif
;    
;    sty VERA_DATA1
    
    sec
    lda SOFT_X2
    sbc SOFT_X1
    sta FILL_LENGTH_LOW
    lda SOFT_X2+1
    sbc SOFT_X1+1
    sta FILL_LENGTH_HIGH
    
    ldx FILL_LENGTH_LOW
    
    ; FIXME: should we do this +1 here or inside of VERA? -> note: when x = 255, 256 pixels will be drawn (which is what we want right now)
;    inx

    ; If x = 0, we dont have to draw any pixels
    beq soft_done_fill_triangle_pixel_0
soft_polygon_fill_triangle_pixel_next_0:    
    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
    sty VERA_DATA1
    dex
    bne soft_polygon_fill_triangle_pixel_next_0

soft_done_fill_triangle_pixel_0:
    ; We draw an additional FILL_LENGTH_HIGH * 256 pixels on this row
    lda FILL_LENGTH_HIGH
    beq soft_polygon_fill_triangle_row_done

    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
soft_polygon_fill_triangle_pixel_next_256:
    ldx #0
soft_polygon_fill_triangle_pixel_next_256_0:
    sty VERA_DATA1
    dex
    bne soft_polygon_fill_triangle_pixel_next_256_0
    dec FILL_LENGTH_HIGH
    bne soft_polygon_fill_triangle_pixel_next_256
    
soft_polygon_fill_triangle_row_done:
    
    ; We always increment SOFT_Y
    inc SOFT_Y
    ; FIXME: we are now assuming a max value of 240, so no need for SOFT_Y+1

    clc
    lda SOFT_X1_SUB
    adc SOFT_X1_INCR_SUB
    sta SOFT_X1_SUB
    lda SOFT_X1_SUB+1
    adc SOFT_X1_INCR_SUB+1
    sta SOFT_X1_SUB+1
    lda SOFT_X1
    adc SOFT_X1_INCR
    sta SOFT_X1
    lda SOFT_X1+1
    adc SOFT_X1_INCR+1
    sta SOFT_X1+1
    
    clc
    lda SOFT_X2_SUB
    adc SOFT_X2_INCR_SUB
    sta SOFT_X2_SUB
    lda SOFT_X2_SUB+1
    adc SOFT_X2_INCR_SUB+1
    sta SOFT_X2_SUB+1
    lda SOFT_X2
    adc SOFT_X2_INCR
    sta SOFT_X2
    lda SOFT_X2+1
    adc SOFT_X2_INCR+1
    sta SOFT_X2+1
    
    ; We check if we have reached the end, if so, we do *NOT* change ADDR1!
    dec NUMBER_OF_ROWS
    beq soft_polygon_fill_triangle_done
    
; FIXME!   
;    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1

    clc
    lda SOFT_X1_SUB
    adc SOFT_X1_INCR_SUB
    sta SOFT_X1_SUB
    lda SOFT_X1_SUB+1
    adc SOFT_X1_INCR_SUB+1
    sta SOFT_X1_SUB+1
    lda SOFT_X1
    adc SOFT_X1_INCR
    sta SOFT_X1
    lda SOFT_X1+1
    adc SOFT_X1_INCR+1
    sta SOFT_X1+1
    
    clc
    lda SOFT_X2_SUB
    adc SOFT_X2_INCR_SUB
    sta SOFT_X2_SUB
    lda SOFT_X2_SUB+1
    adc SOFT_X2_INCR_SUB+1
    sta SOFT_X2_SUB+1
    lda SOFT_X2
    adc SOFT_X2_INCR
    sta SOFT_X2
    lda SOFT_X2+1
    adc SOFT_X2_INCR+1
    sta SOFT_X2+1

    jmp soft_polygon_fill_triangle_row_next
    
soft_polygon_fill_triangle_done:
    
    
    rts


draw_polygon_part_using_polygon_filler_naively:

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
;    inx
    
    ; If x = 0, we dont have to draw any pixels
    beq done_fill_triangle_pixel_0
polygon_fill_triangle_pixel_next_0:
    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
    sty VERA_DATA1
    dex
    bne polygon_fill_triangle_pixel_next_0

done_fill_triangle_pixel_0:
    ; We draw an additional FILL_LENGTH_HIGH * 256 pixels on this row
    lda FILL_LENGTH_HIGH
    beq polygon_fill_triangle_row_done

    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
polygon_fill_triangle_pixel_next_256:
    ldx #0
polygon_fill_triangle_pixel_next_256_0:
    sty VERA_DATA1
    dex
    bne polygon_fill_triangle_pixel_next_256_0
    dec FILL_LENGTH_HIGH
    bne polygon_fill_triangle_pixel_next_256
    
polygon_fill_triangle_row_done:
    
    ; We always increment ADDR0
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (= +1 vertically)
    
    ; We check if we have reached the end, if so, we do *NOT* change ADDR1!
    dec NUMBER_OF_ROWS
    beq polygon_fill_triangle_done
    
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    bra polygon_fill_triangle_row_next
    
polygon_fill_triangle_done:
    
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
    
    ; NOTE that these increments are *HALF* steps!!
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

    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
    
    ldy #TEST_FILL_COLOR     ; We use y as color

; FIXME: hardcoded!
    lda #150
    sta NUMBER_OF_ROWS
    
    jsr draw_polygon_part_using_polygon_filler_naively
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
    
    ; NOTE that these increments are *HALF* steps!!
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
    
    jsr draw_polygon_part_using_polygon_filler_naively
    
    rts

    
generate_y_to_address_table:

    ; TODO: we assume the base address is 0 here!
    stz VRAM_ADDRESS
    stz VRAM_ADDRESS+1
    stz VRAM_ADDRESS+2
    
    ldy #0
generate_next_y_to_address_entry:
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    sta Y_TO_ADDRESS_LOW, y
    
    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    sta Y_TO_ADDRESS_HIGH, y
    
    lda VRAM_ADDRESS+2
    adc #0
    sta VRAM_ADDRESS+2
    .if(USE_POLYGON_FILLER)
        ora #%11100000              ; For polygon filler helper: auto-increment = 320
    .else
        ora #%00010000              ; Without polygon filler helper: auto-increment = 1
    .endif
    sta Y_TO_ADDRESS_BANK, y
    
    iny
    
    cpy #240
    bne generate_next_y_to_address_entry

    rts
    
    
load_slopes_into_banked_ram:


    rts
    
    
    
; NOTE: we are now using ROM banks to contain tables. We need to copy those textures to Banked RAM, but have to run that copy-code in Fixed RAM.
    
copy_slope_table_copier_to_ram:

    ; Copying copy_slope_tables_to_banked_ram -> COPY_SLOPE_TABLES_TO_BANKED_RAM
    
    ldy #0
copy_tables_to_banked_ram_byte:
    lda copy_slope_tables_to_banked_ram, y
    sta COPY_SLOPE_TABLES_TO_BANKED_RAM, y
    iny 
    cpy #(end_of_copy_slope_tables_to_banked_ram-copy_slope_tables_to_banked_ram)
    bne copy_tables_to_banked_ram_byte

    rts
    
    
copy_slope_tables_to_banked_ram:

    ; We copy 10 tables to banked RAM, but we pack them in such a way that they are easily accessible

    lda #1               ; Our first tables starts at ROM Bank 1
    sta TABLE_ROM_BANK
    
next_table_to_copy:    
    lda #<($C000)        ; Our source table starts at C000
    sta LOAD_ADDRESS
    lda #>($C000)
    sta LOAD_ADDRESS+1

    lda #<($A000)        ; We store at Ax00
    sta STORE_ADDRESS
    
    clc
    lda #>($A000)
    adc TABLE_ROM_BANK
    sec
    sbc #1               ; since the TABLE_ROM_BANK starts at 1, we substract one from it
    sta STORE_ADDRESS+1

    ; Switching ROM BANK
    lda TABLE_ROM_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
        ldx #0                             ; x = x-coordinate (within a column of 64)
next_x_to_copy_to_banked_ram:
        ; Switching to RAM BANK x
        stx RAM_BANK
    ; FIXME: remove nop!
        nop
        
        ldy #0                             ; y = y-coordinate (0-239)
next_byte_to_copy_to_banked_ram:
        lda (LOAD_ADDRESS), y
        sta (STORE_ADDRESS), y
        iny
        cpy #240
        bne next_byte_to_copy_to_banked_ram
        
        ; We increment LOAD_ADDRESS by 256 bytes to move to the next x  (there is 240 bytes of data + 16 bytes of padding for each x)
        clc
        lda LOAD_ADDRESS
        adc #<256
        sta LOAD_ADDRESS
        lda LOAD_ADDRESS+1
        adc #>256
        sta LOAD_ADDRESS+1
        
        inx
        cpx #64
        bne next_x_to_copy_to_banked_ram

    inc TABLE_ROM_BANK
    lda TABLE_ROM_BANK
    cmp #11               ; we go from 1-10 so we need to stop at 11
    bne next_table_to_copy

    ; Switching back to ROM bank 0
    lda #$00
    sta ROM_BANK
; FIXME: remove nop!
    nop
   
    rts
end_of_copy_slope_tables_to_banked_ram:

    
    
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


    
    
copy_palette_from_index_16:

    ; Starting at palette VRAM address

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<(VERA_PALETTE+2*16)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE+2*16)
    sta VERA_ADDR_HIGH

    ldy #0
next_packed_color:
    lda palette_data, y
    sta VERA_DATA0
    iny
    cpy #(end_of_palette_data-palette_data)
    bne next_packed_color

    rts

    
    
; =========== FIXME: put this somewhere else! ==============
; https://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product
multply_16bits:
    phx
    lda    #$00
    sta    PRODUCT+2    ; clear upper bits of PRODUCT
    sta    PRODUCT+3
    ldx    #$10         ; set binary count to 16
shift_r:
    lsr    MULTIPLIER+1 ; divide MULTIPLIER by 2
    ror    MULTIPLIER
    bcc    rotate_r
    lda    PRODUCT+2    ; get upper half of PRODUCT and add MULTIPLICAND
    clc
    adc    MULTIPLICAND
    sta    PRODUCT+2
    lda    PRODUCT+3
    adc    MULTIPLICAND+1
rotate_r:
    ror                 ; rotate partial PRODUCT
    sta    PRODUCT+3
    ror    PRODUCT+2
    ror    PRODUCT+1
    ror    PRODUCT
    dex
    bne    shift_r
    plx

    rts
    
; FIXME: put this somewhere else!
; https://codebase64.org/doku.php?id=base:24bit_division_24-bit_result
divide_24bits:
    phx
    phy

    lda #0            ; preset REMAINDER to 0
    sta REMAINDER
    sta REMAINDER+1
    sta REMAINDER+2
    ldx #24            ; repeat for each bit: ...

div24loop:
    asl DIVIDEND    ; DIVIDEND lb & hb*2, msb -> Carry
    rol DIVIDEND+1
    rol DIVIDEND+2
    rol REMAINDER    ; REMAINDER lb & hb * 2 + msb from carry
    rol REMAINDER+1
    rol REMAINDER+2
    lda REMAINDER
    sec
    sbc DIVISOR        ; substract DIVISOR to see if it fits in
    tay                ; lb result -> Y, for we may need it later
    lda REMAINDER+1
    sbc DIVISOR+1
    sta TMP1
    lda REMAINDER+2
    sbc DIVISOR+2
    bcc div24skip     ; if carry=0 then DIVISOR didnt fit in yet

    sta REMAINDER+2 ; else save substraction result as new REMAINDER,
    lda TMP1
    sta REMAINDER+1
    sty REMAINDER
    inc DIVIDEND    ; and INCrement result cause DIVISOR fit in 1 times

div24skip:
    dex
    bne div24loop

    ply
    plx
    rts
; =========== / FIXME: put this somewhere else! ==============
    
    
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

    .if(USE_SLOPE_TABLES)
    .binary "special_tests/tables/slopes_column_0_low.bin"
    .binary "special_tests/tables/slopes_column_0_high.bin"
    .binary "special_tests/tables/slopes_column_1_low.bin"
    .binary "special_tests/tables/slopes_column_1_high.bin"
    .binary "special_tests/tables/slopes_column_2_low.bin"
    .binary "special_tests/tables/slopes_column_2_high.bin"
    .binary "special_tests/tables/slopes_column_3_low.bin"
    .binary "special_tests/tables/slopes_column_3_high.bin"
    .binary "special_tests/tables/slopes_column_4_low.bin"
    .binary "special_tests/tables/slopes_column_4_high.bin"
    .endif
