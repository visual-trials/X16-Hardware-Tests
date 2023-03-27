
TOP_MARGIN = 12
LEFT_MARGIN = 16

COLOR_TEXT  = $01       ; Background color = 0 (transparent), foreground color 1 (white)
BACKGROUND_COLOR = 04   ; 4 = Purple in this palette


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


; FIXME: these are leftovers of memory tests in the general hardware tester (needed by utils.s atm). We dont use them, but cant remove them right now
BANK_TESTING              = $32   
BAD_VALUE                 = $3A

; RAM addresses

; ROM addresses


  .org $C000

reset:

    ; Disable interrupts 
    sei
    
    ; Setup stack
    ldx #$ff
    txs

    jsr setup_vera_for_bitmap_and_tile_map
    jsr change_palette_colors
    jsr copy_petscii_charset
    jsr clear_tilemap_screen
    jsr init_cursor
    jsr init_timer

    jsr clear_screen_slow
    
    lda #$10                 ; 8:1 scale, so we can clearly see the pixels
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE

    jsr test_mult_acc
    
loop:
  jmp loop

  
    
    
test_mult_acc:

    lda #COLOR_TEXT
    sta TEXT_COLOR
    
    lda #5
    sta CURSOR_X
    lda #4
    sta CURSOR_Y

    lda #<multi_acc_message
    sta TEXT_TO_PRINT
    lda #>multi_acc_message
    sta TEXT_TO_PRINT + 1
    
    jsr print_text_zero
    
    
    jsr test_multiplier_16x16
    
    
    rts
    

multi_acc_message: 
    .asciiz "`Multiplier and accumilator "

    
test_multiplier_16x16:

    lda #%00000000           ; Affine helper = 0, DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ; First 16-bit value
    lda #$02
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    ; Second 16-bit value
    lda #$03
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0

; FIXME: we now need affine helper to be 1 to load into cache, but that ALSO puts us into a certain FX helper mode! Which we DONT want!!
; FIXME: we now need affine helper to be 1 to load into cache, but that ALSO puts us into a certain FX helper mode! Which we DONT want!!
; FIXME: we now need affine helper to be 1 to load into cache, but that ALSO puts us into a certain FX helper mode! Which we DONT want!!

    lda #%00000100           ; Affine helper = 1, DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00000000           ; Multiplier NOT enabled, line draw mode
    sta $9F29


    lda #%00000110           ; Affine helper = 1, DCSEL=1, ADDRSEL=0
    sta VERA_CTRL
    
; FIXME: workaround: in line draw mode (=default), we set the x-increment (high bits) to 0, so ADDR1 work work as normal!
; FIXME: workaround: in line draw mode (=default), we set the x-increment (high bits) to 0, so ADDR1 work work as normal!
; FIXME: workaround: in line draw mode (=default), we set the x-increment (high bits) to 0, so ADDR1 work work as normal!
    lda #%00000000
    sta $9F2A

    lda #%00000101           ; Affine helper = 1, DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW

    ; Loading both 16-bit values into the cache32
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    
    ; Writing to vram without multiplication
    
    lda #%00110110           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 4, with wrpattern = 11 (blit)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$04
    sta VERA_ADDR_LOW
    
    stz VERA_DATA1
    
    
    lda #%00000100           ; Affine helper = 1, DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00001000           ; Multiplier enabled, line draw mode
    sta $9F29

    lda #%00000101           ; Affine helper = 1, DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW

    ; Loading both 16-bit values into the cache32
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    lda VERA_DATA1
    
    ; Writing to vram with multiplication
    
    lda #%00110110           ; Setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 4, with wrpattern = 11 (blit)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$08
    sta VERA_ADDR_LOW
    
    stz VERA_DATA1
    
    
    
    
    ; Exiting affine helper mode
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts

    
change_palette_colors:

    ; -- Change some colors in the palette
    
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$08                 ; We use color 4 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$05                 ; gb
    sta VERA_DATA0
    lda #$05                 ; -r
    sta VERA_DATA0
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$04                 ; We use color 2 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$00                 ; gb
    sta VERA_DATA0
    lda #$0F                 ; -r
    sta VERA_DATA0
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$10                 ; We use color 8 in the pallete (each color takes 2 bytes)
    sta VERA_ADDR_LOW

    lda #$80                 ; gb
    sta VERA_DATA0
    lda #$0F                 ; -r
    sta VERA_DATA0

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

    ; ======== NMI / IRQ =======
nmi:
    ; TODO: implement this
    ; FIXME: ugly hack!
    jmp reset
    rti
   
irq:
    rti
    
    ; ======== PETSCII CHARSET =======

    .org $F700
    .include "utils/petscii.s"
    
    

    .org $fffa
    .word nmi
    .word reset
    .word irq
    