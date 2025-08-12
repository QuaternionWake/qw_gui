const rl = @import("raylib");
const Color = rl.Color;

// TODO: fix this awfulness v
const root = @import("../root.zig");
const g = root.grabbing;

pub const Button = struct {
    rect: rl.Rectangle,
    text: [:0]const u8,

    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        return self.drawWithOptions(default_button_options);
    }

    pub fn drawWithOptions(self: Button, options: ButtonOptions) bool {
        self.grab();
        const bg_color, const border_color, const text_color = if (g.holding(self.id()) and g.hovering(self.id()))
            options.held_colors.get()
        else if (g.canGrab(self.id()) and g.hovering(self.id()))
            options.hovered_colors.get()
        else
            options.inactive_colors.get();
        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, options.border_thickness, border_color);
        const text_width = rl.measureText(self.text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(self.text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, text_color);
        return g.holding(self.id()) and g.hovering(self.id()) and rl.isMouseButtonReleased(.left);
    }

    pub fn grab(self: Button) void {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect)) {
            g.hoverElement(self.id());
            g.grabElement(self.id());
        }
    }

    fn id(self: Button) g.ElementID {
        return .{ .rect = self.rect, .data = null };
    }
};

pub var default_button_options: ButtonOptions = .{};

pub const ButtonOptions = struct {
    font_size: i32 = 10, // TODO: Consider changing this to u32
    border_thickness: f32 = 5,
    inactive_colors: Colors = .colors(.light_gray, .gray, .gray),
    hovered_colors: Colors = .colors(.sky_blue, .blue, .blue),
    held_colors: Colors = .colors(.blue, .dark_blue, .dark_blue),

    const Colors = struct {
        background: Color,
        border: Color,
        text: Color,

        pub fn colors(background: Color, border: Color, text: Color) Colors {
            return .{ .background = background, .border = border, .text = text };
        }
        pub fn get(self: Colors) struct { Color, Color, Color } {
            return .{ self.background, self.border, self.text };
        }
    };
};
