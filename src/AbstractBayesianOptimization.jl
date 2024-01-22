"""
Provides an interface and helper utilities for implementing Bayesian optimization algrithms.
"""
module AbstractBayesianOptimization


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
#   - transparent logging of what has been requested / evaluated

"""
An AbstractBOAlgorithm covers every aspect of the solver other than the optimizatio problem
definition & evaluation (objective, constraints, simulations in multifidelity BO). This
captures the "black box" optimization idea.
"""
abstract type AbstractBOAlgorithm end


"""
ask(BO_alg::AbstractBOAlgorithm)

Evaluating problem definition happens "outside" of BO_alg, BO_alg can request
to evaluate something by returning it from ask(..).

For instance for initialization, it might produce a large array of xs that it need to evaluate
the objective on. (Or in TuRBO initializing a trust region may produce a request). Or it may
als for box constraints at the beginning for setting up normalization to unit cube.

TODO: create a small protocol for what can a BO_alg request

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
Tradional BO algorithm structure.

Needs to support:

ask(BO_alg::BasicBO) = ... # e.g. policy can propose point(s) (arg max. aquisition fun)
tell!(BBO_alg::BasicBO, xs, ys) = .. # update DSM by adding eval. ys at points xs


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
struct BasicBO{P <: AbstractPolicy, M <: AbstractDecisionSupportModel} <: AbstractBOAlgorithm
    # presumably also need config?
    dsm::M
    policy::P
    domain_normalizer::DomainNormalizer
    sense_normalizer::SenseNormalizer
    stats::OptimizationStats
end

isdone(BO_alg::BasicBO) = isdone(BO_alg.policy) || isdone(BO_alg.dsm)


function optimize!(BO_alg::AbstractBOAlgorithm, opt_problem::AbstractOptimizationProblem)
    while !isdone(BO_alg::AbstractBOAlgorithm)
        # TODO maybe more tasks per iteration?
        task, callback = ask(BO_alg)
        log_task(task)
         # e.g. eval objective and update surrogate by passing update!(..) into callback
        callback(process_task(opt_problem, task))
    end
end














# using Printf

# # abstract types and interface
# export AbstractDecisionSupportModel,
#     AbstractPolicy, initialize!, update!, next_batch!, isdone
# # main optimization loop
# export optimize!
# include("BayesianOptimizationBase.jl")

# # helpers for problem definition & logging
# export Min, Max
# export OptimizationHelper, evaluate_objective!
# export history, solution, dimension, domain_eltype, range_type,
#     evaluation_counter, max_evaluations, evaluation_budget,
#     norm_observed_maximum, norm_last_x

# include("OptimizationHelper.jl")

# # utilities
# export from_unit_cube, to_unit_cube
# include("utils.jl")

end # module
