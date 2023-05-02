
DO_SPEED_TEST = 1

USE_POLYGON_FILLER = 0
USE_SLOPE_TABLES = 0
USE_UNROLLED_LOOP = 0
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
    
; FIXME
;TOP_MARGIN = 12
TOP_MARGIN = 13
LEFT_MARGIN = 16
VSPACING = 10

SCREEN_WIDTH = 320
SCREEN_HEIGHT = 240

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

TMP_POINT_X              = $A1 ; A2
TMP_POINT_Y              = $A3 ; A4
TMP_POINT_Z              = $A5 ; A6


DEBUG_VALUE              = $C7



FILL_LENGTH_LOW_SOFT     = $2800
FILL_LENGTH_HIGH_SOFT    = $2801

; RAM addresses
FILL_LINE_JUMP_TABLE     = $2F00
FILL_LINE_BELOW_16_CODE  = $3000   ; 128 different (below 16 pixel) fill line code patterns -> safe: takes $0D00 bytes

; FIXME: can we put these jump tables closer to each other? Do they need to be aligned to 256 bytes? (they are 80 bytes each)
; FIXME: IMPORTANT: we set the two lower bits of this address in the code, using JUMP_TABLE_16_0 as base. So the distance between the 4 tables should stay $100! AND the two lower bits should stay 00b!
JUMP_TABLE_16_0          = $3D00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_0)
JUMP_TABLE_16_1          = $3E00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_1)
JUMP_TABLE_16_2          = $3F00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_2)
JUMP_TABLE_16_3          = $4000   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_3)

; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes?
FILL_LINE_CODE_0         = $4100   ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_1         = $4200   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_2         = $4300   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_3         = $4400   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

CLEAR_COLUMN_CODE        = $4500   ; takes up to 02D0

; Triangle data is (easely) accessed through an single index (0-127)
; == IMPORTANT: we assume a *clockwise* ordering of the 3 points of a triangle! ==
MAX_NR_OF_TRIANGLES      = 128
TRIANGLES_POINT1_X       = $4800 ; 4880
TRIANGLES_POINT1_Y       = $4900 ; 4980
TRIANGLES_POINT2_X       = $4A00 ; 4A80
TRIANGLES_POINT2_Y       = $4B00 ; 4B80
TRIANGLES_POINT3_X       = $4C00 ; 4C80
TRIANGLES_POINT3_Y       = $4D00 ; 4D80

TRIANGLES_COLOR          = $4E00 ; Only 128 bytes used

; FIXME: We should instead use a series of POINTS and INDEXES to those points are used to define TRIANGLES!
TRIANGLES_3D_POINT1_X    = $5000 ; 5080
TRIANGLES_3D_POINT1_Y    = $5180 ; 5100
TRIANGLES_3D_POINT1_Z    = $5200 ; 5280
TRIANGLES_3D_POINT2_X    = $5300 ; 5380
TRIANGLES_3D_POINT2_Y    = $5400 ; 5480
TRIANGLES_3D_POINT2_Z    = $5500 ; 5580
TRIANGLES_3D_POINT3_X    = $5600 ; 5680
TRIANGLES_3D_POINT3_Y    = $5700 ; 5780
TRIANGLES_3D_POINT3_Z    = $5800 ; 5880

; FIXME: lots of room here!

TRIANGLES2_3D_POINT1_X   = $6000 ; 6080
TRIANGLES2_3D_POINT1_Y   = $6180 ; 6100
TRIANGLES2_3D_POINT1_Z   = $6200 ; 6280
TRIANGLES2_3D_POINT2_X   = $6300 ; 6380
TRIANGLES2_3D_POINT2_Y   = $6400 ; 6480
TRIANGLES2_3D_POINT2_Z   = $6500 ; 6580
TRIANGLES2_3D_POINT3_X   = $6600 ; 6680
TRIANGLES2_3D_POINT3_Y   = $6700 ; 6780
TRIANGLES2_3D_POINT3_Z   = $6800 ; 6880

Y_TO_ADDRESS_LOW         = $8400
Y_TO_ADDRESS_HIGH        = $8500
Y_TO_ADDRESS_BANK        = $8600

COPY_SLOPE_TABLES_TO_BANKED_RAM   = $8700

    .if(USE_POLYGON_FILLER)
DRAW_ROW_64_CODE         = $AA00   ; When USE_POLYGON_FILLER is 1: A000-A9FF and B0600-BFFF are occucpied by the slope tables! (the latter by the 90-180 degrees slope tables)
    .else
DRAW_ROW_64_CODE         = $B500   ; When USE_POLYGON_FILLER is 0: A000-B4FF are occucpied by the slope tables!
    .endif

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
    
    .if(USE_Y_TO_ADDRESS_TABLE)
        jsr generate_y_to_address_table
    .endif
    
    .if(USE_SLOPE_TABLES)
        jsr copy_slope_table_copier_to_ram
        jsr COPY_SLOPE_TABLES_TO_BANKED_RAM
    .endif
    
    .if(DO_SPEED_TEST)
       jsr test_speed_of_simple_3d_polygon_scene
    .else
      lda #%00000000           ; DCSEL=0, ADDRSEL=0
      sta VERA_CTRL
        
;      lda #$40                 ; 8:1 scale
;      sta VERA_DC_HSCALE
;      sta VERA_DC_VSCALE      
      
;      jsr ...
    .endif
    
  
loop:
  jmp loop


check_raw_message: 
    .byte $FA, 0
cross_raw_message: 
    .byte $56, 0
  
simple_3d_polygon_scene_message: 
    .asciiz "Clear, calculate and draw 3D polygons"
    
rectangle_200x200_8bpp_message: 
    .asciiz "Size: 200x200 (8bpp) "
    
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
  
  
  
test_speed_of_simple_3d_polygon_scene:

    jsr load_3d_triangle_data_into_ram

    jsr start_timer
    
    .if (USE_POLYGON_FILLER || USE_WRITE_CACHE)
        jsr clear_screen_fast_4_bytes
    .else
        jsr clear_screen_slow
    .endif
    
    jsr calculate_projection_of_3d_onto_2d_screen
    
    jsr draw_all_triangles

    jsr stop_timer

    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #2
    sta CURSOR_X
    lda #2
    sta CURSOR_Y

    lda #<simple_3d_polygon_scene_message
    sta TEXT_TO_PRINT
    lda #>simple_3d_polygon_scene_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    .if(0)
        lda #10
        sta CURSOR_X
        lda #4
        sta CURSOR_Y
        
        lda #<rectangle_200x200_8bpp_message
        sta TEXT_TO_PRINT
        lda #>rectangle_200x200_8bpp_message
        sta TEXT_TO_PRINT + 1
        
        jsr print_text_zero
    .endif


    .if(0)
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
    .endif
    

    
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
    
    
    
MACRO_scale_and_position_on_screen_x .macro TRIANGLES_3D_POINT_X, TRIANGLES_POINT_X

    lda \TRIANGLES_3D_POINT_X, y
    sta TMP_POINT_X
    lda \TRIANGLES_3D_POINT_X+MAX_NR_OF_TRIANGLES, y
    sta TMP_POINT_X+1
    
    ; First we multiply by 128 (by dividing by 2)
    lsr TMP_POINT_X+1
    ror TMP_POINT_X
; FIXME: REMOVE THIS!!
; FIXME: REMOVE THIS!!
; FIXME: REMOVE THIS!!
; FIXME: REMOVE THIS!!
    lsr TMP_POINT_X+1
    ror TMP_POINT_X
    
    ; We then add half of the screen width
    clc
    lda TMP_POINT_X
    adc #<(SCREEN_WIDTH/2)
    sta \TRIANGLES_POINT_X, y
    
    lda TMP_POINT_X+1
    adc #>(SCREEN_WIDTH/2)
    sta \TRIANGLES_POINT_X+MAX_NR_OF_TRIANGLES, y

.endmacro
    
MACRO_scale_and_position_on_screen_y .macro TRIANGLES_3D_POINT_Y, TRIANGLES_POINT_Y

    lda \TRIANGLES_3D_POINT_Y, y
    sta TMP_POINT_Y
    lda \TRIANGLES_3D_POINT_Y+MAX_NR_OF_TRIANGLES, y
    sta TMP_POINT_Y+1
    
    ; First we multiply by 128 (by dividing by 2)
    lsr TMP_POINT_Y+1
    ror TMP_POINT_Y
; FIXME: REMOVE THIS!!
; FIXME: REMOVE THIS!!
; FIXME: REMOVE THIS!!
; FIXME: REMOVE THIS!!
    lsr TMP_POINT_Y+1
    ror TMP_POINT_Y
    
    ; We then add half of the screen width
    clc
    lda TMP_POINT_Y
    adc #<(SCREEN_HEIGHT/2)
    sta \TRIANGLES_POINT_Y, y
    
    lda TMP_POINT_Y+1
    adc #>(SCREEN_HEIGHT/2)
    sta \TRIANGLES_POINT_Y+MAX_NR_OF_TRIANGLES, y

.endmacro

calculate_projection_of_3d_onto_2d_screen:

    ; FIXME: implement this!
    ; FIXME: implement this!
    ; FIXME: implement this!
    
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    ; FIXME: THIS IS *SLAP* CODE!
    
; FIXME: not using register x right now!    ldx #0 --> keeping SAME *order* of triangles!
    ldy #0
scale_and_position_next_triangle:
    
    ; -- Point 1 --
    MACRO_scale_and_position_on_screen_x TRIANGLES_3D_POINT1_X, TRIANGLES_POINT1_X
    MACRO_scale_and_position_on_screen_y TRIANGLES_3D_POINT1_Y, TRIANGLES_POINT1_Y
    
    ; -- Point 2 --
    MACRO_scale_and_position_on_screen_x TRIANGLES_3D_POINT2_X, TRIANGLES_POINT2_X
    MACRO_scale_and_position_on_screen_y TRIANGLES_3D_POINT2_Y, TRIANGLES_POINT2_Y
    
    ; -- Point 3 --
    MACRO_scale_and_position_on_screen_x TRIANGLES_3D_POINT3_X, TRIANGLES_POINT3_X
    MACRO_scale_and_position_on_screen_y TRIANGLES_3D_POINT3_Y, TRIANGLES_POINT3_Y
    
    iny
    
; FIXME: this is now a FIXED number, it probably shouldnt be in the future!
    cpy #NR_OF_TRIANGLES
    bne scale_and_position_next_triangle_jmp
    

    rts
    
scale_and_position_next_triangle_jmp:
    jmp scale_and_position_next_triangle

    
    
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
    

    
    
load_3d_triangle_data_into_ram:

    lda #<(triangle_3d_data)
    sta LOAD_ADDRESS
    lda #>(triangle_3d_data)
    sta LOAD_ADDRESS+1

    ldx #0
load_next_triangle:
    
    ldy #0
    
    ; -- Point 1 --
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT1_X, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT1_X+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT1_Y, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT1_Y+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT1_Z, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT1_Z+MAX_NR_OF_TRIANGLES, x
    
    ; -- Point 2 --
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT2_X, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT2_X+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT2_Y, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT2_Y+MAX_NR_OF_TRIANGLES, x

    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT2_Z, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT2_Z+MAX_NR_OF_TRIANGLES, x

    ; -- Point 3 --
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT3_X, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT3_X+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT3_Y, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT3_Y+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT3_Z, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINT3_Z+MAX_NR_OF_TRIANGLES, x
    
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_COLOR, x
    
    clc
    lda LOAD_ADDRESS
    adc #20             ; 10 words (3 * x, y and z, color uses only one byte, but takes space of a word)
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    inx
    
    cpx #NR_OF_TRIANGLES
    bne load_next_triangle_jmp

    rts
    
load_next_triangle_jmp:
    jmp load_next_triangle
    
    
    .if(1)
NR_OF_TRIANGLES = 2
triangle_3d_data:
    ;        x1,   y1,   z1,    x2,   y2,   z2,     x3,   y3,   z3,    cl
   .word      0,    0,    0,   $100,    0,    0,     0,  $100,    0,   29
   .word   $100,    0, $100,   $100, $100, $100,     0,  $100, $100,    2
palette_data:   
    ; dummy
end_of_palette_data:
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
