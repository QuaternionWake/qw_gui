const std = @import("std");
const math = std.math;
const fmt = std.fmt;
const ascii = std.ascii;

const rl = @import("raylib");
const Color = rl.Color;
const Key = rl.KeyboardKey;

const parsing = @import("utils").parsing;
const g = @import("grabbing");
const Rect = @import("Rect");

pub fn ValueInput(T: type) type {
    const signed = @typeInfo(T).int.signedness == .signed;
    return struct {
        rect: Rect,
        data: *ValueInput(T).Data,

        /// Returns new value. If `return_on_change` is true, returns every frame
        /// when the value changes, otherwise returns only when editing finishes.
        /// A value will always be returned when editing finishes.
        ///
        /// If parsing the value fails, or the editing is canceled, the value stored
        /// in .data will not change.
        /// If this happens, the last value returned by this function most likely
        /// won't be what is ultimately saved in .data
        pub fn draw(self: ValueInput(T), return_on_change: bool) ?T {
            return self.drawWithOptions(return_on_change, default_input_field_options);
        }

        pub fn drawWithOptions(self: ValueInput(T), return_on_change: bool, options: InputFieldOptions) ?T {
            const rect = self.rect.rlRect();
            self.grab();
            var fallback_text = "number too big".*;
            const bg_color, const border_color, const text_color, const cursor_color = if (self.data.editing or g.holding(self.id()) and g.hovering(self.id()))
                options.held_colors.get()
            else if (g.canGrab(self.id()) and g.hovering(self.id()))
                options.hovered_colors.get()
            else
                options.inactive_colors.get();
            rl.drawRectangleRec(rect, bg_color);
            rl.drawRectangleLinesEx(rect, options.border_thickness, border_color);

            if (!self.data.editing and g.holding(self.id()) and g.hovering(self.id()) and rl.isMouseButtonReleased(.left)) {
                self.data.editing = true;
                self.data.text = fmt.bufPrintZ(&self.data.buffer, "{d}", .{self.data.value}) catch &fallback_text;
            }

            const text_rect: rl.Rectangle = .{
                .x = rect.x + options.border_thickness + options.padding,
                .y = rect.y + options.border_thickness + options.padding,
                .width = rect.width - 2 * (options.border_thickness + options.padding),
                .height = rect.height - 2 * (options.border_thickness + options.padding),
            };
            const font_size: i32 = @intFromFloat(text_rect.height);
            const max_text_width = text_rect.width;
            var result: ?T = null;
            if (self.data.editing) editing: {
                // TODO: support for moving the cursor
                const text_start, const text_width = blk: {
                    for (0..self.data.text.len) |l| {
                        const text_width: f32 = @floatFromInt(rl.measureText(self.data.text[l..], font_size));
                        if (text_width + options.cursor_width <= max_text_width) break :blk .{ l, text_width + options.cursor_width };
                    }
                    break :blk .{ self.data.text.len, options.cursor_width };
                };
                const text = self.data.text[text_start..];
                const text_x = text_rect.x + (text_rect.width - text_width) / 2;
                const text_y = text_rect.y;
                rl.drawText(text, @intFromFloat(text_x), @intFromFloat(text_y), font_size, text_color);
                const cursor_rect: rl.Rectangle = .{
                    .x = text_x + text_width,
                    .y = text_y,
                    .width = options.cursor_width,
                    .height = @floatFromInt(font_size),
                };
                rl.drawRectangleRec(cursor_rect, cursor_color);

                if (!g.hovering(self.id()) and rl.isMouseButtonPressed(.left)) {
                    self.data.editing = false;
                    const val = parsing.parseInt(T, self.data.text) catch |err| blk: {
                        if (err == error.Overflow) {
                            break :blk if (self.data.text[0] == '-') self.data.min else self.data.max;
                        } else break :editing;
                    };
                    self.data.value = math.clamp(val, self.data.min, self.data.max);
                    result = self.data.value;
                    break :editing;
                }

                if (rl.isKeyPressed(.enter) or rl.isKeyPressed(.kp_enter)) {
                    self.data.editing = false;
                    const val = parsing.parseInt(T, self.data.text) catch |err| blk: {
                        if (err == error.Overflow) {
                            break :blk if (self.data.text[0] == '-') self.data.min else self.data.max;
                        } else break :editing;
                    };
                    self.data.value = math.clamp(val, self.data.min, self.data.max);
                    result = self.data.value;
                    break :editing;
                }

                if (rl.isKeyPressed(.escape)) {
                    self.data.editing = false;
                    break :editing;
                }

                if (rl.isKeyPressed(.backspace) and (rl.isKeyDown(.left_control) or rl.isKeyDown(.right_control))) {
                    self.data.buffer[0] = 0;
                    self.data.text.len = 0;
                    break :editing;
                }

                if (rl.isKeyPressed(.backspace) and self.data.text.len > 0) {
                    self.data.buffer[self.data.text.len - 1] = 0;
                    self.data.text.len -= 1;
                    break :editing;
                }

                if (self.data.text.len + 1 < self.data.buffer.len) {
                    const char = rl.getCharPressed();
                    switch (char) {
                        'a'...'z', 'A'...'Z', '0'...'9', '.' => {},
                        '+' => if (self.data.text.len != 0) break :editing,
                        '-' => if (self.data.text.len != 0 or !signed) break :editing,
                        else => break :editing,
                    }

                    self.data.buffer[self.data.text.len] = @intCast(char);
                    self.data.buffer[self.data.text.len + 1] = 0;
                    self.data.text.len += 1;

                    if (return_on_change) {
                        const val = parsing.parseInt(T, self.data.text) catch |err| blk: {
                            if (err == error.Overflow) {
                                break :blk if (self.data.text[0] == '-') self.data.min else self.data.max;
                            } else break :editing;
                        };
                        result = math.clamp(val, self.data.min, self.data.max);
                        break :editing;
                    }
                }
            } else {
                const text, const text_width = blk: {
                    var value = self.data.value;
                    var text: [:0]const u8 = undefined;
                    var text_width: f32 = undefined;
                    var rounding: i8 = 0;
                    const suffixes = [_][]const u8{ "", "k", "M", "B", "T", "Qa", "Qi" };
                    for (suffixes) |suffix| {
                        const rounded_value = switch (rounding) {
                            0 => value,
                            1 => value + 1,
                            -1 => value - 1,
                            else => unreachable,
                        };
                        text = fmt.bufPrintZ(&self.data.buffer, "{d}{s}", .{ rounded_value, suffix }) catch {
                            rounding = if (@rem(value, 1000) < 500) 0 else if (value < 0) -1 else 1;
                            value = @divTrunc(value, 1000);
                            continue;
                        };
                        text_width = @floatFromInt(rl.measureText(text, font_size));
                        if (text_width < max_text_width) break;
                        rounding = if (@rem(value, 1000) < 500) 0 else if (value < 0) -1 else 1;
                        value = @divTrunc(value, 1000);
                    } else {
                        text = &fallback_text;
                        text_width = @floatFromInt(rl.measureText(text, font_size));
                    }
                    break :blk .{ text, text_width };
                };
                const text_x = text_rect.x + (text_rect.width - text_width) / 2;
                const text_y = text_rect.y;
                rl.drawText(text, @intFromFloat(text_x), @intFromFloat(text_y), font_size, text_color);
            }

            return result;
        }

        pub fn grab(self: ValueInput(T)) void {
            if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect.rlRect())) {
                g.hoverElement(self.id());
                g.grabElement(self.id());
            }
        }

        fn id(self: ValueInput(T)) g.ElementID {
            // TODO: using the data pointer here is bad when data struct is shared
            return .{ .inner = @intFromPtr(self.data) };
        }

        pub const Data = struct {
            value: T,
            min: T = math.minInt(T),
            max: T = math.maxInt(T),
            text: [:0]u8 = undefined,
            buffer: [128]u8 = undefined,
            editing: bool = false,
        };
    };
}

pub var default_input_field_options: InputFieldOptions = .{};

pub const InputFieldOptions = struct {
    border_thickness: f32 = 1,
    padding: f32 = 2,
    cursor_width: f32 = 3,
    inactive_colors: Colors = .colors(.white, .gray, .gray, .blue),
    hovered_colors: Colors = .colors(.white, .blue, .gray, .blue),
    held_colors: Colors = .colors(.init(0, 230, 255, 255), .blue, .gray, .blue),

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
