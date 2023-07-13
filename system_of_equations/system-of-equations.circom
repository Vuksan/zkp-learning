pragma circom  2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";
include "node_modules/circomlib-matrix/circuits/matElemMul.circom";
include "node_modules/circomlib-matrix/circuits/matElemSum.circom";

// n is the number of variables in the system of equations
template SystemOfEquations(n) {
    signal input x[n]; // the solution to the system of equations
    signal input a[n][n]; // this is the coefficient matrix
    signal input b[n]; // the constants in the system of equations

    component elemMul = matElemMul(n,n);

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
            elemMul.a[i][j] <== x[j];
            elemMul.b[i][j] <== a[i][j];
        }
    }

    component elemSum[n];

    for (var i = 0; i < n; i++) {
        elemSum[i] = matElemSum(1,n);
        for (var j = 0; j < n; j++) {
            elemSum[i].a[0][j] <== elemMul.out[i][j];
        }
        elemSum[i].out === b[i];
    }
}

component main {public [a,b]} = SystemOfEquations(3);
