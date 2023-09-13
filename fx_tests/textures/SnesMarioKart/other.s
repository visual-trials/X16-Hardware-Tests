; == Very crude PoC of a 128x128px tilemap rotation ==

; To build: cl65 -t cx16 -o OTHER.PRG other.s
; To run: x16emu.exe -prg OTHER.PRG -run -ram 2048

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start





start:
