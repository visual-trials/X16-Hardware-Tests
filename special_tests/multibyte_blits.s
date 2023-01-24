
BACKGROUND_COLOR = $02
FOREGROUND_COLOR = $01
; FIXME
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
; FIXME: we need COPY_COLUMN_CODE instead!
; FIXME: we need COPY_COLUMN_CODE instead!
; FIXME: we need COPY_COLUMN_CODE instead!
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

    
    lda #$10                 ; 8:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    jsr clear_screen_slow
    jsr blit_some_bytes
    
  
loop:
  jmp loop

blit_some_bytes:

; FIXME: test this *WITH* increments!!
; FIXME: test this *WITH* increments!!
; FIXME: test this *WITH* increments!!

    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1 byte increment (=%0001)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW
    
    lda #01
    sta VERA_DATA0           ; store single pixel
    lda #04
    sta VERA_DATA0           ; store single pixel
    lda #05
    sta VERA_DATA0           ; store single pixel
    lda #06
    sta VERA_DATA0           ; store single pixel

    ; Setting wrpattern to 11b and address % 4 = 01b
    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 + 1)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*1 + 1)
    sta VERA_ADDR_LOW
    
    lda #07
; FIXME    sta VERA_DATA0           ; store pixel (this actually writes 4 bytes -with the same value- inside of VERA!)
    
    ; Setting wrpattern to 11b and address % 4 = 00b
    lda #%00000110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 0 byte increment (=%0000)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*0)
    sta VERA_ADDR_LOW

    lda VERA_DATA0           ; read pixel (we ignore the result, it should now be in the 32-bit VERA cache)

; FIXME: when setting up this address it is likely VERA is *fetching ahead* the data at these (partial) addresses, therfore corrupting our cache!!
;   In fact: setting the to-be-written address will amount to reading at the address you want to write, therefore filling the cache with
;   the *same* value of the vram address you are writing to!!!
    ; Setting wrpattern to 11b and address % 4 = 00b
    lda #%00110110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 4 byte increment (=%0011)
    sta VERA_ADDR_BANK
    lda #>(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_HIGH
    lda #<(320*TOP_MARGIN+LEFT_MARGIN+VSPACING*320*2)
    sta VERA_ADDR_LOW
    
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    sta VERA_DATA0           ; store pixel (this actually blits 4 bytes inside of VERA!)
    
    rts
  
; FIXME: implement a bitmap blitter routine here!
; FIXME: implement a bitmap blitter routine here!
; FIXME: implement a bitmap blitter routine here!
test_speed_of_clearing_screen:

    jsr generate_clear_column_code

    jsr start_timer

; FIXME: use a fast clear screen method!
;    jsr clear_bitmap_screen
    jsr clear_screen_fast
    
    jsr stop_timer


    lda #COLOR_NORMAL
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
    
    
    lda #COLOR_NORMAL
    sta TEXT_COLOR
    
    lda #9
    sta CURSOR_X
    lda #24
    sta CURSOR_Y
    
    jsr print_time_elapsed

    rts
    
clear_screen_320x240_8bpp_message: 
    .asciiz "Cleared screen 320x240 (8bpp) "
clear_screen_1_byte_message: 
    .asciiz "Method: 4 bytes per write"

    
    
; FIXME: implement a bitmap blitter routine here!
; FIXME: implement a bitmap blitter routine here!
; FIXME: implement a bitmap blitter routine here!
clear_screen_fast:

    ; Left part of the screen (256 columns)

    ldx #0
    
clear_next_column_left:
    lda #%11100110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
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
    bne clear_next_column_left
    
    ; Right part of the screen (64 columns)

    ldx #0

clear_next_column_right:
    lda #%11100110           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320 bytes (=14=%1110)
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
    bne clear_next_column_right
    
    rts
    
    
; FIXME: implement a bitmap blitter routine here!
; FIXME: implement a bitmap blitter routine here!
; FIXME: implement a bitmap blitter routine here!
generate_clear_column_code:

    lda #<CLEAR_COLUMN_CODE
    sta CODE_ADDRESS
    lda #>CLEAR_COLUMN_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of clear instructions

next_clear_instruction:

    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
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
    tya
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
    tya
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
