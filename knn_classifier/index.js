const { IncrementalQuinTree } = require('./incrementalquintree/build/IncrementalQuinTree');
const { poseidon } = require('./incrementalquintree/node_modules/circomlib');
const ff = require('./incrementalquintree/node_modules/ffjavascript');
const stringifyBigInts = (obj) => ff.utils.stringifyBigInts(obj);
const fs = require('fs');

const tree = new IncrementalQuinTree(3, 0, 2, poseidon);

const data = [
    [5, 3, 2],
    [1, 2, 3],
    [2, 3, 4],
    [0, 1, 9]
];

for (let i = 0; i < data.length; i += 1) {
    data[i] = [i + 1, ...data[i]];
}

const originalData = [...data];

for (let i = 0; i < data.length; i += 1) {
    tree.insert(
        poseidon([
            i + 1,
            ...data[i].slice(1)
        ])
    );
}

function distance(obj, x) {
    d = 0;
    for (let i = 1; i < obj.length; i += 1) {
        d += Math.abs(obj[i] - x[i - 1]);
    }
    return d;
}

const x = [1, 1, 1];

const checksum = originalData.reduce((acc, curr) => {
    return (acc + curr[0]) % 32767; // we need modul since circom works under modul, so we don't overflow
}, 0);
console.log('Checksum: ', checksum);

const checkprod = originalData.reduce((acc, curr) => {
    return (acc * curr[0]) % 32767; // we need modul since circom works under modul, so we don't overflow
}, 1);
console.log('Checkprod: ', checkprod);

console.log('Distance: ', data.map((row) => distance(row, x)));

const sorted = data.sort((a, b) => distance(a, x) - distance(b, x));
console.log('Distance sorted: ', sorted);
const sortedIndexes = sorted.map(row => row[0]);
console.log('Sorted indexes: ', sorted.map(row => row[0]));

console.log('Num rows: ', data[0].slice(1).length);
console.log('Num columns: ', data[0].length);
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