# To install pygame: pip install pygame      (my version: pygame-2.1.2)
from PIL import Image
import pygame
import math
# FIXME: remove this
import time

source_image_filename = "OtherImage_256x256px.png"
source_image_width = 256
source_image_height = 256

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
new_color_index = 0  # FIXME: dont we want to start at index 16!?
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

pygame.init()

pygame.display.set_caption('X16 2R Lens test')
screen = pygame.display.set_mode((screen_width*2, screen_height*2))
clock = pygame.time.Clock()


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
                
        screen.fill(background_color)

        for source_y in range(source_image_height):
            for source_x in range(source_image_width):

                if (source_y < 32):
                    continue
                if (source_y >= 32 + 200):
                    continue
                    
                y_screen = source_y - 32
                x_screen = source_x + 32
                
                pixel_color = new_pixel_color = new_colors[old_color_index_to_new_color_index[px[source_x, source_y]]]
                
                pygame.draw.rect(screen, pixel_color, pygame.Rect(x_screen*2, y_screen*2, 2, 2))
            
        
        pygame.display.update()
        
        time.sleep(0.1)
   
        
    pygame.quit()


    
run()