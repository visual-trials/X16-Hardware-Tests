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
    
    running = True
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False

        screen.fill(background_color)

        for y in range(32, 96):
            for x in range(-96, 96):
            
                horizon = 1
                fov = 64

                px = x
                py = fov
                pz = y + horizon

                sx = px / pz
                sy = py / pz 

                scaling = 64
                pixel_color = color_by_index[texture[int(sy * scaling) % 64][int(sx * scaling) % 64]]
                pygame.draw.rect(screen, pixel_color, pygame.Rect((x+96+ 64)*2, y*2, 2, 2))  # , width=border_width
        
#        draw_map(map_info, map_width, map_height)
        
#        draw_wall_cone(viewpoint_x, viewpoint_y, current_wall, back_wall_cone_color)

        
        pygame.display.update()
        
        #if rotating:
        #    current_ordered_wall_index += 1
            
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