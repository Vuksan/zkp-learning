from sklearn.linear_model import LinearRegression
from sklearn.datasets import load_diabetes
import pandas as pd
import numpy as np
from math import trunc, log
import matplotlib.pyplot as plt

data = load_diabetes()
x = data.data
y = data.target

df = pd.DataFrame(data=np.concatenate((x, np.array([y]).T), axis=1), columns=data.feature_names + ['target'])
print(df)

lr = LinearRegression()
lr.fit(x, y)
print(lr.coef_)
print(lr.intercept_)
print(f'{lr.intercept_} + ' + ' + '.join(
    [
        f'({lr.coef_[i]}) * x{i + 1}' 
        for i in range(len(lr.coef_))
    ]))

circom_weights = [trunc(lr.intercept_ * 10 ** 16)] + [trunc(x * 10 ** 8) for x in lr.coef_]
print("Circom weights:", circom_weights)

# shape returns number of rows and columns
circom_inputs = [trunc(x[0][i] * (10 ** 8)) for i in range(x.shape[1])]
print("Circom inputs:", circom_inputs)

print("Circom output:", lr.predict([x[0]]))

# Number normalization
min_x = x.min()
max_x = x.max()

norm_numbers = [trunc(x) for x in (x[0] - min_x) * 10 / (max_x - min_x)];
print("Scaled numbers:", norm_numbers)

standard_scaler = x - x.mean() / x.std()
plt.hist(standard_scaler)
plt.show()