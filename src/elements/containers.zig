const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");
const Rect = @import("Rect");

pub const Panel = struct {
    rect: Rect,
    title: ?[]const u8,

    pub fn draw(self: Panel) void {
        self.drawWithOptions(default_panel_options);
    }

    pub fn drawWithOptions(self: Panel, options: PanelOptions) void {
        const rect = self.rect.vanillaRect();

        rect.draw(options.colors.background);
        rect.drawOutline(options.colors.border, options.border_thickness);

        if (self.title) |title| {
            const bar_rect = blk: {
                var bar_rect = rect;
                bar_rect.height = 20;
                break :blk bar_rect;
            };

            bar_rect.draw(options.colors.bar);
            bar_rect.drawOutline(options.colors.border, options.border_thickness);

            const text_pos: b.Vec2 = .{
                .x = bar_rect.x + 3,
                .y = bar_rect.y + (bar_rect.height - options.text_options.size) / 2,
            };
            b.drawText(options.text_options, title, text_pos, options.colors.text);
        }
    }
};

pub var default_panel_options: PanelOptions = .{};

pub const PanelOptions = struct {
    text_options: b.TextOptions = .{},
    border_thickness: f32 = 2,
    colors: Colors = .colors(.white, .light_gray, .gray, .gray),

    const Colors = struct {
        background: Color,
        bar: Color,
        border: Color,
        text: Color,

        pub fn colors(background: Color, bar: Color, border: Color, text: Color) Colors {
            return .{ .background = background, .bar = bar, .border = border, .text = text };
        }
        pub fn get(self: Colors) struct { Color, Color, Color, Color } {
            return .{ self.background, self.bar, self.border, self.text };
        }
    };
};

pub const GroupBox = struct {
    rect: Rect,
    title: ?[]const u8,

    pub fn draw(self: GroupBox) void {
        self.drawWithOptions(default_groupbox_options);
    }

    pub fn drawWithOptions(self: GroupBox, options: GroupBoxOptions) void {
        const rect = self.rect.vanillaRect();
        const left_edge: b.Rectangle = .{
            .x = rect.x,
            .y = rect.y,
            .width = options.border_thickness,
            .height = rect.height,
        };
        const right_edge: b.Rectangle = .{
            .x = rect.x + rect.width - options.border_thickness,
            .y = rect.y,
            .width = options.border_thickness,
            .height = rect.height,
        };
        const bottom_edge: b.Rectangle = .{
            .x = rect.x + options.border_thickness,
            .y = rect.y + rect.height - options.border_thickness,
            .width = rect.width - 2 * options.border_thickness,
            .height = options.border_thickness,
        };
        const top_edge: b.Rectangle = .{
            .x = rect.x + options.border_thickness,
            .y = rect.y,
            .width = rect.width - 2 * options.border_thickness,
            .height = options.border_thickness,
        };

        left_edge.draw(options.colors.border);
        right_edge.draw(options.colors.border);
        bottom_edge.draw(options.colors.border);

        if (self.title) |title| {
            const text_pos: b.Vec2 = .{
                .x = rect.x + options.border_thickness + 10,
                .y = rect.y + (options.border_thickness - options.text_options.size) / 2,
            };
            const top_left_edge = blk: {
                var top_left_edge = top_edge;
                top_left_edge.width = 5;
                break :blk top_left_edge;
            };
            const top_right_edge = blk: {
                var top_right_edge = top_edge;
                const text_width = b.measureText(options.text_options, title).x;
                top_right_edge.x += 10 + text_width + 5;
                top_right_edge.width -= 10 + text_width + 5;
                break :blk top_right_edge;
            };
            b.drawText(options.text_options, title, text_pos, options.colors.text);
            top_right_edge.draw(options.colors.border);
            top_left_edge.draw(options.colors.border);
        } else {
            top_edge.draw(options.colors.border);
        }
    }
};

pub var default_groupbox_options: GroupBoxOptions = .{};

pub const GroupBoxOptions = struct {
    text_options: b.TextOptions = .{},
    border_thickness: f32 = 2,
    colors: Colors = .colors(.gray, .gray),

    const Colors = struct {
        border: Color,
        text: Color,

        pub fn colors(border: Color, text: Color) Colors {
            return .{ .border = border, .text = text };
        }
        pub fn get(self: Colors) struct { Color, Color } {
            return .{ self.border, self.text };
        }
    };
};
