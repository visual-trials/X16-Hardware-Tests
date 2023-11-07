# To install pygame: pip install pygame      (my version: pygame-2.1.2)
from PIL import Image
import pygame
import math
# FIXME: remove this
import time

DO_MOVE_LENS = True

source_image_filename = "OtherImage_256x256px.png"
source_image_width = 256
source_image_height = 256
bitmap_filename = "OTHER.BIN"

# creating a image object
im = Image.open(source_image_filename)
# Workaround: the other png does not contain a palette (its RGB) so we convert it to having a palette
im2 = im.convert("P", palette=Image.ADAPTIVE, colors=256)
im = im2
px = im.load()


# We first determine all unique 12-bit COLORS, so we can re-index the image (pixels) with the new color indexes

new_colors = []
unique_12bit_colors = {}
old_color_index_to_new_color_index = []

old_color_index = 0
new_color_index_offset = 16    # We  start at index 16! (preserving the first 16 colors)
new_color_index = new_color_index_offset
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


background_color = (0,0,0)

screen_width = 320
screen_height = 200

lens_size = 80
lens_radius = lens_size/2
lens_zoom = 16

# x,y offsets
lens_offsets = []


def init_lens():

    d = lens_zoom
    d2 = lens_zoom*lens_zoom
    r2 = lens_radius*lens_radius
    
    hlf = int(lens_radius)

    for y in range(int(lens_size)):
        lens_offsets.append([])
        for x in range(int(lens_size)):
            lens_offsets[y].append(None)

    for y in range(hlf):
        y2 = y*y
        for x in range(hlf):
            x2 = x*x
            if ((x2 + y2) <= r2):
                # old way:
                # shift = d / math.sqrt(d2 - (x2 + y2 - r2))
                # x_shift = shift * x - x
                # y_shift = shift * y - y
                
                distance_from_center = math.sqrt(x2 + y2) / lens_radius # distance from center: 0.0 -> 1.0
                
                # We now use the quadratic function to create the lens effect
                distance_from_center *= 0.9
                distance_from_center += 0.1
# FIXME: this is ALMOST correct!
                desired_distance_from_center = distance_from_center * distance_from_center
                
                if distance_from_center > 0:
                    ratio = desired_distance_from_center / distance_from_center
                else:
                    ratio = 1
                    
                if ratio < 0:
                    ratio = 0
                
                x_shift = ratio * x - x
                y_shift = ratio * y - y
                
                
                # Inside the lens the pixel gets shifted according to the quadrant it is in
                lens_offsets[ hlf   + y][ hlf   + x] = (  x_shift,  y_shift)
                lens_offsets[ hlf-1 - y][ hlf   + x] = (  x_shift, -y_shift)
                lens_offsets[ hlf   + y][ hlf-1 - x] = ( -x_shift,  y_shift)
                lens_offsets[ hlf-1 - y][ hlf-1 - x] = ( -x_shift, -y_shift)
            else:
                # Outside the lens there is no distortion/shift
                lens_offsets[ hlf   + y][ hlf   + x] = (0,0)
                lens_offsets[ hlf-1 - y][ hlf   + x] = (0,0)
                lens_offsets[ hlf   + y][ hlf-1 - x] = (0,0)
                lens_offsets[ hlf-1 - y][ hlf-1 - x] = (0,0)


pygame.init()

pygame.display.set_caption('X16 2R Lens test')
screen = pygame.display.set_mode((screen_width*2, screen_height*2))
clock = pygame.time.Clock()

init_lens()


bitmap_data = []
# FIXME: we now use 0 as BLACK, but in the bitmap a DIFFERENT color index is used as BLACK!
hor_margin_pixels = [0] * 32
for source_y in range(source_image_height):

    if (source_y < 32):
        continue
    if (source_y >= 32 + 200):
        continue
        
    bitmap_data += hor_margin_pixels
    for source_x in range(source_image_width):

        pixel_color_index = new_pixel_color = old_color_index_to_new_color_index[px[source_x, source_y]]
        
        bitmap_data.append(pixel_color_index)
        
    bitmap_data += hor_margin_pixels
    
tableFile = open(bitmap_filename, "wb")
tableFile.write(bytearray(bitmap_data))
tableFile.close()
print("bitmap written to file: " + bitmap_filename)


def run():

    running = True
    
    lens_pos_x = 50
    lens_pos_y = 50
    
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        
        if (DO_MOVE_LENS):
            lens_pos_x += 1
            lens_pos_y += 1
            
            if (lens_pos_x > 150):
                lens_pos_x = 40
                lens_pos_y = 40
        
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False

            '''
            # if event.type == pygame.KEYDOWN:
                    
                #if event.key == pygame.K_LEFT:
                #if event.key == pygame.K_RIGHT:
                #if event.key == pygame.K_COMMA:
                #if event.key == pygame.K_PERIOD:
                #if event.key == pygame.K_UP:
                #if event.key == pygame.K_DOWN:
                    
            #if event.type == pygame.MOUSEMOTION: 
                # newrect.center = event.pos
            '''
                
        screen.fill(background_color)

        for source_y in range(source_image_height):
            for source_x in range(source_image_width):

                if (source_y < 32):
                    continue
                if (source_y >= 32 + 200):
                    continue
                    
                y_screen = source_y - 32
                x_screen = source_x + 32
                
                pixel_color = new_pixel_color = new_colors[old_color_index_to_new_color_index[px[source_x, source_y]] - new_color_index_offset]
                
                pygame.draw.rect(screen, pixel_color, pygame.Rect(x_screen*2, y_screen*2, 2, 2))

                
        for lens_y in range(int(lens_size)):
            for lens_x in range(int(lens_size)):
                
                (x_shift, y_shift) = lens_offsets[lens_y][lens_x]
                
                source_y = lens_pos_y + lens_y + y_shift
                source_x = lens_pos_x + lens_x + x_shift
                
                pixel_color = new_pixel_color = new_colors[old_color_index_to_new_color_index[px[source_x, source_y]] - new_color_index_offset]
                
                y_screen = lens_pos_y - 32 + lens_y
                x_screen = lens_pos_x + 32 + lens_x
                
                pygame.draw.rect(screen, pixel_color, pygame.Rect(x_screen*2, y_screen*2, 2, 2))
                
                
        
        pygame.display.update()
        
        time.sleep(0.05)
   
        
    pygame.quit()


    
run()