mod scalar_field;
mod curve;
use crate::scalar_field::ScalarField;
use crate::curve::Curve;
use crate::curve::CurveParamsTrait;
use dep::std;
use dep::std::ec;
use crate::ec::consts::te::baby_jubjub;
use crate::ec::tecurve::affine::Point as TEPoint;

struct BabyJubJubParams {}
impl CurveParamsTrait for BabyJubJubParams {
    fn a() -> Field { 168700 }
    fn d() -> Field { 168696 }
    fn gen() -> (Field, Field) { (0x0bb77a6ad63e739b4eacb2e09d6277c12ab8d8010534e0b62893f3f6bb957051, 0x25797203f7a0b24925572e1cd16bf9edfce0051fb9e133774b3c257a872d7d8b)}
}
type BabyJubJub = Curve<BabyJubJubParams>;

global Y: u64 = 10;

unconstrained fn update(x: Field, y: Field) -> (Field, Field) {
    (x * x, y * y)
}
fn main(x: Field, y: pub Field) {
    // let xx = x * x;
    // let yy = y * y;
    // // // let aa = 2;
    // // // let bb = 4;
    // std::as_witness(xx);
    // std::as_witness(yy);

    // let mut A: BabyJubJub = Curve { x, y };
    // let mut B: BabyJubJub = Curve { x: xx, y: yy };
    // let mut u: Field = xx;
    // let mut v: Field = yy;
    // for i in 0..10 {
    //     let (uu, vv) = update(u, v);
    //     u = uu;
    //     v = vv;
    //     B = Curve{ x: u, y: v };
    //     let C = B.mul(ScalarField::from_field(x));
    //     println(f"{C}");
    //     // let r = B.is_on_curve();
    //     // println(f"{r}");
    //     // A = B.sub(A);
    //     //  println(f"{A} {B}");
    // }

    let mut scalar_values: [Field; 10] = [0; 10];
    let mut points: [BabyJubJub; 10] = [Curve::zero(); 10];
    let mut scalars: [ScalarField; 10] = [ScalarField::new(); 10];
    // let x = 12345;
    points[0] = Curve::one();
    scalar_values[0] = x;
    scalars[0] = ScalarField::from_field(scalar_values[0]);
    for i in 1..10 {
        points[i] = points[i-1].dbl();
        scalar_values[i] = scalar_values[i-1] + x;
        scalars[i] = ScalarField::from_field(scalar_values[i]);
    }
    let R = Curve::msm(points, scalars);
    println(f"{R}");
    // // std::as_witness(aa);
    // // std::as_witness(bb);
}
// 7019
// #[test]
// fn test_main() {
//   //  main(1, 2);
//     // Uncomment to make test fail
//     // main(1, 1);
// }

#[test]
fn test_sub() {
    let bjj = baby_jubjub();
    let bjj_point = bjj.base8;

    // println(f"{left}");
    let point:  Curve<BabyJubJubParams> = Curve { x: bjj_point.x, y: bjj_point.y };
    println(f"BJJ GEN {point}");

    let expected = point + (point + (point));
    let result = point.dbl().dbl().sub(point);
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_mul() {
    let scalar = 13439285682734681346581734618;
    let bjj = baby_jubjub();
    let bjj_point = bjj.base8;

    let expected = bjj.curve.mul(scalar, bjj_point);
    // println(f"{left}");
    let scalar_f: ScalarField = ScalarField::from_field(scalar);
    let point:  BabyJubJub = Curve { x: bjj_point.x, y: bjj_point.y };
    let result = point.mul(scalar_f);
    assert(scalar_f.convert() == scalar);
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_msm() {
    let scalar = 13439285682734681346581734618;
    let bjj = baby_jubjub();
    let bjj_point = bjj.base8;

    let point:  BabyJubJub = Curve { x: bjj_point.x, y: bjj_point.y };
    let mut scalar_values: [Field; 10] = [0; 10];
    let mut points: [BabyJubJub; 10] = [Curve { x: 0, y: 0 }; 10];
    let mut scalars: [ScalarField; 10] = [ScalarField::new(); 10];
    let mut bjj_points: [TEPoint; 10] = [TEPoint::new(0, 0); 10];

    points[0] = point;
    scalar_values[0] = scalar;
    scalars[0] = ScalarField::from_field(scalar_values[0]);
    bjj_points[0] = TEPoint::new(points[0].x, points[0].y);

    for i in 1..10 {
        points[i] = points[i-1].dbl();
        scalar_values[i] = scalar_values[i-1] + scalar;
    }

    for i in 0..10 {
        scalars[i] = ScalarField::from_field(scalar_values[i]);
        bjj_points[i] = TEPoint::new(points[i].x, points[i].y);
        let scalar_expected = scalar_values[i];
        let scalar_result = scalars[i].convert();
        assert(scalar_result == scalar_expected);

        let result_point = points[i].mul(scalars[i]);
        let expected_point = bjj.curve.mul(scalar_values[i], bjj_points[i]);
        assert(result_point.x == expected_point.x);
        assert(result_point.y == expected_point.y);
    }
    let expected = bjj.curve.msm(scalar_values, bjj_points);
    let result = Curve::msm(points, scalars);

    assert(result.x == expected.x);
    assert(result.y == expected.y);
}
