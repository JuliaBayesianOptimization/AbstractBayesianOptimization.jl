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
export get_hist, get_solution, get_dimension, get_domain_eltype, get_range_type,
    get_evaluation_counter, get_max_evaluations

include("OptimizationHelper.jl")

# utilities
export from_unit_cube, to_unit_cube
include("utils.jl")

end # module
