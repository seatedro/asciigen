const std = @import("std");
pub const bitmap = @import("bitmap.zig");
const stb = @import("stb");

pub const OutputType = enum {
    Stdout,
    Text,
    Image,
    Video,
};

pub const SymbolType = enum {
    Ascii,
    Block,
};

pub const Image = struct {
    data: [*]u8,
    width: usize,
    height: usize,
    channels: usize,
};

const SobelFilter = struct {
    magnitude: []f32,
    direction: []f32,
};

pub const EdgeData = struct {
    grayscale: []u8,
    magnitude: []f32,
    direction: []f32,
};

pub const CoreParams = struct {
    input: []const u8,
    output: ?[]const u8,
    color: bool,
    invert_color: bool,
    scale: f32,
    brightness_boost: f32,
    auto_adjust: bool,
    ascii_chars: []const u8,
    ascii_info: []AsciiCharInfo,
    block_size: u8,
    stretched: bool,
    output_type: OutputType,
    detect_edges: bool,
    threshold_disabled: bool,
    sigma1: f32,
    sigma2: f32,
    frame_rate: ?f32,
    ffmpeg_options: std.StringHashMap([]const u8),
    keep_audio: bool,
    codec: ?[]const u8,

    pub fn deinit(self: *CoreParams) void {
        var it = self.ffmpeg_options.iterator();
        while (it.next()) |entry| {
            self.ffmpeg_options.allocator.free(entry.key_ptr.*);
            self.ffmpeg_options.allocator.free(entry.value_ptr.*);
        }
        self.ffmpeg_options.deinit();
    }
};

pub const AsciiCharInfo = struct { start: usize, len: u8 };

// -----------------------
// CORE ASCIIGEN FUNCTIONS
// -----------------------

pub fn initAsciiChars(allocator: std.mem.Allocator, ascii_chars: []const u8) ![]AsciiCharInfo {
    var char_info = std.ArrayList(AsciiCharInfo).init(allocator);
    defer char_info.deinit();

    var i: usize = 0;
    while (i < ascii_chars.len) {
        const len = try std.unicode.utf8ByteSequenceLength(ascii_chars[i]);
        try char_info.append(.{ .start = i, .len = @intCast(len) });
        i += len;
    }

    return char_info.toOwnedSlice();
}

pub fn selectAsciiChar(block_info: BlockInfo, args: CoreParams) []const u8 {
    const avg_brightness: usize = @intCast(block_info.sum_brightness / block_info.pixel_count);
    const boosted_brightness: usize = @intFromFloat(@as(f32, @floatFromInt(avg_brightness)) * args.brightness_boost);
    const clamped_brightness = std.math.clamp(boosted_brightness, 0, 255);

    if (args.detect_edges) {
        const avg_mag: f32 = block_info.sum_mag / @as(f32, @floatFromInt(block_info.pixel_count));
        const avg_dir: f32 = block_info.sum_dir / @as(f32, @floatFromInt(block_info.pixel_count));
        if (getEdgeChar(avg_mag, avg_dir, args.threshold_disabled)) |ec| {
            return &[_]u8{ec};
        }
    }

    if (clamped_brightness == 0) return " ";

    const char_index = (clamped_brightness * args.ascii_chars.len) / 256;
    const selected_char = args.ascii_info[@min(char_index, args.ascii_info.len - 1)];
    return args.ascii_chars[selected_char.start .. selected_char.start + selected_char.len];
}

pub fn rgbToGrayScale(allocator: std.mem.Allocator, img: Image) ![]u8 {
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

pub fn resizeImage(
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

pub fn autoBrightnessContrast(
    allocator: std.mem.Allocator,
    img: Image,
    clip_hist_percent: f32,
) ![]u8 {
    const gray = try rgbToGrayScale(allocator, img);
    defer allocator.free(gray);

    // Calculate histogram / frequency distribution
    var hist = [_]usize{0} ** 256;
    for (gray) |px| {
        hist[px] += 1;
    }

    // Cumulative distribution
    var accumulator = [_]usize{0} ** 256;
    accumulator[0] = hist[0];
    for (1..256) |i| {
        accumulator[i] = accumulator[i - 1] + hist[i];
    }

    // Locate points to clip
    const max = accumulator[255];
    const clip_hist_count = @as(usize, @intFromFloat(@as(f32, @floatFromInt(max)) * clip_hist_percent / 100.0 / 2.0));

    // Locate left cut
    var min_gray: usize = 0;
    while (accumulator[min_gray] < clip_hist_count) : (min_gray += 1) {}

    // Locate right cut
    var max_gray: usize = 255;
    while (accumulator[max_gray] >= (max - clip_hist_count)) : (max_gray -= 1) {}

    // Calculate alpha and beta values
    const alpha = 255.0 / @as(f32, @floatFromInt(max_gray - min_gray));
    const beta = -@as(f32, @floatFromInt(min_gray)) * alpha;

    // Apply brightness and contrast adjustment
    const len = img.width * img.height * img.channels;
    var res = try allocator.alloc(u8, len);
    for (0..len) |i| {
        const adjusted = @as(f32, @floatFromInt(img.data[i])) * alpha + beta;
        res[i] = @intFromFloat(std.math.clamp(adjusted, 0, 255));
    }

    return res;
}

pub fn gaussianKernel(allocator: std.mem.Allocator, sigma: f32) ![]f32 {
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

pub fn applyGaussianBlur(allocator: std.mem.Allocator, img: Image, sigma: f32) ![]u8 {
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

pub fn differenceOfGaussians(allocator: std.mem.Allocator, img: Image, sigma1: f32, sigma2: f32) ![]u8 {
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

pub fn applySobelFilter(allocator: std.mem.Allocator, img: Image) !SobelFilter {
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

pub fn getEdgeChar(mag: f32, dir: f32, threshold_disabled: bool) ?u8 {
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

pub fn detectEdges(allocator: std.mem.Allocator, img: Image, sigma1: f32, sigma2: f32) !EdgeData {
    // if (!args.detect_edges) {
    //     return .{ .grayscale = &[_]u8{}, .magnitude = &[_]f32{}, .direction = &[_]f32{} };
    // }

    const grayscale_img = try rgbToGrayScale(allocator, img);
    const dog_img = try differenceOfGaussians(allocator, .{
        .data = grayscale_img.ptr,
        .width = img.width,
        .height = img.height,
        .channels = img.channels,
    }, sigma1, sigma2);
    defer allocator.free(dog_img);

    const edge_result = try applySobelFilter(allocator, .{
        .data = dog_img.ptr,
        .width = img.width,
        .height = img.height,
        .channels = 1,
    });

    return .{
        .grayscale = grayscale_img,
        .magnitude = edge_result.magnitude,
        .direction = edge_result.direction,
    };
}

const BlockInfo = struct {
    sum_brightness: u64,
    sum_color: [3]u64,
    pixel_count: u64,
    sum_mag: f32,
    sum_dir: f32,
};
pub fn calculateBlockInfo(
    img: Image,
    edge_result: EdgeData,
    x: usize,
    y: usize,
    out_w: usize,
    out_h: usize,
    args: CoreParams,
) BlockInfo {
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

fn calculateAverageColor(block_info: BlockInfo, args: CoreParams) [3]u8 {
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

fn convertToAscii(
    img: []u8,
    w: usize,
    h: usize,
    x: usize,
    y: usize,
    ascii_char: []const u8,
    color: [3]u8,
    block_size: u8,
    color_enabled: bool,
) !void {
    const bm = &(try bitmap.getCharSet(ascii_char));
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
                if ((bm[dy] & bit) != 0) {
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

pub fn generateAsciiArt(
    allocator: std.mem.Allocator,
    img: Image,
    edge_result: EdgeData,
    args: CoreParams,
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

            try convertToAscii(ascii_img, out_w, out_h, x, y, ascii_char, avg_color, args.block_size, args.color);
        }
    }

    return ascii_img;
}