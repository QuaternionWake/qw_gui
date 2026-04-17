const std = @import("std");

const rl = @import("raylib");

const b = @import("../backend.zig");

pub fn drawRectangle(rectangle: b.Rectangle, color: b.Color) void {
    rl.drawRectangleRec(toRlRect(rectangle), toRlColor(color));
}

pub fn drawRectangleOutline(rectangle: b.Rectangle, color: b.Color, thickness: f32) void {
    rl.drawRectangleLinesEx(toRlRect(rectangle), thickness, toRlColor(color));
}

pub fn drawTriangle(triangle: b.Triangle, color: b.Color) void {
    rl.drawTriangle(toRlVec2(triangle.v1), toRlVec2(triangle.v2), toRlVec2(triangle.v3), toRlColor(color));
}

pub fn getWindowSize() b.Vec2 {
    return .{
        .x = @floatFromInt(rl.getRenderWidth()),
        .y = @floatFromInt(rl.getRenderHeight()),
    };
}

pub fn getMousePosition() b.Vec2 {
    const pos = rl.getMousePosition();
    return .{
        .x = pos.x,
        .y = pos.y,
    };
}

pub fn getMouseButtonState(button: b.MouseButton) b.MouseButtonState {
    const rl_button: rl.MouseButton = switch (button) {
        .left => .left,
        .right => .right,
        .middle => .middle,
    };
    const pressed = rl.isMouseButtonPressed(rl_button);
    const held = rl.isMouseButtonDown(rl_button);
    return .{
        .currently = held,
        .previously = !pressed and held or rl.isMouseButtonReleased(rl_button),
    };
}

pub fn getCharPressed() u21 {
    const rl_char = rl.getCharPressed();
    return std.math.cast(u21, rl_char) orelse 0;
}

pub fn getKeyState(key: b.KeyboardKey) b.KeyboardKeyState {
    const rl_key = toRlKey(key);
    const pressed = rl.isKeyPressed(rl_key);
    const held = rl.isKeyDown(rl_key);
    const repeat = rl.isKeyPressedRepeat(rl_key);
    return .{
        .currently = held,
        .previously = !pressed and held or rl.isKeyReleased(rl_key),
        .repeat = repeat,
    };
}

pub fn getPseudoKeyState(key: b.PseudoKeyboardKey) b.KeyboardKeyState {
    const rl_key_a: rl.KeyboardKey, const rl_key_b: rl.KeyboardKey = switch (key) {
        .shift => .{ .right_shift, .left_shift },
        .control => .{ .right_control, .left_control },
        .super => .{ .right_super, .left_super },
        .alt => .{ .right_alt, .left_alt },
        .enter => .{ .enter, .kp_enter },
    };
    const pressed = rl.isKeyPressed(rl_key_a) or rl.isKeyPressed(rl_key_b);
    const held = rl.isKeyDown(rl_key_a) or rl.isKeyDown(rl_key_b);
    const repeat = rl.isKeyPressedRepeat(rl_key_a) or rl.isKeyPressedRepeat(rl_key_b);
    return .{
        .currently = held,
        .previously = !pressed and held or rl.isKeyReleased(rl_key_a) or rl.isKeyReleased(rl_key_b),
        .repeat = repeat,
    };
}

pub const Font = rl.Font;

pub fn getDefaultFont() ?Font {
    return rl.getFontDefault() catch null;
}

pub fn drawText(options: b.TextOptions, text: []const u8, position: b.Vec2, color: b.Color) void {
    const rl_color = toRlColor(color);
    const font = options.font orelse rl.getFontDefault() catch unreachable; // TODO: handle failure better
    const scale_factor = options.size / @as(f32, @floatFromInt(font.baseSize));
    var char_pos = toRlVec2(position);

    // TODO: unicode
    for (text) |char| {
        if (char == '\n') {
            char_pos.x = position.x;
            char_pos.y += options.size + options.line_spacing;
        } else {
            const idx: usize = @intCast(rl.getGlyphIndex(font, char));
            rl.drawTextCodepoint(font, char, char_pos, options.size, rl_color);
            const char_width: f32 =
                if (font.glyphs[idx].advanceX == 0)
                    font.recs[idx].width
                else
                    @floatFromInt(font.glyphs[idx].advanceX);
            char_pos.x += char_width * scale_factor + options.character_spacing;
        }
    }
}

pub fn measureText(options: b.TextOptions, text: []const u8) b.Vec2 {
    const font = options.font orelse rl.getFontDefault() catch unreachable; // TODO: handle failure better
    const scale_factor = options.size / @as(f32, @floatFromInt(font.baseSize));
    var size: b.Vec2 = .{ .x = 0, .y = options.size };
    var row_width: f32 = 0;

    // TODO: unicode
    for (text) |char| {
        if (char == '\n') {
            row_width -= options.character_spacing;
            size.x = @max(size.x, row_width);
            row_width = 0;
            size.y += options.size + options.line_spacing;
        } else {
            const idx: usize = @intCast(rl.getGlyphIndex(font, char));
            const char_width: f32 =
                if (font.glyphs[idx].advanceX == 0)
                    font.recs[idx].width
                else
                    @floatFromInt(font.glyphs[idx].advanceX);
            row_width += char_width * scale_factor + options.character_spacing;
        }
    }
    row_width -= options.character_spacing;
    size.x = @max(size.x, row_width);

    return size;
}

pub fn longestFittingSubstring(options: b.TextOptions, text: []const u8, max_width: f32) struct { []const u8, f32 } {
    const font = options.font orelse rl.getFontDefault() catch unreachable; // TODO: handle failure better
    const scale_factor = options.size / @as(f32, @floatFromInt(font.baseSize));
    var width: f32 = 0;

    if (text.len != 0) {
        const idx: usize = @intCast(rl.getGlyphIndex(font, text[0]));
        const char_width: f32 =
            if (font.glyphs[idx].advanceX == 0)
                font.recs[idx].width
            else
                @floatFromInt(font.glyphs[idx].advanceX);
        width += char_width * scale_factor;
        if (width > max_width) {
            return .{ text[0..0], 0 };
        }
    } else return .{ text[0..0], 0 };

    // TODO: unicode
    for (text[1..], 1..) |char, i| {
        const idx: usize = @intCast(rl.getGlyphIndex(font, char));
        const char_width: f32 =
            if (font.glyphs[idx].advanceX == 0)
                font.recs[idx].width
            else
                @floatFromInt(font.glyphs[idx].advanceX);
        width += char_width * scale_factor + options.character_spacing;
        if (width > max_width) {
            return .{ text[0..i], width - char_width * scale_factor - options.character_spacing };
        }
    }

    return .{ text, width };
}

pub fn lastLongestFittingSubstring(options: b.TextOptions, text: []const u8, max_width: f32) struct { []const u8, f32 } {
    const font = options.font orelse rl.getFontDefault() catch unreachable; // TODO: handle failure better
    const scale_factor = options.size / @as(f32, @floatFromInt(font.baseSize));
    var width: f32 = 0;

    if (text.len != 0) {
        const idx: usize = @intCast(rl.getGlyphIndex(font, text[text.len - 1]));
        const char_width: f32 =
            if (font.glyphs[idx].advanceX == 0)
                font.recs[idx].width
            else
                @floatFromInt(font.glyphs[idx].advanceX);
        width += char_width * scale_factor;
        if (width > max_width) {
            return .{ text[0..0], 0 };
        }
    } else return .{ text[0..0], 0 };

    // TODO: unicode
    for (2..text.len + 1) |i| {
        const char = text[text.len - i];
        const idx: usize = @intCast(rl.getGlyphIndex(font, char));
        const char_width: f32 =
            if (font.glyphs[idx].advanceX == 0)
                font.recs[idx].width
            else
                @floatFromInt(font.glyphs[idx].advanceX);
        width += char_width * scale_factor + options.character_spacing;
        if (width > max_width) {
            return .{ text[text.len - i + 1 ..], width - char_width * scale_factor - options.character_spacing };
        }
    }

    return .{ text, width };
}

fn toRlColor(color: b.Color) rl.Color {
    return .{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
    };
}

fn toRlVec2(vec: b.Vec2) rl.Vector2 {
    return .{
        .x = vec.x,
        .y = vec.y,
    };
}

fn toRlRect(rect: b.Rectangle) rl.Rectangle {
    return .{
        .x = rect.x,
        .y = rect.y,
        .width = rect.width,
        .height = rect.height,
    };
}

fn toRlKey(key: b.KeyboardKey) rl.KeyboardKey {
    return switch (key) {
        .null => .null,
        .apostrophe => .apostrophe,
        .comma => .comma,
        .minus => .minus,
        .period => .period,
        .slash => .slash,
        .zero => .zero,
        .one => .one,
        .two => .two,
        .three => .three,
        .four => .four,
        .five => .five,
        .six => .six,
        .seven => .seven,
        .eight => .eight,
        .nine => .nine,
        .semicolon => .semicolon,
        .equals => .equal,
        .a => .a,
        .b => .b,
        .c => .c,
        .d => .d,
        .e => .e,
        .f => .f,
        .g => .g,
        .h => .h,
        .i => .i,
        .j => .j,
        .k => .k,
        .l => .l,
        .m => .m,
        .n => .n,
        .o => .o,
        .p => .p,
        .q => .q,
        .r => .r,
        .s => .s,
        .t => .t,
        .u => .u,
        .v => .v,
        .w => .w,
        .x => .x,
        .y => .y,
        .z => .z,
        .space => .space,
        .escape => .escape,
        .enter => .enter,
        .tab => .tab,
        .backspace => .backspace,
        .insert => .insert,
        .delete => .delete,
        .right => .right,
        .left => .left,
        .down => .down,
        .up => .up,
        .page_up => .page_up,
        .page_down => .page_down,
        .home => .home,
        .end => .end,
        .caps_lock => .caps_lock,
        .scroll_lock => .scroll_lock,
        .num_lock => .num_lock,
        .print_screen => .print_screen,
        .pause_break => .pause,
        .f1 => .f1,
        .f2 => .f2,
        .f3 => .f3,
        .f4 => .f4,
        .f5 => .f5,
        .f6 => .f6,
        .f7 => .f7,
        .f8 => .f8,
        .f9 => .f9,
        .f10 => .f10,
        .f11 => .f11,
        .f12 => .f12,
        .left_shift => .left_shift,
        .left_control => .left_control,
        .left_alt => .left_alt,
        .left_super => .left_super,
        .right_shift => .right_shift,
        .right_control => .right_control,
        .right_alt => .right_alt,
        .right_super => .right_super,
        .menu => .kb_menu,
        .left_bracket => .left_bracket,
        .backslash => .backslash,
        .right_bracket => .right_bracket,
        .backtick => .grave,
        .np_zero => .kp_0,
        .np_one => .kp_1,
        .np_two => .kp_2,
        .np_three => .kp_3,
        .np_four => .kp_4,
        .np_five => .kp_5,
        .np_six => .kp_6,
        .np_seven => .kp_7,
        .np_eight => .kp_8,
        .np_nine => .kp_9,
        .np_decimal => .kp_decimal,
        .np_divide => .kp_divide,
        .np_multiply => .kp_multiply,
        .np_subrtact => .kp_subtract,
        .np_add => .kp_add,
        .np_equal => .kp_enter,
        .np_enter => .kp_equal,
    };
}
