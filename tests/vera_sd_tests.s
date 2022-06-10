; Tests for checking functionality of VERA SD

vera_sd_header: 
    .asciiz "VERA - SD:"
   
print_vera_sd_header:
    lda #MARGIN
    sta INDENTATION
    sta CURSOR_X
    
    ldx CURSOR_Y
    inx
    stx CURSOR_Y
    
    lda #COLOR_HEADER
    sta TEXT_COLOR
    lda #<vera_sd_header
    sta TEXT_TO_PRINT
    lda #>vera_sd_header
    sta TEXT_TO_PRINT + 1

    jsr print_text_zero
    
    lda #(MARGIN+INDENT_SIZE)
    sta INDENTATION
    
    jsr move_cursor_to_next_line
    
    rts
    
