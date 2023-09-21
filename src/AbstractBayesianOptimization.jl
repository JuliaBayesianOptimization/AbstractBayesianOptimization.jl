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

# helpers for problem definition & logging
export Min, Max
export OptimizationHelper, evaluate_objective!
export history, solution, dimension, domain_eltype, range_type,
    evaluation_counter, max_evaluations, evaluation_budget

include("OptimizationHelper.jl")

# utilities
export from_unit_cube, to_unit_cube
include("utils.jl")

end # module
