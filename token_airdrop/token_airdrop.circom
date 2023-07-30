pragma circom  2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";
include "membership_proof.circom";

template CalculateIdentityCommitment() {
    signal input in;
    signal output out;

    component poseidon = Poseidon(1);
    poseidon.inputs[0] <== in;
    out <== poseidon.out;
} 

/*
    TokenAirdops lets users claim a fungible tokens from an airdrop.
    A single user can only make one claim and take his airdrop.
*/
template TokenAirdrop(treeDepth) {
    // Merkle root of the tree in which we are trying to prove leaf's membership
    signal input merkleRoot;
    // Siblings of the leaf on its Merkle path
    signal input pathSiblings[treeDepth - 1];
    // Whether the siblings are positioned left(0) or right(1) on the Merkle path of the leaf
    signal input siblingPositions[treeDepth - 1];

    // An address of a user
    signal input claimerAddress;
    // Nullifier making sure that a single claim cannot be claimed multiple times
    signal input claimNullifier;

    // Hash of the user's address and claim nullifier which should be marked as used on the smart contract
    signal output nullifierHash;

    // Identity commitment, which is a hash of the claimer's address represents a leaf in the merkle tree
    component calcIdentityCommitment = CalculateIdentityCommitment();
    calcIdentityCommitment.in <== claimerAddress;

    component membershipProof = MembershipProof(treeDepth);
    membershipProof.leaf <== calcIdentityCommitment.out;
    membershipProof.merkleRoot <== merkleRoot;
    for (var i = 0; i < treeDepth - 1; i++) {
        membershipProof.pathSiblings[i] <== pathSiblings[i];
        membershipProof.siblingPositions[i] <== siblingPositions[i];
    }
    log("User is a member of the merkle tree:", membershipProof.out);
    membershipProof.out === 1;

    // Calculate nullifier hash
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== claimerAddress;
    poseidon.inputs[1] <== claimNullifier;

    nullifierHash <== poseidon.out;
    log("Nullifier hash:", nullifierHash);
}

component main {public[merkleRoot, claimNullifier]} = TokenAirdrop(4);
