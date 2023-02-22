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

y_in_texture_fraction_corrections_low = []
y_in_texture_fraction_corrections_high = []
x_in_texture_fraction_corrections_low = []
x_in_texture_fraction_corrections_high = []
addresses_in_texture_low = []
addresses_in_texture_high = []
x_sub_pixel_steps_low = []
x_sub_pixel_steps_high = []
y_sub_pixel_steps_low = []
y_sub_pixel_steps_high = []

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

    #for y in range(0, 64):
    #    for x in range(0, 64):
    #        pixel_color = color_by_index[texture[y][x]]
    #        pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
    #        
    #pygame.display.update()
    
    start_y = 32
    end_y = 96
    for y in range(start_y, end_y):
#    for y in range(16, 80):
        start_sx = None
        sx_rotated = None
        sy_rotated = None
        sub_pixel_increment_x = None
        sub_pixel_increment_y = None
        for x in range(-96, 96):
        
            horizon = 0.001
            fov = 96
            
            angle = math.pi * 0.07
#            angle = math.pi * 0.05
#            angle = math.pi * 0.0

            px = x
            py = fov
            pz = y + horizon

            sx = px / pz
            sy = py / pz 
            
            sx_rotated = sx * math.cos(angle) - sy * math.sin(angle)
            sy_rotated = sx * math.sin(angle) + sy * math.cos(angle)            
            
            # When we calculated the second pixel of a row, we know the increment between the first and second pixel
            if (x == -95):
                sub_pixel_increment_x = sx_rotated - previous_sx_rotated
                sub_pixel_increment_y = sy_rotated - previous_sy_rotated
            
            scaling = 64

            # When we calculated the first pixel of a row, we know the start x and y position (in the texture) for the start of that row
            if (x == -96):
                start_sx = sx_rotated
                start_sy = sy_rotated

            pixel_color = color_by_index[texture[int(sy_rotated * scaling) % 64][int(sx_rotated * scaling) % 64]]
            pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
            
            previous_sx_rotated = sx_rotated
            previous_sy_rotated = sy_rotated
            
        pygame.display.update()
        # print(str(y) + ':' +str(sy_rotated) , ' - ', str(start_sx) , ' - ', (-start_sx/96)*64)
        
        # print(sub_pixel_increment_x*64*256, sub_pixel_increment_y*64*256)
        
        y_in_texture = (start_sy * 64) % 64
        x_in_texture = (start_sx * 64) % 64


# FIXME: We want more bits of precision!
        x_sub_pixel_step = int(sub_pixel_increment_x*64*512)
        y_sub_pixel_step = int(sub_pixel_increment_y*64*512)
# FIXME: restore this!
#        x_sub_pixel_step = int(sub_pixel_increment_x*64*256)
#        y_sub_pixel_step = int(sub_pixel_increment_y*64*256)
        
        # x_sub_pixel_step = (-start_sx/96)*64 * 256   
        # print('y in texture: ' + str(y_in_texture) + ' - x in texture: ' + str(x_in_texture) + ' - x,y sub pixel step: ' + str(int(x_sub_pixel_step)) + ',' + str(int(y_sub_pixel_step)))
        
        address_in_texture = int(y_in_texture) * 64 + int(x_in_texture)
        
# FIXME: We want more bits of precision!
#        x_in_texture_fraction_correction = int(((x_in_texture % 1)*512-256)%512)
#        y_in_texture_fraction_correction = int(((y_in_texture % 1)*512-256)%512)
# FIXME: restore this!
        x_in_texture_fraction_correction = int(((x_in_texture % 1)*256-128)%256)
        y_in_texture_fraction_correction = int(((y_in_texture % 1)*256-128)%256)
        
        x_in_texture_fraction_corrections_low.append(x_in_texture_fraction_correction % 256)
        x_in_texture_fraction_corrections_high.append(x_in_texture_fraction_correction // 256)
        
        y_in_texture_fraction_corrections_low.append(y_in_texture_fraction_correction % 256)
        y_in_texture_fraction_corrections_high.append(y_in_texture_fraction_correction // 256)
        
        addresses_in_texture_low.append(address_in_texture % 256)
        addresses_in_texture_high.append(address_in_texture // 256)

        x_sub_pixel_steps_low.append(int(x_sub_pixel_step) % 256)
        x_sub_pixel_steps_high.append(int(x_sub_pixel_step) // 256)
        y_sub_pixel_steps_low.append(int(y_sub_pixel_step) % 256)
        y_sub_pixel_steps_high.append(int(y_sub_pixel_step) // 256)

    # ========= SIMULATING USING THE SAME DATA ==========
    
    for y in range(start_y, end_y):
        y_index = y-start_y
        address_in_texture = addresses_in_texture_low[y_index] + addresses_in_texture_high[y_index]*256
        x_in_texture = address_in_texture % 64
        y_in_texture = address_in_texture // 64
        
        x_start_sub_pixel = 0.5
        y_start_sub_pixel = 0.5

# FIXME: We want more bits of precision!
#        x_sub_pixel_correction = (x_in_texture_fraction_corrections_low[y_index] + x_in_texture_fraction_corrections_high[y_index] * 256) / 512
#        y_sub_pixel_correction = (y_in_texture_fraction_corrections_low[y_index] + y_in_texture_fraction_corrections_high[y_index] * 256) / 512
# FIXME: restore this!
        x_sub_pixel_correction = x_in_texture_fraction_corrections_low[y_index] / 256
        y_sub_pixel_correction = y_in_texture_fraction_corrections_low[y_index] / 256
        
        x_start_sub_pixel = (x_start_sub_pixel + x_sub_pixel_correction) % 1
        y_start_sub_pixel = (y_start_sub_pixel + y_sub_pixel_correction) % 1
        
        x_in_texture += x_start_sub_pixel
        y_in_texture += y_start_sub_pixel
        
# FIXME: we also need to allow NEGATIVE numbers!!

# FIXME: We want more bits of precision!
        x_sub_pixel_step = (x_sub_pixel_steps_low[y_index] + x_sub_pixel_steps_high[y_index] * 256)/512 
        y_sub_pixel_step = (y_sub_pixel_steps_low[y_index] + y_sub_pixel_steps_high[y_index] * 256)/512
# FIXME: restore this!
#        x_sub_pixel_step = (x_sub_pixel_steps_low[y_index] + x_sub_pixel_steps_high[y_index] * 256)/256 # FIXME: We want more bits of precision!
#        y_sub_pixel_step = (y_sub_pixel_steps_low[y_index] + y_sub_pixel_steps_high[y_index] * 256)/256 # FIXME: We want more bits of precision!
        
        for x in range(-96, 96):
     
            pixel_color = color_by_index[texture[int(y_in_texture)][int(x_in_texture)]]
            pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2+192, 2, 2))  # , width=border_width
            
            x_in_texture += x_sub_pixel_step
            y_in_texture += y_sub_pixel_step
            
            x_in_texture = x_in_texture % 64
            y_in_texture = y_in_texture % 64
        
        pygame.display.update()
        
    # ========= / SIMULATING USING THE SAME DATA ==========

# FIXME: we need both high and low corrections!
# FIXME: we need both high and low corrections!
# FIXME: we need both high and low corrections!
    print('x_in_texture_fraction_corrections:')
    print('    .byte ' + ','.join(str(x) for x in x_in_texture_fraction_corrections_low))
    print('y_in_texture_fraction_corrections:')
    print('    .byte ' + ','.join(str(x) for x in y_in_texture_fraction_corrections_low))
        
    print('addresses_in_texture_low:')
    print('    .byte ' + ','.join(str(x) for x in addresses_in_texture_low))
    print('addresses_in_texture_high:')
    print('    .byte ' + ','.join(str(x) for x in addresses_in_texture_high))
        
    print('x_sub_pixel_steps_low:')
    print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_low))
    print('x_sub_pixel_steps_high:')
    print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_high))
        
    print('y_sub_pixel_steps_low:')
    print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_low))
    print('y_sub_pixel_steps_high:')
    print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_high))
        
        
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