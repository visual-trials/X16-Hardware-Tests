; == This is a small demo to show a color wheel with 398 colors   ==

; To build: cl65 -t cx16 -o WHEEL.PRG color_wheel.s
; To run: x16emu.exe -prg WHEEL.PRG -run

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; TODO: The following is *copied* from my x16.s (it should be included instead)

; -- some X16 constants --

VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_DATA1        = $9F24
VERA_CTRL         = $9F25

VERA_IEN          = $9F26
VERA_ISR          = $9F27
VERA_IRQLINE_L    = $9F28
VERA_SCANLINE_L   = $9F28

VERA_DC_VIDEO     = $9F29  ; DCSEL=0
VERA_DC_HSCALE    = $9F2A  ; DCSEL=0
VERA_DC_VSCALE    = $9F2B  ; DCSEL=0

VERA_L0_CONFIG    = $9F2D
VERA_L0_TILEBASE  = $9F2F


; Kernal API functions
SETNAM            = $FFBD  ; set filename
SETLFS            = $FFBA  ; Set LA, FA, and SA
LOAD              = $FFD5  ; Load a file into main memory or VRAM

VERA_PALETTE      = $1FA00
 


; === Zero page addresses ===

; Bank switching
RAM_BANK                  = $00
ROM_BANK                  = $01


LOAD_ADDRESS              = $30 ; 31
CODE_ADDRESS              = $32 ; 33
STORE_ADDRESS             = $34 ; 35
VRAM_ADDRESS              = $36 ; 37 ; 38


; === RAM addresses ===


; === VRAM addresses ===

BITMAP_VRAM_ADDRESS       = $00000

; === Other constants ===


start:

    sei
    
    jsr setup_vera_for_layer0_bitmap

    jsr copy_full_top_palette
    
    jsr clear_bitmap_memory   ; SLOW!
    jsr load_bitmap_into_vram
    

swap_loop:
    jsr dumb_wait_for_half_screen
    jsr copy_partial_bottom_palette

    jsr dumb_wait_for_vsync
    jsr copy_partial_top_palette
    
    bra swap_loop


    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts




; This is just a dumb verison of a proper half-screen-wait/interrupt
dumb_wait_for_half_screen:

    ; We wait until SCANLINE == $0E0 (indicating the beam roughly half screen screen, line 112+ low res lines)
wait_for_scanline_bit8_zero:
    lda VERA_IEN
    and #%01000000
    bne wait_for_scanline_bit8_zero
    
wait_for_scanline_low_half:
    lda VERA_SCANLINE_L
    cmp #$E0
; FIXME: this is awfully precise! Maybe do a greater of equal here?
    bne wait_for_scanline_low_half

    rts


; This is just a dumb verison of a proper vsync-wait
dumb_wait_for_vsync:

    ; We wait until SCANLINE == $1FF (indicating the beam is off screen, lines 512-524)
wait_for_scanline_bit8:
    lda VERA_IEN
    and #%01000000
    beq wait_for_scanline_bit8
    
wait_for_scanline_low:
    lda VERA_SCANLINE_L
    cmp #$FF
    bne wait_for_scanline_low

    rts
    


; For debugging    
wait_a_few_ms:
    phx
    phy
    ldx #64
wait_a_few_ms_256:
    ldy #0
wait_a_few_ms_1:
    nop
    nop
    nop
    nop
    iny
    bne wait_a_few_ms_1
    dex
    bne wait_a_few_ms_256
    ply
    plx
    rts

    
    
setup_vera_for_layer0_bitmap:

    lda VERA_DC_VIDEO
    ora #%00010000           ; Enable Layer 0 and sprites
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

    ; Set layer0 tilebase to $00000 and tile width to 320 px
    lda #%00000000   
    sta VERA_L0_TILEBASE

    rts
    


clear_bitmap_memory:

    lda #%00010000      ; setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #0
    sta VERA_ADDR_LOW
    lda #0
    sta VERA_ADDR_HIGH

    ; FIXME: PERFORMANCE we can do this MUCH faster using CACHE writes and UNROLLING!
    
    ; We need 320*240 = 76800 bytes to be cleared
    ; This means we need 300*256 bytes to be cleared (300 = 256 + 44)

    ; First 256*256 bytes
    ldy #0
clear_bitmap_next_256:
    ldx #0
clear_bitmap_next_1:
    stz VERA_DATA0
    inx
    bne clear_bitmap_next_1
    dey
    bne clear_bitmap_next_256

    ldy #44
clear_bitmap_next_256a:
    ldx #0
clear_bitmap_next_1a:
    stz VERA_DATA0
    inx
    bne clear_bitmap_next_1a
    dey
    bne clear_bitmap_next_256a
    
    rts

    


copy_full_top_palette:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 0 of the palette
    lda #<(VERA_PALETTE)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE)
    sta VERA_ADDR_HIGH

    ; HACK: we know we have more than 128 colors to copy (meaning: > 256 bytes), so we are just going to copy 128 colors first
    
    ldy #0
next_packed_color_256:
    lda top_palette, y
    sta VERA_DATA0
    iny
    bne next_packed_color_256

    ldy #0
next_packed_color_1:
    lda top_palette+256, y
    sta VERA_DATA0
    iny
    bne next_packed_color_1
    
    rts





copy_partial_top_palette:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 0 of the palette
    lda #<(VERA_PALETTE)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE)
    sta VERA_ADDR_HIGH

    ; HACK: we know we have more than 128 colors to copy (meaning: > 256 bytes), so we are just going to copy 128 colors first
    
    ldy #0
next_packed_color_256_top:
    lda top_palette, y
    sta VERA_DATA0
    iny
    bne next_packed_color_256_top

    ; We need to copy 142+1 colors, so copy 15 more (=30 bytes) --> this INCLUDES BLACK!
    ldy #0
next_packed_color_1_top:
    lda top_palette+256, y
    sta VERA_DATA0
    iny
    cpy #30+2 ; if y=30 we still need to go on?
    bne next_packed_color_1_top
    
    rts

copy_partial_bottom_palette:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 0 of the palette
    lda #<(VERA_PALETTE)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE)
    sta VERA_ADDR_HIGH

    ; HACK: we know we have more than 128 colors to copy (meaning: > 256 bytes), so we are just going to copy 128 colors first
    
    ldy #0
next_packed_color_256_bottom:
    lda bottom_palette, y
    sta VERA_DATA0
    iny
    bne next_packed_color_256_bottom

    ; We need to copy 142+1 colors, so copy 15 more (=30 bytes) --> this INCLUDES BLACK!
    ldy #0
next_packed_color_1_bottom:
    lda bottom_palette+256, y
    sta VERA_DATA0
    iny
    cpy #30+2 ; if y=30 we still need to go on?
    bne next_packed_color_1_bottom
    
    rts



bitmap_filename:      .byte    "colorwheel.dat" 
end_bitmap_filename:

load_bitmap_into_vram:

    lda #(end_bitmap_filename-bitmap_filename) ; Length of filename
    ldx #<bitmap_filename      ; Low byte of Fname address
    ldy #>bitmap_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    jsr SETLFS
 
    lda #2            ; load into Bank 0 of VRAM (see https://github.com/X16Community/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-load )
    ldx #<BITMAP_VRAM_ADDRESS
    ldy #>BITMAP_VRAM_ADDRESS
    jsr LOAD
    bcc bitmap_loaded
    ; FIXME: do proper error handling!
    stp

bitmap_loaded:
    rts




; ==== DATA ====

top_palette:
  .byte $00, $00
  .byte $20, $01
  .byte $20, $02
  .byte $20, $01
  .byte $20, $02
  .byte $50, $04
  .byte $40, $03
  .byte $50, $04
  .byte $20, $00
  .byte $20, $02
  .byte $40, $02
  .byte $50, $05
  .byte $70, $05
  .byte $70, $06
  .byte $70, $04
  .byte $70, $07
  .byte $20, $00
  .byte $20, $02
  .byte $40, $01
  .byte $40, $05
  .byte $90, $09
  .byte $60, $03
  .byte $60, $07
  .byte $90, $07
  .byte $90, $0a
  .byte $90, $06
  .byte $80, $0a
  .byte $30, $00
  .byte $30, $05
  .byte $60, $02
  .byte $50, $08
  .byte $20, $00
  .byte $20, $02
  .byte $b0, $0b
  .byte $c0, $0c
  .byte $80, $04
  .byte $60, $0a
  .byte $b0, $09
  .byte $a0, $0c
  .byte $b0, $07
  .byte $80, $0d
  .byte $e0, $0f
  .byte $50, $00
  .byte $40, $08
  .byte $e0, $0d
  .byte $c0, $0f
  .byte $80, $02
  .byte $50, $0a
  .byte $31, $00
  .byte $30, $05
  .byte $d0, $0b
  .byte $a0, $0f
  .byte $a0, $05
  .byte $60, $0d
  .byte $21, $00
  .byte $10, $02
  .byte $d0, $09
  .byte $80, $0f
  .byte $e2, $0f
  .byte $c2, $0f
  .byte $70, $00
  .byte $30, $0a
  .byte $e3, $0d
  .byte $b3, $0f
  .byte $90, $03
  .byte $40, $0c
  .byte $51, $00
  .byte $20, $07
  .byte $e3, $0c
  .byte $92, $0f
  .byte $c0, $06
  .byte $50, $0f
  .byte $32, $00
  .byte $20, $05
  .byte $e3, $0a
  .byte $72, $0f
  .byte $21, $00
  .byte $10, $02
  .byte $d5, $0f
  .byte $e5, $0f
  .byte $c5, $0f
  .byte $90, $00
  .byte $20, $0c
  .byte $e5, $0e
  .byte $a5, $0f
  .byte $b0, $03
  .byte $30, $0f
  .byte $72, $00
  .byte $20, $0a
  .byte $d2, $07
  .byte $53, $0f
  .byte $53, $00
  .byte $10, $07
  .byte $e5, $0c
  .byte $85, $0f
  .byte $e5, $0b
  .byte $75, $0f
  .byte $33, $00
  .byte $10, $05
  .byte $e8, $0f
  .byte $c7, $0f
  .byte $f7, $0f
  .byte $b7, $0f
  .byte $a0, $00
  .byte $00, $0f
  .byte $c2, $05
  .byte $22, $0f
  .byte $82, $00
  .byte $00, $0c
  .byte $e7, $0e
  .byte $a7, $0f
  .byte $d5, $09
  .byte $55, $0f
  .byte $73, $00
  .byte $00, $0a
  .byte $e8, $0d
  .byte $98, $0f
  .byte $22, $00
  .byte $00, $03
  .byte $e7, $0c
  .byte $78, $0f
  .byte $54, $00
  .byte $00, $07
  .byte $b2, $02
  .byte $24, $0f
  .byte $da, $0f
  .byte $ea, $0f
  .byte $da, $0f
  .byte $c5, $07
  .byte $56, $0f
  .byte $a2, $00
  .byte $02, $0f
  .byte $fa, $0f
  .byte $ca, $0f
  .byte $ea, $0e
  .byte $ba, $0f
  .byte $e7, $0a
  .byte $88, $0f
  .byte $84, $00
  .byte $01, $0c
  .byte $fa, $0e
  .byte $aa, $0f
  .byte $33, $00
  .byte $00, $05
  .byte $c5, $05
  .byte $57, $0f
  .byte $ea, $0d
  .byte $aa, $0f
  .byte $75, $00
  .byte $01, $0a
  .byte $d7, $09
  .byte $89, $0f
  .byte $b5, $02
  .byte $25, $0f
  .byte $ea, $0c
  .byte $ab, $0f
  .byte $a5, $00
  .byte $03, $0f
  .byte $ec, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $dd, $0f
  .byte $fd, $0f
  .byte $dc, $0f
  .byte $fc, $0f
  .byte $cd, $0f
  .byte $22, $00
  .byte $00, $02
  .byte $d7, $07
  .byte $7a, $0f
  .byte $fd, $0e
  .byte $dd, $0f
  .byte $55, $00
  .byte $01, $07
  .byte $ea, $0b
  .byte $ac, $0f
  .byte $c7, $05
  .byte $58, $0f
  .byte $fc, $0e
  .byte $cd, $0f
  .byte $86, $00
  .byte $03, $0c
  .byte $fd, $0d
  .byte $dd, $0f
  .byte $b7, $02
  .byte $36, $0f
  .byte $da, $0a
  .byte $ac, $0f
  .byte $ed, $0d
  .byte $ce, $0f
  .byte $d9, $08
  .byte $8a, $0f
  .byte $ec, $0d
  .byte $de, $0f
  .byte $db, $0a
  .byte $ad, $0f
  .byte $c8, $05
  .byte $59, $0f
  .byte $a8, $00
  .byte $05, $0f
  .byte $67, $00
  .byte $02, $0a
  .byte $34, $00
  .byte $00, $05
  .byte $de, $0f
  .byte $ee, $0d
  .byte $8a, $0f
  .byte $cb, $07
  .byte $de, $0f
  .byte $ee, $0d
  .byte $ad, $0f
  .byte $dc, $0a
  .byte $36, $0f
  .byte $bb, $02
  .byte $de, $0f
  .byte $ee, $0d
  .byte $03, $0c
  .byte $8b, $00
  .byte $de, $0e
  .byte $ef, $0d
  .byte $59, $0f
  .byte $bc, $05
  .byte $ad, $0f
  .byte $dd, $0a
  .byte $01, $07
  .byte $57, $00
  .byte $de, $0e
  .byte $ef, $0d
  .byte $8b, $0f
  .byte $cd, $07
  .byte $00, $02
  .byte $12, $00
  .byte $de, $0d
  .byte $ef, $0d
  .byte $de, $0d
  .byte $ef, $0d
  .byte $de, $0d
  .byte $ee, $0d
  .byte $de, $0d
  .byte $de, $0d
  .byte $05, $0f
  .byte $ad, $00
  .byte $ad, $0e
  .byte $de, $0a
  .byte $28, $0e
  .byte $ad, $02
  .byte $8c, $0e
  .byte $ce, $07
  .byte $02, $0a
  .byte $6a, $00
  .byte $ad, $0d
  .byte $df, $0a
  .byte $5a, $0f
  .byte $bd, $05
  .byte $00, $05
  .byte $ff, $0f

bottom_palette:
  .byte $00, $00
  .byte $02, $01
  .byte $02, $02
  .byte $02, $01
  .byte $02, $02
  .byte $13, $03
  .byte $13, $02
  .byte $03, $03
  .byte $12, $01
  .byte $02, $02
  .byte $13, $01
  .byte $03, $04
  .byte $15, $03
  .byte $15, $04
  .byte $25, $02
  .byte $15, $05
  .byte $12, $00
  .byte $01, $02
  .byte $13, $01
  .byte $03, $05
  .byte $26, $04
  .byte $25, $01
  .byte $05, $06
  .byte $26, $03
  .byte $16, $05
  .byte $36, $01
  .byte $16, $07
  .byte $13, $01
  .byte $03, $05
  .byte $25, $01
  .byte $05, $07
  .byte $12, $00
  .byte $01, $02
  .byte $38, $03
  .byte $28, $05
  .byte $37, $01
  .byte $06, $08
  .byte $38, $02
  .byte $28, $07
  .byte $49, $01
  .byte $18, $08
  .byte $39, $04
  .byte $36, $01
  .byte $04, $07
  .byte $49, $02
  .byte $39, $06
  .byte $47, $01
  .byte $06, $09
  .byte $24, $00
  .byte $02, $05
  .byte $5a, $02
  .byte $29, $08
  .byte $59, $01
  .byte $18, $0a
  .byte $12, $00
  .byte $01, $02
  .byte $6b, $01
  .byte $1a, $0a
  .byte $6a, $04
  .byte $5a, $06
  .byte $48, $01
  .byte $05, $0a
  .byte $6b, $04
  .byte $5a, $07
  .byte $6a, $01
  .byte $08, $0c
  .byte $36, $00
  .byte $03, $07
  .byte $7c, $04
  .byte $4a, $09
  .byte $7c, $01
  .byte $19, $0c
  .byte $24, $00
  .byte $02, $05
  .byte $8d, $03
  .byte $3a, $0b
  .byte $12, $00
  .byte $00, $02
  .byte $8b, $06
  .byte $8c, $06
  .byte $7b, $08
  .byte $6b, $01
  .byte $06, $0c
  .byte $9d, $06
  .byte $7b, $09
  .byte $8d, $01
  .byte $09, $0e
  .byte $59, $00
  .byte $04, $0a
  .byte $9d, $03
  .byte $3a, $0d
  .byte $47, $00
  .byte $02, $07
  .byte $9d, $06
  .byte $6b, $0a
  .byte $ae, $05
  .byte $6b, $0c
  .byte $34, $00
  .byte $01, $05
  .byte $ad, $08
  .byte $9c, $08
  .byte $ad, $08
  .byte $9c, $09
  .byte $8e, $00
  .byte $08, $0e
  .byte $ae, $03
  .byte $3a, $0e
  .byte $7c, $00
  .byte $05, $0c
  .byte $be, $08
  .byte $9c, $0b
  .byte $be, $05
  .byte $5b, $0d
  .byte $69, $00
  .byte $03, $0a
  .byte $be, $08
  .byte $9c, $0c
  .byte $12, $00
  .byte $00, $02
  .byte $cf, $08
  .byte $8c, $0d
  .byte $47, $00
  .byte $01, $07
  .byte $af, $03
  .byte $29, $0e
  .byte $ce, $0b
  .byte $ce, $0a
  .byte $bd, $0b
  .byte $bf, $05
  .byte $5b, $0e
  .byte $9f, $00
  .byte $06, $0e
  .byte $ce, $0a
  .byte $bd, $0b
  .byte $de, $0a
  .byte $bd, $0c
  .byte $cf, $08
  .byte $8c, $0d
  .byte $8d, $00
  .byte $04, $0c
  .byte $df, $0a
  .byte $bd, $0d
  .byte $35, $00
  .byte $00, $05
  .byte $c5, $05
  .byte $57, $0f
  .byte $ea, $0d
  .byte $aa, $0f
  .byte $75, $00
  .byte $01, $0a
  .byte $d7, $09
  .byte $89, $0f
  .byte $b5, $02
  .byte $25, $0f
  .byte $ea, $0c
  .byte $ab, $0f
  .byte $a5, $00
  .byte $03, $0f
  .byte $ec, $0f
  .byte $ed, $0f
  .byte $ed, $0f
  .byte $dd, $0f
  .byte $fd, $0f
  .byte $dc, $0f
  .byte $fc, $0f
  .byte $cd, $0f
  .byte $22, $00
  .byte $00, $02
  .byte $d7, $07
  .byte $7a, $0f
  .byte $fd, $0e
  .byte $dd, $0f
  .byte $55, $00
  .byte $01, $07
  .byte $ea, $0b
  .byte $ac, $0f
  .byte $c7, $05
  .byte $58, $0f
  .byte $fc, $0e
  .byte $cd, $0f
  .byte $86, $00
  .byte $03, $0c
  .byte $fd, $0d
  .byte $dd, $0f
  .byte $b7, $02
  .byte $36, $0f
  .byte $da, $0a
  .byte $ac, $0f
  .byte $ed, $0d
  .byte $ce, $0f
  .byte $d9, $08
  .byte $8a, $0f
  .byte $ec, $0d
  .byte $de, $0f
  .byte $db, $0a
  .byte $ad, $0f
  .byte $c8, $05
  .byte $59, $0f
  .byte $a8, $00
  .byte $05, $0f
  .byte $67, $00
  .byte $02, $0a
  .byte $34, $00
  .byte $00, $05
  .byte $de, $0f
  .byte $ee, $0d
  .byte $8a, $0f
  .byte $cb, $07
  .byte $de, $0f
  .byte $dc, $0a
  .byte $36, $0f
  .byte $bb, $02
  .byte $de, $0f
  .byte $ee, $0d
  .byte $03, $0c
  .byte $8b, $00
  .byte $de, $0e
  .byte $ef, $0d
  .byte $59, $0f
  .byte $bc, $05
  .byte $ad, $0f
  .byte $dd, $0a
  .byte $01, $07
  .byte $57, $00
  .byte $de, $0e
  .byte $ef, $0d
  .byte $8b, $0f
  .byte $cd, $07
  .byte $00, $02
  .byte $12, $00
  .byte $de, $0d
  .byte $ef, $0d
  .byte $de, $0d
  .byte $ef, $0d
  .byte $de, $0d
  .byte $ee, $0d
  .byte $de, $0d
  .byte $de, $0d
  .byte $05, $0f
  .byte $ad, $00
  .byte $ad, $0e
  .byte $de, $0a
  .byte $28, $0e
  .byte $ad, $02
  .byte $8c, $0e
  .byte $ce, $07
  .byte $02, $0a
  .byte $6a, $00
  .byte $ad, $0d
  .byte $df, $0a
  .byte $5a, $0f
  .byte $bd, $05
  .byte $00, $05
  .byte $ff, $0f
  