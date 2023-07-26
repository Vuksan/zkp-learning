const { IncrementalQuinTree } = require('./incrementalquintree/build/IncrementalQuinTree');
const { poseidon } = require('./incrementalquintree/node_modules/circomlib');
const ff = require('./incrementalquintree/node_modules/ffjavascript');
const stringifyBigInts = (obj) => ff.utils.stringifyBigInts(obj);
const fs = require('fs');
const xlsx = require('xlsx');
const { exec } = require('child_process');
const { error } = require('console');
const { stdout, stderr } = require('process');

const tree = new IncrementalQuinTree(4, 0, 2, poseidon);

// Read the inputs from the file
const workbook = xlsx.readFile('knn_classifier_inputs.xlsx');
const workbook_sheets = workbook.SheetNames;
// First sheet contains neighbours
const neighbours = xlsx.utils.sheet_to_json(workbook.Sheets[workbook_sheets[0]]);
if (neighbours.length != 8) {
    console.error('There should be 8 neighbours!');
    process.exit(1);
}
var data = [];
for (var i = 0; i < neighbours.length; i += 1) {
    if (neighbours[i].class < 0 || neighbours[i].class > 1) {
        console.error('There should only be two classes: 0 and 1!');
        process.exit(1);
    }
    data[i] = {
        coordinates: [neighbours[i].x, neighbours[i].y, neighbours[i].z],
        class: neighbours[i].class
    }
}

// Second sheet contains value of x
const input = xlsx.utils.sheet_to_json(workbook.Sheets[workbook_sheets[1]]);
if (input.length > 1) {
    console.error('There should be only one input!');
    process.exit(1);
}
const x = [input[0].x, input[0].y, input[0].z];

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
