# ascii from image

converts an image to ascii art

## installation

### pre-built binaries (SOMEONE PLEASE MAKE THIS WORK)

you can download the latest release from github: [here](https://github.com/seatedro/asciigen/releases/latest)

### build from source

`zig build -Drelease`


## usage

run the program with the following options (the default zig install directory is `./zig-out/bin`):
   ```
   /path/to/asciigen [options]
   ```
1. options:
   - `-h, --help`: print the help message and exit
   - `-i, --input <file>`: specify the input image file (required)
   - `-o, --output <file>`: specify the output image file (optional, default: `<input>_ascii.jpg`)
   - `-c, --color`: use color ascii characters (optional)
   - `-s, --scale <number>`: set the downscale factor (optional, default: 1)
   - `-e, --detect_edges`: enable edge detection (optional)
   - `--sigma1 <number>`: set the sigma1 value for DoG filter (optional, default: 0.3)
   - `--sigma2 <number>`: set the sigma2 value for DoG filter (optional, default: 1.0)

2. examples:

   basic usage:
   ```
   asciigen -i input.jpg
   ```

   using color and custom output:
   ```
   asciigen -i input.png -o output.png -c
   ```

   with edge detection and custom scale:
   ```
   asciigen -i input.jpg -s 4 -e
   ```

3. the program will generate an ascii art version of your input image and save it as a new image file.

output file needs to be a `.png` since i saw some weird issues with jpegs.

the zig version is the only one i'll be working on from here on. the c code was just to get me started until i figured out some issues with the build.zig
