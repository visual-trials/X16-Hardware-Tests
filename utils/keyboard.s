; Keyboard key code retreival and intepretation

; Also see '_kbd_scan' inside kernal/drivers/x16/ps2kbd.s for proper handling of compact key codes (in the kernal, but only does 'key down' events)
; Also see the keycode table: https://github.com/X16Community/x16-rom/blob/master/keymap/keycode_table.txt

; -- Required CONSTANTS: --
; NR_OF_KBD_KEY_CODE_BYTES = $18   (ZP variable example)
; KEYBOARD_KEY_CODE_BUFFER = $7FE0 (memory address example)   ; 32 bytes (can be much less, since compact key codes are used now)
; KEYBOARD_STATE           = $6D00 (memory address example)   ; 128 bytes (state for each key of the keyboard)
; KEYBOARD_EVENTS          = $6D80 (memory address example)   ; 128 bytes (event for each key of the keyboard)
;   Note: i2c.s must also be included!
; -------------------------

SMC_I2C_ADDR  = $42
KEYBOARD_KEY_CODE_REGISTER = $07

; Key codes for specific keys:
KEY_CODE_SPACE_BAR        = $3D
KEY_CODE_UP_ARROW         = $53
KEY_CODE_DOWN_ARROW       = $54
KEY_CODE_LEFT_ARROW       = $4F
KEY_CODE_RIGHT_ARROW      = $59


init_keyboard:
    jsr reset_key_code_buffer
    jsr clear_keyboard_state
    rts

reset_key_code_buffer:
    stz NR_OF_KBD_KEY_CODE_BYTES
    rts
    
clear_keyboard_state:
    ldx #0
next_key_state:
    stz KEYBOARD_STATE, x
    inx
    cpx #128
    bne next_key_state
    rts

clear_keyboard_events:
    ldx #0
next_key_event:
    stz KEYBOARD_EVENTS, x
    inx
    cpx #128
    bne next_key_event
    rts
    
retrieve_keyboard_key_codes:

    ldx #SMC_I2C_ADDR
    
key_code_next:
    ldy #KEYBOARD_KEY_CODE_REGISTER
    jsr i2c_read_byte
    
    bcs key_code_read_error
    beq key_code_zero

    ldy NR_OF_KBD_KEY_CODE_BYTES
    sta KEYBOARD_KEY_CODE_BUFFER, y

    ; increment nr of bytes in buffer
    iny
    tya
    and #%00011111                ; making sure buffer of 32 bytes is never exceeded
    sta NR_OF_KBD_KEY_CODE_BYTES

    bra key_code_next
    
key_code_read_error:   
    ; TODO: ignoring read errors for now
key_code_zero:
    rts
    

update_keyboard_state:

    ; We look through the buffer byte by byte and update the corresponding key in the keyboard state array (whether a key is up or down atm)
    ; We go on doing that until we have looked through the entire buffer key code buffer.
    
    ; FIXME: we *could* record whether a key as come down AND up in the same key code buffer. We could record this in the KEYBOARD_STATE byte somehow.
    
    ldy #0
read_next_key_code:

    ; -- Loop through the buffer of key codes --
    cpy NR_OF_KBD_KEY_CODE_BYTES
    beq done_reading_keycode_bytes

    ; Read the key code from the buffer
    lda KEYBOARD_KEY_CODE_BUFFER, y
    bmi key_was_up
    
key_was_down:
    ; We store the keyup event
    tax
    lda #1  
    sta KEYBOARD_STATE, x   ; 1 = key is down
    
    lda KEYBOARD_EVENTS, x
    ora #%00000001
    sta KEYBOARD_EVENTS, x  ; 1 = key just went down
    
    bra key_state_stored
    
key_was_up:
    ; We store the keyup event
    and #%01111111          ; remove the key up bit
    tax
    stz KEYBOARD_STATE, x   ; 0 = key is up
    
    lda KEYBOARD_EVENTS, x
    ora #%00000010
    sta KEYBOARD_EVENTS, x  ; 2 = key just went up
    
key_state_stored:
    
    iny
    bra read_next_key_code
    
done_reading_keycode_bytes:

    ; We reset the key code buffer afterwards
    jsr reset_key_code_buffer
    
    rts
    
    
wait_until_spacebar_press:
    ; We reset the keyboard state, since we do not expect it to be properly reset when using this procedure regurlarly
    ; NOTE: clearing the keyboard state should only be done during DEBUG, since it destroys all state of the keyboard!
    jsr clear_keyboard_state

keep_waiting_until_spacebar_press:
    jsr retrieve_keyboard_key_codes
    jsr update_keyboard_state
    
    ldx #KEY_CODE_SPACE_BAR
    lda KEYBOARD_STATE, x
    beq keep_waiting_until_spacebar_press
    
    rts
    
