mutable struct OptimizationStats{U <: Real, V <: Real}
    const no_history::Bool
    # evaluations in the normalized domain in [0,1]^dim
    # TODO: maybe let DSM decide if it normalizes or not (OptimizationStats should not depend on it)
    const hist_xs::Vector{Vector{U}}
    const hist_ys::Vector{V}
    const observed_maximizer::Vector{U}
    # in case of no evaluations, set observed_maximum to -Inf
    observed_maximum::V
    # in seconds since the epoch, set by calling time() in constructor of OptimizationHelper
    start_time::Float64
    evaluation_counter::Int
end
