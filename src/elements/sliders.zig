const std = @import("std");
const math = std.math;

const gui = @import("qw_gui");
const b = @import("backend");
const Color = b.Color;
const g = @import("grabbing");

pub fn drawSlider(
    options: SliderOptions,
    rect: b.Rect,
    interaction: g.InteractionInfo,
    forced_style: ?gui.State,
    min: f32,
    max: f32,
    value: *f32,
    return_on_change: bool,
) ?f32 {
    const holding, const hovering, const can_grab = interaction;
    const bg_color, const border_color, const box_color =
        if (forced_style) |s| switch (s) {
            .default => options.inactive_colors.get(),
            .hovered => options.hovered_colors.get(),
            .held => options.held_colors.get(),
            .disabled => options.disabled_colors.get(),
        } else if (holding.currently)
            options.held_colors.get()
        else if (can_grab and hovering.currently)
            options.hovered_colors.get()
        else
            options.inactive_colors.get();
    rect.draw(bg_color);
    rect.drawOutline(border_color, options.border_thickness);

    const min_x = rect.x + options.border_thickness + options.padding + options.box_width / 2;
    const max_x = rect.x + rect.width - options.border_thickness - options.padding - options.box_width / 2;

    const mouse_x = b.getMousePosition().x;
    const slider_width = max_x - min_x;
    const data_width = max - min;

    var result: ?f32 = null;
    if (holding.currently) {
        const old_val = value.*;
        const unclamped_val = (mouse_x - min_x) / slider_width * data_width + min;
        value.* = math.clamp(unclamped_val, min, max);
        if (value.* != old_val) {
            result = value.*;
        }
    }

    const box_center_x = if (holding.currently)
        math.clamp(mouse_x, min_x, max_x)
    else
        (value.* - min) / data_width * slider_width + min_x;

    const box: b.Rect = .{
        .x = box_center_x - options.box_width / 2,
        .y = rect.y + options.border_thickness + options.padding,
        .width = options.box_width,
        .height = rect.height - (options.border_thickness + options.padding) * 2,
    };
    box.draw(box_color);

    return if (return_on_change)
        result
    else if (holding == g.HoldInfo.released)
        value.*
    else
        null;
}

/// A slider for inputing a numeric value.
pub const Slider = struct {
    data: *Slider.Data,
    id: []const u8,

    /// Returns new value. If `return_on_change` is `true`, returns every frame when the
    /// value changes, otherwise returns on mouse button release.
    pub fn draw(self: Slider, rect: b.Rect, return_on_change: bool) ?f32 {
        return self.drawWithOptions(rect, return_on_change, default_slider_options);
    }

    pub fn drawWithOptions(self: Slider, rect: b.Rect, return_on_change: bool, options: SliderOptions) ?f32 {
        return drawSlider(
            options,
            rect,
            self.grab(rect),
            null,
            self.data.min,
            self.data.max,
            &self.data.value,
            return_on_change,
        );
    }

    pub fn grab(self: Slider, rect: b.Rect) g.InteractionInfo {
        if (rect.containsPoint(b.getMousePosition())) {
            g.hoverElement(self.id);
            g.grabElement(self.id);
        }
        return g.getInteractionInfo(self.id);
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
    inactive_colors: Colors = .colors(.white, .light_gray, .light_cyan),
    hovered_colors: Colors = .colors(.white, .light_gray, .cyan),
    held_colors: Colors = .colors(.white, .light_gray, .darker_cyan),
    disabled_colors: Colors = .colors(.white, .light_gray, .light_gray),

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
