# Changelog

## [0.2.4](https://github.com/noir-lang/noir-edwards/compare/v0.2.3...v0.2.4) (2025-07-17)


### Bug Fixes

* Fix `to_le_radix_16` ([#43](https://github.com/noir-lang/noir-edwards/issues/43)) ([c4f4dfe](https://github.com/noir-lang/noir-edwards/commit/c4f4dfe838df5f65b935715ef350b861240370e3))

## [0.2.3](https://github.com/noir-lang/noir-edwards/compare/v0.2.2...v0.2.3) (2025-07-15)


### Bug Fixes

* Don't use private to_le_radix from stdlib ([#40](https://github.com/noir-lang/noir-edwards/issues/40)) ([9ff020e](https://github.com/noir-lang/noir-edwards/commit/9ff020e88464f54027717ddb585ef24cf8b4aa2a))
* Make some items public ([#41](https://github.com/noir-lang/noir-edwards/issues/41)) ([022fb10](https://github.com/noir-lang/noir-edwards/commit/022fb107c36d73c71374ef037bb8a80b53a5aaf6))

## [0.2.2](https://github.com/noir-lang/noir-edwards/compare/v0.2.1...v0.2.2) (2025-05-22)


### Bug Fixes

* Always use u32 to index arrays ([#38](https://github.com/noir-lang/noir-edwards/issues/38)) ([557245f](https://github.com/noir-lang/noir-edwards/commit/557245f4c3b0c7c394ea0812584fd8b333936174))

## [0.2.1](https://github.com/noir-lang/noir-edwards/compare/v0.2.0...v0.2.1) (2025-03-28)


### Bug Fixes

* Fixed the absolute value being computed wrong ([#35](https://github.com/noir-lang/noir-edwards/issues/35)) ([3762a22](https://github.com/noir-lang/noir-edwards/commit/3762a22fb9c6174cf8169c88bace8b08724fcee2))

## [0.2.0](https://github.com/noir-lang/noir-edwards/compare/v0.1.1...v0.2.0) (2025-03-14)


### ⚠ BREAKING CHANGES

* bump minimum noir version to 1.0.0-beta.0 ([#27](https://github.com/noir-lang/noir-edwards/issues/27))

### Bug Fixes

* Add missing trait imports ([#26](https://github.com/noir-lang/noir-edwards/issues/26)) ([e986b2f](https://github.com/noir-lang/noir-edwards/commit/e986b2f9adcd4856bf3ec2bd3fe61e377170226c))
* Fixed the bug in `from::&lt;Field&gt;` ([#33](https://github.com/noir-lang/noir-edwards/issues/33)) ([c455407](https://github.com/noir-lang/noir-edwards/commit/c4554075e0f4d3c8b1af2a3b13bca5190985c0a9))


### Miscellaneous Chores

* Bump minimum noir version to 1.0.0-beta.0 ([#27](https://github.com/noir-lang/noir-edwards/issues/27)) ([2b76c43](https://github.com/noir-lang/noir-edwards/commit/2b76c437f0d58f3f7153fbcddd0f03c26b88e090))

## [0.1.1](https://github.com/noir-lang/noir-edwards/compare/v0.1.0...v0.1.1) (2025-01-16)


### Bug Fixes

* Add necessary unsafe blocks ([#23](https://github.com/noir-lang/noir-edwards/issues/23)) ([dbd41da](https://github.com/noir-lang/noir-edwards/commit/dbd41da8e83607d231f2b7d969a63be7878f38dd))

## 0.1.0 (2024-12-04)


### ⚠ BREAKING CHANGES

* update to support Noir 0.37.0 ([#9](https://github.com/noir-lang/noir-edwards/issues/9))
* update to support Noir 0.36.0 ([#7](https://github.com/noir-lang/noir-edwards/issues/7))

### Features

* Update to support Noir 0.36.0 ([#7](https://github.com/noir-lang/noir-edwards/issues/7)) ([3188ea7](https://github.com/noir-lang/noir-edwards/commit/3188ea74fe3b059219a2ea87899589c266256d74))


### Bug Fixes

* Update to support Noir 0.37.0 ([#9](https://github.com/noir-lang/noir-edwards/issues/9)) ([a8156aa](https://github.com/noir-lang/noir-edwards/commit/a8156aac31f46de85b2d5f69ac71050b58daf9dc))
* Use `ec` library instead of standard library ([#13](https://github.com/noir-lang/noir-edwards/issues/13)) ([af7daa8](https://github.com/noir-lang/noir-edwards/commit/af7daa8f5f942435e405f69f7c11182a350f65b7))


### Miscellaneous Chores

* Add release-please ([#16](https://github.com/noir-lang/noir-edwards/issues/16)) ([8f17cdf](https://github.com/noir-lang/noir-edwards/commit/8f17cdfdcade8a4fd3ae54450517a57ba3313f61))
