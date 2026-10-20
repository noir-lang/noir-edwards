# noir-edwards

> [!WARNING]
> **This library is experimental software. It has not been fully audited and is not guaranteed to be secure. Expect bugs!**
>
> Bugs in this library can lead to under-constrained circuits, allowing invalid proofs to be accepted. Do not rely on it to protect real assets or sensitive data without your own independent review.

Optimized implementation of Twisted Edwards curves.

Uses lookup tables and maximally efficient representations of group operations (for width-4 noir) to efficiently implement scalar multiplication and multiscalar multiplication.

Cost of 1 scalar mul = 2232 gates. Marginal cost of additional muls in an msm = 972 gates.

For example usage see `test.nr`
