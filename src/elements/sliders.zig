const std = @import("std");
const math = std.math;

const rl = @import("raylib");
const Color = rl.Color;

const g = @import("grabbing");

pub const Slider = struct {
    rect: rl.Rectangle,
    data: *Slider.Data,

    /// Returns new value. If `return_on_change` is true, returns every frame
    /// when the value changes, otherwise returns on mouse button release
    pub fn draw(self: Slider, return_on_change: bool) ?f32 {
        return self.drawWithOptions(return_on_change, default_slider_options);
    }

    pub fn drawWithOptions(self: Slider, return_on_change: bool, options: SliderOptions) ?f32 {
        self.grab();
        const bg_color, const border_color, const box_color = if (g.holding(self.id()))
            options.held_colors.get()
        else if (g.canGrab(self.id()) and g.hovering(self.id()))
            options.hovered_colors.get()
        else
            options.inactive_colors.get();
        rl.drawRectangleRec(self.rect, bg_color);
        rl.drawRectangleLinesEx(self.rect, options.border_thickness, border_color);

        const min_x = self.rect.x + options.border_thickness + options.padding + options.box_width / 2;
        const max_x = self.rect.x + self.rect.width - options.border_thickness - options.padding - options.box_width / 2;

        const mouse_x: f32 = @floatFromInt(rl.getMouseX());
        const slider_width = max_x - min_x;
        const data_width = self.data.max - self.data.min;

        var result: ?f32 = null;
        if (g.holding(self.id())) {
            const old_val = self.data.value;
            const unclamped_val = (mouse_x - min_x) / slider_width * data_width + self.data.min;
            self.data.value = math.clamp(unclamped_val, self.data.min, self.data.max);
            if (self.data.value != old_val) {
                result = self.data.value;
            }
        }

        const box_center_x = if (g.holding(self.id()))
            math.clamp(mouse_x, min_x, max_x)
        else
            (self.data.value - self.data.min) / data_width * slider_width + min_x;

        const box: rl.Rectangle = .{
            .x = box_center_x - options.box_width / 2,
            .y = self.rect.y + options.border_thickness + options.padding,
            .width = options.box_width,
            .height = self.rect.height - (options.border_thickness + options.padding) * 2,
        };
        rl.drawRectangleRec(box, box_color);

        return if (return_on_change)
            result
        else if (g.holding(self.id()) and !rl.isMouseButtonDown(.left))
            self.data.value
        else
            null;
    }

    pub fn grab(self: Slider) void {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect)) {
            g.hoverElement(self.id());
            g.grabElement(self.id());
        }
    }

    fn id(self: Slider) g.ElementID {
        return .{ .rect = self.rect, .data = null };
    }

    pub const Data = struct {
        value: f32,
        min: f32,
        max: f32,
    };
};

pub var default_slider_options: SliderOptions = .{};

pub const SliderOptions = struct {
    border_thickness: f32 = 1,
    padding: f32 = 2,
    box_width: f32 = 10,
    inactive_colors: Colors = .colors(.ray_white, .light_gray, .sky_blue),
    hovered_colors: Colors = .colors(.ray_white, .light_gray, .blue),
    held_colors: Colors = .colors(.ray_white, .light_gray, .dark_blue),

    const Colors = struct {
        background: Color,
        border: Color,
        box: Color,

        pub fn colors(background: Color, border: Color, box: Color) Colors {
            return .{ .background = background, .border = border, .box = box };
        }
        pub fn get(self: Colors) struct { Color, Color, Color } {
            return .{ self.background, self.border, self.box };
        }
    };
};
