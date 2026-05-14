const std = @import("std");
const math = std.math;
const fmt = std.fmt;
const ascii = std.ascii;

const parseInt = @import("num_parse").parseInt;
const FormatInt = @import("num_format").FormatInt;

const gui = @import("qw_gui");
const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");
const buttons = @import("buttons.zig");

pub fn drawTextInput(
    options: InputFieldOptions,
    rect: b.Rect,
    interaction: g.InteractionInfo,
    forced_style: ?gui.State,
    buffer: []u8,
    text_len: *usize,
    editing: *bool,
    return_on_change: bool,
) ?[]u8 {
    const text = buffer[0..text_len.*];
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color, const cursor_color =
        if (forced_style) |s| switch (s) {
            .default => options.inactive_colors.get(),
            .hovered => options.hovered_colors.get(),
            .held => options.held_colors.get(),
            .disabled => options.disabled_colors.get(),
        } else if (editing.* or holding.currently and hovering.currently)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rect.draw(bg_color);
    rect.drawOutline(border_color, options.border_thickness);

    var result: ?[]u8 = null;
    if (!editing.* and holding == g.HoldInfo.grabbed) {
        editing.* = true;
    }

    const text_rect: b.Rect = .{
        .x = rect.x + options.border_thickness + options.padding,
        .y = rect.y + options.border_thickness + options.padding,
        .width = rect.width - 2 * (options.border_thickness + options.padding),
        .height = rect.height - 2 * (options.border_thickness + options.padding),
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
        const cursor_rect: b.Rect = .{
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

/// A single-line text input field.
pub const TextInput = struct {
    data: *TextInput.Data,
    id: []const u8,

    /// Returns new string. If `return_on_change` is `true`, returns every frame when
    /// the string changes, otherwise returns only when editing finishes. A string will
    /// always be returned when editing finishes unless the editing is canceled.
    ///
    /// If the editing is canceled, the new value will not be returned, but **will** be
    /// saved in `.data`.
    pub fn draw(self: TextInput, rect: b.Rect, return_on_change: bool) ?[]u8 {
        return self.drawWithOptions(rect, return_on_change, default_input_field_options);
    }

    pub fn drawWithOptions(self: TextInput, rect: b.Rect, return_on_change: bool, options: InputFieldOptions) ?[]u8 {
        return drawTextInput(
            options,
            rect,
            self.grab(rect),
            null,
            self.data.buffer,
            &self.data.text_len,
            &self.data.editing,
            return_on_change,
        );
    }

    pub fn grab(self: TextInput, rect: b.Rect) g.InteractionInfo {
        if (rect.containsPoint(b.getMousePosition())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
    }

    pub const Data = struct {
        buffer: []u8,
        text_len: usize = 0,
        editing: bool = false,
    };
};

/// An input field for a numeric value.
pub fn ValueInput(T: type) type {
    return struct {
        data: *ValueInput(T).Data,
        id: []const u8,

        /// Returns new value. If `return_on_change` is `true`, returns every frame when the
        /// value changes, otherwise returns only when editing finishes. A value will always
        /// be returned when editing finishes, unless parsing the value fails or the editing
        /// is canceled.
        ///
        /// If parsing the value fails, or the editing is canceled, the value stored in
        /// `.data` will not change. If this happens, and `return_on_change` was `true`, the
        /// last value returned by this function most likely won't be what is ultimately
        /// saved in `.data`.
        pub fn draw(self: ValueInput(T), rect: b.Rect, return_on_change: bool) ?T {
            return self.drawWithOptions(return_on_change, rect, default_input_field_options);
        }

        pub fn drawWithOptions(self: ValueInput(T), rect: b.Rect, return_on_change: bool, options: InputFieldOptions) ?T {
            const ii = self.grab(rect);
            // When editing starts
            if (!self.data.editing and ii.@"0" == g.HoldInfo.grabbed) {
                const num_str = fmt.bufPrint(self.data.buffer, "{d}", .{self.data.value}) catch {
                    unreachable; // TODO: handle failure
                };
                self.data.text_len = num_str.len;
            }
            if (!self.data.editing and self.data.text_len == 0) {
                const num_str = fmt.bufPrint(self.data.buffer, "{f}", .{FormatInt(self.data.value, .{})}) catch {
                    unreachable; // TODO: handle failure
                };
                self.data.text_len = num_str.len;
            }

            const prev_editing = self.data.editing;
            const new_text = drawTextInput(
                options,
                rect,
                ii,
                null,
                self.data.buffer,
                &self.data.text_len,
                &self.data.editing,
                return_on_change,
            );

            var result: ?T = null;

            const editing_finished = prev_editing and !self.data.editing;
            if (new_text) |str| {
                const new_number: ?T = parseInt(T, str) catch |err| switch (err) {
                    error.Overflow => self.data.max,
                    error.Underflow => self.data.min,
                    error.NoNumber => if (str.len == 0) 0 else null,
                    else => null,
                };
                if (editing_finished) {
                    if (new_number) |num| {
                        self.data.value = math.clamp(num, self.data.min, self.data.max);
                        result = self.data.value;
                    }
                    const num_str = fmt.bufPrint(self.data.buffer, "{f}", .{FormatInt(self.data.value, .{})}) catch {
                        unreachable; // TODO: handle failure
                    };
                    self.data.text_len = num_str.len;
                    return result;
                } else {
                    if (new_number) |num| {
                        result = math.clamp(num, self.data.min, self.data.max);
                    }
                }
            }

            if (editing_finished) {
                const num_str = fmt.bufPrint(self.data.buffer, "{f}", .{FormatInt(self.data.value, .{})}) catch {
                    unreachable; // TODO: handle failure
                };
                self.data.text_len = num_str.len;
            }

            return result;
        }

        pub fn grab(self: ValueInput(T), rect: b.Rect) g.InteractionInfo {
            if (rect.containsPoint(b.getMousePosition())) {
                g.hoverElement(self.id);
                g.grabElement(self.id);
            }
            return g.getInteractionInfo(self.id);
        }

        pub const Data = struct {
            value: T,
            min: T = math.minInt(T),
            max: T = math.maxInt(T),
            buffer: []u8,
            text_len: usize = 0,
            editing: bool = false,
        };
    };
}

/// An input field for a numeric value with buttons for incrementing and
/// decrementing the value on the sides.
pub fn ValueInputWithButtons(T: type) type {
    return struct {
        data: *ValueInputWithButtons(T).Data,
        id: []const u8,

        /// Returns new value. If `return_on_change` is `true`, returns every frame when the
        /// value changes, otherwise returns only when editing finishes. A value will always
        /// be returned when editing finishes, unless parsing the value fails or the editing
        /// is canceled. A value will always be returned when a button is pressed.
        ///
        /// If parsing the value fails, or the editing is canceled, the value stored in
        /// `.data` will not change. If this happens, and `return_on_change` was `true`, the
        /// last value returned by this function most likely won't be what is ultimately
        /// saved in `.data`
        pub fn draw(self: ValueInputWithButtons(T), rect: b.Rect, return_on_change: bool) ?T {
            return self.drawWithOptions(rect, return_on_change, default_input_field_options, buttons.default_button_options);
        }

        pub fn drawWithOptions(self: ValueInputWithButtons(T), rect: b.Rect, return_on_change: bool, input_options: InputFieldOptions, button_options: buttons.ButtonOptions) ?T {
            const not_interacting: g.InteractionInfo = .{
                .{ .currently = false, .previously = false },
                .{ .currently = false, .previously = false },
                false,
            };
            const lbutton_rect, const text_rect, const rbutton_rect = rects(rect);
            const ii = self.grab(rect);
            const lbutton_ii = if (lbutton_rect.containsPoint(b.getMousePosition())) ii else not_interacting;
            const text_ii = if (text_rect.containsPoint(b.getMousePosition())) ii else not_interacting;
            const rbutton_ii = if (rbutton_rect.containsPoint(b.getMousePosition())) ii else not_interacting;

            // When editing starts
            if (!self.data.editing and text_ii.@"0" == g.HoldInfo.grabbed) {
                self.updateText(true);
            }
            if (!self.data.editing and self.data.text_len == 0) {
                self.updateText(false);
            }

            const prev_editing = self.data.editing;
            const new_text = drawTextInput(
                input_options,
                text_rect,
                text_ii,
                null,
                self.data.buffer,
                &self.data.text_len,
                &self.data.editing,
                return_on_change,
            );

            var result: ?T = null;
            if (buttons.drawButton(button_options, lbutton_rect, lbutton_ii, null, "-")) {
                const new_val = self.data.value -| self.data.button_step;
                self.data.value = math.clamp(new_val, self.data.min, self.data.max);
                result = self.data.value;
                self.updateText(false);
            }
            if (buttons.drawButton(button_options, rbutton_rect, rbutton_ii, null, "+")) {
                const new_val = self.data.value +| self.data.button_step;
                self.data.value = math.clamp(new_val, self.data.min, self.data.max);
                result = self.data.value;
                self.updateText(false);
            }

            const editing_finished = prev_editing and !self.data.editing;
            if (new_text) |str| {
                const new_number: ?T = parseInt(T, str) catch |err| switch (err) {
                    error.Overflow => self.data.max,
                    error.Underflow => self.data.min,
                    error.NoNumber => if (str.len == 0) 0 else null,
                    else => null,
                };
                if (editing_finished) {
                    if (new_number) |num| {
                        self.data.value = math.clamp(num, self.data.min, self.data.max);
                        result = self.data.value;
                    }
                    self.updateText(false);
                    return result;
                } else {
                    if (new_number) |num| {
                        result = math.clamp(num, self.data.min, self.data.max);
                    }
                }
            }

            if (editing_finished) {
                self.updateText(false);
            }

            return result;
        }

        pub fn grab(self: ValueInputWithButtons(T), rect: b.Rect) g.InteractionInfo {
            if (rect.containsPoint(b.getMousePosition())) {
                g.hoverElement(self.id);
                g.grabElement(self.id);
            }
            return g.getInteractionInfo(self.id);
        }

        fn updateText(self: ValueInputWithButtons(T), editing: bool) void {
            if (editing) {
                const num_str = fmt.bufPrint(self.data.buffer, "{d}", .{self.data.value}) catch {
                    unreachable; // TODO: handle failure
                };
                self.data.text_len = num_str.len;
            } else {
                const num_str = fmt.bufPrint(self.data.buffer, "{f}", .{FormatInt(self.data.value, .{})}) catch {
                    unreachable; // TODO: handle failure
                };
                self.data.text_len = num_str.len;
            }
        }

        fn rects(rect: b.Rect) struct { b.Rect, b.Rect, b.Rect } {
            const padding = 1;
            const lbutton_rect = rect.subrect(.{
                .x = .{ .left = 0 },
                .y = .{ .top = 0 },
                .width = .{ .amount = rect.height },
                .height = .max,
            });
            const text_rect = rect.subrect(.{
                .x = .{ .middle = 0 },
                .y = .{ .top = 0 },
                .width = .{ .relative = -(rect.height + padding) * 2 },
                .height = .max,
            });
            const rbutton_rect = rect.subrect(.{
                .x = .{ .right = 0 },
                .y = .{ .top = 0 },
                .width = .{ .amount = rect.height },
                .height = .max,
            });
            return .{ lbutton_rect, text_rect, rbutton_rect };
        }

        pub const Data = struct {
            value: T,
            min: T = math.minInt(T),
            max: T = math.maxInt(T),
            button_step: T = 1,
            buffer: []u8,
            text_len: usize = 0,
            editing: bool = false,
        };
    };
}

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
    disabled_colors: Colors = .colors(.lighter_gray, .light_gray, .light_gray, .light_gray),

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
