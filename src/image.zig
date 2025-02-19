const std = @import("std");
const stb = @import("stb");
const core = @import("libglyph");
const bitmap = core.bitmap;
const term = @import("libglyphterm");

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
fn loadImage(allocator: std.mem.Allocator, path: []const u8) !core.Image {
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
    var rgb_data = allocator.alloc(u8, @as(usize, @intCast(w * h * 3))) catch return error.OutOfMemory;

    defer stb.stbi_image_free(data);

    if (@intFromPtr(data) == 0) {
        std.debug.print("Error loading image: {s}\n", .{path});
        return error.ImageLoadFailed;
    }

    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".png")) {

        // If image has 4 channels (RGBA), strip the alpha channel
        if (chan == 4) {
            var i: usize = 0;
            var j: usize = 0;
            while (i < @as(usize, @intCast(w * h * 4))) : (i += 4) {
                rgb_data[j] = data[i]; // R
                rgb_data[j + 1] = data[i + 1]; // G
                rgb_data[j + 2] = data[i + 2]; // B
                j += 3;
            }

            return core.Image{
                .data = rgb_data.ptr,
                .width = @intCast(w),
                .height = @intCast(h),
                .channels = 3,
            };
        }

        @memcpy(rgb_data.ptr, data[0..(@as(usize, @intCast(w * h * 3)))]);

        return core.Image{
            .data = rgb_data.ptr,
            .width = @intCast(w),
            .height = @intCast(h),
            .channels = @intCast(chan),
        };
    }

    @memcpy(rgb_data.ptr, data[0..(@as(usize, @intCast(w * h * chan)))]);

    return core.Image{
        .data = data,
        .width = @intCast(w),
        .height = @intCast(h),
        .channels = @intCast(chan),
    };
}

fn loadAndScaleImage(allocator: std.mem.Allocator, args: core.CoreParams) !core.Image {
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

fn scaleImage(img: core.Image, scale: f32) !core.Image {
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

    return core.Image{
        .data = scaled_img,
        .width = img_w,
        .height = img_h,
        .channels = img.channels,
    };
}

fn generateAsciiTxt(
    allocator: std.mem.Allocator,
    img: core.Image,
    edge_result: core.EdgeData,
    args: core.CoreParams,
) ![]u8 {
    const out_w = (img.width / args.block_size) * args.block_size;
    const out_h = (img.height / args.block_size) * args.block_size;

    var ascii_text = std.ArrayList(u8).init(allocator);
    defer ascii_text.deinit();

    var y: usize = 0;
    while (y < out_h) : (y += args.block_size) {
        var x: usize = 0;
        while (x < out_w) : (x += args.block_size) {
            const block_info = core.calculateBlockInfo(img, edge_result, x, y, out_w, out_h, args);
            const ascii_char = core.selectAsciiChar(block_info, args);
            try ascii_text.appendSlice(ascii_char);
        }
        try ascii_text.append('\n');
    }

    return ascii_text.toOwnedSlice();
}

fn saveOutputTxt(ascii_text: []const u8, args: core.CoreParams) !void {
    const file = try std.fs.cwd().createFile(args.output.?, .{});
    defer file.close();

    try file.writeAll(ascii_text);
}

fn saveOutputImage(ascii_img: []u8, img: core.Image, args: core.CoreParams) !void {
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

pub fn processImage(allocator: std.mem.Allocator, args: core.CoreParams) !void {
    const original_img = try loadAndScaleImage(allocator, args);
    // defer stb.stbi_image_free(original_img.data);

    const adjusted_data = if (args.auto_adjust)
        try core.autoBrightnessContrast(allocator, original_img, 1.0)
    else
        original_img.data[0 .. original_img.width * original_img.height * original_img.channels];

    const adjusted_img = core.Image{
        .data = adjusted_data.ptr,
        .width = original_img.width,
        .height = original_img.height,
        .channels = original_img.channels,
    };
    defer allocator.free(adjusted_data);

    const edge_result = try core.detectEdges(allocator, adjusted_img, args.sigma1, args.sigma2);
    defer {
        allocator.free(edge_result.grayscale);
        allocator.free(edge_result.magnitude);
        allocator.free(edge_result.direction);
    }

    switch (args.output_type) {
        core.OutputType.Image => {
            const ascii_img = try core.generateAsciiArt(
                allocator,
                adjusted_img,
                edge_result,
                args,
            );
            defer allocator.free(ascii_img);
            try saveOutputImage(ascii_img, adjusted_img, args);
        },
        core.OutputType.Stdout => {
            var t = try term.init(allocator, args.ascii_chars);
            defer t.deinit();

            var img: core.Image = undefined;
            if (args.stretched) {
                img = try core.resizeImage(adjusted_img, t.size.w - 2, t.size.h - 4);
            } else {
                var new_w: usize = 0;
                var new_h: usize = 0;
                const rw = adjusted_img.width / (t.size.w - 2);
                const rh = adjusted_img.height / (t.size.h - 4);
                if (rw > rh) {
                    new_h = adjusted_img.height / (rw * 2);
                    new_w = t.size.w - 2;
                } else {
                    new_h = (t.size.h - 4) / 2;
                    new_w = adjusted_img.width / rh;
                }
                img = try core.resizeImage(adjusted_img, new_w, new_h);
            }
            defer if (args.stretched) stb.stbi_image_free(img.data);

            t.stats = .{
                .original_w = adjusted_img.width,
                .original_h = adjusted_img.height,
                .new_w = img.width,
                .new_h = img.height,
            };

            const img_len = img.height * img.width * img.channels;

            try t.enableAsciiMode();
            const params = term.RenderParams{
                .img = img.data[0..img_len],
                .width = img.width,
                .height = img.height,
                .channels = img.channels,
                .color = args.color,
                .invert = args.invert_color,
            };
            try t.renderAsciiArt(params);

            // Wait for user input before exiting
            _ = try t.stdin.readByte();
            try t.disableAsciiMode();
        },
        core.OutputType.Text => {
            // 1 : og
            // dr : grid
            const img = try core.resizeImage(adjusted_img, adjusted_img.width, adjusted_img.height / 2);
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
