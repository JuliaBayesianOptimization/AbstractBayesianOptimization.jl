"""
Provides an interface and helper utilities for implementing Bayesian optimization algrithms.
"""
module AbstractBayesianOptimization

using Printf

export
# abstract types and interface
      AbstractDecisionSupportModel, AbstractPolicy,
      initialize!, update!,
# main optimization loop
      optimize!,
# helpers for problem definition & optimization statistics
      OptimizationHelper, evaluate_objective!, get_hist, get_solution, Min, Max,
# utilities
      from_unit_cube, to_unit_cube

"""
Maintain a state of the decision support model (e.g. trust regions, local surrogates and
corresponding AbstractHyperparameterHandler instances for maintaining their hyperparameters
in TuRBO).

An instance of AbstractDecisionSupportModel is used by the policy to decide where to sample
next.
"""
abstract type AbstractDecisionSupportModel end

"""
Decide where we evaluate the objective function next based on information aggregated
in a decision support model.

In particular, take care of details regarding acquisition functions & solvers for them.
An instance of AbstractPolicy may set the flag `isdone` in a decision support model to true
(when the cost of acquiring a new point outweights the information gain).
"""
abstract type AbstractPolicy end

"""
An abstract type generelizing different optimization problems, e.g., constrained, unconstrained
problems.
"""
abstract type AbstractOptimizationProblem end

"""
    initialize!(dsm::AbstractDecisionSupportModel, oh::OptimizationHelper)

Perform initial sampling, evaluate f on them and process evaluations in
a decision support model.
"""
function initialize! end

"""
    update!(dsm::AbstractDecisionSupportModel, oh::OptimizationHelper, xs, ys)

Process evaluations `ys` at points `xs`, i.e., aggregate new data into a decision model.
"""
function update! end

"""
    apply_policy(policy::AbstractPolicy, dsm::AbstractDecisionSupportModel, oh::OptimizationHelper)

Get the next batch of points for evaluation.
"""
function apply_policy end

# idea from BaysianOptimization.jl
@enum Sense Min=-1 Max=1

include("OptimizationHelper/OptimizationHelper.jl")
include("utils.jl")

"""
    optimize!(dsm::AbstractDecisionSupportModel, policy::AbstractPolicy, oh::OptimizationHelper)

Run the optimization loop.
"""
function optimize!(dsm::AbstractDecisionSupportModel, policy::AbstractPolicy,
                   oh::OptimizationHelper)
    # TODO: add `&& oh.stats.total_duration <= oh.problem.max_duration` once implemented in oh
    while !dsm.state.isdone && oh.stats.evaluation_counter <= oh.problem.max_evaluations
        # apply policy to get a new batch
        xs = apply_policy(policy, dsm, oh)
        ys = evaluate_objective!(oh, xs)
        # trigger update of the decision support model, this may further evaluate f
        update!(dsm, oh, xs, ys)
    end
end

end # module
