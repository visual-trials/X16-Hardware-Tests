# To install pygame: pip install pygame      (my version: pygame-2.1.2)
import pygame
import math
import time
import random
import copy

background_color = (100,0,100)

screen_width = 320
screen_height = 240


pygame.init()

pygame.display.set_caption('X16 polygon 3d helper')
screen = pygame.display.set_mode((screen_width*2, screen_height*2))
clock = pygame.time.Clock()

all_colors = []

# We dont want to touch/use the first 16 colors of the palette
all_colors.append((0,0,0))         # index 0: black
all_colors.append((200,200,200))   # index 1: white/light grey
all_colors.append((200,0,0))       # index 2: red

def run():


    triangles = []
    
    triangle = { "pt1": {"x": 0.0, "y": 0.0, "z": 0.0}, 
                 "pt2": {"x": 1.0, "y": 0.0, "z": 0.0}, 
                 "pt3": {"x": 0.0, "y": 1.0, "z": 0.0},
                 "clr" : 1 }
    
    triangles.append(triangle)

    triangle = { "pt1": {"x": 1.0, "y": 0.0, "z": 1.0}, 
                 "pt2": {"x": 1.0, "y": 1.0, "z": 1.0}, 
                 "pt3": {"x": 0.0, "y": 1.0, "z": 1.0},
                 "clr" : 2 }
    
    triangles.append(triangle)

    
    angle_z = 0.0
    angle_x = 0.0
    
        
    running = True
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False

        angle_x += 0.01
        angle_z += 0.02

        screen.fill(background_color)
        draw_world(triangles, angle_z, angle_x)
        pygame.display.update()

                
        # time.sleep(0.5)
    
        
    pygame.quit()

def draw_world(triangles, angle_z, angle_x):
    triangles_scaled = do_the_3d_transformations(triangles, angle_z, angle_x)
    
    # FIXME: UGLY HACK! We need to sort properly!
    if (triangles_scaled[0]["avg_z"] < triangles_scaled[1]["avg_z"]):
        triangles_scaled.reverse()
    
    for triangle_scaled in triangles_scaled:
        tri = triangle_scaled
        triangle_color = all_colors[tri["clr"]]
        
        pygame.draw.polygon(screen, triangle_color, [
            [(tri["pt1"]["x"]+screen_width/2)*2, (tri["pt1"]["y"]+screen_height/2)*2], 
            [(tri["pt2"]["x"]+screen_width/2)*2, (tri["pt2"]["y"]+screen_height/2)*2], 
            [(tri["pt3"]["x"]+screen_width/2)*2, (tri["pt3"]["y"]+screen_height/2)*2]], 0)
            
            #pygame.display.update()
            
        # pygame.display.update()
            
    # print(triangles)

def do_the_3d_transformations(triangles, angle_z, angle_x):

    offset_x = 0
    offset_y = 0
    offset_z = 3
    
    scale_x = 100
    scale_y = 100
    
    triangles_rotated_z = []
    for tri in triangles:
        tri_r_z = copy.deepcopy(tri)
        
        cos = math.cos(angle_z)
        sin = math.sin(angle_z)
        
        tri_r_z["pt1"]["x"] = ((tri["pt1"]["x"])*cos) - ((tri["pt1"]["y"])*sin)
        tri_r_z["pt1"]["y"] = ((tri["pt1"]["x"])*sin) + ((tri["pt1"]["y"])*cos)

        tri_r_z["pt2"]["x"] = ((tri["pt2"]["x"])*cos) - ((tri["pt2"]["y"])*sin)
        tri_r_z["pt2"]["y"] = ((tri["pt2"]["x"])*sin) + ((tri["pt2"]["y"])*cos)
        
        tri_r_z["pt3"]["x"] = ((tri["pt3"]["x"])*cos) - ((tri["pt3"]["y"])*sin)
        tri_r_z["pt3"]["y"] = ((tri["pt3"]["x"])*sin) + ((tri["pt3"]["y"])*cos)
        
        triangles_rotated_z.append(tri_r_z)

        
    triangles_rotated_x = []
    for tri_r_z in triangles_rotated_z:
        tri_r_x = copy.deepcopy(tri_r_z)
        
        cos = math.cos(angle_x)
        sin = math.sin(angle_x)
        
        tri_r_x["pt1"]["y"] = ((tri_r_z["pt1"]["y"])*cos) - ((tri_r_z["pt1"]["z"])*sin)
        tri_r_x["pt1"]["z"] = ((tri_r_z["pt1"]["y"])*sin) + ((tri_r_z["pt1"]["z"])*cos)

        tri_r_x["pt2"]["y"] = ((tri_r_z["pt2"]["y"])*cos) - ((tri_r_z["pt2"]["z"])*sin)
        tri_r_x["pt2"]["z"] = ((tri_r_z["pt2"]["y"])*sin) + ((tri_r_z["pt2"]["z"])*cos)
        
        tri_r_x["pt3"]["y"] = ((tri_r_z["pt3"]["y"])*cos) - ((tri_r_z["pt3"]["z"])*sin)
        tri_r_x["pt3"]["z"] = ((tri_r_z["pt3"]["y"])*sin) + ((tri_r_z["pt3"]["z"])*cos)
        
        triangles_rotated_x.append(tri_r_x)
        
    """
    // Rotation X
    matRotX.m[1][1] = cosf(fTheta * 0.5f);
    matRotX.m[1][2] = sinf(fTheta * 0.5f);
    matRotX.m[2][1] = -sinf(fTheta * 0.5f);
    matRotX.m[2][2] = cosf(fTheta * 0.5f);
    
    o.y = i.x * m.m[0][1] + i.y * m.m[1][1] + i.z * m.m[2][1] + m.m[3][1];
    o.z = i.x * m.m[0][2] + i.y * m.m[1][2] + i.z * m.m[2][2] + m.m[3][2];
    """
        
    
    triangles_translated = []
    for triangle_rotated_x in triangles_rotated_x:
        tri = copy.deepcopy(triangle_rotated_x)

        tri["pt1"]["z"] += offset_z
        tri["pt2"]["z"] += offset_z
        tri["pt3"]["z"] += offset_z
        
        tri["avg_z"] = (tri["pt1"]["z"] + tri["pt2"]["z"] + tri["pt3"]["z"]) / 3
        
        triangles_translated.append(tri)
        
    triangles_projected = []
    for triangle_translated in triangles_translated:
        tri = copy.deepcopy(triangle_translated)
        
        tri["pt1"]["x"] /= tri["pt1"]["z"]
        tri["pt2"]["x"] /= tri["pt2"]["z"]
        tri["pt3"]["x"] /= tri["pt3"]["z"]
        
        tri["pt1"]["y"] /= tri["pt1"]["z"]
        tri["pt2"]["y"] /= tri["pt2"]["z"]
        tri["pt3"]["y"] /= tri["pt3"]["z"]
        
        triangles_projected.append(tri)
       
    triangles_scaled = []
    for triangle_projected in triangles_projected:
        tri = copy.deepcopy(triangle_projected)
        
        tri["pt1"]["x"] *= scale_x
        tri["pt2"]["x"] *= scale_x
        tri["pt3"]["x"] *= scale_x
        
        tri["pt1"]["y"] *= scale_y
        tri["pt2"]["y"] *= scale_y
        tri["pt3"]["y"] *= scale_y
        
        triangles_scaled.append(tri)
        
    return triangles_scaled


run()