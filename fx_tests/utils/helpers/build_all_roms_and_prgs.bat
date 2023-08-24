REM Cache write tests
REM ./vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DEFAULT -o ./fx_tests/multibyte_writes.rom
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=0 -o ./fx_tests/ROM/SINGLE-WRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=0 -D CREATE_PRG -o ./fx_tests/SD/SINGLE-WRITE.PRG
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=1 -o ./fx_tests/ROM/MULTI-WRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=1 -D CREATE_PRG -o ./fx_tests/SD/MULTI-WRITE.PRG

REM Cache read and write tests
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=0 -o ./fx_tests/ROM/SINGLE-READWRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=0 -D CREATE_PRG -o ./fx_tests/SD/SINGLE-READWRITE.PRG
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=1 -o ./fx_tests/ROM/MULTI-READWRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=1 -D CREATE_PRG -o ./fx_tests/SD/MULTI-READWRITE.PRG

REM Line draw tests


REM Polygon filler tests

REM FIXME: ADD MORE OPTIONS HERE!

REM WARNING!!! THERE ARE INCORRECT SLOPE TABLES FOR NOFXPOLY!!
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -D USE_POLYGON_FILLER=0 -D USE_UNROLLED_LOOP=0 -o ./fx_tests/ROM/POLYFILL-NOFXPOLY.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -D USE_POLYGON_FILLER=0 -D USE_UNROLLED_LOOP=0 -D CREATE_PRG -o ./fx_tests/SD/POLYFILL-NOFXPOLY.PRG
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -D USE_POLYGON_FILLER=0 -D USE_UNROLLED_LOOP=1 -o ./fx_tests/ROM/POLYFILL-NOFXPOLY-UNROLL.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -D USE_POLYGON_FILLER=0 -D USE_UNROLLED_LOOP=1 -D CREATE_PRG -o ./fx_tests/SD/POLYFILL-NOFXPOLY-UNROLL.PRG

vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -D USE_POLYGON_FILLER=1 -D USE_UNROLLED_LOOP=0 -o ./fx_tests/ROM/POLYFILL-FXPOLY.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -D USE_POLYGON_FILLER=1 -D USE_UNROLLED_LOOP=0 -D CREATE_PRG -o ./fx_tests/SD/POLYFILL-FXPOLY.PRG

REM copy SLOPE tables (16kB each)
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

REM copy DIVISION tables (16kB each)
copy .\fx_tests\tables\div_pos_0_low.bin  .\fx_tests\SD\TBL\DIV-A.BIN
copy .\fx_tests\tables\div_pos_0_high.bin .\fx_tests\SD\TBL\DIV-B.BIN
copy .\fx_tests\tables\div_pos_1_low.bin  .\fx_tests\SD\TBL\DIV-C.BIN
copy .\fx_tests\tables\div_pos_1_high.bin .\fx_tests\SD\TBL\DIV-D.BIN