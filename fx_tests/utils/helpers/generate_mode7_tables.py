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
# FIXME: disable this to create tables!
do_single_angle = True
do_draw_border_lines = False
do_clip = False

max_x_position_in_map = 2048 # The affine helper allows for a max position of 11 bits
max_y_position_in_map = max_x_position_in_map

screen_width = 320
screen_height = 240

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
screen = pygame.display.set_mode((screen_width*2, screen_height*2))
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
    
    all_angles_x_subpixel_positions_in_map_low = []
    all_angles_x_subpixel_positions_in_map_high = []
    all_angles_y_subpixel_positions_in_map_low = []
    all_angles_y_subpixel_positions_in_map_high = []
    all_angles_x_pixel_positions_in_map_low = []
    all_angles_x_pixel_positions_in_map_high = []
    all_angles_y_pixel_positions_in_map_low = []
    all_angles_y_pixel_positions_in_map_high = []
    all_angles_addresses_in_texture_low = []
    all_angles_addresses_in_texture_high = []
    all_angles_x_sub_pixel_steps_low = []
    all_angles_x_sub_pixel_steps_high = []
    all_angles_y_sub_pixel_steps_low = []
    all_angles_y_sub_pixel_steps_high = []

    angle_max = 256
    if do_single_angle:
        angle_max = 1 # This is a workaround/hack to make sure only one angle is drawn/generated
    for angle_index in range(angle_max):

        x_subpixel_positions_in_map_low = []
        x_subpixel_positions_in_map_high = []
        y_subpixel_positions_in_map_low = []
        y_subpixel_positions_in_map_high = []
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

        
        width = 256
#        width = 192
        half_width = width // 2
        left_margin = (screen_width - width) // 2

#        scaling = 96
#        scaling = 80  # = height?
        scaling = 20
#        scaling = 64  # = height?
        start_y = 32 - 16
        end_y = 112 - 16
#        end_y = 96 - 16
        for y in range(start_y, end_y):
    #    for y in range(16, 80):
    
            start_sx = None
            sx_rotated = None
            sy_rotated = None
            sub_pixel_increment_x = None
            sub_pixel_increment_y = None
            for x in range(-half_width, half_width):
            
                horizon = 0.001
# FOV = half_width??
# FOV = half_width??
# FOV = half_width??
#                fov = 96
                fov = half_width
                
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
                if (x == -(half_width-1)):
                    sub_pixel_increment_x = sx_rotated - previous_sx_rotated
                    sub_pixel_increment_y = sy_rotated - previous_sy_rotated
                
                # When we calculated the first pixel of a row, we know the start x and y position (in the texture) for the start of that row
                if (x == -half_width):
                    start_sx = sx_rotated
                    start_sy = sy_rotated

                if do_draw_orig:
                    if do_clip and (int(sy_rotated * scaling) // map_pixel_height != 0 or int(sx_rotated * scaling) // map_pixel_width != 0):
                        pixel_color = black_color
                    else:
                        pixel_color = color_by_index[texture[int(sy_rotated * scaling) % map_pixel_height][int(sx_rotated * scaling) % map_pixel_width]]
                    pygame.draw.rect(screen, pixel_color, pygame.Rect((x+half_width+ left_margin)*2, y*2, 2, 2))  # , width=border_width
                
                previous_sx_rotated = sx_rotated
                previous_sy_rotated = sy_rotated
                
            # pygame.display.update()
            # print(str(y) + ':' +str(sy_rotated) , ' - ', str(start_sx) , ' - ', (-start_sx/96)*64)
            
            # print(sub_pixel_increment_x*64*256, sub_pixel_increment_y*64*256)
            
            
            y_pixel_position_in_map = (start_sy * scaling) % max_y_position_in_map
            x_pixel_position_in_map = (start_sx * scaling) % max_x_position_in_map

            x_sub_pixel_step = int(sub_pixel_increment_x * scaling * 512)
            y_sub_pixel_step = int(sub_pixel_increment_y * scaling * 512)
            
            # x_sub_pixel_step = (-start_sx/96)*64 * 256   
            # print('y in texture: ' + str(y_pixel_position_in_map) + ' - x in texture: ' + str(x_pixel_position_in_map) + ' - x,y sub pixel step: ' + str(int(x_sub_pixel_step)) + ',' + str(int(y_sub_pixel_step)))
            
            if x_sub_pixel_step < 0:
                x_sub_pixel_step = 32768 + x_sub_pixel_step  # We convert to a two complement 15-bit number 
                
            x_sub_pixel_steps_low.append(int(x_sub_pixel_step) % 256)
            x_sub_pixel_steps_high.append(int(x_sub_pixel_step) // 256)

            if y_sub_pixel_step < 0:
                y_sub_pixel_step = 32768 + y_sub_pixel_step  # We convert to a two complement 15-bit number 

            y_sub_pixel_steps_low.append(int(y_sub_pixel_step) % 256)
            y_sub_pixel_steps_high.append(int(y_sub_pixel_step) // 256)

            x_subpixel_position_in_map = int(((x_pixel_position_in_map % 1)*512)%512)
            y_subpixel_position_in_map = int(((y_pixel_position_in_map % 1)*512)%512)
            
            # Note: we need only the lowest bit into the _low array here. And it has to be put into the slot of the 7th bit, so a multiply by 128
            x_subpixel_positions_in_map_low.append(int(x_subpixel_position_in_map % 2) * 128)
            x_subpixel_positions_in_map_high.append(int(x_subpixel_position_in_map // 2))
            
# FIXME: we could also pack the reset cache reset bit into y_subpixel_positions_in_map_low!
            # Note: we need only the lowest bit into the _low array here. And it has to be put into the slot of the 7th bit, so a multiply by 128
            y_subpixel_positions_in_map_low.append(int(y_subpixel_position_in_map % 2) * 128)
            y_subpixel_positions_in_map_high.append(int(y_subpixel_position_in_map // 2))
            
            x_pixel_positions_in_map_low.append(int(x_pixel_position_in_map % 256))
            x_pixel_positions_in_map_high.append(int(x_pixel_position_in_map // 256))
            
            y_pixel_positions_in_map_low.append(int(y_pixel_position_in_map % 256))
            y_pixel_positions_in_map_high.append(int(y_pixel_position_in_map // 256))
            
            
        # ========= SIMULATING USING THE SAME DATA ==========
        
        if do_draw_sim:
            for y in range(start_y, end_y):
                y_index = y-start_y
                x_pixel_position_in_map = x_pixel_positions_in_map_low[y_index] + x_pixel_positions_in_map_high[y_index]*256
                y_pixel_position_in_map = y_pixel_positions_in_map_low[y_index] + y_pixel_positions_in_map_high[y_index]*256
                
                x_subpixel_position_in_map = (x_subpixel_positions_in_map_low[y_index]/128 + x_subpixel_positions_in_map_high[y_index]*2) / 512
                y_subpixel_position_in_map = (y_subpixel_positions_in_map_low[y_index]/128 + y_subpixel_positions_in_map_high[y_index]*2) / 512
                
                x_pixel_position_in_map += x_subpixel_position_in_map
                y_pixel_position_in_map += y_subpixel_position_in_map
                
                x_sub_pixel_step = (x_sub_pixel_steps_low[y_index] + x_sub_pixel_steps_high[y_index] * 256)/512 
                y_sub_pixel_step = (y_sub_pixel_steps_low[y_index] + y_sub_pixel_steps_high[y_index] * 256)/512
                
                for x in range(-half_width, half_width):
             
                    if do_clip and (int(y_pixel_position_in_map) // map_pixel_height != 0 or int(x_pixel_position_in_map) // map_pixel_width != 0):
                        pixel_color = black_color
                    else:
                        pixel_color = color_by_index[texture[int(y_pixel_position_in_map) % map_pixel_height][int(x_pixel_position_in_map) % map_pixel_width]]

                    pygame.draw.rect(screen, pixel_color, pygame.Rect((x+half_width+ left_margin)*2, y*2+192, 2, 2))  # , width=border_width
                    
                    x_pixel_position_in_map += x_sub_pixel_step
                    y_pixel_position_in_map += y_sub_pixel_step
                    
                    # FIXME: shouldnt we simulate that when in repeat-mode everything always has a position *inside* the map?
                    
                    # We simulate that the values inside of VERA (max 11 bit for position) will overflow automatically
                    x_pixel_position_in_map = x_pixel_position_in_map % max_x_position_in_map
                    y_pixel_position_in_map = y_pixel_position_in_map % max_y_position_in_map
                
                # pygame.display.update()

        # ========= / SIMULATING USING THE SAME DATA ==========

        pygame.display.update()
        
        if do_single_angle:
            print('x_subpixel_positions_in_map_low:')
            print('    .byte ' + ','.join(str(x) for x in x_subpixel_positions_in_map_low))
            print('x_subpixel_positions_in_map_high:')
            print('    .byte ' + ','.join(str(x) for x in x_subpixel_positions_in_map_high))
            
            print('y_subpixel_positions_in_map_low:')
            print('    .byte ' + ','.join(str(x) for x in y_subpixel_positions_in_map_low))
            print('y_subpixel_positions_in_map_high:')
            print('    .byte ' + ','.join(str(x) for x in y_subpixel_positions_in_map_high))
                
            print('x_pixel_positions_in_map_low:')
            print('    .byte ' + ','.join(str(x) for x in x_pixel_positions_in_map_low))
            print('x_pixel_positions_in_map_high:')
            print('    .byte ' + ','.join(str(x) for x in x_pixel_positions_in_map_high))
            
            print('y_pixel_positions_in_map_low:')
            print('    .byte ' + ','.join(str(x) for x in y_pixel_positions_in_map_low))
            print('y_pixel_positions_in_map_high:')
            print('    .byte ' + ','.join(str(x) for x in y_pixel_positions_in_map_high))
                
            print('x_sub_pixel_steps_low:')
            print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_low))
            print('x_sub_pixel_steps_high:')
            print('    .byte ' + ','.join(str(x) for x in x_sub_pixel_steps_high))
                
            print('y_sub_pixel_steps_low:')
            print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_low))
            print('y_sub_pixel_steps_high:')
            print('    .byte ' + ','.join(str(x) for x in y_sub_pixel_steps_high))
        else:
            all_angles_x_subpixel_positions_in_map_low += x_subpixel_positions_in_map_low
            all_angles_x_subpixel_positions_in_map_high += x_subpixel_positions_in_map_high
            
            all_angles_y_subpixel_positions_in_map_low += y_subpixel_positions_in_map_low
            all_angles_y_subpixel_positions_in_map_high += y_subpixel_positions_in_map_high
            
            all_angles_x_pixel_positions_in_map_low += x_pixel_positions_in_map_low
            all_angles_x_pixel_positions_in_map_high += x_pixel_positions_in_map_high
            
            all_angles_y_pixel_positions_in_map_low += y_pixel_positions_in_map_low
            all_angles_y_pixel_positions_in_map_high += y_pixel_positions_in_map_high
            
            all_angles_x_sub_pixel_steps_low += x_sub_pixel_steps_low
            all_angles_x_sub_pixel_steps_high += x_sub_pixel_steps_high
            
            all_angles_y_sub_pixel_steps_low += y_sub_pixel_steps_low
            all_angles_y_sub_pixel_steps_high += y_sub_pixel_steps_high
        
    if not do_single_angle:
        half_index = (angle_max // 2) * (end_y-start_y) # We have nr angles times nr of rows on screen
        filler_size = 16 * 1024 - half_index  # We need 16kB files (so we need a filler size)
        filler = [0] * filler_size
    
        # FIXME: we do not want a filler added when loading these files from an SD card! (its better to fill in the assembler when including these files in a ROM)

        # X subpixel positions Low
        tableFile = open("fx_tests/tables/x_subpixel_positions_in_map_low1.bin", "wb")
        tableFile.write(bytearray(all_angles_x_subpixel_positions_in_map_low[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/x_subpixel_positions_in_map_low2.bin", "wb")
        tableFile.write(bytearray(all_angles_x_subpixel_positions_in_map_low[half_index:]+filler))
        tableFile.close()
        
        # X subpixel positions High
        tableFile = open("fx_tests/tables/x_subpixel_positions_in_map_high1.bin", "wb")
        tableFile.write(bytearray(all_angles_x_subpixel_positions_in_map_high[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/x_subpixel_positions_in_map_high2.bin", "wb")
        tableFile.write(bytearray(all_angles_x_subpixel_positions_in_map_high[half_index:]+filler))
        tableFile.close()
        
        # Y subpixel positions Low
        tableFile = open("fx_tests/tables/y_subpixel_positions_in_map_low1.bin", "wb")
        tableFile.write(bytearray(all_angles_y_subpixel_positions_in_map_low[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/y_subpixel_positions_in_map_low2.bin", "wb")
        tableFile.write(bytearray(all_angles_y_subpixel_positions_in_map_low[half_index:]+filler))
        tableFile.close()
        
        # Y subpixel positions High
        tableFile = open("fx_tests/tables/y_subpixel_positions_in_map_high1.bin", "wb")
        tableFile.write(bytearray(all_angles_y_subpixel_positions_in_map_high[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/y_subpixel_positions_in_map_high2.bin", "wb")
        tableFile.write(bytearray(all_angles_y_subpixel_positions_in_map_high[half_index:]+filler))
        tableFile.close()

        # X pixel positions Low
        tableFile = open("fx_tests/tables/x_pixel_positions_in_map_low1.bin", "wb")
        tableFile.write(bytearray(all_angles_x_pixel_positions_in_map_low[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/x_pixel_positions_in_map_low2.bin", "wb")
        tableFile.write(bytearray(all_angles_x_pixel_positions_in_map_low[half_index:]+filler))
        tableFile.close()
        
        # X pixel positions High
        tableFile = open("fx_tests/tables/x_pixel_positions_in_map_high1.bin", "wb")
        tableFile.write(bytearray(all_angles_x_pixel_positions_in_map_high[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/x_pixel_positions_in_map_high2.bin", "wb")
        tableFile.write(bytearray(all_angles_x_pixel_positions_in_map_high[half_index:]+filler))
        tableFile.close()
        
        # Y pixel positions Low
        tableFile = open("fx_tests/tables/y_pixel_positions_in_map_low1.bin", "wb")
        tableFile.write(bytearray(all_angles_y_pixel_positions_in_map_low[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/y_pixel_positions_in_map_low2.bin", "wb")
        tableFile.write(bytearray(all_angles_y_pixel_positions_in_map_low[half_index:]+filler))
        tableFile.close()
        
        # Y pixel positions High
        tableFile = open("fx_tests/tables/y_pixel_positions_in_map_high1.bin", "wb")
        tableFile.write(bytearray(all_angles_y_pixel_positions_in_map_high[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/y_pixel_positions_in_map_high2.bin", "wb")
        tableFile.write(bytearray(all_angles_y_pixel_positions_in_map_high[half_index:]+filler))
        tableFile.close()

        # X subpixel steps Low
        tableFile = open("fx_tests/tables/x_sub_pixel_steps_low1.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_low[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/x_sub_pixel_steps_low2.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_low[half_index:]+filler))
        tableFile.close()
        
        # X subpixel steps High
        tableFile = open("fx_tests/tables/x_sub_pixel_steps_high1.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_high[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/x_sub_pixel_steps_high2.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_high[half_index:]+filler))
        tableFile.close()

        # Y subpixel steps Low
        tableFile = open("fx_tests/tables/y_sub_pixel_steps_low1.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_low[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/y_sub_pixel_steps_low2.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_low[half_index:]+filler))
        tableFile.close()
        
        # Y subpixel steps High
        tableFile = open("fx_tests/tables/y_sub_pixel_steps_high1.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_high[:half_index]+filler))
        tableFile.close()
        tableFile = open("fx_tests/tables/y_sub_pixel_steps_high2.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_high[half_index:]+filler))
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