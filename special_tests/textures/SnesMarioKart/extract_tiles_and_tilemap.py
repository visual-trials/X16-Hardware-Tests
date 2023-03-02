from PIL import Image
import hashlib

# creating a image object
im = Image.open(r"SuperMarioKartMapMushroomCup1_clean.png")
px = im.load()


# FIXME: we should FIRST determine all unique 12-bit COLORS, and re-index the image with the new color indexes!
# FIXME: we should FIRST determine all unique 12-bit COLORS, and re-index the image with the new color indexes!
# FIXME: we should FIRST determine all unique 12-bit COLORS, and re-index the image with the new color indexes!


tile_index = 0
unique_tiles = {}
tile_map = []



# WORKAROUND: making sure tile 0 is a grass tile! (we use tile 0,127 for this)
tile_pixels_as_string = ""
tile_x = 0
tile_y = 127
for x_in_tile in range(8):
    for y_in_tile in range(8):
        tile_pixels_as_string += str(px[tile_x*8+x_in_tile, tile_y*8+y_in_tile])
unique_tiles[tile_pixels_as_string] = 0

for tile_y in range(128):
    tile_map.append([])
    for tile_x in range(128):
        tile_map[tile_y].append([])
        tile_pixels_as_string = ""
        for x_in_tile in range(8):
            for y_in_tile in range(8):
                tile_pixels_as_string += str(px[tile_x*8+x_in_tile, tile_y*8+y_in_tile])
        if (tile_pixels_as_string in unique_tiles):
            tile_map[tile_y][tile_x] = unique_tiles.get(tile_pixels_as_string)
        else:
            unique_tiles[tile_pixels_as_string] = tile_index
            tile_map[tile_y][tile_x] = tile_index
            tile_index += 1

# Printing out asm for palette:

index = 0
nr_of_palette_bytes = 3*256
palette_bytes = im.getpalette()

# DEBUG: print(palette_bytes)

palette_string = ""
while (index < nr_of_palette_bytes):
    red = palette_bytes[index]
    red = red & 0xF0
    red = red >> 4
    index += 1
    
    green = palette_bytes[index]
    green = green & 0xF0
    index += 1
    # print(hex(green))
    # print(format(blue | green,"02x"))
    
    blue = palette_bytes[index]
    blue = blue & 0xF0
    blue = blue >> 4
    index += 1
    # print(hex(blue))
    
    # print(format(red,"02x"))
    palette_string += "  .byte "
    palette_string += "$" + format(green | blue,"02x") + ", "
    palette_string += "$" + format(red,"02x")
    palette_string += "\n"

print(palette_string)

# Printing out asm for tilemap:
tilemap_asm_string = ""
for tile_y in range(128):
    tilemap_asm_string += "  .byte "
    for tile_x in range(128):
        tile_index = tile_map[tile_y][tile_x]
        tilemap_asm_string += "$" + format(tile_index,"02x") + ", "
    tilemap_asm_string += "\n"

print(tilemap_asm_string)
