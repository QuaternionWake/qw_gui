const rl = @import("raylib");
const Color = rl.Color;

const g = @import("grabbing");
const Rect = @import("Rect");

pub fn drawDropdown(
    options: DropdownOptions,
    rect: Rect,
    interaction: g.InteractionInfo,
    items: []const [:0]const u8,
    selected: *usize,
    editing: *bool,
) ?usize {
    const rl_rect = rect.rlRect();
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color =
        if (holding.currently and hovering.currently or editing.*)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rl.drawRectangleRec(rl_rect, bg_color);
    rl.drawRectangleLinesEx(rl_rect, options.border_thickness, border_color);

    const selected_text = items[selected.*];
    const text_width = rl.measureText(selected_text, options.font_size);
    const text_pos: rl.Vector2 = .{
        .x = rl_rect.x + (rl_rect.width - @as(f32, @floatFromInt(text_width))) / 2,
        .y = rl_rect.y + (rl_rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
    };
    rl.drawText(selected_text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, text_color);

    if (holding.currently and hovering.currently) {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), rl_rect) and rl.isMouseButtonPressed(.left)) {
            editing.* = !editing.*;
        }
    } else if (rl.isMouseButtonPressed(.left)) {
        editing.* = false;
    }

    if (editing.*) {
        const dropdown_rect = dropdownRect(rl_rect, items.len);
        rl.drawRectangleRec(dropdown_rect, options.inactive_colors.background);
        rl.drawRectangleLinesEx(dropdown_rect, options.border_thickness, options.inactive_colors.border);

        var result: ?usize = null;
        for (items, 0..) |item, i| {
            const item_rect = nthItemRect(rl_rect, i);
            const item_text_width = rl.measureText(item, options.font_size);
            const item_text_pos: rl.Vector2 = .{
                .x = item_rect.x + (item_rect.width - @as(f32, @floatFromInt(item_text_width))) / 2,
                .y = item_rect.y + (item_rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
            };

            const hovering_item = rl.checkCollisionPointRec(rl.getMousePosition(), item_rect);
            if (i == selected.*) {
                rl.drawRectangleRec(item_rect, options.held_colors.background);
                rl.drawRectangleLinesEx(item_rect, options.border_thickness, options.held_colors.border);
                rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.held_colors.text);
            } else if (can_grab and hovering_item) {
                rl.drawRectangleRec(item_rect, options.hovered_colors.background);
                rl.drawRectangleLinesEx(item_rect, options.border_thickness, options.hovered_colors.border);
                rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.hovered_colors.text);
            } else {
                rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.inactive_colors.text);
            }

            if (hovering.currently and holding == g.HoldInfo.released and hovering_item) {
                result = i;
                selected.* = i;
                editing.* = !editing.*;
            }
        }
        return result;
    }
    return null;
}

fn fullRect(rect: rl.Rectangle, len: usize) rl.Rectangle {
    var result = rect;
    result.height *= @floatFromInt(len + 1);
    return result;
}

fn dropdownRect(rect: rl.Rectangle, len: usize) rl.Rectangle {
    var result = rect;
    result.y += result.height;
    result.height *= @floatFromInt(len);
    return result;
}

fn nthItemRect(rect: rl.Rectangle, n: usize) rl.Rectangle {
    var result = rect;
    result.y += result.height * @as(f32, @floatFromInt(n + 1));
    return result;
}

pub const Dropdown = struct {
    rect: Rect,
    items: []const [:0]const u8,
    data: *Dropdown.Data,
    id: []const u8,

    pub fn draw(self: Dropdown) ?usize {
        return self.drawWithOptions(default_dropdown_options);
    }

    pub fn drawWithOptions(self: Dropdown, options: DropdownOptions) ?usize {
        return drawDropdown(
            options,
            self.rect,
            self.grab(),
            self.items,
            &self.data.selected,
            &self.data.editing,
        );
    }

    pub fn grab(self: Dropdown) g.InteractionInfo {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect.rlRect()) or
            self.data.editing and rl.checkCollisionPointRec(rl.getMousePosition(), fullRect(self.rect.rlRect(), self.items.len)))
        {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
    }

    pub const Data = struct {
        selected: usize = 0,
        editing: bool = false,
    };
};

pub var default_dropdown_options: DropdownOptions = .{};

pub const DropdownOptions = struct {
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
