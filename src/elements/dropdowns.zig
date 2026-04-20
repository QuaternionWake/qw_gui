const mem = @import("std").mem;
const enumFromInt = @import("std").enums.fromInt;

const gui = @import("qw_gui");
const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");
const Rect = @import("Rect");

pub fn drawDropdown(
    options: DropdownOptions,
    rect: Rect,
    interaction: g.InteractionInfo,
    forced_style: ?gui.State,
    items: []const []const u8,
    selected: *usize,
    editing: *bool,
) ?usize {
    const rect_ = rect.vanillaRect();
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const text_color =
        if (forced_style) |s| switch (s) {
            .default => options.inactive_colors.get(),
            .hovered => options.hovered_colors.get(),
            .held => options.held_colors.get(),
            .disabled => options.disabled_colors.get(),
        } else if (holding.currently and hovering.currently or editing.*)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();

    rect_.draw(bg_color);
    rect_.drawOutline(border_color, options.border_thickness);

    const arrow_height = options.text_options.size / 2;
    const arrow_rect: b.Rectangle = .{
        .x = rect_.x + rect_.width - arrow_height * 2 - 5 - options.border_thickness,
        .y = rect_.y + (rect_.height - arrow_height) / 2,
        .width = arrow_height * 2,
        .height = arrow_height,
    };
    const triangle: b.Triangle = .{
        .v1 = .{ .x = arrow_rect.x + arrow_rect.width, .y = arrow_rect.y },
        .v2 = .{ .x = arrow_rect.x, .y = arrow_rect.y },
        .v3 = .{ .x = arrow_rect.center().x, .y = arrow_rect.y + arrow_rect.height },
    };
    triangle.draw(text_color);

    const selected_text = items[selected.*];
    const text_size = b.measureText(options.text_options, selected_text);
    const text_pos: b.Vec2 = .{
        .x = rect_.x + (rect_.width - text_size.x - arrow_rect.width) / 2,
        .y = rect_.y + (rect_.height - text_size.y) / 2,
    };
    b.drawText(options.text_options, selected_text, text_pos, text_color);

    if (holding.currently and hovering.currently) {
        if (holding == g.HoldInfo.grabbed and rect_.containsPoint(b.getMousePosition())) {
            editing.* = !editing.*;
        }
    } else if (b.getMouseButtonState(.left) == b.MouseButtonState.clicked) {
        editing.* = false;
    }

    if (editing.*) {
        const dropdown_rect = dropdownRect(rect_, items.len);
        dropdown_rect.draw(options.inactive_colors.background);
        dropdown_rect.drawOutline(options.inactive_colors.border, options.border_thickness);

        var result: ?usize = null;
        for (items, 0..) |item, i| {
            const item_rect = nthItemRect(rect_, i);
            const item_text_size = b.measureText(options.text_options, item);
            const item_text_pos: b.Vec2 = .{
                .x = item_rect.x + (item_rect.width - item_text_size.x) / 2,
                .y = item_rect.y + (item_rect.height - item_text_size.y) / 2,
            };

            const hovering_item = item_rect.containsPoint(b.getMousePosition());
            if (i == selected.*) {
                item_rect.draw(options.held_colors.background);
                item_rect.drawOutline(options.held_colors.border, options.border_thickness);
                b.drawText(options.text_options, item, item_text_pos, options.held_colors.text);
            } else if (can_grab and hovering_item) {
                item_rect.draw(options.hovered_colors.background);
                item_rect.drawOutline(options.hovered_colors.border, options.border_thickness);
                b.drawText(options.text_options, item, item_text_pos, options.hovered_colors.text);
            } else {
                b.drawText(options.text_options, item, item_text_pos, options.inactive_colors.text);
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

fn fullRect(rect: b.Rectangle, len: usize) b.Rectangle {
    var result = rect;
    result.height *= @floatFromInt(len + 1);
    return result;
}

fn dropdownRect(rect: b.Rectangle, len: usize) b.Rectangle {
    var result = rect;
    result.y += result.height;
    result.height *= @floatFromInt(len);
    return result;
}

fn nthItemRect(rect: b.Rectangle, n: usize) b.Rectangle {
    var result = rect;
    result.y += result.height * @as(f32, @floatFromInt(n + 1));
    return result;
}

/// A dropdown containing a list of items.
pub const Dropdown = struct {
    rect: Rect,
    items: []const []const u8,
    data: *Dropdown.Data,
    id: []const u8,

    /// Returns the index of selected item.
    pub fn draw(self: Dropdown) ?usize {
        return self.drawWithOptions(default_dropdown_options);
    }

    pub fn drawWithOptions(self: Dropdown, options: DropdownOptions) ?usize {
        return drawDropdown(
            options,
            self.rect,
            self.grab(),
            null,
            self.items,
            &self.data.selected,
            &self.data.editing,
        );
    }

    pub fn grab(self: Dropdown) g.InteractionInfo {
        if (self.rect.vanillaRect().containsPoint(b.getMousePosition()) or
            self.data.editing and fullRect(self.rect.vanillaRect(), self.items.len).containsPoint(b.getMousePosition()))
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

/// A dropdown whose list of items is made up of variants of an enum.
pub fn EnumDropdown(Enum: type) type {
    return struct {
        rect: Rect,
        data: *EnumDropdown(Enum).Data,
        id: []const u8,

        /// Returns selected value.
        pub fn draw(self: EnumDropdown(Enum)) ?Enum {
            return self.drawWithOptions(default_dropdown_options);
        }

        pub fn drawWithOptions(self: EnumDropdown(Enum), options: DropdownOptions) ?Enum {
            var selected = mem.indexOfScalar(Enum, &variants, self.data.selected) orelse unreachable;
            const result = drawDropdown(
                options,
                self.rect,
                self.grab(),
                null,
                &items,
                &selected,
                &self.data.editing,
            );
            self.data.selected = variants[selected];

            if (result) |r| {
                return variants[r];
            }
            return null;
        }

        pub fn grab(self: EnumDropdown(Enum)) g.InteractionInfo {
            if (self.rect.vanillaRect().containsPoint(b.getMousePosition()) or
                self.data.editing and fullRect(self.rect.vanillaRect(), items.len).containsPoint(b.getMousePosition()))
            {
                g.hoverElement(self.id);
                g.grabElement(self.id);
            }
            return g.getInteractionInfo(self.id);
        }

        // needed to work with non-dense enums
        const variants = blk: {
            const fields = @typeInfo(Enum).@"enum".fields;
            var variants_: [fields.len]Enum = undefined;
            for (fields, 0..) |field, i| {
                variants_[i] = @enumFromInt(field.value);
            }
            break :blk variants_;
        };

        const items = blk: {
            const fields = @typeInfo(Enum).@"enum".fields;
            var items_: [fields.len][]const u8 = undefined;
            for (fields, 0..) |field, i| {
                items_[i] = field.name;
            }
            break :blk items_;
        };

        pub const Data = struct {
            selected: Enum = enumFromInt(Enum, 0) orelse
                @compileError("`" ++ @typeName(Enum) ++ "` does not have a variant with value 0, you must provide an explicit inital value"),
            editing: bool = false,
        };
    };
}

pub var default_dropdown_options: DropdownOptions = .{};

pub const DropdownOptions = struct {
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
