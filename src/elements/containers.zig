const rl = @import("raylib");
const Color = rl.Color;

const g = @import("grabbing");
const Rect = @import("Rect");

pub const Panel = struct {
    rect: Rect,
    title: ?[:0]const u8,

    pub fn draw(self: Panel) void {
        self.drawWithOptions(default_panel_options);
    }

    pub fn drawWithOptions(self: Panel, options: PanelOptions) void {
        const rect = self.rect.rlRect();
        rl.drawRectangleRec(rect, options.colors.background);
        rl.drawRectangleLinesEx(rect, options.border_thickness, options.colors.border);
        if (self.title) |title| {
            const bar_rect = blk: {
                var bar_rect = rect;
                bar_rect.height = 20;
                break :blk bar_rect;
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
        pub fn get(self: Colors) struct { Color, Color, Color, Color } {
            return .{ self.background, self.bar, self.border, self.text };
        }
    };
};

pub const GroupBox = struct {
    rect: Rect,
    title: ?[:0]const u8,

    pub fn draw(self: GroupBox) void {
        self.drawWithOptions(default_groupbox_options);
    }

    pub fn drawWithOptions(self: GroupBox, options: GroupBoxOptions) void {
        const rect = self.rect.rlRect();
        const left_edge: rl.Rectangle = .{
            .x = rect.x,
            .y = rect.y,
            .width = options.border_thickness,
            .height = rect.height,
        };
        const right_edge: rl.Rectangle = .{
            .x = rect.x + rect.width - options.border_thickness,
            .y = rect.y,
            .width = options.border_thickness,
            .height = rect.height,
        };
        const bottom_edge: rl.Rectangle = .{
            .x = rect.x + options.border_thickness,
            .y = rect.y + rect.height - options.border_thickness,
            .width = rect.width - 2 * options.border_thickness,
            .height = options.border_thickness,
        };
        const top_edge: rl.Rectangle = .{
            .x = rect.x + options.border_thickness,
            .y = rect.y,
            .width = rect.width - 2 * options.border_thickness,
            .height = options.border_thickness,
        };

        rl.drawRectangleRec(left_edge, options.colors.border);
        rl.drawRectangleRec(right_edge, options.colors.border);
        rl.drawRectangleRec(bottom_edge, options.colors.border);

        if (self.title) |title| {
            const text_x = rect.x + options.border_thickness + 10;
            const text_y = rect.y + (options.border_thickness - @as(f32, @floatFromInt(options.font_size))) / 2;
            const top_left_edge = blk: {
                var top_left_edge = top_edge;
                top_left_edge.width = 5;
                break :blk top_left_edge;
            };
            const top_right_edge = blk: {
                var top_right_edge = top_edge;
                const text_width = rl.measureText(title, options.font_size);
                top_right_edge.x += @floatFromInt(10 + text_width + 5);
                top_right_edge.width -= @floatFromInt(10 + text_width + 5);
                break :blk top_right_edge;
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
        pub fn get(self: Colors) struct { Color, Color } {
            return .{ self.border, self.text };
        }
    };
};
