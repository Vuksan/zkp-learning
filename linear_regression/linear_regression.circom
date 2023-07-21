pragma circom  2.0.0;

/*
    Multiplies two arrays and sums the results
*/
template DotProduct(n) {
    signal input u[n];
    signal input v[n];
    signal input intercept;
    signal output prod;

    signal tmp[n];

    tmp[0] <== intercept + u[0] * v[0];
    for (var i = 1; i < n; i++) {
        tmp[i] <== tmp[i - 1] + u[i] * v[i];
    }

    prod <== tmp[n - 1];
}

/*
    This circuit calculates the result of linear regression algorithm.
    
    x = [X1, X2, ..., Xn]
    w = [b, W1, W2, ..., Wn]
    y = x * w = b + X1 * W1 + X2 * W2 + ... + Xn * Wn
*/
template LinearRegression(n) {
    signal input x[n];
    signal input w[n + 1]; // because of bias (b)

    signal output y;

    component dotProd = DotProduct(n);
    dotProd.intercept <== w[0];
    for (var i = 0; i < n; i++) {
        dotProd.u[i] <== x[i];
        dotProd.v[i] <== w[i + 1];
    }

    y <== dotProd.prod;
    log("Result:", y);
}

component main = LinearRegression(10);
