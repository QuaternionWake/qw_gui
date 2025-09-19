const rl = @import("raylib");
const Color = rl.Color;

const g = @import("grabbing");
const Rect = @import("Rect");

pub const Dropdown = struct {
    rect: Rect,
    items: []const [:0]const u8,
    data: *Dropdown.Data,

    pub fn draw(self: Dropdown) ?usize {
        return self.drawWithOptions(default_dropdown_options);
    }

    pub fn drawWithOptions(self: Dropdown, options: DropdownOptions) ?usize {
        const rect = self.rect.rlRect();
        self.grab();
        const bg_color, const border_color, const text_color = if (g.holding(self.id(null)) and g.hovering(self.id(null)) or self.data.editing)
            options.held_colors.get()
        else if (g.canGrab(self.id(null)) and g.hovering(self.id(null)))
            options.hovered_colors.get()
        else
            options.inactive_colors.get();
        rl.drawRectangleRec(rect, bg_color);
        rl.drawRectangleLinesEx(rect, options.border_thickness, border_color);
        const selected_text = self.items[self.data.selected];
        const text_width = rl.measureText(selected_text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = rect.x + (rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = rect.y + (rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(selected_text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, text_color);
        if (g.holding(self.id(null)) and g.hovering(self.id(null)) and rl.isMouseButtonPressed(.left)) {
            self.data.editing = !self.data.editing;
        }
        if (self.data.editing) {
            const dropdown_rect = self.dropdownRect();
            rl.drawRectangleRec(dropdown_rect, options.inactive_colors.background);
            rl.drawRectangleLinesEx(dropdown_rect, options.border_thickness, options.inactive_colors.border);
            var result: ?usize = null;
            for (self.items, 0..) |item, i| {
                const item_rect = self.nthItemRect(i);
                const item_text_width = rl.measureText(item, options.font_size);
                const item_text_pos: rl.Vector2 = .{
                    .x = item_rect.x + (item_rect.width - @as(f32, @floatFromInt(item_text_width))) / 2,
                    .y = item_rect.y + (item_rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
                };
                if (i == self.data.selected) {
                    rl.drawRectangleRec(item_rect, options.held_colors.background);
                    rl.drawRectangleLinesEx(item_rect, options.border_thickness, options.held_colors.border);
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.held_colors.text);
                } else if (g.hovering(self.id(i)) and (g.canGrab(self.id(i)) or g.canGrab(self.id(null)))) {
                    rl.drawRectangleRec(item_rect, options.hovered_colors.background);
                    rl.drawRectangleLinesEx(item_rect, options.border_thickness, options.hovered_colors.border);
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.hovered_colors.text);
                } else {
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.inactive_colors.text);
                }
                if ((g.holding(self.id(i)) or g.holding(self.id(null))) and g.hovering(self.id(i)) and rl.isMouseButtonReleased(.left)) {
                    result = i;
                    self.data.selected = i;
                    self.data.editing = !self.data.editing;
                }
            }
            return result;
        }
        return null;
    }

    pub fn grab(self: Dropdown) void {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect.rlRect())) {
            g.hoverElement(self.id(null));
            g.grabElement(self.id(null));
        }
        if (self.data.editing) {
            for (0..self.items.len) |n| {
                if (rl.checkCollisionPointRec(rl.getMousePosition(), self.nthItemRect(n))) {
                    g.hoverElement(self.id(n));
                    g.grabElement(self.id(n));
                }
            }
        }
    }

    fn fullRect(self: Dropdown) rl.Rectangle {
        var rect = self.rect.rlRect();
        rect.height *= @floatFromInt(self.items.len + 1);
        return rect;
    }

    fn dropdownRect(self: Dropdown) rl.Rectangle {
        var rect = self.rect.rlRect();
        rect.y += rect.height;
        rect.height *= @floatFromInt(self.items.len);
        return rect;
    }

    fn nthItemRect(self: Dropdown, n: usize) rl.Rectangle {
        var rect = self.rect.rlRect();
        rect.y += rect.height * @as(f32, @floatFromInt(n + 1));
        return rect;
    }

    fn id(self: Dropdown, data: ?usize) g.ElementID {
        return if (data) |d|
            .{ .inner = @intCast(@intFromPtr(self.items[d].ptr)) }
        else
            // TODO: using the data pointer here is bad when data struct is shared
            .{ .inner = @intCast(@intFromPtr(self.data)) };
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
