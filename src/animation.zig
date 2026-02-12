const rl = @import("raylib"); 
const std = @import("std");

pub const AnimationType = enum {HorizontalMoving, SineMoving, FadeOut, LoopingFadeInFadeOut, HexUpBg};

pub const Animation = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    animationType: AnimationType,
    const VTable = struct {
        UpdateAnimation: *const fn (*anyopaque) void,
        StartAnimation: *const fn (*anyopaque) void,
        Draw: *const fn (*anyopaque) void,
        IsFinish: *const fn (*anyopaque) bool,
        Clone: *const fn (*anyopaque, std.mem.Allocator) Animation,
        Deinit: *const fn (*anyopaque, std.mem.Allocator) void
    };

    pub fn UpdateAnimation(self: Animation) void {
        self.vtable.UpdateAnimation(self.ptr);
    }
    pub fn StartAnimation(self: Animation) void {
        self.vtable.StartAnimation(self.ptr);
    }
    pub fn Draw(self: Animation) void {
        self.vtable.Draw(self.ptr);
    }
    pub fn IsFinish(self: Animation) bool {
        return self.vtable.IsFinish(self.ptr);
    }
    pub fn Clone(self: Animation, allocator: std.mem.Allocator) Animation {
        return self.vtable.Clone(self.ptr, allocator);
    }

    pub fn Deinit(self: Animation, allocator: std.mem.Allocator) void {
        self.vtable.Deinit(self.ptr, allocator);
    }
};

pub const HorizontalMovingAnimation = struct {
    texture: rl.Texture2D,
    startX: i32,
    endX: i32,
    currentX: i32,
    y: i32,
    duration: f64,
    timeInterval: f64,
    currentTime: f64 = -1,
    isAnimating: bool = false,

    pub fn animation(self: *HorizontalMovingAnimation) Animation {
        return Animation{
            .ptr = self,
            .animationType = AnimationType.HorizontalMoving,
            .vtable = &.{
                .UpdateAnimation = UpdateAnimation,
                .StartAnimation = StartAnimation,
                .Draw = Draw,
                .IsFinish = IsFinish,
                .Clone = Clone,
                .Deinit = Deinit,
            }
        };
    }

    pub fn Deinit(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *HorizontalMovingAnimation = @ptrCast(@alignCast(ptr));
        allocator.destroy(self);
    }

     pub fn UpdateAnimation(ptr: *anyopaque) void {
        const self: *HorizontalMovingAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) {
            return;
        }
        if (self.animation().IsFinish()) {
            return;
        }
        if (self.currentTime < 0) {
            self.currentTime = rl.getTime();
        }
        if (rl.getTime() - self.currentTime >= self.timeInterval) {
            self.currentX -= 1;
            self.currentTime = rl.getTime();
        }
    }
    pub fn StartAnimation(ptr: *anyopaque) void {
        const self: *HorizontalMovingAnimation = @ptrCast(@alignCast(ptr));
        self.isAnimating = true;
    }
    pub fn Draw(ptr: *anyopaque) void {
        const self: *HorizontalMovingAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) {
            return;
        }
        rl.drawTexture(self.texture, self.currentX, self.y, .white);
    }
    pub fn IsFinish(ptr: *anyopaque) bool {
        const self: *HorizontalMovingAnimation = @ptrCast(@alignCast(ptr));
        return self.currentX == self.endX;
    }
    pub fn Clone(ptr: *anyopaque, allocator: std.mem.Allocator) Animation {
        const self: *HorizontalMovingAnimation = @ptrCast(@alignCast(ptr));
        var clonedMovingAnimation = allocator.create(HorizontalMovingAnimation) catch return .{.ptr = self.animation().ptr, .vtable = self.animation().vtable, .animationType = AnimationType.HorizontalMoving};
        clonedMovingAnimation.* = HorizontalMovingAnimation{
            .texture = self.texture,
            .startX = self.startX,
            .endX = self.endX,
            .currentX = self.startX,
            .y = self.y,
            .duration = self.duration,
            .timeInterval = self.timeInterval,
        };
        const clonedAnimation = clonedMovingAnimation.animation();
        return clonedAnimation;      
    }
};


pub const SineMovingAnimation = struct {
    texture: rl.Texture2D,
    startX: i32,
    endX: i32,
    currentX: i32,
    currentY: i32,
    minY: i32,
    maxY: i32,
    duration: f64,
    yCycleDuration: f64,
    timeInterval: f64,
    yTimeInterval: f64,
    currentTime: f64 = -1,
    currentYTime: f64 = -1,
    isAnimating: bool = false,
    increaseY: bool = true,

    pub fn animation(self: *SineMovingAnimation) Animation {
        return Animation{
            .ptr = self,
            .animationType = AnimationType.SineMoving,
            .vtable = &.{
                .UpdateAnimation = UpdateAnimation,
                .StartAnimation = StartAnimation,
                .Draw = Draw,
                .IsFinish = IsFinish,
                .Clone = Clone,
                .Deinit = Deinit,
            }
        };
    }

    pub fn Deinit(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *SineMovingAnimation = @ptrCast(@alignCast(ptr));
        allocator.destroy(self);
    }

     pub fn UpdateAnimation(ptr: *anyopaque) void {
        const self: *SineMovingAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) {
            return;
        }
        if (self.animation().IsFinish()) {
            return;
        }
        if (self.currentTime < 0) {
            self.currentTime = rl.getTime();
        }

        if (self.currentYTime < 0) {
            self.currentYTime = rl.getTime();
        }
        if (rl.getTime() - self.currentTime >= self.timeInterval) {
            self.currentX -= 1;
            self.currentTime = rl.getTime();
        }

        if (rl.getTime() - self.currentYTime >= self.yTimeInterval) {
            if (self.currentY >= self.minY) {
                self.increaseY = true;
            } else if (self.currentY <= self.maxY) {
                self.increaseY = false;
            }

            if (self.increaseY) {
                self.currentY -= 1;
            } else {
                self.currentY += 1;
            }
            self.currentYTime = rl.getTime();
        }
    }

    pub fn StartAnimation(ptr: *anyopaque) void {
        const self: *SineMovingAnimation = @ptrCast(@alignCast(ptr));
        self.isAnimating = true;
    }
    pub fn Draw(ptr: *anyopaque) void {
        const self: *SineMovingAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) {
            return;
        }
        rl.drawTexture(self.texture, self.currentX, self.currentY, .white);
    }
    pub fn IsFinish(ptr: *anyopaque) bool {
        const self: *SineMovingAnimation = @ptrCast(@alignCast(ptr));
        return self.currentX == self.endX;
    }
    pub fn Clone(ptr: *anyopaque, allocator: std.mem.Allocator) Animation {
        const self: *SineMovingAnimation = @ptrCast(@alignCast(ptr));
        var clonedMovingAnimation = allocator.create(SineMovingAnimation) catch return .{.ptr = self.animation().ptr, .vtable = self.animation().vtable, .animationType = AnimationType.SineMoving};
        clonedMovingAnimation.* = SineMovingAnimation{
            .texture = self.texture,
            .startX = self.startX,
            .endX = self.endX,
            .currentX = self.startX,
            .currentY = self.currentY,
            .minY = self.minY,
            .maxY = self.maxY,
            .duration = self.duration,
            .yCycleDuration = self.yCycleDuration,
            .timeInterval = self.timeInterval,
            .yTimeInterval = self.yTimeInterval,
            .increaseY = self.increaseY,
        };
        const clonedAnimation = clonedMovingAnimation.animation();
        return clonedAnimation;      
    }
};

pub const HexUpBgAnimation = struct {
    hexBase: rl.Texture2D,
    hexFill: rl.Texture2D,
    hexChara: rl.Texture2D,
    charaSrc: rl.Rectangle,
    startX: i32,
    endX: i32,
    currentX: i32,
    charaXOffset: i32,
    charaXLocation: i32,
    charaYLocation: i32,
    hexFillXOffset: i32,
    locationID: i32,
    charaXOffsetStart: i32,
    hexFillXOffsetStart: i32,
    minY: i32,
    maxY: i32,
    yCycleDuration: f64,
    currentY: i32,
    duration: f64,
    isAnimating: bool = false,
    movementTimeInterval: f64,
    currentMovementTime: f64 = -1,
    charaAppearCurrentTime: f64 = -1,
    charaDisappearCurrentTime: f64 = 0,
    charaHexFillAnimationCurrentTime: f64 = -1,
    charaHexFillAnimationTimeInterval: f64,
    startTime: f64 = -1,
    hasSwitchingStarted: bool = false,
    disappearDelay: f64 = 6,
    appearDelay: f64 = 3,
    yTime: f64 = -1,
    yTimeInterval: f64 = -1,
    increaseY: bool = true,
    id: i32,
    currentPhase: Phase = Phase.WaitingToDisappear,
    phaseStartTime: f64 = -1,
    const Phase = enum{WaitingToDisappear, Disappearing, WaitingToAppear, Appearing};

    pub fn animation(self: *HexUpBgAnimation) Animation {
        return Animation{
            .ptr = self,
            .animationType = AnimationType.HexUpBg,
            .vtable = &.{
                .UpdateAnimation = UpdateAnimation,
                .StartAnimation = StartAnimation,
                .Draw = Draw,
                .IsFinish = IsFinish,
                .Clone = Clone,
                .Deinit = Deinit,
            }
        };
    }

    pub fn updateLocationId(self: *HexUpBgAnimation) void {
        if (self.locationID == 1) {
            self.charaXLocation = 100;
            self.charaYLocation = 75;
            self.hexFillXOffset = 138;
        } else if (self.locationID == 2) {
            self.charaXLocation = 225;
            self.charaYLocation = 90;
            self.hexFillXOffset = -138;
        } else if (self.locationID == 4) {
            self.charaXLocation = 240;
            self.charaYLocation = 128;
            self.hexFillXOffset = -138;
        }
    }

    pub fn Deinit(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *HexUpBgAnimation = @ptrCast(@alignCast(ptr));
        allocator.destroy(self);
    }

     pub fn UpdateAnimation(ptr: *anyopaque) void {
        const self: *HexUpBgAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) return;
        const now = rl.getTime();
        if (self.yTime < 0) self.yTime = now;

        if (now - self.yTime >= self.yTimeInterval) {
            if (self.currentY >= self.minY) {
                self.increaseY = true;
            }

            if (self.currentY <= self.maxY) {
                self.increaseY = false;
            }

            if (self.increaseY) {
                self.currentY -= 1;
            } else {
                self.currentY += 1;
            }

            self.yTime = now;
        }

        if (self.currentMovementTime < 0) self.currentMovementTime = now;
        if (now - self.currentMovementTime >= self.movementTimeInterval) {
            self.currentX -= 1;
            self.currentMovementTime = now;
        }

        if (self.phaseStartTime < 0) {
            self.phaseStartTime = now;
        }

        if (self.currentPhase == Phase.WaitingToDisappear) {
            if (now >= self.phaseStartTime + self.disappearDelay) {
                self.charaHexFillAnimationCurrentTime = now;
                self.charaXOffsetStart = self.charaXOffset;
                self.hexFillXOffsetStart = self.hexFillXOffset;
                self.currentPhase = Phase.Disappearing;
            }
        } else if (self.currentPhase == Phase.Disappearing) {
            if (now - self.charaHexFillAnimationCurrentTime >= self.charaHexFillAnimationTimeInterval) {
                self.charaXOffset += if (self.locationID == 1) 1 else -1;
                self.hexFillXOffset += if (self.locationID == 1) -1 else 1;
                self.charaHexFillAnimationCurrentTime = now;
            }

            if (@abs(self.charaXOffset - self.charaXOffsetStart) >= 138) {
                self.currentPhase = Phase.WaitingToAppear;
                self.phaseStartTime = now;
                self.charaHexFillAnimationCurrentTime = -1;
            }
        } else if (self.currentPhase == Phase.WaitingToAppear) {
            if (now >= self.phaseStartTime + self.appearDelay) {
                self.charaHexFillAnimationCurrentTime = now;
                self.charaXOffsetStart = self.charaXOffset;
                self.hexFillXOffsetStart = self.hexFillXOffset;
                self.currentPhase = Phase.Appearing;
            }
        } else if (self.currentPhase == Phase.Appearing) {
            if (now - self.charaHexFillAnimationCurrentTime >= self.charaHexFillAnimationTimeInterval) {
                self.charaXOffset += if (self.locationID == 1) -1 else 1;
                self.hexFillXOffset+= if (self.locationID == 1) 1 else -1;
                self.charaHexFillAnimationCurrentTime = now;
            }

            if (@abs(self.charaXOffset - self.charaXOffsetStart) >= 138) {
                self.currentPhase = Phase.WaitingToDisappear;
                self.phaseStartTime = now;
                self.charaHexFillAnimationCurrentTime = -1;
            }
        }
    }

    pub fn StartAnimation(ptr: *anyopaque) void {
        const self: *HexUpBgAnimation = @ptrCast(@alignCast(ptr));
        self.isAnimating = true;
    }
    pub fn Draw(ptr: *anyopaque) void {
        const self: *HexUpBgAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) {
            return;
        }
        rl.drawTexturePro(self.hexChara, self.charaSrc, .{.x = @floatFromInt(self.currentX + self.charaXOffset + self.charaXLocation), .y = @floatFromInt(self.currentY + self.charaYLocation), .width = self.charaSrc.width, .height = self.charaSrc.height}, rl.Vector2.zero(), 0, .white);
        rl.drawTexture(self.hexFill, self.currentX + self.hexFillXOffset, self.currentY, .white);
        rl.drawTexture(self.hexBase, self.currentX, self.currentY, .white);
    }
    pub fn IsFinish(ptr: *anyopaque) bool {
        const self: *HexUpBgAnimation = @ptrCast(@alignCast(ptr));
        return self.currentX <= self.endX;
    }
    pub fn Clone(ptr: *anyopaque, allocator: std.mem.Allocator) Animation {
        const self: *HexUpBgAnimation = @ptrCast(@alignCast(ptr));
        self.animation().Deinit(allocator); 
        return .{.ptr = self.animation().ptr, .vtable = self.animation().vtable, .animationType = self.animation().animationType};
    }
};

pub const FadeOutAnimation = struct {
    texture: rl.Texture2D,
    isAnimating: bool = false,
    duration: f64,
    timeInterval: f64,
    alpha: u8 = 255,
    time: f64 = -1,
    holdTime: f64 = -1,
    src: rl.Rectangle,
    dst: rl.Rectangle,
    isHoldFinished: bool = false,
    

    pub fn animation(self: *FadeOutAnimation) Animation {
        return Animation{
            .ptr = self,
            .animationType = AnimationType.FadeOut,
            .vtable = &.{
                .UpdateAnimation = UpdateAnimation,
                .StartAnimation = StartAnimation,
                .Draw = Draw,
                .IsFinish = IsFinish,
                .Clone = Clone,
                .Deinit = Deinit,
            }
        };
    }

    pub fn Deinit(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *FadeOutAnimation = @ptrCast(@alignCast(ptr));
        allocator.destroy(self);
    }

     pub fn UpdateAnimation(ptr: *anyopaque) void {
        const self: *FadeOutAnimation = @ptrCast(@alignCast(ptr));

        if (self.time < 0) {
            self.time = rl.getTime();
        }

        if (self.holdTime != -1) {
            if (rl.getTime() - self.time >= self.holdTime) {
                self.isAnimating = true;
                self.isHoldFinished = true;
            }
        }

        if (!self.isAnimating) {
            return;
        }

        if (!self.isHoldFinished) {
            return;
        }

        var isUpdating = false;
        const currentTime = rl.getTime();
        while (currentTime - self.time >= self.timeInterval) {
            isUpdating = true;
            self.alpha -= 1;
            if (self.alpha == 0) {
                break;
            }
            self.time += self.timeInterval;
        }

        if (isUpdating) {
            self.time = rl.getTime();
        }
    }
    pub fn StartAnimation(ptr: *anyopaque) void {
        const self: *FadeOutAnimation = @ptrCast(@alignCast(ptr));
        self.isAnimating = self.holdTime == -1;
    }
    pub fn Draw(ptr: *anyopaque) void {
        const self: *FadeOutAnimation = @ptrCast(@alignCast(ptr));
        rl.drawTexturePro(self.texture, self.src, self.dst, rl.Vector2.zero(), 0, .{.r = 255, .g = 255, .b = 255, .a = self.alpha});
    }
    pub fn IsFinish(ptr: *anyopaque) bool {
        const self: *FadeOutAnimation = @ptrCast(@alignCast(ptr));
        return self.alpha == 0;
    }
    pub fn Clone(ptr: *anyopaque, allocator: std.mem.Allocator) Animation {
        const self: *FadeOutAnimation = @ptrCast(@alignCast(ptr));
        var clonedMovingAnimation = allocator.create(FadeOutAnimation) catch return .{.ptr = self.animation().ptr, .vtable = self.animation().vtable, .animationType = AnimationType.HorizontalMoving};
        clonedMovingAnimation.* = FadeOutAnimation{
            .texture = self.texture,
            .duration = self.duration,
            .src = self.src,
            .dst = self.dst,
            .timeInterval = self.duration / 255.0,
            .holdTime = self.holdTime            
        };
        const clonedAnimation = clonedMovingAnimation.animation();
        return clonedAnimation;      
    }
};

pub const LoopingFadeInFadeOutAnimation = struct {
    texture: rl.Texture2D,
    src: rl.Rectangle,
    dst: rl.Rectangle,
    cycleDuration: f64,
    timeBeforeChange: f64,
    time: f64 = -1,
    alpha: u8,
    maxAlpha: u8,
    minAlpha: u8,
    increaseAlpha: bool = true,
    isAnimating: bool = false,

    pub fn animation(self: *LoopingFadeInFadeOutAnimation) Animation {
        return Animation{
            .ptr = self,
            .animationType = AnimationType.LoopingFadeInFadeOut,
            .vtable = &.{
                .UpdateAnimation = UpdateAnimation,
                .StartAnimation = StartAnimation,
                .Draw = Draw,
                .IsFinish = IsFinish,
                .Clone = Clone,
                .Deinit = Deinit,
            }
        };
    }

    pub fn Deinit(ptr: *anyopaque, allocator: std.mem.Allocator) void {
        const self: *LoopingFadeInFadeOutAnimation = @ptrCast(@alignCast(ptr));
        allocator.destroy(self);
    }

     pub fn UpdateAnimation(ptr: *anyopaque) void {
        const self: *LoopingFadeInFadeOutAnimation = @ptrCast(@alignCast(ptr));
        if (!self.isAnimating) {
            return;
        }
         
        if (self.time < 0) {
           self.time = rl.getTime();
        }

        if (rl.getTime() - self.time >= self.timeBeforeChange) {
            if (self.alpha == self.maxAlpha) {
                self.increaseAlpha = false;
            }

            if (self.alpha == self.minAlpha) {
                self.increaseAlpha = true;
            }

            if (self.increaseAlpha and self.alpha < self.maxAlpha) {
                self.alpha += 1;
            } else if (!self.increaseAlpha and self.alpha > self.minAlpha) {
                self.alpha -= 1;
            }
            self.time = rl.getTime();
        }
    }
    pub fn StartAnimation(ptr: *anyopaque) void {
        const self: *LoopingFadeInFadeOutAnimation = @ptrCast(@alignCast(ptr));
        self.isAnimating = true;
    }
    pub fn Draw(ptr: *anyopaque) void {
        const self: *LoopingFadeInFadeOutAnimation = @ptrCast(@alignCast(ptr));
        rl.drawTexturePro(self.texture, self.src, self.dst, rl.Vector2.zero(), 0, .{.r = 255, .g = 255, .b = 255, .a = self.alpha});
    }
    pub fn IsFinish(ptr: *anyopaque) bool {
        const self: *LoopingFadeInFadeOutAnimation = @ptrCast(@alignCast(ptr));
        self.increaseAlpha = self.increaseAlpha; 
        return false;
    }
    pub fn Clone(ptr: *anyopaque, allocator: std.mem.Allocator) Animation {
        const self: *LoopingFadeInFadeOutAnimation = @ptrCast(@alignCast(ptr));
        self.animation().Deinit(allocator);    
        return .{.ptr = self.animation().ptr, .vtable = self.animation().vtable, .animationType = self.animation().animationType}; 
    }
};
