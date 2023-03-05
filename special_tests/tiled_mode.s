
USE_CACHE_FOR_WRITING = 1
USE_TABLE_FILES = 1
DRAW_TILED_PERSPECTIVE = 1  ; Otherwise FLAT tiles
MOVE_XY_POSITION = 1


BACKGROUND_COLOR = 255  ; 255 = Purple in this palette
COLOR_TEXT  = $06       ; Background color = 0 (transparent), foreground color 6 (grey in this palette)

; FIXME: we use this for copying the minecraft textures (8x128 pixels). But we also use it to create copy-code. So this is actually wrong.
TEXTURE_WIDTH = 64
TEXTURE_HEIGHT = 64

MAP_WIDTH = 32
MAP_HEIGHT = 32
;MAP_WIDTH = 4
;MAP_HEIGHT = 4

TOP_MARGIN = 12
LEFT_MARGIN = 16
VSPACING = 10

MAPDATA_VRAM_ADDRESS = $17000
TILEDATA_VRAM_ADDRESS = $18000

DESTINATION_PICTURE_POS_X = 64
DESTINATION_PICTURE_POS_Y = 65


; Mode7 projection: 
;    https://www.coranac.com/tonc/text/mode7.htm
;    https://gamedev.stackexchange.com/questions/24957/doing-an-snes-mode-7-affine-transform-effect-in-pygame

; Minecraft textures:
;    https://minecraft.fandom.com/wiki/List_of_block_textures
; Merge texture images into 1 image: https://www.filesmerge.com/merge-images
; Convert images to 256 colors: https://redketchup.io/image-converter/help


; === Zero page addresses ===

; Bank switching
RAM_BANK                  = $00
ROM_BANK                  = $01

; Temp vars
TMP1                      = $02
TMP2                      = $03
TMP3                      = $04
TMP4                      = $05

; Printing
TEXT_TO_PRINT             = $06 ; 07
TEXT_COLOR                = $08
CURSOR_X                  = $09
CURSOR_Y                  = $0A
INDENTATION               = $0B
BYTE_TO_PRINT             = $0C
DECIMAL_STRING            = $0D ; 0E ; 0F

; Timing
TIMING_COUNTER            = $14 ; 15
TIME_ELAPSED_MS           = $16
TIME_ELAPSED_SUB_MS       = $17 ; one nibble of sub-milliseconds

DATA_PTR_ZP               = $26 ; 27
PALLETE_PTR_ZP            = $28 ; 29
VERA_ADDR_ZP_FROM         = $2A ; 2B ; 2C
VERA_ADDR_ZP_TO           = $2D ; 2E


; FIXME: these are leftovers of memory tests in the general hardware tester (needed by utils.s atm). We dont use them, but cant remove them right now
BANK_TESTING              = $32   
BAD_VALUE                 = $3A

CODE_ADDRESS              = $3D ; 3E

LOAD_ADDRESS              = $40 ; 41
STORE_ADDRESS             = $42 ; 43

TABLE_ROM_BANK            = $44
VIEWING_ANGLE             = $45

WORLD_X_POSITION          = $50 ; 51
WORLD_Y_POSITION          = $52 ; 53

; RAM addresses
COPY_ROW_CODE               = $7800
COPY_TABLES_TO_BANKED_RAM   = $8000


Y_IN_TEXTURE_FRACTION_CORRECTIONS_LOW  = $A000
Y_IN_TEXTURE_FRACTION_CORRECTIONS_HIGH = $A100
X_IN_TEXTURE_FRACTION_CORRECTIONS_LOW  = $A200
X_IN_TEXTURE_FRACTION_CORRECTIONS_HIGH = $A300
X_PIXEL_POSITIONS_IN_MAP_LOW           = $A400
X_PIXEL_POSITIONS_IN_MAP_HIGH          = $A500
Y_PIXEL_POSITIONS_IN_MAP_LOW           = $A600
Y_PIXEL_POSITIONS_IN_MAP_HIGH          = $A700
X_SUB_PIXEL_STEPS_DECR                 = $A800
X_SUB_PIXEL_STEPS_LOW                  = $A900
X_SUB_PIXEL_STEPS_HIGH                 = $AA00
Y_SUB_PIXEL_STEPS_DECR                 = $AB00
Y_SUB_PIXEL_STEPS_LOW                  = $AC00
Y_SUB_PIXEL_STEPS_HIGH                 = $AD00


; ROM addresses
PALLETE           = $CE00
PIXELS            = $D000
TILEMAP           = $E000


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

;    jsr clear_screen_slow
;    lda #$10                 ; 8:1 scale, so we can clearly see the pixels
;    sta VERA_DC_HSCALE
;    sta VERA_DC_VSCALE
;    jsr affine_transform_some_bytes
    
    ; Put orginal picture on screen (slow)
    jsr clear_screen_slow
    jsr copy_palette
    jsr copy_pixels_to_high_vram
    jsr copy_tilemap_to_high_vram
    
    .if(DRAW_TILED_PERSPECTIVE)
        ; Test speed of perspective style transformation
        jsr test_speed_of_tiled_perspective
    .else    
        ; Test speed of flat tiles draws
        jsr test_speed_of_flat_tiles
    .endif
  
loop:
  jmp loop

  

one_byte_per_write_message: 
    .asciiz "Method: 1 byte per write"
four_bytes_per_write_message: 
    .asciiz "Method: 4 bytes per write"

    
    
; ====================================== TILED PERSPECTIVE SPEED TEST ========================================
  
test_speed_of_tiled_perspective:

    jsr generate_copy_row_code
    
    .if(USE_TABLE_FILES)
        jsr copy_table_copier_to_ram
        jsr COPY_TABLES_TO_BANKED_RAM
        
        lda #0
        sta WORLD_X_POSITION
        sta WORLD_X_POSITION+1
        sta WORLD_Y_POSITION
        sta WORLD_Y_POSITION+1
        
        lda #220
        sta VIEWING_ANGLE
turn_around:
        lda VIEWING_ANGLE
        sta RAM_BANK

        jsr tiled_perspective_fast

;        inc VIEWING_ANGLE
        
        .if(MOVE_XY_POSITION)
            dec WORLD_X_POSITION
            bne  done_moving_x_position
            dec WORLD_X_POSITION+1
done_moving_x_position:
            dec WORLD_Y_POSITION
            bne  done_moving_y_position
            dec WORLD_Y_POSITION+1
done_moving_y_position:
        .endif
        
; FIXME: added this condition:
;        lda VIEWING_ANGLE
;        cmp #100
;        bne turn_around
        
        bra turn_around
    .else
        jsr start_timer
        jsr tiled_perspective_fast
        jsr stop_timer

        lda #COLOR_TEXT
        sta TEXT_COLOR
        
        lda #5
        sta CURSOR_X
        lda #4
        sta CURSOR_Y

        lda #<tiled_perspective_192x64_8bpp_message
        sta TEXT_TO_PRINT
        lda #>tiled_perspective_192x64_8bpp_message
        sta TEXT_TO_PRINT + 1
        
        jsr print_text_zero
        
        lda #8
        sta CURSOR_X
        lda #21
        sta CURSOR_Y

        .if(USE_CACHE_FOR_WRITING)
            lda #<four_bytes_per_write_message
            sta TEXT_TO_PRINT
            lda #>four_bytes_per_write_message
            sta TEXT_TO_PRINT + 1
        .else
            lda #<one_byte_per_write_message
            sta TEXT_TO_PRINT
            lda #>one_byte_per_write_message
            sta TEXT_TO_PRINT + 1
        .endif
        
        jsr print_text_zero
        
        lda #COLOR_TEXT
        sta TEXT_COLOR
        
        lda #8
        sta CURSOR_X
        lda #26
        sta CURSOR_Y
        
        jsr print_time_elapsed
    
    .endif

    rts
    


tiled_perspective_192x64_8bpp_message: 
    .asciiz "Tiled perspective 192x64 (8bpp) "

    
; For tiled perspective we need to set the x and y coordinate within the tilemap for each pixel row on the screen. 
; We also have to set the sub pixel increment for each pixel row on the screen.
; We generated this using the python script (see same folder) and put the data here.
    
x_in_texture_fraction_corrections_low:
    .byte 126,99,119,203,112,116,227,201,49,35,169,200,138,243,9,210,83,144,141,78,215,41,74,58,254,151,7,80,117,120,89,26,190,69,176,2,58,91,100,88,55,2,185,94,241,114,228,69,152,219,17,57,84,98,99,89,68,36,249,195,132,59,232,141
x_in_texture_fraction_corrections_high:
    .byte 0,0,1,1,1,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,1,0,0,1,0,0,0,0,0,0,1,1,0,0,1,0,1,0,1,0,0,1,1,0,0,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1,0,0
y_in_texture_fraction_corrections_low:
    .byte 250,41,221,10,166,168,9,193,201,27,179,139,159,236,108,29,253,7,59,148,17,176,111,77,71,92,139,210,49,166,47,205,126,65,21,250,239,243,6,38,84,142,213,39,133,238,97,222,101,245,142,48,218,140,70,8,208,160,118,83,55,32,15,4
y_in_texture_fraction_corrections_high:
    .byte 1,1,0,1,1,0,0,1,1,0,0,1,0,1,1,1,0,1,1,1,0,0,1,0,1,0,1,0,0,1,1,0,0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,1,1,0,1,1,0,1,0,0,1,0,1,0,1,0,1
x_pixel_positions_in_map_low:
    .byte 162,169,176,182,188,193,198,203,208,213,217,221,225,228,232,235,239,242,245,248,250,253,0,2,4,7,9,11,13,15,17,19,21,23,24,26,28,29,31,32,34,35,36,38,39,40,41,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,57,58
x_pixel_positions_in_map_high:
    .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
y_pixel_positions_in_map_low:
    .byte 246,250,255,2,6,10,13,16,19,22,25,27,30,32,34,36,39,40,42,44,46,48,49,51,52,54,55,57,58,59,60,62,63,64,65,66,67,68,69,70,71,72,73,73,74,75,76,77,77,78,79,79,80,81,81,82,83,83,84,84,85,85,86,86
y_pixel_positions_in_map_high:
    .byte 7,7,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
x_sub_pixel_steps_decr:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
x_sub_pixel_steps_low:
    .byte 231,201,172,145,120,96,73,51,31,11,249,231,214,198,183,168,154,140,127,115,102,91,80,69,59,49,39,30,20,12,3,251,243,235,228,221,214,207,200,194,188,182,176,170,164,159,153,148,143,138,133,129,124,120,115,111,107,103,99,95,91,87,84,80
x_sub_pixel_steps_high:
    .byte 3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
y_sub_pixel_steps_decr:
    .byte 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
y_sub_pixel_steps_low:
    .byte 223,216,210,204,198,193,188,183,178,174,170,166,162,158,155,152,148,145,142,140,137,134,132,129,127,125,123,121,119,117,115,113,111,109,108,106,105,103,102,100,99,97,96,95,94,92,91,90,89,88,87,86,85,84,83,82,81,80,79,78,77,76,76,75
y_sub_pixel_steps_high:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    
tiled_perspective_fast:

    ; Setup FROM and TO VRAM addresses
    lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO
    lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO+1
    lda #<(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM
    lda #>(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM+1

    lda #(TILEDATA_VRAM_ADDRESS >> 9)
    sta VERA_L0_MAPBASE
    lda #(MAPDATA_VRAM_ADDRESS >> 9)
    sta VERA_L0_HSCROLL_L
    
    ; VERA_L0_CONFIG = 100 + 011 ; enable bitmap mode and color depth = 8bpp on layer 0
    ;                + 01010000 for 32x32 map
    lda #%01010111
    ;                + 00100000 for 4x4 map
;        lda #%00100111
    sta VERA_L0_CONFIG
    
    ; Making sure the increment for ADDR0 is set correctly (which is used in affine mode by ADDR1)
    lda #%00000000           ; DCSEL=0, ADDRSEL=0, no affine helper
    sta VERA_CTRL
; FIXME: this is the *old* method of copying the incrementer!
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    
    ; Setting up for reading from a new line from a texture/bitmap
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    sta VERA_ADDR_BANK
    
    ; Entering *affine helper mode*: from now on ADDR1 will use two incrementers: the *current* one from ADDR0 (its settings are copied) and from itself
    lda #%00000101           ; Affine helper = 1, DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #0                   ; X increment low
    sta $9F29
    lda #%00100101           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 001, X increment high = 01
    sta $9F2A
    lda #00
    sta $9F2B                ; Y increment low
; FIXME: Clip is now 01!!
    lda #%00100100           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 001, Y increment high = 00 
    sta $9F2C                ; Y increment high

    ldx #0
    
tiled_perspective_copy_next_row_1:
    
    lda #%00000100           ; DCSEL=0, ADDRSEL=0, with affine helper
    sta VERA_CTRL

    .if (USE_CACHE_FOR_WRITING)
        lda #%00110110           ; Setting auto-increment value to 4 byte increment (=%0011) and wrpattern = 11b
        sta VERA_ADDR_BANK
    .else
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW
    
    ; We reset so both x and y sub pixels positions are reset to 128 
    lda #%00000101           ; DCSEL=0, ADDRSEL=1, with affine helper
    sta VERA_CTRL
    
    ; FIXME: Since loading *once* screws up my cache byte index, we need to load 3 times first!
    .if(USE_CACHE_FOR_WRITING)
    stz $9F29                ; X increment low
    stz $9F2A                ; X increment high (only 1 bit is used)
    stz $9F2B                ; Y increment low
    stz $9F2C                ; Y increment high (only 1 bit is used)
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    .endif
    
    
    ; We correct both x and y sub pixels positions to the correct starting value by setting the deltas 
    .if(USE_TABLE_FILES)
        lda X_IN_TEXTURE_FRACTION_CORRECTIONS_LOW, x
    .else
        lda x_in_texture_fraction_corrections_low, x
    .endif
    sta $9F29

    .if(USE_TABLE_FILES)
        lda X_IN_TEXTURE_FRACTION_CORRECTIONS_HIGH, x
    .else
        lda x_in_texture_fraction_corrections_high, x
    .endif
    .if(USE_TABLE_FILES)
        lda X_SUB_PIXEL_STEPS_DECR, x
    .else
        ora x_sub_pixel_steps_decr, x   ; TODO: we could encode the decr value into the high value itself!
    .endif
    ora #%00100000           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 000, X increment high = 00 (these two bits are already in a by the lda)
    sta $9F2A
    
    .if(USE_TABLE_FILES)
        lda Y_IN_TEXTURE_FRACTION_CORRECTIONS_LOW, x
    .else
        lda y_in_texture_fraction_corrections_low, x
    .endif
    sta $9F2B

    .if(USE_TABLE_FILES)
        lda Y_IN_TEXTURE_FRACTION_CORRECTIONS_HIGH, x
    .else
        lda y_in_texture_fraction_corrections_high, x
    .endif
; FIXME: Clip is now 01!!
    ora #%00000000           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 000, Y increment high = 00 (these two bits are already in a by the lda)
;    ora #%00100000           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 000, Y increment high = 00 (these two bits are already in a by the lda)
    sta $9F2C

    ; FIXME: we shouldnt need this if we didnt have to correct the subpixel position. We also should be calculating the subpixel position in the table generator.
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    .if(USE_TABLE_FILES)
        ora Y_SUB_PIXEL_STEPS_DECR, x
    .else
        ora y_sub_pixel_steps_decr, x
    .endif
    sta VERA_ADDR_BANK
    
    ; We read once from ADDR1 which adds the corrections
    lda VERA_DATA1
    
    ; We now set the actual increments
    .if(USE_TABLE_FILES)
        lda X_SUB_PIXEL_STEPS_LOW, x
    .else
        lda x_sub_pixel_steps_low, x
    .endif
    sta $9F29                ; X increment low
    .if(USE_TABLE_FILES)
        lda X_SUB_PIXEL_STEPS_HIGH, x
    .else
        lda x_sub_pixel_steps_high, x
    .endif
    .if(USE_TABLE_FILES)
        ora X_SUB_PIXEL_STEPS_DECR, x
    .else
        ora x_sub_pixel_steps_decr, x   ; TODO: we could encode the decr value into the high value itself!
    .endif
    ora #%00100000           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 000, X increment high = 00 (these two bits are already in a by the lda)
    sta $9F2A
    .if(USE_TABLE_FILES)
        lda Y_SUB_PIXEL_STEPS_LOW, x
    .else
        lda y_sub_pixel_steps_low, x
    .endif
    sta $9F2B
    .if(USE_TABLE_FILES)
        lda Y_SUB_PIXEL_STEPS_HIGH, x
    .else
        lda y_sub_pixel_steps_high, x
    .endif
; FIXME: Clip is now 01!!
    ora #%00000000           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 000, Y increment high = 00 (these two bits are already in a by the lda)
;    ora #%00100000           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 000, Y increment high = 00 (these two bits are already in a by the lda)
    sta $9F2C
    
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    .if(USE_TABLE_FILES)
        ora Y_SUB_PIXEL_STEPS_DECR, x
    .else
        ora y_sub_pixel_steps_decr, x
    .endif
    sta VERA_ADDR_BANK
    
    
    ; Setting the position
    
    lda #%00000111           ; DCSEL=1, ADDRSEL=1, with affine helper
    sta VERA_CTRL

; FIXME: WORKAROUND! WE HAVE TO TURN ON TILE LOOKUP BEFORE SETTING THE POSITION!! BUT THEY ARE IN THE SAME REGISTER!!
    lda #%10000000                   ; Y pixel position high [10:8] = 0, tile lookup = 1
    sta $9F2C

    
    .if(USE_TABLE_FILES)
        lda X_PIXEL_POSITIONS_IN_MAP_LOW, x
        .if(MOVE_XY_POSITION)
            clc
            adc WORLD_X_POSITION
        .endif
    .else
        lda x_pixel_positions_in_map_low, x
    .endif
    sta $9F29                ; X pixel position low [7:0]
    .if(USE_TABLE_FILES)
        lda X_PIXEL_POSITIONS_IN_MAP_HIGH, x
        .if(MOVE_XY_POSITION)
            adc WORLD_X_POSITION+1
        .endif
    .else
        lda x_pixel_positions_in_map_high, x
    .endif
    sta $9F2A                ; X pixel position high [10:8]
    .if(USE_TABLE_FILES)
        lda Y_PIXEL_POSITIONS_IN_MAP_LOW, x
        .if(MOVE_XY_POSITION)
            clc
            adc WORLD_Y_POSITION
        .endif
    .else
        lda y_pixel_positions_in_map_low, x
    .endif
    sta $9F2B                ; Y pixel position low [7:0]
    .if(USE_TABLE_FILES)
        lda Y_PIXEL_POSITIONS_IN_MAP_HIGH, x
        .if(MOVE_XY_POSITION)
            adc WORLD_Y_POSITION+1
        .endif
    .else
        lda y_pixel_positions_in_map_high, x
    .endif
    ora #%10000000           
    sta $9F2C                ; Y pixel position high [10:8] = 0, tile lookup = 1
    

    ; Copy three rows of 64 pixels (= 192 pixels)
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with 320
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(320)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(320)
    sta VERA_ADDR_ZP_TO+1

    inx
    cpx #TEXTURE_HEIGHT          ; we do 64 rows
    beq done_tiled_perspective_copy
    
    jmp tiled_perspective_copy_next_row_1
done_tiled_perspective_copy:
    
    ; Exiting affine helper mode
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
; ====================================== FLAT TILES SPEED TEST ========================================
  
test_speed_of_flat_tiles:

    jsr generate_copy_row_code

    jsr start_timer

    jsr flat_tiles_fast
    
    jsr stop_timer

    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #4
    sta CURSOR_X
    lda #4
    sta CURSOR_Y

    lda #<flat_tiles_24x8_8bpp_message
    sta TEXT_TO_PRINT
    lda #>flat_tiles_24x8_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #8
    sta CURSOR_X
    lda #21
    sta CURSOR_Y

    .if(USE_CACHE_FOR_WRITING)
        lda #<four_bytes_per_write_message
        sta TEXT_TO_PRINT
        lda #>four_bytes_per_write_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #<one_byte_per_write_message
        sta TEXT_TO_PRINT
        lda #>one_byte_per_write_message
        sta TEXT_TO_PRINT + 1
    .endif
    
    jsr print_text_zero
    
    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #8
    sta CURSOR_X
    lda #26
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts
    


flat_tiles_24x8_8bpp_message: 
    .asciiz "24x8 flat tiles of 8x8 size (8bpp) "

    


flat_tiles_fast:

    ; Setup FROM and TO VRAM addresses
    lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO
    lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*320)
    sta VERA_ADDR_ZP_TO+1
    lda #<(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM
    lda #>(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_ZP_FROM+1

    lda #(TILEDATA_VRAM_ADDRESS >> 9)
    sta VERA_L0_MAPBASE
    lda #(MAPDATA_VRAM_ADDRESS >> 9)
    sta VERA_L0_HSCROLL_L
    
    ; VERA_L0_CONFIG = 100 + 011 ; enable bitmap mode and color depth = 8bpp on layer 0
    ;                + 01010000 for 32x32 map
;    lda #%01010111
    ;                + 00100000 for 4x4 map
    lda #%00100111
    sta VERA_L0_CONFIG
    
    ; Making sure the increment for ADDR0 is set correctly (which is used in affine mode by ADDR1)
    lda #%00000000           ; DCSEL=0, ADDRSEL=0, no affine helper
    sta VERA_CTRL
; FIXME: this is the *old* method of copying the incrementer!
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    
    ; Setting up for reading from a new line from a texture/bitmap
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%01110001           ; Setting auto-increment value to 64 byte increment (=%0111) and bit16 to 1
    sta VERA_ADDR_BANK
    
    ; Entering *affine helper mode*: from now on ADDR1 will use two incrementers: the *current* one from ADDR0 (its settings are copied) and from itself
    lda #%00000101           ; Affine helper = 1, DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #0                   ; X increment low
    sta $9F29
    lda #%00100101           ; DECR = 0, Address increment = 01, X subpixel increment exponent = 001, X increment high = 01
    sta $9F2A
    lda #00
    sta $9F2B                ; Y increment low
; FIXME: Clip is now 01!!
    lda #%00100100           ; L0/L1 = 0, Repeat (01) / Clip (10) / Combined (11) / None (00) = 01, Y subpixel increment exponent = 001, Y increment high = 00 
    sta $9F2C                ; Y increment high

    ldx #0
    
repetitive_copy_next_row_1:
    lda #%00000100           ; DCSEL=0, ADDRSEL=0, with affine helper
    sta VERA_CTRL

    .if (USE_CACHE_FOR_WRITING)
        lda #%00110110           ; Setting auto-increment value to 4 byte increment (=%0011) and wrpattern = 11b
        sta VERA_ADDR_BANK
    .else
        lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
        sta VERA_ADDR_BANK
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW

    ; Setting the position
    
    lda #%00000111           ; DCSEL=1, ADDRSEL=1, with affine helper
    sta VERA_CTRL

; FIXME: WORKAROUND! WE HAVE TO TURN ON TILE LOOKUP BEFORE SETTING THE POSITION!! BUT THEY ARE IN THE SAME REGISTER!!
    lda #%10000000                   ; Y pixel position high [10:8] = 0, tile lookup = 1
    sta $9F2C

    
    lda #0                   ; X pixel position low [7:0]
    sta $9F29
    lda #0                   ; X pixel position high [10:8]
    sta $9F2A
;        lda #0                   ; Y pixel position low [7:0]
;        sta $9F2B
; FIXME: We directly put register x in the x pixel position low atm
    txa
;    clc
;    adc #4
    sta $9F2B
;        lda #0                   ; Y pixel position high [10:8] = 0
    lda #%10000000                   ; Y pixel position high [10:8] = 0, tile lookup = 1
    sta $9F2C
    
    
    ; Copy three rows of 64 pixels
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with 320
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(320)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(320)
    sta VERA_ADDR_ZP_TO+1

    inx
    cpx #TEXTURE_HEIGHT          ; we do 64 rows
    bne repetitive_copy_next_row_1
    
    ; Exiting affine helper mode
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts



    
generate_copy_row_code:

    lda #<COPY_ROW_CODE
    sta CODE_ADDRESS
    lda #>COPY_ROW_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions

next_copy_instruction:

    ; -- lda VERA_DATA1 ($9F24)
    lda #$AD               ; lda ....
    jsr add_code_byte
    
    lda #$24               ; VERA_DATA1
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    .if (USE_CACHE_FOR_WRITING)
        ; When using the cache for writing we only write 1/4th of the time, so we read 3 extra bytes here (they go into the cache)
        
        ; -- lda VERA_DATA1 ($9F24)
        lda #$AD               ; lda ....
        jsr add_code_byte
        
        lda #$24               ; VERA_DATA1
        jsr add_code_byte
        
        lda #$9F         
        jsr add_code_byte

        ; -- lda VERA_DATA1 ($9F24)
        lda #$AD               ; lda ....
        jsr add_code_byte
        
        lda #$24               ; VERA_DATA1
        jsr add_code_byte
        
        lda #$9F         
        jsr add_code_byte

        ; -- lda VERA_DATA1 ($9F24)
        lda #$AD               ; lda ....
        jsr add_code_byte
        
        lda #$24               ; VERA_DATA1
        jsr add_code_byte
        
        lda #$9F         
        jsr add_code_byte

    .endif

    
    .if (USE_CACHE_FOR_WRITING)
        ; We use the cache for writing, we do not want a mask to we store 0 (stz)
    
        ; -- stz VERA_DATA0 ($9F23)
        lda #$9C               ; stz ....
        jsr add_code_byte

        lda #$23               ; $23
        jsr add_code_byte
        
        lda #$9F               ; $9F
        jsr add_code_byte

    .else
        ; -- sta VERA_DATA0 ($9F23)
        lda #$8D               ; sta ....
        jsr add_code_byte

        lda #$23               ; $23
        jsr add_code_byte
        
        lda #$9F               ; $9F
        jsr add_code_byte
    .endif
    
    inx
    .if (USE_CACHE_FOR_WRITING)
        cpx #TEXTURE_WIDTH/4             ; 16*4 copy pixels written to VERA (due to diagonal)
    .else
        cpx #TEXTURE_WIDTH               ; 64 copy pixels written to VERA (due to diagonal)
    .endif
    bne next_copy_instruction

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


; ================================== loading picture data from ROM =====================================


copy_palette:

    ; Starting at palette VRAM address

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<VERA_PALETTE
    sta VERA_ADDR_LOW
    lda #>VERA_PALETTE
    sta VERA_ADDR_HIGH

    ldy #0
next_packed_color:
    lda PALLETE, y
    sta VERA_DATA0
    iny
    bne next_packed_color

    ldy #0
next_packed_color2:
    lda PALLETE+256, y
    sta VERA_DATA0
    iny
    bne next_packed_color2

    rts

copy_pixels_to_high_vram:  

    lda #<PIXELS
    sta DATA_PTR_ZP
    lda #>PIXELS
    sta DATA_PTR_ZP+1 

    ; For now copying to TILEDATA_VRAM_ADDRESS
    ; TODO: we are ASSUMING here that TEXTURE_VRAM_ADDRESS has its bit16 set to 1!!
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #<(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_LOW
    lda #>(TILEDATA_VRAM_ADDRESS)
    sta VERA_ADDR_HIGH
    
    ldx #0
next_pixel_row_high_vram:  

    ldy #0
next_horizontal_pixel_high_vram:
    lda (DATA_PTR_ZP),y

    sta VERA_DATA0

    iny
    cpy #TEXTURE_WIDTH
    bne next_horizontal_pixel_high_vram
    inx
    
    ; Adding TEXTURE_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #TEXTURE_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    cpx #TEXTURE_HEIGHT
    bne next_pixel_row_high_vram
    
    rts
    
    
copy_tilemap_to_high_vram:

    lda #<TILEMAP
    sta DATA_PTR_ZP
    lda #>TILEMAP
    sta DATA_PTR_ZP+1 

    ; For now copying to MAPDATA_VRAM_ADDRESS
    ; TODO: we are ASSUMING here that MAPDATA_VRAM_ADDRESS has its bit16 set to 1!!
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #<(MAPDATA_VRAM_ADDRESS)
    sta VERA_ADDR_LOW
    lda #>(MAPDATA_VRAM_ADDRESS)
    sta VERA_ADDR_HIGH
    
    ldx #0
next_tile_row_high_vram:  

    ldy #0
next_horizontal_tile_high_vram:
    lda (DATA_PTR_ZP),y

    sta VERA_DATA0

    iny
    cpy #MAP_WIDTH
    bne next_horizontal_tile_high_vram
    inx
    
    ; Adding TILE_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #MAP_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    cpx #MAP_HEIGHT
    bne next_tile_row_high_vram
    
    rts
    
    
    
    
; NOTE: we are now using ROM banks to contain tables. We need to copy those textures to Banked RAM, but have to run that copy-code in Fixed RAM.
    
copy_table_copier_to_ram:

    ; Copying copy_tables_to_banked_ram -> COPY_TABLES_TO_BANKED_RAM
    
    ldy #0
copy_tables_to_banked_ram_byte:
    lda copy_tables_to_banked_ram, y
    sta COPY_TABLES_TO_BANKED_RAM, y
    iny 
    cpy #(end_of_copy_tables_to_banked_ram-copy_tables_to_banked_ram)
    bne copy_tables_to_banked_ram_byte

    rts
    
; FIXME: this is UGLY!
copy_tables_to_banked_ram:


    ; We copy 14 tables to banked RAM, but we pack them so they are easily accessible

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

    ldx #0                             ; x = angle
next_angle_to_copy_to_banked_ram:
    ; Switching to RAM BANK x
    stx RAM_BANK
; FIXME: remove nop!
    nop
    
    ldy #0                             ; y = screen y-line value
next_byte_to_copy_to_banked_ram:
    lda (LOAD_ADDRESS), y
    sta (STORE_ADDRESS), y
    iny
    cpy #64
    bne next_byte_to_copy_to_banked_ram
    
    ; We increment LOAD_ADDRESS by 64 bytes to move to the next angle
    clc
    lda LOAD_ADDRESS
    adc #64
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    inx
    bne next_angle_to_copy_to_banked_ram

    inc TABLE_ROM_BANK
    lda TABLE_ROM_BANK
    cmp #15               ; we go from 1-14 so we need to stop at 15
    bne next_table_to_copy

    ; Switching back to ROM bank 0
    lda #$00
    sta ROM_BANK
; FIXME: remove nop!
    nop
   
    rts
end_of_copy_tables_to_banked_ram:
    
    
    
    

    
    
    ; === Included files ===
    
    .include utils/x16.s
    .include utils/utils.s
    .include utils/timing.s
    .include utils/setup_vera_for_bitmap_and_tilemap.s

    ; ======== NMI / IRQ =======
nmi:
    ; TODO: implement this
    ; FIXME: ugly hack!
    jmp reset
    rti
   
irq:
    rti
    
    
    
  .org $CE00

  .byte $bb, $0b
  .byte $99, $09
  .byte $44, $04
  .byte $ba, $0d
  .byte $99, $0d
  .byte $a9, $0c
  .byte $aa, $0a
  .byte $99, $0b
  .byte $88, $0b
  .byte $88, $08
  .byte $77, $0b
  .byte $77, $09
  .byte $66, $0b
  .byte $77, $07
  .byte $66, $0a
  .byte $66, $0a
  .byte $66, $08
  .byte $66, $06
  .byte $55, $08
  .byte $55, $09
  .byte $55, $07
  .byte $54, $08
  .byte $44, $09
  .byte $44, $08
  .byte $33, $09
  .byte $44, $08
  .byte $20, $0e
  .byte $33, $08
  .byte $33, $09
  .byte $20, $0d
  .byte $33, $07
  .byte $33, $06
  .byte $20, $0d
  .byte $20, $0c
  .byte $22, $09
  .byte $22, $09
  .byte $20, $0c
  .byte $33, $07
  .byte $33, $06
  .byte $10, $0b
  .byte $22, $08
  .byte $33, $05
  .byte $22, $06
  .byte $10, $0a
  .byte $10, $0a
  .byte $22, $05
  .byte $22, $05
  .byte $10, $09
  .byte $22, $04
  .byte $22, $06
  .byte $22, $05
  .byte $22, $05
  .byte $10, $08
  .byte $11, $06
  .byte $22, $04
  .byte $11, $05
  .byte $10, $08
  .byte $22, $03
  .byte $11, $05
  .byte $10, $07
  .byte $11, $06
  .byte $11, $03
  .byte $00, $07
  .byte $11, $04
  .byte $00, $05
  .byte $11, $03
  .byte $00, $04
  .byte $00, $04
  .byte $11, $02
  .byte $00, $04
  .byte $00, $02
  .byte $00, $03
  .byte $00, $02
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $ed, $0e
  .byte $eb, $0f
  .byte $eb, $0e
  .byte $dc, $0e
  .byte $db, $0e
  .byte $d4, $0f
  .byte $da, $0e
  .byte $d3, $0f
  .byte $d4, $0f
  .byte $dc, $0e
  .byte $d3, $0f
  .byte $da, $0d
  .byte $d9, $0d
  .byte $d9, $0d
  .byte $c9, $0d
  .byte $c3, $0f
  .byte $cb, $0d
  .byte $c8, $0d
  .byte $c4, $0e
  .byte $c3, $0e
  .byte $c2, $0f
  .byte $bb, $0c
  .byte $ba, $0b
  .byte $a4, $0c
  .byte $a7, $0a
  .byte $a4, $0c
  .byte $a5, $0b
  .byte $a7, $0a
  .byte $96, $0b
  .byte $96, $0c
  .byte $99, $09
  .byte $98, $0a
  .byte $96, $0a
  .byte $86, $0b
  .byte $88, $09
  .byte $96, $09
  .byte $85, $0b
  .byte $85, $0a
  .byte $85, $0a
  .byte $88, $08
  .byte $76, $09
  .byte $76, $08
  .byte $74, $09
  .byte $64, $09
  .byte $65, $08
  .byte $66, $07
  .byte $65, $08
  .byte $64, $08
  .byte $64, $08
  .byte $54, $08
  .byte $63, $07
  .byte $64, $07
  .byte $53, $08
  .byte $54, $07
  .byte $53, $07
  .byte $53, $07
  .byte $55, $05
  .byte $54, $07
  .byte $53, $07
  .byte $52, $06
  .byte $43, $06
  .byte $43, $06
  .byte $42, $06
  .byte $43, $05
  .byte $42, $05
  .byte $21, $04
  .byte $21, $04
  .byte $21, $03
  .byte $fa, $0f
  .byte $fb, $0f
  .byte $f7, $0f
  .byte $f6, $0f
  .byte $f5, $0f
  .byte $f5, $0f
  .byte $f4, $0f
  .byte $f4, $0f
  .byte $f4, $0f
  .byte $f4, $0f
  .byte $e5, $0f
  .byte $e6, $0f
  .byte $e5, $0f
  .byte $e4, $0f
  .byte $e4, $0f
  .byte $e3, $0f
  .byte $d6, $0d
  .byte $db, $0d
  .byte $d5, $0d
  .byte $d6, $0d
  .byte $d6, $0d
  .byte $c8, $0c
  .byte $c5, $0c
  .byte $c5, $0c
  .byte $b4, $0b
  .byte $b7, $0b
  .byte $b5, $0b
  .byte $b4, $0b
  .byte $a9, $0a
  .byte $a4, $0a
  .byte $99, $09
  .byte $77, $07
  .byte $66, $06
  .byte $55, $05
  .byte $97, $07
  .byte $87, $07
  .byte $86, $06
  .byte $87, $07
  .byte $86, $06
  .byte $87, $07
  .byte $85, $05
  .byte $76, $06
  .byte $76, $06
  .byte $75, $05
  .byte $76, $06
  .byte $76, $06
  .byte $65, $05
  .byte $74, $04
  .byte $65, $05
  .byte $64, $04
  .byte $73, $03
  .byte $54, $04
  .byte $54, $04
  .byte $54, $04
  .byte $53, $03
  .byte $52, $02
  .byte $43, $03
  .byte $bc, $0a
  .byte $77, $07
  .byte $68, $06
  .byte $67, $06
  .byte $57, $05
  .byte $00, $00
  .byte $9a, $09
  .byte $88, $08
  .byte $77, $07
  .byte $67, $06
  .byte $24, $03
  .byte $24, $02
  .byte $23, $02
  .byte $12, $02
  .byte $12, $01
  .byte $12, $01
  .byte $11, $01
  .byte $01, $00
  .byte $ab, $0b
  .byte $aa, $0a
  .byte $7a, $0b
  .byte $7a, $0a
  .byte $9b, $0c
  .byte $8b, $0b
  .byte $8b, $0b
  .byte $8a, $0b
  .byte $7a, $0a
  .byte $7a, $0a
  .byte $79, $0a
  .byte $69, $09
  .byte $69, $09
  .byte $69, $09
  .byte $68, $09
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $00, $00
  .byte $27, $04


  .org $D000

  .byte $7b, $85, $7b, $79, $7c, $7f, $7a, $85
  .byte $79, $7b, $7c, $7a, $76, $7e, $7c, $7a
  .byte $7c, $7a, $7b, $87, $85, $84, $81, $7c
  .byte $7f, $7a, $7e, $7b, $7a, $75, $85, $7a
  .byte $7f, $81, $7b, $87, $7f, $7c, $76, $85
  .byte $7b, $7a, $76, $7a, $79, $7f, $7c, $80
  .byte $7b, $7c, $7c, $7a, $85, $7f, $7b, $7a
  .byte $7f, $76, $85, $80, $7a, $7f, $7c, $7f
  .byte $d1, $06, $d0, $01, $06, $83, $d0, $01
  .byte $d1, $09, $b0, $01, $72, $af, $0d, $d1
  .byte $06, $11, $09, $83, $ae, $06, $09, $0d
  .byte $af, $0d, $11, $af, $0d, $d1, $0d, $b0
  .byte $d0, $06, $af, $d0, $00, $d0, $ae, $72
  .byte $02, $af, $11, $72, $b0, $83, $06, $ad
  .byte $06, $01, $b0, $72, $06, $d1, $09, $af
  .byte $d1, $0d, $d1, $af, $af, $af, $d0, $11
  .byte $81, $81, $7f, $80, $7c, $88, $7a, $85
  .byte $7e, $7c, $7f, $7b, $7f, $87, $7c, $7c
  .byte $88, $81, $7c, $8b, $85, $80, $87, $81
  .byte $7c, $7b, $80, $87, $7f, $85, $88, $7b
  .byte $81, $88, $88, $87, $87, $81, $7a, $87
  .byte $81, $87, $76, $7b, $77, $88, $85, $7e
  .byte $7a, $87, $81, $7c, $88, $87, $7a, $7a
  .byte $85, $76, $87, $84, $7a, $7f, $87, $85
  .byte $ad, $09, $af, $c1, $b9, $db, $ae, $72
  .byte $c3, $c4, $b3, $b2, $c7, $af, $be, $bc
  .byte $db, $bf, $09, $83, $b1, $b5, $d1, $bd
  .byte $09, $c4, $ba, $c6, $c5, $b6, $d0, $b2
  .byte $c2, $da, $be, $b4, $b1, $c0, $bd, $ad
  .byte $c0, $b8, $83, $06, $b4, $c4, $c1, $af
  .byte $06, $c3, $ba, $bd, $bc, $da, $b2, $c2
  .byte $0d, $bb, $ae, $c2, $b7, $ae, $bd, $bd
  .byte $5d, $53, $9d, $9d, $9d, $9c, $9c, $53
  .byte $9a, $91, $93, $94, $93, $95, $95, $9e
  .byte $9c, $95, $95, $95, $94, $95, $95, $9d
  .byte $9c, $95, $98, $98, $97, $96, $96, $9e
  .byte $9b, $94, $94, $97, $97, $95, $95, $9e
  .byte $9a, $91, $91, $92, $92, $93, $93, $53
  .byte $9a, $91, $91, $92, $92, $99, $52, $5e
  .byte $9d, $9c, $9d, $9d, $9d, $55, $5a, $5f
  .byte $0d, $d0, $cf, $09, $c9, $09, $11, $0d
  .byte $d0, $cf, $6e, $ab, $66, $cb, $a4, $c9
  .byte $0d, $0d, $09, $63, $78, $a0, $72, $d1
  .byte $d0, $ce, $a4, $64, $ca, $62, $cf, $0d
  .byte $ab, $6b, $cb, $06, $8f, $73, $d0, $09
  .byte $ae, $c9, $a8, $c9, $cc, $c8, $67, $d0
  .byte $0d, $ab, $65, $c9, $90, $50, $64, $d0
  .byte $0d, $d1, $0d, $d0, $c9, $d0, $d1, $0d
  .byte $83, $ad, $78, $09, $ae, $af, $06, $af
  .byte $0d, $78, $83, $0d, $72, $78, $0d, $11
  .byte $6d, $11, $0d, $0d, $b0, $d0, $11, $69
  .byte $af, $01, $11, $09, $72, $0d, $69, $af
  .byte $09, $83, $0d, $d0, $78, $0d, $83, $d1
  .byte $72, $09, $11, $ae, $78, $ae, $0d, $6d
  .byte $72, $78, $72, $ad, $d0, $ad, $ae, $0d
  .byte $0d, $72, $0d, $78, $d0, $af, $0d, $6d
  .byte $89, $82, $7d, $7d, $82, $86, $7d, $89
  .byte $7d, $68, $6c, $6c, $6c, $6c, $68, $82
  .byte $86, $6c, $70, $6f, $6f, $70, $6c, $7d
  .byte $82, $6c, $6f, $71, $71, $6f, $6c, $7d
  .byte $7d, $6c, $6f, $71, $71, $6f, $6c, $82
  .byte $7d, $6c, $70, $70, $6f, $70, $6c, $86
  .byte $82, $68, $6c, $6c, $6c, $6c, $68, $7d
  .byte $89, $7d, $86, $82, $7d, $7d, $82, $89
  .byte $0f, $25, $29, $2a, $3c, $0c, $3f, $15
  .byte $30, $46, $18, $19, $46, $43, $1e, $3f
  .byte $19, $29, $16, $36, $0a, $13, $29, $3f
  .byte $2a, $30, $13, $3d, $47, $17, $33, $1c
  .byte $30, $22, $40, $32, $0a, $29, $26, $28
  .byte $42, $17, $44, $1c, $13, $39, $1f, $42
  .byte $0a, $36, $31, $2d, $37, $18, $16, $36
  .byte $26, $3a, $33, $47, $1e, $26, $2d, $2e
  .byte $d9, $d9, $d9, $d9, $d6, $d7, $d9, $d6
  .byte $cd, $d2, $d6, $d5, $d3, $d9, $d7, $d8
  .byte $d9, $d9, $cd, $d9, $d9, $d9, $d8, $d9
  .byte $d9, $cd, $d3, $d3, $cd, $d6, $d4, $d8
  .byte $d9, $d4, $d9, $d5, $d9, $cd, $d5, $d9
  .byte $d9, $cd, $d9, $d8, $d7, $d9, $d8, $d7
  .byte $d6, $d2, $cd, $d8, $d6, $d5, $d8, $d9
  .byte $d9, $d8, $d8, $d9, $d8, $d7, $d8, $d9
  .byte $8c, $8e, $8d, $8d, $8d, $8d, $8d, $8d
  .byte $8e, $8e, $8e, $8e, $8e, $8e, $8e, $8e
  .byte $8d, $8d, $8d, $8d, $8d, $8d, $8c, $8d
  .byte $8e, $8e, $8e, $8e, $8e, $8e, $8e, $8e
  .byte $8d, $8d, $8c, $8d, $8c, $8d, $8d, $8d
  .byte $8e, $8e, $8e, $8e, $8e, $8e, $8e, $8e
  .byte $8c, $8d, $8d, $8d, $8c, $8d, $8d, $8d
  .byte $8e, $8e, $8e, $8e, $8e, $8e, $8e, $8e
  .byte $de, $e0, $df, $e2, $de, $e1, $e0, $e2
  .byte $e0, $dc, $dc, $e6, $e0, $e3, $dd, $e5
  .byte $e0, $dc, $e3, $e6, $df, $dc, $dc, $e5
  .byte $e2, $e6, $e8, $e8, $e2, $e5, $e5, $e7
  .byte $de, $df, $df, $e2, $de, $e0, $df, $e2
  .byte $e1, $dd, $dd, $e7, $e0, $dd, $dc, $e6
  .byte $e1, $e4, $dc, $e5, $df, $dc, $e4, $e6
  .byte $e2, $e6, $e5, $e7, $e2, $e6, $e6, $e7
  .byte $05, $2a, $2e, $35, $12, $0e, $45, $5b
  .byte $36, $48, $08, $54, $ab, $45, $25, $2d
  .byte $1b, $14, $4e, $39, $07, $03, $32, $43
  .byte $31, $6d, $25, $4b, $6a, $2d, $10, $04
  .byte $30, $23, $4a, $74, $25, $15, $49, $35
  .byte $42, $4e, $8a, $40, $60, $41, $15, $42
  .byte $0e, $39, $2a, $61, $2a, $0a, $0b, $36
  .byte $54, $45, $33, $47, $1e, $26, $2d, $2e
  .byte $1d, $20, $20, $21, $27, $21, $20, $1d
  .byte $20, $27, $27, $3b, $38, $2f, $2c, $20
  .byte $24, $34, $34, $3b, $3e, $38, $27, $1d
  .byte $20, $2f, $3e, $3e, $38, $3b, $2b, $21
  .byte $1a, $34, $3e, $3b, $3e, $3e, $34, $21
  .byte $20, $34, $3e, $2f, $38, $3b, $2f, $1d
  .byte $21, $2c, $27, $2b, $34, $2f, $2c, $21
  .byte $1a, $1d, $1a, $21, $21, $1a, $20, $1a
  .byte $4f, $51, $51, $56, $4f, $4f, $51, $4d
  .byte $56, $51, $59, $4f, $51, $5c, $51, $51
  .byte $56, $57, $59, $4f, $5c, $51, $56, $59
  .byte $51, $4f, $4f, $58, $57, $56, $56, $58
  .byte $56, $51, $59, $4f, $51, $57, $4c, $56
  .byte $57, $56, $5c, $59, $56, $56, $59, $56
  .byte $4d, $58, $4f, $4f, $56, $51, $56, $4f
  .byte $56, $59, $58, $58, $59, $59, $51, $57
  .byte $aa, $a5, $a6, $aa, $a1, $a9, $a3, $aa
  .byte $a5, $a6, $a5, $a9, $a1, $a7, $ac, $9f
  .byte $a6, $a6, $aa, $a6, $ac, $a5, $a6, $a5
  .byte $aa, $a3, $a9, $a3, $a2, $a6, $a5, $a5
  .byte $a6, $a6, $a5, $a9, $aa, $ac, $aa, $ac
  .byte $aa, $a2, $a2, $a9, $a2, $a3, $a2, $a5
  .byte $a6, $aa, $a5, $a7, $ac, $a6, $a9, $a3
  .byte $a5, $aa, $ac, $a3, $9f, $a1, $a9, $aa


  ; manual TILEMAP
  .org $E000
;  .byte 9, 1, 2, 3
;  .byte 3, 2, 1, 0
;  .byte 5, 4, 5, 4
;  .byte 6, 7, 8, 9
  
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  4,  9,  9,  9,  4,  9,  9,  5,  5,  9,  9,  1,  1,  9,  9,  7,  9,  7,  9,  9,  3,  3,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  4,  9,  9,  9,  4,  9,  5,  9,  9,  5,  9,  1,  9,  1,  9,  7,  9,  7,  9,  3,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  4,  9,  9,  9,  4,  9,  5,  9,  9,  5,  9,  1,  1,  9,  9,  7,  7,  9,  9,  9,  3,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  5,  9,  9,  5,  9,  1,  9,  1,  9,  7,  9,  7,  9,  9,  9,  3,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  4,  9,  4,  9,  9,  9,  5,  5,  9,  9,  1,  9,  1,  9,  7,  9,  7,  9,  3,  3,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9

  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
    
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
    
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
  .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
    
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"
    
    

    .org $fffa
    .word nmi
    .word reset
    .word irq
    
    .if(USE_TABLE_FILES)
    .binary "special_tests/tables/x_in_texture_fraction_corrections_low.bin"
    .binary "special_tests/tables/x_in_texture_fraction_corrections_high.bin"
    .binary "special_tests/tables/y_in_texture_fraction_corrections_low.bin"
    .binary "special_tests/tables/y_in_texture_fraction_corrections_high.bin"
    .binary "special_tests/tables/x_pixel_positions_in_map_low.bin"
    .binary "special_tests/tables/x_pixel_positions_in_map_high.bin"
    .binary "special_tests/tables/y_pixel_positions_in_map_low.bin"
    .binary "special_tests/tables/y_pixel_positions_in_map_high.bin"
    .binary "special_tests/tables/x_sub_pixel_steps_decr.bin"
    .binary "special_tests/tables/x_sub_pixel_steps_low.bin"
    .binary "special_tests/tables/x_sub_pixel_steps_high.bin"
    .binary "special_tests/tables/y_sub_pixel_steps_decr.bin"
    .binary "special_tests/tables/y_sub_pixel_steps_low.bin"
    .binary "special_tests/tables/y_sub_pixel_steps_high.bin"
    .endif
    
