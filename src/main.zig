const std = @import("std");
const builtin = @import("builtin");
const clap = @import("clap");
const core = @import("libglyph");
const image = @import("libglyphimg");
const video = @import("libglyphav");
const term = @import("libglyphterm");
const bitmap = core.bitmap;

const default_block = " .:coPO?@█";
const default_ascii = " .:-=+*%@#";
const full_characters = " .-:=+iltIcsv1x%7aejorzfnuCJT3*69LYpqy25SbdgFGOVXkPhmw48AQDEHKUZR@B#NW0M";

fn parseArgs(allocator: std.mem.Allocator) !core.CoreParams {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                     Print this help message and exit
        \\-i, --input <str>              Input media file (img, video)
        \\-o, --output <str>             Output file (img, video, txt)
        \\-c, --color                    Use color ASCII characters
        \\-n, --invert_color             Inverts the color values
        \\-a, --auto_adjust              Auto adjusts the brightness and contrast of input media
        \\-s, --scale <f32>              Scale factor (default: 1.0)
        \\    --symbols <str>            Character set to use: "ascii" or "block" (default: ascii)
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
            break :blk core.OutputType.Text;
        } else if (video.isVideoFile(op)) {
            break :blk core.OutputType.Video;
        } else {
            break :blk core.OutputType.Image;
        }
    } else core.OutputType.Stdout;

    var ffmpeg_options = std.StringHashMap([]const u8).init(allocator);
    errdefer ffmpeg_options.deinit();
    var pos: usize = 0;
    while (pos < res.positionals.len) : (pos += 2) {
        if (output_type != core.OutputType.Video) {
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

    const ascii_chars = blk: {
        if (res.args.ascii_chars) |custom_chars| {
            if (res.args.disable_sort != 0) {
                break :blk custom_chars;
            } else {
                break :blk sortCharsBySize(allocator, custom_chars) catch getDefaultChars(res.args.symbols);
            }
        } else if (res.args.full_characters != 0) {
            break :blk full_characters;
        } else {
            break :blk getDefaultChars(res.args.symbols);
        }
    };

    const ascii_info = try core.initAsciiChars(allocator, ascii_chars);

    return core.CoreParams{
        .input = res.args.input.?,
        .output_type = output_type,
        .output = res.args.output,
        .color = res.args.color != 0,
        .invert_color = res.args.invert_color != 0,
        .auto_adjust = res.args.auto_adjust != 0,
        .scale = res.args.scale orelse 1.0,
        .detect_edges = res.args.detect_edges != 0,
        .sigma1 = res.args.sigma1 orelse 0.5,
        .sigma2 = res.args.sigma2 orelse 1.0,
        .brightness_boost = res.args.brightness_boost orelse 1.0,
        .ascii_chars = ascii_chars,
        .ascii_info = ascii_info,
        .block_size = res.args.block_size orelse 8,
        .threshold_disabled = res.args.threshold_disabled != 0,
        .codec = res.args.codec,
        .keep_audio = res.args.keep_audio != 0,
        .ffmpeg_options = ffmpeg_options,
        .frame_rate = res.args.frame_rate,
        .stretched = res.args.stretched != 0,
    };
}

fn getDefaultChars(symbols: ?[]const u8) []const u8 {
    const symbol_type = if (symbols) |s|
        if (std.mem.eql(u8, s, "ascii")) core.SymbolType.Ascii else core.SymbolType.Block
    else
        core.SymbolType.Ascii;
    return switch (symbol_type) {
        .Ascii => default_ascii,
        .Block => default_block,
    };
}

fn sortCharsBySize(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    const CharInfo = struct {
        char: []const u8,
        size: usize,
    };

    var char_infos = std.ArrayList(CharInfo).init(allocator);
    defer char_infos.deinit();

    var it = std.unicode.Utf8Iterator{ .bytes = input, .i = 0 };
    while (it.nextCodepoint()) |codepoint| {
        const len = std.unicode.utf8CodepointSequenceLength(codepoint) catch continue;
        const char_start = it.i - len;
        const char = input[char_start..it.i];

        const bm = bitmap.getCharSet(char) catch continue;
        var size: usize = 0;

        for (bm) |row| {
            size += @popCount(row);
        }

        if (size == 0 and !std.mem.eql(u8, char, " ")) continue; // Skip zero-size characters except space

        try char_infos.append(.{ .char = char, .size = size });
    }

    // Sort characters by size
    std.mem.sort(CharInfo, char_infos.items, {}, struct {
        fn lessThan(_: void, a: CharInfo, b: CharInfo) bool {
            return a.size < b.size;
        }
    }.lessThan);

    // Create the sorted string
    var result = std.ArrayList(u8).init(allocator);
    for (char_infos.items) |char_info| {
        try result.appendSlice(char_info.char);
    }

    return result.toOwnedSlice();
}

// -----------------------
// MAIN ENTRYPOINT AND HELPER FUNCTIONS
// -----------------------

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try parseArgs(allocator);
    defer args.deinit();
    defer allocator.free(args.ascii_info);

    if (video.isVideoFile(args.input)) {
        try video.processVideo(allocator, args);
    } else {
        try image.processImage(allocator, args);
    }
}

test "test_ascii_generation" {
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
    const test_args = core.CoreParams{
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
    try image.processImage(allocator, test_args);

    // Check if the output file exists
    const file = try std.fs.openFileAbsolute(tmp_path, .{});
    defer file.close();

    // Delete the temporary file
    // try std.fs.deleteFileAbsolute(tmp_path);

    // Try to open the file again, which should fail
    // const result = std.fs.openFileAbsolute(tmp_path, .{});
    // try std.testing.expectError(error.FileNotFound, result);
}
