; X16 constants

; For VIA info see: https://eater.net/datasheets/w65c22.pdf

                          ; Write                | Read
VIA1_PORTB        = $9F00 ; Output Register "B"  | Input Register "B"
VIA1_PORTA        = $9F01 ; Output Register "A"  | Input Register "A"
VIA1_DDRB         = $9F02 ; Data Direction Register "B"
VIA1_DDRA         = $9F03 ; Data Direction Register "A"
VIA1_T1C_L        = $9F04 ; T1 Latch (low order) | T1 Count (low order)
VIA1_T1C_H        = $9F05 ; T1 Latch (high order)
VIA1_T1L_L        = $9F06 ; T1 Clock (low order)
VIA1_T1L_H        = $9F07 ; T1 Clock (high order)
VIA1_T2C_L        = $9F08 ; T2 Clock (low order)
VIA1_T2C_H        = $9F09 ; T2 Clock (high order)
VIA1_SR           = $9F0A ; Shift Register
VIA1_ACR          = $9F0B ; Auxiliary Control Register
VIA1_PCR          = $9F0C ; Peripheral Control Register
VIA1_IFR          = $9F0D ; Interrupt Flag Register
VIA1_IER          = $9F0E ; Interrupt Enable Register
VIA1_PORTA_ALT    = $9F0F ; Same as Reg 1 except no "Handshake"

                          ; Write                | Read
VIA2_PORTB        = $9F10 ; Output Register "B"  | Input Register "B"
VIA2_PORTA        = $9F11 ; Output Register "A"  | Input Register "A"
VIA2_DDRB         = $9F12 ; Data Direction Register "B"
VIA2_DDRA         = $9F13 ; Data Direction Register "A"
VIA2_T1C_L        = $9F14 ; T1 Latch (low order) | T1 Count (low order)
VIA2_T1C_H        = $9F15 ; T1 Latch (high order)
VIA2_T1L_L        = $9F16 ; T1 Clock (low order)
VIA2_T1L_H        = $9F17 ; T1 Clock (high order)
VIA2_T2C_L        = $9F18 ; T2 Clock (low order)
VIA2_T2C_H        = $9F19 ; T2 Clock (high order)
VIA2_SR           = $9F1A ; Shift Register
VIA2_ACR          = $9F1B ; Auxiliary Control Register
VIA2_PCR          = $9F1C ; Peripheral Control Register
VIA2_IFR          = $9F1D ; Interrupt Flag Register
VIA2_IER          = $9F1E ; Interrupt Enable Register
VIA2_PORTA_ALT    = $9F1F ; Same as Reg 1 except no "Handshake"

; Control words for Auxiliary Control Register in 65c22
VIA_T1_MODE0    = %00000000 	; One shot mode.
VIA_T1_MODE1    = %01000000		; Continuous mode.
VIA_T1_MODE2    = %10000000		; Mode 0. Plus PB7 one shot output
VIA_T1_MODE3    = %11000000		; Mode 1. Plus PB7 square wave output

; For VERA info see: https://github.com/commanderx16/x16-docs/blob/master/VERA%20Programmer's%20Reference.md

VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_DATA1        = $9F24
VERA_CTRL         = $9F25

VERA_IEN          = $9F26
VERA_ISR          = $9F27
VERA_IRQLINE_L    = $9F28

VERA_DC_VIDEO     = $9F29  ; DCSEL=0
VERA_DC_HSCALE    = $9F2A  ; DCSEL=0
VERA_DC_VSCALE    = $9F2B  ; DCSEL=0
VERA_DC_BORDER    = $9F2C  ; DCSEL=0

VERA_DC_HSTART    = $9F29  ; DCSEL=1
VERA_DC_HSTOP     = $9F2A  ; DCSEL=1
VERA_DC_VSTART    = $9F2B  ; DCSEL=1
VERA_DC_VSTOP     = $9F2C  ; DCSEL=1

VERA_FX_CTRL      = $9F29  ; DCSEL=2
VERA_FX_TILEBASE  = $9F2A  ; DCSEL=2
VERA_FX_MAPBASE   = $9F2B  ; DCSEL=2
VERA_FX_MULT      = $9F2C  ; DCSEL=2

VERA_FX_X_INCR_L  = $9F29  ; DCSEL=3
VERA_FX_X_INCR_H  = $9F2A  ; DCSEL=3
VERA_FX_Y_INCR_L  = $9F2B  ; DCSEL=3
VERA_FX_Y_INCR_H  = $9F2C  ; DCSEL=3

VERA_FX_X_POS_L   = $9F29  ; DCSEL=4
VERA_FX_X_POS_H   = $9F2A  ; DCSEL=4
VERA_FX_Y_POS_L   = $9F2B  ; DCSEL=4
VERA_FX_Y_POS_H   = $9F2C  ; DCSEL=4

VERA_FX_X_POS_S   = $9F29  ; DCSEL=5
VERA_FX_Y_POS_S   = $9F2A  ; DCSEL=5
VERA_FX_POLY_FILL_L = $9F2B  ; DCSEL=5
VERA_FX_POLY_FILL_H = $9F2C  ; DCSEL=5

VERA_FX_CACHE_L   = $9F29  ; DCSEL=6
VERA_FX_ACCUM_RESET = $9F29  ; DCSEL=6
VERA_FX_CACHE_M   = $9F2A  ; DCSEL=6
VERA_FX_ACCUM     = $9F2A  ; DCSEL=6
VERA_FX_CACHE_H   = $9F2B  ; DCSEL=6
VERA_FX_CACHE_U   = $9F2C  ; DCSEL=6

VERA_DC_VER0      = $9F29  ; DCSEL=63
VERA_DC_VER1      = $9F2A  ; DCSEL=63
VERA_DC_VER2      = $9F2B  ; DCSEL=63
VERA_DC_VER3      = $9F2C  ; DCSEL=63

VERA_L0_CONFIG    = $9F2D
VERA_L0_MAPBASE   = $9F2E
VERA_L0_TILEBASE  = $9F2F
VERA_L0_HSCROLL_L = $9F30
VERA_L0_HSCROLL_H = $9F31
VERA_L0_VSCROLL_L = $9F32
VERA_L0_VSCROLL_H = $9F33

VERA_L1_CONFIG    = $9F34
VERA_L1_MAPBASE   = $9F35
VERA_L1_TILEBASE  = $9F36
VERA_L1_HSCROLL_L = $9F37
VERA_L1_HSCROLL_H = $9F38
VERA_L1_VSCROLL_L = $9F39
VERA_L1_VSCROLL_H = $9F3A

VERA_AUDIO_CTRL   = $9F3B
VERA_AUDIO_RATE   = $9F3C
VERA_AUDIO_DATA   = $9F3D

VERA_SPI_DATA     = $9F3E
VERA_SPI_CTRL     = $9F3F

VERA_PALETTE      = $1FA00
VERA_SPRITES      = $1FC00 

YM_REG            = $9F40
YM_DATA           = $9F41

; This is currently used to trigger an LA
IO3_BASE_ADDRESS  = $9F60
IO4_BASE_ADDRESS  = $9F80
IO5_BASE_ADDRESS  = $9FA0
IO6_BASE_ADDRESS  = $9FC0
IO7_BASE_ADDRESS  = $9FE0

; Kernal (ZP usage (from MooingLemur 2023-08-27)

; $02-$22 are safe if you never call 16 bit kernal calls
; $22-$7F are completely safe
; $80-$A8 must be left alone, otherwise the kernal breaks, in particular, DOS is breaking.
; $A9-$FF can be used if you dont use the floating point lib or intend to return to basic (cold start BASIC is fine, though)

; KERNAL/DOS/BASIC/etc bank 0 vars

; KEYMAP:   start = $A000, size = $0800; # the current keyboard mapping table
; KVARSB0:  start = $A800, size = $0400; # there is some space free here
; VECB0:    start = $AC00, size = $0020; # for misc vectors, stable addresses
; BVARSB0:  start = $AD00, size = $00C0; # BASIC expansion variables, few used
; AUDIOBSS: start = $ADC0, size = $0040; # audio bank scratch space and misc state
; BAUDIO:   start = $AE00, size = $0100; # YM2151 shadow for audio routines
; DOSDAT:   start = $B000, size = $0F00; # there is some space free here, too
; USERPARM: start = $BF00, size = $0100; # Reserved param passing area for user progs

; Kernal API functions
SETNAM            = $FFBD  ; set filename
SETLFS            = $FFBA  ; Set LA, FA, and SA
LOAD              = $FFD5  ; Load a file into main memory or VRAM
CHROUT            = $FFD2  ; print a character
