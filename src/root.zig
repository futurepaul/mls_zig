//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

pub const tree_math = @import("tree_math.zig");
pub const binary_tree = @import("binary_tree.zig");
pub const binary_tree_diff = @import("binary_tree_diff.zig");
pub const tls_codec = @import("tls_codec.zig");
pub const credentials = @import("credentials.zig");
pub const cipher_suite = @import("cipher_suite.zig");
pub const key_package = @import("key_package.zig");
pub const leaf_node = @import("leaf_node.zig");
pub const tree_kem = @import("tree_kem.zig");
pub const mls_group = @import("mls_group.zig");

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
