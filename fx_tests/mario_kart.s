
; To build (from fx_tests):       cl65 -t cx16 -o SD/MARIO-KART.PRG mario_kart.s
; To run   (from fx_tests/SD):    x16emu.exe -ram 2048 -prg MARIO-KART.PRG -run

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

DRAW_BITMAP_TEXT = 0
DRAW_CURSOR_KEYS = 0
USE_POLYGON_FILLER_FOR_BITMAP = 1

PLAYER_FORWARD_SPEED = 8
PLAYER_BACKWARD_SPEED = 4
USE_KEYBOARD_INPUT = 1

BACKGROUND_COLOR = 2;   ; Black in this palette
COLOR_TEXT  = $06       ; Background color = 0 (transparent), foreground color ??
MAP_WIDTH = 128
MAP_HEIGHT = 128
TEXTURE_WIDTH = 64      ; FIXME: this actually the number of bytes in a tile! (we should use TILE_WIDTH/TILE_HEIGHT)
TEXTURE_HEIGHT = 171    ; FIXME: We have 171 unique tiles, we should name the variable/constant that way!

NR_OF_BYTES_PER_LINE = 320
    
    
TILE_WIDTH = 8
TILE_HEIGHT = 8


TOP_MARGIN = 12
LEFT_MARGIN = 16
VSPACING = 10

MAPDATA_VRAM_ADDRESS = $13000   ; should be aligned to 1kB
TILEDATA_VRAM_ADDRESS = $17000  ; should be aligned to 1kB
KARTDATA_VRAM_ADDRESS = $12C00  ; right after the bitmap of 320x240 (32x24 pixels = 1024 pixels)
KART_WIDTH = 32
KART_HEIGHT = 24


DESTINATION_PICTURE_POS_X = 32
DESTINATION_PICTURE_POS_Y = 32
DESTINATION_SND_PICTURE_POS_Y = 120

DESTINATION_PICTURE_WIDTH = 256
DESTINATION_PICTURE_HEIGHT = 80


; Mode7 projection: 
;    https://www.coranac.com/tonc/text/mode7.htm
;    https://gamedev.stackexchange.com/questions/24957/doing-an-snes-mode-7-affine-transform-effect-in-pygame



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
BAD_VALUE                 = $33

CODE_ADDRESS              = $36 ; 37

LOAD_ADDRESS              = $38 ; 39
STORE_ADDRESS             = $3A ; 3B
VRAM_ADDRESS              = $3C ; 3D ; 3E

TABLE_ROM_BANK            = $41
VIEWING_ANGLE             = $42

TILE_X                    = $43
TILE_Y                    = $44

; Used only by (slow) 16-bit multiplier (multiply_16bits)
MULTIPLIER                = $47 ; 48
MULTIPLICAND              = $49 ; 4A
PRODUCT                   = $4B ; 4C ; 4D ; 4E

; Used by the (slow) 24-bit divider (divide_24bits)
DIVIDEND                  = $4F ; 50 ; 51  ; the thing you want to divide (e.g. 100 /) . This will also the result after the division
DIVISOR                   = $52 ; 53 ; 54  ; the thing you divide by (e.g. / 10)
REMAINDER                 = $55 ; 56 ; 57


CAMERA_WORLD_X_POSITION   = $58 ; 59
CAMERA_WORLD_Y_POSITION   = $5A ; 5B

PLAYER_WORLD_X_POSITION   = $5C ; 5D
PLAYER_WORLD_X_SUBPOS     = $5E
PLAYER_WORLD_Y_POSITION   = $5F ; 60
PLAYER_WORLD_Y_SUBPOS     = $61


AFFINE_SETTINGS           = $62

DO_DRAW_OVERVIEW_MAP      = $63

NR_OF_KBD_KEY_CODE_BYTES  = $64     ; Required by keyboard.s

DELTA_X                   = $65 ; 66
DELTA_X_SUB               = $67
DELTA_Y                   = $68 ; 69
DELTA_Y_SUB               = $6A

BITMAP_RAM_BANK_START      = $74
CHARACTER_INDEX_TO_DRAW    = $75
BITMAP_TEXT_TO_DRAW        = $76 ; 77
BITMAP_TO_DRAW = BITMAP_TEXT_TO_DRAW
BITMAP_TEXT_LENGTH         = $78
BITMAP_TEXT_LENGTH_PIXELS = BITMAP_TEXT_LENGTH
BITMAP_WIDTH_PIXELS        = $79
BITMAP_HEIGHT_PIXELS       = $7A
BITMAP_X_POS               = $7B ; 7C


; ---------- RAM addresses used during LOADING of SD files ------

SOURCE_TABLE_ADDRESS     = $5F00

; ---------------------------------------------------------------

; ------------ RAM addresses used during the DEMO ---------------


KEYBOARD_KEY_CODE_BUFFER = $5DE0   ; 32 bytes (can be much less, since compact key codes are used now) -> used by keyboard.s
KEYBOARD_STATE           = $5E00   ; 128 bytes (state for each key of the keyboard)
KEYBOARD_EVENTS          = $5E80   ; 128 bytes (event for each key of the keyboard)

; RAM addresses
; FIXME: is there enough space for COPY_ROW_CODE?
COPY_ROW_CODE               = $7800


; === Banked RAM addresses ===


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

BITMAP_TEXT              = $AC00
BITMAP = BITMAP_TEXT

TILEMAP_ROM_BANK  = 25   ; Our tilemap starts at ROM Bank 25
TILEDATA_ROM_BANK = 26   ; Our tiledata starts at ROM Bank 26


start:

    ; Disable interrupts 
;    sei
    
    ; Setup stack
;    ldx #$ff
;    txs

    jsr setup_vera_for_bitmap_and_tile_map
    jsr init_keyboard
    
    jsr clear_screen_slow
    jsr copy_palette_from_index_16
    jsr copy_tables_to_banked_ram
    jsr copy_tiledata_to_high_vram
    jsr copy_tilemap_to_high_vram
    
    jsr copy_mario_on_kart_pixels_to_high_vram
    jsr copy_kart_palette
; FIXME: enable the sprite LATER!
; FIXME: enable the sprite LATER!
; FIXME: enable the sprite LATER!
    jsr setup_mario_on_kart_sprite
    
    
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
        
        ; -- DEMO TITLE --
        
        lda #end_of_demo_title_text-demo_title_text
        sta BITMAP_TEXT_LENGTH
        
        lda #<demo_title_text
        sta BITMAP_TEXT_TO_DRAW
        lda #>demo_title_text
        sta BITMAP_TEXT_TO_DRAW+1
        
        lda #DEMO_TITLE_RAM_BANK_START
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
    
    
    ; Test speed of perspective style transformation
    
    jsr generate_copy_row_code
    
    lda #1
    sta DO_DRAW_OVERVIEW_MAP
    jsr draw_overview_map
    
    stz DO_DRAW_OVERVIEW_MAP
    jsr draw_tiled_perspective
  
loop:
  jmp loop

  

; ====================================== OVERVIEW MAP ========================================
    
draw_overview_map:

    ; The camera position should be in the middle of the map (X = 512) and back in the Y-direction (Y = -422)

    lda #0
    sta CAMERA_WORLD_X_POSITION
    lda #2
    sta CAMERA_WORLD_X_POSITION+1
    
    lda #<(-422)
    sta CAMERA_WORLD_Y_POSITION
    lda #>(-422)
    sta CAMERA_WORLD_Y_POSITION+1
    
    ; FIXME: set variable that we have to use a SINGLE/STATIC shot (not the TABLE FILES!)
    
    
    jsr tiled_perspective_fast


    rts
    
; ==================================== / OVERVIEW MAP ========================================

; ====================================== TILED PERSPECTIVE ========================================
  
draw_tiled_perspective:

    ; -- Initial world position --
    
    lda #0
    sta PLAYER_WORLD_X_SUBPOS
    lda #183
    sta PLAYER_WORLD_X_POSITION
    lda #3
    sta PLAYER_WORLD_X_POSITION+1
    
    lda #0
    sta PLAYER_WORLD_Y_SUBPOS
    lda #255
    sta PLAYER_WORLD_Y_POSITION
    lda #2
    sta PLAYER_WORLD_Y_POSITION+1


    lda #128
    sta VIEWING_ANGLE
move_or_turn_around:

    jsr get_user_input


    ; -- Update world --

    .if(USE_KEYBOARD_INPUT)

        ; Our default velocity is 0
        stz DELTA_X_SUB
        stz DELTA_X
        stz DELTA_X+1
        
        stz DELTA_Y_SUB
        stz DELTA_Y
        stz DELTA_Y+1

        ; -- Left arrow key --
        ldx #KEY_CODE_LEFT_ARROW
        lda KEYBOARD_STATE, x
        beq left_arrow_key_down_handled

        ; FIXME: implement a better turning technique!
        dec VIEWING_ANGLE
left_arrow_key_down_handled:

        ; -- Right arrow key --
        ldx #KEY_CODE_RIGHT_ARROW
        lda KEYBOARD_STATE, x
        beq right_arrow_key_down_handled
        
        ; FIXME: implement a better turning technique!
        inc VIEWING_ANGLE
right_arrow_key_down_handled:

        ; -- Up arrow key --
        ldx #KEY_CODE_UP_ARROW
        lda KEYBOARD_STATE, x
        beq up_arrow_key_down_handled
        
        ; - Forward movement -
        ; Ymove = +(cos(angle)*72)/256 * PLAYER_FORWARD_SPEED
        ; Xmove = -(sin(angle)*72)/256 * PLAYER_FORWARD_SPEED
        ; Note: our cosine_values and sine_values have a max of 72!
    
        ldx VIEWING_ANGLE
        
        ; +cos(angle)*72/256 * PLAYER_FORWARD_SPEED

        lda cosine_values_low, x
        sta MULTIPLICAND
        lda cosine_values_high, x
        sta MULTIPLICAND+1

        lda #<PLAYER_FORWARD_SPEED
        sta MULTIPLIER
        lda #>PLAYER_FORWARD_SPEED
        sta MULTIPLIER+1

        jsr multiply_16bits_signed
        
        lda PRODUCT
        sta DELTA_Y_SUB
        lda PRODUCT+1
        sta DELTA_Y
        lda PRODUCT+2
        sta DELTA_Y+1
        
        ; 0-sin(angle)*72/256 * PLAYER_FORWARD_SPEED
        
        lda sine_values_low, x
        sta MULTIPLICAND
        lda sine_values_high, x
        sta MULTIPLICAND+1

        lda #<PLAYER_FORWARD_SPEED
        sta MULTIPLIER
        lda #>PLAYER_FORWARD_SPEED
        sta MULTIPLIER+1

        jsr multiply_16bits_signed
        
        sec
        lda #0
        sbc PRODUCT
        sta DELTA_X_SUB
        lda #0
        sbc PRODUCT+1
        sta DELTA_X
        lda #0
        sbc PRODUCT+2
        sta DELTA_X+1
        
        
up_arrow_key_down_handled:

        ; -- Down arrow key --
        ldx #KEY_CODE_DOWN_ARROW
        lda KEYBOARD_STATE, x
        beq down_arrow_key_down_handled
        
        ; - Backward movement -
        ; Ymove = -(cos(angle)*72)/256 * PLAYER_BACKWARD_SPEED
        ; Xmove = +(sin(angle)*72)/256 * PLAYER_BACKWARD_SPEED
        ; Note: our cosine_values and sine_values have a max of 72!
    
        ldx VIEWING_ANGLE
        
        ; -cos(angle)*72/256 * PLAYER_BACKWARD_SPEED

        lda cosine_values_low, x
        sta MULTIPLICAND
        lda cosine_values_high, x
        sta MULTIPLICAND+1

        lda #<PLAYER_BACKWARD_SPEED
        sta MULTIPLIER
        lda #>PLAYER_BACKWARD_SPEED
        sta MULTIPLIER+1

        jsr multiply_16bits_signed
        
        sec
        lda #0
        sbc PRODUCT
        sta DELTA_Y_SUB
        lda #0
        sbc PRODUCT+1
        sta DELTA_Y
        lda #0
        sbc PRODUCT+2
        sta DELTA_Y+1
        
        ; 0-sin(angle)*72/256 * PLAYER_BACKWARD_SPEED
        
        lda sine_values_low, x
        sta MULTIPLICAND
        lda sine_values_high, x
        sta MULTIPLICAND+1

        lda #<PLAYER_BACKWARD_SPEED
        sta MULTIPLIER
        lda #>PLAYER_BACKWARD_SPEED
        sta MULTIPLIER+1

        jsr multiply_16bits_signed
        
        lda PRODUCT
        sta DELTA_X_SUB
        lda PRODUCT+1
        sta DELTA_X
        lda PRODUCT+2
        sta DELTA_X+1
        
down_arrow_key_down_handled:

    .else
        ; FIXME: implement auto movement!
    .endif


    clc
    lda PLAYER_WORLD_X_SUBPOS
    adc DELTA_X_SUB
    sta PLAYER_WORLD_X_SUBPOS
    lda PLAYER_WORLD_X_POSITION
    adc DELTA_X
    sta PLAYER_WORLD_X_POSITION
    lda PLAYER_WORLD_X_POSITION+1
    adc DELTA_X+1
    sta PLAYER_WORLD_X_POSITION+1
    
    clc
    lda PLAYER_WORLD_Y_SUBPOS
    adc DELTA_Y_SUB
    sta PLAYER_WORLD_Y_SUBPOS
    lda PLAYER_WORLD_Y_POSITION
    adc DELTA_Y
    sta PLAYER_WORLD_Y_POSITION
    lda PLAYER_WORLD_Y_POSITION+1
    adc DELTA_Y+1
    sta PLAYER_WORLD_Y_POSITION+1


    ; -- Render world --

    lda VIEWING_ANGLE
    sta RAM_BANK


    ; Calculate the CAMERA position from the PLAYER position + VIEWING_ANGLE
            
    ldx VIEWING_ANGLE
    
    ; Ycam = Yplayer - (cos(angle)*72)
    ; Xcam = Xplayer + (sin(angle)*72)
    ; Note: our cosine_values and sine_values have a max of 72!
    
    
    ; FIXME: we should probably also put the sub-position into the subpixel position of VERA! (more precise/smoother)
    ; FIXME: if we do that we also have to make the cosine/sine values more precise!

    sec
    lda PLAYER_WORLD_Y_POSITION
    sbc cosine_values_low, x
    sta CAMERA_WORLD_Y_POSITION
    lda PLAYER_WORLD_Y_POSITION+1
    sbc cosine_values_high, x
    sta CAMERA_WORLD_Y_POSITION+1
    
    clc
    lda PLAYER_WORLD_X_POSITION
    adc sine_values_low, x
    sta CAMERA_WORLD_X_POSITION
    lda PLAYER_WORLD_X_POSITION+1
    adc sine_values_high, x
    sta CAMERA_WORLD_X_POSITION+1
    

    ; FIXME: set variable that we have to use a DYNAMIC shot (using the TABLE FILES!)
    
    jsr tiled_perspective_fast

    .if(DRAW_BITMAP_TEXT)
        jsr draw_all_bitmap_texts
        jsr draw_cursor_keys
    .endif

    jmp move_or_turn_around

    rts

    
get_user_input:

    ; FIXME: SPEED: clearing *all* keyboard events costs time...
    jsr clear_keyboard_events   ; before retrieving the key codes, we clear all previous events
    jsr retrieve_keyboard_key_codes
    jsr update_keyboard_state   ; this also records all keyboard events

    rts
    


tiled_perspective_256x80_8bpp_message: 
    .asciiz "Tiled perspective 256x80 (8bpp) "
tiled_perspective_256x80_4bpp_message: 
    .asciiz "Tiled perspective 256x80 (4bpp) "

    
; For tiled perspective we need to set the x and y coordinate within the tilemap for each pixel row on the screen. 
; We also have to set the sub pixel increment for each pixel row on the screen.
; We generated this using the python script (see same folder) and put the data here.
    
; IMPORTANT: the positions and steps below are used ONLY for the OVERVIEW map
    
x_subpixel_positions_in_map_low:
    .byte 128,0,0,128,0,0,0,128,128,128,0,128,128,0,128,128,0,0,0,128,0,0,128,128,128,0,128,128,0,0,0,0,0,128,128,128,128,0,128,0,0,128,128,0,0,0,0,0,0,128,0,128,128,0,0,128,0,128,0,128,0,0,0,0,128,0,128,0,128,128,128,0,0,128,128,128,128,128,0,128
x_subpixel_positions_in_map_high:
    .byte 204,183,152,110,60,0,186,107,19,178,73,214,91,216,76,184,28,120,204,24,93,154,207,253,36,68,92,110,121,125,122,113,97,74,45,10,225,178,124,65,0,184,107,25,193,99,0,151,41,181,61,191,60,181,40,150,0,100,196,31,118,200,21,94,162,227,30,86,137,184,227,10,45,75,102,125,144,159,171,178
y_subpixel_positions_in_map_low:
    .byte 0,128,128,0,0,0,128,0,0,0,128,128,0,0,128,0,0,0,128,0,0,0,128,0,0,0,0,0,0,128,128,128,0,0,0,0,128,0,128,0,0,0,128,128,128,0,0,0,128,0,0,128,128,0,128,128,0,128,128,0,128,128,128,128,128,0,0,0,128,0,128,128,128,0,128,0,0,0,128,128
y_subpixel_positions_in_map_high:
    .byte 0,91,136,136,90,0,121,200,236,230,182,94,222,54,102,113,85,20,173,35,116,162,172,149,91,0,131,230,40,74,77,49,247,158,39,147,225,19,40,34,0,194,105,246,104,193,0,37,49,37,0,194,109,1,124,225,48,103,136,148,137,105,52,234,139,24,144,244,68,129,170,192,195,180,145,93,22,189,82,214
x_pixel_positions_in_map_low:
    .byte 236,240,244,248,252,0,3,7,11,14,18,21,25,28,32,35,39,42,45,49,52,55,58,61,65,68,71,74,77,80,83,86,89,92,95,98,100,103,106,109,112,114,117,120,122,125,128,130,133,135,138,140,143,145,148,150,153,155,157,160,162,164,167,169,171,173,176,178,180,182,184,187,189,191,193,195,197,199,201,203
x_pixel_positions_in_map_high:
    .byte 4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
y_pixel_positions_in_map_low:
    .byte 150,168,186,204,222,240,1,18,35,52,69,86,102,119,135,151,167,183,198,214,229,244,3,18,33,48,62,76,91,105,119,133,146,160,174,187,200,214,227,240,253,9,22,34,47,59,72,84,96,108,120,131,143,155,166,177,189,200,211,222,233,244,255,9,20,31,41,51,62,72,82,92,102,112,122,132,142,151,161,170
y_pixel_positions_in_map_high:
    .byte 1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
x_sub_pixel_steps_low:
    .byte 76,61,45,30,15,0,241,226,211,197,182,168,154,140,126,113,99,86,72,59,46,33,20,8,251,238,226,214,202,190,178,166,154,142,131,119,108,97,86,74,63,53,42,31,20,10,0,245,235,225,215,205,195,185,175,165,156,146,136,127,118,108,99,90,81,72,63,54,45,37,28,19,11,2,250,242,233,225,217,209
x_sub_pixel_steps_high:
    .byte 12,12,12,12,12,12,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,8,8,8,8,8,8
y_sub_pixel_steps_low:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
y_sub_pixel_steps_high:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    
    
tiled_perspective_fast:

    ; Setup FROM and TO VRAM addresses
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

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
    
    
    ; Setting base addresses and map size
    
    lda #(TILEDATA_VRAM_ADDRESS >> 9)
    and #$FC   ; only the 6 highest bits of the address can be set
    ora #%00000010  ; 1 for Clip
    sta VERA_FX_TILEBASE
    
    lda #(MAPDATA_VRAM_ADDRESS >> 9)
    and #$FC   ; only the 6 highest bits of the address can be set
    ora #%00000011  ; Map size = 11 (128x128 map)
    sta VERA_FX_MAPBASE
    
    lda #%00100011  ; cache fill enabled = 1, affine helper mode (with tile lookup)
    ora #%01000000  ; blit write = 1
    sta VERA_FX_CTRL
    

    ldx #0
    
tiled_perspective_copy_next_row_1:
    
    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL

    lda #%00110000           ; Setting auto-increment value to 4 byte increment (=%0011)
    sta VERA_ADDR_BANK
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
        lda X_SUB_PIXEL_STEPS_LOW, x
        sta VERA_FX_X_INCR_L          ; X increment low
        
        lda X_SUB_PIXEL_STEPS_HIGH, x
        ; Note: the x32 is packed into the table-data
        sta VERA_FX_X_INCR_H
        
        lda Y_SUB_PIXEL_STEPS_LOW, x
        sta VERA_FX_Y_INCR_L
        
        lda Y_SUB_PIXEL_STEPS_HIGH, x
        ; Note: the x32 is packed into the table-data
        sta VERA_FX_Y_INCR_H
            
        ; Setting the position
        
        lda #%00001001           ; DCSEL=4, ADDRSEL=1
        sta VERA_CTRL

        lda X_PIXEL_POSITIONS_IN_MAP_LOW, x
        clc
        adc CAMERA_WORLD_X_POSITION
        sta VERA_FX_X_POS_L       ; X pixel position low [7:0]
        lda X_PIXEL_POSITIONS_IN_MAP_HIGH, x
        adc CAMERA_WORLD_X_POSITION+1
        ora X_SUBPIXEL_POSITIONS_IN_MAP_LOW, x
        sta VERA_FX_X_POS_H        ; X subpixel position[0], X pixel position high [10:8]
        
        lda Y_PIXEL_POSITIONS_IN_MAP_LOW, x
        clc
        adc CAMERA_WORLD_Y_POSITION
        sta VERA_FX_Y_POS_L        ; Y pixel position low [7:0]
        lda Y_PIXEL_POSITIONS_IN_MAP_HIGH, x
        adc CAMERA_WORLD_Y_POSITION+1
        ora Y_SUBPIXEL_POSITIONS_IN_MAP_LOW, x
        ora #%01000000           ; Reset cache byte index = 1
        sta VERA_FX_Y_POS_H      ; Y subpixel position[0], Reset cache byte index = 1, Y pixel position high [10:8]
        
        
        ; Setting the sub position
        
        lda #%00001011           ; DCSEL=5, ADDRSEL=1
        sta VERA_CTRL
        
        lda X_SUBPIXEL_POSITIONS_IN_MAP_HIGH, x
        sta VERA_FX_X_POS_S      ; X subpixel increment [8:1]
        
        lda Y_SUBPIXEL_POSITIONS_IN_MAP_HIGH, x
        sta VERA_FX_Y_POS_S      ; Y subpixel increment [8:1]
    
        bra done_setting_up_increments_and_positions
    
setup_increment_and_positions_for_overview_map:
        ; We now set the increments
        lda x_sub_pixel_steps_low, x
        sta VERA_FX_X_INCR_L     ; X increment low
        
        lda x_sub_pixel_steps_high, x
        ; Note: the x32 is packed into the table-data
        sta VERA_FX_X_INCR_H
        
        lda y_sub_pixel_steps_low, x
        sta VERA_FX_Y_INCR_L
        
        lda y_sub_pixel_steps_high, x
        ; Note: the x32 is packed into the table-data
        sta VERA_FX_Y_INCR_H
            
        ; Setting the position
        
        lda #%00001001           ; DCSEL=4, ADDRSEL=1
        sta VERA_CTRL

        lda x_pixel_positions_in_map_low, x
        clc
        adc CAMERA_WORLD_X_POSITION
        sta VERA_FX_X_POS_L      ; X pixel position low [7:0]
        lda x_pixel_positions_in_map_high, x
        adc CAMERA_WORLD_X_POSITION+1
        ora x_subpixel_positions_in_map_low, x
        sta VERA_FX_X_POS_H      ; X subpixel position[0], X pixel position high [10:8]
        
        lda y_pixel_positions_in_map_low, x
        clc
        adc CAMERA_WORLD_Y_POSITION
        sta VERA_FX_Y_POS_L      ; Y pixel position low [7:0]
        lda y_pixel_positions_in_map_high, x
        adc CAMERA_WORLD_Y_POSITION+1
        ora y_subpixel_positions_in_map_low, x
        ora #%01000000           ; Reset cache byte index = 1
        sta VERA_FX_Y_POS_H      ; Y subpixel position[0], Reset cache byte index = 1, Y pixel position high [10:8]
        
        
        ; Setting the sub position
        
        lda #%00001011           ; DCSEL=5, ADDRSEL=1
        sta VERA_CTRL
        
        lda x_subpixel_positions_in_map_high, x
        sta VERA_FX_X_POS_S      ; X subpixel increment [8:1]
        
        lda y_subpixel_positions_in_map_high, x
        sta VERA_FX_Y_POS_S      ; Y subpixel increment [8:1]
        
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
    sta VERA_FX_CTRL
    
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

    
    ; We use the cache for writing, we do not want a mask to we store 0 (stz)

    ; -- stz VERA_DATA0 ($9F23)
    lda #$9C               ; stz ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte

    inx
    cpx #DESTINATION_PICTURE_WIDTH/4   ; 64*4=256 copy pixels written to VERA
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

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; We use A as color
    lda #BACKGROUND_COLOR
    
    ldy #240
vera_wr_fill_bitmap_col_once:
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
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once2
    inx
    cpx #64                  ; The right part of the screen is 320 - 256 = 64 pixels
    bne vera_wr_fill_bitmap_once2
    
    rts


; ================================== loading mario data =====================================

    
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
    
    
copy_kart_palette:

    ; Starting at palette VRAM address: at palette 200

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<(VERA_PALETTE+208*2)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE+208*2)
    sta VERA_ADDR_HIGH

    ldy #0
next_kart_packed_color:
    lda mario_on_kart_palette, y
    sta VERA_DATA0
    iny
    cpy #13*2                    ; FIXME: hardcoded amount of colors 
    bne next_kart_packed_color

    rts


copy_mario_on_kart_pixels_to_high_vram:  

    lda #<mario_on_kart_pixels
    sta DATA_PTR_ZP
    lda #>mario_on_kart_pixels
    sta DATA_PTR_ZP+1 

    ; TODO: we are ASSUMING here that KARTDATA_VRAM_ADDRESS has its bit16 set to 1!!
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #<(KARTDATA_VRAM_ADDRESS)
    sta VERA_ADDR_LOW
    lda #>(KARTDATA_VRAM_ADDRESS)
    sta VERA_ADDR_HIGH
    
    ldx #0
next_kart_pixel_row_high_vram:  

    ldy #0
next_kart_horizontal_pixel_high_vram:
    lda (DATA_PTR_ZP),y

    sta VERA_DATA0

    iny
    cpy #KART_WIDTH
    bne next_kart_horizontal_pixel_high_vram
    inx
    
    ; Adding KART_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #KART_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    cpx #KART_HEIGHT
    bne next_kart_pixel_row_high_vram
    
    
    ; Filling in the bottom with 00 pixels (to 32 pixel height)

    ldx #0
next_kart_zero_pixel_row_high_vram:  

    ldy #0
next_kart_zero_horizontal_pixel_high_vram:
    stz VERA_DATA0

    iny
    cpy #KART_WIDTH
    bne next_kart_zero_horizontal_pixel_high_vram
    inx
    
    ; Adding KART_WIDTH to the previous data address
    clc
    lda DATA_PTR_ZP
    adc #KART_WIDTH
    sta DATA_PTR_ZP
    lda DATA_PTR_ZP+1
    adc #0
    sta DATA_PTR_ZP+1

    cpx #32-KART_HEIGHT
    bne next_kart_zero_pixel_row_high_vram
    
    
    rts


setup_mario_on_kart_sprite:

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; NOTE: we are using sprite #1 here (not #0)
    lda #<(VERA_SPRITES+1*8)
    sta VERA_ADDR_LOW
    lda #>(VERA_SPRITES+1*8)
    sta VERA_ADDR_HIGH
    
    ; Address (12:5)
    lda #<(KARTDATA_VRAM_ADDRESS>>5)
    sta VERA_DATA0

    ; Mode,	-	, Address (16:13)
    lda #<(KARTDATA_VRAM_ADDRESS>>13)
    ora #%10000000 ; 8bpp
    sta VERA_DATA0
    
    ; X (7:0)
    lda #<(160-11)
    sta VERA_DATA0
    
    ; X (9:8)
    lda #0
    sta VERA_DATA0

    ; Y (7:0)
    lda #<(70)
    sta VERA_DATA0

    ; X (9:8)
    lda #0
    sta VERA_DATA0
    
    ; Collision mask	Z-depth	V-flip	H-flip
    lda #%00001100 ; z-depth = 3
    sta VERA_DATA0

    ; Sprite height,	Sprite width,	Palette offset
    lda #%10101101 ; 32x32, 13*16 = 208 palette offset
    sta VERA_DATA0
    
    
    rts
    
    
mario_tiles_filename:      .byte    "tbl/mario-tiles.bin" 
end_mario_tiles_filename:

load_mario_tiles_table:

    lda #(end_mario_tiles_filename-mario_tiles_filename) ; Length of filename
    ldx #<mario_tiles_filename      ; Low byte of Fname address
    ldy #>mario_tiles_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    jsr SETLFS
 
    lda #0
    ldx #<SOURCE_TABLE_ADDRESS
    ldy #>SOURCE_TABLE_ADDRESS
    jsr LOAD
    bcc mario_tiles_table_file_loaded
; FIXME: do proper error handling!
    stp
    
mario_tiles_table_file_loaded:

    rts
        

copy_tiledata_to_high_vram:    
    
    jsr load_mario_tiles_table
    
    lda #<SOURCE_TABLE_ADDRESS
    sta LOAD_ADDRESS
    lda #>SOURCE_TABLE_ADDRESS
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
    
    rts
end_of_copy_tiledata_to_high_vram:

    
    
mario_map_filename:      .byte    "tbl/mario-map.bin" 
end_mario_map_filename:

load_mario_map_table:

    lda #(end_mario_map_filename-mario_map_filename) ; Length of filename
    ldx #<mario_map_filename      ; Low byte of Fname address
    ldy #>mario_map_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    jsr SETLFS
 
    lda #0
    ldx #<SOURCE_TABLE_ADDRESS
    ldy #>SOURCE_TABLE_ADDRESS
    jsr LOAD
    bcc mario_map_table_file_loaded
; FIXME: do proper error handling!
    stp

mario_map_table_file_loaded:

    rts
    

copy_tilemap_to_high_vram:    
    
    ; We copy a 128x128 tilemap to high VRAM

    jsr load_mario_map_table
    
    lda #<SOURCE_TABLE_ADDRESS
    sta LOAD_ADDRESS
    lda #>SOURCE_TABLE_ADDRESS
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
    
    
    rts
end_of_copy_tilemap_to_high_vram:
    
    
pers_filename:      .byte    "tbl/pers-a.bin" 
end_pers_filename:

; This will load a PERS table using the TABLE_ROM_BANK (which starts at 1)
load_perspective_table:

    clc
    lda #'a'                  ; 'a' = $61
    adc TABLE_ROM_BANK
    
    ; This is a bit a of HACK/WORKAROUD: we are subtracting again from TABLE_ROM_BANK (so it always starts with 1)
    sec
    sbc #1                    ; since the TABLE_ROM_BANK starts at 1, we substract 1 from it
    
    sta end_pers_filename-5 ; 5 characters from the end is the 'a'

    lda #(end_pers_filename-pers_filename) ; Length of filename
    ldx #<pers_filename      ; Low byte of Fname address
    ldy #>pers_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    jsr SETLFS
 
    lda #0
    ldx #<SOURCE_TABLE_ADDRESS
    ldy #>SOURCE_TABLE_ADDRESS
    jsr LOAD
    bcc perspective_table_file_loaded
; FIXME: do proper error handling!
    stp
    lda TABLE_ROM_BANK
    
perspective_table_file_loaded:

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

  
    lda #<SOURCE_TABLE_ADDRESS
    sta LOAD_ADDRESS
    lda #>SOURCE_TABLE_ADDRESS
    sta LOAD_ADDRESS+1

    lda #<($A000)        ; We store at Ax00
    sta STORE_ADDRESS
    clc
    lda #>($A000)
    adc TMP1
    sta STORE_ADDRESS+1
    
    jsr load_perspective_table

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

    rts
end_of_copy_tables_to_banked_ram:
    
    
    
    ; --------------------------------- BITMAP TEXTS --------------------------------------
    
FIRMWARE_X_POS = 100
FIRMWARE_Y_POS = 19
FIRMWARE_RAM_BANK_START = 0
vera_firmware_version_text:
    .byte 22, 5, 18, 1, 0, 6, 9, 18, 13, 23, 1, 18, 5, 0, 22, 27, 37, 27, 37, 27 ; "VERA FIRMWARE V0.0.0"
end_of_vera_firmware_version_text:

DEMO_TITLE_X_POS = 98
DEMO_TITLE_Y_POS = 9
DEMO_TITLE_RAM_BANK_START = 10
demo_title_text:
    .byte 6, 24, 0, 4, 5, 13, 15, 38, 0, 39, 13, 1, 18, 9, 15, 0, 11, 1, 18, 20, 39 ; 'FX DEMO: "MARIO KART"'
end_of_demo_title_text:

    ; ------------------------------- / BITMAP TEXTS --------------------------------------


    ; --------------------------------- BITMAPS --------------------------------------
    
; FIXME: this might be lower if less than 3 bitmap texts are drawn!
LEFT_DOWN_RIGHT_KEY_RAM_BANK_START = 15
LEFT_DOWN_RIGHT_KEY_Y_POS = 219
LEFT_DOWN_RIGHT_KEY_X_POS = 140
    
UP_KEY_RAM_BANK_START = 15+13
UP_KEY_Y_POS = LEFT_DOWN_RIGHT_KEY_Y_POS-14
UP_KEY_X_POS = LEFT_DOWN_RIGHT_KEY_X_POS+14

    ; ------------------------------- / BITMAPS --------------------------------------

    
draw_all_bitmap_texts:

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
    
    ; -- DEMO TITLE --

    lda #DEMO_TITLE_RAM_BANK_START
    sta BITMAP_RAM_BANK_START
    
    lda #(end_of_demo_title_text-demo_title_text)*6
    sta BITMAP_TEXT_LENGTH_PIXELS

    lda #<(320*DEMO_TITLE_Y_POS+DEMO_TITLE_X_POS)
    sta VRAM_ADDRESS
    lda #>(320*DEMO_TITLE_Y_POS+DEMO_TITLE_X_POS)
    sta VRAM_ADDRESS+1

    jsr draw_bitmap_text_to_screen

    rts

    
    
    
    
; This sets up VERA for a bitmap (320x240) in layer 0 and a tile map (8x8) in layer 1

setup_vera_for_bitmap_and_tile_map:

    ; lda #%00010001           ; Enable Layer 0, Enable VGA
    ; lda #%00100001           ; Enable Layer 1, Enable VGA
    ; lda #%00110001           ; Enable Layer 0 and 1, Enable VGA
    ; lda #%01000001           ; Enable sprites, Enable VGA
    
    lda VERA_DC_VIDEO
    and #%00000011
    bne output_mode_is_set
    
    ; If no output mode is, we turn on VGA
    lda VERA_DC_VIDEO
    ora #%00000001             ; Enable VGA
    sta VERA_DC_VIDEO
    
output_mode_is_set:
    lda VERA_DC_VIDEO
    ora #%01010000           ; Enable Layer 0 and sprites
    and #%11011111           ; Disable layer 1
    sta VERA_DC_VIDEO

    lda #0                   ; Set Horizontal and vertical scoll to 0
    sta VERA_L0_HSCROLL_L
    sta VERA_L0_HSCROLL_H
    sta VERA_L0_VSCROLL_L
    sta VERA_L0_VSCROLL_H
    
    sta VERA_L1_HSCROLL_L
    sta VERA_L1_HSCROLL_H
    sta VERA_L1_VSCROLL_L
    sta VERA_L1_VSCROLL_H

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; -- Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; VERA.layer0.config = (4 + 3) ; enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    ; VERA.layer0.tilebase = ; set new tilebase for layer 0 (0x00000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($000 >> 1)
    sta VERA_L0_TILEBASE
    
    ; -- Layer 1 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; TODO: use TILE_MAP_HEIGHT and TILE_MAP_WIDTH to determine this value!
    lda #%10100000           ; Set map height/width to 64/128, and Tile mode 1 bpp (16 color text mode)
    sta VERA_L1_CONFIG
    
    lda #($1B0 >> 1)         ; Set mapbase for layer 1 to 0x1B000. This also sets the tile width and height to 8 px
    sta VERA_L1_MAPBASE
    
    lda #($1F0 >> 1)         ; Set tilebase for layer 1 to 0x1F000. This also sets the tile width and height to 8 px
    sta VERA_L1_TILEBASE

    rts

    
    
; Python script to generate sine and cosine bytes: for CAMERA displacement (and also for directional movement)
;   import math
;   cycle=256
;   ampl=72   # -72 to +72
;   [(int(math.sin(float(i)/cycle*2.0*math.pi)*ampl) % 256) for i in range(cycle)]
;   [(int(math.sin(float(i)/cycle*2.0*math.pi)*ampl) // 256) for i in range(cycle)]
;   [(int(math.cos(float(i)/cycle*2.0*math.pi)*ampl) % 256) for i in range(cycle)]
;   [(int(math.cos(float(i)/cycle*2.0*math.pi)*ampl) // 256) for i in range(cycle)]
    
.feature force_range
sine_values_low:
    .byte 0, 1, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24, 25, 27, 29, 30, 32, 33, 35, 37, 38, 40, 41, 42, 44, 45, 47, 48, 49, 50, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 65, 66, 67, 67, 68, 68, 69, 69, 70, 70, 70, 71, 71, 71, 71, 71, 71, 72, 71, 71, 71, 71, 71, 71, 70, 70, 70, 69, 69, 68, 68, 67, 67, 66, 65, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 50, 49, 48, 47, 45, 44, 42, 41, 40, 38, 37, 35, 33, 32, 30, 29, 27, 25, 24, 22, 20, 19, 17, 15, 14, 12, 10, 8, 7, 5, 3, 1, 0, 255, 253, 251, 249, 248, 246, 244, 242, 241, 239, 237, 236, 234, 232, 231, 229, 227, 226, 224, 223, 221, 219, 218, 216, 215, 214, 212, 211, 209, 208, 207, 206, 204, 203, 202, 201, 200, 199, 198, 197, 196, 195, 194, 193, 192, 191, 191, 190, 189, 189, 188, 188, 187, 187, 186, 186, 186, 185, 185, 185, 185, 185, 185, 184, 185, 185, 185, 185, 185, 185, 186, 186, 186, 187, 187, 188, 188, 189, 189, 190, 191, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 206, 207, 208, 209, 211, 212, 214, 215, 216, 218, 219, 221, 223, 224, 226, 227, 229, 231, 232, 234, 236, 237, 239, 241, 242, 244, 246, 248, 249, 251, 253, 255
sine_values_high:
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
cosine_values_low:
    .byte 72, 71, 71, 71, 71, 71, 71, 70, 70, 70, 69, 69, 68, 68, 67, 67, 66, 65, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 50, 49, 48, 47, 45, 44, 42, 41, 40, 38, 37, 35, 33, 32, 30, 29, 27, 25, 24, 22, 20, 19, 17, 15, 14, 12, 10, 8, 7, 5, 3, 1, 0, 255, 253, 251, 249, 248, 246, 244, 242, 241, 239, 237, 236, 234, 232, 231, 229, 227, 226, 224, 223, 221, 219, 218, 216, 215, 214, 212, 211, 209, 208, 207, 206, 204, 203, 202, 201, 200, 199, 198, 197, 196, 195, 194, 193, 192, 191, 191, 190, 189, 189, 188, 188, 187, 187, 186, 186, 186, 185, 185, 185, 185, 185, 185, 184, 185, 185, 185, 185, 185, 185, 186, 186, 186, 187, 187, 188, 188, 189, 189, 190, 191, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 206, 207, 208, 209, 211, 212, 214, 215, 216, 218, 219, 221, 223, 224, 226, 227, 229, 231, 232, 234, 236, 237, 239, 241, 242, 244, 246, 248, 249, 251, 253, 255, 0, 1, 3, 5, 7, 8, 10, 12, 14, 15, 17, 19, 20, 22, 24, 25, 27, 29, 30, 32, 33, 35, 37, 38, 40, 41, 42, 44, 45, 47, 48, 49, 50, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 65, 66, 67, 67, 68, 68, 69, 69, 70, 70, 70, 71, 71, 71, 71, 71, 71
cosine_values_high:
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

    
    
    
; -- FIXME: SLOW HACK! --
MULTIPLIER_XOR_MULTIPLICAND_NEGATED = TMP2
multiply_16bits_signed:
    stz MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    
    lda MULTIPLIER+1
    bpl multiplier_is_positive
    
    ; We negate the multiplier
    sec
    lda #0
    sbc MULTIPLIER
    sta MULTIPLIER
    lda #0
    sbc MULTIPLIER+1
    sta MULTIPLIER+1
    
    lda #1
    sta MULTIPLIER_XOR_MULTIPLICAND_NEGATED
multiplier_is_positive:

    lda MULTIPLICAND+1
    bpl multiplcand_is_positive

    ; We negate the multiplicand
    sec
    lda #0
    sbc MULTIPLICAND
    sta MULTIPLICAND
    lda #0
    sbc MULTIPLICAND+1
    sta MULTIPLICAND+1
    
    lda MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    eor #1
    sta MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    
multiplcand_is_positive:

    jsr multiply_16bits
    
    lda MULTIPLIER_XOR_MULTIPLICAND_NEGATED
    beq signed_product_is_valid
    
    ;We negate the product
    sec
    lda #0
    sbc PRODUCT
    sta PRODUCT
    lda #0
    sbc PRODUCT+1
    sta PRODUCT+1
    lda #0
    sbc PRODUCT+2
    sta PRODUCT+2
    lda #0
    sbc PRODUCT+3
    sta PRODUCT+3
    
signed_product_is_valid:

    rts
    
; https://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product
multiply_16bits:
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
    
    .include "../utils/x16.s"
    .include "../utils/i2c_ca65.s"
    .include "../utils/keyboard.s"
    .include "../fx_tests/utils/demo.s"

; FIXME: REMOVE this is the OLD name!
PALLETE:

palette_data:
  
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
    
end_of_palette_data:

    
    ; Picture of Mario on Kart (22x24px) -> made 32x24 with 5px padding on the left and right
    
mario_on_kart_pixels:
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $0a, $0a, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $0a, $02, $02, $02, $02, $0a, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $02, $02, $02, $02, $02, $02, $02, $02, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $03, $03, $02, $02, $02, $02, $02, $02, $02, $02, $03, $03, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $0a, $04, $0a, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $0a, $04, $0a, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $0a, $04, $04, $0a, $03, $03, $03, $03, $03, $03, $03, $03, $0a, $04, $04, $0a, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $0a, $05, $04, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $04, $05, $0a, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $05, $04, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $04, $05, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $05, $04, $0a, $0a, $0a, $0a, $0a, $0a, $04, $05, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $0a, $05, $05, $02, $02, $02, $02, $05, $05, $0a, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $02, $02, $0b, $0b, $02, $02, $02, $02, $0b, $0b, $02, $02, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $0a, $02, $02, $02, $0c, $0c, $0a, $0a, $0a, $0a, $0c, $0c, $02, $02, $02, $0a, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $0a, $03, $02, $03, $0c, $0a, $04, $04, $04, $04, $0a, $0c, $03, $02, $03, $0a, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $0a, $03, $0a, $0a, $04, $05, $05, $05, $05, $04, $0a, $0a, $03, $0a, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $09, $09, $09, $09, $0a, $04, $05, $05, $05, $05, $05, $05, $04, $0a, $09, $09, $09, $09, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $0a, $0a, $0a, $0a, $0c, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0c, $0a, $0a, $0a, $0a, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $0a, $08, $08, $08, $08, $0a, $0a, $07, $07, $07, $07, $07, $07, $07, $07, $0a, $0a, $08, $08, $08, $08, $0a, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $0a, $09, $09, $09, $09, $0a, $07, $0a, $06, $06, $06, $06, $06, $06, $0a, $07, $0a, $09, $09, $09, $09, $0a, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $0a, $0a, $0a, $0a, $0a, $0a, $07, $0a, $07, $07, $07, $07, $07, $07, $0a, $07, $0a, $0a, $0a, $0a, $0a, $0a, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $0a, $0a, $0a, $0a, $0a, $0a, $07, $0a, $01, $06, $06, $06, $06, $01, $0a, $07, $0a, $0a, $0a, $0a, $0a, $0a, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $0a, $0a, $0a, $0a, $0a, $0a, $03, $03, $07, $07, $07, $07, $07, $07, $03, $03, $0a, $0a, $0a, $0a, $0a, $0a, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $0a, $0a, $0a, $0a, $00, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $0a, $00, $0a, $0a, $0a, $0a, $00, $00, $00, $00, $00, $00

mario_on_kart_palette:
  .byte $f0, $0f  ; dummy color (yellow) = transparant
  .byte $00, $00 ; #01
  .byte $00, $0f ; #02
  .byte $00, $0a ; #03
  .byte $a8, $0e ; #04
  .byte $75, $0a ; #05
  .byte $77, $07 ; #06
  .byte $ee, $0c ; #07
  .byte $66, $04 ; #08
  .byte $44, $02 ; #09
  .byte $22, $00 ; #0a
  .byte $8f, $00 ; #0b
  .byte $0e, $00 ; #0c
