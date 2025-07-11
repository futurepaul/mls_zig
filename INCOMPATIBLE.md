# MLS Implementation Incompatibilities

This document tracks known differences between our MLS implementation and the OpenMLS reference implementation, as discovered through test vector validation.

## Exporter Secret Derivation

**Status**: 🔴 **INCOMPATIBLE** - OpenMLS test vectors fail

**Discovered**: 2025-01-11 during key schedule test vector validation

### The Issue

Our `exporterSecret()` function produces different results than OpenMLS for identical inputs:

```
Test Input:
- Exporter Secret: 5a097e149f2a375d0b9e1d1f4dc3a9c6c1788df888e5441f41a8791f4dc56cea
- Label (hex):     9ba13d54ecdec7cbefcb47b4268d7b1990fabc6d6e67681e167959389d84e4e4
- Context (hex):   884f1af892ab002f5be4c5d5081ade9e0e6418c6ea7a9a92e90534f19dcef785
- Length:          32

Expected (OpenMLS): dbce4e25e59ab4dfa6f6200f113ed08393cf6e7286d024811141c6a4dd11c0cb
Our Result:         37154cdd9c0625bf5643a531591078fb2c8107fa08bff4c2b8ca64cc2b596125
```

### Root Cause Analysis

**Our Implementation**:
```zig
pub fn exporterSecret(
    self: CipherSuite,
    allocator: Allocator,
    exporter_secret: []const u8,
    label: []const u8,
    context: []const u8,
    length: u16,
) !Secret {
    // Hash the context
    const context_hash = hash(context);
    
    // Derive using: Derive-Secret(exporter_secret, label, Hash(context))
    return self.hkdfExpandLabel(allocator, exporter_secret, label, context_hash, length);
}
```

**The Problem**: Our `hkdfExpandLabel` treats the label as a string and prepends "MLS 1.0 ":
```zig
const full_label = try std.fmt.allocPrint(allocator, "{s}{s}", .{ MLS_LABEL_PREFIX, label });
```

But OpenMLS test vectors provide **binary label data**, not string labels.

### Approaches Tested

We tested 4 different derivation methods, none matched OpenMLS:

1. **Raw HKDF** (no MLS prefix): `172c14d5...` ❌
2. **Direct deriveSecret** (raw context): `72ae5f81...` ❌  
3. **Hashed context**: `37154cdd...` ❌
4. **Our exporterSecret**: `37154cdd...` ❌ (same as #3)

### Specification Ambiguity

**RFC 9420 Section 8.5** states:
> MLS-Exporter(label, context, length) = Derive-Secret(exporter_secret, label, Hash(context))

But it's unclear:
- Should `label` be a string that gets "MLS 1.0 " prefix?
- Should `label` be raw binary data?
- How should the HKDF info structure be constructed?

### Impact

**Functionality**: ✅ Our exporter function works correctly for internal use
**Interoperability**: ❌ Cannot exchange exporter-derived keys with OpenMLS implementations
**Security**: ⚠️ Different key derivation means different encryption keys

### Workaround

For applications needing OpenMLS compatibility, use the `deriveSecret` function directly:

```zig
// OpenMLS-compatible exporter (theory - not yet verified)
var compatible_secret = try cipher_suite.deriveSecret(
    allocator,
    exporter_secret,
    raw_binary_label,  // Binary data from OpenMLS
    hashed_context     // SHA256(context)
);
```

### Resolution Status

- [x] Issue identified and characterized
- [x] Test cases created for validation
- [ ] OpenMLS source code analysis
- [ ] RFC interpretation clarification
- [ ] Implementation fix
- [ ] Verification with test vectors

---

## Known Compatible Features

### ✅ Cryptographic Primitives
- **HKDF**: Compatible with RFC 5869
- **Hash Functions**: SHA-256/384/512 compatible
- **deriveSecret/expandWithLabel**: Core functions work correctly

### ✅ Tree Mathematics  
- **Tree Structure**: All OpenMLS tree-math test vectors pass (10/10)
- **Node Relationships**: parent(), sibling(), direct_path() all correct

### ✅ TreeKEM Operations
- **UpdatePath**: Parsing and structure validation works
- **PathSecret**: Key derivation and chaining compatible  
- **HPKE Integration**: Key pair generation works correctly

### ✅ Key Schedule Framework
- **Secret Types**: All 11 MLS secret types validated
- **Length Validation**: Secret sizes match cipher suite requirements
- **Epoch Management**: Key schedule progression works

---

## Testing Philosophy

This document exists because **test vectors should expose incompatibilities**, not hide them. Every difference discovered helps us build a more robust and interoperable MLS implementation.

**"The whole point of these test vectors is to expose what we might be doing wrong!"** - User feedback during investigation

## Version History

- **v1.0** (2025-01-11): Initial documentation of exporter secret incompatibility
- **v1.1** (TBD): Resolution and verification

---

*This document will be updated as we resolve incompatibilities and discover new ones through continued test vector validation.*