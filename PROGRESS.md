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
- [ ] Basic tree creation
- [ ] Tree size reporting
- [ ] Node access by index
- [ ] Tree diff operations

## Phase 3: Credentials (Introduction to Serialization)
- [ ] Basic credential with identity
- [ ] Credential type enum
- [ ] Credential serialization/deserialization

## Notes
- Currently implementing in `src/tree_math.zig`
- All index types use wrapper structs around u32
- TreeNodeIndex is a union(enum) in Zig vs enum in Rust
- Method names changed from `u32()` to `asU32()` to avoid shadowing primitives