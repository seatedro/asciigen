const std = @import("std");
const clap = @import("clap");
// const stb = @import("stb");
const stb = @cImport({
    @cInclude("stb_image.h");
    @cInclude("stb_image_write.h");
    @cInclude("stb_image_resize2.h");
});

// VARS
const ASCII_CHARS = "@%#*+=-:. ";
const CHAR_SIZE = 8;
const THRESHOLD = 50;

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
    .{ 0x36, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0022 (")
    .{ 0x36, 0x36, 0x7F, 0x36, 0x7F, 0x36, 0x36, 0x00 }, // U+0023 (#)
    .{ 0x0C, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x0C, 0x00 }, // U+0024 ($)
    .{ 0x00, 0x63, 0x33, 0x18, 0x0C, 0x66, 0x63, 0x00 }, // U+0025 (%)
    .{ 0x1C, 0x36, 0x1C, 0x6E, 0x3B, 0x33, 0x6E, 0x00 }, // U+0026 (&)
    .{ 0x06, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0027 (')
    .{ 0x18, 0x0C, 0x06, 0x06, 0x06, 0x0C, 0x18, 0x00 }, // U+0028 (()
    .{ 0x06, 0x0C, 0x18, 0x18, 0x18, 0x0C, 0x06, 0x00 }, // U+0029 ())
    .{ 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00 }, // U+002A (*)
    .{ 0x00, 0x0C, 0x0C, 0x3F, 0x0C, 0x0C, 0x00, 0x00 }, // U+002B (+)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x06 }, // U+002C (,)
    .{ 0x00, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x00 }, // U+002D (-)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x00 }, // U+002E (.)
    .{ 0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x01, 0x00 }, // U+002F (/)
    .{ 0x3E, 0x63, 0x73, 0x7B, 0x6F, 0x67, 0x3E, 0x00 }, // U+0030 (0)
    .{ 0x0C, 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x3F, 0x00 }, // U+0031 (1)
    .{ 0x1E, 0x33, 0x30, 0x1C, 0x06, 0x33, 0x3F, 0x00 }, // U+0032 (2)
    .{ 0x1E, 0x33, 0x30, 0x1C, 0x30, 0x33, 0x1E, 0x00 }, // U+0033 (3)
    .{ 0x38, 0x3C, 0x36, 0x33, 0x7F, 0x30, 0x78, 0x00 }, // U+0034 (4)
    .{ 0x3F, 0x03, 0x1F, 0x30, 0x30, 0x33, 0x1E, 0x00 }, // U+0035 (5)
    .{ 0x1C, 0x06, 0x03, 0x1F, 0x33, 0x33, 0x1E, 0x00 }, // U+0036 (6)
    .{ 0x3F, 0x33, 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x00 }, // U+0037 (7)
    .{ 0x1E, 0x33, 0x33, 0x1E, 0x33, 0x33, 0x1E, 0x00 }, // U+0038 (8)
    .{ 0x1E, 0x33, 0x33, 0x3E, 0x30, 0x18, 0x0E, 0x00 }, // U+0039 (9)
    .{ 0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x00 }, // U+003A (:)
    .{ 0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x06 }, // U+003B (;)
    .{ 0x18, 0x0C, 0x06, 0x03, 0x06, 0x0C, 0x18, 0x00 }, // U+003C (<)
    .{ 0x00, 0x00, 0x3F, 0x00, 0x00, 0x3F, 0x00, 0x00 }, // U+003D (=)
    .{ 0x06, 0x0C, 0x18, 0x30, 0x18, 0x0C, 0x06, 0x00 }, // U+003E (>)
    .{ 0x1E, 0x33, 0x30, 0x18, 0x0C, 0x00, 0x0C, 0x00 }, // U+003F (?)
    .{ 0x3E, 0x63, 0x7B, 0x7B, 0x7B, 0x03, 0x1E, 0x00 }, // U+0040 (@)
    .{ 0x0C, 0x1E, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x00 }, // U+0041 (A)
    .{ 0x3F, 0x66, 0x66, 0x3E, 0x66, 0x66, 0x3F, 0x00 }, // U+0042 (B)
    .{ 0x3C, 0x66, 0x03, 0x03, 0x03, 0x66, 0x3C, 0x00 }, // U+0043 (C)
    .{ 0x1F, 0x36, 0x66, 0x66, 0x66, 0x36, 0x1F, 0x00 }, // U+0044 (D)
    .{ 0x7F, 0x46, 0x16, 0x1E, 0x16, 0x46, 0x7F, 0x00 }, // U+0045 (E)
    .{ 0x7F, 0x46, 0x16, 0x1E, 0x16, 0x06, 0x0F, 0x00 }, // U+0046 (F)
    .{ 0x3C, 0x66, 0x03, 0x03, 0x73, 0x66, 0x7C, 0x00 }, // U+0047 (G)
    .{ 0x33, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x33, 0x00 }, // U+0048 (H)
    .{ 0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 }, // U+0049 (I)
    .{ 0x78, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E, 0x00 }, // U+004A (J)
    .{ 0x67, 0x66, 0x36, 0x1E, 0x36, 0x66, 0x67, 0x00 }, // U+004B (K)
    .{ 0x0F, 0x06, 0x06, 0x06, 0x46, 0x66, 0x7F, 0x00 }, // U+004C (L)
    .{ 0x63, 0x77, 0x7F, 0x7F, 0x6B, 0x63, 0x63, 0x00 }, // U+004D (M)
    .{ 0x63, 0x67, 0x6F, 0x7B, 0x73, 0x63, 0x63, 0x00 }, // U+004E (N)
    .{ 0x1C, 0x36, 0x63, 0x63, 0x63, 0x36, 0x1C, 0x00 }, // U+004F (O)
    .{ 0x3F, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x0F, 0x00 }, // U+0050 (P)
    .{ 0x1E, 0x33, 0x33, 0x33, 0x3B, 0x1E, 0x38, 0x00 }, // U+0051 (Q)
    .{ 0x3F, 0x66, 0x66, 0x3E, 0x36, 0x66, 0x67, 0x00 }, // U+0052 (R)
    .{ 0x1E, 0x33, 0x07, 0x0E, 0x38, 0x33, 0x1E, 0x00 }, // U+0053 (S)
    .{ 0x3F, 0x2D, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 }, // U+0054 (T)
    .{ 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x3F, 0x00 }, // U+0055 (U)
    .{ 0x33, 0x33, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00 }, // U+0056 (V)
    .{ 0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00 }, // U+0057 (W)
    .{ 0x63, 0x63, 0x36, 0x1C, 0x1C, 0x36, 0x63, 0x00 }, // U+0058 (X)
    .{ 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x0C, 0x1E, 0x00 }, // U+0059 (Y)
    .{ 0x7F, 0x63, 0x31, 0x18, 0x4C, 0x66, 0x7F, 0x00 }, // U+005A (Z)
    .{ 0x1E, 0x06, 0x06, 0x06, 0x06, 0x06, 0x1E, 0x00 }, // U+005B ([)
    .{ 0x03, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x40, 0x00 }, // U+005C (\)
    .{ 0x1E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1E, 0x00 }, // U+005D (])
    .{ 0x08, 0x1C, 0x36, 0x63, 0x00, 0x00, 0x00, 0x00 }, // U+005E (^)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF }, // U+005F (_)
    .{ 0x0C, 0x0C, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+0060 (`)
    .{ 0x00, 0x00, 0x1E, 0x30, 0x3E, 0x33, 0x6E, 0x00 }, // U+0061 (a)
    .{ 0x07, 0x06, 0x06, 0x3E, 0x66, 0x66, 0x3B, 0x00 }, // U+0062 (b)
    .{ 0x00, 0x00, 0x1E, 0x33, 0x03, 0x33, 0x1E, 0x00 }, // U+0063 (c)
    .{ 0x38, 0x30, 0x30, 0x3e, 0x33, 0x33, 0x6E, 0x00 }, // U+0064 (d)
    .{ 0x00, 0x00, 0x1E, 0x33, 0x3f, 0x03, 0x1E, 0x00 }, // U+0065 (e)
    .{ 0x1C, 0x36, 0x06, 0x0f, 0x06, 0x06, 0x0F, 0x00 }, // U+0066 (f)
    .{ 0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x1F }, // U+0067 (g)
    .{ 0x07, 0x06, 0x36, 0x6E, 0x66, 0x66, 0x67, 0x00 }, // U+0068 (h)
    .{ 0x0C, 0x00, 0x0E, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 }, // U+0069 (i)
    .{ 0x30, 0x00, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E }, // U+006A (j)
    .{ 0x07, 0x06, 0x66, 0x36, 0x1E, 0x36, 0x67, 0x00 }, // U+006B (k)
    .{ 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 }, // U+006C (l)
    .{ 0x00, 0x00, 0x33, 0x7F, 0x7F, 0x6B, 0x63, 0x00 }, // U+006D (m)
    .{ 0x00, 0x00, 0x1F, 0x33, 0x33, 0x33, 0x33, 0x00 }, // U+006E (n)
    .{ 0x00, 0x00, 0x1E, 0x33, 0x33, 0x33, 0x1E, 0x00 }, // U+006F (o)
    .{ 0x00, 0x00, 0x3B, 0x66, 0x66, 0x3E, 0x06, 0x0F }, // U+0070 (p)
    .{ 0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x78 }, // U+0071 (q)
    .{ 0x00, 0x00, 0x3B, 0x6E, 0x66, 0x06, 0x0F, 0x00 }, // U+0072 (r)
    .{ 0x00, 0x00, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x00 }, // U+0073 (s)
    .{ 0x08, 0x0C, 0x3E, 0x0C, 0x0C, 0x2C, 0x18, 0x00 }, // U+0074 (t)
    .{ 0x00, 0x00, 0x33, 0x33, 0x33, 0x33, 0x6E, 0x00 }, // U+0075 (u)
    .{ 0x00, 0x00, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00 }, // U+0076 (v)
    .{ 0x00, 0x00, 0x63, 0x6B, 0x7F, 0x7F, 0x36, 0x00 }, // U+0077 (w)
    .{ 0x00, 0x00, 0x63, 0x36, 0x1C, 0x36, 0x63, 0x00 }, // U+0078 (x)
    .{ 0x00, 0x00, 0x33, 0x33, 0x33, 0x3E, 0x30, 0x1F }, // U+0079 (y)
    .{ 0x00, 0x00, 0x3F, 0x19, 0x0C, 0x26, 0x3F, 0x00 }, // U+007A (z)
    .{ 0x38, 0x0C, 0x0C, 0x07, 0x0C, 0x0C, 0x38, 0x00 }, // U+007B ({)
    .{ 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00 }, // U+007C (|)
    .{ 0x07, 0x0C, 0x0C, 0x38, 0x0C, 0x0C, 0x07, 0x00 }, // U+007D (})
    .{ 0x6E, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+007E (~)
    .{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, // U+007F
};

const Args = struct {
    input: []const u8,
    output: []const u8,
    color: bool,
    scale: u8,
    detect_edges: bool,
    sigma1: f32,
    sigma2: f32,
};

const Image = struct {
    data: [*]u8,
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
        \\-h, --help            Print this help message and exit
        \\-i, --input <str>     Input image file
        \\-o, --output <str>    Output image file
        \\-c, --color           Use color ASCII characters
        \\-s, --scale <u8>      Scale factor (default: 8)
        \\-e, --detect_edges    Detect edges
        \\    --sigma1 <f32>   Sigma 1 for DoG filter (default: 0.5)
        \\    --sigma2 <f32>   Sigma 2 for DoG filter (default: 1.0)
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

    return Args{
        .input = res.args.input.?,
        .output = res.args.output orelse blk: {
            var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
            const current_dir = try std.fs.cwd().realpath(".", &buf);
            const input_path = std.fs.path.basename(res.args.input.?);
            const output_filename = std.fmt.allocPrint(std.heap.page_allocator, "{s}_ascii.jpg", .{input_path}) catch unreachable;
            break :blk std.fs.path.join(allocator, &.{ current_dir, output_filename }) catch unreachable;
        },
        .color = res.args.color != 0,
        .scale = res.args.scale orelse 8,
        .detect_edges = res.args.detect_edges != 0,
        .sigma1 = res.args.sigma1 orelse 0.5,
        .sigma2 = res.args.sigma2 orelse 1.0,
    };
}

fn loadImage(path: []const u8) !Image {
    var w: c_int = undefined;
    var h: c_int = undefined;
    var chan: c_int = undefined;
    const data = stb.stbi_load(path.ptr, &w, &h, &chan, 0);
    if (@intFromPtr(data) == 0) {
        std.debug.print("Error loading image: {s}\n", .{path});
        return error.ImageLoadFailed;
    }

    return Image{
        .data = data,
        .width = @intCast(w),
        .height = @intCast(h),
        .channels = @intCast(chan),
    };
}

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

fn getEdgeChar(mag: f32, dir: f32) ?u8 {
    if (mag < THRESHOLD) {
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
    brightness: usize,
) void {
    if (ascii_char < 32 or ascii_char > 126) {
        // std.debug.print("Error: invalid ASCII character: {}\n", .{ascii_char});
        return;
    }

    const bitmap = &font_bitmap[ascii_char];
    const block_w = @min(CHAR_SIZE, w - x);
    const block_h = @min(CHAR_SIZE, img.len / (w * 3) - y);
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
                    img[idx] = color[0];
                    img[idx + 1] = color[1];
                    img[idx + 2] = color[2];
                } else {
                    // Background pixel: adjust based on brightness
                    if (brightness > 192) { // For very bright colors
                        img[idx] = @max(0, color[0] - 64);
                        img[idx + 1] = @max(0, color[1] - 64);
                        img[idx + 2] = @max(0, color[2] - 64);
                    } else if (brightness > 64) { // For mid-range colors
                        img[idx] = color[0] / 2;
                        img[idx + 1] = color[1] / 2;
                        img[idx + 2] = color[2] / 2;
                    } else { // For dark colors
                        img[idx] = @min(255, color[0] * 2);
                        img[idx + 1] = @min(255, color[1] * 2);
                        img[idx + 2] = @min(255, color[2] * 2);
                    }
                }
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try parseArgs(allocator);

    const original_img = loadImage(args.input) catch |err| {
        std.debug.print("Error loading image: {}\n", .{err});
        return err;
    };
    defer stb.stbi_image_free(original_img.data);

    var img: Image = undefined;
    if (args.scale != 1) {
        const img_w = original_img.width / args.scale;
        const img_h = original_img.height / args.scale;

        const downscaled_img = stb.stbir_resize_uint8_linear(
            original_img.data,
            @intCast(original_img.width),
            @intCast(original_img.height),
            0,
            0,
            @intCast(img_w),
            @intCast(img_h),
            0,
            @intCast(original_img.channels),
        );
        if (downscaled_img == null) {
            std.debug.print("Error downscaling image\n", .{});
            return error.ImageDownscaleFailed;
        }

        // const upscaled_img = stb.stbir_resize_uint8_linear(
        //     downscaled_img,
        //     @intCast(img_w),
        //     @intCast(img_h),
        //     0,
        //     0,
        //     @intCast(img_w * args.scale),
        //     @intCast(img_h * args.scale),
        //     0,
        //     @intCast(original_img.channels),
        // );
        // if (upscaled_img == null) {
        //     std.debug.print("Error upscaling image\n", .{});
        //     return error.ImageUpscaleFailed;
        // }
        // defer stb.stbi_image_free(upscaled_img);

        // img = Image{
        //     .data = upscaled_img,
        //     .width = img_w * args.scale,
        //     .height = img_h * args.scale,
        //     .channels = original_img.channels,
        // };

        img = Image{
            .data = downscaled_img,
            .width = img_w,
            .height = img_h,
            .channels = original_img.channels,
        };
    } else {
        img = original_img;
    }
    defer if (args.scale != 1) stb.stbi_image_free(img.data);

    var grayscale_img: []u8 = undefined;
    var edge_result: SobelFilter = undefined;
    defer {
        if (args.detect_edges) {
            allocator.free(grayscale_img);
            allocator.free(edge_result.magnitude);
            allocator.free(edge_result.direction);
        }
    }

    if (args.detect_edges) {
        grayscale_img = try rgbToGrayScale(allocator, img);
        const dog_img = try differenceOfGaussians(allocator, .{ .data = grayscale_img.ptr, .width = img.width, .height = img.height, .channels = img.channels }, args.sigma1, args.sigma2);
        defer allocator.free(dog_img);
        edge_result = try applySobelFilter(allocator, .{
            .data = dog_img.ptr,
            .width = img.width,
            .height = img.height,
            .channels = 1,
        });
    }

    // Output image dimensions (multiples of 8 for ASCII blocks)
    const out_w = (img.width / CHAR_SIZE) * CHAR_SIZE;
    const out_h = (img.height / CHAR_SIZE) * CHAR_SIZE;

    // Create output buffer for the ASCII art image
    const ascii_img = try allocator.alloc(u8, out_w * out_h * 3);
    defer allocator.free(ascii_img);

    @memset(ascii_img, 0);

    // Process each 8x8 block
    var y: usize = 0;
    while (y < out_h) : (y += CHAR_SIZE) {
        var x: usize = 0;
        while (x < out_w) : (x += CHAR_SIZE) {
            var sum_brightness: u64 = 0;
            var sum_color: [3]u64 = .{ 0, 0, 0 };
            var pixel_count: u64 = 0;
            var sum_mag: f32 = 0;
            var sum_dir: f32 = 0;

            // Calculate average brightness in the block
            // (upto 8x8, or less for edge blocks)
            const block_w = @min(CHAR_SIZE, out_w - x);
            const block_h = @min(CHAR_SIZE, out_h - y);

            for (0..block_h) |dy| {
                for (0..block_w) |dx| {
                    const ix = x + dx;
                    const iy = y + dy;
                    // Add boundary check
                    if (ix >= img.width or iy >= img.height) {
                        continue; // Skip this pixel if it's outside the image
                    }
                    const pixel_index = (iy * img.width + ix) * img.channels;
                    // Add another boundary check
                    if (pixel_index + 2 >= img.width * img.height * img.channels) {
                        continue; // Skip this pixel if it would cause out-of-bounds access
                    }
                    const r = img.data[pixel_index];
                    const g = img.data[pixel_index + 1];
                    const b = img.data[pixel_index + 2];
                    const gray: u64 = @intFromFloat(@as(f32, @floatFromInt(r)) * 0.3 + @as(f32, @floatFromInt(g)) * 0.59 + @as(f32, @floatFromInt(b)) * 0.11);
                    sum_brightness += gray;
                    if (args.color) {
                        sum_color[0] += r;
                        sum_color[1] += g;
                        sum_color[2] += b;
                    }
                    if (args.detect_edges) {
                        const edge_index = iy * img.width + ix;
                        sum_mag += edge_result.magnitude[edge_index];
                        sum_dir += edge_result.direction[edge_index];
                    }
                    pixel_count += 1;
                }
            }

            // Map brightness to ASCII character
            const avg_brightness: usize = @intCast(sum_brightness / pixel_count);
            var ascii_char: u8 = undefined;
            if (args.detect_edges) {
                const avg_mag: f32 = sum_mag / @as(f32, @floatFromInt(pixel_count));
                const avg_dir: f32 = sum_dir / @as(f32, @floatFromInt(pixel_count));
                const edge_char = getEdgeChar(avg_mag, avg_dir);
                if (edge_char) |ec| {
                    ascii_char = ec;
                } else {
                    ascii_char = if (avg_brightness < 32) ' ' else ASCII_CHARS[(avg_brightness * ASCII_CHARS.len) / 256];
                }
            } else {
                ascii_char = if (avg_brightness < 32) ' ' else ASCII_CHARS[(avg_brightness * ASCII_CHARS.len) / 256];
            }

            // Calculate average color only if args.color is true
            var avg_color: [3]u8 = undefined;
            if (args.color) {
                avg_color = .{
                    @intCast(sum_color[0] / pixel_count),
                    @intCast(sum_color[1] / pixel_count),
                    @intCast(sum_color[2] / pixel_count),
                };
            } else {
                avg_color = .{ 255, 255, 255 }; // Default to white if color is not used
            }

            // Draw ASCII character in the output image
            convertToAscii(ascii_img, out_w, out_h, x, y, ascii_char, avg_color, avg_brightness);
        }
    }

    const save_result = stb.stbi_write_png(
        @ptrCast(args.output.ptr),
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

test "test_load_time" {
    const start_time = std.time.milliTimestamp();
    const img = loadImage("stb/x.jpeg") catch |err| {
        std.debug.print("Error loading image: {}\n", .{err});
        return err;
    };
    defer stb.stbi_image_free(img.data);
    const time_after_load = std.time.milliTimestamp();
    std.debug.print("Load time: {} ms\n", .{time_after_load - start_time});
}

test "test_load_downsampleby8_upsampletooriginal_write" {
    const start_time = std.time.milliTimestamp();
    const img = try loadImage("images/green_vagabond.jpg");
    defer stb.stbi_image_free(img.data);
    const time_after_load = std.time.milliTimestamp();

    // Downsample by 8
    const down_w = img.width / 8;
    const down_h = img.height / 8;
    const downsampled = stb.stbir_resize_uint8_linear(
        img.data,
        @intCast(img.width),
        @intCast(img.height),
        0,
        0,
        @intCast(down_w),
        @intCast(down_h),
        0,
        @intCast(img.channels),
    );
    defer stb.stbi_image_free(downsampled);
    const time_after_downsample = std.time.milliTimestamp();

    // Upscale back to original size
    const upscaled = stb.stbir_resize_uint8_linear(
        downsampled,
        @intCast(down_w),
        @intCast(down_h),
        0,
        0,
        @intCast(img.width),
        @intCast(img.height),
        0,
        @intCast(img.channels),
    );
    defer stb.stbi_image_free(upscaled);
    const time_after_upscale = std.time.milliTimestamp();

    const result = stb.stbi_write_png("images/green_vagabond_downup.png", @intCast(img.width), @intCast(img.height), @intCast(img.channels), upscaled, @intCast(img.width * img.channels));
    const time_after_write = std.time.milliTimestamp();

    if (result != 0) {
        std.debug.print("Load time: {} ms\n", .{time_after_load - start_time});
        std.debug.print("Downsample time: {} ms\n", .{time_after_downsample - time_after_load});
        std.debug.print("Upscale time: {} ms\n", .{time_after_upscale - time_after_downsample});
        std.debug.print("Write time: {} ms\n", .{time_after_write - time_after_upscale});
        std.debug.print("Total time: {} ms\n", .{time_after_write - start_time});
    } else {
        std.debug.print("Error writing image\n", .{});
    }
}
test "test_difference_of_gaussians" {
    const allocator = std.testing.allocator;

    // Load the image
    const img = try loadImage("images/pink_vagabond.jpg");
    defer stb.stbi_image_free(img.data);

    // Convert to grayscale
    const grayscale_img = try rgbToGrayScale(allocator, img);
    defer allocator.free(grayscale_img);

    // Apply difference of gaussians
    const dog_img = try differenceOfGaussians(allocator, .{
        .data = grayscale_img.ptr,
        .width = img.width,
        .height = img.height,
        .channels = 1,
    }, 0.3, 1.0);
    defer allocator.free(dog_img);

    // Save the result
    const result = stb.stbi_write_png(
        "images/test_dog_result.png",
        @intCast(img.width),
        @intCast(img.height),
        1,
        dog_img.ptr,
        @intCast(img.width),
    );

    try std.testing.expect(result != 0);
}
