const std = @import("std");
/// Author: andrewrk
/// Source: https://github.com/andrewrk/mime/blob/2.0.0/mime.zig
/// The integer values backing these enum tags are not protected by the
/// semantic version of this package but the backing integer type is.
/// The tags are guaranteed to be sorted by name.
pub const Type = enum(u16) {
    @"image/bmp",
    @"image/gif",
    @"image/jpeg",
    @"image/png",
    @"image/svg+xml",
    @"image/tiff",
    @"image/vnd.microsoft.icon",
    @"image/webp",
    @"video/3gpp",
    @"video/3gpp2",
    @"video/mp2t",
    @"video/mp4",
    @"video/mpeg",
    @"video/ogg",
    @"video/quicktime",
    @"video/webm",
    @"video/x-msvideo",
};

/// Maps file extension to mime type.
pub const extension_map = std.StaticStringMap(Type).initComptime(.{
    .{ ".bmp", .@"image/bmp" },
    .{ ".gif", .@"image/gif" },
    .{ ".ico", .@"image/vnd.microsoft.icon" },
    .{ ".jpg", .@"image/jpeg" },
    .{ ".jpeg", .@"image/jpeg" },
    .{ ".png", .@"image/png" },
    .{ ".svg", .@"image/svg+xml" },
    .{ ".tiff", .@"image/tiff" },
    .{ ".webp", .@"image/webp" },
    .{ ".avi", .@"video/x-msvideo" },
    .{ ".mov", .@"video/quicktime" },
    .{ ".mp4", .@"video/mp4" },
    .{ ".mpeg", .@"video/mpeg" },
    .{ ".ogv", .@"video/ogg" },
    .{ ".ts", .@"video/mp2t" },
    .{ ".webm", .@"video/webm" },
    .{ ".3gp", .@"video/3gpp" },
    .{ ".3g2", .@"video/3gpp2" },
});
