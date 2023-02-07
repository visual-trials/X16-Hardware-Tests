# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
# FIXME: remove this
import time

background_color = (100,0,100)
white_color = (200,200,200)
black_color = (20,20,20)

screen_width = 320*2
screen_height = 240*2

texture = []

y_in_texture_fraction_corrections = []
x_in_texture_fraction_corrections = []
addresses_in_texture_low = []
addresses_in_texture_high = []
x_sub_pixel_steps_low = []
x_sub_pixel_steps_high = []

color_by_index = [ black_color, white_color ]

pygame.init()

pygame.display.set_caption('X16 Mode7 table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

def run():

        
    # filling texture
    for y in range(64):
        texture.append([])
        for x in range(64):
            if (y < 32 and x < 32):
                texture[y].append(1)
            elif (y >= 32 and x >= 32):
                texture[y].append(1)
            else:
                texture[y].append(0)
    
    screen.fill(background_color)

    for y in range(32, 96):
        start_sx = None
        for x in range(-96, 96):
        
            horizon = 0.001
            fov = 96

            px = x
            py = fov
            pz = y + horizon

            sx = px / pz
            sy = py / pz 
            
            if (x == -96):
                start_sx = sx

            scaling = 64
            pixel_color = color_by_index[texture[int(sy * scaling) % 64][int(sx * scaling) % 64]]
            pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
            
        pygame.display.update()
        # print(str(y) + ':' +str(sy) , ' - ', str(start_sx) , ' - ', (-start_sx/96)*64)
        
        y_in_texture = (-sy * 64) % 64
        x_in_texture = (start_sx * 64) % 64
        x_sub_pixel_step = (-start_sx/96)*64 * 256   # FIXME: We want more bits of precision!
        print('y in texture: ' + str(y_in_texture) + ' - x in texture: ' + str(x_in_texture) + ' - x sub pixel step: ' + str(int(x_sub_pixel_step)))
        
        address_in_texture = int(y_in_texture) * 64 + int(x_in_texture)
        x_in_texture_fraction_correction = int(((x_in_texture % 1)*256-128)%256)
        y_in_texture_fraction_correction = int(((y_in_texture % 1)*256-128)%256)
        
        x_in_texture_fraction_corrections.append(x_in_texture_fraction_correction)
        y_in_texture_fraction_corrections.append(y_in_texture_fraction_correction)
        
        addresses_in_texture_low.append(address_in_texture % 256)
        addresses_in_texture_high.append(address_in_texture // 256)
        x_sub_pixel_steps_low.append(int(x_sub_pixel_step) % 256)    # FIXME: We want more bits of precision!
        x_sub_pixel_steps_high.append(int(x_sub_pixel_step) // 256)  # FIXME: We want more bits of precision!


    print('x_in_texture_fraction_corrections:')
    print('    .byte ' + ','.join(str(x) for x in x_in_texture_fraction_corrections))
    print('y_in_texture_fraction_corrections:')
    print('    .byte ' + ','.join(str(x) for x in y_in_texture_fraction_corrections))
        
    print('addresses_in_texture_low:')
    print('    .byte ' + ','.join(str(x) for x in addresses_in_texture_low))
    print('addresses_in_texture_high:')
    print('    .byte ' + ','.join(str(x) for x in addresses_in_texture_high))
        
    print('x_sub_pixel_steps_low:')
    print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_low))
    print('x_sub_pixel_steps_high:')
    print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_high))
        
        
        
    running = True
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False
                
        time.sleep(0.5)
   
        
    pygame.quit()

    

'''
def draw_texture(map_info, map_width, map_height):

    for y in range(nr_of_sqaures_vertical):
        if (y >= map_height):
            continue
        for x in range(nr_of_sqaures_horizontal):
            if (x >= map_width):
                continue
                
                
            pygame.draw.rect(screen, square_color, pygame.Rect(x*grid_size+4, (screen_height-grid_size)-y*grid_size+4, grid_size-8, grid_size-8), width=border_width)
'''

run()