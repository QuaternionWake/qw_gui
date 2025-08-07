const std = @import("std");

const rl = @import("raylib");
const Color = rl.Color;

pub const Button = struct {
    rect: rl.Rectangle,
    text: [:0]const u8,

    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        return self.drawWithOptions(defaultButtonOptions);
    }

    pub fn drawWithOptions(self: Button, options: ButtonOptions) bool {
        const hovering = rl.checkCollisionPointRec(rl.getMousePosition(), self.rect);
        const holding = rl.isMouseButtonDown(.left);
        const primary_color, const secondary_color = if (holding and hovering)
            options.held_colors
        else if (hovering)
            options.hovered_colors
        else
            options.default_colors;
        rl.drawRectangleRec(self.rect, primary_color);
        rl.drawRectangleLinesEx(self.rect, 5, secondary_color);
        const text_width = rl.measureText(self.text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(self.text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, secondary_color);
        return rl.isMouseButtonReleased(.left) and hovering;
    }
};

pub var defaultButtonOptions: ButtonOptions = .{};

pub const ButtonOptions = struct {
    font_size: i32 = 10, // TODO: Consider changing this to u32
    default_colors: Colors = .{ .light_gray, .gray },
    hovered_colors: Colors = .{ .sky_blue, .blue },
    held_colors: Colors = .{ .blue, .dark_blue },

    const Colors = struct { Color, Color };
};
