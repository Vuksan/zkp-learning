const { IncrementalQuinTree } = require('./incrementalquintree/build/IncrementalQuinTree');
const { poseidon } = require('./incrementalquintree/node_modules/circomlib');
const ff = require('./incrementalquintree/node_modules/ffjavascript');
const stringifyBigInts = (obj) => ff.utils.stringifyBigInts(obj);
const fs = require('fs');

const tree = new IncrementalQuinTree(4, 0, 2, poseidon);

const data = [
    [5, 3, 2],
    [1, 2, 3],
    [2, 3, 4],
    [0, 1, 9],
    [2, 3, 2],
    [1, 9, 8],
    [8, 6, 4],
    [3, 3, 3]
];

const originalData = [...data];

for (let i = 0; i < data.length; i += 1) {
    data[i] = [i + 1, ...data[i]];
}

for (let i = 0; i < originalData.length; i += 1) {
    tree.insert(
        poseidon([
            i + 1,
            ...originalData[i]
        ])
    );
}

function distance(obj, x) {
    d = 0;
    for (let i = 0; i < obj.length; i += 1) {
        d += Math.abs(obj[i] - x[i]);
    }
    return d;
}

const x = [1, 1, 1];

const checksum = data.reduce((acc, curr) => {
    return (acc + curr[0]) % 372183; // we need modul since circom works under modul, so we don't overflow
}, 0);
console.log('Checksum: ', checksum);

const checkprod = data.reduce((acc, curr) => {
    return (acc * curr[0]) % 372183; // we need modul since circom works under modul, so we don't overflow
}, 1);
console.log('Checkprod: ', checkprod);

console.log('Distance: ', originalData.map((row) => distance(row, x)));

const sorted = data.sort((a, b) => {
    // Lose the index to calculate distance
    return distance(a.slice(1), x) - distance(b.slice(1), x);
});
console.log('Distance sorted: ', sorted);
const sortedIndexes = sorted.map(row => row[0]);
console.log('Sorted indexes: ', sorted.map(row => row[0]));

console.log('Num neighbours: ', originalData.length);
console.log('Num coordinates: ', originalData[0].length);
console.log('Commitment: ', tree.root);

const proofPaths = [];
const proofIndices = [];

for (const index of sortedIndexes) {
    const proof = tree.genMerklePath(index - 1);
    proofPaths.push(proof.pathElements);
    proofIndices.push(proof.indices);
}

// console.log('Proof paths:', proofPaths);
// console.log('Proof indices:', proofIndices);

const circomInputs = {
    checksum: `${checksum}`,
    checkprod: `${checkprod}`,
    proofPaths,
    proofIndices: proofIndices.map(indices => indices.map(x => `${x}`)),
    commitment: tree.root,
    sortedRows: sorted.map(x => x.map(x => `${x}`)),
    x: x.map(el => `${el}`)
}

console.log(JSON.stringify(stringifyBigInts(circomInputs), null, 2));

fs.writeFileSync('inputs.json', JSON.stringify(stringifyBigInts(circomInputs), null, 2));