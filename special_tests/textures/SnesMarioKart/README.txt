- Get maps here:
    https://www.snesmaps.com/maps/SuperMarioKart/SuperMarioKartMapSelect.html

- Remove the top banner using some "crop png" tool:  https://www.iloveimg.com/crop-image/crop-png
   -> it is important the color depth (8bits) is preseverded! (so check it, by looking at the file properties -> Details tab)
- create a subfolder and cd to it
- Split the image into 8x8 tiles:
    pip install split-image (https://pypi.org/project/split-image/)
    PATH TO SPLIT IMAGE\split-image "PATH TO IMAGE FOLDER\YOUR IMAGE FILENAME" 128 128
- To check how manu are unique: (http://www.pc-tools.net/win32/md5sums/)
    PATH TO MD5SUMS\md5sums.exe *.png -e -b -n > md5hashes.txt
    Remove all filenames from txt file (regex "\n.+   " -> "\n")
    Then run this in Notepad++ : ^(.*?)$\s+?^(?=.*^\1$) -> ""

