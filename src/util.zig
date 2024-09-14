const std = @import("std");
const builtin = @import("builtin");
const Thread = std.Thread;
const Mutex = Thread.Mutex;
const Condition = Thread.Condition;

pub fn FrameBuffer(comptime T: type) type {
    return struct {
        const Self = @This();
        frames: std.ArrayList(T),
        w: usize = 0,
        h: usize = 0,
        channels: usize = 3,
        mutex: Mutex,
        cond: Condition,
        max_size: usize,
        is_finished: bool,
        allocator: std.mem.Allocator,
        ready: bool,

        pub fn init(allocator: std.mem.Allocator, max_size: usize) Self {
            return .{
                .frames = std.ArrayList(T).init(allocator),
                .mutex = Mutex{},
                .cond = Condition{},
                .max_size = max_size,
                .is_finished = false,
                .allocator = allocator,
                .ready = false,
            };
        }

        pub fn deinit(self: *Self) void {
            self.frames.deinit();
        }

        pub fn push(self: *Self, frame: T) !void {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.frames.items.len >= self.max_size) {
                self.cond.wait(&self.mutex);
            }

            try self.frames.append(frame);
            self.cond.signal();
        }

        pub fn pop(self: *Self) ?T {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.frames.items.len == 0 and !self.is_finished) {
                self.cond.wait(&self.mutex);
            }

            if (self.frames.items.len == 0) {
                return null;
            }

            const frame = self.frames.orderedRemove(0);
            self.cond.signal();
            return frame;
        }

        pub fn setFinished(self: *Self) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.is_finished = true;
            self.cond.broadcast();
        }

        pub fn setReady(self: *Self) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.ready = true;
            self.cond.broadcast();
        }

        pub fn waitUntilReady(self: *Self) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            while (!self.ready) {
                self.cond.wait(&self.mutex);
            }
        }
    };
}
