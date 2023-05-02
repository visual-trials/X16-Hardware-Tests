
; ISSUE: what if VERA says: draw 321 pixels? We will crash now...

DO_SPEED_TEST = 1

USE_POLYGON_FILLER = 0
USE_SLOPE_TABLES = 1
USE_UNROLLED_LOOP = 0     ; FIXME: BROKEN ATM!!
USE_JUMP_TABLE = 0
USE_WRITE_CACHE = USE_JUMP_TABLE ; TODO: do we want to separate these options? (they are now always the same)

TEST_JUMP_TABLE = 0 ; This turns off the iteration in-between the jump-table calls
USE_SOFT_FILL_LEN = 0; ; This turns off reading from 9F2B and 9F2C (for fill length data) and instead reads from USE_SOFT_FILL_LEN-variables

USE_180_DEGREES_SLOPE_TABLE = 0  ; When in polygon filler mode and slope tables turned on, its possible to use a 180 degrees slope table

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
JUMP16_ADDRESS            = $2C ; 2D
JUMP_ADDRESS              = $2E ; 2F
CODE_ADDRESS              = $30 ; 31
LOAD_ADDRESS              = $32 ; 33
STORE_ADDRESS             = $34 ; 35

TABLE_ROM_BANK            = $36
DRAW_LENGTH               = $37  ; for generating draw code

TRIANGLE_INDEX            = $38


; Polygon filler
NUMBER_OF_ROWS             = $39
FILL_LENGTH_LOW            = $3A
FILL_LENGTH_HIGH           = $3B
; X1_THREE_LOWER_BITS        = $3C

; "Software" implementation of polygon filler
SOFT_Y                     = $3E ; 3F
SOFT_X1_SUB                = $40 ; 41
SOFT_X1                    = $42 ; 43
SOFT_X2_SUB                = $44 ; 45
SOFT_X2                    = $46 ; 47
SOFT_X1_INCR_SUB           = $48 ; 49  ; TODO: We only use 1 byte here!
SOFT_X1_INCR               = $4A ; 4B
SOFT_X2_INCR_SUB           = $4C ; 4D  ; TODO: We only use 1 byte here!
SOFT_X2_INCR               = $4E ; 4F

SOFT_X1_INCR_HALF_SUB      = $50 ; 51
SOFT_X1_INCR_HALF          = $52 ; 53
SOFT_X2_INCR_HALF_SUB      = $54 ; 55
SOFT_X2_INCR_HALF          = $56 ; 57


; Note: a triangle either has:
;   - a single top-point, which means it also has a bottom-left point and bottom-right point
;   - a double top-point (two points are at the same top-y), which means top-left point and top-right point and a single bottom-point
;   TODO: we still need to deal with "triangles" that have three points with the same x or the same y coordinate (which is in fact a vertical or horizontal *line*, not a triangle).
TOP_POINT_X              = $60 ; 61
TOP_POINT_Y              = $62 ; 63
LEFT_POINT_X             = $64 ; 65
LEFT_POINT_Y             = $66 ; 67
RIGHT_POINT_X            = $68 ; 69
RIGHT_POINT_Y            = $6A ; 6B
BOTTOM_POINT_X           = TOP_POINT_X
BOTTOM_POINT_Y           = TOP_POINT_Y
TRIANGLE_COLOR           = $6C

; Used for calculating the slope between two points
X_DISTANCE               = $70 ; 71
X_DISTANCE_IS_NEGATED    = $72
Y_DISTANCE_LEFT_TOP      = $73 ; 74
Y_DISTANCE_BOTTOM_LEFT = Y_DISTANCE_LEFT_TOP
Y_DISTANCE_RIGHT_TOP     = $75 ; 76
Y_DISTANCE_BOTTOM_RIGHT = Y_DISTANCE_RIGHT_TOP
Y_DISTANCE_RIGHT_LEFT    = $77 ; 78
Y_DISTANCE_LEFT_RIGHT = Y_DISTANCE_RIGHT_LEFT
Y_DISTANCE_IS_NEGATED    = $79
SLOPE_TOP_LEFT           = $7A ; 7B ; 7C   ; TODO: do we really need 24 bits here?
SLOPE_LEFT_BOTTOM = SLOPE_TOP_LEFT
SLOPE_TOP_RIGHT          = $7D ; 7E ; 7F   ; TODO: do we really need 24 bits here?
SLOPE_RIGHT_BOTTOM = SLOPE_TOP_RIGHT
SLOPE_LEFT_RIGHT         = $80 ; 81 ; 82   ; TODO: do we really need 24 bits here?
SLOPE_RIGHT_LEFT = SLOPE_LEFT_RIGHT


Y_DISTANCE_FIRST         = $86 ; 87
Y_DISTANCE_SECOND        = $88 ; 89

VRAM_ADDRESS             = $90 ; 91 ; 92

LEFT_OVER_PIXELS         = $96 ; 97
NIBBLE_PATTERN           = $98
NR_OF_4_PIXELS           = $99
NR_OF_STARTING_PIXELS    = $9A
NR_OF_ENDING_PIXELS      = $9B


GEN_START_X              = $9C
GEN_FILL_LENGTH_LOW      = $9D
GEN_FILL_LENGTH_IS_16_OR_MORE = $9E
GEN_LOANED_16_PIXELS     = $9F
GEN_FILL_LINE_CODE_INDEX = $A0


DEBUG_VALUE              = $C7



FILL_LENGTH_LOW_SOFT     = $2800
FILL_LENGTH_HIGH_SOFT    = $2801

; RAM addresses
FILL_LINE_JUMP_TABLE     = $2F00
FILL_LINE_BELOW_16_CODE  = $3000   ; 128 different (below 16 pixel) fill line code patterns


; FIXME: can we put these jump tables closer to each other? Do they need to be aligned to 256 bytes? (they are 80 bytes each)
; FIXME: IMPORTANT: we set the two lower bits of this address in the code, using JUMP_TABLE_16_0 as base. So the distance between the 4 tables should stay $100! AND the two lower bits should stay 00b!
JUMP_TABLE_16_0          = $6400   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_0)
JUMP_TABLE_16_1          = $6500   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_1)
JUMP_TABLE_16_2          = $6600   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_2)
JUMP_TABLE_16_3          = $6700   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_3)

; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes?
FILL_LINE_CODE_0         = $6800   ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_1         = $6A00   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_2         = $6C00   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_3         = $6E00   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

CLEAR_COLUMN_CODE        = $7000   ; up to 72D0
TEST_FILL_LINE_CODE      = $7300

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

DRAW_ROW_64_CODE         = $AA00   ; A0-A9 and B6-BF are accucpied by the slope tables!

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
    
    .if(USE_UNROLLED_LOOP)
        jsr generate_draw_row_64_code
    .endif
    
    .if(USE_JUMP_TABLE)
        jsr generate_four_times_fill_line_code
        jsr generate_four_times_jump_table_16
        jsr generate_fill_line_codes_and_table
    .endif
    
    jsr generate_y_to_address_table
    
    .if(USE_SLOPE_TABLES)
        jsr copy_slope_table_copier_to_ram
        jsr COPY_SLOPE_TABLES_TO_BANKED_RAM
    .endif
    
    .if(DO_SPEED_TEST)
       jsr test_speed_of_filling_triangle
    .else
      lda #%00000000           ; DCSEL=0, ADDRSEL=0
      sta VERA_CTRL
        
;      lda #$20                 ; 4:1 scale
;      sta VERA_DC_HSCALE
;      sta VERA_DC_VSCALE      
    
      jsr start_timer

      ; jsr test_simple_polygon_filler
      jsr test_fill_length_jump_table
      
      jsr stop_timer
      
      lda #COLOR_TRANSPARANT
      sta TEXT_COLOR
        
      lda #8
      sta CURSOR_X
      lda #27
      sta CURSOR_Y
        
      jsr print_time_elapsed
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


    jsr load_triangle_data_into_ram

    jsr start_timer

    jsr draw_all_triangles

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
    
;    lda DEBUG_VALUE
;    sta BYTE_TO_PRINT
;    jsr print_byte_as_hex

    rts



    
set_cache32_with_color_slow:

; FIXME: we should create a (fast) macro for this!
    ; We first need to fill the 32-bit cache with 4 times our color

    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00000000           ; normal addr1 mode 
    sta $9F29
    
    lda #%00000001           ; ... cache fill enabled = 1
    sta $9F2C   
    
; FIXME: we should use a different VRAM address for this cache filling!!
    lda #%00000000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 bytes (=0=%00000)
    sta VERA_ADDR_BANK
    stz VERA_ADDR_HIGH
    stz VERA_ADDR_LOW

    lda #TEST_FILL_COLOR
    sta VERA_DATA1
    
    lda VERA_DATA1    
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
     
    lda #%00000000           ; ... cache fill enabled = 0
    sta $9F2C   
    
    lda #%00000010           ; map base addr = 0, blit write enabled = 1, repeat/clip = 0
    sta $9F2B     

    rts
  
test_fill_length_jump_table:

    jsr set_cache32_with_color_slow
    
    lda #8
    sta LEFT_POINT_Y
    
    lda #6
    sta LEFT_POINT_X
    lda #0
    sta LEFT_POINT_X+1

    lda #4
    sta TMP1               ; X START[1:0]
TEST_pattern_column_next:
    lda #33                ; FILL LENGTH[9:0] -> FIXME: this does not allow > 256 pixel atm!
    sta TMP3
TEST_pattern_next:
    jsr TEST_set_address_using_y2address_table_and_point_x
    
    lda #<TEST_FILL_LINE_CODE
    sta CODE_ADDRESS
    lda #>TEST_FILL_LINE_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ; stp
    
    lda LEFT_POINT_X
    asl
    asl
    asl
    asl
    asl
    asl
    sta TMP4
    
    lda TMP3             ; FILL_LEN[9:0]
    asl
    and #%00011110       ; FILL_LEN[3:0], 0
    ora TMP4    ; X1[0:1]
    sta FILL_LENGTH_LOW
    
    lda TMP3             ; FILL_LEN[9:0]
    lsr
    lsr
    lsr                  ; FILL_LEN[9:3]
    asl                  ; FILL_LEN[9:3], 0
    sta FILL_LENGTH_HIGH
    .if(USE_SOFT_FILL_LEN)
        sta FILL_LENGTH_HIGH_SOFT
    .endif
    
    and #%11111100        ; We check if FILL_LENGTH[9:4] is 0
    beq fill_len_not_higher_than_or_equal_to_16
    
    lda FILL_LENGTH_LOW
    ora #%00100000
    sta FILL_LENGTH_LOW
fill_len_not_higher_than_or_equal_to_16:
    .if(USE_SOFT_FILL_LEN)
        lda FILL_LENGTH_LOW
        sta FILL_LENGTH_LOW_SOFT
    .endif
    
    .if(0)
        jsr generate_single_fill_line_code
        ; stp
        jsr TEST_FILL_LINE_CODE
    .else
        ldx FILL_LENGTH_LOW_SOFT
        
        ;stp 
        
        jsr do_the_jump_to_the_table
    .endif

    inc LEFT_POINT_Y
    inc LEFT_POINT_Y

    dec TMP3
    bne TEST_pattern_next

    lda #8
    sta LEFT_POINT_Y
    
    clc
    lda LEFT_POINT_X
    adc #33
    sta LEFT_POINT_X
    lda LEFT_POINT_X+1
    lda #0
    sta LEFT_POINT_X+1
    
    dec TMP1
    bne TEST_pattern_column_next
    

    rts
    
test_simple_polygon_filler:

    .if(USE_JUMP_TABLE)
        ; NOTE: this will reset/screw up your ADDR1 settings!
        jsr set_cache32_with_color_slow
    .else
        ldy #TEST_FILL_COLOR     ; We use y as color
    .endif

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


    .if(USE_JUMP_TABLE)
        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
        lda #%00110000           ; Setting auto-increment value to 4 byte increment (=%0011)
        sta VERA_ADDR_BANK
    .else
        ; Note: when setting the x and y pixel positions, ADDR1 will be set as well: ADDR1 = ADDR0 + x1. So there is no need to set ADDR1 explicitly here.
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif

; FIXME: hardcoded!
    lda #150
    sta NUMBER_OF_ROWS
    
    ; stp
    
    
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


    ; Turning off polygon filler mode
    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    ; Normal addr1 mode
    lda #%00000000
    sta $9F29
    
    lda #%00000000           ; map base addr = 0, blit write enabled = 0, repeat/clip = 0
    sta $9F2B     
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
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

    ; -- stz VERA_DATA0 ($9F23)
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
    
    
    .if(0)
NR_OF_TRIANGLES = 12
triangle_data:
    ;     x1,  y1,    x2,  y2,    x3,  y3    cl
   .word   0,   0,   100,  70,    0,  50,    4       ; all positive slopes
   .word   0,   0,   200,   1,  100,  70,    5
   .word   0,   0,   280,   0,  200,   1,    3
   .word 200,   1,   279,   0,  280,   120,  7
   .word 279,   0,   280,   0,  280,   120,  15
   .word 180,  50,   200,   1,  280,   120,  8       ; negative + positive slope at the top, positive+positive slope at the bottom
   .word   0, 120,    80, 100,  280,   120,  9
   .word 100,  70,   200,   1,  180,    50,  10
   .word   0,  50,    80, 100,    0,   120,  11
   .word   0,  50,   100,  70,   80,   100,  12
   .word 100,  70,   180,  50,   80,   100,  13
   .word 180,  50,   280, 120,   80,   100,  14
palette_data:   
    ; dummy
end_of_palette_data:
    .endif
   
   
    .if(1)
palette_data:
    .byte $c8, $08  ; palette index 16
    .byte $c9, $07  ; palette index 17
    .byte $c7, $09  ; palette index 18
    .byte $a6, $06  ; palette index 19
    .byte $fa, $0d  ; palette index 20
    .byte $a7, $06  ; palette index 21
    .byte $b7, $09  ; palette index 22
    .byte $fc, $0b  ; palette index 23
    .byte $73, $04  ; palette index 24
    .byte $ff, $0f  ; palette index 25
    .byte $95, $05  ; palette index 26
    .byte $84, $05  ; palette index 27
    .byte $b7, $06  ; palette index 28
    .byte $b7, $08  ; palette index 29
    .byte $e9, $0c  ; palette index 30
    .byte $d8, $0b  ; palette index 31
    .byte $fb, $0e  ; palette index 32
    .byte $ec, $08  ; palette index 33
    .byte $fd, $09  ; palette index 34
    .byte $b8, $08  ; palette index 35
    .byte $b7, $07  ; palette index 36
    .byte $db, $08  ; palette index 37
    .byte $fe, $09  ; palette index 38
    .byte $d9, $09  ; palette index 39
    .byte $da, $08  ; palette index 40
    .byte $eb, $08  ; palette index 41
    .byte $ff, $0a  ; palette index 42
    .byte $b8, $07  ; palette index 43
    .byte $eb, $0a  ; palette index 44
    .byte $fd, $0a  ; palette index 45
    .byte $eb, $09  ; palette index 46
    .byte $a6, $07  ; palette index 47
    .byte $da, $09  ; palette index 48
    .byte $fc, $0a  ; palette index 49
    .byte $ca, $07  ; palette index 50
    .byte $a5, $07  ; palette index 51
    .byte $ff, $0c  ; palette index 52
end_of_palette_data:


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
    .endif
   
   
    .if(0)
palette_data:
    .byte $31, $09  ; palette index 16
    .byte $51, $0a  ; palette index 17
    .byte $72, $0d  ; palette index 18
    .byte $72, $0e  ; palette index 19
    .byte $61, $0c  ; palette index 20
    .byte $41, $09  ; palette index 21
    .byte $41, $0a  ; palette index 22
    .byte $51, $0b  ; palette index 23
    .byte $61, $0b  ; palette index 24
    .byte $a2, $0f  ; palette index 25
    .byte $92, $0f  ; palette index 26
    .byte $62, $0c  ; palette index 27
    .byte $b2, $0f  ; palette index 28
    .byte $d2, $0f  ; palette index 29
    .byte $62, $0b  ; palette index 30
    .byte $72, $0c  ; palette index 31
    .byte $82, $0d  ; palette index 32
    .byte $52, $0b  ; palette index 33
    .byte $82, $0e  ; palette index 34
    .byte $92, $0e  ; palette index 35
    .byte $52, $0a  ; palette index 36
    .byte $e3, $0f  ; palette index 37
    .byte $f4, $0f  ; palette index 38
    .byte $d3, $0f  ; palette index 39
    .byte $31, $08  ; palette index 40
end_of_palette_data:


NR_OF_TRIANGLES = 246
triangle_data:
    ;     x1,  y1,    x2,  y2,    x3,  y3    cl
    .word 56  ,120 ,86  ,119 ,107 ,120 ,16
    .word 155 ,119 ,186 ,119 ,194 ,120 ,17
    .word 139 ,120 ,155 ,119 ,194 ,120 ,17
    .word 194 ,120 ,235 ,98  ,278 ,120 ,18
    .word 235 ,98  ,255 ,84  ,278 ,120 ,19
    .word 278 ,120 ,255 ,84  ,279 ,87  ,20
    .word 255 ,84  ,273 ,73  ,279 ,87  ,18
    .word 273 ,73  ,272 ,72  ,280 ,65  ,20
    .word 272 ,72  ,267 ,59  ,280 ,65  ,20
    .word 279 ,87  ,273 ,73  ,280 ,65  ,20
    .word 276 ,26  ,280 ,20  ,280 ,22  ,21
    .word 276 ,26  ,280 ,22  ,280 ,32  ,22
    .word 274 ,44  ,276 ,26  ,280 ,32  ,22
    .word 268 ,47  ,274 ,44  ,280 ,50  ,23
    .word 267 ,59  ,268 ,47  ,280 ,50  ,23
    .word 274 ,44  ,280 ,32  ,280 ,50  ,17
    .word 280 ,20  ,276 ,26  ,280 ,17  ,21
    .word 276 ,26  ,275 ,7   ,280 ,17  ,21
    .word 275 ,7   ,280 ,5   ,280 ,17  ,21
    .word 278 ,120 ,279 ,87  ,280 ,120 ,23
    .word 279 ,87  ,280 ,65  ,280 ,120 ,23
    .word 267 ,59  ,280 ,50  ,280 ,60  ,23
    .word 280 ,65  ,267 ,59  ,280 ,60  ,23
    .word 280 ,5   ,275 ,7   ,280 ,0   ,21
    .word 275 ,7   ,260 ,0   ,280 ,0   ,21
    .word 274 ,44  ,268 ,47  ,276 ,26  ,17
    .word 260 ,0   ,275 ,7   ,276 ,26  ,21
    .word 255 ,84  ,272 ,72  ,273 ,73  ,18
    .word 268 ,47  ,249 ,44  ,276 ,26  ,17
    .word 237 ,10  ,260 ,0   ,276 ,26  ,22
    .word 249 ,44  ,237 ,10  ,276 ,26  ,17
    .word 240 ,41  ,237 ,10  ,249 ,44  ,23
    .word 255 ,84  ,267 ,59  ,272 ,72  ,18
    .word 231 ,7   ,215 ,0   ,260 ,0   ,22
    .word 251 ,46  ,249 ,44  ,268 ,47  ,24
    .word 267 ,59  ,251 ,46  ,268 ,47  ,24
    .word 232 ,85  ,251 ,46  ,255 ,84  ,25
    .word 255 ,84  ,251 ,46  ,267 ,59  ,18
    .word 232 ,85  ,220 ,75  ,251 ,46  ,26
    .word 220 ,75  ,219 ,54  ,251 ,46  ,19
    .word 237 ,10  ,231 ,7   ,260 ,0   ,22
    .word 219 ,54  ,233 ,43  ,251 ,46  ,27
    .word 235 ,98  ,234 ,96  ,255 ,84  ,28
    .word 234 ,96  ,232 ,85  ,255 ,84  ,29
    .word 217 ,23  ,237 ,10  ,240 ,41  ,23
    .word 223 ,38  ,217 ,23  ,240 ,41  ,30
    .word 240 ,41  ,249 ,44  ,251 ,46  ,24
    .word 233 ,43  ,240 ,41  ,251 ,46  ,27
    .word 218 ,34  ,217 ,23  ,223 ,38  ,30
    .word 194 ,120 ,226 ,94  ,235 ,98  ,18
    .word 217 ,23  ,231 ,7   ,237 ,10  ,17
    .word 233 ,43  ,223 ,38  ,240 ,41  ,27
    .word 194 ,120 ,197 ,98  ,226 ,94  ,27
    .word 226 ,94  ,232 ,85  ,234 ,96  ,28
    .word 226 ,94  ,234 ,96  ,235 ,98  ,25
    .word 219 ,54  ,223 ,38  ,233 ,43  ,27
    .word 226 ,94  ,220 ,75  ,232 ,85  ,28
    .word 219 ,54  ,217 ,40  ,223 ,38  ,27
    .word 197 ,98  ,204 ,91  ,226 ,94  ,18
    .word 217 ,23  ,215 ,0   ,231 ,7   ,17
    .word 208 ,0   ,215 ,0   ,217 ,23  ,17
    .word 202 ,56  ,219 ,54  ,220 ,75  ,18
    .word 204 ,91  ,220 ,75  ,226 ,94  ,26
    .word 217 ,40  ,218 ,34  ,223 ,38  ,30
    .word 192 ,18  ,208 ,0   ,217 ,23  ,17
    .word 202 ,56  ,217 ,40  ,219 ,54  ,31
    .word 204 ,91  ,186 ,65  ,220 ,75  ,32
    .word 186 ,65  ,202 ,56  ,220 ,75  ,18
    .word 207 ,34  ,217 ,23  ,218 ,34  ,30
    .word 186 ,65  ,190 ,60  ,202 ,56  ,32
    .word 182 ,79  ,186 ,65  ,204 ,91  ,18
    .word 197 ,39  ,207 ,34  ,217 ,40  ,27
    .word 202 ,56  ,197 ,39  ,217 ,40  ,31
    .word 217 ,40  ,207 ,34  ,218 ,34  ,27
    .word 207 ,34  ,192 ,18  ,217 ,23  ,30
    .word 194 ,120 ,185 ,112 ,197 ,98  ,30
    .word 197 ,39  ,192 ,18  ,207 ,34  ,27
    .word 192 ,18  ,186 ,0   ,208 ,0   ,17
    .word 190 ,60  ,197 ,39  ,202 ,56  ,18
    .word 197 ,98  ,181 ,91  ,204 ,91  ,31
    .word 181 ,91  ,182 ,79  ,204 ,91  ,31
    .word 175 ,11  ,186 ,0   ,192 ,18  ,33
    .word 185 ,112 ,178 ,105 ,197 ,98  ,30
    .word 190 ,60  ,169 ,59  ,197 ,39  ,34
    .word 169 ,59  ,162 ,41  ,197 ,39  ,25
    .word 162 ,41  ,192 ,18  ,197 ,39  ,18
    .word 186 ,119 ,185 ,112 ,194 ,120 ,23
    .word 178 ,105 ,181 ,91  ,197 ,98  ,27
    .word 178 ,105 ,176 ,98  ,181 ,91  ,30
    .word 162 ,41  ,175 ,11  ,192 ,18  ,31
    .word 182 ,112 ,178 ,105 ,185 ,112 ,23
    .word 186 ,65  ,169 ,59  ,190 ,60  ,35
    .word 182 ,112 ,185 ,112 ,186 ,119 ,23
    .word 155 ,119 ,182 ,112 ,186 ,119 ,17
    .word 182 ,79  ,169 ,59  ,186 ,65  ,34
    .word 175 ,11  ,139 ,0   ,186 ,0   ,36
    .word 165 ,84  ,164 ,59  ,169 ,59  ,25
    .word 181 ,91  ,165 ,84  ,182 ,79  ,31
    .word 165 ,84  ,169 ,59  ,182 ,79  ,32
    .word 155 ,119 ,178 ,105 ,182 ,112 ,23
    .word 153 ,68  ,164 ,59  ,165 ,84  ,35
    .word 176 ,98  ,169 ,95  ,181 ,91  ,27
    .word 169 ,95  ,165 ,84  ,181 ,91  ,27
    .word 162 ,41  ,140 ,20  ,175 ,11  ,18
    .word 169 ,95  ,176 ,98  ,178 ,105 ,30
    .word 155 ,119 ,169 ,95  ,178 ,105 ,33
    .word 164 ,59  ,162 ,41  ,169 ,59  ,37
    .word 140 ,20  ,139 ,0   ,175 ,11  ,30
    .word 152 ,81  ,153 ,68  ,165 ,84  ,32
    .word 144 ,94  ,152 ,88  ,169 ,95  ,30
    .word 155 ,119 ,139 ,103 ,169 ,95  ,33
    .word 139 ,103 ,144 ,94  ,169 ,95  ,30
    .word 152 ,88  ,165 ,84  ,169 ,95  ,27
    .word 131 ,52  ,162 ,41  ,164 ,59  ,38
    .word 153 ,68  ,131 ,52  ,164 ,59  ,39
    .word 152 ,88  ,152 ,81  ,165 ,84  ,31
    .word 131 ,52  ,140 ,20  ,162 ,41  ,25
    .word 138 ,71  ,131 ,52  ,147 ,71  ,35
    .word 147 ,71  ,131 ,52  ,153 ,68  ,25
    .word 152 ,81  ,147 ,71  ,153 ,68  ,34
    .word 139 ,120 ,139 ,103 ,155 ,119 ,17
    .word 128 ,65  ,131 ,52  ,138 ,71  ,32
    .word 138 ,71  ,147 ,71  ,152 ,81  ,32
    .word 152 ,88  ,144 ,94  ,152 ,81  ,27
    .word 144 ,94  ,138 ,71  ,152 ,81  ,31
    .word 132 ,105 ,139 ,103 ,139 ,120 ,17
    .word 131 ,52  ,111 ,38  ,140 ,20  ,31
    .word 136 ,120 ,132 ,105 ,139 ,120 ,22
    .word 139 ,103 ,132 ,105 ,144 ,94  ,36
    .word 132 ,105 ,112 ,98  ,144 ,94  ,17
    .word 111 ,77  ,138 ,71  ,144 ,94  ,30
    .word 112 ,98  ,111 ,77  ,144 ,94  ,36
    .word 103 ,20  ,97  ,0   ,139 ,0   ,22
    .word 111 ,38  ,106 ,34  ,140 ,20  ,30
    .word 106 ,34  ,103 ,20  ,140 ,20  ,36
    .word 103 ,20  ,139 ,0   ,140 ,20  ,36
    .word 125 ,107 ,132 ,105 ,136 ,120 ,17
    .word 111 ,77  ,128 ,65  ,138 ,71  ,27
    .word 125 ,107 ,112 ,98  ,132 ,105 ,17
    .word 123 ,120 ,125 ,107 ,136 ,120 ,22
    .word 128 ,65  ,111 ,38  ,131 ,52  ,31
    .word 111 ,77  ,89  ,56  ,128 ,65  ,33
    .word 89  ,56  ,111 ,38  ,128 ,65  ,30
    .word 123 ,120 ,107 ,120 ,125 ,107 ,21
    .word 107 ,120 ,112 ,98  ,125 ,107 ,21
    .word 89  ,56  ,100 ,34  ,111 ,38  ,17
    .word 89  ,106 ,76  ,71  ,111 ,77  ,21
    .word 76  ,71  ,89  ,56  ,111 ,77  ,22
    .word 89  ,106 ,111 ,77  ,112 ,98  ,22
    .word 98  ,107 ,89  ,106 ,112 ,98  ,21
    .word 107 ,120 ,98  ,107 ,112 ,98  ,21
    .word 67  ,83  ,76  ,71  ,89  ,106 ,21
    .word 100 ,34  ,103 ,20  ,106 ,34  ,17
    .word 100 ,34  ,106 ,34  ,111 ,38  ,36
    .word 89  ,56  ,87  ,55  ,100 ,34  ,17
    .word 86  ,119 ,98  ,107 ,107 ,120 ,21
    .word 89  ,0   ,97  ,0   ,103 ,20  ,21
    .word 71  ,31  ,77  ,8   ,78  ,36  ,21
    .word 87  ,55  ,78  ,36  ,100 ,34  ,21
    .word 77  ,8   ,89  ,0   ,103 ,20  ,21
    .word 100 ,34  ,78  ,36  ,103 ,20  ,22
    .word 78  ,36  ,77  ,8   ,103 ,20  ,21
    .word 86  ,119 ,89  ,106 ,98  ,107 ,21
    .word 68  ,9   ,35  ,0   ,89  ,0   ,40
    .word 66  ,50  ,78  ,36  ,87  ,55  ,21
    .word 76  ,71  ,87  ,55  ,89  ,56  ,21
    .word 77  ,8   ,68  ,9   ,89  ,0   ,21
    .word 86  ,119 ,59  ,109 ,89  ,106 ,16
    .word 59  ,109 ,67  ,83  ,89  ,106 ,21
    .word 71  ,31  ,68  ,9   ,77  ,8   ,21
    .word 76  ,71  ,66  ,50  ,87  ,55  ,21
    .word 56  ,120 ,59  ,109 ,86  ,119 ,40
    .word 60  ,11  ,35  ,0   ,68  ,9   ,40
    .word 60  ,11  ,68  ,9   ,71  ,31  ,21
    .word 55  ,18  ,60  ,11  ,71  ,31  ,16
    .word 64  ,39  ,71  ,31  ,78  ,36  ,21
    .word 66  ,50  ,64  ,39  ,78  ,36  ,21
    .word 64  ,39  ,64  ,36  ,71  ,31  ,21
    .word 44  ,65  ,66  ,50  ,76  ,71  ,21
    .word 59  ,109 ,53  ,83  ,67  ,83  ,16
    .word 48  ,76  ,44  ,65  ,76  ,71  ,16
    .word 67  ,83  ,48  ,76  ,76  ,71  ,21
    .word 53  ,83  ,48  ,76  ,67  ,83  ,16
    .word 64  ,36  ,55  ,18  ,71  ,31  ,21
    .word 44  ,65  ,40  ,60  ,45  ,47  ,40
    .word 45  ,47  ,64  ,39  ,66  ,50  ,21
    .word 44  ,65  ,45  ,47  ,66  ,50  ,16
    .word 32  ,90  ,53  ,83  ,53  ,111 ,40
    .word 56  ,120 ,53  ,111 ,59  ,109 ,40
    .word 53  ,111 ,53  ,83  ,59  ,109 ,40
    .word 55  ,18  ,55  ,16  ,60  ,11  ,40
    .word 45  ,47  ,55  ,18  ,64  ,36  ,16
    .word 45  ,47  ,64  ,36  ,64  ,39  ,16
    .word 45  ,47  ,24  ,25  ,55  ,18  ,40
    .word 55  ,16  ,35  ,0   ,60  ,11  ,40
    .word 33  ,9   ,35  ,0   ,55  ,16  ,40
    .word 37  ,120 ,53  ,111 ,56  ,120 ,40
    .word 23  ,110 ,32  ,90  ,53  ,111 ,40
    .word 33  ,9   ,55  ,16  ,55  ,18  ,40
    .word 24  ,25  ,33  ,9   ,55  ,18  ,40
    .word 32  ,90  ,32  ,85  ,53  ,83  ,40
    .word 37  ,120 ,23  ,110 ,53  ,111 ,40
    .word 42  ,72  ,44  ,65  ,48  ,76  ,40
    .word 32  ,85  ,48  ,76  ,53  ,83  ,40
    .word 24  ,25  ,29  ,10  ,33  ,9   ,40
    .word 24  ,52  ,24  ,25  ,45  ,47  ,40
    .word 40  ,60  ,37  ,55  ,45  ,47  ,40
    .word 32  ,85  ,42  ,72  ,48  ,76  ,40
    .word 37  ,55  ,24  ,52  ,45  ,47  ,40
    .word 42  ,72  ,40  ,60  ,44  ,65  ,40
    .word 27  ,68  ,40  ,60  ,42  ,72  ,40
    .word 32  ,85  ,27  ,68  ,42  ,72  ,40
    .word 11  ,6   ,0   ,0   ,35  ,0   ,40
    .word 27  ,68  ,37  ,55  ,40  ,60  ,40
    .word 24  ,52  ,12  ,30  ,24  ,25  ,40
    .word 27  ,86  ,27  ,68  ,32  ,85  ,40
    .word 27  ,68  ,24  ,52  ,37  ,55  ,40
    .word 0   ,120 ,23  ,110 ,37  ,120 ,40
    .word 33  ,9   ,29  ,10  ,35  ,0   ,40
    .word 29  ,10  ,11  ,6   ,35  ,0   ,40
    .word 23  ,110 ,3   ,101 ,27  ,86  ,40
    .word 23  ,110 ,27  ,86  ,32  ,90  ,40
    .word 32  ,90  ,27  ,86  ,32  ,85  ,40
    .word 8   ,109 ,3   ,101 ,23  ,110 ,40
    .word 7   ,62  ,24  ,52  ,27  ,68  ,40
    .word 0   ,69  ,27  ,68  ,27  ,86  ,40
    .word 24  ,25  ,11  ,6   ,29  ,10  ,40
    .word 0   ,120 ,8   ,109 ,23  ,110 ,40
    .word 12  ,30  ,11  ,6   ,24  ,25  ,40
    .word 0   ,69  ,7   ,62  ,27  ,68  ,40
    .word 3   ,101 ,0   ,69  ,27  ,86  ,40
    .word 0   ,12  ,11  ,6   ,12  ,30  ,40
    .word 0   ,60  ,12  ,30  ,24  ,52  ,40
    .word 7   ,62  ,0   ,60  ,24  ,52  ,40
    .word 0   ,102 ,0   ,69  ,3   ,101 ,40
    .word 0   ,114 ,3   ,109 ,8   ,109 ,40
    .word 0   ,120 ,0   ,114 ,8   ,109 ,40
    .word 0   ,12  ,0   ,11  ,11  ,6   ,40
    .word 0   ,60  ,0   ,12  ,12  ,30  ,40
    .word 0   ,11  ,0   ,0   ,11  ,6   ,40
    .word 3   ,109 ,0   ,108 ,3   ,101 ,40
    .word 3   ,109 ,3   ,101 ,8   ,109 ,40
    .word 0   ,108 ,0   ,103 ,3   ,101 ,40
    .word 0   ,69  ,0   ,60  ,7   ,62  ,40
    .word 0   ,114 ,0   ,108 ,3   ,109 ,40
    .word 0   ,103 ,0   ,102 ,3   ,101 ,40
    .endif 
   
    
    
    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/timing.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include special_tests/fx_polygon_fill.s

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

    ; NOTE: we are now using ROM banks to contain tables. We need to copy those tables to Banked RAM, but have to run that copy-code in Fixed RAM.
    
    .if(USE_SLOPE_TABLES)
        .if(USE_POLYGON_FILLER)
            .binary "special_tests/tables/slopes_packed_column_0_low.bin"
            .binary "special_tests/tables/slopes_packed_column_0_high.bin"
            .binary "special_tests/tables/slopes_packed_column_1_low.bin"
            .binary "special_tests/tables/slopes_packed_column_1_high.bin"
            .binary "special_tests/tables/slopes_packed_column_2_low.bin"
            .binary "special_tests/tables/slopes_packed_column_2_high.bin"
            .binary "special_tests/tables/slopes_packed_column_3_low.bin"
            .binary "special_tests/tables/slopes_packed_column_3_high.bin"
            .binary "special_tests/tables/slopes_packed_column_4_low.bin"
            .binary "special_tests/tables/slopes_packed_column_4_high.bin"
            .if(USE_180_DEGREES_SLOPE_TABLE)
                .binary "special_tests/tables/slopes_negative_packed_column_0_low.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_0_high.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_1_low.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_1_high.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_2_low.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_2_high.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_3_low.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_3_high.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_4_low.bin"
                .binary "special_tests/tables/slopes_negative_packed_column_4_high.bin"
            .endif
        .else
            ; FIXME: right now we include vhigh tables *TWICE*! The second time is a dummy include! (since we want all _low tables to be aligned with ROM_BANK % 4 == 1)
            .binary "special_tests/tables/slopes_column_0_low.bin"
            .binary "special_tests/tables/slopes_column_0_high.bin"
            .binary "special_tests/tables/slopes_column_0_vhigh.bin"
            .binary "special_tests/tables/slopes_column_0_vhigh.bin"
            .binary "special_tests/tables/slopes_column_1_low.bin"
            .binary "special_tests/tables/slopes_column_1_high.bin"
            .binary "special_tests/tables/slopes_column_1_vhigh.bin"
            .binary "special_tests/tables/slopes_column_1_vhigh.bin"
            .binary "special_tests/tables/slopes_column_2_low.bin"
            .binary "special_tests/tables/slopes_column_2_high.bin"
            .binary "special_tests/tables/slopes_column_2_vhigh.bin"
            .binary "special_tests/tables/slopes_column_2_vhigh.bin"
            .binary "special_tests/tables/slopes_column_3_low.bin"
            .binary "special_tests/tables/slopes_column_3_high.bin"
            .binary "special_tests/tables/slopes_column_3_vhigh.bin"
            .binary "special_tests/tables/slopes_column_3_vhigh.bin"
            .binary "special_tests/tables/slopes_column_4_low.bin"
            .binary "special_tests/tables/slopes_column_4_high.bin"
            .binary "special_tests/tables/slopes_column_4_vhigh.bin"
            .binary "special_tests/tables/slopes_column_4_vhigh.bin"
        .endif
        
    .endif
