const std = @import("std");

const rl = @import("raylib");

const gui = @import("qw_gui");

pub fn main() !void {
    rl.initWindow(600, 400, "Test window");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    rl.setExitKey(.null);

    var counter: u32 = 0;
    var bg_color: rl.Color = .ray_white;

    gui.buttons.default_button_options.text_options.size = 15;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        gui.updateGuiGlobals();

        rl.clearBackground(bg_color);

        panel.draw();
        box.draw();
        // grab first in case there is something below it, like maybe a scary button
        _ = test_dropdown.grab();
        if (test_button.draw()) {
            counter +|= step_up_data.value;
        }
        if (custom_button.drawWithOptions(green_button_options)) {
            counter -|= step_down_data.value;
        }
        if (scary_button.draw()) {
            counter = 0;
        }
        if (test_dropdown.draw()) |color| {
            bg_color = switch (color) {
                .ray_white => .ray_white,
                .red => .red,
                .green => .green,
                .sky_blue => .sky_blue,
                .dark_gray => .dark_gray,
            };
        }
        rl.drawText(rl.textFormat("%d", .{counter}), 295, 100, 20, .black);

        if (step_up_input.draw(false)) |val| {
            rl.drawText(rl.textFormat("%d", .{val}), 160, 160, 10, .black);
        }

        if (step_down_input.draw(true)) |val| {
            rl.drawText(rl.textFormat("%d", .{val}), 160, 260, 10, .black);
        }

        if (text_input.draw(true)) |val| {
            var buf: [129]u8 = undefined;
            const text = std.fmt.bufPrintZ(&buf, "{s}", .{val}) catch unreachable;
            rl.drawText(text, 250, 350, 10, .black);
        }

        if (slider_a.draw(true)) |_| {
            rl.drawRectangle(420, 180, 20, 20, .green);
        }
        if (slider_b.draw(false)) |_| {
            rl.drawRectangle(420, 210, 20, 20, .green);
        }
        rl.drawText(rl.textFormat("%f", .{slider_data.value}), 450, 270, 20, .black);
    }
}

const panel: gui.containers.Panel = .{
    .rect = .{
        .parent = null,
        .x = .{ .middle = 0 },
        .y = .{ .middle = 0 },
        .width = .{ .amount = 140 },
        .height = .{ .amount = 260 },
    },
    .title = "TittTtTtleeEeEe",
};

const box: gui.containers.GroupBox = .{
    .rect = .{
        .parent = null,
        .x = .{ .left = 450 },
        .y = .{ .middle = 0 },
        .width = .{ .amount = 120 },
        .height = .{ .amount = 100 },
    },
    .title = "Wait what's this",
};

const test_button: gui.buttons.Button = .{
    .rect = .{
        .parent = &panel.rect,
        .x = .{ .middle = 0 },
        .y = .{ .top = 80 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 60 },
    },
    .text = "Test button",
    .id = "test_button",
};

const custom_button: gui.buttons.Button = .{
    .rect = .{
        .parent = &panel.rect,
        .x = .{ .middle = 0 },
        .y = .{ .top = 180 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 60 },
    },
    .text = "Custom button",
    .id = "custom_button",
};

const slider_a: gui.sliders.Slider = .{
    .rect = .{
        .parent = &box.rect,
        .x = .{ .middle = 0 },
        .y = .{ .top = 30 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 20 },
    },
    .data = &slider_data,
    .id = "slider_a",
};

const slider_b: gui.sliders.Slider = .{
    .rect = .{
        .parent = &box.rect,
        .x = .{ .middle = 0 },
        .y = .{ .top = 60 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 20 },
    },
    .data = &slider_data,
    .id = "slider_b",
};

var slider_data: gui.sliders.Slider.Data = .{ .value = 50, .min = -100, .max = 100 };

const green_button_options: gui.buttons.ButtonOptions = .{
    .hovered_colors = .colors(.green, .dark_green, .dark_green),
    .held_colors = .colors(.pale_green, .dark_pale_green, .dark_pale_green),
};

const test_dropdown: gui.dropdowns.EnumDropdown(Colors) = .{
    .rect = .{
        .parent = null,
        .x = .{ .left = 20 },
        .y = .{ .top = 20 },
        .width = .{ .amount = 80 },
        .height = .{ .amount = 30 },
    },
    .data = &test_dropdown_data,
    .id = "test_dropdown",
};

var test_dropdown_data: gui.dropdowns.EnumDropdown(Colors).Data = .{};

const Colors = enum(u8) { ray_white, red, green, sky_blue, dark_gray };

const scary_button: gui.buttons.Button = .{
    .rect = .{
        .parent = null,
        .x = .{ .left = 20 },
        .y = .{ .top = 70 },
        .height = .{ .amount = 60 },
        .width = .{ .amount = 100 },
    },
    .text = "Scary button",
    .id = "scary_button",
};

const step_up_input: gui.inputs.ValueInputWithButtons(u32) = .{
    .rect = .{
        .parent = &test_button.rect,
        .x = .{ .left = -120 },
        .y = .{ .middle = 0 },
        .width = .{ .amount = 90 },
        .height = .{ .amount = 20 },
    },
    .data = &step_up_data,
    .id = "step_up_input",
};

var step_up_data: gui.inputs.ValueInputWithButtons(u32).Data = .{
    .value = 1,
    .min = 1,
    .max = 1_000_000,
    .buffer = &step_up_input_bufer,
};

var step_up_input_bufer: [128]u8 = undefined;

const step_down_input: gui.inputs.ValueInputWithButtons(u32) = .{
    .rect = .{
        .parent = &custom_button.rect,
        .x = .{ .left = -120 },
        .y = .{ .middle = 0 },
        .width = .{ .amount = 90 },
        .height = .{ .amount = 20 },
    },
    .data = &step_down_data,
    .id = "step_down_input",
};

var step_down_data: gui.inputs.ValueInputWithButtons(u32).Data = .{
    .value = 1,
    .min = 1,
    .max = 1_000_000,
    .buffer = &step_down_input_bufer,
};

var step_down_input_bufer: [128]u8 = undefined;

const text_input: gui.inputs.TextInput = .{
    .rect = .{
        .parent = &panel.rect,
        .x = .{ .middle = 0 },
        .y = .{ .bottom = 50 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 20 },
    },
    .data = &text_data,
    .id = "text_input",
};

var text_data: gui.inputs.TextInput.Data = .{
    .buffer = &text_input_bufer,
};

var text_input_bufer: [128]u8 = undefined;
