from PIL import Image
import sys

def buildmap(img_width,img_height,tile_width,tile_height):
    output = open("MAP{:02d}{:02d}.BIN".format(tile_width,tile_height), "wb")
    word = bytearray(2)
    output.write(word)

    start_col = int((640 - img_width) / (tile_width*2))
    num_cols = int(img_width / tile_width)
    start_row = int((480 - img_height) / (tile_height*2))
    num_rows = int(img_height / tile_height)
    all_cols = 128 if (tile_width == 8) else 64
    all_rows = 64 if (tile_height == 8) else 32

    for i in range(0,start_row):
        for j in range(0,all_cols):
            output.write(word)
        
    do_hflip = False
    do_vflip = False
    vstep = 1
    vrange_from = start_row
    vrange_to = start_row+num_rows
    if (do_vflip):
        vstep = -1
        vrange_from = start_row+num_rows-1
        vrange_to = start_row-1
        
    for i in range(vrange_from, vrange_to, vstep):
        for j in range(0,start_col):
            output.write(word)
      
        htile_increment = num_rows
        hstart_tile_index = 1 + i - start_row
        if (do_hflip):
            htile_increment = -num_rows
            hstart_tile_index = 1 + i - start_row + (num_rows * (num_cols-1))
            
        tile_index = hstart_tile_index
        for j in range(0,num_cols):
            word[0] = tile_index & 0xFF
            word[1] = ((tile_index & 0x300) >> 8) 
            if do_hflip:
                word[1] |= 0x04
            if do_vflip:
                word[1] |= 0x08
            output.write(word)
            tile_index = tile_index+htile_increment

        word = bytearray(2)
        for j in range(start_col+num_cols,all_cols):
            output.write(word)

    for i in range(start_row+num_rows,all_rows):
        for j in range(1,all_cols):
            output.write(word)


if len(sys.argv) < 2:
    print("Usage: python ", sys.argv[0], " [image filename]")
    sys.exit()

srcdata = Image.open(sys.argv[1])

if (srcdata.width > 640) or (srcdata.height > 480):
    print("Error: Image must fit within 640x480 screen")
    sys.exit()

if (srcdata.width % 16 > 0) or (srcdata.height % 16 > 0):
    print("Error: Image dimensions must be evenly divisble by 16 pixels")
    sys.exit()

pixels = srcdata.width * srcdata.height

if pixels > 94208:
    print("Error: Image is too large - can't be more than 94,208 pixels")
    sys.exit()

if pixels > 65536:
    print("Warning: Image is too large for 8x8 tile map - will repeat")
elif pixels > 16384:
    print("Warning: Image is too large for 8x8 1bpp tile map - will repeat")

img8bpp = srcdata.convert(mode='P', dither=Image.Dither.FLOYDSTEINBERG, palette=Image.Palette.ADAPTIVE, colors=256)
img4bpp = srcdata.convert(mode='P', dither=Image.Dither.FLOYDSTEINBERG, palette=Image.Palette.ADAPTIVE, colors=16)
img2bpp = srcdata.convert(mode='P', dither=Image.Dither.FLOYDSTEINBERG, palette=Image.Palette.ADAPTIVE, colors=4)
img1bpp = srcdata.convert(mode='P', dither=Image.Dither.FLOYDSTEINBERG, palette=Image.Palette.ADAPTIVE, colors=2)

px8bpp = img8bpp.load()
px4bpp = img4bpp.load()
px2bpp = img2bpp.load()
px1bpp = img1bpp.load()

# 16-pixel wide
tiles816 = bytearray(srcdata.width * srcdata.height)
tiles416 = bytearray(int(srcdata.width * srcdata.height / 2))
tiles216 = bytearray(int(srcdata.width * srcdata.height / 4))
tiles116 = bytearray(int(srcdata.width * srcdata.height / 8))
for col in range(0,int(srcdata.width/16)):
    for y in range(0,srcdata.height):
        for x in range(0,16):
            index = x+y*16+col*16*srcdata.height
            imgx = x+col*16
            tiles816[index] = px8bpp[imgx,y]
            index = int(index / 2)
            tiles416[index] = tiles416[index] | (px4bpp[imgx,y] << (4 - 4*(x % 2)))
            index = int(index / 2)
            tiles216[index] = tiles216[index] | (px2bpp[imgx,y] << (6 - 2*(x % 4)))
            index = int(index / 2)
            tiles116[index] = tiles116[index] | (px1bpp[imgx,y] << (7 - (x % 8)))

header = bytearray(2)

output = open("8BPP16W.BIN", "wb")
output.write(header)
output.write(tiles816)

output = open("4BPP16W.BIN", "wb")
output.write(header)
output.write(tiles416)

output = open("2BPP16W.BIN", "wb")
output.write(header)
output.write(tiles216)

output = open("1BPP16W.BIN", "wb")
output.write(header)
output.write(tiles116)

# 8-pixel wide
tiles88 = bytearray(srcdata.width * srcdata.height)
tiles48 = bytearray(srcdata.width * int(srcdata.height / 2))
tiles28 = bytearray(srcdata.width * int(srcdata.height / 4))
tiles18 = bytearray(srcdata.width * int(srcdata.height / 8))
for col in range(0,int(srcdata.width/8)):
    for y in range(0,srcdata.height):
        for x in range(0,8):
            index = x+y*8+col*8*srcdata.height
            imgx = x+col*8
            tiles88[index] = px8bpp[imgx,y]
            index = int(index / 2)
            tiles48[index] = tiles48[index] | (px4bpp[imgx,y] << (4 - 4*(x % 2)))
            index = int(index / 2)
            tiles28[index] = tiles28[index] | (px2bpp[imgx,y] << (6 - 2*(x % 4)))
            index = int(index / 2)
            tiles18[index] = tiles18[index] | (px1bpp[imgx,y] << (7 - x))

header = bytearray(2)

output = open("8BPP8W.BIN", "wb")
output.write(header)
output.write(tiles88)

output = open("4BPP8W.BIN", "wb")
output.write(header)
output.write(tiles48)

output = open("2BPP8W.BIN", "wb")
output.write(header)
output.write(tiles28)

output = open("1BPP8W.BIN", "wb")
output.write(header)
output.write(tiles18)

# palettes
pal8 = bytearray()
pal4 = bytearray()
pal2 = bytearray()
pal1 = bytearray()

i = 0
for val in img8bpp.palette.getdata()[1]:
    if (i < 768):
        if (i % 3) == 0:
            red = (val & 0xF0) >> 4
        if (i % 3) == 1:
            green = val & 0xF0
        if (i % 3) == 2:
            pal8.append(green | (val & 0xF0) >> 4)
            pal8.append(red)
        i = i+1
output = open("8PAL.BIN", "wb")
output.write(header)
output.write(pal8)

i = 0
for val in img4bpp.palette.getdata()[1]:
    if (i < 48):
        if (i % 3) == 0:
            red = (val & 0xF0) >> 4
        if (i % 3) == 1:
            green = val & 0xF0
        if (i % 3) == 2:
            pal4.append(green | (val & 0xF0) >> 4)
            pal4.append(red)
        i = i+1
output = open("4PAL.BIN", "wb")
output.write(header)
output.write(pal4)

i = 0
for val in img2bpp.palette.getdata()[1]:
    if (i < 12):
        if (i % 3) == 0:
            red = (val & 0xF0) >> 4
        if (i % 3) == 1:
            green = val & 0xF0
        if (i % 3) == 2:
            pal2.append(green | (val & 0xF0) >> 4)
            pal2.append(red)
        i = i+1
output = open("2PAL.BIN", "wb")
output.write(header)
output.write(pal2)

i = 0
for val in img1bpp.palette.getdata()[1]:
    if (i < 6):
        if (i % 3) == 0:
            red = (val & 0xF0) >> 4
        if (i % 3) == 1:
            green = val & 0xF0
        if (i % 3) == 2:
            pal1.append(green | (val & 0xF0) >> 4)
            pal1.append(red)
        i = i+1
output = open("1PAL.BIN", "wb")
output.write(header)
output.write(pal1)

# maps
buildmap(srcdata.width, srcdata.height,8,8)
buildmap(srcdata.width, srcdata.height,8,16)
buildmap(srcdata.width, srcdata.height,16,8)
buildmap(srcdata.width, srcdata.height,16,16)
