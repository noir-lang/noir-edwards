# noir-edwards

Optimized implementation of Twisted Edwards curves.

Uses lookup tables and maximally efficient representations of group operations (for width-4 noir) to efficiently implement scalar multiplication and multiscalar multiplication.

Cost of 1 scalar mul = 2232 gates. Marginal cost of additional muls in an msm = 972 gates.

For example usage see `test.nr`

## Noir version compatibility

This library is tested with all Noir stable releases from v0.37.0.

## Benchmarks

TODO

## Installation

In your _Nargo.toml_ file, add the version of this library you would like to install under dependency:

```toml
[dependencies]
LIBRARY = { tag = "v0.1.0", git = "https://github.com/noir-lang/noir-edwards" }
```
