const std = @import("std");
const rl = @import("raylib");
const screen = @import("screen.zig");
const animation = @import("animation.zig");
const chart = @import("chart.zig");
pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{})= .init;
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        std.debug.print("memory status : {}\n", .{status});
    }
    const folder: []u8 = @constCast("./Songs/Dragoon");
    const fileName: []u8 = @constCast("Dragoon.tja");
    var testChartData = try chart.ParseChar(allocator, folder  ,fileName, .Oni, 0);
    defer {
        testChartData.Deinit(allocator);
        allocator.destroy(testChartData);
    }
    testChartData.difficulty = .Oni;
    
    
    rl.setConfigFlags(.{ .vsync_hint = true, .fullscreen_mode = true, .borderless_windowed_mode = true });
    rl.initAudioDevice();
    defer rl.closeAudioDevice();
    rl.initWindow(1920, 1080, "Zaiko!");
    defer rl.closeWindow();
    var songPlaying = screen.SongPlaying.init(allocator);
    var currentScreen = songPlaying.screen();
    defer currentScreen.Deinit();
    currentScreen.LoadTextures();
    currentScreen.LoadSounds();
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(.white);
        currentScreen.Draw();
        rl.drawFPS(0, 0);
        rl.endDrawing();
        currentScreen.HandleInput();
        currentScreen.HandleAudio();
    }
}
