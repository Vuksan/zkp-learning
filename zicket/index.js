const { IncrementalQuinTree } = require('./incrementalquintree/build/IncrementalQuinTree');
const { poseidon } = require('./incrementalquintree/node_modules/circomlib');
const fs = require('fs');
const ff = require('./incrementalquintree/node_modules/ffjavascript');
const stringifyBigInts = (obj) => ff.utils.stringifyBigInts(obj);

const tree = new IncrementalQuinTree(4, 0, 2, poseidon);

// Read user addresses from the file
const inputs = JSON.parse(fs.readFileSync('merkle_inputs.json'));
const userAddresses = inputs['userAddresses'];
const proofAddress = inputs['proofAddress'];
const purchaseNullifier = inputs['purchaseNullifier'];

// proofAddress must be in userAddresses
// Remember the index
const proofAddressIndex = userAddresses.indexOf(proofAddress);
if (proofAddressIndex < 0) {
    console.error("proofAddress should be in userAddresses!");
    process.exit(1);
}

// Insert user addresses in merkle tree
for (let i = 0; i < userAddresses.length; i += 1) {
    tree.insert(poseidon([userAddresses[i]]));
}
console.log("Merkle tree root: ", tree.root);

// Find merkle path siblings and indices for the proofAddress
const merklePath = tree.genMerklePath(proofAddressIndex);

const circomInputs = {
    usersRoot: tree.root,
    pathSiblings: merklePath.pathElements.map(path => path[0]),
    siblingPositions: merklePath.indices.map(index => `${index}`),
    usersAddress: proofAddress,
    purchaseNullifier: purchaseNullifier
}

console.log(circomInputs);
const output = JSON.stringify(stringifyBigInts(circomInputs), null, 2);
console.log(output);
fs.writeFileSync("inputs.json", output);
