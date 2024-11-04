# noir-edwards

Optimized implementation of Twisted Edwards curves.

Uses lookup tables and maximally efficient representations of group operations (for width-4 noir) to efficiently implement scalar multiplication and multiscalar multiplication.

Cost of 1 scalar mul = 2232 gates. Marginal cost of additional muls in an msm = 972 gates.

For example usage see `test.nr`
