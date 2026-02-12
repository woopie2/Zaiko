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
    rollStart: ?Note,
    rollEnd: ?Note,
    notes: rl.Texture2D,
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
    notes: std.ArrayList(Note),
    activeNotes: std.ArrayList(Note),
    removedNotes: std.ArrayList(Note),
    timeLength: f64,
    songStartTime: f64,
    timeSignature: f64,
    pixelPerBeat: f64 = 318,

    fn GetNearestEndOfRoll(self: Measure, index: usize) ?Note {
        for (index..self.notes.items.len) |i| {
            if (self.notes.items[i].noteType == enums.NoteType.EndOfRoll) {
                return self.notes.items[i];
            }
        }
        return null;
    }

    fn IndexOf(list: std.ArrayList(Note), element: Note) usize{
        for (0..list.items.len) |i| {
            if (list.items[i].timeInMeasure == element.timeInMeasure) {
                return i;
            }
        }
        return -1;
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
                    const endOfRoll: ?Note = self.GetNearestEndOfRoll(IndexOf(self.notes, note));

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
            self.activeNotes.orderedRemove(IndexOf(self.activeNotes, note));
            self.removedNotes.orderedRemove(IndexOf(self.removedNotes, note));
        }
    }

    pub fn IsMeasureFinished(self: Measure, songTime: f32) bool {
        return songTime >= self.songStartTime + self.timeLength  and self.notes.getLast().x <= 0;
    }
};

pub const ChartData = struct {
    difficulty: enums.Difficulty,
    measures: std.ArrayList(Measure) = .empty,
    fields: std.StringHashMap(std.ArrayList(u8)),
};

fn GetRollStartMeasure(data: ChartData, currentMeasure: Measure) Measure {
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
}

fn GetNearestRollStart(measure: Measure, index: usize) usize {
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
    return -1;
}