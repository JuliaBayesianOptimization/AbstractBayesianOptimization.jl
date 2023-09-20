"""
Provides an interface and helper utilities for implementing Bayesian optimization algrithms.
"""
module AbstractBayesianOptimization

using Printf

# abstract types and interface
export AbstractDecisionSupportModel,
    AbstractPolicy, initialize!, update!, next_batch!, is_done
# main optimization loop
export optimize!
include("BayesianOptimizationBase.jl")

# helpers for problem definition & optimization logging
export OptimizationHelper, evaluate_objective!, get_hist, get_solution, Min, Max
include("OptimizationHelper.jl")

# utilities
export from_unit_cube, to_unit_cube
include("utils.jl")

end # module
