const std = @import("std");

const backend = @import("backends/raylib.zig");

comptime {
    std.testing.refAllDecls(Color);
}

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn fromRgba(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Alpha is set to 255
    pub fn fromRgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = 255 };
    }

    /// Interprets int as RGBA
    pub fn fromIntRgba(int: u32) Color {
        const bytes = std.mem.asBytes(&int);
        if (@import("builtin").cpu.arch.endian() == .little) {
            return .{ .r = bytes[3], .g = bytes[2], .b = bytes[1], .a = bytes[0] };
        } else {
            return .{ .r = bytes[0], .g = bytes[1], .b = bytes[2], .a = bytes[3] };
        }
    }

    /// Interprets int as RGB, alpha is set to 255
    pub fn fromIntRgb(int: u24) Color {
        return fromIntRgba(@as(u32, @intCast(int)) << 8 | 0xFF);
    }

    /// Parses hex string into a `Color`
    /// String can be 3, 4, 6, or 8 characters long, with an optional "0x" prefix
    ///
    /// The way strings are parsed, by length:
    ///   * 8 - Parsed as RGBA
    ///   * 6 - Parsed as RGB, A is set to 255
    ///   * 4 - Parsed as RGBA, each character is treated as if it repeated twice
    ///   * 3 - Parsed as RGB, each character is treated as if it repeated twice, A is set to 255
    pub fn fromHex(string: []const u8) Color {
        const string_ = if (std.mem.startsWith(u8, string, "0x")) string[2..] else string;
        switch (string_.len) {
            inline 3, 4, 6, 8 => |len| {
                const vec: @Vector(len, u8) = string_[0..len].*;
                const isDigit = @intFromBool((vec >= @as(@Vector(len, u8), @splat('0'))) & (vec <= @as(@Vector(len, u8), @splat('9'))));
                const isHexLower = @intFromBool((vec >= @as(@Vector(len, u8), @splat('a'))) & (vec <= @as(@Vector(len, u8), @splat('f'))));
                const isHexUpper = @intFromBool((vec >= @as(@Vector(len, u8), @splat('A'))) & (vec <= @as(@Vector(len, u8), @splat('F'))));
                const subs = (@as(@Vector(len, u8), @splat('0')) * isDigit) | (@as(@Vector(len, u8), @splat(('a' - 10))) * isHexLower) | (@as(@Vector(len, u8), @splat(('A' - 10))) * isHexUpper);
                const nibbles = vec - subs;

                return switch (len) {
                    3 => .{
                        .r = nibbles[0] << 4 | nibbles[0],
                        .g = nibbles[1] << 4 | nibbles[1],
                        .b = nibbles[2] << 4 | nibbles[2],
                        .a = 255,
                    },
                    4 => .{
                        .r = nibbles[0] << 4 | nibbles[0],
                        .g = nibbles[1] << 4 | nibbles[1],
                        .b = nibbles[2] << 4 | nibbles[2],
                        .a = nibbles[3] << 4 | nibbles[3],
                    },
                    6 => .{
                        .r = nibbles[0] << 4 | nibbles[1],
                        .g = nibbles[2] << 4 | nibbles[3],
                        .b = nibbles[4] << 4 | nibbles[5],
                        .a = 255,
                    },
                    8 => .{
                        .r = nibbles[0] << 4 | nibbles[1],
                        .g = nibbles[2] << 4 | nibbles[3],
                        .b = nibbles[4] << 4 | nibbles[5],
                        .a = nibbles[6] << 4 | nibbles[7],
                    },
                    else => comptime unreachable,
                };
            },
            else => unreachable,
        }
    }

    test "Colors" {
        const t = std.testing;

        try t.expectEqual(Color.fromRgba(0xFF, 0x88, 0x44, 0x22), Color.fromIntRgba(0xff884422));
        try t.expectEqual(Color.fromRgba(0xFF, 0x88, 0x44, 0xFF), Color.fromIntRgb(0xff8844));

        try t.expectEqual(Color.fromRgba(0x87, 0x65, 0x43, 0x21), Color.fromHex("0x87654321"));
        try t.expectEqual(Color.fromRgba(0x87, 0x65, 0x43, 0xFF), Color.fromHex("0x876543"));
        try t.expectEqual(Color.fromRgba(0x88, 0x44, 0x22, 0x11), Color.fromHex("0x8421"));
        try t.expectEqual(Color.fromRgba(0x88, 0x44, 0x22, 0xFF), Color.fromHex("0x842"));
        try t.expectEqual(Color.fromRgba(0x87, 0x65, 0x43, 0x21), Color.fromHex("87654321"));
        try t.expectEqual(Color.fromRgba(0x87, 0x65, 0x43, 0xFF), Color.fromHex("876543"));
        try t.expectEqual(Color.fromRgba(0x88, 0x44, 0x22, 0x11), Color.fromHex("8421"));
        try t.expectEqual(Color.fromRgba(0x88, 0x44, 0x22, 0xFF), Color.fromHex("842"));
    }

    // TODO: godawful colors, do better
    // zig fmt: off
    pub const      white: Color = init(255, 255, 255, 255);
    pub const light_gray: Color = init(172, 172, 172, 255);
    pub const       gray: Color = init(128, 128, 128, 255);
    pub const  dark_gray: Color = init(78, 78, 78, 255);
    pub const      black: Color = init(0, 0, 0, 255);

    pub const      green: Color = init(0, 255, 0, 255);
    pub const dark_green: Color = init(0, 128, 0, 255);

    pub const       blue: Color = init(0, 0, 255, 255);
    pub const  dark_blue: Color = init(0, 0, 128, 255);
    pub const       cyan: Color = init(0, 255, 255, 255);
    // zig fmt: on
};

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub const zero: Vec2 = .{ .x = 0, .y = 0 };
};

pub const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn init(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    pub fn containsPoint(self: Rectangle, point: Vec2) bool {
        return (point.x >= self.x and point.x <= self.x + self.width) and
            (point.y >= self.y and point.y <= self.y + self.height);
    }

    pub const draw: fn (Rectangle, Color) void = backend.drawRectangle;
    pub const drawOutline: fn (Rectangle, Color, f32) void = backend.drawRectangleOutline;
};

pub const MouseButton = enum { left, right, middle };

pub const MouseButtonState = packed struct {
    currently: bool,
    previously: bool,

    pub const clicked: MouseButtonState = .{ .currently = true, .previously = false };
    pub const released: MouseButtonState = .{ .currently = false, .previously = true };
};

pub const TextOptions = struct {
    font: ?Font = null,
    size: f32 = 10,
    character_spacing: f32 = 1,
    line_spacing: f32 = 2,
};

pub const Font = backend.Font;

pub const getWindowSize: fn () Vec2 = backend.getWindowSize;
pub const getMousePosition: fn () Vec2 = backend.getMousePosition;
pub const getMouseButtonState: fn (MouseButton) MouseButtonState = backend.getMouseButtonState;
pub const getDefaultFont: fn () ?Font = backend.getDefaultFont;
pub const drawText: fn (TextOptions, []const u8, Vec2, Color) void = backend.drawText;
pub const measureText: fn (TextOptions, []const u8) Vec2 = backend.measureText;
pub const longestFittingSubstring: fn (TextOptions, []const u8, f32) struct { []const u8, f32 } = backend.longestFittingSubstring;
pub const lastLongestFittingSubstring: fn (TextOptions, []const u8, f32) struct { []const u8, f32 } = backend.lastLongestFittingSubstring;
