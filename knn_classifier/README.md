# How to run

1. This will install dependencies from incrementalquintree as well:  
`sudo npm install`

2. Build the project  
`sudo npm run build`

3. Generate inputs for the circuit:  
`npm start`

4. Compile the circuit:  
`circom knn.circom --wasm`

5. Generate the witness:  
`cd knn_js && node generate_witness.js knn.wasm ../inputs.json witness.wtns`