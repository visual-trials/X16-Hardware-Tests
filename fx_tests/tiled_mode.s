
USE_CACHE_FOR_WRITING = 1
DO_4BIT = 0
USE_TABLE_FILES = 1
; FIXME: there is no more non-tile-lookup mode!
; FIXME: there is no more non-tile-lookup mode!
; FIXME: there is no more non-tile-lookup mode!
DO_NO_TILE_LOOKUP = 0
USE_MARIO_MAP_AND_TILES = 1

; FIXME: turn on CLIPPING!
; FIXME: turn on CLIPPING!
; FIXME: turn on CLIPPING!
DO_CLIP = 1


DRAW_TILED_PERSPECTIVE = 1  ; Otherwise FLAT tiles
MOVE_XY_POSITION = 0
TURN_AROUND = 0
MOVE_SLOWLY = 0
DEBUG_LEDS = 0

    .if(DO_NO_TILE_LOOKUP)
BACKGROUND_COLOR = 240  ; 240 = Purple in this palette
COLOR_TEXT  = $03       ; Background color = 0 (transparent), foreground color 3 (white in this palette)
MAP_WIDTH = 8    ; 8 * 8 = 64 pixels
MAP_HEIGHT = 8   ; 8 * 8 = 64 pixels
; This is used in copy_texture_pixels_as_tile_pixels_to_high_vram
TEXTURE_WIDTH = 64
TEXTURE_HEIGHT = 64
    .else
        .if(DO_4BIT)
BACKGROUND_COLOR = $00  ; Purple (black is changed to purple)
COLOR_TEXT  = $01       ; Background color = 0 (transparent), foreground color 1 (white)
MAP_WIDTH = 2
MAP_HEIGHT = 2
; FIXME: the minecraft textures are NOT USED in 4bit mode!
TEXTURE_WIDTH = 8
TEXTURE_HEIGHT = 128
        .else
            .if(USE_MARIO_MAP_AND_TILES)
; FIXME
BACKGROUND_COLOR = 2;   ; Black in this palette
; FIXME
COLOR_TEXT  = $06       ; Background color = 0 (transparent), foreground color ??
MAP_WIDTH = 128
MAP_HEIGHT = 128
TEXTURE_WIDTH = 64      ; FIXME: this actually the number of bytes in a tile! (we should use TILE_WIDTH/TILE_HEIGHT)
TEXTURE_HEIGHT = 171    ; FIXME: We have 171 unique tiles, we should name the variable/constant that way!
            .else
BACKGROUND_COLOR = 255  ; 255 = Purple in this palette
COLOR_TEXT  = $06       ; Background color = 0 (transparent), foreground color 6 (grey in this palette)
MAP_WIDTH = 32
MAP_HEIGHT = 32
; This is used in copy_tiledata_to_high_vram
TEXTURE_WIDTH = 64      ; FIXME: this actually the number of bytes in a tile! (we should use TILE_WIDTH/TILE_HEIGHT)
TEXTURE_HEIGHT = 16     ; FIXME: We have 16 unique tiles, we should name the variable/constant that way!
            .endif
        .endif
    .endif

    .if(DO_4BIT)
NR_OF_BYTES_PER_LINE = 160
    .else
NR_OF_BYTES_PER_LINE = 320
    .endif
    
    
;MAP_WIDTH = 4
;MAP_HEIGHT = 4


TILE_WIDTH = 8
TILE_HEIGHT = 8


TOP_MARGIN = 12
LEFT_MARGIN = 16
VSPACING = 10

    .if(USE_MARIO_MAP_AND_TILES && !DO_4BIT)
MAPDATA_VRAM_ADDRESS = $13000   ; should be aligned to 1kB
TILEDATA_VRAM_ADDRESS = $17000  ; should be aligned to 1kB
    .else
MAPDATA_VRAM_ADDRESS = $17000   ; should be aligned to 1kB
TILEDATA_VRAM_ADDRESS = $18000  ; should be aligned to 1kB
    .endif

DESTINATION_PICTURE_POS_X = 32
DESTINATION_PICTURE_POS_Y = 24
DESTINATION_SND_PICTURE_POS_Y = 124

DESTINATION_PICTURE_WIDTH = 256
DESTINATION_PICTURE_HEIGHT = 80

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

TILE_X                    = $46
TILE_Y                    = $47

WORLD_X_POSITION          = $50 ; 51
WORLD_Y_POSITION          = $52 ; 53

AFFINE_SETTINGS           = $60

DO_DRAW_OVERVIEW_MAP      = $61

; RAM addresses
; FIXME: is there enough space for COPY_ROW_CODE?
COPY_ROW_CODE               = $7800
COPY_TABLES_TO_BANKED_RAM   = $8000
COPY_TILEMAP_TO_HIGH_VRAM   = $8100  ; TODO: this can probably re-use the other copier memory
COPY_TILEDATA_TO_HIGH_VRAM  = $8200  ; TODO: this can probably re-use the other copier memory



X_SUBPIXEL_POSITIONS_IN_MAP_LOW        = $A000
X_SUBPIXEL_POSITIONS_IN_MAP_HIGH       = $A100
Y_SUBPIXEL_POSITIONS_IN_MAP_LOW        = $A200
Y_SUBPIXEL_POSITIONS_IN_MAP_HIGH       = $A300
X_PIXEL_POSITIONS_IN_MAP_LOW           = $A400
X_PIXEL_POSITIONS_IN_MAP_HIGH          = $A500
Y_PIXEL_POSITIONS_IN_MAP_LOW           = $A600
Y_PIXEL_POSITIONS_IN_MAP_HIGH          = $A700
X_SUB_PIXEL_STEPS_LOW                  = $A800
X_SUB_PIXEL_STEPS_HIGH                 = $A900
Y_SUB_PIXEL_STEPS_LOW                  = $AA00
Y_SUB_PIXEL_STEPS_HIGH                 = $AB00


; ROM addresses
PALLETE           = $D000
PIXELS            = $D200
TILEMAP           = $E200

    .if(USE_TABLE_FILES)
TILEMAP_ROM_BANK  = 25   ; Our tilemap starts at ROM Bank 25
TILEDATA_ROM_BANK = 26   ; Our tiledata starts at ROM Bank 26
    .else
TILEMAP_ROM_BANK  = 1   ; Our tilemap starts at ROM Bank 1
TILEDATA_ROM_BANK = 2   ; Our tiledata starts at ROM Bank 2
    .endif


  .org $C000

reset:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs

    lda #1
    jsr output_debug_leds
    
    jsr setup_vera_for_bitmap_and_tile_map

    lda #2
    jsr output_debug_leds
    
    jsr copy_petscii_charset
    
    lda #3
    jsr output_debug_leds
    
    jsr clear_tilemap_screen
    
    lda #4
    jsr output_debug_leds
    
    ; FIXME: we sometimes HANG here!! (green light, with randomly looking bitmap)
    jsr init_cursor
    jsr init_timer

    lda #5
    jsr output_debug_leds
    
;    jsr clear_screen_slow
;    lda #$20                 ; 4:1 scale, so we can clearly see the pixels
;    sta VERA_DC_HSCALE
;    sta VERA_DC_VSCALE
;    jsr affine_transform_some_bytes
    
    ; Put orginal picture on screen (slow)
    jsr clear_screen_slow
    .if(!DO_4BIT)
        jsr copy_palette
    .endif
    .if(DO_NO_TILE_LOOKUP)
        jsr copy_texture_pixels_as_tile_pixels_to_high_vram
    .else
        .if(USE_MARIO_MAP_AND_TILES)
            ; We are copying a large tilemap and tiledata here, so we have to use a ROM bank
            jsr copy_tiledata_copier_to_ram
            jsr COPY_TILEDATA_TO_HIGH_VRAM
        
            jsr copy_tilemap_copier_to_ram
            jsr COPY_TILEMAP_TO_HIGH_VRAM
        .else
            jsr copy_tiledata_to_high_vram
            jsr copy_tilemap_to_high_vram
        .endif
    .endif
    
    lda #6
    jsr output_debug_leds
    
    .if(DRAW_TILED_PERSPECTIVE)
        ; Test speed of perspective style transformation
        
        jsr generate_copy_row_code
        
        .if(USE_TABLE_FILES)
            jsr copy_table_copier_to_ram
            jsr COPY_TABLES_TO_BANKED_RAM
        .endif
        
        lda #1
        sta DO_DRAW_OVERVIEW_MAP
        jsr draw_overview_map
        
        stz DO_DRAW_OVERVIEW_MAP
        jsr test_speed_of_tiled_perspective
    .else    
        ; Test speed of flat tiles draws
        jsr test_speed_of_flat_tiles
    .endif
  
    lda #7
    jsr output_debug_leds
    
loop:
  jmp loop

  

one_byte_per_write_message: 
    .asciiz "Method: 1 byte per write"
four_bytes_per_write_message: 
    .asciiz "Method: 4 bytes per write"


output_debug_leds:
    .if(DEBUG_LEDS)
    sta BYTE_TO_PRINT
    jsr output_3bits_as_debug_leds
    .endif
    rts

; ====================================== OVERVIEW MAP ========================================
    
draw_overview_map:

    lda #128
    sta WORLD_X_POSITION
    lda #1
    sta WORLD_X_POSITION+1
    
    lda #213
    sta WORLD_Y_POSITION
    lda #5
    sta WORLD_Y_POSITION+1
    
    
    ; FIXME: set variable that we have to use a SINGLE/STATIC shot (not the TABLE FILES!)
    
    
    jsr tiled_perspective_fast


    rts
    
; ==================================== / OVERVIEW MAP ========================================

; ====================================== TILED PERSPECTIVE SPEED TEST ========================================
  
test_speed_of_tiled_perspective:

    ; -- Initial world position --
    
    lda #128
;    lda #$D0
    sta WORLD_X_POSITION
    lda #3
;    lda #$FF
    sta WORLD_X_POSITION+1
    
    lda #100
    sta WORLD_Y_POSITION
    lda #0
    sta WORLD_Y_POSITION+1
    
    .if(USE_TABLE_FILES)
    
        lda #0
;        lda #210
;        lda #60
        sta VIEWING_ANGLE
move_or_turn_around:
        lda VIEWING_ANGLE
        sta RAM_BANK

        ; FIXME: set variable that we have to use a DYNAMIC shot (using the TABLE FILES!)
        
        jsr tiled_perspective_fast

        .if(TURN_AROUND)
            inc VIEWING_ANGLE
        .endif
        
        .if(MOVE_XY_POSITION)
            clc
            lda WORLD_X_POSITION
            adc #1
            sta WORLD_X_POSITION
            lda WORLD_X_POSITION+1
            adc #0
            sta WORLD_X_POSITION+1
            
            clc
            lda WORLD_Y_POSITION
            adc #1
            sta WORLD_Y_POSITION
            lda WORLD_Y_POSITION+1
            adc #0
            sta WORLD_Y_POSITION+1
        .endif

        .if(MOVE_SLOWLY)
            lda #0
            sta TMP1
wait_a_bit_1:
            lda #70
            sta TMP2
wait_a_bit_2:
            dec TMP2
            bne wait_a_bit_2
            
            inc TMP1
            bne wait_a_bit_1
        .endif
        
        bra move_or_turn_around
    .else
        jsr start_timer
        jsr tiled_perspective_fast
        jsr stop_timer

        lda #COLOR_TEXT
        sta TEXT_COLOR
        
        lda #5
        sta CURSOR_X
        lda #2
        sta CURSOR_Y

        if (DO_4BIT)
            lda #<tiled_perspective_256x80_4bpp_message
            sta TEXT_TO_PRINT
            lda #>tiled_perspective_256x80_4bpp_message
            sta TEXT_TO_PRINT + 1
        .else
            lda #<tiled_perspective_256x80_8bpp_message
            sta TEXT_TO_PRINT
            lda #>tiled_perspective_256x80_8bpp_message
            sta TEXT_TO_PRINT + 1
        .endif
        
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
    


tiled_perspective_256x80_8bpp_message: 
    .asciiz "Tiled perspective 256x80 (8bpp) "
tiled_perspective_256x80_4bpp_message: 
    .asciiz "Tiled perspective 256x80 (4bpp) "

    
; For tiled perspective we need to set the x and y coordinate within the tilemap for each pixel row on the screen. 
; We also have to set the sub pixel increment for each pixel row on the screen.
; We generated this using the python script (see same folder) and put the data here.
    
x_subpixel_positions_in_map_low:
    .byte 128,0,0,128,0,0,0,128,128,128,0,128,128,0,128,128,0,0,0,128,0,0,128,128,128,0,128,128,0,0,0,0,0,128,128,128,128,0,128,0,0,128,128,0,0,0,0,0,0,128,0,128,128,0,0,128,0,128,0,128,0,0,0,0,128,0,128,0,128,128,128,0,0,128,128,128,128,128,0,128
x_subpixel_positions_in_map_high:
    .byte 204,183,152,110,60,0,186,107,19,178,73,214,91,216,76,184,28,120,204,24,93,154,207,253,36,68,92,110,121,125,122,113,97,74,45,10,225,178,124,65,0,184,107,25,193,99,0,151,41,181,61,191,60,181,40,150,0,100,196,31,118,200,21,94,162,227,30,86,137,184,227,10,45,75,102,125,144,159,171,178
y_subpixel_positions_in_map_low:
    .byte 128,128,128,0,0,0,128,0,0,0,128,128,0,0,128,0,0,0,128,0,0,0,128,0,0,0,0,0,0,128,128,128,0,0,0,0,128,0,128,0,128,0,128,128,128,0,0,0,128,0,0,128,128,0,128,128,128,128,128,0,128,128,128,128,128,0,0,0,128,0,128,128,128,0,128,0,0,0,128,128
y_subpixel_positions_in_map_high:
    .byte 255,91,136,136,90,0,121,200,236,230,182,94,222,54,102,113,85,20,173,35,116,162,172,149,91,0,131,230,40,74,77,49,247,158,39,147,225,19,40,34,255,194,105,246,104,193,0,37,49,37,0,194,109,1,124,225,47,103,136,148,137,105,52,234,139,24,144,244,68,129,170,192,195,180,145,93,22,189,82,214
x_pixel_positions_in_map_low:
    .byte 116,120,124,128,132,136,139,143,147,150,154,157,161,164,168,171,175,178,181,185,188,191,194,197,201,204,207,210,213,216,219,222,225,228,231,234,236,239,242,245,248,250,253,0,2,5,8,10,13,15,18,20,23,25,28,30,33,35,37,40,42,44,47,49,51,53,56,58,60,62,64,67,69,71,73,75,77,79,81,83
x_pixel_positions_in_map_high:
    .byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
y_pixel_positions_in_map_low:
    .byte 29,48,66,84,102,120,137,154,171,188,205,222,238,255,15,31,47,63,78,94,109,124,139,154,169,184,198,212,227,241,255,13,26,40,54,67,80,94,107,120,132,145,158,170,183,195,208,220,232,244,0,11,23,35,46,57,69,80,91,102,113,124,135,145,156,167,177,187,198,208,218,228,238,248,2,12,22,31,41,50
y_pixel_positions_in_map_high:
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6
x_sub_pixel_steps_low:
    .byte 76,61,45,30,15,0,241,226,211,197,182,168,154,140,126,113,99,86,72,59,46,33,20,8,251,238,226,214,202,190,178,166,154,142,131,119,108,97,86,74,63,53,42,31,20,10,0,245,235,225,215,205,195,185,175,165,156,146,136,127,118,108,99,90,81,72,63,54,45,37,28,19,11,2,250,242,233,225,217,209
x_sub_pixel_steps_high:
    .byte 12,12,12,12,12,12,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,8,8,8,8,8,8
y_sub_pixel_steps_low:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
y_sub_pixel_steps_high:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    
    
tiled_perspective_fast:

    .if(DO_4BIT)
        lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
        sta VERA_ADDR_BANK
        
        lda #$FA
        sta VERA_ADDR_HIGH
        lda #$00                 ; We overwrite color 0 here
        sta VERA_ADDR_LOW

        ; Nice purple
        lda #$05                 ; gb
        sta VERA_DATA0
        lda #$05                 ; -r
        sta VERA_DATA0
            
        ; VERA.layer0.config = (4 + 2) ; enable bitmap mode and color depth = 4bpp on layer 0
        lda #(4+2)
        sta VERA_L0_CONFIG
    .endif

    ; Setup FROM and TO VRAM addresses
    .if(DO_4BIT)
        lda #<(DESTINATION_PICTURE_POS_X/2+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO
        lda #>(DESTINATION_PICTURE_POS_X/2+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO+1
    .else
        lda DO_DRAW_OVERVIEW_MAP
        beq setup_vram_for_dynamic_draw
        lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_SND_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO
        lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_SND_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO+1
        bra setup_vram_done
setup_vram_for_dynamic_draw:    
        lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO
        lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO+1
setup_vram_done:
    .endif

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    
    ; Setting base addresses and map size
    
    lda #(TILEDATA_VRAM_ADDRESS >> 9)
    and #$FC   ; only the 6 highest bits of the address can be set
    .if(DO_CLIP)
        ora #%00000010  ; 1 for Clip
    .else
        ora #%00000000  ; 0 for Repeat
    .endif
    sta $9F2A
    
    lda #(MAPDATA_VRAM_ADDRESS >> 9)
    and #$FC   ; only the 6 highest bits of the address can be set
    .if(DO_NO_TILE_LOOKUP)
NON TILE LOOK MODE DOESNT EXIST ANYMORE
        ora #%00000001  ; Map size = 01 (8x8 map)
    .else
        .if(DO_4BIT)
            ora #%00000000  ; Map size = 00 (2x2 map)
        .else
            .if(USE_MARIO_MAP_AND_TILES)
                ora #%00000011  ; Map size = 11 (128x128 map)
            .else
                ora #%00000010  ; Map size = 10 (32x32 map)
            .endif
        .endif
    .endif
    sta $9F2B
    
    .if(DO_NO_TILE_LOOKUP)
; FIXME: there is no more mode without tile lookup!
NON TILE LOOK MODE DOESNT EXIST ANYMORE
    .else
        if(DO_4BIT)
            lda #%00100111  ; cache fill enabled = 1, 4-bit mode, affine helper mode (with tile lookup)
        .else
            lda #%00100011  ; cache fill enabled = 1, affine helper mode (with tile lookup)
        .endif
    .endif
    .if(USE_CACHE_FOR_WRITING)
        ora #%01000000  ; blit write = 1
    .endif
    sta $9F29
    
    
;    lda #%00000110           ; DCSEL=3, ADDRSEL=0
;    sta VERA_CTRL
    
; FIXME: why are we setting the increment here??
;    lda #0                   ; X increment low
;    sta $9F29
;    lda #%00000101           ; 00, X decr = 0, X subpixel increment exponent = 001, X increment high = 01
;    sta $9F2A
;    lda #00                  ; Y increment low
;    sta $9F2B
;    lda #%00000100           ; 00, Y decr, Y subpixel increment exponent = 001, Y increment high = 00 
;    sta $9F2C

    ldx #0
    
tiled_perspective_copy_next_row_1:
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL

    .if (USE_CACHE_FOR_WRITING)
        lda #%00110000           ; Setting auto-increment value to 4 byte increment (=%0011)
        sta VERA_ADDR_BANK
    .else
        .if(DO_4BIT)
            lda #%00000100           ; Setting auto-increment value to 0.5 byte (1 nibble) increment (=%0000 + 1)
            sta VERA_ADDR_BANK
        .else
            lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
            sta VERA_ADDR_BANK
        .endif
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW
    
    ; We have to set both x and y subpixels incrementers, so we change to the appropiate selectors
    ; NOTE: since we already in this setting, we dont have to set it again
    ; lda #%00000110           ; DCSEL=3, ADDRSEL=0
    ; sta VERA_CTRL
    
    lda DO_DRAW_OVERVIEW_MAP
    bne setup_increment_and_positions_for_overview_map
    
        ; We now set the increments
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
        ; Note: the x32 is packed into the table-data
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
        ; Note: the x32 is packed into the table-data
        sta $9F2C
            
        ; Setting the position
        
        lda #%00001001           ; DCSEL=4, ADDRSEL=1
        sta VERA_CTRL

        .if(USE_TABLE_FILES)
            lda X_PIXEL_POSITIONS_IN_MAP_LOW, x
        .else
            lda x_pixel_positions_in_map_low, x
        .endif
        clc
        adc WORLD_X_POSITION
        sta $9F29                ; X pixel position low [7:0]
        .if(USE_TABLE_FILES)
            lda X_PIXEL_POSITIONS_IN_MAP_HIGH, x
        .else
            lda x_pixel_positions_in_map_high, x
        .endif
        adc WORLD_X_POSITION+1
    ; FIXME: and #%00000111
        .if(USE_TABLE_FILES)
            ora X_SUBPIXEL_POSITIONS_IN_MAP_LOW, x
        .else
            ora x_subpixel_positions_in_map_low, x
        .endif
        sta $9F2A                ; X subpixel position[0], X pixel position high [10:8]
        
        .if(USE_TABLE_FILES)
            lda Y_PIXEL_POSITIONS_IN_MAP_LOW, x
        .else
            lda y_pixel_positions_in_map_low, x
        .endif
        clc
        adc WORLD_Y_POSITION
        sta $9F2B                ; Y pixel position low [7:0]
        .if(USE_TABLE_FILES)
            lda Y_PIXEL_POSITIONS_IN_MAP_HIGH, x
        .else
            lda y_pixel_positions_in_map_high, x
        .endif
        adc WORLD_Y_POSITION+1
    ; FIXME: and #%00000111
        .if(USE_TABLE_FILES)
            ora Y_SUBPIXEL_POSITIONS_IN_MAP_LOW, x
        .else
            ora y_subpixel_positions_in_map_low, x
        .endif
        ora #%01000000           ; Reset cache byte index = 1
        sta $9F2C                ; Y subpixel position[0], Reset cache byte index = 1, Y pixel position high [10:8]
        
        
        ; Setting the sub position
        
        lda #%00001011           ; DCSEL=5, ADDRSEL=1
        sta VERA_CTRL
        
        .if(USE_TABLE_FILES)
            lda X_SUBPIXEL_POSITIONS_IN_MAP_HIGH, x
        .else
            lda x_subpixel_positions_in_map_high, x
        .endif
        sta $9F29                ; X subpixel increment [8:1]
        
        .if(USE_TABLE_FILES)
            lda Y_SUBPIXEL_POSITIONS_IN_MAP_HIGH, x
        .else
            lda y_subpixel_positions_in_map_high, x
        .endif
        sta $9F2A                ; Y subpixel increment [8:1]
    
        bra done_setting_up_increments_and_positions
    
setup_increment_and_positions_for_overview_map:
        ; We now set the increments
        lda x_sub_pixel_steps_low, x
        sta $9F29                ; X increment low
        
        lda x_sub_pixel_steps_high, x
        ; Note: the x32 is packed into the table-data
        sta $9F2A
        
        lda y_sub_pixel_steps_low, x
        sta $9F2B
        
        lda y_sub_pixel_steps_high, x
        ; Note: the x32 is packed into the table-data
        sta $9F2C
            
        ; Setting the position
        
        lda #%00001001           ; DCSEL=4, ADDRSEL=1
        sta VERA_CTRL

        lda x_pixel_positions_in_map_low, x
        clc
        adc WORLD_X_POSITION
        sta $9F29                ; X pixel position low [7:0]
        lda x_pixel_positions_in_map_high, x
        adc WORLD_X_POSITION+1
    ; FIXME: and #%00000111
        ora x_subpixel_positions_in_map_low, x
        sta $9F2A                ; X subpixel position[0], X pixel position high [10:8]
        
        lda y_pixel_positions_in_map_low, x
        clc
        adc WORLD_Y_POSITION
        sta $9F2B                ; Y pixel position low [7:0]
        lda y_pixel_positions_in_map_high, x
        adc WORLD_Y_POSITION+1
    ; FIXME: and #%00000111
        .if(USE_TABLE_FILES)
            ora Y_SUBPIXEL_POSITIONS_IN_MAP_LOW, x
        .else
            ora y_subpixel_positions_in_map_low, x
        .endif
        ora #%01000000           ; Reset cache byte index = 1
        sta $9F2C                ; Y subpixel position[0], Reset cache byte index = 1, Y pixel position high [10:8]
        
        
        ; Setting the sub position
        
        lda #%00001011           ; DCSEL=5, ADDRSEL=1
        sta VERA_CTRL
        
        lda x_subpixel_positions_in_map_high, x
        sta $9F29                ; X subpixel increment [8:1]
        
        lda y_subpixel_positions_in_map_high, x
        sta $9F2A                ; Y subpixel increment [8:1]
        
done_setting_up_increments_and_positions:

    ; Copy one row of 256 pixels
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with NR_OF_BYTES_PER_LINE
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(NR_OF_BYTES_PER_LINE)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(NR_OF_BYTES_PER_LINE)
    sta VERA_ADDR_ZP_TO+1

    inx
; FIXME: this is a bad name! We are not doing textures anymore!
    cpx #DESTINATION_PICTURE_HEIGHT     ; we do 80 rows
    beq done_tiled_perspective_copy

    jmp tiled_perspective_copy_next_row_1
done_tiled_perspective_copy:
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00000000  ; cache fill enabled = 0, blit write = 0, 8-bit mode, normal addr1-mode
    sta $9F29
    
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

    .if(DO_4BIT)
        lda #<flat_tiles_24x8_4bpp_message
        sta TEXT_TO_PRINT
        lda #>flat_tiles_24x8_4bpp_message
        sta TEXT_TO_PRINT + 1
    .else
        lda #<flat_tiles_24x8_8bpp_message
        sta TEXT_TO_PRINT
        lda #>flat_tiles_24x8_8bpp_message
        sta TEXT_TO_PRINT + 1
    .endif
    
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
flat_tiles_24x8_4bpp_message: 
    .asciiz "24x8 flat tiles of 8x8 size (4bpp) "

    


flat_tiles_fast:

    .if(DO_4BIT)
        lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
        sta VERA_ADDR_BANK
        
        lda #$FA
        sta VERA_ADDR_HIGH
        lda #$00                 ; We overwrite color 0 here
        sta VERA_ADDR_LOW

        ; Nice purple
        lda #$05                 ; gb
        sta VERA_DATA0
        lda #$05                 ; -r
        sta VERA_DATA0
            
        ; VERA.layer0.config = (4 + 2) ; enable bitmap mode and color depth = 4bpp on layer 0
        lda #(4+2)
        sta VERA_L0_CONFIG
    .endif

    ; Setup FROM and TO VRAM addresses
    .if(DO_4BIT)
        lda #<(DESTINATION_PICTURE_POS_X/2+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO
        lda #>(DESTINATION_PICTURE_POS_X/2+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO+1
    .else
        lda #<(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO
        lda #>(DESTINATION_PICTURE_POS_X+DESTINATION_PICTURE_POS_Y*NR_OF_BYTES_PER_LINE)
        sta VERA_ADDR_ZP_TO+1
    .endif

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    ; Setting base addresses and map size
    
    lda #(TILEDATA_VRAM_ADDRESS >> 9)
    and #$FC   ; only the 6 highest bits of the address can be set
    .if(DO_CLIP)
        ora #%00000010  ; 1 for Clip
    .else
        ora #%00000000  ; 0 for Repeat
    .endif
    sta $9F2A
    
    lda #(MAPDATA_VRAM_ADDRESS >> 9)
    and #$FC   ; only the 6 highest bits of the address can be set
    .if(DO_NO_TILE_LOOKUP)
NON TILE LOOK MODE DOESNT EXIST ANYMORE
        ora #%00000001  ; Map size = 01 (8x8 map)
    .else
        .if(DO_4BIT)
            ora #%00000000  ; Map size = 00 (2x2 map)
        .else
            .if(USE_MARIO_MAP_AND_TILES)
                ora #%00000011  ; Map size = 11 (128x128 map)
            .else
                ora #%00000010  ; Map size = 10 (32x32 map)
            .endif
        .endif
    .endif
    sta $9F2B
    
    .if(DO_NO_TILE_LOOKUP)
; FIXME: there is no more mode without tile lookup!
NON TILE LOOK MODE DOESNT EXIST ANYMORE
    .else
        if(DO_4BIT)
            lda #%00100111  ; cache fill enabled = 1, 4-bit mode, affine helper mode (with tile lookup)
        .else
            lda #%00100011  ; cache fill enabled = 1, affine helper mode (with tile lookup)
        .endif
    .endif
    .if(USE_CACHE_FOR_WRITING)
        ora #%01000000  ; blit write = 1
    .endif
    sta $9F29
    
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL
    
    lda #0                   ; X increment low = 0
    sta $9F29
    lda #%00000010           ; X increment high = 10b
    sta $9F2A
    lda #00                  ; Y increment low = 0
    sta $9F2B
    lda #%00000000           ; Y increment high = 0
    sta $9F2C

    ldx #0
    
repetitive_copy_next_row_1:
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL

    .if (USE_CACHE_FOR_WRITING)
        lda #%00110000           ; Setting auto-increment value to 4 byte increment (=%0011) 
        sta VERA_ADDR_BANK
    .else
        .if(DO_4BIT)
            lda #%00000100           ; Setting auto-increment value to 0.5 byte (1 nibble) increment (=%0000 + 1)
            sta VERA_ADDR_BANK
        .else
            lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001)
            sta VERA_ADDR_BANK
        .endif
    .endif
    lda VERA_ADDR_ZP_TO+1
    sta VERA_ADDR_HIGH
    lda VERA_ADDR_ZP_TO
    sta VERA_ADDR_LOW

    ; Setting the position
    
    lda #%00001001           ; DCSEL=4, ADDRSEL=1
    sta VERA_CTRL
    
    lda #0                   ; X pixel position low [7:0]
    sta $9F29
    lda #0                   ; X subpixel position[0] = 0, X pixel position high [10:8]
    sta $9F2A
;        lda #0                   ; Y pixel position low [7:0]
;        sta $9F2B
; FIXME: We directly put register x in the x pixel position low atm
    txa
;    clc
;    adc #4
    sta $9F2B
;        lda #0                   ; Y pixel position high [10:8] = 0
    lda #%01000000           ; Y subpixel position[0] = 0, Reset cache byte index = 1, Y pixel position high [10:8] = 0
    sta $9F2C
    
    
    ; Copy one row of 256 pixels
    jsr COPY_ROW_CODE
    
    ; We increment our VERA_ADDR_TO with NR_OF_BYTES_PER_LINE
    clc
    lda VERA_ADDR_ZP_TO
    adc #<(NR_OF_BYTES_PER_LINE)
    sta VERA_ADDR_ZP_TO
    lda VERA_ADDR_ZP_TO+1
    adc #>(NR_OF_BYTES_PER_LINE)
    sta VERA_ADDR_ZP_TO+1

    inx
    cpx #DESTINATION_PICTURE_HEIGHT     ; we do 80 rows
    bne repetitive_copy_next_row_1
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00000000  ; cache fill enabled = 0, blit write = 0, 8-bit mode, normal addr1-mode
    sta $9F29
    
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
        
        .if(DO_4BIT)
            ; When using the cache for writing we only write 1/8th of the time, so we read 4 extra bytes here (they go into the cache)
        
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

            ; -- lda VERA_DATA1 ($9F24)
            lda #$AD               ; lda ....
            jsr add_code_byte
            
            lda #$24               ; VERA_DATA1
            jsr add_code_byte
            
            lda #$9F         
            jsr add_code_byte

        .endif

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
        .if(DO_4BIT)
            cpx #DESTINATION_PICTURE_WIDTH/8   ; 32*8=256 copy pixels written to VERA
        .else
            cpx #DESTINATION_PICTURE_WIDTH/4   ; 64*4=256 copy pixels written to VERA
        .endif
    .else
        cpx #DESTINATION_PICTURE_WIDTH     ; 256 copy pixels written to VERA
    .endif
    beq copy_instruction_end
    jmp next_copy_instruction
    
copy_instruction_end:

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

; FIXME! this is WRONG for 4-bit mode!
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

; FIXME! this is WRONG for 4-bit mode!
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
; FIXME! this is WRONG for 4-bit mode! Right?
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

    
    .if(USE_MARIO_MAP_AND_TILES && !DO_4BIT)
    
copy_tiledata_copier_to_ram:

    ; Copying copy_tiledata_to_high_vram -> COPY_TILEDATA_TO_HIGH_VRAM
    
    ldy #0
copy_tiledata_to_high_vram_byte:
    lda copy_tiledata_to_high_vram, y
    sta COPY_TILEDATA_TO_HIGH_VRAM, y
    iny 
    cpy #(end_of_copy_tiledata_to_high_vram-copy_tiledata_to_high_vram)
    bne copy_tiledata_to_high_vram_byte

    rts

copy_tiledata_to_high_vram:    
    
    ; Switching ROM BANK
    lda #TILEDATA_ROM_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    lda #<($C000)        ; Our source table starts at C000
    sta LOAD_ADDRESS
    lda #>($C000)
    sta LOAD_ADDRESS+1

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
    lda (LOAD_ADDRESS),y

; FIXME!
;    lda #2
    sta VERA_DATA0

    iny
    cpy #TEXTURE_WIDTH
    bne next_horizontal_pixel_high_vram
    inx
    
    ; Adding TEXTURE_WIDTH to the previous data address
    clc
    lda LOAD_ADDRESS
    adc #TEXTURE_WIDTH
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1

    cpx #TEXTURE_HEIGHT
    bne next_pixel_row_high_vram
    
    ; Switching back to ROM bank 0
    lda #$00
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    rts
end_of_copy_tiledata_to_high_vram:

    .else
    
    
copy_tiledata_to_high_vram:  

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
    
    .endif
    
    
    
    .if(DO_NO_TILE_LOOKUP)
copy_texture_pixels_as_tile_pixels_to_high_vram:  

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
    
    lda #0
    sta TILE_Y

next_tile_row_high_vram_tx:

    lda #0
    sta TILE_X

next_tile_high_vram_tx:    

    ldx #0
next_tile_pixel_row_high_vram:  

    ldy #0
next_horizontal_tile_pixel_high_vram:
    lda (DATA_PTR_ZP),y

    sta VERA_DATA0

    iny
    cpy #TILE_WIDTH
    bne next_horizontal_tile_pixel_high_vram
    inx
    
    ; Adding TEXTURE_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #TEXTURE_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    cpx #TILE_HEIGHT
    bne next_tile_pixel_row_high_vram
    
    ; Move the texture pixel 8 pixels upwards and one tile width to the right (this is where the next 'tile' starts)
    sec
    lda DATA_PTR_ZP
    sbc #<(TEXTURE_WIDTH*TILE_HEIGHT-TILE_WIDTH)
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    sbc #>(TEXTURE_WIDTH*TILE_HEIGHT-TILE_WIDTH)
    sta DATA_PTR_ZP+1
    
    inc TILE_X
    lda TILE_X
    cmp #MAP_WIDTH
    bne next_tile_high_vram_tx

    ; Move the texture pixel 7 pixels downwards (this is where the the next 'tile row' starts)

    clc
    lda DATA_PTR_ZP
    adc #<(TEXTURE_WIDTH*7)
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #>(TEXTURE_WIDTH*7)
    sta DATA_PTR_ZP+1
    
    inc TILE_Y
    lda TILE_Y
    cmp #MAP_HEIGHT
    bne next_tile_row_high_vram_tx

    
    rts
    .endif
    
    
    .if(USE_MARIO_MAP_AND_TILES && !DO_4BIT)
    
copy_tilemap_copier_to_ram:

    ; Copying copy_tilemap_to_high_vram -> COPY_TILEMAP_TO_HIGH_VRAM
    
    ldy #0
copy_tilemap_to_high_vram_byte:
    lda copy_tilemap_to_high_vram, y
    sta COPY_TILEMAP_TO_HIGH_VRAM, y
    iny 
    cpy #(end_of_copy_tilemap_to_high_vram-copy_tilemap_to_high_vram)
    bne copy_tilemap_to_high_vram_byte

    rts

copy_tilemap_to_high_vram:    
    
    ; We copy a 128x128 tilemap to high VRAM

    ; Switching ROM BANK
    lda #TILEMAP_ROM_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    lda #<($C000)        ; Our source table starts at C000
    sta LOAD_ADDRESS
    lda #>($C000)
    sta LOAD_ADDRESS+1

    
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
    lda (LOAD_ADDRESS),y

; FIXME!
;    lda #3
    sta VERA_DATA0

    iny
    cpy #MAP_WIDTH
    bne next_horizontal_tile_high_vram
    inx
    
    ; Adding MAP_WIDTH to the previous data address
    clc
    lda LOAD_ADDRESS
    adc #MAP_WIDTH
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1

    cpx #MAP_HEIGHT
    bne next_tile_row_high_vram
    
    
    ; Switching back to ROM bank 0
    lda #$00
    sta ROM_BANK
; FIXME: remove nop!
    nop
    
    rts
end_of_copy_tilemap_to_high_vram:
    
    .else
    
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
    
    ; Adding MAP_WIDTH to the previous data address
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
    
    .endif
    
    
    
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

    ; We copy 12*2=24 half-tables (12 full tables) to banked RAM, but we pack them so they are easily accessible

    lda #1               ; Our first tables starts at ROM Bank 1
    sta TABLE_ROM_BANK
    
next_table_to_copy:  
    ; We calculate the address (in Banked RAM) where we have to store this table
    lda TABLE_ROM_BANK
    sec
    sbc #1               ; since the TABLE_ROM_BANK starts at 1, we substract one from it
    ; Since each ROM BANK is really half a table we divide by 2
    lsr
    sta TMP1             ; We store it here for now

  
    lda #<($C000)        ; Our source table starts at C000
    sta LOAD_ADDRESS
    lda #>($C000)
    sta LOAD_ADDRESS+1

    lda #<($A000)        ; We store at Ax00
    sta STORE_ADDRESS
    clc
    lda #>($A000)
    adc TMP1
    sta STORE_ADDRESS+1

    ; Switching ROM BANK
    lda TABLE_ROM_BANK
    sta ROM_BANK
; FIXME: remove nop!
    nop

    lda TABLE_ROM_BANK
    and #%00000001      ; check if its even or odd
    bne copy_table_even_rom_bank

        ; -- Odd rom bank: angles 0-127 --
copy_table_odd_rom_bank:
        ldx #0                             ; x = angle
next_angle_to_copy_to_banked_ram_odd:
        ; Switching to RAM BANK x
        stx RAM_BANK
    ; FIXME: remove nop!
        nop
        
        ldy #0                             ; y = screen y-line value
next_byte_to_copy_to_banked_ram_odd:
        lda (LOAD_ADDRESS), y
        sta (STORE_ADDRESS), y
        iny
        cpy #80
        bne next_byte_to_copy_to_banked_ram_odd
        
        ; We increment LOAD_ADDRESS by 80 bytes to move to the next angle
        clc
        lda LOAD_ADDRESS
        adc #80
        sta LOAD_ADDRESS
        lda LOAD_ADDRESS+1
        adc #0
        sta LOAD_ADDRESS+1
        
        inx
        cpx #128
        bne next_angle_to_copy_to_banked_ram_odd
        
        bra rom_bank_loaded
    
    
        ; -- Even rom bank: angles 128-255 --
copy_table_even_rom_bank:
        ldx #128                             ; x = angle
next_angle_to_copy_to_banked_ram_even:
        ; Switching to RAM BANK x
        stx RAM_BANK
    ; FIXME: remove nop!
        nop
        
        ldy #0                             ; y = screen y-line value
next_byte_to_copy_to_banked_ram_even:
        lda (LOAD_ADDRESS), y
        sta (STORE_ADDRESS), y
        iny
        cpy #80
        bne next_byte_to_copy_to_banked_ram_even
        
        ; We increment LOAD_ADDRESS by 80 bytes to move to the next angle
        clc
        lda LOAD_ADDRESS
        adc #80
        sta LOAD_ADDRESS
        lda LOAD_ADDRESS+1
        adc #0
        sta LOAD_ADDRESS+1
        
        inx
        bne next_angle_to_copy_to_banked_ram_even
    
    
rom_bank_loaded:

    inc TABLE_ROM_BANK
    lda TABLE_ROM_BANK
    cmp #25               ; we go from 1-24 so we need to stop at 25
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
    
    
    
  .org $D000
  
  .if(DO_NO_TILE_LOOKUP)
  
  .byte $aa, $0a
  .byte $88, $08
  .byte $00, $00
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $ee, $0f
  .byte $ee, $0e
  .byte $ee, $0f
  .byte $ee, $0e
  .byte $dd, $0e
  .byte $dd, $0e
  .byte $dc, $0e
  .byte $cc, $0d
  .byte $66, $06
  .byte $56, $06
  .byte $55, $06
  .byte $ff, $0f
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $fe, $0f
  .byte $ff, $0f
  .byte $fe, $0f
  .byte $fd, $0f
  .byte $fe, $0f
  .byte $fd, $0f
  .byte $ed, $0f
  .byte $ee, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ee, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $ec, $0e
  .byte $ec, $0e
  .byte $ed, $0e
  .byte $dd, $0f
  .byte $ec, $0e
  .byte $dc, $0f
  .byte $dd, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0e
  .byte $dc, $0d
  .byte $db, $0d
  .byte $cb, $0d
  .byte $cc, $0d
  .byte $cc, $0d
  .byte $cb, $0d
  .byte $cb, $0c
  .byte $ba, $0c
  .byte $ba, $0c
  .byte $bb, $0b
  .byte $ba, $0b
  .byte $55, $05
  .byte $34, $03
  .byte $34, $02
  .byte $ab, $0b
  .byte $44, $04
  .byte $44, $04
  .byte $34, $04
  .byte $34, $03
  .byte $34, $03
  .byte $33, $03
  .byte $34, $03
  .byte $33, $03
  .byte $33, $03
  .byte $33, $03
  .byte $33, $03
  .byte $23, $02
  .byte $23, $02
  .byte $11, $01
  .byte $ef, $0e
  .byte $ee, $0e
  .byte $dd, $0d
  .byte $55, $05
  .byte $45, $05
  .byte $45, $05
  .byte $45, $04
  .byte $44, $04
  .byte $44, $04
  .byte $44, $04
  .byte $44, $04
  .byte $34, $04
  .byte $34, $04
  .byte $34, $03
  .byte $ee, $0e
  .byte $de, $0e
  .byte $de, $0e
  .byte $de, $0e
  .byte $dd, $0e
  .byte $dd, $0d
  .byte $55, $06
  .byte $55, $06
  .byte $55, $05
  .byte $55, $05
  .byte $55, $05
  .byte $55, $05
  .byte $45, $05
  .byte $45, $05
  .byte $44, $05
  .byte $22, $02
  .byte $22, $02
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
  .byte $4a, $07   ; The last few palette I copied from affine_helper.s / finch.s
  .byte $4e, $07
  .byte $3e, $08
  .byte $3b, $06
  .byte $48, $06
  .byte $39, $05
  .byte $36, $04
  .byte $27, $04
  .byte $23, $02
  .byte $02, $00
  .byte $bc, $0b
  .byte $ab, $0a
  .byte $89, $09
  .byte $69, $08
  .byte $dd, $0d
  .byte $cd, $0d
  .byte $99, $0a
  .byte $78, $08
  .byte $67, $07
  .byte $44, $04
  .byte $34, $04
  .byte $22, $02
  .byte $12, $03

  .else
    .if(USE_MARIO_MAP_AND_TILES)
    
  .byte $44, $0f
  .byte $00, $0e
  .byte $00, $00
  .byte $f6, $06
  .byte $e0, $00
  .byte $f9, $0f
  .byte $e0, $0e
  .byte $6f, $06
  .byte $2f, $00
  .byte $50, $00
  .byte $80, $00
  .byte $a0, $00
  .byte $d0, $00
  .byte $00, $07
  .byte $90, $09
  .byte $06, $00
  .byte $52, $06
  .byte $64, $07
  .byte $a7, $0b
  .byte $96, $0a
  .byte $85, $09
  .byte $dd, $0d
  .byte $66, $06
  .byte $00, $0f
  .byte $ff, $0f
  .byte $f0, $0f
  .byte $00, $0b
  .byte $00, $08
  .byte $bb, $0b
  .byte $c3, $0d
  .byte $80, $0f
  .byte $77, $07
  .byte $b0, $0f
  .byte $22, $02
  .byte $33, $03
  .byte $44, $04
  .byte $55, $05
  .byte $88, $08
  .byte $99, $09
  .byte $aa, $0a
  .byte $cc, $0c
  .byte $ee, $0e    
    
    .else

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
      .endif
  .endif

  .org $D200

  .if(DO_NO_TILE_LOOKUP)
  
  .byte $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $3e, $4a, $4a, $4a, $4e, $5d, $4a, $5b, $5b, $5b, $5b, $46, $5d, $47, $4b, $47, $5a, $47, $59, $5b, $49, $5c, $5c, $59, $57, $57, $5c, $45, $46, $5c, $5b, $57, $4f
  .byte $00, $20, $24, $25, $20, $1e, $1e, $1b, $06, $1b, $29, $29, $22, $1b, $1b, $1b, $1b, $1b, $1e, $29, $20, $25, $24, $24, $1e, $20, $1e, $04, $08, $1b, $1e, $02, $47, $47, $4c, $5d, $5d, $5c, $5d, $5c, $5a, $5c, $47, $47, $5d, $47, $5c, $5a, $5a, $5b, $4b, $47, $44, $57, $57, $6c, $58, $59, $5a, $5a, $5c, $46, $5d, $02
  .byte $00, $1e, $20, $20, $1d, $1e, $1b, $1c, $07, $04, $1e, $1e, $20, $1e, $1e, $1e, $20, $1b, $1b, $29, $1b, $24, $1b, $1b, $24, $1b, $1e, $21, $1b, $1e, $26, $02, $4a, $4a, $4d, $5d, $4a, $5d, $47, $5b, $46, $4c, $49, $5d, $4b, $4a, $5d, $4c, $47, $5a, $59, $59, $59, $5b, $5b, $59, $49, $46, $5b, $59, $49, $5c, $4b, $02
  .byte $00, $24, $20, $1e, $20, $1e, $1b, $1e, $06, $1c, $2a, $22, $22, $1b, $1b, $1b, $1e, $1b, $25, $1b, $24, $1e, $1e, $1b, $1e, $24, $22, $1c, $21, $04, $1e, $02, $4a, $4c, $4a, $47, $5c, $5c, $5c, $5c, $59, $5b, $47, $4c, $47, $5d, $5b, $5b, $57, $5a, $5a, $5a, $5b, $57, $59, $5b, $46, $5c, $44, $5a, $47, $5b, $5c, $02
  .byte $00, $20, $20, $24, $24, $1b, $1e, $24, $1e, $23, $2b, $07, $06, $2e, $0a, $19, $1f, $21, $1b, $1b, $1e, $1b, $1b, $1e, $04, $1f, $1b, $21, $1e, $22, $22, $02, $4b, $5d, $5d, $5d, $5c, $4c, $47, $5b, $47, $47, $47, $47, $5c, $47, $5c, $5b, $49, $5b, $5a, $59, $48, $5d, $44, $46, $5b, $5b, $69, $5a, $44, $46, $4c, $02
  .byte $00, $1b, $20, $25, $1e, $20, $24, $2d, $1e, $24, $1e, $1e, $1b, $1e, $1e, $22, $1e, $21, $04, $04, $1c, $03, $03, $03, $09, $1c, $14, $1e, $1e, $25, $20, $02, $5c, $5a, $4a, $5c, $5d, $47, $5c, $5b, $5d, $49, $47, $47, $47, $4a, $47, $47, $47, $5a, $5d, $5b, $5b, $59, $5c, $46, $5b, $57, $59, $5d, $43, $5d, $48, $02
  .byte $00, $1b, $30, $1b, $1d, $24, $25, $25, $24, $2c, $1e, $1b, $20, $25, $20, $1e, $1b, $1e, $1b, $1b, $22, $1c, $1b, $1b, $1b, $1b, $05, $1b, $1b, $22, $20, $02, $5d, $47, $4a, $5c, $5c, $5b, $59, $5b, $5b, $4a, $4c, $49, $4c, $4a, $4c, $4a, $5c, $49, $47, $44, $59, $43, $5c, $5c, $5a, $5b, $57, $5a, $44, $4b, $4c, $02
  .byte $00, $20, $2c, $20, $26, $24, $1d, $1e, $20, $20, $1b, $20, $20, $2d, $2c, $24, $15, $15, $1e, $1b, $2a, $1e, $2c, $1b, $1b, $1b, $1b, $1f, $1d, $1e, $24, $02, $4b, $4c, $49, $5a, $5a, $5b, $5b, $47, $5d, $47, $4c, $5d, $4d, $5d, $4d, $4d, $4e, $4b, $5c, $5c, $5d, $5c, $4b, $5a, $59, $5a, $43, $48, $4c, $4b, $49, $02
  .byte $00, $2d, $18, $1d, $1d, $13, $1d, $18, $20, $1e, $2c, $20, $26, $20, $20, $20, $12, $1b, $1b, $20, $25, $32, $1b, $1b, $18, $1b, $1b, $1b, $1b, $12, $1e, $02, $47, $5d, $57, $5c, $5a, $6c, $5a, $5b, $5c, $47, $4a, $4a, $4c, $4c, $4c, $4a, $5d, $4c, $47, $47, $5b, $5d, $5c, $57, $5b, $5c, $5b, $48, $4b, $4d, $5b, $02
  .byte $00, $15, $20, $24, $1b, $1b, $1b, $1b, $18, $20, $1e, $20, $1b, $20, $26, $24, $1d, $1b, $1b, $1e, $25, $25, $24, $20, $29, $1b, $26, $1b, $1b, $1b, $12, $02, $44, $49, $5b, $59, $5b, $5d, $5b, $47, $48, $4d, $5d, $5d, $4a, $5c, $5c, $4c, $47, $47, $5b, $5c, $5b, $5c, $5a, $59, $6c, $59, $5a, $4b, $4b, $4a, $5b, $02
  .byte $00, $1e, $24, $24, $24, $1b, $1b, $20, $1d, $25, $2c, $1d, $24, $18, $20, $1d, $15, $1d, $20, $20, $26, $29, $24, $29, $20, $20, $24, $1b, $1b, $20, $1b, $02, $57, $5a, $5b, $55, $5c, $5b, $5a, $4d, $47, $5c, $5b, $5c, $5c, $5d, $5c, $4c, $47, $47, $4a, $5c, $59, $47, $5a, $5a, $5a, $45, $46, $49, $5a, $5c, $5c, $02
  .byte $00, $24, $1d, $20, $20, $24, $24, $20, $24, $26, $20, $25, $20, $18, $1d, $20, $1d, $13, $24, $24, $20, $24, $26, $2d, $24, $1d, $24, $24, $29, $1e, $15, $02, $55, $55, $6c, $44, $4b, $5d, $5d, $48, $47, $4c, $5c, $4a, $4c, $5c, $4a, $47, $47, $47, $4a, $5b, $59, $59, $55, $5c, $5b, $59, $5a, $4b, $47, $5d, $4b, $02
  .byte $00, $1d, $26, $24, $25, $1d, $20, $1d, $24, $2c, $24, $1d, $20, $18, $1b, $18, $1b, $19, $1b, $25, $1d, $2c, $1e, $24, $29, $20, $26, $24, $20, $25, $24, $02, $57, $6a, $45, $49, $5a, $6c, $5d, $5b, $4c, $47, $5d, $47, $5b, $5b, $5c, $5b, $5c, $5d, $5d, $5a, $59, $57, $59, $43, $5b, $59, $44, $5d, $5c, $5d, $5b, $02
  .byte $00, $20, $25, $26, $26, $25, $20, $20, $24, $26, $26, $20, $1b, $1b, $1a, $13, $18, $15, $18, $1b, $29, $2c, $29, $30, $29, $1b, $24, $26, $20, $24, $24, $02, $56, $57, $59, $59, $59, $46, $5d, $44, $4a, $4b, $5d, $5b, $5b, $5a, $55, $6c, $5d, $5b, $57, $5b, $57, $5c, $5b, $5b, $43, $5b, $48, $5c, $44, $5d, $5b, $02
  .byte $00, $15, $20, $24, $20, $18, $1b, $1b, $20, $26, $24, $24, $20, $20, $13, $20, $20, $29, $1a, $25, $2c, $2d, $20, $2c, $24, $20, $20, $24, $1b, $20, $1e, $02, $55, $57, $43, $58, $45, $49, $59, $5b, $46, $4a, $57, $57, $6c, $55, $57, $59, $5a, $5c, $59, $57, $57, $5a, $5a, $5a, $59, $44, $5a, $5c, $57, $57, $59, $02
  .byte $00, $24, $24, $20, $18, $1b, $1b, $1b, $20, $26, $24, $25, $24, $20, $11, $20, $2d, $20, $1d, $14, $13, $29, $30, $24, $20, $20, $24, $24, $20, $1b, $1b, $02, $6c, $45, $5a, $44, $5a, $44, $59, $5b, $5a, $5a, $6b, $6b, $69, $59, $55, $55, $44, $6c, $57, $6b, $59, $55, $6c, $43, $5a, $5c, $43, $55, $59, $5a, $5a, $02
  .byte $00, $20, $20, $20, $1b, $1b, $1b, $1e, $24, $24, $25, $20, $1e, $19, $15, $24, $30, $20, $20, $26, $26, $29, $20, $14, $1d, $1b, $1b, $1b, $1e, $1b, $1b, $02, $42, $55, $42, $5a, $55, $43, $59, $46, $6c, $6b, $6c, $57, $68, $58, $68, $58, $59, $5a, $6c, $59, $55, $6a, $58, $59, $59, $59, $59, $57, $57, $43, $57, $02
  .byte $00, $1e, $1e, $1e, $1d, $14, $18, $15, $12, $12, $1a, $17, $12, $12, $20, $1b, $26, $1b, $1b, $1d, $29, $25, $29, $19, $20, $20, $24, $1b, $1b, $1f, $08, $02, $6c, $55, $5a, $45, $58, $55, $59, $6c, $6b, $6a, $59, $68, $68, $6a, $6c, $46, $59, $45, $5a, $43, $5a, $56, $44, $48, $45, $59, $5a, $44, $5a, $43, $43, $02
  .byte $00, $1e, $1b, $1b, $12, $20, $12, $15, $1a, $17, $20, $25, $1a, $20, $1b, $20, $13, $1b, $1b, $20, $24, $1e, $25, $24, $24, $1e, $22, $1e, $1e, $09, $1e, $02, $58, $43, $59, $55, $69, $57, $69, $6c, $68, $6b, $6c, $69, $6c, $56, $44, $45, $44, $43, $5a, $6c, $6c, $45, $59, $45, $57, $59, $6c, $57, $45, $5b, $57, $02
  .byte $00, $22, $1e, $14, $22, $1e, $24, $20, $25, $24, $1d, $1e, $18, $1b, $1b, $19, $1e, $1d, $1b, $1b, $20, $1b, $24, $25, $25, $20, $1e, $20, $22, $21, $1b, $02, $6c, $56, $56, $6c, $6c, $69, $67, $69, $67, $65, $54, $6a, $54, $56, $42, $48, $44, $6c, $57, $58, $43, $55, $57, $43, $6b, $6c, $43, $59, $6c, $44, $59, $02
  .byte $00, $1f, $14, $1e, $1c, $12, $14, $1e, $24, $20, $15, $1a, $15, $15, $13, $2d, $1b, $1b, $24, $18, $20, $1d, $20, $25, $29, $20, $20, $22, $24, $06, $1f, $02, $56, $43, $42, $59, $68, $55, $54, $67, $54, $67, $69, $42, $55, $59, $58, $45, $59, $57, $5a, $44, $55, $59, $43, $56, $59, $59, $58, $59, $46, $5a, $6c, $02
  .byte $00, $07, $51, $1e, $04, $1c, $28, $1f, $1b, $31, $1f, $1e, $1b, $1e, $1e, $1b, $1b, $1b, $1d, $1b, $18, $1b, $24, $25, $24, $25, $29, $26, $20, $1e, $1c, $02, $46, $56, $5a, $69, $55, $67, $55, $53, $68, $65, $54, $54, $55, $56, $6c, $42, $55, $44, $44, $6c, $57, $5a, $44, $59, $43, $48, $5b, $48, $59, $5a, $55, $02
  .byte $00, $1c, $1b, $1e, $1e, $22, $08, $06, $50, $5e, $05, $2b, $06, $1f, $08, $2a, $1b, $1b, $1b, $1b, $20, $20, $18, $1b, $20, $20, $24, $2c, $1e, $1e, $1e, $02, $43, $43, $43, $54, $6c, $6a, $68, $69, $66, $67, $54, $67, $42, $42, $42, $6c, $43, $59, $6b, $6b, $42, $43, $57, $45, $46, $45, $45, $5a, $5a, $55, $55, $02
  .byte $00, $51, $08, $1f, $1e, $1e, $24, $21, $09, $20, $62, $21, $3d, $1e, $1b, $0b, $1e, $1e, $1b, $1b, $20, $1b, $1d, $20, $24, $20, $29, $2c, $24, $20, $1b, $02, $43, $43, $44, $6c, $56, $69, $6c, $67, $53, $65, $54, $56, $55, $40, $56, $6c, $58, $6a, $58, $6a, $6c, $43, $44, $43, $46, $5a, $5a, $44, $57, $69, $57, $02
  .byte $00, $07, $09, $22, $1f, $08, $1e, $5f, $1e, $04, $27, $27, $30, $27, $04, $2f, $1e, $1b, $1b, $18, $20, $20, $1d, $1b, $18, $20, $20, $24, $1e, $18, $3c, $02, $59, $6a, $57, $6c, $67, $69, $64, $64, $53, $68, $56, $53, $42, $42, $6c, $56, $55, $43, $55, $43, $58, $42, $59, $46, $59, $59, $5a, $5a, $55, $69, $56, $02
  .byte $00, $21, $21, $1f, $08, $1c, $07, $09, $08, $1b, $1e, $23, $18, $1e, $29, $24, $05, $03, $09, $22, $24, $24, $1d, $1b, $1d, $1e, $1d, $20, $1b, $1c, $1f, $02, $69, $5a, $59, $65, $10, $0f, $68, $69, $54, $65, $66, $42, $55, $43, $58, $42, $6c, $56, $55, $42, $42, $42, $46, $59, $59, $59, $55, $6b, $67, $65, $6a, $02
  .byte $00, $1c, $07, $1f, $28, $1e, $1c, $23, $1c, $21, $1e, $1e, $1e, $1a, $22, $1b, $1c, $07, $23, $1e, $24, $13, $20, $20, $20, $24, $20, $20, $24, $1b, $27, $02, $45, $55, $68, $67, $69, $53, $56, $54, $68, $53, $54, $58, $55, $44, $59, $55, $55, $54, $6b, $58, $43, $55, $57, $69, $57, $55, $6a, $10, $68, $65, $66, $02
  .byte $00, $28, $52, $1f, $07, $1b, $50, $60, $23, $1e, $2c, $2c, $2e, $1b, $1b, $1e, $32, $09, $24, $24, $18, $1b, $1d, $1e, $24, $20, $25, $26, $20, $1b, $2b, $02, $55, $69, $68, $67, $58, $6a, $54, $67, $54, $53, $53, $42, $55, $56, $54, $68, $68, $53, $68, $56, $55, $6c, $6a, $10, $54, $69, $10, $6c, $69, $64, $67, $02
  .byte $00, $22, $07, $1c, $50, $1b, $1e, $28, $1e, $24, $2a, $18, $1b, $1b, $18, $1b, $24, $24, $25, $24, $20, $1a, $24, $24, $26, $29, $29, $20, $1e, $1e, $61, $02, $54, $69, $56, $55, $66, $54, $68, $66, $53, $10, $53, $53, $68, $56, $55, $56, $54, $67, $58, $54, $58, $53, $6b, $65, $69, $68, $53, $56, $10, $0f, $10, $02
  .byte $00, $5f, $1c, $08, $62, $0a, $23, $32, $2c, $1e, $1b, $25, $1e, $1d, $25, $32, $2d, $29, $2c, $2c, $24, $1d, $26, $24, $26, $29, $20, $1e, $20, $1e, $12, $02, $56, $67, $68, $55, $54, $68, $65, $64, $68, $66, $65, $68, $58, $54, $54, $56, $68, $56, $56, $43, $56, $54, $53, $54, $54, $67, $54, $68, $65, $0f, $68, $02
  .byte $00, $1b, $1e, $1e, $1e, $1e, $1e, $1e, $22, $20, $1e, $20, $1b, $1b, $24, $24, $24, $20, $1d, $24, $13, $26, $24, $25, $26, $25, $20, $1b, $24, $05, $1e, $02, $56, $64, $55, $69, $68, $65, $54, $53, $68, $66, $66, $64, $53, $68, $56, $54, $54, $54, $69, $55, $54, $55, $55, $65, $68, $66, $53, $54, $0e, $66, $0f, $02
  .byte $3e, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $6d, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
  .byte $44, $43, $55, $6c, $43, $44, $6c, $58, $56, $6c, $56, $43, $6c, $58, $43, $58, $43, $56, $6b, $54, $6c, $67, $64, $66, $64, $54, $42, $6c, $54, $55, $54, $6e, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $3e
  .byte $44, $58, $59, $56, $44, $3f, $44, $56, $44, $58, $55, $43, $45, $45, $58, $55, $42, $68, $6c, $43, $6a, $6b, $58, $56, $43, $3f, $46, $56, $54, $69, $53, $02, $00, $1f, $1b, $1f, $21, $1e, $24, $1e, $1b, $1e, $13, $1e, $1b, $24, $24, $12, $24, $24, $1e, $1b, $1e, $1b, $2a, $3b, $51, $1f, $1e, $5f, $05, $04, $13, $02
  .byte $44, $43, $43, $45, $44, $40, $59, $5a, $42, $6c, $45, $46, $48, $45, $44, $57, $55, $56, $58, $56, $54, $6b, $56, $44, $43, $45, $58, $55, $55, $54, $54, $02, $00, $1e, $19, $15, $1e, $20, $20, $1e, $1e, $13, $18, $1b, $11, $24, $20, $05, $24, $12, $1d, $1e, $1e, $24, $2e, $08, $22, $2a, $0b, $28, $08, $1b, $19, $02
  .byte $45, $42, $5a, $45, $46, $46, $47, $58, $5b, $45, $43, $44, $46, $46, $5a, $55, $56, $68, $59, $58, $6b, $43, $58, $45, $56, $56, $59, $58, $59, $55, $55, $02, $00, $24, $20, $1e, $1a, $1d, $1b, $1b, $1b, $13, $12, $1b, $22, $15, $29, $1b, $1d, $19, $1e, $20, $20, $24, $24, $63, $2a, $21, $38, $3a, $27, $17, $1e, $02
  .byte $42, $44, $42, $45, $59, $45, $44, $59, $5b, $43, $46, $44, $59, $44, $6b, $6c, $55, $42, $58, $42, $43, $42, $55, $56, $40, $45, $43, $44, $55, $55, $68, $02, $00, $20, $1d, $1b, $19, $1a, $1e, $11, $18, $15, $1b, $1b, $20, $25, $20, $1b, $13, $11, $20, $1e, $20, $25, $22, $22, $2e, $29, $1e, $2a, $29, $12, $1b, $02
  .byte $44, $42, $58, $5a, $57, $44, $6c, $59, $45, $45, $49, $5b, $46, $6c, $57, $55, $58, $58, $44, $44, $58, $43, $43, $48, $46, $59, $48, $59, $54, $6c, $55, $02, $00, $24, $25, $24, $20, $2c, $1f, $18, $18, $18, $13, $1b, $20, $1e, $1d, $15, $12, $12, $1e, $1d, $24, $24, $25, $24, $35, $1b, $1b, $1b, $1b, $1e, $1e, $02
  .byte $56, $44, $59, $58, $46, $59, $57, $58, $46, $5c, $57, $59, $57, $59, $59, $57, $6c, $58, $58, $44, $44, $5b, $58, $46, $5b, $45, $5a, $57, $42, $43, $56, $02, $00, $1d, $24, $26, $30, $20, $18, $1b, $1b, $1b, $18, $20, $1b, $20, $25, $14, $1d, $12, $1b, $1b, $20, $20, $24, $25, $22, $20, $25, $18, $1e, $20, $2c, $02
  .byte $6b, $58, $44, $57, $58, $6c, $45, $46, $46, $5d, $43, $5c, $46, $5a, $59, $43, $43, $59, $55, $5a, $6c, $43, $5a, $44, $46, $48, $5a, $45, $43, $43, $57, $02, $00, $1b, $1d, $20, $1d, $1d, $1a, $20, $1b, $1b, $1b, $24, $1a, $1e, $17, $1d, $12, $24, $20, $1e, $1d, $25, $24, $24, $20, $1e, $1e, $1e, $2c, $2c, $26, $02
  .byte $46, $46, $5a, $6c, $43, $59, $48, $44, $44, $48, $5d, $5d, $59, $57, $5a, $5b, $57, $57, $42, $45, $43, $44, $59, $44, $48, $5c, $59, $59, $5a, $55, $42, $02, $00, $1d, $20, $1d, $15, $1e, $1e, $20, $1d, $1b, $20, $20, $1b, $1d, $24, $20, $12, $1b, $1d, $1d, $1b, $24, $20, $1b, $1e, $20, $1d, $29, $26, $20, $25, $02
  .byte $44, $56, $55, $57, $6c, $45, $43, $43, $5c, $5c, $59, $5c, $5c, $6b, $57, $58, $59, $46, $5a, $43, $5a, $56, $59, $43, $5a, $57, $55, $59, $6c, $57, $68, $02, $00, $20, $20, $1d, $24, $1e, $1b, $1e, $20, $1e, $24, $18, $20, $20, $24, $15, $1d, $12, $1e, $1b, $1b, $20, $20, $1b, $1b, $1b, $24, $20, $34, $2c, $20, $02
  .byte $45, $42, $58, $44, $43, $5a, $59, $5a, $46, $47, $59, $47, $59, $5b, $5b, $46, $43, $45, $5a, $43, $55, $57, $57, $57, $5a, $57, $6c, $58, $57, $58, $69, $02, $00, $20, $24, $1e, $1d, $1e, $1e, $1b, $1b, $1e, $1b, $1b, $1b, $1d, $1d, $24, $12, $14, $24, $20, $20, $1d, $1e, $20, $24, $20, $24, $26, $24, $20, $2c, $02
  .byte $59, $43, $46, $42, $44, $59, $5a, $58, $45, $46, $44, $47, $5b, $57, $59, $46, $58, $5c, $57, $58, $57, $6c, $43, $58, $43, $55, $6b, $43, $43, $44, $58, $02, $00, $20, $24, $20, $1e, $1e, $1b, $1e, $15, $1b, $24, $24, $24, $20, $20, $20, $13, $1d, $20, $24, $25, $24, $1d, $20, $26, $24, $26, $26, $32, $20, $1e, $02
  .byte $58, $58, $43, $57, $5a, $58, $44, $57, $46, $4c, $5d, $5c, $57, $6c, $45, $57, $5c, $43, $59, $6a, $42, $55, $44, $59, $57, $55, $58, $42, $5a, $58, $6b, $02, $00, $24, $1d, $1d, $20, $1e, $1b, $18, $1b, $1d, $1d, $24, $26, $15, $14, $26, $1e, $24, $14, $25, $29, $25, $20, $20, $26, $29, $26, $20, $32, $1b, $1e, $02
  .byte $6c, $56, $43, $59, $59, $46, $43, $44, $48, $45, $5b, $5b, $5a, $49, $59, $5b, $5a, $48, $59, $5b, $6c, $43, $45, $5b, $44, $5b, $55, $5a, $56, $55, $6b, $02, $00, $20, $18, $20, $1b, $1e, $20, $1e, $20, $1d, $18, $1d, $20, $1d, $29, $24, $26, $20, $25, $14, $20, $24, $29, $26, $24, $24, $20, $2c, $20, $1b, $20, $02
  .byte $42, $45, $55, $42, $44, $5a, $43, $44, $5d, $44, $5b, $59, $5b, $57, $5a, $5b, $5c, $5c, $59, $43, $5a, $45, $57, $58, $57, $55, $59, $58, $57, $43, $6c, $02, $00, $29, $20, $20, $1e, $1b, $1b, $1d, $1e, $15, $24, $24, $26, $24, $29, $1a, $2c, $20, $24, $24, $1b, $2c, $25, $24, $24, $20, $1e, $20, $1b, $1b, $20, $02
  .byte $58, $6b, $59, $57, $43, $43, $6c, $45, $43, $59, $5b, $59, $55, $5c, $5b, $58, $6c, $5b, $5b, $59, $55, $69, $6b, $55, $56, $43, $59, $45, $56, $45, $58, $02, $00, $15, $20, $1b, $20, $1e, $1e, $1b, $18, $20, $25, $24, $20, $20, $26, $20, $24, $1d, $2c, $30, $24, $20, $1e, $26, $24, $24, $1d, $1e, $26, $1b, $20, $02
  .byte $6c, $42, $42, $42, $44, $58, $45, $46, $5b, $43, $5c, $5a, $44, $59, $43, $57, $59, $5a, $44, $57, $59, $55, $6b, $6c, $42, $59, $55, $56, $59, $57, $57, $02, $00, $1b, $1e, $1b, $20, $1b, $13, $1b, $15, $1b, $20, $20, $24, $25, $26, $1e, $20, $20, $1e, $24, $24, $1e, $20, $24, $1e, $1d, $22, $1e, $20, $1b, $20, $02
  .byte $58, $45, $44, $6c, $42, $46, $5b, $45, $59, $57, $46, $5b, $5a, $46, $44, $59, $57, $43, $46, $59, $5a, $58, $59, $43, $46, $56, $57, $58, $55, $59, $68, $02, $00, $24, $25, $1b, $14, $15, $1e, $1b, $18, $1e, $26, $25, $24, $1d, $20, $1b, $20, $20, $20, $24, $20, $1b, $1b, $24, $20, $2a, $23, $20, $1c, $1e, $24, $02
  .byte $6c, $58, $55, $43, $48, $5b, $45, $5a, $44, $45, $57, $46, $47, $44, $59, $5a, $5a, $43, $59, $5b, $6c, $57, $42, $5b, $67, $44, $57, $6c, $58, $55, $55, $02, $00, $1b, $1b, $1b, $1b, $1d, $1b, $18, $1b, $20, $20, $15, $14, $20, $20, $1b, $24, $26, $24, $20, $1b, $1d, $1e, $1b, $1e, $37, $22, $5e, $28, $1c, $33, $02
  .byte $55, $55, $59, $46, $44, $45, $5a, $4b, $57, $5a, $59, $40, $5d, $5a, $5c, $5c, $59, $44, $57, $58, $5a, $59, $57, $59, $6c, $57, $44, $58, $6b, $68, $55, $02, $00, $20, $22, $29, $24, $24, $20, $1e, $13, $16, $12, $20, $24, $20, $1e, $1d, $20, $24, $26, $25, $24, $1e, $1b, $20, $22, $31, $22, $27, $22, $41, $38, $02
  .byte $69, $54, $45, $45, $43, $44, $45, $5a, $59, $57, $44, $40, $5b, $5c, $46, $5c, $57, $57, $5c, $44, $43, $59, $58, $59, $6c, $42, $5a, $6a, $6b, $56, $6c, $02, $00, $1e, $1e, $24, $24, $2c, $20, $14, $1b, $24, $20, $1e, $20, $1d, $1b, $24, $24, $1d, $25, $26, $25, $20, $1e, $1e, $1f, $23, $60, $22, $0c, $37, $3c, $02
  .byte $6b, $42, $46, $48, $46, $48, $5a, $44, $47, $45, $47, $49, $5c, $5b, $59, $6c, $55, $55, $57, $6c, $6c, $6c, $43, $56, $57, $48, $56, $68, $6b, $55, $69, $02, $00, $1b, $20, $1e, $20, $25, $30, $29, $24, $25, $20, $20, $1b, $1b, $20, $1d, $1d, $24, $20, $24, $24, $1e, $20, $1b, $08, $03, $5e, $1e, $21, $61, $1c, $02
  .byte $42, $44, $45, $49, $48, $5b, $45, $49, $5c, $57, $46, $5b, $5d, $5b, $5c, $6c, $69, $57, $44, $6c, $5a, $6b, $59, $55, $59, $6c, $6c, $67, $6c, $58, $54, $02, $00, $1b, $1e, $22, $20, $1b, $24, $1b, $1b, $1b, $18, $1b, $20, $20, $1d, $17, $20, $20, $20, $26, $20, $1b, $1e, $21, $1e, $5e, $1e, $28, $1c, $0d, $1e, $02
  .byte $45, $4b, $43, $43, $57, $6c, $44, $46, $59, $49, $5a, $48, $59, $5b, $57, $6c, $6c, $57, $44, $59, $44, $6c, $6c, $56, $67, $55, $69, $69, $56, $58, $54, $02, $00, $20, $1e, $20, $1e, $20, $1d, $25, $19, $12, $15, $1b, $17, $17, $20, $14, $13, $1b, $1b, $20, $1d, $1b, $1b, $04, $5f, $06, $1e, $21, $1e, $36, $1c, $02
  .byte $42, $45, $46, $5a, $45, $5b, $44, $5a, $5a, $5c, $5b, $5a, $5d, $44, $5b, $57, $57, $43, $6b, $59, $58, $68, $55, $54, $56, $6c, $58, $56, $56, $53, $6c, $02, $00, $1b, $12, $18, $1b, $18, $15, $13, $24, $24, $20, $20, $20, $24, $20, $20, $14, $11, $18, $20, $18, $1b, $1b, $05, $21, $08, $1c, $1e, $05, $1f, $1e, $02
  .byte $57, $44, $57, $44, $46, $5c, $40, $47, $45, $49, $4b, $48, $4c, $4c, $5b, $57, $5a, $43, $54, $59, $59, $68, $6c, $59, $59, $69, $55, $53, $6b, $58, $6c, $02, $00, $20, $1b, $1b, $1a, $1b, $1b, $18, $20, $29, $20, $20, $20, $20, $18, $1e, $1b, $1d, $1a, $1a, $1e, $1b, $20, $22, $1c, $1c, $04, $1c, $2f, $1b, $1e, $02
  .byte $44, $48, $48, $45, $46, $49, $5c, $46, $46, $47, $5d, $4a, $4b, $5d, $59, $5a, $57, $58, $57, $58, $57, $59, $43, $59, $54, $6c, $42, $58, $42, $58, $54, $02, $00, $1b, $1b, $20, $1b, $20, $24, $1b, $1e, $25, $20, $1b, $20, $24, $1d, $1b, $20, $26, $1e, $1b, $1d, $22, $1e, $1e, $04, $05, $08, $39, $37, $1e, $2a, $02
  .byte $40, $3f, $49, $5c, $47, $4c, $5b, $4a, $49, $5d, $5c, $5d, $5b, $5c, $6b, $5c, $5b, $5b, $58, $58, $5b, $56, $57, $58, $46, $59, $56, $69, $6a, $54, $55, $02, $00, $24, $20, $24, $24, $24, $20, $1b, $24, $29, $26, $20, $26, $20, $1e, $1b, $1d, $20, $20, $1d, $18, $24, $22, $22, $21, $1c, $0a, $27, $28, $0c, $06, $02
  .byte $44, $4c, $46, $46, $46, $49, $48, $5d, $49, $47, $5d, $5a, $6c, $59, $59, $45, $59, $55, $58, $42, $5a, $43, $43, $5a, $6c, $58, $54, $56, $43, $54, $6a, $02, $00, $25, $24, $25, $26, $24, $25, $29, $1a, $20, $24, $26, $24, $26, $20, $1b, $1e, $1b, $1e, $20, $12, $24, $24, $22, $5e, $1c, $04, $21, $22, $2e, $1e, $02
  .byte $46, $4b, $43, $5c, $5a, $4a, $5c, $47, $5b, $5a, $59, $59, $6c, $5a, $5a, $5c, $5a, $6c, $59, $57, $43, $59, $45, $45, $42, $55, $56, $56, $56, $44, $43, $02, $00, $24, $22, $24, $24, $20, $24, $1e, $24, $30, $20, $1d, $1d, $1d, $1b, $1d, $20, $20, $20, $24, $1d, $1a, $2b, $22, $22, $1e, $1b, $1e, $1e, $24, $22, $02
  .byte $45, $44, $5c, $5b, $44, $49, $47, $5b, $5d, $5a, $6c, $43, $5b, $44, $6c, $45, $6c, $6b, $44, $6c, $43, $59, $5b, $59, $59, $57, $45, $59, $58, $45, $43, $02, $00, $1e, $1b, $24, $1e, $1e, $1d, $20, $29, $26, $2d, $24, $20, $24, $20, $1b, $1b, $1b, $15, $1a, $15, $03, $16, $16, $24, $1e, $18, $1e, $1e, $25, $1e, $02
  .byte $4f, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $3e, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02

  .else 
  
  
    .if(DO_4BIT)
        .if(DRAW_TILED_PERSPECTIVE)
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  .byte $11, $11, $11, $11
  
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  .byte $22, $22, $22, $22
  
        .else
  .byte $11, $11, $11, $11
  .byte $22, $22, $22, $22
  .byte $33, $33, $33, $33
  .byte $44, $44, $44, $44
  .byte $55, $55, $55, $55
  .byte $66, $66, $66, $66
  .byte $77, $77, $77, $77
  .byte $88, $88, $88, $88
      
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
  .byte $12, $34, $56, $78
        .endif
      
    .else
;        .if(USE_MARIO_MAP_AND_TILES)
        
; FIXME: Add tile data here! or load it via a ROM bank!
        
;        .else
  
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
;        .endif

    .endif
    
  .endif

  ; manual TILEMAP
  .org $E200
;  .byte 9, 1, 2, 3
;  .byte 3, 2, 1, 0
;  .byte 5, 4, 5, 4
;  .byte 6, 7, 8, 9

  .if(DO_4BIT)
  
  .byte 0, 1
  .byte 1, 0
  
  .else
  
    .if(USE_MARIO_MAP_AND_TILES)

; FIXME!
; FIXME!
; FIXME!

  .byte $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $02, $02, $02, $02, $03, $03, $03, $03, $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $00, $00, $00, $00, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $03, $05, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $03, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $03, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $09, $0a, $0b, $0c, $0d, $0d, $0d, $0d, $0d, $0d, $0e, $0f, $10, $11, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $03, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $12, $13, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $02, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $02, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $12, $13, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $02, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $02, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $17, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $02, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $02, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $17, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $02, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $02, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $17, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $03, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $01, $07, $08, $08, $08, $08, $08, $08, $08, $08, $08, $17, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $03, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $01, $07, $08, $08, $08, $08, $08, $08, $08, $08, $17, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $03, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $01, $07, $08, $08, $08, $08, $08, $08, $08, $18, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $03, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $01, $07, $08, $08, $08, $08, $08, $08, $08, $19, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $07, $08, $08, $08, $08, $08, $08, $18, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $1a, $1a, $1a, $1a, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $07, $08, $08, $08, $08, $08, $08, $19, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $1b, $1c, $1d, $1e, $1f, $1f, $1f, $1f, $20, $21, $22, $23, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $24, $14, $14, $14, $24, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $07, $08, $08, $08, $08, $08, $18, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $25, $26, $27, $28, $29, $08, $08, $08, $08, $08, $08, $2a, $2b, $2c, $2d, $2e, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $07, $08, $08, $08, $08, $08, $19, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $2f, $30, $31, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $32, $33, $2d, $2e, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $24, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $03, $07, $08, $08, $08, $08, $34, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $2f, $35, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $32, $33, $2d, $2e, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $03, $07, $08, $08, $08, $08, $36, $14, $14, $14, $14, $14, $14, $14, $14, $14, $37, $38, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $32, $33, $39, $3a, $14, $14, $14, $14, $24, $14, $14, $14, $24, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $15, $16, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    
    
    .else
    
  
        .if(1)

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
        .else
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
    
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4

  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4

  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
  .byte  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9
  .byte  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4,  9,  4
      .endif
    .endif
  .endif

    
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"
    
    

    .org $fffa
    .word nmi
    .word reset
    .word irq
    
    .if(USE_TABLE_FILES)
        .binary "fx_tests/tables/x_subpixel_positions_in_map_low1.bin"
        .binary "fx_tests/tables/x_subpixel_positions_in_map_low2.bin"
        .binary "fx_tests/tables/x_subpixel_positions_in_map_high1.bin"
        .binary "fx_tests/tables/x_subpixel_positions_in_map_high2.bin"
        .binary "fx_tests/tables/y_subpixel_positions_in_map_low1.bin"
        .binary "fx_tests/tables/y_subpixel_positions_in_map_low2.bin"
        .binary "fx_tests/tables/y_subpixel_positions_in_map_high1.bin"
        .binary "fx_tests/tables/y_subpixel_positions_in_map_high2.bin"
        .binary "fx_tests/tables/x_pixel_positions_in_map_low1.bin"
        .binary "fx_tests/tables/x_pixel_positions_in_map_low2.bin"
        .binary "fx_tests/tables/x_pixel_positions_in_map_high1.bin"
        .binary "fx_tests/tables/x_pixel_positions_in_map_high2.bin"
        .binary "fx_tests/tables/y_pixel_positions_in_map_low1.bin"
        .binary "fx_tests/tables/y_pixel_positions_in_map_low2.bin"
        .binary "fx_tests/tables/y_pixel_positions_in_map_high1.bin"
        .binary "fx_tests/tables/y_pixel_positions_in_map_high2.bin"
        .binary "fx_tests/tables/x_sub_pixel_steps_low1.bin"
        .binary "fx_tests/tables/x_sub_pixel_steps_low2.bin"
        .binary "fx_tests/tables/x_sub_pixel_steps_high1.bin"
        .binary "fx_tests/tables/x_sub_pixel_steps_high2.bin"
        .binary "fx_tests/tables/y_sub_pixel_steps_low1.bin"
        .binary "fx_tests/tables/y_sub_pixel_steps_low2.bin"
        .binary "fx_tests/tables/y_sub_pixel_steps_high1.bin"
        .binary "fx_tests/tables/y_sub_pixel_steps_high2.bin"
    .endif
    .if(!DO_NO_TILE_LOOKUP && USE_MARIO_MAP_AND_TILES && !DO_4BIT)
        .binary "fx_tests/textures/SnesMarioKart/mario_tile_map.bin"
        .binary "fx_tests/textures/SnesMarioKart/mario_tile_pixel_data.bin"  ; WARNING!! ONLY 11kB!!
    .endif
    
