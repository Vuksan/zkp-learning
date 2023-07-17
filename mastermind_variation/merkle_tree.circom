pragma circom  2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";

template HashTreeLeaf() {
    signal input leaf;
    signal output out;

    component poseidon = Poseidon(1);

    poseidon.inputs[0] <== leaf;
    out <== poseidon.out;
}

template CreateMerkleTree(numLeaves, treeDepth) {
    signal input leaves[numLeaves];
    signal output merkleRoot;

    // TODO: If numLeaves is odd, duplicate the last leaf.

    signal merkleTree[treeDepth][numLeaves];

    // Lets hash all leaves first.
    component hashLeaves[numLeaves];

    log("Merkle tree level 0:");
    for (var i = 0; i < numLeaves; i++) {
        hashLeaves[i] = HashTreeLeaf();
        hashLeaves[i].leaf <== leaves[i];
        merkleTree[0][i] <== hashLeaves[i].out;
        log(merkleTree[0][i]);
    }

    var numParents = numLeaves / 2;
    var parentLevel = 1;
    var childLevel = 0;
    var nodePositionIndex; // index of the node on a level
    component poseidon[treeDepth][numParents];

    while (parentLevel < treeDepth) {
        nodePositionIndex = 0;

        log("Merkle tree level", parentLevel, ":");
        for (var i = 0; i < numParents; i++) {
            poseidon[childLevel][i] = Poseidon(2);
            poseidon[childLevel][i].inputs[0] <== merkleTree[childLevel][2 * i];
            poseidon[childLevel][i].inputs[1] <== merkleTree[childLevel][2 * i + 1];
            merkleTree[parentLevel][nodePositionIndex] <== poseidon[childLevel][i].out;
            log(merkleTree[parentLevel][nodePositionIndex]);
            nodePositionIndex++;
        }
        numParents = nodePositionIndex / 2;

        // Fill remaining empty spaces on a level with zeros
        while (nodePositionIndex < numLeaves) {
            merkleTree[parentLevel][nodePositionIndex] <== 0;
            nodePositionIndex++;
        }

        parentLevel++;
        childLevel++;
    }

    merkleRoot <== merkleTree[treeDepth - 1][0];
    log("Merkle root is:", merkleRoot);
}
