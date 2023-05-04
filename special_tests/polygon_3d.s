

; BUG: when turning on all options (SLOPE_TABLES and JUMP_TABLES) it shows horizontal "stripes" on real HW!

DO_SPEED_TEST = 1
KEEP_RUNNING = 1
USE_DOUBLE_BUFFER = 1  ; IMPORTANT: we cant show text AND do double buffering!
SLOW_DOWN = 0

; WEIRD BUG: when using JUMP_TABLES, the triangles look very 'edgy'!! --> it is 'SOLVED' by putting the jump FILL_LINE_CODE_x-block aligned to 256 bytes!?!?

USE_POLYGON_FILLER = 1
USE_SLOPE_TABLES = 1
USE_UNROLLED_LOOP = 1
USE_JUMP_TABLE = 1
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
SCREEN_HEIGHT = 200-1   ; FIXME: A minus 1 since we only have room (atm) for 199.7 lines! (we need to move the second buffer a little lower in vram)

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


ANGLE_X                  = $A7 ; A8  ; number between 0 and 511
ANGLE_Z                  = $A9 ; AA  ; number between 0 and 511

ANGLE                    = $AB ; AC
SINE_OUTPUT              = $AD ; AE
COSINE_OUTPUT            = $AF ; B0

TRANSLATE_Z              = $B1 ; B2
DO_CORRECT_WINDING       = $B3

DOT_PRODUCT              = $B4 ; B5
SUM_Z_DIFF               = $B6 ; B7

FRAME_BUFFER_INDEX       = $B8     ; 0 or 1: indicating which frame buffer is to be filled (for double buffering)

DEBUG_VALUE              = $C7



FILL_LENGTH_LOW_SOFT     = $2800
FILL_LENGTH_HIGH_SOFT    = $2801

; RAM addresses

CLEAR_COLUMN_CODE        = $2B00   ; takes up to 02D0

FILL_LINE_JUMP_TABLE     = $2E00
FILL_LINE_BELOW_16_CODE  = $2F00   ; 128 different (below 16 pixel) fill line code patterns -> safe: takes $0D00 bytes

; FIXME: can we put these jump tables closer to each other? Do they need to be aligned to 256 bytes? (they are 80 bytes each)
; FIXME: IMPORTANT: we set the two lower bits of this address in the code, using JUMP_TABLE_16_0 as base. So the distance between the 4 tables should stay $100! AND the two lower bits should stay 00b!
JUMP_TABLE_16_0          = $3C00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_0)
JUMP_TABLE_16_1          = $3D00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_1)
JUMP_TABLE_16_2          = $3E00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_2)
JUMP_TABLE_16_3          = $3F00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_CODE_3)

; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes? -> MORE than 256 bytes!!
FILL_LINE_CODE_0         = $4000   ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_1         = $4200   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_2         = $4400   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_CODE_3         = $4600   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

; Triangle data is (easely) accessed through an single index (0-127)
; == IMPORTANT: we assume a *clockwise* ordering of the 3 points of a triangle! ==
MAX_NR_OF_TRIANGLES      = 128
TRIANGLES_POINT1_X       = $4800 ; 4880
TRIANGLES_POINT1_Y       = $4900 ; 4980
TRIANGLES_POINT2_X       = $4A00 ; 4A80
TRIANGLES_POINT2_Y       = $4B00 ; 4B80
TRIANGLES_POINT3_X       = $4C00 ; 4C80
TRIANGLES_POINT3_Y       = $4D00 ; 4D80

TRIANGLES_ORG_COLOR      = $4E00 ; Only 128 bytes used
TRIANGLES_COLOR          = $4E80 ; Only 128 bytes used

; FIXME: We should instead use a series of POINTS and INDEXES to those points are used to define TRIANGLES!
TRIANGLES_3D_POINT1_X    = $5000 ; 5080
TRIANGLES_3D_POINT1_Y    = $5100 ; 5180
TRIANGLES_3D_POINT1_Z    = $5200 ; 5280
TRIANGLES_3D_POINT2_X    = $5300 ; 5380
TRIANGLES_3D_POINT2_Y    = $5400 ; 5480
TRIANGLES_3D_POINT2_Z    = $5500 ; 5580
TRIANGLES_3D_POINT3_X    = $5600 ; 5680
TRIANGLES_3D_POINT3_Y    = $5700 ; 5780
TRIANGLES_3D_POINT3_Z    = $5800 ; 5880
TRIANGLES_3D_POINTN_X    = $5900 ; 5980
TRIANGLES_3D_POINTN_Y    = $5A00 ; 5A80
TRIANGLES_3D_POINTN_Z    = $5B00 ; 5B80

TRIANGLES2_3D_POINT1_X   = $5C00 ; 5C80
TRIANGLES2_3D_POINT1_Y   = $5D00 ; 5D80
TRIANGLES2_3D_POINT1_Z   = $5E00 ; 5E80
TRIANGLES2_3D_POINT2_X   = $5F00 ; 5F80
TRIANGLES2_3D_POINT2_Y   = $6000 ; 6080
TRIANGLES2_3D_POINT2_Z   = $6100 ; 6180
TRIANGLES2_3D_POINT3_X   = $6200 ; 6280
TRIANGLES2_3D_POINT3_Y   = $6300 ; 6380
TRIANGLES2_3D_POINT3_Z   = $6400 ; 6480
TRIANGLES2_3D_POINTN_X   = $6500 ; 6580
TRIANGLES2_3D_POINTN_Y   = $6600 ; 6680
TRIANGLES2_3D_POINTN_Z   = $6700 ; 6780

TRIANGLES3_3D_POINT1_X   = $6800 ; 6880
TRIANGLES3_3D_POINT1_Y   = $6900 ; 6980
TRIANGLES3_3D_POINT1_Z   = $6A00 ; 6A80
TRIANGLES3_3D_POINT2_X   = $6B00 ; 6B80
TRIANGLES3_3D_POINT2_Y   = $6C00 ; 6C80
TRIANGLES3_3D_POINT2_Z   = $6D00 ; 6D80
TRIANGLES3_3D_POINT3_X   = $6E00 ; 6E80
TRIANGLES3_3D_POINT3_Y   = $6F00 ; 6F80
TRIANGLES3_3D_POINT3_Z   = $7000 ; 7080
TRIANGLES3_3D_POINTN_X   = $7100 ; 7180
TRIANGLES3_3D_POINTN_Y   = $7200 ; 7280
TRIANGLES3_3D_POINTN_Z   = $7300 ; 7380
TRIANGLES3_3D_SUM_Z      = $7400 ; 7480


Y_TO_ADDRESS_LOW         = $8400
Y_TO_ADDRESS_HIGH        = $8500
Y_TO_ADDRESS_BANK        = $8600
Y_TO_ADDRESS_BANK2       = $8700   ; Only use when double buffering

COPY_SLOPE_TABLES_TO_BANKED_RAM   = $8800

    .if(USE_POLYGON_FILLER)
DRAW_ROW_64_CODE         = $AA00   ; When USE_POLYGON_FILLER is 1: A000-A9FF and B600-BFFF are occucpied by the slope tables! (the latter by the 90-180 degrees slope tables)
    .else
DRAW_ROW_64_CODE         = $B500   ; When USE_POLYGON_FILLER is 0: A000-B4FF are occucpied by the slope tables!
    .endif

; ------------- VRAM addresses -------------

COLOR_PIXELS_ADDRESS     = $0FF00  ; The place where all color pixels are stored (the cache is filled with these colors) -> After the first frame buffer, just before the second frame buffer.

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
        jsr put_color_pixels_in_vram
    .endif
    
    .if(USE_Y_TO_ADDRESS_TABLE)
        jsr generate_y_to_address_table
    .endif
    
    .if(USE_SLOPE_TABLES)
        jsr copy_slope_table_copier_to_ram
        jsr COPY_SLOPE_TABLES_TO_BANKED_RAM
    .endif
    
    .if(DO_SPEED_TEST)
    
        lda #%00000000  ; DCSEL=0
        sta VERA_CTRL
       
        lda #BACKGROUND_COLOR
;        sta VERA_DC_BORDER
    
        .if(USE_DOUBLE_BUFFER)
            lda #%00010001           ; Enable Layer 0, Enable VGA
            sta VERA_DC_VIDEO
        .endif
    
        lda #%00000010  ; DCSEL=1
        sta VERA_CTRL
       
        lda #20
        sta VERA_DC_VSTART
        lda #SCREEN_HEIGHT+20-1
        sta VERA_DC_VSTOP
    
        .if(USE_DOUBLE_BUFFER)
            lda #1
            sta FRAME_BUFFER_INDEX
            jsr switch_frame_buffer   ; This will switch to filling buffer 0, but *showing* buffer 1
        .endif
        
        jsr test_speed_of_simple_3d_polygon_scene
    .else
        lda #%00000000           ; DCSEL=0, ADDRSEL=0
        sta VERA_CTRL
        
;        lda #$40                 ; 8:1 scale
;        sta VERA_DC_HSCALE
;        sta VERA_DC_VSCALE      
      
;        jsr ...
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

    
wait_for_a_while:

    lda #2
    sta TMP1
wait_256_256:
    stz TMP2
wait_256:
    stz TMP3
wait_1:
    inc TMP3
    nop
    nop
    nop
    bne wait_1
    
    inc TMP2
    bne wait_256
    
    dec TMP1
    bne wait_256_256

    rts
  
  
test_speed_of_simple_3d_polygon_scene:

    jsr load_3d_triangle_data_into_ram

    jsr start_timer
    
    jsr init_world
    
keep_running:
    
    .if (USE_POLYGON_FILLER || USE_WRITE_CACHE)
        jsr clear_screen_fast_4_bytes
    .else
        jsr clear_screen_slow
    .endif
    
    jsr calculate_projection_of_3d_onto_2d_screen
    jsr draw_all_triangles
    
    .if(KEEP_RUNNING)
        .if(USE_DOUBLE_BUFFER)
            jsr switch_frame_buffer   ; This will switch to filling buffer 0, but *showing* buffer 1
        .endif
        .if(SLOW_DOWN)
            jsr wait_for_a_while
        .endif
        jsr update_world
        bra keep_running
    .endif

    jsr stop_timer
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #2
    sta CURSOR_X
    lda #0
    sta CURSOR_Y

    lda #<simple_3d_polygon_scene_message
    sta TEXT_TO_PRINT
    lda #>simple_3d_polygon_scene_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    .if(0)
        lda #10
        sta CURSOR_X
        lda #2
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
        lda #21
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
        lda #22
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
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed
    
;    lda DEBUG_VALUE
;    sta BYTE_TO_PRINT
;    jsr print_byte_as_hex

    rts
 
 
switch_frame_buffer:

    lda FRAME_BUFFER_INDEX
    beq switch_to_filling_high_vram_buffer
    
switch_to_filling_low_vram_buffer:
    lda #0
    sta FRAME_BUFFER_INDEX
    
    ; While we are going to fill framebuffer 0, we *show* framebuffer 1
    ; VERA.layer0.tilebase = ; set new tilebase for layer 0 (0x10000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($100 >> 1)
    sta VERA_L0_TILEBASE

;    lda TMP4
;    beq tmp_over_loop
;tmp_loop:
;    jmp tmp_loop
;tmp_over_loop:
;    lda #1
;    sta TMP4
    
    rts
    
switch_to_filling_high_vram_buffer:
    lda #1
    sta FRAME_BUFFER_INDEX
    
    ; While we are going to fill framebuffer 1, we *show* framebuffer 0
    ; VERA.layer0.tilebase = ; set new tilebase for layer 0 (0x00000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($000 >> 1)
    sta VERA_L0_TILEBASE
    
    rts

    
    
init_world:    
    lda #0
    sta ANGLE_Z
    lda #0
    sta ANGLE_Z+1

    lda #0
    sta ANGLE_X
    lda #0
    sta ANGLE_X+1
    
    lda #$B8
    sta TRANSLATE_Z
    lda #$02
    sta TRANSLATE_Z+1
    
    rts
    
update_world:

    .if(1)
    clc
    lda ANGLE_Z
    adc #2
    sta ANGLE_Z
    lda ANGLE_Z+1
    adc #0
    sta ANGLE_Z+1

    cmp #2                ; we should never reach $200, we reset to 0 then
    bne angle_z_updated
    stz ANGLE_Z
    stz ANGLE_Z+1
angle_z_updated:
    .endif

    .if(1)
    clc
    lda ANGLE_X
    adc #1
    sta ANGLE_X
    lda ANGLE_X+1
    adc #0
    sta ANGLE_X+1

    cmp #2                ; we should never reach $200, we reset to 0 then
    bne angle_x_updated
    stz ANGLE_X
    stz ANGLE_X+1
angle_x_updated:
    .endif

    rts
    

    
    
MACRO_scale_and_position_on_screen_x .macro TRIANGLES_3D_POINT_X, TRIANGLES_POINT_X

    lda \TRIANGLES_3D_POINT_X, x
    sta TMP_POINT_X
    lda \TRIANGLES_3D_POINT_X+MAX_NR_OF_TRIANGLES, x
    sta TMP_POINT_X+1
    
    clc
    lda TMP_POINT_X+1
    bpl \@point_x_is_sign_extended
    sec
\@point_x_is_sign_extended:

    ; First we multiply by 128 (by dividing by 2)
    ror TMP_POINT_X+1
    ror TMP_POINT_X

    ; We then add half of the screen width
    clc
    lda TMP_POINT_X
    adc #<(SCREEN_WIDTH/2)
    sta \TRIANGLES_POINT_X, x
    
    lda TMP_POINT_X+1
    adc #>(SCREEN_WIDTH/2)
    sta \TRIANGLES_POINT_X+MAX_NR_OF_TRIANGLES, x

.endmacro
    
MACRO_scale_and_position_on_screen_y .macro TRIANGLES_3D_POINT_Y, TRIANGLES_POINT_Y

    lda \TRIANGLES_3D_POINT_Y, x
    sta TMP_POINT_Y
    lda \TRIANGLES_3D_POINT_Y+MAX_NR_OF_TRIANGLES, x
    sta TMP_POINT_Y+1
    
    clc
    lda TMP_POINT_Y+1
    bpl \@point_y_is_sign_extended
    sec
\@point_y_is_sign_extended:
    ; First we multiply by 128 (by dividing by 2)
    lsr TMP_POINT_Y+1
    ror TMP_POINT_Y
    
    ; We then add half of the screen width
    clc
    lda TMP_POINT_Y
    adc #<(SCREEN_HEIGHT/2)
    sta \TRIANGLES_POINT_Y, x
    
    lda TMP_POINT_Y+1
    adc #>(SCREEN_HEIGHT/2)
    sta \TRIANGLES_POINT_Y+MAX_NR_OF_TRIANGLES, x

.endmacro


MACRO_rotate_cos_minus_sin .macro INPUT_ANGLE, TRIANGLES_3D_POINT_A, TRIANGLES_3D_POINT_B, TRIANGLES_3D_POINT_OUTPUT

    ; - value = a*cos - b*sin -
    
    ; - a*cos -
    
    lda \INPUT_ANGLE
    sta ANGLE
    lda \INPUT_ANGLE+1
    sta ANGLE+1
    
    jsr get_cosine_for_angle ; Note: this *destroys* ANGLE!
    
    lda COSINE_OUTPUT
    sta MULTIPLIER
    lda COSINE_OUTPUT+1
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINT_A, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINT_A+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed
    
    ; TODO: rename this temp variable
    lda PRODUCT+1
    sta TMP_POINT_X
    lda PRODUCT+2
    sta TMP_POINT_X+1
    
    ; - b*sin -
    
    lda \INPUT_ANGLE
    sta ANGLE
    lda \INPUT_ANGLE+1
    sta ANGLE+1
    
    jsr get_sine_for_angle ; Note: this *destroys* ANGLE!
    
    lda SINE_OUTPUT
    sta MULTIPLIER
    lda SINE_OUTPUT+1
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINT_B, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINT_B+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed
    
    ; TODO: rename this temp variable
    sec
    lda TMP_POINT_X
    sbc PRODUCT+1
    sta \TRIANGLES_3D_POINT_OUTPUT, x
    lda TMP_POINT_X+1
    sbc PRODUCT+2
    sta \TRIANGLES_3D_POINT_OUTPUT+MAX_NR_OF_TRIANGLES, x

.endmacro


MACRO_rotate_sin_plus_cos .macro INPUT_ANGLE, TRIANGLES_3D_POINT_A, TRIANGLES_3D_POINT_B, TRIANGLES_3D_POINT_OUTPUT

    ; - value = a*sin + b*cos -
    
    ; - a*sin -
    
    lda \INPUT_ANGLE
    sta ANGLE
    lda \INPUT_ANGLE+1
    sta ANGLE+1
    
    jsr get_sine_for_angle ; Note: this *destroys* ANGLE!
    
    lda SINE_OUTPUT
    sta MULTIPLIER
    lda SINE_OUTPUT+1
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINT_A, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINT_A+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed
    
    ; TODO: rename this temp variable
    lda PRODUCT+1
    sta TMP_POINT_Y
    lda PRODUCT+2
    sta TMP_POINT_Y+1
    
    ; - b*cos -
    
    lda \INPUT_ANGLE
    sta ANGLE
    lda \INPUT_ANGLE+1
    sta ANGLE+1
    
    jsr get_cosine_for_angle ; Note: this *destroys* ANGLE!
    
    lda COSINE_OUTPUT
    sta MULTIPLIER
    lda COSINE_OUTPUT+1
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINT_B, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINT_B+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed
    
    ; TODO: rename this temp variable
    clc
    lda TMP_POINT_Y
    adc PRODUCT+1
    sta \TRIANGLES_3D_POINT_OUTPUT, x
    lda TMP_POINT_Y+1
    adc PRODUCT+2
    sta \TRIANGLES_3D_POINT_OUTPUT+MAX_NR_OF_TRIANGLES, x

.endmacro


MACRO_copy_point_value .macro TRIANGLES_3D_POINT_VALUE, OUTPUT_TRIANGLES_3D_POINT_VALUE
    lda \TRIANGLES_3D_POINT_VALUE,x
    sta \OUTPUT_TRIANGLES_3D_POINT_VALUE,x
    lda \TRIANGLES_3D_POINT_VALUE+MAX_NR_OF_TRIANGLES,x
    sta \OUTPUT_TRIANGLES_3D_POINT_VALUE+MAX_NR_OF_TRIANGLES,x
.endmacro



MACRO_translate_z .macro TRIANGLES_3D_POINT_Z, TRANSLATE_Z
    clc
    lda \TRIANGLES_3D_POINT_Z,x
    adc \TRANSLATE_Z
    sta \TRIANGLES_3D_POINT_Z,x
    lda \TRIANGLES_3D_POINT_Z+MAX_NR_OF_TRIANGLES,x
    adc \TRANSLATE_Z+1
    sta \TRIANGLES_3D_POINT_Z+MAX_NR_OF_TRIANGLES,x
.endmacro


DIVIDEND_IS_NEGATED=TMP2
MACRO_divide_by_z .macro TRIANGLES_3D_POINT_X_OR_Y, TRIANGLES_3D_POINT_Z, OUTPUT_TRIANGLES_3D_POINT_X_OR_Y

    ; We do the divide: TRIANGLES_3D_POINT_X_OR_Y * 256 / TRIANGLES_3D_POINT_Z
    
    lda \TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
    sta DIVIDEND+2
    lda \TRIANGLES_3D_POINT_X_OR_Y,x
    sta DIVIDEND+1
    lda #0
    sta DIVIDEND
    
    stz DIVIDEND_IS_NEGATED
    lda DIVIDEND+2
    bpl \@dividend_is_positive
    
    sec
    lda #0
    sbc DIVIDEND
    sta DIVIDEND
    lda #0
    sbc DIVIDEND+1
    sta DIVIDEND+1
    lda #0
    sbc DIVIDEND+2
    sta DIVIDEND+2
    
    lda #1
    sta DIVIDEND_IS_NEGATED
\@dividend_is_positive:

    lda #0
    sta DIVISOR+2
    lda \TRIANGLES_3D_POINT_Z+MAX_NR_OF_TRIANGLES,x
    sta DIVISOR+1
    lda \TRIANGLES_3D_POINT_Z,x
    sta DIVISOR

    jsr divide_24bits

    lda DIVIDEND_IS_NEGATED
    beq \@divide_output_is_valid
    
    sec
    lda #0
    sbc DIVIDEND
    sta DIVIDEND
    lda #0
    sbc DIVIDEND+1
    sta DIVIDEND+1
    lda #0
    sbc DIVIDEND+2
    sta DIVIDEND+2
    
\@divide_output_is_valid:

    ; We ignore the higher byte
    ;lda DIVIDEND+2
    ;sta \SLOPE+2
    lda DIVIDEND+1
    sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
    lda DIVIDEND
    sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y,x
    
.endmacro


MACRO_calculate_dot_product .macro TRIANGLES_3D_POINTA_X, TRIANGLES_3D_POINTA_Y, TRIANGLES_3D_POINTA_Z, TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES_3D_POINTN_Z

    ; To do the dot-product we have to do:
    ; A.x * N.x + A.y * N.y + A.z + N.z
    
    stz DOT_PRODUCT
    stz DOT_PRODUCT+1
    
    ; -- A.x * N.x
    
    lda \TRIANGLES_3D_POINTA_X,x
    sta MULTIPLIER
    lda \TRIANGLES_3D_POINTA_X+MAX_NR_OF_TRIANGLES,x
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINTN_X, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINTN_X+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed

    clc
    lda DOT_PRODUCT
    adc PRODUCT+1
    sta DOT_PRODUCT
    lda DOT_PRODUCT+1
    adc PRODUCT+2
    sta DOT_PRODUCT+1
    
    ; -- A.y * N.y
    
    lda \TRIANGLES_3D_POINTA_Y,x
    sta MULTIPLIER
    lda \TRIANGLES_3D_POINTA_Y+MAX_NR_OF_TRIANGLES,x
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINTN_Y, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINTN_Y+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed

    clc
    lda DOT_PRODUCT
    adc PRODUCT+1
    sta DOT_PRODUCT
    lda DOT_PRODUCT+1
    adc PRODUCT+2
    sta DOT_PRODUCT+1

    ; -- A.z * N.z
    
    lda \TRIANGLES_3D_POINTA_Z,x
    sta MULTIPLIER
    lda \TRIANGLES_3D_POINTA_Z+MAX_NR_OF_TRIANGLES,x
    sta MULTIPLIER+1

    lda \TRIANGLES_3D_POINTN_Z, x
    sta MULTIPLICAND
    lda \TRIANGLES_3D_POINTN_Z+MAX_NR_OF_TRIANGLES, x
    sta MULTIPLICAND+1

    jsr multply_16bits_signed

    clc
    lda DOT_PRODUCT
    adc PRODUCT+1
    sta DOT_PRODUCT
    lda DOT_PRODUCT+1
    adc PRODUCT+2
    sta DOT_PRODUCT+1

.endmacro



MACRO_calculate_sum_of_z .macro TRIANGLES_3D_POINT1_Z, TRIANGLES_3D_POINT2_Z, TRIANGLES_3D_POINT3_Z, TRIANGLES_3D_SUM_Z

    lda \TRIANGLES_3D_POINT1_Z,x
    sta \TRIANGLES_3D_SUM_Z,x
    lda \TRIANGLES_3D_POINT1_Z+MAX_NR_OF_TRIANGLES,x
    sta \TRIANGLES_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x
    
    clc
    lda \TRIANGLES_3D_SUM_Z,x
    adc \TRIANGLES_3D_POINT2_Z,x
    sta \TRIANGLES_3D_SUM_Z,x
    lda \TRIANGLES_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x
    adc \TRIANGLES_3D_POINT2_Z+MAX_NR_OF_TRIANGLES,x
    sta \TRIANGLES_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x

    clc
    lda \TRIANGLES_3D_SUM_Z,x
    adc \TRIANGLES_3D_POINT3_Z,x
    sta \TRIANGLES_3D_SUM_Z,x
    lda \TRIANGLES_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x
    adc \TRIANGLES_3D_POINT3_Z+MAX_NR_OF_TRIANGLES,x
    sta \TRIANGLES_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x

.endmacro


MACRO_copy_2d_triangle_to_2d_triangle .macro ; x = index of source triangle, y = index of destination triangle

    lda TRIANGLES_POINT1_X,x
    sta TRIANGLES_POINT1_X,y
    lda TRIANGLES_POINT1_Y,x
    sta TRIANGLES_POINT1_Y,y

    lda TRIANGLES_POINT2_X,x
    sta TRIANGLES_POINT2_X,y
    lda TRIANGLES_POINT2_Y,x
    sta TRIANGLES_POINT2_Y,y

    lda TRIANGLES_POINT3_X,x
    sta TRIANGLES_POINT3_X,y
    lda TRIANGLES_POINT3_Y,x
    sta TRIANGLES_POINT3_Y,y
    
    lda TRIANGLES_POINT1_X+MAX_NR_OF_TRIANGLES,x
    sta TRIANGLES_POINT1_X+MAX_NR_OF_TRIANGLES,y
    lda TRIANGLES_POINT1_Y+MAX_NR_OF_TRIANGLES,x
    sta TRIANGLES_POINT1_Y+MAX_NR_OF_TRIANGLES,y

    lda TRIANGLES_POINT2_X+MAX_NR_OF_TRIANGLES,x
    sta TRIANGLES_POINT2_X+MAX_NR_OF_TRIANGLES,y
    lda TRIANGLES_POINT2_Y+MAX_NR_OF_TRIANGLES,x
    sta TRIANGLES_POINT2_Y+MAX_NR_OF_TRIANGLES,y

    lda TRIANGLES_POINT3_X+MAX_NR_OF_TRIANGLES,x
    sta TRIANGLES_POINT3_X+MAX_NR_OF_TRIANGLES,y
    lda TRIANGLES_POINT3_Y+MAX_NR_OF_TRIANGLES,x
    sta TRIANGLES_POINT3_Y+MAX_NR_OF_TRIANGLES,y
    
    lda TRIANGLES_COLOR,x
    sta TRIANGLES_COLOR,y
.endmacro

calculate_projection_of_3d_onto_2d_screen:


    ldx #0
rotate_in_z_next_triangle:

    .if(1)
        ; -- Point 1 --
        MACRO_rotate_cos_minus_sin ANGLE_Z, TRIANGLES_3D_POINT1_X, TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_X
        MACRO_rotate_sin_plus_cos  ANGLE_Z, TRIANGLES_3D_POINT1_X, TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Y
        MACRO_copy_point_value TRIANGLES_3D_POINT1_Z, TRIANGLES2_3D_POINT1_Z
        
        ; -- Point 2 --
        MACRO_rotate_cos_minus_sin ANGLE_Z, TRIANGLES_3D_POINT2_X, TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_X
        MACRO_rotate_sin_plus_cos  ANGLE_Z, TRIANGLES_3D_POINT2_X, TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Y
        MACRO_copy_point_value TRIANGLES_3D_POINT2_Z, TRIANGLES2_3D_POINT2_Z

        ; -- Point 3 --
        MACRO_rotate_cos_minus_sin ANGLE_Z, TRIANGLES_3D_POINT3_X, TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_X
        MACRO_rotate_sin_plus_cos  ANGLE_Z, TRIANGLES_3D_POINT3_X, TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Y
        MACRO_copy_point_value TRIANGLES_3D_POINT3_Z, TRIANGLES2_3D_POINT3_Z

        ; -- Point N --
        MACRO_rotate_cos_minus_sin ANGLE_Z, TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_X
        MACRO_rotate_sin_plus_cos  ANGLE_Z, TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Y
        MACRO_copy_point_value TRIANGLES_3D_POINTN_Z, TRIANGLES2_3D_POINTN_Z
    .else
        ; -- Point 1 --
        MACRO_copy_point_value TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_X
        MACRO_copy_point_value TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Y
        MACRO_copy_point_value TRIANGLES_3D_POINT1_Z, TRIANGLES2_3D_POINT1_Z
        
        ; -- Point 2 --
        MACRO_copy_point_value TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_X
        MACRO_copy_point_value TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Y
        MACRO_copy_point_value TRIANGLES_3D_POINT2_Z, TRIANGLES2_3D_POINT2_Z

        ; -- Point 3 --
        MACRO_copy_point_value TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_X
        MACRO_copy_point_value TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Y
        MACRO_copy_point_value TRIANGLES_3D_POINT3_Z, TRIANGLES2_3D_POINT3_Z

        ; -- Point N --
        MACRO_copy_point_value TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_X
        MACRO_copy_point_value TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Y
        MACRO_copy_point_value TRIANGLES_3D_POINTN_Z, TRIANGLES2_3D_POINTN_Z
    .endif

    inx
    cpx #NR_OF_TRIANGLES
    beq rotate_in_z_done
    jmp rotate_in_z_next_triangle
rotate_in_z_done:


    ldx #0
rotate_in_x_next_triangle:
    
    .if(1)
        ; -- Point 1 --
        MACRO_rotate_cos_minus_sin ANGLE_X, TRIANGLES2_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Y
        MACRO_rotate_sin_plus_cos  ANGLE_X, TRIANGLES2_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Z
        MACRO_copy_point_value TRIANGLES2_3D_POINT1_X, TRIANGLES3_3D_POINT1_X
        
        ; -- Point 2 --
        MACRO_rotate_cos_minus_sin ANGLE_X, TRIANGLES2_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Y
        MACRO_rotate_sin_plus_cos  ANGLE_X, TRIANGLES2_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Z
        MACRO_copy_point_value TRIANGLES2_3D_POINT2_X, TRIANGLES3_3D_POINT2_X

        ; -- Point 3 --
        MACRO_rotate_cos_minus_sin ANGLE_X, TRIANGLES2_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Y
        MACRO_rotate_sin_plus_cos  ANGLE_X, TRIANGLES2_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Z
        MACRO_copy_point_value TRIANGLES2_3D_POINT3_X, TRIANGLES3_3D_POINT3_X
        
        ; -- Point N --
        MACRO_rotate_cos_minus_sin ANGLE_X, TRIANGLES2_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Y
        MACRO_rotate_sin_plus_cos  ANGLE_X, TRIANGLES2_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Z
        MACRO_copy_point_value TRIANGLES2_3D_POINTN_X, TRIANGLES3_3D_POINTN_X
    .else
        ; -- Point 1 --
        MACRO_copy_point_value TRIANGLES2_3D_POINT1_X, TRIANGLES3_3D_POINT1_X
        MACRO_copy_point_value TRIANGLES2_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Z
        
        ; -- Point 2 --
        MACRO_copy_point_value TRIANGLES2_3D_POINT2_X, TRIANGLES3_3D_POINT2_X
        MACRO_copy_point_value TRIANGLES2_3D_POINT2_Y, TRIANGLES3_3D_POINT2_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Z

        ; -- Point 3 --
        MACRO_copy_point_value TRIANGLES2_3D_POINT3_X, TRIANGLES3_3D_POINT3_X
        MACRO_copy_point_value TRIANGLES2_3D_POINT3_Y, TRIANGLES3_3D_POINT3_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Z
        
        ; -- Point N --
        MACRO_copy_point_value TRIANGLES2_3D_POINTN_X, TRIANGLES3_3D_POINTN_X
        MACRO_copy_point_value TRIANGLES2_3D_POINTN_Y, TRIANGLES3_3D_POINTN_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Z
    .endif
    
    inx
    cpx #NR_OF_TRIANGLES
    beq rotate_in_x_done
    jmp rotate_in_x_next_triangle
rotate_in_x_done:
    
    
    ldx #0
scale_and_position_next_triangle:

    ; -- Translate into z --
    MACRO_translate_z TRIANGLES3_3D_POINT1_Z, TRANSLATE_Z
    MACRO_translate_z TRIANGLES3_3D_POINT2_Z, TRANSLATE_Z
    MACRO_translate_z TRIANGLES3_3D_POINT3_Z, TRANSLATE_Z
    
    ; -- Copy color of triangle --
    
    lda TRIANGLES_ORG_COLOR,x
    sta TRIANGLES_COLOR,x
    
    ; -- We calculate the average Z (or actually: the *sum* of Z) for all 3 points --
    
    MACRO_calculate_sum_of_z TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_SUM_Z

    ; --  We check whether the triangle should be visible.
    ; FIXME: right now we *flip* two points to correct the winding of the triangle, but we shouldnt really show the triangle!
    ; We calculate the dot-product between point1 and pointN (the normal of the triange)
    MACRO_calculate_dot_product TRIANGLES3_3D_POINT1_X, TRIANGLES3_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINTN_X, TRIANGLES3_3D_POINTN_Y, TRIANGLES3_3D_POINTN_Z
    
    stz DO_CORRECT_WINDING
    lda DOT_PRODUCT+1
    bpl triangle_is_correctly_wounded
    lda #1
    sta DO_CORRECT_WINDING
triangle_is_correctly_wounded:
    
    ; -- Point 1 --
    MACRO_divide_by_z TRIANGLES3_3D_POINT1_X, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT1_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Y
    
    ; -- Point 2 --
    MACRO_divide_by_z TRIANGLES3_3D_POINT2_X, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT2_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT2_Y, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Y
    
    ; -- Point 3 --
    MACRO_divide_by_z TRIANGLES3_3D_POINT3_X, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_POINT3_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT3_Y, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Y
    
    lda DO_CORRECT_WINDING
    beq scale_and_dont_correct_winding
    jmp scale_and_correct_winding
    
scale_and_dont_correct_winding:
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT1_X, TRIANGLES_POINT1_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT1_Y, TRIANGLES_POINT1_Y
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT2_X, TRIANGLES_POINT2_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT2_Y, TRIANGLES_POINT2_Y
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT3_X, TRIANGLES_POINT3_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT3_Y, TRIANGLES_POINT3_Y
    jmp triangle_has_been_scaled_and_positioned
    
scale_and_correct_winding:
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT1_X, TRIANGLES_POINT2_X  ; pt1 -> pt2
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT1_Y, TRIANGLES_POINT2_Y  ; pt1 -> pt2
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT2_X, TRIANGLES_POINT1_X  ; pt2 -> pt1
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT2_Y, TRIANGLES_POINT1_Y  ; pt2 -> pt1
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT3_X, TRIANGLES_POINT3_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT3_Y, TRIANGLES_POINT3_Y
    
triangle_has_been_scaled_and_positioned:

    inx
    cpx #NR_OF_TRIANGLES
    beq scale_and_position_done
    jmp scale_and_position_next_triangle
scale_and_position_done:


    .if(1)
    ; FIXME: HACK: we "sort" the two triangles here in an UGLY hardcoded way!!
    sec
    ldy #0
    lda TRIANGLES3_3D_SUM_Z,y
    iny
    sbc TRIANGLES3_3D_SUM_Z,y
    sta SUM_Z_DIFF
    ldy #0
    lda TRIANGLES3_3D_SUM_Z+MAX_NR_OF_TRIANGLES,y
    iny
    sbc TRIANGLES3_3D_SUM_Z+MAX_NR_OF_TRIANGLES,y
    sta SUM_Z_DIFF+1
    
    bmi triangles_need_to_be_sorted
    jmp triangles_are_in_correct_order
    
triangles_need_to_be_sorted:
;    stp
    
; FIXME: VERY UGLY!!!
; FIXME: VERY UGLY!!!
; FIXME: VERY UGLY!!!

    ldx #0
    ldy #2
    MACRO_copy_2d_triangle_to_2d_triangle

    ldx #1
    ldy #0
    MACRO_copy_2d_triangle_to_2d_triangle 
    
    ldx #2
    ldy #1
    MACRO_copy_2d_triangle_to_2d_triangle 
    
triangles_are_in_correct_order:
    .endif


    rts
    
clear_screen_slow:
  
vera_wr_start:
    ldx #0
vera_wr_fill_bitmap_once:

    .if(USE_DOUBLE_BUFFER)
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
        ora FRAME_BUFFER_INDEX   ; this is either $00 or $01
        sta VERA_ADDR_BANK
    .else
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
        sta VERA_ADDR_BANK
    .endif
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #SCREEN_HEIGHT/8
vera_wr_fill_bitmap_col_once:
; FIXME: now drawing a pattern!
;    tya
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel

    dey
    bne vera_wr_fill_bitmap_col_once
    
    ; FIXME: workaround for SCREEN_HEIGHT = 199
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    
    inx
    bne vera_wr_fill_bitmap_once

    ; Right part of the screen

    ldx #0
vera_wr_fill_bitmap_once2:

    .if(USE_DOUBLE_BUFFER)
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
        ora FRAME_BUFFER_INDEX   ; this is either $00 or $01
        sta VERA_ADDR_BANK
    .else
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
        sta VERA_ADDR_BANK
    .endif
    lda #$01                ; The right side part of the screen has a start byte starting at address 256 and up
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #SCREEN_HEIGHT/8
vera_wr_fill_bitmap_col_once2:
; FIXME: now drawing a pattern!
;    tya
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    
    dey
    bne vera_wr_fill_bitmap_col_once2
    
    ; FIXME: workaround for SCREEN_HEIGHT = 199
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel
    sta VERA_DATA0           ; store pixel

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
    
    .if(USE_DOUBLE_BUFFER)
        ; lda #%00000000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 bytes (=0=%00000)
        lda FRAME_BUFFER_INDEX   ; this is either $00 or $01
        sta VERA_ADDR_BANK
    .else
        lda #%00000000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 bytes (=0=%00000)
        sta VERA_ADDR_BANK
    .endif
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

    .if(USE_DOUBLE_BUFFER)
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
        ora FRAME_BUFFER_INDEX   ; this is either $00 or $01
        sta VERA_ADDR_BANK
    .else
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
        sta VERA_ADDR_BANK
    .endif
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
    .if(USE_DOUBLE_BUFFER)
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
        ora FRAME_BUFFER_INDEX   ; this is either $00 or $01
        sta VERA_ADDR_BANK
    .else
        lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
        sta VERA_ADDR_BANK
    .endif
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
    cpx #SCREEN_HEIGHT     ; SCREEN_HEIGHT times clear pixels written to VERA
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

    ; -- Normal point --
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINTN_X, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINTN_X+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINTN_Y, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINTN_Y+MAX_NR_OF_TRIANGLES, x
    
    clc
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINTN_Z, x
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_3D_POINTN_Z+MAX_NR_OF_TRIANGLES, x

    ; -- Color --
    lda (LOAD_ADDRESS), y
    iny
    sta TRIANGLES_ORG_COLOR, x
    
    clc
    lda LOAD_ADDRESS
    adc #26             ; 13 words (4 * x, y and z, color uses only one byte, but takes space of a word)
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
    
    
get_sine_for_angle:

    ; We multiply the angle by 2 (shift left)
    asl ANGLE
    rol ANGLE+1
    
    ; We add the angle to the table base address
    clc
    lda #<sine_words
    adc ANGLE
    sta LOAD_ADDRESS
    lda #>sine_words
    adc ANGLE+1
    sta LOAD_ADDRESS+1
    
    ldy #0
    
    lda (LOAD_ADDRESS), y
    sta SINE_OUTPUT
    iny
    lda (LOAD_ADDRESS), y
    sta SINE_OUTPUT+1
    
    rts
    
get_cosine_for_angle:

    ; We multiply the angle by 2 (shift left)
    asl ANGLE
    rol ANGLE+1
    
    ; We add the angle to the table base address
    clc
    lda #<cosine_words
    adc ANGLE
    sta LOAD_ADDRESS
    lda #>cosine_words
    adc ANGLE+1
    sta LOAD_ADDRESS+1
    
    ldy #0
    
    lda (LOAD_ADDRESS), y
    sta COSINE_OUTPUT
    iny
    lda (LOAD_ADDRESS), y
    sta COSINE_OUTPUT+1
    
    rts
    
    
    .if(1)
NR_OF_TRIANGLES = 2
triangle_3d_data:

; FIXME: should we do a NEGATIVE or a NEGATIVE Z for the NORMAL?
    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)
    ;        x1,   y1,   z1,    x2,   y2,   z2,     x3,   y3,   z3,    xn,   yn,   zn,   cl
   .word      0,    0,    0,   $100,    0,    0,     0,  $100,    0,    0,    0, $100,   29
   .word   $100,    0, $100,   $100, $100, $100,     0,  $100, $100,    0,    0, $100,   2    ; FIXME: the winding on this triangle is actually WRONG! (and its normal too!) -> its the other side of a cube!
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

    
    ; === Cosine and sine tables ===

    .org $EF00
    
    ; FIXME: put this in a more general place!

    ; Python script to generate sine and cosine words    
    ;   import math
    ;   cycle=512
    ;   ampl=256   # -256 ($FF.00) to +256 ($01.00)
    ;   [int(math.sin(float(i)/cycle*2.0*math.pi)*ampl+0.5) for i in range(cycle)]
    ;   [int(math.cos(float(i)/cycle*2.0*math.pi)*ampl+0.5) for i in range(cycle)]
    
    ; FIXME: it now goes from +256 to -255. But we probably want +256 to -256
sine_words:
    .word 0, 3, 6, 9, 13, 16, 19, 22, 25, 28, 31, 34, 38, 41, 44, 47, 50, 53, 56, 59, 62, 65, 68, 71, 74, 77, 80, 83, 86, 89, 92, 95, 98, 101, 104, 107, 109, 112, 115, 118, 121, 123, 126, 129, 132, 134, 137, 140, 142, 145, 147, 150, 152, 155, 157, 160, 162, 165, 167, 170, 172, 174, 177, 179, 181, 183, 185, 188, 190, 192, 194, 196, 198, 200, 202, 204, 206, 207, 209, 211, 213, 215, 216, 218, 220, 221, 223, 224, 226, 227, 229, 230, 231, 233, 234, 235, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 248, 249, 250, 250, 251, 252, 252, 253, 253, 254, 254, 254, 255, 255, 255, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 255, 255, 255, 254, 254, 254, 253, 253, 252, 252, 251, 250, 250, 249, 248, 248, 247, 246, 245, 244, 243, 242, 241, 240, 239, 238, 237, 235, 234, 233, 231, 230, 229, 227, 226, 224, 223, 221, 220, 218, 216, 215, 213, 211, 209, 207, 206, 204, 202, 200, 198, 196, 194, 192, 190, 188, 185, 183, 181, 179, 177, 174, 172, 170, 167, 165, 162, 160, 157, 155, 152, 150, 147, 145, 142, 140, 137, 134, 132, 129, 126, 123, 121, 118, 115, 112, 109, 107, 104, 101, 98, 95, 92, 89, 86, 83, 80, 77, 74, 71, 68, 65, 62, 59, 56, 53, 50, 47, 44, 41, 38, 34, 31, 28, 25, 22, 19, 16, 13, 9, 6, 3, 0, -2, -5, -8, -12, -15, -18, -21, -24, -27, -30, -33, -37, -40, -43, -46, -49, -52, -55, -58, -61, -64, -67, -70, -73, -76, -79, -82, -85, -88, -91, -94, -97, -100, -103, -106, -108, -111, -114, -117, -120, -122, -125, -128, -131, -133, -136, -139, -141, -144, -146, -149, -151, -154, -156, -159, -161, -164, -166, -169, -171, -173, -176, -178, -180, -182, -184, -187, -189, -191, -193, -195, -197, -199, -201, -203, -205, -206, -208, -210, -212, -214, -215, -217, -219, -220, -222, -223, -225, -226, -228, -229, -230, -232, -233, -234, -236, -237, -238, -239, -240, -241, -242, -243, -244, -245, -246, -247, -247, -248, -249, -249, -250, -251, -251, -252, -252, -253, -253, -253, -254, -254, -254, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -254, -254, -254, -253, -253, -253, -252, -252, -251, -251, -250, -249, -249, -248, -247, -247, -246, -245, -244, -243, -242, -241, -240, -239, -238, -237, -236, -234, -233, -232, -230, -229, -228, -226, -225, -223, -222, -220, -219, -217, -215, -214, -212, -210, -208, -206, -205, -203, -201, -199, -197, -195, -193, -191, -189, -187, -184, -182, -180, -178, -176, -173, -171, -169, -166, -164, -161, -159, -156, -154, -151, -149, -146, -144, -141, -139, -136, -133, -131, -128, -125, -122, -120, -117, -114, -111, -108, -106, -103, -100, -97, -94, -91, -88, -85, -82, -79, -76, -73, -70, -67, -64, -61, -58, -55, -52, -49, -46, -43, -40, -37, -33, -30, -27, -24, -21, -18, -15, -12, -8, -5, -2
cosine_words:
    .word 256, 256, 256, 256, 256, 256, 255, 255, 255, 254, 254, 254, 253, 253, 252, 252, 251, 250, 250, 249, 248, 248, 247, 246, 245, 244, 243, 242, 241, 240, 239, 238, 237, 235, 234, 233, 231, 230, 229, 227, 226, 224, 223, 221, 220, 218, 216, 215, 213, 211, 209, 207, 206, 204, 202, 200, 198, 196, 194, 192, 190, 188, 185, 183, 181, 179, 177, 174, 172, 170, 167, 165, 162, 160, 157, 155, 152, 150, 147, 145, 142, 140, 137, 134, 132, 129, 126, 123, 121, 118, 115, 112, 109, 107, 104, 101, 98, 95, 92, 89, 86, 83, 80, 77, 74, 71, 68, 65, 62, 59, 56, 53, 50, 47, 44, 41, 38, 34, 31, 28, 25, 22, 19, 16, 13, 9, 6, 3, 0, -2, -5, -8, -12, -15, -18, -21, -24, -27, -30, -33, -37, -40, -43, -46, -49, -52, -55, -58, -61, -64, -67, -70, -73, -76, -79, -82, -85, -88, -91, -94, -97, -100, -103, -106, -108, -111, -114, -117, -120, -122, -125, -128, -131, -133, -136, -139, -141, -144, -146, -149, -151, -154, -156, -159, -161, -164, -166, -169, -171, -173, -176, -178, -180, -182, -184, -187, -189, -191, -193, -195, -197, -199, -201, -203, -205, -206, -208, -210, -212, -214, -215, -217, -219, -220, -222, -223, -225, -226, -228, -229, -230, -232, -233, -234, -236, -237, -238, -239, -240, -241, -242, -243, -244, -245, -246, -247, -247, -248, -249, -249, -250, -251, -251, -252, -252, -253, -253, -253, -254, -254, -254, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -255, -254, -254, -254, -253, -253, -253, -252, -252, -251, -251, -250, -249, -249, -248, -247, -247, -246, -245, -244, -243, -242, -241, -240, -239, -238, -237, -236, -234, -233, -232, -230, -229, -228, -226, -225, -223, -222, -220, -219, -217, -215, -214, -212, -210, -208, -206, -205, -203, -201, -199, -197, -195, -193, -191, -189, -187, -184, -182, -180, -178, -176, -173, -171, -169, -166, -164, -161, -159, -156, -154, -151, -149, -146, -144, -141, -139, -136, -133, -131, -128, -125, -122, -120, -117, -114, -111, -108, -106, -103, -100, -97, -94, -91, -88, -85, -82, -79, -76, -73, -70, -67, -64, -61, -58, -55, -52, -49, -46, -43, -40, -37, -33, -30, -27, -24, -21, -18, -15, -12, -8, -5, -2, 0, 3, 6, 9, 13, 16, 19, 22, 25, 28, 31, 34, 38, 41, 44, 47, 50, 53, 56, 59, 62, 65, 68, 71, 74, 77, 80, 83, 86, 89, 92, 95, 98, 101, 104, 107, 109, 112, 115, 118, 121, 123, 126, 129, 132, 134, 137, 140, 142, 145, 147, 150, 152, 155, 157, 160, 162, 165, 167, 170, 172, 174, 177, 179, 181, 183, 185, 188, 190, 192, 194, 196, 198, 200, 202, 204, 206, 207, 209, 211, 213, 215, 216, 218, 220, 221, 223, 224, 226, 227, 229, 230, 231, 233, 234, 235, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 248, 249, 250, 250, 251, 252, 252, 253, 253, 254, 254, 254, 255, 255, 255, 256, 256, 256, 256, 256
    
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