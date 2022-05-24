
## To compile into a .rom file

Right now the hardware tester is best compiled with vasm6502 (oldstyle). This is how you can generate a .rom file:

  `vasm6502_oldstyle.exe -Fbin -dotdir x16_hardware_tester.s -o x16_hardware_tester.rom`

VASM manual: http://sun.hasenbraten.de/vasm/release/vasm_6.html

## To run using the X16 emulator

In order to run the hardware tester using the emulator you can set the rom-file like this:

  `x16emu.exe -rom "x16_hardware_tester.rom" -debug`

## To run using X16 hardware

The generated .rom file can be flashed to your ROM (SST39SF040) using your favorite flash programmer. It uses the full 512 KB in size.

## Screenshot

After you run the tester it will look similar to this:

![alt text](https://raw.githubusercontent.com/visual-trials/X16-Hardware-Tests/master/utils/screenshot.png)

