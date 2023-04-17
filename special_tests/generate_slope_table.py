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

screen_width = 320*2
screen_height = 240*2

color_by_index = [ black_color, white_color, blue_color, red_color, green_color, yellow_color, purple_color ]

pygame.init()

pygame.display.set_caption('X16 slope table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

def run():

    screen.fill(background_color)

    #for y in range(0, 64):
    #    for x in range(0, 64):
    #        pixel_color = color_by_index[texture[y][x]]
    #        pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
    #        
    #pygame.display.update()
    
    pixel_color = white_color
    
    #for y in range(0, 240):
    for y in range(3, 4):
        #for x in range(0, 320):
        for x in range(3*50, 3*51):
            slope = x / y
            
            do_32_times = 0
            # FIXME: what exactly is the criteriafor doing "times 32"?
            if (slope > 127 or slope < -127):
                do_32_times = 1
                slope = slope / 32
            
            slope_low = int((slope % 1) * 256)
            slope_high = int(slope % 256)
            if (do_32_times):
                slope_high += 128
            
            print('slope:' + str(x) + ":"+ str(y) + " -> " +str(slope_high) + "." + str(slope_low))
        
            #pygame.draw.rect(screen, pixel_color, pygame.Rect(x*2, y*2, 2, 2))  # , width=border_width
            pygame.display.update()
        pygame.display.update()
        """        
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
        tableFile = open("special_tests/tables/x_subpixel_positions_in_map_low.bin", "wb")
        tableFile.write(bytearray(all_angles_x_subpixel_positions_in_map_low))
        tableFile.close()
        tableFile = open("special_tests/tables/x_subpixel_positions_in_map_high.bin", "wb")
        tableFile.write(bytearray(all_angles_x_subpixel_positions_in_map_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/y_subpixel_positions_in_map_low.bin", "wb")
        tableFile.write(bytearray(all_angles_y_subpixel_positions_in_map_low))
        tableFile.close()
        tableFile = open("special_tests/tables/y_subpixel_positions_in_map_high.bin", "wb")
        tableFile.write(bytearray(all_angles_y_subpixel_positions_in_map_high))
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

        tableFile = open("special_tests/tables/x_sub_pixel_steps_low.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_low))
        tableFile.close()
        tableFile = open("special_tests/tables/x_sub_pixel_steps_high.bin", "wb")
        tableFile.write(bytearray(all_angles_x_sub_pixel_steps_high))
        tableFile.close()

        tableFile = open("special_tests/tables/y_sub_pixel_steps_low.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_low))
        tableFile.close()
        tableFile = open("special_tests/tables/y_sub_pixel_steps_high.bin", "wb")
        tableFile.write(bytearray(all_angles_y_sub_pixel_steps_high))
        tableFile.close()
        """
        
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