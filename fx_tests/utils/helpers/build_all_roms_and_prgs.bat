@echo off

echo Building: Cache write tests

REM .\vasm6502_oldstyle.exe -Fbin -dotdir .\fx_tests\multibyte_writes.s -wdc02 -D DEFAULT -o .\fx_tests\multibyte_writes.rom

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=0 -o .\fx_tests\ROM\SINGLE-WRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=0 -D CREATE_PRG -o .\fx_tests\SD\SINGLE-WRITE.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=1 -o .\fx_tests\ROM\MULTI-WRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=1 -D CREATE_PRG -o .\fx_tests\SD\MULTI-WRITE.PRG

echo Building: Cache read and write tests

REM .\vasm6502_oldstyle.exe -Fbin -dotdir .\fx_tests\multibyte_blits.s -wdc02 -D DEFAULT -o .\fx_tests\multibyte_blits.rom

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=0 -o .\fx_tests\ROM\SINGLE-READWRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=0 -D CREATE_PRG -o .\fx_tests\SD\SINGLE-READWRITE.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=1 -o .\fx_tests\ROM\MULTI-READWRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=1 -D CREATE_PRG -o .\fx_tests\SD\MULTI-READWRITE.PRG

echo Building: Line draw tests


echo Building: Polygon filler tests

REM .\vasm6502_oldstyle.exe -Fbin -dotdir .\fx_tests\polygon_filler.s -wdc02 -D DEFAULT -o .\fx_tests\polygon_filler.rom

REM WARNING!!! THERE ARE INCORRECT SLOPE TABLES FOR NOFXPOLY!!
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=0 -D UNR=0 -D SLP=0 -D JMP=0 -o .\fx_tests\ROM\POLYFILL-NOFXPOLY.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=0 -D UNR=0 -D SLP=0 -D JMP=0 -D CREATE_PRG -o .\fx_tests\SD\POLYFILL-NOFXPOLY.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=0 -D UNR=1 -D SLP=0 -D JMP=0 -o .\fx_tests\ROM\POLYFILL-NOFXPOLY-UNROLL.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=0 -D UNR=1 -D SLP=0 -D JMP=0 -D CREATE_PRG -o .\fx_tests\SD\POLYFILL-NOFXPOLY-UNROLL.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=0 -D JMP=0 -o .\fx_tests\ROM\POLYFILL-FXPOLY.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=0 -D JMP=0 -D CREATE_PRG -o .\fx_tests\SD\POLYFILL-FXPOLY.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=1 -D JMP=0 -o .\fx_tests\ROM\POLYFILL-FXPOLY-SLP.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=1 -D JMP=0 -D CREATE_PRG -o .\fx_tests\SD\POLYFILL-FXPOLY-SLP.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=1 -D UNR=1 -D SLP=1 -D JMP=1 -o .\fx_tests\ROM\POLYFILL-FXPOLY-SLP-JMP.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_filler.s -wdc02 -D FXPOLY=1 -D UNR=1 -D SLP=1 -D JMP=1 -D CREATE_PRG -o .\fx_tests\SD\POLYFILL-FXPOLY-SLP-JMP.PRG

echo Building: Polygon 3D tests

REM .\vasm6502_oldstyle.exe -Fbin -dotdir .\fx_tests\polygon_3d.s -wdc02 -D DEFAULT -o .\fx_tests\polygon_3d.rom

REM FIXME! OVERLAPPING SECTIONS!?

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=0 -D JMP=0 -D DIV=0 -o .\fx_tests\ROM\POLY3D-FXPOLY.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=0 -D JMP=0 -D DIV=0 -D CREATE_PRG -o .\fx_tests\SD\POLY3D-FXPOLY.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=0 -D JMP=1 -D DIV=0 -o .\fx_tests\ROM\POLY3D-FXPOLY-JMP.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=0 -D JMP=1 -D DIV=0 -D CREATE_PRG -o .\fx_tests\SD\POLY3D-FXPOLY-JMP.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=1 -D JMP=0 -D DIV=0 -o .\fx_tests\ROM\POLY3D-FXPOLY-SLP.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=0 -D SLP=1 -D JMP=0 -D DIV=0 -D CREATE_PRG -o .\fx_tests\SD\POLY3D-FXPOLY-SLP.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=1 -D SLP=1 -D JMP=1 -D DIV=0 -o .\fx_tests\ROM\POLY3D-FXPOLY-SLP-JMP.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=1 -D SLP=1 -D JMP=1 -D DIV=0 -D CREATE_PRG -o .\fx_tests\SD\POLY3D-FXPOLY-SLP-JMP.PRG

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=1 -D SLP=1 -D JMP=1 -D DIV=1 -o .\fx_tests\ROM\POLY3D-FXPOLY-SLP-JMP-DIV.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\polygon_3d.s -wdc02 -D FXPOLY=1 -D UNR=1 -D SLP=1 -D JMP=1 -D DIV=1 -D CREATE_PRG -o .\fx_tests\SD\POLY3D-FXPOLY-SLP-JMP-DIV.PRG

echo Building: Affine helper tests

vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\tiled_mode.s -wdc02 -o .\fx_tests\ROM\MARIO-KART.ROM
vasm6502_oldstyle.exe -Fbin -dotdir -quiet .\fx_tests\tiled_mode.s -wdc02 -D CREATE_PRG -o .\fx_tests\SD\MARIO-KART.PRG


echo Copying: SLOPE tables (16kB each)
copy .\fx_tests\tables\slopes_packed_column_0_low.bin             .\fx_tests\SD\TBL\SLP-A.BIN
copy .\fx_tests\tables\slopes_packed_column_0_high.bin            .\fx_tests\SD\TBL\SLP-B.BIN
copy .\fx_tests\tables\slopes_packed_column_1_low.bin             .\fx_tests\SD\TBL\SLP-C.BIN
copy .\fx_tests\tables\slopes_packed_column_1_high.bin            .\fx_tests\SD\TBL\SLP-D.BIN
copy .\fx_tests\tables\slopes_packed_column_2_low.bin             .\fx_tests\SD\TBL\SLP-E.BIN
copy .\fx_tests\tables\slopes_packed_column_2_high.bin            .\fx_tests\SD\TBL\SLP-F.BIN
copy .\fx_tests\tables\slopes_packed_column_3_low.bin             .\fx_tests\SD\TBL\SLP-G.BIN
copy .\fx_tests\tables\slopes_packed_column_3_high.bin            .\fx_tests\SD\TBL\SLP-H.BIN
copy .\fx_tests\tables\slopes_packed_column_4_low.bin             .\fx_tests\SD\TBL\SLP-I.BIN
copy .\fx_tests\tables\slopes_packed_column_4_high.bin            .\fx_tests\SD\TBL\SLP-J.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_0_low.bin    .\fx_tests\SD\TBL\SLP-K.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_0_high.bin   .\fx_tests\SD\TBL\SLP-L.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_1_low.bin    .\fx_tests\SD\TBL\SLP-M.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_1_high.bin   .\fx_tests\SD\TBL\SLP-N.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_2_low.bin    .\fx_tests\SD\TBL\SLP-O.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_2_high.bin   .\fx_tests\SD\TBL\SLP-P.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_3_low.bin    .\fx_tests\SD\TBL\SLP-Q.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_3_high.bin   .\fx_tests\SD\TBL\SLP-R.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_4_low.bin    .\fx_tests\SD\TBL\SLP-S.BIN
copy .\fx_tests\tables\slopes_negative_packed_column_4_high.bin   .\fx_tests\SD\TBL\SLP-T.BIN

echo Copying: DIVISION tables (16kB each)
copy .\fx_tests\tables\div_pos_0_low.bin  .\fx_tests\SD\TBL\DIV-A.BIN
copy .\fx_tests\tables\div_pos_0_high.bin .\fx_tests\SD\TBL\DIV-B.BIN
copy .\fx_tests\tables\div_pos_1_low.bin  .\fx_tests\SD\TBL\DIV-C.BIN
copy .\fx_tests\tables\div_pos_1_high.bin .\fx_tests\SD\TBL\DIV-D.BIN

echo Copying: PERPECTIVE tables (16kB each)
copy .\fx_tests\tables\x_subpixel_positions_in_map_low1.bin  .\fx_tests\SD\TBL\PERS-A.BIN
copy .\fx_tests\tables\x_subpixel_positions_in_map_low2.bin  .\fx_tests\SD\TBL\PERS-B.BIN
copy .\fx_tests\tables\x_subpixel_positions_in_map_high1.bin .\fx_tests\SD\TBL\PERS-C.BIN
copy .\fx_tests\tables\x_subpixel_positions_in_map_high2.bin .\fx_tests\SD\TBL\PERS-D.BIN
copy .\fx_tests\tables\y_subpixel_positions_in_map_low1.bin  .\fx_tests\SD\TBL\PERS-E.BIN
copy .\fx_tests\tables\y_subpixel_positions_in_map_low2.bin  .\fx_tests\SD\TBL\PERS-F.BIN
copy .\fx_tests\tables\y_subpixel_positions_in_map_high1.bin .\fx_tests\SD\TBL\PERS-G.BIN
copy .\fx_tests\tables\y_subpixel_positions_in_map_high2.bin .\fx_tests\SD\TBL\PERS-H.BIN
copy .\fx_tests\tables\x_pixel_positions_in_map_low1.bin     .\fx_tests\SD\TBL\PERS-I.BIN
copy .\fx_tests\tables\x_pixel_positions_in_map_low2.bin     .\fx_tests\SD\TBL\PERS-J.BIN
copy .\fx_tests\tables\x_pixel_positions_in_map_high1.bin    .\fx_tests\SD\TBL\PERS-K.BIN
copy .\fx_tests\tables\x_pixel_positions_in_map_high2.bin    .\fx_tests\SD\TBL\PERS-L.BIN
copy .\fx_tests\tables\y_pixel_positions_in_map_low1.bin     .\fx_tests\SD\TBL\PERS-M.BIN
copy .\fx_tests\tables\y_pixel_positions_in_map_low2.bin     .\fx_tests\SD\TBL\PERS-N.BIN
copy .\fx_tests\tables\y_pixel_positions_in_map_high1.bin    .\fx_tests\SD\TBL\PERS-O.BIN
copy .\fx_tests\tables\y_pixel_positions_in_map_high2.bin    .\fx_tests\SD\TBL\PERS-P.BIN
copy .\fx_tests\tables\x_sub_pixel_steps_low1.bin            .\fx_tests\SD\TBL\PERS-Q.BIN
copy .\fx_tests\tables\x_sub_pixel_steps_low2.bin            .\fx_tests\SD\TBL\PERS-R.BIN
copy .\fx_tests\tables\x_sub_pixel_steps_high1.bin           .\fx_tests\SD\TBL\PERS-S.BIN
copy .\fx_tests\tables\x_sub_pixel_steps_high2.bin           .\fx_tests\SD\TBL\PERS-T.BIN
copy .\fx_tests\tables\y_sub_pixel_steps_low1.bin            .\fx_tests\SD\TBL\PERS-U.BIN
copy .\fx_tests\tables\y_sub_pixel_steps_low2.bin            .\fx_tests\SD\TBL\PERS-V.BIN
copy .\fx_tests\tables\y_sub_pixel_steps_high1.bin           .\fx_tests\SD\TBL\PERS-W.BIN
copy .\fx_tests\tables\y_sub_pixel_steps_high2.bin           .\fx_tests\SD\TBL\PERS-X.BIN
