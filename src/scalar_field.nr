struct ScalarField {
    base4_slices: [u8; 63]
}
// TODO check to_be_radix?
// unconstrained fn slice_field_into_base4(x: Field) -> [Field; 63] {
//     let x_bytes: [u8] = x.to_be_bytes(32);
//     let mut x_nibbles: [Field; 63] = [0; 63];
//     for i in 1..32 {
//         let hi = x_bytes[i] & 0xf;
//         let lo = x_bytes[i] >> 4;
//         x_nibbles[i + i] = hi as Field;
//         x_nibbles[i + i + 1] = lo as Field;
//     }
//     x_nibbles
// }

impl ScalarField {
    fn new() -> Self {
        Self { base4_slices: [0; 63] }
    }
    fn from_field(x: Field) -> Self {
        let bytes: [u8] = x.to_le_radix(16, 63);
        let mut result: Self = ScalarField { base4_slices: [0; 63] };
        for i in 0..63 {
            result.base4_slices[i] = bytes[62 - i];
        }
        result
    }
    fn get(self, idx: u64) -> u8 {
        self.base4_slices[idx]
    }

    fn convert(self) -> Field {
        let mut acc: Field = 0;
        for i in 0..63 {
            acc = acc * 16;
            acc = acc + self.base4_slices[i] as Field;
        }
        acc
    }
}
