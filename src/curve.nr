use dep::std;
use crate::scalar_field::ScalarField;

struct Curve {
    x: Field,
    y: Field,
}

global d: Field = 555;
impl Curve {
    unconstrained pub fn get_inverses(x1: Field, x2: Field, y1: Field, y2: Field) -> (Field, Field, Field) {
        let lambda = y1 * y2 * x1 * x2;
        let y = (x1 * x2 - y1 * y2) / (lambda * d - 1);
        let x = (x1 * y2 + y1 * x2) / (lambda * d + 1);
        (lambda, x, y)
    }

    fn add(self, other: Self) -> Self {
        let x1 = self.x;
        let x2 = other.x;
        let y1 = self.y;
        let y2 = other.y;
        let (lambda, x, y) = Curve::get_inverses(x1, x2, y1, y2);

        let x1x2 = x1 * x2;
        let x1y2 = x1 * y2;

        let x_lhs = x * (lambda * d + 1) - x1y2; // equals y1x2
        let y_lhs = y * (1 - lambda * d) + x1x2; // equals y1y2

        let y1x2 = y1 * x2;
        let y1y2 = y1 * y2;

        let y1y2x1x2 = y1y2 * x1x2;
        assert(x_lhs == y1x2);
        assert(y_lhs == y1y2);
        assert(y1y2x1x2 == lambda);
        Self { x, y }
    }

    fn dbl(self) -> Self {
        let x1 = self.x;
        let y1 = self.y;
        let (lambda, x, y) = Curve::get_inverses(x1, x1, y1, y1);

        let x1x1 = x1 * x1;
        let x1y1 = x1 * y1;

        let x_lhs = x * (lambda * d + 1) - x1y1; // equals x1y1
        let y_lhs = y * (1 - lambda * d) + x1x1; // equals y1y1

        let y1y1 = y1 * y1;
        let y1y2x1x2 = y1y1 * x1x1;
        assert(x_lhs == x1y1);
        assert(y_lhs == y1y1);
        assert(y1y2x1x2 == lambda);
        Self { x, y }
    }

    fn mul(self, scalar: ScalarField) -> Self {
        let mut tableY: [Field; 8] = [0; 8];
        for i in 0..8 {
            let xx = 5;
            std::as_witness(xx);
            tableY[i] = xx;
        }
        let mut accumulator: Curve = Curve { x: 0, y: 0 };
        for i in 0..62 {
            let idx: Field = scalar.get(i) as Field;
            let x = tableY[idx];
            // let y = tableY[idx];
            // accumulator = accumulator.add(Curve{ x, y });
            std::as_witness(x);
        }
        Curve { x: 0, y: 0 }
        // 32 = 68
        // 16 = 32
        // 8 = 20
    }
}

// 6244
// 6328