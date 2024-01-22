# WORK-IN-PROGRESS


# Ask-tell interface motivation:

# For interactive use and increased generality, adopt ask-tell interface.
# - easier human-in-the loop interactive use in REPL & inspection of surrogate while optimizing
# - handles initialization of a surrogate the same as later optimization (clearer for TuRBO
# that sometimes needs to reinitialize a local surrogate)
#    - easier integration into downstream tasks
# - multifidelity BO can be easily incorporated into the ask-tell interface
#     - request containts points for evaluation and a fidelity level
# - more natural formulation of a black box optimization; a clear split between problem definition
# and optimization algorithm, evaluation of the objective / constraints / simulations needs to be
# explicitely requested by the algorithm -> transparency in high cost objective functions

"""
An AbstractBOAlgorithm covers every aspect of the solver other than the optimizatio problem
definition & evaluation (objective, constraints, simulations in multifidelity BO). This
captures the "black box" optimization idea.

Traditional BO mehods can be formulated in terms of
- policy
    - e.g. maximizing acquisition function
- decision support model (DSM)
    - e.g. taking care of a GP surrogate and performing hyperparameter optimization
- stats
    - e.g. access to last evaluated point or best observed optimizer (can be used by policy),
        number of evaluations (can be used by DSM to stop optimization when the eval. budget exhausted), etc.


Policy and DSM are abstracted in AbstractPolicy and AbstractDecisionSupportModel interfaces.
"""
abstract type AbstractBOAlgorithm end

"""
Tradional BO algorithm structure.

Needs to support:

ask(BO_alg::BasicBO) = ... # e.g. policy can propose point(s) (arg max. aquisition fun)
tell!(BBO_alg::BasicBO, xs, ys) = .. # update DSM by adding eval. ys at points xs
"""
struct BasicBO{P <: AbstractPolicy, M <: AbstractDecisionSupportModel} <: AbstractBOAlgorithm
    policy::P
    dsm::M
    stats::OptimizationStats
end
isdone(BO_alg::BasicBO) = isdone(BO_alg.policy) || isdone(BO_alg.dsm)


# todo: reuse optimization problem defitions from SciML instead AbstractOptimizationProblem
function optimize!(BO_alg::AbstractBOAlgorithm, opt_problem::AbstractOptimizationProblem)
    while !isdone(BO_alg::AbstractBOAlgorithm)
        request = ask(BO_alg)
        answer = process_request(opt_problem, request)
        tell!(BO_alg, request, answer)
    end
end

"""
ask(BO_alg::AbstractBOAlgorithm)

Evaluating problem definition happens "outside" of BO_alg, BO_alg can request
to evaluate something by returning it from ask(..).

For instance for initialization, it might produce a large array of xs that it need to evaluate
the objective on. (Or in TuRBO initializing a trust region may produce a request).

Examples
- ask to evaluate objective function at some points
- ask to evaluate a simulation (multifidelity BO) at some points
- ask to evaluate constraints at some points
"""
function ask end

"""
tell!(BO_alg, request, answer)

Update decision support model.
"""
function tell! end

# is it type piracy from Base?
"""
    isdone(BO_alg::AbstractBOAlgorithm) -> Bool

Enforce stopping the optimization loop.

# Example

Evaluation budged is compared to numer of evaluated points in BasicBO.stats counter.
"""
function isdone end

# TODO: mark as not required but optional
"""
    evaluation_budget(stats::OptimizationStats) -> Int

Return the number of times we can evaluate the objective.
"""
function evaluation_budget end

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


# idea from https://github.com/jbrea/BayesianOptimization.jl
@enum Sense Min=-1 Max=1


# """
# An abstract type generelizing types for providing helper functions for optimization.
# """
# abstract type AbstractOptimizationHelper end

# """
#     initialize!(dsm::AbstractDecisionSupportModel, oh::OptimizationHelper)

# Perform initial sampling, evaluate f on them and process evaluations in
# a decision support model.
# """
# function initialize! end

# """
#     update!(dsm::AbstractDecisionSupportModel, oh::OptimizationHelper, xs, ys)

# Process evaluations `ys` at points `xs`, i.e., aggregate new data into a decision model.
# """
# function update! end

# """
#     next_batch!(policy::AbstractPolicy, dsm::AbstractDecisionSupportModel, oh::OptimizationHelper)

# Get the next batch of points for evaluation, applying policy may change internal state of `policy`.
# """
# function next_batch! end

# TODO: should this be Base.isdone? Or is that type-piracy?
# """
#     isdone(dsm::AbstractDecisionSupportModel) -> Bool
#     isdone(dsm::AbstractOptimizationHelper) -> Bool

# A method that allows decision support model or optimization helper to stop optimization loop
# deliberately.
# """
# function isdone end

# """
#     evaluation_budget(oh::OptimizationHelper) -> Int

# Return the number of times we can evaluate the objective.
# """
# function evaluation_budget end


# function run_optimization(dsm::AbstractDecisionSupportModel,
#     oh::AbstractOptimizationHelper,
#     verbose)
#     if isdone(dsm)
#         verbose && @info "Decision support model stopped optimization loop."
#         return false
#     elseif isdone(oh)
#         verbose && @info "Optimization helper stopped optimization loop."
#         return false
#     else
#         return true
#     end
# end

# """
#     optimize!(dsm::AbstractDecisionSupportModel, policy::AbstractPolicy, oh::AbstractOptimizationHelper; verbose=true)

# Run the optimization loop.
# """
# function optimize!(dsm::AbstractDecisionSupportModel, policy::AbstractPolicy,
#     oh::AbstractOptimizationHelper; verbose = true)
#     while run_optimization(dsm, oh, verbose)
#         # apply policy to get a new batch
#         xs = next_batch!(policy, dsm, oh)
#         # check if there is budget before evaluating the objective
#         if evaluation_budget(oh) < length(xs)
#             verbose &&
#                 @info "No evaluation budget left for the next batch. Optimization stopped."
#             break
#         end
#         ys = evaluate_objective!(oh, xs)
#         # trigger update of the decision support model, this may further evaluate f
#         update!(dsm, oh, xs, ys)
#     end
#     return nothing
# end
