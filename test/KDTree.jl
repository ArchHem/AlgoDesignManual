using Test

include("../src/AbstractModule.jl")
using .Basics
using Random

@testset "Node KDTree Tests" begin
    rng = Xoshiro(1)
    D = 3
    N = 10
    basedata = rand(rng, D, N)
    root = NodeKDTRee(basedata)
    #choose an elemement at random
    index = rand(rng, 1:N)
    #test that nn works
    point = basedata[:, index]

    dist, nearest = nn_search(root, point)
    @test nearest.point == point
    @test isapprox(dist, 0.0)

end