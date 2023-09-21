"""
Maintain a state of the decision support model (e.g. trust regions, local surrogates).

An instance of AbstractDecisionSupportModel is used by the policy to decide where to sample
next.
"""
abstract type AbstractDecisionSupportModel end

"""
Decide where we evaluate the objective function next based on information aggregated
in a decision support model.

In particular, take care of details regarding acquisition functions & solvers for them.
"""
abstract type AbstractPolicy end

"""
An abstract type generelizing different optimization problems, e.g., constrained, unconstrained
problems.
"""
abstract type AbstractOptimizationProblem end

"""
An abstract type generelizing types for providing helper functions for optimization.
"""
abstract type AbstractOptimizationHelper end

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
    next_batch!(policy::AbstractPolicy, dsm::AbstractDecisionSupportModel, oh::OptimizationHelper)

Get the next batch of points for evaluation, applying policy may change internal state of `policy`.
"""
function next_batch! end

"""
    isdone(dsm::AbstractDecisionSupportModel; verbose=true) -> Bool
    isdone(dsm::AbstractOptimizationHelper; verbose=true) -> Bool

A method that allows decision support model or optimization helper to stop optimization loop
deliberately.
"""
function isdone end

"""
    evaluation_budget(oh::OptimizationHelper) -> Int

Return the number of times we can evaluate the objective.
"""
function evaluation_budget end

# idea from https://github.com/jbrea/BayesianOptimization.jl
@enum Sense Min=-1 Max=1

"""
    optimize!(dsm::AbstractDecisionSupportModel, policy::AbstractPolicy, oh::AbstractOptimizationHelper; verbose=true)

Run the optimization loop.
"""
function optimize!(dsm::AbstractDecisionSupportModel, policy::AbstractPolicy,
    oh::AbstractOptimizationHelper; verbose = true)
    while true
        if isdone(dsm)
            verbose && @info "Decision support model stopped optimization loop."
            break
        elseif isdone(oh)
            verbose && @info "Optimization helper stopped optimization loop."
            break
        end
        # apply policy to get a new batch
        xs = next_batch!(policy, dsm, oh)
        # check if there is budget before evaluating the objective
        if evaluation_budget(oh) < length(xs)
            verbose &&
                @info "No evaluation budget left for the next batch. Optimization stopped."
            break
        end
        ys = evaluate_objective!(oh, xs)
        # trigger update of the decision support model, this may further evaluate f
        update!(dsm, oh, xs, ys)
    end
    return nothing
end
