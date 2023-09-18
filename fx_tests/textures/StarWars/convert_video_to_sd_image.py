from PIL import Image
import hashlib

# FIXME: 
source_image_filename_prefix = "Walker/output_" # 0001.png"
video_pixel_data_filename = "walker_sdcard.img"
nr_of_frames = 72
image_width = 320
image_height = 136

new_colors = []
unique_12bit_colors = {}
old_color_index_to_new_color_index = []

old_color_index = 0
new_color_index = 1
byte_index = 0
nr_of_palette_bytes = 3*256


def get_color_str(pixel):
    red = pixel[0]
# FIXME: HACK: removing another BIT to make sure we dont have TOO MANY colors!
    # red = red & 0xE0
    red = red & 0xF0

    green = pixel[1]
# FIXME: HACK: removing another BIT to make sure we dont have TOO MANY colors!
    green = green & 0xE0
    # green = green & 0xF0

    blue = pixel[2]
# FIXME: HACK: removing another BIT to make sure we dont have TOO MANY colors!
    blue = blue & 0xE0
    # blue = blue & 0xF0
    
    color_str = format(red, "02x") + format(green, "02x") + format(blue, "02x") 
    
    return (color_str, red, green, blue)
    


# FIXME: we should instead try to find a *good matching* 256-color (or 128-color?) palette!

for file_index in range(nr_of_frames):

    source_image_filename = source_image_filename_prefix + format(file_index + 1, "04d") + ".png"
    
    # creating a image object
    im = Image.open(source_image_filename)
    px = im.load()

    # We first determine all unique 12-bit COLORS, so we can re-index the image (pixels) with the new color indexes
    for y in range(image_height):
        for x in range(image_width):
            pixel = px[x, y]
            
            (color_str, red, green, blue) = get_color_str(pixel)

# FIXME: we are NOT USING old_color_index_to_new_color_index right now!
            if color_str in unique_12bit_colors:
                old_color_index_to_new_color_index.append(unique_12bit_colors.get(color_str))
            else:
                old_color_index_to_new_color_index.append(new_color_index)
                unique_12bit_colors[color_str] = new_color_index
                new_colors.append((red, green, blue))
                new_color_index += 1
            
            old_color_index += 1
    

    # print(new_color_index)

    
# Printing out asm for palette:

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


video_pixel_data = []
for file_index in range(nr_of_frames):

    source_image_filename = source_image_filename_prefix + format(file_index + 1, "04d") + ".png"
    
    # creating a image object
    im = Image.open(source_image_filename)
    px = im.load()
    
    # frame_pixel_data = []
    for y in range(image_height):
        for x in range(image_width):
            pixel = px[x, y]
            (color_str, red, green, blue) = get_color_str(pixel)
            new_color_index = unique_12bit_colors[color_str]
            video_pixel_data.append(new_color_index)
            
    # video_pixel_data.append(frame_pixel_data)


videoFile = open(video_pixel_data_filename, "wb")
videoFile.write(bytearray(video_pixel_data))
videoFile.close()
print("video pixel data written to file: " + video_pixel_data_filename)


