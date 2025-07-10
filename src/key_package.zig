const std = @import("std");
const testing = std.testing;
const crypto = std.crypto;
const Allocator = std.mem.Allocator;

const tls_codec = @import("tls_codec.zig");
const cipher_suite = @import("cipher_suite.zig");
const credentials = @import("credentials.zig");

pub const MLS_PROTOCOL_VERSION: u16 = 0x0001;

pub const HpkePublicKey = struct {
    data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, key_data: []const u8) !HpkePublicKey {
        const data = try allocator.dupe(u8, key_data);
        return HpkePublicKey{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HpkePublicKey) void {
        self.allocator.free(self.data);
        self.data = &[_]u8{};
    }

    pub fn asSlice(self: HpkePublicKey) []const u8 {
        return self.data;
    }

    pub fn len(self: HpkePublicKey) usize {
        return self.data.len;
    }
};

pub const HpkePrivateKey = struct {
    data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, key_data: []const u8) !HpkePrivateKey {
        const data = try allocator.dupe(u8, key_data);
        return HpkePrivateKey{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HpkePrivateKey) void {
        crypto.secureZero(u8, self.data);
        self.allocator.free(self.data);
        self.data = &[_]u8{};
    }

    pub fn asSlice(self: HpkePrivateKey) []const u8 {
        return self.data;
    }

    pub fn len(self: HpkePrivateKey) usize {
        return self.data.len;
    }
};

pub const SignaturePublicKey = struct {
    data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, key_data: []const u8) !SignaturePublicKey {
        const data = try allocator.dupe(u8, key_data);
        return SignaturePublicKey{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SignaturePublicKey) void {
        self.allocator.free(self.data);
        self.data = &[_]u8{};
    }

    pub fn asSlice(self: SignaturePublicKey) []const u8 {
        return self.data;
    }

    pub fn len(self: SignaturePublicKey) usize {
        return self.data.len;
    }
};

pub const SignaturePrivateKey = struct {
    data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, key_data: []const u8) !SignaturePrivateKey {
        const data = try allocator.dupe(u8, key_data);
        return SignaturePrivateKey{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SignaturePrivateKey) void {
        crypto.secureZero(u8, self.data);
        self.allocator.free(self.data);
        self.data = &[_]u8{};
    }

    pub fn asSlice(self: SignaturePrivateKey) []const u8 {
        return self.data;
    }

    pub fn len(self: SignaturePrivateKey) usize {
        return self.data.len;
    }
};

pub const Signature = struct {
    data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, signature_data: []const u8) !Signature {
        const data = try allocator.dupe(u8, signature_data);
        return Signature{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Signature) void {
        self.allocator.free(self.data);
        self.data = &[_]u8{};
    }

    pub fn asSlice(self: Signature) []const u8 {
        return self.data;
    }

    pub fn len(self: Signature) usize {
        return self.data.len;
    }
};

pub const Lifetime = struct {
    not_before: u64,
    not_after: u64,

    pub fn init(not_before: u64, not_after: u64) Lifetime {
        return Lifetime{
            .not_before = not_before,
            .not_after = not_after,
        };
    }

    pub fn isValid(self: Lifetime, current_time: u64) bool {
        return current_time >= self.not_before and current_time <= self.not_after;
    }
};

pub const LeafNodeSource = union(enum) {
    key_package: Lifetime,
    update: void,
    commit: []u8,

    pub fn deinit(self: *LeafNodeSource, allocator: Allocator) void {
        switch (self.*) {
            .commit => |parent_hash| allocator.free(parent_hash),
            else => {},
        }
    }
};

pub const Capabilities = struct {
    versions: []u16,
    cipher_suites: []cipher_suite.CipherSuite,
    extensions: []u16,
    proposals: []u8,
    credentials: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Capabilities {
        return Capabilities{
            .versions = &[_]u16{},
            .cipher_suites = &[_]cipher_suite.CipherSuite{},
            .extensions = &[_]u16{},
            .proposals = &[_]u8{},
            .credentials = &[_]u8{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Capabilities) void {
        self.allocator.free(self.versions);
        self.allocator.free(self.cipher_suites);
        self.allocator.free(self.extensions);
        self.allocator.free(self.proposals);
        self.allocator.free(self.credentials);
    }

    pub fn supportsVersion(self: Capabilities, version: u16) bool {
        for (self.versions) |v| {
            if (v == version) return true;
        }
        return false;
    }

    pub fn supportsCipherSuite(self: Capabilities, cs: cipher_suite.CipherSuite) bool {
        for (self.cipher_suites) |suite| {
            if (suite == cs) return true;
        }
        return false;
    }
};

pub const Extension = struct {
    extension_type: u16,
    extension_data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, ext_type: u16, data: []const u8) !Extension {
        const extension_data = try allocator.dupe(u8, data);
        return Extension{
            .extension_type = ext_type,
            .extension_data = extension_data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Extension) void {
        self.allocator.free(self.extension_data);
        self.extension_data = &[_]u8{};
    }
};

pub const Extensions = struct {
    extensions: []Extension,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Extensions {
        return Extensions{
            .extensions = &[_]Extension{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Extensions) void {
        for (self.extensions) |*ext| {
            ext.deinit();
        }
        self.allocator.free(self.extensions);
    }

    pub fn addExtension(self: *Extensions, extension: Extension) !void {
        const new_extensions = try self.allocator.realloc(self.extensions, self.extensions.len + 1);
        new_extensions[self.extensions.len] = extension;
        self.extensions = new_extensions;
    }

    pub fn findExtension(self: Extensions, ext_type: u16) ?*const Extension {
        for (self.extensions) |*ext| {
            if (ext.extension_type == ext_type) return ext;
        }
        return null;
    }
};

pub const LeafNode = struct {
    encryption_key: HpkePublicKey,
    signature_key: SignaturePublicKey,
    credential: credentials.Credential,
    capabilities: Capabilities,
    leaf_node_source: LeafNodeSource,
    extensions: Extensions,
    signature: Signature,

    pub fn deinit(self: *LeafNode) void {
        self.encryption_key.deinit();
        self.signature_key.deinit();
        self.credential.deinit();
        self.capabilities.deinit();
        self.leaf_node_source.deinit(self.capabilities.allocator);
        self.extensions.deinit();
        self.signature.deinit();
    }
};

pub const KeyPackageTBS = struct {
    protocol_version: u16,
    cipher_suite: cipher_suite.CipherSuite,
    init_key: HpkePublicKey,
    leaf_node: LeafNode,
    extensions: Extensions,

    pub fn deinit(self: *KeyPackageTBS) void {
        self.init_key.deinit();
        self.leaf_node.deinit();
        self.extensions.deinit();
    }
};

pub const KeyPackage = struct {
    payload: KeyPackageTBS,
    signature: Signature,

    pub fn deinit(self: *KeyPackage) void {
        self.payload.deinit();
        self.signature.deinit();
    }

    pub fn cipherSuite(self: KeyPackage) cipher_suite.CipherSuite {
        return self.payload.cipher_suite;
    }

    pub fn protocolVersion(self: KeyPackage) u16 {
        return self.payload.protocol_version;
    }

    pub fn initKey(self: KeyPackage) *const HpkePublicKey {
        return &self.payload.init_key;
    }

    pub fn leafNode(self: KeyPackage) *const LeafNode {
        return &self.payload.leaf_node;
    }

    pub fn encryptionKey(self: KeyPackage) *const HpkePublicKey {
        return &self.payload.leaf_node.encryption_key;
    }

    pub fn signatureKey(self: KeyPackage) *const SignaturePublicKey {
        return &self.payload.leaf_node.signature_key;
    }

    pub fn credential(self: KeyPackage) *const credentials.Credential {
        return &self.payload.leaf_node.credential;
    }
};

pub const KeyPackageBundle = struct {
    key_package: KeyPackage,
    private_init_key: HpkePrivateKey,
    private_encryption_key: HpkePrivateKey,
    private_signature_key: SignaturePrivateKey,

    pub fn deinit(self: *KeyPackageBundle) void {
        self.key_package.deinit();
        self.private_init_key.deinit();
        self.private_encryption_key.deinit();
        self.private_signature_key.deinit();
    }
};

pub const KeyPair = struct {
    public_key: []u8,
    private_key: []u8,
    allocator: Allocator,

    pub fn deinit(self: *KeyPair) void {
        self.allocator.free(self.public_key);
        crypto.secureZero(u8, self.private_key);
        self.allocator.free(self.private_key);
        self.public_key = &[_]u8{};
        self.private_key = &[_]u8{};
    }
};

pub fn generateSignatureKeyPair(
    allocator: Allocator,
    cs: cipher_suite.CipherSuite,
) !KeyPair {
    return switch (cs.signatureScheme()) {
        .ED25519 => {
            const key_pair = crypto.sign.Ed25519.KeyPair.generate();
            
            const public_key = try allocator.dupe(u8, &key_pair.public_key.toBytes());
            const private_key = try allocator.dupe(u8, &key_pair.secret_key.toBytes());
            
            return KeyPair{
                .public_key = public_key,
                .private_key = private_key,
                .allocator = allocator,
            };
        },
        .ECDSA_SECP256R1_SHA256 => {
            const private_scalar = crypto.ecc.P256.scalar.random(.big);
            const public_point = crypto.ecc.P256.basePoint.mul(private_scalar, .big) catch return error.InvalidKeyGeneration;
            
            const public_bytes = public_point.toUncompressedSec1();
            
            const public_key = try allocator.dupe(u8, &public_bytes);
            const private_key = try allocator.dupe(u8, &private_scalar);
            
            return KeyPair{
                .public_key = public_key,
                .private_key = private_key,
                .allocator = allocator,
            };
        },
        else => error.UnsupportedSignatureScheme,
    };
}

pub fn generateHpkeKeyPair(
    allocator: Allocator,
    cs: cipher_suite.CipherSuite,
) !KeyPair {
    return switch (cs.hpkeKemType()) {
        .DHKEMX25519 => {
            const key_pair = crypto.dh.X25519.KeyPair.generate();
            
            const public_key = try allocator.dupe(u8, &key_pair.public_key);
            const private_key = try allocator.dupe(u8, &key_pair.secret_key);
            
            return KeyPair{
                .public_key = public_key,
                .private_key = private_key,
                .allocator = allocator,
            };
        },
        .DHKEMP256 => {
            const private_scalar = crypto.ecc.P256.scalar.random(.big);
            const public_point = crypto.ecc.P256.basePoint.mul(private_scalar, .big) catch return error.InvalidKeyGeneration;
            
            const public_bytes = public_point.toUncompressedSec1();
            
            const public_key = try allocator.dupe(u8, &public_bytes);
            const private_key = try allocator.dupe(u8, &private_scalar);
            
            return KeyPair{
                .public_key = public_key,
                .private_key = private_key,
                .allocator = allocator,
            };
        },
        else => error.UnsupportedHpkeKemType,
    };
}

pub fn signWithLabel(
    allocator: Allocator,
    cs: cipher_suite.CipherSuite,
    private_key: []const u8,
    label: []const u8,
    content: []const u8,
) !Signature {
    var sign_content = std.ArrayList(u8).init(allocator);
    defer sign_content.deinit();

    var tls_writer = tls_codec.TlsWriter(@TypeOf(sign_content.writer())).init(sign_content.writer());
    
    const full_label = try std.fmt.allocPrint(allocator, "{s}{s}", .{ cipher_suite.MLS_LABEL_PREFIX, label });
    defer allocator.free(full_label);
    
    try tls_writer.writeVarBytes(u8, full_label);
    try tls_writer.writeVarBytes(u32, content);

    const signature_data = switch (cs.signatureScheme()) {
        .ED25519 => blk: {
            if (private_key.len != 64) return error.InvalidPrivateKeySize;
            
            const secret_key = crypto.sign.Ed25519.SecretKey.fromBytes(private_key[0..64].*) catch return error.InvalidPrivateKey;
            const key_pair = crypto.sign.Ed25519.KeyPair.fromSecretKey(secret_key) catch return error.InvalidPrivateKey;
            const signature = key_pair.sign(sign_content.items, null) catch return error.SigningFailed;
            
            const sig_bytes = signature.toBytes();
            break :blk try allocator.dupe(u8, &sig_bytes);
        },
        .ECDSA_SECP256R1_SHA256 => blk: {
            if (private_key.len != 32) return error.InvalidPrivateKeySize;
            
            var hash: [32]u8 = undefined;
            crypto.hash.sha2.Sha256.hash(sign_content.items, &hash, .{});
            
            const secret_key = crypto.sign.ecdsa.EcdsaP256Sha256.SecretKey.fromBytes(private_key[0..32].*) catch return error.InvalidPrivateKey;
            const key_pair = crypto.sign.ecdsa.EcdsaP256Sha256.KeyPair.fromSecretKey(secret_key) catch return error.InvalidPrivateKey;
            const signature = key_pair.sign(sign_content.items, null) catch return error.SigningFailed;
            
            const sig_bytes = signature.toBytes();
            break :blk try allocator.dupe(u8, &sig_bytes);
        },
        else => return error.UnsupportedSignatureScheme,
    };

    defer allocator.free(signature_data);
    return Signature.init(allocator, signature_data);
}

pub fn verifyWithLabel(
    cs: cipher_suite.CipherSuite,
    public_key: []const u8,
    signature: []const u8,
    label: []const u8,
    content: []const u8,
    allocator: Allocator,
) !bool {
    var sign_content = std.ArrayList(u8).init(allocator);
    defer sign_content.deinit();

    var tls_writer = tls_codec.TlsWriter(@TypeOf(sign_content.writer())).init(sign_content.writer());
    
    const full_label = try std.fmt.allocPrint(allocator, "{s}{s}", .{ cipher_suite.MLS_LABEL_PREFIX, label });
    defer allocator.free(full_label);
    
    try tls_writer.writeVarBytes(u8, full_label);
    try tls_writer.writeVarBytes(u32, content);

    return switch (cs.signatureScheme()) {
        .ED25519 => blk: {
            if (public_key.len != 32 or signature.len != 64) break :blk false;
            
            const pub_key = crypto.sign.Ed25519.PublicKey.fromBytes(public_key[0..32].*) catch break :blk false;
            const sig = crypto.sign.Ed25519.Signature.fromBytes(signature[0..64].*);
            
            sig.verify(sign_content.items, pub_key) catch break :blk false;
            break :blk true;
        },
        .ECDSA_SECP256R1_SHA256 => blk: {
            if (public_key.len != 65 or signature.len != 64) break :blk false;
            
            const pub_key = crypto.sign.ecdsa.EcdsaP256Sha256.PublicKey.fromSec1(public_key) catch break :blk false;
            const sig = crypto.sign.ecdsa.EcdsaP256Sha256.Signature.fromBytes(signature[0..64].*);
            sig.verify(sign_content.items, pub_key) catch break :blk false;
            break :blk true;
        },
        else => false,
    };
}

test "key package structures" {
    const allocator = testing.allocator;
    
    const test_key_data = [_]u8{ 0x01, 0x02, 0x03, 0x04 };
    var hpke_key = try HpkePublicKey.init(allocator, &test_key_data);
    defer hpke_key.deinit();
    
    try testing.expectEqual(@as(usize, 4), hpke_key.len());
    try testing.expectEqualSlices(u8, &test_key_data, hpke_key.asSlice());
}

test "capabilities" {
    const allocator = testing.allocator;
    
    var caps = Capabilities.init(allocator);
    defer caps.deinit();
    
    try testing.expect(caps.supportsVersion(MLS_PROTOCOL_VERSION) == false);
    try testing.expect(caps.supportsCipherSuite(.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519) == false);
}

test "extensions" {
    const allocator = testing.allocator;
    
    var extensions = Extensions.init(allocator);
    defer extensions.deinit();
    
    const test_data = [_]u8{ 0xaa, 0xbb, 0xcc };
    const ext = try Extension.init(allocator, 0x1234, &test_data);
    try extensions.addExtension(ext);
    
    const found = extensions.findExtension(0x1234);
    try testing.expect(found != null);
    try testing.expectEqual(@as(u16, 0x1234), found.?.extension_type);
    try testing.expectEqualSlices(u8, &test_data, found.?.extension_data);
}

test "lifetime validation" {
    const lifetime = Lifetime.init(1000, 2000);
    
    try testing.expect(lifetime.isValid(1500) == true);
    try testing.expect(lifetime.isValid(500) == false);
    try testing.expect(lifetime.isValid(2500) == false);
    try testing.expect(lifetime.isValid(1000) == true);
    try testing.expect(lifetime.isValid(2000) == true);
}

test "ed25519 key generation" {
    const allocator = testing.allocator;
    const cs = cipher_suite.CipherSuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;
    
    var key_pair = try generateSignatureKeyPair(allocator, cs);
    defer key_pair.deinit();
    
    try testing.expectEqual(@as(usize, 32), key_pair.public_key.len);
    try testing.expectEqual(@as(usize, 64), key_pair.private_key.len);
}

test "p256 key generation" {
    const allocator = testing.allocator;
    const cs = cipher_suite.CipherSuite.MLS_128_DHKEMP256_AES128GCM_SHA256_P256;
    
    var key_pair = try generateSignatureKeyPair(allocator, cs);
    defer key_pair.deinit();
    
    try testing.expectEqual(@as(usize, 65), key_pair.public_key.len);
    try testing.expectEqual(@as(usize, 32), key_pair.private_key.len);
}

test "x25519 hpke key generation" {
    const allocator = testing.allocator;
    const cs = cipher_suite.CipherSuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;
    
    var key_pair = try generateHpkeKeyPair(allocator, cs);
    defer key_pair.deinit();
    
    try testing.expectEqual(@as(usize, 32), key_pair.public_key.len);
    try testing.expectEqual(@as(usize, 32), key_pair.private_key.len);
}

test "ed25519 signing and verification" {
    const allocator = testing.allocator;
    const cs = cipher_suite.CipherSuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;
    
    var key_pair = try generateSignatureKeyPair(allocator, cs);
    defer key_pair.deinit();
    
    const test_content = "test message";
    const test_label = "test_label";
    
    var signature = try signWithLabel(allocator, cs, key_pair.private_key, test_label, test_content);
    defer signature.deinit();
    
    const is_valid = try verifyWithLabel(cs, key_pair.public_key, signature.asSlice(), test_label, test_content, allocator);
    try testing.expect(is_valid);
    
    const is_invalid = try verifyWithLabel(cs, key_pair.public_key, signature.asSlice(), "wrong_label", test_content, allocator);
    try testing.expect(!is_invalid);
}

test "p256 signing and verification" {
    const allocator = testing.allocator;
    const cs = cipher_suite.CipherSuite.MLS_128_DHKEMP256_AES128GCM_SHA256_P256;
    
    var key_pair = try generateSignatureKeyPair(allocator, cs);
    defer key_pair.deinit();
    
    const test_content = "test message";
    const test_label = "test_label";
    
    var signature = try signWithLabel(allocator, cs, key_pair.private_key, test_label, test_content);
    defer signature.deinit();
    
    const is_valid = try verifyWithLabel(cs, key_pair.public_key, signature.asSlice(), test_label, test_content, allocator);
    try testing.expect(is_valid);
    
    const is_invalid = try verifyWithLabel(cs, key_pair.public_key, signature.asSlice(), "wrong_label", test_content, allocator);
    try testing.expect(!is_invalid);
}