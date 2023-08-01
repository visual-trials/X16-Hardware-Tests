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
    slopes_column_0_vhigh = []
    slopes_column_1_low = []
    slopes_column_1_high = []
    slopes_column_1_vhigh = []
    slopes_column_2_low = []
    slopes_column_2_high = []
    slopes_column_2_vhigh = []
    slopes_column_3_low = []
    slopes_column_3_high = []
    slopes_column_3_vhigh = []
    slopes_column_4_low = []
    slopes_column_4_high = []
    slopes_column_4_vhigh = []
    
    slopes_packed_column_0_low = []
    slopes_packed_column_0_high = []
    slopes_packed_column_1_low = []
    slopes_packed_column_1_high = []
    slopes_packed_column_2_low = []
    slopes_packed_column_2_high = []
    slopes_packed_column_3_low = []
    slopes_packed_column_3_high = []
    slopes_packed_column_4_low = []
    slopes_packed_column_4_high = []
    
    slopes_negative_packed_column_0_low = []
    slopes_negative_packed_column_0_high = []
    slopes_negative_packed_column_1_low = []
    slopes_negative_packed_column_1_high = []
    slopes_negative_packed_column_2_low = []
    slopes_negative_packed_column_2_high = []
    slopes_negative_packed_column_3_low = []
    slopes_negative_packed_column_3_high = []
    slopes_negative_packed_column_4_low = []
    slopes_negative_packed_column_4_high = []
    
    for x in range(0, 320):
    # for x in range(0, 3):
        
        for y in range(0, 256):  # We do y >= 240 to make sure the files are exactly 16kB (filler)
        # for y in range(0, 3):
        
            # We currently have a precision of 1/512th of a pixel per step: we have 9-bit fraction precision. A value of 1 means 1/512th of a pixel
            # But when doing polygons we have to do *two* steps. This is because each step is considered the distance in x when traveling 0.5 pixels in y.
            # But because we have to do 2 steps each y-pixel, we effectively have one 1/256th of a pixel precision.
            # So when we calculate our slope, we should do it in 1/256th of pixels (which happens to be 8-bits btw)
            
            # Note that on the *upper* end we have 15 bits signed so a maximum (positive) value of (1 bit sign, 5 bits value, 9 bits fraction) +31.xxx. But for polygons this is effectively +63.xxx (because we do 2 steps)
            # So when our slope has to be > 63.xxx we do "times 32". Meaning a maximum value of 63.xxx * 32 = 2047.xxx is possible.
            
            if (y == 0):
                slope = 0       # We dont want to divide by 0
                neg_slope = 0
            elif (y >= 240):
                slope = 0       # We fill the 240-255 slopes with 0 (so the resulting files are exactly 16kB)
                neg_slope = 0
            else:
                slope = x / y
                neg_slope = (-320+x) / y
                
            slope_int = int(slope * 256)
            neg_slope_int = int(neg_slope * 256)
            
            # print("neg_slope: " + str(neg_slope))
            # print("neg_slope_int: " + str(neg_slope_int))
                
            do_32_times = 0
            # FIXME: what exactly is the criteria for doing "times 32"?
            if (slope_int >= 64*256):
                do_32_times = 1
                slope_packed = slope_int // 32
            else:
                slope_packed = slope_int
            
            neg_do_32_times = 0
            # FIXME: what exactly is the criteria for doing "times 32"?
            if (neg_slope_int <= -64*256):
                neg_do_32_times = 1
                slope_negative_packed = 32768 + (neg_slope_int // 32)   # We convert to a two complement 15-bit number 
            else:
                slope_negative_packed = 32768 + neg_slope_int           # We convert to a two complement 15-bit number 
                
            # print("slope_negative_packed: " + str(slope_negative_packed))
            
            slope_low = int(slope_int % 256)
            slope_high = int((slope_int // 256) % 256)
            slope_vhigh = int((slope_int // (256*256)) % 256)
            
            slope_packed_low = int(slope_packed % 256)
            slope_packed_high = int((slope_packed // 256) % 256)
            
            slope_negative_packed_low = int(slope_negative_packed % 256)
            slope_negative_packed_high = int((slope_negative_packed // 256) % 256)
            
            if (do_32_times):
                slope_packed_high += 128   # setting bit7
            if (neg_do_32_times):
                slope_negative_packed_high += 128   # setting bit7
            
            if (x < 1*64):
                slopes_column_0_low.append(slope_low)
                slopes_column_0_high.append(slope_high)
                slopes_column_0_vhigh.append(slope_vhigh)
                
                slopes_packed_column_0_low.append(slope_packed_low)
                slopes_packed_column_0_high.append(slope_packed_high)
                
                slopes_negative_packed_column_0_low.append(slope_negative_packed_low)
                slopes_negative_packed_column_0_high.append(slope_negative_packed_high)
            elif (x < 2*64):
                slopes_column_1_low.append(slope_low)
                slopes_column_1_high.append(slope_high)
                slopes_column_1_vhigh.append(slope_vhigh)
                
                slopes_packed_column_1_low.append(slope_packed_low)
                slopes_packed_column_1_high.append(slope_packed_high)
                
                slopes_negative_packed_column_1_low.append(slope_negative_packed_low)
                slopes_negative_packed_column_1_high.append(slope_negative_packed_high)
            elif (x < 3*64):
                slopes_column_2_low.append(slope_low)
                slopes_column_2_high.append(slope_high)
                slopes_column_2_vhigh.append(slope_vhigh)
                
                slopes_packed_column_2_low.append(slope_packed_low)
                slopes_packed_column_2_high.append(slope_packed_high)
                
                slopes_negative_packed_column_2_low.append(slope_negative_packed_low)
                slopes_negative_packed_column_2_high.append(slope_negative_packed_high)
            elif (x < 4*64):
                slopes_column_3_low.append(slope_low)
                slopes_column_3_high.append(slope_high)
                slopes_column_3_vhigh.append(slope_vhigh)
                
                slopes_packed_column_3_low.append(slope_packed_low)
                slopes_packed_column_3_high.append(slope_packed_high)
                
                slopes_negative_packed_column_3_low.append(slope_negative_packed_low)
                slopes_negative_packed_column_3_high.append(slope_negative_packed_high)
            else:
                slopes_column_4_low.append(slope_low)
                slopes_column_4_high.append(slope_high)
                slopes_column_4_vhigh.append(slope_vhigh)
                
                slopes_packed_column_4_low.append(slope_packed_low)
                slopes_packed_column_4_high.append(slope_packed_high)
                
                slopes_negative_packed_column_4_low.append(slope_negative_packed_low)
                slopes_negative_packed_column_4_high.append(slope_negative_packed_high)
            
            
            # print('packed slope:' + str(x) + ":"+ str(y) + " -> $" + format(slope_packed_high,"02X") + ".$" + format(slope_packed_low,"02X"))
            # print('negative packed slope:' + str(-320+x) + ":"+ str(y) + " -> $" + format(slope_negative_packed_high,"02X") + ".$" + format(slope_negative_packed_low,"02X"))
                
            pygame.draw.rect(screen, pixel_color, pygame.Rect(x*2, y*2, 2, 2))  # , width=border_width
            #pygame.display.update()
            
        pygame.display.update()
            
            
    #print(slopes_column_0_low)
    #print(slopes_column_0_high)
    #print(slopes_column_0_vhigh)
        
    if(True):
    
        tableFile = open("fx_tests/tables/slopes_column_0_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_0_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_0_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_0_high))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_0_vhigh.bin", "wb")
        tableFile.write(bytearray(slopes_column_0_vhigh))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_column_1_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_1_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_1_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_1_high))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_1_vhigh.bin", "wb")
        tableFile.write(bytearray(slopes_column_1_vhigh))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_column_2_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_2_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_2_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_2_high))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_2_vhigh.bin", "wb")
        tableFile.write(bytearray(slopes_column_2_vhigh))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_column_3_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_3_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_3_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_3_high))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_3_vhigh.bin", "wb")
        tableFile.write(bytearray(slopes_column_3_vhigh))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_column_4_low.bin", "wb")
        tableFile.write(bytearray(slopes_column_4_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_4_high.bin", "wb")
        tableFile.write(bytearray(slopes_column_4_high))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_column_4_vhigh.bin", "wb")
        tableFile.write(bytearray(slopes_column_4_vhigh))
        tableFile.close()
    
    
    
        tableFile = open("fx_tests/tables/slopes_packed_column_0_low.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_0_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_packed_column_0_high.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_0_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_packed_column_1_low.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_1_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_packed_column_1_high.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_1_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_packed_column_2_low.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_2_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_packed_column_2_high.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_2_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_packed_column_3_low.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_3_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_packed_column_3_high.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_3_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_packed_column_4_low.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_4_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_packed_column_4_high.bin", "wb")
        tableFile.write(bytearray(slopes_packed_column_4_high))
        tableFile.close()
        
        
    
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_0_low.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_0_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_0_high.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_0_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_1_low.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_1_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_1_high.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_1_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_2_low.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_2_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_2_high.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_2_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_3_low.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_3_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_3_high.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_3_high))
        tableFile.close()
        
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_4_low.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_4_low))
        tableFile.close()
        tableFile = open("fx_tests/tables/slopes_negative_packed_column_4_high.bin", "wb")
        tableFile.write(bytearray(slopes_negative_packed_column_4_high))
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