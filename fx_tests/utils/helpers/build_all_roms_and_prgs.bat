REM Cache write tests
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=0 -o ./fx_tests/ROM/SINGLE-WRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=0 -D CREATE_PRG -o ./fx_tests/SD/SINGLE-WRITE.PRG
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=1 -o ./fx_tests/ROM/MULTI-WRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D DO_4_BYTES_PER_WRITE=1 -D CREATE_PRG -o ./fx_tests/SD/MULTI-WRITE.PRG

REM Cache read and write tests
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=0 -o ./fx_tests/ROM/SINGLE-READWRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=0 -D CREATE_PRG -o ./fx_tests/SD/SINGLE-READWRITE.PRG
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=1 -o ./fx_tests/ROM/MULTI-READWRITE.ROM
vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_blits.s -wdc02 -D DO_4_BYTES_PER_COPY=1 -D CREATE_PRG -o ./fx_tests/SD/MULTI-READWRITE.PRG


