# TODO: reuse optimization problem defitions from SciML instead AbstractOptimizationProblem

# idea from https://github.com/jbrea/BayesianOptimization.jl
@enum Sense Min=-1 Max=1

"""
An abstract type generelizing different optimization problems, e.g., constrained, unconstrained
problems.
"""
abstract type AbstractOptimizationProblem end

"""
Definition of a box constrained optimization problem.
"""
struct BoxConstrainedProblem{S <: Real, T <: Real} <: AbstractOptimizationProblem
    # Objective f
    f::Function
    # dimension::Int  # can be inferred from lower, upper bound?
    # domain_eltype::Type
    # range_type::Type
    # either -1 or 1, for maximization +1, for min. -1
    sense::Sense
    # box constraints: lowerbounds, upperbounds
    lb::Vector{S}
    ub::Vector{S}
    # TODO: max_evaluations and max total duration, maybe put into a DSM instead (next to check of eval budget)
    # it is not an information for problem eval. but instead more of a config for DSM
    # max_evaluations::Int
    # in seconds,
    # max_duration::T
    # TODO: verbose levels, now Bool
    # verbose::Bool
end

function process_task(opt_problem::BoxConstrainedProblem,  _::GetBoxConstraints)
    opt_problem.lb, opt_problem.ub
end

function process_task(opt_problem::BoxConstrainedProblem,  _::GetSense)
    opt_problem.sense
end

# the only place where f is ever evaluated -> transparency for expensive objective fun.
function process_task(opt_problem::BoxConstrainedProblem,  task::EvalObjective)
    (opt_problem.f).(task.xs)
end
