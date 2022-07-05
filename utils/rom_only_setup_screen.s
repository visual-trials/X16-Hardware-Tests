
    ; === This file is for setup of palette colors, petscii charset, screen, title on screen, fixed ram header ===

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
    
    ; Copy petscii charset to VRAM
    .include "utils/rom_only_copy_petscii_charset.s"
    
    ; This will clear the screen without using RAM.

    ; -- Fill tilemap into VRAM at $1B000-$1EBFF

vera_clear_start:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B0
    sta VERA_ADDR_HIGH
    lda #$00
    sta VERA_ADDR_LOW
    
    ldy #(TILE_MAP_HEIGHT / (256 / TILE_MAP_WIDTH))
vera_clear_fill_tile_map:
    ldx #0
vera_clear_fill_tile_map_row:
    lda #$20
    sta VERA_DATA0           ; character index = 'space'
    lda #COLOR_NORMAL
    sta VERA_DATA0           ; Fill Foreground and background color
    inx
    bne vera_clear_fill_tile_map_row
    dey
    bne vera_clear_fill_tile_map
    
    
; --- This is printing the title
    
print_title:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B1
    sta VERA_ADDR_HIGH
    lda #$2E
    sta VERA_ADDR_LOW
    
    ldx #0
print_title_message:
    lda title_message, x
    beq done_print_title_message
    cmp #97  ; 'a'
    bpl title_larger_than_or_equal_to_a
title_smaller_than_a:            
    cmp #65  ; 'A'
    bpl title_between_A_and_a
    ; This part is roughly the same between ASCII and PETSCII
    jmp title_char_convert_done
title_between_A_and_a:           ; Uppercase letters
    sec
    sbc #64
    jmp title_char_convert_done
title_larger_than_or_equal_to_a: ; Lowercase letters
    sec
    sbc #96
    clc
    adc #128
title_char_convert_done:  
    inx
    sta VERA_DATA0
    lda #COLOR_TITLE
    sta VERA_DATA0           
    jmp print_title_message
    
title_message:
    .asciiz "*** X16 Hardware Tester v0.4.4 ***"

done_print_title_message:
    
    
; --- This is printing the Fixed RAM header
    
print_fixed_ram_header:
    lda #%00010001           ; Setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #$B3
    sta VERA_ADDR_HIGH
    lda #($00+MARGIN*2)
    sta VERA_ADDR_LOW
    
    ldx #0
print_fixed_ram_message:
    lda fixed_ram_header_message, x
    beq done_print_fixed_ram_message
    cmp #97  ; 'a'
    bpl fixed_ram_larger_than_or_equal_to_a
fixed_ram_smaller_than_a:            
    cmp #65  ; 'A'
    bpl fixed_ram_between_A_and_a
    ; This part is roughly the same between ASCII and PETSCII
    jmp fixed_ram_char_convert_done
fixed_ram_between_A_and_a:           ; Uppercase letters
    sec
    sbc #64
    jmp fixed_ram_char_convert_done
fixed_ram_larger_than_or_equal_to_a: ; Lowercase letters
    sec
    sbc #96
    clc
    adc #128
fixed_ram_char_convert_done:  
    inx
    sta VERA_DATA0
    lda #COLOR_HEADER
    sta VERA_DATA0           
    jmp print_fixed_ram_message
    
done_print_fixed_ram_message:
    
