pragma circom  2.1.4;

include "./knn.circom";
include "./node_modules/circomlib/circuits/comparators.circom";
include "./node_modules/circomlib/circuits/mux1.circom";
include "./k_means_clustering/k_means_clustering.circom";

template KNNClassifier(numElements, numAttrs, mod, treeDepth, kNeighbours) {
    signal input checksum;
    signal input checkprod;
    signal input proofPaths[numElements][treeDepth];
    signal input proofIndices[numElements][treeDepth];
    signal input commitment;
    // sorted coordinates contain coordinate index as a first element, 
    // then x,y,z coordinates and the class as the last element
    signal input sortedCoordinates[numElements][numAttrs + 2];
    signal input centroids[2][numAttrs];
    signal input x[numAttrs];
    
    signal output xClass;

    // Check if coordinates are clustered correctly
    component kMeans[numElements];
    for (var i = 0; i < numElements; i++) {
        kMeans[i] = KMeansClustering(numAttrs);

        for (var j = 0; j < numAttrs; j++) {
            kMeans[i].element[j] <== sortedCoordinates[i][j + 1]; // we skip the index and class
        }
        for (var c = 0; c < 2; c++) {
            for (var j = 0; j < numAttrs; j++) {
                kMeans[i].centroids[c][j] <== centroids[c][j];
            }
        }

        sortedCoordinates[i][numAttrs + 1] === kMeans[i].closestCentroidIndex;
    }
    
    component knn = KNN(numElements, numAttrs, mod, treeDepth, kNeighbours);
    knn.checksum <== checksum;
    knn.checkprod <== checkprod;
    knn.commitment <== commitment;
    for (var i = 0; i < numElements; i++) {
        for (var j = 0; j < treeDepth; j++) {
            knn.proofPaths[i][j] <== proofPaths[i][j];
            knn.proofIndices[i][j] <== proofIndices[i][j];
        }
        for (var j = 0; j < numAttrs + 2; j++) {
            knn.sortedCoordinates[i][j] <== sortedCoordinates[i][j];
        }
    }
    for (var i = 0; i < numAttrs; i++) {
        knn.x[i] <== x[i];
    }

    // We take class for each of the closest neighbours
    // and find which one has the most occurances
    var classElements[2];
    component isEqual[2][kNeighbours];
    for (var c = 0; c < 2; c++) {
        for (var n = 0; n < kNeighbours; n++) {
            isEqual[c][n] = IsEqual();
            isEqual[c][n].in[0] <== c;
            isEqual[c][n].in[1] <== knn.neighbours[n][numAttrs + 1];
            classElements[c] += isEqual[c][n].out;
        }
    }

    component mux = Mux1();
    mux.c[0] <== 0; // Class 0
    mux.c[1] <== 1; // Class 1
    component isLess = LessThan(32);
    isLess.in[0] <== classElements[0];
    isLess.in[1] <== classElements[1];
    mux.s <== isLess.out;

    xClass <== mux.out;
    log();
    log("X coordinate is of class:", xClass);
}

component main = KNNClassifier(8, 3, 372183, 4, 3);
