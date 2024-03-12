; == Testing the triggering the incrementer by doing many reads (interleaved with writes) ==

; To build: cl65 -t cx16 -o READTRIGGER.PRG read_trigger_test.s
; To run: x16emu.exe -prg READTRIGGER.PRG -run

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; -- some X16 constants --

VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_DATA1        = $9F24
VERA_CTRL         = $9F25

VERA_DC_VIDEO     = $9F29  ; DCSEL=0
VERA_DC_HSCALE    = $9F2A  ; DCSEL=0
VERA_DC_VSCALE    = $9F2B  ; DCSEL=0

VERA_DC_VSTART    = $9F2B  ; DCSEL=1
VERA_DC_VSTOP     = $9F2C  ; DCSEL=1

VERA_L0_CONFIG    = $9F2D
VERA_L0_TILEBASE  = $9F2F

CODE_ADDRESS           = $32 ; 33

READ_WRITE_ROW_CODE    = $7800

BACKGROUND_COLOR       = 0



start:

    jsr setup_vera_for_layer0_bitmap

    jsr generate_read_write_row_code

    jsr clear_screen_slow
    
    jsr keep_drawing_pattern_on_screen

    rts
    
    
    
setup_vera_for_layer0_bitmap:

    lda VERA_DC_VIDEO
    ora #%00010000           ; Enable Layer 0 
    and #%10011111           ; Disable Layer 1 and sprites
    sta VERA_DC_VIDEO

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; Enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    ; Set layer0 tilebase to 0x00000 and tile width to 320 px
    lda #0
    sta VERA_L0_TILEBASE

    rts
    

keep_drawing_pattern_on_screen:
    lda #%00010000           ; Setting auto-increment value to 1 byte increment (=%0001) 
    sta VERA_ADDR_BANK
    stz VERA_ADDR_HIGH
    stz VERA_ADDR_LOW
    
    lda #1

    ldy #240
read_write_entire_next_row:
    jsr READ_WRITE_ROW_CODE
    dey
    bne read_write_entire_next_row

    ; We keep drawing the same pattern to the screen without clearing the screen
    jmp keep_drawing_pattern_on_screen

    rts


    

clear_screen_slow:

vera_wr_start:
    ldx #0
vera_wr_fill_bitmap_once:

    lda #%11100000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 320px (=14=%1110)
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW

    ; We use A as color
    lda #BACKGROUND_COLOR

    ldy #240
vera_wr_fill_bitmap_col_once:
    sta VERA_DATA0
    dey
    bne vera_wr_fill_bitmap_col_once
    inx
    bne vera_wr_fill_bitmap_once

    ; Right part of the screen

    ldx #0
vera_wr_fill_bitmap_once2:

    lda #%11100000
    sta VERA_ADDR_BANK
    lda #$01
    sta VERA_ADDR_HIGH
    stx VERA_ADDR_LOW

    ; We use A as color
    lda #BACKGROUND_COLOR

    ldy #240
vera_wr_fill_bitmap_col_once2:
    sta VERA_DATA0           ; store pixel
    dey
    bne vera_wr_fill_bitmap_col_once2
    inx
    cpx #64
    bne vera_wr_fill_bitmap_once2

    rts
    

generate_read_write_row_code:

    lda #<READ_WRITE_ROW_CODE
    sta CODE_ADDRESS
    lda #>READ_WRITE_ROW_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of copy instructions

next_read_write_instruction:

    ; -- ldx VERA_DATA0 ($9F23)
    lda #$AE               ; ldx ....
    jsr add_code_byte
    
    lda #$23               ; VERA_DATA0
    jsr add_code_byte
    
    lda #$9F         
    jsr add_code_byte

    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$23               ; VERA_DATA0
    jsr add_code_byte
    
    lda #$9F  
    jsr add_code_byte

    inx
    cpx #160
    bne next_read_write_instruction

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
