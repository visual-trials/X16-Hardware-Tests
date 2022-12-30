## Introduction

The [X16 Commander](https://www.commanderx16.com/forum/index.php?/home/) is a modern retro computer that is currently in (hardware) development. This new hardware requires testing. This repository aims to supply a tool for testing X16 (compatible) hardware. It comes in the form of asm-source that can compiled into a ROM image. That image can be flashed onto the EEPROM of the X16 hardware and will run immediatly after power on.

The tester currently consists of the following tests:

  * Initialization of VERA VGA output as first sign of life (rom-only mode)
  * Setup of a tiled screen and upload of petscii character set to VRAM (rom-only mode)
  * Testing of zero page and stack RAM (rom-only mode)
  * Testing of Fixed RAM
  * Testing of Banked RAM
  * Testing of Banked ROM
  * Testing of VERA
  * Testing of VIAs

The above tests are all in a state of Work-In-Progress and are destined to changed, extended and improved.

Note: 'rom-only mode' means that no stack, zero page or any other RAM is used.

## To compile into a .rom file

Right now the hardware tester is best compiled with vasm6502 (oldstyle). This is how you can generate a .rom file:

  `vasm6502_oldstyle.exe -Fbin -dotdir -wdc02 x16_hardware_tester.s -o x16_hardware_tester.rom`

VASM manual: http://sun.hasenbraten.de/vasm/release/vasm_6.html

## To run using the X16 emulator

In order to run the hardware tester using the emulator you can set the rom-file like this:

  `x16emu.exe -rom "x16_hardware_tester.rom" -debug`
  
NOTE: to get the latest build of the X16 emulator, go to https://github.com/commanderx16/x16-emulator/actions/workflows/build.yml
      there you can find the binaries of the latest build of the emulator

## To run using X16 hardware

The generated .rom file can be flashed to your ROM (SST39SF040) using your favorite flash programmer. It uses the full 512 KB in size.

## Screenshot

After you run the tester it will look similar to this:

![alt text](https://raw.githubusercontent.com/visual-trials/X16-Hardware-Tests/master/utils/screenshot.png)

