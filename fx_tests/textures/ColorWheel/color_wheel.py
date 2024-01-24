# To install pygame: pip install pygame      (my version: pygame-2.1.2)
from PIL import Image
import pygame
import math
import time
import random
from functools import cmp_to_key

random.seed(10)

DRAW_NEW_PALETTE = False
SHOW_12BIT_COLORS = True
SHOW_ORG_PICTURE = False
DRAW_STRUCTURAL_POINTS = False

source_image_filename = "color_wheel.png"
# FIXME: we probably want to use a higher resolution source file!
source_image_width = 1600
source_image_height = 1600
bitmap_filename = "COLORWHEEL.DAT"
tile_data_filename = "WHEEL-TILES.DAT"
tile_map0_filename = "WHEEL-MAP0.DAT"
tile_map1_filename = "WHEEL-MAP1.DAT"

screen_width = 320
screen_height = 240

# IMPORANT: set this to 1 if you want 320x240 output, set to 2 if you want 640x480 output
scale = 2

# creating a image object for the background
#im_org = Image.open(source_image_filename)
#px_org = im_org.load()
im_surface_org = pygame.image.load(source_image_filename)



# Generating your own 'color wheel':

# - determine the distance between two points (this is the length of the side of all diamand shapes): its around 72px? (for 1600x1600 picture)
# - determine all points:
#   - start at the top point (x = 0*sin(angle), y = -72*cos(angle))
#   - next point is calculated by changing the angle
#   - store the angle (from the middle) to each point (this is a lookup table, which loops)
#   - the next ring points (n+2) can be calculated by taking the *two* n->n+1 vectors  *adding* them together


# Create the empty points first
rows_of_points = []
for i in range(13):
    rows_of_points.append([])
    for j in range(36):
        rows_of_points[i].append((None,None))
        
# We use brightness_index = 0 as center point, we create 36 of them!
for hue_angle_index in range(36):
    rows_of_points[0][hue_angle_index] = (0,0)

# FIXME: ADJUST THIS!
# FIXME: ADJUST THIS!
# FIXME: ADJUST THIS!
side_length = 71.5
# We use brightness_index = 1 as first ring, we create 36 of them with a starting position
for hue_angle_index in range(36):

    hue_angle = math.radians(hue_angle_index * 10)

    x_offset = math.sin(hue_angle)
    y_offset = - math.cos(hue_angle)
    
    point_x = x_offset*side_length
    point_y = y_offset*side_length
    
    rows_of_points[1][hue_angle_index] = (point_x,point_y)

        
# We then do each next ring of points
for brightness_index in range(2, 13):
    for hue_angle_index in range(36):

        left_index = None
        right_index = None
        if (brightness_index % 2 == 0):
            left_index = hue_angle_index
            right_index = hue_angle_index + 1
        else:
            left_index = hue_angle_index - 1
            right_index = hue_angle_index
            
        if (left_index < 0):
            left_index += 36
        if (right_index >= 36):
            right_index -= 36

        base_point = rows_of_points[brightness_index-2][hue_angle_index]
        left_point = rows_of_points[brightness_index-1][left_index]
        right_point = rows_of_points[brightness_index-1][right_index]
        
        delta_x = (left_point[0] - base_point[0]) + (right_point[0] - base_point[0])
        delta_y = (left_point[1] - base_point[1]) + (right_point[1] - base_point[1])
        
        point_x = base_point[0] + delta_x
        point_y = base_point[1] + delta_y
        
        rows_of_points[brightness_index][hue_angle_index] = (point_x,point_y)
    




background_color = (0,0,0)


pygame.init()

pygame.display.set_caption('X16 Color wheel')
screen = pygame.display.set_mode((screen_width*scale, screen_height*scale))
clock = pygame.time.Clock()

source_image_buffer = pygame.Surface((source_image_width, source_image_height))
source_image_buffer.blit(im_surface_org, (0, 0))



screen.fill(background_color)

center_x = source_image_width // 2
center_y = source_image_height // 2


radius_per_brightness_index = [
    80,
    148,
    216,
    282,
    349,
    408,
    475,
    526,
    582,
    624,
    670
]


colors_24bit = []
colors_24bit.append((0,0,0)) # black is always color #0
for brightness_index in range(11):

    radius = radius_per_brightness_index[brightness_index]
        
    for hue_angle_index in range(0, 36):

        if (brightness_index % 2 == 0): 
            hue_angle = math.radians(hue_angle_index * 10 + 5)
        else:
            hue_angle = math.radians(hue_angle_index * 10)
    
        x_offset = math.sin(hue_angle)
        y_offset = - math.cos(hue_angle)
        
        sample_point_x = int(center_x + x_offset*radius)
        sample_point_y = int(center_y + y_offset*radius)
        
        sample_color = source_image_buffer.get_at((sample_point_x, sample_point_y))
        colors_24bit.append(sample_color)
        
        #mark_point_color = (0xFF, 0xFF, 0x00)
        #pygame.draw.rect(source_image_buffer, mark_point_color, pygame.Rect(sample_point_x, sample_point_y, 4, 4))




def get_color_24bit_by_org_index(clr_idx):
    color_24bit = colors_24bit[clr_idx] 
    
    if (SHOW_12BIT_COLORS):
        r = color_24bit[0]
        g = color_24bit[1]
        b = color_24bit[2]

        # 8 bit to 4 bit conversion (for each channel)
        r = int((r * 15 + 135)) >> 8
        g = int((g * 15 + 135)) >> 8
        b = int((b * 15 + 135)) >> 8
        
        new_12bit_color = (r,g,b)
        
        # 4 bit to 8 bit (for each channel)
        r = new_12bit_color[0] * 17
        g = new_12bit_color[1] * 17
        b = new_12bit_color[2] * 17
        
        color_24bit = (r,g,b)
        
    return color_24bit

def get_color_12bit_by_org_index(clr_idx):

    color_24bit = colors_24bit[clr_idx] 
    
    r = color_24bit[0]
    g = color_24bit[1]
    b = color_24bit[2]

    # 8 bit to 4 bit conversion (for each channel)
    r = int((r * 15 + 135)) >> 8
    g = int((g * 15 + 135)) >> 8
    b = int((b * 15 + 135)) >> 8
    
    color_12bit = (r,g,b)
    
    return color_12bit

def get_max_and_min_y_for_polygon(diamond_polygon):

    min_y = None
    max_y = None
    
    for point in diamond_polygon:
        if min_y is None or point[1] < min_y:
            min_y = point[1]
        if max_y is None or point[1] > max_y:
            max_y = point[1]

    return (min_y, max_y)

polygons = []

# FIXME! Right now we dont draw the WHITE, so the MIDDLE is different from the original!
# FIXME! Right now we dont draw the WHITE, so the MIDDLE is different from the original!
# FIXME! Right now we dont draw the WHITE, so the MIDDLE is different from the original!
for brightness_index in range(0,11):
        
    for hue_angle_index in range(0, 36):

        left_index = None
        right_index = None
        if (brightness_index % 2 == 0):
            left_index = hue_angle_index
            right_index = hue_angle_index + 1
        else:
            left_index = hue_angle_index - 1
            right_index = hue_angle_index
            
        if (left_index < 0):
            left_index += 36
        if (right_index >= 36):
            right_index -= 36
            
        base_point = rows_of_points[brightness_index][hue_angle_index]
        left_point = rows_of_points[brightness_index+1][left_index]
        right_point = rows_of_points[brightness_index+1][right_index]
        far_point = rows_of_points[brightness_index+2][hue_angle_index]

        top_diamond_polygon = [
            (int(center_x+base_point[0]), int(center_y+base_point[1])), 
            (int(center_x+left_point[0]), int(center_y+left_point[1])), 
            (int(center_x+far_point[0]), int(center_y+far_point[1])), 
            (int(center_x+right_point[0]), int(center_y+right_point[1])), 
        ]
        top_clr_idx = brightness_index*36+hue_angle_index+1  # +1 due to color #0 (black)
        (top_min_y, top_max_y) = get_max_and_min_y_for_polygon(top_diamond_polygon)
        
        # We also add the vertical-mirror of this polygon (its "bottom-mirror")
        bottom_diamond_polygon = [
# FIXME: should we reverse the order of the polygon-vertices here?
            (int(center_x+base_point[0]), int(center_y-base_point[1])), 
            (int(center_x+left_point[0]), int(center_y-left_point[1])), 
            (int(center_x+far_point[0]), int(center_y-far_point[1])), 
            (int(center_x+right_point[0]), int(center_y-right_point[1])), 
        ]
        # We mirror the hue index
        if (brightness_index % 2 == 0):
            bottom_hue_angle_index = 18 - hue_angle_index
        else:
            bottom_hue_angle_index = 19 - hue_angle_index

        if bottom_hue_angle_index < 0:
            bottom_hue_angle_index += 36
        bottom_clr_idx = brightness_index*36+bottom_hue_angle_index+1  # +1 due to color #0 (black)
        # (bottom_min_y, bottom_max_y) = get_max_and_min_y_for_polygon(bottom_diamond_polygon)
        
        
        polygons.append((top_clr_idx, top_min_y, top_max_y, top_diamond_polygon, bottom_clr_idx, bottom_diamond_polygon))


def compare_polygons(polygon_a, polygon_b):
    
    result = None

    #if ('in_front_of' in face_a):
    #    if (face_b['orig_face_index'] in face_a['in_front_of']):
    #        return -1
            
    #if ('in_front_of' in face_b):
    #    if (face_a['orig_face_index'] in face_b['in_front_of']):
    #        return 1

    min_y_a = polygon_a[1]
    min_y_b = polygon_b[1]
    max_y_a = polygon_a[2]
    max_y_b = polygon_b[2]
    
    avg_y_a = (min_y_a + max_y_a) / 2
    avg_y_b = (min_y_b + max_y_b) / 2
    
    '''
    # TODO: we wanted to use this setting to use a different way of sorting for the top and bottom polygons
    #       but this is probematic when trying to create two palettes that need to be flipped.
    #       So for now we dont use this. But it may be beneficial to the amount of time available to swap the palette.
    use_max_y_for_sorting = True

    if (use_max_y_for_sorting):
        if max_y_a == max_y_b:
            result = 0
        if max_y_a < max_y_b:
            result = 1
        if max_y_a > max_y_b:
            result = -1
    else:
        if min_y_a == min_y_b:
            result = 0
        if min_y_a < min_y_b:
            result = 1
        if min_y_a > min_y_b:
            result = -1
    '''
            
    if avg_y_a == avg_y_b:
        result = 0
    if avg_y_a < avg_y_b:
        result = 1
    if avg_y_a > avg_y_b:
        result = -1
            
    return result

compare_key = cmp_to_key(compare_polygons)


top_to_bottom_sorted_polygons = sorted(polygons, key=compare_key, reverse=True)
#bottom_to_top_sorted_polygons = sorted(polygons, key=compare_key, reverse=False)

frame_buffer = pygame.Surface((source_image_width, source_image_height), depth=8)


if (not SHOW_ORG_PICTURE):
    frame_buffer.fill(0)


# These are two 256-color palettes
colors_12bit_top = []
colors_12bit_bottom = []
colors_24bit_top = []
colors_24bit_bottom = []

# We add BLACK as color #0
colors_12bit_top.append((0,0,0))
colors_24bit_top.append((0,0,0))
colors_12bit_bottom.append((0,0,0))
colors_24bit_bottom.append((0,0,0))

all_polygons = []
for top_to_bottom_sorted_idx, top_polygon_info in enumerate(top_to_bottom_sorted_polygons):

    # There are 11*36 colors in the color wheel = 396 colors
    # There is also BLACK and WHITE
    
    # The amount of colors in a X16 palette is 256 (of which the first one we want to be BLACK) so 255 of available colors
    # So we need to put 397 colors (396 + WHITE) into a 255 palette somehow. We do that by swapping (397-255=) 142 colors each frame
    # We want the top and bottom 142 diamonds/colors to be swapped. So we want the following palette:
    # - 1 color BLACK
    # - 142 colors (first the TOP ones, overwritten by the BOTTOM ones)
    # - 112 middle colors 
    # - 1 color WHITE
    
    
    (top_clr_idx, top_min_y, top_max_y, top_diamond_polygon, bottom_clr_idx, bottom_diamond_polygon) = top_polygon_info
    
    if (top_to_bottom_sorted_idx >= 396 - 142):
        # We STOP where we reach 396-142 index! (so 254 colors added, BLACK and WHITE are added at the beginning/end)
        break
    elif (top_to_bottom_sorted_idx < 142):
    
        # Note: we want the bottom 142 diamonds to be sorted top to bottom, so we negate the index here
        #bottom_to_top_sorted_idx = 142 - top_to_bottom_sorted_idx
        #bottom_polygon_info = bottom_to_top_sorted_polygons[bottom_to_top_sorted_idx]
        #(bottom_clr_idx, bottom_min_y, bottom_max_y, bottom_diamond_polygon) = bottom_polygon_info
        
        top_color_12bit = get_color_12bit_by_org_index(top_clr_idx)
        top_color_24bit = get_color_24bit_by_org_index(top_clr_idx)
        bottom_color_12bit = get_color_12bit_by_org_index(bottom_clr_idx)
        bottom_color_24bit = get_color_24bit_by_org_index(bottom_clr_idx)
        
        # Note: the top and bottom polygons share the same color 142 indexes!
        new_clr_idx = top_to_bottom_sorted_idx+1
        
        new_polygon_info = (new_clr_idx, top_diamond_polygon)
        all_polygons.append(new_polygon_info)
        colors_12bit_top.append(top_color_12bit)
        colors_24bit_top.append(top_color_24bit)

        # TODO: we probably shouldnt draw this polygon this early, but drawing order doesnt really matter (only color order)
        new_polygon_info = (new_clr_idx, bottom_diamond_polygon)
        all_polygons.append(new_polygon_info)
        colors_12bit_bottom.append(bottom_color_12bit)
        colors_24bit_bottom.append(bottom_color_24bit)
    else:
        new_clr_idx = top_to_bottom_sorted_idx+1
        
        # FIXME: HACK! the +5 is a HACK to work around the polygons right in the middle of the screen!
        if (top_to_bottom_sorted_idx >= 396 // 2 + 5):
            # WORKAROUND:
            # if we are beyond half of the polygons we get into sorting issues (the bottom half of the polyons is not sorted perfectly in reverse compared to the top half)
            # In order to fix that we simply "playback" the polygons in reverse after reaching half of them. And we take the mirror polygon of those polygons.
            inv_top_polygon_info = top_to_bottom_sorted_polygons[395-top_to_bottom_sorted_idx]
            (tmp_top_clr_idx, tmp_top_min_y, tmp_top_max_y, tmp_top_diamond_polygon, tmp_bottom_clr_idx, tmp_bottom_diamond_polygon) = inv_top_polygon_info
            
            top_clr_idx = tmp_bottom_clr_idx
            top_diamond_polygon = tmp_bottom_diamond_polygon

        # We use the top colors/polygons for the middle polygons
        color_12bit = get_color_12bit_by_org_index(top_clr_idx)
        color_24bit = get_color_24bit_by_org_index(top_clr_idx)
        
        new_polygon_info = (new_clr_idx, top_diamond_polygon)
        all_polygons.append(new_polygon_info)
    
        colors_12bit_top.append(color_12bit)
        colors_24bit_top.append(color_24bit)
        colors_12bit_bottom.append(color_12bit)
        colors_24bit_bottom.append(color_24bit)
    


# We add WHITE as color #255
colors_12bit_top.append((15,15,15))
colors_24bit_top.append((255,255,255))
colors_12bit_bottom.append((15,15,15))
colors_24bit_bottom.append((255,255,255))


# Printing out asm for top palette:
palette_string = "top_palette:\n"
for new_color in colors_12bit_top:
    red = new_color[0]
    green = new_color[1]
    blue = new_color[2]
    
    green = green << 4

    palette_string += "  .byte "
    palette_string += "$" + format(green | blue,"02x") + ", "
    palette_string += "$" + format(red,"02x")
    palette_string += "\n"

print(palette_string)


palette_string = "bottom_palette:\n"
for new_color in colors_12bit_bottom:
    red = new_color[0]
    green = new_color[1]
    blue = new_color[2]

    green = green << 4

    palette_string += "  .byte "
    palette_string += "$" + format(green | blue,"02x") + ", "
    palette_string += "$" + format(red,"02x")
    palette_string += "\n"

print(palette_string)


for polygon_info in all_polygons:

    (clr_idx_256, diamond_polygon) = polygon_info

    pygame.draw.polygon(frame_buffer, clr_idx_256, diamond_polygon)
    

# Scaling to the size we want to draw on the X16    
# FIXME: we should have TWO kinds of scales: one for the scale on the X16 and one scale for pygame!
scaled_surface = pygame.transform.scale(frame_buffer, (screen_height*scale, screen_height*scale))

# We want to draw in the middle of the screen
start_x = (screen_width-screen_height)//2*scale
end_x = screen_width-start_x
    
if (scale == 1):

    # FIXME: this needs adjusting when scaling to 640x480!!
    bitmap_data = []

    scaled_pxarray = pygame.PixelArray(scaled_surface)
    for screen_y in range(screen_height*scale):

        for screen_x in range(screen_width*scale):

            if (screen_x < start_x or screen_x >= end_x):
                pixel_color_index = 0
            else:
                pixel_color_index = scaled_pxarray[screen_x-start_x, screen_y]
            
            bitmap_data.append(pixel_color_index)
    scaled_pxarray.close()

    tableFile = open(bitmap_filename, "wb")
    tableFile.write(bytearray(bitmap_data))
    tableFile.close()
    print("bitmap written to file: " + bitmap_filename)
else:


    # We generate tile data and two tile maps (needed for 640x480 mode)

    tiles_data = []
    tile_index = 0

    # Our first 16x16 tile is completely black 
    tile_data = [0] * 256
    tiles_data.append(tile_data)
    tile_index += 1
    tile_map_0 = []
    tile_map_1 = []

    scaled_pxarray = pygame.PixelArray(scaled_surface)
    for screen_tile_y_index in range(32):
        for screen_tile_x_index in range(64):
            # Layer 0 is only visible up to tile row 18
            if screen_tile_y_index >= 18:
                tile_map_0.append(0)
                continue
            
            # There are 5 tiles on each side (640-480=160, 160/16 = 10 tiles)
            if (screen_tile_x_index < 5 or screen_tile_x_index >= 40-5):
                tile_map_0.append(0)
                continue
                
            # We extract the pixel bytes from the scaled_surface and see if its not all black
            tile_data = []
            is_all_black = True
            for column_in_tile_index in range(16):
                for row_in_tile_index in range(16):
                    scaled_x = (screen_tile_x_index-5) * 16 + row_in_tile_index
                    scaled_y = screen_tile_y_index * 16 + column_in_tile_index
                    pixel_color_index = scaled_pxarray[scaled_x, scaled_y]
                    if (pixel_color_index != 0):
                        is_all_black = False
                    tile_data.append(pixel_color_index)

            # If the tile turned out to be complete black, we can simply re-use the black tile
            if (is_all_black):
                tile_map_0.append(0)
                continue

            # The tile is not black so we add the tile data and we add the new tile to the map
            tiles_data.append(tile_data)
            tile_map_0.append(tile_index)
            tile_index += 1
            
    scaled_pxarray.close()

    for screen_tile_y_index in range(32):
        for screen_tile_x_index in range(64):
            # Layer 1 is only visible from tile row 18
            if screen_tile_y_index < 18 or screen_tile_y_index >= 30:
                tile_map_1.append(0)
                continue
            else:
                # Otherwise its going to be the vertical-mirror of tile_map_0
                mirror_tile_nr_0 = (29-screen_tile_y_index)*64 + screen_tile_x_index
                tile_map_1.append(tile_map_0[mirror_tile_nr_0])
        
    #print(tile_map_0)
    #print(tile_map_1)

    tile_data_bytes = []
    for tile_data in tiles_data:
        tile_data_bytes += tile_data

    tableFile = open(tile_data_filename, "wb")
    tableFile.write(bytearray(tile_data_bytes))
    tableFile.close()
    print("tile data written to file: " + tile_data_filename)

    tile_map_0_bytes = []
    for tile_index in tile_map_0:
        tile_index_low = tile_index % 256
        tile_index_high = tile_index // 256
        
        tile_map_0_bytes.append(tile_index_low)
        tile_map_0_bytes.append(tile_index_high)
        
        
    tile_map_1_bytes = []
    for tile_index in tile_map_1:
        tile_index_low = tile_index % 256
        tile_index_high = tile_index // 256
        
        tile_index_high = tile_index_high | 0x04  # v-flip

        tile_map_1_bytes.append(tile_index_low)
        tile_map_1_bytes.append(tile_index_high)


    tableFile = open(tile_map0_filename, "wb")
    tableFile.write(bytearray(tile_map_0_bytes))
    tableFile.close()
    print("tile map 0 written to file: " + tile_map0_filename)

    tableFile = open(tile_map1_filename, "wb")
    tableFile.write(bytearray(tile_map_1_bytes))
    tableFile.close()
    print("tile map 1 written to file: " + tile_map1_filename)

    
'''
if (DRAW_STRUCTURAL_POINTS):
    # Draw structural points
    for brightness_index in range(0, 13):
        for hue_angle_index in range(0, 36):

            point = rows_of_points[brightness_index][hue_angle_index]
            
            structural_point_x = int(center_x + point[0])
            structural_point_y = int(center_y + point[1])
            
            mark_structural_point_color = (0x00, 0xFF, 0xFF)
            pygame.draw.rect(frame_buffer, mark_structural_point_color, pygame.Rect(structural_point_x, structural_point_y, 4, 4))
'''


screen.fill((0,0,0))


scaled_surface.set_palette(colors_24bit_top)
# IMPORANT: we scale to a SQUARE here so we use screen_height for the destination width as well!
screen.blit(scaled_surface, dest=(start_x, 0), area=pygame.Rect(0,0,screen_height*scale, screen_height*scale//2))
scaled_surface.set_palette(colors_24bit_bottom)
screen.blit(scaled_surface, dest=(start_x, screen_height*scale//2), area=pygame.Rect(0,screen_height*scale//2,screen_height*scale, screen_height*scale//2))



def run():

    running = True
    
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)
        
        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False

            '''
            # if event.type == pygame.KEYDOWN:
                    
                #if event.key == pygame.K_LEFT:
                #if event.key == pygame.K_RIGHT:
                #if event.key == pygame.K_COMMA:
                #if event.key == pygame.K_PERIOD:
                #if event.key == pygame.K_UP:
                #if event.key == pygame.K_DOWN:
                    
            #if event.type == pygame.MOUSEMOTION: 
                # newrect.center = event.pos
            '''
            
                
                
        if (DRAW_NEW_PALETTE):
            # screen.fill(background_color)
            
            diamond_width = 8
            diamond_height = 8
            
            x = diamond_width // 2
            y = 0
            
            for clr_idx in range(396):
            
                #if clr_idx >= len(colors_12bit):
                #    continue

                color_24bit = colors_24bit[clr_idx+1]  # +1 due to color #0 (black)
                if (SHOW_12BIT_COLORS):
                    r = color_24bit[0]
                    g = color_24bit[1]
                    b = color_24bit[2]

                    # 8 bit to 4 bit conversion (for each channel)
                    r = int((r * 15 + 135)) >> 8
                    g = int((g * 15 + 135)) >> 8
                    b = int((b * 15 + 135)) >> 8
                    
                    new_12bit_color = (r,g,b)
                    
                    # 4 bit to 8 bit (for each channel)
                    r = new_12bit_color[0] * 17
                    g = new_12bit_color[1] * 17
                    b = new_12bit_color[2] * 17
                    
                    color_24bit = (r,g,b)
                    
                left_diamond_x = x
                middle_diamond_x = x + diamond_width // 2
                right_diamond_x = x + diamond_width
                top_diamond_y = y
                middle_diamond_y = y + diamond_height // 2
                bottom_diamond_y = y + diamond_height
                
                diamond_polygon = [
                    (middle_diamond_x*scale, top_diamond_y*scale), 
                    (right_diamond_x*scale, middle_diamond_y*scale), 
                    (middle_diamond_x*scale, bottom_diamond_y*scale), 
                    (left_diamond_x*scale, middle_diamond_y*scale), 
                ]

                pygame.draw.polygon(screen, color_24bit, diamond_polygon)
                # pygame.draw.rect(screen, color_24bit, pygame.Rect(x*scale, y*scale, 8*scale, 8*scale))
                
                # if (byte_index % 16 == 0 and byte_index != 0):
                if (clr_idx % 36 == 35):
                    y += diamond_height // 2
                    if ((clr_idx // 36) % 2 == 0):
                        x = 0
                    else:
                        x = diamond_width // 2
                else:
                    x += diamond_width

        
        pygame.display.update()
        
        #time.sleep(0.01)
   
        
    pygame.quit()


    
run()
