"""
Saves definition of an unconstrained optimization problem.
"""
struct UnconstrainedProblem{S <: Real} <: AbstractOptimizationProblem
    # Objective f
    f::Function
    dimension::Int
    domain_eltype::Type
    range_type::Type
    # either -1 or 1, for maximization +1, for min. -1
    sense::Sense
    # box constraints: lowerbounds, upperbounds
    lb::Vector{S}
    ub::Vector{S}
    max_evaluations::Int
    # max_duration::Int
    # TODO: verbose levels, now Bool
    verbose::Bool
end
