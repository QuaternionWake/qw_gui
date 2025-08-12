const std = @import("std");
const mem = std.mem;
const meta = std.meta;

const rl = @import("raylib");
const Color = rl.Color;

const ElementID = struct {
    rect: rl.Rectangle,
};

var hovered_element: ?ElementID = null;
var previous_hovered_element: ?ElementID = null;
var held_element: ?ElementID = null;
var previous_held_element: ?ElementID = null;

pub fn updateGuiGlobals() void {
    previous_held_element = held_element;
    previous_hovered_element = hovered_element;
    hovered_element = null;
}

fn grabElement(id: ElementID) void {
    if (rl.isMouseButtonDown(.left)) {
        if (held_element == null) {
            held_element = id;
        }
    } else {
        held_element = null;
    }
}

fn hoverElement(id: ElementID) void {
    if (hovered_element == null)
        hovered_element = id;
}

fn canGrab(id: ElementID) bool {
    return holding(id) or hovering(id) and held_element == null;
}

fn holding(id: ElementID) bool {
    return meta.eql(held_element, id) or meta.eql(previous_held_element, id);
}

fn hovering(id: ElementID) bool {
    return meta.eql(hovered_element, id) or meta.eql(previous_hovered_element, id);
}

pub const Button = struct {
    rect: rl.Rectangle,
    text: [:0]const u8,

    /// Returns true when clicked
    pub fn draw(self: Button) bool {
        return self.drawWithOptions(default_button_options);
    }

    pub fn drawWithOptions(self: Button, options: ButtonOptions) bool {
        self.grab();
        const bg_color, const border_color, const text_color = if (holding(self.id()))
            options.held_colors.get()
        else if (canGrab(self.id()))
            options.hovered_colors.get()
        else
            options.inactive_colors.get();
        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, options.border_thickness, border_color);
        const text_width = rl.measureText(self.text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(self.text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, text_color);
        return holding(self.id()) and hovering(self.id()) and rl.isMouseButtonReleased(.left);
    }

    pub fn grab(self: Button) void {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect)) {
            hoverElement(self.id());
            grabElement(self.id());
        }
    }

    fn id(self: Button) ElementID {
        return .{ .rect = self.rect };
    }
};

pub var default_button_options: ButtonOptions = .{};

pub const ButtonOptions = struct {
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

pub const Dropdown = struct {
    rect: rl.Rectangle,
    items: []const [:0]const u8,
    data: *Dropdown.Data,

    pub fn draw(self: Dropdown) ?usize {
        return self.drawWithOptions(default_dropdown_options);
    }

    pub fn drawWithOptions(self: Dropdown, options: DropdownOptions) ?usize {
        self.grab();
        const bg_color, const border_color, const text_color = if (holding(self.id()) or self.data.editing)
            options.held_colors.get()
        else if (canGrab(self.id()))
            options.hovered_colors.get()
        else
            options.inactive_colors.get();
        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, options.border_thickness, border_color);
        const selected_text = self.items[self.data.selected];
        const text_width = rl.measureText(selected_text, options.font_size);
        const text_pos: rl.Vector2 = .{
            .x = self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2,
            .y = self.rect.y + (self.rect.height - @as(f32, @floatFromInt(options.font_size))) / 2,
        };
        rl.drawText(selected_text, @intFromFloat(text_pos.x), @intFromFloat(text_pos.y), options.font_size, text_color);
        // FIXME: remove final condition on this after the grabbing system is able to handle this on its own
        if (holding(self.id()) and hovering(self.id()) and rl.isMouseButtonReleased(.left) and rl.checkCollisionPointRec(rl.getMousePosition(), self.rect)) {
            self.data.editing = !self.data.editing;
        }
        if (self.data.editing) {
            const dropdown_rect = blk: {
                var rect = self.rect;
                rect.y += self.rect.height;
                rect.height *= @floatFromInt(self.items.len);
                break :blk rect;
            };
            rl.drawRectangleRec(dropdown_rect, options.inactive_colors.background);
            rl.drawRectangleLinesEx(dropdown_rect, options.border_thickness, options.inactive_colors.border);
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
                    rl.drawRectangleRec(item_rect, options.held_colors.background);
                    rl.drawRectangleLinesEx(item_rect, options.border_thickness, options.held_colors.border);
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.held_colors.text);
                } else if (hovering_item and canGrab(self.id())) {
                    rl.drawRectangleRec(item_rect, options.hovered_colors.background);
                    rl.drawRectangleLinesEx(item_rect, options.border_thickness, options.hovered_colors.border);
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.hovered_colors.text);
                } else {
                    rl.drawText(item, @intFromFloat(item_text_pos.x), @intFromFloat(item_text_pos.y), options.font_size, options.inactive_colors.text);
                }
                if (holding(self.id()) and hovering_item and rl.isMouseButtonReleased(.left)) {
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
        const rect = if (self.data.editing) blk: {
            var rect = self.rect;
            rect.height *= @floatFromInt(self.items.len + 1);
            break :blk rect;
        } else blk: {
            break :blk self.rect;
        };

        if (rl.checkCollisionPointRec(rl.getMousePosition(), rect)) {
            hoverElement(self.id());
            grabElement(self.id());
        }
    }

    fn id(self: Dropdown) ElementID {
        return .{ .rect = self.rect };
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
