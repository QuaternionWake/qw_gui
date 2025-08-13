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
