pragma circom  2.1.4;

include "./node_modules/circomlib/circuits/comparators.circom";
include "./incrementalMerkleTree.circom";
include "./distance.circom";
include "./node_modules/circomlib/circuits/poseidon.circom";

template IsSorted(size) {
    signal input x[size];
    signal output out;

    component comps[size];
    var res = 0;

    for (var i = 0; i < size - 1; i++) {
        comps[i] = LessEqThan(32);
        comps[i].in[0] <== x[i];
        comps[i].in[1] <== x[i + 1];
        res += comps[i].out;
    }

    component finalComp = IsEqual();
    finalComp.in[0] <== res;
    finalComp.in[1] <== size - 1;

    out <== finalComp.out;
}

template Checksum(size, mod) {
    signal input arr[size];
    signal output out;
    signal sums[size];

    sums[0] <== arr[0];
    for (var i = 1; i < size; i++) {
        sums[i] <-- (sums[i - 1] + arr[i]) % mod; // We ommited the check!
    }

    out <== sums[size - 1];
}

template Checkprod(size, mod) {
    signal input arr[size];
    signal output out;
    signal prod[size];

    prod[0] <== arr[0];
    for (var i = 1; i < size; i++) {
        prod[i] <-- (prod[i - 1] * arr[i]) % mod; // We ommited the check!
    }

    out <== prod[size - 1];
}

template KNN(numElements, numAttrs, mod, treeDepth, kNeighbours) {
    signal input checksum;
    signal input checkprod;
    signal input proofPaths[numElements][treeDepth];
    signal input proofIndices[numElements][treeDepth];
    signal input commitment;
    // sorted coordinates contain coordinate index as a first element, 
    // then x,y,z coordinates and the class as the last element
    signal input sortedCoordinates[numElements][numAttrs + 2];
    signal input x[numAttrs];

    signal output neighbours[kNeighbours][numAttrs + 2];

    component checksumVerifier = Checksum(numElements, mod);
    for (var i = 0; i < numElements; i++) {
        checksumVerifier.arr[i] <== sortedCoordinates[i][0];
    }
    checksumVerifier.out === checksum;

    component checkprodVerifier = Checkprod(numElements, mod);
    for (var i = 0; i < numElements; i++) {
        checkprodVerifier.arr[i] <== sortedCoordinates[i][0];
    }
    checkprodVerifier.out === checkprod;

    component merkleProofs[numElements];
    component merkleLeafHashers[numElements];
    for (var i = 0; i < numElements; i++) {
        merkleProofs[i] = MerkleTreeInclusionProof(treeDepth);
        merkleLeafHashers[i] = Poseidon(numAttrs + 2);

        for (var j = 0; j < numAttrs + 2; j++) {
            merkleLeafHashers[i].inputs[j] <== sortedCoordinates[i][j];
        }
        merkleProofs[i].leaf <== merkleLeafHashers[i].out;

        for (var j = 0; j < treeDepth; j++) {
            merkleProofs[i].path_index[j] <== proofIndices[i][j];
            merkleProofs[i].path_elements[j][0] <== proofPaths[i][j];
        }

        merkleProofs[i].root === commitment;
    }

    signal distances[numElements];
    component distCalcs[numElements];
    for (var i = 0; i < numElements; i++) {
        distCalcs[i] = L1Distance(numAttrs);

        for (var j = 1; j < numAttrs + 1; j++) {
            distCalcs[i].x[j - 1] <== sortedCoordinates[i][j];
            distCalcs[i].y[j - 1] <== x[j - 1];
        }

        distances[i] <== distCalcs[i].distance;
    }

    component verifySorted = IsSorted(numElements);
    for (var i = 0; i < numElements; i++) {
        verifySorted.x[i] <== distances[i];
    }
    verifySorted.out === 1;

    log("\nClosest", kNeighbours, "neighbours:");
    for (var i = 0; i < kNeighbours; i++) {
        log();
        log("Neighbour", i + 1);
        for (var j = 0; j < numAttrs + 2; j++) {
            neighbours[i][j] <== sortedCoordinates[i][j];
            if (j == 0) {
                log("index:", neighbours[i][j]);
            } else if (j == numAttrs + 1) {
                log("class:", neighbours[i][j]);
            }
        }
    }
}
