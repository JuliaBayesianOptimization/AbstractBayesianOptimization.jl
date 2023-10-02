# AbstractBayesianOptimization.jl

*This repo contains experimental code at the moment.*

## About

This package formulates a prototypical Bayesian optimization algorithm using abstract building blocks. Currently it supports gradient free optimization only.

It comes with a basic `OptimizationHelper` that provides utilities for unconstrained problem definition and logging.

The purpose of this little framework is to reuse code and to expose Bayesian optimization algorithms via a unified interface.

## Credits

The mathematical framework behind Bayesian optimization algorithms that motivates us to write such a generic Julia code has been described in *Bayesian Optimization Book* by Roman Garnett available at [bayesoptbook.com/](https://bayesoptbook.com/).