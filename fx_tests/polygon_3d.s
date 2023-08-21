
; FIXME: we add nops after switching RAM_BANK. This is needed for the Breadboard of JeffreyH but not on stock hardware! Maybe add a setting to turn this on/off.

DO_SPEED_TEST = 1
DO_4BIT = 0
DO_2BIT = 0
KEEP_RUNNING = 1
USE_LIGHT = 0
USE_KEYBOARD_INPUT = 0
USE_DOUBLE_BUFFER = 1  ; IMPORTANT: we cant show text AND do double buffering!
SLOW_DOWN = 0

; WEIRD BUG: when using JUMP_TABLES, the triangles look very 'edgy'!! --> it is 'SOLVED' by putting the jump FILL_LINE_END_CODE_x-block aligned to 256 bytes!?!?

USE_POLYGON_FILLER = 1
USE_FX_MULTIPLIER = 1
USE_SLOPE_TABLES = 1
USE_DIV_TABLES = 1
USE_UNROLLED_LOOP = 1
USE_JUMP_TABLE = 1
USE_WRITE_CACHE = USE_JUMP_TABLE ; TODO: do we want to separate these options? (they are now always the same)

TEST_JUMP_TABLE = 0 ; This turns off the iteration in-between the jump-table calls
USE_SOFT_FILL_LEN = 0; ; This turns off reading from 9F2B and 9F2C (for fill length data) and instead reads from USE_SOFT_FILL_LEN-variables

USE_180_DEGREES_SLOPE_TABLE = 1  ; When in polygon filler mode and slope tables turned on, its possible to use a 180 degrees slope table

USE_Y_TO_ADDRESS_TABLE = 1

    .if (USE_POLYGON_FILLER || USE_WRITE_CACHE)
BACKGROUND_COLOR = 251  ; Nice purple
    .else
BACKGROUND_COLOR = 06  ; Blue 
    .endif

; FIXME: make this dependent on the 2/4/8 bit mode!    
NR_OF_BYTES_PER_LINE = 320
    
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
END_JUMP_ADDRESS          = $2B ; 2C
START_JUMP_ADDRESS        = $2D ; 2E
CODE_ADDRESS              = $2F ; 30
LOAD_ADDRESS              = $31 ; 32
STORE_ADDRESS             = $33 ; 34

TABLE_ROM_BANK            = $35
DRAW_LENGTH               = $36  ; for generating draw code

TRIANGLE_COUNT            = $37
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
NR_OF_FULL_CACHE_WRITES  = $99
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
MINUS_SINE_OUTPUT        = $AF ; B0
COSINE_OUTPUT            = $B1 ; B2
; FIXME: not used atm!
MINUS_COSINE_OUTPUT      = $B3 ; B4

TRANSLATE_Z              = $B5 ; B6

DOT_PRODUCT              = $B7 ; B8
CURRENT_SUM_Z            = $B9 ; BA

FRAME_BUFFER_INDEX       = $BB     ; 0 or 1: indicating which frame buffer is to be filled (for double buffering)

CURRENT_LINKED_LIST_ENTRY  = $BC
PREVIOUS_LINKED_LIST_ENTRY = $BD
LINKED_LIST_NEW_ENTRY      = $BE

DELTA_ANGLE_X              = $C0 ; C1
DELTA_ANGLE_Y              = $C2 ; C3
DELTA_ANGLE_Z              = $C4 ; C5

NR_OF_KBD_KEY_CODE_BYTES   = $C6     ; Required by keyboard.s

LIGHT_DIRECTION_3D_X       = $C7 ; C8
LIGHT_DIRECTION_3D_Y       = $C9 ; CA
LIGHT_DIRECTION_3D_Z       = $CB ; CC


DEBUG_VALUE                = $D0



FILL_LENGTH_LOW_SOFT     = $2800
FILL_LENGTH_HIGH_SOFT    = $2801

; RAM addresses

KEYBOARD_STATE           = $2A80   ; 128 bytes (state for each key of the keyboard)
CLEAR_COLUMN_CODE        = $2B00   ; takes up to 02D0
KEYBOARD_KEY_CODE_BUFFER = $2DE0   ; 32 bytes (can be much less, since compact key codes are used now) -> used by keyboard.s

FILL_LINE_START_JUMP     = $2E00
FILL_LINE_START_CODE     = $2F00   ; 128 different (start of) fill line code patterns -> safe: takes $0D00 bytes

; FIXME: can we put these jump tables closer to each other? Do they need to be aligned to 256 bytes? (they are 80 bytes each)
; FIXME: IMPORTANT: we set the two lower bits of this address in the code, using FILL_LINE_END_JUMP_0 as base. So the distance between the 4 tables should stay $100! AND the two lower bits should stay 00b!
FILL_LINE_END_JUMP_0     = $3C00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_0)
FILL_LINE_END_JUMP_1     = $3D00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_1)
FILL_LINE_END_JUMP_2     = $3E00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_2)
FILL_LINE_END_JUMP_3     = $3F00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_3)

; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes? -> MORE than 256 bytes!!
FILL_LINE_END_CODE_0     = $4000   ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_END_CODE_1     = $4200   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_END_CODE_2     = $4400   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_END_CODE_3     = $4600   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

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

TRIANGLES_LINKED_LIST_INDEX = $4F00 ; Only 128 bytes used
TRIANGLES_LINKED_LIST_NEXT  = $4F80 ; Only 128 bytes used

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

COPY_SLOPE_TABLES_TO_BANKED_RAM = $8800  ; TODO: is this smaller than 256 bytes?
COPY_DIV_TABLES_TO_BANKED_RAM   = $8900

    .if(USE_POLYGON_FILLER)
DRAW_ROW_64_CODE         = $AA00   ; When USE_POLYGON_FILLER is 1: A000-A9FF and B600-BFFF are occucpied by the slope tables! (the latter by the 90-180 degrees slope tables)
    .else
DRAW_ROW_64_CODE         = $B500   ; When USE_POLYGON_FILLER is 0: A000-B4FF are occucpied by the slope tables!
    .endif

; ------------- VRAM addresses -------------

MATH_RESULTS_ADDRESS     = $0FF00  ; The place where all math results are stored -> After the first frame buffer, just before the second frame buffer.



  .org $C000

reset:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs

    jsr setup_vera_for_bitmap_and_tile_map
    .if(USE_DOUBLE_BUFFER)
        lda #%00000001           ; Disable Layer 0 and 1, Enable VGA
        sta VERA_DC_VIDEO
    .endif
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor
    jsr init_keyboard
    jsr init_timer

    .if (USE_WRITE_CACHE)
        jsr generate_clear_column_code
        jsr clear_screen_fast_4_bytes
    .else
        jsr clear_screen_slow
    .endif
    
    
    .if(USE_UNROLLED_LOOP)
        jsr generate_draw_row_64_code
    .endif
    
    .if(USE_JUMP_TABLE)
        jsr generate_fill_line_end_code
        jsr generate_fill_line_end_jump
        jsr generate_fill_line_start_code_and_jump
    .endif
    
    .if(USE_Y_TO_ADDRESS_TABLE)
        jsr generate_y_to_address_table
    .endif
    
    .if(USE_SLOPE_TABLES)
        jsr copy_slope_table_copier_to_ram
        jsr COPY_SLOPE_TABLES_TO_BANKED_RAM
    .endif
    
    .if(USE_DIV_TABLES)
        jsr copy_div_table_copier_to_ram
        jsr COPY_DIV_TABLES_TO_BANKED_RAM
    .endif
    
    .if(DO_SPEED_TEST)
    
        lda #%00000000  ; DCSEL=0
        sta VERA_CTRL
       
        lda #BACKGROUND_COLOR
;        sta VERA_DC_BORDER

        .if(USE_DOUBLE_BUFFER)
            lda #1
            sta FRAME_BUFFER_INDEX
            
            .if (USE_WRITE_CACHE)
                jsr clear_screen_fast_4_bytes
            .else
                jsr clear_screen_slow
            .endif
            
            jsr switch_frame_buffer   ; This will switch to filling buffer 0, but *showing* buffer 1
            
        .endif

        .if(USE_DOUBLE_BUFFER)
            lda #%00000000  ; DCSEL=0
            sta VERA_CTRL
            lda #%00010001           ; Only enable Layer 0, Enable VGA
            sta VERA_DC_VIDEO
        .endif
    
    
        lda #%00000010  ; DCSEL=1
        sta VERA_CTRL
       
        lda #20
        sta VERA_DC_VSTART
        lda #SCREEN_HEIGHT+20-1
        sta VERA_DC_VSTOP
    
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

    jsr copy_palette_from_index_16

    jsr load_3d_triangle_data_into_ram

    jsr start_timer
    
    jsr init_world
    
keep_running:
    
    .if (USE_WRITE_CACHE)
        jsr clear_screen_fast_4_bytes
    .else
        jsr clear_screen_slow
    .endif
    
    jsr calculate_projection_of_3d_onto_2d_screen
    
    .if(0)
        .if(USE_POLYGON_FILLER)
            ; Turning off polygon filler mode and blit writes
            lda #%00000100           ; DCSEL=2, ADDRSEL=0
            sta VERA_CTRL

            lda #%00000000           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
            sta VERA_FX_CTRL
        .endif
        
        lda #%00000000           ; DCSEL=0, ADDRSEL=0
        sta VERA_CTRL
        
    .endif
    
    
; FIXME!
    jsr draw_all_triangles
    
    .if(KEEP_RUNNING)
        .if(USE_DOUBLE_BUFFER)
            jsr switch_frame_buffer   ; This will switch to filling buffer 0, but *showing* buffer 1
        .endif
        .if(SLOW_DOWN)
            jsr wait_for_a_while
        .endif
        jsr get_user_input
        jsr update_world
        bra keep_running
    .endif

    jsr stop_timer
    
    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #2
    sta CURSOR_X
    lda #1
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
    lda #23
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
    lda #48
; FIXME!
;    lda #0
    sta ANGLE_Z
    lda #0
    sta ANGLE_Z+1

    lda #44
; FIXME!
;    lda #0
    sta ANGLE_X
    lda #0
    sta ANGLE_X+1
    
    .if(0)
    lda #$D8
    sta TRANSLATE_Z
    lda #$02
    sta TRANSLATE_Z+1
    .endif
    
    .if(1)
    lda #$D8
    sta TRANSLATE_Z
    lda #$08
    sta TRANSLATE_Z+1
    .endif
    
    
    ; Light direction
;    lda #153
    lda #0
    sta LIGHT_DIRECTION_3D_X
    lda #0
    sta LIGHT_DIRECTION_3D_X+1
    
    lda #0
    sta LIGHT_DIRECTION_3D_Y
    lda #0
    sta LIGHT_DIRECTION_3D_Y+1
    
;    lda #204
    lda #0
    sta LIGHT_DIRECTION_3D_Z
;    lda #0
    lda #1
    sta LIGHT_DIRECTION_3D_Z+1
    
    
    
    rts
    
update_world:

    stz DELTA_ANGLE_X
    stz DELTA_ANGLE_X+1
    stz DELTA_ANGLE_Y
    stz DELTA_ANGLE_Y+1
    stz DELTA_ANGLE_Z
    stz DELTA_ANGLE_Z+1
    
    .if(USE_KEYBOARD_INPUT)

; FIXME: what we really should do is determine which part of x,y,z has to be adjusted due to a left array key press (= dependent on the ship orientation)

        ; -- Left arrow key --
        ldx #KEY_CODE_LEFT_ARROW
        lda KEYBOARD_STATE, x
        beq left_arrow_key_down_handled
        
        lda #<(2)
        sta DELTA_ANGLE_Z
        lda #>(2)
        sta DELTA_ANGLE_Z+1
left_arrow_key_down_handled:

        ; -- Right arrow key --
        ldx #KEY_CODE_RIGHT_ARROW
        lda KEYBOARD_STATE, x
        beq right_arrow_key_down_handled
        
        lda #<(-2)
        sta DELTA_ANGLE_Z
        lda #>(-2)
        sta DELTA_ANGLE_Z+1
right_arrow_key_down_handled:

        ; -- Up arrow key --
        ldx #KEY_CODE_UP_ARROW
        lda KEYBOARD_STATE, x
        beq up_arrow_key_down_handled
        
        lda #<(2)
        sta DELTA_ANGLE_X
        lda #>(2)
        sta DELTA_ANGLE_X+1
up_arrow_key_down_handled:

        ; -- Down arrow key --
        ldx #KEY_CODE_DOWN_ARROW
        lda KEYBOARD_STATE, x
        beq down_arrow_key_down_handled
        
        lda #<(-2)
        sta DELTA_ANGLE_X
        lda #>(-2)
        sta DELTA_ANGLE_X+1
down_arrow_key_down_handled:

    .else
        lda #2
        sta DELTA_ANGLE_Z
        lda #1
        sta DELTA_ANGLE_X
    .endif
    
    
    ; -- Update ANGLE_Z --
    clc
    lda ANGLE_Z
    adc DELTA_ANGLE_Z
    sta ANGLE_Z
    lda ANGLE_Z+1
    adc DELTA_ANGLE_Z+1
    sta ANGLE_Z+1

    bpl angle_z_is_positive
    clc
    adc #$2               ; We have a negative angle, so we have to add $200
    sta ANGLE_Z+1
    bra angle_z_updated
angle_z_is_positive:
    cmp #2                ; we should never reach $200, we are >= $200
    bne angle_z_updated
    sec
    sbc #$2               ; We have a angle >= $200, so we have to subtract $200
    sta ANGLE_Z+1
angle_z_updated:

    ; -- Update ANGLE_X --
    clc
    lda ANGLE_X
    adc DELTA_ANGLE_X
    sta ANGLE_X
    lda ANGLE_X+1
    adc DELTA_ANGLE_X+1
    sta ANGLE_X+1

    bpl angle_x_is_positive
    clc
    adc #$2               ; We have a negative angle, so we have to add $200
    sta ANGLE_X+1
    bra angle_x_updated
angle_x_is_positive:
    cmp #2                ; we should never reach $200, we are >= $200
    bne angle_x_updated
    sec
    sbc #$2               ; We have a angle >= $200, so we have to subtract $200
    sta ANGLE_X+1
angle_x_updated:

    rts
    

get_user_input:

    jsr retrieve_keyboard_key_codes
    jsr update_keyboard_state

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
    sta \TRIANGLES_POINT_X, y
    
    lda TMP_POINT_X+1
    adc #>(SCREEN_WIDTH/2)
    sta \TRIANGLES_POINT_X+MAX_NR_OF_TRIANGLES, y

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
    ror TMP_POINT_Y+1
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


MACRO_load_sine .macro INPUT_ANGLE
    lda \INPUT_ANGLE
    sta ANGLE
    lda \INPUT_ANGLE+1
    sta ANGLE+1
    
    jsr get_sine_for_angle ; Note: this *destroys* ANGLE!
    
    ; Note: this outputs into SINE_OUTPUT
.endmacro

MACRO_load_cosine .macro INPUT_ANGLE
    lda \INPUT_ANGLE
    sta ANGLE
    lda \INPUT_ANGLE+1
    sta ANGLE+1
    
    jsr get_cosine_for_angle ; Note: this *destroys* ANGLE!
    
    ; Note: this outputs into COSINE_OUTPUT
.endmacro

MACRO_rotate_cos_minus_sin .macro TRIANGLES_3D_POINT_A, TRIANGLES_3D_POINT_B, TRIANGLES_3D_POINT_OUTPUT

    ; - value = a*cos - b*sin -
    
    ; - a*cos -
    
    .if(USE_FX_MULTIPLIER)
    
        lda VERA_FX_ACCUM_RESET   ; reset accumulator
    
        lda COSINE_OUTPUT
        sta VERA_FX_CACHE_L
        lda COSINE_OUTPUT+1
        sta VERA_FX_CACHE_M
    
        lda \TRIANGLES_3D_POINT_A, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINT_A+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U
        
        lda VERA_FX_ACCUM         ; accumulate
    .else 
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
    .endif
        
    ; - b*sin -
    
    .if(USE_FX_MULTIPLIER)
        ; Note: we are using MINUS sine here, since we want to subtract! (but we are in add-mode)
        lda MINUS_SINE_OUTPUT
        sta VERA_FX_CACHE_L
        lda MINUS_SINE_OUTPUT+1
        sta VERA_FX_CACHE_M
        
        lda \TRIANGLES_3D_POINT_B, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINT_B+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U
        
        ; We write the multiplication result to VRAM
        stz VERA_DATA0

; FIXME: WORKAROUND! We need to make sure DATA1 is re-read after storing to the same address!
        lda #>MATH_RESULTS_ADDRESS
        sta VERA_ADDR_HIGH
        
        ; We read (with 16-bit hop) the middle two bytes of the result from VRAM
        ; TODO: rename this temp variable
        lda VERA_DATA1
        sta \TRIANGLES_3D_POINT_OUTPUT, x
        lda VERA_DATA1
        sta \TRIANGLES_3D_POINT_OUTPUT+MAX_NR_OF_TRIANGLES, x
    .else
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
    .endif

.endmacro


MACRO_rotate_sin_plus_cos .macro TRIANGLES_3D_POINT_A, TRIANGLES_3D_POINT_B, TRIANGLES_3D_POINT_OUTPUT

    ; - value = a*sin + b*cos -
    
    ; - a*sin -
    
    .if(USE_FX_MULTIPLIER)
    
        lda VERA_FX_ACCUM_RESET  ; reset accumulator
    
        lda SINE_OUTPUT
        sta VERA_FX_CACHE_L
        lda SINE_OUTPUT+1
        sta VERA_FX_CACHE_M
    
        lda \TRIANGLES_3D_POINT_A, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINT_A+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U
        
        lda VERA_FX_ACCUM        ; accumulate
    .else 
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
    .endif
    
    ; - b*cos -
    
    .if(USE_FX_MULTIPLIER)
        lda COSINE_OUTPUT
        sta VERA_FX_CACHE_L
        lda COSINE_OUTPUT+1
        sta VERA_FX_CACHE_M
        
        lda \TRIANGLES_3D_POINT_B, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINT_B+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U
        
        ; We write the multiplication result to VRAM
        stz VERA_DATA0

; FIXME: WORKAROUND! We need to make sure DATA1 is re-read after storing to the same address!
        lda #>MATH_RESULTS_ADDRESS
        sta VERA_ADDR_HIGH
        
        ; We read (with 16-bit hop) the middle two bytes of the result from VRAM
        ; TODO: rename this temp variable
        lda VERA_DATA1
        sta \TRIANGLES_3D_POINT_OUTPUT, x
        lda VERA_DATA1
        sta \TRIANGLES_3D_POINT_OUTPUT+MAX_NR_OF_TRIANGLES, x
        
    .else
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
    .endif

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


; NOTE: this affects register y when USE_DIV_TABLES is 1!
; FIXME: its dangerous to mask TMP2 here!
DIVIDEND_IS_NEGATED=TMP2
MACRO_divide_by_z .macro TRIANGLES_3D_POINT_X_OR_Y, TRIANGLES_3D_POINT_Z, OUTPUT_TRIANGLES_3D_POINT_X_OR_Y


    .if(USE_DIV_TABLES)
    
        ; We do the multiply: TRIANGLES_3D_POINT_X_OR_Y * 1 / TRIANGLES_3D_POINT_Z
        
        ; First we get the 1/Z from the div table. We need:
        ;   y = Z_LOW
        ;   RAM_BANK = Z_HIGH[5:0]
        ;   LOAD_ADDR_HIGH[1] = Z_HIGH[6]
            
        ldy \TRIANGLES_3D_POINT_Z,x
        
        lda \TRIANGLES_3D_POINT_Z+MAX_NR_OF_TRIANGLES,x

        and #%00111111
        sta RAM_BANK
; FIXME: remove nop!
        nop
    
        ; TODO: we have limited Z to a *positive* (15-bit: 7.8 fixed point) number, we might not want that!
        lda \TRIANGLES_3D_POINT_Z+MAX_NR_OF_TRIANGLES,x
        asl a     ; shifts Z_HIGH[7] into carry (ignored)
        stz TMP3
        asl a     ; shifts Z_HIGH[6] into carry
        rol TMP3  ; 0000000, Z_HIGH[6]
        asl TMP3  ; 000000, Z_HIGH[6], 0
        lda TMP3
        
        ; SPEED: we can put this OUTSIDE of this macro!
        ; Our base address is $B000
        stz LOAD_ADDRESS
        
        ; We combine bit 1 with B0
        ora #>($B000)
        sta LOAD_ADDRESS+1

        .if(USE_FX_MULTIPLIER)
            lda VERA_FX_ACCUM_RESET   ; reset accumulator
    
            ; We load the INVERSE_Z_LOW
            lda (LOAD_ADDRESS), y
            sta VERA_FX_CACHE_L
            
            ; We load the INVERSE_Z_HIGH
            inc LOAD_ADDRESS+1
            lda (LOAD_ADDRESS), y
            sta VERA_FX_CACHE_M

            lda \TRIANGLES_3D_POINT_X_OR_Y,x
            sta VERA_FX_CACHE_H
            lda \TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
            sta VERA_FX_CACHE_U

            ; -- X (or Y) * 1 / Z
            
            ; We write the multiplication result to VRAM
            stz VERA_DATA0
        
; FIXME: WORKAROUND! We need to make sure DATA1 is re-read after storing to the same address!
            lda #>MATH_RESULTS_ADDRESS
            sta VERA_ADDR_HIGH
            
            ; We read (with 16-bit hop) the middle two bytes of the result from VRAM
            
            lda VERA_DATA1
           sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y,x
            lda VERA_DATA1
           sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
        .else
            ; We load the INVERSE_Z_LOW
            lda (LOAD_ADDRESS), y
            sta MULTIPLICAND
            
            ; We load the INVERSE_Z_HIGH
            inc LOAD_ADDRESS+1
            lda (LOAD_ADDRESS), y
            sta MULTIPLICAND+1

            lda \TRIANGLES_3D_POINT_X_OR_Y,x
            sta MULTIPLIER
            lda \TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
            sta MULTIPLIER+1

            ; -- X (or Y) * 1 / Z
            
            jsr multply_16bits_signed
            
            lda PRODUCT+2
            sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
            lda PRODUCT+1
            sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y,x
        .endif
        
    .else
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
        lda DIVIDEND+1
        sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y+MAX_NR_OF_TRIANGLES,x
        lda DIVIDEND
        sta \OUTPUT_TRIANGLES_3D_POINT_X_OR_Y,x
    .endif
    
.endmacro


MACRO_calculate_dot_product .macro TRIANGLES_3D_POINTA_X, TRIANGLES_3D_POINTA_Y, TRIANGLES_3D_POINTA_Z, TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES_3D_POINTN_Z

    ; To do the dot-product we have to do:
    ; A.x * N.x + A.y * N.y + A.z + N.z
    
    .if(!USE_FX_MULTIPLIER)
        stz DOT_PRODUCT
        stz DOT_PRODUCT+1
    .endif
    
    ; -- A.x * N.x
    
    .if(USE_FX_MULTIPLIER)
    
        lda VERA_FX_ACCUM_RESET   ; reset accumulator
    
        lda \TRIANGLES_3D_POINTA_X,x
        sta VERA_FX_CACHE_L
        lda \TRIANGLES_3D_POINTA_X+MAX_NR_OF_TRIANGLES,x
        sta VERA_FX_CACHE_M

        lda \TRIANGLES_3D_POINTN_X, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINTN_X+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U

        lda VERA_FX_ACCUM         ; accumulate
        
    .else
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
    .endif
    
    ; -- A.y * N.y
    
    .if(USE_FX_MULTIPLIER)
    
        lda \TRIANGLES_3D_POINTA_Y,x
        sta VERA_FX_CACHE_L
        lda \TRIANGLES_3D_POINTA_Y+MAX_NR_OF_TRIANGLES,x
        sta VERA_FX_CACHE_M

        lda \TRIANGLES_3D_POINTN_Y, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINTN_Y+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U

        lda VERA_FX_ACCUM       ; accumulate
        
    .else
    
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
    .endif

    ; -- A.z * N.z
    
    .if(USE_FX_MULTIPLIER)
    
        lda \TRIANGLES_3D_POINTA_Z,x
        sta VERA_FX_CACHE_L
        lda \TRIANGLES_3D_POINTA_Z+MAX_NR_OF_TRIANGLES,x
        sta VERA_FX_CACHE_M

        lda \TRIANGLES_3D_POINTN_Z, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINTN_Z+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U

        ; We write the multiplication result to VRAM
        stz VERA_DATA0
        
; FIXME: WORKAROUND! We need to make sure DATA1 is re-read after storing to the same address!
        lda #>MATH_RESULTS_ADDRESS
        sta VERA_ADDR_HIGH

        lda VERA_DATA1
        sta DOT_PRODUCT
        lda VERA_DATA1
        sta DOT_PRODUCT+1
        
    .else
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
    .endif

.endmacro


MACRO_calculate_dot_product_for_light .macro TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES_3D_POINTN_Z

    ; To do the dot-product we have to do:
    ; L.x * N.x + L.y * N.y + L.z + N.z
    
    .if(!USE_FX_MULTIPLIER)
        stz DOT_PRODUCT
        stz DOT_PRODUCT+1
    .endif
    
    ; -- L.x * N.x
    
    .if(USE_FX_MULTIPLIER)
            
        lda VERA_FX_ACCUM_RESET    ; reset accumulator
        
        lda LIGHT_DIRECTION_3D_X
        sta VERA_FX_CACHE_L
        lda LIGHT_DIRECTION_3D_X+1
        sta VERA_FX_CACHE_M

        lda \TRIANGLES_3D_POINTN_X, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINTN_X+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U

        lda VERA_FX_ACCUM         ; accumulate
        
    .else
        lda LIGHT_DIRECTION_3D_X
        sta MULTIPLIER
        lda LIGHT_DIRECTION_3D_X+1
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
    .endif
    
    ; -- L.y * N.y
    
    .if(USE_FX_MULTIPLIER)
    
        lda LIGHT_DIRECTION_3D_Y
        sta VERA_FX_CACHE_L
        lda LIGHT_DIRECTION_3D_Y+1
        sta VERA_FX_CACHE_M

        lda \TRIANGLES_3D_POINTN_Y, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINTN_Y+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U

        lda VERA_FX_ACCUM      ; accumulate
        
    .else
    
        lda LIGHT_DIRECTION_3D_Y
        sta MULTIPLIER
        lda LIGHT_DIRECTION_3D_Y+1
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
    .endif

    ; -- L.z * N.z
    
    .if(USE_FX_MULTIPLIER)
    
        lda LIGHT_DIRECTION_3D_Z
        sta VERA_FX_CACHE_L
        lda LIGHT_DIRECTION_3D_Z+1
        sta VERA_FX_CACHE_M

        lda \TRIANGLES_3D_POINTN_Z, x
        sta VERA_FX_CACHE_H
        lda \TRIANGLES_3D_POINTN_Z+MAX_NR_OF_TRIANGLES, x
        sta VERA_FX_CACHE_U

        ; We write the multiplication result to VRAM
        stz VERA_DATA0
        
; FIXME: WORKAROUND! We need to make sure DATA1 is re-read after storing to the same address!
        lda #>MATH_RESULTS_ADDRESS
        sta VERA_ADDR_HIGH

        lda VERA_DATA1
        sta DOT_PRODUCT
        lda VERA_DATA1
        sta DOT_PRODUCT+1
        
    .else
        lda LIGHT_DIRECTION_3D_Z
        sta MULTIPLIER
        lda LIGHT_DIRECTION_3D_Z+1
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
    .endif

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

MACRO_prepare_fx_multiplier .macro
    .if(USE_FX_MULTIPLIER)
        lda #%00000100           ; DCSEL=2, ADDRSEL=0
        sta VERA_CTRL
        
        lda #%01001000           ; cache write enabled = 1, 16bit hop = 1, addr1-mode = normal
        sta VERA_FX_CTRL
        
        ; Setting ADDR0 + increment
        lda #%00110000           ; +4 increment
        ora #MATH_RESULTS_ADDRESS>>16
        sta VERA_ADDR_BANK
        lda #>MATH_RESULTS_ADDRESS
        sta VERA_ADDR_HIGH
; FIXME: this is done later as well!
        lda #<MATH_RESULTS_ADDRESS
        sta VERA_ADDR_LOW
        
        lda #%00000101           ; DCSEL=2, ADDRSEL=1
        sta VERA_CTRL
        
        ; Setting ADDR1 + increment
        lda #%00110000           ; +4 increment (16bit hopped)
        ora #MATH_RESULTS_ADDRESS>>16
        sta VERA_ADDR_BANK
        lda #>MATH_RESULTS_ADDRESS
        sta VERA_ADDR_HIGH
; FIXME: this is done later as well!
        lda #<(MATH_RESULTS_ADDRESS+1)  ; We offset by 1 so we read the 2 middle 2 bytes of the 32-bit result
        sta VERA_ADDR_LOW
        
        lda #%10010000           ; reset accumulator = 1, add/sub = 0 (add), multiplier enabled = 1, cache index  = 0
        sta VERA_FX_MULT
    .endif
.endmacro

MACRO_reset_fx_multiplier .macro
    ; This sets ADDR0_LOW to $00 and ADDR1_LOW to $01 (assuming MATH_RESULTS_ADDRESS_LOW = $00)
    
    .if(USE_FX_MULTIPLIER)
        ; We reset both ADDR0 and ADDR1 to the MATH_RESULTS_ADDRESS
    
        lda #<(MATH_RESULTS_ADDRESS+1)  ; We offset by 1 so we read the 2 middle 2 bytes of the 32-bit result
        sta VERA_ADDR_LOW        ; Reset ADDR1_LOW
        
        lda #%00001100           ; DCSEL=6, ADDRSEL=0
        sta VERA_CTRL
    
        lda #<MATH_RESULTS_ADDRESS
        sta VERA_ADDR_LOW        ; Reset ADDR0_LOW 
        
        lda #%00001101           ; DCSEL=6, ADDRSEL=1
        sta VERA_CTRL
        
    .endif
.endmacro


calculate_projection_of_3d_onto_2d_screen:

    MACRO_prepare_fx_multiplier

    MACRO_load_sine ANGLE_Z
    MACRO_load_cosine ANGLE_Z
    
    ldx #0
rotate_in_z_next_triangle:

    .if(1)
        MACRO_reset_fx_multiplier
    
        ; -- Point 1 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT1_X, TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_X
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT1_X, TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINT1_Z, TRIANGLES2_3D_POINT1_Z
        
        ; -- Point 2 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT2_X, TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_X
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT2_X, TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINT2_Z, TRIANGLES2_3D_POINT2_Z

        ; -- Point 3 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT3_X, TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_X
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT3_X, TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINT3_Z, TRIANGLES2_3D_POINT3_Z

        ; -- Point N --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_X
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINTN_Z, TRIANGLES2_3D_POINTN_Z
    .else
        ; -- Point 1 --
        MACRO_copy_point_value TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_X
        MACRO_copy_point_value TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINT1_Z, TRIANGLES2_3D_POINT1_Z
        
        ; -- Point 2 --
        MACRO_copy_point_value TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_X
        MACRO_copy_point_value TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINT2_Z, TRIANGLES2_3D_POINT2_Z

        ; -- Point 3 --
        MACRO_copy_point_value TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_X
        MACRO_copy_point_value TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINT3_Z, TRIANGLES2_3D_POINT3_Z

        ; -- Point N --
        MACRO_copy_point_value TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_X
        MACRO_copy_point_value TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Y
        ; MACRO_copy_point_value TRIANGLES_3D_POINTN_Z, TRIANGLES2_3D_POINTN_Z
    .endif

    inx
    cpx #NR_OF_TRIANGLES
    beq rotate_in_z_done
    jmp rotate_in_z_next_triangle
rotate_in_z_done:

    MACRO_load_sine ANGLE_X
    MACRO_load_cosine ANGLE_X

    ldx #0
rotate_in_x_next_triangle:
    
    ; WARNING: we are using TRIANGLES (not TRIANGLES2) for Z here!
    
    .if(1)
        MACRO_reset_fx_multiplier
    
        ; -- Point 1 --
        MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT1_Y, TRIANGLES_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Y
        MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT1_Y, TRIANGLES_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Z
        ; MACRO_copy_point_value TRIANGLES2_3D_POINT1_X, TRIANGLES3_3D_POINT1_X
        
        ; -- Point 2 --
        MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT2_Y, TRIANGLES_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Y
        MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT2_Y, TRIANGLES_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Z
        ; MACRO_copy_point_value TRIANGLES2_3D_POINT2_X, TRIANGLES3_3D_POINT2_X

        ; -- Point 3 --
        MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT3_Y, TRIANGLES_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Y
        MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT3_Y, TRIANGLES_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Z
        ; MACRO_copy_point_value TRIANGLES2_3D_POINT3_X, TRIANGLES3_3D_POINT3_X
        
        ; -- Point N --
        MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINTN_Y, TRIANGLES_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Y
        MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINTN_Y, TRIANGLES_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Z
        ; MACRO_copy_point_value TRIANGLES2_3D_POINTN_X, TRIANGLES3_3D_POINTN_X
    .else
        ; -- Point 1 --
        ; MACRO_copy_point_value TRIANGLES2_3D_POINT1_X, TRIANGLES3_3D_POINT1_X
        MACRO_copy_point_value TRIANGLES2_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Z
        
        ; -- Point 2 --
        ; MACRO_copy_point_value TRIANGLES2_3D_POINT2_X, TRIANGLES3_3D_POINT2_X
        MACRO_copy_point_value TRIANGLES2_3D_POINT2_Y, TRIANGLES3_3D_POINT2_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Z

        ; -- Point 3 --
        ; MACRO_copy_point_value TRIANGLES2_3D_POINT3_X, TRIANGLES3_3D_POINT3_X
        MACRO_copy_point_value TRIANGLES2_3D_POINT3_Y, TRIANGLES3_3D_POINT3_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Z
        
        ; -- Point N --
        ; MACRO_copy_point_value TRIANGLES2_3D_POINTN_X, TRIANGLES3_3D_POINTN_X
        MACRO_copy_point_value TRIANGLES2_3D_POINTN_Y, TRIANGLES3_3D_POINTN_Y
        MACRO_copy_point_value TRIANGLES2_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Z
    .endif
    
    inx
    cpx #NR_OF_TRIANGLES
    beq rotate_in_x_done
    jmp rotate_in_x_next_triangle
rotate_in_x_done:
    
    ; We start with a new linked list 
    ; IMPORTANT NOTE: the first entry is the *start* entry and does not contain a (valid) triangle index!
    stz CURRENT_LINKED_LIST_ENTRY
    stz TRIANGLES_LINKED_LIST_NEXT  ; First entry of the linked list contains a next-value of 0, meaning the end of the list
    lda #1
    sta LINKED_LIST_NEW_ENTRY       ; Our new entry is going to be 1
    
    ldx #0
back_face_cull_next_triangle:

    ; -- Translate into z --
    MACRO_translate_z TRIANGLES3_3D_POINT1_Z, TRANSLATE_Z
    MACRO_translate_z TRIANGLES3_3D_POINT2_Z, TRANSLATE_Z
    MACRO_translate_z TRIANGLES3_3D_POINT3_Z, TRANSLATE_Z
    
    ; --  We check whether the triangle should be visible.

; FIXME: maybe we can skip this here? We do it only once per triangle!    
    MACRO_reset_fx_multiplier
    
    ; We calculate the dot-product between point1 and pointN (the normal of the triange)
    ; WARNING: we are using TRIANGLES2 (not TRIANGLES3) for X here!
    MACRO_calculate_dot_product TRIANGLES2_3D_POINT1_X, TRIANGLES3_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Z, TRIANGLES2_3D_POINTN_X, TRIANGLES3_3D_POINTN_Y, TRIANGLES3_3D_POINTN_Z
    lda DOT_PRODUCT+1
    bmi triangle_is_not_facing_camera
    
    ; The triangle is visible (that is: facing our side) and should be added to the linked list of triangles
    
    ; -- We calculate the average Z (or actually: the *sum* of Z) for all 3 points --
    
    MACRO_calculate_sum_of_z TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_SUM_Z
    
; FIXME!
    jsr insert_sort_triangle_using_sum_of_z
;    jsr insert_triangle_without_sorting
    
triangle_is_not_facing_camera:
    inx
    cpx #NR_OF_TRIANGLES
    beq back_face_culling_done
    jmp back_face_cull_next_triangle
back_face_culling_done:




    ; == We loop through the linked list and color (by light), project onto 2D, scale and position the triangles ==

    ; IMPORTANT NOTE: the first entry is the *start* entry and does not contain a (valid) triangle index!
    stz CURRENT_LINKED_LIST_ENTRY
    stz TRIANGLE_COUNT                  ; We start with a new (2D) triangle index
scale_and_position_next_triangle:
    ; FIXME: this looks SLOW!
    ldy CURRENT_LINKED_LIST_ENTRY
    lda TRIANGLES_LINKED_LIST_NEXT, y   ; We get the next linked list entry
    bne scale_and_position_keep_going   ; If our next linked list entry is 0, we know we reached the end, otherwise go on
    jmp scale_and_position_done
scale_and_position_keep_going:
    sta CURRENT_LINKED_LIST_ENTRY
    tay
    ldx TRIANGLES_LINKED_LIST_INDEX, y  ; We put the (3D) triangle index into register x
    ldy TRIANGLE_COUNT                  ; We put the 2D triangle index into register y
    

    ; -- Copy color of triangle --

    .if(USE_LIGHT)
        ; WARNING: we are using TRIANGLES2 (not TRIANGLES3) for X here!

        MACRO_calculate_dot_product_for_light TRIANGLES2_3D_POINTN_X, TRIANGLES3_3D_POINTN_Y, TRIANGLES3_3D_POINTN_Z

; FIXME: we should take into account that DOT_PRODUCT ranges from -1.0 to +1.0 and therefore color accordingly (now only 0.0 -> 1.0)
        ; -- Take care of < 0.0 cases --
        lda DOT_PRODUCT+1
        bpl check_if_full_light
        ; When DOT_PRODUCT < 00.00 we want dark light color!
        lda #$10    ; Black for now
        bra color_calculated
check_if_full_light:
        ; -- Take care of +1.0 case --
        lda DOT_PRODUCT+1
        beq map_light_to_color
        ; When DOT_PRODUCT = 01.00 we want FULL light color!
        lda #$1F  ; white
        bra color_calculated
map_light_to_color:
        ; -- Take care < +1.0 cases --
        lda DOT_PRODUCT
        lsr
        lsr
        lsr
        lsr
        ora #$10   ; starting with black
color_calculated:
        sta TRIANGLES_COLOR,y
    .else
        lda TRIANGLES_ORG_COLOR,x
        sta TRIANGLES_COLOR,y
    .endif

    ; -- Project triangle from 3D world onto 2D screen --

    MACRO_reset_fx_multiplier

    phy
    
    ; WARNING: we are using TRIANGLES2 (not TRIANGLES3) for X here!
    
    ; - Point 1 -
    MACRO_divide_by_z TRIANGLES2_3D_POINT1_X, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT1_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Y
    
    ; - Point 2 -
    MACRO_divide_by_z TRIANGLES2_3D_POINT2_X, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT2_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT2_Y, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Y
    
    ; - Point 3 -
    MACRO_divide_by_z TRIANGLES2_3D_POINT3_X, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_POINT3_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT3_Y, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Y
    
    ply
    
    ; These macro will use register x as 3D triangle index, whicle using register y as 2D triangle index
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT1_X, TRIANGLES_POINT1_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT1_Y, TRIANGLES_POINT1_Y
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT2_X, TRIANGLES_POINT2_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT2_Y, TRIANGLES_POINT2_Y
    MACRO_scale_and_position_on_screen_x TRIANGLES3_3D_POINT3_X, TRIANGLES_POINT3_X
    MACRO_scale_and_position_on_screen_y TRIANGLES3_3D_POINT3_Y, TRIANGLES_POINT3_Y

    inc TRIANGLE_COUNT                  ; We increment our 2D list counter

    jmp scale_and_position_next_triangle
scale_and_position_done:

    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
        
    lda #%00000000           ; multiplier enabled = 0
    sta VERA_FX_MULT

    rts
    
    
insert_triangle_without_sorting:

    ; We add the entry at the end of the linked list
    
    ; IMPORTANT: x is filled with the current triangle index!

    ; Note: when we reach this point CURRENT_LINKED_LIST_ENTRY is filled with the *last* entry in the linked list
    ldy CURRENT_LINKED_LIST_ENTRY
    lda LINKED_LIST_NEW_ENTRY
    sta TRIANGLES_LINKED_LIST_NEXT, y   ; We store the new linked list entry as the 'next' linked list entry of the current entry
    
    sta CURRENT_LINKED_LIST_ENTRY       ; The newly created link list entry has now become our current linked list entry
    tay                                 ; y is now filled with the (new) link list entry
; FIXME: cant we do stx here instead?
    txa                                 ; x is filled with the current triangle index, we copy it to a
    sta TRIANGLES_LINKED_LIST_INDEX, y     ; We store the triangle index in the current (newly created) linked list entry
    lda #0
    sta TRIANGLES_LINKED_LIST_NEXT, y   ; we set the _NEXT for the last entry to 0 (measning: end of list)
    
    inc LINKED_LIST_NEW_ENTRY           ; We increment the new entry of the linked list

    rts
    
    
insert_sort_triangle_using_sum_of_z:

    ; IMPORTANT: x is filled with the current triangle index!
    lda TRIANGLES3_3D_SUM_Z,x
    sta CURRENT_SUM_Z
    lda TRIANGLES3_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x
    sta CURRENT_SUM_Z+1
    stx TRIANGLE_INDEX                  ; Backing up the current 3D triangle index
    
    ; IMPORTANT NOTE: the first entry is the *start* entry and does not contain a (valid) triangle index!
    stz CURRENT_LINKED_LIST_ENTRY
insertion_sort_compare_with_next_triangle:
    ldy CURRENT_LINKED_LIST_ENTRY
    sty PREVIOUS_LINKED_LIST_ENTRY
    lda TRIANGLES_LINKED_LIST_NEXT, y   ; We get the next linked list entry
    beq reached_end_of_linked_list      ; If our next linked list entry is 0, we know we reached the end, otherwise go on
    sta CURRENT_LINKED_LIST_ENTRY
    tay
    ldx TRIANGLES_LINKED_LIST_INDEX, y  ; We put the (3D) triangle index into register x
    
    
    ; We do: CURRENT_SUM_Z - TRIANGLES3_3D_SUM_Z and check if its negative or positive
    sec
    lda CURRENT_SUM_Z
    sbc TRIANGLES3_3D_SUM_Z,x
    lda CURRENT_SUM_Z+1
    sbc TRIANGLES3_3D_SUM_Z+MAX_NR_OF_TRIANGLES,x
    bpl new_triangle_sum_z_is_higher
    
    ; The new triangle (current sum z) has a lower sum of z than the one in the linked list. So we should *not* insert the new triangle yet. We move on.
    
    bra insertion_sort_compare_with_next_triangle

new_triangle_sum_z_is_higher:

    ; The new triangle (current sum z) has a higher (or equal) sum of z than the one in the linked list. So we should insert the new triangle at this point in the linked list.

    ; We add the entry at *this* point in the linked list
    
    ldx TRIANGLE_INDEX                  ; Restoring the current 3D triangle index

    ; Note: when we reach this point CURRENT_LINKED_LIST_ENTRY is filled with the *compared* entry in the linked list. We have to add the current one *BEFORE* the compared one!
    ldy LINKED_LIST_NEW_ENTRY
    lda CURRENT_LINKED_LIST_ENTRY       ; the compared linked list entry
    sta TRIANGLES_LINKED_LIST_NEXT, y   ; We store the compared linked list entry as the 'next' linked list entry of the newly added/current entry
; FIXME: cant we do stx here instead?
    txa                                 ; x is filled with the current triangle index, we copy it to a
    sta TRIANGLES_LINKED_LIST_INDEX, y  ; We store the triangle index in the current (newly created) linked list entry
    
    ; We store the new entry as the 'next'-entry in the previous entry (the one BEFORE the one we just compared to)
    ldy PREVIOUS_LINKED_LIST_ENTRY
    lda LINKED_LIST_NEW_ENTRY
    sta TRIANGLES_LINKED_LIST_NEXT, y
    
    inc LINKED_LIST_NEW_ENTRY           ; We increment the new entry of the linked list

    rts

reached_end_of_linked_list:

    ; We add the entry at the end of the linked list
    
    ldx TRIANGLE_INDEX                  ; Restoring the current 3D triangle index

    ; Note: when we reach this point CURRENT_LINKED_LIST_ENTRY is filled with the *last* entry in the linked list
    ldy CURRENT_LINKED_LIST_ENTRY
    lda LINKED_LIST_NEW_ENTRY
    sta TRIANGLES_LINKED_LIST_NEXT, y   ; We store the new linked list entry as the 'next' linked list entry of the current entry
    
    sta CURRENT_LINKED_LIST_ENTRY       ; The newly created link list entry has now become our current linked list entry
    tay                                 ; y is now filled with the (new) link list entry
; FIXME: cant we do stx here instead?
    txa                                 ; x is filled with the current triangle index, we copy it to a
    sta TRIANGLES_LINKED_LIST_INDEX, y     ; We store the triangle index in the current (newly created) linked list entry
    lda #0
    sta TRIANGLES_LINKED_LIST_NEXT, y   ; we set the _NEXT for the last entry to 0 (measning: end of list)
    
    inc LINKED_LIST_NEW_ENTRY           ; We increment the new entry of the linked list

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

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    ; TODO: we *could* use 'one byte cache cycling' so we have to set only *one* byte of the cache here
    lda #BACKGROUND_COLOR
    sta VERA_FX_CACHE_L      ; cache32[7:0]
    sta VERA_FX_CACHE_M      ; cache32[15:8]
    sta VERA_FX_CACHE_H      ; cache32[23:16]
    sta VERA_FX_CACHE_U      ; cache32[31:24]

    ; We setup blit writes
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    lda #%01000000           ; transparent writes = 0, blit write = 1, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta VERA_FX_CTRL
    
    
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
     
    lda #%00000000           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta VERA_FX_CTRL
    
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
    
    sec
    lda #0
    sbc SINE_OUTPUT
    sta MINUS_SINE_OUTPUT
    lda #0
    sbc SINE_OUTPUT+1
    sta MINUS_SINE_OUTPUT+1
    
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
    
    sec
    lda #0
    sbc COSINE_OUTPUT
    sta MINUS_COSINE_OUTPUT
    lda #0
    sbc COSINE_OUTPUT+1
    sta MINUS_COSINE_OUTPUT+1
    
    rts
    
    
    .if(0)
NR_OF_TRIANGLES = 12
triangle_3d_data:

; FIXME: should we do a NEGATIVE or a NEGATIVE Z for the NORMAL?
    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)
    ;        x1,   y1,   z1,    x2,   y2,   z2,     x3,   y3,   z3,    xn,   yn,   zn,   cl
;   .word      0,    0,    0,   $100,    0,    0,     0,  $100,    0,    0,    0, $100,   29
;   .word   $100,    0,    0,   $100, $100,    0,     0,  $100,    0,    0,    0, $100,   13
;   .word   $100,    0, $100,      0,    0, $100,     0,  $100, $100,    0,    0,-$100,   3   
;   .word   $100, $100, $100,   $100,    0, $100,     0,  $100, $100,    0,    0,-$100,   2   
   
; FIXME: the winding is exactly the OPPOSITE as javidx9!!! -> we may want to invert Z in the engine!

    ;        x1,    y1,   z1,      x2,   y2,   z2,      x3,   y3,   z3,      xn,   yn,   zn,    cl
   ; SOUTH
   .word       0, $100,    0,       0,    0,    0,    $100, $100,    0,       0,    0, $100,     1
   .word    $100, $100,    0,       0,    0,    0,    $100,    0,    0,       0,    0, $100,     1

   ; NORTH                                                     
   .word    $100, $100, $100,    $100,    0, $100,       0, $100, $100,       0,    0,-$100,     3
   .word       0, $100, $100,    $100,    0, $100,       0,    0, $100,       0,    0,-$100,     3

   ; EAST                                                      
   .word    $100, $100,    0,    $100,    0,    0,    $100, $100, $100,   -$100,    0,    0,     2
   .word    $100, $100, $100,    $100,    0,    0,    $100,    0, $100,   -$100,    0,    0,     2

   ; WEST                                                      
   .word       0, $100, $100,       0,    0, $100,       0, $100,    0,     $100,    0,    0,     4
   .word       0, $100,    0,       0,    0, $100,       0,    0,    0,    $100,    0,    0,     4

   ; TOP                                                       
   .word       0, $100, $100,       0, $100,    0,    $100, $100, $100,       0,-$100,    0,     5
   .word    $100, $100, $100,       0, $100,    0,    $100, $100,    0,       0,-$100,    0,     5

   ; BOTTOM                                                    
   .word       0,    0, $100,    $100,    0, $100,       0,    0,    0,       0, $100,    0,     7
   .word       0,    0,    0,    $100,    0, $100,    $100,    0,    0,       0, $100,    0,     7
   
   
palette_data:   
    ; dummy
end_of_palette_data:
    .endif
    
    
    
    .if(1)
NR_OF_TRIANGLES = 36
triangle_3d_data:
    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)
    ;       x1,    y1,    z1,    x2,    y2,    z2,    x3,    y3,    z3,    xn,    yn,    zn,   cl
    .word $FC32, $FC89, $0000, $FC68, $FD40, $0000, $FD0A, $FD40, $0000, $0000, $0000, $FF00, $0010
    .word $FD0A, $FD40, $0000, $FC68, $FD40, $0000, $FC9E, $FDF8, $0000, $0000, $0000, $FF00, $0011
    .word $FD0A, $FD40, $0000, $FC9E, $FDF8, $0000, $FDE3, $FDF8, $0000, $0000, $0000, $FF00, $0011
    .word $FDE3, $FDF8, $0000, $FC9E, $FDF8, $0000, $FCD5, $FEB0, $0000, $0000, $0000, $FF00, $0012
    .word $FDE3, $FDF8, $0000, $FCD5, $FEB0, $0000, $FEBB, $FEB0, $0000, $0000, $0000, $FF00, $0012
    .word $FEBB, $FEB0, $0000, $FCD5, $FEB0, $0000, $FD0B, $FF68, $0000, $0000, $0000, $FF00, $0013
    .word $FEBB, $FEB0, $0000, $FD0B, $FF68, $0000, $FF94, $FF68, $0000, $0000, $0000, $FF00, $0013
    .word $FF94, $FF68, $0000, $FD0B, $FF68, $0000, $FEEB, $FFEB, $0000, $0000, $0000, $FF00, $0014
    .word $FF94, $FF68, $0000, $FEEB, $FFEB, $0000, $FF94, $FFEB, $0000, $0000, $0000, $FF00, $0014
    .word $FF94, $FFEB, $0000, $FEEB, $FFEB, $0000, $FEEB, $009D, $0000, $0000, $0000, $FF00, $0015
    .word $FF94, $FFEB, $0000, $FEEB, $009D, $0000, $FF94, $009D, $0000, $0000, $0000, $FF00, $0015
    .word $FF94, $009D, $0000, $FEEB, $009D, $0000, $FD5D, $0120, $0000, $0000, $0000, $FF00, $0016
    .word $FF94, $009D, $0000, $FD5D, $0120, $0000, $FF94, $0120, $0000, $0000, $0000, $FF00, $0016
    .word $FF94, $0120, $0000, $FD5D, $0120, $0000, $FD33, $01E8, $0000, $0000, $0000, $FF00, $0017
    .word $FF94, $0120, $0000, $FD33, $01E8, $0000, $FEAD, $01E8, $0000, $0000, $0000, $FF00, $0017
    .word $FEAD, $01E8, $0000, $FD33, $01E8, $0000, $FD0A, $02B0, $0000, $0000, $0000, $FF00, $0018
    .word $FEAD, $01E8, $0000, $FD0A, $02B0, $0000, $FDC6, $02B0, $0000, $0000, $0000, $FF00, $0018
    .word $FDC6, $02B0, $0000, $FD0A, $02B0, $0000, $FCE0, $0377, $0000, $0000, $0000, $FF00, $0019
    .word $FD0A, $FD40, $0000, $FC68, $FD40, $0000, $FC32, $FC89, $0000, $0000, $0000, $0100, $0010
    .word $FC9E, $FDF8, $0000, $FC68, $FD40, $0000, $FD0A, $FD40, $0000, $0000, $0000, $0100, $0011
    .word $FDE3, $FDF8, $0000, $FC9E, $FDF8, $0000, $FD0A, $FD40, $0000, $0000, $0000, $0100, $0011
    .word $FCD5, $FEB0, $0000, $FC9E, $FDF8, $0000, $FDE3, $FDF8, $0000, $0000, $0000, $0100, $0012
    .word $FEBB, $FEB0, $0000, $FCD5, $FEB0, $0000, $FDE3, $FDF8, $0000, $0000, $0000, $0100, $0012
    .word $FD0B, $FF68, $0000, $FCD5, $FEB0, $0000, $FEBB, $FEB0, $0000, $0000, $0000, $0100, $0013
    .word $FF94, $FF68, $0000, $FD0B, $FF68, $0000, $FEBB, $FEB0, $0000, $0000, $0000, $0100, $0013
    .word $FEEB, $FFEB, $0000, $FD0B, $FF68, $0000, $FF94, $FF68, $0000, $0000, $0000, $0100, $0014
    .word $FF94, $FFEB, $0000, $FEEB, $FFEB, $0000, $FF94, $FF68, $0000, $0000, $0000, $0100, $0014
    .word $FEEB, $009D, $0000, $FEEB, $FFEB, $0000, $FF94, $FFEB, $0000, $0000, $0000, $0100, $0015
    .word $FF94, $009D, $0000, $FEEB, $009D, $0000, $FF94, $FFEB, $0000, $0000, $0000, $0100, $0015
    .word $FD5D, $0120, $0000, $FEEB, $009D, $0000, $FF94, $009D, $0000, $0000, $0000, $0100, $0016
    .word $FF94, $0120, $0000, $FD5D, $0120, $0000, $FF94, $009D, $0000, $0000, $0000, $0100, $0016
    .word $FD33, $01E8, $0000, $FD5D, $0120, $0000, $FF94, $0120, $0000, $0000, $0000, $0100, $0017
    .word $FEAD, $01E8, $0000, $FD33, $01E8, $0000, $FF94, $0120, $0000, $0000, $0000, $0100, $0017
    .word $FD0A, $02B0, $0000, $FD33, $01E8, $0000, $FEAD, $01E8, $0000, $0000, $0000, $0100, $0018
    .word $FDC6, $02B0, $0000, $FD0A, $02B0, $0000, $FEAD, $01E8, $0000, $0000, $0000, $0100, $0018
    .word $FCE0, $0377, $0000, $FD0A, $02B0, $0000, $FDC6, $02B0, $0000, $0000, $0000, $0100, $0019
    
palette_data:
    .byte $9c, $0c  ; palette index 16
    .byte $8c, $07  ; palette index 17
    .byte $9c, $04  ; palette index 18
    .byte $cf, $08  ; palette index 19
    .byte $cb, $05  ; palette index 20
    .byte $c8, $03  ; palette index 21
    .byte $c5, $0a  ; palette index 22
    .byte $c5, $0e  ; palette index 23
    .byte $95, $0f  ; palette index 24
    .byte $54, $0f  ; palette index 25
end_of_palette_data:
    .endif
    
    
    
    .if(0)
NR_OF_TRIANGLES = 106
triangle_3d_data:
    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)
    ;       x1,    y1,    z1,    x2,    y2,    z2,    x3,    y3,    z3,    xn,    yn,    zn,   cl
    .word $0000, $FF4D, $0300, $FECD, $FFCD, $0100, $FFB4, $0000, $0500, $009D, $00C4, $FFD3, $0001
    .word $FECD, $0033, $0100, $FF00, $0100, $FF00, $FF00, $0100, $0100, $00F8, $FFC2, $0000, $0002
    .word $0099, $FF67, $FE9A, $FF00, $FF00, $FF00, $0100, $FF00, $FF00, $0000, $00B5, $00B5, $0003
    .word $0100, $FF00, $FF00, $FF00, $FF00, $0100, $0100, $FF00, $0100, $0000, $0100, $0000, $0004
    .word $FF00, $0100, $FF00, $0100, $0100, $0100, $FF00, $0100, $0100, $0000, $FF00, $0000, $0005
    .word $FFB4, $0000, $0500, $0100, $0100, $0100, $004C, $0000, $0500, $0000, $FF08, $FFC2, $0006
    .word $0133, $0033, $0100, $0133, $FFCD, $0100, $004C, $0000, $0500, $FF07, $0000, $FFC8, $0007
    .word $0100, $0100, $0100, $0133, $0033, $0100, $004C, $0000, $0500, $FF0E, $FFC4, $FFC7, $0008
    .word $0000, $FF4D, $0300, $0133, $FFCD, $0100, $0100, $FF00, $0100, $FF24, $0037, $FF8A, $0009
    .word $0100, $FF00, $0100, $FF00, $FF00, $0100, $0000, $FF4D, $0300, $0000, $00FD, $FFDB, $000A
    .word $FF67, $0099, $FE9A, $FECD, $0033, $FF00, $FF48, $001E, $FE9A, $009E, $FFD9, $00C5, $000B
    .word $FECD, $FFCD, $FF00, $FF00, $FF00, $0100, $FF00, $FF00, $FF00, $00F8, $003E, $0000, $000C
    .word $0433, $000F, $FF00, $0133, $0033, $0100, $0133, $0033, $FF00, $FFF5, $FF01, $0000, $000D
    .word $0099, $FF67, $FE9A, $0133, $FFCD, $FF00, $00B8, $FFE2, $FE9A, $FF62, $0027, $00C5, $000E
    .word $0133, $0033, $FF00, $0100, $0100, $0100, $0100, $0100, $FF00, $FF08, $FFC2, $0000, $000F
    .word $0133, $FFCD, $0100, $0100, $FF00, $FF00, $0100, $FF00, $0100, $FF08, $003E, $0000, $0010
    .word $FBCD, $FFF1, $0100, $FECD, $0033, $0100, $FECD, $FFCD, $0100, $0000, $0000, $FF00, $0011
    .word $FECD, $FFCD, $0100, $FECD, $0033, $0100, $FFB4, $0000, $0500, $00F9, $0000, $FFC8, $0012
    .word $0000, $FF4D, $0300, $FFB4, $0000, $0500, $004C, $0000, $0500, $0000, $00F1, $FFAC, $0013
    .word $FECD, $0033, $0100, $FF00, $0100, $0100, $FFB4, $0000, $0500, $00F2, $FFC4, $FFC7, $0014
    .word $FBCD, $FFD2, $FF00, $FBCD, $000F, $FF00, $FBCD, $002E, $FF00, $0000, $0000, $0000, $0015
    .word $FBCD, $000F, $FF00, $FECD, $FFCD, $FF00, $FECD, $0033, $FF00, $0000, $0000, $0100, $0016
    .word $FBCD, $FFF1, $FF00, $FECD, $FFCD, $0100, $FECD, $FFCD, $FF00, $000B, $00FF, $0000, $0017
    .word $FBCD, $000F, $0100, $FECD, $0033, $FF00, $FECD, $0033, $0100, $000B, $FF01, $0000, $0018
    .word $0433, $002E, $FF00, $0433, $000F, $0100, $0433, $000F, $FF00, $0100, $0000, $0000, $0019
    .word $0433, $FFF1, $0100, $0133, $FFCD, $FF00, $0133, $FFCD, $0100, $FFF5, $00FF, $0000, $001A
    .word $0433, $000F, $0100, $0133, $FFCD, $0100, $0133, $0033, $0100, $0000, $0000, $FF00, $001B
    .word $0433, $FFF1, $FF00, $0133, $0033, $FF00, $0133, $FFCD, $FF00, $0000, $0000, $0100, $001C
    .word $0459, $002E, $0300, $0433, $FFD2, $0100, $0433, $002E, $0100, $00FF, $0000, $FFED, $001D
    .word $0433, $FFD2, $0100, $0433, $FFF1, $FF00, $0433, $FFF1, $0100, $0100, $0000, $0000, $001E
    .word $0433, $FFD2, $0100, $0433, $000F, $0100, $0433, $002E, $0100, $0000, $0000, $0000, $001F
    .word $0433, $002E, $FF00, $0433, $FFF1, $FF00, $0433, $FFD2, $FF00, $0000, $0000, $0000, $0020
    .word $0480, $FFD2, $0100, $0480, $002E, $FF00, $0480, $FFD2, $FF00, $FF00, $0000, $0000, $0021
    .word $0480, $FFD2, $FF00, $0433, $002E, $FF00, $0433, $FFD2, $FF00, $0000, $0000, $0100, $0022
    .word $0480, $002E, $FF00, $0433, $002E, $0100, $0433, $002E, $FF00, $0000, $FF00, $0000, $0023
    .word $0480, $FFD2, $0100, $0433, $FFD2, $FF00, $0433, $FFD2, $0100, $0000, $0100, $0000, $0024
    .word $FB80, $002E, $0100, $FBCD, $002E, $FF00, $FBCD, $002E, $0100, $0000, $FF00, $0000, $0025
    .word $FBCD, $FFD2, $FF00, $FBCD, $FFF1, $0100, $FBCD, $FFF1, $FF00, $FF00, $0000, $0000, $0026
    .word $FBCD, $002E, $0100, $FBCD, $000F, $FF00, $FBCD, $000F, $0100, $FF00, $0000, $0000, $0027
    .word $FBCD, $002E, $0100, $FBCD, $FFF1, $0100, $FBCD, $FFD2, $0100, $0000, $0000, $0000, $0028
    .word $FB80, $FFD2, $FF00, $FB80, $002E, $0100, $FB80, $FFD2, $0100, $0100, $0000, $0000, $0029
    .word $FB80, $002E, $0100, $FBCD, $002E, $0100, $FBA7, $002E, $0300, $0000, $FF00, $0000, $002A
    .word $FB80, $002E, $FF00, $FBCD, $FFD2, $FF00, $FBCD, $002E, $FF00, $0000, $0000, $0100, $002B
    .word $FB80, $FFD2, $FF00, $FBCD, $FFD2, $0100, $FBCD, $FFD2, $FF00, $0000, $0100, $0000, $002C
    .word $FB80, $002E, $FF00, $FB80, $002E, $0100, $FB80, $FFD2, $FF00, $0100, $0000, $0000, $002D
    .word $0480, $FFD2, $0100, $0433, $FFD2, $0100, $0459, $FFD2, $0300, $0000, $0100, $0000, $002E
    .word $0433, $002E, $0100, $0480, $002E, $0100, $0459, $002E, $0300, $0000, $FF00, $0000, $002F
    .word $0459, $FFD2, $0300, $0480, $002E, $0100, $0480, $FFD2, $0100, $FF01, $0000, $FFED, $0030
    .word $FBA7, $FFD2, $0300, $FB80, $FFD2, $0100, $FBA7, $002E, $0300, $00FF, $0000, $FFED, $0031
    .word $FBA7, $FFD2, $0300, $FBCD, $002E, $0100, $FBCD, $FFD2, $0100, $FF01, $0000, $FFED, $0032
    .word $FBCD, $FFD2, $0100, $FB80, $FFD2, $0100, $FBA7, $FFD2, $0300, $0000, $0100, $0000, $0033
    .word $FBA7, $002E, $0300, $FB80, $FFD2, $0100, $FB80, $002E, $0100, $00FF, $0000, $FFED, $0034
    .word $0433, $FFF1, $FF00, $0133, $FFCD, $FF00, $0433, $FFF1, $0100, $FFF5, $00FF, $0000, $0035
    .word $0433, $FFF1, $0100, $0133, $FFCD, $0100, $0433, $000F, $0100, $0000, $0000, $FF00, $0036
    .word $0100, $0100, $FF00, $0100, $0100, $0100, $FF00, $0100, $FF00, $0000, $FF00, $0000, $0037
    .word $00B8, $001E, $FE9A, $0133, $FFCD, $FF00, $0133, $0033, $FF00, $FF5D, $0000, $00C4, $0038
    .word $FF67, $FF67, $FE9A, $FECD, $FFCD, $FF00, $FF00, $FF00, $FF00, $009E, $0027, $00C5, $0039
    .word $0099, $0099, $FE9A, $0133, $0033, $FF00, $0100, $0100, $FF00, $FF62, $FFD9, $00C5, $003A
    .word $FF67, $0099, $FE9A, $0100, $0100, $FF00, $FF00, $0100, $FF00, $0000, $FF4B, $00B5, $003B
    .word $FF48, $FFE2, $FE9A, $FECD, $0033, $FF00, $FECD, $FFCD, $FF00, $00A3, $0000, $00C4, $003C
    .word $FF48, $001E, $FE9A, $FF48, $FFE2, $FE9A, $00B8, $FFE2, $FE9A, $0000, $0000, $0100, $003D
    .word $0433, $000F, $FF00, $0133, $0033, $FF00, $0433, $FFF1, $FF00, $0000, $0000, $0100, $003E
    .word $FBCD, $FFF1, $FF00, $FECD, $FFCD, $FF00, $FBCD, $000F, $FF00, $0000, $0000, $0100, $003F
    .word $FBCD, $000F, $FF00, $FECD, $0033, $FF00, $FBCD, $000F, $0100, $000B, $FF01, $0000, $0040
    .word $FBCD, $000F, $0100, $FECD, $0033, $0100, $FBCD, $FFF1, $0100, $0000, $0000, $FF00, $0041
    .word $FBCD, $FFF1, $0100, $FECD, $FFCD, $0100, $FBCD, $FFF1, $FF00, $000B, $00FF, $0000, $0042
    .word $FECD, $FFCD, $0100, $FF00, $FF00, $0100, $FECD, $FFCD, $FF00, $00F8, $003E, $0000, $0043
    .word $FF00, $FF00, $FF00, $FF00, $FF00, $0100, $0100, $FF00, $FF00, $0000, $0100, $0000, $0044
    .word $FF00, $FF00, $0100, $FECD, $FFCD, $0100, $0000, $FF4D, $0300, $00DC, $0037, $FF8A, $0045
    .word $0133, $FFCD, $FF00, $0100, $FF00, $FF00, $0133, $FFCD, $0100, $FF08, $003E, $0000, $0046
    .word $004C, $0000, $0500, $0133, $FFCD, $0100, $0000, $FF4D, $0300, $FF63, $00C4, $FFD3, $0047
    .word $0133, $0033, $0100, $0100, $0100, $0100, $0133, $0033, $FF00, $FF08, $FFC2, $0000, $0048
    .word $0433, $000F, $0100, $0133, $0033, $0100, $0433, $000F, $FF00, $FFF5, $FF01, $0000, $0049
    .word $FF00, $0100, $0100, $0100, $0100, $0100, $FFB4, $0000, $0500, $0000, $FF08, $FFC2, $004A
    .word $FB80, $002E, $FF00, $FBCD, $002E, $FF00, $FB80, $002E, $0100, $0000, $FF00, $0000, $004B
    .word $FECD, $0033, $FF00, $FF00, $0100, $FF00, $FECD, $0033, $0100, $00F8, $FFC2, $0000, $004C
    .word $FBA7, $002E, $0300, $FBCD, $002E, $0100, $FBA7, $FFD2, $0300, $FF01, $0000, $FFED, $004D
    .word $FB80, $FFD2, $0100, $FBCD, $FFD2, $0100, $FB80, $FFD2, $FF00, $0000, $0100, $0000, $004E
    .word $FB80, $FFD2, $FF00, $FBCD, $FFD2, $FF00, $FB80, $002E, $FF00, $0000, $0000, $0100, $004F
    .word $0099, $0099, $FE9A, $0100, $0100, $FF00, $FF67, $0099, $FE9A, $0000, $FF4B, $00B5, $0050
    .word $00B8, $001E, $FE9A, $0133, $0033, $FF00, $0099, $0099, $FE9A, $FF62, $FFD9, $00C5, $0051
    .word $00B8, $FFE2, $FE9A, $0133, $FFCD, $FF00, $00B8, $001E, $FE9A, $FF5D, $0000, $00C4, $0052
    .word $0100, $FF00, $FF00, $0133, $FFCD, $FF00, $0099, $FF67, $FE9A, $FF62, $0027, $00C5, $0053
    .word $FF67, $FF67, $FE9A, $FF00, $FF00, $FF00, $0099, $FF67, $FE9A, $0000, $00B5, $00B5, $0054
    .word $FF48, $FFE2, $FE9A, $FECD, $FFCD, $FF00, $FF67, $FF67, $FE9A, $009E, $0027, $00C5, $0055
    .word $FF48, $001E, $FE9A, $FECD, $0033, $FF00, $FF48, $FFE2, $FE9A, $00A3, $0000, $00C4, $0056
    .word $FF00, $0100, $FF00, $FECD, $0033, $FF00, $FF67, $0099, $FE9A, $009E, $FFD9, $00C5, $0057
    .word $FF67, $0099, $FE9A, $FF48, $001E, $FE9A, $0099, $0099, $FE9A, $0000, $0000, $0100, $0058
    .word $00B8, $001E, $FE9A, $0099, $0099, $FE9A, $FF48, $001E, $FE9A, $0000, $0000, $0100, $0059
    .word $00B8, $FFE2, $FE9A, $00B8, $001E, $FE9A, $FF48, $001E, $FE9A, $0000, $0000, $0100, $005A
    .word $0099, $FF67, $FE9A, $00B8, $FFE2, $FE9A, $FF67, $FF67, $FE9A, $0000, $0000, $0100, $005B
    .word $FF48, $FFE2, $FE9A, $FF67, $FF67, $FE9A, $00B8, $FFE2, $FE9A, $0000, $0000, $0100, $005C
    .word $0480, $002E, $FF00, $0433, $002E, $FF00, $0480, $FFD2, $FF00, $0000, $0000, $0100, $005D
    .word $0480, $002E, $0100, $0480, $002E, $FF00, $0480, $FFD2, $0100, $FF00, $0000, $0000, $005E
    .word $0459, $002E, $0300, $0480, $002E, $0100, $0459, $FFD2, $0300, $FF01, $0000, $FFED, $005F
    .word $0480, $002E, $0100, $0433, $002E, $0100, $0480, $002E, $FF00, $0000, $FF00, $0000, $0060
    .word $0480, $FFD2, $FF00, $0433, $FFD2, $FF00, $0480, $FFD2, $0100, $0000, $0100, $0000, $0061
    .word $FBCD, $FFD2, $0100, $FBCD, $FFF1, $0100, $FBCD, $FFD2, $FF00, $FF00, $0000, $0000, $0062
    .word $FBCD, $002E, $FF00, $FBCD, $000F, $FF00, $FBCD, $002E, $0100, $FF00, $0000, $0000, $0063
    .word $0433, $002E, $0100, $0433, $000F, $0100, $0433, $002E, $FF00, $0100, $0000, $0000, $0064
    .word $0433, $FFD2, $FF00, $0433, $FFF1, $FF00, $0433, $FFD2, $0100, $0100, $0000, $0000, $0065
    .word $0459, $FFD2, $0300, $0433, $FFD2, $0100, $0459, $002E, $0300, $00FF, $0000, $FFED, $0066
    .word $FBCD, $FFF1, $FF00, $FBCD, $000F, $FF00, $FBCD, $FFD2, $FF00, $0000, $0000, $0000, $0067
    .word $0433, $FFF1, $0100, $0433, $000F, $0100, $0433, $FFD2, $0100, $0000, $0000, $0000, $0068
    .word $0433, $000F, $FF00, $0433, $FFF1, $FF00, $0433, $002E, $FF00, $0000, $0000, $0000, $0069
    .word $FBCD, $000F, $0100, $FBCD, $FFF1, $0100, $FBCD, $002E, $0100, $0000, $0000, $0000, $006A
    
palette_data:   
    ; dummy
end_of_palette_data:
    .endif
    
    
    
    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/i2c.s
    .include utils/keyboard.s
    .include utils/timing.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include fx_tests/fx_polygon_fill.s
    .include fx_tests/fx_polygon_fill_jump_tables.s
    .if(!DO_4BIT)
        .include fx_tests/fx_polygon_fill_jump_tables_8bit.s
    .else
        .if(!DO_2BIT)
            .include fx_tests/fx_polygon_fill_jump_tables_4bit.s
        .else
            .include fx_tests/fx_polygon_fill_jump_tables_2bit.s
        .endif
    .endif

    
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
            .binary "fx_tests/tables/slopes_packed_column_0_low.bin"
            .binary "fx_tests/tables/slopes_packed_column_0_high.bin"
            .binary "fx_tests/tables/slopes_packed_column_1_low.bin"
            .binary "fx_tests/tables/slopes_packed_column_1_high.bin"
            .binary "fx_tests/tables/slopes_packed_column_2_low.bin"
            .binary "fx_tests/tables/slopes_packed_column_2_high.bin"
            .binary "fx_tests/tables/slopes_packed_column_3_low.bin"
            .binary "fx_tests/tables/slopes_packed_column_3_high.bin"
            .binary "fx_tests/tables/slopes_packed_column_4_low.bin"
            .binary "fx_tests/tables/slopes_packed_column_4_high.bin"
            .if(USE_180_DEGREES_SLOPE_TABLE)
                .binary "fx_tests/tables/slopes_negative_packed_column_0_low.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_0_high.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_1_low.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_1_high.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_2_low.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_2_high.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_3_low.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_3_high.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_4_low.bin"
                .binary "fx_tests/tables/slopes_negative_packed_column_4_high.bin"
            .endif
        .else
            ; FIXME: right now we include vhigh tables *TWICE*! The second time is a dummy include! (since we want all _low tables to be aligned with ROM_BANK % 4 == 1)
            .binary "fx_tests/tables/slopes_column_0_low.bin"
            .binary "fx_tests/tables/slopes_column_0_high.bin"
            .binary "fx_tests/tables/slopes_column_0_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_0_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_1_low.bin"
            .binary "fx_tests/tables/slopes_column_1_high.bin"
            .binary "fx_tests/tables/slopes_column_1_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_1_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_2_low.bin"
            .binary "fx_tests/tables/slopes_column_2_high.bin"
            .binary "fx_tests/tables/slopes_column_2_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_2_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_3_low.bin"
            .binary "fx_tests/tables/slopes_column_3_high.bin"
            .binary "fx_tests/tables/slopes_column_3_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_3_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_4_low.bin"
            .binary "fx_tests/tables/slopes_column_4_high.bin"
            .binary "fx_tests/tables/slopes_column_4_vhigh.bin"
            .binary "fx_tests/tables/slopes_column_4_vhigh.bin"
            .if(USE_DIV_TABLES)
                FIXME: no support for DIV tables when USE_SLOPE_TABLES is turned off!
            .endif
        .endif
    .endif
    .if(USE_DIV_TABLES)
        .binary "fx_tests/tables/div_pos_0_low.bin"
        .binary "fx_tests/tables/div_pos_0_high.bin"
        .binary "fx_tests/tables/div_pos_1_low.bin"
        .binary "fx_tests/tables/div_pos_1_high.bin"
    .endif
