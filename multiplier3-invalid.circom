pragma circom  2.0.0;

template Multiplier3() {

    // Declaration of signals.
    signal input in1;
    signal input in2;
    signal input in3;
    signal output out;

    // Constraints.
    out <== in1 * in2 * in3;
}

component main = Multiplier3();
