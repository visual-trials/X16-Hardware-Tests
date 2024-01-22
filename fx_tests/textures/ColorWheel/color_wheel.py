# To install pygame: pip install pygame      (my version: pygame-2.1.2)
from PIL import Image
import pygame
import math
import time
import random

random.seed(10)

DRAW_NEW_PALETTE = True
SHOW_12BIT_PALETTE = True
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



# Generating your own 'color wheel':

# - determine the distance between two points (this is the length of the side of all diamand shapes): its around 72px? (for 1600x1600 picture)
# - determine all points:
#   - start at the top point (x = 0*sin(angle), y = -72*cos(angle))
#   - next point is calculated by changing the angle
#   - store the angle (from the middle) to each point (this is a lookup table, which loops)
#   - the next ring points (n+2) can be calculated by taking the *two* n->n+1 vectors  *adding* them together


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


colors_24bit = []
for brightness_index in range(11):

    radius = radius_per_brightness_index[brightness_index]
        
    for hue_angle_index in range(0, 36):

        if (brightness_index % 2 == 0): 
            hue_angle = math.radians(hue_angle_index * 10 + 5)
        else:
            hue_angle = math.radians(hue_angle_index * 10)
    
        x_offset = math.sin(hue_angle)
        y_offset = - math.cos(hue_angle)
        
        sample_point_x = int(center_x + x_offset*radius)
        sample_point_y = int(center_y + y_offset*radius)
        
        sample_color = frame_buffer.get_at((sample_point_x, sample_point_y))
        colors_24bit.append(sample_color)
        
        mark_point_color = (0xFF, 0xFF, 0x00)
        pygame.draw.rect(frame_buffer, mark_point_color, pygame.Rect(sample_point_x, sample_point_y, 4, 4))
        
    
    # print(x_offset, y_offset)




frame_buffer_on_screen_x = 0
frame_buffer_on_screen_y = 0

# FIXME: screen.fill((0,0,0))
screen.fill((255,255,255))
# IMPORANT: we scale to a SQUARE here!
#screen.blit(pygame.transform.scale(frame_buffer, (screen_height*scale, screen_height*scale)), (frame_buffer_on_screen_x, frame_buffer_on_screen_y))





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
            
            diamond_width = 8
            diamond_height = 8
            
            x = diamond_width // 2
            y = 0
            
            for clr_idx in range(396):
            
                #if clr_idx >= len(colors_12bit):
                #    continue

                color_24bit = colors_24bit[clr_idx]
                if (SHOW_12BIT_PALETTE):
                    r = color_24bit[0]
                    g = color_24bit[1]
                    b = color_24bit[2]

                    # 8 bit to 4 bit conversion (for each channel)
                    r = int((r * 15 + 135)) >> 8
                    g = int((g * 15 + 135)) >> 8
                    b = int((b * 15 + 135)) >> 8
                    
                    new_12bit_color = (r,g,b)
                    
                    # 4 bit to 8 bit (for each channel)
                    r = new_12bit_color[0] * 17
                    g = new_12bit_color[1] * 17
                    b = new_12bit_color[2] * 17
                    
                    color_24bit = (r,g,b)
                    
                left_diamond_x = x
                middle_diamond_x = x + diamond_width // 2
                right_diamond_x = x + diamond_width
                top_diamond_y = y
                middle_diamond_y = y + diamond_height // 2
                bottom_diamond_y = y + diamond_height
                
                diamond_polygon = [
                    (middle_diamond_x*scale, top_diamond_y*scale), 
                    (right_diamond_x*scale, middle_diamond_y*scale), 
                    (middle_diamond_x*scale, bottom_diamond_y*scale), 
                    (left_diamond_x*scale, middle_diamond_y*scale), 
                ]

                pygame.draw.polygon(screen, color_24bit, diamond_polygon)
                # pygame.draw.rect(screen, color_24bit, pygame.Rect(x*scale, y*scale, 8*scale, 8*scale))
                
                # if (byte_index % 16 == 0 and byte_index != 0):
                if (clr_idx % 36 == 35):
                    y += diamond_height // 2
                    if ((clr_idx // 36) % 2 == 0):
                        x = 0
                    else:
                        x = diamond_width // 2
                else:
                    x += diamond_width

        
        pygame.display.update()
        
        #time.sleep(0.01)
   
        
    pygame.quit()


    
run()
