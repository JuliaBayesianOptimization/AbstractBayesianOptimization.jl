"""
Saves optimization statistics.
"""
mutable struct OptimizationStats{U <: Real, V <: Real}
    evaluation_counter::Int
    # TODO: duration; for now, don't measure time
    # total_duration::Any
    const no_history::Bool
    # evaluations in the normalized domain in [0,1]^dim
    hist_xs::Vector{Vector{U}}
    hist_ys::Vector{V}
    observed_maximizer::Vector{U}
    # if we don't have any evaluations, we set observed_maximum to -Inf
    observed_maximum::V
end
