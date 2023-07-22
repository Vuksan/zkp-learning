pragma circom  2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";
include "node_modules/circomlib/circuits/mux1.circom";

/*
    BubbleSort sorts the input array of elements in the ascending order.

    argument arraySize - size of the input array
    argument numBits - number of bits array elements have
*/
template BubbleSort(arraySize, numBits) {
    signal input unsortedArray[arraySize];
    signal output sortedArray[arraySize];

    var tmpArray[arraySize];
    log("Unsorted array:");
    for (var i = 0; i < arraySize; i++) {
        log(unsortedArray[i]);
        tmpArray[i] = unsortedArray[i];
    }

    var maxIterations = arraySize;
    component mux[maxIterations][arraySize];
    component isGreater[maxIterations][arraySize];
    var actualIterations = 0; // just for log purposes

    for (var i = 0; i < maxIterations; i++) {

        var anythingChanged = 0; // just for log purposes
        for (var j = 0; j < arraySize - 1; j++) {
            mux[i][j] = MultiMux1(2);
            mux[i][j].c[0][0] <== tmpArray[j];
            mux[i][j].c[0][1] <== tmpArray[j + 1];
            mux[i][j].c[1][0] <== tmpArray[j + 1];
            mux[i][j].c[1][1] <== tmpArray[j];

            isGreater[i][j] = GreaterThan(10);
            isGreater[i][j].in[0] <== tmpArray[j];
            isGreater[i][j].in[1] <== tmpArray[j + 1];
            mux[i][j].s <== isGreater[i][j].out;

            anythingChanged += isGreater[i][j].out;

            tmpArray[j] = mux[i][j].out[0];
            tmpArray[j + 1] = mux[i][j].out[1];
        }

        if (anythingChanged > 0) {
            actualIterations++;
        }
    }

    log("Sorted array:");
    for (var i = 0; i < arraySize; i++) {
        sortedArray[i] <== tmpArray[i];
        log(sortedArray[i]);
    }
    // Required iteration is 1 more because the algorithm needs one last pass to determine that everything is sorted
    log("Performed iterations:", arraySize);
    log("Required iterations:", actualIterations + 1);
}

component main = BubbleSort(5, 10);
