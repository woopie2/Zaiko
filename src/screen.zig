const std = @import("std");
const rl = @import("raylib");
const enums = @import("enum.zig");
pub const Screen = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    bruh: bool = false,
    const VTable = struct {
        LoadTextures: *const fn (*anyopaque) void,
        LoadSounds: *const fn (*anyopaque) void,
        UnloadSounds: *const fn (*anyopaque) void,
        UnloadTextures: *const fn (*anyopaque) void,
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
    pub fn UnloadSounds(self: Screen) void {
        self.vtable.UnloadSounds(self.ptr);
    }
    pub fn UnloadTextures(self: Screen) void {
        self.vtable.UnloadTextures(self.ptr);
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
    textures: std.StringHashMap(rl.Texture2D),
    sounds: std.StringHashMap(rl.Sound),
    allocator: std.mem.Allocator, 
    pub fn screen(self: *SongPlaying) Screen {
        return Screen{ .ptr = self, .vtable = &.{ 
            .LoadTextures = LoadTextures, 
            .LoadSounds = LoadSounds, 
            .UnloadSounds = UnloadSounds, 
            .UnloadTextures = UnloadTextures, .Draw = Draw, 
            .HandleInput = HandleInput, 
            .HandleAudio = HandleAudio, 
            .HandleOthers = HandleOthers } };
    }
    pub fn LoadTexture(self:*SongPlaying, textureName: []const u8, texturePath: []const u8) !void {
        const gameTextureFolder = "./ressources/Graphics/5_Game";
        const imagePath = std.fmt.allocPrint(self.allocator, "{s}/{s}", .{gameTextureFolder, texturePath}) catch return;
        const imagePathToLoad: [:0]const u8 = std.mem.Allocator.dupeZ(self.allocator, u8, imagePath) catch return;
        defer self.allocator.free(imagePath);
        const image: rl.Image = rl.loadImage(imagePathToLoad) catch return;
        const texture: rl.Texture2D = rl.loadTextureFromImage(image) catch return;
        const ownedKey = try self.allocator.dupe(u8, textureName);
        errdefer self.allocator.free(ownedKey);
        try self.textures.put(ownedKey, texture);
        
    }

    pub fn LoadSound(self:*SongPlaying, soundName: []const u8, soundPath: []const u8, volume: f32) !void {
        const gameTextureFolder = "./ressources/Sounds";
        const fullSoundPath = std.fmt.allocPrint(self.allocator, "{s}/{s}", .{gameTextureFolder, soundPath}) catch return;
        const soundPathToLoad: [:0]const u8 = std.mem.Allocator.dupeZ(self.allocator, u8, fullSoundPath) catch return;
        defer self.allocator.free(soundPathToLoad);
        const sound = rl.loadSound(soundPathToLoad) catch return;
        rl.setSoundVolume(sound, volume);
        const ownedKey = try self.allocator.dupe(u8, soundName);
        errdefer self.allocator.free(ownedKey);
        try self.sounds.put(ownedKey, sound);
        
    }

    pub fn LoadTextureWithFilter(self:*SongPlaying, textureName: []const u8, texturePath: []const u8, textureFilter: rl.TextureFilter) !void {
        const gameTextureFolder = "./ressources/Graphics/5_Game";
        const imagePath = std.fmt.allocPrint(self.allocator, "{s}/{s}", .{gameTextureFolder, texturePath}) catch return;
        const imagePathToload = std.mem.Allocator.dupeZ(self.allocator, u8, imagePath) catch return;
        defer self.allocator.free(imagePathToload);
        const image = rl.loadImage(imagePathToload) catch return;
        const texture: rl.Texture2D = rl.loadTextureFromImage(image) catch return;
        rl.setTextureFilter(texture, textureFilter);
        const ownedKey = try self.allocator.dupe(u8, textureName);
        errdefer self.allocator.free(ownedKey);
        try self.textures.put(ownedKey, texture);
        
    }
    pub fn LoadTextures(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.LoadTexture("LeftSideBackground", "6_Taiko/1P_Background_Tokkun.png") catch self.screen().UnloadTextures();
        self.LoadTexture("PlayingZoneFrame", "6_Taiko/1P_Frame.png") catch self.screen().UnloadTextures();
        self.LoadTexture("TaikoDon", "6_Taiko/Don.png") catch self.screen().UnloadTextures();
        self.LoadTexture("TaikoKa", "6_Taiko/Ka.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Taiko", "6_Taiko/Base.png") catch self.screen().UnloadTextures();
        self.LoadTexture("LaneUpBackground", "12_Lane/Background_Main.png") catch self.screen().UnloadTextures();
        self.LoadTexture("LaneDownBackground", "12_Lane/Background_Sub.png") catch self.screen().UnloadTextures();
        self.LoadTexture("UpBackground", "5_Background/Normal/Up/0/1st_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Easy", "4_CourseSymbol/Easy.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Normal", "4_CourseSymbol/Normal.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hard", "4_CourseSymbol/Hard.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Oni", "4_CourseSymbol/Oni.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Ura", "4_CourseSymbol/Edit.png") catch self.screen().UnloadTextures();
        self.LoadTextureWithFilter("DownBackground", "5_Background/Normal/Down/0/0.png", rl.TextureFilter.bilinear) catch self.screen().UnloadTextures();
        self.LoadTexture("Footer", "8_Footer/0.png") catch self.screen().UnloadTextures();
        self.LoadTexture("DownBackgroundLights", "5_Background/Normal/Down/0/1.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Flower", "5_Background/Normal/Up/0/2nd_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("GaugeBase", "7_Gauge/1P_Base.png") catch self.screen().UnloadTextures();
        self.LoadTexture("GaugeFilled", "7_Gauge/1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("GaugeUpdate", "7_Gauge/Gauge_Update.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hex2", "5_Background/Normal/Up/0/3rd_2_0_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hex2Fill", "5_Background/Normal/Up/0/3rd_2_1_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("HexChara", "5_Background/Normal/Up/0/Chara.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hex1", "5_Background/Normal/Up/0/3rd_3_0_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hex1Fill", "5_Background/Normal/Up/0/3rd_3_1_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hex4", "5_Background/Normal/Up/0/3rd_1_0_1P.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Hex4Fill", "5_Background/Normal/Up/0/3rd_1_1_1P.png") catch self.screen().UnloadTextures();
        self.LoadTextureWithFilter("Notes", "Notes.png", rl.TextureFilter.bilinear) catch self.screen().UnloadTextures();
        self.LoadTexture("MeasureBar", "Bar.png") catch self.screen().UnloadTextures();
        self.LoadTexture("Explosion", "10_Effects/Hit/Explosion.png") catch self.screen().UnloadTextures();
        self.LoadTexture("LaneDon", "12_Lane/Yellow.png") catch self.screen().UnloadTextures();
        self.LoadTexture("LaneKa", "12_Lane/Blue.png") catch self.screen().UnloadTextures();
        self.LoadTexture("NoteEndExplosion", "7_Gauge/1P_Explosion.png") catch self.screen().UnloadTextures();
        self.LoadTexture("BigNoteFireworks", "10_Effects/Hit/Explosion_Big.png") catch self.screen().UnloadTextures();
        self.LoadTextureWithFilter("Combo", "6_Taiko/Combo.png", rl.TextureFilter.bilinear) catch self.screen().UnloadTextures();
        self.LoadTextureWithFilter("SilverCombo", "6_Taiko/Combo_Midium.png", rl.TextureFilter.bilinear) catch self.screen().UnloadTextures();
        self.LoadTextureWithFilter("GoldCombo", "6_Taiko/Combo_Big.png", rl.TextureFilter.bilinear) catch self.screen().UnloadTextures();
        self.LoadTextureWithFilter("ComboText", "6_Taiko/Combo_Text.png", rl.TextureFilter.bilinear) catch self.screen().UnloadTextures();
        self.LoadTexture("RollFan", "11_Balloon/Roll.png") catch self.screen().UnloadTextures();
    }
    pub fn LoadSounds(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.LoadSound("Don", "Taiko/dong.wav", 0.25) catch self.screen().UnloadSounds();
        self.LoadSound("Ka", "Taiko/ka.wav", 0.25) catch self.screen().UnloadSounds();
        
    }
    pub fn UnloadSounds(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        var iterator = self.sounds.iterator();
        while (iterator.next()) |entry| {
            rl.unloadSound(entry.value_ptr.*);
        }
        self.sounds.deinit();
    }
    pub fn UnloadTextures(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        var iterator = self.textures.iterator();
        while (iterator.next()) |entry| {
            rl.unloadTexture(entry.value_ptr.*);
        }
        self.textures.deinit();
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
    
    pub fn DrawPlayingZone(self: SongPlaying, x: i32, y: i32) void {
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

        self.DrawTaiko(x + 499 - 180 - 10, y + @divTrunc(self.textures.get("Taiko").?.height, 2));
        self.DrawDifficultyIcon( x + 10, y, enums.Difficulty.Oni);
        self.DrawGauge(@floatFromInt(x + self.textures.get("LeftSideBackground").?.width - 1 + 240), @floatFromInt(y + 12), 4);


    }

    pub fn DrawTaiko(self: SongPlaying, x: i32, y: i32) void {
        rl.drawTexture(self.textures.get("Taiko").?, x, y, .white);
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

    pub fn Draw(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.DrawBackground(276 - 72 + 336);
        self.DrawFooter(1080 - 66);
        self.DrawPlayingZone(0, 276 - 72);
    }
    pub fn HandleInput(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.bruh = true;
    }
    pub fn HandleAudio(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.bruh = true;
    }
    pub fn HandleOthers(ptr: *anyopaque) void {
        const self: *SongPlaying = @ptrCast(@alignCast(ptr));
        self.bruh = true;
    }
};
