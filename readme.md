# ascii from image

converts an image to ascii art

## usage

### pre-built binaries

you can download the latest release from github: [here](https://github.com/seatedro/asciigen/releases/latest)

you can also install it with homebrew:

```bash
brew tap seatedro/asciigen
brew install asciigen
```

### build from source

`zig build -Drelease run -- -i path/to/input.jpeg -o path/to/output.png`

output file needs to be a `.png` since i saw some weird issues with jpegs.

the zig version is the only one i'll be working on from here on. the c code was just to get me started until i figured out some issues with the build.zig
