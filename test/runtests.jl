using AbstractBayesianOptimization
using Test

@testset "utils: to_unit_cube, from_unit_cube" begin
    @test_throws ArgumentError to_unit_cube([1, 1], [-1, -1], [-3, 3])
    @test isapprox(to_unit_cube([1, 1], [-1, -1], [3, 3]), [0.5, 0.5])
    @test isapprox(to_unit_cube([1, 1], [-3, -3], [1, 1]), [1, 1])

    @test_throws ArgumentError from_unit_cube([1, 1], [-1, -1], [-3, 3])
    @test isapprox(from_unit_cube([1, 1], [-1, -1], [3, 3]), [3, 3])
    @test isapprox(from_unit_cube([0.5, 0.5], [-3, 0], [1, 1]), [-1, 0.5])
    # test for bijection
    for (lb, ub) in [
        ([-3.4, 5.6], [-1.0, 7.8]),
        ([67.4, -1.4], [70.3, 0.0]),
        ([-30.0, -48.0], [50.0, 90]),
    ]
        for x in 0:0.1:1, y in 0:0.03:1
            @test isapprox(to_unit_cube(from_unit_cube([x, y], lb, ub), lb, ub), [x, y])
            @test isapprox(from_unit_cube(to_unit_cube([x, y], lb, ub), lb, ub), [x, y])
        end
    end
end

@testset "OptimizationHelper: Preprocessing" begin
    oh = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, 1.0],
        [1.0, 1.5],
        50,
        verbose = false)
    #  test Preprocessing, turn min. problem into a maximization problem
    @test isapprox(oh.problem.f(to_unit_cube([1.0, 1.0], oh.problem.lb, oh.problem.ub)), -2)
end

@testset "OptimizationHelper: evaluate_objective!" begin
    oh1 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, 1.0],
        [1.0, 1.5],
        50,
        verbose = false)

    # [5., 0.] ⊄ [0,1]^dimension
    @test_throws ArgumentError evaluate_objective!(oh1, [[5.0, 0.0]])
    # [1.3, 1.2] is not between lb= [-1., 1.], ub = [1.,1.5]
    @test_throws ArgumentError evaluate_objective!(oh1,
        [to_unit_cube([1.3, 1.2], oh1.problem.lb, oh1.problem.ub)])
    @test isapprox(evaluate_objective!(oh1,
            [to_unit_cube([-0.5, 1.2], oh1.problem.lb, oh1.problem.ub),
                to_unit_cube([0.1, 1.1], oh1.problem.lb, oh1.problem.ub),
            ]), [-0.7, -1.2])
end

@testset "OptimizationHelper: infer dimension and type of elements in the domain" begin
    oh1 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, 1.0],
        [1.0, 1.5],
        50,
        verbose = false)
    oh2 = OptimizationHelper(x -> x[1] + x[2] + x[3],
        Min,
        [-1.0f0, 1.0f0, 3.5f0],
        [1.0f0, 1.4f0, 4.0f0],
        50,
        verbose = false)

    @test oh1.problem.domain_eltype == Float64
    @test oh1.problem.dimension == 2

    @test oh2.problem.domain_eltype == Float32
    @test oh2.problem.dimension == 3
    # by default we passed Float64 as range type but it is Float32
    @test_throws ErrorException evaluate_objective!(oh2, [[1.0f0, 1.0f0, 0.0f0]])
end

@testset "OptimizationHelper: update of best optimizer" begin
    # bounds match unit cube, optimizer = [1., 1.], optimum = 2.
    oh3 = OptimizationHelper(x -> x[1] + x[2],
        Max,
        [0.0, 0.0],
        [1.0, 1.0],
        50,
        verbose = false)
    # init to -Inf
    @test isinf(solution(oh3)[2])
    evaluate_objective!(oh3, [[0.1, 0.9]])
    evaluate_objective!(oh3, [[0.5, 0.5], [0.1, 0.3], [0.5, 0.6], [0.5, 0.6]])
    evaluate_objective!(oh3, [[0.8, 0.1]])
    optimizer, optimum = solution(oh3)
    @test isapprox(optimizer, [0.5, 0.6])
    @test isapprox(optimum, 1.1)

    # bounds match unit cube, optimizer = [0., 0.], optimum = 0.
    oh4 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [0.0, 0.0],
        [1.0, 1.0],
        50,
        verbose = false)
    evaluate_objective!(oh4, [[0.1, 0.9]])
    evaluate_objective!(oh4, [[0.1, 0.9], [0.1, 0.3]])
    evaluate_objective!(oh4, [[0.5, 0.5], [0.5, 0.6], [0.5, 0.6]])
    evaluate_objective!(oh4, [[0.8, 0.1]])
    optimizer, optimum = solution(oh4)
    @test isapprox(optimizer, [0.1, 0.3])
    @test isapprox(optimum, 0.4)
end

@testset "OptimizationHelper: history" begin
    # no_history = true
    oh5 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [0.0, 0.0],
        [1.0, 1.0],
        50,
        no_history = true,
        verbose = false)
    @test_throws ErrorException history(oh5)

    oh6 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, -1.0],
        [1.0, 1.0],
        50,
        verbose = false)
    evaluate_objective!(oh6, [[0.0, 0.0], [1.0, 1.0]])
    xs, ys = history(oh6)
    @test xs == [[-1.0, -1.0], [1.0, 1.0]]
    @test ys == [-2.0, 2.0]
end

@testset "OptimizationHelper: solution" begin
    oh7 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, -1.0],
        [1.0, 1.0],
        50,
        verbose = false)
    optimizer, optimum = solution(oh7)
    @test isinf(optimum)
    evaluate_objective!(oh7, [[0.5, 0.0], [1.0, 1.0]])
    evaluate_objective!(oh7, [[0.1, 0.2]])
    optimizer, optimum = solution(oh7)
    @test isapprox(optimizer, [-0.8, -0.6])
    @test isapprox(optimum, -1.4)
end

@testset "OptimizationHelper: update_history!" begin
    # no_history = true
    oh8 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, -1.0],
        [1.0, 1.0],
        50,
        no_history = true,
        verbose = false)
    # update_history! is not exported
    @test_throws UndefVarError update_history!(oh8, [[0.4, 0.4], [0.2, 0.3]], [1.0, 2.0])
    @test_throws ErrorException AbstractBayesianOptimization.update_history!(oh8,
        [[0.4, 0.4], [0.2, 0.3]],
        [1.0, 2.0])
    oh9 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [0.0, 0.0],
        [1.0, 1.0],
        50,
        verbose = false)
    # calls update_hist with xs
    evaluate_objective!(oh9, [[0.5, 0.0], [1.0, 1.0]])
    @test length(oh9.stats.hist_xs) == 2
    @test length(oh9.stats.hist_ys) == 2
    # eval the same points
    evaluate_objective!(oh9, [[0.5, 0.0], [1.0, 1.0]])
    @test length(oh9.stats.hist_xs) == 4
    @test length(oh9.stats.hist_ys) == 4
end

@testset "OptimizationHelper: getters" begin
    oh10 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, 1.0],
        [1.0, 1.5],
        50,
        verbose = false)
    @test dimension(oh10) == 2
    @test domain_eltype(oh10) == Float64
    @test range_type(oh10) == Float64
    @test evaluation_counter(oh10) == 0
    @test max_evaluations(oh10) == 50
end

@testset "OptimizationHelper: isdone, evaluation_budget" begin
    oh11 = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [0.0, 0.0],
        [1.0, 1.0],
        2,
        verbose = false)
    @test !isdone(oh11; verbose = false)
    evaluate_objective!(oh11, [[0.1, 0.9]])
    @test evaluation_budget(oh11) == 1
    @test !isdone(oh11; verbose = false)
    evaluate_objective!(oh11, [[0.2, 0.9]])
    # now we are done
    @test evaluation_budget(oh11) == 0
    @test isdone(oh11; verbose = false)
    evaluate_objective!(oh11, [[0.1, 0.9], [0.1, 0.3]])
    @test isdone(oh11; verbose = false)
end
