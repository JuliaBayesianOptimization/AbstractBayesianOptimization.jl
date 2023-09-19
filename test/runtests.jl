using AbstractBayesianOptimization
using Test


@testset "utils: to_unit_cube, from_unit_cube" begin
    @test_throws ArgumentError to_unit_cube([1,1], [-1, -1], [-3, 3])
    @test isapprox(to_unit_cube([1,1], [-1, -1], [3, 3]), [0.5, 0.5])
    @test isapprox(to_unit_cube([1,1], [-3, -3], [1, 1]), [1, 1])

    @test_throws ArgumentError from_unit_cube([1,1], [-1, -1], [-3, 3])
    @test isapprox(from_unit_cube([1,1], [-1, -1], [3, 3]), [3, 3])
    @test isapprox(from_unit_cube([0.5,0.5], [-3, 0], [1, 1]), [-1, 0.5])
    # test for bijection
    for (lb, ub) in [ ([-3.4, 5.6], [-1., 7.8]), ([67.4, -1.4], [70.3,0.]), ([-30.,-48.],[50.,90])]
        for x in 0:0.1:1, y in 0:0.03:1
            @test isapprox(to_unit_cube(from_unit_cube( [x, y], lb, ub), lb, ub), [x, y])
            @test isapprox(from_unit_cube(to_unit_cube( [x, y], lb, ub), lb, ub), [x, y])
        end
    end
end


oh = OptimizationHelper(x -> x[1] + x[2], Min, [-1., 1.], [1.,1.5], 50, verbose=false)
@testset "OptimizationHelper: Preprocessing" begin
    #  test Preprocessing, turn min. problem into a maximization problem
    @test isapprox(oh.problem.f(to_unit_cube([1.,1.], oh.problem.lb, oh.problem.ub)), -2)
end
@testset "OptimizationHelper: evaluate_objective!" begin
    # [5., 0.] ⊄ [0,1]^dimension
    @test_throws ArgumentError evaluate_objective!(oh, [[5. , 0.]])
    # [1.3, 1.2] is not between lb= [-1., 1.], ub = [1.,1.5]
    @test_throws ArgumentError evaluate_objective!(oh, [to_unit_cube([1.3,1.2], oh.problem.lb, oh.problem.ub)])
    @test isapprox(evaluate_objective!(oh, [to_unit_cube([-0.5,1.2], oh.problem.lb, oh.problem.ub),
    to_unit_cube([0.1,1.1], oh.problem.lb, oh.problem.ub)
    ]), [-0.7, -1.2])
end

oh2 = OptimizationHelper(x -> x[1] + x[2] + x[3], Min, [-1f0, 1f0, 3.5f0], [1f0,1.4f0,4f0], 50, verbose=false)

@testset "OptimizationHelper: infer dimension and type of elements in the domain" begin
    @test oh.problem.domain_eltype == Float64
    @test oh.problem.dimension == 2

    @test oh2.problem.domain_eltype == Float32
    @test oh2.problem.dimension == 3
    # by default we passed Float64 as range type but it is Float32
    @test_throws ErrorException evaluate_objective!(oh2, [[1f0,1f0,0f0]])
end

# add test: better objective resutls in an update of the current best optimizer
# add tests: get_hist, get_solution update_hist!
