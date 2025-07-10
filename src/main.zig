const std = @import("std");
const mls_zig_lib = @import("mls_zig_lib");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    
    const result = mls_zig_lib.add(5, 3);
    
    try stdout.print("Hello from MLS Zig!\n", .{});
    try stdout.print("Testing library function: add(5, 3) = {}\n", .{result});
}