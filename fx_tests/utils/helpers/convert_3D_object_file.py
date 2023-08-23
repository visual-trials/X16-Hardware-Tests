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

pygame.display.set_caption('X16 convert 3D object file')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()


def run():

    screen.fill(background_color)

    # Using readlines()
    file1 = open('fx_tests/textures/spaceship.obj', 'r')
    lines = file1.readlines()
    
    triangles_raw = []
    points = []
    for line_raw in lines:
        line = line_raw.strip()
        if line.startswith('#'):
            continue
        
        if line.startswith('v '):
        
            line_parts = line.split()
            line_parts.pop(0)  # first element contains the 'v '
            coordinates = [float(line_part) for line_part in line_parts]
            
            point = { "x": coordinates[0], "y": coordinates[1], "z": coordinates[2] }
            points.append(point)

        if line.startswith('f '):
        
            line_parts = line.split()
            line_parts.pop(0)  # first element contains the 'f '
            triangle_point_indexes = [(int(line_part)-1) for line_part in line_parts]
            
            triangles_raw.append(triangle_point_indexes)

    triangles = []
    for triangle_point_indexes in triangles_raw:
        pt1 = points[triangle_point_indexes[0]]
        pt2 = points[triangle_point_indexes[1]]
        pt3 = points[triangle_point_indexes[2]]
        
        # Calculate the normal of the points using the CROSS PRODUCT
        
        a = { "x": pt3['x'] - pt1['x'], "y": pt3['y'] - pt1['y'], "z": pt3['z'] - pt1['z'] }
        b = { "x": pt2['x'] - pt1['x'], "y": pt2['y'] - pt1['y'], "z": pt2['z'] - pt1['z'] }
        
        cross_product = { 'x': a['y'] * b['z'] - a['z'] * b['y'], 
                          'y': a['z'] * b['x'] - a['x'] * b['z'], 
                          'z': a['x'] * b['y'] - a['y'] * b['x'] }
        
        # We NORMALIZE the result of the CROSS PRODUCT
        length_normal = math.sqrt((cross_product['x'] ** 2) + (cross_product['y'] ** 2) + (cross_product['z'] ** 2))
        
        if (length_normal == 0):
            print("ERROR: the length of the normal is 0!")
            print(pt1)
            print(pt2)
            print(pt3)
            #print(a)
            #print(b)
            #print(length_normal)
            # FIXME: what to do in this case??
            normal_vector = { 'x' : 0,
                              'y' : 0,
                              'z' : 0 }
        else:
            normal_vector = { 'x' : cross_product['x'] / length_normal,
                              'y' : cross_product['y'] / length_normal,
                              'z' : cross_product['z'] / length_normal }
        
        
        # FIXME: We should reverse the order of the points in order to create a clockwise winding
        triangle_points = [pt2, pt1, pt3, normal_vector ]
        triangles.append(triangle_points)
        
            
    # print(points)
    # print(triangles)
    
    print('NR_OF_TRIANGLES = ' + str(len(triangles)))
    print('triangle_3d_data:')
    print('    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)')
    print('    ;       x1,    y1,    z1,    x2,    y2,    z2,    x3,    y3,    z3,    xn,    yn,    zn,   cl')
    
    color_index = 0
    for triangle in triangles:
        single_triangle_data = []
        for triangle_point in triangle:
            single_triangle_data.append(float_to_word(triangle_point["x"]))
            single_triangle_data.append(float_to_word(triangle_point["y"]))
            single_triangle_data.append(float_to_word(triangle_point["z"]))
        
        # FIXME: add color??
        color_index += 1
        single_triangle_data.append(color_index)
        
        print('    .word ' + ', '.join('$' + str(format(x,"04X")).ljust(4, ' ') for x in single_triangle_data))
        
        
    running = True
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False
                
        time.sleep(0.5)
    
        
    pygame.quit()

    
def float_to_word(float_value):
    if float_value >= 256:
        print("ERROR: float value is greater than 256!")
    if float_value <= -256:
        print("ERROR: float value is smaller than -256!")
    
    if float_value >= 0:
        value_int = int(float_value * 256)
    else:
        value_int = 256*256 + int(float_value * 256)
    
    return value_int


run()