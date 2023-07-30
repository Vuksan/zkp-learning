pragma circom  2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";
include "merkle_tree/incrementalMerkleTree.circom";

template CalculateIdentityCommitment() {
    signal input in;
    signal output out;

    component poseidon = Poseidon(1);
    poseidon.inputs[0] <== in;
    out <== poseidon.out;
}

/*
    Circuit implementation for Zicket app (https://zicket.vercel.app)
    User needs to call a smart contract with this proof along with the payment to purchase a ticket
    A single user can only purchase one ticket.
*/
template Zicket(treeDepth) {
    // Merkle root for the tree of registered users
    signal input usersRoot;
    // Siblings of the leaf on its Merkle path
    signal input pathSiblings[treeDepth];
    // Whether the siblings are positioned left(0) or right(1) on the Merkle path of the leaf
    signal input siblingPositions[treeDepth];

    // User's address
    signal input usersAddress;
    // Nullifier making sure that user cannot buy more than one ticket
    signal input purchaseNullifier;

    // Hash of the user's address and purchase nullifier which should be marked as used on the smart contract
    signal output nullifierHash;

    // Identity commitment, which is a hash of the user's address represents a leaf in the merkle tree
    component calcIdentityCommitment = CalculateIdentityCommitment();
    calcIdentityCommitment.in <== usersAddress;

    component membershipProof = MerkleTreeInclusionProof(treeDepth);
    membershipProof.leaf <== calcIdentityCommitment.out;
    for (var i = 0; i < treeDepth; i++) {
        membershipProof.path_index[i] <== siblingPositions[i];
        membershipProof.path_elements[i][0] <== pathSiblings[i];
    }
    membershipProof.root === usersRoot;

    // Calculate nullifier hash
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== usersAddress;
    poseidon.inputs[1] <== purchaseNullifier;

    nullifierHash <== poseidon.out;
    log("Nullifier hash:", nullifierHash);
}

component main {public[usersRoot]} = Zicket(4);
