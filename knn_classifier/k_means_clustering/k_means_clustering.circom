pragma circom  2.1.4;

include "../distance.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

/*
    Determines to which centroid provided element is closest.
*/
template KMeansClustering(numAttrs) {
    signal input element[numAttrs];
    signal input centroids[2][numAttrs];
    signal output closestCentroidIndex;

    component distCalcs[2];
    component diffComp = GreaterThan(32);

    for (var c = 0; c < 2; c++) {

        distCalcs[c] = L1Distance(numAttrs);

        for (var i = 0; i < numAttrs; i++) {
            distCalcs[c].x[i] <== element[i];
            distCalcs[c].y[i] <== centroids[c][i];
        }

        diffComp.in[c] <== distCalcs[c].distance;
    }

    closestCentroidIndex <== diffComp.out;
}
