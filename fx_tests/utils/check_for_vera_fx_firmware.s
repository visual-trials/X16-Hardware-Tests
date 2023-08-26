

NEWLINE = $0D

    lda #%01111110           ; DCSEL=63, ADDRSEL=0
    sta VERA_CTRL
    
    ; Note we are skipping VERA_DC_VER0 here, since it must be 'V' when we reach this point
    lda VERA_DC_VER0
    cmp #$56   ; 'V'
    bne vera_firmware_not_good   ; This happens when the VERA has no version at all
    
    ; We need v0.3.1, so if 0 we need to check further, anything higher is good
    lda VERA_DC_VER1
    bne vera_firmware_good

    ; We need v0.3.1, so 3 or higher is good, lower is bad
    lda VERA_DC_VER2
    cmp #3
    bcc vera_firmware_not_good
    
    ; Not checking VERA_DC_VER3

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

vera_firmware_good:
   jmp keep_going

vera_firmware_not_good:

    lda #%00000100           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
   ; Send message to the user the VERA firmware is not high enough and quit
   
   lda #NEWLINE
   jsr CHROUT
   
   lda #<require_message
   sta TEXT_TO_PRINT
   lda #>require_message
   sta TEXT_TO_PRINT+1
   lda #end_require_message-require_message
   sta TMP3
   jsr print_message

   lda #NEWLINE
   jsr CHROUT
   
   lda #<check_message
   sta TEXT_TO_PRINT
   lda #>check_message
   sta TEXT_TO_PRINT+1
   lda #end_check_message-check_message
   sta TMP3
   jsr print_message

   lda #NEWLINE
   jsr CHROUT
   
   lda #<github_message
   sta TEXT_TO_PRINT
   lda #>github_message
   sta TEXT_TO_PRINT+1
   lda #end_github_message-github_message
   sta TMP3
   jsr print_message

   lda #NEWLINE
   jsr CHROUT
   
   rts

require_message: .byte "THIS DEMO REQUIRES VERA FIRMWARE V0.3.1"
end_require_message:

check_message: .byte "PLEASE CHECK FOR INSTRUCTIONS: "
end_check_message:

github_message: .byte "GITHUB.COM/X16COMMUNITY/VERA-MODULE/RELEASES"
end_github_message:

   
; FIXME: put this is a more general place!
print_message:
   
   ; print require message
   ldy #0
print_loop:
   cpy TMP3       ; length of string
   beq print_done
   lda (TEXT_TO_PRINT),y
   jsr CHROUT
   iny
   bra print_loop
print_done:
   ; print newline
   lda #NEWLINE
   jsr CHROUT
   rts

keep_going:
