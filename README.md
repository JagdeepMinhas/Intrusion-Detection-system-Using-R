# Intrusion-Detection-system-Using-R

# Electric Energy Consumption Anomaly Detection Project

![Project Banner](project_banner_image.jpg) <!-- Replace with an image relevant to your project -->

This repository contains the code and documentation for an electric energy consumption anomaly detection project. The project utilizes Principal Component Analysis (PCA) and Hidden Markov Models (HMM) for detecting anomalies in electric energy consumption datasets.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Methods](#methods)
- [Getting Started](#getting-started)
- [Results](#results)



## Introduction

The goal of this project is to identify anomalies in electric energy consumption datasets using a combination of PCA and Hidden Markov Models. PCA is used to reduce the dimensionality of the dataset while retaining critical components and relationships, and HMM is used to model the temporal behavior of the data and detect anomalies by comparing log-likelihood values.

## Features

- Anomaly detection in electric energy consumption datasets.
- Dimensionality reduction using Principal Component Analysis (PCA).
- Hidden Markov Models (HMM) for modeling temporal behavior.
- Automatic determination of the optimal number of states in HMM.
- Log-likelihood comparison for anomaly detection.

## Methods

1. **Data Preprocessing:** Clean and preprocess the electric energy consumption dataset, handling missing values and outliers.

2. **Principal Component Analysis (PCA):** Apply PCA to the preprocessed data to identify critical components and reduce dimensionality.

3. **Hidden Markov Models (HMM):** Train HMM on the PCA-transformed data to model temporal behavior.

4. **Optimal State Selection:** Use methods such as Bayesian Information Criterion (BIC) or Cross-Validation to determine the optimal number of states for HMM.

5. **Anomaly Detection:** Detect anomalies by comparing log-likelihood values obtained from the trained HMM.

Calculated Log-Likelihood of Normal Dataset:
The log-likelihood of the normal dataset with no anomalies was calculated.

Filtered and Scaled Monday's Data:
The data for Mondays between 6:00:00 and 10:00:00 was filtered, missing values were removed, and the "Global_active_power" and "Global_intensity" columns were scaled.

Created a 16-State Model for Normal Dataset:
A 16-state model was created for the filtered and scaled normal dataset.

Stored Loglik and BIC Values for Normal Dataset:
The Loglik and BIC values of the normal dataset were stored in vectors for later comparison.

Filtered and Scaled Anomaly Datasets:
The anomaly datasets (df_anomaly1, df_anomaly2, and df_anomaly3) were filtered and scaled, and models with 16 states were created for each.

Appended Loglik and BIC Values of Anomaly Models:
The Loglik and BIC values of the anomaly models were appended to the vectors for comparison with the normal dataset.

Stored Log-Likelihood and BIC Values in a Table:
The Log-likelihood and BIC values of both the normal and anomaly datasets were stored in a table....
```

2. Apply PCA:

```python
from sklearn.decomposition import PCA

# Apply PCA for dimensionality reduction
pca = PCA(n_components=3)
pca_data = pca.fit_transform(preprocessed_data)
...
```

3. Train Hidden Markov Model:

```python
from hmmlearn.hmm import GaussianHMM

# Train HMM on PCA-transformed data
hmm_model = GaussianHMM(n_components=4, covariance_type="full")
hmm_model.fit(pca_data)
...
```

4. Detect Anomalies:

```python
# Detect anomalies using log-likelihood comparison
log_likelihoods = hmm_model.score_samples(pca_data)
# Anomaly detection logic
...
```

## Results

After comparing the Loglik values of the original dataset and the anomalies, a significant difference is observed between the values. The Loglik value for the original data is 2137.165, while the Loglik values for the anomalies are much lower. Anomaly 2 has the lowest Loglik value, which makes it the most anomalous. The difference in Loglik values between the original dataset and anomaly 2 is the largest, indicating a significant deviation from the normal behavior.



