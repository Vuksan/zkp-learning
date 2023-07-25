const { IncrementalQuinTree } = require('./incrementalquintree/build/IncrementalQuinTree');
const { poseidon } = require('./incrementalquintree/node_modules/circomlib');
const ff = require('./incrementalquintree/node_modules/ffjavascript');
const stringifyBigInts = (obj) => ff.utils.stringifyBigInts(obj);
const fs = require('fs');

const tree = new IncrementalQuinTree(4, 0, 2, poseidon);

const data = [
    { coordinates: [5, 3, 2], class: 0 },
    { coordinates: [1, 2, 3], class: 1 },
    { coordinates: [2, 3, 4], class: 0 },
    { coordinates: [0, 1, 9], class: 0 },
    { coordinates: [2, 3, 2], class: 1 },
    { coordinates: [1, 9, 8], class: 1 },
    { coordinates: [8, 6, 4], class: 0 },
    { coordinates: [3, 3, 3], class: 0 }
];

const x = [1, 1, 1];

const originalCoordinates = [...data.map(d => d.coordinates)];

for (let i = 0; i < data.length; i += 1) {
    data[i].coordinates = [i + 1, ...data[i].coordinates];
}

for (let i = 0; i < data.length; i += 1) {
    tree.insert(
        poseidon([
            ...data[i].coordinates,
            data[i].class
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

const checksum = data.reduce((acc, curr) => {
    return (acc + curr.coordinates[0]) % 372183; // we need modul since circom works under modul, so we don't overflow
}, 0);
console.log('Checksum: ', checksum);

const checkprod = data.reduce((acc, curr) => {
    return (acc * curr.coordinates[0]) % 372183; // we need modul since circom works under modul, so we don't overflow
}, 1);
console.log('Checkprod: ', checkprod);

console.log('Distance: ', originalCoordinates.map((row) => distance(row, x)));

const sorted = data.sort((a, b) => {
    // Lose the index to calculate distance
    return distance(a.coordinates.slice(1), x) - distance(b.coordinates.slice(1), x);
});
console.log('Distance sorted: ', sorted);
const sortedIndexes = sorted.map(row => row.coordinates[0]);
console.log('Sorted indexes: ', sortedIndexes);

console.log('Num neighbours: ', originalCoordinates.length);
console.log('Num coordinates: ', originalCoordinates[0].length);
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

// Append class to the end of coordinates array
for (let i = 0; i < sorted.length; i += 1) {
    sorted[i].coordinates.push(data[i].class);
}

const circomInputs = {
    checksum: `${checksum}`,
    checkprod: `${checkprod}`,
    proofPaths: proofPaths.map(path => path.map(x => x[0])),
    proofIndices: proofIndices.map(indices => indices.map(x => `${x}`)),
    commitment: tree.root,
    sortedCoordinates: sorted.map(x => x.coordinates.map(x => `${x}`)),
    x: x.map(el => `${el}`)
}

// console.log(JSON.stringify(stringifyBigInts(circomInputs), null, 2));

fs.writeFileSync('inputs.json', JSON.stringify(stringifyBigInts(circomInputs), null, 2));