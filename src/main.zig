const std = @import("std");
const builtin = @import("builtin");
const clap = @import("clap");
const mime = @import("mime.zig");
const term = @import("term.zig");
const FrameBuffer = @import("util.zig").FrameBuffer;
// const stb = @import("stb");
const stb = @cImport({
    @cInclude("stb_image.h");
    @cInclude("stb_image_write.h");
    @cInclude("stb_image_resize2.h");
});
const av = @cImport({
    @cInclude("libavformat/avformat.h");
    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavutil/avutil.h");
    @cInclude("libavutil/imgutils.h");
    @cInclude("libavutil/opt.h");
    @cInclude("libswscale/swscale.h");
    @cInclude("libswresample/swresample.h");
    @cInclude("libavutil/channel_layout.h");
    @cInclude("libavutil/samplefmt.h");
});

const default_characters = " .:-=+*%@#";
const full_characters = " .-:=+iltIcsv1x%7aejorzfnuCJT3*69LYpqy25SbdgFGOVXkPhmw48AQDEHKUZR@B#NW0M";

/// Author: Daniel Hepper <daniel@hepper.net>
/// URL: https://github.com/dhepper/font8x8
const font_bitmap: [128][8]u8 = .{
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0000 (null)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0001
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0002
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0003
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0004
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0005
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0006
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0007
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0008
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0009
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+000A
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+000B
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+000C
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+000D
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+000E
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+000F
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0010
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0011
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0012
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0013
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0014
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0015
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0016
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0017
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0018
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0019
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+001A
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+001B
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+001C
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+001D
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+001E
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+001F
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0020 (space)
    .{ 0x18, 0x3C, 0x3C, 0x18, 0x18, 0x00, 0x18, 0x00 }, // U+0021 (!)
    .{ 0x6C, 0x6C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0022 (")
    .{ 0x6C, 0x6C, 0xFE, 0x6C, 0xFE, 0x6C, 0x6C, 0x00 }, // U+0023 (#)
    .{ 0x30, 0x7C, 0xC0, 0x78, 0x0C, 0xF8, 0x30, 0x00 }, // U+0024 ($)
    .{ 0x00, 0xC6, 0xCC, 0x18, 0x30, 0x66, 0xC6, 0x00 }, // U+0025 (%)
    .{ 0x38, 0x6C, 0x38, 0x76, 0xDC, 0xCC, 0x76, 0x00 }, // U+0026 (&)
    .{ 0x60, 0x60, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0027 (')
    .{ 0x18, 0x30, 0x60, 0x60, 0x60, 0x30, 0x18, 0x00 }, // U+0028 (()
    .{ 0x60, 0x30, 0x18, 0x18, 0x18, 0x30, 0x60, 0x00 }, // U+0029 ())
    .{ 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00 }, // U+002A (*)
    .{ 0x00, 0x30, 0x30, 0xFC, 0x30, 0x30, 0x00, 0x00 }, // U+002B (+)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x60 }, // U+002C (,)
    .{ 0x00, 0x00, 0x00, 0xFC, 0x00, 0x00, 0x00, 0x00 }, // U+002D (-)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x00 }, // U+002E (.)
    .{ 0x06, 0x0C, 0x18, 0x30, 0x60, 0xC0, 0x80, 0x00 }, // U+002F (/)
    .{ 0x7C, 0xC6, 0xCE, 0xDE, 0xF6, 0xE6, 0x7C, 0x00 }, // U+0030 (0)
    .{ 0x30, 0x70, 0x30, 0x30, 0x30, 0x30, 0xFC, 0x00 }, // U+0031 (1)
    .{ 0x78, 0xCC, 0x0C, 0x38, 0x60, 0xCC, 0xFC, 0x00 }, // U+0032 (2)
    .{ 0x78, 0xCC, 0x0C, 0x38, 0x0C, 0xCC, 0x78, 0x00 }, // U+0033 (3)
    .{ 0x1C, 0x3C, 0x6C, 0xCC, 0xFE, 0x0C, 0x1E, 0x00 }, // U+0034 (4)
    .{ 0xFC, 0xC0, 0xF8, 0x0C, 0x0C, 0xCC, 0x78, 0x00 }, // U+0035 (5)
    .{ 0x38, 0x60, 0xC0, 0xF8, 0xCC, 0xCC, 0x78, 0x00 }, // U+0036 (6)
    .{ 0xFC, 0xCC, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00 }, // U+0037 (7)
    .{ 0x78, 0xCC, 0xCC, 0x78, 0xCC, 0xCC, 0x78, 0x00 }, // U+0038 (8)
    .{ 0x78, 0xCC, 0xCC, 0x7C, 0x0C, 0x18, 0x70, 0x00 }, // U+0039 (9)
    .{ 0x00, 0x30, 0x30, 0x00, 0x00, 0x30, 0x30, 0x00 }, // U+003A (:)
    .{ 0x00, 0x30, 0x30, 0x00, 0x00, 0x30, 0x30, 0x60 }, // U+003B (;)
    .{ 0x18, 0x30, 0x60, 0xC0, 0x60, 0x30, 0x18, 0x00 }, // U+003C (<)
    .{ 0x00, 0x00, 0xFC, 0x00, 0x00, 0xFC, 0x00, 0x00 }, // U+003D (=)
    .{ 0x60, 0x30, 0x18, 0x0C, 0x18, 0x30, 0x60, 0x00 }, // U+003E (>)
    .{ 0x78, 0xCC, 0x0C, 0x18, 0x30, 0x00, 0x30, 0x00 }, // U+003F (?)
    .{ 0x7C, 0xC6, 0xDE, 0xDE, 0xDE, 0xC0, 0x78, 0x00 }, // U+0040 (@)
    .{ 0x30, 0x78, 0xCC, 0xCC, 0xFC, 0xCC, 0xCC, 0x00 }, // U+0041 (A)
    .{ 0xFC, 0x66, 0x66, 0x7C, 0x66, 0x66, 0xFC, 0x00 }, // U+0042 (B)
    .{ 0x3C, 0x66, 0xC0, 0xC0, 0xC0, 0x66, 0x3C, 0x00 }, // U+0043 (C)
    .{ 0xF8, 0x6C, 0x66, 0x66, 0x66, 0x6C, 0xF8, 0x00 }, // U+0044 (D)
    .{ 0xFE, 0x62, 0x68, 0x78, 0x68, 0x62, 0xFE, 0x00 }, // U+0045 (E)
    .{ 0xFE, 0x62, 0x68, 0x78, 0x68, 0x60, 0xF0, 0x00 }, // U+0046 (F)
    .{ 0x3C, 0x66, 0xC0, 0xC0, 0xCE, 0x66, 0x3E, 0x00 }, // U+0047 (G)
    .{ 0xCC, 0xCC, 0xCC, 0xFC, 0xCC, 0xCC, 0xCC, 0x00 }, // U+0048 (H)
    .{ 0x78, 0x30, 0x30, 0x30, 0x30, 0x30, 0x78, 0x00 }, // U+0049 (I)
    .{ 0x1E, 0x0C, 0x0C, 0x0C, 0xCC, 0xCC, 0x78, 0x00 }, // U+004A (J)
    .{ 0xE6, 0x66, 0x6C, 0x78, 0x6C, 0x66, 0xE6, 0x00 }, // U+004B (K)
    .{ 0xF0, 0x60, 0x60, 0x60, 0x62, 0x66, 0xFE, 0x00 }, // U+004C (L)
    .{ 0xC6, 0xEE, 0xFE, 0xFE, 0xD6, 0xC6, 0xC6, 0x00 }, // U+004D (M)
    .{ 0xC6, 0xE6, 0xF6, 0xDE, 0xCE, 0xC6, 0xC6, 0x00 }, // U+004E (N)
    .{ 0x38, 0x6C, 0xC6, 0xC6, 0xC6, 0x6C, 0x38, 0x00 }, // U+004F (O)
    .{ 0xFC, 0x66, 0x66, 0x7C, 0x60, 0x60, 0xF0, 0x00 }, // U+0050 (P)
    .{ 0x78, 0xCC, 0xCC, 0xCC, 0xDC, 0x78, 0x1C, 0x00 }, // U+0051 (Q)
    .{ 0xFC, 0x66, 0x66, 0x7C, 0x6C, 0x66, 0xE6, 0x00 }, // U+0052 (R)
    .{ 0x78, 0xCC, 0xE0, 0x70, 0x1C, 0xCC, 0x78, 0x00 }, // U+0053 (S)
    .{ 0xFC, 0xB4, 0x30, 0x30, 0x30, 0x30, 0x78, 0x00 }, // U+0054 (T)
    .{ 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xFC, 0x00 }, // U+0055 (U)
    .{ 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0x78, 0x30, 0x00 }, // U+0056 (V)
    .{ 0xC6, 0xC6, 0xC6, 0xD6, 0xFE, 0xEE, 0xC6, 0x00 }, // U+0057 (W)
    .{ 0xC6, 0xC6, 0x6C, 0x38, 0x38, 0x6C, 0xC6, 0x00 }, // U+0058 (X)
    .{ 0xCC, 0xCC, 0xCC, 0x78, 0x30, 0x30, 0x78, 0x00 }, // U+0059 (Y)
    .{ 0xFE, 0xC6, 0x8C, 0x18, 0x32, 0x66, 0xFE, 0x00 }, // U+005A (Z)
    .{ 0x78, 0x60, 0x60, 0x60, 0x60, 0x60, 0x78, 0x00 }, // U+005B ([)
    .{ 0xC0, 0x60, 0x30, 0x18, 0x0C, 0x06, 0x02, 0x00 }, // U+005C (\)
    .{ 0x78, 0x18, 0x18, 0x18, 0x18, 0x18, 0x78, 0x00 }, // U+005D (])
    .{ 0x10, 0x38, 0x6C, 0xC6, 0x00, 0x00, 0x00, 0x00 }, // U+005E (^)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF }, // U+005F (_)
    .{ 0x30, 0x30, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0060 (`)
    .{ 0x00, 0x00, 0x78, 0x0C, 0x7C, 0xCC, 0x76, 0x00 }, // U+0061 (a)
    .{ 0xE0, 0x60, 0x60, 0x7C, 0x66, 0x66, 0xDC, 0x00 }, // U+0062 (b)
    .{ 0x00, 0x00, 0x78, 0xCC, 0xC0, 0xCC, 0x78, 0x00 }, // U+0063 (c)
    .{ 0x1C, 0x0C, 0x0C, 0x7C, 0xCC, 0xCC, 0x76, 0x00 }, // U+0064 (d)
    .{ 0x00, 0x00, 0x78, 0xCC, 0xFC, 0xC0, 0x78, 0x00 }, // U+0065 (e)
    .{ 0x38, 0x6C, 0x60, 0xF0, 0x60, 0x60, 0xF0, 0x00 }, // U+0066 (f)
    .{ 0x00, 0x00, 0x76, 0xCC, 0xCC, 0x7C, 0x0C, 0xF8 }, // U+0067 (g)
    .{ 0xE0, 0x60, 0x6C, 0x76, 0x66, 0x66, 0xE6, 0x00 }, // U+0068 (h)
    .{ 0x30, 0x00, 0x70, 0x30, 0x30, 0x30, 0x78, 0x00 }, // U+0069 (i)
    .{ 0x0C, 0x00, 0x0C, 0x0C, 0x0C, 0xCC, 0xCC, 0x78 }, // U+006A (j)
    .{ 0xE0, 0x60, 0x66, 0x6C, 0x78, 0x6C, 0xE6, 0x00 }, // U+006B (k)
    .{ 0x70, 0x30, 0x30, 0x30, 0x30, 0x30, 0x78, 0x00 }, // U+006C (l)
    .{ 0x00, 0x00, 0xCC, 0xFE, 0xFE, 0xD6, 0xC6, 0x00 }, // U+006D (m)
    .{ 0x00, 0x00, 0xF8, 0xCC, 0xCC, 0xCC, 0xCC, 0x00 }, // U+006E (n)
    .{ 0x00, 0x00, 0x78, 0xCC, 0xCC, 0xCC, 0x78, 0x00 }, // U+006F (o)
    .{ 0x00, 0x00, 0xDC, 0x66, 0x66, 0x7C, 0x60, 0xF0 }, // U+0070 (p)
    .{ 0x00, 0x00, 0x76, 0xCC, 0xCC, 0x7C, 0x0C, 0x1E }, // U+0071 (q)
    .{ 0x00, 0x00, 0xDC, 0x76, 0x66, 0x60, 0xF0, 0x00 }, // U+0072 (r)
    .{ 0x00, 0x00, 0x7C, 0xC0, 0x78, 0x0C, 0xF8, 0x00 }, // U+0073 (s)
    .{ 0x10, 0x30, 0x7C, 0x30, 0x30, 0x34, 0x18, 0x00 }, // U+0074 (t)
    .{ 0x00, 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0x76, 0x00 }, // U+0075 (u)
    .{ 0x00, 0x00, 0xCC, 0xCC, 0xCC, 0x78, 0x30, 0x00 }, // U+0076 (v)
    .{ 0x00, 0x00, 0xC6, 0xD6, 0xFE, 0xFE, 0x6C, 0x00 }, // U+0077 (w)
    .{ 0x00, 0x00, 0xC6, 0x6C, 0x38, 0x6C, 0xC6, 0x00 }, // U+0078 (x)
    .{ 0x00, 0x00, 0xCC, 0xCC, 0xCC, 0x7C, 0x0C, 0xF8 }, // U+0079 (y)
    .{ 0x00, 0x00, 0xFC, 0x98, 0x30, 0x64, 0xFC, 0x00 }, // U+007A (z)
    .{ 0x1C, 0x30, 0x30, 0xE0, 0x30, 0x30, 0x1C, 0x00 }, // U+007B ({)
    .{ 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00 }, // U+007C (|)
    .{ 0xE0, 0x30, 0x30, 0x1C, 0x30, 0x30, 0xE0, 0x00 }, // U+007D (})
    .{ 0x76, 0xDC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+007E (~)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+007F
};

const OutputType = enum {
    Stdout,
    Text,
    Image,
    Video,
};

const Args = struct {
    input: []const u8,
    output: ?[]const u8,
    color: bool,
    invert_color: bool,
    scale: f32,
    detect_edges: bool,
    sigma1: f32,
    sigma2: f32,
    brightness_boost: f32,
    full_characters: bool,
    ascii_chars: []const u8,
    disable_sort: bool,
    block_size: u8,
    threshold_disabled: bool,
    codec: ?[]const u8,
    keep_audio: bool,
    ffmpeg_options: std.StringHashMap([]const u8),
    stretched: bool,
    output_type: OutputType,
    frame_rate: ?f32,

    pub fn deinit(self: *Args) void {
        var it = self.ffmpeg_options.iterator();
        while (it.next()) |entry| {
            self.ffmpeg_options.allocator.free(entry.key_ptr.*);
            self.ffmpeg_options.allocator.free(entry.value_ptr.*);
        }
        self.ffmpeg_options.deinit();
    }
};

const Image = struct {
    data: [*]u8,
    width: usize,
    height: usize,
    channels: usize,
};

const Frame = struct {
    data: []u8,
    width: usize,
    height: usize,
    channels: usize,
};

const SobelFilter = struct {
    magnitude: []f32,
    direction: []f32,
};

fn parseArgs(allocator: std.mem.Allocator) !Args {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                     Print this help message and exit
        \\-i, --input <str>              Input media file (img, video)
        \\-o, --output <str>             Output file (img, video, txt)
        \\-c, --color                    Use color ASCII characters
        \\-n, --invert_color             Inverts the color values
        \\-s, --scale <f32>              Scale factor (default: 1.0)
        \\-e, --detect_edges             Detect edges
        \\    --sigma1 <f32>             Sigma 1 for DoG filter (default: 0.5)
        \\    --sigma2 <f32>             Sigma 2 for DoG filter (default: 1.0)
        \\-b, --brightness_boost <f32>   Brightness boost (default: 1.0)
        \\    --full_characters          Uses full spectrum of characters in image.
        \\    --ascii_chars <str>        Use what characters you want to use in the image. (default: " .:-=+*%#@")
        \\    --disable_sort             Prevents sorting of the ascii_chars by size.
        \\    --block_size <u8>          Set the size of the blocks. (default: 8)
        \\    --threshold_disabled       Disables the threshold.
        \\    --codec <str>              Encoder Codec like "libx264" or "hevc_videotoolbox" (optional)
        \\    --keep_audio               Keeps the audio if input is a video
        \\    --stretched                Resizes media to fit terminal window
        \\-f, --frame_rate <f32>         Target frame rate for video output (default: matches input fps)
        \\<str>...
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .allocator = allocator,
        .diagnostic = &diag,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        try clap.help(std.io.getStdOut().writer(), clap.Help, &params, .{});
        std.process.exit(0);
    }

    if (res.args.input == null) {
        std.debug.print("Error: input file must be specified.\n", .{});
        std.process.exit(1);
    }

    const output_type = if (res.args.output) |op| blk: {
        const ext = std.fs.path.extension(op);
        if (std.mem.eql(u8, ext, ".txt")) {
            break :blk OutputType.Text;
        } else if (isVideoFile(op)) {
            break :blk OutputType.Video;
        } else {
            break :blk OutputType.Image;
        }
    } else OutputType.Stdout;

    var ffmpeg_options = std.StringHashMap([]const u8).init(allocator);
    errdefer ffmpeg_options.deinit();
    var pos: usize = 0;
    while (pos < res.positionals.len) : (pos += 2) {
        if (output_type != OutputType.Video) {
            std.debug.print("Warning: You have passed options not meant for this input/output type, they will be ignored.\n", .{});
            break;
        }
        const positional = res.positionals[pos];
        if (std.mem.startsWith(u8, positional, "-")) {
            const key = positional[1..];
            const val = if (pos + 1 < res.positionals.len) res.positionals[pos + 1] else return error.ValueNotFound;
            try ffmpeg_options.put(key, val);
        }
    }

    return Args{
        .input = res.args.input.?,
        .output_type = output_type,
        .output = res.args.output,
        .color = res.args.color != 0,
        .invert_color = res.args.invert_color != 0,
        .scale = res.args.scale orelse 1.0,
        .detect_edges = res.args.detect_edges != 0,
        .sigma1 = res.args.sigma1 orelse 0.5,
        .sigma2 = res.args.sigma2 orelse 1.0,
        .brightness_boost = res.args.brightness_boost orelse 1.0,
        .full_characters = res.args.full_characters != 0,
        .ascii_chars = if (res.args.ascii_chars) |custom_chars| blk: {
            if (res.args.disable_sort != 0) {
                break :blk custom_chars;
            } else {
                if (sortCharsBySize(allocator, custom_chars)) |sorted_chars| {
                    break :blk sorted_chars;
                } else |_| {
                    break :blk default_characters;
                }
            }
        } else blk: {
            if (res.args.full_characters != 0) {
                break :blk full_characters;
            } else {
                break :blk default_characters;
            }
        },
        .disable_sort = res.args.disable_sort != 0,
        .block_size = res.args.block_size orelse 8,
        .threshold_disabled = res.args.threshold_disabled != 0,
        .codec = res.args.codec,
        .keep_audio = res.args.keep_audio != 0,
        .ffmpeg_options = ffmpeg_options,
        .frame_rate = res.args.frame_rate,
        .stretched = res.args.stretched != 0,
    };
}

fn sortCharsBySize(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    const CharInfo = struct {
        char: u8,
        size: usize,
    };

    var char_infos = std.ArrayList(CharInfo).init(allocator);
    defer char_infos.deinit();

    for (input) |char| {
        if (char >= 128) continue; // Skip non-ASCII characters

        const bitmap = font_bitmap[char];
        var size: usize = 0;

        for (bitmap) |row| {
            size += @popCount(row);
        }

        if (size == 0 and char != ' ') continue; // Skip zero-size characters except space

        try char_infos.append(.{ .char = char, .size = size });
    }

    // Sort characters by size
    std.mem.sort(CharInfo, char_infos.items, {}, struct {
        fn lessThan(_: void, a: CharInfo, b: CharInfo) bool {
            return a.size < b.size;
        }
    }.lessThan);

    // Create the sorted string
    var result = try allocator.alloc(u8, char_infos.items.len);
    for (char_infos.items, 0..) |char_info, i| {
        result[i] = char_info.char;
    }

    // Print the sorted string
    //std.debug.print("Sorted string: {s}\n", .{result});

    // Convert []u8 to []const u8 before returning
    return result[0..];
}

// -----------------------
// VIDEO PROCESSING FUNCTIONS
// -----------------------

fn isVideoFile(file_path: []const u8) bool {
    const extension = std.fs.path.extension(file_path);
    if (mime.extension_map.get(extension)) |mime_type| {
        return switch (mime_type) {
            .@"video/3gpp",
            .@"video/3gpp2",
            .@"video/mp2t",
            .@"video/mp4",
            .@"video/mpeg",
            .@"video/ogg",
            .@"video/quicktime",
            .@"video/webm",
            .@"video/x-msvideo",
            => true,
            else => false,
        };
    }
    return false;
}

fn openInputVideo(path: []const u8) !*av.AVFormatContext {
    var fmt_ctx: ?*av.AVFormatContext = null;
    if (av.avformat_open_input(
        &fmt_ctx,
        path.ptr,
        null,
        null,
    ) < 0) {
        return error.FailedToOpenInputVideo;
    }
    if (av.avformat_find_stream_info(fmt_ctx, null) < 0) {
        return error.FailedToFindStreamInfo;
    }
    return fmt_ctx.?;
}

const AVStream = struct {
    stream: *av.AVStream,
    index: c_int,
};
fn openVideoStream(fmt_ctx: *av.AVFormatContext) !AVStream {
    const index = av.av_find_best_stream(
        fmt_ctx,
        av.AVMEDIA_TYPE_VIDEO,
        -1,
        -1,
        null,
        0,
    );
    if (index < 0) {
        return error.VideoStreamNotFound;
    }

    return .{
        .stream = fmt_ctx.streams[@intCast(index)],
        .index = index,
    };
}

fn createDecoder(stream: *av.AVStream) !*av.AVCodecContext {
    const decoder = av.avcodec_find_decoder(
        stream.codecpar.*.codec_id,
    ) orelse {
        return error.DecoderNotFound;
    };
    const codex_ctx = av.avcodec_alloc_context3(decoder);
    if (codex_ctx == null) {
        return error.FailedToAllocCodecCtx;
    }
    if (av.avcodec_parameters_to_context(
        codex_ctx,
        stream.codecpar,
    ) < 0) {
        return error.FailedToSetCodecParams;
    }
    if (av.avcodec_open2(
        codex_ctx,
        decoder,
        null,
    ) < 0) {
        return error.FailedToOpenEncoder;
    }

    return codex_ctx;
}

fn setEncoderOption(enc_ctx: *av.AVCodecContext, key: []const u8, value: []const u8) bool {
    var opt: ?*const av.AVOption = null;

    // Try to find the option in AVCodecContext
    opt = av.av_opt_find(@ptrCast(enc_ctx), key.ptr, null, 0, 0);
    if (opt != null) {
        if (av.av_opt_set(enc_ctx, key.ptr, value.ptr, 0) >= 0) {
            return true;
        }
    }

    // If not found or setting failed, try in priv_data
    if (enc_ctx.*.priv_data != null) {
        opt = av.av_opt_find(enc_ctx.*.priv_data, key.ptr, null, 0, 0);
        if (opt != null) {
            if (av.av_opt_set(enc_ctx.*.priv_data, key.ptr, value.ptr, 0) >= 0) {
                return true;
            }
        }
    }

    return false;
}

fn createEncoder(codec_ctx: *av.AVCodecContext, stream: *av.AVStream, args: Args) !*av.AVCodecContext {
    const encoder = if (args.codec) |codec| av.avcodec_find_encoder_by_name(codec.ptr) else av.avcodec_find_encoder_by_name("h264_nvenc") orelse
        av.avcodec_find_encoder_by_name("hevc_amf") orelse
        av.avcodec_find_encoder_by_name("hevc_qsv") orelse
        av.avcodec_find_encoder_by_name("hevc_videotoolbox") orelse
        av.avcodec_find_encoder_by_name("libx265") orelse
        av.avcodec_find_encoder_by_name("h264_amf") orelse
        av.avcodec_find_encoder_by_name("h264_qsv") orelse
        av.avcodec_find_encoder_by_name("libx264") orelse
        return error.EncoderNotFound;

    const enc_ctx = av.avcodec_alloc_context3(encoder);
    if (enc_ctx == null) {
        return error.FailedToAllocCodecCtx;
    }

    // Setting up encoding context
    enc_ctx.*.width = codec_ctx.width;
    enc_ctx.*.height = codec_ctx.height;
    enc_ctx.*.pix_fmt = av.AV_PIX_FMT_YUV420P;
    // enc_ctx.*.pix_fmt = encoder.*.pix_fmts[0];
    enc_ctx.*.time_base = stream.time_base;
    enc_ctx.*.framerate = .{
        .num = codec_ctx.framerate.num,
        .den = 1,
    };
    enc_ctx.*.gop_size = 10;
    enc_ctx.*.max_b_frames = 1;
    enc_ctx.*.flags |= av.AV_CODEC_FLAG_GLOBAL_HEADER;

    // Ensure the stride is aligned to 32 bytes
    const stride = (enc_ctx.*.width + 31) & ~@as(c_int, 31);
    _ = av.av_opt_set(enc_ctx, "stride", stride, 0);

    var it = args.ffmpeg_options.iterator();
    while (it.next()) |entry| {
        const k = entry.key_ptr.*;
        const v = entry.value_ptr.*;
        if (!setEncoderOption(enc_ctx, k, v)) {
            std.debug.print("Warning: Failed to set FFmpeg option: {s}={s}\n", .{ k, v });
        }
    }

    if (av.avcodec_open2(enc_ctx, encoder, null) < 0) {
        return error.FailedToOpenEncoder;
    }

    return enc_ctx;
}

const OutputContext = struct {
    ctx: *av.AVFormatContext,
    video_stream: *av.AVStream,
    audio_stream: ?*av.AVStream,
};
fn createOutputCtx(output_path: []const u8, enc_ctx: *av.AVCodecContext, audio_stream: ?*av.AVStream) !OutputContext {
    var fmt_ctx: ?*av.AVFormatContext = null;
    if (av.avformat_alloc_output_context2(&fmt_ctx, null, null, output_path.ptr) < 0) {
        return error.FailedToCreateOutputCtx;
    }

    const video_stream = av.avformat_new_stream(fmt_ctx, null);
    if (video_stream == null) {
        return error.FailedToCreateNewStream;
    }

    if (av.avcodec_parameters_from_context(video_stream.*.codecpar, enc_ctx) < 0) {
        return error.FailedToSetCodecParams;
    }

    // Create audio stream
    var audio_out_stream: ?*av.AVStream = null;
    if (audio_stream) |as| {
        audio_out_stream = av.avformat_new_stream(fmt_ctx, null);
        if (audio_out_stream == null) {
            return error.FailedToCreateAudioStream;
        }

        if (av.avcodec_parameters_copy(audio_out_stream.?.*.codecpar, as.*.codecpar) < 0) {
            return error.FailedToCopyAudioCodecParams;
        }
    }

    if (av.avio_open(&fmt_ctx.?.pb, output_path.ptr, av.AVIO_FLAG_WRITE) < 0) {
        return error.FailedToOpenOutputFile;
    }

    if (av.avformat_write_header(fmt_ctx, null) < 0) {
        return error.FailedToWriteHeader;
    }

    return .{ .ctx = fmt_ctx.?, .video_stream = video_stream, .audio_stream = audio_out_stream };
}

fn openAudioStream(fmt_ctx: *av.AVFormatContext) !AVStream {
    const index = av.av_find_best_stream(
        fmt_ctx,
        av.AVMEDIA_TYPE_AUDIO,
        -1,
        -1,
        null,
        0,
    );
    if (index < 0) {
        return error.AudioStreamNotFound;
    }

    return .{
        .stream = fmt_ctx.streams[@intCast(index)],
        .index = index,
    };
}

fn processVideo(allocator: std.mem.Allocator, args: Args) !void {
    var input_ctx = try openInputVideo(args.input);
    defer av.avformat_close_input(@ptrCast(&input_ctx));

    const stream_info = try openVideoStream(input_ctx);
    var dec_ctx = try createDecoder(stream_info.stream);
    defer av.avcodec_free_context(@ptrCast(&dec_ctx));

    var enc_ctx = try createEncoder(dec_ctx, stream_info.stream, args);
    defer av.avcodec_free_context(@ptrCast(&enc_ctx));

    // Extract frame rate
    const input_frame_rate = @as(f64, @floatFromInt(stream_info.stream.*.r_frame_rate.num)) /
        @as(f64, @floatFromInt(stream_info.stream.*.r_frame_rate.den));
    const target_frame_rate = args.frame_rate orelse input_frame_rate;
    const frame_time_ns = @as(u64, @intFromFloat(1e9 / target_frame_rate));
    std.debug.print("Input FPS: {d}, Target FPS: {d}, FrameTime: {d}\n", .{ input_frame_rate, target_frame_rate, frame_time_ns });

    var audio_stream_info: ?AVStream = null;
    if (args.keep_audio) {
        audio_stream_info = openAudioStream(input_ctx) catch |err| blk: {
            if (err == error.AudioStreamNotFound) {
                std.debug.print("No audio stream found in input video. Continuing without audio.\n", .{});
                break :blk null;
            } else {
                return err;
            }
        };
    }

    var op: ?OutputContext = null;
    var t: term = undefined;
    var frames = std.ArrayList(Image).init(allocator);
    if (args.output) |output| {
        op = try createOutputCtx(output, enc_ctx, if (audio_stream_info) |asi| asi.stream else null);
        // Set up progress bar
    } else {
        t = try term.init(allocator, args.ascii_chars);
    }
    defer {
        if (op) |output| {
            _ = av.av_write_trailer(output.ctx);
            if ((output.ctx.oformat.*.flags & av.AVFMT_NOFILE) == 0) {
                _ = av.avio_closep(&output.ctx.pb);
            }
            av.avformat_free_context(output.ctx);
        } else {
            t.deinit();
        }
        for (frames.items) |f| {
            const img_len = f.height * f.width * f.channels;
            allocator.free(f.data[0..img_len]);
        }
        frames.deinit();
    }

    // Creates a FrameBuffer that holds enough frames for a 2 second buffer
    var frame_buf = FrameBuffer(Image).init(allocator, @as(usize, @intFromFloat(target_frame_rate * 2)));
    defer frame_buf.deinit();

    const producer_thread = try std.Thread.spawn(
        .{},
        producerTask,
        .{ allocator, &frame_buf, input_ctx, stream_info, audio_stream_info, dec_ctx, enc_ctx, op, t, args },
    );
    defer producer_thread.join();

    var processed_frames: usize = 0;
    const start_time = std.time.nanoTimestamp();
    var last_frame_time = std.time.nanoTimestamp();
    if (args.output_type != OutputType.Stdout) return;

    // Consume the frames and render if we are targeting stdout
    frame_buf.waitUntilReady();
    t.stats = .{
        .original_w = @intCast(dec_ctx.width),
        .original_h = @intCast(dec_ctx.height),
        .new_w = t.size.w,
        .new_h = t.size.h - 4,
    };
    try t.enableAsciiMode();
    defer t.disableAsciiMode() catch {};

    while (true) {
        const f = frame_buf.pop() orelse break;
        defer stb.stbi_image_free(f.data);

        const target_time: i128 = start_time + (@as(i128, processed_frames) * @as(i128, frame_time_ns));
        const curr_time = std.time.nanoTimestamp();
        const sleep_duration: i128 = target_time - curr_time;

        if (sleep_duration > 0) {
            std.time.sleep(@as(u64, @intCast(sleep_duration)));
        } else {
            // If we are lagging behind, we should probably log that we're not able to
            // match the target fps.
            // We will not sleep in this case.
        }

        const post_sleep_time = std.time.nanoTimestamp();
        const elapsed_seconds = @as(f32, @floatFromInt(post_sleep_time - start_time)) / 1e9;

        processed_frames += 1;
        t.stats.frame_count = processed_frames;
        t.stats.fps = @as(f32, @floatFromInt(processed_frames)) / elapsed_seconds;
        t.stats.frame_delay = @as(i64, @intCast(post_sleep_time - (start_time + ((processed_frames - 1) * frame_time_ns))));

        const img_len = f.height * f.width * f.channels;
        try t.renderAsciiArt(
            f.data[0..img_len],
            f.width,
            f.height,
            f.channels,
            args.color,
            args.invert_color,
        );
        last_frame_time = curr_time;
    }

    for (frames.items) |f| {
        stb.stbi_image_free(f.data);
    }

    const avg_time = t.stats.total_time.? / @as(u128, t.stats.frame_count.?);
    t.stats.avg_frame_time = avg_time;
    std.debug.print("Average time for loop: {d}ms\n", .{t.stats.avg_frame_time.? / 1_000_000});
    std.debug.print("Total Time rendering: {d}ms\n", .{@divFloor((std.time.nanoTimestamp() - start_time), 1_000_000)});
}

fn producerTask(
    allocator: std.mem.Allocator,
    frame_buf: *FrameBuffer(Image),
    input_ctx: *av.AVFormatContext,
    stream_info: AVStream,
    audio_stream_info: ?AVStream,
    dec_ctx: *av.AVCodecContext,
    enc_ctx: *av.AVCodecContext,
    op: ?OutputContext,
    t: term,
    args: Args,
) !void {
    // Get total frames
    var total_frames: usize = undefined;
    var progress: std.Progress.Node = undefined;
    var root_node: std.Progress.Node = undefined;
    var eta_node: std.Progress.Node = undefined;
    if (args.output_type == OutputType.Video) {
        total_frames = @intCast(getTotalFrames(input_ctx, stream_info));
        progress = std.Progress.start(.{});
        root_node = progress.start("Processing video", total_frames);
        eta_node = progress.start("(time elapsed (s)/time remaining(s))", 100);
    }

    var packet = av.av_packet_alloc();
    defer av.av_packet_free(&packet);

    var frame = av.av_frame_alloc();
    defer av.av_frame_free(&frame);

    var rgb_frame = av.av_frame_alloc();
    defer av.av_frame_free(&rgb_frame);

    const input_pix_fmt = dec_ctx.*.pix_fmt;
    std.debug.print("Input pixel format: {s}\n", .{av.av_get_pix_fmt_name(input_pix_fmt)});

    const output_pix_fmt = av.AV_PIX_FMT_RGB24;

    rgb_frame.*.format = output_pix_fmt;
    rgb_frame.*.width = @divFloor(dec_ctx.*.width, args.block_size) * args.block_size;
    rgb_frame.*.height = @divFloor(dec_ctx.*.height, args.block_size) * args.block_size;
    if (av.av_frame_get_buffer(rgb_frame, 0) < 0) {
        return error.FailedToAllocFrameBuf;
    }

    var yuv_frame = av.av_frame_alloc();
    defer av.av_frame_free(&yuv_frame);

    yuv_frame.*.format = av.AV_PIX_FMT_YUV420P;
    yuv_frame.*.width = enc_ctx.*.width;
    yuv_frame.*.height = enc_ctx.*.height;
    if (av.av_frame_get_buffer(yuv_frame, 0) < 0) {
        return error.FailedToAllocFrameBuf;
    }

    const sws_ctx = av.sws_getContext(
        dec_ctx.width,
        dec_ctx.height,
        input_pix_fmt,
        dec_ctx.width,
        dec_ctx.height,
        output_pix_fmt,
        av.SWS_BILINEAR,
        null,
        null,
        null,
    );
    defer av.sws_freeContext(sws_ctx);

    var term_ctx: ?*av.struct_SwsContext = undefined;
    var term_frame: *av.struct_AVFrame = undefined;
    if (op == null) {
        term_ctx = av.sws_getContext(
            dec_ctx.width,
            dec_ctx.height,
            output_pix_fmt,
            @intCast(t.size.w),
            @intCast(t.size.h),
            output_pix_fmt,
            av.SWS_BILINEAR,
            null,
            null,
            null,
        );
        term_frame = av.av_frame_alloc();
    }
    defer {
        if (op == null) {
            av.sws_freeContext(term_ctx.?);
            av.av_frame_free(&rgb_frame);
        }
    }

    // Set color space and range
    _ = av.sws_setColorspaceDetails(
        sws_ctx,
        av.sws_getCoefficients(av.SWS_CS_DEFAULT),
        0,
        av.sws_getCoefficients(av.SWS_CS_DEFAULT),
        0,
        0,
        (1 << 16) - 1,
        (1 << 16) - 1,
    );

    const out_sws_ctx = av.sws_getContext(
        rgb_frame.*.width,
        rgb_frame.*.height,
        @intCast(rgb_frame.*.format),
        yuv_frame.*.width,
        yuv_frame.*.height,
        @intCast(yuv_frame.*.format),
        av.SWS_BILINEAR,
        null,
        null,
        null,
    );
    defer av.sws_freeContext(out_sws_ctx);

    var frame_count: usize = 0;
    const start_time = std.time.milliTimestamp();
    var last_update_time = start_time;
    const update_interval: i64 = 1000; // Update every 1 second
    while (av.av_read_frame(input_ctx, packet) >= 0) {
        defer av.av_packet_unref(packet);

        if (packet.*.stream_index == stream_info.index) {
            if (av.avcodec_send_packet(dec_ctx, packet) < 0) {
                continue;
            }

            while (av.avcodec_receive_frame(dec_ctx, frame) >= 0) {
                _ = av.sws_scale(
                    sws_ctx,
                    &frame.*.data,
                    &frame.*.linesize,
                    0,
                    frame.*.height,
                    &rgb_frame.*.data,
                    &rgb_frame.*.linesize,
                );
                frame_count += 1;
                if (op) |output| {
                    try convertFrameToAscii(allocator, rgb_frame, args);
                    _ = av.sws_scale(
                        out_sws_ctx,
                        &rgb_frame.*.data,
                        &rgb_frame.*.linesize,
                        0,
                        rgb_frame.*.height,
                        &yuv_frame.*.data,
                        &yuv_frame.*.linesize,
                    );

                    yuv_frame.*.pts = frame.*.pts;

                    var enc_packet = av.av_packet_alloc();
                    defer av.av_packet_free(&enc_packet);

                    if (av.avcodec_send_frame(enc_ctx, yuv_frame) >= 0) {
                        while (av.avcodec_receive_packet(enc_ctx, enc_packet) >= 0) {
                            enc_packet.*.stream_index = 0;
                            enc_packet.*.pts = av.av_rescale_q(
                                enc_packet.*.pts,
                                enc_ctx.*.time_base,
                                output.video_stream.*.time_base,
                            );
                            enc_packet.*.dts = av.av_rescale_q(
                                enc_packet.*.dts,
                                enc_ctx.*.time_base,
                                output.video_stream.*.time_base,
                            );
                            enc_packet.*.duration = av.av_rescale_q(
                                enc_packet.*.duration,
                                enc_ctx.*.time_base,
                                output.video_stream.*.time_base,
                            );

                            _ = av.av_interleaved_write_frame(output.ctx, enc_packet);
                        }
                    }
                } else {
                    const frame_size = @as(usize, @intCast(rgb_frame.*.width)) * @as(usize, @intCast(rgb_frame.*.height)) * 3;
                    const frame_data = try allocator.alloc(u8, frame_size);
                    defer allocator.free(frame_data);
                    @memcpy(frame_data, rgb_frame.*.data[0][0..frame_size]);
                    const f = Image{
                        .data = frame_data.ptr,
                        .width = @intCast(rgb_frame.*.width),
                        .height = @intCast(rgb_frame.*.height),
                        .channels = 3,
                    };
                    const resized_img = try resizeImage(f, t.size.w, t.size.h - 4);
                    try frame_buf.push(resized_img);
                    if (frame_count == frame_buf.max_size) {
                        frame_buf.setReady();
                    }
                }
                if (args.output_type == OutputType.Video) {
                    root_node.completeOne();

                    const current_time = std.time.milliTimestamp();
                    if (current_time - last_update_time >= update_interval) {
                        const elapsed_time = @as(f64, @floatFromInt(current_time - start_time)) / 1000.0;
                        const frames_per_second = @as(f64, @floatFromInt(frame_count)) / elapsed_time;
                        const estimated_total_time = @as(f64, @floatFromInt(total_frames)) / frames_per_second;
                        const estimated_remaining_time = estimated_total_time - elapsed_time;

                        eta_node.setCompletedItems(@as(usize, (@intFromFloat(elapsed_time))));
                        eta_node.setEstimatedTotalItems(@intFromFloat(estimated_remaining_time));

                        last_update_time = current_time;
                    }
                }
            }
        } else if (args.keep_audio and audio_stream_info != null and packet.*.stream_index == audio_stream_info.?.index) {
            // Audio packet processing
            const output = op.?;
            packet.*.stream_index = output.audio_stream.?.index;
            packet.*.pts = av.av_rescale_q(packet.*.pts, audio_stream_info.?.stream.time_base, output.audio_stream.?.time_base);
            packet.*.dts = av.av_rescale_q(packet.*.dts, audio_stream_info.?.stream.time_base, output.audio_stream.?.time_base);
            packet.*.duration = av.av_rescale_q(packet.*.duration, audio_stream_info.?.stream.time_base, output.audio_stream.?.time_base);

            if (av.av_interleaved_write_frame(output.ctx, packet) < 0) {
                return error.FailedToWriteAudioPacket;
            }
        }
    }
}

fn convertFrameToAscii(allocator: std.mem.Allocator, frame: *av.AVFrame, args: Args) !void {
    const img = Image{
        .data = frame.data[0],
        .width = @intCast(frame.width),
        .height = @intCast(frame.height),
        .channels = 3,
    };

    const edge_result = try detectEdges(allocator, img, args);
    defer if (args.detect_edges) {
        allocator.free(edge_result.grayscale);
        allocator.free(edge_result.magnitude);
        allocator.free(edge_result.direction);
    };

    const ascii_img = try generateAsciiArt(allocator, img, edge_result, args);
    defer allocator.free(ascii_img);

    // Copy ascii art back to frame
    const out_w = (img.width / args.block_size) * args.block_size;
    const out_h = (img.height / args.block_size) * args.block_size;
    const frame_linesize = @as(usize, @intCast(frame.linesize[0]));

    for (0..out_h) |y| {
        const src_start = y * out_w * 3;
        const dst_start = y * frame_linesize;
        const row_size = @min(out_w * 3, frame_linesize);
        @memcpy(frame.data[0][dst_start..][0..row_size], ascii_img[src_start..][0..row_size]);
    }
}

fn getTotalFrames(fmt_ctx: *av.AVFormatContext, stream_info: AVStream) i64 {
    if (stream_info.stream.nb_frames > 0) {
        return stream_info.stream.nb_frames;
    }

    var total_frames: i64 = 0;
    var pkt: av.AVPacket = undefined;
    while (av.av_read_frame(fmt_ctx, &pkt) >= 0) {
        defer av.av_packet_unref(&pkt);
        if (pkt.stream_index == stream_info.index) {
            total_frames += 1;
        }
    }

    // Reset the file position indicator
    _ = av.avio_seek(fmt_ctx.*.pb, 0, av.SEEK_SET);
    _ = av.avformat_seek_file(
        fmt_ctx,
        stream_info.index,
        std.math.minInt(i64),
        0,
        std.math.maxInt(i64),
        0,
    );

    return total_frames;
}

// -----------------------
// IMAGE PROCESSING FUNCTIONS
// -----------------------

fn downloadImage(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);

    var buf: [4096]u8 = undefined;
    var req = try client.open(.GET, uri, .{ .server_header_buffer = &buf });
    defer req.deinit();

    // Sending HTTP req headers
    try req.send();
    try req.finish();

    // Wait for response
    try req.wait();

    if (req.response.status != .ok) {
        return error.HttpRequestFailed;
    }

    const content_len = req.response.content_length orelse return error.NoContentLength;
    const body = try allocator.alloc(u8, content_len);
    errdefer allocator.free(body);

    const bytes_read = try req.readAll(body);
    if (bytes_read != content_len) {
        return error.IncompleteRead;
    }

    return body;
}

/// Okay so this is an insane bug. If a user passes in a .png file as input,
/// it works fine most of the time. But SOMETIMES, for reasons unknown to me,
/// the ascii art conversion gets absolutely NUKED. I'm not sure what's going
/// but to fix it, I'm going to try to re-encode the image as a JPEG and then
/// load it again. This is a very hacky solution, but it works. If anyone has
/// any ideas on how to fix this, please let me know.
fn loadImage(allocator: std.mem.Allocator, path: []const u8) !Image {
    const is_url = std.mem.startsWith(u8, path, "http://") or std.mem.startsWith(u8, path, "https://");

    var image_data: []u8 = undefined;
    defer if (is_url) allocator.free(image_data);

    if (is_url) {
        image_data = try downloadImage(allocator, path);
    }

    var w: c_int = undefined;
    var h: c_int = undefined;
    var chan: c_int = undefined;
    const data = if (is_url)
        stb.stbi_load_from_memory(image_data.ptr, @intCast(image_data.len), &w, &h, &chan, 0)
    else
        stb.stbi_load(path.ptr, &w, &h, &chan, 0);

    if (@intFromPtr(data) == 0) {
        std.debug.print("Error loading image: {s}\n", .{path});
        return error.ImageLoadFailed;
    }

    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".png")) {
        defer stb.stbi_image_free(data);
        // Create a temporary file for the re-encoded image
        var tmp_path_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        const ts = std.time.timestamp();
        const tmp_path = try std.fmt.bufPrintZ(&tmp_path_buf, "asciigen-tmp-{d}.jpg", .{ts});

        // Re-encode the image as JPEG
        const write_result = stb.stbi_write_jpg(
            tmp_path.ptr,
            w,
            h,
            chan,
            data,
            100, // quality
        );
        if (write_result == 0) {
            return error.ImageReEncodeFailed;
        }

        // Load the re-encoded image
        const reencoded_data = stb.stbi_load(tmp_path.ptr, &w, &h, &chan, 0);
        if (@intFromPtr(reencoded_data) == 0) {
            std.debug.print("Error loading re-encoded image\n", .{});
            return error.ImageLoadFailed;
        }

        // Delete the temporary file
        std.fs.deleteFileAbsolute(tmp_path) catch |err| {
            std.debug.print("Warning: Failed to delete temporary file: {}\n", .{err});
        };

        return Image{
            .data = reencoded_data,
            .width = @intCast(w),
            .height = @intCast(h),
            .channels = @intCast(chan),
        };
    }

    return Image{
        .data = data,
        .width = @intCast(w),
        .height = @intCast(h),
        .channels = @intCast(chan),
    };
}

// -----------------------
// CORE ASCIIGEN FUNCTIONS
// -----------------------

fn rgbToGrayScale(allocator: std.mem.Allocator, img: Image) ![]u8 {
    const grayscale_img = try allocator.alloc(u8, img.width * img.height);
    for (0..img.height) |y| {
        for (0..img.width) |x| {
            const i = (y * img.width + x) * img.channels;
            const r = img.data[i];
            const g = img.data[i + 1];
            const b = img.data[i + 2];
            grayscale_img[y * img.width + x] = @intFromFloat((0.299 * @as(f32, @floatFromInt(r)) + 0.587 * @as(f32, @floatFromInt(g)) + 0.114 * @as(f32, @floatFromInt(b))));
        }
    }
    return grayscale_img;
}

fn gaussianKernel(allocator: std.mem.Allocator, sigma: f32) ![]f32 {
    const size: usize = @intFromFloat(6 * sigma);
    const kernel_size = if (size % 2 == 0) size + 1 else size;
    const half: f32 = @floatFromInt(kernel_size / 2);

    var kernel = try allocator.alloc(f32, kernel_size);
    var sum: f32 = 0;

    for (0..kernel_size) |i| {
        const x = @as(f32, @floatFromInt(i)) - half;
        kernel[i] = @exp(-(x * x) / (2 * sigma * sigma));
        sum += kernel[i];
    }

    // Normalize the kernel
    for (0..kernel_size) |i| {
        kernel[i] /= sum;
    }

    return kernel;
}

fn applyGaussianBlur(allocator: std.mem.Allocator, img: Image, sigma: f32) ![]u8 {
    const kernel = try gaussianKernel(allocator, sigma);
    defer allocator.free(kernel);

    var temp = try allocator.alloc(u8, img.width * img.height);
    defer allocator.free(temp);
    var res = try allocator.alloc(u8, img.width * img.height);

    // Horizontal pass
    for (0..img.height) |y| {
        for (0..img.width) |x| {
            var sum: f32 = 0;
            for (0..kernel.len) |i| {
                const ix: i32 = @as(i32, @intCast(x)) + @as(i32, @intCast(i)) - @as(i32, @intCast(kernel.len / 2));
                if (ix >= 0 and ix < img.width) {
                    sum += @as(f32, @floatFromInt(img.data[y * img.width + @as(usize, @intCast(ix))])) * kernel[i];
                }
            }
            temp[y * img.width + x] = @intFromFloat(sum);
        }
    }

    // Vertical pass
    for (0..img.height) |y| {
        for (0..img.width) |x| {
            var sum: f32 = 0;
            for (0..kernel.len) |i| {
                const iy: i32 = @as(i32, @intCast(y)) + @as(i32, @intCast(i)) - @as(i32, @intCast(kernel.len / 2));
                if (iy >= 0 and iy < img.height) {
                    sum += @as(f32, @floatFromInt(temp[@as(usize, @intCast(iy)) * img.width + x])) * kernel[i];
                }
            }
            res[y * img.width + x] = @intFromFloat(sum);
        }
    }

    return res;
}

fn differenceOfGaussians(allocator: std.mem.Allocator, img: Image, sigma1: f32, sigma2: f32) ![]u8 {
    const blur1 = try applyGaussianBlur(allocator, img, sigma1);
    defer allocator.free(blur1);
    const blur2 = try applyGaussianBlur(allocator, img, sigma2);
    defer allocator.free(blur2);

    var res = try allocator.alloc(u8, img.width * img.height);
    for (0..img.width * img.height) |i| {
        const diff = @as(i16, blur1[i]) - @as(i16, blur2[i]);
        res[i] = @as(u8, @intCast(std.math.clamp(diff + 128, 0, 255)));
    }

    return res;
}

fn applySobelFilter(allocator: std.mem.Allocator, img: Image) !SobelFilter {
    const Gx = [_][3]i32{ .{ -1, 0, 1 }, .{ -2, 0, 2 }, .{ -1, 0, 1 } };
    const Gy = [_][3]i32{ .{ -1, -2, -1 }, .{ 0, 0, 0 }, .{ 1, 2, 1 } };

    var mag = try allocator.alloc(f32, img.width * img.height);
    var dir = try allocator.alloc(f32, img.width * img.height);

    for (1..img.height - 1) |y| {
        for (1..img.width - 1) |x| {
            var gx: f32 = 0;
            var gy: f32 = 0;

            for (0..3) |i| {
                for (0..3) |j| {
                    const pixel = img.data[(y + i - 1) * img.width + (x + j - 1)];
                    gx += @as(f32, @floatFromInt(Gx[i][j])) * @as(f32, @floatFromInt(pixel));
                    gy += @as(f32, @floatFromInt(Gy[i][j])) * @as(f32, @floatFromInt(pixel));
                }
            }

            mag[y * img.width + x] = @sqrt(gx * gx + gy * gy);
            dir[y * img.width + x] = std.math.atan2(gy, gx); // The lord's function
        }
    }

    return SobelFilter{
        .magnitude = mag,
        .direction = dir,
    };
}

fn getEdgeChar(mag: f32, dir: f32, threshold_disabled: bool) ?u8 {
    const threshold: f32 = 50;
    if (mag < threshold and !threshold_disabled) {
        return null;
    }

    const angle = (dir + std.math.pi) * (@as(f32, 180) / std.math.pi);
    return switch (@as(u8, @intFromFloat(@mod(angle + 22.5, 180) / 45))) {
        0, 4 => '-',
        1, 5 => '\\',
        2, 6 => '|',
        3, 7 => '/',
        else => unreachable,
    };
}

fn convertToAscii(
    img: []u8,
    w: usize,
    h: usize,
    x: usize,
    y: usize,
    ascii_char: u8,
    color: [3]u8,
    block_size: u8,
    color_enabled: bool,
) void {
    if (ascii_char < 32 or ascii_char > 126) {
        // std.debug.print("Error: invalid ASCII character: {}\n", .{ascii_char});
        return;
    }

    const bitmap = &font_bitmap[ascii_char];
    const block_w = @min(block_size, w - x);
    const block_h = @min(block_size, img.len / (w * 3) - y);

    // Define new colors
    const background_color = [3]u8{ 21, 9, 27 }; // Blackcurrant
    const text_color = [3]u8{ 211, 106, 111 }; // Indian Red

    var dy: usize = 0;
    while (dy < block_h) : (dy += 1) {
        var dx: usize = 0;
        while (dx < block_w) : (dx += 1) {
            const img_x = x + dx;
            const img_y = y + dy;

            if (img_x < w and img_y < h) {
                const idx = (img_y * w + img_x) * 3;
                const shift: u3 = @intCast(7 - dx);
                const bit: u8 = @as(u8, 1) << shift;
                if ((bitmap[dy] & bit) != 0) {
                    // Character pixel: use the original color
                    if (color_enabled) {
                        img[idx] = color[0];
                        img[idx + 1] = color[1];
                        img[idx + 2] = color[2];
                    } else {
                        img[idx] = text_color[0];
                        img[idx + 1] = text_color[1];
                        img[idx + 2] = text_color[2];
                    }
                } else {
                    // not a character pixel: set to black
                    if (color_enabled) {
                        img[idx] = 0;
                        img[idx + 1] = 0;
                        img[idx + 2] = 0;
                    } else {
                        img[idx] = background_color[0];
                        img[idx + 1] = background_color[1];
                        img[idx + 2] = background_color[2];
                    }
                }
            }
        }
    }
}

// -----------------------
// MAIN ENTRYPOINT AND HELPER FUNCTIONS
// -----------------------

pub fn main() !void {
    _ = av;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try parseArgs(allocator);
    defer args.deinit();

    if (isVideoFile(args.input)) {
        try processVideo(allocator, args);
    } else {
        try processImage(allocator, args);
    }
}

fn processImage(allocator: std.mem.Allocator, args: Args) !void {
    const original_img = try loadAndScaleImage(allocator, args);
    defer stb.stbi_image_free(original_img.data);

    const edge_result = try detectEdges(allocator, original_img, args);
    defer if (args.detect_edges) {
        allocator.free(edge_result.grayscale);
        allocator.free(edge_result.magnitude);
        allocator.free(edge_result.direction);
    };

    switch (args.output_type) {
        OutputType.Image => {
            const ascii_img = try generateAsciiArt(allocator, original_img, edge_result, args);
            defer allocator.free(ascii_img);
            try saveOutputImage(ascii_img, original_img, args);
        },
        OutputType.Stdout => {
            var t = try term.init(allocator, args.ascii_chars);
            defer t.deinit();

            var img: Image = undefined;
            if (args.stretched) {
                img = try resizeImage(original_img, t.size.w - 2, t.size.h - 4);
            } else {
                var new_w: usize = 0;
                var new_h: usize = 0;
                const rw = original_img.width / (t.size.w - 2);
                const rh = original_img.height / (t.size.h - 4);
                if (rw > rh) {
                    new_h = original_img.height / (rw * 2);
                    new_w = t.size.w - 2;
                } else {
                    new_h = (t.size.h - 4) / 2;
                    new_w = original_img.width / rh;
                }
                img = try resizeImage(original_img, new_w, new_h);
            }
            defer if (args.stretched) stb.stbi_image_free(img.data);

            t.stats = .{
                .original_w = original_img.width,
                .original_h = original_img.height,
                .new_w = img.width,
                .new_h = img.height,
            };

            const img_len = img.height * img.width * img.channels;

            try t.enableAsciiMode();
            try t.renderAsciiArt(
                img.data[0..img_len],
                img.width,
                img.height,
                img.channels,
                args.color,
                args.invert_color,
            );

            // Wait for user input before exiting
            _ = try t.stdin.readByte();
            try t.disableAsciiMode();
        },
        OutputType.Text => {
            // 1 : og
            // dr : grid
            const img = try resizeImage(original_img, original_img.width, original_img.height / 2);
            defer stb.free(img.data);
            const ascii_txt = try generateAsciiTxt(
                allocator,
                img,
                edge_result,
                args,
            );
            defer allocator.free(ascii_txt);
            try saveOutputTxt(ascii_txt, args);
        },
        else => {},
    }
}

fn generateAsciiTxt(
    allocator: std.mem.Allocator,
    img: Image,
    edge_result: EdgeData,
    args: Args,
) ![]u8 {
    const out_w = (img.width / args.block_size) * args.block_size;
    const out_h = (img.height / args.block_size) * args.block_size;

    var ascii_text = std.ArrayList(u8).init(allocator);
    defer ascii_text.deinit();

    var y: usize = 0;
    while (y < out_h) : (y += args.block_size) {
        var x: usize = 0;
        while (x < out_w) : (x += args.block_size) {
            const block_info = calculateBlockInfo(img, edge_result, x, y, out_w, out_h, args);
            const ascii_char = selectAsciiChar(block_info, args);
            try ascii_text.append(ascii_char);
        }
        try ascii_text.append('\n');
    }

    return ascii_text.toOwnedSlice();
}

fn saveOutputTxt(ascii_text: []const u8, args: Args) !void {
    const file = try std.fs.cwd().createFile(args.output.?, .{});
    defer file.close();

    try file.writeAll(ascii_text);
}

fn loadAndScaleImage(allocator: std.mem.Allocator, args: Args) !Image {
    const original_img = loadImage(allocator, args.input) catch |err| {
        std.debug.print("Error loading image: {}\n", .{err});
        return err;
    };

    if (args.scale != 1.0 and args.scale > 0.0) {
        return scaleImage(original_img, args.scale);
    } else {
        return original_img;
    }
}

fn scaleImage(img: Image, scale: f32) !Image {
    const img_w = @as(usize, @intFromFloat(@round(@as(f32, @floatFromInt(img.width)) / scale)));
    const img_h = @as(usize, @intFromFloat(@round(@as(f32, @floatFromInt(img.height)) / scale)));

    const scaled_img = stb.stbir_resize_uint8_linear(
        img.data,
        @intCast(img.width),
        @intCast(img.height),
        0,
        0,
        @intCast(img_w),
        @intCast(img_h),
        0,
        @intCast(img.channels),
    );
    if (scaled_img == null) {
        std.debug.print("Error downscaling image\n", .{});
        return error.ImageScaleFailed;
    }

    return Image{
        .data = scaled_img,
        .width = img_w,
        .height = img_h,
        .channels = img.channels,
    };
}

fn resizeImage(
    img: Image,
    new_width: usize,
    new_height: usize,
) !Image {
    const resized_data = stb.stbir_resize_uint8_linear(
        img.data,
        @intCast(img.width),
        @intCast(img.height),
        0,
        0,
        @intCast(new_width),
        @intCast(new_height),
        0,
        @intCast(img.channels),
    );

    if (resized_data == null) {
        return error.ImageResizeFailed;
    }

    return Image{
        .data = resized_data,
        .width = new_width,
        .height = new_height,
        .channels = img.channels,
    };
}

const EdgeData = struct {
    grayscale: []u8,
    magnitude: []f32,
    direction: []f32,
};
fn detectEdges(allocator: std.mem.Allocator, img: Image, args: Args) !EdgeData {
    if (!args.detect_edges) {
        return .{ .grayscale = &[_]u8{}, .magnitude = &[_]f32{}, .direction = &[_]f32{} };
    }

    const grayscale_img = try rgbToGrayScale(allocator, img);
    const dog_img = try differenceOfGaussians(allocator, .{
        .data = grayscale_img.ptr,
        .width = img.width,
        .height = img.height,
        .channels = img.channels,
    }, args.sigma1, args.sigma2);
    defer allocator.free(dog_img);

    const edge_result = try applySobelFilter(allocator, .{
        .data = dog_img.ptr,
        .width = img.width,
        .height = img.height,
        .channels = 1,
    });

    return .{ .grayscale = grayscale_img, .magnitude = edge_result.magnitude, .direction = edge_result.direction };
}

fn generateAsciiArt(
    allocator: std.mem.Allocator,
    img: Image,
    edge_result: EdgeData,
    args: Args,
) ![]u8 {
    const out_w = (img.width / args.block_size) * args.block_size;
    const out_h = (img.height / args.block_size) * args.block_size;

    const ascii_img = try allocator.alloc(u8, out_w * out_h * 3);
    @memset(ascii_img, 0);

    var y: usize = 0;
    while (y < out_h) : (y += args.block_size) {
        var x: usize = 0;
        while (x < out_w) : (x += args.block_size) {
            const block_info = calculateBlockInfo(img, edge_result, x, y, out_w, out_h, args);
            const ascii_char = selectAsciiChar(block_info, args);
            const avg_color = calculateAverageColor(block_info, args);

            convertToAscii(ascii_img, out_w, out_h, x, y, ascii_char, avg_color, args.block_size, args.color);
        }
    }

    return ascii_img;
}

const BlockInfo = struct {
    sum_brightness: u64,
    sum_color: [3]u64,
    pixel_count: u64,
    sum_mag: f32,
    sum_dir: f32,
};
fn calculateBlockInfo(img: Image, edge_result: EdgeData, x: usize, y: usize, out_w: usize, out_h: usize, args: Args) BlockInfo {
    var info = BlockInfo{ .sum_brightness = 0, .sum_color = .{ 0, 0, 0 }, .pixel_count = 0, .sum_mag = 0, .sum_dir = 0 };

    const block_w = @min(args.block_size, out_w - x);
    const block_h = @min(args.block_size, out_h - y);

    for (0..block_h) |dy| {
        for (0..block_w) |dx| {
            const ix = x + dx;
            const iy = y + dy;
            if (ix >= img.width or iy >= img.height) {
                continue;
            }
            const pixel_index = (iy * img.width + ix) * img.channels;
            if (pixel_index + 2 >= img.width * img.height * img.channels) {
                continue;
            }
            const r = img.data[pixel_index];
            const g = img.data[pixel_index + 1];
            const b = img.data[pixel_index + 2];
            const gray: u64 = @intFromFloat(@as(f32, @floatFromInt(r)) * 0.3 + @as(f32, @floatFromInt(g)) * 0.59 + @as(f32, @floatFromInt(b)) * 0.11);
            info.sum_brightness += gray;
            if (args.color) {
                info.sum_color[0] += r;
                info.sum_color[1] += g;
                info.sum_color[2] += b;
            }
            if (args.detect_edges) {
                const edge_index = iy * img.width + ix;
                info.sum_mag += edge_result.magnitude[edge_index];
                info.sum_dir += edge_result.direction[edge_index];
            }
            info.pixel_count += 1;
        }
    }

    return info;
}

fn selectAsciiChar(block_info: BlockInfo, args: Args) u8 {
    const avg_brightness: usize = @intCast(block_info.sum_brightness / block_info.pixel_count);
    const boosted_brightness: usize = @intFromFloat(@as(f32, @floatFromInt(avg_brightness)) * args.brightness_boost);
    const clamped_brightness = std.math.clamp(boosted_brightness, 0, 255);

    if (args.detect_edges) {
        const avg_mag: f32 = block_info.sum_mag / @as(f32, @floatFromInt(block_info.pixel_count));
        const avg_dir: f32 = block_info.sum_dir / @as(f32, @floatFromInt(block_info.pixel_count));
        if (getEdgeChar(avg_mag, avg_dir, args.threshold_disabled)) |ec| {
            return ec;
        }
    }

    return if (clamped_brightness == 0) ' ' else args.ascii_chars[(clamped_brightness * args.ascii_chars.len) / 256];
}

fn calculateAverageColor(block_info: BlockInfo, args: Args) [3]u8 {
    if (args.color) {
        var color = [3]u8{
            @intCast(block_info.sum_color[0] / block_info.pixel_count),
            @intCast(block_info.sum_color[1] / block_info.pixel_count),
            @intCast(block_info.sum_color[2] / block_info.pixel_count),
        };

        if (args.invert_color) {
            color[0] = 255 - color[0];
            color[1] = 255 - color[1];
            color[2] = 255 - color[2];
        }

        return color;
    } else {
        return .{ 255, 255, 255 };
    }
}

fn saveOutputImage(ascii_img: []u8, img: Image, args: Args) !void {
    const out_w = (img.width / args.block_size) * args.block_size;
    const out_h = (img.height / args.block_size) * args.block_size;

    const save_result = stb.stbi_write_png(
        @ptrCast(args.output.?.ptr),
        @intCast(out_w),
        @intCast(out_h),
        @intCast(img.channels),
        @ptrCast(ascii_img.ptr),
        @intCast(out_w * 3),
    );
    if (save_result == 0) {
        std.debug.print("Error writing output image\n", .{});
        return error.ImageWriteFailed;
    }
}

test "test_ascii_generation" {
    _ = av;
    const allocator = std.testing.allocator;

    // Create a temporary file path
    var tmp_path_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    try std.fs.cwd().makePath("test_output");
    const tmp_path = try std.fmt.bufPrintZ(
        &tmp_path_buf,
        "test_output/test_ascii_output.png",
        .{},
    );

    // Set up test arguments
    const test_args = Args{
        .input = "test_img.png",
        .output = tmp_path,
        .color = false,
        .invert_color = false,
        .scale = 1.0,
        .detect_edges = false,
        .sigma1 = 0.5,
        .sigma2 = 1.0,
        .brightness_boost = 1.0,
        .full_characters = false,
        .ascii_chars = null, //uses default (" .:-=+*%@#")
        .disable_sort = false,
        .block_size = 8,
        .threshold_disabled = false,
    };

    // Run the main function with test arguments
    try processImage(allocator, test_args);

    // Check if the output file exists
    const file = try std.fs.openFileAbsolute(tmp_path, .{});
    defer file.close();

    // Delete the temporary file
    // try std.fs.deleteFileAbsolute(tmp_path);

    // Try to open the file again, which should fail
    // const result = std.fs.openFileAbsolute(tmp_path, .{});
    // try std.testing.expectError(error.FileNotFound, result);
}
