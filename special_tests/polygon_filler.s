
DO_SPEED_TEST = 1
USE_POLYGON_FILLER = 1
USE_SLOPE_TABLES = 1
USE_UNROLLED_LOOP = 0
USE_JUMP_TABLE = 0
USE_WRITE_CACHE = 0


    .if (USE_POLYGON_FILLER)
BACKGROUND_COLOR = 251  ; Nice purple
    .else
BACKGROUND_COLOR = 06  ; Blue 
    .endif
    
COLOR_CHECK        = $05 ; Background color = 0, foreground color 5 (green)
COLOR_CROSS        = $02 ; Background color = 0, foreground color 2 (red)

NR_OF_TRIANGLES_TO_DRAW = 1
    
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

TABLE_ROM_BANK            = $46

; Polygon filler
NUMBER_OF_ROWS             = $40
FILL_LENGTH_LOW            = $41
FILL_LENGTH_HIGH           = $42
X1_THREE_LOWER_BITS        = $43

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
Y_DISTANCE_RIGHT_TOP     = $65 ; 66
Y_DISTANCE_RIGHT_LEFT    = $67 ; 68
Y_DISTANCE_LEFT_RIGHT = Y_DISTANCE_RIGHT_LEFT
Y_DISTANCE_IS_NEGATED    = $69
SLOPE_TOP_LEFT           = $6A ; 6B ; 6C   ; TODO: do we really need 24 bits here?
SLOPE_TOP_RIGHT          = $6D ; 6E ; 6F   ; TODO: do we really need 24 bits here?
SLOPE_LEFT_RIGHT         = $70 ; 71 ; 72   ; TODO: do we really need 24 bits here?
SLOPE_RIGHT_LEFT = SLOPE_LEFT_RIGHT


Y_DISTANCE_FIRST         = $76 ; 77
Y_DISTANCE_SECOND        = $78 ; 79

VRAM_ADDRESS             = $80 ; 81 ; 82

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

    jsr generate_clear_column_code
    jsr clear_screen_fast_4_bytes
    
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
    .asciiz "Filling a rectangle with triangles"
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

    
    
triangles_points:
    ;        x ,     y
   .word BX+ 20, BY+  0   ; TOP POINT
   .word BX+  0, BY+ 50   ; LEFT POINT
   .word BX+100, BY+ 120   ; RIGHT POINT
    
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
    
    ; -- TOP POINT --
    lda triangles_points
    sta TOP_POINT_X
    lda triangles_points+1
    sta TOP_POINT_X+1
    
    lda triangles_points+2
    sta TOP_POINT_Y
    lda triangles_points+3
    sta TOP_POINT_Y+1

    ; -- LEFT POINT --
    lda triangles_points+4
    sta LEFT_POINT_X
    lda triangles_points+5
    sta LEFT_POINT_X+1
    
    lda triangles_points+6
    sta LEFT_POINT_Y
    lda triangles_points+7
    sta LEFT_POINT_Y+1

    ; -- RIGHT POINT --
    lda triangles_points+8
    sta RIGHT_POINT_X
    lda triangles_points+9
    sta RIGHT_POINT_X+1
    
    lda triangles_points+10
    sta RIGHT_POINT_Y
    lda triangles_points+11
    sta RIGHT_POINT_Y+1
    
    lda triangles_colors
    sta TRIANGLE_COLOR
    
    jsr draw_triangle_with_single_top_point
    
    
    ; Turning off polygon filler mode
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    ; Normal addr1 mode
    lda #%00000000
    sta $9F29
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
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

    
    ; ============== LEFT POINT vs TOP POINT ============
    
    stz X_DISTANCE_IS_NEGATED
    
    ; We subtract: X_DISTANCE: LEFT_POINT_X - TOP_POINT_X
    sec
    lda LEFT_POINT_X
    sbc TOP_POINT_X
    sta X_DISTANCE
    lda LEFT_POINT_X+1
    sbc TOP_POINT_X+1
    sta X_DISTANCE+1
    bpl x_distance_left_top_is_positive
    
    lda #1
    sta X_DISTANCE_IS_NEGATED

    ; We negate the X_DISTANCE
    sec
    lda #0
    sbc X_DISTANCE
    sta X_DISTANCE
    lda #0
    sbc X_DISTANCE+1
    sta X_DISTANCE+1
    
x_distance_left_top_is_positive:

    ; We subtract: Y_DISTANCE_LEFT_TOP: LEFT_POINT_Y - TOP_POINT_Y
    lda LEFT_POINT_Y
    sbc TOP_POINT_Y
    sta Y_DISTANCE_LEFT_TOP
    lda LEFT_POINT_Y+1
    sbc TOP_POINT_Y+1
    sta Y_DISTANCE_LEFT_TOP+1
    
    ; Note: since we know the top point has a lower y than the left point, there is no need to negate it!
    
y_distance_left_top_is_positive:
    
    .if(USE_SLOPE_TABLES)
        ; We get the SLOPE from the slope table. We need:
        ;   y = Y_DISTANCE_LEFT_TOP
        ;   RAM_BANK = X_DISTANCE[5:0]
        ;   ADDR_HIGH[3:1] = X_DISTANCE[8:6]
        
        ldy Y_DISTANCE_LEFT_TOP
        
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
        sta SLOPE_TOP_LEFT
        
        ; We load the SLOPE_HIGH
        inc LOAD_ADDRESS+1
        lda (LOAD_ADDRESS), y
        sta SLOPE_TOP_LEFT+1
    
        ldx X_DISTANCE_IS_NEGATED
        beq slope_top_left_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
        
        ; We need to preserve the x32 bit here!
        and #%10000000
        sta TMP2

        ; We unset the x32 (in case it was set) because we have to negate the number
        ; SPEED: can we use a different opcode here to unset the x32 bit?
        lda SLOPE_TOP_LEFT+1
        and #%01111111
        sta SLOPE_TOP_LEFT+1
        
        sec
        lda #0
        sbc SLOPE_TOP_LEFT
        sta SLOPE_TOP_LEFT
        lda #0
        sbc SLOPE_TOP_LEFT+1
        and #%01111111         ; Only keep the lower 7 bits
        ora TMP2               ; We restore the x32 bit
        sta SLOPE_TOP_LEFT+1
    
    .else
        ; We do the divide: X_DISTANCE * 256 / Y_DISTANCE_LEFT_TOP
        lda X_DISTANCE+1
        sta DIVIDEND+2
        lda X_DISTANCE
        sta DIVIDEND+1
        lda #0
        sta DIVIDEND

        lda #0
        sta DIVISOR+2
        lda Y_DISTANCE_LEFT_TOP+1
        sta DIVISOR+1
        lda Y_DISTANCE_LEFT_TOP
        sta DIVISOR

        jsr divide_24bits
        
        lda DIVIDEND+2
        sta SLOPE_TOP_LEFT+2
        lda DIVIDEND+1
        sta SLOPE_TOP_LEFT+1
        lda DIVIDEND
        sta SLOPE_TOP_LEFT
        
        ldx X_DISTANCE_IS_NEGATED
        beq slope_top_left_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
        
        sec
        lda #0
        sbc SLOPE_TOP_LEFT
        sta SLOPE_TOP_LEFT
        lda #0
        sbc SLOPE_TOP_LEFT+1
        sta SLOPE_TOP_LEFT+1
        lda #0
        sbc SLOPE_TOP_LEFT+2
        sta SLOPE_TOP_LEFT+2

        ; FIXME: since we just negated, we unset bit15, but we should set bit15 properly
        lda SLOPE_TOP_LEFT+1
        and #%01111111           ; increment is only 15-bits long
        sta SLOPE_TOP_LEFT+1
    .endif
    
slope_top_left_is_correctly_signed:


    ; ============== RIGHT POINT vs TOP POINT ============

    stz X_DISTANCE_IS_NEGATED
    
    ; We subtract: X_DISTANCE: RIGHT_POINT_X - TOP_POINT_X
    sec
    lda RIGHT_POINT_X
    sbc TOP_POINT_X
    sta X_DISTANCE
    lda RIGHT_POINT_X+1
    sbc TOP_POINT_X+1
    sta X_DISTANCE+1
    bpl x_distance_right_top_is_positive
    
    lda #1
    sta X_DISTANCE_IS_NEGATED

    ; We negate the X_DISTANCE
    sec
    lda #0
    sbc X_DISTANCE
    sta X_DISTANCE
    lda #0
    sbc X_DISTANCE+1
    sta X_DISTANCE+1
    
x_distance_right_top_is_positive:

    ; We subtract: Y_DISTANCE_RIGHT_TOP: RIGHT_POINT_Y - TOP_POINT_Y
    lda RIGHT_POINT_Y
    sbc TOP_POINT_Y
    sta Y_DISTANCE_RIGHT_TOP
    lda RIGHT_POINT_Y+1
    sbc TOP_POINT_Y+1
    sta Y_DISTANCE_RIGHT_TOP+1
    
    ; Note: since we know the top point has a lower y than the right point, there is no need to negate it!
    
y_distance_right_top_is_positive:
    
    
    .if(USE_SLOPE_TABLES)
        ; We get the SLOPE from the slope table. We need:
        ;   y = Y_DISTANCE_RIGHT_TOP
        ;   RAM_BANK = X_DISTANCE[5:0]
        ;   ADDR_HIGH[3:1] = X_DISTANCE[8:6]
        
        ldy Y_DISTANCE_RIGHT_TOP
        
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
        sta SLOPE_TOP_RIGHT
        
        ; We load the SLOPE_HIGH
        inc LOAD_ADDRESS+1
        lda (LOAD_ADDRESS), y
        sta SLOPE_TOP_RIGHT+1
    
        ldx X_DISTANCE_IS_NEGATED
        beq slope_top_right_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
        
        ; We need to preserve the x32 bit here!
        and #%10000000
        sta TMP2

        ; We unset the x32 (in case it was set) because we have to negate the number
        ; SPEED: can we use a different opcode here to unset the x32 bit?
        lda SLOPE_TOP_RIGHT+1
        and #%01111111
        sta SLOPE_TOP_RIGHT+1
        
        sec
        lda #0
        sbc SLOPE_TOP_RIGHT
        sta SLOPE_TOP_RIGHT
        lda #0
        sbc SLOPE_TOP_RIGHT+1
        and #%01111111         ; Only keep the lower 7 bits
        ora TMP2               ; We restore the x32 bit
        sta SLOPE_TOP_RIGHT+1
    
    .else
        ; We do the divide: X_DISTANCE * 256 / Y_DISTANCE_RIGHT_TOP
        lda X_DISTANCE+1
        sta DIVIDEND+2
        lda X_DISTANCE
        sta DIVIDEND+1
        lda #0
        sta DIVIDEND

        lda #0
        sta DIVISOR+2
        lda Y_DISTANCE_RIGHT_TOP+1
        sta DIVISOR+1
        lda Y_DISTANCE_RIGHT_TOP
        sta DIVISOR

        jsr divide_24bits
        
        lda DIVIDEND+2
        sta SLOPE_TOP_RIGHT+2
        lda DIVIDEND+1
        sta SLOPE_TOP_RIGHT+1
        lda DIVIDEND
        sta SLOPE_TOP_RIGHT
        
        ldx X_DISTANCE_IS_NEGATED
        beq slope_top_right_is_correctly_signed   ; if X_DISTANCE is negated we dont have to negate now, otherwise we do
        
        sec
        lda #0
        sbc SLOPE_TOP_RIGHT
        sta SLOPE_TOP_RIGHT
        lda #0
        sbc SLOPE_TOP_RIGHT+1
        sta SLOPE_TOP_RIGHT+1
        lda #0
        sbc SLOPE_TOP_RIGHT+2
        sta SLOPE_TOP_RIGHT+2
        
        ; FIXME: since we just negated, we unset bit15, but we should set bit15 properly
        lda SLOPE_TOP_RIGHT+1
        and #%01111111           ; increment is only 15-bits long
        sta SLOPE_TOP_RIGHT+1
    .endif
    
slope_top_right_is_correctly_signed:


    ; ============== RIGHT POINT vs LEFT POINT ============

    stz Y_DISTANCE_IS_NEGATED
    
    ; We subtract: X_DISTANCE: RIGHT_POINT_X - LEFT_POINT_X
    sec
    lda RIGHT_POINT_X
    sbc LEFT_POINT_X
    sta X_DISTANCE
    lda RIGHT_POINT_X+1
    sbc LEFT_POINT_X+1
    sta X_DISTANCE+1

    ; Note: since we know the right point has a higher x than the left point, there is no need to negate it!
    
x_distance_right_left_is_positive:
    
    ; We subtract: Y_DISTANCE_RIGHT_TOP: RIGHT_POINT_Y - LEFT_POINT_Y
    lda RIGHT_POINT_Y
    sbc LEFT_POINT_Y
    sta Y_DISTANCE_RIGHT_LEFT
    lda RIGHT_POINT_Y+1
    sbc LEFT_POINT_Y+1
    sta Y_DISTANCE_RIGHT_LEFT+1
    bpl y_distance_right_left_is_positive
    
    lda #1
    sta Y_DISTANCE_IS_NEGATED

    ; We negate the Y_DISTANCE_RIGHT_LEFT
    sec
    lda #0
    sbc Y_DISTANCE_RIGHT_LEFT
    sta Y_DISTANCE_RIGHT_LEFT
    lda #0
    sbc Y_DISTANCE_RIGHT_LEFT+1
    sta Y_DISTANCE_RIGHT_LEFT+1
    
y_distance_right_left_is_positive:

    .if(USE_SLOPE_TABLES)
        ; We get the SLOPE from the slope table. We need:
        ;   y = Y_DISTANCE_RIGHT_LEFT
        ;   RAM_BANK = X_DISTANCE[5:0]
        ;   ADDR_HIGH[3:1] = X_DISTANCE[8:6]
        
        ldy Y_DISTANCE_RIGHT_LEFT
        
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
        sta SLOPE_RIGHT_LEFT
        
        ; We load the SLOPE_HIGH
        inc LOAD_ADDRESS+1
        lda (LOAD_ADDRESS), y
        sta SLOPE_RIGHT_LEFT+1
    
        ldx Y_DISTANCE_IS_NEGATED
        beq slope_right_left_is_correctly_signed   ; if Y_DISTANCE is negated we dont have to negate now, otherwise we do
        
        ; We need to preserve the x32 bit here!
        and #%10000000
        sta TMP2

        ; We unset the x32 (in case it was set) because we have to negate the number
        ; SPEED: can we use a different opcode here to unset the x32 bit?
        lda SLOPE_RIGHT_LEFT+1
        and #%01111111
        sta SLOPE_RIGHT_LEFT+1
        
        sec
        lda #0
        sbc SLOPE_RIGHT_LEFT
        sta SLOPE_RIGHT_LEFT
        lda #0
        sbc SLOPE_RIGHT_LEFT+1
        and #%01111111         ; Only keep the lower 7 bits
        ora TMP2               ; We restore the x32 bit
        sta SLOPE_RIGHT_LEFT+1
    
    .else
        ; We do the divide: X_DISTANCE * 256 / Y_DISTANCE_RIGHT_LEFT
        lda X_DISTANCE+1
        sta DIVIDEND+2
        lda X_DISTANCE
        sta DIVIDEND+1
        lda #0
        sta DIVIDEND

        lda #0
        sta DIVISOR+2
        lda Y_DISTANCE_RIGHT_LEFT+1
        sta DIVISOR+1
        lda Y_DISTANCE_RIGHT_LEFT
        sta DIVISOR

        jsr divide_24bits
        
        lda DIVIDEND+2
        sta SLOPE_RIGHT_LEFT+2
        lda DIVIDEND+1
        sta SLOPE_RIGHT_LEFT+1
        lda DIVIDEND
        sta SLOPE_RIGHT_LEFT
        
        ldx Y_DISTANCE_IS_NEGATED
        beq slope_right_left_is_correctly_signed   ; if Y_DISTANCE is negated we dont have to negate now, otherwise we do
        
        sec
        lda #0
        sbc SLOPE_RIGHT_LEFT
        sta SLOPE_RIGHT_LEFT
        lda #0
        sbc SLOPE_RIGHT_LEFT+1
        sta SLOPE_RIGHT_LEFT+1
        lda #0
        sbc SLOPE_RIGHT_LEFT+2
        sta SLOPE_RIGHT_LEFT+2
        
        ; FIXME: since we just negated, we unset bit15, but we should set bit15 properly
        lda SLOPE_RIGHT_LEFT+1
        and #%01111111           ; increment is only 15-bits long
        sta SLOPE_RIGHT_LEFT+1
    .endif
    
slope_right_left_is_correctly_signed:

    
    ; -- We setup the starting x and y and the color --
    .if(USE_POLYGON_FILLER)
        ; Setting up for drawing a polygon, setting both addresses at the same starting point

        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        .if(1)
            ; TODO: we limit the y-coordinate to 1 byte (so max 255 right now)
            ldy TOP_POINT_Y
            
            lda Y_TO_ADDRESS_BANK, y     ; This will include the auto-increment of 320 byte
            sta VERA_ADDR_BANK
            lda Y_TO_ADDRESS_HIGH, y
            sta VERA_ADDR_HIGH
            lda Y_TO_ADDRESS_LOW, y
            sta VERA_ADDR_LOW
        .else
            ; FIXME: we should do this *much* earlier and not for every triangle!
            lda #%11100000           ; Setting auto-increment value to 320 byte increment (=%1110)
            sta VERA_ADDR_BANK
            
            ; -- THIS IS SLOW! --
            ; We need to multiply the Y-coordinate with 320
            lda TOP_POINT_Y
            sta MULTIPLICAND
            lda TOP_POINT_Y+1
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
        .endif
    
        ; FIXME: we should do this *much* earlier and not for every triangle!
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

        ; FIXME: we should do this *much* earlier and not for every triangle!
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
    
        ldy TRIANGLE_COLOR      ; We use y as color
    .else 
    
        ; FIXME: implement this!
        
    .endif


    .if(USE_POLYGON_FILLER)

        ; -- We setup the x1 and x2 slopes for the first part of the triangle --
        
        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL

        ; FIXME: we should do x32 when the number is too high!!
        
        ; FIXME: NOTE that these increments are *HALF* steps!!
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

        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
    ; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
        
        ; FIXME: NOTE that these increments are *HALF* steps!!
        lda SLOPE_RIGHT_LEFT     ; X1 increment low
        sta $9F29
        lda SLOPE_RIGHT_LEFT+1   ; X1 increment high
        sta $9F2A

        lda Y_DISTANCE_RIGHT_LEFT
        sta NUMBER_OF_ROWS
        
        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively

        bra done_drawing_polygon_part
first_right_point_is_lower_in_y:
        lda Y_DISTANCE_RIGHT_TOP
        sta NUMBER_OF_ROWS
        
        ; -- We draw the first part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively

        lda #%00000110           ; DCSEL=3, ADDRSEL=0
        sta VERA_CTRL
        
    ; FIXME: dont you want to be able to reset the subpixel position here too? Or is that not really what you want here? Do you do that *only* when you set the pixel position?
        
        ; FIXME: NOTE that these increments are *HALF* steps!!
        lda SLOPE_RIGHT_LEFT     ; X2 increment low
        sta $9F2B                
        lda SLOPE_RIGHT_LEFT+1   ; X2 increment high
        sta $9F2C
        
        lda Y_DISTANCE_RIGHT_LEFT
        sta NUMBER_OF_ROWS
        
        ; -- We draw the second part of the triangle --
        jsr draw_polygon_part_using_polygon_filler_naively
        
done_drawing_polygon_part:
    .else
    
        ; FIXME: implement this!
        
    .endif
        
    
    
;    .if(USE_POLYGON_FILLER)
;        jsr draw_polygon_part_fast
;    .else
;        jsr draw_polygon_part_slow
;    .endif
    
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
    
    jsr draw_polygon_part_using_polygon_filler_naively
    
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
    
    jsr draw_polygon_part_using_polygon_filler_naively
    
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
    inx
    
    ; SLOW: we can speed this up *massively*, by unrolling this loop (and using blits), but this is just an example to explain how the feature works
polygon_fill_triangle_pixel_next_0:
    sty VERA_DATA1
    dex
    bne polygon_fill_triangle_pixel_next_0

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
    
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes (= +1 vertically)
    lda VERA_DATA1   ; this will increment x1 and x2 and the fill_line_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1
    
    dec NUMBER_OF_ROWS
    bne polygon_fill_triangle_row_next
    
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
    ora #%11100000              ; TODO: auto-increment = 320 (should we put this in a variable?)
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
