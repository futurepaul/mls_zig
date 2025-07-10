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

## Notes
- TreeMath implemented in `src/tree_math.zig`
- Binary tree structure implemented in `src/binary_tree.zig`
- Tree diff operations implemented in `src/binary_tree_diff.zig`
- TLS codec framework implemented in `src/tls_codec.zig`
- Credential types implemented in `src/credentials.zig`
- All index types use wrapper structs around u32
- TreeNodeIndex is a union(enum) in Zig vs enum in Rust
- Method names changed from `u32()` to `asU32()` to avoid shadowing primitives
- BinaryTree uses generic types for leaf and parent node data
- Iterators return typed structs (LeafItem/ParentItem) instead of anonymous structs
- Diff system uses HashMaps for tracking changes instead of BTreeMap
- Tree growing doubles leaf count, shrinking halves it (maintains full binary tree property)
- TLS codec follows MLS/TLS conventions (big-endian, length-prefixed data)
- VarBytes manages memory automatically for variable-length data