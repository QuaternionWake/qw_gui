const rl = @import("raylib");

const b = @import("../backend.zig");

pub fn drawRectangle(rectangle: b.Rectangle, color: b.Color) void {
    rl.drawRectangleRec(toRlRect(rectangle), toRlColor(color));
}

pub fn drawRectangleOutline(rectangle: b.Rectangle, color: b.Color, thickness: f32) void {
    rl.drawRectangleLinesEx(toRlRect(rectangle), thickness, toRlColor(color));
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

pub const Font = rl.Font;

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
