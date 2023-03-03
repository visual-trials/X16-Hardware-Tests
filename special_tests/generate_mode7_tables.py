# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
# FIXME: remove this
import time

background_color = (100,0,100)
white_color = (200,200,200)
black_color = (20,20,20)
blue_color = (20,20,200)
red_color = (200,20,20)
green_color = (20,200,20)
yellow_color = (200,200,20)
purple_color = (200,0,200)

do_draw_orig = True
do_draw_sim = False
do_single_angle = False
do_draw_border_lines = False
    
screen_width = 320*2
screen_height = 240*2

map_width = 32
map_height = map_width

tile_width = 8
tile_height = tile_width

map_pixel_width = map_width * tile_width
map_pixel_height = map_height * tile_height

texture = []

color_by_index = [ black_color, white_color, blue_color, red_color, green_color, yellow_color, purple_color ]

pygame.init()

pygame.display.set_caption('X16 Mode7 table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

def run():

    texture = [[0 for x in range(map_pixel_width)] for y in range(map_pixel_height)] 
        
    # filling texture as a tile map
    for tile_y in range(map_height):
        for tile_x in range(map_width):
            for y in range(tile_height):
                pixel_position_y = tile_y*tile_height + y
                for x in range(tile_width):
                    pixel_position_x = tile_x*tile_width + x
                    if (tile_y == 0 and tile_x == 0):
                        texture[pixel_position_y][pixel_position_x] = 6 # 0:0 = purple
                    elif (tile_y == 1 and tile_x == 1):
                        texture[pixel_position_y][pixel_position_x] = 5 # 1:1 = yellow
                    elif (tile_y % 2 == 0 and tile_x % 2 == 0):
                        texture[pixel_position_y][pixel_position_x] = 1
                    elif (tile_y % 2 == 1 and tile_x % 2 == 1):
                        texture[pixel_position_y][pixel_position_x] = 1
                    else:
                        texture[pixel_position_y][pixel_position_x] = 0
                    if (do_draw_border_lines):
                        if (y == tile_height-1):
                            texture[pixel_position_y][pixel_position_x] = 2
                        elif (y == 0):
                            texture[pixel_position_y][pixel_position_x] = 4
                        elif (x == tile_width-1):
                            texture[pixel_position_y][pixel_position_x] = 3
                        elif (x == 0):
                            texture[pixel_position_y][pixel_position_x] = 5
    
    screen.fill(background_color)

    #for y in range(0, 64):
    #    for x in range(0, 64):
    #        pixel_color = color_by_index[texture[y][x]]
    #        pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
    #        
    #pygame.display.update()
    
    all_angles_y_in_texture_fraction_corrections_low = []
    all_angles_y_in_texture_fraction_corrections_high = []
    all_angles_x_in_texture_fraction_corrections_low = []
    all_angles_x_in_texture_fraction_corrections_high = []
    all_angles_x_pixel_positions_in_map_low = []
    all_angles_x_pixel_positions_in_map_high = []
    all_angles_y_pixel_positions_in_map_low = []
    all_angles_y_pixel_positions_in_map_high = []
    all_angles_addresses_in_texture_low = []
    all_angles_addresses_in_texture_high = []
    all_angles_x_sub_pixel_steps_decr = []
    all_angles_x_sub_pixel_steps_low = []
    all_angles_x_sub_pixel_steps_high = []
    all_angles_y_sub_pixel_steps_decr = []
    all_angles_y_sub_pixel_steps_low = []
    all_angles_y_sub_pixel_steps_high = []

    angle_max = 256
    if do_single_angle:
        angle_max = 1 # This is a workaround/hack to make sure only one angle is drawn/generated
    for angle_index in range(angle_max):

# FIXME: we should put this in a bigger array    
        y_in_texture_fraction_corrections_low = []
        y_in_texture_fraction_corrections_high = []
        x_in_texture_fraction_corrections_low = []
        x_in_texture_fraction_corrections_high = []
        x_pixel_positions_in_map_low = []
        x_pixel_positions_in_map_high = []
        y_pixel_positions_in_map_low = []
        y_pixel_positions_in_map_high = []
        x_sub_pixel_steps_decr = []
        x_sub_pixel_steps_low = []
        x_sub_pixel_steps_high = []
        y_sub_pixel_steps_decr = []
        y_sub_pixel_steps_low = []
        y_sub_pixel_steps_high = []

        scaling = 64
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
                
                if do_single_angle:
                    angle = math.pi * -0.07
                    # angle = math.pi * 0.05
                    # angle = math.pi * 0.0
                else:
                    angle = math.pi*2 * (angle_index / angle_max)

                px = x
                py = fov
                pz = y + horizon

                sx = px / pz
                sy = - py / pz 
                
                sx_rotated = sx * math.cos(angle) - sy * math.sin(angle)
                sy_rotated = sx * math.sin(angle) + sy * math.cos(angle)            
                
                sx_rotated += 17 * 8 / scaling
                sy_rotated += 17 * 8 / scaling
                
                # When we calculated the second pixel of a row, we know the increment between the first and second pixel
                if (x == -95):
                    sub_pixel_increment_x = sx_rotated - previous_sx_rotated
                    sub_pixel_increment_y = sy_rotated - previous_sy_rotated
                
                # When we calculated the first pixel of a row, we know the start x and y position (in the texture) for the start of that row
                if (x == -96):
                    start_sx = sx_rotated
                    start_sy = sy_rotated

                if do_draw_orig:
                    pixel_color = color_by_index[texture[int(sy_rotated * scaling) % map_pixel_height][int(sx_rotated * scaling) % map_pixel_width]]
# FIXME: +96 +64??
                    pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
                
                previous_sx_rotated = sx_rotated
                previous_sy_rotated = sy_rotated
                
            # pygame.display.update()
            # print(str(y) + ':' +str(sy_rotated) , ' - ', str(start_sx) , ' - ', (-start_sx/96)*64)
            
            # print(sub_pixel_increment_x*64*256, sub_pixel_increment_y*64*256)
            
            y_in_texture = (start_sy * scaling) % map_pixel_height
            x_in_texture = (start_sx * scaling) % map_pixel_width


            x_sub_pixel_step = int(sub_pixel_increment_x * scaling * 512)
            y_sub_pixel_step = int(sub_pixel_increment_y * scaling * 512)
            
            # x_sub_pixel_step = (-start_sx/96)*64 * 256   
            # print('y in texture: ' + str(y_in_texture) + ' - x in texture: ' + str(x_in_texture) + ' - x,y sub pixel step: ' + str(int(x_sub_pixel_step)) + ',' + str(int(y_sub_pixel_step)))
            
            x_sub_pixel_step_decr = 0
            if x_sub_pixel_step < 0:
                x_sub_pixel_step = -x_sub_pixel_step
                x_sub_pixel_step_decr = 1
                
            x_sub_pixel_steps_decr.append(x_sub_pixel_step_decr * 128)   # Bit 7 is the DECR bit for the EXTRA X-incrementer of ADDR1 (usually 1), so we multiply by 128 here
            x_sub_pixel_steps_low.append(int(x_sub_pixel_step) % 256)
            x_sub_pixel_steps_high.append(int(x_sub_pixel_step) // 256)
            
            y_sub_pixel_step_decr = 0
            if y_sub_pixel_step < 0:
                y_sub_pixel_step = -y_sub_pixel_step
                y_sub_pixel_step_decr = 1
                
            y_sub_pixel_steps_decr.append(y_sub_pixel_step_decr * 8)  # Bit 3 is the DECR bit for the NORMAL Y-incrementer of ADDR1 (usually 64), so we multiply by 8 here
            y_sub_pixel_steps_low.append(int(y_sub_pixel_step) % 256)
            y_sub_pixel_steps_high.append(int(y_sub_pixel_step) // 256)

            # TODO: give an explanation why we are doing this: 512 - ...
            x_in_texture_fraction_correction = int(((x_in_texture % 1)*512-256)%512)
            if x_sub_pixel_step_decr:
                x_in_texture_fraction_correction = 512 - x_in_texture_fraction_correction
            y_in_texture_fraction_correction = int(((y_in_texture % 1)*512-256)%512)
            if y_sub_pixel_step_decr:
                y_in_texture_fraction_correction = 512 - y_in_texture_fraction_correction
            
            x_in_texture_fraction_corrections_low.append(x_in_texture_fraction_correction % 256)
            x_in_texture_fraction_corrections_high.append(x_in_texture_fraction_correction // 256)
            
            y_in_texture_fraction_corrections_low.append(y_in_texture_fraction_correction % 256)
            y_in_texture_fraction_corrections_high.append(y_in_texture_fraction_correction // 256)
            
            x_pixel_positions_in_map_low.append(int(x_in_texture % 256))
            x_pixel_positions_in_map_high.append(int(x_in_texture // 256))
            y_pixel_positions_in_map_low.append(int(y_in_texture % 256))
            y_pixel_positions_in_map_high.append(int(y_in_texture // 256))
            
            
        # ========= SIMULATING USING THE SAME DATA ==========
        
        if do_draw_sim:
            for y in range(start_y, end_y):
                y_index = y-start_y
                x_in_texture = x_pixel_positions_in_map_low[y_index] + x_pixel_positions_in_map_high[y_index]*256
                y_in_texture = y_pixel_positions_in_map_low[y_index] + y_pixel_positions_in_map_high[y_index]*256
                
                x_start_sub_pixel = 0.5
                y_start_sub_pixel = 0.5

                x_sub_pixel_correction = (x_in_texture_fraction_corrections_low[y_index] + x_in_texture_fraction_corrections_high[y_index] * 256) / 512
                y_sub_pixel_correction = (y_in_texture_fraction_corrections_low[y_index] + y_in_texture_fraction_corrections_high[y_index] * 256) / 512
                
                x_sub_pixel_step = (x_sub_pixel_steps_low[y_index] + x_sub_pixel_steps_high[y_index] * 256)/512 
                if x_sub_pixel_steps_decr[y_index]:
                    x_sub_pixel_step = -x_sub_pixel_step
                    x_sub_pixel_correction = 512 - x_sub_pixel_correction
                y_sub_pixel_step = (y_sub_pixel_steps_low[y_index] + y_sub_pixel_steps_high[y_index] * 256)/512
                if y_sub_pixel_steps_decr[y_index]:
                    y_sub_pixel_step = -y_sub_pixel_step
                    y_sub_pixel_correction = 512 - y_sub_pixel_correction
                
                x_start_sub_pixel = (x_start_sub_pixel + x_sub_pixel_correction) % 1
                y_start_sub_pixel = (y_start_sub_pixel + y_sub_pixel_correction) % 1
                
                x_in_texture += x_start_sub_pixel
                y_in_texture += y_start_sub_pixel
                
                for x in range(-96, 96):
             
                    pixel_color = color_by_index[texture[int(y_in_texture)][int(x_in_texture)]]
# FIXME: +96 +64??
                    pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2+192, 2, 2))  # , width=border_width
                    
                    x_in_texture += x_sub_pixel_step
                    y_in_texture += y_sub_pixel_step
                    
                    x_in_texture = x_in_texture % map_pixel_width
                    y_in_texture = y_in_texture % map_pixel_height
                
                # pygame.display.update()

        # ========= / SIMULATING USING THE SAME DATA ==========

        pygame.display.update()
        
        if do_single_angle:
            print('x_in_texture_fraction_corrections_low:')
            print('    .byte ' + ','.join(str(x) for x in x_in_texture_fraction_corrections_low))
            print('x_in_texture_fraction_corrections_high:')
            print('    .byte ' + ','.join(str(x) for x in x_in_texture_fraction_corrections_high))
            
            print('y_in_texture_fraction_corrections_low:')
            print('    .byte ' + ','.join(str(x) for x in y_in_texture_fraction_corrections_low))
            print('y_in_texture_fraction_corrections_high:')
            print('    .byte ' + ','.join(str(x) for x in y_in_texture_fraction_corrections_high))
                
            print('x_pixel_positions_in_map_low:')
            print('    .byte ' + ','.join(str(x) for x in x_pixel_positions_in_map_low))
            print('x_pixel_positions_in_map_high:')
            print('    .byte ' + ','.join(str(x) for x in x_pixel_positions_in_map_high))
            
            print('y_pixel_positions_in_map_low:')
            print('    .byte ' + ','.join(str(x) for x in y_pixel_positions_in_map_low))
            print('y_pixel_positions_in_map_high:')
            print('    .byte ' + ','.join(str(x) for x in y_pixel_positions_in_map_high))
                
            print('x_sub_pixel_steps_decr:')
            print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_decr))
            print('x_sub_pixel_steps_low:')
            print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_low))
            print('x_sub_pixel_steps_high:')
            print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_high))
                
            print('y_sub_pixel_steps_decr:')
            print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_decr))
            print('y_sub_pixel_steps_low:')
            print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_low))
            print('y_sub_pixel_steps_high:')
            print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_high))
        else:
            all_angles_x_in_texture_fraction_corrections_low += x_in_texture_fraction_corrections_low
            all_angles_x_in_texture_fraction_corrections_high += x_in_texture_fraction_corrections_high
            
            all_angles_y_in_texture_fraction_corrections_low += y_in_texture_fraction_corrections_low
            all_angles_y_in_texture_fraction_corrections_high += y_in_texture_fraction_corrections_high
            
            all_angles_x_pixel_positions_in_map_low += x_pixel_positions_in_map_low
            all_angles_x_pixel_positions_in_map_high += x_pixel_positions_in_map_high
            
            all_angles_y_pixel_positions_in_map_low += y_pixel_positions_in_map_low
            all_angles_y_pixel_positions_in_map_high += y_pixel_positions_in_map_high
            
            all_angles_x_sub_pixel_steps_decr += x_sub_pixel_steps_decr
            all_angles_x_sub_pixel_steps_low += x_sub_pixel_steps_low
            all_angles_x_sub_pixel_steps_high += x_sub_pixel_steps_high
            
            all_angles_y_sub_pixel_steps_decr += y_sub_pixel_steps_decr
            all_angles_y_sub_pixel_steps_low += y_sub_pixel_steps_low
            all_angles_y_sub_pixel_steps_high += y_sub_pixel_steps_high
        
    if not do_single_angle:
        tableFile = open("special_tests/tables/x_in_texture_fraction_corrections_low.bin", "wb")
        tableFile.write(bytearray(all_angles_x_in_texture_fraction_corrections_low))
        tableFile.close()
        tableFile = open("special_tests/tables/x_in_texture_fraction_corrections_high.bin", "wb")
        tableFile.write(bytearray(all_angles_x_in_texture_fraction_corrections_low))
        tableFile.close()
        
        tableFile = open("special_tests/tables/y_in_texture_fraction_corrections_low.bin", "wb")
        tableFile.write(bytearray(all_angles_y_in_texture_fraction_corrections_low))
        tableFile.close()
        tableFile = open("special_tests/tables/y_in_texture_fraction_corrections_high.bin", "wb")
        tableFile.write(bytearray(all_angles_y_in_texture_fraction_corrections_low))
        tableFile.close()
        
        tableFile = open("special_tests/tables/x_pixel_positions_in_map_low.bin", "wb")
        tableFile.write(bytearray(all_angles_x_pixel_positions_in_map_low))
        tableFile.close()
        tableFile = open("special_tests/tables/x_pixel_positions_in_map_high.bin", "wb")
        tableFile.write(bytearray(all_angles_x_pixel_positions_in_map_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/y_pixel_positions_in_map_low.bin", "wb")
        tableFile.write(bytearray(all_angles_y_pixel_positions_in_map_low))
        tableFile.close()
        tableFile = open("special_tests/tables/y_pixel_positions_in_map_high.bin", "wb")
        tableFile.write(bytearray(all_angles_y_pixel_positions_in_map_high))
        tableFile.close()

        tableFile = open("special_tests/tables/x_sub_pixel_steps_decr.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_decr))
        tableFile.close()
        tableFile = open("special_tests/tables/x_sub_pixel_steps_low.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_low))
        tableFile.close()
        tableFile = open("special_tests/tables/x_sub_pixel_steps_high.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_high))
        tableFile.close()

        tableFile = open("special_tests/tables/y_sub_pixel_steps_decr.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_decr))
        tableFile.close()
        tableFile = open("special_tests/tables/y_sub_pixel_steps_low.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_low))
        tableFile.close()
        tableFile = open("special_tests/tables/y_sub_pixel_steps_high.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_high))
        tableFile.close()
        
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