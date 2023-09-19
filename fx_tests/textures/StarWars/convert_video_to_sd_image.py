from PIL import Image
import hashlib
import sys

# FIXME: 
source_image_filename_prefix = "Walker/output_" # 0001.png"
video_pixel_data_filename = "walker_sdcard.img"
nr_of_frames = 72
image_width = 320
image_height = 136


def get_color_str(pixel):
    red = pixel[0]
# FIXME: HACK: removing another BIT to make sure we dont have TOO MANY colors!
    # red = red & 0xE0
    red = red & 0xF0

    green = pixel[1]
# FIXME: HACK: removing another BIT to make sure we dont have TOO MANY colors!
    # green = green & 0xE0
    green = green & 0xF0

    blue = pixel[2]
# FIXME: HACK: removing another BIT to make sure we dont have TOO MANY colors!
    # blue = blue & 0xE0
    blue = blue & 0xF0
    
    color_str = format(red, "02x") + format(green, "02x") + format(blue, "02x") 
    
    return (color_str, red, green, blue)
    
def add_frame_pixels_to_video_pixel_data(video_pixel_data, frame_pixels, frame_colors_to_palette_index):

    for y in range(image_height):
        for x in range(image_width):
            pixel = frame_pixels[x, y]
            (color_str, red, green, blue) = get_color_str(pixel)
            palette_color_index = frame_colors_to_palette_index[color_str]
            video_pixel_data.append(palette_color_index)

def get_free_palette_color_index(used_palette_color_indexes, current_frame_index):
    free_palette_color_index = None
    for palette_color_index in used_palette_color_indexes:
        # If the frame is still available or is used by a frame before the previous frame, its free
        if ((used_palette_color_indexes[palette_color_index] is None) or
             used_palette_color_indexes[palette_color_index] < current_frame_index - 1):
             free_palette_color_index =  palette_color_index
             break
            
    return free_palette_color_index
            
# FIXME: we should instead try to find a *good matching* 256-color (or 128-color?) palette!

video_pixel_data = []
initial_palette_colors = []

current_frame_colors_to_palette_index = {}

used_palette_color_indexes = {}
used_palette_color_indexes[0] = 999999  # Note: we dont want to touch color 0 (it is now used by frame 999999, we its never freed up)
for palette_color_index in range(1,256):
    used_palette_color_indexes[palette_color_index] = None

# -- Determine the initial palette colors --

palette_color_index = 1

frame_index = 0
source_image_filename = source_image_filename_prefix + format(frame_index + 1, "04d") + ".png"

# creating a image object
im = Image.open(source_image_filename)
frame_pixels = im.load()

# We first determine all initially unique 12-bit COLORS, so we can create an initial palette
for y in range(image_height):
    for x in range(image_width):
        pixel = frame_pixels[x, y]
        
        (color_str, red, green, blue) = get_color_str(pixel)

        if color_str in current_frame_colors_to_palette_index:
            pass
        else:
            current_frame_colors_to_palette_index[color_str] = palette_color_index
            initial_palette_colors.append((red, green, blue))
            used_palette_color_indexes[palette_color_index] = frame_index
            palette_color_index += 1
            
            # FIXME: what if we exceed 255 here?
            
# We add the pixels of the first frame to the video pixel data
add_frame_pixels_to_video_pixel_data(video_pixel_data, frame_pixels, current_frame_colors_to_palette_index)
        
        
# print(used_palette_color_indexes)

    
# Printing out asm for initial palette:
palette_string = ""
for palette_color in initial_palette_colors:
    red = palette_color[0]
    green = palette_color[1]
    blue = palette_color[2]

    red = red >> 4
    blue = blue >> 4
    
    palette_string += "  .byte "
    palette_string += "$" + format(green | blue,"02x") + ", "
    palette_string += "$" + format(red,"02x")
    palette_string += "\n"

print(palette_string)


# FIXME! 
# for frame_index in range(1, nr_of_frames):
for frame_index in range(1, 10):

    source_image_filename = source_image_filename_prefix + format(frame_index + 1, "04d") + ".png"
    
    # creating a image object
    im = Image.open(source_image_filename)
    frame_pixels = im.load()
    
    added_frame_palette_colors = []
    
    # print(used_palette_color_indexes)

    # We first determine all unique 12-bit COLORS, so we can re-index the image (pixels) with the new color indexes
    for y in range(image_height):
        for x in range(image_width):
            pixel = frame_pixels[x, y]
            
            (color_str, red, green, blue) = get_color_str(pixel)
            
# FIXME: we are NOT USING old_color_index_to_new_color_index right now!
            if color_str in current_frame_colors_to_palette_index:
                palette_color_index = current_frame_colors_to_palette_index[color_str]
                used_palette_color_indexes[palette_color_index] = frame_index
            else:
                # We need a NEW color, so we need a FREE palette_color_index!
                palette_color_index = get_free_palette_color_index(used_palette_color_indexes, frame_index)
                
                if palette_color_index is None:
                    # FIXME: we need to be able to deal with this situation!
                    sys.exit("Could not find a free palette color index!")
                
                # We have to remove the color_string that used this old color_palette_index
                # FIXME: this is SLOW!
                color_strings = list(current_frame_colors_to_palette_index.keys())
                for check_color_str in color_strings:
                    if (current_frame_colors_to_palette_index[check_color_str] == palette_color_index):
                        print('deleting old color: ' + check_color_str)
                        del current_frame_colors_to_palette_index[check_color_str]
                
                current_frame_colors_to_palette_index[color_str] = palette_color_index
                used_palette_color_indexes[palette_color_index] = frame_index
                added_frame_palette_colors.append((palette_color_index, red, green, blue))
                
            
    # print(current_frame_colors_to_palette_index)
    
    # We add the pixels of this frame to the video pixel data
    add_frame_pixels_to_video_pixel_data(video_pixel_data, frame_pixels, current_frame_colors_to_palette_index)
    
    # print(used_palette_color_indexes)
    print(added_frame_palette_colors)

# FIXME!
video_pixel_data = video_pixel_data * 30
    
videoFile = open(video_pixel_data_filename, "wb")
videoFile.write(bytearray(video_pixel_data))
videoFile.close()
print("video pixel data written to file: " + video_pixel_data_filename)


