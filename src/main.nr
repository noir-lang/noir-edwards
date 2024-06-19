mod scalar_field;
mod curve;
use crate::scalar_field::ScalarField;
use crate::curve::Curve;
use dep::std;
fn main(x: Field, y: pub Field) {
    let xx = x * x;
    let yy = y * y;
    // let aa = 2;
    // let bb = 4;
    std::as_witness(xx);
    std::as_witness(yy);
    // // std::as_witness(aa);
    // // std::as_witness(bb);

    // let mut A: [Field; 1] = [0];
    // A[x] = y;
    // for i in 0..1 {
    //     let Z = A[x];
    //     println(f"{Z}");
    // }
    // 476 - 35 = 441 / 100 = 4.4 
    // let Q = A[y];
    // println(f"{Q}");
    //   std::as_witness(x);
    //    std::as_witness(y);
    let mut A: Curve = Curve { x, y };
    let mut B: Curve = Curve { x: xx, y: yy };
    // // let mut C: Curve = Curve { x: aa, y: bb };
    // // this loop increases circuit size from 23 to 1021 -> approx 10 gates per add
    for i in 0..101 {
        A = A.add(B);
        println(f"{A}");
    }
    //let scalar: ScalarField = ScalarField::from_field(x);
    // A = A.mul(scalar);
    //A = A.mul(scalar);
    // 7964
    // 12392
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
