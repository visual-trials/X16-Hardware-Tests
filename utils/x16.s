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

; TODO: add YM2151 addresses and info

; This is currently used to trigger an LA
IO3_BASE_ADDRESS  = $9F60


