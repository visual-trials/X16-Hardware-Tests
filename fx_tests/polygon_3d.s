
; FIXME: we add nops after switching RAM_BANK. This is needed for the Breadboard of JeffreyH but not on stock hardware! Maybe add a setting to turn this on/off.

    .ifdef DEFAULT
; These are the *default* settings. 
USE_POLYGON_FILLER = 1
USE_SLOPE_TABLES = 1
USE_UNROLLED_LOOP = 1
USE_JUMP_TABLE = 1
USE_DIV_TABLES = 1
    .else
; When not defining DEFAULT from the commandline, these (shift names) will all have to be set from the commandline.    
USE_POLYGON_FILLER = FXPOLY
USE_SLOPE_TABLES = SLP
USE_UNROLLED_LOOP = UNR
USE_JUMP_TABLE = JMP
USE_DIV_TABLES = DIV
    .endif

USE_FX_MULTIPLIER = 1

DO_BUTTERFLY = 1
DRAW_BITMAP_TEXT = 1
DRAW_CURSOR_KEYS = 1

DO_SPEED_TEST = 1
DO_4BIT = 0
DO_2BIT = 0
KEEP_RUNNING = 1
USE_LIGHT = 1
USE_KEYBOARD_INPUT = 1
USE_DOUBLE_BUFFER = 1  ; IMPORTANT: we cant show text AND do double buffering!
SLOW_DOWN = 0
DEBUG = 0

; WEIRD BUG: when using JUMP_TABLES, the triangles look very 'edgy'!! --> it is 'SOLVED' by putting the jump FILL_LINE_END_CODE_x-block aligned to 256 bytes!?!?

USE_WRITE_CACHE = USE_JUMP_TABLE ; TODO: do we want to separate these options? (they are now always the same)

TEST_JUMP_TABLE = 0 ; This turns off the iteration in-between the jump-table calls
USE_SOFT_FILL_LEN = 0; ; This turns off reading from 9F2B and 9F2C (for fill length data) and instead reads from USE_SOFT_FILL_LEN-variables

; When in polygon filler mode and slope tables turned on, its possible to use a 180 degrees slope table
; Right now this is always turned on when slope tables are turned on
USE_180_DEGREES_SLOPE_TABLE = USE_SLOPE_TABLES

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
TIMING_COUNTER            = $13 ; 14
TIME_ELAPSED_MS           = $15
TIME_ELAPSED_SUB_MS       = $16 ; one nibble of sub-milliseconds

; Used only by (slow) 16-bit multiplier (multply_16bits)
MULTIPLIER                = $17 ; 18
MULTIPLICAND              = $19 ; 1A
PRODUCT                   = $1B ; 1C ; 1D ; 1E

; Used by the (slow) 24-bit divider (divide_24bits)
DIVIDEND                  = $1F ; 20 ; 21  ; the thing you want to divide (e.g. 100 /) . This will also the result after the division
DIVISOR                   = $22 ; 23 ; 24  ; the thing you divide by (e.g. / 10)
REMAINDER                 = $25 ; 26 ; 27

; For geneating code
END_JUMP_ADDRESS          = $28 ; 29
START_JUMP_ADDRESS        = $2A ; 2B
CODE_ADDRESS              = $2C ; 2D
LOAD_ADDRESS              = $2E ; 2F
STORE_ADDRESS             = $30 ; 31
VRAM_ADDRESS              = $32 ; 33 ; 34

TABLE_ROM_BANK            = $35
DRAW_LENGTH               = $36  ; for generating draw code

TRIANGLE_COUNT            = $37
TRIANGLE_INDEX            = $38

; Polygon filler
NUMBER_OF_ROWS             = $39
FILL_LENGTH_LOW            = $3A
FILL_LENGTH_HIGH           = $3B
; X1_THREE_LOWER_BITS      = $3C

; FREE: $3D available

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

BITMAP_RAM_BANK_START      = $58
CHARACTER_INDEX_TO_DRAW    = $59
BITMAP_TEXT_TO_DRAW        = $5A ; 5B
BITMAP_TO_DRAW = BITMAP_TEXT_TO_DRAW
BITMAP_TEXT_LENGTH         = $5C
BITMAP_TEXT_LENGTH_PIXELS = BITMAP_TEXT_LENGTH
BITMAP_WIDTH_PIXELS        = $5D
BITMAP_HEIGHT_PIXELS       = $5E

; FREE: $5F available

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

; FREE: $6D - $6F available

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

; $80-$A8 must be left alone, otherwise the kernal breaks, in particular, DOS is breaking.

SLOPE_LEFT_RIGHT         = $A9 ; AA ; AB   ; TODO: do we really need 24 bits here?
SLOPE_RIGHT_LEFT = SLOPE_LEFT_RIGHT

; FREE: $AC - $AF available

LEFT_OVER_PIXELS         = $B0 ; B1
NIBBLE_PATTERN           = $B2
NR_OF_FULL_CACHE_WRITES  = $B3
NR_OF_STARTING_PIXELS    = $B4
NR_OF_ENDING_PIXELS      = $B5

GEN_START_X              = $B6
GEN_FILL_LENGTH_LOW      = $B7
GEN_FILL_LENGTH_IS_16_OR_MORE = $B8
GEN_LOANED_16_PIXELS     = $B9
GEN_FILL_LINE_CODE_INDEX = $BA

; FREE: $BB - $BF available

TMP_POINT_X              = $C0 ; C1
TMP_POINT_Y              = $C2 ; C3
TMP_POINT_Z              = $C4 ; C5

ANGLE_X                  = $C6 ; C7  ; number between 0 and 511
ANGLE_Y_WINGS            = $C8 ; C9  ; number between 0 and 511
ANGLE_Y_WINGS_INV        = $CA ; CB  ; number between 0 and 511
ANGLE_Z                  = $CC ; CD  ; number between 0 and 511

WING_ANIMATION_INDEX     = $CE

; FREE: $CF available

TRANSLATE_Z              = $D0 ; D1

ANGLE                    = $D2 ; D3
SINE_OUTPUT              = $D4 ; D5
MINUS_SINE_OUTPUT        = $D6 ; D7
COSINE_OUTPUT            = $D8 ; D9
; FIXME: not used atm!
MINUS_COSINE_OUTPUT      = $DA ; DB

DOT_PRODUCT              = $DC ; DD
CURRENT_SUM_Z            = $DE ; DF

FRAME_BUFFER_INDEX       = $E0     ; 0 or 1: indicating which frame buffer is to be filled (for double buffering)

CURRENT_LINKED_LIST_ENTRY  = $E1
PREVIOUS_LINKED_LIST_ENTRY = $E2
LINKED_LIST_NEW_ENTRY      = $E3

DELTA_ANGLE_X              = $E4 ; E5
DELTA_ANGLE_Y_WINGS        = $E6 ; E7
DELTA_ANGLE_Z              = $E8 ; E9

NR_OF_KBD_KEY_CODE_BYTES   = $EA     ; Required by keyboard.s

LIGHT_DIRECTION_3D_X       = $EB ; EC
LIGHT_DIRECTION_3D_Y       = $ED ; EE
LIGHT_DIRECTION_3D_Z       = $EF ; F0


DEBUG_VALUE                = $F1


; ---------- RAM addresses used during LOADING of SD files ------
    .ifndef CREATE_PRG
SOURCE_TABLE_ADDRESS     = $C000
    .else
DOS_BANK0_BACKUP         = $5000  ; We use this part of memory to backup $B000-BF00 (used by DOS) to be able to load SD files
SOURCE_TABLE_ADDRESS     = $5F00
    .endif
; ---------------------------------------------------------------

; ------------ RAM addresses used during the DEMO ---------------

FILL_LENGTH_LOW_SOFT     = $4800
FILL_LENGTH_HIGH_SOFT    = $4801

KEYBOARD_STATE           = $4A80   ; 128 bytes (state for each key of the keyboard)
CLEAR_COLUMN_CODE        = $4B00   ; takes up to 02D0
KEYBOARD_KEY_CODE_BUFFER = $4DE0   ; 32 bytes (can be much less, since compact key codes are used now) -> used by keyboard.s

FILL_LINE_START_JUMP     = $4E00
FILL_LINE_START_CODE     = $4F00   ; 128 different (start of) fill line code patterns -> safe: takes $0D00 bytes

; FIXME: can we put these jump tables closer to each other? Do they need to be aligned to 256 bytes? (they are 80 bytes each)
; FIXME: IMPORTANT: we set the two lower bits of this address in the code, using FILL_LINE_END_JUMP_0 as base. So the distance between the 4 tables should stay $100! AND the two lower bits should stay 00b!
FILL_LINE_END_JUMP_0     = $5C00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_0)
FILL_LINE_END_JUMP_1     = $5D00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_1)
FILL_LINE_END_JUMP_2     = $5E00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_2)
FILL_LINE_END_JUMP_3     = $5F00   ; 20 entries (* 4 bytes) of jumps into FILL_LINE_END_CODE_3)

; FIXME: can we put these code blocks closer to each other? Are they <= 256 bytes? -> MORE than 256 bytes!!
FILL_LINE_END_CODE_0     = $6000   ; 3 (stz) * 80 (=320/4) = 240                      + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_END_CODE_1     = $6200   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_END_CODE_2     = $6400   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?
FILL_LINE_END_CODE_3     = $6600   ; 3 (stz) * 80 (=320/4) = 240 + lda .. + sta DATA1 + lda DATA0 + lda DATA1 + dey + beq + ldx $9F2B + jmp (..,x) + rts/jmp?

; Triangle data is (easely) accessed through an single index (0-127)
; == IMPORTANT: we assume a *clockwise* ordering of the 3 points of a triangle! ==
MAX_NR_OF_TRIANGLES      = 128
TRIANGLES_POINT1_X       = $6800 ; 6880
TRIANGLES_POINT1_Y       = $6900 ; 6980
TRIANGLES_POINT2_X       = $6A00 ; 6A80
TRIANGLES_POINT2_Y       = $6B00 ; 6B80
TRIANGLES_POINT3_X       = $6C00 ; 6C80
TRIANGLES_POINT3_Y       = $6D00 ; 6D80

TRIANGLES_ORG_COLOR      = $6E00 ; Only 128 bytes used
TRIANGLES_COLOR          = $6E80 ; Only 128 bytes used

TRIANGLES_LINKED_LIST_INDEX = $6F00 ; Only 128 bytes used
TRIANGLES_LINKED_LIST_NEXT  = $6F80 ; Only 128 bytes used

; FIXME: We should instead use a series of POINTS and INDEXES to those points are used to define TRIANGLES!
TRIANGLES_3D_POINT1_X    = $7000 ; 7080
TRIANGLES_3D_POINT1_Y    = $7100 ; 7180
TRIANGLES_3D_POINT1_Z    = $7200 ; 7280
TRIANGLES_3D_POINT2_X    = $7300 ; 7380
TRIANGLES_3D_POINT2_Y    = $7400 ; 7480
TRIANGLES_3D_POINT2_Z    = $7500 ; 7580
TRIANGLES_3D_POINT3_X    = $7600 ; 7680
TRIANGLES_3D_POINT3_Y    = $7700 ; 7780
TRIANGLES_3D_POINT3_Z    = $7800 ; 7880
TRIANGLES_3D_POINTN_X    = $7900 ; 7980
TRIANGLES_3D_POINTN_Y    = $7A00 ; 7A80
TRIANGLES_3D_POINTN_Z    = $7B00 ; 7B80

TRIANGLES2_3D_POINT1_X   = $7C00 ; 7C80
TRIANGLES2_3D_POINT1_Y   = $7D00 ; 7D80
TRIANGLES2_3D_POINT1_Z   = $7E00 ; 7E80
TRIANGLES2_3D_POINT2_X   = $7F00 ; 7F80
TRIANGLES2_3D_POINT2_Y   = $8000 ; 8080
TRIANGLES2_3D_POINT2_Z   = $8100 ; 8180
TRIANGLES2_3D_POINT3_X   = $8200 ; 8280
TRIANGLES2_3D_POINT3_Y   = $8300 ; 8380
TRIANGLES2_3D_POINT3_Z   = $8400 ; 8480
TRIANGLES2_3D_POINTN_X   = $8500 ; 8580
TRIANGLES2_3D_POINTN_Y   = $8600 ; 8680
TRIANGLES2_3D_POINTN_Z   = $8700 ; 8780

TRIANGLES3_3D_POINT1_X   = $8800 ; 8880
TRIANGLES3_3D_POINT1_Y   = $8900 ; 8980
TRIANGLES3_3D_POINT1_Z   = $8A00 ; 8A80
TRIANGLES3_3D_POINT2_X   = $8B00 ; 8B80
TRIANGLES3_3D_POINT2_Y   = $8C00 ; 8C80
TRIANGLES3_3D_POINT2_Z   = $8D00 ; 8D80
TRIANGLES3_3D_POINT3_X   = $8E00 ; 8E80
TRIANGLES3_3D_POINT3_Y   = $8F00 ; 8F80
TRIANGLES3_3D_POINT3_Z   = $9000 ; 9080
TRIANGLES3_3D_POINTN_X   = $9100 ; 9180
TRIANGLES3_3D_POINTN_Y   = $9200 ; 9280
TRIANGLES3_3D_POINTN_Z   = $9300 ; 9380
TRIANGLES3_3D_SUM_Z      = $9400 ; 9480


Y_TO_ADDRESS_LOW         = $9500
Y_TO_ADDRESS_HIGH        = $9600
Y_TO_ADDRESS_BANK        = $9700
Y_TO_ADDRESS_BANK2       = $9800   ; Only use when double buffering

    .ifndef CREATE_PRG
COPY_SLOPE_TABLES_TO_BANKED_RAM = $9900  ; TODO: is this smaller than 256 bytes?
COPY_DIV_TABLES_TO_BANKED_RAM   = $9A00
    .endif

; === Banked RAM addresses ===

    ; When USE_POLYGON_FILLER is 1: A000-A9FF and B600-BFFF are occucpied by the slope tables! (the latter by the 90-180 degrees slope tables)
    ;                               B000-B3FF will contain the DIV tables
    ;                               B500-B5FF will be used for bitmap text
BITMAP_TEXT              = $B500
BITMAP = BITMAP_TEXT

    ; When USE_POLYGON_FILLER is 0: A000-B4FF are occucpied by the slope tables!
    
    .if(USE_POLYGON_FILLER)
        .if(!USE_JUMP_TABLE)
DRAW_ROW_64_CODE         = $AA00   
        .endif
    .else
DRAW_ROW_64_CODE         = $B500   
    .endif

; ---------------------------------------------------------------
    


; ------------- VRAM addresses -------------

MATH_RESULTS_ADDRESS     = $0FF00  ; The place where all math results are stored -> After the first frame buffer, just before the second frame buffer.


    .include utils/build_as_prg_or_rom.s


reset:

    .if(CREATE_PRG)
        .include fx_tests/utils/check_for_vera_fx_firmware.s
    .endif

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs

    jsr setup_vera_for_bitmap_and_tile_map
    .if(USE_DOUBLE_BUFFER)
        lda #%00000000  ; DCSEL=0
        sta VERA_CTRL
        
        lda VERA_DC_VIDEO
        and #%10001111           ; Disable Layer 0 and 1 and sprites
        sta VERA_DC_VIDEO
    .endif
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor
    jsr init_keyboard
    jsr init_timer

    .ifdef CREATE_PRG
        ; We create a backup of the DOS variables in B000-BF00 of ram bank 0
        jsr backup_bank0_B000_into_5000
    .endif

    .if(USE_SLOPE_TABLES)
        .ifndef CREATE_PRG
            jsr copy_slope_table_copier_to_ram
            jsr COPY_SLOPE_TABLES_TO_BANKED_RAM
        .else
            ; When running as PRG, we have to load the SLOPE tables from the SD card
            ; So we dont need to use ROM banks. There is no need to copy the copier.
            ; IMPORTANT: copying of the SLOPE tables temporarily uses 16kB of Fixed RAM, so this
            ;            has to be done BEFORE parts of this 16kB is filled with other information!
            jsr copy_slope_tables_to_banked_ram
        .endif
    .endif
    
    .if(USE_DIV_TABLES)
        .ifndef CREATE_PRG
            jsr copy_div_table_copier_to_ram
            jsr COPY_DIV_TABLES_TO_BANKED_RAM
        .else
            ; When running as PRG, we have to load the DIV tables from the SD card
            ; So we dont need to use ROM banks. There is no need to copy the copier.
            ; IMPORTANT: copying of the DIV tables temporarily uses 16kB of Fixed RAM, so this
            ;            has to be done BEFORE parts of this 16kB is filled with other information!
            jsr copy_div_tables_to_banked_ram
        .endif
    .endif
    
; FIXME: is this the correct place?
    .if(DRAW_BITMAP_TEXT)
        ; -- FIRMWARE VERSION --
    
        jsr copy_vera_firmware_version
        
        lda #end_of_vera_firmware_version_text-vera_firmware_version_text
        sta BITMAP_TEXT_LENGTH
        
        lda #<vera_firmware_version_text
        sta BITMAP_TEXT_TO_DRAW
        lda #>vera_firmware_version_text
        sta BITMAP_TEXT_TO_DRAW+1
        
        lda #FIRMWARE_RAM_BANK_START
        sta BITMAP_RAM_BANK_START
        
        jsr generate_text_as_bitmap_in_banked_ram
        
        ; -- VERA FX DEMO --
        
        lda #end_of_vera_fx_demo_text-vera_fx_demo_text
        sta BITMAP_TEXT_LENGTH
        
        lda #<vera_fx_demo_text
        sta BITMAP_TEXT_TO_DRAW
        lda #>vera_fx_demo_text
        sta BITMAP_TEXT_TO_DRAW+1
        
        lda #FX_DEMO_RAM_BANK_START
        sta BITMAP_RAM_BANK_START
        
        jsr generate_text_as_bitmap_in_banked_ram
        
        ; -- BUTTERFLY --
        
        lda #end_of_butterfly_3d_text-butterfly_3d_text
        sta BITMAP_TEXT_LENGTH
        
        lda #<butterfly_3d_text
        sta BITMAP_TEXT_TO_DRAW
        lda #>butterfly_3d_text
        sta BITMAP_TEXT_TO_DRAW+1
        
        lda #BUTTERFLY_RAM_BANK_START
        sta BITMAP_RAM_BANK_START
        
        jsr generate_text_as_bitmap_in_banked_ram
        
    .endif
    .if(DRAW_CURSOR_KEYS)
    
        lda #<left_down_right_keys_data
        sta BITMAP_TO_DRAW
        lda #>left_down_right_keys_data
        sta BITMAP_TO_DRAW+1
    
        lda #LEFT_DOWN_RIGHT_KEY_RAM_BANK_START
        sta BITMAP_RAM_BANK_START
        
        lda #LEFT_DOWN_RIGHT_KEY_HEIGHT_PIXELS
        sta BITMAP_HEIGHT_PIXELS
        
        lda #LEFT_DOWN_RIGHT_KEY_WIDTH_PIXELS
        sta BITMAP_WIDTH_PIXELS
        
        jsr copy_bitmap_to_banked_ram
        
        lda #<up_key_data
        sta BITMAP_TO_DRAW
        lda #>up_key_data
        sta BITMAP_TO_DRAW+1
        
        lda #UP_KEY_RAM_BANK_START
        sta BITMAP_RAM_BANK_START
        
        lda #UP_KEY_HEIGHT_PIXELS
        sta BITMAP_HEIGHT_PIXELS
        
        lda #UP_KEY_WIDTH_PIXELS
        sta BITMAP_WIDTH_PIXELS
        
        jsr copy_bitmap_to_banked_ram
    
    .endif

    .if (USE_WRITE_CACHE)
        jsr generate_clear_column_code
        jsr clear_screen_fast_4_bytes
    .else
        jsr clear_screen_slow
    .endif
    
    
    .if(USE_UNROLLED_LOOP)
        .if(!USE_JUMP_TABLE)
            jsr generate_draw_row_64_code
        .endif
    .endif
    
    .if(USE_JUMP_TABLE)
        jsr generate_fill_line_end_code
        jsr generate_fill_line_end_jump
        jsr generate_fill_line_start_code_and_jump
    .endif
    
    .if(USE_Y_TO_ADDRESS_TABLE)
        jsr generate_y_to_address_table
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
                .if(DRAW_BITMAP_TEXT)
                    jsr draw_all_bitmap_texts
                    jsr draw_cursor_keys
                .endif
            .else
                jsr clear_screen_slow
            .endif
            
            jsr switch_frame_buffer   ; This will switch to filling buffer 0, but *showing* buffer 1
            
        .endif

        .if(USE_DOUBLE_BUFFER)
            lda #%00000000  ; DCSEL=0
            sta VERA_CTRL
            
            lda VERA_DC_VIDEO
            ora #%00010000           ; Only enable Layer 0
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

    .if(1)
        jsr copy_palette_from_index_16
        .if(DO_BUTTERFLY)
            jsr copy_palette_from_index_128
        .endif
    .endif

    jsr load_3d_triangle_data_into_ram

    jsr start_timer
    
    jsr init_world
    
keep_running:
    
    .if (USE_WRITE_CACHE)
        jsr clear_screen_fast_4_bytes
        
        .if(DRAW_BITMAP_TEXT)
            jsr draw_all_bitmap_texts
            jsr draw_cursor_keys
        .endif
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

    .if(DO_BUTTERFLY)
; FIXME!
        lda #0
        sta ANGLE_Y_WINGS
        lda #0
        sta ANGLE_Y_WINGS+1

        stz WING_ANIMATION_INDEX
        
        ; We start movement of the wings
        lda #2
        sta DELTA_ANGLE_Y_WINGS
        lda #0
        sta DELTA_ANGLE_Y_WINGS+1
    .endif

; FIXME!
    lda #200
;    lda #0
    sta ANGLE_Z
    lda #0
    sta ANGLE_Z+1

; FIXME!
    lda #200
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
; FIXME: do this more cleanly!
;    stz DELTA_ANGLE_Y_WINGS
;    stz DELTA_ANGLE_Y_WINGS+1
    stz DELTA_ANGLE_Z
    stz DELTA_ANGLE_Z+1
    
    .if(USE_KEYBOARD_INPUT)

; FIXME: what we really should do is determine which part of x,y,z has to be adjusted due to a left array key press (= dependent on the ship orientation)
X_SPEED = 2
Z_SPEED = 2

        ; -- Left arrow key --
        ldx #KEY_CODE_LEFT_ARROW
        lda KEYBOARD_STATE, x
        beq left_arrow_key_down_handled
        
        lda #<(Z_SPEED)
        sta DELTA_ANGLE_Z
        lda #>(Z_SPEED)
        sta DELTA_ANGLE_Z+1
left_arrow_key_down_handled:

        ; -- Right arrow key --
        ldx #KEY_CODE_RIGHT_ARROW
        lda KEYBOARD_STATE, x
        beq right_arrow_key_down_handled
        
        lda #<(-Z_SPEED)
        sta DELTA_ANGLE_Z
        lda #>(-Z_SPEED)
        sta DELTA_ANGLE_Z+1
right_arrow_key_down_handled:

        ; -- Up arrow key --
        ldx #KEY_CODE_UP_ARROW
        lda KEYBOARD_STATE, x
        beq up_arrow_key_down_handled
        
        lda #<(X_SPEED)
        sta DELTA_ANGLE_X
        lda #>(X_SPEED)
        sta DELTA_ANGLE_X+1
up_arrow_key_down_handled:

        ; -- Down arrow key --
        ldx #KEY_CODE_DOWN_ARROW
        lda KEYBOARD_STATE, x
        beq down_arrow_key_down_handled
        
        lda #<(-X_SPEED)
        sta DELTA_ANGLE_X
        lda #>(-X_SPEED)
        sta DELTA_ANGLE_X+1
down_arrow_key_down_handled:

    .else
        lda #2
        sta DELTA_ANGLE_Z
        lda #1
        sta DELTA_ANGLE_X
    .endif
    
    .if(DO_BUTTERFLY)
    
; FIXME: do this more cleanly!

        lda WING_ANIMATION_INDEX
        cmp #30
        bcc delta_angle_y_wings_is_ok
        
        ; We need to negate the wing motion
        sec
        lda #<(512)
        sbc DELTA_ANGLE_Y_WINGS
        sta DELTA_ANGLE_Y_WINGS
        lda #>(512)
        sbc DELTA_ANGLE_Y_WINGS+1
        sta DELTA_ANGLE_Y_WINGS+1
        
        ; We start over the animation (the opposite direction)
        stz WING_ANIMATION_INDEX
        
delta_angle_y_wings_is_ok:
        inc WING_ANIMATION_INDEX
        
        ; -- Update ANGLE_Y_WINGS --
        clc
        lda ANGLE_Y_WINGS
        adc DELTA_ANGLE_Y_WINGS
        sta ANGLE_Y_WINGS
        lda ANGLE_Y_WINGS+1
        adc DELTA_ANGLE_Y_WINGS+1
        sta ANGLE_Y_WINGS+1

        bpl angle_y_wings_is_positive
        clc
        adc #$2               ; We have a negative angle, so we have to add $200
        sta ANGLE_Y_WINGS+1
        bra angle_y_wings_updated
angle_y_wings_is_positive:
        cmp #2                ; we should never reach $200, we are >= $200
        bne angle_y_wings_updated
        sec
        sbc #$2               ; We have a angle >= $200, so we have to subtract $200
        sta ANGLE_Y_WINGS+1
angle_y_wings_updated:
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
    
    ; Handy: https://www.cs.helsinki.fi/group/goa/mallinnus/3dtransf/3drot.html
    
    ; FIXME: SPEED: we should *COMBINE* these X, Y and Z rotations into a WORLD MATRIX!
    
    .if(DO_BUTTERFLY)
    
        MACRO_load_sine ANGLE_Y_WINGS
        MACRO_load_cosine ANGLE_Y_WINGS
        
        ldx #0
rotate_first_wing_in_y_next_triangle:

        MACRO_reset_fx_multiplier

        ; -- Point 1 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT1_Z, TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT1_Z, TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_X
        
        ; -- Point 2 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT2_Z, TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT2_Z, TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_X

        ; -- Point 3 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT3_Z, TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT3_Z, TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_X

        ; -- Point N --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINTN_Z, TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINTN_Z, TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_X

        inx
        cpx #NR_OF_TRIANGLES/2  ; first wing = first half of the triangles
        beq rotate_first_wing_in_y_done
        jmp rotate_first_wing_in_y_next_triangle
rotate_first_wing_in_y_done:

        ; We take the inverse (360 degrees minus the angle) of the wing-angle for the second wing
        sec
; FIXME: WHY DOESNT 512 work here??
; FIXME: WHY DOESNT 512 work here??
; FIXME: WHY DOESNT 512 work here??
        lda #<(511)    ; 511 = 360 degrees
        sbc ANGLE_Y_WINGS
        sta ANGLE_Y_WINGS_INV
        lda #>(511)
        sbc ANGLE_Y_WINGS+1
        sta ANGLE_Y_WINGS_INV+1
        
        MACRO_load_sine ANGLE_Y_WINGS_INV
        MACRO_load_cosine ANGLE_Y_WINGS_INV
        
        ldx #NR_OF_TRIANGLES/2 ; second wing =  second half of the triangles
rotate_second_wing_in_y_next_triangle:

        MACRO_reset_fx_multiplier

        ; -- Point 1 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT1_Z, TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT1_Z, TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_X
        
        ; -- Point 2 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT2_Z, TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT2_Z, TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_X

        ; -- Point 3 --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINT3_Z, TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINT3_Z, TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_X

        ; -- Point N --
        MACRO_rotate_cos_minus_sin TRIANGLES_3D_POINTN_Z, TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_Z
        MACRO_rotate_sin_plus_cos  TRIANGLES_3D_POINTN_Z, TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_X

        inx
        cpx #NR_OF_TRIANGLES
        beq rotate_second_wing_in_y_done
        jmp rotate_second_wing_in_y_next_triangle
rotate_second_wing_in_y_done:

    .else
        ; FIXME: SPEED: we dont really want to do this when not doing butterfly wings!
        ldx #0
copy_x_and_z_next_triangle:

        ; -- Point 1 --
        MACRO_copy_point_value TRIANGLES_3D_POINT1_X, TRIANGLES2_3D_POINT1_X
        MACRO_copy_point_value TRIANGLES_3D_POINT1_Z, TRIANGLES2_3D_POINT1_Z
        
        ; -- Point 2 --
        MACRO_copy_point_value TRIANGLES_3D_POINT2_X, TRIANGLES2_3D_POINT2_X
        MACRO_copy_point_value TRIANGLES_3D_POINT2_Z, TRIANGLES2_3D_POINT2_Z

        ; -- Point 3 --
        MACRO_copy_point_value TRIANGLES_3D_POINT3_X, TRIANGLES2_3D_POINT3_X
        MACRO_copy_point_value TRIANGLES_3D_POINT3_Z, TRIANGLES2_3D_POINT3_Z

        ; -- Point N --
        MACRO_copy_point_value TRIANGLES_3D_POINTN_X, TRIANGLES2_3D_POINTN_X
        MACRO_copy_point_value TRIANGLES_3D_POINTN_Z, TRIANGLES2_3D_POINTN_Z

        inx
        cpx #NR_OF_TRIANGLES
        beq copy_x_and_z_done
        jmp copy_x_and_z_next_triangle
copy_x_and_z_done:

    .endif
    
    
    
    

    MACRO_load_sine ANGLE_Z
    MACRO_load_cosine ANGLE_Z
    
    ldx #0
rotate_in_z_next_triangle:

    MACRO_reset_fx_multiplier

    ; -- Point 1 --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT1_X, TRIANGLES_3D_POINT1_Y, TRIANGLES3_3D_POINT1_X
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT1_X, TRIANGLES_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Y
    
    ; -- Point 2 --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT2_X, TRIANGLES_3D_POINT2_Y, TRIANGLES3_3D_POINT2_X
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT2_X, TRIANGLES_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Y

    ; -- Point 3 --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT3_X, TRIANGLES_3D_POINT3_Y, TRIANGLES3_3D_POINT3_X
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT3_X, TRIANGLES_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Y

    ; -- Point N --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES3_3D_POINTN_X
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINTN_X, TRIANGLES_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Y

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
    
    MACRO_reset_fx_multiplier

    ; -- Point 1 --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Y
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT1_Y, TRIANGLES2_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Z
    
    ; -- Point 2 --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Y
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT2_Y, TRIANGLES2_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Z

    ; -- Point 3 --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Y
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINT3_Y, TRIANGLES2_3D_POINT3_Z, TRIANGLES3_3D_POINT3_Z
    
    ; -- Point N --
    MACRO_rotate_cos_minus_sin TRIANGLES2_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Y
    MACRO_rotate_sin_plus_cos  TRIANGLES2_3D_POINTN_Y, TRIANGLES2_3D_POINTN_Z, TRIANGLES3_3D_POINTN_Z
    
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
    MACRO_calculate_dot_product TRIANGLES3_3D_POINT1_X, TRIANGLES3_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINTN_X, TRIANGLES3_3D_POINTN_Y, TRIANGLES3_3D_POINTN_Z
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
        
; FIXME: maybe we should the bright color base base color (not black)?
        
; FIXME: REMOVE lda #$10    ; Black for now
        lda TRIANGLES_ORG_COLOR,x   ; Base color (dark)
        bra color_calculated
check_if_full_light:
        ; -- Take care of +1.0 case --
        lda DOT_PRODUCT+1
        beq map_light_to_color
        ; When DOT_PRODUCT = 01.00 we want FULL light color!
        lda #$0F  ; white
        ora TRIANGLES_ORG_COLOR,x   ; Base color (dark)
; FIXME: REMOVE lda #$1F  ; white
        bra color_calculated
map_light_to_color:
        ; -- Take care < +1.0 cases --
        lda DOT_PRODUCT
        lsr
        lsr
        lsr
        lsr
        ora TRIANGLES_ORG_COLOR,x   ; Base color (dark)
; FIXME: REMOVE   ora #$10   ; starting with black
color_calculated:
        sta TRIANGLES_COLOR,y
    .else
        lda TRIANGLES_ORG_COLOR,x
        sta TRIANGLES_COLOR,y
    .endif

    ; -- Project triangle from 3D world onto 2D screen --

    MACRO_reset_fx_multiplier

    phy
    
    ; - Point 1 -
    MACRO_divide_by_z TRIANGLES3_3D_POINT1_X, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT1_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT1_Y, TRIANGLES3_3D_POINT1_Z, TRIANGLES3_3D_POINT1_Y
    
    ; - Point 2 -
    MACRO_divide_by_z TRIANGLES3_3D_POINT2_X, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT2_X
    MACRO_divide_by_z TRIANGLES3_3D_POINT2_Y, TRIANGLES3_3D_POINT2_Z, TRIANGLES3_3D_POINT2_Y
    
    ; - Point 3 -
    MACRO_divide_by_z TRIANGLES3_3D_POINT3_X, TRIANGLES3_3D_POINT3_Z, TRIANGLES3_3D_POINT3_X
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

    .if(DO_BUTTERFLY)
copy_palette_from_index_128:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<(VERA_PALETTE+2*128)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE+2*128)
    sta VERA_ADDR_HIGH

    ldy #0
next_packed_color_128:
    lda palette_data_128, y
    sta VERA_DATA0
    iny
    cpy #(end_of_palette_data_128-palette_data_128)
    bne next_packed_color_128

    rts
    .endif

    
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
    

; FIXME: move this somewhere else!

; This will generate a bitmap given a text string
; The size of the bitmap will be BITMAP_TEXT_LENGTH * 6 pixels wide by 5 pixels high
; Each of the 5 horizontal lines will be stored in a different bank.
; The address each line is stored is STORE_ADDRESS+1 + 256-(6*BITMAP_TEXT_LENGTH)
; The text input should start BITMAP_TEXT_TO_DRAW and be in ascii lower case. BITMAP_TEXT_LENGTH should be set appropiatly (zero-termination is ignored)

ascii_to_5x5_character_index:
; FIXME: implement this!
    rts


set_load_address_to_5x5_character_data:

    lda #<font_5x5_data
    sta LOAD_ADDRESS
    lda #>font_5x5_data
    sta LOAD_ADDRESS+1
    
    ; HACK: in order to multiply the character index by 25 (=5x5 bytes) we multiply by 16, by 8 and by 1 and add the results (16+8+1=25)
    lda CHARACTER_INDEX_TO_DRAW
    sta TMP1
    stz TMP2
    
    ; Adding CHARACTER_INDEX_TO_DRAW * 1
    clc
    lda LOAD_ADDRESS
    adc TMP1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc TMP2
    sta LOAD_ADDRESS+1
    
    ; CHARACTER_INDEX_TO_DRAW * 2
    asl TMP1
    rol TMP2  

    ; CHARACTER_INDEX_TO_DRAW * 4
    asl TMP1
    rol TMP2  
    
    ; CHARACTER_INDEX_TO_DRAW * 8
    asl TMP1
    rol TMP2
    
    ; Adding CHARACTER_INDEX_TO_DRAW * 8
    clc
    lda LOAD_ADDRESS
    adc TMP1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc TMP2
    sta LOAD_ADDRESS+1
    
    ; CHARACTER_INDEX_TO_DRAW * 16
    asl TMP1
    rol TMP2

    ; Adding CHARACTER_INDEX_TO_DRAW * 16
    clc
    lda LOAD_ADDRESS
    adc TMP1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc TMP2
    sta LOAD_ADDRESS+1

    rts


generate_one_5x5_character:
    
    ldx #0   ; x represents the line number of the character
generate_one_line_of_char:
    ldy #0   ; y represents the pixel number within the line of a character
generate_one_pixel_of_char:
    lda (LOAD_ADDRESS)
    bne char_pixel_color_ok
    lda #BACKGROUND_COLOR      ; If we see a 00, we want to replace it with the background color
char_pixel_color_ok:
    sta (STORE_ADDRESS), y
    
    ; We need to move to the next pixel to load
    clc
    lda LOAD_ADDRESS
    adc #1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    iny
    cpy #5
    bne generate_one_pixel_of_char
    
    ; We are one more empty pixel (whitespace)
    lda #BACKGROUND_COLOR
    sta (STORE_ADDRESS), y

    ; The next line to be store is in the next RAM_BANK
    inc RAM_BANK
    
    inx
    cpx #5
    bne generate_one_line_of_char
    
    rts

    
    ; --------------------------------- BITMAP TEXTS --------------------------------------
    
    ; FIXME: dont put this here!!
FIRMWARE_X_POS = 10
FIRMWARE_Y_POS = 20
;FIRMWARE_Y_POS = 180
FIRMWARE_RAM_BANK_START = 0
vera_firmware_version_text:
;    .byte 6, 9, 18, 13, 23, 1, 18, 5, 0, 22, 27, 37, 27, 37, 27 ; "FIRMWARE V0.0.0"
    .byte 22, 5, 18, 1, 0, 6, 9, 18, 13, 23, 1, 18, 5, 0, 22, 27, 37, 27, 37, 27 ; "VERA FIRMWARE V0.0.0"
end_of_vera_firmware_version_text:

FX_DEMO_X_POS = 10
FX_DEMO_Y_POS = 10
FX_DEMO_RAM_BANK_START = 5
vera_fx_demo_text:
;    .byte 22, 5, 18, 1, 0, 6, 24, 0, 4, 5, 13, 15 ; "VERA FX DEMO"
;    .byte 22, 5, 18, 1, 0, 6, 24, 0, 4, 5, 13, 15, 38, 0, 39, 30, 4, 0, 2, 21, 20, 20, 5, 18, 6, 12, 25, 39 ; 'VERA FX DEMO: "3D BUTTERFLY"'
    .byte 6, 24, 0, 4, 5, 13, 15, 38, 0, 39, 30, 4, 0, 2, 21, 20, 20, 5, 18, 6, 12, 25, 39 ; 'FX DEMO: "3D BUTTERFLY"'
end_of_vera_fx_demo_text:

BUTTERFLY_X_POS = 10
BUTTERFLY_Y_POS = 10
;BUTTERFLY_Y_POS = 180
BUTTERFLY_RAM_BANK_START = 10
butterfly_3d_text:
;    .byte 39, 30, 4, 0, 2, 21, 20, 20, 5, 18, 6, 12, 25, 39 ; '"3D BUTTERFLY"'
    .byte 6, 24, 0, 4, 5, 13, 15, 38, 0, 39, 30, 4, 0, 2, 21, 20, 20, 5, 18, 6, 12, 25, 39 ; 'FX DEMO: "3D BUTTERFLY"'
end_of_butterfly_3d_text:

    ; ------------------------------- / BITMAP TEXTS --------------------------------------


    ; --------------------------------- BITMAPS --------------------------------------
    
; FIXME: this might be lower if less than 3 bitmap texts are drawn!
LEFT_DOWN_RIGHT_KEY_RAM_BANK_START = 15
LEFT_DOWN_RIGHT_KEY_Y_POS = 175
LEFT_DOWN_RIGHT_KEY_X_POS = 260
    
UP_KEY_RAM_BANK_START = 15+13
UP_KEY_Y_POS = 175-14
UP_KEY_X_POS = 260+14

    ; ------------------------------- / BITMAPS --------------------------------------

copy_vera_firmware_version:

    lda #%01111110           ; DCSEL=63, ADDRSEL=0
    sta VERA_CTRL
    
    ; Note we are skipping VERA_DC_VER0 here, since it must be 'V' when we reach this point
    
    clc
    lda VERA_DC_VER1
    adc #27          ; our 0 starts at character index 27
    sta end_of_vera_firmware_version_text-5
    
    clc
    lda VERA_DC_VER2
    adc #27          ; our 0 starts at character index 27
    sta end_of_vera_firmware_version_text-3
    
    clc
    lda VERA_DC_VER3
    adc #27          ; our 0 starts at character index 27
    sta end_of_vera_firmware_version_text-1

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    rts

copy_bitmap_to_banked_ram:

    lda #<BITMAP
    sta STORE_ADDRESS
    lda #>BITMAP
    sta STORE_ADDRESS+1
    
    ; Switching the the appropiate RAM_BANK
    lda BITMAP_RAM_BANK_START
    sta RAM_BANK

    lda BITMAP_TO_DRAW
    sta LOAD_ADDRESS
    lda BITMAP_TO_DRAW+1
    sta LOAD_ADDRESS+1

    ldx #0   ; x represents the y position in the bitmap
generate_one_line_of_bitmap:
    ldy #0   ; y represents the x position the horizontal line of a bitmap
generate_one_pixel_of_bitmap:
    lda (LOAD_ADDRESS)
    bne bitmap_pixel_color_ok
    lda #BACKGROUND_COLOR      ; If we see a 00, we want to replace it with the background color
bitmap_pixel_color_ok:
    sta (STORE_ADDRESS), y
    
    ; We need to move to the next pixel to load
    clc
    lda LOAD_ADDRESS
    adc #1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    iny
    cpy BITMAP_WIDTH_PIXELS
    bne generate_one_pixel_of_bitmap
    
    ; The next line to be store is in the next RAM_BANK
    inc RAM_BANK
    
    inx
    cpx BITMAP_HEIGHT_PIXELS
    bne generate_one_line_of_bitmap
    

; FIXME: restore the RAM_BANK properly?!
    lda #0
    sta RAM_BANK
    
    rts

generate_text_as_bitmap_in_banked_ram:    

    ; FIXME: we need to offset STORE_ADDRESS by 256 - 6*BITMAP_TEXT_LENGTH!
    lda #<BITMAP_TEXT
    sta STORE_ADDRESS
    lda #>BITMAP_TEXT
    sta STORE_ADDRESS+1

    ; We start at the first character of the string
; FIXME: use a different variable than TMP4 here!
    stz TMP4
    
generate_next_character:
    ; TODO: jsr ascii_to_5x5_character_index

; FIXME: use a different variable than TMP4 here!
    ldy TMP4  ; the index in the string
    lda (BITMAP_TEXT_TO_DRAW), y
    sta CHARACTER_INDEX_TO_DRAW

    jsr set_load_address_to_5x5_character_data
    
    ; Switching the the appropiate RAM_BANK
    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    jsr generate_one_5x5_character
    
    ; Moving to the next place to draw a character (6 pixels to the right: 5 for the character + 1 for whitespace)
    clc
    lda STORE_ADDRESS
    adc #6
    sta STORE_ADDRESS
    lda STORE_ADDRESS+1
    adc #0
    sta STORE_ADDRESS+1

; FIXME: use a different variable than TMP4 here!
    inc TMP4

    dec BITMAP_TEXT_LENGTH
    bne generate_next_character

; FIXME: restore the RAM_BANK properly?!
    lda #0
    sta RAM_BANK
    
    rts
    
    
; FIXME: use generated code to make this FASTER!!
draw_bitmap_text_to_screen:

; FIXME: SPEED this is setup each time this routine is called. 
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
 
;    lda #%01001000           ; cache write enabled = 1, 16bit hop = 1, addr1-mode = normal
;    sta VERA_FX_CTRL
    
; FIXME: SPEED this is setup each time this routine is called. 
    ; Setting ADDR0 + increment
    lda #%00010000           ; +1 increment
    ora FRAME_BUFFER_INDEX   ; contains 0 or 1
    sta VERA_ADDR_BANK

    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    ; FIXME: we need to offset LOAD_ADDRESS by 256 - 6*BITMAP_TEXT_LENGTH!
    lda #<BITMAP_TEXT
    sta LOAD_ADDRESS
    lda #>BITMAP_TEXT
    sta LOAD_ADDRESS+1
    
    ldx #5
draw_bitmap_text_next_line:

    lda VRAM_ADDRESS
    sta VERA_ADDR_LOW
    lda VRAM_ADDRESS+1
    sta VERA_ADDR_HIGH
    
    ; We draw 6 pixels for each character
    ldy #0
draw_bitmap_text_next_character_line:
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    cpy BITMAP_TEXT_LENGTH_PIXELS
    bne draw_bitmap_text_next_character_line
    
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    
    inc RAM_BANK
    
    dex
    bne draw_bitmap_text_next_line

    rts
    
    
draw_bitmap_to_screen:

; FIXME: SPEED this is setup each time this routine is called. 
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
 
;    lda #%01001000           ; cache write enabled = 1, 16bit hop = 1, addr1-mode = normal
;    sta VERA_FX_CTRL
    
; FIXME: SPEED this is setup each time this routine is called. 
    ; Setting ADDR0 + increment
    lda #%00010000           ; +1 increment
    ora FRAME_BUFFER_INDEX   ; contains 0 or 1
    sta VERA_ADDR_BANK

    lda BITMAP_RAM_BANK_START
    sta RAM_BANK
    
    lda #<BITMAP
    sta LOAD_ADDRESS
    lda #>BITMAP
    sta LOAD_ADDRESS+1
    
    ldx BITMAP_HEIGHT_PIXELS
draw_bitmap_next_line:

    lda VRAM_ADDRESS
    sta VERA_ADDR_LOW
    lda VRAM_ADDRESS+1
    sta VERA_ADDR_HIGH

; FIXME: SPEED this is SLOW!    
; FIXME: SPEED this is SLOW!    
; FIXME: SPEED this is SLOW!    
    ldy #0
draw_bitmap_next_pixel:
    lda (LOAD_ADDRESS),y
    sta VERA_DATA0
    iny
    cpy BITMAP_WIDTH_PIXELS
    bne draw_bitmap_next_pixel
    
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    
    inc RAM_BANK
    
    dex
    bne draw_bitmap_next_line

    rts
    

    
draw_all_bitmap_texts:

    .if(1)
    ; -- FIRMWARE VERSION --

    lda #FIRMWARE_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #(end_of_vera_firmware_version_text-vera_firmware_version_text)*6
    sta BITMAP_TEXT_LENGTH_PIXELS

    lda #<(320*FIRMWARE_Y_POS+FIRMWARE_X_POS)
    sta VRAM_ADDRESS
    lda #>(320*FIRMWARE_Y_POS+FIRMWARE_X_POS)
    sta VRAM_ADDRESS+1

    jsr draw_bitmap_text_to_screen
    .endif
    
; FIXME: dont GENERATE THIS!
; FIXME: dont GENERATE THIS!
; FIXME: dont GENERATE THIS!
    .if(0)
    ; -- VERA FX DEMO --

    lda #FX_DEMO_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #(end_of_vera_fx_demo_text-vera_fx_demo_text)*6
    sta BITMAP_TEXT_LENGTH_PIXELS

    lda #<(320*FX_DEMO_Y_POS+FX_DEMO_X_POS)
    sta VRAM_ADDRESS
    lda #>(320*FX_DEMO_Y_POS+FX_DEMO_X_POS)
    sta VRAM_ADDRESS+1

    jsr draw_bitmap_text_to_screen
    .endif

    .if(1)
    ; -- BUTTERFLY --

    lda #BUTTERFLY_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #(end_of_butterfly_3d_text-butterfly_3d_text)*6
    sta BITMAP_TEXT_LENGTH_PIXELS

    lda #<(320*BUTTERFLY_Y_POS+BUTTERFLY_X_POS)
    sta VRAM_ADDRESS
    lda #>(320*BUTTERFLY_Y_POS+BUTTERFLY_X_POS)
    sta VRAM_ADDRESS+1

    jsr draw_bitmap_text_to_screen
    .endif

    rts

draw_cursor_keys:

    ; -- UP key --

    lda #UP_KEY_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #UP_KEY_HEIGHT_PIXELS
    sta BITMAP_HEIGHT_PIXELS
    
    lda #UP_KEY_WIDTH_PIXELS
    sta BITMAP_WIDTH_PIXELS
    
    lda #<(320*UP_KEY_Y_POS+UP_KEY_X_POS)
    sta VRAM_ADDRESS
    lda #>(320*UP_KEY_Y_POS+UP_KEY_X_POS)
    sta VRAM_ADDRESS+1
    
    jsr draw_bitmap_to_screen

    ; -- LEFT, DOWN, RIGHT key --

    lda #LEFT_DOWN_RIGHT_KEY_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #LEFT_DOWN_RIGHT_KEY_HEIGHT_PIXELS
    sta BITMAP_HEIGHT_PIXELS
    
    lda #LEFT_DOWN_RIGHT_KEY_WIDTH_PIXELS
    sta BITMAP_WIDTH_PIXELS
    
    lda #<(320*LEFT_DOWN_RIGHT_KEY_Y_POS+LEFT_DOWN_RIGHT_KEY_X_POS)
    sta VRAM_ADDRESS
    lda #>(320*LEFT_DOWN_RIGHT_KEY_Y_POS+LEFT_DOWN_RIGHT_KEY_X_POS)
    sta VRAM_ADDRESS+1
    
    jsr draw_bitmap_to_screen

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
NR_OF_TRIANGLES = 72
triangle_3d_data:
    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)
    ;       x1,    y1,    z1,    x2,    y2,    z2,    x3,    y3,    z3,    xn,    yn,    zn,   cl
    .word $FC32, $FC89, $0000, $FC68, $FD40, $0000, $FD0A, $FD40, $0000, $0000, $0000, $FF00, $0010
    .word $FD0A, $FD40, $0000, $FC68, $FD40, $0000, $FC9E, $FDF8, $0000, $0000, $0000, $FF00, $0020
    .word $FD0A, $FD40, $0000, $FC9E, $FDF8, $0000, $FDE3, $FDF8, $0000, $0000, $0000, $FF00, $0020
    .word $FDE3, $FDF8, $0000, $FC9E, $FDF8, $0000, $FCD5, $FEB0, $0000, $0000, $0000, $FF00, $0030
    .word $FDE3, $FDF8, $0000, $FCD5, $FEB0, $0000, $FEBB, $FEB0, $0000, $0000, $0000, $FF00, $0030
    .word $FEBB, $FEB0, $0000, $FCD5, $FEB0, $0000, $FD0B, $FF68, $0000, $0000, $0000, $FF00, $0040
    .word $FEBB, $FEB0, $0000, $FD0B, $FF68, $0000, $FF94, $FF68, $0000, $0000, $0000, $FF00, $0040
    .word $FF94, $FF68, $0000, $FD0B, $FF68, $0000, $FEEB, $FFEB, $0000, $0000, $0000, $FF00, $0050
    .word $FF94, $FF68, $0000, $FEEB, $FFEB, $0000, $FF94, $FFEB, $0000, $0000, $0000, $FF00, $0050
    .word $FF94, $FFEB, $0000, $FEEB, $FFEB, $0000, $FEEB, $009D, $0000, $0000, $0000, $FF00, $0060
    .word $FF94, $FFEB, $0000, $FEEB, $009D, $0000, $FF94, $009D, $0000, $0000, $0000, $FF00, $0060
    .word $FF94, $009D, $0000, $FEEB, $009D, $0000, $FD5D, $0120, $0000, $0000, $0000, $FF00, $0070
    .word $FF94, $009D, $0000, $FD5D, $0120, $0000, $FF94, $0120, $0000, $0000, $0000, $FF00, $0070
    .word $FF94, $0120, $0000, $FD5D, $0120, $0000, $FD33, $01E8, $0000, $0000, $0000, $FF00, $0080
    .word $FF94, $0120, $0000, $FD33, $01E8, $0000, $FEAD, $01E8, $0000, $0000, $0000, $FF00, $0080
    .word $FEAD, $01E8, $0000, $FD33, $01E8, $0000, $FD0A, $02B0, $0000, $0000, $0000, $FF00, $0090
    .word $FEAD, $01E8, $0000, $FD0A, $02B0, $0000, $FDC6, $02B0, $0000, $0000, $0000, $FF00, $0090
    .word $FDC6, $02B0, $0000, $FD0A, $02B0, $0000, $FCE0, $0377, $0000, $0000, $0000, $FF00, $00A0
    .word $FD0A, $FD40, $0000, $FC68, $FD40, $0000, $FC32, $FC89, $0000, $0000, $0000, $0100, $0010
    .word $FC9E, $FDF8, $0000, $FC68, $FD40, $0000, $FD0A, $FD40, $0000, $0000, $0000, $0100, $0020
    .word $FDE3, $FDF8, $0000, $FC9E, $FDF8, $0000, $FD0A, $FD40, $0000, $0000, $0000, $0100, $0020
    .word $FCD5, $FEB0, $0000, $FC9E, $FDF8, $0000, $FDE3, $FDF8, $0000, $0000, $0000, $0100, $0030
    .word $FEBB, $FEB0, $0000, $FCD5, $FEB0, $0000, $FDE3, $FDF8, $0000, $0000, $0000, $0100, $0030
    .word $FD0B, $FF68, $0000, $FCD5, $FEB0, $0000, $FEBB, $FEB0, $0000, $0000, $0000, $0100, $0040
    .word $FF94, $FF68, $0000, $FD0B, $FF68, $0000, $FEBB, $FEB0, $0000, $0000, $0000, $0100, $0040
    .word $FEEB, $FFEB, $0000, $FD0B, $FF68, $0000, $FF94, $FF68, $0000, $0000, $0000, $0100, $0050
    .word $FF94, $FFEB, $0000, $FEEB, $FFEB, $0000, $FF94, $FF68, $0000, $0000, $0000, $0100, $0050
    .word $FEEB, $009D, $0000, $FEEB, $FFEB, $0000, $FF94, $FFEB, $0000, $0000, $0000, $0100, $0060
    .word $FF94, $009D, $0000, $FEEB, $009D, $0000, $FF94, $FFEB, $0000, $0000, $0000, $0100, $0060
    .word $FD5D, $0120, $0000, $FEEB, $009D, $0000, $FF94, $009D, $0000, $0000, $0000, $0100, $0070
    .word $FF94, $0120, $0000, $FD5D, $0120, $0000, $FF94, $009D, $0000, $0000, $0000, $0100, $0070
    .word $FD33, $01E8, $0000, $FD5D, $0120, $0000, $FF94, $0120, $0000, $0000, $0000, $0100, $0080
    .word $FEAD, $01E8, $0000, $FD33, $01E8, $0000, $FF94, $0120, $0000, $0000, $0000, $0100, $0080
    .word $FD0A, $02B0, $0000, $FD33, $01E8, $0000, $FEAD, $01E8, $0000, $0000, $0000, $0100, $0090
    .word $FDC6, $02B0, $0000, $FD0A, $02B0, $0000, $FEAD, $01E8, $0000, $0000, $0000, $0100, $0090
    .word $FCE0, $0377, $0000, $FD0A, $02B0, $0000, $FDC6, $02B0, $0000, $0000, $0000, $0100, $00A0
    .word $03CE, $FC89, $0000, $0398, $FD40, $0000, $02F6, $FD40, $0000, $0000, $0000, $0100, $0010
    .word $02F6, $FD40, $0000, $0398, $FD40, $0000, $0362, $FDF8, $0000, $0000, $0000, $0100, $0020
    .word $02F6, $FD40, $0000, $0362, $FDF8, $0000, $021D, $FDF8, $0000, $0000, $0000, $0100, $0020
    .word $021D, $FDF8, $0000, $0362, $FDF8, $0000, $032B, $FEB0, $0000, $0000, $0000, $0100, $0030
    .word $021D, $FDF8, $0000, $032B, $FEB0, $0000, $0145, $FEB0, $0000, $0000, $0000, $0100, $0030
    .word $0145, $FEB0, $0000, $032B, $FEB0, $0000, $02F5, $FF68, $0000, $0000, $0000, $0100, $0040
    .word $0145, $FEB0, $0000, $02F5, $FF68, $0000, $006C, $FF68, $0000, $0000, $0000, $0100, $0040
    .word $006C, $FF68, $0000, $02F5, $FF68, $0000, $0115, $FFEB, $0000, $0000, $0000, $0100, $0050
    .word $006C, $FF68, $0000, $0115, $FFEB, $0000, $006C, $FFEB, $0000, $0000, $0000, $0100, $0050
    .word $006C, $FFEB, $0000, $0115, $FFEB, $0000, $0115, $009D, $0000, $0000, $0000, $0100, $0060
    .word $006C, $FFEB, $0000, $0115, $009D, $0000, $006C, $009D, $0000, $0000, $0000, $0100, $0060
    .word $006C, $009D, $0000, $0115, $009D, $0000, $02A3, $0120, $0000, $0000, $0000, $0100, $0070
    .word $006C, $009D, $0000, $02A3, $0120, $0000, $006C, $0120, $0000, $0000, $0000, $0100, $0070
    .word $006C, $0120, $0000, $02A3, $0120, $0000, $02CD, $01E8, $0000, $0000, $0000, $0100, $0080
    .word $006C, $0120, $0000, $02CD, $01E8, $0000, $0153, $01E8, $0000, $0000, $0000, $0100, $0080
    .word $0153, $01E8, $0000, $02CD, $01E8, $0000, $02F6, $02B0, $0000, $0000, $0000, $0100, $0090
    .word $0153, $01E8, $0000, $02F6, $02B0, $0000, $023A, $02B0, $0000, $0000, $0000, $0100, $0090
    .word $023A, $02B0, $0000, $02F6, $02B0, $0000, $0320, $0377, $0000, $0000, $0000, $0100, $00A0
    .word $02F6, $FD40, $0000, $0398, $FD40, $0000, $03CE, $FC89, $0000, $0000, $0000, $FF00, $0010
    .word $0362, $FDF8, $0000, $0398, $FD40, $0000, $02F6, $FD40, $0000, $0000, $0000, $FF00, $0020
    .word $021D, $FDF8, $0000, $0362, $FDF8, $0000, $02F6, $FD40, $0000, $0000, $0000, $FF00, $0020
    .word $032B, $FEB0, $0000, $0362, $FDF8, $0000, $021D, $FDF8, $0000, $0000, $0000, $FF00, $0030
    .word $0145, $FEB0, $0000, $032B, $FEB0, $0000, $021D, $FDF8, $0000, $0000, $0000, $FF00, $0030
    .word $02F5, $FF68, $0000, $032B, $FEB0, $0000, $0145, $FEB0, $0000, $0000, $0000, $FF00, $0040
    .word $006C, $FF68, $0000, $02F5, $FF68, $0000, $0145, $FEB0, $0000, $0000, $0000, $FF00, $0040
    .word $0115, $FFEB, $0000, $02F5, $FF68, $0000, $006C, $FF68, $0000, $0000, $0000, $FF00, $0050
    .word $006C, $FFEB, $0000, $0115, $FFEB, $0000, $006C, $FF68, $0000, $0000, $0000, $FF00, $0050
    .word $0115, $009D, $0000, $0115, $FFEB, $0000, $006C, $FFEB, $0000, $0000, $0000, $FF00, $0060
    .word $006C, $009D, $0000, $0115, $009D, $0000, $006C, $FFEB, $0000, $0000, $0000, $FF00, $0060
    .word $02A3, $0120, $0000, $0115, $009D, $0000, $006C, $009D, $0000, $0000, $0000, $FF00, $0070
    .word $006C, $0120, $0000, $02A3, $0120, $0000, $006C, $009D, $0000, $0000, $0000, $FF00, $0070
    .word $02CD, $01E8, $0000, $02A3, $0120, $0000, $006C, $0120, $0000, $0000, $0000, $FF00, $0080
    .word $0153, $01E8, $0000, $02CD, $01E8, $0000, $006C, $0120, $0000, $0000, $0000, $FF00, $0080
    .word $02F6, $02B0, $0000, $02CD, $01E8, $0000, $0153, $01E8, $0000, $0000, $0000, $FF00, $0090
    .word $023A, $02B0, $0000, $02F6, $02B0, $0000, $0153, $01E8, $0000, $0000, $0000, $FF00, $0090
    .word $0320, $0377, $0000, $02F6, $02B0, $0000, $023A, $02B0, $0000, $0000, $0000, $FF00, $00A0
    
palette_data:
    .byte $00, $00  ; palette index 16
    .byte $00, $00  ; palette index 17
    .byte $11, $01  ; palette index 18
    .byte $12, $02  ; palette index 19
    .byte $23, $03  ; palette index 20
    .byte $34, $04  ; palette index 21
    .byte $34, $04  ; palette index 22
    .byte $45, $05  ; palette index 23
    .byte $46, $06  ; palette index 24
    .byte $57, $07  ; palette index 25
    .byte $68, $08  ; palette index 26
    .byte $68, $08  ; palette index 27
    .byte $79, $09  ; palette index 28
    .byte $7a, $0a  ; palette index 29
    .byte $8b, $0b  ; palette index 30
    .byte $9c, $0c  ; palette index 31
    .byte $00, $00  ; palette index 32
    .byte $00, $00  ; palette index 33
    .byte $11, $00  ; palette index 34
    .byte $12, $01  ; palette index 35
    .byte $23, $01  ; palette index 36
    .byte $24, $02  ; palette index 37
    .byte $34, $02  ; palette index 38
    .byte $35, $03  ; palette index 39
    .byte $46, $03  ; palette index 40
    .byte $47, $04  ; palette index 41
    .byte $58, $04  ; palette index 42
    .byte $58, $05  ; palette index 43
    .byte $69, $05  ; palette index 44
    .byte $6a, $06  ; palette index 45
    .byte $7b, $06  ; palette index 46
    .byte $8c, $07  ; palette index 47
    .byte $00, $00  ; palette index 48
    .byte $00, $00  ; palette index 49
    .byte $11, $00  ; palette index 50
    .byte $12, $00  ; palette index 51
    .byte $23, $01  ; palette index 52
    .byte $34, $01  ; palette index 53
    .byte $34, $01  ; palette index 54
    .byte $45, $01  ; palette index 55
    .byte $46, $02  ; palette index 56
    .byte $57, $02  ; palette index 57
    .byte $68, $02  ; palette index 58
    .byte $68, $02  ; palette index 59
    .byte $79, $03  ; palette index 60
    .byte $7a, $03  ; palette index 61
    .byte $8b, $03  ; palette index 62
    .byte $9c, $04  ; palette index 63
    .byte $00, $00  ; palette index 64
    .byte $01, $00  ; palette index 65
    .byte $12, $01  ; palette index 66
    .byte $23, $01  ; palette index 67
    .byte $34, $02  ; palette index 68
    .byte $45, $02  ; palette index 69
    .byte $46, $03  ; palette index 70
    .byte $57, $03  ; palette index 71
    .byte $68, $04  ; palette index 72
    .byte $79, $04  ; palette index 73
    .byte $8a, $05  ; palette index 74
    .byte $8b, $05  ; palette index 75
    .byte $9c, $06  ; palette index 76
    .byte $ad, $06  ; palette index 77
    .byte $be, $07  ; palette index 78
    .byte $cf, $08  ; palette index 79
    .byte $00, $00  ; palette index 80
    .byte $00, $00  ; palette index 81
    .byte $11, $00  ; palette index 82
    .byte $22, $01  ; palette index 83
    .byte $32, $01  ; palette index 84
    .byte $43, $01  ; palette index 85
    .byte $44, $02  ; palette index 86
    .byte $55, $02  ; palette index 87
    .byte $65, $02  ; palette index 88
    .byte $76, $03  ; palette index 89
    .byte $87, $03  ; palette index 90
    .byte $88, $03  ; palette index 91
    .byte $98, $04  ; palette index 92
    .byte $a9, $04  ; palette index 93
    .byte $ba, $04  ; palette index 94
    .byte $cb, $05  ; palette index 95
    .byte $00, $00  ; palette index 96
    .byte $00, $00  ; palette index 97
    .byte $11, $00  ; palette index 98
    .byte $21, $00  ; palette index 99
    .byte $32, $00  ; palette index 100
    .byte $42, $01  ; palette index 101
    .byte $43, $01  ; palette index 102
    .byte $53, $01  ; palette index 103
    .byte $64, $01  ; palette index 104
    .byte $74, $01  ; palette index 105
    .byte $85, $02  ; palette index 106
    .byte $85, $02  ; palette index 107
    .byte $96, $02  ; palette index 108
    .byte $a6, $02  ; palette index 109
    .byte $b7, $02  ; palette index 110
    .byte $c8, $03  ; palette index 111
    .byte $00, $00  ; palette index 112
    .byte $00, $00  ; palette index 113
    .byte $10, $01  ; palette index 114
    .byte $21, $02  ; palette index 115
    .byte $31, $02  ; palette index 116
    .byte $41, $03  ; palette index 117
    .byte $42, $04  ; palette index 118
    .byte $52, $04  ; palette index 119
    .byte $62, $05  ; palette index 120
    .byte $73, $06  ; palette index 121
    .byte $83, $06  ; palette index 122
    .byte $83, $07  ; palette index 123
    .byte $94, $08  ; palette index 124
    .byte $a4, $08  ; palette index 125
    .byte $b4, $09  ; palette index 126
    .byte $c5, $0a  ; palette index 127
end_of_palette_data:


palette_data_128:
    .byte $00, $00  ; palette index 128
    .byte $00, $00  ; palette index 129
    .byte $10, $01  ; palette index 130
    .byte $21, $02  ; palette index 131
    .byte $31, $03  ; palette index 132
    .byte $41, $04  ; palette index 133
    .byte $42, $05  ; palette index 134
    .byte $52, $06  ; palette index 135
    .byte $62, $07  ; palette index 136
    .byte $73, $08  ; palette index 137
    .byte $83, $09  ; palette index 138
    .byte $83, $0a  ; palette index 139
    .byte $94, $0b  ; palette index 140
    .byte $a4, $0c  ; palette index 141
    .byte $b4, $0d  ; palette index 142
    .byte $c5, $0e  ; palette index 143
    .byte $00, $00  ; palette index 144
    .byte $00, $01  ; palette index 145
    .byte $10, $02  ; palette index 146
    .byte $11, $03  ; palette index 147
    .byte $21, $04  ; palette index 148
    .byte $31, $05  ; palette index 149
    .byte $32, $06  ; palette index 150
    .byte $42, $07  ; palette index 151
    .byte $42, $08  ; palette index 152
    .byte $53, $09  ; palette index 153
    .byte $63, $0a  ; palette index 154
    .byte $63, $0b  ; palette index 155
    .byte $74, $0c  ; palette index 156
    .byte $74, $0d  ; palette index 157
    .byte $84, $0e  ; palette index 158
    .byte $95, $0f  ; palette index 159
    .byte $00, $00  ; palette index 160
    .byte $00, $01  ; palette index 161
    .byte $00, $02  ; palette index 162
    .byte $10, $03  ; palette index 163
    .byte $11, $04  ; palette index 164
    .byte $11, $05  ; palette index 165
    .byte $21, $06  ; palette index 166
    .byte $21, $07  ; palette index 167
    .byte $22, $08  ; palette index 168
    .byte $32, $09  ; palette index 169
    .byte $32, $0a  ; palette index 170
    .byte $32, $0b  ; palette index 171
    .byte $43, $0c  ; palette index 172
    .byte $43, $0d  ; palette index 173
    .byte $43, $0e  ; palette index 174
    .byte $54, $0f  ; palette index 175
end_of_palette_data_128:
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
    
    
; FIXME! Put this somewhere else!
    
NR_OF_5X5_CHARACTERS = 40   ; whitespace, A-Z, 0-9, period (37), semicolon (38), quote (39)
font_5x5_data:
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $00, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $00, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $00, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $01, $01, $01, $01, $01
    .byte $00, $01, $01, $01, $01, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $01, $00, $01, $00, $00, $01, $01, $01, $00
    .byte $01, $00, $00, $01, $00, $01, $00, $01, $00, $00, $01, $01, $00, $00, $00, $01, $00, $01, $00, $00, $01, $00, $00, $01, $00
    .byte $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $01, $01, $01, $00
    .byte $01, $00, $00, $00, $01, $01, $01, $00, $01, $01, $01, $00, $01, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01
    .byte $01, $00, $00, $00, $01, $01, $01, $00, $00, $01, $01, $00, $01, $00, $01, $01, $00, $00, $01, $01, $01, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $00, $00, $01, $00, $01, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00
    .byte $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $00, $01, $00, $01, $00, $00, $01, $00, $01, $00, $00, $00, $01, $00, $00
    .byte $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $01, $00, $01, $01, $01, $00, $01, $01, $01, $00, $00, $00, $01
    .byte $01, $00, $00, $00, $01, $00, $01, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $01, $00, $01, $00, $00, $00, $01
    .byte $01, $00, $00, $00, $01, $00, $01, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00
    .byte $01, $01, $01, $01, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $00, $01, $01, $01, $00, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $01, $00, $00, $00, $01, $00, $01, $01, $01, $00
    .byte $00, $01, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00, $00
    .byte $00, $01, $01, $00, $00, $01, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $00, $01, $01, $01, $00, $00, $00, $00, $01, $00, $01, $01, $01, $01, $00
    .byte $01, $00, $00, $01, $00, $01, $00, $00, $01, $00, $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $00
    .byte $00, $01, $01, $01, $00, $01, $00, $00, $00, $00, $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $00, $01, $00, $00, $00, $00, $01, $01, $01, $01, $00, $01, $00, $00, $01, $00, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00
    .byte $01, $01, $01, $01, $00, $01, $00, $00, $01, $00, $00, $01, $01, $00, $00, $01, $00, $00, $01, $00, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $00, $01, $00, $00, $01, $00, $01, $01, $01, $01, $00, $00, $00, $00, $01, $00, $01, $01, $01, $01, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00
    .byte $00, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    
    
    
UP_KEY_WIDTH_PIXELS = 13
UP_KEY_HEIGHT_PIXELS = 13
up_key_data:
    .byte $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $00, $00, $00, $00, $00, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00
    
LEFT_DOWN_RIGHT_KEY_WIDTH_PIXELS = 41
LEFT_DOWN_RIGHT_KEY_HEIGHT_PIXELS = 13
left_down_right_keys_data:
    .byte $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $00, $00, $00, $00, $00, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00
    
    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/i2c.s
    .include utils/keyboard.s
    .include utils/timing.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s
    .include fx_tests/utils/fx_polygon_fill.s
    .include fx_tests/utils/fx_polygon_fill_jump_tables.s
    .if(!DO_4BIT)
        .include fx_tests/utils/fx_polygon_fill_jump_tables_8bit.s
    .else
        .if(!DO_2BIT)
            .include fx_tests/utils/fx_polygon_fill_jump_tables_4bit.s
        .else
            .include fx_tests/utils/fx_polygon_fill_jump_tables_2bit.s
        .endif
    .endif
    

    .ifndef CREATE_PRG
        ; ======== NMI / IRQ =======
nmi:
        ; TODO: implement this
        ; FIXME: ugly hack!
        jmp reset
        rti
   
irq:
        rti
    .endif
        
    
    ; === Cosine and sine tables ===

    .ifndef CREATE_PRG
        .org $EF00
    .else
; FIXME!
; FIXME!
; FIXME!  
;        .org $EF00
    .endif
    
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
    
    .ifndef CREATE_PRG
        ; ======== PETSCII CHARSET =======

        .org $F700
        .include "utils/petscii.s"
        

        .org $fffa
        .word nmi
        .word reset
        .word irq
    .endif

    ; NOTE: we are now using ROM banks to contain tables. We need to copy those tables to Banked RAM, but have to run that copy-code in Fixed RAM.
    
    .ifndef CREATE_PRG
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
    .endif
