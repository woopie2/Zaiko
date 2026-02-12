const std = @import("std");
const rl = @import("raylib");
const enums = @import("enum.zig");
const animation = @import("animation.zig");
pub const Screen = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    bruh: bool = false,
    const VTable = struct {
        LoadTextures: *const fn (*anyopaque) void,
        LoadSounds: *const fn (*anyopaque) void,
        Deinit: *const fn (*anyopaque) void,
        Draw: *const fn (*anyopaque) void,
        HandleInput: *const fn (*anyopaque) void,
        HandleAudio: *const fn (*anyopaque) void,
        HandleOthers: *const fn (*anyopaque) void,
    };

    pub fn LoadTextures(self: Screen) void {
        self.vtable.LoadTextures(self.ptr);
    }
    pub fn LoadSounds(self: Screen) void {
        self.vtable.LoadSounds(self.ptr);
    }
    pub fn Deinit(self: Screen) void {
        self.vtable.Deinit(self.ptr);
    }
    pub fn Draw(self: Screen) void {
        self.vtable.Draw(self.ptr);
    }
    pub fn HandleInput(self: Screen) void {
        self.vtable.HandleInput(self.ptr);
    }
    pub fn HandleAudio(self: Screen) void {
        self.vtable.HandleAudio(self.ptr);
    }pub fn HandleOthers(self: Screen) void {
        self.vtable.HandleOthers(self.ptr);
    }
};

pub const SongPlaying = struct {
    bruh: bool = false,
    areAnimationsInitialized: bool = false,
    textures: std.StringHashMap(rl.Texture2D),
    sounds: std.StringHashMap(rl.Sound),
    allocator: std.mem.Allocator, 
    runningBackgroundAnimations: std.ArrayList(animation.Animation),
    runningForegroundAnimations: std.ArrayList(animation.Animation),
    isLeftDonPressed: bool = false,
    isRightDonPressed: bool = false,
    isLeftKaPressed: bool = false,
    isRightKaPressed: bool = false,
    playingHitSounds: std.ArrayList(rl.Sound),
    lastDonHitSoundTime: f64 = std.math.floatMin(f64),
    lastKaHitSoundTime: f64 = std.math.floatMin(f64),

    pub fn screen(self: *SongPlaying) Screen {
        return Screen{ .ptr = self, .vtable = &.{ 
            .LoadTextures = LoadTextures, 
            .LoadSounds = LoadSounds, 
            .Deinit = Deinit,
            .Draw = Draw, 
            .HandleInput = HandleInput, 
            .HandleAudio = HandleAudio, 
            .HandleOthers = HandleOthers } };
    }

    pub fn init(alloc: std.mem.Allocator) SongPlaying {
    var result: SongPlaying = undefined;
    result.bruh = false;
    result.areAnimationsInitialized = false;
    result.textures = std.StringHashMap(rl.Texture2D).init(alloc);
    result.sounds = std.StringHashMap(rl.Sound).init(alloc);
    result.runningBackgroundAnimations = std.ArrayList(animation.Animation).empty;
    result.playingHitSounds = .empty;
    result.allocator = alloc;
    result.runningForegroundAnimations = .empty;
    return result;
}
    pub fn LoadTexture(self:*SongPlaying, textureName: []const u8, texturePath: []const u8) !void {
        const gameTextureFolder = "./ressources/Graphics/5_Game";
        const imagePath = std.fmt.allocPrint(self.allocator, "{s}/{s}", .{gameTextureFolder, texturePath}) catch return;
        defer self.allocator.free(imagePath);
        const imagePathToLoad: [:0]const u8 = std.mem.Allocator.dupeZ(self.allocator, u8, imagePath) catch return;
        defer self.allocator.free(imagePathToLoad);
        const image: rl.Image = rl.loadImage(imagePathToLoad) catch return;
        const texture: rl.Texture2D = rl.loadTextureFromImage(image) catch return;
        try self.textures.put(textureName, texture);
        
    }

    pub fn LoadSound(self:*SongPlaying, soundName: []const u8, soundPath: []const u8, volume: f32) !void {
        const gameTextureFolder = "./ressources/Sounds";
        const fullSoundPath = std.fmt.allocPrint(self.allocator, "{s}/{s}", .{gameTextureFolder, soundPath}) catch return;
        defer self.allocator.free(fullSoundPath);
        const soundPathToLoad: [:0]const u8 = std.mem.Allocator.dupeZ(self.allocator, u8, fullSoundPath) catch return;
        defer self.allocator.free(soundPathToLoad);
        const sound = rl.loadSound(soundPathToLoad) catch return;
        rl.setSoundVolume(sound, volume);
        try self.sounds.put(soundName, sound);
        
    }

    pub fn LoadTextureWithFilter(self:*SongPlaying, textureName: []const u8, texturePath: []const u8, textureFilter: rl.TextureFilter) !void {
        const gameTextureFolder = "./ressources/Graphics/5_Game";
        const imagePath = std.fmt.allocPrint(self.allocator, "{s}/{s}", .{gameTextureFolder, texturePath}) catch return;
        defer self.allocator.free(imagePath);
        const imagePathToload = std.mem.Allocator.dupeZ(self.allocator, u8, imagePath) catch return;
        defer self.allocator.free(imagePathToload);
        const image = rl.loadImage(imagePathToload) catch return;
        const texture: rl.Texture2D = rl.loadTextureFromImage(image) catch return;
        rl.setTextureFilter(texture, textureFilter);
        try self.textures.put(textureName, texture);
        
    }
    pub fn LoadTextures(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.LoadTexture("LeftSideBackground", "6_Taiko/1P_Background_Tokkun.png") catch self.UnloadTextures();
        self.LoadTexture("PlayingZoneFrame", "6_Taiko/1P_Frame.png") catch self.UnloadTextures();
        self.LoadTexture("TaikoDon", "6_Taiko/Don.png") catch self.UnloadTextures();
        self.LoadTexture("TaikoKa", "6_Taiko/Ka.png") catch self.UnloadTextures();
        self.LoadTexture("Taiko", "6_Taiko/Base.png") catch self.UnloadTextures();
        self.LoadTexture("LaneUpBackground", "12_Lane/Background_Main.png") catch self.UnloadTextures();
        self.LoadTexture("LaneDownBackground", "12_Lane/Background_Sub.png") catch self.UnloadTextures();
        self.LoadTexture("UpBackground", "5_Background/Normal/Up/0/1st_1P.png") catch self.UnloadTextures();
        self.LoadTexture("Easy", "4_CourseSymbol/Easy.png") catch self.UnloadTextures();
        self.LoadTexture("Normal", "4_CourseSymbol/Normal.png") catch self.UnloadTextures();
        self.LoadTexture("Hard", "4_CourseSymbol/Hard.png") catch self.UnloadTextures();
        self.LoadTexture("Oni", "4_CourseSymbol/Oni.png") catch self.UnloadTextures();
        self.LoadTexture("Ura", "4_CourseSymbol/Edit.png") catch self.UnloadTextures();
        self.LoadTextureWithFilter("DownBackground", "5_Background/Normal/Down/0/0.png", rl.TextureFilter.bilinear) catch self.UnloadTextures();
        self.LoadTexture("Footer", "8_Footer/0.png") catch self.UnloadTextures();
        self.LoadTextureWithFilter("DownBackgroundLights", "5_Background/Normal/Down/0/1.png", .bilinear) catch self.UnloadTextures();
        self.LoadTexture("Flower", "5_Background/Normal/Up/0/2nd_1P.png") catch self.UnloadTextures();
        self.LoadTexture("GaugeBase", "7_Gauge/1P_Base.png") catch self.UnloadTextures();
        self.LoadTexture("GaugeFilled", "7_Gauge/1P.png") catch self.UnloadTextures();
        self.LoadTexture("GaugeUpdate", "7_Gauge/Gauge_Update.png") catch self.UnloadTextures();
        self.LoadTexture("Hex2", "5_Background/Normal/Up/0/3rd_2_0_1P.png") catch self.UnloadTextures();
        self.LoadTexture("Hex2Fill", "5_Background/Normal/Up/0/3rd_2_1_1P.png") catch self.UnloadTextures();
        self.LoadTexture("HexChara", "5_Background/Normal/Up/0/Chara.png") catch self.UnloadTextures();
        self.LoadTexture("Hex1", "5_Background/Normal/Up/0/3rd_3_0_1P.png") catch self.UnloadTextures();
        self.LoadTexture("Hex1Fill", "5_Background/Normal/Up/0/3rd_3_1_1P.png") catch self.UnloadTextures();
        self.LoadTexture("Hex4", "5_Background/Normal/Up/0/3rd_1_0_1P.png") catch self.UnloadTextures();
        self.LoadTexture("Hex4Fill", "5_Background/Normal/Up/0/3rd_1_1_1P.png") catch self.UnloadTextures();
        self.LoadTextureWithFilter("Notes", "Notes.png", rl.TextureFilter.bilinear) catch self.UnloadTextures();
        self.LoadTexture("MeasureBar", "Bar.png") catch self.UnloadTextures();
        self.LoadTexture("Explosion", "10_Effects/Hit/Explosion.png") catch self.UnloadTextures();
        self.LoadTexture("LaneDon", "12_Lane/Yellow.png") catch self.UnloadTextures();
        self.LoadTexture("LaneKa", "12_Lane/Blue.png") catch self.UnloadTextures();
        self.LoadTexture("NoteEndExplosion", "7_Gauge/1P_Explosion.png") catch self.UnloadTextures();
        self.LoadTexture("BigNoteFireworks", "10_Effects/Hit/Explosion_Big.png") catch self.UnloadTextures();
        self.LoadTextureWithFilter("Combo", "6_Taiko/Combo.png", rl.TextureFilter.bilinear) catch self.UnloadTextures();
        self.LoadTextureWithFilter("SilverCombo", "6_Taiko/Combo_Midium.png", rl.TextureFilter.bilinear) catch self.UnloadTextures();
        self.LoadTextureWithFilter("GoldCombo", "6_Taiko/Combo_Big.png", rl.TextureFilter.bilinear) catch self.UnloadTextures();
        self.LoadTextureWithFilter("ComboText", "6_Taiko/Combo_Text.png", rl.TextureFilter.bilinear) catch self.UnloadTextures();
        self.LoadTexture("RollFan", "11_Balloon/Roll.png") catch self.UnloadTextures();
    }
    pub fn LoadSounds(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.LoadSound("Don", "Taiko/dong.wav", 0.25) catch self.UnloadSounds();
        self.LoadSound("Ka", "Taiko/ka.wav", 0.25) catch self.UnloadSounds();
        
    }
    fn UnloadSounds(self: *SongPlaying) void {
        var iterator = self.sounds.iterator();
        while (iterator.next()) |entry| {
            rl.unloadSound(entry.value_ptr.*);
        }
        self.sounds.deinit();
    }
    fn UnloadTextures(self: *SongPlaying) void {
        var iterator = self.textures.iterator();
        while (iterator.next()) |entry| {
            rl.unloadTexture(entry.value_ptr.*);
        }
        self.textures.deinit();
    }

    pub fn Deinit(ptr: *anyopaque) void {
       const self: *SongPlaying = @ptrCast(@alignCast(ptr)); 
        for (self.playingHitSounds.items) |s| {
            rl.stopSound(s);
            rl.unloadSoundAlias(s);
        }
        for (self.runningForegroundAnimations.items) |anim| {
             anim.Deinit(self.allocator);
        }
       self.UnloadTextures();
       self.UnloadSounds();
       for (self.runningBackgroundAnimations.items) |toFree| {
            toFree.Deinit(self.allocator);
       }
       self.runningBackgroundAnimations.deinit(self.allocator);
       self.runningForegroundAnimations.deinit(self.allocator);
       self.playingHitSounds.deinit(self.allocator);
    }

    pub fn DrawBackground(self: SongPlaying, y: f32) void {
        rl.drawTexturePro(self.textures.get("DownBackground").?, 
        .{ .x = 0, .y = 0, .width = @floatFromInt(self.textures.get("DownBackground").?.width), .height = @floatFromInt(self.textures.get("DownBackground").?.height)}, 
        .{.x = 0, .y = y, .width = 1920, .height = y - (1080 - 66)}, 
        .{.x = 0, .y = 0}, 
        0, 
        .white);
    }

    pub fn DrawFooter(self: SongPlaying, y: i32) void {
        rl.drawTexture(self.textures.get("Footer").?, 0, y, .white);
    }
    
    pub fn DrawPlayingZone(self: *SongPlaying, x: i32, y: i32) void {
        rl.drawTexture(self.textures.get("PlayingZoneFrame").?, 
        x + self.textures.get("LeftSideBackground").?.width - 1, 
        y, .
        white);

        rl.drawTexturePro(self.textures.get("LaneUpBackground").?, 
        .{.x = 0, .y = 0, .width = @floatFromInt(self.textures.get("LaneUpBackground").?.width), 
        .height = @floatFromInt(self.textures.get("LaneUpBackground").?.height)}, 
        .{.x = @floatFromInt(x + self.textures.get("LeftSideBackground").?.width), .y = @floatFromInt(y + 83),  
        .width = @floatFromInt(self.textures.get("PlayingZoneFrame").?.width), 
        .height = @floatFromInt(self.textures.get("LaneUpBackground").?.height)}, 
        .{.x = 0, .y = 0}, 
        0, 
        .white);

        rl.drawTexturePro(self.textures.get("LaneDownBackground").?,
        .{.x = 0, .y = 0, .width = @floatFromInt(self.textures.get("LaneDownBackground").?.width), .height = @floatFromInt(self.textures.get("LaneDownBackground").?.height)},
        .{.x = @floatFromInt(x + self.textures.get("LeftSideBackground").?.width), .y = @floatFromInt(y + 83 + self.textures.get("LaneUpBackground").?.height + 6), .width = @floatFromInt(self.textures.get("PlayingZoneFrame").?.width), .height = @floatFromInt(self.textures.get("LaneDownBackground").?.height)},
        .{.x = 0, .y = 0},
        0,
        .white);

        rl.drawTexture(self.textures.get("LeftSideBackground").?,
        x,
        y + 72,
        .white);

        self.DrawTaiko(@floatFromInt(x + 499 - 180 - 10),  @floatFromInt(y + @divTrunc(self.textures.get("Taiko").?.height, 2))) catch return;
        self.DrawDifficultyIcon( x + 10, y, enums.Difficulty.Oni);
        self.DrawGauge(@floatFromInt(x + self.textures.get("LeftSideBackground").?.width - 1 + 240), @floatFromInt(y + 12), 4);


    }

    pub fn DrawTaiko(self: *SongPlaying, x: f32, y: f32) !void {
        rl.drawTexture(self.textures.get("Taiko").?, @intFromFloat(x), @intFromFloat(y), .white);
        const taikoHitViewerTime = 0.1875;
        const holdTime = 0.1;
        if (self.isLeftDonPressed) {
            const taikoDon = self.textures.get("TaikoDon").?;
            const width: f32 = @floatFromInt(@divFloor(taikoDon.width, 2));
            const height: f32 = @floatFromInt(taikoDon.height);

            var leftDonAnimation = self.allocator.create(animation.FadeOutAnimation) catch return;
            errdefer self.allocator.destroy(leftDonAnimation);
            leftDonAnimation.* = animation.FadeOutAnimation{
                .texture = taikoDon,
                .duration = taikoHitViewerTime,
                .holdTime = holdTime,
                .src = .{.x = 0, .y = 0, .width =  width, .height = height},
                .dst = .{.x = x, .y = y, .width = width, .height = height},
                .timeInterval =  taikoHitViewerTime / 255.0,
            };
            leftDonAnimation.animation().StartAnimation();
            self.runningForegroundAnimations.append(self.allocator, leftDonAnimation.animation()) catch self.allocator.destroy(leftDonAnimation);
        }
        
        if (self.isRightDonPressed) {
            const taikoDon = self.textures.get("TaikoDon").?;
            const width: f32 = @floatFromInt(@divFloor(taikoDon.width, 2));
            const height: f32 = @floatFromInt(taikoDon.height);

            var rightDonAnimation = self.allocator.create(animation.FadeOutAnimation) catch return;
            errdefer self.allocator.destroy(rightDonAnimation);
            rightDonAnimation.* = animation.FadeOutAnimation{
                .texture = taikoDon,
                .duration = taikoHitViewerTime,
                .holdTime = holdTime,
                .src = .{.x = width, .y = 0, .width =  width, .height = height},
                .dst = .{.x = x + width, .y = y, .width = width, .height = height},
                .timeInterval =  taikoHitViewerTime / 255.0,
            };
            rightDonAnimation.animation().StartAnimation();
            self.runningForegroundAnimations.append(self.allocator, rightDonAnimation.animation()) catch self.allocator.destroy(rightDonAnimation);
        }

        if (self.isLeftKaPressed) {
            const taikoKa = self.textures.get("TaikoKa").?;
            const width: f32 = @floatFromInt(@divFloor(taikoKa.width, 2));
            const height: f32 = @floatFromInt(taikoKa.height);

            var leftKaAnimation = try self.allocator.create(animation.FadeOutAnimation);
            errdefer self.allocator.destroy(leftKaAnimation);
            leftKaAnimation.* = animation.FadeOutAnimation{
                .texture = taikoKa,
                .duration = taikoHitViewerTime,
                .holdTime = holdTime,
                .src = .{.x = 0, .y = 0, .width = width, .height = height},
                .dst = .{.x = x, .y = y, .width = width, .height = height},
                .timeInterval =  taikoHitViewerTime / 255.0,
            };
            leftKaAnimation.animation().StartAnimation();
            self.runningForegroundAnimations.append(self.allocator, leftKaAnimation.animation()) catch self.allocator.destroy(leftKaAnimation);
        }
        if (self.isRightKaPressed) {
            const taikoKa = self.textures.get("TaikoKa").?;
            const width: f32 = @floatFromInt(@divFloor(taikoKa.width, 2));
            const height: f32 = @floatFromInt(taikoKa.height);

            var rightKaAnimation = self.allocator.create(animation.FadeOutAnimation) catch return;
            errdefer self.allocator.destroy(rightKaAnimation);
            rightKaAnimation.* = animation.FadeOutAnimation{
                .texture = taikoKa,
                .duration = taikoHitViewerTime,
                .holdTime = holdTime,
                .src = .{.x = width, .y = 0, .width = width, .height = height},
                .dst = .{.x = x + width, .y = y, .width = width, .height = height},
                .timeInterval =  taikoHitViewerTime / 255.0,
            };
            rightKaAnimation.animation().StartAnimation();
            self.runningForegroundAnimations.append(self.allocator, rightKaAnimation.animation()) catch self.allocator.destroy(rightKaAnimation);
        }
    }

    pub fn DrawDifficultyIcon(self: SongPlaying, x: i32, y: i32, difficulty: enums.Difficulty) void {
        var texture: rl.Texture2D = self.textures.get("Easy").?;
        if (difficulty == enums.Difficulty.Normal) {
            texture = self.textures.get("Normal").?;
        } else if (difficulty == enums.Difficulty.Hard) {
            texture = self.textures.get("Hard").?;
        } else if (difficulty == enums.Difficulty.Oni) {
            texture = self.textures.get("Oni").?;
        } else if (difficulty == enums.Difficulty.Ura) {
            texture = self.textures.get("Ura").?;
        }
        rl.drawTexture(texture, x, y + @divTrunc(texture.height, 2) + 100, .white);
    }

    pub fn DrawGauge(self: SongPlaying, x: f32, y: f32, percent: i32) void {
        const baseSheet = self.textures.get("GaugeBase").?;
        const fillSheet = self.textures.get("GaugeFilled").?;
        
        const gaugeSrcX = 0;
        const gaugeSrcY = 0;
        const gaugeSrcHeight = 43;
        const gaugeSrcFullWidth = 695;

        const destBaseWidth: f32 = 1050;
        const scaleX: f32 = destBaseWidth / @as(f32, @floatFromInt(gaugeSrcFullWidth));
        const destHeight = gaugeSrcHeight * scaleX;

        var fillSrcWidth: f32 = 1 + (gaugeSrcFullWidth - 1) * (@as(f32, @floatFromInt(percent)) / 50.0);
        fillSrcWidth = std.math.clamp(fillSrcWidth, 0, gaugeSrcFullWidth);

        rl.drawTexturePro(baseSheet,
        .{.x = gaugeSrcX, .y = gaugeSrcY, .width = gaugeSrcFullWidth, .height = gaugeSrcHeight},
        .{.x = x, .y = y, .width = destBaseWidth, .height = destHeight},
        .{.x = 0, .y = 0},
        0,
        .white);

        rl.drawTexturePro(fillSheet,
        .{.x = gaugeSrcX, .y = gaugeSrcY, .width = fillSrcWidth, .height = gaugeSrcHeight},
        .{.x = x, .y = y, .width = fillSrcWidth * scaleX, .height = destHeight},
        .{.x = 0, .y = 0},
        0,
        .white);
    }

    pub fn InitializeAnimations(self: *SongPlaying) !void {
        const upBackgroundScrollingTime: f64 = 10;
        const flowerCycleDuration: f64 = 2;
        const lightCycleDuration = 0.25;
        var upBackgroundScrolling1 = try self.allocator.create(animation.HorizontalMovingAnimation);
        upBackgroundScrolling1.* = animation.HorizontalMovingAnimation{
            .texture = self.textures.get("UpBackground").?,
            .startX = 492 * 4,
            .endX = 492 * 3,
            .y = 0,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 4,
            .timeInterval = upBackgroundScrollingTime / ((492 * 4) - (492 * 3))
        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundScrolling1.animation()); 
        upBackgroundScrolling1.animation().StartAnimation();

        var upBackgroundScrolling2 = try self.allocator.create(animation.HorizontalMovingAnimation);
        upBackgroundScrolling2.* = animation.HorizontalMovingAnimation{
            .texture = self.textures.get("UpBackground").?,
            .startX = 492 * 0,
            .endX = 492 * (-1),
            .y = 0,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 0,
            .timeInterval = upBackgroundScrollingTime / ((492 * 0) - (492 * (-1)))
        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundScrolling2.animation()); 
        upBackgroundScrolling2.animation().StartAnimation();
        
        var upBackgroundScrolling3 = try self.allocator.create(animation.HorizontalMovingAnimation);
        upBackgroundScrolling3.* = animation.HorizontalMovingAnimation{
            .texture = self.textures.get("UpBackground").?,
            .startX = 492 * 1,
            .endX = 492 * 0,
            .y = 0,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 1,
            .timeInterval = upBackgroundScrollingTime / ((492 * 1) - (492 * 0))
        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundScrolling3.animation()); 
        upBackgroundScrolling3.animation().StartAnimation();

        var upBackgroundScrolling4 = try self.allocator.create(animation.HorizontalMovingAnimation);
        upBackgroundScrolling4.* = animation.HorizontalMovingAnimation{
            .texture = self.textures.get("UpBackground").?,
            .startX = 492 * 2,
            .endX = 492 * 1,
            .y = 0,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 2,
            .timeInterval = upBackgroundScrollingTime / ((492 * 2) - (492 * 1))
        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundScrolling4.animation()); 
        upBackgroundScrolling4.animation().StartAnimation();

        var upBackgroundScrolling5 = try self.allocator.create(animation.HorizontalMovingAnimation);
        upBackgroundScrolling5.* = animation.HorizontalMovingAnimation{
            .texture = self.textures.get("UpBackground").?,
            .startX = 492 * 3,
            .endX = 492 * 2,
            .y = 0,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 3,
            .timeInterval = upBackgroundScrollingTime / ((492 * 3) - (492 * 2))
        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundScrolling5.animation()); 
        upBackgroundScrolling5.animation().StartAnimation();

        var upBackgroundFlower1 = try self.allocator.create(animation.SineMovingAnimation);
        upBackgroundFlower1.* = animation.SineMovingAnimation{
            .texture = self.textures.get("Flower").?,
            .startX = 492 * 3,
            .endX = 492 * 2,
            .minY = 0,
            .maxY = -20,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 3,
            .currentY = 0,
            .timeInterval = upBackgroundScrollingTime / ((492*3) - (492 * 2)),
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .yCycleDuration = flowerCycleDuration,

        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundFlower1.animation());
        upBackgroundFlower1.animation().StartAnimation();

        var upBackgroundFlower2 = try self.allocator.create(animation.SineMovingAnimation);
        upBackgroundFlower2.* = animation.SineMovingAnimation{
            .texture = self.textures.get("Flower").?,
            .startX = 492 * 2,
            .endX = 492 * 1,
            .minY = 0,
            .maxY = -20,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 2,
            .currentY = 0,
            .timeInterval = upBackgroundScrollingTime / ((492*2) - (492 * 1)),
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .yCycleDuration = flowerCycleDuration,

        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundFlower2.animation());
        upBackgroundFlower2.animation().StartAnimation();

        var upBackgroundFlower3 = try self.allocator.create(animation.SineMovingAnimation);
        upBackgroundFlower3.* = animation.SineMovingAnimation{
            .texture = self.textures.get("Flower").?,
            .startX = 492 * 1,
            .endX = 492 * 0,
            .minY = 0,
            .maxY = -20,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 1,
            .currentY = 0,
            .timeInterval = upBackgroundScrollingTime / ((492*1) - (492 * 0)),
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .yCycleDuration = flowerCycleDuration,

        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundFlower3.animation());
        upBackgroundFlower3.animation().StartAnimation();

        var upBackgroundFlower4 = try self.allocator.create(animation.SineMovingAnimation);
        upBackgroundFlower4.* = animation.SineMovingAnimation{
            .texture = self.textures.get("Flower").?,
            .startX = 492 * 0,
            .endX = 492 * (-1),
            .minY = 0,
            .maxY = -20,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 0,
            .currentY = 0,
            .timeInterval = upBackgroundScrollingTime / ((492*0) - (492 * (-1))),
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .yCycleDuration = flowerCycleDuration,
        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundFlower4.animation());
        upBackgroundFlower4.animation().StartAnimation();

        var upBackgroundFlower5 = try self.allocator.create(animation.SineMovingAnimation);
        upBackgroundFlower5.* = animation.SineMovingAnimation{
            .texture = self.textures.get("Flower").?,
            .startX = 492 * 4,
            .endX = 492 * 3,
            .minY = 0,
            .maxY = -20,
            .duration = upBackgroundScrollingTime,
            .currentX = 492 * 4,
            .currentY = 0,
            .timeInterval = upBackgroundScrollingTime / ((492*4) - (492 * 3)),
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .yCycleDuration = flowerCycleDuration,

        };
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundFlower5.animation());
        upBackgroundFlower5.animation().StartAnimation();
        
        var upBackgroundHex1 = try self.allocator.create(animation.HexUpBgAnimation);
        upBackgroundHex1.* = .{
            .hexBase = self.textures.get("Hex4").?,
            .hexFill = self.textures.get("Hex4Fill").?,
            .hexChara = self.textures.get("HexChara").?,
            .charaSrc = .{.x = 56, .y = 13, .width = 90, .height = 252},
            .startX = 492 * 1,
            .endX = 492 * 0,
            .minY = 0,
            .maxY = -20,
            .yCycleDuration = flowerCycleDuration,
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .duration = upBackgroundScrollingTime,
            .movementTimeInterval = upBackgroundScrollingTime / (492 * 1 - 492 * 0),
            .locationID = 4,
            .id = 0,
            .hexFillXOffset = 0,
            .charaXLocation = 0,
            .charaYLocation = 0,
            .charaXOffset = 0,
            .charaXOffsetStart = 0,
            .hexFillXOffsetStart = 0,
            .currentY = 0,
            .currentX = 492 * 1,
            .charaHexFillAnimationTimeInterval = 0.001

        };
        upBackgroundHex1.updateLocationId();
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundHex1.animation());
        upBackgroundHex1.animation().StartAnimation();

        var upBackgroundHex2 = try self.allocator.create(animation.HexUpBgAnimation);
        upBackgroundHex2.* = .{
            .hexBase = self.textures.get("Hex2").?,
            .hexFill = self.textures.get("Hex2Fill").?,
            .hexChara = self.textures.get("HexChara").?,
            .charaSrc = .{.x = 56, .y = 13, .width = 90, .height = 252},
            .startX = 492 * 2,
            .endX = 492 * 1,
            .minY = 0,
            .maxY = -20,
            .yCycleDuration = flowerCycleDuration,
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .duration = upBackgroundScrollingTime,
            .movementTimeInterval = upBackgroundScrollingTime / (492 * 2 - 492 * 1),
            .locationID = 2,
            .id = 1,
            .hexFillXOffset = 0,
            .charaXLocation = 0,
            .charaYLocation = 0,
            .charaXOffset = 0,
            .charaXOffsetStart = 0,
            .hexFillXOffsetStart = 0,
            .currentY = 0,
            .currentX = 492 * 2,
            .charaHexFillAnimationTimeInterval = 0.001

        };
        upBackgroundHex2.updateLocationId();
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundHex2.animation());
        upBackgroundHex2.animation().StartAnimation();

        var upBackgroundHex3 = try self.allocator.create(animation.HexUpBgAnimation);
        upBackgroundHex3.* = .{
            .hexBase = self.textures.get("Hex1").?,
            .hexFill = self.textures.get("Hex1Fill").?,
            .hexChara = self.textures.get("HexChara").?,
            .charaSrc = .{.x = 273, .y = 29, .width = 99, .height = 146},
            .startX = 492 * 3,
            .endX = 492 * 2,
            .minY = 0,
            .maxY = -20,
            .yCycleDuration = flowerCycleDuration,
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .duration = upBackgroundScrollingTime,
            .movementTimeInterval = upBackgroundScrollingTime / (492 * 3 - 492 * 2),
            .locationID = 1,
            .id = 2,
            .hexFillXOffset = 0,
            .charaXLocation = 0,
            .charaYLocation = 0,
            .charaXOffset = 0,
            .charaXOffsetStart = 0,
            .hexFillXOffsetStart = 0,
            .currentY = 0,
            .currentX = 492 * 3,
            .charaHexFillAnimationTimeInterval = 0.001

        };
        upBackgroundHex3.updateLocationId();
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundHex3.animation());
        upBackgroundHex3.animation().StartAnimation();

        var upBackgroundHex4 = try self.allocator.create(animation.HexUpBgAnimation);
        upBackgroundHex4.* = .{
            .hexBase = self.textures.get("Hex4").?,
            .hexFill = self.textures.get("Hex4Fill").?,
            .hexChara = self.textures.get("HexChara").?,
            .charaSrc = .{.x = 739, .y = 58, .width = 133, .height = 140},
            .startX = 492 * 4,
            .endX = 492 * 3,
            .minY = 0,
            .maxY = -20,
            .yCycleDuration = flowerCycleDuration,
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .duration = upBackgroundScrollingTime,
            .movementTimeInterval = upBackgroundScrollingTime / (492 * 4 - 492 * 3),
            .locationID = 4,
            .id = 3,
            .hexFillXOffset = 0,
            .charaXLocation = 0,
            .charaYLocation = 0,
            .charaXOffset = 0,
            .charaXOffsetStart = 0,
            .hexFillXOffsetStart = 0,
            .currentY = 0,
            .currentX = 492 * 4,
            .charaHexFillAnimationTimeInterval = 0.001

        };
        upBackgroundHex4.updateLocationId();
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundHex4.animation());
        upBackgroundHex4.animation().StartAnimation();

        var upBackgroundHex5 = try self.allocator.create(animation.HexUpBgAnimation);
        upBackgroundHex5.* = .{
            .hexBase = self.textures.get("Hex2").?,
            .hexFill = self.textures.get("Hex2Fill").?,
            .hexChara = self.textures.get("HexChara").?,
            .charaSrc = .{.x = 56, .y = 13, .width = 90, .height = 252},
            .startX = 492 * 0,
            .endX = 492 * (-1),
            .minY = 0,
            .maxY = -20,
            .yCycleDuration = flowerCycleDuration,
            .yTimeInterval = flowerCycleDuration / @as(f64, @floatFromInt(20 * 2 - 1)),
            .duration = upBackgroundScrollingTime,
            .movementTimeInterval = upBackgroundScrollingTime / (492 * 0 - 492 * (-1)),
            .locationID = 4,
            .id = 3,
            .hexFillXOffset = 0,
            .charaXLocation = 0,
            .charaYLocation = 0,
            .charaXOffset = 0,
            .charaXOffsetStart = 0,
            .hexFillXOffsetStart = 0,
            .currentY = 0,
            .currentX = 492 * 0,
            .charaHexFillAnimationTimeInterval = 0.001

        };
        upBackgroundHex5.updateLocationId();
        try self.runningBackgroundAnimations.append(self.allocator, upBackgroundHex5.animation());
        upBackgroundHex5.animation().StartAnimation();

        var lightAnimation = try self.allocator.create(animation.LoopingFadeInFadeOutAnimation);
        lightAnimation.* = animation.LoopingFadeInFadeOutAnimation{
            .texture =  self.textures.get("DownBackgroundLights").?,
            .src = .{.x = 0, .y = 0, .width = @floatFromInt(self.textures.get("DownBackgroundLights").?.width), .height = @floatFromInt(self.textures.get("DownBackgroundLights").?.height)},
            .dst = .{.x = 0, .y = 276 - 72 + 336, .width = 1920, .height = (276 - 72 + 336) - (1080 - 66)},
            .cycleDuration = lightCycleDuration,
            .minAlpha = 110,
            .maxAlpha = 125,
            .timeBeforeChange = lightCycleDuration / (((125.0 - 110.0) * 2.0) - 1.0),
            .alpha = 110,
            .increaseAlpha = true
        };
        lightAnimation.animation().StartAnimation();
        try self.runningBackgroundAnimations.append(self.allocator, lightAnimation.animation());


    }

    pub fn DrawBackgroundAnimations(self: SongPlaying) void {
        for (self.runningBackgroundAnimations.items) |animationToDraw| {
            animationToDraw.Draw();
        }
    }

    pub fn UpdateBackgroundAnimations(self: *SongPlaying) !void {
        var finishedAnimations: std.ArrayList(animation.Animation) = .empty;
        defer finishedAnimations.deinit(self.allocator);
        var restartedAnimations: std.ArrayList(animation.Animation) = .empty;
        defer restartedAnimations.deinit(self.allocator);
        var finishedAnimationsOriginalIndex: std.ArrayList(usize) = .empty;
        defer finishedAnimationsOriginalIndex.deinit(self.allocator);
        var i: usize = self.runningBackgroundAnimations.items.len;
        while (i > 0) {
            i -= 1;
            var animationToUpdate = self.runningBackgroundAnimations.items[i];
            if (animationToUpdate.IsFinish()) {
                try finishedAnimations.append(self.allocator, animationToUpdate);
                try finishedAnimationsOriginalIndex.append(self.allocator, i);
            } else  {
                animationToUpdate.UpdateAnimation();
            }
        }
        if (finishedAnimations.items.len > 0) {
            for (0..finishedAnimations.items.len) |idx| {
                var animationToRestart = finishedAnimations.items[idx];
                if (animationToRestart.animationType != animation.AnimationType.HexUpBg) {
                    var restarted = animationToRestart.Clone(self.allocator);
                    restarted.StartAnimation();
                    try restartedAnimations.append(self.allocator, restarted);
                } else {
                    const oldAnim: *animation.HexUpBgAnimation = @ptrCast(@alignCast(animationToRestart.ptr));
                    const oldAnimEndX = oldAnim.endX;
                    const locationID = oldAnim.locationID;
                    var startPosFactor = @divExact(oldAnimEndX, 492);
                    var endPosFactor = @divExact(oldAnimEndX, 492) - 1;

                    if (startPosFactor == -1 and endPosFactor == -2) {
                        startPosFactor = 4;
                        endPosFactor = 3;
                    }

                    const startX = 492 * startPosFactor;
                    const endX = 492 * endPosFactor;

                    var restarted = try self.allocator.create(animation.HexUpBgAnimation);
                    restarted.* = animation.HexUpBgAnimation{
                        .hexBase = oldAnim.hexBase,
                        .hexFill = oldAnim.hexFill,
                        .hexChara = self.textures.get("HexChara").?,
                        .charaSrc = oldAnim.charaSrc,
                        .startX = startX,
                        .endX = endX,
                        .minY = 0,
                        .maxY = -20,
                        .yCycleDuration = 2,
                        .yTimeInterval = 2.0 / @as(f64, @floatFromInt(20 * 2 - 1)),
                        .duration = 10,
                        .movementTimeInterval = 10.0 / @as(f64, @floatFromInt(startX - endX)),
                        .locationID = locationID,
                        .id = oldAnim.id,
                        .hexFillXOffset = oldAnim.hexFillXOffset,
                        .charaXLocation = 0,
                        .charaYLocation = 0,
                        .charaXOffset = oldAnim.charaXOffset,
                        .charaXOffsetStart = 0,
                        .hexFillXOffsetStart = 0,
                        .currentY = oldAnim.currentY,
                        .currentX = startX,
                        .charaHexFillAnimationTimeInterval = 0.001,
                        .currentPhase = oldAnim.currentPhase,
                        .increaseY = oldAnim.increaseY
                    };
                    restarted.updateLocationId();
                    restarted.animation().StartAnimation();
                    try restartedAnimations.append(self.allocator, restarted.animation());
                }
                _ = self.runningBackgroundAnimations.orderedRemove(finishedAnimationsOriginalIndex.items[idx]);
                animationToRestart.Deinit(self.allocator);
            }
        }
        
        i = finishedAnimations.items.len;
        while (i > 0) {
            i -= 1;
            try self.runningBackgroundAnimations.insert(self.allocator, finishedAnimationsOriginalIndex.items[i], restartedAnimations.items[i]);
        }

    }

    pub fn UpdateForegroundAnimation(self: *SongPlaying) !void {
    var i: usize = self.runningForegroundAnimations.items.len;

    while (i > 0) {
        i -= 1;

        var anim = &self.runningForegroundAnimations.items[i];

        if (anim.IsFinish()) {
            const removed = self.runningForegroundAnimations.orderedRemove(i);
            removed.Deinit(self.allocator);
        } else {
            anim.UpdateAnimation();
        }
    }
}

    pub fn DrawForegroundAnimations(self: SongPlaying) void {
        for (self.runningForegroundAnimations.items) |anim| {
            anim.Draw();
        }
    }

    pub fn Draw(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        if (!self.areAnimationsInitialized) {
            self.InitializeAnimations() catch return;
            self.areAnimationsInitialized = true;
        }
        self.DrawBackground(276 - 72 + 336);
        self.DrawFooter(1080 - 66);
        self.DrawBackgroundAnimations();
        self.DrawPlayingZone(0, 276 - 72);
        self.UpdateBackgroundAnimations() catch return;
        self.UpdateForegroundAnimation() catch return;
        self.DrawForegroundAnimations();
    }

    pub fn HitLeftDon(self: *SongPlaying) void {
        self.isLeftDonPressed = true;
        const sound = rl.loadSoundAlias(self.sounds.get("Don").?);
        self.playingHitSounds.append(self.allocator, sound) catch return;
        if (rl.getTime() - self.lastDonHitSoundTime >= 0.001) {
            rl.playSound(sound);
            self.lastDonHitSoundTime = rl.getTime();
        } 
    }

    pub fn HitRightDon(self: *SongPlaying) void {
        self.isRightDonPressed = true;
        const sound = rl.loadSoundAlias(self.sounds.get("Don").?);
        self.playingHitSounds.append(self.allocator, sound) catch return;
        if (rl.getTime() - self.lastDonHitSoundTime >= 0.001) {
            rl.playSound(sound);
            self.lastDonHitSoundTime = rl.getTime();
        } 
    }

    pub fn HitLeftKa(self: *SongPlaying) void {
        self.isLeftKaPressed = true;
        const sound = rl.loadSoundAlias(self.sounds.get("Ka").?);
        self.playingHitSounds.append(self.allocator, sound) catch return;
        if (rl.getTime() - self.lastKaHitSoundTime >= 0.001) {
            rl.playSound(sound);
            self.lastKaHitSoundTime = rl.getTime();
        } 
    }

    pub fn HitRightKa(self: *SongPlaying) void {
        self.isRightKaPressed = true;
        const sound = rl.loadSoundAlias(self.sounds.get("Ka").?);
        self.playingHitSounds.append(self.allocator, sound) catch return;
        if (rl.getTime() - self.lastKaHitSoundTime >= 0.001) {
            rl.playSound(sound);
            self.lastKaHitSoundTime = rl.getTime();
        } 
    }


    pub fn HandleInput(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        if (rl.isKeyPressed(.f)) {
            self.HitLeftDon();    
        } else {
            self.isLeftDonPressed = false;
        }

        if (rl.isKeyPressed(.j)) {
            self.HitRightDon();
        } else  {
            self.isRightDonPressed = false;
        }

        if (rl.isKeyPressed(.d)) {
            self.HitLeftKa();
        } else {
            self.isLeftKaPressed = false;
        }

        if (rl.isKeyPressed(.k)) {
            self.HitRightKa();
        } else {
            self.isRightKaPressed = false;
        }
    }
    pub fn HandleAudio(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        var i: usize = self.playingHitSounds.items.len;
        while (i > 0) {
            i -= 1;
            if (!rl.isSoundPlaying(self.playingHitSounds.items[i])) {
                rl.unloadSoundAlias(self.playingHitSounds.items[i]);
                _ = self.playingHitSounds.orderedRemove(i);
            }
        }
    }
    pub fn HandleOthers(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.bruh = true;
    }
};
