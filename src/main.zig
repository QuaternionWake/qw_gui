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

    gui.buttons.default_button_options.font_size = 15;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        gui.updateGuiGlobals();

        rl.clearBackground(bg_color);

        panel.draw();
        box.draw();
        // grab first in case there is something below it, like maybe a scary button
        test_dropdown.grab();
        if (test_button.draw()) {
            counter +|= step_up_data.value;
        }
        if (custom_button.drawWithOptions(green_button_options)) {
            counter -|= step_down_data.value;
        }
        if (scary_button.draw()) {
            counter = 0;
        }
        if (test_dropdown.draw()) |idx| {
            bg_color = switch (idx) {
                0 => .ray_white,
                1 => .red,
                2 => .green,
                3 => .sky_blue,
                4 => .dark_gray,
                else => unreachable,
            };
        }
        rl.drawText(rl.textFormat("%d", .{counter}), 295, 100, 20, .black);

        if (step_up_input.draw(false)) |val| {
            rl.drawText(rl.textFormat("%d", .{val}), 160, 175, 10, .black);
        }

        if (step_down_input.draw(true)) |val| {
            rl.drawText(rl.textFormat("%d", .{val}), 160, 275, 10, .black);
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
        .height = 260,
        .width = 140,
        .x = 230,
        .y = 70,
    },
    .title = "TittTtTtleeEeEe",
};

const box: gui.containers.GroupBox = .{
    .rect = .{
        .height = 100,
        .width = 120,
        .x = 450,
        .y = 150,
    },
    .title = "Wait what's this",
};

const test_button: gui.buttons.Button = .{
    .rect = .{
        .height = 60,
        .width = 100,
        .x = 250,
        .y = 150,
    },
    .text = "Test button",
};

const custom_button: gui.buttons.Button = .{
    .rect = .{
        .height = 60,
        .width = 100,
        .x = 250,
        .y = 250,
    },
    .text = "Custom button",
};

const slider_a: gui.sliders.Slider = .{
    .rect = .{
        .height = 20,
        .width = 100,
        .x = 460,
        .y = 180,
    },
    .data = &slider_data,
};

const slider_b: gui.sliders.Slider = .{
    .rect = .{
        .height = 20,
        .width = 100,
        .x = 460,
        .y = 210,
    },
    .data = &slider_data,
};

var slider_data: gui.sliders.Slider.Data = .{ .value = 50, .min = -100, .max = 100 };

const greenish: rl.Color = .init(0, 180, 100, 255);
const green_button_options: gui.buttons.ButtonOptions = .{
    .hovered_colors = .colors(.green, greenish, greenish),
    .held_colors = .colors(greenish, .dark_green, .dark_green),
};

const test_dropdown: gui.dropdowns.Dropdown = .{
    .rect = .{
        .x = 20,
        .y = 20,
        .width = 80,
        .height = 30,
    },
    .items = &.{ "White", "Red", "Green", "Blue", "Gray" },
    .data = &test_dropdown_data,
};

var test_dropdown_data: gui.dropdowns.Dropdown.Data = .{};

const scary_button: gui.buttons.Button = .{
    .rect = .{
        .x = 20,
        .y = 70,
        .height = 60,
        .width = 100,
    },
    .text = "Scary button",
};

const step_up_input: gui.inputs.ValueInput(u32) = .{
    .rect = .{
        .x = 160,
        .y = 170,
        .width = 50,
        .height = 20,
    },
    .data = &step_up_data,
};

var step_up_data: gui.inputs.ValueInput(u32).Data = .{
    .value = 1,
    .min = 1,
    .max = 1_000_000,
};

const step_down_input: gui.inputs.ValueInput(u32) = .{
    .rect = .{
        .x = 160,
        .y = 270,
        .width = 50,
        .height = 20,
    },
    .data = &step_down_data,
};

var step_down_data: gui.inputs.ValueInput(u32).Data = .{
    .value = 1,
    .min = 1,
    .max = 1_000_000,
};
