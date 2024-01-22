# To install pygame: pip install pygame      (my version: pygame-2.1.2)
from PIL import Image
import pygame
import math
import time
import random

random.seed(10)

DRAW_NEW_PALETTE = False
SHOW_ORG_PICTURE = False

source_image_filename = "color_wheel.png"
# FIXME: we probably want to use a higher resolution source file!
source_image_width = 1600
source_image_height = 1600
bitmap_filename = "COLORWHEEL.DAT"

screen_width = 320
screen_height = 240

scale = 3

# creating a image object for the background
#im_org = Image.open(source_image_filename)
#px_org = im_org.load()
im_surface_org = pygame.image.load(source_image_filename)


'''
img8bpp = im_org.convert(mode='P', dither=Image.Dither.FLOYDSTEINBERG, palette=Image.Palette.ADAPTIVE, colors=256)
px = img8bpp.load()

palette_bytes = img8bpp.getpalette()

# We first convert to 12-bit COLORS
colors_12bit = []

byte_index = 0
nr_of_palette_bytes = 3*256
while (byte_index < nr_of_palette_bytes):
    try:
        r = palette_bytes[byte_index]
    except:
        r = 0

    byte_index += 1

    try:
        g = palette_bytes[byte_index]
    except:
        g = 0

    byte_index += 1

    try:
        b = palette_bytes[byte_index]
    except:
        b = 0

    byte_index += 1

    # 8 bit to 4 bit conversion (for each channel)
    r = (r * 15 + 135) >> 8
    g = (g * 15 + 135) >> 8
    b = (b * 15 + 135) >> 8
    
    new_12bit_color = (r,g,b)
    colors_12bit.append(new_12bit_color)
    
    


# Printing out asm for palette:
palette_string = ""
for new_color in colors_12bit:
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
'''

background_color = (0,0,0)


pygame.init()

pygame.display.set_caption('X16 Color wheel')
screen = pygame.display.set_mode((screen_width*scale, screen_height*scale))
clock = pygame.time.Clock()

frame_buffer = pygame.Surface((source_image_width, source_image_height))
frame_buffer.blit(im_surface_org, (0, 0))


'''
bitmap_data = []
# FIXME: we now use 0 as BLACK, but in the bitmap a DIFFERENT color index is used as BLACK!
#hor_margin_pixels = [0] * 32
for source_y in range(source_image_height):

    for source_x in range(source_image_width):

        pixel_color_index = px[source_x, source_y]
        
        bitmap_data.append(pixel_color_index)
    
tableFile = open(bitmap_filename, "wb")
tableFile.write(bytearray(bitmap_data))
tableFile.close()
print("bitmap written to file: " + bitmap_filename)
'''



screen.fill(background_color)

'''
for source_y in range(source_image_height):
    for source_x in range(source_image_width):

        y_screen = source_y
        x_screen = source_x
        
        pixel_color_24bit = None
        if (SHOW_ORG_PICTURE):
            pixel_color_24bit = px_org[source_x, source_y]
        else:
            pixel_color_12bit = colors_12bit[px[source_x, source_y]]
            
            # 4 bit to 8 bit (for each channel)
            r = pixel_color_12bit[0] * 17
            g = pixel_color_12bit[1] * 17
            b = pixel_color_12bit[2] * 17

            pixel_color_24bit = (r,g,b)
        
        pygame.draw.rect(screen, pixel_color_24bit, pygame.Rect(x_screen*scale, y_screen*scale, scale, scale))
'''



center_x = source_image_width // 2
center_y = source_image_height // 2


radius_per_brightness_index = [
    80,
    148,
    216,
    282,
    349,
    408,
    475,
    526,
    582,
    624,
    670
]

for brightness_index in range(11):

    radius = radius_per_brightness_index[brightness_index]
    
    for hue_angle_index in range(0, 36):
# FIXME: we need to offset the hue_angle by HALF for even/odd brightnesses!
        if (brightness_index % 2 == 0): 
            hue_angle = math.radians(hue_angle_index * 10 + 5)
        else:
            hue_angle = math.radians(hue_angle_index * 10)
    
        x_offset = math.sin(hue_angle)
        y_offset = - math.cos(hue_angle)
        
        sample_point_color = (0xFF, 0xFF, 0x00)
        sample_point_x = center_x + x_offset*radius
        sample_point_y = center_y + y_offset*radius
        
        pygame.draw.rect(frame_buffer, sample_point_color, pygame.Rect(sample_point_x, sample_point_y, 4, 4))
        
    
    # print(x_offset, y_offset)




frame_buffer_on_screen_x = 0
frame_buffer_on_screen_y = 0

screen.fill((0,0,0))
# IMPORANT: we scale to a SQUARE here!
screen.blit(pygame.transform.scale(frame_buffer, (screen_height*scale, screen_height*scale)), (frame_buffer_on_screen_x, frame_buffer_on_screen_y))





def run():

    running = True
    
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
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
            
                
                
        if (DRAW_NEW_PALETTE):
            # screen.fill(background_color)
            
            x = 0
            y = 0
            
            for clr_idx in range(256):
            
                #if clr_idx >= len(colors_12bit):
                #    continue
            
                pixel_color = colors_12bit[clr_idx]
                
                pygame.draw.rect(screen, pixel_color, pygame.Rect(x*scale, y*scale, 8*scale, 8*scale))
                
                # if (byte_index % 16 == 0 and byte_index != 0):
                if (clr_idx % 16 == 15):
                    y += 8
                    x = 0
                else:
                    x += 8

        
        pygame.display.update()
        
        #time.sleep(0.01)
   
        
    pygame.quit()


    
run()
