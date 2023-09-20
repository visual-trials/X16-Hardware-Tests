from PIL import Image
import hashlib
import sys

# FIXME: 
source_image_filename_prefix = "Walker/output_" # 0001.png"
video_pixel_data_filename = "walker_sdcard.img"
nr_of_frames = 157
image_width = 320
image_height = 136


def get_color_str(pixel):
    red = pixel[0]
    red = red & 0xF0

    green = pixel[1]
    green = green & 0xF0

    blue = pixel[2]
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
    
    
def find_closely_matching_color(pixel, frame_colors_to_palette_index):
    
    # We try to find a color that closely matches (since there is no more room to create a new color)
    closely_matching_palette_color_index = None
    
    best_score = 9999
    # We are simply iterating over all colors and take the best matching color
    for color_str in current_frame_colors_to_palette_index:
        palette_color_index = current_frame_colors_to_palette_index[color_str]
        
        red_value = int(color_str[0:2], 16)
        green_value = int(color_str[2:4], 16)
        blue_value = int(color_str[4:6], 16)
        
        score_color = 0
        score_color += abs(red_value - pixel[0])
        score_color += abs(green_value - pixel[1])
        score_color += abs(blue_value - pixel[2])
        
        #print(color_str, red_value, green_value, blue_value)
        #print(pixel)
        #print(score_color)
        
        if (score_color < best_score):
            closely_matching_palette_color_index = palette_color_index
            best_score = score_color
    
    
    '''
    # We try several closely matching colors: red (0) +1/-1, green (1) +1/-1, blue (2) +1/-1
    delta_tries = [(1,0,0),(0,1,0),(0,0,1),(-1,0,0),(0,-1,0),(0,0,-1), 
                   (1,1,0),(0,1,1),(1,0,1),(-1,-1,0),(0,-1,-1),(-1,0,-1),
                   (1,-1,0),(0,1,-1),(1,0,-1),(-1,1,0),(0,-1,1),(-1,0,1),
                   (-1,1,1),(1,-1,-1),(1,1,-1),(-1,-1,1),(1,-1,1),(-1,1,-1),
                   (1,1,1),(-1,-1,-1)]
    
    for (delta_red, delta_green, delta_blue) in delta_tries:
        red = pixel[0]
        red = red & 0xF0

        green = pixel[1]
        green = green & 0xF0

        blue = pixel[2]
        blue = blue & 0xF0
        
        if (delta_red > 0):
            red += delta_red*16
            if red > 255:
                continue
        elif (delta_red < 0):
            red += delta_red*16
            if red < 0:
                continue
                
        if (delta_green > 0):
            green += delta_green*16
            if green > 255:
                continue
        elif (delta_green < 0):
            green += delta_green*16
            if green < 0:
                continue
                
        if (delta_blue > 0):
            blue += delta_blue*16
            if blue > 255:
                continue
        elif (delta_blue < 0):
            blue += delta_blue*16
            if blue < 0:
                continue
   
        color_str = format(red, "02x") + format(green, "02x") + format(blue, "02x") 
        
        (orig_color_str, orig_red, orig_green, orig_blue) = get_color_str(pixel)
        #print("trying to find color for: " + orig_color_str + ", trying: " + color_str)
        
        if color_str in current_frame_colors_to_palette_index:
            closely_matching_palette_color_index = current_frame_colors_to_palette_index[color_str]
            # print("found closely matching color for: " + orig_color_str + ", namely: " + color_str)
            break
    '''
    
    return closely_matching_palette_color_index
    
            
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
            
            # If we exceed 255 for the first frame, we need to deal with that
            if palette_color_index > 255:
                # FIXME: we need to be able to deal with this situation!
                sys.exit("First frame has more than 255 colors!")
            
# We add the pixels of the first frame to the video pixel data
add_frame_pixels_to_video_pixel_data(video_pixel_data, frame_pixels, current_frame_colors_to_palette_index)
        
        
    

added_frame_palette_colors_per_frame = []
for frame_index in range(1, nr_of_frames):

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
                
                if palette_color_index is not None:
                    # We have to remove the color_string that used this old color_palette_index
                    # FIXME: this is SLOW!
                    color_strings = list(current_frame_colors_to_palette_index.keys())
                    for check_color_str in color_strings:
                        if (current_frame_colors_to_palette_index[check_color_str] == palette_color_index):
                            # print('deleting old color: ' + check_color_str)
                            del current_frame_colors_to_palette_index[check_color_str]
                    
                    current_frame_colors_to_palette_index[color_str] = palette_color_index
                    used_palette_color_indexes[palette_color_index] = frame_index
                    added_frame_palette_colors.append((palette_color_index, red, green, blue))
                else:
                    # If we cant find an EXACT match of the color AND we dont have room for a new color, we need to find a closely matching color
                    
                    # FIXME: in a LATER frame we want to replace this color with the EXACT color. We dont do that now. So this color can stay a litte off for a long time!
                    palette_color_index = find_closely_matching_color(pixel, current_frame_colors_to_palette_index)
                    
                    if palette_color_index is None:
                        # FIXME: we need to be able to deal with this situation!
                        sys.exit("Could not find a free (or closely matching) palette color index!")
                
                    current_frame_colors_to_palette_index[color_str] = palette_color_index
                    used_palette_color_indexes[palette_color_index] = frame_index

    if False:
        nr_of_palette_colors_used_in_current_frame = 0
        for palette_color_index in used_palette_color_indexes:
            check_frame_index = used_palette_color_indexes[palette_color_index]
            if (check_frame_index == frame_index):
                nr_of_palette_colors_used_in_current_frame += 1
        print("Nr of palette colros used in current frame: " + str(nr_of_palette_colors_used_in_current_frame))
            
    # print(current_frame_colors_to_palette_index)
    
    # We add the pixels of this frame to the video pixel data
    add_frame_pixels_to_video_pixel_data(video_pixel_data, frame_pixels, current_frame_colors_to_palette_index)
    
    # print(used_palette_color_indexes)
    #
    added_frame_palette_colors_per_frame.append(added_frame_palette_colors)
    print(frame_index)

print()



# Printing out asm for initial palette:
palette_string = "palette_data: \n"
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

palette_string += "end_of_palette_data: \n"
print(palette_string)

print()

palette_changes_string = "palette_changes_per_frame: \n"
for added_frame_palette_colors in added_frame_palette_colors_per_frame:
    nr_of_changed_colors = len(added_frame_palette_colors)
    
    # Note: we are ommiting the trailing comma here, so we can start with a comma for each color
    palette_changes_string += "  .byte " + "$" + format(nr_of_changed_colors, "02x") + "  "
    
    for palette_color in added_frame_palette_colors:
        palette_color_index = palette_color[0]
        red = palette_color[1]
        green = palette_color[2]
        blue = palette_color[3]

        red = red >> 4
        blue = blue >> 4
        palette_changes_string += ",  "
        palette_changes_string += "$" + format(palette_color_index, "02x") + ", "
        palette_changes_string += "$" + format(green | blue,"02x") + ", "
        palette_changes_string += "$" + format(red,"02x")
        
    palette_changes_string += "\n"

print(palette_changes_string)

# FIXME!
# video_pixel_data = video_pixel_data * 30
    
videoFile = open(video_pixel_data_filename, "wb")
videoFile.write(bytearray(video_pixel_data))
videoFile.close()
print("video pixel data written to file: " + video_pixel_data_filename)


