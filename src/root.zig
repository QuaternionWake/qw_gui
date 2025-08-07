const std = @import("std");

const rl = @import("raylib");
const Color = rl.Color;

pub const Button = struct {
    rect: rl.Rectangle,
    text: [:0]const u8,

    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        return self.drawWithOptions(defaultButtonOptions);
    }

    pub fn drawWithOptions(self: Button, options: ButtonOptions) bool {
        const hovering = rl.checkCollisionPointRec(rl.getMousePosition(), self.rect);
        const holding = rl.isMouseButtonDown(.left);
        const primary_color, const secondary_color = if (holding and hovering)
            options.held_colors
        else if (hovering)
            options.hovered_colors
        else
            options.default_colors;
        rl.drawRectangleRec(self.rect, primary_color);
        rl.drawRectangleLinesEx(self.rect, 5, secondary_color);
        const text_width = rl.measureText(self.text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(self.text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, secondary_color);
        return rl.isMouseButtonReleased(.left) and hovering;
    }
};

pub var defaultButtonOptions: ButtonOptions = .{};

pub const ButtonOptions = struct {
    font_size: i32 = 10, // TODO: Consider changing this to u32
    default_colors: Colors = .{ .light_gray, .gray },
    hovered_colors: Colors = .{ .sky_blue, .blue },
    held_colors: Colors = .{ .blue, .dark_blue },

    const Colors = struct { Color, Color };
};

pub const Dropdown = struct {
    rect: rl.Rectangle,
    items: []const [:0]const u8,
    data: *Dropdown.Data,

    pub fn draw(self: Dropdown) ?usize {
        return self.drawWithOptions(defaultDropdownOptions);
    }

    pub fn drawWithOptions(self: Dropdown, options: DropdownOptions) ?usize {
        const hovering = rl.checkCollisionPointRec(rl.getMousePosition(), self.rect);
        const holding = rl.isMouseButtonDown(.left);
        const primary_color, const secondary_color = if (holding and hovering or self.data.editing)
            options.held_colors
        else if (hovering)
            options.hovered_colors
        else
            options.default_colors;
        rl.drawRectangleRec(self.rect, primary_color);
        rl.drawRectangleLinesEx(self.rect, 5, secondary_color);
        const selected_text = self.items[self.data.selected];
        const text_width = rl.measureText(selected_text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(selected_text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, secondary_color);
        if (hovering and rl.isMouseButtonReleased(.left)) {
            self.data.editing = !self.data.editing;
        }
        if (self.data.editing) {
            const dropdown_rect = blk: {
                var rect = self.rect;
                rect.y += self.rect.height;
                rect.height *= @floatFromInt(self.items.len);
                break :blk rect;
            };
            rl.drawRectangleRec(dropdown_rect, options.default_colors.@"0");
            rl.drawRectangleLinesEx(dropdown_rect, 5, options.default_colors.@"1");
            var result: ?usize = null;
            for (self.items, 0..) |item, i| {
                const item_rect = blk: {
                    var rect = self.rect;
                    rect.y += rect.height * @as(f32, @floatFromInt(i + 1));
                    break :blk rect;
                };
                const hovering_item = rl.checkCollisionPointRec(rl.getMousePosition(), item_rect);
                const item_text_width = rl.measureText(item, options.font_size);
                const item_text_pos: rl.Vector2 = .{
                    .x = item_rect.x + (item_rect.width - @as(f32, @floatFromInt(item_text_width))) / 2,
                    .y = item_rect.y + (item_rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
                };
                if (i == self.data.selected) {
                    rl.drawRectangleRec(item_rect, options.held_colors.@"0");
                    rl.drawRectangleLinesEx(item_rect, 5, options.held_colors.@"1");
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.held_colors.@"1");
                } else if (hovering_item) {
                    rl.drawRectangleRec(item_rect, options.hovered_colors.@"0");
                    rl.drawRectangleLinesEx(item_rect, 5, options.hovered_colors.@"1");
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.hovered_colors.@"1");
                } else {
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.default_colors.@"1");
                }
                if (hovering_item and rl.isMouseButtonReleased(.left)) {
                    result = i;
                    self.data.selected = i;
                    self.data.editing = !self.data.editing;
                }
            }
            return result;
        }
        return null;
    }

    pub const Data = struct {
        selected: usize = 0,
        editing: bool = false,
    };
};

pub var defaultDropdownOptions: DropdownOptions = .{};

pub const DropdownOptions = struct {
    font_size: i32 = 10, // TODO: Consider changing this to u32
    default_colors: Colors = .{ .light_gray, .gray },
    hovered_colors: Colors = .{ .sky_blue, .blue },
    held_colors: Colors = .{ .blue, .dark_blue },

    const Colors = struct { Color, Color };
};
