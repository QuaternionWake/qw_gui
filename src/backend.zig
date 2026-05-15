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

    // zig fmt: off
    // Hex colors
    pub const   hex_white: Color = .fromRgb(255, 255, 255);
    pub const    hex_gray: Color = .fromRgb(128, 128, 128);
    pub const   hex_black: Color = .fromRgb(  0,   0,   0);

    pub const     hex_red: Color = .fromRgb(255,   0,   0);
    pub const   hex_green: Color = .fromRgb(  0, 255,   0);
    pub const    hex_blue: Color = .fromRgb(  0,   0, 255);

    pub const    hex_cyan: Color = .fromRgb(  0, 255, 255);
    pub const hex_magenta: Color = .fromRgb(255,   0, 255);
    pub const  hex_yellow: Color = .fromRgb(255, 255,   0);

    // Normal colors
    pub const darker_magenta: Color = .fromIntRgb(0x6d0c5d);
    pub const   dark_magenta: Color = .fromIntRgb(0x9a087f);
    pub const        magenta: Color = .fromIntRgb(0xd40caf);
    pub const  light_magenta: Color = .fromIntRgb(0xf318e8);

    pub const  darker_red: Color = .fromIntRgb(0x51010c);
    pub const    dark_red: Color = .fromIntRgb(0x720312);
    pub const         red: Color = .fromIntRgb(0xc40720);
    pub const   light_red: Color = .fromIntRgb(0xe2041e);
    pub const lighter_red: Color = .fromIntRgb(0xef324e);
    pub const        pink: Color = .fromIntRgb(0xfc83d6);

    pub const reddish_orange: Color = .fromIntRgb(0xff5117);

    pub const   dark_brown: Color = .fromIntRgb(0x512b00);
    pub const        brown: Color = .fromIntRgb(0x713e00);
    pub const  light_brown: Color = .fromIntRgb(0x9a4902);
    pub const  dark_orange: Color = .fromIntRgb(0xb75805);
    pub const       orange: Color = .fromIntRgb(0xff8f1e);
    pub const light_orange: Color = .fromIntRgb(0xffa411);

    pub const yellowish_orange: Color = .fromIntRgb(0xffd11a);

    pub const  dark_yellow: Color = .fromIntRgb(0xe2cb1a);
    pub const       yellow: Color = .fromIntRgb(0xffea03);
    pub const light_yellow: Color = .fromIntRgb(0xfffa73);

    pub const  dark_pale_green: Color = .fromIntRgb(0x4d862a);
    pub const       pale_green: Color = .fromIntRgb(0x75d918);
    pub const light_pale_green: Color = .fromIntRgb(0xa1d159);
    pub const             lime: Color = .fromIntRgb(0x8cff08);

    pub const darkest_green: Color = .fromIntRgb(0x124a0b);
    pub const  darker_green: Color = .fromIntRgb(0x1d7d13);
    pub const    dark_green: Color = .fromIntRgb(0x22b433);
    pub const         green: Color = .fromIntRgb(0x2be716);
    pub const   light_green: Color = .fromIntRgb(0x25ff03);

    pub const  dark_turquoise: Color = .fromIntRgb(0x1e8770);
    pub const       turquoise: Color = .fromIntRgb(0x1db187);
    pub const light_turquoise: Color = .fromIntRgb(0x17f0af);

    pub const darkest_cyan: Color = .fromIntRgb(0x165050);
    pub const  darker_cyan: Color = .fromIntRgb(0x207475);
    pub const    dark_cyan: Color = .fromIntRgb(0x158f91);
    pub const         cyan: Color = .fromIntRgb(0x12b3b3);
    pub const   light_cyan: Color = .fromIntRgb(0x15d9d9);
    pub const lighter_cyan: Color = .fromIntRgb(0x0df1de);

    pub const  dark_sky_blue: Color = .fromIntRgb(0x09679e);
    pub const       sky_blue: Color = .fromIntRgb(0x0c87d4);
    pub const light_sky_blue: Color = .fromIntRgb(0x02a6ff);

    pub const darker_blue: Color = .fromIntRgb(0x0e116d);
    pub const   dark_blue: Color = .fromIntRgb(0x0e19b6);
    pub const        blue: Color = .fromIntRgb(0x1751f0);

    pub const indgo: Color = .fromIntRgb(0x460af9);

    pub const darker_purple: Color = .fromIntRgb(0x2a0e5f);
    pub const   dark_purple: Color = .fromIntRgb(0x431696);
    pub const        purple: Color = .fromIntRgb(0x6100f3);

    pub const       purpleish_magenta: Color = .fromIntRgb(0xa913f4);
    pub const light_purpleish_magenta: Color = .fromIntRgb(0xd70cff);

    // Whites, blacks. greys
    pub const warm_white: Color = .fromIntRgb(0xfffcf8);
    pub const      cream: Color = .fromIntRgb(0xfff8f4);

    pub const        black: Color = .fromIntRgb(0x1d1d1d);
    pub const  darker_gray: Color = .fromIntRgb(0x404050);
    pub const    dark_gray: Color = .fromIntRgb(0x5c5c6c);
    pub const         gray: Color = .fromIntRgb(0x808090);
    pub const   light_gray: Color = .fromIntRgb(0xc0c0d0);
    pub const lighter_gray: Color = .fromIntRgb(0xe0e0f0);
    pub const        white: Color = .fromIntRgb(0xf4f4ff);
    // zig fmt: on
};

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub const zero: Vec2 = .{ .x = 0, .y = 0 };
};

pub const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn init(x: f32, y: f32, width: f32, height: f32) Rect {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    pub fn center(self: Rect) Vec2 {
        return .{
            .x = self.x + self.width / 2,
            .y = self.y + self.height / 2,
        };
    }

    pub fn containsPoint(self: Rect, point: Vec2) bool {
        return (point.x >= self.x and point.x <= self.x + self.width) and
            (point.y >= self.y and point.y <= self.y + self.height);
    }

    pub fn subrect(parent: Rect, options: SubrectOptions) Rect {
        const width = switch (options.width) {
            .amount => |val| val,
            .relative => |val| parent.width + val,
            .proportion => |val| parent.width * val,
            .max => parent.width,
        };

        const height = switch (options.height) {
            .amount => |val| val,
            .relative => |val| parent.height + val,
            .proportion => |val| parent.height * val,
            .max => parent.height,
        };

        const x = switch (options.x) {
            .left => |offset| parent.x + offset,
            .middle => |offset| parent.x + (parent.width - width) / 2 + offset,
            .right => |offset| parent.x + parent.width - width + offset,
        };

        const y = switch (options.y) {
            .top => |offset| parent.y + offset,
            .middle => |offset| parent.y + (parent.height - height) / 2 + offset,
            .bottom => |offset| parent.y + parent.height - height + offset,
        };

        return .init(x, y, width, height);
    }

    pub const SubrectOptions = struct {
        x: union(enum) { left: f32, middle: f32, right: f32 },
        y: union(enum) { top: f32, middle: f32, bottom: f32 },
        width: union(enum) { amount: f32, relative: f32, proportion: f32, max },
        height: union(enum) { amount: f32, relative: f32, proportion: f32, max },
    };

    pub fn nthSubrectV(parent: Rect, n: usize, options: NthSubrectOptions) Rect {
        var result = options.padding.subrect(parent);
        result.height = (result.height + options.gap) / options.total_subrects;
        result.y += result.height * n;
        result.height -= options.gap;
        return result;
    }

    pub fn nthSubrectH(parent: Rect, n: usize, options: NthSubrectOptions) Rect {
        var result = options.padding.subrect(parent);
        result.width = (result.width + options.gap) / options.total_subrects;
        result.x += result.width * n;
        result.width -= options.gap;
        return result;
    }

    pub const NthSubrectOptions = struct {
        total_subrects: usize,
        padding: Padding,
        gap: f32,
    };

    pub fn gridSubrect(parent: Rect, x: usize, y: usize, options: GridSubrectOptions) Rect {
        var result = options.padding.subrect(parent);
        result.width = (result.width + options.gap_x) / options.total_subrects_x;
        result.height = (result.height + options.gap_y) / options.total_subrects_y;
        result.x += result.width * x;
        result.y += result.height * y;
        result.width -= options.gap_x;
        result.height -= options.gap_y;
        return result;
    }

    pub const GridSubrectOptions = struct {
        total_subrects_x: usize,
        total_subrects_y: usize,
        padding: Padding,
        gap_x: f32,
        gap_y: f32,
    };

    pub const draw: fn (Rect, Color) void = backend.drawRectangle;
    pub const drawOutline: fn (Rect, Color, f32) void = backend.drawRectangleOutline;
};

pub fn screenRect() Rect {
    const window_size = getWindowSize();
    return .{
        .x = 0,
        .y = 0,
        .width = window_size.x,
        .height = window_size.y,
    };
}

pub const Padding = struct {
    top: f32,
    right: f32,
    bottom: f32,
    left: f32,

    fn all(all_: f32) Padding {
        return .{
            .top = all_,
            .right = all_,
            .bottom = all_,
            .left = all_,
        };
    }

    fn verticalHorizntal(vertical: f32, horizontal: f32) Padding {
        return .{
            .top = vertical,
            .right = horizontal,
            .bottom = vertical,
            .left = horizontal,
        };
    }

    fn topHorizntalBottom(top: f32, horizontal: f32, bottom: f32) Padding {
        return .{
            .top = top,
            .right = horizontal,
            .bottom = bottom,
            .left = horizontal,
        };
    }

    fn topRightBottomLeft(top: f32, right: f32, bottom: f32, left: f32) Padding {
        return .{
            .top = top,
            .right = right,
            .bottom = bottom,
            .left = left,
        };
    }

    fn subrect(self: Padding, rect: Rect) Rect {
        var result = rect;
        result.x += self.left;
        result.y += self.top;
        result.width -= self.left - self.right;
        result.height -= self.top - self.bottom;
        return result;
    }
};

pub const Triangle = struct {
    v1: Vec2,
    v2: Vec2,
    v3: Vec2,

    pub fn init(x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32) Triangle {
        return .{
            .v1 = .{ .x = x1, .y = y1 },
            .v2 = .{ .x = x2, .y = y2 },
            .v3 = .{ .x = x3, .y = y3 },
        };
    }

    pub const draw: fn (Triangle, Color) void = backend.drawTriangle;
};

pub const MouseButton = enum { left, right, middle };

pub const MouseButtonState = packed struct {
    currently: bool,
    previously: bool,

    pub const clicked: MouseButtonState = .{ .currently = true, .previously = false };
    pub const released: MouseButtonState = .{ .currently = false, .previously = true };
};

// TODO: aliases for some keys (grave => backtick, return => enter, ...)
// TODO: maybe give these concrete values?
pub const KeyboardKey = enum(u16) {
    // zig fmt: off
    null = 0,

    q, w, e, r, t, y, u, i, o, p,
    a, s, d, f, g, h, j, k, l,
    z, x, c, v, b, n, m,

    space,

    left_bracket, right_bracket,
    semicolon, apostrophe, backslash,
    comma, period, slash,

    escape, backtick, tab, caps_lock,
    backspace, enter,

    left_shift, left_control, left_super, left_alt,
    right_shift, right_control, right_super, right_alt,
    menu,

       zero,     one,     two,     three,     four,     five,     six,     seven,     eight,     nine,
    np_zero,  np_one,  np_two,  np_three,  np_four,  np_five,  np_six,  np_seven,  np_eight,  np_nine,
    minus, equals,
    num_lock, np_divide, np_multiply, np_subrtact, np_add, np_decimal, np_equal, np_enter,

    // TODO: higher than f12 keys?
    f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,

    print_screen, scroll_lock, pause_break,
    insert, delete, page_up, page_down, home, end,
    up, down, left, right,
    // zig fmt: on
};

pub const PseudoKeyboardKey = enum(u16) { shift, control, super, alt, enter };

pub const KeyboardKeyState = packed struct {
    currently: bool,
    previously: bool,
    repeat: bool,

    pub fn isPressed(state: KeyboardKeyState) bool {
        return state.currently and !state.previously or state.repeat;
    }
    pub fn isReleased(state: KeyboardKeyState) bool {
        return !state.currently and state.previously;
    }
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

pub const getCharPressed: fn () u21 = backend.getCharPressed;
pub const getKeyState: fn (KeyboardKey) KeyboardKeyState = backend.getKeyState;
pub const getPseudoKeyState: fn (PseudoKeyboardKey) KeyboardKeyState = backend.getPseudoKeyState;

pub const getDefaultFont: fn () ?Font = backend.getDefaultFont;
pub const drawText: fn (TextOptions, []const u8, Vec2, Color) void = backend.drawText;
pub const measureText: fn (TextOptions, []const u8) Vec2 = backend.measureText;
pub const longestFittingSubstring: fn (TextOptions, []const u8, f32) struct { []const u8, f32 } = backend.longestFittingSubstring;
pub const lastLongestFittingSubstring: fn (TextOptions, []const u8, f32) struct { []const u8, f32 } = backend.lastLongestFittingSubstring;
