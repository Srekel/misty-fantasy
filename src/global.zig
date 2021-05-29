pub const print = @import("std").debug.print;

pub fn println(comptime line: []const u8) void {
    print(line ++ "\n", .{});
}
