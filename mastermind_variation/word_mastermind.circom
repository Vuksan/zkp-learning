pragma circom 2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";
include "node_modules/circomlib/circuits/poseidon.circom";

// Rules of the game: https://www.thedarkimp.com/blog/2020/06/18/you-can-play-word-mastermind/
// Note: In this game letters [A-Z] are represented by numbers [0-25].

template WordMastermind(lettersInAlphabet, numLetters, numValidWords) {
    // Public inputs
    signal input pubValidWords[numValidWords][numLetters];
    signal input guess[numLetters];
    // a black peg is achieved for each letter that appears in the word and is in the correct position.
    signal input pubNumBlackPegs;
    // a white peg is achieved for each letter that appears in the word but is in the incorrect position.
    signal input pubNumWhitePegs;
    // a hash of the solution so that we can show that we didn't change it (since it's a private input).
    signal input publicSolutionHash;

    // Private inputs
    signal input solution[numLetters];

    // Output
    signal output correct;

    // Create a constraint that the solution and guess letters are a part of alphabet.
    component lessThan[lettersInAlphabet * 2];

    for (var i = 0; i < numLetters; i++) {
        lessThan[i] = LessThan(5);
        lessThan[i].in[0] <== guess[i];
        lessThan[i].in[1] <== lettersInAlphabet;
        lessThan[i].out === 1;
        lessThan[i+lettersInAlphabet] = LessThan(5);
        lessThan[i+lettersInAlphabet].in[0] <== solution[i];
        lessThan[i+lettersInAlphabet].in[1] <== lettersInAlphabet;
        lessThan[i+lettersInAlphabet].out === 1;
    }

    // TODO: Create a constraint that checks whether both the solution and the guess are valid words.

    // The hash of the solution should match public input so that we know that prover hasn't changed it.
    component poseidon = Poseidon(numLetters);
    for (var i = 0; i < numLetters; i++) {
        poseidon.inputs[i] <== solution[i];
    }
    publicSolutionHash === poseidon.out;

    // Count white and black pegs
    component isEqual[numLetters ** 2];
    var equalIndex = 0;
    var numBlackPegs = 0;
    var numWhitePegs = 0;

    for (var i = 0; i < numLetters; i++) {
        for (var j = 0; j < numLetters; j++) {
            isEqual[equalIndex] = IsEqual();
            isEqual[equalIndex].in[0] <== solution[j];
            isEqual[equalIndex].in[1] <== guess[i];
            // Are they on a different spot? -> white hit
            numWhitePegs += isEqual[equalIndex].out;
            if (i == j) {
                // Are they on the same spot? -> black hit
                numBlackPegs += isEqual[equalIndex].out;
                numWhitePegs -= isEqual[equalIndex].out;
            }
            equalIndex++;
        }
    }

    // Create a constraint around the number of black pegs
    component equalBlackPegs = IsEqual();
    equalBlackPegs.in[0] <== pubNumBlackPegs;
    equalBlackPegs.in[1] <== numBlackPegs;
    equalBlackPegs.out === 1;
    
    // Create a constraint around the number of white pegs
    component equalWhitePegs = IsEqual();
    equalWhitePegs.in[0] <== pubNumWhitePegs;
    equalWhitePegs.in[1] <== numWhitePegs;
    equalWhitePegs.out === 1;

    correct <== equalBlackPegs.out * equalWhitePegs.out;
    log("Solution satisfies the criteria:", correct);
 }

 component main {public [pubValidWords, guess, pubNumBlackPegs, pubNumWhitePegs, publicSolutionHash]} = WordMastermind(26, 4, 50);
