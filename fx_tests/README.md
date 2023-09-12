
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

## Test results

Below is a complete list of the results of all the tests performed.

| Code | Description | Result Emulator | Result HW |
| ---- | ----------- | --------------- | --------- |
|  A1  | Writing to VRAM 1 byte at the time still works | OK |  |
|  C1  | Filling the 32-bit cache directly works | OK |  |
|  C2  | Writing the 32-bit cache to VRAM (without multiplier or one-byte-cycling) works | OK |  |

## Cache write tests

These tests use the 32-bit cache to **write a constant value** many times to a bitmap. Essentially filling the screen.

There are two variants: 
  - writing one byte a time (the old way) 
  - writing four bytes at the same time (using the 32-bit cache)

Here are the PRG names and what their results should look like:

| PRG  | Screenshot | What this tests |
| ------------- | ------------- | ------------- |
| `SINGLE-WRITE.PRG`  | <img src='screenshots/SINGLE-WRITE.PRG.png' width='300'> | A1 |
| `MULTI-WRITE.PRG`  | <img src='screenshots/MULTI-WRITE.PRG.png' width='300'> | C1 C2 |


## Cache read and write tests

These tests use the 32-bit cache to **read and write** (aka copy) many times from and to VRAM. Essentially copying a bitmap to the screen.

There are two variants: 
  - reading and writing one byte a time (the old way) 
  - reading one and writing four bytes at the same time (using the 32-bit cache)

Here are the PRG names and what their results should look like:

| PRG  | Screenshot |
| ------------- | ------------- |
| `SINGLE-READWRITE.PRG`  | <img src='screenshots/SINGLE-READWRITE.PRG.png' width='300'> |
| `MULTI-READWRITE.PRG`  | <img src='screenshots/MULTI-READWRITE.PRG.png' width='300'> |


## Line draw tests




## Affine helper tests



## Polygon filler tests



## Multiplier and accumulator tests



## Tiled Perspective (integrated) tests 



## Polygon 3D Engine (integrated) tests




