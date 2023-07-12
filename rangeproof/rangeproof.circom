pragma circom  2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";

template Rangeproof(n) {

    // Declaration of signals.
    signal input rangeLowerBound;
    signal input rangeUpperBound;
    signal input in;
    // signal tmp1;
    // signal tmp2;
    signal output out;

    // Constraints.
    component gte = GreaterEqThan(n);
    gte.in[0] <== in;
    gte.in[1] <== rangeLowerBound;
    // tmp1 <== gte.out;

    component lte = LessEqThan(n);
    lte.in[0] <== in;
    lte.in[1] <== rangeUpperBound;
    // tmp2 <== lte.out;

    // out <== tmp1 * tmp2;
    out <== gte.out * lte.out;
    log("Result is:", out);
}

component main {public[rangeLowerBound, rangeUpperBound]} = Rangeproof(64);
