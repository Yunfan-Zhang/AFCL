# Asynchronous Federated Clustering with Unknown Number of Clusters

This file is our implementation of  "Asynchronous Federated Clustering with Unknown Number of Clusters."

## How to Run AFCL

Just run "AFCL_main.m", then the experimental results will be displayed automatically. 

```
cen_xx = readmatrix('./public_data/xxx.csv');
```
xxx: select the dataset you want to run

For detailed settings about the parameters, initialization, etc., please refer to the Proposed Method and the Appendix.


## File description

All the folders and files for implementing the proposed AFCL algorithm are introduced below:
- public_data: A folder contains public/benchmark data sets used in the corresponding paper.
   - AFCL_main.m: A script to cluster different data sets in the Datasets folder using the proposed method.
   - AFCL_client.m: A function implements the client-side update accumulation. 
   - AFCL_server.m: A function for implementing the interaction of the server-side seed.
   - AFCL.m: A function to implement server-side aggregation when receiving client's update information.
   - generate_clients.m: A function that implements a uniform selection of participating clients. (we don't use this function in our experiments)
   - kmeans_plusplus_init.m: A function for implementing the initialization seeds in clients and the server.

## Experimental environment
Mac Sonoma 14.5 operating systems, MATLAB R2021b compilation environment, Apple M1 processor, and 8-GB installation memory.

## Citation

```
@inproceedings{
AFCL,
title={Asynchronous Federated Clustering with Unknown Number of Clusters},
author={Yunfan Zhang, Yiqun Zhang, Yang Lu, Mengke Li, Xi Chen, Yiu-ming Cheung},
booktitle={In Proceedings of the AAAI Conference on Artificial Intelligence},
year={2025}
}
```
