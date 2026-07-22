use std::static_assert;

/// ScalarField represents a scalar multiplier as a sequence of 4-bit slices
///
/// There is nuance to ScalarField, because twisted edwards curves generally have prime group orders that easily fit into a Field
/// We can therefore obtain cheap conversions by simply summing up the bit slices and validate they equal the input scalar
/// However...when converting arbitrary field elements (i.e. scalars that are multiples of a TE curve group order),
/// we must perform additional checks when converting into 4-bit slices, as we must validate that the sum of the slices is smaller than the Field modulus (when evaluated over the integers)
/// This is expensive and we would rather not do it! therefore ScalarField<N> is flexible.
/// ScalarField<63> enables cheap bitslice converions for scalar multipliers that must be <2^{252}
/// ScalarField<64> enables bitslice conversions for arbitrary field elements
///
/// N.B. ScalarField bit values are not constrained to be smaller than the TE curve group order.
/// ScalarField is used when performing scalar multiplications, where all operations wrap modulo the curve order
pub global TWO_POW_128: Field = 0x100000000000000000000000000000000;
pub global PLO: Field = 0x2833e84879b9709143e1f593f0000001;
pub global PHI: Field = 0x30644e72e131a029b85045b68181585d;

pub struct ScalarField<let N: u32> {
    pub(crate) base4_slices: [u8; N],
    pub(crate) skew: bool,
}

unconstrained fn get_wnaf_slices<let N: u32>(x: Field) -> ([u8; N], bool) {
    let mut result: [u8; N] = [0; N];
    let mut nibbles: [u8; N] = to_le_radix_16(x);

    let skew: bool = nibbles[0] & 1 == 0;
    nibbles[0] += skew as u8;
    result[N - 1] = (nibbles[0] + 15) / 2;
    for i in 1..N {
        let mut nibble: u8 = nibbles[i];
        result[N - 1 - i] = (nibble + 15) / 2;
        if (nibble & 1 == 0) {
            result[N - 1 - i] += 1;
            result[N - i] -= 8;
        }
    }
    (result, skew)
}

unconstrained fn from_wnaf_slices<let N: u32>(x: [u8; N], skew: bool) -> Field {
    let mut result: Field = 0;

    for i in 0..N {
        result *= 16;
        result += (x[i] as Field) * 2 - 15;
    }
    result -= skew as Field;
    result
}

unconstrained fn get_borrow_flag(lhs_lo: Field, rhs_lo: Field) -> bool {
    lhs_lo.lt(rhs_lo + 1)
}

unconstrained fn to_le_radix_16<let N: u32>(value: Field) -> [u8; N] {
    // Round up on odd values of `N` to ensure space for last nibble.
    let bytes = value.to_le_bytes::<(N + 1) / 2>();
    let mut result: [u8; N] = [0; N];
    for index in 0..(N / 2) {
        result[index * 2] = bytes[index] & 0x0F; // Extract low nibble (bits 0-3)
        result[index * 2 + 1] = (bytes[index] >> 4); // Extract high nibble (bits 4-7)
    }
    if (N & 1) == 1 {
        let last_nibble = bytes[bytes.len() - 1];
        // The last byte must have the top 4 bits empty.
        (last_nibble as Field).assert_max_bit_size::<4>();
        result[N - 1] = last_nibble;
    }
    result
}

/// Constrain the two-limb wNAF decomposition `(hi, lo)` (with `lo` already skew-adjusted)
/// to represent the scalar `x`. This binds the decomposition to `x` and checks that the
/// value it represents is smaller than the field modulus, so it cannot be a non-canonical
/// alias such as `x + p`. Used by `From<Field>` when `N >= 64`.
fn assert_wnaf_decomposition_binds(hi: Field, lo: Field, x: Field) {
    assert(hi * TWO_POW_128 + lo == x);

    // `lo` is a signed low limb in [-2^128, 2^128 - 1] (the low 32 slices decode to an odd
    // value, then skew is subtracted). Normalize it into an unsigned limb in [0, 2^128) by
    // adding 2^128 and borrowing one limb from `hi` when it is negative, leaving
    // `hi * 2^128 + lo` unchanged.
    // Safety: `is_negative` is constrained by the `lo_u` range check below; only the correct
    // choice yields a `lo_u` smaller than 2^128.
    let is_negative: bool = unsafe { !get_borrow_flag(lo, TWO_POW_128) };
    let lo_u = lo + (is_negative as Field) * TWO_POW_128;
    let hi_u = hi - (is_negative as Field);

    // Both limbs must be non-negative and fit in 128 bits. The `hi_u` check also rejects a
    // negative `hi`, whose field value would otherwise be close to the modulus.
    lo_u.assert_max_bit_size::<128>();
    hi_u.assert_max_bit_size::<128>();

    // Check (hi_u, lo_u) < (PHI, PLO) by subtracting limb by limb, borrowing from the high
    // limb when the low limb underflows. `r_lo` and `r_hi` are the limbs of `p - 1 - V`,
    // which are both valid 128-bit values only when `V < p`.
    // Safety: `borrow` is constrained by the `r_lo`/`r_hi` range checks below.
    let borrow: bool = unsafe { get_borrow_flag(PLO, lo_u) };
    let r_lo = PLO - lo_u + (borrow as Field) * TWO_POW_128 - 1; // -1: strict `<`, not `<=`
    let r_hi = PHI - hi_u - (borrow as Field);
    r_lo.assert_max_bit_size::<128>();
    r_hi.assert_max_bit_size::<128>();
}

impl<let N: u32> std::convert::From<Field> for ScalarField<N> {

    /// Construct from a field element
    ///
    /// if N >= 64 we perform extra checks to ensure the slice decomposition represents the same integral value as the input
    /// (e.g. sum of slices != x + modulus)
    fn from(x: Field) -> Self {
        // the field elements have 254 bits max, so we do not need to support N > 64
        static_assert(N <= 64, "N must be at most 64");
        let mut result: Self = ScalarField { base4_slices: [0; N], skew: false };
        let (slices, skew): ([u8; N], bool) = unsafe { get_wnaf_slices(x) };
        result.base4_slices = slices;
        result.skew = skew;
        if (N < 64) {
            let mut acc: Field = (slices[0] as Field) * 2 - 15;
            for i in 1..N {
                acc *= 16;
                acc += (slices[i] as Field) * 2 - 15;
            }
            assert(acc - skew as Field == x);
        } else {
            let mut lo: Field = 0;
            let mut hi: Field = 0;

            for i in 0..32 {
                lo *= 16;
                lo += (slices[32 + i] as Field) * 2 - 15;
                hi *= 16;
                hi += (slices[i] as Field) * 2 - 15;
            }

            lo -= skew as Field;
            assert_wnaf_decomposition_binds(hi, lo, x);
        }
        for i in 0..N {
            (result.base4_slices[i] as Field).assert_max_bit_size::<4>();
        }
        result
    }
}

impl<let N: u32> std::convert::Into<Field> for ScalarField<N> {

    /// Construct from tuple of field elements
    ///
    /// Use this method instead of `new` if you know x/y is on the curve
    fn into(self: Self) -> Field {
        let mut acc: Field = 0;
        for i in 0..N {
            acc = acc * 16;
            acc = acc + (self.base4_slices[i] as Field) * 2 - 15;
        }
        acc -= self.skew as Field;
        acc
    }
}

impl<let N: u32> ScalarField<N> {

    pub fn new() -> Self {
        Self { base4_slices: [0; N], skew: false }
    }
    fn get(self, idx: u32) -> u8 {
        self.base4_slices[idx]
    }
}

#[test]
unconstrained fn test_wnaf() {
    let result: Field = 0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0;
    let (t0, t1) = get_wnaf_slices::<64>(result);
    let expected = from_wnaf_slices(t0, t1);
    assert_eq(result, expected);
}

#[test]
fn test_regression_wnaf() {
    let a = 0x7b;
    let s: ScalarField<64> = ScalarField::<64>::from(a);
    let b: Field = ScalarField::<64>::into(s);
    assert_eq(a, b);
}

#[test]
unconstrained fn to_le_radix_16_works_with_odd_N() {
    let input = 0x0f00;
    let nibbles: [u8; 3] = to_le_radix_16(input);
    assert_eq(nibbles, [0x0, 0x0, 0xf]);
}

// ---------------------------------------------------------------------------
// Regression tests for two bugs in the `N >= 64` branch of `From<Field>`.
// These are expected to FAIL against the current implementation.
// ---------------------------------------------------------------------------

// Finding 1 (completeness): the canonicity range check rejects legitimate
// scalars at the `lo == PLO` / `abs_lo + PLO == 2^128` boundary, because
// `get_borrow_flag` compares with `<=` while `assert_max_bit_size::<128>` is a
// strict `< 2^128`, so an intermediate that lands exactly on `2^128` is wrongly
// rejected. `from(0)` and `from(PLO)` are unprovable today.

#[test]
fn regression_from_zero_is_provable() {
    // Honest decomposition of 0 is hi = 1, lo = -2^128, so abs_lo = 2^128 and
    // `abs_lo.assert_max_bit_size::<128>()` fails.
    let a: Field = 0;
    let s: ScalarField<64> = ScalarField::<64>::from(a);
    assert_eq(ScalarField::<64>::into(s), a);
}

#[test]
fn regression_from_low_limb_equal_plo_is_provable() {
    // Any x with (x mod 2^128) == PLO drives abs_lo + PLO == 2^128 exactly, which
    // fails `(threshold_flag * (abs_lo + PLO)).assert_max_bit_size::<128>()`.
    let a: Field = PLO;
    let s: ScalarField<64> = ScalarField::<64>::from(a);
    assert_eq(ScalarField::<64>::into(s), a);
}

// Finding 2 (soundness): the canonicity check handles a negative `lo` but
// implicitly assumes `hi >= 0`. Nothing forces the top 32 signed slices to sum
// to a non-negative value, so a prover can pick `hi < 0`: then `hi` (as a field
// element) is ~p, and `PHI - hi` wraps mod p to a small value that passes the
// bit-size check, defeating the `hi <= PHI` comparison. The decomposition then
// encodes a negative integer `V = x - p` that is accepted despite being
// non-canonical, so `mul`/`msm` would compute `[x - p]*P` instead of `[x]*P`.
//
// A sound check must REJECT such a witness, so proving must fail -> should_fail.
// This drives the real `assert_wnaf_decomposition_binds` used by `from` directly.
#[test(should_fail)]
fn regression_negative_hi_decomposition_is_rejected() {
    // Malicious hint: hi = -1, lo = 1 => V = hi*2^128 + lo = -(2^128 - 1) = x - p,
    // a non-canonical (negative) integer. Reachable from valid 4-bit slices.
    let hi: Field = -1;
    let lo: Field = 1;
    let x: Field = hi * TWO_POW_128 + lo; // = p - (2^128 - 1)
    assert_wnaf_decomposition_binds(hi, lo, x);
}
