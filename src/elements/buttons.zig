const gui = @import("qw_gui");
const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");

pub fn drawButton(
    options: ButtonOptions,
    rect: b.Rect,
    interaction: g.InteractionInfo,
    forced_style: ?gui.State,
    text: []const u8,
) bool {
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color =
        if (forced_style) |s| switch (s) {
            .default => options.inactive_colors.get(),
            .hovered => options.hovered_colors.get(),
            .held => options.held_colors.get(),
            .disabled => options.disabled_colors.get(),
        } else if (holding.currently and hovering.currently)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rect.draw(bg_color);
    rect.drawOutline(border_color, options.border_thickness);

    const text_size = b.measureText(options.text_options, text);
    const text_pos: b.Vec2 = .{
        .x = rect.x + (rect.width - text_size.x) / 2,
        .y = rect.y + (rect.height - text_size.y) / 2,
    };
    b.drawText(options.text_options, text, text_pos, text_color);

    return hovering.currently and holding == g.HoldInfo.released;
}

/// A button that returns true on click.
pub const Button = struct {
    text: []const u8,
    id: []const u8,

    /// Returns `true` when clicked.
    pub fn draw(self: Button, rect: b.Rect) bool {
        return self.drawWithOptions(rect, default_button_options);
    }

    pub fn drawWithOptions(self: Button, rect: b.Rect, options: ButtonOptions) bool {
        return drawButton(
            options,
            rect,
            self.grab(rect),
            null,
            self.text,
        );
    }

    pub fn grab(self: Button, rect: b.Rect) g.InteractionInfo {
        if (rect.containsPoint(b.getMousePosition())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
    }
};

/// A button that executes a function on click.
pub fn FnButton(Fn: type) type {
    return struct {
        text: []const u8,
        func: *const Fn,
        id: []const u8,

        const FuncReturnType = @typeInfo(Fn).@"fn".return_type.?;
        const ReturnType = if (FuncReturnType == void) void else ?FuncReturnType;

        /// Executes `func` when clicked.
        /// If func has a non-`void` return type, returns its return value.
        pub fn draw(self: FnButton(Fn), rect: b.Rect, args: anytype) ReturnType {
            return self.drawWithOptions(rect, default_button_options, args);
        }

        pub fn drawWithOptions(self: FnButton(Fn), rect: b.Rect, options: ButtonOptions, args: anytype) ReturnType {
            if (drawButton(
                options,
                rect,
                self.grab(rect),
                null,
                self.text,
            )) {
                return @call(.auto, self.func, args);
            }
            if (ReturnType != void) return null;
        }

        pub fn grab(self: FnButton(Fn), rect: b.Rect) g.InteractionInfo {
            if (rect.containsPoint(b.getMousePosition())) {
                g.hoverElement(self.id);
                g.grabElement(self.id);
            }
            return g.getInteractionInfo(self.id);
        }
    };
}

/// A button that con be toggled on or off.
pub const ToggleButton = struct {
    text: []const u8,
    data: *ToggleButton.Data,
    id: []const u8,

    /// Returns new state when clicked.
    pub fn draw(self: ToggleButton, rect: b.Rect) ?bool {
        return self.drawWithOptions(rect, default_button_options);
    }

    pub fn drawWithOptions(self: ToggleButton, rect: b.Rect, options: ButtonOptions) ?bool {
        const ii = self.grab(rect);
        const state: ?gui.State =
            if (self.data.pressed or (ii.@"0".holdingAny()) and ii.@"1".currently)
                .held
            else
                null;
        if (drawButton(
            options,
            rect,
            ii,
            state,
            self.text,
        )) {
            self.data.pressed = !self.data.pressed;
            return self.data.pressed;
        }
        return null;
    }

    pub fn grab(self: ToggleButton, rect: b.Rect) g.InteractionInfo {
        if (rect.containsPoint(b.getMousePosition())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
    }

    pub const Data = struct {
        pressed: bool = false,
    };
};

pub var default_button_options: ButtonOptions = .{};

pub const ButtonOptions = struct {
    text_options: b.TextOptions = .{},
    border_thickness: f32 = 2,
    inactive_colors: Colors = .colors(.light_gray, .gray, .gray),
    hovered_colors: Colors = .colors(.light_cyan, .dark_cyan, .dark_cyan),
    held_colors: Colors = .colors(.cyan, .darker_cyan, .darker_cyan),
    disabled_colors: Colors = .colors(.lighter_gray, .light_gray, .light_gray),

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
