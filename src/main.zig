const std = @import("std");
const rl = @import("raylib");
const screen = @import("screen.zig");
pub fn main() !void {
    rl.setConfigFlags(.{ .vsync_hint = true, .fullscreen_mode = true, .borderless_windowed_mode = true });
    rl.initAudioDevice();
    rl.initWindow(1920, 1080, "Zaiko!");
    var gpa: std.heap.DebugAllocator(.{})= .init;
    const allocator = gpa.allocator();
    defer rl.closeWindow();
    var songPlaying = screen.SongPlaying{
        .textures = .init(allocator),
        .sounds =  .init(allocator),
        .allocator = allocator
    };
    var currentScreen = songPlaying.screen();
    currentScreen.LoadTextures();
    currentScreen.LoadSounds();
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(.white);
        currentScreen.Draw();
        rl.endDrawing();
    }
    currentScreen.UnloadTextures();
    currentScreen.UnloadSounds();
    rl.closeAudioDevice();
}
