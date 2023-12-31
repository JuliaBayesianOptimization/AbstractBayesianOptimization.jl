using AbstractBayesianOptimization
using Test

@testset "utils: to_unit_cube, from_unit_cube" begin
    @test_throws ArgumentError to_unit_cube([1, 1], [-1, -1], [-3, 3])
    @test isapprox(to_unit_cube([1, 1], [-1, -1], [3, 3]), [0.5, 0.5])
    @test isapprox(to_unit_cube([1, 1], [-3, -3], [1, 1]), [1, 1])

    @test_throws ArgumentError from_unit_cube([1, 1], [-1, -1], [-3, 3])
    @test isapprox(from_unit_cube([1, 1], [-1, -1], [3, 3]), [3, 3])
    @test isapprox(from_unit_cube([0.5, 0.5], [-3, 0], [1, 1]), [-1, 0.5])
    # test for bijection property
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
    oh = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, 1.0],
        [1.0, 1.5],
        50,
        verbose = false)

    # [5., 0.] ⊄ [0,1]^dimension
    @test_throws ArgumentError evaluate_objective!(oh, [[5.0, 0.0]])
    # [1.3, 1.2] is not between lb= [-1., 1.], ub = [1.,1.5]
    @test_throws ArgumentError evaluate_objective!(oh,
        [to_unit_cube([1.3, 1.2], oh.problem.lb, oh.problem.ub)])
    @test isapprox(evaluate_objective!(oh,
            [to_unit_cube([-0.5, 1.2], oh.problem.lb, oh.problem.ub),
                to_unit_cube([0.1, 1.1], oh.problem.lb, oh.problem.ub),
            ]), [-0.7, -1.2])
end

@testset "OptimizationHelper: infer dimension and type of elements in the domain" begin
    let oh = OptimizationHelper(x -> x[1] + x[2],
            Min,
            [-1.0, 1.0],
            [1.0, 1.5],
            50,
            verbose = false)
        @test oh.problem.domain_eltype == Float64
        @test oh.problem.dimension == 2
    end

    let oh = OptimizationHelper(x -> x[1] + x[2] + x[3],
            Min,
            [-1.0f0, 1.0f0, 3.5f0],
            [1.0f0, 1.4f0, 4.0f0],
            50,
            verbose = false)
        @test oh.problem.domain_eltype == Float32
        @test oh.problem.dimension == 3
        # by default we passed Float64 as range type but it is Float32
        @test_throws ErrorException evaluate_objective!(oh, [[1.0f0, 1.0f0, 0.0f0]])
    end
end

@testset "OptimizationHelper: update of best optimizer" begin
    # bounds match unit cube, optimizer = [1., 1.], optimum = 2.
    let oh = OptimizationHelper(x -> x[1] + x[2],
            Max,
            [0.0, 0.0],
            [1.0, 1.0],
            50,
            verbose = false)
        # init to -Inf
        @test isinf(solution(oh)[2])
        evaluate_objective!(oh, [[0.1, 0.9]])
        evaluate_objective!(oh, [[0.5, 0.5], [0.1, 0.3], [0.5, 0.6], [0.5, 0.6]])
        evaluate_objective!(oh, [[0.8, 0.1]])
        optimizer, optimum = solution(oh)
        @test isapprox(optimizer, [0.5, 0.6])
        @test isapprox(optimum, 1.1)
    end

    # bounds match unit cube, optimizer = [0., 0.], optimum = 0.
    let oh = OptimizationHelper(x -> x[1] + x[2],
            Min,
            [0.0, 0.0],
            [1.0, 1.0],
            50,
            verbose = false)
        evaluate_objective!(oh, [[0.1, 0.9]])
        evaluate_objective!(oh, [[0.1, 0.9], [0.1, 0.3]])
        evaluate_objective!(oh, [[0.5, 0.5], [0.5, 0.6], [0.5, 0.6]])
        evaluate_objective!(oh, [[0.8, 0.1]])
        optimizer, optimum = solution(oh)
        @test isapprox(optimizer, [0.1, 0.3])
        @test isapprox(optimum, 0.4)
    end
end

@testset "OptimizationHelper: history" begin
    # no_history = true
    let oh = OptimizationHelper(x -> x[1] + x[2],
            Min,
            [0.0, 0.0],
            [1.0, 1.0],
            50,
            no_history = true,
            verbose = false)
        @test_throws ErrorException history(oh)
    end

    let oh = OptimizationHelper(x -> x[1] + x[2],
            Min,
            [-1.0, -1.0],
            [1.0, 1.0],
            50,
            verbose = false)
        evaluate_objective!(oh, [[0.0, 0.0], [1.0, 1.0]])
        xs, ys = history(oh)
        @test xs == [[-1.0, -1.0], [1.0, 1.0]]
        @test ys == [-2.0, 2.0]
    end
end

@testset "OptimizationHelper: solution" begin
    oh = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, -1.0],
        [1.0, 1.0],
        50,
        verbose = false)
    optimizer, optimum = solution(oh)
    @test isinf(optimum)
    evaluate_objective!(oh, [[0.5, 0.0], [1.0, 1.0]])
    evaluate_objective!(oh, [[0.1, 0.2]])
    optimizer, optimum = solution(oh)
    @test isapprox(optimizer, [-0.8, -0.6])
    @test isapprox(optimum, -1.4)
end

@testset "OptimizationHelper: update_history!" begin
    # no_history = true
    let oh = OptimizationHelper(x -> x[1] + x[2],
            Min,
            [-1.0, -1.0],
            [1.0, 1.0],
            50,
            no_history = true,
            verbose = false)
        # update_history! is not exported
        @test_throws UndefVarError update_history!(oh, [[0.4, 0.4], [0.2, 0.3]], [1.0, 2.0])
        @test_throws ErrorException AbstractBayesianOptimization.update_history!(oh,
            [[0.4, 0.4], [0.2, 0.3]],
            [1.0, 2.0])
    end

    let oh = OptimizationHelper(x -> x[1] + x[2],
            Min,
            [0.0, 0.0],
            [1.0, 1.0],
            50,
            verbose = false)
        # calls update_hist with xs
        evaluate_objective!(oh, [[0.5, 0.0], [1.0, 1.0]])
        @test length(oh.stats.hist_xs) == 2
        @test length(oh.stats.hist_ys) == 2
        # eval the same points
        evaluate_objective!(oh, [[0.5, 0.0], [1.0, 1.0]])
        @test length(oh.stats.hist_xs) == 4
        @test length(oh.stats.hist_ys) == 4
    end
end

@testset "OptimizationHelper: getters" begin
    oh = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [-1.0, 1.0],
        [1.0, 1.5],
        50,
        verbose = false)
    @test dimension(oh) == 2
    @test domain_eltype(oh) == Float64
    @test range_type(oh) == Float64
    @test evaluation_counter(oh) == 0
    @test max_evaluations(oh) == 50
end

@testset "OptimizationHelper: evaluation_budget" begin
    oh = OptimizationHelper(x -> x[1] + x[2],
        Min,
        [0.0, 0.0],
        [1.0, 1.0],
        2,
        verbose = false)
    evaluate_objective!(oh, [[0.1, 0.9]])
    @test evaluation_budget(oh) == 1
    evaluate_objective!(oh, [[0.2, 0.9]])
    # now we are done
    @test evaluation_budget(oh) == 0
    evaluate_objective!(oh, [[0.1, 0.9], [0.1, 0.3]])
end
