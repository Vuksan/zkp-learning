const { IncrementalQuinTree } = require('./incrementalquintree/build/IncrementalQuinTree');
const { poseidon } = require('./incrementalquintree/node_modules/circomlib');
const ff = require('./incrementalquintree/node_modules/ffjavascript');
const stringifyBigInts = (obj) => ff.utils.stringifyBigInts(obj);
const fs = require('fs');
const { parse } = require('csv-parse/sync');
const { exec } = require('child_process');
const { error } = require('console');
const { stdout, stderr } = require('process');

function maxDigitsAfterDecimal(arr) {
    var largestNumDigits = 0;
    for (var i = 0; i < arr.length; i += 1) {
        if (!Number.isInteger(arr[i])) {
            let dec = arr[i].toString().split('.');
            let decLength = dec[1].length;
            largestNumDigits = largestNumDigits < decLength ? decLength : largestNumDigits;
        }
    }
    return largestNumDigits;
}

function normalizeData(arr, numDecimalDigits) {
    var normalized = [];
    for (var i = 0; i < arr.length; i += 1) {
        normalized[i] = arr[i] * Math.pow(10, numDecimalDigits);
    }

    return normalized;
}

const tree = new IncrementalQuinTree(4, 0, 2, poseidon);

// Read neighbours from the file
const neighbours = parse(fs.readFileSync("input_neighbours.csv"), {delimiter: ",", trim: true, from_line: 2, cast: true});
if (neighbours.length != 8) {
    console.error('There should be 8 neighbours!');
    process.exit(1);
}
for (var i = 0; i < neighbours.length; i += 1) {
    if (neighbours[i][3] < 0 || neighbours[i][3] > 1) {
        console.error('There should only be two classes: 0 and 1!');
        process.exit(1);
    }
}

// Read the value of x from the file
const input = parse(fs.readFileSync("input_x.csv"), {delimiter: ",", trim: true, from_line: 2, cast: true});
if (input.length > 1) {
    console.error('There should be only one input!');
    process.exit(1);
}
const x = input[0];

const originalCoordinates = [...neighbours.map(n => n.slice(0,3))];

// TODO: Normalize data to integers, since circom and poseidon only work with integers
const maxDecimalDigits = maxDigitsAfterDecimal([...neighbours.flat(), ...x]);
const xInt = normalizeData(x, maxDecimalDigits);
const data = [];
for (var i = 0; i < neighbours.length; i += 1) {
    data[i] = normalizeData(neighbours[i].slice(0, 3), maxDecimalDigits);
    data[i].push(neighbours[i][3]);
}

for (let i = 0; i < data.length; i += 1) {
    data[i] = [i + 1, ...data[i]];
}

for (let i = 0; i < data.length; i += 1) {
    tree.insert(poseidon(data[i]));
}

function distance(obj, x) {
    d = 0;
    for (let i = 0; i < obj.length; i += 1) {
        d += Math.abs(obj[i] - x[i]);
    }
    return d;
}

const checksum = data.reduce((acc, curr) => {
    return (acc + curr[0]) % 372183; // we need modul since circom works under modul, so we don't overflow
}, 0);
console.log('Checksum: ', checksum);

const checkprod = data.reduce((acc, curr) => {
    return (acc * curr[0]) % 372183; // we need modul since circom works under modul, so we don't overflow
}, 1);
console.log('Checkprod: ', checkprod);

console.log('Distance: ', originalCoordinates.map((row) => distance(row, x)));

const sorted = data.sort((a, b) => {
    // Lose the index and class to calculate distance
    return distance(a.slice(1, 4), xInt) - distance(b.slice(1, 4), xInt);
});
console.log('Distance sorted: ', sorted);
const sortedIndexes = sorted.map(row => row[0]);
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

const circomInputs = {
    checksum: `${checksum}`,
    checkprod: `${checkprod}`,
    proofPaths: proofPaths.map(path => path.map(x => x[0])),
    proofIndices: proofIndices.map(indices => indices.map(x => `${x}`)),
    commitment: tree.root,
    sortedCoordinates: sorted.map(x => x.map(x => `${x}`)),
    x: xInt.map(el => `${el}`)
}

// console.log(JSON.stringify(stringifyBigInts(circomInputs), null, 2));
const inputsFilename = 'inputs.json';

fs.writeFileSync(inputsFilename, JSON.stringify(stringifyBigInts(circomInputs), null, 2));

// Generate the witness
exec(`cd knn_classifier_js && node generate_witness.js knn_classifier.wasm ../${inputsFilename} witness.wtns`, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    console.log(stdout);
});
