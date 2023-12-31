"""
Saves definition of an unconstrained optimization problem.
"""
struct UnconstrainedProblem{S <: Real, T <: Real} <: AbstractOptimizationProblem
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
    # in seconds
    max_duration::T
    # TODO: verbose levels, now Bool
    verbose::Bool
end

"""
Saves optimization statistics.
"""
mutable struct OptimizationStats{U <: Real, V <: Real}
    evaluation_counter::Int
    const no_history::Bool
    # evaluations in the normalized domain in [0,1]^dim
    const hist_xs::Vector{Vector{U}}
    const hist_ys::Vector{V}
    const observed_maximizer::Vector{U}
    # if we don't have any evaluations, we set observed_maximum to -Inf
    observed_maximum::V
    # in seconds since the epoch, set by calling time() in constructor of OptimizationHelper
    start_time::Float64
end

"""
Saves optimization problem and maintains progress.

Internally, the problem is normalized, i.e., the domain is transformed into a unit cube and
the problem becomes a maximization problem.
"""
struct OptimizationHelper{T <: AbstractOptimizationProblem} <: AbstractOptimizationHelper
    problem::T
    stats::OptimizationStats
end

# TODO: make lb, ub AbstractVector??
"""
    OptimizationHelper(g, sense::Sense, lb::Vector{D}, ub::Vector{D}, max_evaluations; max_duration=Inf, range_type = Float64, no_history = false) where D

Return an optimization helper, infer type of elements in the domain and dimension of
the domain from lower (upper) bound.

Argument `sense` can be either `Max` or `Min`, `max_duration` is in seconds.
"""
function OptimizationHelper(g,
    sense::Sense,
    lb::Vector{U},
    ub::Vector{U},
    max_evaluations;
    max_duration = Inf,
    range_type = Float64,
    verbose = true,
    no_history = false) where {U}
    max_evaluations <= 0 && throw(ArgumentError("max_evaluations <= 0"))
    all(lb .<= ub) ||
        throw(ArgumentError("lowerbounds are not componentwise less or equal to upperbounds"))
    length(lb) == length(ub) ||
        throw(ArgumentError("lowerbounds, upperbounds have different lengths"))
    max_evaluations >= 0 || throw(ArgumentError("max_evaluations < 0"))
    max_duration >= 0 || throw(ArgumentError("max_duration < 0"))

    # infer dimension of the domain from lower (upper) bound
    dimension = length(lb)
    # Preprocessing: rescale the domain to [0,1]^dim, make it a maximization problem
    f(x) = Int(sense) * g(from_unit_cube(x, lb, ub))
    # infer type of the domain from lower (upper) bound
    problem = UnconstrainedProblem(f,
        dimension,
        U,
        range_type,
        sense,
        lb,
        ub,
        max_evaluations,
        max_duration,
        verbose)
    init_stats = OptimizationStats(0,
        no_history,
        Vector{Vector{U}}(),
        Vector{range_type}(),
        Vector{U}(undef, dimension),
        -Inf,
        time())
    return OptimizationHelper(problem, init_stats)
end

"""
    evaluate_objective!(oh::OptimizationHelper, xs)

Evaluate objective at (normalized) `xs` ⊂ [0,1]^dimension, return (normalized) `ys`, i.e.,
with the opposite sign if the orginal problem was to minimize.

Log the number of function evaluations & total duration.
Update observed optimizer & optimal value.

The (normalized) objective should only be evaluated using this method.
"""
function evaluate_objective!(oh::OptimizationHelper, xs)
    all(all(0 .<= x .<= 1) for x in xs) ||
        throw(ArgumentError("trying to evaluate at points outside of unit cube"))
    ys = (oh.problem.f).(xs)
    oh.stats.evaluation_counter += length(xs)
    if eltype(ys) != oh.problem.range_type
        throw(ErrorException("passed range_type does not coincide with actual type of evaluation result"))
    end
    if eltype(eltype(xs)) != oh.problem.domain_eltype
        throw(ErrorException("infered domain_eltype from lower (upper) bounds does not coincide with actual type of point we evaluate the objective at"))
    end
    oh.stats.no_history || update_history!(oh, xs, ys)
    argmax_ys = argmax(ys)
    if ys[argmax_ys] > oh.stats.observed_maximum
        oh.stats.observed_maximum = ys[argmax_ys]
        # copy elementwise from xs[argmax_ys] into oh.observed_maximizer
        oh.stats.observed_maximizer .= xs[argmax_ys]
        # TODO: printing based on verbose levels
        oh.problem.verbose &&
            @info @sprintf "#eval: %4i, new best objective approx. %6.4f" oh.stats.evaluation_counter (Int(oh.problem.sense)*oh.stats.observed_maximum)
    end
    return ys
end
"""
    update_history!(oh::OptimizationHelper, xs, ys)

Add (normalized) evaluations `ys` at (normalized) points `xs`⊂ [0,1]^dimension into history.
"""
function update_history!(oh::OptimizationHelper, xs, ys)
    all(all(0 .<= x .<= 1) for x in xs) ||
        throw(ArgumentError("trying to add points outside of unit cube"))
    oh.stats.no_history &&
        throw(ErrorException("calling update_history! with flag no_hist = true"))
    (length(xs) == 0 || length(ys) == 0) && throw(ArgumentError("xs or ys is empty"))
    length(xs) == length(ys) || throw(ArgumentError("xs, ys have different lenghts"))
    append!(oh.stats.hist_xs, xs)
    append!(oh.stats.hist_ys, ys)
    return nothing
end

"""
    history(oh::OptimizationHelper)

Return a tuple with first element equal to an array of evaluated points, the second element
equal to corresponding objective values.
"""
function history(oh::OptimizationHelper)
    oh.stats.no_history &&
        throw(ErrorException("calling history with flag no_hist = true"))
    # rescale from unit cube to lb, ub
    return [from_unit_cube(x, oh.problem.lb, oh.problem.ub) for x in oh.stats.hist_xs],
    Int(oh.problem.sense) .* oh.stats.hist_ys
end

"""
    solution(oh::OptimizationHelper)

Return a tuple consisting of an observed optimizer and optimal value.
"""
function solution(oh::OptimizationHelper)
    return from_unit_cube(oh.stats.observed_maximizer, oh.problem.lb, oh.problem.ub),
    Int(oh.problem.sense) * oh.stats.observed_maximum
end

function isdone(oh::OptimizationHelper)
    if time() - oh.stats.start_time > oh.problem.max_duration
        oh.problem.verbose && @info "Time duration has exeeded maximum duration."
        return true
    elseif evaluation_budget(oh) <= 0
        oh.problem.verbose && @info "Evaluation budget is used up."
        return true
    else
        return false
    end
end

dimension(oh::OptimizationHelper) = oh.problem.dimension
domain_eltype(oh::OptimizationHelper) = oh.problem.domain_eltype
range_type(oh::OptimizationHelper) = oh.problem.range_type
evaluation_counter(oh::OptimizationHelper) = oh.stats.evaluation_counter
max_evaluations(oh::OptimizationHelper) = oh.problem.max_evaluations
function evaluation_budget(oh::OptimizationHelper)
    oh.problem.max_evaluations - oh.stats.evaluation_counter
end
# normalized observed maximum, i.e., of the internal representation of the objective we maximize
norm_observed_maximum(oh::OptimizationHelper) = oh.stats.observed_maximum
# last (normalized) x in [0,1]^dimension that was evaluated
function norm_last_x(oh::OptimizationHelper)
    @assert oh.stats.evaluation_counter > 0
    oh.stats.no_history &&
        throw(ErrorException("no_history flag is set to false, cannot return last x"))
    return oh.stats.hist_xs[end]
end
