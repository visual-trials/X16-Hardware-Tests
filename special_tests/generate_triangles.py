# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
import time
import random

random.seed(2)

background_color = (100,0,100)

left_border = 20
top_border = 50
lb = left_border*2
tb = top_border*2

white_color = (200,200,200)
black_color = (20,20,20)
blue_color = (20,20,200)
red_color = (200,20,20)
green_color = (20,200,20)
yellow_color = (200,200,20)
purple_color = (200,0,200)
orange_color = (200,100,0)

screen_width = 320*2
screen_height = 240*2

color_by_index = [ black_color, white_color, blue_color, red_color, green_color, yellow_color, purple_color, orange_color ]


pygame.init()

pygame.display.set_caption('X16 slope table generator')
screen = pygame.display.set_mode((screen_width, screen_height))
clock = pygame.time.Clock()

def run():

    screen.fill(background_color)

    pixel_color = white_color
    
    triangles = []

    base_triangles_data = [
        [   0,   0,   100,  70,    0,  50,    ],
        [   0,   0,   200,   1,  100,  70,    ],
        [   0,   0,   280,   0,  200,   1,    ],
        [ 200,   1,   279,   0,  280,   120,  ],
        [ 279,   0,   280,   0,  280,   120,  ],
        [ 180,  50,   200,   1,  280,   120,  ],
        [   0, 120,    80, 100,  280,   120,  ],
        [ 100,  70,   200,   1,  180,    50,  ],
        [   0,  50,    80, 100,    0,   120,  ],
        [   0,  50,   100,  70,   80,   100,  ],
        [ 100,  70,   180,  50,   80,   100,  ],
        [ 180,  50,   280, 120,   80,   100,  ]
    ]
    
    for triangle_data_index in range(len(base_triangles_data)):
        triangle_data = base_triangles_data[triangle_data_index]
        
        random_color = random.randint(0, 255)
        
        triangles.append({
            "pt1": {"x":triangle_data[0], "y":triangle_data[1]}, 
            "pt2": {"x":triangle_data[2], "y":triangle_data[3]}, 
            "pt3": {"x":triangle_data[4], "y":triangle_data[5]}, 
            "clr": random_color})
        
    # print (triangle_data)
    """
    color = 1
    point1 = {"x":0, "y":0}
    point2 = {"x":100, "y":60}
    point3 = {"x":0, "y":120}
    triangles.append({"pt1": point1, "pt2": point2, "pt3": point3, "clr": color})

    color = 2
    point1 = {"x":0, "y":0}
    point2 = {"x":280, "y":0}
    point3 = {"x":100, "y":60}
    triangles.append({"pt1": point1, "pt2": point2, "pt3": point3, "clr": color})
    
    color = 3
    point1 = {"x":280, "y":0}
    point2 = {"x":280, "y":120}
    point3 = {"x":100, "y":60}
    triangles.append({"pt1": point1, "pt2": point2, "pt3": point3, "clr": color})
    
    color = 4
    point1 = {"x":280, "y":120}
    point2 = {"x":0, "y":120}
    point3 = {"x":100, "y":60}
    triangles.append({"pt1": point1, "pt2": point2, "pt3": point3, "clr": color})
    """    
    
    for i in range(0, 20):
        random_x = random.randint(0, 280-1)
        random_y = random.randint(0, 120-1)
        random_point = {"x":random_x, "y":random_y}
        triangles = split_one_triangle_based_on_point(triangles, random_point)
        
    
    # print(len(triangles))
    
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]
        triangle_color = color_by_index[tri["clr"] % 8] 
        
        pygame.draw.polygon(screen, triangle_color, [
            [tri["pt1"]["x"]*2+lb, tri["pt1"]["y"]*2+tb], 
            [tri["pt2"]["x"]*2+lb, tri["pt2"]["y"]*2+tb], 
            [tri["pt3"]["x"]*2+lb, tri["pt3"]["y"]*2+tb]], 0)
            
            # print('slope:' + str(x) + ":"+ str(y) + " -> " +str(slope_high) + "." + str(slope_low))
                
            #pygame.display.update()
            
        pygame.display.update()
            
    # print(triangles)
    
    print('NR_OF_TRIANGLES = ' + str(len(triangles)))
    print('triangle_data:')
    print('    ;     x1,  y1,    x2,  y2,    x3,  y3    cl')
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]
        
        single_triangle_data = []
        single_triangle_data.append(tri["pt1"]["x"])
        single_triangle_data.append(tri["pt1"]["y"])
        single_triangle_data.append(tri["pt2"]["x"])
        single_triangle_data.append(tri["pt2"]["y"])
        single_triangle_data.append(tri["pt3"]["x"])
        single_triangle_data.append(tri["pt3"]["y"])
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

    

    
    
# See: https://stackoverflow.com/questions/2049582/how-to-determine-if-a-point-is-in-a-2d-triangle
    
def sign(p1, p2, p3):
    return (p1["x"] - p3["x"]) * (p2["y"] - p3["y"]) - (p2["x"] - p3["x"]) * (p1["y"] - p3["y"])

    
def point_in_triangle (point, tri):
    d1 = sign(point, tri["pt1"], tri["pt2"])
    d2 = sign(point, tri["pt2"], tri["pt3"])
    d3 = sign(point, tri["pt3"], tri["pt1"])
    
    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    
    return not (has_neg and has_pos)

def split_one_triangle_based_on_point(triangles, random_point):
    new_triangles = []
    
    for triangle_index in range(0, len(triangles)):
        tri = triangles[triangle_index]
        if (point_in_triangle(random_point, tri)):
            pt1 = tri["pt1"]
            pt2 = tri["pt2"]
            pt3 = tri["pt3"]
            color = tri["clr"]
            
            new_triangles.append({"pt1" : pt1, "pt2": pt2, "pt3": random_point, "clr" : random.randint(0, 255)})
            new_triangles.append({"pt1" : pt2, "pt2": pt3, "pt3": random_point, "clr" : random.randint(0, 255)})
            new_triangles.append({"pt1" : pt3, "pt2": pt1, "pt3": random_point, "clr" : random.randint(0, 255)})
        else:
            new_triangles.append(tri)
        
    return new_triangles


run()