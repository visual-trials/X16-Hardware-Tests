VERA_DC_VIDEO    = $9F29

  .org $C000

reset:
  lda #%00010001 ; Enable Layer 0, Enable VGA
  sta VERA_DC_VIDEO

loop:
  jmp loop
  

  .org $fffc
  .word reset
  .word reset
  
  
  
