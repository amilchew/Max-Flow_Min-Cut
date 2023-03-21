# Max-Flow Min-Cut Theorem in Lean

## Introduction:

This project strives to contribute to and is dependent on [mathlib](https://github.com/leanprover-community/mathlib/edit/max_flow_min_cut/README.md), the library of the Lean theorem prover. 
The purpose of the [file](https://github.com/amilchew/Max-Flow_Min-Cut/blob/master/src/max_flow_min_cut.lean) is to implement the Max-Flow Min-Cut theorem, stating that if a maximum flow exists in a flow network, then its value is equal to the capacity of the minimum cut in the same network. 
Introduction to the field and formal proof of the theorem can be found in [this file](https://github.com/amilchew/Max-Flow_Min-Cut/blob/master/Max-Flow-Min-Cut-Proof.pdf).

## References:

- The code is based on the [first try to prove the theorem](https://github.com/Zetagon/maxflow-mincut/blob/master/src/maxflowmincut.lean) by Leo Okawa Ericson and Viggo Laakshoharju.
- The proof is based on the [Combinatorial Optimisation] (https://onlinelibrary.wiley.com/doi/book/10.1002/9781118033142) book by William J. Cook, William H. Cunningham, William R. Pulleyblank, Alexander Schrijver. 

## Maintainers:

* Aleksandar Ivaylov Milchev
