const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");
const Rect = @import("Rect");

pub fn drawButton(
    options: ButtonOptions,
    rect: Rect,
    interaction: g.InteractionInfo,
    text: []const u8,
) bool {
    const rect_ = rect.vanillaRect();
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color =
        if (holding.currently and hovering.currently)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rect_.draw(bg_color);
    rect_.drawOutline(border_color, options.border_thickness);

    const text_size = b.measureText(options.text_options, text);
    const text_pos: b.Vec2 = .{
        .x = rect_.x + (rect_.width - text_size.x) / 2,
        .y = rect_.y + (rect_.height - text_size.y) / 2,
    };
    b.drawText(options.text_options, text, text_pos, text_color);

    return hovering.currently and holding == g.HoldInfo.released;
}

/// A button that returns true on click.
pub const Button = struct {
    rect: Rect,
    text: []const u8,
    id: []const u8,

    /// Returns `true` when clicked.
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
        if (self.rect.vanillaRect().containsPoint(b.getMousePosition())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
    }
};

/// A button that executes a function on click.
pub fn FnButton(Fn: type) type {
    return struct {
        rect: Rect,
        text: []const u8,
        func: *const Fn,
        id: []const u8,

        const FuncReturnType = @typeInfo(Fn).@"fn".return_type.?;
        const ReturnType = if (FuncReturnType == void) void else ?FuncReturnType;

        /// Executes `func` when clicked.
        /// If func has a non-`void` return type, returns its return value.
        pub fn draw(self: FnButton(Fn), args: anytype) ReturnType {
            return self.drawWithOptions(default_button_options, args);
        }

        pub fn drawWithOptions(self: FnButton(Fn), options: ButtonOptions, args: anytype) ReturnType {
            if (drawButton(
                options,
                self.rect,
                self.grab(),
                self.text,
            )) {
                return @call(.auto, self.func, args);
            }
            if (ReturnType != void) return null;
        }

        pub fn grab(self: FnButton(Fn)) g.InteractionInfo {
            if (self.rect.vanillaRect().containsPoint(b.getMousePosition())) {
                g.hoverElement(self.id);
                g.grabElement(self.id);
            }
            return g.getInteractionInfo(self.id);
        }
    };
}

pub var default_button_options: ButtonOptions = .{};

pub const ButtonOptions = struct {
    text_options: b.TextOptions = .{},
    border_thickness: f32 = 2,
    inactive_colors: Colors = .colors(.light_gray, .gray, .gray),
    hovered_colors: Colors = .colors(.light_cyan, .dark_cyan, .dark_cyan),
    held_colors: Colors = .colors(.cyan, .darker_cyan, .darker_cyan),

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
