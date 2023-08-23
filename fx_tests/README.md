
# VERA FX Tests

The VERA FX update contains quite a lot of new features that need to be tested.

Below are the FX tests that have been created to test all facets of the FX feature set.

### Building into ROM or PRG files

For each of these tests a .rom file can be created or a alternatively a PRG file. 
Some tests require some additional files to be generated and included. 
For each test the steps to produce these .rom/.PRG or additional files is given.

**Note** that these files have already been pre-generated and are located in the ROM vs SD folder respectively.


## Cache write tests

The cache write tests can be build into a .rom like this:

`./vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -o ./fx_tests/ROM/multibyte_writes.rom`

or as a PRG like this:

`./vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/multibyte_writes.s -wdc02 -D CREATE_PRG -o ./fx_tests/SD/MULTI-WRITE.PRG`

## Line draw tests




## Affine helper tests



## Polygon filler tests

The polygon filler tests can be build into a .rom like this:

`./vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -o ./fx_tests/ROM/polygon_filler.rom` 

or as a PRG like this:

`./vasm6502_oldstyle.exe -Fbin -dotdir ./fx_tests/polygon_filler.s -wdc02 -o ./fx_tests/ROM/polygon_filler.rom` 




## Polygon 3D tests