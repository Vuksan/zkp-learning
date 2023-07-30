# Zicket

Circuit implementation for Zicket app (https://zicket.vercel.app)

# How to install

1. This will install dependencies from incrementalquintree as well:  
`sudo npm install`

2. Build the project  
`sudo npm run build`

3. Compile the circuit:  
`circom zicket.circom --wasm`

# How to run

1. Enter inputs in a file `merkle_inputs.json`

2. Generate the inputs for the circuit:  
`npm start`

3. Generate the proof:
`cd zicket_js && node generate_witness.js zicket.wasm ../inputs.json witness.wtns`