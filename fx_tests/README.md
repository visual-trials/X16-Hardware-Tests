
# VERA FX Tests

The VERA FX update contains quite a lot of new features that need to be tested.

Below are the FX tests that have been created to test all facets of the FX feature set.

### Running the tests

For each of these tests a PRG file is generated. These PRG files are located in the SD folder. 
Some tests require some additional files and these are also included in the SD folder.

To run the tests copy the contents of the SD folder (in this git repo) to a folder on your SD card (e.g. "FX").
Then using the `DOS "CD:<MY FOLDER>` command go to the folder you just copied and where all the tests are located. 
Pressing `F7` or using the command `DOS "$` (or the command `LOAD "$"` followed by `LIST`) you can see all the PRG files. 
Do a `LOAD "<THE FILENAME.PRG>"` to load a specific test program and `RUN` to execute it.

Alternatively you can use a .rom file (inside the ROM folder) to run these tests as a ROM.

# Features to test

In the following sections several test programs will be described and screenshots will be included for each run on a machine or emulator.

These test programs test something specific: either an **old or a new feature** of VERA. Basicly, if things are working, something has been proven to work on that machine or emulator.

What they actually tested is mentioned in the column *"What this tests"*. This column will contain test (result) codes.

These start with a specific letter to group them together. These are the test groups:

| Group | Meaning |
| ---- | ------- |
|   A  | Affine helper |
|   B  | Backwards compatibility |
|   C  | 32-bit Cache |
|   L  | Line draw helper |
|   M  | Multiplier and accumulator |
|   O  | Other features |
|   P  | Polygon filler helper |

In the last section called *"Test results"* ([click link here](#test-results)) all test results (their code and their description) are put together in one table showing what does (or does not) work on what type of machine/emulator.

## Cache write tests

These tests use the 32-bit cache to **write a constant value** many times to a bitmap. Essentially filling the screen.

There are two variants: 
  - writing one byte a time (the old way) 
  - writing four bytes at the same time (using the 32-bit cache)

Here are the PRG names and what their results look like:

| PRG  | Screenshot Emulator | Screenshot HW | What this tests |
| ------------- | ------------- | ------------- | ------------- |
| `SINGLE-WRITE.PRG`  | <img src='screenshots/SINGLE-WRITE.PRG.png' width='300'> | <img src='screenshots/SINGLE-WRITE-HW.PRG.png' width='300'>| B1 |
| `MULTI-WRITE.PRG`  | <img src='screenshots/MULTI-WRITE.PRG.png' width='300'> | <img src='screenshots/MULTI-WRITE-HW.PRG.png' width='300'>| C1 C3 |


## Cache read and write tests

These tests use the 32-bit cache to **read and write** (aka copy) many times from and to VRAM. Essentially copying a bitmap to the screen.

There are two variants: 
  - reading and writing one byte a time (the old way) 
  - reading one and writing four bytes at the same time (using the 32-bit cache)

Here are the PRG names and what their results look like:

| PRG  | Screenshot Emulator | Screenshot HW | What this tests |
| ------------- | ------------- | ------------- | ------------- |
| `SINGLE-READWRITE.PRG`  | <img src='screenshots/SINGLE-READWRITE.PRG.png' width='300'> | <img src='screenshots/SINGLE-READWRITE-HW.PRG.png' width='300'> | B1 B2 |
| `MULTI-READWRITE.PRG`  | <img src='screenshots/MULTI-READWRITE.PRG.png' width='300'> | <img src='screenshots/MULTI-READWRITE-HW.PRG.png' width='300'> | C2 C3 |


## Line draw tests

These tests use the line draw helper mode to draw diagonal lines.

This is done (when the line draw helper is used): 
  - Set the start address somewhere in a bitmap (of the screen)
  - Set the increment (per Bresenham's algo)
  - Write many bytes to ADDR1 until a border of the screen is reached
  - Iterate the above using different angles

These are the variants:
  - Drawing the old way (8bpp): without the use of the line draw helper
  - Drawing the new way (8bpp): with the use of the line draw helper
  - Drawing the new way (4bpp): with the use of the line draw helper

Here are the PRG names and what their results look like:

| PRG  | Screenshot Emulator | Screenshot HW | What this tests |
| ------------- | ------------- | ------------- | ------------- |
| `LINE_8BPP-NOFX.PRG`  | <img src='screenshots/LINE_8BPP-NOFX.PRG.png' width='300'> | <img src='screenshots/LINE_8BPP-NOFX-HW.PRG.png' width='300'> | B1 B3 |
| `LINE_8BPP-FX.PRG`  | <img src='screenshots/LINE_8BPP-FX.PRG.png' width='300'> | <img src='screenshots/LINE_8BPP-FX-HW.PRG.png' width='300'> | B3 L1 L2 L3.1 L4 |
| `LINE_4BPP-FX.PRG`  | <img src='screenshots/LINE_4BPP-FX.PRG.png' width='300'> | <img src='screenshots/LINE_4BPP-FX-HW.PRG.png' width='300'> | B3 L1 L2 L3.2 L4 O2 O3 |
 

## Affine helper tests

These tests use the affine helper mode to **rotate or shear** a bitmap. Any kind of affine transformation (like scaling and flipping) are actually possible this way.

This is what both variants do: 
  - Copying a tilemap and tiledata to VRAM, effectively containing the source image
  - Setting the initial X and Y cooridinate to a starting point in the (tiled) source image 
  - Setting the X/Y increment for step in the source miage
  - Drawing a line to the destination, by doing this for each pixel:
    - Read a source pixel (this automatically increments X and Y (in the source) to the next position)
    - Write a source pixel to the destination
  - Set the starting point the next line (for rotation this is slightly more work on the CPU side)
    
**TODO**: add 4bpp variant

Here are the PRG names and what their results look like:

| PRG  | Screenshot Emulator | Screenshot HW | What this tests |
| ------------- | ------------- | ------------- | ------------- |
| `AFF_SHEAR-CACHE.PRG`  | <img src='screenshots/AFF_SHEAR-CACHE.PRG.png' width='300'> | <img src='screenshots/AFF_SHEAR-CACHE-HW.PRG.png' width='300'> | A1 A2 A3 A4 A5.1 A6 A7 C2.1 C3 C5.1 |
| `AFF_SHEAR-NOCACHE.PRG`  | <img src='screenshots/AFF_SHEAR-NOCACHE.PRG.png' width='300'> | <img src='screenshots/AFF_SHEAR-NOCACHE-HW.PRG.png' width='300'> | A1 A2 A3 A4 A5.1 A6 A7 B1 B2 O1.1 |
| `AFF_ROTATION-CACHE.PRG`  | <img src='screenshots/AFF_ROTATION-CACHE.PRG.png' width='300'> | <img src='screenshots/AFF_ROTATION-CACHE-HW.PRG.png' width='300'> | A1 A2 A3 A4 A5.1 A6 A7 C2.1 C3 C5.1 |
| `AFF_ROTATION-NOCACHE.PRG`  | <img src='screenshots/AFF_ROTATION-NOCACHE.PRG.png' width='300'> | <img src='screenshots/AFF_ROTATION-NOCACHE-HW.PRG.png' width='300'> | A1 A2 A3 A4 A5.1 A6 A7 B1 B2 O1.1 |
| `AFF_FLAT_4BPP.PRG`  | <img src='screenshots/AFF_FLAT_4BPP.PRG.png' width='300'> | <img src='screenshots/AFF_FLAT_4BPP-HW.PRG.png' width='300'> | A1 A2 A3 A4 A5.2 A6 A7 C2.2 C3 |


## Polygon filler tests

These tests use the polygon filler mode to **draw many polygons** to a bitmap. Essentially filling a rectangle with triangles.

This is what the tests are doing: 
  - Doing all the work on the CPU side (the old way) 
    - Calculating the X1 and X2 coordinates for each line
    - Setting the VRAM addresses each line
  - Using as many FX features as possible (8bpp/4bpp/2bpp)
    - Using the 32-bit cache to write multiple pixels at once
    - Using nibble masking when writing the cache to VRAM (not all pixels will be written)
    - Using the polygon filler helper to setup the ADDR1 each line
    - Using the polygon filler fill-length codes as input to JUMP-tables (65C02 feature)

There are three sub-variants of the latter: 
  - 8bpp polygons
  - 4bpp polygons
  - 2bpp polygons (with dithering)
    
Here are the PRG names and what their results look like:

| PRG  | Screenshot Emulator | Screenshot HW | What this tests |
| ------------- | ------------- | ------------- | ------------- |
| `POLYFILL-NOFXPOLY.PRG`  | <img src='screenshots/POLYFILL-NOFXPOLY.PRG.png' width='300'> | <img src='screenshots/POLYFILL-NOFXPOLY-HW.PRG.png' width='300'> | B1 B3 |
| `POLYFILL-FXPOLY-SLP-JMP.PRG`  | <img src='screenshots/POLYFILL-FXPOLY-SLP-JMP.PRG.png' width='300'> | <img src='screenshots/POLYFILL-FXPOLY-SLP-JMP-HW.PRG.png' width='300'> | C1 C3 C4 P1 P2 P3.1 P4.1 P5 |
| `POLYFILL-FXPOLY-SLP-JMP-4BIT.PRG`  | <img src='screenshots/POLYFILL-FXPOLY-SLP-JMP-4BIT.PRG.png' width='300'> | <img src='screenshots/POLYFILL-FXPOLY-SLP-JMP-4BIT-HW.PRG.png' width='300'> | C1 C3 C4 P1 P2 P3.2 P4.2 P5 |
| `POLYFILL-FXPOLY-SLP-JMP-2BIT.PRG`  | <img src='screenshots/POLYFILL-FXPOLY-SLP-JMP-2BIT.PRG.png' width='300'> | <img src='screenshots/POLYFILL-FXPOLY-SLP-JMP-2BIT-HW.PRG.png' width='300'> | C1 C3 C4 C6 P1 P2 P3.2 P4.3 P5 P6 |


## Multiplier and accumulator tests

These tests 16x16bit signed multiplier and accumulator. It starts simple, but builds up to more complex examples.

Here are the calculation being performed in this test program:

```
C: $0002 (2) S: $F4C3 (-2877)

X1: $0003 (3) Y1: $0123 (291)
X2: $0007 (7) Y2: $FFF3 (-13)

X1, C = $00020003
X1 * C = $00000006 (2 * 3 = 6)
X2 * S = $FFFFB155 (7 * -2877 = -20139)
X1 * C + Y1 * S = $FFF339AF (3 * 2 + 291 * -2877 = -837201)
X2 * S - Y2 * C = $FFFFB16F ( (7 * -2877) - (-13 * 2) = -20113)
```

Here are the PRG names and what their results look like:

| PRG  | Screenshot Emulator | Screenshot HW | What this tests |
| ------------- | ------------- | ------------- | ------------- |
| `MULTACC.PRG`  | <img src='screenshots/MULTACC.PRG.png' width='300'>| <img src='screenshots/MULTACC-HW.PRG.png' width='300'> | C1 C3 M1 M2 M3 M4 M5 M6 M7 M8 M9 |



# Test results

Below is a complete list of the results of all the tests performed:


| Code | Description | Result Emulator | Result HW |
| ---- | ----------- | --------------- | --------- |
|  A1  | Setting the FX tilemap base address works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A2  | Setting the FX tiledata base address works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A3  | Setting the X/Y coordinate in a tilemap works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A4  | Setting the X/Y increment for a tilemap works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A5.1  | Reading bytes from the FX tilemap works (8bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A5.2  | Reading nibbles from the FX tilemap works (4bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A6  | Incrementing the X/Y coordinate after a read works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  A7  | Clipping a tilemap works (pixels form tile 0 are read) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  B1  | Writing to VRAM 1 byte at the time still works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  B2  | Reading from VRAM 1 byte at the time still works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  B3  | Setting of VRAM addresses still works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C1  | Filling the 32-bit cache directly works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C2.1  | Filling the 32-bit cache (1 byte at the time: 8bpp) by reading from VRAM works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C2.2  | Filling the 32-bit cache (1 nibble at the time: 4bpp) by reading from VRAM works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C3  | Writing the full 32-bit cache to VRAM works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C4  | Writing the nibble-masked 32-bit cache to VRAM works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C5.1  | Transparent writes work with 32-bit cache (8bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  C6  | One byte cache cycling works with 32-bit cache | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  L1  | Resetting the X coordinate (overflow bit) of line draw helper works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  L2  | Setting the X-increment of line draw helper works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  L3.1  | Writing a pixel (8bpp) works and increments the X-coordinate and also ADDR1  | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  L3.2  | Writing a pixel (4bpp) works and increments the X-coordinate and also ADDR1 (one *nibble*) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  L4  | When X-coordinate is overflown ADDR0-address increment is *also added* to ADDR1 | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M1  | Resetting the accumulator works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M2  | Multiplying two positive numbers works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M2  | Multiplying with negative numbers works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M4  | Multiplication result can be written to VRAM | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M5  | Multiplication result can be added to the accumulator | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M6  | Multiplication result can be subtracted to the accumulator | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M7  | A series of multiplications and accumulations can be achieved | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M8  | Reset of accumulation can be triggered by reading from FX_ACCUM_RESET register | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  M9  | Accumulation can be triggered by reading from FX_ACCUM register | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  O1.1  | Transparent writes work (8bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  O2  | Setting of the nibble address bit (4bpp) works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  O3  | Setting of the nibble decrement/increment bit (4bpp) works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P1  | Polygon filler incrementers (X1 and X2) work | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P2  | Polygon filler (sub)pixel positions (X1 and X2) work | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P3.1  | Polygon filler setting ADDR1 = ADDR0 + X1 works (8bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P3.2  | Polygon filler setting ADDR1 = ADDR0 + X1 / 2 works + nibble address bit (4bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P4.1  | Polygon filler reading fill length code works (8bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P4.2  | Polygon filler reading fill length code works (4bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P4.3  | Polygon filler reading fill length code works (2bpp) | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P5  | Polygon filler reset of (sub)pixel positions (X1 and X2) works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |
|  P6  | The special 'poke'-mode (2bpp) works | <p align="center"><img src='screenshots/ok.png' width='30'></p> | <p align="center"><img src='screenshots/ok.png' width='30'></p> |



