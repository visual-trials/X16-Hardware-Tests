# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
import time

background_color = (100,0,100)
white_color = (200,200,200)

screen_width = 320*2
screen_height = 240*2

pygame.init()

pygame.display.set_caption('X16 division table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

def run():

    screen.fill(background_color)

    pixel_color = white_color


    # FIXME: for now we only do POSITIVE numbers!
    
    div_pos_0_low = []
    div_pos_0_high = []
    div_pos_1_low = []
    div_pos_1_high = []
    
    # Since we dont want to divide by zero, we add 0 as answer to dividing by zero
    div_pos_0_low.append(0)
    div_pos_0_high.append(0)
    
# FIXME: can we do 1/256??
    div_pos_0_low.append(0)
    div_pos_0_high.append(0)
    
    for n in range(2, 65536 // 2):
    #for n in range(2, 5):
        
        # Note: we interpret n as a 8.8 fixed point number
        n_real = n / 256
        
        # print("n_real: " + str(n_real))
        
        division = 1 / (n_real)
        
        # print("division: " + str(division))
        
        div_int = int(division * 256)
        
        # print("div_int: " + str(div_int))
        
        div_int_fraction = div_int % 256
        div_int_whole_number = div_int // 256
            
            
        if (n < (16384 / 2) * 2):
            div_pos_0_low.append(div_int_fraction)
            div_pos_0_high.append(div_int_whole_number)
        else:
            div_pos_1_low.append(div_int_fraction)
            div_pos_1_high.append(div_int_whole_number)
            
        # pygame.display.update()
            
        
    # print(div_pos_0_low)
    # print(div_pos_0_high)
    
    if(True):
    
        tableFile = open("special_tests/tables/div_pos_0_low.bin", "wb")
        tableFile.write(bytearray(div_pos_0_low))
        tableFile.close()
        tableFile = open("special_tests/tables/div_pos_0_high.bin", "wb")
        tableFile.write(bytearray(div_pos_0_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/div_pos_1_low.bin", "wb")
        tableFile.write(bytearray(div_pos_1_low))
        tableFile.close()
        tableFile = open("special_tests/tables/div_pos_1_high.bin", "wb")
        tableFile.write(bytearray(div_pos_1_high))
        tableFile.close()
        
        print("tables written to disk")
        
    running = True
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False
                
        time.sleep(0.5)
    
        
    pygame.quit()


run()