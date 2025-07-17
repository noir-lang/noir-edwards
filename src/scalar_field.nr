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
            // TODO: if num bits = 64, validate in sum of the bits is smaller than the Field modulus
            let mut lo: Field = 0;
            let mut hi: Field = 0;

            for i in 0..32 {
                lo *= 16;
                lo += (slices[32 + i] as Field) * 2 - 15;
                hi *= 16;
                hi += (slices[i] as Field) * 2 - 15;
            }

            lo -= skew as Field;
            // Validate that the integer represented by (lo, hi) is smaller than the integer represented by (plo, phi)

            // Safety: `borrow`'s value is constrained to be correct by below range constraints.
            // Safety: we assert that the absolute value has less than 128 bits
            let is_positive: bool = unsafe { get_borrow_flag(lo, TWO_POW_128) };

            let abs_lo = (is_positive as Field) * lo + (1 - is_positive as Field) * (-lo);

            abs_lo.assert_max_bit_size::<128>();
            // Safety: `borrow`'s value is constrained to be correct by below range constraints.
            let borrow = unsafe { get_borrow_flag(PLO, abs_lo) as Field };
            // we only need to check the rlo has 128 bits or less if lo is positive. if negative, the lo is already less than PLO
            let rlo = is_positive as Field * (PLO - lo + borrow * TWO_POW_128 - 1)
                + (1 - is_positive as Field) * (-lo); // -1 because we are checking a strict <, not <=
            // is lo is positive, we need to check the hi is less than phi with the borrow flag subtracted
            // if lo is negative, we have to check that hi * 2^128 < phi * 2^128 + abs_lo + plo
            // to do this we first make a flag to check that abs_lo + plo is larger than 2^128 or not
            // if they are larger, we check that hi < phi + 1 and otherwise we check that hi < phi
            // Safety: we assert the when the flag is positive we have less than 128 bits
            let threshold_flag: bool = unsafe { get_borrow_flag(abs_lo + PLO, TWO_POW_128) };
            (threshold_flag as Field * (abs_lo + PLO)).assert_max_bit_size::<128>();
            let rhi = is_positive as Field * (PHI - hi - borrow)
                + (1 - is_positive as Field) * (PHI - hi + threshold_flag as Field);
            // the rlo value would have 128 bits or less if positive and more if negative as the modulus is 254 bits
            rlo.assert_max_bit_size::<128>();
            rhi.assert_max_bit_size::<128>();
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
