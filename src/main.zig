const std = @import("std");

const rl = @import("raylib");

const gui = @import("qw_gui");

pub fn main() !void {
    rl.initWindow(600, 400, "Test window");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var counter: u32 = 0;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        if (test_button.draw()) {
            counter += 1;
        }
        rl.drawText(rl.textFormat("%d", .{counter}), 295, 100, 20, .black);
    }
}

const test_button: gui.Button = .{
    .rect = .{
        .height = 60,
        .width = 100,
        .x = 250,
        .y = 150,
    },
    .text = "Test button",
};
