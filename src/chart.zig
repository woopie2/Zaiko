const enums = @import("enum.zig");
const rl = @import("raylib");
const std = @import("std");

var globalAnimationTimer: f64 = -1;
var noteTextureType: enums.NoteTextureType = enums.NoteTextureType.NORMAL;
var globalBPM: f64 = 120;
const Note = struct {
    noteType: enums.NoteType,
    timeInMeasure: f64,
    scrollSpeed: f64,
    bpm: f64,
    rollType: enums.RollType,
    x: f64,
    rollStart: ?*Note,
    rollEnd: ?*Note,
    notes: ?rl.Texture2D,
    showBarLine: bool,

    pub fn GetNoteTextureSrc(self: Note) rl.Rectangle {
        var yOffset = 0;
        if (noteTextureType == enums.NoteTextureType.TONGUE) {
            yOffset = 130;
        } else if (noteTextureType == enums.NoteTextureType.TONGUE_EYE) {
            yOffset = 260;
        }

        if (self.noteType == enums.NoteType.Don) {
            return .{.x = 159, .y = 30 + yOffset, .width = 70, .height = 70};
        } else if (self.noteType == enums.NoteType.Ka) {
            return .{.x = 290, .y = 30 + yOffset, .width = 70, .height = 70};
        } else if (self.noteType == enums.NoteType.BigDon) {
            return .{.x = 401, .y = 12 + yOffset, .width = 105, .height = 105};
        } else if (self.noteType == enums.NoteType.BigKa) {
            return .{.x = 530, .y = 12 + yOffset, .width = 105, .height = 105};
        } else if (self.noteType == enums.NoteType.Drumroll) {
            return .{.x = 679, .y = 30 + yOffset, .width = 70, .height = 70};
        } else if (self.noteType == enums.NoteType.BigDrumroll) {
            return .{.x = 1050, .y = 12 + yOffset, .width = 105, .height = 105};
        } else if (self.noteType == enums.NoteType.Balloon) {
            return .{.x = 1460, .y = 30 + yOffset, .width = 175, .height = 70};
        }

        if (self.rollType == enums.RollType.NORMAL and self.noteType != enums.NoteType.EndOfRoll) {
            return .{.x = 780, .y = 30, .width = 130, .height = 69};
        }

        if (self.rollType == enums.RollType.BIG and self.noteType != enums.NoteType.EndOfRoll) {
            return .{.x = 1170, .y = 142, .width = 130, .height = 106};
        }

        if (self.noteType == enums.NoteType.EndOfRoll) {
            if (self.rollType == enums.RollType.NORMAL) {
                return .{.x = 910, .y = 30, .width = 30, .height = 70};
            }
            return .{.x = 1303, .y = 142, .width = 130, .height = 108};
        }
        return .{.x = 0, .y = 0, .width = 0, .height = 0};
    }

    pub fn GetRollSrc(rollType: enums.RollType) rl.Rectangle {
        if (rollType == enums.RollType.NORMAL) {
            return .{.x = 780, .y = 30, .width = 130, .height = 69};
        }
        if (rollType == enums.RollType.BIG) {
             return .{.x = 1170, .y = 142, .width = 130, .height = 106};
        }
        return .{.x = 0, .y = 0, .width = 0, .height = 0};
    }

    pub fn Draw(self: *Note, y: i32, measureBar: rl.Texture2D, noteAnimationType: enums.NoteAnimationType, songTime: f32) void {
        if (noteAnimationType != enums.NoteAnimationType.NONE) {
            var timeInterval: f64 = 0;
            if (noteAnimationType == enums.NoteAnimationType.TONGUE) {
                timeInterval = 60.0 / globalBPM * 0.5;
            } else if (noteAnimationType == enums.NoteAnimationType.TONGUE_FAST or noteAnimationType == enums.NoteAnimationType.TONGUE_EYE) {
                timeInterval = 60.0 / globalBPM * 0.25;
            } else {
                timeInterval = 60.0 / globalBPM;
            }
            const adjustedTime = songTime;
            const currentCycle: i32 = @intFromFloat(adjustedTime / timeInterval);

            const targetTexture = if (currentCycle % 2 == 0) 
                enums.NoteTextureType.NORMAL
                else if (noteAnimationType == enums.NoteAnimationType.TONGUE_EYE)
                    enums.NoteTextureType.TONGUE_EYE
                    else enums.noteTextureType.TONGUE;
            noteTextureType = targetTexture;
        }

        if (self.showBarLine) {
            rl.drawTexturePro(measureBar, .{.x = 0, .y = 0, .width = 4, .height = 270}, .{.x = (GetRollSrc(self.rollType).height * 1.5 / 2.0) + 50, .y = y - 40, .width = 4, .height = 200});
        }

        if (self.noteType == enums.NoteType.BigDrumroll or self.noteType == enums.NoteType.Drumroll) {
            rl.drawTexturePro(self.notes, GetRollSrc(self.rollType),
            .{.x = @as(f32, self.x + 50), .y = y + (GetRollSrc(self.rollType).height * 1.5 / 2.0) + 50, .width = GetRollSrc(self.rollType).widt * 1.5, .height = GetRollSrc(self.rollType).height * 1.5},
            rl.Vector2.zero(), 0, .white);
        }
        const src = self.GetNoteTextureSrc();
        const scaledWidth: f32 = src.width * 1.5;
        const scaledHeight: f32 = src.height * 1.5;
        const offsetX: f32 = if (self.noteType == enums.NoteType.Balloon) 0 else scaledHeight * 0.5;
        rl.drawTexturePro(
            self.notes,
            src,
            .{
                .x = @as(f32, self.x) - offsetX + 50.0,
                .y = y - scaledHeight * 0.5 + 50,
                .width = scaledWidth,
                .height = scaledHeight
            },
            rl.Vector2.zero(),
            0,
            .white
        );


    }
};

pub const MEASURE_SPAWN_X: i32 = 1920;
pub const MEASURE_HIT_X: i32 = 521;

pub const Measure = struct {
    notes: std.ArrayList(Note) = .empty,
    activeNotes: std.ArrayList(Note) = .empty,
    removedNotes: std.ArrayList(Note) = .empty,
    timeLength: f64,
    songStartTime: f64,
    timeSignature: f64,
    pixelPerBeat: f64 = 318,

    pub fn Deinit(self: Measure, alloc: std.mem.Allocator) void{
        for (self.notes.items) |*n| {
            alloc.destroy(n);
        }
        @constCast(&self.notes).deinit(alloc);
        for (self.activeNotes.items) |*n| {
            alloc.destroy(n);
        }
        @constCast(&self.activeNotes).deinit(alloc);
        for (self.removedNotes.items) |*n| {
            alloc.destroy(n);
        }
        @constCast(&self.removedNotes).deinit(alloc);
    }

    fn GetNearestEndOfRoll(self: Measure, index: usize) ?Note {
        for (index..self.notes.items.len) |i| {
            if (self.notes.items[i].noteType == enums.NoteType.EndOfRoll) {
                return self.notes.items[i];
            }
        }
        return null;
    }

    fn IndexOf(list: std.ArrayList(Note), element: Note) ?usize{
        for (0..list.items.len) |i| {
            if (list.items[i].timeInMeasure == element.timeInMeasure) {
                return i;
            }
        }
        return null;
    }

    fn Contains(list: std.ArrayList(Note), element: Note) bool {
        for (0..list.items.len) |i| {
            if (list.items[i].timeInMeasure == element.timeInMeasure) {
                return true;
            }
        }
        return false;
    }

    fn GetMeasureEndX(self: Measure, songTime: f64) f64 {
        return self.pixelPerBeat * (self.notes.items[0].bpm / 60) * ((self.songStartTime + self.timeLength) - songTime) * self.notes.items[0].scrollSpeed;
    }

    pub fn GetMeasureStartX(self: Measure, songTime: f64) f64 {
        return self.pixelPerBeat * (self.notes.items[0].bpm / 60) * ((self.songStartTime) - songTime) * self.notes.items[0].scrollSpeed;
    }

    pub fn Draw(self: Measure, y: f32, notesTexture: rl.Texture2D, songTime: f32, barLine: rl.Texture2D, noteAnimationType: enums.NoteAnimationType, alloc: std.mem.Allocator) void {
        var drawLater: std.ArrayList(Note) = .empty;
        defer drawLater.deinit(alloc);
        for (self.activeNotes.items) |note| {
            if (note.rollType == enums.RollType.BALLOON and note.noteType == enums.NoteType.EndOfRoll) {
                continue;
            }
            note.notes = notesTexture;
            if (note.rollType != enums.RollType.NONE and note.rollType != enums.RollType.BALLOON and note.noteType != enums.NoteType.EndOfRoll) {
                if (self.notes.items.len == 1) {
                    const startX: f64 = if (note.noteType == enums.NoteType.Drumroll or note.noteType == enums.NoteType.BigDrumroll) note.x + @as(f64, note.GetNoteTextureSrc().width / 2.0 * 1.5) else self.notes.items[0].x;
                    const endX: f64 = if (note.rollEnd.?.x > 0 and note.rollEnd.?.x <= MEASURE_SPAWN_X) note.rollEnd.?.x else MEASURE_SPAWN_X + Note.GetNoteTextureSrc(note.rollType).width * 1.5;
                    rl.drawTexturePro(note.notes, Note.GetRollSrc(note.rollType), 
                    .{.x = @as(f32, startX), .y =  y - (Note.GetRollSrc(note.rollType).height * 1.5 / 2.0) + 50,
                    .width = @as(f32, endX - startX),
                    .height = Note.GetRollSrc(note.rollType).height * 1.5},
                    rl.Vector2.zero(),
                    0,
                    .white);
                } else if (self.notes.items.len > 1) {
                    const endOfRoll: ?Note = self.GetNearestEndOfRoll(Measure.IndexOf(self.notes, note));

                    var startX: f32 = 0;
                    if (note.rollStart != null and note.rollStart.x > 0) {
                        startX = (note.rollStart.x + note.rollStart.GetNoteTextureSrc().width * 1.5);
                    } else {
                        startX = 0;
                    }   

                    const endX: f32 = if (endOfRoll != null and Contains(self.activeNotes, endOfRoll)) @as(f32, endOfRoll.?.x) - (endOfRoll.?.GetNoteTextureSrc().width * 1.5 / 2.0) + 50 else self.GetMeasureEndX(songTime);

                    if (startX < endX) {
                        rl.drawTexturePro(note.notes, 
                        Note.GetRollSrc(note.rollType),
                        .{
                            .x = startX,
                            .y = y - (Note.GetRollSrc(note.rollType).height * 1.5 / 2.0) + 50,
                            .width = endX - startX,
                            .height = Note.GetRollSrc(note.rollType).height * 1.5
                        },
                        rl.Vector2.zero(), 0, .white);
                    }

                }
            }
            if (note.noteType == enums.NoteType.Drumroll or note.noteType == enums.NoteType.BigDrumroll) {
                drawLater.append(note) catch continue;
                continue;
            }

            if (note.noteType != enums.NoteType.None) {
                note.Draw(@intFromFloat(y), barLine, noteAnimationType, songTime);
            }
        }

        for (drawLater.items) |note| {
            note.Draw(@intFromFloat(y), barLine, noteAnimationType, songTime);
        }

    } 

    pub fn Update(self: Measure, songTime: f64, removedNotesResult: *std.ArrayList(), alloc: std.mem.Allocator) void {
        var lastBPM: f64 = 0;
        for (0..self.notes.items.len) |i| {
            var note: Note = self.notes.items[i];
            lastBPM = note.bpm;
            if (note.bpm != lastBPM) {
                globalBPM = note.bpm;
            }
            const notePos: f64 = self.pixelPerBeat * (note.bpm / 60.0) * ((self.songStartTime + note.timeInMeasure) - songTime) * note.scrollSpeed;
            if (!Contains(self.activeNotes, note) and !Contains(self.removedNotes, note) and notePos <= MEASURE_SPAWN_X and notePos > 0) {
                self.activeNotes.append(note) catch return;
            }

            note.x = notePos + MEASURE_HIT_X;
            if (note.noteType == enums.NoteType.EndOfRoll and note.rollType != enums.NoteType.Balloon and note.rollStart != null) {
                const minRollLength: f64 = 130;
                const calculatedEnd: f64 = notePos + MEASURE_HIT_X;
                const minEnd = note.rollStart.?.x + @as(f64, note.rollStart.?.GetNoteTextureSrc().width) * 1.5 + minRollLength;

                note.x = @max(calculatedEnd, minEnd);
            }

            if (note.noteType == enums.NoteType.Balloon and note.x <= MEASURE_HIT_X) {
                note.x = MEASURE_HIT_X;
            }

            if (self.songStartTime + note.timeInMeasure < songTime and note.rollType == enums.RollType.NONE and note.noteType != enums.NoteType.Drumroll and note.noteType != enums.NoteType.BigDrumroll and note.noteType != enums.NoteType.Balloon and note.noteType != note.noteType.endOfRoll) {
                note.x = 0;
                removedNotesResult.append(alloc, note) catch return;
            }

            if (note.noteType == enums.NoteType.Balloon and note.rollEnd != null and note.rollEnd.?.x <= MEASURE_HIT_X and note.rollEnd.?.x > 0) {
                note.x = 0;
                removedNotesResult.append(alloc, note) catch return;
            }
        }
    }

    pub fn UpdateRemoveNote(self: Measure, notesToRemove: std.ArrayList(Note)) void {
        for (notesToRemove.items) |note| {
            self.activeNotes.orderedRemove(Measure.IndexOf(self.activeNotes, note));
            self.removedNotes.orderedRemove(Measure.IndexOf(self.removedNotes, note));
        }
    }

    pub fn IsMeasureFinished(self: Measure, songTime: f32) bool {
        return songTime >= self.songStartTime + self.timeLength  and self.notes.getLast().x <= 0;
    }
};

pub const ChartData = struct {
    difficulty: enums.Difficulty,
    measures: std.ArrayList(Measure) = .empty,
    fields: std.StringHashMap([]u8),

    pub fn Deinit(self: ChartData, alloc: std.mem.Allocator) void {
        for (self.measures.items) |*m| {
            m.Deinit(alloc);
            alloc.destroy(m);
        }
        @constCast(&self.measures).deinit(alloc);
        @constCast(&self.fields).deinit();
    }
};

fn GetRollStartMeasure(data: ChartData, currentMeasure: Measure) ?Measure {
    for (currentMeasure.notes.items) |note| {
        if (note.noteType == enums.NoteType.Balloon or note.noteType == enums.NoteType.Drumroll or note.noteType == enums.NoteType.BigDrumroll) {
            return currentMeasure;
        }
    }
    var i: usize = 0;
    while (i > 0) {
        i -= 1;
        for (data.measures.items[i].notes.items) |note| {
            if (note.noteType == enums.NoteType.Balloon or note.noteType == enums.NoteType.Drumroll or note.noteType == enums.NoteType.BigDrumroll) {
                return data.measures.items[i];
            }
        }
    }
    return null;
}

fn GetNearestRollStart(measure: Measure, index: usize) ?usize {
    var i: usize = index;
    while (i > 0) {
        i -= 1;
        if (measure.notes.items[i].noteType == enums.NoteType.Balloon or
            measure.notes.items[i].noteType == enums.NoteType.Drumroll or
            measure.notes.items[i].noteType == enums.NoteType.BigDrumroll) {
                if (measure.notes.items[i].rollEnd != null) {
                    return i;
                }
            }
    } 
    return null;
}

pub fn IsWhiteSpace(s: []u8) bool {
    for (s) |c| {
        if (!std.ascii.isWhitespace(c)) {
            return false;
        }
    }
    return true;
}

pub fn IndexOf(list: std.ArrayList(Measure), element: Measure) ?usize {
    var i: usize = 0;
    for (list.items) |m| {
        if (m.songStartTime == element.songStartTime) {
            return i;
        }
        i += 1;
    }
    return null;
}

pub fn ParseChar(alloc: std.mem.Allocator, tjaFilePath: []u8, fileName: []u8, difficulty: enums.Difficulty, audioOffset: f64) !*ChartData {
    const fullPath: []const u8 = try std.fmt.allocPrint(alloc, "{s}/{s}", .{tjaFilePath, fileName});
    defer alloc.free(fullPath);
    const file = try std.fs.cwd().openFile(fullPath, .{});
    defer file.close();
    var buffer: [1024]u8 = undefined;
    var reader: std.fs.File.Reader = file.reader(&buffer);

    var difficultyDataName: [6]u8 = undefined;
    if (difficulty == enums.Difficulty.Easy) {
        @memcpy(difficultyDataName[0..5], @constCast("Easy").*[0..5]);
    } else if (difficulty == enums.Difficulty.Normal) {
        @memcpy(difficultyDataName[0..6], @constCast("Normal").*[0..6]);
    } else if (difficulty == enums.Difficulty.Hard) {
        @memcpy(difficultyDataName[0..4], @constCast("Hard").*[0..4]);
    } else if (difficulty == enums.Difficulty.Oni) {
        @memcpy(difficultyDataName[0..3], @constCast("Oni").*[0..3]);
    } else if (difficulty == enums.Difficulty.Ura) {
        @memcpy(difficultyDataName[0..4], @constCast("Edit").*[0..4]);
    }

    var chartData = try alloc.create(ChartData);
    errdefer {
        chartData.Deinit(alloc);
        alloc.destroy(chartData);
    }
    chartData.* = ChartData{.difficulty = difficulty, .fields = .init(alloc)};
    try chartData.fields.put("LOCATION", tjaFilePath);

    var currentMeasure: ?Measure = null;
    var canParseMeasure: bool = false; 
    var canParseEvent: bool = false;
    var isMeasureComplete: bool = false;
    var showMeasureBa: bool = true;
    var isGoGoTime: bool = false;
    var isParsingFieldName: bool = true;
    var isParsingEvent: bool = false;
    var currentRollType: enums.RollType = .NONE;

    var fieldName: [256]u8 = undefined;
    fieldName[0] = 0;
    var fieldValue: [256]u8 = undefined;
    fieldValue[0] = 0;
    var measureContent: [1024]u8 = undefined;
    measureContent[0] = 0;
    var eventContent: [256]u8 = undefined;
    eventContent[0] = 0;
    var currentTimeSignature: f64 = 1;
    var currentBPM: f64 = 120;
    var currentScrollSpeed: f64 = 1;

    var offset: f64 = audioOffset;
    var currentRollStart: Note = undefined;
    var secondsPerMeasures: std.ArrayList(f64) = .empty;




    while (reader.interface.takeDelimiter('\n')) |line| {
        std.debug.print("parsing line\n", .{});
        if (line == null) {
            break;
        }
        const lineToParse = line.?;
        if (std.mem.eql(u8, lineToParse, "")) {
            continue;
        }
        if (IsWhiteSpace(lineToParse)) {
            continue;
        }

        var parts = std.mem.splitScalar(u8, lineToParse, ':');
        var part1: []u8 = undefined;
        var part2: []u8 = undefined;
        var index: usize = 0;
        while (parts.next()) |x| {
            if (index == 0) {
                part1 = @constCast(x);
            } else if (index == 1) {
                part2 = @constCast(x);
            } else {
                break;
            }
            index += 1;
        }
        if (std.mem.eql(u8, part1, "COURSE") and std.mem.eql(u8, part1, &difficultyDataName)) {
            canParseEvent = true;
            continue;
        }

        if (std.mem.eql(u8, part1, "COURSE") or std.mem.eql(u8, part1, "LEVEL") or std.mem.eql(u8, part1, "BALLOON") or std.mem.eql(u8, part1, "SCOREINIT") or std.mem.eql(u8, part1, "SCOREDIFF") and !canParseEvent) {
            continue;
        }

        if (canParseEvent and std.mem.startsWith(u8, lineToParse, "#START")) {
            canParseEvent = true;
            canParseMeasure = true;
            continue;
        }

        if (canParseEvent and std.mem.startsWith(u8, lineToParse, "#END")) {
            return chartData;
        }
        var lineIndex: usize = 0;
        if (lineToParse[0] == ',' and std.mem.eql(u8, &measureContent, "")) {
            var measureStartTime: f64 = 0;
            if (chartData.measures.items.len == 0) {
                measureStartTime = -offset;
            } else {
                const prev = chartData.measures.getLast();
                if (prev.timeLength <= 0) {
                    measureStartTime = prev.songStartTime;
                } else {
                    measureStartTime = prev.songStartTime + prev.timeLength;
                }
            }
            var m = try alloc.create(Measure);
            m.* = Measure{.timeLength = (60000.0 * currentTimeSignature * 4.0 / currentBPM) / 1000.0, .songStartTime = measureStartTime, .timeSignature = currentTimeSignature};
            const n = try alloc.create(Note);
            n.* = Note{.noteType = enums.NoteType.None, .timeInMeasure = 0, .scrollSpeed = currentScrollSpeed, .showBarLine = showMeasureBa, .bpm = currentBPM, .rollStart = &currentRollStart, .rollType = currentRollType, .x = 0, .rollEnd = null, .notes = null};            
            try m.notes.append(alloc, n.*);
            try chartData.measures.append(alloc, m.*);
            continue;
        }
        for (lineToParse) |c| {
            if (c == '/' and lineToParse[lineIndex + 1] == '/') {
                break;
            }

            isParsingEvent = (lineToParse[0] == '#' and canParseEvent);

            if (isParsingEvent) {
                const arrIndex: usize = std.mem.indexOf(u8, &eventContent,&.{0}).?;
                eventContent[arrIndex] = c;
                eventContent[arrIndex + 1] = 0;
            }

            if (!(lineToParse[0] >= '0' and lineToParse[0] <= '9') and lineToParse[0] != '#') {
                if (c == ':') {
                    isParsingFieldName = false;
                } else if (isParsingFieldName) {
                    const arrIndex: usize = std.mem.indexOf(u8, &fieldName, &.{0}).?;
                    fieldName[arrIndex] = c;
                    fieldName[arrIndex + 1] = 0;
                } else {
                    const arrIndex: usize = std.mem.indexOf(u8, &fieldValue, &.{0}).?;
                    fieldValue[arrIndex] = c;
                    fieldValue[arrIndex + 1] = 0;
                }
            }

            if ((lineToParse[0] >= '0' and lineToParse[0] <= '9') and canParseMeasure) {
                if (c == ',') {
                    isMeasureComplete = true;
                    break;
                }
                if (currentMeasure == null) {
                    currentMeasure = Measure{.timeLength = (60000.0 * currentTimeSignature * 4.0 / currentBPM) / 1000.0, .songStartTime = 0, .timeSignature = currentTimeSignature};
                }
                const arrIndex = std.mem.indexOf(u8, &measureContent, &.{0}).?;
                measureContent[arrIndex] = c;
                measureContent[arrIndex + 1] = 0;
            }
            lineIndex += 1;
        }

        if (!(lineToParse[0] >= '0' and lineToParse[0] <= '9') and lineToParse[0] != '#') {
            try chartData.fields.put(fieldName[0..std.mem.indexOf(u8, &fieldName, &.{0}).?], fieldValue[0..std.mem.indexOf(u8, &fieldValue, &.{0}).?]);
            const fieldValueTerminated = fieldValue[0..std.mem.indexOf(u8, &fieldValue, &.{0}).?];
            const fieldNameTerminated = fieldName[0..std.mem.indexOf(u8, &fieldName, &.{0}).?];
            if (std.mem.startsWith(u8, fieldNameTerminated, "BPM")) {
                currentBPM = try std.fmt.parseFloat(f64, fieldValueTerminated);
            }

            if (std.mem.startsWith(u8, fieldNameTerminated, "OFFSET")) {
                offset = try std.fmt.parseFloat(f64, fieldValueTerminated) - audioOffset;
            }
            fieldName = undefined;
            fieldName[0] = 0;
            fieldValue = undefined;
            fieldValue[0] = 0;
            isParsingFieldName = true;
        }

        if (lineToParse[0] == '#' and canParseEvent) {
            @memcpy(eventContent[0..std.mem.indexOf(u8, &eventContent, &.{0}).? - 1], eventContent[1..std.mem.indexOf(u8, &eventContent, &.{0}).?]);
            var splitIndex: usize = 0;
            parts = std.mem.splitScalar(u8, &eventContent, ' ');
            while (parts.next()) |x| {
                if (splitIndex == 0) {
                    part1 = @constCast(x);
                } else if (splitIndex == 1) {
                    part2 = @constCast(x);
                } else {
                    break;
                }
                splitIndex += 1;
            }
            if (std.mem.eql(u8, part1, "GOGOSTART")) {
                isGoGoTime = true;
            } else if (std.mem.eql(u8, part1, "GOGOEND")) {
                isGoGoTime = false;
            } else if (std.mem.eql(u8, part1, "MEASURE")) {
                splitIndex = 0;
                parts = std.mem.splitScalar(u8, part2, '/');
                var numerator:[]u8 = undefined;
                var denominator:[]u8 = undefined;
                while (parts.next()) |x| {
                    if (splitIndex == 0) {
                        numerator = @constCast(x);
                    } else if (splitIndex == 1) {
                        denominator = @constCast(x);
                    } else {
                        break;
                    }
                    splitIndex += 1;
                }
                currentTimeSignature = try std.fmt.parseFloat(f64, numerator) / try std.fmt.parseFloat(f64, denominator);
                const secondsPerMeasure: f64 = (60000.0 * currentTimeSignature * 4.0 / currentBPM) / 1000.0;
                currentMeasure = (try alloc.create(Measure)).*;
                currentMeasure = Measure{.timeLength = secondsPerMeasure, .songStartTime = 0, .timeSignature = currentTimeSignature};
            } else if (std.mem.eql(u8, part1, "SCROLL")) {
                currentScrollSpeed = try std.fmt.parseFloat(f64, part2);
            } else if (std.mem.eql(u8, part1, "BPMCHANGE")) {
                currentBPM = try std.fmt.parseFloat(f64, part2);
            } else if (std.mem.eql(u8, part1, "BARLINEOFF")) {
                showMeasureBa = false;
            } else if (std.mem.eql(u8, part1, "BARLINEON")) {
                showMeasureBa = true;
            }
            eventContent = undefined;
            eventContent[0] = 0;
        }

        if (lineToParse[0] >= '0' and lineToParse[0] <= '9') {
            var i:usize = 0;
            for (measureContent[0..std.mem.indexOf(u8, &measureContent, &.{0}).?]) |c| {
                const noteType: enums.NoteType = @enumFromInt(c - 48);
                const secondsPerMeasure = (60000.0 * currentTimeSignature * 4.0 / currentBPM) / 1000.0;
                const isNoteBarlined = (currentMeasure.?.notes.items.len == 0 and showMeasureBa);
                var note = try alloc.create(Note); 
                note.* = Note{.x = 0, .rollStart = &currentRollStart, .rollEnd = null, .notes = null, .noteType =  noteType, .timeInMeasure = 0, .scrollSpeed = currentScrollSpeed, .rollType = currentRollType, .bpm =  currentBPM, .showBarLine = isNoteBarlined};
                try secondsPerMeasures.append(alloc, secondsPerMeasure);
                note.rollStart.?.* = currentRollStart;
                try currentMeasure.?.notes.append(alloc, note.*);
                if (noteType == .EndOfRoll) {
                    currentRollType = .NORMAL;
                    currentRollStart = undefined;
                    const startRollMeasure = GetRollStartMeasure(chartData.*, currentMeasure.?);
                    if (startRollMeasure.?.songStartTime == currentMeasure.?.songStartTime) {
                        const endIndex = currentMeasure.?.notes.items.len - 1;
                        const startIndex = GetNearestRollStart(currentMeasure.?, endIndex - 1);
                        for (currentMeasure.?.notes.items) |n| {
                            const nIndex = Measure.IndexOf(currentMeasure.?.notes, n);
                            if (nIndex.? < startIndex.? or nIndex.? > endIndex) {
                                continue;
                            }
                            n.rollEnd.?.* = note.*;
                        }  
                    } else {
                        for (IndexOf(chartData.measures, startRollMeasure.?).?..chartData.measures.items.len) |mIndex| {
                            for (chartData.measures.items[mIndex].notes.items) |n| {
                                if (Measure.IndexOf(chartData.measures.items[mIndex].notes, n).? < GetNearestRollStart(chartData.measures.items[mIndex], chartData.measures.items[mIndex].notes.items.len - 1).?) {
                                    continue;
                                }
                                n.rollEnd.?.* = note.*;
                            }

                            for (currentMeasure.?.notes.items) |n| {
                                n.rollEnd.?.* = note.*;
                            }
                        }
                    }
                }

                if (noteType == enums.NoteType.BigDrumroll) {
                    currentRollType = .BIG;
                    note.rollType = currentRollType;
                    note.rollStart = note;
                    currentRollStart = note.*;
                } else if (noteType == enums.NoteType.Drumroll) {
                    currentRollType = .NORMAL;
                    note.rollType = currentRollType;
                    note.rollStart = note;
                    currentRollStart = note.*;
                } else if (noteType == enums.NoteType.Balloon) {
                    currentRollType = .BALLOON;
                    note.rollType = currentRollType;
                    note.rollStart = note;
                    currentRollStart = note.*;
                }
                i += 1;
            }

            measureContent = undefined;
            measureContent[0] = 0;
            if (isMeasureComplete) {
                var secondsPerMeasure: f64= 0;
                var lastMilInMeasure: f64= 0;
                var idx: usize = 0;
                for (currentMeasure.?.notes.items) |*n| {
                    secondsPerMeasure = secondsPerMeasures.items[idx];
                    n.timeInMeasure = lastMilInMeasure;
                    lastMilInMeasure += secondsPerMeasure / @as(f64, @floatFromInt(currentMeasure.?.notes.items.len));
                    idx += 1;
                }
                secondsPerMeasures.clearAndFree(alloc);
                isMeasureComplete = false;

                var measureStartTime: f64 = 0;
                if (chartData.measures.items.len == 0) {
                    measureStartTime = -offset;
                } else {
                    const prev = chartData.measures.items[chartData.measures.items.len - 1];
                    if (prev.timeLength <= 0) {
                        measureStartTime = prev.songStartTime;
                    } else {
                        measureStartTime = prev.songStartTime + prev.timeLength;
                    }
                }

                currentMeasure.?.songStartTime = measureStartTime;
                currentMeasure.?.timeLength = lastMilInMeasure;
                try chartData.measures.append(alloc, currentMeasure.?);
                currentMeasure = Measure{.songStartTime = 0, .timeLength = 0, .timeSignature = currentTimeSignature};
                lastMilInMeasure = 0;
            }
        } 
    } else |_| {}
    return chartData;

}
