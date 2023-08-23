
# VERA FX Tests

The VERA FX update contains quite a lot of new features that need to be tested.

Below are the FX tests that have been created to test all facets of the FX feature set.

### PRG files

For each of these tests a PRG file is generated. These PRG files are located in the SD folder. 
Some tests require some additional files and these are also included in the SD folder.

To run the tests copy the contents of the SD folder (in this git repo) to a folder on your SD card (e.g. "FX-TESTS").
Then using the `DOS "CD:<MY FOLDER>` command go to the folder where all tests are located. 
Using the command `DOS "$` or the command `LOAD "$",8` you can see all the PRG files. 
Do a `LOAD "<THE FILENAME.PRG>"` to load a specific test program and `RUN` to execute it.

Alternatively you can use a .rom file (inside the ROM folder) to run these tests as a ROM.


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