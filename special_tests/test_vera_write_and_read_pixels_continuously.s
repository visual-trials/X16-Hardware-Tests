; This code reads and writes pixel data to VERA contiuously. 
; Is is meant to show erros in reading and write and let the 
; errors be cumulative. Meaning when an error occurs in either reading or writing
; what error will be the new pixel and stay on screen

; The reason for using pixels is to make more data appear on screen.

    .org $C000

reset:
    ; === Important: we start running using ROM only here, so there is no RAN/stack usage initially (no jsr, rts, or vars) ===

    ; Disable interrupts 
    sei

    ; Requires bitmap setup for layer 0
    .include "../utils/rom_only_setup_vera_for_bitmap.s"

    ; -- Fill pixels into VRAM at $0000-$0FFFF
    
    ; NOTE: this will not fill the complete screen!!
    
vera_rdwr_start:
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #0
vera_rdwr_fill_bitmap_once:
    ldx #0
vera_rdwr_fill_bitmap_row_once:
    ; We use x as color
    stx VERA_DATA0           ; store pixel data
    inx
    bne vera_rdwr_fill_bitmap_row_once
    ldx #0
vera_rdwr_fill_bitmap_end_of_row_once:
    stx VERA_DATA0           ; store pixel data
    inx
    cpx #64                  ; We do 64 more pixels
    bne vera_rdwr_fill_bitmap_end_of_row_once
    iny
    cpy #200                 ; 200 lines (slightly less than 64KB)
    bne vera_rdwr_fill_bitmap_once
    
    ; Bottom black part
    ldy #0
vera_rdwr_fill_bitmap_once2:
    ldx #0
vera_rdwr_fill_bitmap_row_once2:
    lda #0
    sta VERA_DATA0           ; black pixel data
    inx
    bne vera_rdwr_fill_bitmap_row_once2
    ldx #0
vera_rdwr_fill_bitmap_end_of_row_once2:
    lda #0
    sta VERA_DATA0           ; black pixel data
    inx
    cpx #64                  ; We do 64 more pixels
    bne vera_rdwr_fill_bitmap_end_of_row_once2
    iny
    cpy #40                 ; 40 bottom lines
    bne vera_rdwr_fill_bitmap_once2


    
vera_rdwr_keep_reading_and_writing:
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    lda #%00000001           ; DCSEL=0, ADDRSEL=1
    sta VERA_CTRL
    
    lda #%00010000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #$00
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #0
vera_rdwr_fill_bitmap:
    ldx #0
vera_rdwr_fill_bitmap_row:

; FIXME: VERA_DATA1 has not been updated! We should trigger a reload of it!
    ; This will trigger a reload of VERA_DATA1!
    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda VERA_DATA1           ; Read pixel data
    sta VERA_DATA0           ; Write back pixel data
    
    inx
    bne vera_rdwr_fill_bitmap_row
    
    ldx #0
vera_rdwr_fill_bitmap_row2:

; FIXME: VERA_DATA1 has not been updated! We should trigger a reload of it!
    ; This will trigger a reload of VERA_DATA1!
    lda #%00010000           ; Setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda VERA_DATA1           ; Read pixel data
    sta VERA_DATA0           ; Write back pixel data
    
    inx
    cpx #64
    bne vera_rdwr_fill_bitmap_row2

    iny
    cpy #200                 ; 200 lines (slightly less than 64KB)
    bne vera_rdwr_fill_bitmap
    
    jmp vera_rdwr_keep_reading_and_writing

    ; === Included files ===
    
    .include utils/x16.s

    ; ======== NMI / IRQ =======
nmi:
    rti
   
irq:
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
