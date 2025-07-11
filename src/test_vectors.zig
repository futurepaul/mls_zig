const std = @import("std");
const testing = std.testing;
const json = std.json;
const fmt = std.fmt;

const mls = @import("mls_zig_lib");
const CipherSuite = mls.cipher_suite.CipherSuite;
const tree_math = mls.tree_math;

// Hex conversion utilities
fn hexToBytes(allocator: std.mem.Allocator, hex_string: []const u8) ![]u8 {
    if (hex_string.len % 2 != 0) return error.InvalidHexLength;
    
    const bytes = try allocator.alloc(u8, hex_string.len / 2);
    var i: usize = 0;
    while (i < hex_string.len) : (i += 2) {
        bytes[i / 2] = try fmt.parseInt(u8, hex_string[i..i + 2], 16);
    }
    return bytes;
}

fn bytesToHex(allocator: std.mem.Allocator, bytes: []const u8) ![]u8 {
    const hex = try allocator.alloc(u8, bytes.len * 2);
    for (bytes, 0..) |byte, i| {
        _ = try fmt.bufPrint(hex[i * 2..i * 2 + 2], "{x:0>2}", .{byte});
    }
    return hex;
}

/// Test vector runner for OpenMLS test vectors
pub const TestVectorRunner = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) TestVectorRunner {
        return TestVectorRunner{
            .allocator = allocator,
        };
    }
    
    /// Run crypto basics test vectors
    pub fn runCryptoBasics(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("crypto-basics.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} crypto-basics test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const cipher_suite_num = test_case.object.get("cipher_suite").?.integer;
            
            // Convert cipher suite number to enum
            const cipher_suite: CipherSuite = @enumFromInt(@as(u16, @intCast(cipher_suite_num)));
            
            // Skip unsupported cipher suites
            if (!cipher_suite.isSupported()) {
                std.log.info("Skipping unsupported cipher suite: {}", .{cipher_suite_num});
                continue;
            }
            
            std.log.info("Testing cipher suite: {} ({})", .{ cipher_suite_num, cipher_suite });
            
            // Test derive_secret
            if (test_case.object.get("derive_secret")) |derive_secret| {
                try self.testDeriveSecret(cipher_suite, derive_secret);
            }
            
            // Test expand_with_label
            if (test_case.object.get("expand_with_label")) |expand_with_label| {
                try self.testExpandWithLabel(cipher_suite, expand_with_label);
            }
            
            // Test derive_tree_secret
            if (test_case.object.get("derive_tree_secret")) |derive_tree_secret| {
                try self.testDeriveTreeSecret(cipher_suite, derive_tree_secret);
            }
        }
    }
    
    /// Run tree math test vectors
    pub fn runTreeMath(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("tree-math.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} tree-math test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const n_leaves = test_case.object.get("n_leaves").?.integer;
            const n_nodes = test_case.object.get("n_nodes").?.integer;
            
            std.log.info("Testing tree with {} leaves, {} nodes", .{ n_leaves, n_nodes });
            
            // Test tree structure calculations
            try self.testTreeStructure(@intCast(n_leaves), @intCast(n_nodes));
        }
    }
    
    /// Run TreeKEM test vectors
    pub fn runTreeKEM(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("treekem.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} TreeKEM test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const cipher_suite = test_case.object.get("cipher_suite").?.integer;
            const epoch = test_case.object.get("epoch").?.integer;
            
            std.log.info("Testing TreeKEM cipher suite: {}, epoch: {}", .{ cipher_suite, epoch });
            
            // Test TreeKEM operations
            try self.testTreeKEMOperations(test_case);
        }
    }
    
    /// Run key schedule test vectors
    pub fn runKeySchedule(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("key-schedule.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} key-schedule test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const cipher_suite = test_case.object.get("cipher_suite").?.integer;
            std.log.info("Testing key schedule cipher suite: {}", .{cipher_suite});
            
            // Test key schedule epochs
            if (test_case.object.get("epochs")) |epochs| {
                for (epochs.array.items) |epoch| {
                    try self.testKeyScheduleEpoch(epoch);
                }
            }
        }
    }
    
    /// Run secret tree test vectors
    pub fn runSecretTree(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("secret-tree.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} secret-tree test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const cipher_suite = test_case.object.get("cipher_suite").?.integer;
            std.log.info("Testing secret tree cipher suite: {}", .{cipher_suite});
            
            try self.testSecretTreeOperations(test_case);
        }
    }
    
    /// Run message protection test vectors
    pub fn runMessageProtection(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("message-protection.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} message-protection test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const cipher_suite = test_case.object.get("cipher_suite").?.integer;
            std.log.info("Testing message protection cipher suite: {}", .{cipher_suite});
            
            try self.testMessageProtectionOperations(test_case);
        }
    }
    
    /// Run welcome message test vectors
    pub fn runWelcome(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("welcome.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} welcome test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            const cipher_suite = test_case.object.get("cipher_suite").?.integer;
            std.log.info("Testing welcome cipher suite: {}", .{cipher_suite});
            
            try self.testWelcomeOperations(test_case);
        }
    }
    
    /// Run MLS messages test vectors
    pub fn runMessages(self: *const TestVectorRunner) !void {
        const file_content = try self.readTestVector("messages.json");
        defer self.allocator.free(file_content);
        
        const parsed = try json.parseFromSlice(json.Value, self.allocator, file_content, .{});
        defer parsed.deinit();
        
        const test_cases = parsed.value.array;
        std.log.info("Running {} messages test cases", .{test_cases.items.len});
        
        for (test_cases.items) |test_case| {
            std.log.info("Testing message operations", .{});
            
            try self.testMessageOperations(test_case);
        }
    }
    
    // Helper functions for reading test vectors
    fn readTestVector(self: *const TestVectorRunner, filename: []const u8) ![]u8 {
        const path = try std.fmt.allocPrint(self.allocator, "test_vectors/{s}", .{filename});
        defer self.allocator.free(path);
        
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.log.err("Failed to open test vector file: {s}", .{path});
            return err;
        };
        defer file.close();
        
        const file_size = try file.getEndPos();
        const content = try self.allocator.alloc(u8, file_size);
        _ = try file.readAll(content);
        
        return content;
    }
    
    // Test implementations - now with actual crypto validation!
    fn testDeriveSecret(self: *const TestVectorRunner, cipher_suite: CipherSuite, derive_secret: json.Value) !void {
        const label = derive_secret.object.get("label").?.string;
        const secret_hex = derive_secret.object.get("secret").?.string;
        const expected_hex = derive_secret.object.get("out").?.string;
        
        // Convert hex strings to bytes
        const secret_bytes = try hexToBytes(self.allocator, secret_hex);
        defer self.allocator.free(secret_bytes);
        
        const expected_bytes = try hexToBytes(self.allocator, expected_hex);
        defer self.allocator.free(expected_bytes);
        
        // Call the actual deriveSecret function (with empty context)
        var result = try cipher_suite.deriveSecret(self.allocator, secret_bytes, label, &[_]u8{});
        defer result.deinit();
        
        // Compare results
        if (std.mem.eql(u8, expected_bytes, result.asSlice())) {
            std.log.info("  ✅ derive_secret PASSED: label={s}", .{label});
        } else {
            const result_hex = try bytesToHex(self.allocator, result.asSlice());
            defer self.allocator.free(result_hex);
            std.log.err("  ❌ derive_secret FAILED: label={s}", .{label});
            std.log.err("    Expected: {s}", .{expected_hex});
            std.log.err("    Got:      {s}", .{result_hex});
            return error.TestFailed;
        }
    }
    
    fn testExpandWithLabel(self: *const TestVectorRunner, cipher_suite: CipherSuite, expand_with_label: json.Value) !void {
        const label = expand_with_label.object.get("label").?.string;
        const length = expand_with_label.object.get("length").?.integer;
        const secret_hex = expand_with_label.object.get("secret").?.string;
        const context_hex = expand_with_label.object.get("context").?.string;
        const expected_hex = expand_with_label.object.get("out").?.string;
        
        // Convert hex strings to bytes
        const secret_bytes = try hexToBytes(self.allocator, secret_hex);
        defer self.allocator.free(secret_bytes);
        
        const context_bytes = try hexToBytes(self.allocator, context_hex);
        defer self.allocator.free(context_bytes);
        
        const expected_bytes = try hexToBytes(self.allocator, expected_hex);
        defer self.allocator.free(expected_bytes);
        
        // Call the actual hkdfExpandLabel function
        var result = try cipher_suite.hkdfExpandLabel(self.allocator, secret_bytes, label, context_bytes, @intCast(length));
        defer result.deinit();
        
        // Compare results
        if (std.mem.eql(u8, expected_bytes, result.asSlice())) {
            std.log.info("  ✅ expand_with_label PASSED: label={s}, length={}", .{ label, length });
        } else {
            const result_hex = try bytesToHex(self.allocator, result.asSlice());
            defer self.allocator.free(result_hex);
            std.log.err("  ❌ expand_with_label FAILED: label={s}", .{label});
            std.log.err("    Expected: {s}", .{expected_hex});
            std.log.err("    Got:      {s}", .{result_hex});
            return error.TestFailed;
        }
    }
    
    fn testDeriveTreeSecret(self: *const TestVectorRunner, cipher_suite: CipherSuite, derive_tree_secret: json.Value) !void {
        _ = self;
        _ = cipher_suite;
        const label = derive_tree_secret.object.get("label").?.string;
        const generation = derive_tree_secret.object.get("generation").?.integer;
        const length = derive_tree_secret.object.get("length").?.integer;
        const expected_out = derive_tree_secret.object.get("out").?.string;
        
        std.log.info("  🚧 derive_tree_secret TODO: label={s}, gen={}, len={}, expected={s}", .{ label, generation, length, expected_out });
        // TODO: Implement actual derive_tree_secret test when the function is available
    }
    
    fn testTreeStructure(self: *const TestVectorRunner, n_leaves: u32, n_nodes: u32) !void {
        _ = self;
        
        // For a binary tree with n_leaves leaf nodes, the total number of nodes should be 2*n_leaves - 1
        // This is the standard formula for complete binary trees
        const calculated_nodes = 2 * n_leaves - 1;
        
        if (calculated_nodes == n_nodes) {
            std.log.info("  ✅ tree_structure PASSED: leaves={}, nodes={}", .{ n_leaves, n_nodes });
        } else {
            std.log.err("  ❌ tree_structure FAILED: leaves={}", .{n_leaves});
            std.log.err("    Expected nodes: {}", .{n_nodes});
            std.log.err("    Got nodes:      {}", .{calculated_nodes});
            return error.TestFailed;
        }
    }
    
    fn testTreeKEMOperations(self: *const TestVectorRunner, test_case: json.Value) !void {
        _ = self;
        _ = test_case;
        std.log.info("  TreeKEM operations test", .{});
        // TODO: Implement TreeKEM operations test
    }
    
    fn testKeyScheduleEpoch(self: *const TestVectorRunner, epoch: json.Value) !void {
        _ = self;
        _ = epoch;
        std.log.info("  key_schedule epoch test", .{});
        // TODO: Implement key schedule epoch test
    }
    
    fn testSecretTreeOperations(self: *const TestVectorRunner, test_case: json.Value) !void {
        _ = self;
        _ = test_case;
        std.log.info("  secret_tree operations test", .{});
        // TODO: Implement secret tree operations test
    }
    
    fn testMessageProtectionOperations(self: *const TestVectorRunner, test_case: json.Value) !void {
        _ = self;
        _ = test_case;
        std.log.info("  message_protection operations test", .{});
        // TODO: Implement message protection operations test
    }
    
    fn testWelcomeOperations(self: *const TestVectorRunner, test_case: json.Value) !void {
        _ = self;
        _ = test_case;
        std.log.info("  welcome operations test", .{});
        // TODO: Implement welcome operations test
    }
    
    fn testMessageOperations(self: *const TestVectorRunner, test_case: json.Value) !void {
        _ = self;
        _ = test_case;
        std.log.info("  message operations test", .{});
        // TODO: Implement message operations test
    }
};

// Test runner functions
test "crypto-basics test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runCryptoBasics();
}

test "tree-math test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runTreeMath();
}

test "treekem test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runTreeKEM();
}

test "key-schedule test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runKeySchedule();
}

test "secret-tree test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runSecretTree();
}

test "message-protection test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runMessageProtection();
}

test "welcome test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runWelcome();
}

test "messages test vectors" {
    var runner = TestVectorRunner.init(testing.allocator);
    try runner.runMessages();
}

// Convenience function to run all test vectors
pub fn runAllTestVectors(allocator: std.mem.Allocator) !void {
    var runner = TestVectorRunner.init(allocator);
    
    std.log.info("Starting OpenMLS test vector validation...", .{});
    
    try runner.runCryptoBasics();
    try runner.runTreeMath();
    try runner.runTreeKEM();
    try runner.runKeySchedule();
    try runner.runSecretTree();
    try runner.runMessageProtection();
    try runner.runWelcome();
    try runner.runMessages();
    
    std.log.info("All test vectors completed!", .{});
}