pragma circom  2.0.0;

include "node_modules/circomlib/circuits/mux1.circom";
include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";

template CalculateMerkleRoot(treeDepth) {
    signal input leaf;
    signal input pathSiblings[treeDepth - 1];
    signal input siblingPositions[treeDepth - 1];

    signal output merkleRoot;

    component multiplexer[treeDepth];
    signal nodes[treeDepth];
    nodes[0] <== leaf;

    component poseidons[treeDepth];

    // Calculate the parent for each tree level until we get to the root
    for (var level = 0; level < treeDepth - 1; level++) {
        // Determine on which side of the leaf (and nodes on the path) is the sibling located
        // For this we use multiplexer with siblingPositions[level] as a selector
        // We only need 2 for multiplexer since sibling can be either on the left or right side of the node
        multiplexer[level] = MultiMux1(2);
        multiplexer[level].c[0][0] <== pathSiblings[level];
        multiplexer[level].c[0][1] <== nodes[level];
        multiplexer[level].c[1][0] <== nodes[level];
        multiplexer[level].c[1][1] <== pathSiblings[level];
        multiplexer[level].s <== siblingPositions[level];

        // We hash the node and its sibling and get the parent, which we store on the next level.
        poseidons[level] = Poseidon(2);
        poseidons[level].inputs[0] <== multiplexer[level].out[0];
        poseidons[level].inputs[1] <== multiplexer[level].out[1];
        nodes[level + 1] <== poseidons[level].out;
    }

    merkleRoot <== nodes[treeDepth - 1];
    log("Calculated merkle root:", merkleRoot);
}

template MembershipProof(treeDepth) {
    // Leaf for which we are trying to prove membership
    // Note: data should be hashed
    signal input leaf;
    // Merkle root of the tree in which we are trying to prove leaf's membership
    signal input merkleRoot;
    // Siblings of the leaf on its Merkle path
    signal input pathSiblings[treeDepth - 1];
    // Whether the siblings are positioned left(0) or right(1) on the Merkle path of the leaf
    signal input siblingPositions[treeDepth - 1];

    // Whether the leaf is a member of the tree (1), or not (0)
    signal output out;

    // We calculate the merkle root given the leaf and its siblings
    component calculateMerkleRoot = CalculateMerkleRoot(treeDepth);
    calculateMerkleRoot.leaf <== leaf;
    for (var level = 0; level < treeDepth - 1; level++) {
        calculateMerkleRoot.pathSiblings[level] <== pathSiblings[level];
        calculateMerkleRoot.siblingPositions[level] <== siblingPositions[level];
    }

    // If calculated merkle root matches the one from the input, the proof is correct
    component isEqual = IsEqual();
    isEqual.in[0] <== merkleRoot;
    isEqual.in[1] <== calculateMerkleRoot.merkleRoot;
    out <== isEqual.out;

    log("Result:", out);
}

component main {public [merkleRoot]} = MembershipProof(4);
