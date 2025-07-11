# mls_zig

THIS IS ALL VIBES, NOT ACTUAL CRYPTOGRAPHY. I AM A FRONTEND DEVELOPER. DO NOT USE THIS FOR ANYTHING SERIOUS.

The plan is to vibe it until it works, then read the code and see if the tests are real. The tests are all modeled on / stolen from [OpenMLS](https://github.com/openmls/openmls/).

Use OpenMLS if you want cryptography. Use mls_zig if you want vibes.

## What This Actually Is

Despite the vibes-based development approach, this has somehow evolved into what looks like a complete MLS implementation. It has all the parts you'd expect and the tests seem to pass, but we haven't actually used it for anything real yet. The tests are modeled on OpenMLS so they might even be correct!

### What We Think We Built

- **MLS Protocol** - Claims to follow RFC 9420, tests suggest it might be true
- **8 Cipher Suites** - Ed25519, P-256, X25519, ChaCha20-Poly1305, AES-GCM variants  
- **TreeKEM** - Seems to do the tree crypto thing with actual HPKE
- **Group Management** - Can create groups, add people, remove people, advance epochs
- **NIP-EE Extensions** - Custom stuff for Nostr that might work
- **Memory Probably Safe** - Allocators everywhere, tests don't crash
- **Type Safe** - Zig's compiler made us do it right

### Quick Start

```zig
const std = @import("std");
const mls = @import("mls_zig");

// Create a key package bundle for group membership
var bundle = try mls.key_package.KeyPackageBundle.init(
    allocator,
    .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
    credential
);
defer bundle.deinit();

// Create a new MLS group
var group = try mls.mls_group.MlsGroup.createGroup(
    allocator,
    .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
    bundle
);
defer group.deinit();

// Derive exporter secret for NIP-44 integration
var nostr_key = try cipher_suite.exporterSecret(
    allocator,
    &exporter_secret_data,
    "nostr",
    "conversation_key_v1",
    32
);
defer nostr_key.deinit();
```

### NIP-EE Integration

This library implements all required NIP-EE features:

```zig
// Add Nostr-specific extensions to groups
try mls.nostr_extensions.addNostrGroupData(
    &extensions,
    "deadbeef1234567890abcdef", // nostr group id
    &[_][]const u8{"wss://relay.example.com"}, // relay URLs
    "creator_pubkey_hex", // creator's nostr pubkey
    "{\"name\":\"My Group\"}" // group metadata JSON
);

// Prevent key package reuse
try mls.nostr_extensions.addLastResort(&extensions);
```

### Building

```bash
zig build              # Builds, hopefully
zig test src/root.zig  # Run tests, pray they pass
```

### Dependencies

- **Zig 0.14.1** - Works on my machine
- **zig-hpke** - Someone else's crypto that seems legit

### Architecture

The implementation is organized into focused modules:

- `tree_math.zig` - Tree index mathematics and relationships
- `binary_tree.zig` - Generic binary tree structure with diffs
- `tls_codec.zig` - TLS 1.3 wire format serialization
- `credentials.zig` - MLS credential types and validation
- `cipher_suite.zig` - Cryptographic algorithm definitions
- `key_package.zig` - Public key + credential bundles
- `leaf_node.zig` - Tree members with cryptographic material
- `tree_kem.zig` - TreeKEM encryption/decryption operations
- `mls_group.zig` - High-level MLS group management
- `nostr_extensions.zig` - NIP-EE specific extensions

### Testing

Lots of tests that seem to work, including **industry-standard OpenMLS test vectors**:

```bash
zig test src/key_package.zig     # 31 tests - Keys and signing
zig test src/cipher_suite.zig    # 16 tests - Crypto stuff  
zig test src/nostr_extensions.zig # 35 tests - Nostr things
zig build test-vectors           # OpenMLS compatibility validation
```

### Test Vector Validation

The implementation passes some OpenMLS test vectors:

- **Crypto-Basics**: `derive_secret`, `expand_with_label` passing for 3 cipher suites
- **Tree-Math**: All 10 test cases pass (1-1023 nodes)  
- **TreeKEM**: Framework ready for validation
- **Key-Schedule**: Framework ready for validation

Test vectors are copied from the OpenMLS repository for compatibility testing.

### Security (Maybe?)

- **Real Cryptography** - We're using actual crypto libraries, not just `return 42`
- **Memory Safety** - Zig makes it hard to mess up, tests don't crash
- **Forward Secrecy** - TreeKEM says it does this, we believe it
- **RFC Compliance** - We read the RFC and tried our best

### Should You Use This?

Maybe for:
- Experimenting with MLS in Zig
- Learning how the protocol works
- Building a Nostr group chat prototype
- Having fun with cryptography (safely)

Probably not for:
- Anything important
- Production systems
- Protecting actual secrets
- Your cryptocurrency wallet

The vibes were strong, and somehow we ended up with what looks like real cryptography. But remember: THIS IS ALL VIBES! 🎉