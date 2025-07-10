# MLS Zig Development Notes

## 🎯 **Where to Continue Next**

The foundation is solid! Next logical steps would be:

### **Phase 4: Cryptographic Primitives & Key Packages**
1. **Cipher Suite Framework** - Define supported crypto algorithms (Ed25519, P-256, etc.)
2. **Key Package Structure** - Public keys + credentials for joining groups
3. **Signature Operations** - Integrate with Zig's `std.crypto` for signing/verification
4. **Key Generation** - Create proper key pairs for MLS clients

### **Phase 5: Basic Group Operations**
1. **Leaf Nodes** - Combine credentials + keys + capabilities
2. **Tree Sync** - Maintain group member tree with cryptographic material
3. **Simple Group Creation** - Basic MLS group with 2-3 members

## 🧠 **Key Learnings & Findings**

### **Zig-Specific Insights**
- **Memory Management**: Zig's allocator pattern works excellently for MLS - we can pass allocators down through the call stack for precise memory control
- **Error Handling**: Zig's error unions are perfect for MLS operations that can fail (invalid credentials, crypto errors, etc.)
- **Generics**: Zig's `comptime` generics are more powerful than Rust's for the binary tree - we can parameterize on both data types and behavior
- **Packed Structs**: Will be crucial for wire format compatibility when we implement message parsing

### **Architecture Decisions Made**
- **TLS Codec Pattern**: Our `TlsWriter`/`TlsReader` approach scales well - can easily add more complex types
- **VarBytes Design**: Auto-managing memory for variable-length data works smoothly
- **Index Type Safety**: Wrapper structs prevent index confusion (LeafNodeIndex vs ParentNodeIndex)
- **Diff System**: HashMap-based diffs are more Zig-idiomatic than Rust's BTreeMap approach

### **Performance Notes**
- **Zero-Copy Potential**: Our `VarBytes.asSlice()` returns const references - good for performance
- **Allocation Strategy**: We're allocating sensibly - each component owns its data clearly
- **Iterator Design**: Our iterator pattern avoids heap allocation unlike Rust's `Box<dyn Iterator>`

### **MLS-Specific Insights**
- **Tree Growing Strategy**: Doubling leaf count maintains the full binary tree property correctly
- **Credential Flexibility**: The generic `Credential` wrapper will easily support X.509 certificates later
- **Serialization Compatibility**: Our TLS format matches the spec (big-endian, length-prefixed)

## 📁 **File Organization Status**

```
src/
├── main.zig              # Executable entry point
├── root.zig              # Library exports
├── tree_math.zig         # ✅ Complete - Tree index math
├── binary_tree.zig       # ✅ Complete - Generic tree structure  
├── binary_tree_diff.zig  # ✅ Complete - Tree diff operations
├── tls_codec.zig         # ✅ Complete - Binary serialization
└── credentials.zig       # ✅ Complete - MLS credentials

Next files to create:
├── cipher_suite.zig      # Crypto algorithm definitions
├── key_package.zig       # Public key + credential bundles
├── leaf_node.zig         # Tree members with crypto material
└── signatures.zig        # Signing operations
```

## 🚧 **Technical Debt & Considerations**
- **Error Types**: Consider consolidating error types across modules
- **Allocator Strategy**: May want to explore arena allocators for request-scoped allocations
- **Const Correctness**: Some places could be more const-correct
- **Test Coverage**: Could add property-based testing for tree operations

## 🔧 **Development Setup Notes**
- **Zig Version**: Working with 0.14.1 - stable and reliable
- **Test Strategy**: Each module has comprehensive unit tests - continue this pattern
- **Git Strategy**: Clean commits with descriptive messages work well
- **Sample Code**: Having the OpenMLS Rust reference is invaluable for understanding

## 💡 **Architectural Strengths So Far**
1. **Modularity**: Each component is self-contained with clear interfaces
2. **Type Safety**: Wrapper types prevent common indexing errors
3. **Memory Safety**: Proper RAII patterns with explicit cleanup
4. **Testability**: Good separation allows focused unit testing
5. **Extensibility**: Generic designs will support future MLS extensions

## 🎯 **Phase 5: Basic Group Operations (Next Goals)**

**Status**: Ready to begin - Phase 4 (Cryptographic Primitives & Key Packages) is complete!

### **5.1 Leaf Nodes Implementation** ⭐ **Start Here**
1. **File**: Create `src/leaf_node.zig`
2. **Core Features**:
   - Implement `LeafNode` creation with proper signing
   - Add `LeafNodeTBS` (To Be Signed) structure for signature validation
   - Integrate with existing `KeyPackage` and `Credential` types
   - Support for `LeafNodeSource` variants (KeyPackage, Update, Commit)
3. **Key Operations**:
   - `createLeafNode()` - generate properly signed leaf nodes
   - `validateLeafNode()` - verify signatures and capabilities
   - `updateLeafNode()` - create updates for existing members
4. **References**: `samples/openmls/openmls/src/treesync/node/leaf_node/`

### **5.2 TreeKEM Integration**
1. **File**: Create `src/tree_kem.zig` 
2. **Core Features**:
   - Integrate `BinaryTree` with `LeafNode` data
   - Implement TreeKEM encryption/decryption operations
   - Add parent node key derivation
   - Support for tree synchronization
3. **Key Operations**:
   - `encryptToPath()` - encrypt along tree path
   - `decryptFromPath()` - decrypt received updates
   - `updateTreePath()` - refresh keys along path
4. **References**: `samples/openmls/openmls/src/treesync/`

### **5.3 Simple Group Creation**
1. **File**: Create `src/mls_group.zig`
2. **Core Features**:
   - Basic MLS group with 2-3 members
   - Group state management
   - Welcome message processing
   - Basic Add/Remove proposal handling
3. **Key Operations**:
   - `createGroup()` - initialize new group with founder
   - `addMember()` - process Add proposals
   - `processWelcome()` - join existing group
4. **References**: `samples/openmls/openmls/src/group/`

### **Implementation Order & Dependencies**
```
1. leaf_node.zig     ← Uses: key_package.zig, cipher_suite.zig, credentials.zig
   ↓
2. tree_kem.zig      ← Uses: leaf_node.zig, binary_tree.zig, cipher_suite.zig  
   ↓
3. mls_group.zig     ← Uses: tree_kem.zig, key_package.zig, all above
```

### **Key Design Decisions Needed**
1. **Tree Sync Strategy**: How to handle concurrent updates and conflicts
2. **Message Processing**: Synchronous vs asynchronous processing model
3. **State Storage**: In-memory vs persistent storage interface
4. **Error Handling**: How to handle malformed messages and crypto failures

### **Testing Strategy for Phase 5**
1. **Unit Tests**: Each component (LeafNode, TreeKEM, Group) with focused tests
2. **Integration Tests**: Cross-module tests with real key material
3. **Interop Tests**: Use OpenMLS test vectors for compatibility validation
4. **Property Tests**: Verify TreeKEM security properties

## 📊 **Current Test Status** (Post Phase 4)
- **Total Tests**: 23 passing (cipher_suite.zig + key_package.zig)
- **Coverage**: All implemented modules have comprehensive tests
- **Patterns**: Each module tests creation, serialization, and core operations
- **Memory Safety**: All tests pass with no memory leaks

## 🔍 **Useful References**
- **OpenMLS Rust Implementation**: `samples/openmls/` - excellent reference for understanding
- **Zig Standard Library**: `samples/zig/lib/std/` - crypto, TLS, and serialization utilities
- **MLS RFC**: For specification compliance
- **Test Vectors**: Available in `samples/openmls/openmls/test_vectors/` for validation

## 🧪 **Testing Strategy Notes**
- **Unit Tests**: Each module has focused unit tests for its core functionality
- **Integration Tests**: Should add cross-module tests as we build higher-level components
- **Reference Tests**: OpenMLS test vectors will be valuable for compatibility validation
- **Property Testing**: Consider adding property-based tests for tree operations

## 🔄 **Handoff Notes for Phase 5**

### **Quick Start Guide**
1. **Begin with**: `src/leaf_node.zig` - this is the critical next step
2. **Reference**: Look at `samples/openmls/openmls/src/treesync/node/leaf_node/` for structure
3. **Pattern**: Follow the same structure as `key_package.zig` - data structures, operations, tests
4. **Integration**: LeafNode will use existing `KeyPackage`, `Credential`, and `cipher_suite` modules

### **Key Implementation Hints**
1. **LeafNode Signing**: Use `signWithLabel()` from `key_package.zig` with label `"LeafNodeTBS"`
2. **Tree Integration**: The `BinaryTree<LeafNode, ParentNode>` pattern is already established
3. **Error Handling**: Follow the existing pattern of specific error types per module
4. **Memory Management**: Use the same allocator patterns - each struct owns its data

### **Critical Design Considerations**
1. **Signature Validation**: LeafNode signatures are crucial for MLS security
2. **Tree Consistency**: TreeKEM requires consistent tree state across all members  
3. **Capability Validation**: Extensions and proposals must match declared capabilities
4. **Key Freshness**: TreeKEM keys must be properly derived and rotated

### **Available Foundation**
- ✅ **Complete crypto stack**: All signing, HKDF, hashing operations ready
- ✅ **Key management**: KeyPackage creation and validation working
- ✅ **Tree operations**: Binary tree with diff operations fully implemented
- ✅ **Serialization**: TLS codec handles all wire format needs
- ✅ **Testing framework**: Comprehensive test patterns established

### **Expected Complexity**
- **LeafNode**: ~400-500 lines (Medium complexity - mostly data structure + signing)
- **TreeKEM**: ~600-800 lines (High complexity - crypto + tree operations)  
- **MLS Group**: ~800-1200 lines (Very high complexity - state management + protocols)

The foundation is **extremely solid** - Phase 5 should build naturally on the existing architecture!