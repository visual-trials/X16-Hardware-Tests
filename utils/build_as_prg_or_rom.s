  .ifdef CREATE_PRG
      ; See also: https://michaelcmartin.github.io/Ophis/book/x72.html
      
      .org $07FF                ; This is added so the assembler puts the following bytes right before the next .org
      .byte $01, $08            ; PRG is loaded into $0801 (meaning: everything that follows, so everything *except* these two byte themselves)
      
      ; This is loaded into $0801:
      .byte $0B, $08            ; 2-byte pointer to the next line of BASIC code ($080B).
      .byte $0A, $00            ; 2-byte line number ($000A = 10).
      .byte $9E                 ; Byte code for the SYS command.
      .byte $32, $30, $36, $31  ; The rest of the line, which is just the string "2061". (= $080D)
      .byte $00                 ; Null byte, terminating the line.
      .byte $00, $00            ; 2-byte pointer to the next line of BASIC code ($0000 = end of program).
      ; The above bytes end at $080C, so the next byte starts at $080D
      
      .org $080D
  .else
      .org $C000
  .endif
