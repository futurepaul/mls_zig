# MLS Zig Test Porting Progress

This document tracks the progress of porting OpenMLS tests from Rust to Zig.

## Phase 1: Basic Data Structures (No Crypto)

### TreeMath Index Types
- [x] LeafNodeIndex creation and access
- [x] ParentNodeIndex creation and access  
- [x] TreeNodeIndex conversions between leaf/parent

### TreeMath Operations
- [x] log2() function
- [x] level() function for nodes
- [x] tree_size() calculation (TreeSize struct)
- [x] is_leaf() and is_parent() checks

### TreeMath Relationships
- [x] parent() calculations
- [x] left() and right() child calculations
- [x] sibling() calculations
- [x] direct_path() calculations
- [x] root() calculations

## Phase 2: Binary Tree Structure
- [x] Basic tree creation
- [x] Tree size reporting
- [x] Node access by index
- [x] Leaf and parent iterators
- [x] Tree diff operations
  - [x] Diff creation from tree
  - [x] Grow/shrink tree operations
  - [x] Replace leaf/parent nodes
  - [x] Direct path operations
  - [x] Staged diff and merge back to tree

## Phase 3: Credentials (Introduction to Serialization)
- [x] TLS codec framework (binary serialization)
  - [x] Big-endian integer read/write
  - [x] Variable-length byte arrays
  - [x] Writer/Reader interfaces
- [x] Basic credential with identity
- [x] Credential type enum
- [x] Credential serialization/deserialization
  - [x] BasicCredential TLS encoding/decoding
  - [x] Generic Credential wrapper
  - [x] Conversion between BasicCredential and Credential

## Phase 4: Cryptographic Primitives & Key Packages
- [x] Cipher Suite Framework - MLS cipher suite definitions and component extraction
- [x] Secret wrapper type for secure key material handling  
- [x] Hash functions (SHA-256/384/512) with MLS label system
- [x] HKDF key derivation (extract/expand) with MLS labels
- [x] Key pair generation for Ed25519 and ECDSA P-256
- [x] HPKE key pair generation for X25519 and P-256
- [x] Signature operations with MLS labeled signing
- [x] Signature verification with proper label handling
- [x] KeyPackage data structures (LeafNode, Extensions, Capabilities)
- [x] KeyPackageBundle for managing public/private key pairs

## Phase 5: Basic Group Operations

### 5.1 Leaf Nodes ✅ **COMPLETE**
- [x] LeafNode creation with proper MLS signing using `signWithLabel("LeafNodeTBS")`
- [x] LeafNodeTBS (To Be Signed) structure for signature validation with group context
- [x] Integration with KeyPackage and Credential types
- [x] Support for LeafNodeSource variants (KeyPackage, Update, Commit) with proper serialization
- [x] LeafNode validation and signature verification with tree context
- [x] Complete extension framework (standard + custom Nostr extensions)
- [x] Capabilities system for MLS feature declaration
- [x] Comprehensive test suite (19 tests passing, 4 skipped pending KeyPackageBundle)
- [x] Full TLS serialization/deserialization compatibility

### 5.2 TreeKEM Integration ✅ **COMPLETE**
- [x] Integrate BinaryTree with LeafNode cryptographic material via TreeSync wrapper
- [x] TreeKEM encryption/decryption along tree paths (createUpdatePath/decryptPath)
- [x] Parent node key derivation for tree structure (PathSecret.deriveKeyPair)
- [x] Tree synchronization and update operations (applyUpdatePath)
- [x] Path encryption for secure group key updates with real HPKE encryption
- [x] Filtered direct path computation (skip blank nodes)
- [x] Copath resolution for encryption targets
- [x] UpdatePath creation with proper key derivation chain
- [x] ParentNode structure with encryption keys and parent hashes
- [x] HpkeCiphertext for encrypted path secrets
- [x] HPKE integration using zig-hpke library (X25519 + AES-GCM/ChaCha20-Poly1305)
- [x] Tests for ParentNode, PathSecret, TreeSync, and HPKE roundtrip

### 5.3 Simple Group Creation ⭐ **IN PROGRESS**
- [ ] Basic MLS group with 2-3 members
- [ ] Group state management and initialization
- [ ] Welcome message generation and processing
- [ ] Basic Add/Remove proposal handling
- [ ] Group membership validation and updates
- [ ] Commit message processing and epoch advancement
- [ ] Group context computation and management
- [ ] Interim transcript hash for proposals

**Implementation Files**: ✅ `src/leaf_node.zig` → ✅ `src/tree_kem.zig` → 🚧 `src/mls_group.zig`

## Notes
- TreeMath implemented in `src/tree_math.zig`
- Binary tree structure implemented in `src/binary_tree.zig`
- Tree diff operations implemented in `src/binary_tree_diff.zig`
- TLS codec framework implemented in `src/tls_codec.zig`
- Credential types implemented in `src/credentials.zig`
- Cipher suites and crypto primitives implemented in `src/cipher_suite.zig`
- Key packages and signature operations implemented in `src/key_package.zig`
- All index types use wrapper structs around u32
- TreeNodeIndex is a union(enum) in Zig vs enum in Rust
- Method names changed from `u32()` to `asU32()` to avoid shadowing primitives
- BinaryTree uses generic types for leaf and parent node data
- Iterators return typed structs (LeafItem/ParentItem) instead of anonymous structs
- Diff system uses HashMaps for tracking changes instead of BTreeMap
- Tree growing doubles leaf count, shrinking halves it (maintains full binary tree property)
- TLS codec follows MLS/TLS conventions (big-endian, length-prefixed data)
- VarBytes manages memory automatically for variable-length data
- HPKE encryption using zig-hpke library for path secret protection
- TreeSync wrapper provides high-level tree operations over BinaryTree
- External dependencies managed through build.zig.zon and build.zig