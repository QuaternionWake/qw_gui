const std = @import("std");
const rl = @import("raylib");
const gui = @import("qw_gui");

pub fn main() !void {
    rl.initWindow(600, 400, "Buttons example");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var counter: u32 = 0;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        gui.updateGuiGlobals();

        rl.clearBackground(.ray_white);

        if (increment_button.draw()) {
            counter +|= 1;
        }
        if (decrement_button.drawWithOptions(decrement_button_options)) {
            counter -|= 1;
        }
        if (reset_button.draw()) {
            counter = 0;
        }

        rl.drawText(rl.textFormat("%d", .{counter}), 295, 100, 20, .black);
    }
}

const increment_button: gui.buttons.Button = .{
    .rect = .{
        .parent = null,
        .x = .{ .left = 150 },
        .y = .{ .top = 150 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 60 },
    },
    .text = "Increment value",
};

const decrement_button: gui.buttons.Button = .{
    .rect = .{
        .parent = null,
        .x = .{ .right = -150 },
        .y = .{ .top = 150 },
        .width = .{ .amount = 100 },
        .height = .{ .amount = 60 },
    },
    .text = "Decrement value",
};

const bright_red: rl.Color = .init(255, 100, 90, 255);
const dark_red: rl.Color = .init(160, 10, 10, 255);
const decrement_button_options: gui.buttons.ButtonOptions = .{
    .hovered_colors = .colors(bright_red, .red, .red),
    .held_colors = .colors(.red, .maroon, dark_red),
};

const reset_button: gui.buttons.Button = .{
    .rect = .{
        .parent = null,
        .x = .{ .left = 20 },
        .y = .{ .top = 20 },
        .height = .{ .amount = 60 },
        .width = .{ .amount = 100 },
    },
    .text = "Reset value",
};
