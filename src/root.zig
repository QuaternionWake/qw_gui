const std = @import("std");

const rl = @import("raylib");
const Color = rl.Color;

pub const Button = struct {
    rect: rl.Rectangle,
    text: [:0]const u8,

    const font_size = 10;
    const default_colors = .{ Color.light_gray, Color.gray };
    const hovered_colors = .{ Color.sky_blue, Color.blue };
    const held_colors = .{ Color.blue, Color.dark_blue };
    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        const hovering = rl.checkCollisionPointRec(rl.getMousePosition(), self.rect);
        const holding = rl.isMouseButtonDown(.left);
        const primary_color, const secondary_color = if (holding and hovering)
            held_colors
        else if (hovering)
            hovered_colors
        else
            default_colors;
        rl.drawRectangleRec(self.rect, primary_color);
        rl.drawRectangleLinesEx(self.rect, 5, secondary_color);
        const text_width = rl.measureText(self.text, font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(font_size))) / 2,
        };
        rl.drawText(self.text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), font_size, secondary_color);
        return rl.isMouseButtonReleased(.left) and hovering;
    }
};
