
# VERA FX Tests

The VERA FX update contains quite a lot of new features that need to be tested.

Below are the FX tests that have been created to test all facets of the FX feature set.

### Running the tests

For each of these tests a PRG file is generated. These PRG files are located in the SD folder. 
Some tests require some additional files and these are also included in the SD folder.

To run the tests copy the contents of the SD folder (in this git repo) to a folder on your SD card (e.g. "FX-TESTS").
Then using the `DOS "CD:<MY FOLDER>` command go to the folder where all tests are located. 
Using the command `DOS "$` or the command `LOAD "$",8` you can see all the PRG files. 
Do a `LOAD "<THE FILENAME.PRG>"` to load a specific test program and `RUN` to execute it.

Alternatively you can use a .rom file (inside the ROM folder) to run these tests as a ROM.


## Cache write tests

These test uses the 32-bit cache to write many times to a bitmap. Essentially filling the screen.

There are multiple variants: 
  - filling to a 4bpp bitmap (320x240) or a 8bpp bitmap (320x240). 
  - filling one byte a time (the old way) or four bytes at the same time (using the 32-bit cache)

Here are the corresponding PRGs:

> **SINGLE-WRITE-4BPP.PRG**

**SINGLE-WRITE-8BPP.PRG**

`**MULTI-WRITE-8BPP.PRG**`

**MULTI-WRITE-4BPP.PRG**

## Line draw tests




## Affine helper tests



## Polygon filler tests



## Polygon 3D tests