include("OptimizationProblems/UnconstrainedProblem.jl")
include("OptimizationStats.jl")

"""
Saves optimization problem and maintains progress.

Internally, it transforms the domain into a unit cube and makes it a maximization problem.
"""
struct OptimizationHelper{T <: AbstractOptimizationProblem}
    problem::T
    stats::OptimizationStats
end

# TODO: make lb, ub AbstractVector??
"""
    OptimizationHelper(g, sense::Sense, lb::Vector{D}, ub::Vector{D}, max_evaluations; range_type = Float64, no_history = false) where D

Return an optimization helper, infer type of elements in the domain and dimension of
the domain from lower (upper) bound.

Argument `sense` can be either `Max` or `Min`.
"""
function OptimizationHelper(g, sense::Sense, lb::Vector{U}, ub::Vector{U}, max_evaluations; range_type = Float64, no_history = false) where U
    max_evaluations <= 0 && throw(ArgumentError("max_evaluations <= 0"))
    all(lb .<= ub) || throw(ArgumentError("lowerbounds are not componentwise less or equal to upperbounds"))
    length(lb) == length(ub) ||
        throw(ArgumentError("lowerbounds, upperbounds have different lengths"))
    # Preprocessing: rescale domain to [0,1]^dim, make it a maximization problem
    f(x) = Int(sense) * g(from_unit_cube(x, lb, ub))
    # infer type of domain & dimension from lower (upper) bound,
    problem = UnconstrainedProblem(f, length(lb), U, range_type, sense, lb, ub, max_evaluations)
    init_stats = OptimizationStats(0,
                                    no_history,
                                   Vector{Vector{U}}(),
                                   Vector{range_type}(),
                                   Vector{U}(),
                                   -Inf)
    OptimizationHelper(problem, init_stats)
end

"""
    evaluate_objective!(oh::OptimizationHelper, xs)

Evaluate objective. Log number of function evaluations & total duration.

Update observed optimizer & optimal value.
The (normalized) objective should only be evaluated using this method.
"""
function evaluate_objective!(oh::OptimizationHelper, xs)
    # TODO: increase total duration time in oh
    ys = (oh.problem.f).(xs)
    oh.stats.evaluation_counter += length(xs)
    if eltype(ys) != oh.range_type
        throw(ErrorException("passed range_type does not coincide with actual type of evaluation result"))
    end
    if eltype(xs) != oh.domain_eltype
        throw(ErrorException("infered domain_eltype from lower (upper) bounds does not coincide with actual type of point we evaluate the objective at"))
    end
    oh.stats.no_history || update_hist!(oh, xs, ys)
    argmax_ys = argmax(ys)
    if ys[argmax_ys] > oh.stats.observed_maximum
        oh.stats.observed_maximum = ys[argmax_ys]
        # copy elementwise from xs[argmax_ys] into oh.observed_maximizer (dimensions have to be equal)
        oh.stats.observed_maximizer .= xs[argmax_ys]
        # TODO: printing based on verbose levels
        @info @sprintf "#eval: %4i, new best objective approx. %6.4f" oh.stats.evaluation_counter oh.stats.observed_maximum
    end
    ys
end
"""
    update_hist!(oh::OptimizationHelper, xs, ys)

Add evaluations `ys` at points `xs` into history.
"""
function update_hist!(oh::OptimizationHelper, xs, ys)
    oh.stats.no_history && throw(ErrorException("calling update_hist! with flag no_hist = true"))
    (length(xs) == 0 || length(ys) == 0) && throw(ArgumentError("xs or ys is empty"))
    length(xs) == length(ys) || throw(ArgumentError("xs, ys have different lenghts"))
    append!(oh.stats.hist_xs, xs)
    append!(oh.stats.hist_ys, ys)
end

"""
    get_hist(oh::OptimizationHelper)

Return a tuple with first element equal to an array of evaluated points, the second element
equal to corresponding objective values.
"""
function get_hist(oh::OptimizationHelper)
    oh.stats.no_history && throw(ErrorException("calling get_hist with flag no_hist = true"))
    # rescale from unit cube to lb, ub
    [from_unit_cube(x, oh.problem.lb, oh.problem.ub) for x in oh.stats.hist_xs],
    oh.stats.hist_ys
end


"""
    get_solution(oh::OptimizationHelper)

Return a tuple consiting of an observed optimizer and optimal value.
"""
function get_solution(oh::OptimizationHelper)
    from_unit_cube(oh.stats.observed_maximizer, oh.problem.lb, oh.problem.ub),
    Int(oh.problem.sense) *
    oh.stats.observed_maximum
end