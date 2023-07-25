pragma circom  2.1.4;

include "./node_modules/circomlib/circuits/comparators.circom";
include "./incrementalMerkleTree.circom";
include "./node_modules/circomlib/circuits/poseidon.circom";

template AbsDiff() {
    signal input a;
    signal input b;
    signal output out;

    component diffComp = GreaterEqThan(32);
    diffComp.in[0] <== a;
    diffComp.in[1] <== a;

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

template KNN(treeSize, numAttrs, mod, treeDepth, kNeighbours) {
    signal input checksum;
    signal input checkprod;
    signal input proofPaths[treeSize][treeDepth][1];
    signal input proofIndices[treeSize][treeDepth][1];
    signal input commitment;
    signal input sortedRows[treeSize][numAttrs + 1];
    signal input x[numAttrs];

    component checksumVerifier = Checksum(treeSize, mod);
    for (var i = 0; i < treeSize; i++) {
        checksumVerifier.arr[i] <== sortedRows[i][0];
    }
    checksumVerifier.out === checksum;

    component checkprodVerifier = Checkprod(treeSize, mod);
    for (var i = 0; i < treeSize; i++) {
        checkprodVerifier.arr[i] <== sortedRows[i][0];
    }
    checkprodVerifier.out === checkprod;

    component merkleProofs[treeSize];
    component merkleLeafHashers[treeSize];
    for (var i = 0; i < treeSize; i++) {
        merkleProofs[i] = MerkleTreeInclusionProof(treeDepth);
        merkleLeafHashers[i] = Poseidon(numAttrs + 1);

        for (var j = 0; j < numAttrs + 1; j++) {
            merkleLeafHashers[i].inputs[j] <== sortedRows[i][j];
        }
        merkleProofs[i].leaf <== merkleLeafHashers[i].out;

        for (var j = 0; j < treeDepth; j++) {
            merkleProofs[i].path_index[j] <== proofIndices[i][j][0];
            merkleProofs[i].path_elements[j][0] <== proofPaths[i][j][0];
        }

        merkleProofs[i].root === commitment;
    }

    signal distances[treeSize];
    component distCalcs[treeSize];
    for (var i = 0; i < treeSize; i++) {
        distCalcs[i] = L1Distance(numAttrs);

        for (var j = 1; j < numAttrs + 1; j++) {
            distCalcs[i].x[j - 1] <== sortedRows[i][j];
            distCalcs[i].y[j - 1] <== x[j - 1];
        }

        distances[i] <== distCalcs[i].distance;
    }

    component verifySorted = IsSorted(treeSize);
    for (var i = 0; i < treeSize; i++) {
        verifySorted.x[i] <== distances[i];
    }
    verifySorted.out === 1;

    signal output neighbours[kNeighbours][numAttrs];
    log("Closest", kNeighbours, "neighbours:");
    for (var i = 0; i < kNeighbours; i++) {
        log("Neighbour", i + 1, "coordinates:");
        for (var j = 1; j <= numAttrs; j++) {
            neighbours[i][j - 1] <== sortedRows[i][j];
            log(neighbours[i][j - 1]);
        }
    }
}

// Za domaci napravi da radi sa realnim brojevima, tj da javascript spremi odgovarajuce brojeve
// Takodje napravi program koji ucita csv ili excel i izbaci proof za k najblizih instanci
// Bonus: Klasifikator gde imamo dve klase i odredjuje se kojoj pripada -> moze u novi fajl

component main = KNN(8, 3, 372183, 4, 3);
