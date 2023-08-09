pragma circom  2.1.4;

include "./node_modules/circomlib/circuits/comparators.circom";

template AbsDiff() {
    signal input a;
    signal input b;
    signal output out;

    component diffComp = GreaterEqThan(32);
    diffComp.in[0] <== a;
    diffComp.in[1] <== b;

    signal tmp1 <== diffComp.out * (a - b);
    signal tmp2 <== (1 - diffComp.out) * (b - a);
    out <== tmp1 + tmp2;
}

template L1Distance(size) {
    signal input x[size];
    signal input y[size];
    signal output distance;

    var totalDist = 0;
    component absDiffs[size];

    for (var i = 0; i < size; i++) {
        absDiffs[i] = AbsDiff();
        absDiffs[i].a <== x[i];
        absDiffs[i].b <== y[i];
        totalDist += absDiffs[i].out;
    }

    distance <== totalDist;
}
