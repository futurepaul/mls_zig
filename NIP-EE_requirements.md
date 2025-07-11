# NIP-EE MLS Implementation Requirements

This document outlines the specific MLS subset needed to implement NIP-EE (Nostr Event Encryption) based on analysis of the [NIP-EE specification](https://github.com/nostr-protocol/nips/blob/001c516f7294308143515a494a35213fc45978df/EE.md) and [MLS RFC 9420](https://www.rfc-editor.org/rfc/rfc9420.html).

## Executive Summary

NIP-EE uses **MLS for key management only** - actual message encryption uses NIP-44. This significantly simplifies the MLS implementation requirements, focusing on group membership, key derivation, and forward secrecy rather than full MLS message processing.

**Implementation Status**: Our current Phase 4 implementation covers ~70% of NIP-EE requirements. The remaining work aligns with our planned Phase 5 roadmap.

## Core MLS Components Required

### 1. Cipher Suite Support ✅ **IMPLEMENTED**

**Requirements:**
- Support any MLS-compliant cipher suite
- NIP-EE doesn't mandate specific algorithms

**Current Status:**
- ✅ Ed25519 signature support
- ✅ P-256 ECDSA support  
- ✅ X25519 HPKE support
- ✅ ChaCha20-Poly1305 and AES-GCM variants
- ✅ Complete cipher suite framework

**Recommendation:** Start with `MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519` (Cipher Suite 0x0001)

### 2. Key Package Operations ✅ **MOSTLY IMPLEMENTED**

**Requirements:**
- KeyPackage creation and validation
- BasicCredential support (required by NIP-EE)
- MLS extensions framework
- Nostr-specific extensions

**Current Status:**
- ✅ KeyPackage and KeyPackageBundle structures
- ✅ BasicCredential implementation
- ✅ Extensions framework
- ❌ **TODO**: Nostr-specific extensions

**Missing Components:**
- `nostr_group_data` extension (custom for Nostr identity)
- `last_resort` extension (prevents key package reuse)

### 3. Required MLS Extensions ⚠️ **PARTIALLY IMPLEMENTED**

NIP-EE mandates these extensions:

#### 3.1 `required_capabilities` ✅ **FRAMEWORK EXISTS**
- Capabilities validation in KeyPackage
- Current framework supports this

#### 3.2 `ratchet_tree` ❌ **NEEDS TREEKEMIMPLEMENTATION**  
- Requires TreeKEM encryption/decryption
- **Dependency**: Phase 5.2 TreeKEM implementation

#### 3.3 `nostr_group_data` ❌ **CUSTOM EXTENSION**
- Nostr-specific group metadata
- Links MLS group to Nostr identity

#### 3.4 `last_resort` ❌ **CUSTOM EXTENSION** (Highly Recommended)
- Prevents key package reuse
- Important for security best practices

### 4. Group Operations (Simplified Subset) ❌ **PHASE 5 WORK**

**Required Operations:**
- Group creation with founder
- Add member via proposals
- Remove member via proposals  
- Welcome message processing
- Epoch management for forward secrecy

**NOT NEEDED:**
- Complex multi-party protocols
- External commits
- Advanced proposal types

**Implementation Plan:** Aligns with Phase 5.3 (Simple Group Creation)

### 5. Message Processing (Limited Scope) ❌ **PHASE 5 WORK**

**Required Message Types:**
- Proposal messages (Add/Remove)
- Commit messages (apply proposals)
- Welcome messages (join groups)

**NOT NEEDED:**
- Application messages (NIP-EE uses separate NIP-44 encryption)
- Full MLS message flow

### 6. Cryptographic Operations ⚠️ **MOSTLY IMPLEMENTED**

**Current Status:**
- ✅ HKDF with MLS labels
- ✅ Signature generation/verification  
- ✅ Hash functions (SHA-256/384/512)
- ❌ **TODO**: `exporter_secret` derivation with "nostr" label
- ❌ **TODO**: TreeKEM encryption/decryption

**Key Missing Component:**
```zig
// Need to implement this function
pub fn exporterSecret(
    cs: CipherSuite,
    allocator: Allocator,
    secret: []const u8,
    label: []const u8, // "nostr" for NIP-EE
    context: []const u8,
    length: u16,
) !Secret
```

## Implementation Roadmap

### Phase 5A: NIP-EE Essentials (Minimal MLS)

**Priority 1: Core TreeKEM** 
- File: `src/tree_kem.zig`
- TreeKEM encryption/decryption for ratchet_tree extension
- Parent node key derivation
- Basic tree synchronization

**Priority 2: Exporter Secret**
- File: Extend `src/cipher_suite.zig`  
- Add `exporterSecret()` function with "nostr" label support
- Simple addition to existing HKDF implementation

**Priority 3: Nostr Extensions**
- File: `src/nostr_extensions.zig`
- Implement `nostr_group_data` extension
- Implement `last_resort` extension
- Integration with existing Extensions framework

**Priority 4: Basic Group Operations**
- File: `src/mls_group.zig`
- Group creation with 2-3 members
- Add/Remove proposals
- Welcome message processing
- Epoch management

### Phase 5B: Production Ready

**Scalability:**
- Support for larger groups
- Optimized tree operations
- Memory-efficient group state

**Robustness:**
- Comprehensive error handling
- Malformed message handling
- Network failure recovery

**Security:**
- Key rotation and epoch management
- Forward secrecy validation
- Post-compromise security

**Interoperability:**
- Test vector validation
- Cross-implementation testing
- OpenMLS compatibility verification

## Technical Specifications

### NIP-EE Specific Requirements

1. **Group ID**: 32-byte random identifier
2. **Signing Keys**: MUST be different from Nostr identity keys
3. **Credential Type**: BasicCredential with Nostr identity public key
4. **Key Rotation**: Regular rotation recommended
5. **Message Flow**: MLS for key management → NIP-44 for actual encryption

### Security Properties

1. **Forward Secrecy**: Keys compromised in one epoch don't affect others
2. **Post-Compromise Security**: Recovery from key compromise
3. **Metadata Protection**: Group membership and message metadata protected
4. **Device Support**: Multiple devices per user identity

### Integration Points

1. **Nostr Events**: KeyPackage distribution via Nostr events
2. **NIP-44 Integration**: Use MLS exporter_secret for conversation keys
3. **Identity Management**: Link MLS credentials to Nostr public keys
4. **Event Storage**: Secure storage of MLS group state

## Success Metrics

### Phase 5A Complete:
- [ ] Create 2-person encrypted group using MLS + NIP-44
- [ ] Add third member to existing group
- [ ] Process Welcome messages for joining groups
- [ ] Derive exporter_secret for NIP-44 encryption
- [ ] Handle basic key rotation (new epoch)

### Phase 5B Complete:
- [ ] Support groups of 10+ members
- [ ] Handle concurrent group operations
- [ ] Implement all required Nostr extensions
- [ ] Pass MLS test vector validation
- [ ] Demonstrate interoperability with other MLS implementations

## Development Notes

### Existing Foundation (Phase 4 Complete)
- Complete cipher suite framework with 8 MLS cipher suites
- Ed25519 and P-256 key generation and signatures
- HKDF key derivation with MLS label support
- KeyPackage structures and validation
- TLS codec for all wire formats
- Comprehensive test coverage (23 tests passing)

### Key Simplifications for NIP-EE
1. **No Application Messages**: MLS only handles key management
2. **Simplified Group Ops**: Focus on Add/Remove, not complex protocols  
3. **Nostr Integration**: Custom extensions instead of generic MLS features
4. **Small Groups**: Initially target 2-10 members, not hundreds

### Risk Mitigation
1. **Incremental Implementation**: Phase 5A provides minimal viable product
2. **Test-Driven Development**: Use OpenMLS test vectors for validation
3. **Security Review**: Focus on TreeKEM and key derivation correctness
4. **Interop Testing**: Validate against reference implementations

This implementation approach leverages our strong foundation while focusing on the specific subset needed for secure Nostr group messaging.