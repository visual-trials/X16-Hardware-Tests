from PIL import Image
import hashlib
import sys
from operator import itemgetter

# FIXME: 
source_image_filename_prefix = "C:/ffmpeg/output/output_" # 0001.png"
#source_image_filename_prefix = "Walker/output_" # 0001.png"
video_data_filename = "walker_sdcard.img"
nr_of_frames = 100
#nr_of_frames = 157
image_width = 320
image_height = 136

# FIXME: Load audio binary as array: https://stackoverflow.com/questions/41498630/how-to-read-binary-file-data-into-arrays



def get_color_str(pixel):
    red = pixel[0]
    red = red & 0xF0

    green = pixel[1]
    green = green & 0xF0

    blue = pixel[2]
    blue = blue & 0xF0
    
    color_str = format(red, "02x") + format(green, "02x") + format(blue, "02x") 
    
    return (color_str, (red, green, blue))
    
def add_frame_data_to_video_data(video_data, frame_pixels, frame_colors_to_palette_index):

    # We add 6 sectors of audio (6 * 512 bytes)
    # We add 1 sector of palette (1 * 512 bytes)
    # We add 30 sectors of video (30 * 512 bytes = 48 lines of 320px)
    # We add 3 sectors of audio (2 * 512 + 70 audio bytes + 186 dummy/filler bytes)
    # We add 55 sectors of video (55 * 512 bytes = 88 lines of 320px)
    
    # FIXME: add REAL audio data!
    for n in range(6*512):
        video_data.append(250)

    # FIXME: add REAL palette data!
#    for n in range(1*512):
#        video_data.append(0)

    for y in range(0, 48):
        for x in range(image_width):
            pixel = frame_pixels[x, y]
            (color_str, rgb) = get_color_str(pixel)
            palette_color_index = frame_colors_to_palette_index[color_str]
            video_data.append(palette_color_index)
            
    # FIXME: add REAL audio data!
    for n in range(3*512):
        video_data.append(255)
            
    for y in range(48, 136):
        for x in range(image_width):
            pixel = frame_pixels[x, y]
            (color_str, rgb) = get_color_str(pixel)
            palette_color_index = frame_colors_to_palette_index[color_str]
            video_data.append(palette_color_index)
    

def get_free_palette_color_index(used_palette_color_indexes, current_frame_index):
    free_palette_color_index = None
    for palette_color_index in used_palette_color_indexes:
        # If the frame is still available or is used by a frame before the previous frame, its free
        (frame_index, rgb) = used_palette_color_indexes[palette_color_index]
        if ((frame_index is None) or
             frame_index < current_frame_index - 1):
             free_palette_color_index =  palette_color_index
             break
            
    return free_palette_color_index
    
def get_rgb_from_color_str(color_str):
    red_value = int(color_str[0:2], 16)
    green_value = int(color_str[2:4], 16)
    blue_value = int(color_str[4:6], 16)
    
    return (red_value, green_value, blue_value)
    
def get_score(color_str, pixel):
    red_value = int(color_str[0:2], 16)
    green_value = int(color_str[2:4], 16)
    blue_value = int(color_str[4:6], 16)
    
    score_color = 0
    score_color += abs(red_value - pixel[0])
    score_color += abs(green_value - pixel[1])
    score_color += abs(blue_value - pixel[2])
    
    return score_color
    
def find_closely_matching_color(pixel, frame_colors_to_palette_index):
    
    # We try to find a color that closely matches (since there is no more room to create a new color)
    closely_matching_palette_color_index = None
    
    best_score = 9999
    # We are simply iterating over all colors and take the best matching color
    for color_str in current_frame_colors_to_palette_index:
        palette_color_index = current_frame_colors_to_palette_index[color_str]
        
        score_color = get_score(color_str, pixel)
        
        if (score_color < best_score):
            closely_matching_palette_color_index = palette_color_index
            best_score = score_color
    
    return (closely_matching_palette_color_index, best_score)
    
            
# FIXME: we should instead try to find a *good matching* 256-color (or 128-color?) palette!

video_data = []
initial_palette_colors = []

current_frame_colors_to_palette_index = {}

used_palette_color_indexes = {}
# FIXME: we might want to make the black color available for (nearly dark) pixels!
used_palette_color_indexes[0] = ( 999999, None )  # Note: we dont want to touch color 0 (it is now used by frame 999999, we its never freed up)
for palette_color_index in range(1,256):
    used_palette_color_indexes[palette_color_index] = (None, None) # no frame index, no color

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
        
        (color_str, rgb) = get_color_str(pixel)

        if color_str in current_frame_colors_to_palette_index:
            pass
        else:
            current_frame_colors_to_palette_index[color_str] = palette_color_index
            initial_palette_colors.append(rgb)
            used_palette_color_indexes[palette_color_index] = (frame_index, rgb)
            palette_color_index += 1
            
            # If we exceed 255 for the first frame, we need to deal with that
            if palette_color_index > 255:
                # FIXME: we need to be able to deal with this situation!
                sys.exit("First frame has more than 255 colors!")
            
# We add the data of the first frame to the video data
add_frame_data_to_video_data(video_data, frame_pixels, current_frame_colors_to_palette_index)
        
added_frame_palette_colors_per_frame = []
for frame_index in range(1, nr_of_frames):

    source_image_filename = source_image_filename_prefix + format(frame_index + 1, "04d") + ".png"
    
    # creating a image object
    im = Image.open(source_image_filename)
    frame_pixels = im.load()
    
    added_frame_palette_colors = []

    # FIXME: I think we are now rounding *DOWN* pixels (24 bits) to rgb12-values. We should consider rounding NORMALLY?

    # print(used_palette_color_indexes)
    
    colors_that_need_palette_color_index = {}
    colors_that_already_have_palette_color_index = {}
    for y in range(image_height):
        for x in range(image_width):
            pixel = frame_pixels[x, y]
            
            (color_str, rgb) = get_color_str(pixel)
            
            if ((color_str in colors_that_need_palette_color_index) or
               (color_str in colors_that_already_have_palette_color_index)):
                continue
            
            if color_str in current_frame_colors_to_palette_index:
                old_palette_color_index = current_frame_colors_to_palette_index[color_str]
                (old_frame_index, old_rgb) = used_palette_color_indexes[old_palette_color_index]
                
                (old_color_str, old_rgb) = get_color_str(old_rgb)
                if (old_color_str != color_str):
                    # Not a perfect match, we get the current score
                    score = get_score(old_color_str, rgb)
                    
                    # We are re-CLAIMING this imperfect color!
                    used_palette_color_indexes[old_palette_color_index] = (frame_index, old_rgb)
                else:
                    # Perfect match
                    score = 0
                    
                    # We are re-CLAIMING this perfect color!
                    used_palette_color_indexes[old_palette_color_index] = (frame_index, old_rgb)

                colors_that_already_have_palette_color_index[color_str] = score
            else:
                    
                (palette_color_index, score) = find_closely_matching_color(pixel, current_frame_colors_to_palette_index)
                
                if palette_color_index is None:
                    # FIXME: we need to be able to deal with this situation!
                    sys.exit("Could not find a free (or closely matching) palette color index!")
                    
                colors_that_need_palette_color_index[color_str] = score
            
    colors_that_need_palette_color_index_sorted = sorted(colors_that_need_palette_color_index.items(), key=lambda item: item[1], reverse=True)
    print("colors that need palette color index: " + str(len(colors_that_need_palette_color_index_sorted)))
    #print(colors_that_need_palette_color_index_sorted)
    for (color_str, score) in colors_that_need_palette_color_index_sorted:
    
        rgb = get_rgb_from_color_str(color_str)
        
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
            used_palette_color_indexes[palette_color_index] = (frame_index, rgb)
            added_frame_palette_colors.append((palette_color_index, rgb))
        else:
            # If we dont have an EXACT match of the color AND we dont have room for a new color, we need to find a closely matching color
            
            # FIXME: in a LATER frame we want to replace this color with the EXACT color. We dont do that now. So this color can stay a litte off for a long time!
            (palette_color_index, score) = find_closely_matching_color(rgb, current_frame_colors_to_palette_index)
            
            if palette_color_index is None:
                # FIXME: we need to be able to deal with this situation!
                sys.exit("Could not find a free (or closely matching) palette color index!")
        
            current_frame_colors_to_palette_index[color_str] = palette_color_index
            (old_frame_index, old_rgb) = used_palette_color_indexes[palette_color_index]
            used_palette_color_indexes[palette_color_index] = (frame_index, old_rgb)

                
    colors_that_already_have_palette_color_index_sorted = sorted(colors_that_already_have_palette_color_index.items(), key=lambda item: item[1], reverse=True)
    print("colors that already have palette color index: " + str(len(colors_that_already_have_palette_color_index_sorted)))
    #print(colors_that_already_have_palette_color_index_sorted)
    for (color_str, score) in colors_that_already_have_palette_color_index_sorted:
    
        rgb = get_rgb_from_color_str(color_str)
        
        if score != 0:
        
            # We have a *close* palette color. So we want to try to create a *exact* palette color 
        
            # We need a NEW color, so we need a FREE palette_color_index!
            palette_color_index = get_free_palette_color_index(used_palette_color_indexes, frame_index)
            
            if palette_color_index is not None:
                print("improving color: " + color_str)

                # The to-be-improved color is going to have its own unique value, but it first needs to be detached from the close value
                del current_frame_colors_to_palette_index[color_str]

                # We have to remove the color_string that used this old color_palette_index
                # FIXME: this is SLOW!
                color_strings = list(current_frame_colors_to_palette_index.keys())
                for check_color_str in color_strings:
                    if (current_frame_colors_to_palette_index[check_color_str] == palette_color_index):
                        # print('deleting old color: ' + check_color_str)
                        del current_frame_colors_to_palette_index[check_color_str]
                
                current_frame_colors_to_palette_index[color_str] = palette_color_index
                used_palette_color_indexes[palette_color_index] = (frame_index, rgb)
                added_frame_palette_colors.append((palette_color_index, rgb))
            
            else:
                # There is no more room, we stop trying to improve colors
                print("could not improve colors anymore, due to lack of room")
                
                # Nothing left to do: we use the (old) close color, its the best we can do (we already re-claimed it for this frame)
                
                # FIXME: SPEED: we should probably BREAK here!
                # pass
                break
        
        else:
            # If we already have a perfect score there is nothing left to do for this color (we already re-claimed it for this frame)
            pass
        
    
    '''
    # We first determine all unique 12-bit COLORS, so we can re-index the image (pixels) with the new color indexes
    for y in range(image_height):
        for x in range(image_width):
            pixel = frame_pixels[x, y]
            
            (color_str, rgb) = get_color_str(pixel)
            
            if color_str in current_frame_colors_to_palette_index:
                old_palette_color_index = current_frame_colors_to_palette_index[color_str]
                (old_frame_index, old_rgb) = used_palette_color_indexes[old_palette_color_index]
                
                (old_color_str, old_rgb) = get_color_str(old_rgb)
                if (old_color_str != color_str):
                    # print(old_color_str + " <-> " + color_str)
                
                    # We have a *close* palette color. So we want to try to create a *exact* palette color 
                
                    # We need a NEW color, so we need a FREE palette_color_index!
                    palette_color_index = get_free_palette_color_index(used_palette_color_indexes, frame_index)
                    
                    if palette_color_index is not None:
                        print("improving color: " + color_str)

                        # The to-be-improved color is going to have its own unique value, but it first needs to be detached from the close value
                        del current_frame_colors_to_palette_index[color_str]

                        # We have to remove the color_string that used this old color_palette_index
                        # FIXME: this is SLOW!
                        color_strings = list(current_frame_colors_to_palette_index.keys())
                        for check_color_str in color_strings:
                            if (current_frame_colors_to_palette_index[check_color_str] == palette_color_index):
                                # print('deleting old color: ' + check_color_str)
                                del current_frame_colors_to_palette_index[check_color_str]
                        
                        current_frame_colors_to_palette_index[color_str] = palette_color_index
                        used_palette_color_indexes[palette_color_index] = (frame_index, rgb)
                        added_frame_palette_colors.append((palette_color_index, rgb))
                    
                    else:
                        # There is no more room, we stop trying to improve colors
                        # print("could not improve colors anymore, due to lack of room")
                        
                        # We fould the (old) close color, its the best we can do
                        used_palette_color_indexes[old_palette_color_index] = (frame_index, old_rgb)
                
                else:
                    # We fould the exact color, all is ok
                    used_palette_color_indexes[old_palette_color_index] = (frame_index, old_rgb)
            else:
                # We need a NEW color, so we need a FREE palette_color_index!
                palette_color_index = get_free_palette_color_index(used_palette_color_indexes, frame_index)
                
                if palette_color_index is not None:
                    # We have to remove the color_string that used this old color_palette_index
                    # FIXME: this is SLOW! -> USE palette_color_index_used_by_frame_colors instead!
                    color_strings = list(current_frame_colors_to_palette_index.keys())
                    for check_color_str in color_strings:
                        if (current_frame_colors_to_palette_index[check_color_str] == palette_color_index):
                            # print('deleting old color: ' + check_color_str)
                            del current_frame_colors_to_palette_index[check_color_str]
                            del palette_color_index_used_by_frame_colors[palette_color_index][check_color_str]

                    
                    current_frame_colors_to_palette_index[color_str] = palette_color_index
                    palette_color_index_used_by_frame_colors[palette_color_index] = {}
                    palette_color_index_used_by_frame_colors[palette_color_index][color_str] = True
                    used_palette_color_indexes[palette_color_index] = (frame_index, rgb)
                    added_frame_palette_colors.append((palette_color_index, rgb))
                else:
                    # If we cant find an EXACT match of the color AND we dont have room for a new color, we need to find a closely matching color
                    
                    # FIXME: in a LATER frame we want to replace this color with the EXACT color. We dont do that now. So this color can stay a litte off for a long time!
                    (palette_color_index, score) = find_closely_matching_color(pixel, current_frame_colors_to_palette_index)
                    
                    if palette_color_index is None:
                        # FIXME: we need to be able to deal with this situation!
                        sys.exit("Could not find a free (or closely matching) palette color index!")
                
                    current_frame_colors_to_palette_index[color_str] = palette_color_index
                    palette_color_index_used_by_frame_colors[palette_color_index][color_str] = True
                    (old_frame_index, old_rgb) = used_palette_color_indexes[palette_color_index]
                    used_palette_color_indexes[palette_color_index] = (frame_index, old_rgb)
    '''

    if False:
        nr_of_palette_colors_used_in_current_frame = 0
        for palette_color_index in used_palette_color_indexes:
            (check_frame_index, rgb) = used_palette_color_indexes[palette_color_index]
            if (check_frame_index == frame_index):
                nr_of_palette_colors_used_in_current_frame += 1
        print("Nr of palette colors used in current frame: " + str(nr_of_palette_colors_used_in_current_frame))
        
    
            
    # print(current_frame_colors_to_palette_index)
    
    # We add the pixels of this frame to the video pixel data
    add_frame_data_to_video_data(video_data, frame_pixels, current_frame_colors_to_palette_index)
    
    # print(used_palette_color_indexes)
    #
    added_frame_palette_colors_per_frame.append(added_frame_palette_colors)
    print(frame_index)

print()



# Printing out asm for initial palette:
palette_string = "palette_data: \n"
for rgb in initial_palette_colors:
    red = rgb[0]
    green = rgb[1]
    blue = rgb[2]

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
        rgb = palette_color[1]
        
        red = rgb[0]
        green = rgb[1]
        blue = rgb[2]

        red = red >> 4
        blue = blue >> 4
        palette_changes_string += ",  "
        palette_changes_string += "$" + format(palette_color_index, "02x") + ", "
        palette_changes_string += "$" + format(green | blue,"02x") + ", "
        palette_changes_string += "$" + format(red,"02x")
        
    palette_changes_string += "\n"

print(palette_changes_string)

    
videoFile = open(video_data_filename, "wb")
videoFile.write(bytearray(video_data))
videoFile.close()
print("video pixel data written to file: " + video_data_filename)


