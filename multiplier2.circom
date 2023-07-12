pragma circom  2.0.0;

/* This circuit template checks that out is the multiplication of in1 and in2. */

template Multiplier2 () {
    // Declaration of signals.
    signal input in1;
    signal input in2;
    signal output out;

    // Constraints.
    out <== in1 * in2;
}

component main = Multiplier2();
