

for cur_volume in range(64):
    # case (cur_volume[5:2])
    volume_to_volume_shift = {
        0: 22,
        1: 16,
        2: 17,
        3: 18,
        4: 12,
        5: 13,
        6: 14,
        7: 8,
        8: 9,
        9: 10,
        10: 4,
        11: 5,
        12: 6,
        13: 0,
        14: 1,
        15: 2,
    }
    
    # case ({cur_volume_shift[1:0], cur_volume[1:0]})
    to_volume_base = {
        0: 270,
        1: 286,
        2: 303,
        3: 321,
        4: 341,
        5: 361,
        6: 382,
        7: 405,
        8: 429,
        9: 455,
        10: 482,
        11: 511,
        12: 511,
        13: 511,
        14: 511,
        15: 511,
    }
    
    # case (cur_volume)
    if (cur_volume == 0):
        cur_volume_log = 0
    elif (cur_volume == 1):
        cur_volume_log = 13
    elif (cur_volume == 2):
        cur_volume_log = 14
    else:
        
        mask_5_2 = 0b00111100
        cur_vol_5_2 = cur_volume & mask_5_2
        cur_volume_shift = volume_to_volume_shift[cur_vol_5_2 >> 2]
        
        mask_1_0 = 0b00000011
        cur_vol_shift_1_0 = cur_volume_shift & mask_1_0
        cur_volume_1_0 = cur_volume & mask_1_0
        cur_volume_base = to_volume_base[(cur_vol_shift_1_0 << 2) | cur_volume_1_0]
        
        mask_4_2 = 0b00011100
        cur_vol_shift_4_2 = cur_volume_shift & mask_4_2
        cur_volume_log = cur_volume_base >> (cur_vol_shift_4_2 >> 2);
            
    print(str(cur_volume) + ':' + str(cur_volume_log))
