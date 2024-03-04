const std = @import("std");
const tzif = @import("tzif");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.log.err("Path to TZif file is required", .{});
        return 1;
    }

    const localtime = try tzif.parseFile(allocator, args[1]);
    defer localtime.deinit();

    std.log.info("TZ string: {s}", .{localtime.string});
    std.log.info("TZif version: {s}", .{localtime.version.string()});

    const now = std.time.timestamp();
    if (localtime.localTimeFromUTC(now)) |result| {
        std.log.info("Current Time: adjusted_ts={}s  ut_offset={}s  dst={}  designation={s}", .{
            result.timestamp,
            result.offset,
            result.is_daylight_saving_time,
            result.designation,
        });
    }

    std.log.info("{} transition times", .{localtime.transitionTimes.len});
    for (0.., localtime.transitionTimes, localtime.transitionTypes) |n, transition, type_index| {
        const info = localtime.localTimeTypes[type_index];
        std.log.info("    [{}]: ts={}s  ut_offset={}s  dst={}  designation={s}", .{
            n,
            transition,
            info.ut_offset,
            info.is_daylight_saving_time,
            localtime.designation(info.designation_index),
        });
    }

    std.log.info("{} leap seconds", .{localtime.leapSeconds.len});
    for (0.., localtime.leapSeconds) |n, leap| {
        std.log.info("    [{}]: {}", .{n, leap});
    }

    return 0;
}
