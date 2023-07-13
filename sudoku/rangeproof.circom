pragma circom  2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";

template rangeproof(n) {

    // Declaration of signals.
    signal input range[2];
    signal input in;
    signal output out;

    // Constraints.
    component gte = GreaterEqThan(n);
    gte.in[0] <== in;
    gte.in[1] <== range[0];

    component lte = LessEqThan(n);
    lte.in[0] <== in;
    lte.in[1] <== range[1];

    out <== gte.out * lte.out;
}
