const rl = @import("raylib");
const Color = rl.Color;

const root = @import("../root.zig");
const g = root.grabbing;

pub const Panel = struct {
    rect: rl.Rectangle,
    title: ?[:0]const u8,

    pub fn draw(self: Panel) void {
        self.drawWithOptions(default_panel_options);
    }

    pub fn drawWithOptions(self: Panel, options: PanelOptions) void {
        rl.drawRectangleRec(self.rect, options.colors.background);
        rl.drawRectangleLinesEx(self.rect, options.border_thickness, options.colors.border);
        if (self.title) |title| {
            const bar_rect = blk: {
                var rect = self.rect;
                rect.height = 20;
                break :blk rect;
            };
            rl.drawRectangleRec(bar_rect, options.colors.bar);
            rl.drawRectangleLinesEx(bar_rect, options.border_thickness, options.colors.border);
            const text_x = bar_rect.x + 3;
            const text_y = bar_rect.y + (bar_rect.height - @as(f32, @floatFromInt(options.font_size))) / 2;
            rl.drawText(title, @intFromFloat(text_x), @intFromFloat(text_y), options.font_size, options.colors.text);
        }
    }
};

pub var default_panel_options: PanelOptions = .{};

pub const PanelOptions = struct {
    font_size: i32 = 10, // TODO: Consider changing this to u32
    border_thickness: f32 = 2,
    colors: Colors = .colors(.ray_white, .light_gray, .gray, .gray),

    const Colors = struct {
        background: Color,
        bar: Color,
        border: Color,
        text: Color,

        pub fn colors(background: Color, bar: Color, border: Color, text: Color) Colors {
            return .{ .background = background, .bar = bar, .border = border, .text = text };
        }
        pub fn get(self: Colors) struct { Color, Color, Color } {
            return .{ self.background, self.bar, self.border, self.text };
        }
    };
};

pub const GroupBox = struct {
    rect: rl.Rectangle,
    title: ?[:0]const u8,

    pub fn draw(self: GroupBox) void {
        self.drawWithOptions(default_groupbox_options);
    }

    pub fn drawWithOptions(self: GroupBox, options: GroupBoxOptions) void {
        const left_edge: rl.Rectangle = .{
            .x = self.rect.x,
            .y = self.rect.y,
            .width = options.border_thickness,
            .height = self.rect.height,
        };
        const right_edge: rl.Rectangle = .{
            .x = self.rect.x + self.rect.width - options.border_thickness,
            .y = self.rect.y,
            .width = options.border_thickness,
            .height = self.rect.height,
        };
        const bottom_edge: rl.Rectangle = .{
            .x = self.rect.x + options.border_thickness,
            .y = self.rect.y + self.rect.height - options.border_thickness,
            .width = self.rect.width - 2 * options.border_thickness,
            .height = options.border_thickness,
        };
        const top_edge: rl.Rectangle = .{
            .x = self.rect.x + options.border_thickness,
            .y = self.rect.y,
            .width = self.rect.width - 2 * options.border_thickness,
            .height = options.border_thickness,
        };

        rl.drawRectangleRec(left_edge, options.colors.border);
        rl.drawRectangleRec(right_edge, options.colors.border);
        rl.drawRectangleRec(bottom_edge, options.colors.border);

        if (self.title) |title| {
            const text_x = self.rect.x + options.border_thickness + 10;
            const text_y = self.rect.y + (options.border_thickness - @as(f32, @floatFromInt(options.font_size))) / 2;
            const top_left_edge = blk: {
                var rect = top_edge;
                rect.width = 5;
                break :blk rect;
            };
            const top_right_edge = blk: {
                var rect = top_edge;
                const text_width = rl.measureText(title, options.font_size);
                rect.x += @floatFromInt(10 + text_width + 5);
                rect.width -= @floatFromInt(10 + text_width + 5);
                break :blk rect;
            };
            rl.drawText(title, @intFromFloat(text_x), @intFromFloat(text_y), options.font_size, options.colors.text);
            rl.drawRectangleRec(top_right_edge, options.colors.border);
            rl.drawRectangleRec(top_left_edge, options.colors.border);
        } else {
            rl.drawRectangleRec(top_edge, options.colors.border);
        }
    }
};

pub var default_groupbox_options: GroupBoxOptions = .{};

pub const GroupBoxOptions = struct {
    font_size: i32 = 10, // TODO: Consider changing this to u32
    border_thickness: f32 = 2,
    colors: Colors = .colors(.gray, .gray),

    const Colors = struct {
        border: Color,
        text: Color,

        pub fn colors(border: Color, text: Color) Colors {
            return .{ .border = border, .text = text };
        }
        pub fn get(self: Colors) struct { Color, Color, Color } {
            return .{ self.border, self.text };
        }
    };
};
