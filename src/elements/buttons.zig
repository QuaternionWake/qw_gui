const rl = @import("raylib");
const Color = rl.Color;

const g = @import("grabbing");
const Rect = @import("Rect");

pub fn drawButton(
    options: ButtonOptions,
    rect: Rect,
    interaction: g.InteractionInfo,
    text: [:0]const u8,
) bool {
    const rl_rect = rect.rlRect();
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color =
        if (holding.currently and hovering.currently)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rl.drawRectangleRec(rl_rect, bg_color);
    rl.drawRectangleLinesEx(rl_rect, options.border_thickness, border_color);

    const text_width = rl.measureText(text, options.font_size);
    const text_pos: rl.Vector2 = .{
        .x = rl_rect.x + (rl_rect.width - @as(f32, @floatFromInt(text_width))) / 2,
        .y = rl_rect.y + (rl_rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
    };
    rl.drawText(text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, text_color);

    return hovering.currently and holding == g.HoldInfo.released;
}

pub const Button = struct {
    rect: Rect,
    text: [:0]const u8,
    id: []const u8,

    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        return self.drawWithOptions(default_button_options);
    }

    pub fn drawWithOptions(self: Button, options: ButtonOptions) bool {
        return drawButton(
            options,
            self.rect,
            self.grab(),
            self.text,
        );
    }

    pub fn grab(self: Button) g.InteractionInfo {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect.rlRect())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
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
