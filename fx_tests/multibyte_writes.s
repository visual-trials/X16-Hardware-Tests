
DO_SPEED_TEST = 1
DO_4_BYTES_PER_WRITE = 1

    .if (DO_4_BYTES_PER_WRITE)
BACKGROUND_COLOR = 57  ; We use color 57 (instead of 2), since it 57 contains both a high nibble and low nibble values (used for testing blit nibble masks)
    .else
BACKGROUND_COLOR = 06; Blue 
    .endif
FOREGROUND_COLOR = 1

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
BANK_TESTING              = $12   
BAD_VALUE                 = $1A

CODE_ADDRESS              = $1D ; 1E ; TODO: this can probably share the address of LOAD_ADDRESS

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


; RAM addresses
CLEAR_COLUMN_CODE        = $7E00    ; 152 * 3 bytes + 1 byte = 457 bytes


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

    .if(DO_SPEED_TEST)
    .if(DO_4_BYTES_PER_WRITE)
      jsr test_speed_of_clearing_screen_4_bytes_per_write
    .else
      jsr test_speed_of_clearing_screen_1_byte_per_write
    .endif
    .else
      jsr clear_screen_slow
      lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
      sta VERA_DC_HSCALE
      sta VERA_DC_VSCALE
      jsr draw_test_pattern
    .endif
    
  
loop:
  jmp loop


draw_test_pattern:


    ; creating some specific background pixels, to see if the cache contains general background or this new background

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_1:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_1
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_2:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_2

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_3:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_3

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3 - 2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3 - 2)
    sta VERA_ADDR_LOW

    lda #06 ; blue
    
    ldx #20  ; draw 20 pixels
next_blue_pixel_4:
    sta VERA_DATA0           ; store single pixel
    dex
    bne next_blue_pixel_4


    ; Experiment 1: draw a single pixel several times (with increment to 4)
  
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel
    
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
    
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
  
    ; Experiment 2: draw a double single pixel several times (with increment to 4)
  
    lda #%00010010           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *double* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1)
    sta VERA_ADDR_LOW
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel


    ; Experiment 3: draw a triple single pixel several times (with increment to 4)
  
    lda #%00010100           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *alternative double* or *triple* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
    
    ; Experiment 4: draw a quadruple single pixel several times (with increment to 4)
  
    lda #%00010110           ; Setting address bit 16, setting auto-increment value to 1 byte increment (=%0001) and *quadruple* byte writing
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*3)
    sta VERA_ADDR_LOW
    

; FIXME: remove this setup of ADDR1!!
    ; Note: we are setting up the ADDR1 address *after* drawing the pixels we are about to *copy/blit*
    ;       since the setup of this address will caused a *pre-fetch* of the data at that address! (which will be used to fill the blit-cache)
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    lda #%00110110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 4 byte increment (=%0011)
    sta VERA_ADDR_BANK
    lda #>(0)                ; Top left position of screen (containing background color)
;    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(0)                ; Top left position of screen (containing background color)
;    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; We use A as color
    lda #FOREGROUND_COLOR

    ldx VERA_DATA1
    ldy #%00101101           ; all kinds of nible combinations
    sty VERA_DATA0           ; store pixel --> blit!
    
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel

    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    ldx VERA_DATA0
    sta VERA_DATA0           ; store pixel
    
    rts

  
  
  
test_speed_of_clearing_screen_1_byte_per_write:

    jsr generate_clear_column_code

    jsr start_timer
    jsr clear_screen_fast_1_byte
    jsr stop_timer

    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #8
    sta CURSOR_Y

    lda #<clear_screen_320x240_8bpp_message
    sta TEXT_TO_PRINT
    lda #>clear_screen_320x240_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #7
    sta CURSOR_X
    lda #12
    sta CURSOR_Y

    lda #<clear_screen_1_byte_message
    sta TEXT_TO_PRINT
    lda #>clear_screen_1_byte_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts


test_speed_of_clearing_screen_4_bytes_per_write:

    jsr generate_clear_column_code

    jsr start_timer
    jsr clear_screen_fast_4_bytes
    jsr stop_timer

    lda #COLOR_TRANSPARANT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #8
    sta CURSOR_Y

    lda #<clear_screen_320x240_8bpp_message
    sta TEXT_TO_PRINT
    lda #>clear_screen_320x240_8bpp_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #7
    sta CURSOR_X
    lda #12
    sta CURSOR_Y

    lda #<clear_screen_4_bytes_message
    sta TEXT_TO_PRINT
    lda #>clear_screen_4_bytes_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts


    
clear_screen_320x240_8bpp_message: 
    .asciiz "Cleared screen 320x240 (8bpp) "
clear_screen_1_byte_message: 
    .asciiz "Method: 1 byte per write"
clear_screen_4_bytes_message: 
    .asciiz "Method: 4 bytes per write"

    
    
clear_screen_fast_1_byte:

    ; Left part of the screen (256 columns)

    ldx #0
    
clear_next_column_left_1_byte:
    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; Color for clearing screen
    lda #BACKGROUND_COLOR
    jsr CLEAR_COLUMN_CODE
    
    inx
    bne clear_next_column_left_1_byte
    
    ; Right part of the screen (64 columns)

    ldx #0

clear_next_column_right_1_byte:
    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$01
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; Color for clearing screen
    lda #BACKGROUND_COLOR
    jsr CLEAR_COLUMN_CODE
    
    inx
    cpx #64
    bne clear_next_column_right_1_byte
    
    rts



clear_screen_fast_4_bytes:

    ; We first need to fill the 32-bit cache with 4 times our background color

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    ; TODO: we *could* use 'one byte cache cycling' so we have to set only *one* byte of the cache here
    lda #BACKGROUND_COLOR
    sta $9F29                ; cache32[7:0]
    sta $9F2A                ; cache32[15:8]
    sta $9F2B                ; cache32[23:16]
    sta $9F2C                ; cache32[31:24]

    ; We setup blit writes
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    lda #%01000000           ; transparent writes = 0, blit write = 1, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta $9F29

    ; Left part of the screen (256 columns)

    
    ldx #0
    
clear_next_column_left_4_bytes:
    lda #%11100100           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; Color for clearing screen
    lda #02
    jsr CLEAR_COLUMN_CODE
    
    inx
    inx
    inx
    inx
    bne clear_next_column_left_4_bytes
    
    ; Right part of the screen (64 columns)

    ldx #0

clear_next_column_right_4_bytes:
    lda #%11100100           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$01
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW       ; We use x as the column number, so we set it as as the start byte of a column
    
    ; Color for clearing screen
    lda #02
    jsr CLEAR_COLUMN_CODE
    
    inx
    inx
    inx
    inx
    cpx #64
    bne clear_next_column_right_4_bytes

    lda #%00000000           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta $9F29
    
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
