const std = @import("std");
const mls = @import("mls_zig");

/// Demonstrate HMAC support for Nostr authentication and message integrity
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("=== HMAC for Nostr Authentication ===", .{});

    const cipher_suite = mls.CipherSuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;

    // Example 1: Message authentication for Nostr events
    std.log.info("1. Nostr event authentication...", .{});
    
    const secret_key = "my_secret_authentication_key";
    const nostr_event = "{\"id\":\"abc123\",\"pubkey\":\"user123\",\"content\":\"Hello Nostr!\"}";
    
    var auth_tag = try cipher_suite.hmac(allocator, secret_key, nostr_event);
    defer auth_tag.deinit();
    
    std.log.info("   Event: {s}", .{nostr_event[0..30]});
    std.log.info("   HMAC:  {x}", .{auth_tag.asSlice()[0..8]});

    // Example 2: Relay authentication
    std.log.info("2. Relay authentication...", .{});
    
    const relay_secret = "relay_shared_secret_2024";
    const auth_message = "AUTH:user123:1704063600";
    
    var relay_auth = try cipher_suite.hmac(allocator, relay_secret, auth_message);
    defer relay_auth.deinit();
    
    std.log.info("   Auth message: {s}", .{auth_message});
    std.log.info("   HMAC token:   {x}", .{relay_auth.asSlice()[0..8]});

    // Example 3: Channel integrity for encrypted DMs
    std.log.info("3. DM integrity protection...", .{});
    
    const channel_key = "dm_channel_integrity_key";
    const encrypted_dm = "nip44_encrypted_content_here_base64";
    
    var integrity_tag = try cipher_suite.hmac(allocator, channel_key, encrypted_dm);
    defer integrity_tag.deinit();
    
    std.log.info("   Encrypted DM: {s}", .{encrypted_dm[0..20]});
    std.log.info("   Integrity:    {x}", .{integrity_tag.asSlice()[0..8]});

    // Example 4: Multiple hash functions for different security levels
    std.log.info("4. Different hash functions...", .{});
    
    const test_cases = [_]struct { 
        name: []const u8, 
        cs: mls.CipherSuite, 
        expected_len: usize 
    }{
        .{ .name = "SHA-256", .cs = .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519, .expected_len = 32 },
        .{ .name = "SHA-384", .cs = .MLS_256_DHKEMP384_AES256GCM_SHA384_P384, .expected_len = 48 },
        .{ .name = "SHA-512", .cs = .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448, .expected_len = 64 },
    };
    
    const message = "same message, different hash functions";
    const key = "test_key";
    
    for (test_cases) |test_case| {
        var hmac_result = try test_case.cs.hmac(allocator, key, message);
        defer hmac_result.deinit();
        
        std.log.info("   {s}: {} bytes, {x}", .{ 
            test_case.name, 
            hmac_result.len(), 
            hmac_result.asSlice()[0..8] 
        });
    }

    // Example 5: HMAC verification pattern
    std.log.info("5. HMAC verification...", .{});
    
    const verification_key = "verification_secret";
    const original_message = "important nostr message";
    
    // Create HMAC
    var original_hmac = try cipher_suite.hmac(allocator, verification_key, original_message);
    defer original_hmac.deinit();
    
    // Verify HMAC (simulate receiving the message and tag)
    var verification_hmac = try cipher_suite.hmac(allocator, verification_key, original_message);
    defer verification_hmac.deinit();
    
    const is_valid = original_hmac.eql(verification_hmac);
    std.log.info("   Message valid: {}", .{is_valid});
    
    // Test with tampered message
    const tampered_message = "important nostr message!"; // Added exclamation
    var tampered_hmac = try cipher_suite.hmac(allocator, verification_key, tampered_message);
    defer tampered_hmac.deinit();
    
    const tampered_valid = original_hmac.eql(tampered_hmac);
    std.log.info("   Tampered valid: {}", .{tampered_valid});

    std.log.info("🔐 HMAC support ready for Nostr authentication!", .{});
}