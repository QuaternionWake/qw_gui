const std = @import("std");
const math = std.math;
const fmt = std.fmt;
const ascii = std.ascii;

const parsing = @import("utils").parsing;
const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");
const Rect = @import("Rect");

pub fn drawTextInput(
    options: InputFieldOptions,
    rect: Rect,
    interaction: g.InteractionInfo,
    buffer: []u8,
    text_len: *usize,
    editing: *bool,
    return_on_change: bool,
) ?[]u8 {
    const text = buffer[0..text_len.*];
    const rect_ = rect.vanillaRect();
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color, const cursor_color =
        if (editing.* or holding.currently and hovering.currently)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rect_.draw(bg_color);
    rect_.drawOutline(border_color, options.border_thickness);

    var result: ?[]u8 = null;
    if (!editing.* and holding == g.HoldInfo.grabbed) {
        editing.* = true;
    }

    const text_rect: b.Rectangle = .{
        .x = rect_.x + options.border_thickness + options.padding,
        .y = rect_.y + options.border_thickness + options.padding,
        .width = rect_.width - 2 * (options.border_thickness + options.padding),
        .height = rect_.height - 2 * (options.border_thickness + options.padding),
    };
    const max_text_width = text_rect.width;
    const text_options = blk: {
        var o = options.text_options;
        o.size = text_rect.height;
        break :blk o;
    };
    if (editing.*) editing: {
        // TODO: support for moving the cursor
        const max_text_width_ = max_text_width - options.cursor_width - options.cursor_padding;
        const substring, const text_width = b.lastLongestFittingSubstring(text_options, text, max_text_width_);
        const text_pos: b.Vec2 = .{
            .x = text_rect.x + (text_rect.width - text_width - options.cursor_width - options.cursor_padding) / 2,
            .y = text_rect.y,
        };
        b.drawText(text_options, substring, text_pos, text_color);
        const cursor_rect: b.Rectangle = .{
            .x = text_pos.x + text_width + options.cursor_padding,
            .y = text_pos.y,
            .width = options.cursor_width,
            .height = text_options.size,
        };
        cursor_rect.draw(cursor_color);

        if (!hovering.currently and b.getMouseButtonState(.left) == b.MouseButtonState.clicked or b.getPseudoKeyState(.enter).isPressed()) {
            editing.* = false;
            result = text;
        }

        if (b.getKeyState(.escape).isPressed()) {
            editing.* = false;
            break :editing;
        }

        if (b.getKeyState(.backspace).isPressed() and b.getPseudoKeyState(.control).currently) {
            text_len.* = 0;
            if (return_on_change) {
                result = buffer[0..text_len.*];
            }
            break :editing;
        }

        if (b.getKeyState(.backspace).isPressed() and text.len > 0) {
            text_len.* -= 1;
            if (return_on_change) {
                result = buffer[0..text_len.*];
            }
            break :editing;
        }

        if (text_len.* + 1 < buffer.len) {
            const unicode_char = b.getCharPressed();
            const char: u8 = if (unicode_char < 255) @intCast(unicode_char) else break :editing;
            if (char != '\t' and !ascii.isPrint(char)) break :editing;

            buffer[text_len.*] = char;
            text_len.* += 1;

            if (return_on_change) {
                result = buffer[0..text_len.*];
                break :editing;
            }
        }
    } else {
        const substring, const text_width = b.longestFittingSubstring(text_options, text, max_text_width);
        const text_pos: b.Vec2 = .{
            .x = text_rect.x + (text_rect.width - text_width) / 2,
            .y = text_rect.y,
        };
        b.drawText(text_options, substring, text_pos, text_color);
    }

    return result;
}

pub const TextInput = struct {
    rect: Rect,
    data: *TextInput.Data,
    id: []const u8,

    pub fn draw(self: TextInput, return_on_change: bool) ?[]u8 {
        return self.drawWithOptions(return_on_change, default_input_field_options);
    }

    pub fn drawWithOptions(self: TextInput, return_on_change: bool, options: InputFieldOptions) ?[]u8 {
        return drawTextInput(
            options,
            self.rect,
            self.grab(),
            self.data.buffer,
            &self.data.text_len,
            &self.data.editing,
            return_on_change,
        );
    }

    pub fn grab(self: TextInput) g.InteractionInfo {
        if (self.rect.vanillaRect().containsPoint(b.getMousePosition())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
    }

    pub const Data = struct {
        buffer: []u8,
        text_len: usize,
        editing: bool,
    };
};

pub var default_input_field_options: InputFieldOptions = .{};

pub const InputFieldOptions = struct {
    text_options: b.TextOptions = .{},
    border_thickness: f32 = 1,
    padding: f32 = 2,
    cursor_width: f32 = 3,
    cursor_padding: f32 = 1,
    inactive_colors: Colors = .colors(.white, .gray, .gray, .gray),
    hovered_colors: Colors = .colors(.white, .cyan, .gray, .dark_cyan),
    held_colors: Colors = .colors(.lighter_cyan, .cyan, .gray, .dark_cyan),

    const Colors = struct {
        background: Color,
        border: Color,
        text: Color,
        cursor: Color,

        pub fn colors(background: Color, border: Color, text: Color, cursor: Color) Colors {
            return .{ .background = background, .border = border, .text = text, .cursor = cursor };
        }
        pub fn get(self: Colors) struct { Color, Color, Color, Color } {
            return .{ self.background, self.border, self.text, self.cursor };
        }
    };
};
