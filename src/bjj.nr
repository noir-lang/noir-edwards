use crate::Curve;
use crate::TECurveParameterTrait;

pub struct BabyJubJubParams {}
impl TECurveParameterTrait for BabyJubJubParams {
    fn a() -> Field {
        168700
    }
    fn d() -> Field {
        168696
    }
    fn gen() -> (Field, Field) {
        (
            0x023343e3445b673d38bcba38f25645adb494b1255b1162bb40f41a59f4d4b45e,
            0x0c19139cb84c680a6e14116da06056174a0cfa121e6e5c2450f87d64fc000001,
        )
    }
}
pub type BabyJubJub = Curve<BabyJubJubParams>;
