# How to install

1. This will install dependencies from incrementalquintree as well:  
`sudo npm install`

2. Build the project  
`sudo npm run build`

3. Compile the circuit:  
`circom knn_classifier.circom --wasm`

# How to run

1. Enter inputs in a file `knn_classifier_inputs.xlsx`
Note: The program only supports two classes of neighbours (0 and 1)

2. Generate the witness:  
`npm start`