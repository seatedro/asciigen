# ascii from image

converts an image to ascii art

## installation

### pre-built binaries (SOMEONE PLEASE MAKE THIS WORK)

you can download the latest release from github: [here](https://github.com/seatedro/asciigen/releases/latest)

### build from source

`zig build -Drelease`

the above command builds an executable found at `./zig-out/bin`

if you want to just directly run the executable, run:

`zig build run -Drelease -- [options]`

see below for explanations for available options

## usage

run the program with the following options (the default zig install directory is `./zig-out/bin`):
   ```
   /path/to/asciigen [options]
   ```
1. options:
   - `-h, --help`: print the help message and exit
   - `-i, --input <file>`: specify the input image file path (local path/URL) (required)
   - `-o, --output <file>`: specify the output image file (optional, default: `<input>_ascii.jpg`)
   - `-c, --color`: use color ascii characters (optional)
   - `-n, --invert_color`: Inverts the color values (optional)
   - `-s, --scale <float>`: set the downscale or upscale factor (optional, default: 1)
   - `-e, --detect_edges`: enable edge detection (optional)
   - `    --sigma1 <float>`: set the sigma1 value for DoG filter (optional, default: 0.3)
   - `    --sigma2 <float>`: set the sigma2 value for DoG filter (optional, default: 1.0)
   - `-b, --brightness_boost <float>`: increase/decrease perceived brightness (optional, default: 1.0)
   
   advanced options (your image will break, probably, but you might get some cool results):
   - `    --full_characters`: Uses full spectrum of characters in image.
   - `    --ascii_chars <string>`: Use what characters you want to use in the image. (default: " .:-=+*%@#")
   - `    --disable_sort`: Prevents sorting of the ascii_chars by size.
   - `    --block_size <u8>`: Set the size of the blocks. (default: 8)
   - `    --threshold_disabled`: Disables the threshold.

   set a custom color value
   - `    --custom_color`: Enables custom color from the --r, --g, --b parameters
   - `    --r`: Sets the r color.
   - `    --g`: Sets the g color.
   - `    --b`: Sets the b color.

2. examples:

   basic usage:
   ```bash
   asciigen -i input.jpg -o output.png
   ```

   using color:
   ```bash
   asciigen -i input.png -o output.png -c
   ```

   with edge detection, color, and custom downscale: 
   ```bash
   asciigen -i input.jpeg -o output.png -s 4 -e -c
   ```

   with brightness boost and url input:
   ```bash
   # bonus (this is a sweet wallpaper)
   asciigen -i "https://w.wallhaven.cc/full/p9/wallhaven-p9gr2p.jpg" -o output.png -e -c-b 1.5
   ```

3. the program will generate an ascii art version of your input image and save it as a new image file.

output file needs to be a `.png` since i saw some weird issues with jpegs.

the zig version is the only one i'll be working on from here on. the c code was just to get me started until i figured out some issues with the build.zig

4. Using the long arguments on windows may or may not work. Please use the short arguments for now.
