use dep::std;
use crate::scalar_field::ScalarField;

struct Curve {
    x: Field,
    y: Field,
}

// global d: Field = 555;
impl Curve {
    unconstrained pub fn get_inverses(x1: Field, x2: Field, y1: Field, y2: Field) -> (Field, Field, Field) {
        let d = 555;
        let lambda = y1 * y2 * x1 * x2;
        let y = (x1 * x2 - y1 * y2) / (lambda * d - 1);
        let x = (x1 * y2 + y1 * x2) / (lambda * d + 1);
        (x, y, lambda)
    }

    fn add(self, other: Self) -> Self {
        let x1 = self.x;
        let x2 = other.x;
        let y1 = self.y;
        let y2 = other.y;
        let (x, y, lambda) = Curve::get_inverses(x1, x2, y1, y2);
        let d = 555;
        let x1x2 = x1 * x2;
        let x1y2 = x1 * y2;
        std::as_witness(x1x2);
        std::as_witness(x1y2);
        let x_lhs = x * lambda * d + x - x1y2; // equals y1x2
        let y_lhs = y * -lambda * d + y + x1x2; // equals y1y2
        let y1x2 = y1 * x2;
        let y1y2 = y1 * y2;
        std::as_witness(y1x2);
        std::as_witness(y1y2);
        let y1y2x1x2 = y1y2 * x1x2;
        assert(x_lhs == y1x2);
        assert(y_lhs == y1y2);
        assert(y1y2x1x2 == lambda);
        Self { x, y }
    }

    fn dbl(self) -> Self {
        let x1 = self.x;
        let y1 = self.y;

        let (x, y, lambda) = Curve::get_inverses(x1, x1, y1, y1);

        let x1x1 = x1 * x1;
        let x1y1 = x1 * y1;
        std::as_witness(x1x1);
        std::as_witness(x1y1);

        let x_lhs = x + x * lambda * 555; // equals x1y1
        // let x_lhs = -x1y1 + x * (lambda * 555 + 1); // equals x1y1
        let y_lhs = x1x1 + y + lambda * y * 555; // equals y1y1
        let y1y1 = y1 * y1;
        std::as_witness(y1y1);
        let y1y1x1x1 = y1y1 * x1x1;

        assert(x_lhs == x1y1 * 2);
        assert(y_lhs == y1y1);
        assert(y1y1x1x1 == lambda);
        Self { x, y }
    }

    fn foobar(self, scalar: ScalarField, param: [Field; 32]) {
        for i in 0..10 {
            let idx = scalar.base4_slices[i];
            let x = param[idx];
            let y = x * x;
            std::as_witness(y);
            // let y = tableY[idx];
            // accumulator = accumulator.add(Curve{ x, y });
        }
    }
    fn mul(self, scalar: ScalarField) -> Self {
        let mut table: [Curve; 16] = [Curve { x: 0, y: 0 }; 16];

        let x= scalar.get(0) as u64;
        table[x].x = x as Field;
        let D2 = self.dbl();
        table[0] = self;
        for i in 1..15 {
            table[i] = D2.add(table[i-1]);
        }
        let idx = scalar.base4_slices[0];
        let mut accumulator: Curve = table[idx];

        //    let mut slice: [Field] = &[tableY[0], tableY[1], tableY[2], tableY[3]];
        //26 - 7 = 19
        for i in 0..1 {
            // accumulator = accumulator.dbl();
            // accumulator = accumulator.dbl();
            // accumulator = accumulator.dbl();
            // accumulator = accumulator.dbl();
            let idx: u8 = scalar.base4_slices[i];
            let t = table[idx];
            println(f"{t}");
            //  std::as_witness(t.x * t.y);
            //    accumulator = accumulator.add(table[idx]);
            // 44 dbl
            // 7 add
            // 8 lookup = 59 wtf
            // 39 dbl
            // 15 lookup?
        }
        // for i in 0..1 {
        //     let idx: u64 = scalar.base4_slices[i] as u64;
        //     let t = table[idx];
        //     println(f"{t}");
        // }
        // 72

        accumulator
        // 32 = 68
        // 16 = 32
        // 8 = 20
    }
    // 3834 10
    // 3754 1
    // 80 for 9 = 9, should be 7
}

// 4309
// 3619

// 690 / 50 = 13.8
// 6244
// 6328