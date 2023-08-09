import pandas as pd
from matplotlib import pyplot as plt

from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler

neighbours = pd.read_csv('../input_neighbours.csv', skipinitialspace=True)
x = pd.read_csv('../input_x.csv', skipinitialspace=True)
data = pd.concat([neighbours, x], ignore_index=True)

coordinate_names = data.columns

scaler = MinMaxScaler().fit(data)
neighbours_transformed = pd.DataFrame(scaler.transform(neighbours), columns=coordinate_names)
x_transformed = pd.DataFrame(scaler.transform(x), columns=coordinate_names)

# Perform K-means on neighbours data only
kmeans = KMeans(n_clusters=2, n_init=10)
kmeans.fit(neighbours_transformed)

# Prepare transformed data for prooving k-means
decimal_places = 6

neighbours_transformed['class'] = kmeans.labels_
neighbours_transformed.round(decimal_places).to_csv('neighbours_clustered.csv', index=False)

x_transformed.round(decimal_places).to_csv('x.csv', index=False)

centroids = pd.DataFrame(kmeans.cluster_centers_, columns=['x', 'y', 'z'])
centroids.round(decimal_places).to_csv('neighbours_centroids.csv', index=False)

print("Inertia: ", kmeans.inertia_)
print("Centroids: ", kmeans.cluster_centers_)
print("Num iterations: ", kmeans.n_iter_)
print("Labels: ", kmeans.labels_)
