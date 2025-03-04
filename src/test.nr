use crate::bjj::{BabyJubJubParams, BabyJubJub};
use crate::Curve;
use crate::CurveTrait;
use crate::scalar_field::ScalarField;
use dep::ec::consts::te::baby_jubjub;
use ec::tecurve::affine::Point as TEPoint;

global BASE8: [Field; 2] = [
    5299619240641551281634865583518297030282874472190772894086521144482721001553,
    16950150798460657717958625567821834550301663161624707787222815936182638968203,
];

#[test]
fn test_sub() {
    let point: Curve<BabyJubJubParams> = Curve { x: BASE8[0], y: BASE8[1] };
    let expected = point + (point + (point));
    let result = point.dbl().dbl() - point;
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_scalar_mul_1() {
    let scalar = 9;
    let bjj_point = BabyJubJub::new(BASE8[0], BASE8[1]);
    let scalar_f: ScalarField<63> = ScalarField::from(scalar);
    let expected = bjj_point.mul(scalar_f);
    let mut result = bjj_point.dbl().dbl().dbl(); 
    result = result+ bjj_point;
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_scalar_mul_2() {
    let scalar = 125008707422548553008458566692055115405265404091165231253731979; 
    let point: BabyJubJub = BabyJubJub{x: 0x0bb77a6ad63e739b4eacb2e09d6277c12ab8d8010534e0b62893f3f6bb957051,
            y: 0x25797203f7a0b24925572e1cd16bf9edfce0051fb9e133774b3c257a872d7d8b};
    let scalar_f: ScalarField<63> = ScalarField::from(scalar);
    let result = point.mul(scalar_f);
    let expected : BabyJubJub = BabyJubJub{x: 617161874567552582384121722828904445762099298246151845490568021290206689792, y: 13034886054222108846214594281471929075849418819835081605284620402790201340104 };
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_scalar_mul_3() {
    let scalar = 54151461856964260907680256125457277518023881635046757770759266; 
    let point: BabyJubJub = BabyJubJub{x: BASE8[0], y: BASE8[1]};
    let scalar_f: ScalarField<63> = ScalarField::from(scalar);
    let result = point.mul(scalar_f);
    let expected : BabyJubJub = BabyJubJub{x: 19208535741451908456059246935738795913108647784428496829884866473148752123890, y: 11995935797001296221514672688383396330912779758746145432661060411923774860388 };
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_msm() {
    let scalar = 13439285682734681346581734618;
    let bjj = baby_jubjub();
    let bjj_point = bjj.base8;

    let point: BabyJubJub = Curve { x: bjj_point.x, y: bjj_point.y };
    let mut scalar_values: [Field; 1] = [0; 1];
    let mut points: [Curve<BabyJubJubParams>; 1] = [Curve { x: 0, y: 0 }; 1];
    let mut scalars: [ScalarField<63>; 1] = [ScalarField::new(); 1];
    let mut bjj_points: [TEPoint; 1] = [TEPoint::new(0, 0); 1];

    points[0] = point;
    scalar_values[0] = scalar;
    scalars[0] = ScalarField::from(scalar_values[0]);
    bjj_points[0] = TEPoint::new(points[0].x, points[0].y);

    for i in 1..1 {
        points[i] = points[i - 1].dbl();
        scalar_values[i] = scalar_values[i - 1] + scalar;
    }

    for i in 0..1 {
        scalars[i] = ScalarField::from(scalar_values[i]);
        bjj_points[i] = TEPoint::new(points[i].x, points[i].y);
        let scalar_expected = scalar_values[i];
        let scalar_result: Field = ScalarField::into(scalars[i]);
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
