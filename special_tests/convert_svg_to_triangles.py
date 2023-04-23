# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
import time
import random

background_color = (100,0,100)

left_border = 20
top_border = 50
lb = left_border*2
tb = top_border*2

screen_width = 320*2
screen_height = 240*2


pygame.init()

pygame.display.set_caption('X16 slope table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

all_colors_by_str = {} 
all_colors = []

# We dont want to touch/use the first 16 colors of the palette
all_colors.append(None)
all_colors.append(None)
all_colors.append(None)
all_colors.append(None)

all_colors.append(None)
all_colors.append(None)
all_colors.append(None)
all_colors.append(None)

all_colors.append(None)
all_colors.append(None)
all_colors.append(None)
all_colors.append(None)

all_colors.append(None)
all_colors.append(None)
all_colors.append(None)
all_colors.append(None)

def run():

    screen.fill(background_color)

    # Take svg from here: https://msurguy.github.io/triangles/ (using F12, inspect)
    # replace '><' with '>\n<' and save as .svg

    # Using readlines()
    # file1 = open('special_tests/textures/triangles_1.svg', 'r')
    file1 = open('special_tests/textures/triangles_2.svg', 'r')
    lines = file1.readlines()
    
    width = None
    height = None
    
    min_x = 99999
    max_x = -99999
    min_y = 99999
    max_y = -99999
    
    triangles = []
    for line_raw in lines:
        line = line_raw.strip()
        if '<svg' in line:
            width_string_raw = line.split('width="',1)[1]
            width_string = width_string_raw.split('"',1)[0]
            width = int(width_string)
            height_string_raw = line.split('height="',1)[1]
            height_string = height_string_raw.split('"',1)[0]
            height = int(height_string)
        
        if '<polygon' not in line:
            continue
            
        points_string_raw = line.split('points="',1)[1]
        points_string = points_string_raw.split('"',1)[0]
        points_strings = points_string.split(' ')
        points = []
        for point_index in range(0, len(points_strings)):
            point_string = points_strings[point_index]
            point_coord_strings = point_string.split(',')
            point_x = float(point_coord_strings[0])
            point_y = float(point_coord_strings[1])
            point = {"x": point_x, "y": point_y}

            if point_x < min_x:
                min_x = point_x
            if point_x > max_x:
                max_x = point_x
            if point_y < min_y:
                min_y = point_y
            if point_y > max_y:
                max_y = point_y
            
            points.append(point)
        
        # print(points)
        color_string_raw = line.split('style="fill:#',1)[1]
        color_string_long = color_string_raw.split(';',1)[0]
        color_string = color_string_long[0] + color_string_long[2] + color_string_long[4]
        
        # FIXME: offset colors by 16!
        
        clr_index = None
        if color_string in all_colors_by_str:
            clr_index = all_colors_by_str[color_string]["index"]
        else:
            color_index = len(all_colors)
            
            red = int('0x'+color_string[0], 0)*16
            green = int('0x'+color_string[1], 0)*16
            blue = int('0x'+color_string[2], 0)*16
            
            color = ( red, green, blue)
            
            color_data = {"color_str" : color_string, "index" : color_index, "color": color}
            all_colors.append(color_data)
            clr_index = color_data["index"]
            all_colors_by_str[color_string] = color_data
        
        # We are reversing the order of the points in order to create a clockwise winding
        triangle = { "pt1": points[2], "pt2": points[1], "pt3": points[0], "clr_str": color_string, "clr" : clr_index }
        
        triangles.append(triangle)
        
    offset_x = - min_x
    scale_x = 280 / (max_x - min_x)
    offset_y = - min_y
    scale_y = 120 / (max_y - min_y)
    
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]

        tri["pt1"]["x"] += offset_x
        tri["pt1"]["y"] += offset_y
        tri["pt2"]["x"] += offset_x
        tri["pt2"]["y"] += offset_y
        tri["pt3"]["x"] += offset_x
        tri["pt3"]["y"] += offset_y
        
        tri["pt1"]["x"] *= scale_x
        tri["pt1"]["y"] *= scale_y
        tri["pt2"]["x"] *= scale_x
        tri["pt2"]["y"] *= scale_y
        tri["pt3"]["x"] *= scale_x
        tri["pt3"]["y"] *= scale_y
        
    
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]
        triangle_color = all_colors[tri["clr"]]["color"] 
        
        pygame.draw.polygon(screen, triangle_color, [
            [tri["pt1"]["x"]*2+lb, tri["pt1"]["y"]*2+tb], 
            [tri["pt2"]["x"]*2+lb, tri["pt2"]["y"]*2+tb], 
            [tri["pt3"]["x"]*2+lb, tri["pt3"]["y"]*2+tb]], 0)
            
            # print('slope:' + str(x) + ":"+ str(y) + " -> " +str(slope_high) + "." + str(slope_low))
                
            #pygame.display.update()
            
        pygame.display.update()
            
    # print(triangles)
    
    
    paletteString = ""
    
    print('palette_data:')
    for color in all_colors:
        if (color is None):
            continue
        blue = color["color"][2]
        blue = blue & 0xF0
        blue = blue >> 4
        # print(hex(blue))
        
        green = color["color"][1]
        green = green & 0xF0
        # print(hex(green))
        # print(format(blue | green,"02x"))
        
        red = color["color"][0]
        red = red & 0xF0
        red = red >> 4
        # print(format(red,"02x"))
        paletteString += "    .byte "
        paletteString += "$" + format(green | blue,"02x") + ", "
        paletteString += "$" + format(red,"02x")
        paletteString += "  ; palette index " + str(color["index"])
        paletteString += "\n"
    paletteString += "end_of_palette_data:\n"
    print(paletteString)
    print('')
    
    print('NR_OF_TRIANGLES = ' + str(len(triangles)))
    print('triangle_data:')
    print('    ;     x1,  y1,    x2,  y2,    x3,  y3    cl')
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]
        
        single_triangle_data = []
        single_triangle_data.append(int(tri["pt1"]["x"]))
        single_triangle_data.append(int(tri["pt1"]["y"]))
        single_triangle_data.append(int(tri["pt2"]["x"]))
        single_triangle_data.append(int(tri["pt2"]["y"]))
        single_triangle_data.append(int(tri["pt3"]["x"]))
        single_triangle_data.append(int(tri["pt3"]["y"]))
        single_triangle_data.append(tri["clr"])
        
        print('    .word ' + ','.join(str(x).ljust(4, ' ') for x in single_triangle_data))
    
        
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