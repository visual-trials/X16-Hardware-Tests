from PIL import Image
import hashlib

# creating a image object
im = Image.open(r"SuperMarioKartMapMushroomCup1_clean.png")
px = im.load()


# We first determine all unique 12-bit COLORS, so we can re-index the image (pixels) with the new color indexes

new_colors = []
unique_12bit_colors = {}
old_color_index_to_new_color_index = []

old_color_index = 0
new_color_index = 16  # We start at index 16!
byte_index = 0
nr_of_palette_bytes = 3*256
palette_bytes = im.getpalette()
while (byte_index < nr_of_palette_bytes):
    red = palette_bytes[byte_index]
    red = red & 0xF0
    byte_index += 1

    green = palette_bytes[byte_index]
    green = green & 0xF0
    byte_index += 1

    blue = palette_bytes[byte_index]
    blue = blue & 0xF0
    byte_index += 1
    
    color_str = format(red, "02x") + format(green, "02x") + format(blue, "02x") 
    
    if color_str in unique_12bit_colors:
        old_color_index_to_new_color_index.append(unique_12bit_colors.get(color_str))
    else:
        old_color_index_to_new_color_index.append(new_color_index)
        unique_12bit_colors[color_str] = new_color_index
        new_colors.append((red, green, blue))
        new_color_index += 1
    
    old_color_index += 1
    
# print(new_colors)
# print(old_color_index_to_new_color_index)
    
    
# Printing out asm for palette:

# DEBUG: print(palette_bytes)

palette_string = ""
for new_color in new_colors:
    red = new_color[0]
    green = new_color[1]
    blue = new_color[2]

    red = red >> 4
    blue = blue >> 4
    
    palette_string += "  .byte "
    palette_string += "$" + format(green | blue,"02x") + ", "
    palette_string += "$" + format(red,"02x")
    palette_string += "\n"

print(palette_string)


tile_index = 0
unique_tiles = {}
tile_map = []
tiles_pixel_data = []

# WORKAROUND: making sure tile 0 is a grass tile! (we use tile 0,127 for this)
tile_pixels_as_string = ""
tile_x = 0
tile_y = 127
tile_pixel_data = []
for y_in_tile in range(8):
    for x_in_tile in range(8):
        new_pixel_color = old_color_index_to_new_color_index[px[tile_x*8+x_in_tile, tile_y*8+y_in_tile]]
        tile_pixels_as_string += str(new_pixel_color)
        tile_pixel_data.append(new_pixel_color)
unique_tiles[tile_pixels_as_string] = tile_index
tiles_pixel_data.append(tile_pixel_data)
tile_index += 1

for tile_y in range(128):
    tile_map.append([])
    for tile_x in range(128):
        tile_map[tile_y].append([])
        tile_pixels_as_string = ""
        tile_pixel_data = []
        for y_in_tile in range(8):
            for x_in_tile in range(8):
                new_pixel_color = old_color_index_to_new_color_index[px[tile_x*8+x_in_tile, tile_y*8+y_in_tile]]
                tile_pixels_as_string += str(new_pixel_color)
                tile_pixel_data.append(new_pixel_color)
        if (tile_pixels_as_string in unique_tiles):
            tile_map[tile_y][tile_x] = unique_tiles.get(tile_pixels_as_string)
        else:
            unique_tiles[tile_pixels_as_string] = tile_index
            tiles_pixel_data.append(tile_pixel_data)
            tile_map[tile_y][tile_x] = tile_index
            tile_index += 1

# Printing out asm for tilemap:
tilemap_asm_string = ""
mario_tile_map = []
for tile_y in range(128):
    tilemap_asm_string += "  .byte "
    for tile_x in range(128):
        tile_index = tile_map[tile_y][tile_x]
        mario_tile_map.append(tile_index)
        tilemap_asm_string += "$" + format(tile_index,"02x") + ", "
    tilemap_asm_string += "\n"

# print(tilemap_asm_string)

tableFile = open("mario_tile_map.bin", "wb")
tableFile.write(bytearray(mario_tile_map))
tableFile.close()
print("tile map written to file")

# Printing out tile data:

tiles_pixel_asm_string = ""
mario_tile_pixel_data = []
for tile_pixel_data in tiles_pixel_data:
    tiles_pixel_asm_string += "  .byte "
    for tile_pixel in tile_pixel_data:
        mario_tile_pixel_data.append(tile_pixel)
        tiles_pixel_asm_string += "$" + format(tile_pixel,"02x") + ", "
    tiles_pixel_asm_string += "\n"

#print(tiles_pixel_asm_string)

# FIXME: we might want to PAD this file until its 16kB long!
tableFile = open("mario_tile_pixel_data.bin", "wb")
tableFile.write(bytearray(mario_tile_pixel_data))
tableFile.close()

print("tile data written to file")

print("nr of unique tiles: " + str(len(unique_tiles.keys())))
