# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
import time
import random

background_color = (100,0,100)

left_border = 20
top_border = 20
lb = left_border*2
tb = top_border*2

screen_width = 320*2
screen_height = 240*2

white_color = (200,200,200)
black_color = (20,20,20)
blue_color = (20,20,200)
red_color = (200,20,20)
green_color = (20,200,20)
yellow_color = (200,200,20)
purple_color = (200,0,200)
orange_color = (200,100,0)

color_by_index = [ black_color, white_color, blue_color, red_color, green_color, yellow_color, purple_color, orange_color ]

pygame.init()

pygame.display.set_caption('X16 generate butterfly triangles')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()


def run():

    screen.fill(background_color)

    # These are taken from x16_logo_measurements.png
    base_points = [
        [   0,   0 ],  # 0
        [  40, 135 ],  # 1
        [ 159, 135 ],  # 2
        [ 128, 159 ],  # 3
        [ 128, 192 ],  # 4
        [  55, 216 ],  # 5
        [ 159, 216 ],  # 6
        [  32, 326 ]   # 7
    ]
    
    points = []
    
    # 0
    points.append({ "x" : base_points[0][0], "y" : base_points[0][1], "z" : 0 })
    points.append({ "x" : (base_points[1][0] - base_points[0][0]) * 1/4, "y" : (base_points[1][1] - base_points[0][1]) * 1/4, "z" : 0 })
    points.append({ "x" : (base_points[2][0] - base_points[0][0]) * 1/4, "y" : (base_points[2][1] - base_points[0][1]) * 1/4, "z" : 0 })
    points.append({ "x" : (base_points[1][0] - base_points[0][0]) * 2/4, "y" : (base_points[1][1] - base_points[0][1]) * 2/4, "z" : 0 })
    points.append({ "x" : (base_points[2][0] - base_points[0][0]) * 2/4, "y" : (base_points[2][1] - base_points[0][1]) * 2/4, "z" : 0 })
    points.append({ "x" : (base_points[1][0] - base_points[0][0]) * 3/4, "y" : (base_points[1][1] - base_points[0][1]) * 3/4, "z" : 0 })
    points.append({ "x" : (base_points[2][0] - base_points[0][0]) * 3/4, "y" : (base_points[2][1] - base_points[0][1]) * 3/4, "z" : 0 })
    points.append({ "x" : (base_points[1][0] - base_points[0][0]) * 4/4, "y" : (base_points[1][1] - base_points[0][1]) * 4/4, "z" : 0 })
    points.append({ "x" : (base_points[2][0] - base_points[0][0]) * 4/4, "y" : (base_points[2][1] - base_points[0][1]) * 4/4, "z" : 0 })
    # 9
    points.append({ "x" : base_points[3][0], "y" : base_points[3][1], "z" : 0 })
    points.append({ "x" : base_points[2][0], "y" : base_points[3][1], "z" : 0 })
    # 11
    points.append({ "x" : base_points[4][0], "y" : base_points[4][1], "z" : 0 })
    points.append({ "x" : base_points[2][0], "y" : base_points[4][1], "z" : 0 })
    
    # print(points)
    
    triangles_raw = [
# FIXME: is this the right order? Clockwise or anti-clock wise?
        [ 0,  1,  2],
        [ 1,  2,  3],
        [ 3,  2,  4],
        [ 3,  4,  5],
        [ 5,  4,  6],
        [ 5,  6,  7],
        [ 7,  6,  8],
        [ 7,  8,  9],
        [ 9,  8, 10],
        [ 9, 10, 11],
        [11, 10, 12],
        
    
    ]
    
    triangles = []
    color_index = 0
    for triangle_point_indexes in triangles_raw:
        pt1 = points[triangle_point_indexes[0]]
        pt2 = points[triangle_point_indexes[1]]
        pt3 = points[triangle_point_indexes[2]]

        # FIXME: we need a new color every TWO triangles!
        # FIXME: we need a new color every TWO triangles!
        # FIXME: we need a new color every TWO triangles!
        # FIXME: should we start at index 0 or 1?
        color_index += 1
        
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
        triangles.append({ "triangle_points" : triangle_points, "clr" : color_index})
            
    # print(points)
    # print(triangles)
    
    
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]
        tri_points = tri["triangle_points"]
        triangle_color = color_by_index[tri["clr"] % 8] 
        
        sc = 1.5 # scale
        
        pygame.draw.polygon(screen, triangle_color, [
            [tri_points[0]["x"]*sc+lb, tri_points[0]["y"]*sc+tb], 
            [tri_points[1]["x"]*sc+lb, tri_points[1]["y"]*sc+tb], 
            [tri_points[2]["x"]*sc+lb, tri_points[2]["y"]*sc+tb]], 0)
            
            # print('slope:' + str(x) + ":"+ str(y) + " -> " +str(slope_high) + "." + str(slope_low))
                
            #pygame.display.update()
            
        pygame.display.update()
            
    
    print('NR_OF_TRIANGLES = ' + str(len(triangles)))
    print('triangle_3d_data:')
    print('    ; Note: the normal is a normal point relative to 0.0 (with a length of $100)')
    print('    ;       x1,    y1,    z1,    x2,    y2,    z2,    x3,    y3,    z3,    xn,    yn,    zn,   cl')
    
    for triangle in triangles:
        single_triangle_data = []
        for triangle_point in triangle["triangle_points"]:
            single_triangle_data.append(float_to_word(triangle_point["x"]))
            single_triangle_data.append(float_to_word(triangle_point["y"]))
            single_triangle_data.append(float_to_word(triangle_point["z"]))
        
        single_triangle_data.append(triangle["clr"])
        
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