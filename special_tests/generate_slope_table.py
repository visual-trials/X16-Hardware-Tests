# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
import time

background_color = (100,0,100)
white_color = (200,200,200)

screen_width = 320*2
screen_height = 240*2

pygame.init()

pygame.display.set_caption('X16 slope table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

def run():

    screen.fill(background_color)

    pixel_color = white_color
    
    slopes_column_0_low = []
    slopes_column_0_high = []
    slopes_column_1_low = []
    slopes_column_1_high = []
    slopes_column_2_low = []
    slopes_column_2_high = []
    slopes_column_3_low = []
    slopes_column_3_high = []
    slopes_column_4_low = []
    slopes_column_4_high = []
    
    for x in range(0, 320):
    # for x in range(0, 3):
        
        for y in range(0, 256):  # We do y >= 240 to make sure the files are exactly 16kB (filler)
        # for y in range(0, 256):
        
            # We currently have a precision of 1/512th of a pixel per step: we have 9-bit fraction precision. A value of 1 means 1/512th of a pixel
            # But when doing polygons we have to do *two* steps. This is because each step is considered the distance in x when traveling 0.5 pixels in y.
            # But because we have to do 2 steps each y-pixel, we effectively have one 1/256th of a pixel precision.
            # So when we calculate our slope, we should do it in 1/256th of pixels (which happens to be 8-bits btw)
            
            # Note that on the *upper* end we have 15 bits signed so a maximum (positive) value of (1 bit sign, 5 bits value, 9 bits fraction) +31.xxx. But for polygons this is effectively +63.xxx (because we do 2 steps)
            # So when our slope has to be > 63.xxx we do "times 32". Meaning a maximum value of 63.xxx * 32 = 2047.xxx is possible.
            
            if (y == 0):
                slope = 0       # We dont want to divide by 0
            elif (y >= 240):
                slope = 0       # We fill the 240-255 slopes with 0 (so the resulting files are exactly 16kB)
            else:
                slope = x / y
                
            do_32_times = 0
            # FIXME: what exactly is the criteria for doing "times 32"?
            if (slope >= 64):
                do_32_times = 1
                slope = slope / 32
            
            slope_low = int((slope % 1) * 256)
            slope_high = int(slope % 256)
            if (do_32_times):
                slope_high += 128
            
            if (x < 1*64):
                slopes_column_0_low.append(slope_low)
                slopes_column_0_high.append(slope_high)
            elif (x < 2*64):
                slopes_column_1_low.append(slope_low)
                slopes_column_1_high.append(slope_high)
            elif (x < 3*64):
                slopes_column_2_low.append(slope_low)
                slopes_column_2_high.append(slope_high)
            elif (x < 4*64):
                slopes_column_3_low.append(slope_low)
                slopes_column_3_high.append(slope_high)
            else:
                slopes_column_4_low.append(slope_low)
                slopes_column_4_high.append(slope_high)
            
            
            # print('slope:' + str(x) + ":"+ str(y) + " -> " +str(slope_high) + "." + str(slope_low))
                
            pygame.draw.rect(screen, pixel_color, pygame.Rect(x*2, y*2, 2, 2))  # , width=border_width
            #pygame.display.update()
            
        pygame.display.update()
            
            
    #print(slopes_column_0_low)
    #print(slopes_column_0_high)
        
    if(True):
        tableFile = open("special_tests/tables/slopes_column_0_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_0_low))
        tableFile.close()
        tableFile = open("special_tests/tables/slopes_column_0_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_0_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/slopes_column_1_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_1_low))
        tableFile.close()
        tableFile = open("special_tests/tables/slopes_column_1_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_1_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/slopes_column_2_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_2_low))
        tableFile.close()
        tableFile = open("special_tests/tables/slopes_column_2_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_2_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/slopes_column_3_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_3_low))
        tableFile.close()
        tableFile = open("special_tests/tables/slopes_column_3_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_3_high))
        tableFile.close()
        
        tableFile = open("special_tests/tables/slopes_column_4_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_4_low))
        tableFile.close()
        tableFile = open("special_tests/tables/slopes_column_4_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_4_high))
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


run()