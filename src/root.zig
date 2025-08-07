const std = @import("std");

const rl = @import("raylib");

pub const Button = struct {
    rect: rl.Rectangle,
    text: [:0]const u8,

    const font_size = 10;
    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        rl.drawRectangleRec(self.rect, .light_gray);
        rl.drawRectangleLinesEx(self.rect, 5, .gray);
        const text_width = rl.measureText(self.text, font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(font_size))) / 2,
        };
        rl.drawText(self.text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), font_size, .dark_gray);
        return rl.isMouseButtonReleased(.left) and rl.checkCollisionPointRec(rl.getMousePosition(), self.rect);
    }
};
