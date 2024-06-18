mod scalar_field;
mod curve;
use crate::scalar_field::ScalarField;
use crate::curve::Curve;
use dep::std;
fn main(x: Field, y: pub Field) {
    assert(x != y);

    let xx = 3;
    let yy = 5;
    // let aa = 2;
    // let bb = 4;
    std::as_witness(xx);
    std::as_witness(yy);
    // std::as_witness(aa);
    // std::as_witness(bb);

    let mut A: Curve = Curve { x, y };
    let mut B: Curve = Curve { x: xx, y: yy };
    // let mut C: Curve = Curve { x: aa, y: bb };

    // this loop increases circuit size from 23 to 1021 -> approx 10 gates per add
    for i in 0..100 {
        A = A.add(B);
    }

    let scalar: ScalarField = ScalarField::from_field(x);
    A = A.mul(scalar);
    //A = A.mul(scalar);
    // 28430
    // 16206
    // 12224 yeowzers
}

#[test]
fn test_main() {
    main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
