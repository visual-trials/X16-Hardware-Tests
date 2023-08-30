
# Then did this: https://lvgl.io/tools/imageconverter  (CF_INDEXED_8_BIT, to c-array, no extra options selected) -> mario_on_kart.c
# Copy pasted the pixel bytes (first replaced 0x with $ in notepad++, add ".byte" and remove trailing comma) directly into assembly -> padding to 32x32 sprite
# and copy-pasted the palette bytes below. NOTE: removed the 4th column containing the ALPHA bytes! (use Alt + mouse)
# This generates the (packed) palette bytes we need in assembly

# NOTE: There are transparent bytes in this picture. So I had to SWAP their color with 00.

# NOTE: I use an palette OFFSET for the sprite, that way I can keep these low numbers

paletteBytes = [
  0x00, 0xf2, 0xff, # 06 -> 00 (filled in with yellow myself)
  0x00, 0x00, 0x00, # 01
  0x00, 0x00, 0xf8, # 02
  0x00, 0x00, 0xa0, # 03
  0x88, 0xa8, 0xe0, # 04
  0x58, 0x78, 0xa8, # 05
  0x78, 0x78, 0x78, # 00 -> 06
  0xe8, 0xe8, 0xc8, # 07
  0x68, 0x68, 0x48, # 08
  0x48, 0x48, 0x28, # 09
  0x28, 0x28, 0x00, # 0A
  0xf8, 0x80, 0x00, # 0B
  0xe0, 0x00, 0x00, # 0C
]

index = 0
nrOfBytes = len(paletteBytes)

paletteString = ""

while (index < nrOfBytes):
    blue = paletteBytes[index]
    blue = blue & 0xF0
    blue = blue >> 4
    index += 1
    # print(hex(blue))
    
    green = paletteBytes[index]
    green = green & 0xF0
    index += 1
    # print(hex(green))
    # print(format(blue | green,"02x"))
    
    red = paletteBytes[index]
    red = red & 0xF0
    red = red >> 4
    index += 1
    # print(format(red,"02x"))
    paletteString += "  .byte "
    paletteString += "$" + format(green | blue,"02x") + ", "
    paletteString += "$" + format(red,"02x")
    paletteString += "\n"

print(paletteString)
