const backend = @import("backends/raylib.zig");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
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

pub const TextOptions = struct {
    font: ?Font = null,
    size: f32 = 10,
    character_spacing: f32 = 1,
    line_spacing: f32 = 2,
};

pub const Font = backend.Font;

pub const getWindowSize: fn () Vec2 = backend.getWindowSize;
pub const getMousePosition: fn () Vec2 = backend.getMousePosition;
pub const getDefaultFont: fn () *anyopaque = backend.getDefaultFont;
pub const drawText: fn (TextOptions, []const u8, Vec2, Color) void = backend.drawText;
pub const measureText: fn (TextOptions, []const u8) Vec2 = backend.measureText;
