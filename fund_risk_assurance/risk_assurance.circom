pragma circom  2.1.4;

include "./node_modules/circomlib/circuits/comparators.circom";

template RiskAssurance(numAssets) {
    signal input weightedPortfolio[numAssets];
    signal input riskConstraints[numAssets];
    // Weighted risk constraint represents individual risk constraint of the asset 
    // multiplied by that asset's weight in the portfolio of the fund.
    signal input weightedRiskConstraints[numAssets];
    // Upper and lower risk limit
    signal input riskLimits[2];
    signal output aggregatedRisk;

    // Sum of all weights should be equal to 1 (or 100 if scaled)
    var sumWeights = 0;
    for (var a = 0; a < numAssets; a++) {
        sumWeights += weightedPortfolio[a];
    }
    sumWeights === 100;

    // Weighted risk constraint should be calculated correctly
    for (var a = 0; a < numAssets; a++) {
        weightedRiskConstraints[a] === weightedPortfolio[a] * riskConstraints[a];
    }

    // Aggregated risk constraint should be within risk limits set by an investor
    var aggRisk = 0;
    for (var a = 0; a < numAssets; a++) {
        aggRisk += weightedRiskConstraints[a];
    }

    component gte = GreaterEqThan(32);
    gte.in[0] <== aggRisk;
    gte.in[1] <== riskLimits[0];
    gte.out === 1;
    
    component lte = LessEqThan(32);
    lte.in[0] <== aggRisk;
    lte.in[1] <== riskLimits[1];
    lte.out === 1;

    aggregatedRisk <== aggRisk;
}

component main {public[riskConstraints, riskLimits]} = RiskAssurance(10);
